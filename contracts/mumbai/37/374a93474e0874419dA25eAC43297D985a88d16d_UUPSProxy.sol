// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

interface StakingInterface {
    struct MainNodeInfo {
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 totalLightNodes;
        uint256 rate;            // rate for APR base is 10000
        uint256 commissionRate;  // commission rate of main node 
        bool isStopped;
        bool isUsed;
    }

    struct LightNodeInfo {
        uint256 mainNodeId;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 totalUsers;
        uint256 registerTime;
        uint256 commissionRate;
        address ownerAddress;
        bool isStopped;
        bool isUsed;
    }

    struct StakeInfo {
        uint256 lightNodeId;
        uint256 updateTime;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 unstakeCount;
        address referee; 
        bool isUsed;
    }

    struct UnstakeInfo {
        uint256 timestamp;
        uint256 amount;
        bool isClaimed;
        bool isUsed;
    }

    event NewUser(address indexed user, uint256 lightId, uint256 mainId, address referee, uint256 timestamp);
    event Staked( address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 rate, uint256 timestamp);
    event Unstaked(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 leftAmount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 leftAmount);
    event RewardClaimed(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 amount, uint256 timestamp);
    event NewStakeRate(uint256 nodeId, uint256 oldRate, uint256 newRate);
    event NewMainNodeCommission(uint256 nodeId, uint256 oldRate, uint256 rate);
    event NewLightNodeCommission(uint256 nodeId, uint256 oldRate, uint256 rate);
    event NewMainNode(uint256 id, uint256 timestamp);
    event NewLightNode(uint256 id, uint256 mainId, address owner, uint256 timestamp);
    event ReferRewardSet(uint256 batchNo);
    event ReStaked(address indexed account, uint256 indexed lightNodeId, uint256 indexed mainNodeId, uint256 reward, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./StakingInterface.sol";

contract UUPSProxy is StakingInterface {
    address public implementation;
    address public admin;
    mapping (uint256 => MainNodeInfo) public mainNodeInfo;  // node id -> info
    mapping (uint256 => LightNodeInfo) public lightNodeInfo; // node id -> info
    mapping (address => uint256) public ownerLightNodeId; // owner address -> node id
    mapping (address => StakeInfo) public stakeInfo; // address -> stake info
    mapping (address => uint256) public referRewards; // address -> refer award 
    mapping (address => bool) public lightNodeBlacklist; // address -> refer award 
    mapping (uint256 => mapping(address => uint256)) public dynamicReward; // date -> (address -> award) 
    mapping (address => uint256) public firstDynamicRecord; // address -> date 
    mapping (address => uint256) public dynamicRewardClaimed; // address -> amount claimed
    mapping(address => UnstakeInfo[]) public unstakeInfo; // user -> unstakeInfo 

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;  // seconds per day
    uint256 constant DEFAULT_RATE = 10000;  // default APR rate 
    uint256 public currentTotalStaked;  // current total staked in the contract
    uint256 public currentTotalReward;  // current total reward available for claiming
    uint256 public totalStaked;     // total staked amount (including unstaked)
    uint256 public totalReward;     // total reward generated (inlcuding claimed)
    uint256 public totalUnstaked;   // total unstaked 
    uint256 public totalRewardClaimed; // total reward claimed
    uint256 public stopLimit; // stop limit of light node 

    uint256 public mainNodeCap;     // staking cap for every main node  
    uint256 public currentMainNodeIndex; // start from 1
    uint256 public currentLightNodeIndex; // start from 1
    uint256 public initTime; // init time for staking 

    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
        currentMainNodeIndex = 1;
        currentLightNodeIndex = 1;
        stopLimit = 1000;
        mainNodeCap = 8_500_000* 1 ether;
        initTime = 1680278400; // since April 1st
    }

    receive() external payable {}

    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
        if (!success) {
            _revertWithData(data);
        }
        _returnWithData(data);
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}