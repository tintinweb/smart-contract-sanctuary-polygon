/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SmartMoney {
    uint256 public balanceReceived;

    function deposit() public payable {
        balanceReceived += msg.value;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAll() public {
        payable(msg.sender).transfer(getBalance());
    }

    function withdrawToAddress(address payable to) public {
        to.transfer(getBalance());
    }
}