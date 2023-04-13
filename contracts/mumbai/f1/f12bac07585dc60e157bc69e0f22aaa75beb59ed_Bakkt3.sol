/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;



contract Bakkt3   {


     struct accountInfo {
        address userAddress;
        uint id;
        string name;
    }

    mapping(address => accountInfo) public accountInfoList;

    uint testNum;
    
    function setUser(accountInfo memory _user) public {
        accountInfoList[_user.userAddress]=_user;
    }
     function getUser(address _userAddress) view public returns(accountInfo memory info) {
        return accountInfoList[_userAddress];
    }

    function getTestNum() view public returns(uint num){
        return testNum;
    }
 function setTestNum(uint _num)  public {
        testNum=_num;
    }
 

    
   

}