// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Storage {

    int256 FavNum;

    address[] users;
    

    function setFavNum(int256 _favnum) public {
        FavNum = _favnum;
    }

    function getFavNum() public view returns (int256) {
        return FavNum;
    }

    function getUsers() public view returns (address[] memory) {
        uint addCount = 0;
        for (uint i = 0; i < users.length; i++) {
            addCount += 1;           
        }
        return users;
    }

}