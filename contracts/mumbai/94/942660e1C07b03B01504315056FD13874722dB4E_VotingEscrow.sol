// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ---------------------------------------------------------------------------------------
// ------------------------------------- veISS ---------------------------------------
// ---------------------------------------------------------------------------------------

// Forked and adjusted from Shade Finance which have...
// Converted from vyper to solidity from SnowBall Voting Escrow
// Time-weighted balance
// The balance in this implementation is linear, and lock can't be more than maxtime
// B ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> T
//   maxtime (4 years)

contract VotingEscrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // -------------------------------- VARIABLES -----------------------------------
    struct Point {
        int256 bias;
        int256 slope; // - dweight / dt
        uint256 timeStamp; //timestamp
        uint256 blockNumber; // block
    }

    struct LockedBalance {
        //int256 amount;
        uint256 amount;
        uint256 end;
    }

    /**
    struct Reward {
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }
    **/


    enum LockAction {
        CREATE_LOCK,
        INCREASE_LOCK_AMOUNT,
        INCREASE_LOCK_TIME
    }

    uint256 constant WEEK = 7 days; // all future times are rounded by week
    uint256 constant MINTIME = WEEK;
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    address public stakingToken;

    mapping(address => LockedBalance) public lockedBalances;
    uint256 public stakedTotal;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point.
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    string public name;
    string public symbol;
    uint256 public decimals;

    bool public expired = false;
    

    // -------------------------------- CONSTRUCT -----------------------------------
    constructor(address _ISSAddress) Ownable() {
        name = "veISS Token";
        symbol = "veISS";
        decimals = 18; // MUST be same as for staking tokem
        stakingToken = _ISSAddress;

        pointHistory[0].blockNumber = block.number;
        pointHistory[0].timeStamp = block.timestamp;
        
    }

    // -------------------------------- ADMIN -----------------------------------
    /**
    function setContractExpired() external onlyOwner notExpired {
        expired = true;
        emit Expired();
    }
    **/

    //
    /**
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
        IERC20(tokenAddress).safeTransfer(owner(), amount);
        emit Recovered(tokenAddress, amount);
    }
    **/

    // -------------------------------- VIEWS -----------------------------------
    //
    function getLastUserSlope(address account) external view returns (uint256) {
        uint256 userEpoch = userPointEpoch[account];
        return uint256(userPointHistory[account][userEpoch].slope);
    }

    //
    function userPointHistoryTs(address account, uint256 idx) external view returns (uint256) {
        return userPointHistory[account][idx].timeStamp;
    }

    //
    function balanceOf(address account) public view returns (uint256) {
        return balanceOfAtTime(account, block.timestamp);
    }

    //
    function balanceOfAtTime(address account, uint256 timeStamp) public view returns (uint256) {
        if (timeStamp == 0) {
            timeStamp = block.timestamp;
        }

        uint256 userEpoch = userPointEpoch[account];
        if (userEpoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[account][userEpoch];
            lastPoint.bias -= lastPoint.slope * int256(timeStamp - lastPoint.timeStamp);
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(lastPoint.bias);
        }
    }

    //
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber <= block.number, "Wrong block number");

        uint256 min;
        uint256 max = userPointEpoch[account];
        for (uint256 i; i <= 255; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (userPointHistory[account][mid].blockNumber <= blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        Point memory userPoint = userPointHistory[account][min];

        uint256 blockEpoch = findBlockEpoch(blockNumber, epoch);

        Point memory point0 = pointHistory[blockEpoch];
        uint256 deltaBlockNumber;
        uint256 deltaTimeStamp;

        if (blockEpoch < epoch) {
            Point memory point1 = pointHistory[blockEpoch + 1];
            deltaBlockNumber = point1.blockNumber - point0.blockNumber;
            deltaTimeStamp = point1.timeStamp - point0.timeStamp;
        } else {
            deltaBlockNumber = block.number - point0.blockNumber;
            deltaTimeStamp = block.timestamp - point0.timeStamp;
        }

        uint256 blockTime = point0.timeStamp;
        if (deltaBlockNumber != 0) {
            blockTime += (deltaTimeStamp * (blockNumber - point0.blockNumber)) / deltaBlockNumber;
        }

        userPoint.bias -= userPoint.slope * int256(blockTime - userPoint.timeStamp);
        if (userPoint.bias >= 0) {
            return uint256(userPoint.bias);
        } else {
            return 0;
        }
    }

    //
    function supplyAt(Point memory point, uint256 timeStamp) internal view returns (uint256) {
        //Runde den timestamp auf die letzte Woche
        uint256 _timeStamp = (point.timeStamp / WEEK) * WEEK;
        
        //Iteriere vom letzten aufgezeichneten Punkt Zeitpunkt bis zum gegebenen Zeitpunkt
        for (uint256 i; i < 255; i++) {
            _timeStamp += WEEK;
            int256 slope = 0;

            if (_timeStamp > timeStamp) {
                _timeStamp = timeStamp;
            } else {
                slope = slopeChanges[_timeStamp];
            }
            point.bias -= point.slope * int256(_timeStamp - point.timeStamp);

            if (_timeStamp == timeStamp) {
                break;
            }
            point.slope += slope;
            point.timeStamp = _timeStamp;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }
        return uint256(point.bias);
    }

    //
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256) {
        require(blockNumber <= block.number, "Only current or past block number");

        uint256 targetEpoch = findBlockEpoch(blockNumber, epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 delta;
        if (targetEpoch < epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blockNumber != pointNext.blockNumber) {
                delta = ((blockNumber - point.blockNumber) * (pointNext.timeStamp - point.timeStamp)) / (pointNext.blockNumber - point.blockNumber);
            }
        } else {
            if (point.blockNumber != block.number) {
                delta = ((blockNumber - point.blockNumber) * (block.timestamp - point.timeStamp)) / (block.number - point.blockNumber);
            }
        }

        return supplyAt(point, point.timeStamp + delta);
    }

    //
    function totalSupply() public view returns (uint256) {
        return supplyAt(pointHistory[epoch], block.timestamp);
    }

    //
    function getUserPointEpoch(address _user) external view returns (uint256) {
        return userPointEpoch[_user];
    }

    //
    function findBlockEpoch(uint256 blockNumber, uint256 maxEpoch) internal view returns (uint256) {
        uint256 min;
        uint256 max = maxEpoch;
        for (uint256 i; i < 255; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (pointHistory[mid].blockNumber <= blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    // Contract Data method for decrease number of request to contract from dApp UI
    function contractData()
        public
        view
        returns (
            uint256 _stakedTotal, // stakedTotal
            uint256 _totalSupply, // totalSupply
            uint256 _minTime, // minimum Lock Time MINTIME
            uint256 _maxTime // maximum Lock Time MAXTIME
        )
    {
        _stakedTotal = stakedTotal;
        _totalSupply = totalSupply();
        _minTime = MINTIME;
        _maxTime = MAXTIME;
    }

    // User Data method for decrease number of request to contract from dApp UI
    function userData(address account)
        public
        view
        returns (
            LockedBalance memory _lockedBalance, // Balances [] amount, end
            uint256 _balanceVeISS, // veISS balance
            uint256 _allowance, // allowance of staking token
            uint256 _balance // balance of staking token
        )
    {
        _lockedBalance = lockedBalances[account];
        _balanceVeISS = balanceOf(account);
        _allowance = IERC20(stakingToken).allowance(account, address(this));
        _balance = IERC20(stakingToken).balanceOf(account);
    }

    // -------------------------------- MUTATIVE -----------------------------------
    // Creates a new lock
    function createLock(uint256 amount, uint256 unlockTime) external nonReentrant notContract {
        unlockTime = unlockTime / WEEK * WEEK; // Locktime is rounded down to weeks

        require(amount != 0, "Must stake non zero amount");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");

        LockedBalance memory locked = lockedBalances[msg.sender];
        
        
        require(locked.amount == 0, "Withdraw old tokens first");
        
    

    

        uint256 roundedMin = block.timestamp / WEEK * WEEK + MINTIME;
        uint256 roundedMax = block.timestamp / WEEK * WEEK + MAXTIME;
        if (unlockTime < roundedMin) {
            unlockTime = roundedMin;
        } else if (unlockTime > roundedMax) {
            unlockTime = roundedMax;
        }

        _depositFor(msg.sender, amount, unlockTime, locked, LockAction.CREATE_LOCK);
    }

    // Increases amount of staked tokens
    function increaseLockAmount(uint256 amount) external nonReentrant notContract {
        LockedBalance memory locked = lockedBalances[msg.sender];

        require(amount != 0, "Must stake non zero amount");
        require(locked.amount != 0, "No existing lock found");
        require(locked.end >= block.timestamp, "Can't add to expired lock. Withdraw old tokens first");

        _depositFor(msg.sender, amount, 0, locked, LockAction.INCREASE_LOCK_AMOUNT);
    }

    // Increases length of staked tokens unlock time
    function increaseLockTime(uint256 unlockTime) external nonReentrant notContract {
        LockedBalance memory locked = lockedBalances[msg.sender];
        
        require(locked.amount != 0, "No existing lock found");
        require(locked.end >= block.timestamp, "Lock expired. Withdraw old tokens first");
    
    uint256 maxUnlockTime = block.timestamp / WEEK * WEEK + MAXTIME;
    require(locked.end != maxUnlockTime, "Already locked for maximum time");    

        unlockTime = unlockTime / WEEK * WEEK; // Locktime is rounded down to weeks
    require(unlockTime <= maxUnlockTime, "Can't lock for more than max time");
   
        _depositFor(msg.sender, 0, unlockTime, locked, LockAction.INCREASE_LOCK_TIME);
    }

    // Withdraw all tokens  if the lock has expired
    function withdraw() external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];
        LockedBalance memory oldLocked = locked;
    
    require(block.timestamp >= locked.end || expired, "The lock didn't expire");
                    
        stakedTotal -= locked.amount;
    locked.amount = 0;
    locked.end = 0; 

        _checkpoint(msg.sender, oldLocked, locked);

        IERC20(stakingToken).safeTransfer(msg.sender, oldLocked.amount);

        emit Withdraw(msg.sender, oldLocked.amount, block.timestamp);       
    }

    // Record global and per-user data to checkpoint
    function _checkpoint(
        address account,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) internal {
        
        Point memory userOldPoint;
        Point memory userNewPoint;
        int256 oldSlope = 0;
        int256 newSlope = 0;
        uint256 _epoch = epoch;


        if (account != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                userOldPoint.slope = int256(oldLocked.amount / MAXTIME);
                userOldPoint.bias = userOldPoint.slope * int256(oldLocked.end - block.timestamp);
               
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                userNewPoint.slope = int256(newLocked.amount / MAXTIME);
                userNewPoint.bias = userNewPoint.slope * int256(newLocked.end - block.timestamp);
                
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired than zeros
            oldSlope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    newSlope = oldSlope;
                } else {
                    newSlope = slopeChanges[newLocked.end];
                }
            }
        }
        Point memory lastPoint = Point({ bias: 0, slope: 0, timeStamp: block.timestamp, blockNumber: block.number });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.timeStamp;
        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.timeStamp) {
            blockSlope = (MULTIPLIER * (block.number - lastPoint.blockNumber)) / (block.timestamp - lastPoint.timeStamp);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 timeStamp = lastCheckpoint / WEEK * WEEK;
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            timeStamp += WEEK;
            int256 slope = 0;
            if (timeStamp > block.timestamp) {
                timeStamp = block.timestamp;
            } else {
                slope = slopeChanges[timeStamp];
            }

            lastPoint.bias -= lastPoint.slope * int256(timeStamp - lastCheckpoint);
            lastPoint.slope += slope;
            
            if (lastPoint.bias < 0) {               
                lastPoint.bias = 0; // This can happen
            }

            if (lastPoint.slope < 0) {              
                lastPoint.slope = 0; // This cannot happen - just in case
            }

            lastCheckpoint = timeStamp;
            lastPoint.timeStamp = timeStamp;
            lastPoint.blockNumber = initialLastPoint.blockNumber + ((blockSlope * (timeStamp - initialLastPoint.timeStamp)) / MULTIPLIER);

            _epoch += 1;

            if (timeStamp == block.timestamp) {
                lastPoint.blockNumber = block.number;
                break;
            } else {
                pointHistory[_epoch] = lastPoint;
            }
        }
        epoch = _epoch;
        // Now pointHistory is filled until timeStamp=now

        if (account != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += userNewPoint.slope - userOldPoint.slope;
            lastPoint.bias += userNewPoint.bias - userOldPoint.bias;
            
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            
        }
        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;

        address account2 = account; // To avoid being "Stack Too Deep"

        if (account2 != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [newLocked.end]
            // and add old_user_slope to [oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // oldSlope was <something> - userOldPoint.slope, so we cancel that
                oldSlope += userOldPoint.slope;
                if (newLocked.end == oldLocked.end) {
                    oldSlope -= userNewPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[oldLocked.end] = oldSlope;
            }
            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newSlope -= userNewPoint.slope; // old slope disappeared at this point
                    slopeChanges[newLocked.end] = newSlope;
                }
                // else we recorded it already in oldSlope
            }

            // Now handle user history
            uint256 userEpoch = userPointEpoch[account2] + 1;

            userPointEpoch[account2] = userEpoch;
            userNewPoint.timeStamp = block.timestamp;
            userNewPoint.blockNumber = block.number;
            userPointHistory[account2][userEpoch] = userNewPoint;
        }
    }

    //
    function checkpoint() external {
        LockedBalance memory a;
        LockedBalance memory b;
        _checkpoint(address(0), a, b);
    }

    // Deposits or creates a stake for a given account
    function _depositFor(
        address account,
        uint256 amount,
        uint256 unlockTime,
        LockedBalance memory locked,
        LockAction action
    ) internal {
        LockedBalance memory _locked = locked;
        LockedBalance memory oldLocked;
        (oldLocked.amount, oldLocked.end) = (_locked.amount, _locked.end);
        
        

        
    if (amount != 0) {
      _locked.amount += amount;  
      stakedTotal += amount;            
            IERC20(stakingToken).safeTransferFrom(account, address(this), amount);
        }
    
    if (unlockTime != 0) {
            _locked.end = unlockTime;
        }
    
        lockedBalances[account] = _locked;

        _checkpoint(account, oldLocked, _locked);


        emit Deposit(account, amount, _locked.end, action, block.timestamp);     
    }

    // ------------------------------------ EVENTS --------------------------------------
    /**
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event RewardAdded(address indexed rewardsToken, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 amount);
    event FTMReceived(address distributor, uint256 amount);
    **/

    event Deposit(address indexed accouunt, uint256 value, uint256 indexed locktime, LockAction indexed action, uint256 timestamp);
    event Withdraw(address indexed accouunt, uint256 value, uint256 timestamp); 
    event Expired();
    event Recovered(address token, uint256 amount);

    // ------------------------------------ MODIFIERS ------------------------------------
    /**
    modifier notExpired() {
        require(!expired, "Contract is expired");
        _;
    }
    **/

    modifier notContract() {
        require(!Address.isContract(msg.sender), "Not allowed for contract address");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
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