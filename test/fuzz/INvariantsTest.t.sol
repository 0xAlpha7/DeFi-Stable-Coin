// SPDX-License-Identifier: MIT
// Have our invariant aka properties

/* Keep in mind
 what are our varients
 1: The total supply of DSC should be less than the total value of collateral
 2: Getter view functions should never revert  <- evergreen invariant
*/

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract InvariantsTest is StdInvariant, Test {
    
    function setUp() external{}
    
}