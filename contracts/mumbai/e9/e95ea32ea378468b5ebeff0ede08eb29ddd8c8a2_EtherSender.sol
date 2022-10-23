/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender{
    address payable owner = payable(0x73E112D9a2B5E5e04d6b7ef2C9eE5Ceea236978f);

    function getBalance() private view returns (uint256){
        uint256 balance = address(this).balance;

        return balance;
    }

    function deposit() external payable{

    }

    function withrawFixedAmount() external {
        //require(getBalance() >= 0,01, "Balance insufficient");
        address payable sender = payable(msg.sender);
        sender.transfer(0.01 ether);
    }
    
    function withrawHalfBalance() external {
        uint256 halfBalance = getBalance() / 2;
        address payable sender = payable(msg.sender);
        sender.transfer(halfBalance);
    }

    function withrawOwner() external {
        uint balance = getBalance();

        owner.transfer(balance);
    }
}