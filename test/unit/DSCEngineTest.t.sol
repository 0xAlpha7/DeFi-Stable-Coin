// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    address public USER = makeAddr("user");

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run(); 
        (ethUsdPriceFeed, btcUsdPriceFeed , weth, , ) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

     //TODO: constructor tests
     address[] public tokenAddresses;
     address[] public priceFeedAddresses;
     function testRevertIfTokenLengthDoesNotMatchPriceFeeds() public{
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);


     }

    //TODO: price tests
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        //15e18 * 2000e18 = 30,000e18
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd); 
    }  

    //TODO: deposit collateral test
    function testRevertsIfCollateralZero() public{
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsc), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositeCollateral(weth, 0);
        vm.stopPrank();
    }
    
    
} 