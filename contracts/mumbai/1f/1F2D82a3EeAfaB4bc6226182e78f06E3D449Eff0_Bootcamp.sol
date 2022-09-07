// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bootcamp{
    string userName = "Blocorbit";

    function getuserName() public view returns (string memory){
        return userName;
    }

    function setuserName(string memory newUserName) public{
        userName = newUserName;   
    }
}