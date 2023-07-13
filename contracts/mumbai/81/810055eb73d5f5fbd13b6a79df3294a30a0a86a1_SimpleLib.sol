// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SimpleLib {

    struct Data {
        uint256 a;
    }

    function y(Data storage self) public {
        self.a++;
    }

    function x(Data storage self) public {
        y(self);
    }
}