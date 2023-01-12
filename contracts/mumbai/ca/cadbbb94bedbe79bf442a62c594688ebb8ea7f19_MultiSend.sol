/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSend {

    address public owner = payable(msg.sender);
    address[]   wallets;

    function _sendto(address[] memory addresses) public{
        wallets = addresses;
    }

    function sendFund(uint amount_to_each_wallet) public payable {
        for(uint i=0;i<wallets.length;i++){
           payable(wallets[i]).transfer(amount_to_each_wallet);
        }

        payable(owner).transfer(address(this).balance);
    }

    
}