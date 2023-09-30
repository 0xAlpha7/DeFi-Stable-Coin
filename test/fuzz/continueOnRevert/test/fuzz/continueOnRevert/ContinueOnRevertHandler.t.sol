// Commented out for now until revert on fail == false per function customization is implemented

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import {Test} from "forge-std/Test.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

// import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
// import {DSCEngine, AggregatorV3Interface} from "../../../src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
// import {Randomish, EnumerableSet} from "../Randomish.sol";
// import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
// import {console} from "forge-std/console.sol";

// contract ContinueOnRevertHandler is Test {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using Randomish for EnumerableSet.AddressSet;

//     // Deployed contracts to interact with
//     DSCEngine public dscEngine;
//     DecentralizedStableCoin public dsc;
//     MockV3Aggregator public ethUsdPriceFeed;
//     MockV3Aggregator public btcUsdPriceFeed;
//     ERC20Mock public weth;
//     ERC20Mock public wbtc;

//     // Ghost Variables
//     uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

//     constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
//         dscEngine = _dscEngine;
//         dsc = _dsc;

//         address[] memory collateralTokens = dscEngine.getCollateralTokens();
//         weth = ERC20Mock(collateralTokens[0]);
//         wbtc = ERC20Mock(collateralTokens[1]);

//         ethUsdPriceFeed = MockV3Aggregator(
//             dscEngine.getCollateralTokenPriceFeed(address(weth))
//         );
//         btcUsdPriceFeed = MockV3Aggregator(
//             dscEngine.getCollateralTokenPriceFeed(address(wbtc))
//         );
//     }

//     // FUNCTOINS TO INTERACT WITH

//     ///////////////
//     // DSCEngine //
//     ///////////////
//     function mintAndDepositCollateral(
//         uint256 collateralSeed,
//         uint256 amountCollateral
//     ) public {
//         amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);
//         ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
//         collateral.mint(msg.sender, amountCollateral);
//         dscEngine.depositCollateral(address(collateral), amountCollateral);
//     }


// }