/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public owner;
    IERC20 public token;
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }
    
    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external {
        require(msg.sender == owner, "Only the owner can distribute tokens");
        require(recipients.length == amounts.length, "Invalid input length");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amounts[i]);
        }
    }
}