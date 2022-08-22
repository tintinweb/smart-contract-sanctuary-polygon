//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
    uint256 favNumber = 5;

    function getFavNumber() public view returns (uint256) {
        return favNumber;
    }

    function getModifiedFavNumber() public returns (uint256) {
        uint256 _favNumber = favNumber + 5;
        return _favNumber;
    }
}