//SPDX-License-Identifier: MIT
//@author:varun-arya
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error BCBCT__APR__AprIdNotInRange();
error BCBCT__Staking__InvalidArgument();
error BCBCT__Stake__MustStakeSomeToken();
error BCBCT__Stake__TenureNotExist();
error BCBCT__Stake__InsufficientAllowance();
error BCBCT__UnStake__AlreadyClaimed();
error BCBCT__Stake__StakeAmountNotInRange();
error BCBCT__WaitFortheFreezePeriodToEnd(uint256 endTime);
error BCBCT__Withdraw__InsufficientBalance();

interface IBCBCT {
    function freezePeriod() external view returns (uint256);
}

abstract contract APR is Ownable {
    event UpdatedAPR(uint8 _id, uint8 indexed apr);
    mapping(uint8 => mapping(uint8 => uint8)) public aprs;

    function setApr(uint8 _id, uint8 _apr) public virtual;

    function _setApr(
        uint8 _id,
        uint8 tenure,
        uint8 _apr
    ) internal {
        aprs[_id][tenure] = _apr;
    }
}

contract Staking is APR, ReentrancyGuard {
    using SafeERC20 for IERC20;
    //--------------events---------------------//
    event Staked(
        address indexed staker,
        uint256 stakeAmount,
        uint8 _tenure,
        uint256 indexed _id
    );
    event UnStaked(
        address indexed staker,
        uint256 unstakeAmount,
        uint256 reward,
        uint256 penalty
    );
    event Withdrawn(address indexed owner, uint256 BCBCT);
    //--------------enum---------------------//
    enum Status {
        UNSTAKED,
        STAKED
    }
    //--------------structs---------------------//
    struct data {
        uint256 staketokens;
        uint256 start;
        uint256 end;
        uint8 tenure;
        uint8 apr;
    }

    struct investoreStakesStruct {
        uint256 count;
        mapping(uint256 => data) stakeDetails;
        Status isStaked;
    }
    //--------------mappings---------------------//
    mapping(address => investoreStakesStruct) public stakeStatus;
    mapping(address => uint256[]) stakeID;
    //--------------modifier---------------------//
    modifier checkForZeroArgument(address var1, uint256 var2) {
        bool check = (var1 == address(0) && var2 <= 0);
        if (check) {
            revert BCBCT__Staking__InvalidArgument();
        }
        _;
    }

    modifier isFreezeFree() {
        uint256 endtime = BCBCT2.freezePeriod();
        if (block.timestamp <= BCBCT2.freezePeriod())
            revert BCBCT__WaitFortheFreezePeriodToEnd({endTime: endtime});
        _;
    }

    IERC20 public BCBCT;
    IBCBCT BCBCT2;
    uint256 public min = 1e18;
    uint256 public max = type(uint256).max;
    uint256 public totalTokenLocked;

    constructor(address _bcbct) {
        if (_bcbct == address(0)) revert BCBCT__Staking__InvalidArgument();
        BCBCT = IERC20(_bcbct);
        BCBCT2 = IBCBCT(_bcbct);
        aprs[0][1] = 11;
        aprs[1][1] = 13;
        aprs[2][1] = 15; //adjustable
    }

    //--------------write---------------------//

    function stake(uint256 stakeAmount, uint8 _tenure)
        external
        nonReentrant
        isFreezeFree
        returns (bool)
    {
        checkForTenure(_tenure);
        uint8 _apr = getApr(stakeAmount);
        if (stakeAmount > max || stakeAmount < min) {
            revert BCBCT__Stake__StakeAmountNotInRange();
        }
        if (isApproved(msg.sender, address(this)) < stakeAmount) {
            revert BCBCT__Stake__InsufficientAllowance();
        }
        address sender = msg.sender;
        uint256 staketime = block.timestamp;
        uint256 len = stakeID[sender].length;
        data storage s = stakeStatus[sender].stakeDetails[len + 1];
        s.staketokens = stakeAmount;
        s.start = block.timestamp;
        s.end = staketime + (31560000) * _tenure;
        s.tenure = _tenure;
        s.apr = _apr;
        stakeStatus[sender].isStaked = Status.STAKED;
        stakeStatus[sender].count += 1;
        stakeID[sender].push(len + 1);
        totalTokenLocked = totalTokenLocked +stakeAmount;
        emit Staked(msg.sender, stakeAmount, _tenure, (len+1));
        BCBCT.safeTransferFrom(sender, address(this), stakeAmount);
        return true;
    }

    function unstake(uint256 _stakeID)
        external
        nonReentrant
        isFreezeFree
        returns (bool)
    {
        address sender = msg.sender;
        uint256 stakedamount = stakeStatus[sender]
            .stakeDetails[_stakeID]
            .staketokens;
        (uint256 penalty, uint256 reward) = (0, 0);
        if (stakedamount <= 0 || stakeStatus[sender].count == 0) {
            revert BCBCT__Stake__MustStakeSomeToken();
        }
        if (stakeID[sender][_stakeID - 1] == 0)
            revert BCBCT__UnStake__AlreadyClaimed();
        if (getStakesID().length <= 1)
            stakeStatus[sender].isStaked = Status.UNSTAKED;
        (reward, penalty) = getReward(_stakeID);

        _unstake(stakedamount, reward, penalty, _stakeID);
        return true;
    }

    function _unstake(
        uint256 stakedamount,
        uint256 reward,
        uint256 penalty,
        uint256 _stakeID
    ) internal {
        address sender = msg.sender;
        uint256 cliamable = (stakedamount + reward);
        stakeStatus[sender].count -= 1;
        _pop(sender, _stakeID);
        delete stakeStatus[sender].stakeDetails[_stakeID];
        totalTokenLocked = totalTokenLocked - stakedamount;
        emit UnStaked(sender, cliamable, reward, penalty);
        BCBCT.safeTransfer(sender, cliamable);
    }

    function setApr(uint8 _id, uint8 apr) public virtual override onlyOwner {
        bool check = (apr <= 0);
        if (check) {
            revert BCBCT__Staking__InvalidArgument();
        }
        if (_id >= uint8(3)) revert BCBCT__APR__AprIdNotInRange();
        emit UpdatedAPR(_id, apr);
        _setApr(_id, 1, apr); // Only the APR is adjustable, whereas the tenure is fixed at one year.
    }

    function updateStakeAmount(uint256 _min, uint256 _max) external onlyOwner {
        bool check = (_min <= 0 || _max <= 0 || (_min >= _max) || _min > max);
        if (check) revert BCBCT__Staking__InvalidArgument();
        min = _min;
        max = _max;
    }

    function _pop(address sender, uint256 _stakeID) internal {
        delete stakeID[sender][_stakeID - 1];
    }

    function checkForTenure(uint8 tenure) internal  pure returns (bool) {
        if (
            tenure == 1 ||
            tenure == 2 ||
            tenure == 3 ||
            tenure == 4 ||
            tenure == 5 ||
            tenure == 6
        ) {
            return true;
        } else {
            revert BCBCT__Stake__TenureNotExist();
        }
    }

    function getReward(uint256 _stakeID)
        public
        view
        returns (uint256, uint256)
    {
        data memory s = stakeStatus[msg.sender].stakeDetails[_stakeID];
        uint256 stakedamount = s.staketokens;
        uint256 stakedEndTime = s.end;
        uint256 stakedStartTime = s.start;
        uint8 tenure = s.tenure;
        uint8 apr = s.apr;
        (uint256 denominatorAPR, uint256 lockedDays, uint256 lockedMonths) = (
            100,
            0,
            0
        );
        if (block.timestamp < stakedEndTime) {
            lockedDays = (block.timestamp - stakedStartTime) / 86400; // 5
            lockedMonths = diffMonths(stakedStartTime, block.timestamp);
        } else {
            lockedDays = uint256(tenure) * 365;
        }
        uint256 earnedAmount = (stakedamount * lockedDays * uint256(apr)) /
            (365 * denominatorAPR);

        (uint256 rewardClaimable, uint256 penalty) = getPenalty(
            lockedMonths,
            earnedAmount
        );

        return (rewardClaimable, penalty);
    }

    function getPenalty(uint256 _months, uint256 _earnedAmount)
        internal 
        pure
        returns (uint256, uint256)
    {
        uint256 deduction;
        if (_months < 6) {
            deduction = (_earnedAmount * 75) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        } else if (_months >= 6 && _months <= 12) {
            deduction = (_earnedAmount * 50) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        }else if(_months >= 13 && _months <= 19){
            deduction = (_earnedAmount * 25) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        }else {
            return (_earnedAmount, 0);
        }
    }

    function getApr(uint256 _amount) public view returns (uint8) {
        if (_amount < 100000e18) {
            return aprs[0][1];
        } else if (_amount >= 100000e18 && _amount < 500000e18) {
            return aprs[1][1];
        } else if (_amount >= 500000e18) {
            return aprs[2][1];
        } else {
            return 0;
        }
    }

    function getStakesInfo(uint256 _stakeID)
        external
        view
        returns (data memory)
    {
        return stakeStatus[msg.sender].stakeDetails[_stakeID];
    }

    function isApproved(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return BCBCT.allowance(owner, spender);
    }

    //------------helpers-----------------------//

    function getStakesID() public view returns (uint256[] memory) {
        uint256 activeStakeCount = 0;
        uint256 len = stakeID[msg.sender].length;
        for (uint256 i = 0; i < len; i++) {
            if (stakeID[msg.sender][i] != 0) {
                activeStakeCount++;
            }
        }
        uint256[] memory arr = new uint256[](activeStakeCount);
        uint256 j = 0;
        for (uint256 i = 0; i < len; i++) {
            if (stakeID[msg.sender][i] != 0) {
                arr[j] = stakeID[msg.sender][i];
                j++;
            }
        }
        return arr;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal 
        pure
        returns (uint256 _months)
    {
        if (fromTimestamp >= toTimestamp) revert();
        (uint256 fromYear, uint256 fromMonth, ) = timeHelper(
            fromTimestamp / 86400
        );
        (uint256 toYear, uint256 toMonth, ) = timeHelper(toTimestamp / 86400);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function timeHelper(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + 2440588;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    //--------------withdraw---------------------//
    function emergencyWithdraw(address owner, uint256 _amount)
        external
        onlyOwner
        checkForZeroArgument(owner, _amount)
    {   uint256 bal = BCBCT.balanceOf(address(this)); 
        if (bal - totalTokenLocked >= _amount){
            revert BCBCT__Withdraw__InsufficientBalance(); // keep investor stakes safe
        }
        emit Withdrawn(owner, _amount);
        BCBCT.safeTransfer(owner, _amount);
    }

    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) external onlyOwner checkForZeroArgument(_to, _amount) {
        if(IERC20(_tokenAddr) == IERC20(BCBCT)) revert BCBCT__Withdraw__InsufficientBalance(); //// keep investor stakes safe
        if (_tokenAddr == address(0)) revert BCBCT__Staking__InvalidArgument();
        emit Withdrawn(_to, _amount);
        IERC20(_tokenAddr).safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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