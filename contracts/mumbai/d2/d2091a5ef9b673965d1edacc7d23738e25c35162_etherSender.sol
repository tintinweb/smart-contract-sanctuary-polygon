/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract etherSender {

    function withdrawAmount() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        to.transfer(amount);
    }
    
    function withdrawHalf() external {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance()/2;
        to.transfer(amount);
    }

    function withdrawOwner() external {
        address payable owner = payable(0xA23debA903483Fc651C09918e358DFC3C5318025);
        uint256 amount = getBalance();
        owner.transfer(amount);
    }
    
    function reciveEther() external payable returns(uint256) {
        return msg.value;
    }
    
    function getBalance() private view returns(uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

}