/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;



contract BatchTransfer  {
    function batchTransfer(address[] memory recipients) public payable {
        uint256 amount=1478800000000000000;
        require(recipients.length > 0, "No recipients provided");
        require(msg.value >= recipients.length * amount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amount);
        }
    }

    function withdraw() public payable{
       address payable  recipient=  payable(0x888DE4eE08dB5cC1E4588689C5aAeb52561e2320);
       require(address(this).balance > 0, "Contract balance is zero");
       recipient.transfer(address(this).balance);
    }
}