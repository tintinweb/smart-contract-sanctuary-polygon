/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @title HOPE
 * @author 0xSumo
 */

/// OwnControll by 0xSumo
abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

abstract contract FxBaseChildTunnel is IFxMessageProcessor {

    event MessageSent(bytes message);
    address public fxChild;
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal virtual;
}

/**
 * @title Point Database
 * @author 0xSumo
 *
 * Description:
 * This smart contract implements a simple point system that can serve as a 
 * foundation for a variety of applications.
 *
 * Features:
 * - Increase points for a specific address
 * - Decrease points from a specific address
 * - Transfer points from one address to another
 *
 * Note:
 * This contract does not include any tokenization features or integrations 
 * with ERC standards. Points do not represent a form of currency or value 
 * outside of the specific system in which they are used. Please ensure 
 * legal compliance in your jurisdiction when using this contract.
 */

abstract contract PointDatabase {

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function _increasePoints(address address_, uint256 amount_) internal {
        balanceOf[address_] += amount_;
    }

    function _decreasePoints(address address_, uint256 amount_) internal {
        balanceOf[address_] -= amount_;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        require(msg.sender == from_, "Only the sender can transfer points");
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }
}

contract HOPE is PointDatabase, FxBaseChildTunnel, OwnControll {

    address public constant NTP = 0x334dB376ccBFfa66c0C1C7901Ab55915D1101D78;
    address public constant ROARS = 0x8762Cafe946Ccd1F2Ca29ae5693dA66E62e50A7D;

    uint256 public NTPRATE = 20 ether; //testing 1 per 7.2 min
    uint256 public ROARSRATE = 1 ether; //testing 1 per 14.4 min

    /// user => collection => amount
    mapping(address => mapping(address => uint256)) public stakedBalanceByUser;
    mapping(address => mapping(address => uint256)) public hopeAccumulatedByUser;
    mapping(address => mapping(address => uint256)) public lastUpdatedByUser;

    event ProcessedMessage(address from, address collection, uint256 amount, bool action);

    constructor() FxBaseChildTunnel(0xCf73231F28B7331BBe3124B907840A94851f9f11) {}

    /// fxbasechild polygon 0x8397259c983751DAf40400790063935a11afa28a
    /// fxbasechild mumbai 0xCf73231F28B7331BBe3124B907840A94851f9f11

    /// point system
    function increasePoints(address address_, uint256 amount_) external onlyAdmin("GET") {
        _increasePoints(address_, amount_);
    }

    function decreasePoints(address address_, uint256 amount_) external onlyAdmin("LOSE") {
        _decreasePoints(address_, amount_);
    }

    /// collect points
    function collectHOPE() external updateReward(msg.sender) {
        uint256 n = hopeAccumulatedByUser[msg.sender][NTP];
        uint256 r = hopeAccumulatedByUser[msg.sender][ROARS];
        uint256 amount = n + r;
        hopeAccumulatedByUser[msg.sender][NTP] = 0;
        hopeAccumulatedByUser[msg.sender][ROARS] = 0;
        _increasePoints(msg.sender, amount);
    }

    /// owner setting
    function setNTPRATE(uint256 reward) external onlyOwner {
        NTPRATE = reward;
    }

    function setROARSRATE(uint256 reward) external onlyOwner {
        ROARSRATE = reward;
    }

    function updateFxRootTunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }

    /// internal staking logic
    modifier updateReward(address account) {
        uint256 ntpAmount = earnedNTP(account);
        uint256 roarsAmount = earnedROARS(account);
    
        lastUpdatedByUser[account][NTP] = block.timestamp;
        hopeAccumulatedByUser[account][NTP] += ntpAmount;

        lastUpdatedByUser[account][ROARS] = block.timestamp;
        hopeAccumulatedByUser[account][ROARS] += roarsAmount;
    
        _;
    }


    function processStake(address account, address collection, uint256 amount) internal updateReward(account) {
        stakedBalanceByUser[account][collection] += amount;
    }

    function processUnstake(address account, address collection, uint256 amount) internal updateReward(account) {
        uint256 totalStaked = stakedBalanceByUser[account][collection];
        if (amount == totalStaked) {
            hopeAccumulatedByUser[account][collection] = 0;
        } else {
            uint256 percentageUnstaked = amount * 1e18 / totalStaked; // Calculate the percentage being unstaked (in Wei for precision)
            uint256 rewardReduction = hopeAccumulatedByUser[account][collection] * percentageUnstaked / 1e18; // Calculate the amount of rewards to reduce
            hopeAccumulatedByUser[account][collection] -= rewardReduction;
        }
        stakedBalanceByUser[account][collection] -= amount;
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal override validateSender(sender) {
        (address from, address collection, uint256 count, bool action) 
        = abi.decode(message, (address, address, uint256, bool));
        action ? processStake(from, collection, count) : processUnstake(from, collection, count);
        emit ProcessedMessage(from, collection, count, action);
    }

    /// utilities
    function getUserAccruedRewards(address account) external view returns (uint256) {
        return hopeAccumulatedByUser[account][NTP] + hopeAccumulatedByUser[account][ROARS] + earnedNTP(account) + earnedROARS(account);
    }

    function earnedNTP(address account) internal view returns (uint256) {
        return rewardsPerSecondNTP(account) * (block.timestamp - lastUpdatedByUser[account][NTP]);
    }

    function earnedROARS(address account) internal view returns (uint256) {
        return rewardsPerSecondROARS(account) * (block.timestamp - lastUpdatedByUser[account][ROARS]);
    }

    function rewardsPerSecondNTP(address account) internal view returns (uint256) {
        return (stakedBalanceByUser[account][NTP] * NTPRATE) / 1 days;
    }

    function rewardsPerSecondROARS(address account) internal view returns (uint256) {
        return (stakedBalanceByUser[account][ROARS] * ROARSRATE) / 1 days;
    }
}