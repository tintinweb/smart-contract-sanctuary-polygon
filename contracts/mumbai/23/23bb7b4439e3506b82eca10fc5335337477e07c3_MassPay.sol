/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract MassPay {

    function payETH(address payable[] calldata payees, uint256 amount) external payable {
        uint256 totalPayment = amount * payees.length;
        require(msg.value >= totalPayment, "Ethers sent are less than total payment amount.");

        for(uint i = 0; i < payees.length; i++){
            payees[i].call{value: amount}("");
        }
        msg.sender.call{value: msg.value - totalPayment}("");
    }
}