// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./OwnerPausable.sol";

contract StakingReward is OwnerPausable {

    struct UserInfo {
        uint256 amount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
        uint256 lastRewardBlock;
        uint256 level; //0-18%
        uint256 firstOrderEndedBlock;
    }

    struct OrderInfo {
        uint256 index;
        uint256 addedBlock;
        uint256 amount;
    }

    struct LevelApy {
        uint256 startBlock;
        uint256 rewardPerBlock;
    }

    address private _privatePlacementAddress;

    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**18;

    uint256 public constant RELEASE_CYCLE = 5 minutes;
    uint256 public constant RELEASE_CYCLE_TIMES = 6;

    uint256 private immutable SECONDS_PER_BLOCK;
    uint256 public immutable BASE_REWARD_PER_BLOCK; //1%的apy 1个区块的奖励
    uint256[] private apy = [18, 20, 28, 35, 60] ;
    mapping(address => UserInfo) private _userInfo;
    mapping(address => OrderInfo[]) private _orders;
    //mapping(uint256 => LevelApy[]) private apy;
    

    constructor(address owner, uint256 secondsPerBlock) OwnerPausable(owner) {
        SECONDS_PER_BLOCK = secondsPerBlock;
        BASE_REWARD_PER_BLOCK = secondsPerBlock*PRECISION_FACTOR/365 days/100;
    }

    modifier onlyPP() {
        require(msg.sender == _privatePlacementAddress, "not PrivatePlacement");
        _;
    }


    function setPrivatePlacementAddress(address privatePlacementAddress_) external onlyOwner{
        _privatePlacementAddress = privatePlacementAddress_;
    }

    function privatePlacementAddress() external view returns(address){
        return _privatePlacementAddress;
    }

    function deposit(address staker, uint256 amount) external onlyPP {
        
    }

    function updateUserLevel(address user, uint256 level) external {
        _userInfo[user].level = level;
    }

    function depositMock(uint256 index, uint256 amount) external {
        address staker = msg.sender;
        UserInfo storage user = _userInfo[staker];
        OrderInfo[] storage userOrders = _orders[staker];

        //发放已有收益
        if (_userInfo[staker].amount > 0) {
            uint256 pendingRewards;
            for (uint256 i; i < _orders[staker].length; i++) {
                uint256 multiplier = _getMultiplier(user.lastRewardBlock, block.number, 
                        userOrders[i].addedBlock+RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK);
                pendingRewards += userOrders[i].amount*multiplier*apy[user.level]*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
            }
            user.rewardDebt += pendingRewards;
        }

        //记录新记录
        user.amount += amount;
        user.lastRewardBlock = block.number;
        userOrders.push(OrderInfo(index, block.number, amount));
    }

    function calculatePendingRewards(address staker) external view returns(uint256, uint256 ) {
        UserInfo memory user = _userInfo[staker];
        OrderInfo[] memory userOrders = _orders[staker];
        uint256 pendingRewards;
        if (_userInfo[staker].amount > 0) {
            for (uint256 i; i < _orders[staker].length; i++) {
                uint256 multiplier = _getMultiplier(user.lastRewardBlock, block.number, 
                        userOrders[i].addedBlock+RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK);
                pendingRewards += _orders[staker][i].amount*multiplier*apy[user.level]*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
            }
        }
        return (user.rewardDebt, pendingRewards);
    }

    function calculateWithdrawBack(address staker) external view returns(uint256[] memory) {
        OrderInfo[] memory userOrders = _orders[staker];
        uint256[] memory result = new uint256[](userOrders.length);
        if (_userInfo[staker].amount > 0) {
            for (uint256 i; i < userOrders.length; i++) {
                uint256 period = (block.number - userOrders[i].addedBlock)/(RELEASE_CYCLE/SECONDS_PER_BLOCK);
                if (period > 0) {
                    result[i] = userOrders[i].amount*period/RELEASE_CYCLE_TIMES;
                }
            }
        }
        return result;
    }


    function userInfo(address staker) external view returns(UserInfo memory) {
        return _userInfo[staker];
    }

    function orders(address staker) external view returns(OrderInfo[] memory) {
        return _orders[staker];
    }

    function claim() external {
        address staker = msg.sender;
        _userInfo[staker].lastRewardBlock = block.number;
    }

     function withdraw() external {
        address staker = msg.sender;
        _userInfo[staker].lastRewardBlock = block.number;
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to, uint256 endBlock) internal pure returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";

contract OwnerPausable is Pausable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    address private _candidate;
    address private _operator;

    
    constructor(address owner_) {
        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(_owner == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(_operator == msg.sender || _owner == msg.sender, "Ownable: caller is not the operator or owner");
        _;
    }

    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }


    function candidate() public view returns (address) {
        return _candidate;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner zero address");
        require(newOwner != _owner, "newOwner same as original");
        require(newOwner != _candidate, "newOwner same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "candidate is zero address");
        require(_candidate == _msgSender(), "not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}