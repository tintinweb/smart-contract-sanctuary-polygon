/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Multisender {
    // Contract owner
    address public owner;
    
    // Mapping to track supported tokens
    mapping(address => bool) public supportedTokens;

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to add a supported token
    function addSupportedToken(address tokenAddress) external onlyOwner {
        supportedTokens[tokenAddress] = true;
    }
    
    // Function to remove a supported token
    function removeSupportedToken(address tokenAddress) external onlyOwner {
        supportedTokens[tokenAddress] = false;
    }

    // Function to distribute tokens to multiple addresses
    function multisend(address[] memory _to, uint256[] memory _values, address[] memory _tokens) external onlyOwner returns (bool) {
        require(_to.length == _values.length && _values.length == _tokens.length, "Invalid input lengths");

        for (uint256 i = 0; i < _to.length; i++) {
            require(_to[i] != address(0), "Invalid recipient address");
            require(supportedTokens[_tokens[i]], "Unsupported token");

            IERC20 token = IERC20(_tokens[i]);
            uint256 availableBalance = token.balanceOf(address(this));
            require(availableBalance >= _values[i], "Insufficient token balance");

            require(token.transfer(_to[i], _values[i]), "Token transfer failed");
        }

        return true;
    }
}