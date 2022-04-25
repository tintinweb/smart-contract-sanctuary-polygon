// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IPopStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PopStaking is IPopStaking, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 public _oneDayBlocks;
    uint256 public _startBlockNumber;
    uint256 public _endBlockNumber;
    uint256 public _releasePerBlock;
    uint256 public _totalStakingAmount;

    address public _lpPool;
    address public _usdt;
    address public _popToken;
    address public _stakeOut;
    bool public _isEmergency;

    uint256[] public _veType;
    uint256[] public _stakingType;
    uint256[] public _timestampType;
    PoolInfo public _poolInfo;
    mapping(address => UserInfo[]) public _userInfo;

    constructor (
        address popAdd,
        address stakeOut,
        uint256 startBlock
    ) {
        _popToken = popAdd;
        _stakeOut = stakeOut;
        _releasePerBlock = 2 ether;
        _oneDayBlocks = 34560;
        _startBlockNumber = startBlock;
        _endBlockNumber = startBlock + 50457600;
        _veType = [0.1 ether, 0.205 ether, 0.42 ether, 1.28 ether, 2.54 ether, 5 ether, 10 ether, 15 ether];
        _timestampType = [604800, 1209600, 2592000, 7776000, 15552000, 31536000, 63072000, 94608000];
        _stakingType = [241920, 483840, 1036800, 3110400, 6220800, 12614400, 25228800, 37843200];
    }

    function updatePool() public {
        if (_isEmergency == true) {
            return;
        }

        uint256 curBlock = block.number;
        uint256 popStake = _totalStakingAmount;

        if (curBlock >= _endBlockNumber) {
            return;
        }

        if (popStake == 0) {
            _poolInfo.lastRewardBlock = curBlock;
            return;
        }

        uint256 popReward = getPeriodReward(_poolInfo.lastRewardBlock, curBlock);
        IERC20(_popToken).transferFrom(_stakeOut, address(this), popReward);

        _poolInfo.accPerShare = _poolInfo.accPerShare + (popReward * 1e12) / popStake;
        _poolInfo.lastRewardBlock = curBlock;
    }

    function deposit(uint256 lockAmount, uint256 lockType) public override nonReentrant {
        require(_isEmergency != true, "NOW YOU CAN NOT DEPOSIT");
        require(lockType < _stakingType.length, "INVALID LOCK TYPE");
        uint256 currentBlock = block.number;
        uint256 currentTimestamp = block.timestamp;
        uint256 userInd = _userInfo[msg.sender].length;

        IERC20(_popToken).transferFrom(msg.sender, address(this), lockAmount);
        updatePool();

        _userInfo[msg.sender].push(
            UserInfo({
                index: userInd,
                poolType: lockType,
                amount: lockAmount,
                veTokenAmount: _veType[lockType],
                startTimestamp: currentTimestamp,
                endTimestamp: currentTimestamp + _timestampType[lockType],
                depositTime: currentBlock,
                endTime: currentBlock + _stakingType[lockType],
                rewardDebt: (lockAmount * _poolInfo.accPerShare) / 1e12,
                isClaimed: false
            })
        );
        _totalStakingAmount += lockAmount;

        emit Deposit(msg.sender, lockAmount, lockType);
    }

    function reedem(uint256 userIndex) public override nonReentrant {
        require(_isEmergency != true, "INVALID REEDEM");
        require(userIndex < _userInfo[msg.sender].length, "STAKING MESSAGE NOT EXISTS.");
        require(_userInfo[msg.sender][userIndex].isClaimed == false, "YOU HAD CLAIMED REWARDS.");
        require(_userInfo[msg.sender][userIndex].endTime < block.number, "NOT UNLOCKED YET.");
        updatePool();

        _totalStakingAmount -= _userInfo[msg.sender][userIndex].amount;

        uint256 pending = _userInfo[msg.sender][userIndex].amount 
                            * _poolInfo.accPerShare / 1e12 
                            - _userInfo[msg.sender][userIndex].rewardDebt;
        uint256 reedemAmount = pending + _userInfo[msg.sender][userIndex].amount;

        _userInfo[msg.sender][userIndex].veTokenAmount = 0;
        _userInfo[msg.sender][userIndex].isClaimed = true;

        safePopTransfer(msg.sender, reedemAmount);

        emit Reedem(msg.sender, reedemAmount);
    }

    function emergencyWithdraw(uint256 userIndex) public override nonReentrant {
        require(_isEmergency == true, "EMERGENCY WITHDRAW NOT OPEN.");
        require(userIndex < _userInfo[msg.sender].length, "STAKING MESSAGE NOT EXISTS.");        
        require(_userInfo[msg.sender][userIndex].isClaimed == false, "YOU HAD CLAIMED REWARDS.");
        
        _totalStakingAmount -= _userInfo[msg.sender][userIndex].amount;

        uint256 pending = _userInfo[msg.sender][userIndex].amount 
                            * _poolInfo.accPerShare / 1e12 
                            - _userInfo[msg.sender][userIndex].rewardDebt;
        uint256 reedemAmount = pending + _userInfo[msg.sender][userIndex].amount;

        _userInfo[msg.sender][userIndex].veTokenAmount = 0;
        _userInfo[msg.sender][userIndex].isClaimed = true;

        safePopTransfer(msg.sender, reedemAmount);

        emit Reedem(msg.sender, reedemAmount);
    }

    function safePopTransfer(address to, uint256 amount) internal {
        uint256 popBal = IERC20(_popToken).balanceOf(address(this));
        if (amount > popBal) {
            IERC20(_popToken).transfer(to, popBal);
        } else {
            IERC20(_popToken).transfer(to, amount);
        }
    }


    function getDailyRewards() public view override returns (uint256 dailyRewards) {
        uint256 rewardPerBlock = getRewardPerBlock(block.number);
        dailyRewards = _oneDayBlocks * rewardPerBlock;
    }

    function getRewardPerBlock(uint256 blockNumber) public view override returns (uint256 perBlockReward) {
        if (blockNumber >= _startBlockNumber) {
            uint256 throughBlock = blockNumber - _startBlockNumber;
            if (throughBlock <= 967680) {
                perBlockReward = _releasePerBlock;
            } else {
                uint256 epic = (throughBlock - 967680) / 34560;
                perBlockReward = _releasePerBlock + (epic + 1) * 16 * 1e18 / 10000;
            }
        }
    }

    function getPeriodReward(uint256 startBlock, uint256 endBlock) public view returns (uint256 popRelease) {
        if (startBlock < endBlock) {
            uint256 oneDayBlocks = _oneDayBlocks;            
            uint256 startPRD = (startBlock - _startBlockNumber) % oneDayBlocks;
            uint256 endPRD = (endBlock - _startBlockNumber) % oneDayBlocks;
            uint256 releasePerBlock = _releasePerBlock;
            uint256 wholeEpic;
            if (endBlock - startBlock < oneDayBlocks) {
                wholeEpic = 0;
            } else {
                wholeEpic = (endBlock - startBlock - endPRD + startPRD - oneDayBlocks) / oneDayBlocks;
            }

            uint256 popPerInStart = getRewardPerBlock(startBlock);
            uint256 popPerInEnd = getRewardPerBlock(endBlock);

            if (popPerInStart == popPerInEnd) {
                popRelease = popPerInEnd * (endBlock - startBlock);
            } else if (wholeEpic == 0) {
                popRelease = popPerInStart * (oneDayBlocks - startPRD) + popPerInEnd * endPRD;
            } else {
                uint256 wholeBlockPopRelease;
                for (uint i; i < wholeEpic; i++) {
                    wholeBlockPopRelease += oneDayBlocks * popPerInStart 
                                            + oneDayBlocks * releasePerBlock * 8 * (i + 1) / 10000;
                }
                
                popRelease = wholeBlockPopRelease 
                            + popPerInStart * (oneDayBlocks - startPRD) 
                            + popPerInEnd * endPRD;
            }
        }
    }

    function getPopPrice() public view override returns (uint256 popPrice) {
        uint256 usdtValue = IERC20(_usdt).balanceOf(_lpPool);
        uint256 popSupply = IERC20(_popToken).balanceOf(_lpPool);
        popPrice = usdtValue * 1e24 / popSupply;
    }

    function getStakeTVL() public view override returns (uint256 tvl) {
        uint256 popPrice = getPopPrice();
        tvl = popPrice * _totalStakingAmount / 1e18;
    }

    function annualPerRate() public view override returns (uint256 apr) {
        uint256 currentBlock = block.number;
        uint256 popPerBlock = getRewardPerBlock(currentBlock);
        if (_totalStakingAmount != 0) {
            apr = _oneDayBlocks * popPerBlock * 365 * 1e12 / _totalStakingAmount;
        } else {
            apr = 0;
        }
    }

    function getUserTotalStake() public view override returns (uint256 totalStake) {
        for (uint i; i < _userInfo[msg.sender].length; i++) {
            if (_userInfo[msg.sender][i].isClaimed != true) {
                totalStake += _userInfo[msg.sender][i].amount;
            }
        }
    }

    function getUserInfo(address user) public view override returns (UserInfo[] memory) {
        return _userInfo[user];
    }

    function getCurrentBlock() public view override returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function getUserRewardList() public view override returns (uint256[] memory userReward) {
        uint256 curBlock = block.number;
        uint256 lastRewardBlock = _poolInfo.lastRewardBlock;
        uint256 accPerShare = _poolInfo.accPerShare;
        uint256 userLength = _userInfo[msg.sender].length;
        uint256 popStake = _totalStakingAmount;

        if (userLength != 0) {
            userReward = new uint256[](userLength);
            if (_isEmergency == false) {
                uint256 popReward = getPeriodReward(lastRewardBlock, curBlock);
                accPerShare = accPerShare + (popReward * 1e12) / popStake;
            }
            
            for (uint i; i < userLength; i++) {
                userReward[i] = _userInfo[msg.sender][i].amount 
                                * accPerShare / 1e12 
                                - _userInfo[msg.sender][i].rewardDebt;
            }
        }
        
    }

    function setEmergencyOpen() public onlyOwner {
        updatePool();
        _isEmergency = !_isEmergency;
    }

    function setLpPool(address lpPool) public onlyOwner {
        _lpPool = lpPool;
    }

    function setUSDT(address usdtAdd) public onlyOwner {
        _usdt = usdtAdd;
    }

    function setOneDayBlock(uint256 newDayBlock) public onlyOwner {
        _oneDayBlocks = newDayBlock;
    }

    function setStartBlock(uint256 newStartBlock) public onlyOwner {
        _startBlockNumber = newStartBlock;
    }

    function setEndBlock(uint256 newEndBlock) public onlyOwner {
        _endBlockNumber = newEndBlock;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPopStaking {
    event Deposit(address sender, uint256 amount, uint256 lockType);
    event Reedem(address recipient, uint256 amount);

    struct UserInfo {
        uint256 index;
        uint256 poolType;
        uint256 amount;
        uint256 veTokenAmount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 depositTime;
        uint256 endTime;
        uint256 rewardDebt;
        bool isClaimed;
    }

    struct PoolInfo {
        uint256 accPerShare;
        uint256 lastRewardBlock;
    }

    function deposit(uint256 lockAmount, uint256 lockType) external;
    function reedem(uint256 userIndex) external;
    function emergencyWithdraw(uint256 userIndex) external;
    function getDailyRewards() external view returns (uint256 dailyRewards);
    function getRewardPerBlock(uint256 blockNumber) external view returns (uint256 perBlockReward);
    function getUserTotalStake() external view returns (uint256 totalStake);
    function getPopPrice() external view returns (uint256 popPrice);
    function getUserInfo(address user) external view returns (UserInfo[] memory);
    function getStakeTVL() external view returns (uint256 lpTVL);
    function annualPerRate() external view returns (uint256 apr);
    function getCurrentBlock() external view returns (uint256 blockNumber);
    function getUserRewardList() external view returns (uint256[] memory userReward);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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