// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Owner.sol';

contract SimpleStorage is Owner {

    uint s_favoriteNumber;

    event u_favoriteNumber(uint _x, uint _timestamp);

    constructor(uint _x) {
        s_favoriteNumber = _x;
    }

    function setFavoriteNumber(uint _x) external isOwner {
        s_favoriteNumber = _x;
        emit u_favoriteNumber(_x, block.timestamp);
    }

    function getFavoriteNumber() external view returns(uint) {
        return s_favoriteNumber;
    }
}