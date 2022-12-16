/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract SmartMoney {
    uint public balance;

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        balance += msg.value;
    }

    function withdrawAll() public {
        address payable to = payable(msg.sender);
        to.transfer(getContractBalance());
    }

    function withdrawToAddress(address payable to) public {
        to.transfer(getContractBalance());
    } 
}