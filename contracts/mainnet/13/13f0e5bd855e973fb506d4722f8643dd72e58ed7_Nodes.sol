// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/*
    @Nodes - Created by Parma Token
    - Website: https://parmatoken.com/
    - Telegram: https://t.me/parmatoken
*/

contract Nodes is Ownable {
    using SafeMath for uint256;

    uint256 public nodesLimit;
    uint256 public nodeCost;
    uint256 public nodeFee;
    uint256 public tokenDecimals; // Example would be 1e18 which is 18 decimals
    address private _feeAddress;

    bool public nodesPaused = false;
    uint256 public totalNodes;

    IERC20 public nodesToken;
    Reward public dailyReward;
    
    struct User {
        address addr;
        uint256 created;
        uint256 lastCreated;
        uint256 nodePools;
    }

    struct Node {
        uint256 id;
        uint256 amount;
        string name;
        string description;
        uint256 created;
        uint256 timestamp;
        uint256 reward;
    }

    struct Reward {
        uint256 reward;
        uint256 updated;
    }

    mapping(address => mapping(uint256 => Node)) public nodes;
    mapping(address => User) public user;

    // Make constructor much more configurable through deployment to make sure everything is correct
    constructor(uint256 limit, uint256 decimals, uint256 cost, uint256 reward, uint256 fee, IERC20 token, address feeAddress) {
        nodesLimit = limit;
        tokenDecimals = decimals;
        nodeCost = uint256(cost).mul(1*10**tokenDecimals);
        dailyReward = Reward({reward: uint256(reward).mul(1*10**tokenDecimals), updated: block.timestamp});
        nodeFee = fee;
        nodesToken = token;
        _feeAddress = feeAddress;
    }

    modifier nodeExists(address creator, uint256 nodeId) {
        require(nodes[creator][nodeId].id > 0, "This node does not exists.");
        _;
    }

    function userNode(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (Node memory) {
        return nodes[creator][nodeId];
    }

    function rewardCheck(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (bool) {
        return nodes[creator][nodeId].reward == dailyReward.reward;
    }
    
    function nodeEarned(address creator, uint256 nodeId) public view nodeExists(creator, nodeId) returns (uint256) {
        Node memory node = nodes[creator][nodeId];
        uint256 nodeStart = node.timestamp;
        uint256 reward = node.reward;

        uint256 nodeAge = block.timestamp / 1 seconds - nodeStart / 1 seconds;

        if (dailyReward.reward < reward) {
            uint256 updatedTime = block.timestamp / 1 seconds - dailyReward.updated / 1 seconds;
            nodeAge -= updatedTime;
        }

        uint256 rewardPerSec = reward.div(86400);
        uint256 earnedPerSec = rewardPerSec.mul(nodeAge);

        return earnedPerSec;
    }

    function createNodes(string memory name, string memory desc, uint256 amount) external {
        require(!nodesPaused, "Nodes are currently paused.");

        if (user[msg.sender].addr != msg.sender) {
            user[msg.sender] = User({
                addr: msg.sender,
                created: 0,
                lastCreated: 0,
                nodePools: 0
            });
        }

        require(user[msg.sender].created + amount <= nodesLimit, "The node amount exceeds your limit.");

        uint256 totalCost = nodeCost.mul(amount);
        uint256 nodeId = (user[msg.sender].lastCreated).add(1);
        nodes[msg.sender][nodeId] = Node({
            id: nodeId,
            amount: amount,
            name: name,
            description: desc,
            created: block.timestamp,
            timestamp: block.timestamp,
            reward: dailyReward.reward
        });

        totalNodes += amount;
        user[msg.sender].created += amount;
        user[msg.sender].nodePools += 1;
        user[msg.sender].lastCreated = nodeId;
        

        require(nodesToken.balanceOf(msg.sender) > totalCost, "Insufficient Funds in wallet");

        uint256 fee = totalCost.mul(nodeFee).div(100);

        nodesToken.transferFrom(msg.sender, address(this), totalCost.sub(fee));
        nodesToken.transferFrom(msg.sender, _feeAddress, fee);
    }

    function createNodesFor(address[] memory addresses, uint256[] memory amounts, string memory name, string memory desc) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addy = addresses[i];
            uint256 amt = amounts[i];

            if (user[addy].addr != addy) {
                user[addy] = User({
                    addr: addy,
                    created: 0,
                    lastCreated: 0,
                    nodePools: 0
                });
            }

            require(user[addy].created + amt <= nodesLimit, "The node amount exceeds your limit.");

            uint256 nodeId = (user[addy].lastCreated).add(1);
            nodes[addy][nodeId] = Node({
                id: nodeId,
                amount: amt,
                name: name,
                description: desc,
                created: block.timestamp,
                timestamp: block.timestamp,
                reward: dailyReward.reward
            });

            totalNodes += amt;
            user[addy].created += amt;
            user[addy].nodePools += 1;
            user[addy].lastCreated = nodeId;
        }
    }

    function claimEarnings() external {
        require(!nodesPaused, "Nodes are currently paused.");

        uint256 totalClaim;
        for (uint256 i = 1; i < user[msg.sender].nodePools + 1; i++) {
            uint256 reward = nodeEarned(msg.sender, i);
            uint256 totalReward = reward.mul(nodes[msg.sender][i].amount);

            nodes[msg.sender][i].reward = dailyReward.reward;
            nodes[msg.sender][i].timestamp = block.timestamp;

            totalClaim += totalReward;
        }

        nodesToken.transfer(msg.sender, totalClaim);
    }

    function setNodesLimit(uint256 limit) external onlyOwner {
        nodesLimit = limit;
    }

    function updateDailyReward(uint256 reward) external onlyOwner {
        dailyReward.reward = reward.mul(1*10**tokenDecimals);
        dailyReward.updated = block.timestamp;
    }

    function updateNodeCost(uint256 cost) external onlyOwner {
        nodeCost = cost.mul(1*10**tokenDecimals);
    }

    function setNodeFee(uint256 fee) external onlyOwner {
        nodeFee = fee;
    }

    function setNodesPaused(bool onoff) external onlyOwner {
        nodesPaused = onoff;
    }

    function emergencyWithdrawToken(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function emergencyWithdrawTokenAmount(IERC20 token, uint256 amount) external onlyOwner() {
        token.transfer(msg.sender, amount);
    }

    function setFeeAddress(address addr) external onlyOwner {
        _feeAddress = addr;
    }

    /**
     * @dev This function is in case of a relaunch or something of that sort.
     */
    function updateNodesToken(IERC20 token, uint256 decimals) external onlyOwner {
        nodesToken = token;
        tokenDecimals = decimals;
    }
}