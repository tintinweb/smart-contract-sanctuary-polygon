pragma solidity ^0.8;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingRewards is Ownable{

    MyIERC20 private _stakingToken;

    uint private _maxReward;
    uint private _totalStaked;
    uint private _rewardTobePaid;
    Pool[] public pools;
    mapping(uint => mapping(address => uint)) public stakes;

    using Counters for Counters.Counter;
    Counters.Counter private _poolIds;
    Counters.Counter private _stakeIds;

    struct Pool {
        uint poolId;
        string name;
        uint startTime;
        uint endTime;
        uint returnTime;
        uint capacity;
        uint rewardRate; // rewardRate is real reward rate * 1e10
        uint rewardApy;
        uint currentAmount;
        bool isValid;
    }

    event PoolCreated(uint poolId, string name, uint startTime, uint endTime, uint returnTime, uint capacity, uint rewardRate, uint rewardApy);
    event PoolDeleted(uint poolId);
    event Staked(address account, uint poolId, uint amount);
    event Withdrawed(address account, uint poolId, uint amount);

    constructor(address stakingToken) {
        _stakingToken = MyIERC20(stakingToken);
    }

    function getPoolsize() external view returns (uint) {
        return _poolIds.current();
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getBalance() public view onlyOwner returns (uint) {
        return _stakingToken.balanceOf(address(this));
    }

    function getMaxReward() external view onlyOwner returns (uint) {
        return _maxReward;
    }

    function getTotalStaked() external view returns (uint) {
        return _totalStaked;
    }

    function getRewardTobePaid() external view onlyOwner returns (uint) {
        return _rewardTobePaid;
    }

    function setMaxReward(uint maxReward) external onlyOwner{
        // should transfer token first, then ser maxReward
        require(maxReward <= getBalance() - _totalStaked -_rewardTobePaid, "balance not enough, please add balance first");
        require(maxReward >= _rewardTobePaid, "cannot be less than rewardTobePaid");
        _maxReward = maxReward;
    }

    // rewardRate is real reward rate * 1e10
    function addPool(string calldata name, uint startTime, uint endTime, uint returnTime, uint capacity, uint rewardRate, uint rewardApy) external onlyOwner{
        uint maxPoolReward = capacity / 1e10 * rewardRate / 100; 
        require(_rewardTobePaid + maxPoolReward <= _maxReward, "Reward exceeds maxReward");
        uint poolId = _poolIds.current();
        pools.push(Pool(poolId, name, startTime, endTime, returnTime, capacity, rewardRate, rewardApy, 0, true));
        _poolIds.increment();
        emit PoolCreated(poolId, name, startTime, endTime, returnTime, capacity, rewardRate, rewardApy);
    }

    function stake(uint amount, uint poolId) external{
        require(_stakingToken.allowance(msg.sender, address(this)) >= amount, "allowance not enough");
        require(pools[poolId].isValid, "poolId does not exist.");
        require(pools[poolId].currentAmount + amount <= pools[poolId].capacity, "Exceed capacity");
        require(pools[poolId].startTime <= block.timestamp * 1000, "staking does not start in this pool");
        require(pools[poolId].endTime > block.timestamp * 1000, "staking has ended in this pool");
        _totalStaked += amount;

        stakes[poolId][msg.sender] += amount;

        pools[poolId].currentAmount += amount; 
        _rewardTobePaid += (amount / 1e10 * pools[poolId].rewardRate / 100);
        _stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, poolId, amount);
    }

    function withdraw(uint amount, uint poolId) external {
        require(pools[poolId].returnTime <= block.timestamp * 1000, "return time does not reach");
        require(amount <= stakes[poolId][msg.sender], "Withdraw amount exceeds staked amount");

        uint reward = amount / 1e10 * pools[poolId].rewardRate / 100; 
        _totalStaked -= amount;

        stakes[poolId][msg.sender] -= amount;

        pools[poolId].currentAmount -= amount; 
        if(pools[poolId].currentAmount == 0) {
            pools[poolId].isValid = false;
            emit PoolDeleted(poolId);
        }
        _rewardTobePaid -= reward;
        _stakingToken.transfer(msg.sender, amount + reward);
        emit Withdrawed(msg.sender, poolId, amount);
    }
}

interface MyIERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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