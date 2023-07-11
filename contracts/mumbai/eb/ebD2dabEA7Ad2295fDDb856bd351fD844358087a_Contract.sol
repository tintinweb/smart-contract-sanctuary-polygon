// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Contract {

    uint public _counter;

    event CounterMutation(address sender, uint newValue);

    constructor(){
        _counter = 0;
    }

    function increment() external {
        _counter += 1;
        emit CounterMutation(msg.sender, _counter);
    }


}