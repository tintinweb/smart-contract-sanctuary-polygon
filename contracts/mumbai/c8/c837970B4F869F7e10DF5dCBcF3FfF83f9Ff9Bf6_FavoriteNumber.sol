/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FavoriteNumber {
    uint favoriteNumber;

    function getFavoriteNumber() external view returns(uint) {
        return favoriteNumber;
    }

    function setFavoriteNumber(uint _favoriteNumber) external {
        favoriteNumber = _favoriteNumber;
    }
}