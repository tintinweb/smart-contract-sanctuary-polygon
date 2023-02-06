// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Box_v1 {
    uint public value;
    // proxy contracts cant have constructors
    // they have initiliazers for state variables
    // devlivered trhough proxy
    // upgradable contracts the state variables insie impl are never used

    // Emitted when the stored value changes
    event ValueChanged(uint newValue);

    // Stores a new value in the contract
    function initial_state_values(uint newValue) external {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint) {
        return value;
    }

    // function initizialize(uint _val) external {
    //     value = _val;
    // }
}