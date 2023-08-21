// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/*
* @title: Decentralized Stable Coin Engine
* @author: Talha
*
* This system is design to be as minimal as posible, and have the tokens maintain a 1 token =   $1 peg.
*
* this systme has the following properties:
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
contract DSCEngine {

    //!errors
    error DSCEngine__NeedsMoreThanZero();    

    //!modifiers
    modifier moreThanZero(uint256 amount) {
        // require((amount > uint256(0)), "Amount must not be zero");
        if(amount == 0){
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }
    
    function depositeCollateralAndMintDsc() external {}


    /**
     * @param tokenCollateralAddress The address of the token todeposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositeCollateral(address tokenCollateralAddress, uint256 amountCollateral) external moreThanZero(amountCollateral) {

    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}
    function liquidate() external {
        //$100 ETH  --> $40 (liquidated) $60 --> kickout from the system because you are too close
        //$50 DSC
    }

    function getHealthFactor() external view {}
}
