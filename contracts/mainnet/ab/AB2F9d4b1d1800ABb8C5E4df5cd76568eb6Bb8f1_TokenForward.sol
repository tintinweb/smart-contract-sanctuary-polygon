// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenForward {
    address public owner;
    address public tokenAddress;
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }
    
    function receiveTokens(uint256 _amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, _amount), "Token transfer failed");
    }
}