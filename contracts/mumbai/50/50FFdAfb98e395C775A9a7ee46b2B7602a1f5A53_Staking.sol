/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract Staking is Ownable {
    using Counters for Counters.Counter;

    // Authority Node Staking

    struct DepositInfo {
        address user;
        uint256 updateTime;
        uint256 depositAmount;
        uint256 ratePerSec; //deciminal is 18
    }

    event Deposit(
        address user,
        uint256 amount,
        uint256 rate,
        uint256 depositTime
    );
    event Withdraw(address user, uint256 amount, uint256 leftAmount);
    event GetReward(address user, uint256 amount, uint256 updateTime);

    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public deposits;
    mapping(address => DepositInfo) public rateinfo;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public authorities;

    uint256 public totalDeposit = 0;
    uint256 public totalWithdraw = 0;

    constructor() payable {
        authorities[msg.sender] = true;
    }

    modifier onlyAuthorities() {
        require(authorities[msg.sender], "Only authorities are allowed");
        _;
    }

    function earn(address user) public view returns (uint256) {
        DepositInfo memory info = rateinfo[user];
        uint256 reward = ((block.timestamp - info.updateTime) *
            info.depositAmount *
            info.ratePerSec) / 1e18;

        return rewards[msg.sender] + reward;
    }

    function deposit() public payable onlyAuthorities {
        uint256 rate = 2000;
        DepositInfo memory oldInfo = rateinfo[msg.sender];
        uint256 earned = earn(msg.sender);

        DepositInfo memory newInfo = DepositInfo(
            msg.sender,
            block.timestamp,
            msg.value + oldInfo.depositAmount,
            (rate * 1e18) / 1e5 / (365 * 24 * 60 * 60)
        );

        rewards[msg.sender] += earned;
        rateinfo[msg.sender] = newInfo;

        deposits[msg.sender] += msg.value;
        totalDeposit += msg.value;
        nonces[msg.sender]++;
        emit Deposit(msg.sender, msg.value, rate, block.timestamp);
    }

    function getReward(uint256 amount) public onlyAuthorities {
        DepositInfo storage info = rateinfo[msg.sender];

        uint256 diff = block.timestamp - info.updateTime;
        uint256 reward = (diff * info.depositAmount * info.ratePerSec) / 1e18;
        info.updateTime = block.timestamp;
        rewards[msg.sender] += reward;

        require(rewards[msg.sender] >= amount, "reward not enough");

        rewards[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to get reward");

        emit GetReward(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 amount) public onlyAuthorities {
        DepositInfo storage info = rateinfo[msg.sender];

        require(info.depositAmount != 0, "already withdraw");
        require(info.depositAmount >= amount, "not enough to withdraw");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw");

        totalDeposit -= amount;
        totalWithdraw += amount;
        info.depositAmount -= amount;
        emit Withdraw(msg.sender, amount, info.depositAmount);
    }

    // Regional Node Staking

    struct UserStaking {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 stakingAmount;
        uint256 withdrawn;
    }

    Counters.Counter public regionCount;
    struct Region {
        uint256 id;
        string name;
        uint256 stakingAmount;
        uint256 percentageRate; // Divide by 10_000
        uint256 stakingPeriodSeconds;
    }
    mapping(uint256 => Region) public regions;
    mapping(uint256 => mapping (address => mapping (uint256 => UserStaking))) public regionUserStakings;
    mapping(uint256 => mapping (address => Counters.Counter)) public regionUserStakingCount;

    event regionCreated(uint256 id);
    event stakingCreated(address owner, uint256 regionId, uint256 stakingAmount, uint256 id);
    event stakingWithdrawn(address owner, uint256 regionId, uint256 stakingAmount, uint256 id);

    function createRegion(
        string memory name,
        uint256 percentageRate,
        uint256 stakingPeriodSeconds
    ) public onlyOwner returns (uint256) {
        regionCount.increment();
        uint256 newId = regionCount.current();

        regions[newId] = Region({
            id: newId,
            name: name,
            stakingAmount: 0,
            percentageRate: percentageRate,
            stakingPeriodSeconds: stakingPeriodSeconds
        });

        emit regionCreated(newId);

        return newId;
    }

    function stake(
        uint256 regionId
    ) public payable returns (bool) {
        uint256 stakingAmount = msg.value;
        require(stakingAmount > 0, "Must stake more than 0");

        regions[regionId].stakingAmount += msg.value;
        regionUserStakingCount[regionId][msg.sender].increment();

        uint256 newId = regionUserStakingCount[regionId][msg.sender].current();

        regionUserStakings[regionId][msg.sender][newId] = UserStaking({
            id: newId,
            startTime: block.timestamp,
            endTime: block.timestamp + regions[regionId].stakingPeriodSeconds,
            stakingAmount: stakingAmount,
            withdrawn: 0
        });

        emit stakingCreated(msg.sender, regionId, msg.value, newId);

        return true;
    }

    function withdrawStaking(
        uint256 regionId,
        uint256 regionUserStakingId
    ) public returns (bool) {
        require(block.timestamp >= regionUserStakings[regionId][msg.sender][regionUserStakingId].endTime, "Staking is not ready");

        uint256 toWithdraw = regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount * (10000 + regions[regionId].percentageRate) / 10000;

        (bool success, ) = msg.sender.call{
            value: toWithdraw
        }("");
        require(success, "Failed to withdraw staking");

        regionUserStakings[regionId][msg.sender][regionUserStakingId].withdrawn = toWithdraw;
        regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount = 0;

        emit stakingWithdrawn(
            msg.sender,
            regionId,
            regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount,
            regionUserStakingId
        );

        return true;
    }
}