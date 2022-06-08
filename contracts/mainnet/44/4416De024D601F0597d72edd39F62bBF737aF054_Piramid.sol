/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface Interface {
    event deposit(uint indexed id);
}

contract Piramid is Interface {

    uint internal multiplier = 14;
    address payable public contractOwner;

    constructor () payable {
        contractOwner = payable(msg.sender);
    }

    uint public coversId1 = 0;
    bool prev1 = false;
    address payable public investor1;
    address payable public nextToCollect1;
    mapping(uint => address payable) public covers1;
    mapping(address => uint) public getId1;

    uint public coversId2 = 0;
    bool prev2 = false;
    address payable public investor2;
    address payable public nextToCollect2;
    mapping(uint => address payable) public covers2;
    mapping(address => uint) public getId2;

    uint public coversId3 = 0;
    bool prev3 = false;
    address payable public investor3;
    address payable public nextToCollect3;
    mapping(uint => address payable) public covers3;
    mapping(address => uint) public getId3;

    mapping(address => uint8) public permisions;

    uint  price1 =   200*10**multiplier;
    uint  reguard1 = 340*10**multiplier;
    uint  comision1 = price1*2-reguard1;

    uint  price2 =   340*10**multiplier;
    uint  reguard2 = 612*10**multiplier;
    uint  comision2 = price2*2-reguard2;

    uint  price3 =   612*10**multiplier;
    uint  reguard3 = 116*10**multiplier;
    uint  comision3 = price3*2-reguard3;

    function pool1() public payable returns(bool){
        require(msg.value == price1,"Invalid amount to deposit");
        if(prev1 == false && coversId1 == 0){
            coversId1 = 1;
            covers1[1] = payable(msg.sender);
            getId1[msg.sender] = coversId1+1;
            nextToCollect1 = payable(msg.sender);
        }else {
            if(!prev1){
                investor1 = payable(msg.sender);
                prev1 = true;
                getId1[msg.sender] = coversId1+1;
            }else{
                covers1[coversId1].transfer(reguard1); 
                nextToCollect1 = investor1;
                investor1 = payable(msg.sender);
                prev1 = false;
                covers1[coversId1+1] = payable(investor1);
                covers1[coversId1+2] = payable(msg.sender);
                coversId1 = coversId1+2;
                getId1[msg.sender] = coversId1+1;
            }
        }
        if(permisions[msg.sender] == 0 ) permisions[msg.sender] = 1;
        uint id = coversId1;
        emit deposit(id);
        return true;
    }

    function pool2() public payable returns (bool){
        require(permisions[msg.sender] > 0,"You don heve permisions");
        require(msg.value == price2,"Invalid amount to deposit");
        if(prev2 == false && coversId2 == 0){
            coversId2 = 1;
            covers2[1] = payable(msg.sender);
            nextToCollect2 = payable(msg.sender);
            getId2[msg.sender] = coversId2+1;
        }else {

            if(!prev2){
                investor2 = payable(msg.sender);
                prev2 = true;
                getId2[msg.sender] = coversId2+1;
            }else{
                covers2[coversId2].transfer(reguard2); 
                nextToCollect2 = investor2;
                investor2 = payable(msg.sender);
                prev2 = false;
                covers2[coversId2+1] = investor2;
                covers2[coversId2+2] = payable(msg.sender);
                coversId2 = coversId2+2;
                getId2[msg.sender] = coversId2+1;
            }
        }
        permisions[msg.sender] = permisions[msg.sender] + 1;
        uint id = coversId2;
        emit deposit(id);
        return true;
    }

    function pool3() public payable returns (bool){
        require(permisions[msg.sender] > 1,"You don heve permisions");
        require(msg.value == price3,"Invalid amount to deposit");
        if(prev3 == false && coversId3 == 0){
            coversId3 = 1;
            covers3[1] = payable(msg.sender);
            nextToCollect3 = payable(msg.sender);
            getId3[msg.sender] = coversId3+1;
        }else {

            if(!prev3){
                investor3 = payable(msg.sender);
                prev3 = true;
                getId3[msg.sender] = coversId3+1;
            }else{
                covers3[coversId3].transfer(reguard3); 
                nextToCollect3 = investor3;
                investor3 = payable(msg.sender);
                prev3 = false;
                covers3[coversId3+1] = investor3;
                covers3[coversId3+2] = payable(msg.sender);
                coversId3 = coversId3+2;
                getId3[msg.sender] = coversId3+1;
            }
        }
        uint id = coversId3;
        emit deposit(id);
        return true;
    }

    function getInvestor1() public view returns (address){
        return investor1;
    }

    function getInvestor2() public view returns (address){
        return investor2;
    }

    function getInvestor3() public view returns (address){
        return investor3;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not owner");
        _;
    }

    function withdraw(uint amount) public onlyOwner returns(bool){
        require(msg.sender == contractOwner, "Not owner");
        (bool success,) = contractOwner.call{value: amount}("");
        require(success, "Failed to send Ether");
        return true;
    }

    function renounceOwner() public onlyOwner returns(bool){
        require(msg.sender == contractOwner, "Not owner");
        contractOwner = payable(address(0));
        return true;
    }

    function balance() public view returns(uint){
        return address(this).balance;
    }

    function changeOwner (address newOwner) public onlyOwner returns(bool){
        require(msg.sender == contractOwner, "Not owner");
        contractOwner = payable(newOwner);
        return true;
    }

}