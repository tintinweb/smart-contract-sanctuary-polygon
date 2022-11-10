// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Storage {

    int256 FavNum;

    mapping (address => int256) User;
    address[] public allUsers;

    

    function setFavNum(address _address, int256 _favnum) public {
        allUsers.push(_address);
        FavNum = _favnum;
    }

    function getFavNum() public view returns (int256) {
        return FavNum;
    }

}