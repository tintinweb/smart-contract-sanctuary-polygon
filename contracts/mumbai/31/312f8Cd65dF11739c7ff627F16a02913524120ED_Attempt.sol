// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IObjective {
    function attempt() external;
}

contract Attempt {
    function callObjectiveContract(address objetiveAdx) external {
        IObjective(objetiveAdx).attempt();
    }
}