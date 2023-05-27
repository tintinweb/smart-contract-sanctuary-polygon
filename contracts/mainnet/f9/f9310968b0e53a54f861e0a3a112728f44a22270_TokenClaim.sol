/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenClaim {
    address public tokenContractAddress = 0x19971b392740A28a1Ca3bab43C42cD7E96cCD3Fe; // Address of the ERC20 token contract
    address public joinedContract = 0xb99Fd24DA1C76783007d331A8324dB2D391165e1; // Address of the contract to check if joined
    address public owner;
    
    IERC20 public token;
    mapping(address => bool) public hasClaimedTokens;
    mapping(address => bool) public joinedAddresses; // Mapping to track joined addresses

    event TokensClaimed(address indexed recipient, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
        token = IERC20(tokenContractAddress);
    }

    function claimTokens() external {
        require(!hasClaimedTokens[msg.sender], "Tokens already claimed");
        require(isJoined(msg.sender), "Caller has not joined the required contract");

        uint256 amountToClaim = 10 * 10 ** 18; // 10 tokens

        require(token.balanceOf(address(this)) >= amountToClaim, "Insufficient tokens in the contract");
        require(token.transfer(msg.sender, amountToClaim), "Token transfer failed");

        hasClaimedTokens[msg.sender] = true;

        emit TokensClaimed(msg.sender, amountToClaim);
    }

    function withdrawTokens() external {
        require(msg.sender == owner, "Only the owner can withdraw tokens");

        uint256 contractBalance = token.balanceOf(address(this));

        require(contractBalance > 0, "No tokens to withdraw");

        require(token.transfer(owner, contractBalance), "Token transfer failed");

        emit TokensWithdrawn(owner, contractBalance);
    }

    function isJoined(address recipient) internal view returns (bool) {
        return joinedAddresses[recipient];
    }
    
    function hasClaimed(address recipient) public view returns (bool) {
        return hasClaimedTokens[recipient];
    }
}