/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract TestInputAndReadContract{
    uint private privateNumber1;
    uint private privateNumber2;
    uint public publicNum1;
    uint public publicNum2;
    string public publicName;
    string private privateName;


    constructor(uint input1,uint input2,uint input3,uint input4,string memory input5, string memory input6){
    privateNumber1=input1;
    privateNumber2=input2;
    publicNum1=input3;
    publicNum2=input4;
    publicName=input5;
    privateName=input6;
    }

    function modifyPrivateNumber1(uint input) public {
        privateNumber1 = input;
    }

    function modifyPrivateNumber2(uint input) public {
        privateNumber2 = input;
    }

    function modifyPublicNum1(uint input) public {
        publicNum1 = input;
    }

    function modifyPublicNum2(uint input) public {
        publicNum2 = input;
    }

    function modifyPublicName(string memory input) public {
        publicName = input;
    }

    function modifyPrivateName(string memory input) public {
        privateName = input;
    }




//read only
    function readPrivateNum1() public view returns (uint){

        return privateNumber1;
    }

    function readPrivateNum2() public view returns (uint){

        return privateNumber2;
    }

    function readPublicNum1() public view returns (uint){
        return publicNum1;
    }

    function readPublicName() public view returns (string memory){
        return publicName;
    }

    function readPrivateName() public view returns (string memory){
        return privateName;
    }

    
}