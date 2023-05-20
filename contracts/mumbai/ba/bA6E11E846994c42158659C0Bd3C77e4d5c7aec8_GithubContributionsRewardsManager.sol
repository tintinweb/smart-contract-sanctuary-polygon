// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract GithubContributionsRewardsManager {
    uint256 public PRICE_REWARD = 333 ether; // 333 matic per contribution
    uint256 public MIN_WITHDRAWAL_REWARD = 0; // if zero it is just a sanity check
    
    address private gelatoSender;
    address private owner;
    
    mapping (address => uint256) public rewards;
    
    event RewardsAssigned(address indexed contributor, uint256 amount, bytes32 indexed data);
    event RewardsClaimed(address contributor, uint256 amount);
    
    constructor () {
        owner = msg.sender;
    }
    
    // data allows the gelato w3f to send arbitrary data,
    // w3f will send the hash of repo & pull request being rewarded to track it on events
    // avoiding double rewarding, just like the evm nonce avoids double spending
    function assignRewards(address contributor, uint256 amount, bytes32 data) external {
        require(msg.sender == gelatoSender, "Forbidden");
        rewards[contributor] += amount;
        emit RewardsAssigned(contributor, amount, data);
    }
    
    function claimRewards() external {
        uint256 amount = rewards[msg.sender];
        rewards[msg.sender] = 0;
        require(amount > MIN_WITHDRAWAL_REWARD, "NotEnoughReward");
        (bool success, ) = msg.sender.call{ value: amount  *  PRICE_REWARD }("");
        require(success, "Withdrawal");
        emit RewardsClaimed(msg.sender, amount);
    }
    
    function setGelatoSender(address _gelatoSender) external {
        require(msg.sender == owner, "Forbidden");
        gelatoSender = _gelatoSender;
    }
}