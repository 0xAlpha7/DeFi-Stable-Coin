// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


 /*
 * @title OracleLib
 * @notice This library is used to check the chianlink oracle for stale data
 *         if Price is stale, the function will revert and render the DSCEngine unuseable -  *         this is by design
 * 
 * We want DSCEngine to freez if prices becomes stale
 * so if the chainlink network explodes and you have a lot of money locked in the protocol -- to bad
 * */

 library oracleLib {
    uint256 private constant TIMEOUT = 3 hours;

    function stalePriceCheck(AggregatorV3Interface priceFeed) public view returns(uint80, int256, uint256, uint256, int80) 
    {
      
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();


    }
    
 }