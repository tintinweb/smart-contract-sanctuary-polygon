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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";

contract STRTLocking is Ownable {
    modifier isLockPaused{
        require(!lockPaused, "paused");
        _;
    }
    
    IERC20 public immutable token;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public apy_d2; // decimal 2
    uint256 public minLock;
    bool public lockPaused;
    uint256 public penalty_d2; // charged when unlock before due date (decimal 2)
    uint256 public fee_d2; // charged when unlock after due date (decimal 2)
    uint256 private lockPeriod; // in seconds
    address[] private members;
    
    uint256 public strtLocked;

    struct Detail {
        uint256 index;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 lastClaimed;
        uint256 rewardEnded;
    }
    
    mapping(address => Detail[]) public summaries;
    mapping(address => uint256) public locked;
    mapping(address => uint256) public memberIndex;
    
    event Locked (address indexed _member, uint256 _amount, uint256 _lockedAt);
    event Claimed (address indexed _member, uint256 _amount, uint256 _claimedAt);
    event Unlocked (address indexed _member, uint256 _amount, uint256 _unlockedAt);

    constructor(
        IERC20 _token,
        uint256 _apy_d2,
        uint256 _minLock,
        uint256 _penalty_d2,
        uint256 _fee_d2,
        // uint256 _lockDurationInMonth
        uint256 _lockPeriod // TEST !! Remove at mainnet
    ){
        token = _token;
        apy_d2 = _apy_d2;
        minLock = _minLock;
        penalty_d2 = _penalty_d2;
        fee_d2 = _fee_d2;
        // lockPeriod = _lockDurationInMonth * 30 * 86400;
        lockPeriod = _lockPeriod; // TEST !! Remove at mainnet
    }

    /* ========== VIEW AREA BEGIN ========== */

    // result in month
    function lockDuration() external view returns (uint256){
        return (lockPeriod / 86400) / 30;
    }

    function pendingReward(uint256 _lockIndex, address _member) public view returns(uint){
        if(!everLocked(_member)) return 0;

        uint256 dateTimeNow = block.timestamp;
        Detail memory summary = summaries[_member][_lockIndex];

        uint256 startDate = summary.lastClaimed;
        if(startDate == 0) startDate = summary.start;

        uint endDate = dateTimeNow;
        if(summary.rewardEnded > 0) endDate = summary.rewardEnded;

        return calcReward(summary.amount, startDate, endDate);
    }

    function calcReward(uint256 _amount, uint256 _start, uint256 _end) public view returns (uint256) {
        uint256 rewardPerSecond = ((((apy_d2 * _amount) / 12) / 30) / 86400) / 10000;
        return (_end - _start) * rewardPerSecond;
    }

    function everLocked(address _member) public view returns(bool){
        return (summaries[_member].length > 0);
    }

    /**
     * @dev Gets the length stake history of a specified address
     * @param _member The address to query the length stake history of
     */
    function getUserLockedLength(address _member) public view returns(uint256){
        return summaries[_member].length;
    } 

    /**
     * @dev Gets the staked tokens of a specified address & date before
     * @param _member The address to query the the locked token count of
     */
    function getLockedTokensBeforeDate(address _member, uint256 _before) public view returns (uint256 lockedTokens) {
        uint256 locksLength = summaries[_member].length;
        for (uint256 i = 0; i < locksLength; i++) {
            if (summaries[_member][i].start <= _before) {
                lockedTokens += summaries[_member][i].amount;
            }
        }
    }
    
    /**
     * @dev Gets the total Locked of all Users start from private sale
     */
    function getLockedTokensGreaterThan(uint256 _min) public view returns(uint256 total){
        for(uint256 i=0; i<members.length; i++){
            uint256 qty = locked[members[i]];
            if(qty >= _min){
                total += qty;
            }
        }
    }

    /* ========== VIEW AREA END ========== */

    
    /* ========== MAIN AREA BEGIN ========== */

    /**
     * @dev Locks specified amount of tokens
     * @param _amount Number of tokens to be locked
     */

    function lock(uint256 _amount, address _member) public isLockPaused {
        _lock(_amount, _member);
        TransferHelper.safeTransferFrom(address(token), _member, address(this), _amount);
    }

    function claim(uint256 _lockIndex, address _member) isLockPaused public {
        uint256 reward = _claim(_lockIndex, _member);
        _releaseToken(reward, _member, 0, 0);

        if(locked[_member] == 0) _deleteMember(_member);
    }

    // take & lock the rewards
    function relock(uint256 _lockIndex, address _member) isLockPaused public {
        uint256 reward = _claim(_lockIndex, _member);
        _lock(reward, _member);

        // emit Relock(msg.sender, unlockableTokens);
    }

    // take locked token
    function unlock(uint256 _lockIndex, address _member) isLockPaused public {
        uint256 dateTimeNow = block.timestamp;
        Detail memory summary = summaries[_member][_lockIndex];

        require(everLocked(_member), "bad");

        locked[_member] -= summary.amount;
        strtLocked -= summary.amount;

        uint256 charged_d2;
        uint256 startDate;
        if(summary.end > dateTimeNow){
            charged_d2 = penalty_d2;
            startDate = summary.start;

            _deleteLockIndex(_lockIndex, _member);
            if(locked[_member] == 0) _deleteMember(_member);
        } else {
            charged_d2 = fee_d2;
            summaries[_member][_lockIndex].rewardEnded = dateTimeNow;
        }

        _releaseToken(summary.amount, _member, charged_d2, startDate);

        emit Unlocked(_member, summary.amount, dateTimeNow);
    }

    function _lock(uint256 _amount, address _member) internal {
        require(_amount >= minLock, "bad");

        uint256 dateTimeNow = block.timestamp;

        if(!everLocked(_member)){
            members.push(_member);
            memberIndex[_member] = members.length - 1;
        }
    
        summaries[_member].push(Detail(summaries[_member].length+1, _amount, dateTimeNow, dateTimeNow + lockPeriod, 0, 0));
        locked[_member] += _amount;
        strtLocked += _amount;

        emit Locked(_member, _amount, dateTimeNow);
    }

    // just rewards
    function _claim(uint256 _lockIndex, address _member) internal returns(uint256 reward) {
        uint256 dateTimeNow = block.timestamp;
        Detail memory summary = summaries[_member][_lockIndex];

        require(everLocked(_member) && summary.end <= dateTimeNow, "bad");

        summaries[_member][_lockIndex].lastClaimed = dateTimeNow;

        uint256 startDate = summary.lastClaimed;
        if(startDate == 0) startDate = summary.start;

        uint endDate = dateTimeNow;
        if(summary.rewardEnded > 0){
            endDate = summary.rewardEnded;
            
            _deleteLockIndex(_lockIndex, _member);
        }

        reward = calcReward(summary.amount, startDate, endDate);

        emit Claimed(_member, reward, dateTimeNow);
    }

    function _releaseToken(uint256 _amount, address _member, uint256 _charged_d2, uint256 _start) internal {
        uint256 chargedAmount;
        if(_charged_d2 > 0){
            if(_start > 0) _charged_d2 = _charged_d2 - ((block.timestamp - _start) * _charged_d2 / lockPeriod);
            
            chargedAmount = (_amount * _charged_d2) / 10000;
            TransferHelper.safeTransfer(address(token), DEAD, chargedAmount);
        }

        TransferHelper.safeTransfer(address(token), _member, _amount - chargedAmount);
    }

    function _deleteLockIndex(uint256 _lockIndexToDelete, address _member) internal {
        uint256 lockIndexToMove = summaries[_member].length - 1;
        Detail memory summaryToMove = summaries[_member][lockIndexToMove];
        summaryToMove.index = _lockIndexToDelete;

        summaries[_member][_lockIndexToDelete] = summaryToMove;

        summaries[_member].pop();
    }

    function _deleteMember(address _member) internal {
        require(!everLocked(_member), "bad");

        address memberToMove = members[members.length - 1];
        uint256 indexToDelete = memberIndex[_member];

        members[indexToDelete] = memberToMove;
        memberIndex[memberToMove] = indexToDelete;

        members.pop();
        delete memberIndex[_member];
    }

    /* ========== MAIN AREA END ========== */


    /* ========== ADMIN AREA BEGIN ========== */

    function updateApy(uint256 _apy_d2) public onlyOwner {
        apy_d2 = _apy_d2;
    }

    function updateMinLock(uint256 _minLock) public onlyOwner {
        minLock = _minLock;
    }

    function updatePenalty(uint256 _penalty_d2) public onlyOwner {
        penalty_d2 = _penalty_d2;
    }

    function updateFee(uint256 _fee_d2) public onlyOwner {
        fee_d2 = _fee_d2;
    }

    // input in month
    // function updateLockDuration(uint256 _lockDurationInMonth) public onlyOwner {
    //     lockPeriod = _lockDurationInMonth * 30 * 86400;
    // }

    // TESTNET !! Remove at mainnet
    function updateLockPeriod(uint256 _lockPeriod) public onlyOwner {
        lockPeriod = _lockPeriod;
    }
    
    function toggleLocked() public onlyOwner {
        lockPaused = !lockPaused;
    } 

    /* ========== ADMIN AREA END ========== */

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
	function safeApprove(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
	}

	function safeTransfer(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
	}

	function safeTransferFrom(address token, address from, address to, uint value) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
	}

	function safeTransferETH(address to, uint value) internal {
		(bool success,) = to.call{value:value}(new bytes(0));
		require(success, "TransferHelper: ETH_TRANSFER_FAILED");
	}
}