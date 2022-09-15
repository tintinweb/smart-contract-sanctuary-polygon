// SPDX-License-Identifier: MIT
/// @dev size: 12.285 Kbytes
pragma solidity 0.8.4;
/*
# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)
*/

import "../security/ReentrancyGuard.sol";
import "../security/Ownable.sol";

import "../utils/NonZeroAddressGuard.sol";
import "./VotingStorage.sol";

contract VotingEscrow is VotingStorage, Ownable, ReentrancyGuard, NonZeroAddressGuard {

    event Deposited(address indexed provider, uint256 value, uint256 lockTime);
    event IncreasedAmount(address indexed provider, uint256 amount);
    event IncreasedTime(address indexed provider, uint256 time);
    event Withdrawn(address indexed provider, uint256 value);

    /// @notice An event that's emitted when an account changes their delegate
    event DelegateChanged(address indexed delegator, address indexed delegatee);

    /// @notice An event that's emitted when an smart wallet Checker is changed
    event SmartWalletCheckedChanged(address oldChecker, address newChecker);


    modifier onlyLockOwner(address addr) {
        require(locks[addr].owner == addr, "only owner can call this function");
        _;
    }

    modifier onlyAllowed(address addr) {
        isAllowed(addr);
        _;
    }

    function isAllowed(address addr) internal view {
        if (addr != tx.origin) {
            require(smartWalletChecker.check(addr), "Smart contract depositors not allowed");
        }
    }

    constructor(IERC20 amptToken_, SmartWalletChecker smartWalletChecker_, string memory name_, string memory symbol_) {
        amptToken = amptToken_;
        smartWalletChecker = smartWalletChecker_;

        name = name_;
        symbol = symbol_;

        pointHistory[0].block = getBlockNumber();
        pointHistory[0].ts = getBlockTimestamp();
    }


    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of tokens owner by `addr`.
    */
    function locked(address addr) external view returns (Lock memory) {
        return locks[addr];
    }

    function changeSmartWalletChecker(SmartWalletChecker newSmartWalletChecker) external onlyOwner nonZeroAddress(address(newSmartWalletChecker)) {
        SmartWalletChecker currentWalletChecker = smartWalletChecker;
        require(newSmartWalletChecker != currentWalletChecker, "New smart wallet checker is the same as the old one");
        smartWalletChecker = newSmartWalletChecker;
        emit SmartWalletCheckedChanged(address(currentWalletChecker), address(newSmartWalletChecker));
    }

    /**
     * @notice Get the current voting power for `msg.sender`
     * @param addr User wallet address
     * @return User voting power
    */
    function balanceOf(address addr) external view returns (uint256) {
        uint256 _votePower;
        Lock memory lock = locks[addr];
        
        // User have locked tokens
        if(lock.amount != 0 && userOwnsTheLock(lock, addr)) {
            _votePower = balanceOfOneLock(addr);
        }

        // User have delegated tokens
        uint256 delegationLegth = delegations[addr].length;
        if(delegationLegth != 0) {
            for(uint256 i = 0; i < delegationLegth; i++) {
                _votePower += balanceOfOneLock(delegations[addr][i]);
            }
        }
        return _votePower;
    }

    function userOwnsTheLock(Lock memory _lock, address lockOwner) internal pure returns (bool) {
        return _lock.owner == lockOwner && _lock.delegator == address(0);
    }

    function balanceOfOneLock(address addr) internal view returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        uint256 ts = getBlockTimestamp();

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _point = userPointHistory[addr][_epoch];
            _point.bias -= _point.slope * int256(ts - _point.ts);

            if (_point.bias < 0) {
                _point.bias = 0;
            }
            return uint256(_point.bias);
        }
    }

    /**
     * @notice Calculate total voting power
     * @return Total voting power
    */
    function totalSupply() external view returns (uint256) {
        return supplyAt(getBlockTimestamp());
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param block_ Block to calculate the total voting power at
     * @return Total voting power ar `block`
    */
    function totalSupplyAt(uint256 block_) external view returns (uint256) {
        uint256 currentTimestamp = getBlockTimestamp();
        uint256 currentBlock = getBlockNumber();

        require(currentBlock >= block_, "Block must be in the past");
        
        uint256 _targetEpoch = findBlockEpoch(block_, epoch);
        Point memory point = pointHistory[_targetEpoch];
        uint256 dt;

        if (epoch > _targetEpoch) {
            Point memory nextPoint = pointHistory[_targetEpoch + 1];
            if (point.block != nextPoint.block) {
                dt = (block_ - point.block) * (nextPoint.ts - point.ts) / (nextPoint.block - point.block);
            }
        } else if (point.block != currentBlock) {
            dt = (block_ - point.block) * (currentTimestamp - point.ts) / (currentBlock - point.block);
        }

        return supplyAt(point.ts + dt);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param timestamp Time to calculate the total voting power at
     * @return Total voting power at that time
    */
    function supplyAt(uint256 timestamp) internal view returns (uint256) {
        Point memory point = pointHistory[epoch];
        uint256 timeIndex = point.ts * WEEK / WEEK;

        for(int256 i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > timestamp) {
                timeIndex = timestamp;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            point.bias -= point.slope * int256(timeIndex - point.ts);
            if (timeIndex == timestamp) {
                break;
            }
            point.slope += dSlope;
            point.ts = timeIndex;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }
        return uint256(point.bias);
    }

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param block_ Block to find
     * @param epoch_ Don't go beyond this epoch
     * @return Approximate timestamp for block
    */
    function findBlockEpoch(uint256 block_, uint256 epoch_) internal view returns (uint256)  {
        uint256 _min;
        uint256 _max = epoch_;
        for(int256 i=0; i <= 128; i++) {
            if (_min >= _max) break;

            uint256 _mid = (_min + _max + 1) / 2;

            if (pointHistory[_mid].block <= block_) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /**
     * @notice Record global data to checkpoint
    */
    function checkpoint() external {
        RewardEntry[] memory rewardEntries;
        Lock memory emptyLock = Lock(0, 0, address(0), address(0), rewardEntries);
        checkpointInternal(address(0), emptyLock, emptyLock);
    }

    /**
     * @notice Deposit `value` tokens for `msg.sender` and lock until `unlockTime`
     * @param value Amount to deposit
     * @param unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    */
    function createLock(uint256 value, uint256 unlockTime) external {
        createLockInternal(msg.sender, value, unlockTime);
    }

    function createLockInternal(address depositer, uint256 value, uint256 unlockTime) internal nonReentrant nonZeroAddress(depositer) {
        require(value != 0, "zero value");
        
        uint256 currentTime = getBlockTimestamp();
        require(unlockTime > currentTime, "unlock time is in the past");
        require(currentTime + MAXCAP >= unlockTime, "lock can be 4 years max");

        Lock storage newLock = locks[depositer];
        require(newLock.amount == 0, "already locked");

        Lock memory oldLock = newLock;

        uint16 rate = getRateByPeriod(unlockTime - block.timestamp);
        RewardEntry memory rewardEntry = RewardEntry(
            block.timestamp,
            unlockTime,
            value,
            rate
        );

        newLock.rewardEntries.push(rewardEntry);
        newLock.amount = value;
        newLock.end = unlockTime;
        newLock.owner = depositer;
        newLock.delegator = address(0);

        totalLocked += value;

        // checkpoint for the lock here;
        checkpointInternal(depositer, oldLock, newLock);

        emit Deposited(depositer, value, unlockTime);
        assert(amptToken.transferFrom(depositer, address(this), value));
    }

    /**
     * @notice Deposit `value` additional tokens for `msg.sender` without modifying the unlock time
     * @param value Amount of tokens to deposit and add to the lock
    */
    function increaseLockAmount(uint256 value) external onlyLockOwner(msg.sender) {
        increaseLockAmountInternal(msg.sender, value);
    }

    function increaseLockAmountInternal(address depositer, uint256 value) internal nonReentrant {
        require(value != 0, "zero value");

        Lock storage lock = locks[depositer];
        require(lock.end > getBlockTimestamp(), "lock has expired. Withdraw");

        uint16 rate = getRateByPeriod(lock.end - block.timestamp);
        RewardEntry memory rewardEntry = RewardEntry(
            block.timestamp,
            lock.end,
            value,
            rate
        );
        Lock memory oldLock = lock;
        lock.amount += value;
        lock.rewardEntries.push(rewardEntry);
        totalLocked += value;

        // checkpoint for the lock here;
        checkpointInternal(depositer, oldLock, lock);

        emit IncreasedAmount(depositer, value);
        assert(amptToken.transferFrom(depositer, address(this), value));
    }

    /**
     * @notice Extend the unlock time for `msg.sender` to `unlockTime`
     * @param newLockTime New epoch time for unlocking
    */
    function increaseLockTime(uint256 newLockTime) external onlyLockOwner(msg.sender) {
        increaseLockTimeInternal(msg.sender, newLockTime);
    }

    function increaseLockTimeInternal(address depositer, uint256 newLockTime) internal nonReentrant {
        uint256 currentTimestamp = getBlockTimestamp();
        require(currentTimestamp + MAXCAP >= newLockTime, "lock can be 4 years max");

        Lock storage lock = locks[depositer];
        require(lock.end > currentTimestamp, "lock has expired. Withdraw");
        require(newLockTime > lock.end, "lock time lower than expiration");

        Lock memory oldLock = lock;
        lock.end = newLockTime;

        // Extend the reward end time and find the new rate
        for (uint i = 0; i < lock.rewardEntries.length; i++) {
            RewardEntry storage entry = lock.rewardEntries[i];
            uint16 newRate = getRateByPeriod(newLockTime - entry.start);
            entry.end = newLockTime;
            entry.rate = newRate;
        }

        // checkpoint for the lock here;
        checkpointInternal(depositer, oldLock, lock);

        emit IncreasedTime(depositer, newLockTime);
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
    */
    function withdraw() external onlyLockOwner(msg.sender) {
        withdrawInternal(msg.sender);
    }

    function withdrawInternal(address depositer) internal nonReentrant {
        Lock storage lock = locks[depositer];
        require(lock.end <= getBlockTimestamp(), "lock has not expired yet");

        uint256 rewardAmount = 0;
        for (uint i = 0; i < lock.rewardEntries.length; i++) {
            RewardEntry memory entry = lock.rewardEntries[i];
            rewardAmount += entry.amount * entry.rate / 10000;
        }
        require(rewardLocked >= rewardAmount, "not enough reward balance");
        
        Lock memory oldLock = lock;
        lock.amount = 0;
        lock.end = 0;
        delete lock.rewardEntries;

        totalLocked -= oldLock.amount;
        rewardLocked -= rewardAmount;

        // checkpoint for the lock here;
        checkpointInternal(depositer, oldLock, lock);

        emit Withdrawn(depositer, oldLock.amount);
        assert(amptToken.transfer(depositer, oldLock.amount + rewardAmount));
    }

    /**
     * @notice Deposit `value` tokens for `depositer` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but cannot extend their locktime and deposit for a brand new user
     * @param depositer User's wallet address
     * @param value Amount to add to user's lock
    */
    function depositFor(address depositer, uint256 value) external nonReentrant nonZeroAddress(depositer) {
        require(value != 0, "zero value");

        Lock storage _lock = locks[depositer]; 
        require(_lock.amount != 0, "no lock found");
        require(_lock.end > getBlockTimestamp(), "Cannot add to expired lock. Withdraw");

        Lock memory oldLock = _lock;
        _lock.amount += value;
        totalLocked += value;

        // checkpoint for the lock here;
        checkpointInternal(depositer, oldLock, _lock);

        emit IncreasedAmount(depositer, value);
        assert(amptToken.transferFrom(msg.sender, address(this), value));
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external onlyAllowed(msg.sender) {
        delegateInternal(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: invalid signature");

        require(nonce == nonces[signatory], "delegateBySig: invalid nonce");
        nonces[signatory]++;
        require(getBlockTimestamp() <= expiry, "delegateBySig: signature expired");

        delegateInternal(signatory, delegatee);
    }

    function delegateInternal(address delegator, address delegatee) internal nonReentrant {
        require(delegator != address(0), "Cannot delegate from the zero address");
        require(delegator != delegatee, "Cannot delegate to self");

        Lock storage delegatorLock = locks[delegator];
        require(delegatorLock.amount != 0, "No existing lock found");
        require(delegatorLock.delegator != delegatee, "Cannot delegate to the same address");

        address oldDelegatee = delegatorLock.delegator;
        uint256 delegateeIndex = delegationIndexInMap[oldDelegatee][delegator];
        if (delegatee == address(0)) {
            delete delegations[oldDelegatee][delegateeIndex];
            delete delegationIndexInMap[oldDelegatee][delegator];
        } else {
            if(oldDelegatee != address(0)) {
                delete delegations[oldDelegatee][delegateeIndex];
                delete delegationIndexInMap[oldDelegatee][delegator];
            }
            delegations[delegatee].push(delegator);
            delegationIndexInMap[delegatee][delegator] = delegations[delegatee].length - 1;
        }
        delegatorLock.delegator = delegatee;

        // checkpoint for the lock here;
        checkpointInternal(delegator, delegatorLock, delegatorLock);

        emit DelegateChanged(delegator, delegatee);
    }

    struct CheckPointVars {
        int256 oldDslope;
        int256 newDslope;
        uint256 epoch;
        uint256 block;
        uint256 ts;
        uint256 userEpoch;
    }
    /**
     * @notice Record global and per-user data to checkpoint
     * @param addr User's wallet address. No user checkpoint if 0x0
     * @param oldLock Previous locked amount / end lock time for the user
     * @param newLock New locked amount / end lock time for the user
    */
    function checkpointInternal(address addr, Lock memory oldLock, Lock memory newLock) internal {
        Point memory _userPointOld = Point(0, 0, 0, 0);
        Point memory _userPointNew = Point(0, 0, 0, 0);

        CheckPointVars memory _vars = CheckPointVars(
            0, 
            0, 
            epoch, 
            getBlockNumber(), 
            getBlockTimestamp(), 
            userPointEpoch[addr]
        );

        if (addr != address(0)) {
            if (oldLock.end > _vars.ts && oldLock.amount != 0) {
                _userPointOld.slope = int256(oldLock.amount / MAXCAP);
                _userPointOld.bias = _userPointOld.slope * int256(oldLock.end - _vars.ts);
            }

            if (newLock.end > _vars.ts && newLock.amount != 0) {
                _userPointNew.slope = int256(newLock.amount / MAXCAP);
                _userPointNew.bias = _userPointNew.slope * int256(newLock.end - _vars.ts);
            }

            _vars.oldDslope = slopeChanges[oldLock.end];
            if (newLock.end != 0) {
                if (newLock.end == oldLock.end) {
                    _vars.newDslope = _vars.oldDslope;
                } else {
                    _vars.newDslope = slopeChanges[newLock.end];
                }
            }
        }

        Point memory lastPoint = Point(0, 0, _vars.ts, _vars.block);
        if (_vars.epoch != 0) {
            lastPoint = pointHistory[_vars.epoch];
        }

        uint lastCheckpoint = lastPoint.ts;
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope;
        if (_vars.ts > lastPoint.ts) {
            blockSlope = 1e18 * (_vars.block - lastPoint.block) / (_vars.ts - lastPoint.ts);
        }


        uint256 timeIndex = lastCheckpoint * WEEK / WEEK;
        for (int256 i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > _vars.ts) {
                timeIndex = _vars.ts;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            lastPoint.bias -= lastPoint.slope * int256(timeIndex - lastCheckpoint);
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            lastCheckpoint = timeIndex;
            lastPoint.ts = timeIndex;

            lastPoint.block = initialLastPoint.block + blockSlope * (timeIndex - initialLastPoint.ts) / 1e18;
            _vars.epoch += 1;
            if (timeIndex == _vars.ts) {
                lastPoint.block = _vars.block;
                break;
            } else {
                pointHistory[_vars.epoch] = lastPoint;
            }
        }
        epoch = _vars.epoch;


        if (addr != address(0)) {
            lastPoint.slope += (_userPointNew.slope - _userPointOld.slope);
            lastPoint.bias += (_userPointNew.bias - _userPointOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }
        pointHistory[_vars.epoch] = lastPoint;

         if (addr != address(0)) {
            if (oldLock.end > _vars.ts) {
                _vars.oldDslope += _userPointOld.slope;
                if (newLock.end == oldLock.end) {
                    _vars.oldDslope -= _userPointNew.slope;
                }
                slopeChanges[oldLock.end] = _vars.oldDslope;
            }
            if (newLock.end > _vars.ts) {
                if (newLock.end > oldLock.end) {
                    _vars.newDslope -= _userPointNew.slope;
                    slopeChanges[newLock.end] = _vars.newDslope;
                }
            }

            userPointEpoch[addr]++;
            _userPointNew.ts = _vars.ts;
            _userPointNew.block = _vars.block;
            userPointHistory[addr][_vars.userEpoch + 1] = _userPointNew;
        }
    }

    /**
     * @notice Seperated reward pool from lock pool by rewardLocked
     */
    function rewardDeposit(uint256 value) external {
        rewardLocked += value;
        assert(amptToken.transferFrom(msg.sender, address(this), value));
    }

    function rewardWithdraw(uint256 value) external onlyOwner {
        require(rewardLocked >= value, "not enough reward balance");
        rewardLocked -= value;
        assert(amptToken.transfer(msg.sender, value));
    }

    /**
     * @notice Reward schedule array must start from longer period
     *         for getRateByPeriod loop to find the correct rate
     */
    function rewardScheduleUpdate(RateSchedule[] memory _rateSchedules)
        external onlyOwner
    {
        delete rateSchedules;
        for (uint i = 0; i < _rateSchedules.length; i++) {
            RateSchedule memory schedule = _rateSchedules[i];
            rateSchedules.push(schedule);
        }
    }

    /**
     * Search rate from user's staking period from
     * @param stakingPeriod user's staking period
     */
    function getRateByPeriod(uint256 stakingPeriod) internal virtual returns (uint16) {
        for (uint i = 0; i < rateSchedules.length; i++) {
            RateSchedule memory schedule = rateSchedules[i];
            if (stakingPeriod > schedule.period) {
                return schedule.rate;
            }
        }

        return 0;
    }

    function getBlockNumber() public virtual view returns (uint256) {
        return block.number;
    }

    function getBlockTimestamp() public virtual view returns (uint256) {
        return block.timestamp;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Ownable {

    /// @notice owner address set on construction
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership role
     * @notice Changes the owner of this contract to a new address
     * @dev Only owner
     * @param _newOwner beneficiary to vest remaining tokens to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must be non-zero");
        
        address currentOwner = owner;
        require(_newOwner != currentOwner, "New owner cannot be the current owner");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract NonZeroAddressGuard {

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address must be non-zero");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IERC20 } from "../ERC20/IERC20.sol";
import { SmartWalletChecker } from "../utils/SmartWalletWhitelist.sol";

abstract contract VotingStorage {

     /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /**
     * @dev Returns the amount of locked tokens in existence.
    */
    uint256 public totalLocked;
    uint256 public rewardLocked;

    
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 block;
    }

    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory;
    mapping(uint256 => int256) public slopeChanges; // timestamp => slope change

    mapping(address => mapping(uint256 => Point)) public userPointHistory;
    mapping(address => uint256) public userPointEpoch;

    struct RewardEntry {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint16 rate;
    }

    struct Lock {
        uint256 amount;
        uint256 end;
        address owner;
        address delegator;
        RewardEntry[] rewardEntries;
    }

    mapping(address => Lock) public locks;
    
    /**
     * Minimum staking period for specific rate
     * schedules should be set from longest to the shortest period
     * to meet getRateByPeriod method looping
     * 
     * Rate will be divided by 10000 to represent 2 decimal places
     * in integer. 600 = 6.00%
     */
    struct RateSchedule {
        uint256 period;
        uint16 rate;
    }
    RateSchedule[] public rateSchedules;

    mapping(address => address[]) public delegations;
    mapping(address => mapping(address => uint256)) internal delegationIndexInMap;

    uint256 internal constant WEEK = 604800; // 7 * 24 * 3600;
    uint256 internal constant MAXCAP = 126144000; // 4 * 365 * 24 * 3600;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    IERC20 public amptToken;
    SmartWalletChecker public smartWalletChecker;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Base {
    function balanceOf(address owner) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
}

interface IERC20 is IERC20Base {
    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Interface for checking whether address belongs to a whitelisted type of a smart wallet.
 * When new types are added - the whole contract is changed
 * The check() method is modifying to be able to use caching
 * for individual wallet addresses
*/
interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    address public admin;
    address public checker;

    mapping(address => bool) public wallets;
    
    event ApproveWallet(address);
    event RevokeWallet(address);

    event CheckerChanged(address oldChecker, address newChecker);
    
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function setChecker(address _checker) external onlyAdmin {
        address currentChecker = checker;
        require(_checker == address(0), "Can't set zero address");
        emit CheckerChanged(currentChecker, checker);
        checker = _checker;
    }
    
    function approveWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't approve zero address");
        wallets[_wallet] = true;
        emit ApproveWallet(_wallet);
    }

    function revokeWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't revoke zero address");
        wallets[_wallet] = false;
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        if (wallets[_wallet]) {
            return true;
        } else if (checker != address(0)) {
            return SmartWalletChecker(checker).check(_wallet);
        }
        return false;
    }
}