// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    //!state variables
    mapping(address token => address priceFeed) private s_priceFeed; //token => priceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;


    DecentralizedStableCoin private immutable i_dsc;

    //!events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount); 

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
    function depositeCollateralAndMintDsc() external {}

    /**
     * @notice follow CEI pattern (checks effects Interaction)
     * @param tokenCollateralAddress The address of the token todeposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositeCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
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

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}


    /**
     * @notice Follow CEI pattern (checks effects Interaction)
     * @param amountDscToMint: The amount of decentralized stable coin to mint
     * @notice The must have more collateral value than the minimam threshold
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant() {
        // require(_checkAllowance(), "DSC Engine: allowance not enough");
        s_DSCMinted[msg.sender] += amountDscToMint;
        //if they minted too much
        revertIfHealthFactorIsBroken(msg.sender);
        

    }

    function burnDsc() external {}
    function liquidate() external {
        //$100 ETH  --> $40 (liquidated) $60 --> kickout from the system because you are too close
        //$50 DSC
    }

    function getHealthFactor() external view {}

    //!private and internal, view functions
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
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1: check health factor (do they have enough collateral?)
        // 2" revert if they do not have  good health factor        
    }

     //!public and external, view functions

     function getAccountCollateralValue(address user) public view returns (uint256) {
        //loop throw each collateral token, get the amount they have deposited and map it to the price, to get the USD value
        
     }
}
