/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
interface ITest {
    function foo(uint256 amount) external;
}
contract TestCaller {
    address immutable test;
    constructor() {
        test = 0x30ea6364357F3980365d4325d4F251B84df730aD;
    }

    function foo2(uint256 amount) public {
        ITest(test).foo(amount);
    }

}