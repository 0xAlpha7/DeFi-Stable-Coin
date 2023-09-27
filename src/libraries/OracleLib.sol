// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

 /*
 * @title OracleLib
 * @notice This library is used to check the chianlink oracle for stale data
 *         if Price is stale, the function will revert and render the DSCEngine unuseable -  *         this is by design
 * 
 * We want DSCEngine to freez if prices becomes stale
 * so if the chainlink network explodes and you have a lot of money locked in the protocol -- to bad
 * */