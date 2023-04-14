/**
 *Submitted for verification at polygonscan.com on 2023-04-14
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
    bool boolA;
    string strb;
    string[] listStr;
    uint[] listUint;

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
 
    function getBoolA() view public returns(bool a){
        return boolA;
    }
    function setboolA(bool _boolA)  public {
        boolA=_boolA;
    }
    function getstrb() view public returns(string memory b){
        return strb;
    }
    function setstrb(string memory _strb)  public {
        strb=_strb;
    }
    function getlistStr() view public returns(string[] memory b){
        return listStr;
    }
    function setlistUint(string[] memory _listStr)  public {
        listStr=_listStr;
    }
    function getlistUint() view public returns(uint[] memory b){
        return listUint;
    }
    function setlistUint(uint[] memory _listUint)  public {
        listUint=_listUint;
    }

}