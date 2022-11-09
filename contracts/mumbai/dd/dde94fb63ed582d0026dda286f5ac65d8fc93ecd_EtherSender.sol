/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSender {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier enoughEther{
        require(getBalance() > 0, "No funds");
        _;
    }

    event etherReceived(address to, bool success);
    event moreEtherReceived(address to, bool success);
    event getAllMoney(address to, bool success);
    
    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function sendEther() payable external {
        require(msg.value >= 0.02 ether, "Not enough ether");
    }

    function receiveEther() external {
        require(getBalance() >= 0.01 ether, "Not 0.01 ether");
        (bool success, ) = payable(msg.sender).call{value: 0.01 ether}("");
        emit etherReceived(msg.sender, success);
    }

    function receiveMoreEther() external enoughEther {
        (bool success, ) = payable(msg.sender).call{value: getBalance() / 2}("");
        emit moreEtherReceived(msg.sender, success);
    }

    function receiveMoreAndMoreEther() external enoughEther {
        require(msg.sender == owner, "You're not the owner");
        (bool success, ) = owner.call{value: getBalance()}("");
        emit getAllMoney(owner, success);
    }

}