// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract FirstContract {
    uint256 _count;

    function increment() public {
        _count = _count + 1;
    }

    function count() public view returns(uint256) {
        return _count;
    }
}