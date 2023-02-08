/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

pragma solidity ^0.8.0;

contract ExternalContract {
address contractAddress;
address tokenAddress;
address owner;

constructor(address _contractAddress, address _tokenAddress) {
    contractAddress = _contractAddress;
    tokenAddress = _tokenAddress;
    owner = msg.sender;
}

function setTokenAddress(address _tokenAddress) public onlyOwner {
    tokenAddress = _tokenAddress;
}

function setOwner(address _owner) public onlyOwner {
    owner = _owner;
}

function setContractAddress(address _contractAddress) public onlyOwner {
    contractAddress = _contractAddress;
}

function notifyRewardAmount() public {
    // Call the "balanceOf" function of the token contract to get the balance of the tokenAddress
    uint256 balance = ERC20(tokenAddress).balanceOf(tokenAddress);
    
    // Call the "totalSupply" function of the contractAddress to get the total supply of tokens
    uint256 totalSupply = ContractA(contractAddress).totalSupply();
    
    // Calculate the reward value
    uint256 reward = totalSupply - balance;
    
    // Call the "notifyRewardAmount" function of the contractAddress with the calculated reward value
    ContractA(contractAddress).notifyRewardAmount(reward);
}

modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can perform this action.");
    _;
}
}

interface ERC20 {
function balanceOf(address tokenOwner) external view returns (uint256);
}

interface ContractA {
function notifyRewardAmount(uint256 reward) external;
function totalSupply() external view returns (uint256);
}