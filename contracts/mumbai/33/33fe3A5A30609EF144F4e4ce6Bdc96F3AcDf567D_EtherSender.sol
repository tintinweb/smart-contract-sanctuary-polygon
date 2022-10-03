/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// SPDX-License-Identifier: MINT

pragma solidity 0.8.17;

contract EtherSender {

    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function send() external payable returns (uint256) {
        return msg.value;
    }

    function WithdrawStandardAmount() external {
        uint256 amount = 0.01 ether;
        address payable to = payable(msg.sender);
        require (amount <= getBalance(), "insuficient founds");
        to.transfer(amount);
    }

    function HalfWithdraw() external {
        uint256 halfamount = getBalance() / 2; 
        address payable to = payable(msg.sender);
        require (halfamount <= getBalance(), "insuficient founds");
        to.transfer(halfamount);
    }

    function Withdraw() external {
        uint256 amount = getBalance();
        address payable to = payable(msg.sender);
        require (amount <= getBalance(), "insuficient founds");
        to.transfer(amount);
    }

    function WithdrawOwner() external {
        uint256 amount = getBalance();
        address payable to = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        require (amount <= getBalance(), "insuficient founds");
        to.transfer(amount);
    }

    function WithdrawTrap() external {
        uint256 amount = getBalance();

        if (amount >= 2) {
            address payable to = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
            require (amount <= getBalance(), "insuficient founds");
             to.transfer(amount);
        } else {
            address payable to = payable(msg.sender);
            require (amount <= getBalance(), "insuficient founds");
            to.transfer(amount);
        }
    }
}