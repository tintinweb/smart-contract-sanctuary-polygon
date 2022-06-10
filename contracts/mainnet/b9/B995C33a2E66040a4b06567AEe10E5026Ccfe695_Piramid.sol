/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface Interface {
    event deposit(uint indexed id);
}

contract Piramid is Interface {

    uint internal multiplier = 16;
    address payable public contractOwner;
    address payable public comision;

    constructor () payable {
        contractOwner = payable(msg.sender);
        comision = payable(msg.sender);
    }

    uint public coversId1  = 0;
    uint public investorId1 = 0;
    bool prev1 = false;
    address payable public nextToCollect1;
    address payable public nextToCollect2;
    mapping(uint => address payable) public covers1;
    mapping(address => uint) public getId1;

    mapping(address => uint8) public permisions;

    uint  price1 =   200*10**multiplier;
    uint  reguard1 = 340*10**multiplier;
    uint  comision1 = price1*2-reguard1;

    function pool1() public payable returns(bool){
        require(msg.value == price1,"Invalid amount to deposit");
        if(prev1 == false && coversId1 == 0){
            comision.transfer(comision1);
            coversId1 = coversId1 + 1;
            investorId1 = investorId1 +1;
            covers1[investorId1] = payable(msg.sender);
            getId1[msg.sender] = investorId1;
            nextToCollect1 = payable(msg.sender);
        }else {
            if(!prev1){
                prev1 = true;
                investorId1 = investorId1 +1;

                covers1[investorId1] = payable(msg.sender);
                getId1[msg.sender] = investorId1;

                nextToCollect1 = covers1[coversId1];
                nextToCollect2 = covers1[coversId1+1];
            }else{
                covers1[coversId1].transfer(reguard1);
                comision.transfer(comision1);
                
                investorId1 = investorId1 +1;
                coversId1 = coversId1+1;
                prev1 = false;

                covers1[investorId1] = payable(msg.sender);
                getId1[msg.sender] = investorId1;
                
                nextToCollect1 = covers1[coversId1];
                nextToCollect2 = covers1[coversId1+1];

            }
        }
        if(permisions[msg.sender] == 0 ) permisions[msg.sender] = 1;
        uint id = coversId1;
        emit deposit(id);
        return true;
    }

    function getNnextToCollect1() public view returns (address){
        return nextToCollect1;
    }
    function getNnextToCollect2() public view returns (address){
        return nextToCollect2;
    }
//**** stake 1
//******************************************************************************

    uint public coversId2  = 0;
    uint public investorId2 = 0;
    bool prev2 = false;
    address payable public nextToCollect1b;
    address payable public nextToCollect2b;
    mapping(uint => address payable) public covers2;
    mapping(address => uint) public getId2;

    uint  price2 =   340*10**multiplier;
    uint  reguard2 = 612*10**multiplier;
    uint  comision2 = price2*2-reguard2;

    function pool2() public payable returns(bool){
        require(msg.value == price2,"Invalid amount to deposit");
        require(permisions[msg.sender] > 0);
        if(prev2 == false && coversId2 == 0){
            comision.transfer(comision2);
            coversId2 = coversId2 + 1;
            investorId2 = investorId2 +1;
            covers2[investorId2] = payable(msg.sender);
            getId2[msg.sender] = investorId2;
            nextToCollect1b = payable(msg.sender);
        }else {
            if(!prev2){
                prev2 = true;
                investorId2 = investorId2 +1;

                covers2[investorId2] = payable(msg.sender);
                getId2[msg.sender] = investorId2;

                nextToCollect1b = covers2[coversId2];
                nextToCollect2b = covers2[coversId2+1];
            }else{
                covers2[coversId2].transfer(reguard2);
                comision.transfer(comision2);
                
                investorId2 = investorId2 +1;
                coversId2 = coversId2+1;
                prev2 = false;

                covers2[investorId2] = payable(msg.sender);
                getId2[msg.sender] = investorId2;
                
                nextToCollect1b = covers2[coversId2];
                nextToCollect2b = covers2[coversId2+1];

            }
        }
        permisions[msg.sender] = permisions[msg.sender] +1;
        uint id = coversId2;
        emit deposit(id);
        return true;
    }

    function getNnextToCollect1b() public view returns (address){
        return nextToCollect1b;
    }
    function getNnextToCollect2b() public view returns (address){
        return nextToCollect2b;
    }
//*** stake 2
//******************************************************************************
    uint public coversId3  = 0;
    uint public investorId3 = 0;
    bool prev3 = false;
    address payable public nextToCollect1c;
    address payable public nextToCollect2c;
    mapping(uint => address payable) public covers3;
    mapping(address => uint) public getId3;

    uint  price3 =    612*10**multiplier;
    uint  reguard3 = 1162*10**multiplier;
    uint  comision3 = price3*2-reguard3;

    function pool3() public payable returns(bool){
        require(msg.value == price3,"Invalid amount to deposit");
        require(permisions[msg.sender] > 1,"permisions fail");
        if(prev3 == false && coversId3 == 0){
            comision.transfer(comision3);
            coversId3 = coversId3 + 1;
            investorId3 = investorId3 +1;
            covers3[investorId3] = payable(msg.sender);
            getId3[msg.sender] = investorId3;
            nextToCollect1c = payable(msg.sender);
        }else {
            if(!prev3){
                prev3 = true;
                investorId3 = investorId3 +1;

                covers3[investorId3] = payable(msg.sender);
                getId3[msg.sender] = investorId3;

                nextToCollect1c = covers3[coversId3];
                nextToCollect2c = covers3[coversId3+1];
            }else{
                covers3[coversId3].transfer(reguard3);
                comision.transfer(comision3);
                
                investorId3 = investorId3 +1;
                coversId3 = coversId3+1;
                prev3 = false;

                covers3[investorId3] = payable(msg.sender);
                getId3[msg.sender] = investorId3;
                
                nextToCollect1c = covers3[coversId3];
                nextToCollect2c = covers3[coversId3+1];

            }
        }
        permisions[msg.sender] = permisions[msg.sender] +1;
        uint id = coversId3;
        emit deposit(id);
        return true;
    }

    function getNnextToCollect1c() public view returns (address){
        return nextToCollect1b;
    }
    function getNnextToCollect2c() public view returns (address){
        return nextToCollect2b;
    }
//*** stake 3
//******************************************************************************


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