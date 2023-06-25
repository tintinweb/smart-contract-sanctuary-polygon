// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract StakeContract {
    // The owner of this contract
    address public owner;

    // The amount each address can stake
    uint256 public stakeAmount = 0.01 ether;

    // Mapping to keep track of stakers
    mapping(address => bool) public stakers;

    // Mapping to keep track of balances
    mapping(address => uint256) public balances;

    // Array to keep track of all stakers' addresses
    address[] public stakersAddresses;

    constructor() {
        owner = msg.sender;
    }

    // Function to stake ETH
    function stake() public payable {
        // Only allow the exact stake amount
        require(msg.value == stakeAmount, "Must stake exactly 0.01 ETH.");

        stakers[msg.sender] = true;
        balances[msg.sender] += msg.value;
        stakersAddresses.push(msg.sender);
    }

    // Function for the owner to release all staked funds
    function release() public {
        require(msg.sender == owner, "Only the contract owner can release funds.");

        // Loop over all stakers and send them their staked funds
        for (uint i=0; i<stakersAddresses.length; i++) {
            // Skip if this address has not staked
            if (!stakers[stakersAddresses[i]]) continue;

            // Transfer the staked amount back to the staker
            payable(stakersAddresses[i]).transfer(balances[stakersAddresses[i]]);
            
            // Reset staker status and balance
            stakers[stakersAddresses[i]] = false;
            balances[stakersAddresses[i]] = 0;
        }
    }
}