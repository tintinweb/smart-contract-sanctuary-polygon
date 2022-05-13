/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RequireTest {
    bool public _dummyBool;

    function externalFnTest(bool b) external {
        require(b, "Require Failed in the externalFnTest!");
        _dummyBool = b;
    }

    function publicFnTest(bool b) public {
        require(b, "Require Failed in the publicFnTest!");
        _dummyBool = b;
    }

    function externalPureFnTest(bool b) external pure {
        require(b, "Require Failed in the externalPureFnTest!");
    }

    function publicPureFnTest(bool b) public pure {
        require(b, "Require Failed in the publicPureFnTest!");
    }
}