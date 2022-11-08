/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSender {

    address payable owner = payable(0xF12B4dAb269496016Fee2373e97b90473e589364);

    event etherReceived(address to, bool success);
    event moreEtherReceived(address to, bool success);
    event getAllMoney(address to, bool success);
    
    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function sendEther() payable external {
        
    }

    function receiveEther() external {
        (bool success, ) = payable(msg.sender).call{value: 0.01 ether}("");
        emit etherReceived(msg.sender, success);
    }

    function receiveMoreEther() external {
        (bool success, ) = payable(msg.sender).call{value: getBalance() / 2}("");
        emit moreEtherReceived(msg.sender, success);
    }

    function receiveMoreAndMoreEther() external {
        (bool success, ) = owner.call{value: getBalance()}("");
        emit getAllMoney(owner, success);
    }

}