/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EventDemo{

    event Log(string);
    event Log(uint);
    event NameRegister(string,uint,uint);


    function nameRegister() public{
        emit Log(unicode"域名注册");
        emit Log("20220202");
        emit NameRegister("doge king",7,62506390903782477599530665597457164490176241968269406480552883851120722732686);
    }

}