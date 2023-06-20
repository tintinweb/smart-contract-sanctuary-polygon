/**
 *Submitted for verification at polygonscan.com on 2023-06-20
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

    uint256 public yieldEndTime = 2222222222;
    uint256 public yieldRatePerTokenNTP = 20 ether;
    uint256 public yieldRatePerTokenROARS = 10 ether;

    mapping(address => mapping(address => uint256)) public stakedTokens;
    mapping(address => mapping(address => uint256)) public lastClaimedTimestamp;
    
    event Claim(address to_, uint256 totalClaimed_);
    event ProcessedMessage(address from, address collection, uint256 count, bool action);

    constructor() FxBaseChildTunnel(0xCf73231F28B7331BBe3124B907840A94851f9f11) {}

    /// fxbasechild polygon 0x8397259c983751DAf40400790063935a11afa28a
    /// fxbasechild mumbai 0xCf73231F28B7331BBe3124B907840A94851f9f11

    /// Admin setting
    function setYieldEndTime(uint256 yieldEndTime_) external onlyAdmin("ADMIN") { 
        yieldEndTime = yieldEndTime_; 
    }

    function setYieldRatePerTokenNTP(uint256 yieldRatePerTokenNTP_) external onlyAdmin("ADMIN") { 
        yieldRatePerTokenNTP = yieldRatePerTokenNTP_; 
    }

    function setYieldRatePerTokenROARS(uint256 yieldRatePerTokenROARS_) external onlyAdmin("ADMIN") { 
        yieldRatePerTokenROARS = yieldRatePerTokenROARS_; 
    }

    function increasePoints(address address_, uint256 amount_) external onlyAdmin("INCREASE") {
        _increasePoints(address_, amount_);
    }

    function decreasePoints(address address_, uint256 amount_) external onlyAdmin("DECREASE") {
        _decreasePoints(address_, amount_);
    }

    /// HOPE
    function increaseAll() external {
        uint256 _pendingPointsNTP = getPendingPoints(msg.sender, NTP);
        uint256 _pendingPointsROARS = getPendingPoints(msg.sender, ROARS);
        _updateTimestamp(msg.sender, NTP);
        _updateTimestamp(msg.sender, ROARS);
        _increasePoints(msg.sender, _pendingPointsNTP + _pendingPointsROARS);
        emit Claim(msg.sender, _pendingPointsNTP + _pendingPointsROARS);
    }

    /// Staking internal logic
    function processStake(address account, address collection, uint256 amount) internal {
        if(collection == NTP) {
            processStakeNTP(account, amount);
            _updateTimestamp(msg.sender, collection);
        } else if(collection == ROARS) {
            processStakeROARS(account, amount);
            _updateTimestamp(msg.sender, collection);
        }
    }

    function processUnstake(address account, address collection, uint256 amount) internal {
        if(collection == NTP) {
            processUnstakeNTP(account, amount);
        } else if(collection == ROARS) {
            processUnstakeROARS(account, amount);
        }
    }

    function processStakeNTP(address account, uint256 amount) internal {
        stakedTokens[account][NTP] += amount;
    }

    function processStakeROARS(address account, uint256 amount) internal {
        stakedTokens[account][ROARS] += amount;
    }

    function processUnstakeNTP(address account, uint256 amount) internal {
        stakedTokens[account][NTP] -= amount;
    }

    function processUnstakeROARS(address account, uint256 amount) internal {
        stakedTokens[account][ROARS] -= amount;
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal override validateSender(sender) {
        (address from, address collection, uint256 count, bool action) 
        = abi.decode(message, (address, address, uint256, bool));
        action ? processStake(from, collection, count) : processUnstake(from, collection, count);
        emit ProcessedMessage(from, collection, count, action);
    }

    function _updateTimestamp(address account, address tokenAddress) internal {
        lastClaimedTimestamp[account][tokenAddress] = block.timestamp;
    }

    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? block.timestamp : yieldEndTime;
    }

    /// Pending HOPE
    function getPendingPoints(address account, address tokenAddress) public view returns (uint256) {
        uint256 _lastClaimedTimestamp = lastClaimedTimestamp[account][tokenAddress];
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        uint256 yieldRate = tokenAddress == NTP ? yieldRatePerTokenNTP : yieldRatePerTokenROARS;
        return (_timeElapsed * yieldRate * stakedTokens[account][tokenAddress]) / 1 days;
    }
}