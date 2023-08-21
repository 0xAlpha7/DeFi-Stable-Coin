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

* @notice: This contract is the core of the DCS System. It handles all the logics for minting and redeeming DCS, as well as depositing and withdrawing collateral. 
* @notice: This contract is very loosly based on the makerDAO (DAI) system
*/
contract DSCEngine {
    constructor() {
        
    }
}