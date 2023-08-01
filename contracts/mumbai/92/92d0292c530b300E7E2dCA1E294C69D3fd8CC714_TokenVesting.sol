/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: tokrnvesting/1.sol


pragma solidity ^0.8.0;



contract TokenVesting is Ownable {
    IERC20 public deodToken;
    address public admin;
    uint public totalAmountAlloted;

    struct VestingSchedule {
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 vestingDuration; // In days
        uint256 vestingCliff; // In days, the period where no tokens are released
        bool fullyClaimed; // Flag to indicate whether the schedule has been fully claimed or not
    }

    mapping(address => VestingSchedule[]) public vestingSchedules;

    event Allotment(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 endTime);

    constructor(address _deodTokenAddress) {
        deodToken = IERC20(_deodTokenAddress);
    }

    modifier onlyAdmin(){
        require(msg.sender==admin,"your are not admin");
        _;
    }
    function setVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingDuration,
        uint256 vestingCliff
    ) external onlyAdmin {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(vestingDuration > 0, "Vesting duration must be greater than zero");
        require(totalAmount > 0, "Total amount must be greater than zero");

        VestingSchedule memory newSchedule = VestingSchedule({
            startTime: block.timestamp,
            endTime: block.timestamp + vestingDuration * 1 minutes,
            totalAmount: totalAmount,
            claimedAmount: 0,
            vestingDuration: vestingDuration,
            vestingCliff: vestingCliff,
            fullyClaimed: false
        });

        vestingSchedules[beneficiary].push(newSchedule);
        totalAmountAlloted+=totalAmount;


        // Transfer the totalAmount to the contract
        require(deodToken.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed");

        emit Allotment(beneficiary, totalAmount, newSchedule.startTime, newSchedule.endTime);
    }

    function claimAllotment() external {
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];
        require(schedules.length > 0, "No allotment available");

        for (uint256 i = 0; i < schedules.length; i++) {
            if (!schedules[i].fullyClaimed && block.timestamp >= schedules[i].startTime) {
                uint256 claimableAmount = calculateClaimableAmount(schedules[i]);
                uint256 remainingClaimAmount = schedules[i].totalAmount - schedules[i].claimedAmount;

                if (claimableAmount > 0 && remainingClaimAmount > 0) {
                    if (remainingClaimAmount >= claimableAmount) {
                        schedules[i].claimedAmount += claimableAmount;
                        deodToken.transfer(msg.sender, claimableAmount);
                    } else {
                        schedules[i].claimedAmount += remainingClaimAmount;
                        deodToken.transfer(msg.sender, remainingClaimAmount);
                    }
                }

                // If all tokens from the schedule have been claimed, mark the schedule as fully claimed
                if (schedules[i].claimedAmount >= schedules[i].totalAmount) {
                    schedules[i].fullyClaimed = true;
                }
            }
        }
    }

    function calculateClaimableAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.startTime + schedule.vestingCliff * 1 minutes) {
            return 0;
        } else if (block.timestamp >= schedule.endTime) {
            return schedule.totalAmount - schedule.claimedAmount;
        } else {
            uint256 elapsedTime = block.timestamp - schedule.startTime - schedule.vestingCliff * 1 minutes;
            uint256 totalVestingTime = schedule.vestingDuration * 1 minutes;
            return (schedule.totalAmount * elapsedTime) / totalVestingTime - schedule.claimedAmount;
        }
    }

 

    function getContractBalance() external view returns (uint256) {
        return deodToken.balanceOf(address(this));
    }

   
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Invalid Admin address");
        admin=_adminAddress;
    }
}