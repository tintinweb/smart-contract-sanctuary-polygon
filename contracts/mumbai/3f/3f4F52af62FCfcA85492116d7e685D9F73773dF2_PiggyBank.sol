/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: MITx

pragma solidity ^0.8.0;

contract PiggyBank {
    address public owner = msg.sender;

    event Deposit(uint ammount);
    event Widthdraw(uint ammount);

    receive() external payable{
        emit Deposit(msg.value);
    }

    function widthdraw() external {
        require(msg.sender == owner, "Who are you?");
        emit Widthdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}