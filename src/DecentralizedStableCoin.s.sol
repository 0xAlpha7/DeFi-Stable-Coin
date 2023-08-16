// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Talha
 * Collateral: Exogenous (Eth and Btc)
 * Minting: Algorithimic
 * Relative Stability: Pegged to USD
 * This is the contract meant to be governed by DSCEngie. This contract is just the ERC20 implimentation of our satable coin system.
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable{
    constructor () ERC20("DecentralizedStableCoin", "DSC") {
        
    }
}