// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
* @title: Decentralized Stable Coin Engine
* @author: Talha
*
* This system is design to be as minimal as posible, and have the tokens maintain a 1 token =   $1 peg.
*
* this systme has the following properties:moreThanZero
* - Exogenous Collateral
* - Dollar pegged
* - Algorithimic Stable
*
* This is similar to DAI. If DAI had no governance, no fees, and was only backed by WETH and WBTC
*
* Our DSC system should always be "overcollateraized". At no point, should the value of all collateral <= the $ backed value of all the DSC. 
*
* @notice: This contract is the core of the DCS System. It handles all the logics for minting and redeeming DCS, as well as depositing and withdrawing collateral. 
* @notice: This contract is very loosly based on the makerDAO (DAI) system
*/
contract DSCEngine is ReentrancyGuard {
    //!errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressAndPriceFeedAddressMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    //!state variables

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; 
    uint256 private constant PRECISION = 1e18; 
    uint256 private constant LIQUDATION_THRESHOLD = 50; //200% collateralized
    uint256 private constant LIQUDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10;  //10% bonus



    mapping(address token => address priceFeed) private s_priceFeed;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;


    DecentralizedStableCoin private immutable i_dsc;

    //!events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount); 
    event CollateralRedeemed(address indexed edeemedFrom, address indexed redeemTo, address indexed token,uint256 amount);

    //!modifiers
    modifier moreThanZero(uint256 amount) {
        // require((amount > uint256(0)), "Amount must not be zero");
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    //!functions
    constructor(address[] memory tokenAddress, address[] memory priceFeedAddress, address dscAddress) {
        //USD priceFeed
        if (tokenAddress.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressAndPriceFeedAddressMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeed[tokenAddress[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddress[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //!external functions
    /**
     * @notice This function will deposite your collatetal and mint DSC in one trasection
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     * @param amountDscToMint The amount of decentralized stable coin to mint
     */
    function depositeCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint) external {
        depositeCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice follow CEI pattern (checks effects Interaction)
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositeCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral); 
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
        
    }

    /**
     * @param tokenCollateralAddress: The collateral address to redeem
     * @param amountCollateral: The amount colateral to redeem 
     * @param amountDscToBurn: The amount of DSC to burn
     * This function burns DSC and redeem underlying collateral in one transaction
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemCollateral already checks health factor


    }

    // In order to redeem collateral:
    // 1: Health factor must be over 1 after collateral pull
    // DRY: do not repeat yourself
    // Follow CEI: Checks, Effects, Interaction 
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant() {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }


    /**
     * @notice Follow CEI pattern (checks effects Interaction)
     * @param amountDscToMint: The amount of decentralized stable coin to mint
     * @notice The must have more collateral value than the minimam threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant() {
        // require(_checkAllowance(), "DSC Engine: allowance not enough");
        s_DSCMinted[msg.sender] += amountDscToMint;
        //if they minted too much ($150 Dsc $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted){
            revert DSCEngine__MintFailed();
        }

    }

    //no need to check if this breaks health factor
    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);  //i don't think this would ever hit
    }
    

    /**
     * @param collateral: The ERC20 collateral address to liquidate from user
     * @param user: The user who has broken the health factor. Their _helthFactor should be below MIN_HEALTH_FACTOR
     * @param debtToCover: The amount of DSC you want to burn to improve the users health factor
     * @notice You can partially liquidate a user
     * @notice You will get a liquidation bonus for taking the users funds
     * @notice This function working assumes the protocol will be roughly 200% collateralized in order for this to work
     * @notice A known bug would be if the protocol were 100% or less collateralized, then we wouldn't be able to incentive the liquidators
     * for example: if the price of the collateral plummeted before anyone could be liquidated
     * Follow: CEI (checks, effects, interaction)
     */
    function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant() {
        //$100 ETH  --> $40 (liquidated) $60 --> kickout from the system because you are too close
        //$50 DSC
        uint256 statingUserHealthFactor = _healthFactor(user);
        if(statingUserHealthFactor >= MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorOk();
        }
        //burn their DSC "debt" and take their collateral
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        //give 10% bonus
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUDATION_PRECISION;
        uint256 totalCollateralRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(collateral, totalCollateralRedeem, user, msg.sender); 
        //burn DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= statingUserHealthFactor){
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(user);

    }

    function getHealthFactor() external view {}

    //!private and internal, view functions

    /**
     * @dev Low-level internal function, do not call unless the function calling it is checking for health factors being broken
     */

    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if(!success){
            revert DSCEngine__TransferFailed();
        }  
    } 
    
    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd) 
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);         
    }


    /**
     * returns how close to liquidation a user is
     * if a user goes below 1. then they can get liquidated
     */
    function _healthFactor(address user) view private returns(uint256){
        // we need 
        //1: total DSC minted
        //2: total collateral VALUE (make sure the VALUE > total DSC minted)
        (uint256 totalDscMinted, uint256 collateraValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateraValueInUsd * LIQUDATION_THRESHOLD) / LIQUDATION_PRECISION;

        //1000 ETH * 50 = 50,000 / 100 = 500

        //150 ETH * 50 = 7500 / 100 = 75 (75 /100 < 1) 

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;

        //100 ETH / 100 DSC = 1.5
        // return (collateraValueInUsd / totalDscMinted ); //it will not hanle points values

    }


   /**
     * check health factor (do they have enough collateral?)
     * revert if they don't
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor =  _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }

    }

     //!public and external, view functions

     function getTokenAmountFromUsd(address token, uint256 amountInWei) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (amountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
     } 

     function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        //loop throw each collateral token, get the amount they have deposited and map it to the price, to get the USD value
        for(uint256 i = 0; i < s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
     }

     function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeed[token]);
        (, int256 price, , ,) = priceFeed.latestRoundData();
        // 1 ETH = $1000
        // The returned value from CL will be 1000 * 1e8 (1e8 is decimal of ETH / USD)
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
     }
}
