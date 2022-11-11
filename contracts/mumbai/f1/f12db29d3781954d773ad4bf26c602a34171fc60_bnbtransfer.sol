/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract bnbtransfer{
    event Sent(address indexed from, address indexed to, uint indexed amount );

    address public owner;

    constructor() {
    owner = msg.sender;
    }

    function transfer(address payable _to) public payable{
        _to.transfer(msg.value);
        emit Sent(msg.sender,_to,msg.value);
    }

    function balanceof(address _add) view public returns(uint){
        return _add.balance;
    }
}