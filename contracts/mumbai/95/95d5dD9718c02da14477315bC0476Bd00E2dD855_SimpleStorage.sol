// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Owner.sol';

contract SimpleStorage is Owner {

    uint s_favoriteNumber;

    constructor(uint _x) {
        s_favoriteNumber = _x;
    }

    function setFavoriteNumber(uint _x) external isOwner {
        s_favoriteNumber = _x;
    }

    function getFavoriteNumber() external view returns(uint) {
        return s_favoriteNumber;
    }
}