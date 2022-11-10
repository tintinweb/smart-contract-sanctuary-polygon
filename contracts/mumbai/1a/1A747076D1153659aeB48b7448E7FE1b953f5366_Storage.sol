// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Storage {

    int256 FavNum;

    function setFavNum(int256 _favnum) public {
        FavNum = _favnum;
    }

    function getFavNum() public view returns (int256) {
        return FavNum;
    }

}