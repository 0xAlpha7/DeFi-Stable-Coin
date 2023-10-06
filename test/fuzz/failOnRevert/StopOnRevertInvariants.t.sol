// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// Invariants:
// protocol must never be insolvent / undercollateralized
// TODO: users cant create stablecoins with a bad health factor
// TODO: a user should only be able to be liquidated if they have a bad health factor

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";


contract StopOnRevertInvariants is StdInvariant, Test {
  
    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

  
    function setUp() external {
    }

  
}