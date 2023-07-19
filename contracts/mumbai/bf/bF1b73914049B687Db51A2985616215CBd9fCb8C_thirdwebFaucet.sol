// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract thirdwebFaucet {
    mapping(address => uint256) public balances;
    uint256 public tokenAmount = 100; // Amount of testnet tokens to distribute per request

    // Event emitted when tokens are distributed
    event TokensDistributed(address recipient, uint256 amount);

    // Function to request testnet tokens
    function requestTokens() external {
        address recipient = msg.sender;
        require(balances[recipient] == 0, "Tokens can only be requested once.");
        
        balances[recipient] = tokenAmount;
        emit TokensDistributed(recipient, tokenAmount);
    }
}