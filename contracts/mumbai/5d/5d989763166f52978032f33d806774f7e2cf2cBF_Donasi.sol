// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donasi {
    address public operator;
    uint public balance;

      modifier isOperator() {
        require(
            (msg.sender == operator),
            "Caller is not the operator"
        );
        _;
    }

    constructor(){
       operator =  msg.sender;
    }
   
    function add(uint a, uint b) public pure returns(uint){
        return a + b;
    }
    function substract(uint a, uint b) public pure returns(uint){
        return a - b;
    }
    function pay() public payable{
        balance = msg.value;
    }


}