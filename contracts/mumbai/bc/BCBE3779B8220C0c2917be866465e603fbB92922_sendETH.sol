/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract sendETH{

    // address payable public getter = payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);

    receive() external payable{

    }

    function checkBal() public view returns(uint){
        return address(this).balance;
    }

    event log(uint _value);

    function SEND(address payable getter) public payable{
        emit log(msg.value);
        bool sent = getter.send(msg.value);
        require(sent, "Train is failed");
    }

    function TRANSFER(address payable getter) public payable{
        emit log(msg.value);
        getter.transfer(100000000000000);
    }

    function CALL(address payable getter) public payable{
        emit log(msg.value);
        (bool sent,) = getter.call{value: 100000000000000}("");
        require(sent, "Transaction is failed");
    }
}