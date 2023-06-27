/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract MSTest {

    event ContractPaused();
    event ContractActivated();
    event ContractExploited(address attacker);

    bool public isActive;

    constructor() {
        isActive = true;
    }

    function pause() public {
        require(isActive, "CONTRACT_PAUSED");
        isActive = false;

        emit ContractPaused();
    }

    function unpause() public {
        require(!isActive, "CONTRACT_NOT_PAUSED");
        isActive = true;
        
        emit ContractActivated();
    }

    function exploit() public {
        require(isActive, "CONTRACT_PAUSED");
        emit ContractExploited(msg.sender);
    }
}