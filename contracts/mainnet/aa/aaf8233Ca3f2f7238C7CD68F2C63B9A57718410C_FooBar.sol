//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

contract FooBar {
    address public _tokenSent;

    function deposit(address tokenSent) external {
        _tokenSent = tokenSent;
    }
}