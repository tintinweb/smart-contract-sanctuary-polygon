// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../access/Ownable.sol";
import "../utils/SafeMathMC.sol";
import "../../contracts-upgradable/token/ERC20/IERC20Upgradeable.sol";


contract MeetcapTimeLock is Ownable {
    using SafeMathX for uint256;

    // Beneficiary
    address private immutable _beneficiary;

    // Token address
    IERC20Upgradeable private immutable _token;

    // Total amount of locked tokens
    uint256 private immutable _totalAllocation;

    // Total amount of tokens have been released
    uint256 private _releasedAmount;

    // Current release phase
    uint32 private _releaseId;

    // Lock duration (in seconds) of each phase
    uint32[] private _lockDurations;

    // Release percent of each phase
    uint32[] private _releasePercents;

    // Dates the beneficiary executes a release for each phase
    uint64[] private _releaseDates;

    // Start date of the lockup period
    uint64 private immutable _startTime;

    event Released(
        uint256 releasableAmount,
        uint32 toIdx
    );

    constructor(
        address beneficiary_,
        IERC20Upgradeable token_,
        uint256 totalAllocation_,
        uint32[] memory lockDurations_,
        uint32[] memory releasePercents_,
        uint64 startTime_
    ) {
        require(
            lockDurations_.length == releasePercents_.length,
            "Unlock length does not match"
        );

        uint256 _sum;
        for (uint256 i = 0; i < releasePercents_.length; ++i) {
            _sum += releasePercents_[i];
        }

        require(
            _sum == 100, 
            "Total unlock percent is not equal to 100"
        );

        require(
            beneficiary_ != address(0),
            "Beneficiary address cannot be the zero address"
        );

        require(
            address(token_) != address(0), 
            "Token address cannot be the zero address"
        );

        require(
            totalAllocation_ > 0, 
            "The total allocation must be greater than zero"
        );

        _beneficiary = beneficiary_;
        _token = token_;
        _startTime = startTime_;
        _lockDurations = lockDurations_;
        _releasePercents = releasePercents_;
        _totalAllocation = totalAllocation_;
        _releasedAmount = 0;
        _releaseId = 0;
        _releaseDates = new uint64[](_lockDurations.length);
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function token() public view virtual returns (IERC20Upgradeable) {
        return _token;
    }

    function totalAllocation() public view virtual returns (uint256) {
        return _totalAllocation;
    }

    function releasedAmount() public view virtual returns (uint256) {
        return _releasedAmount;
    }

    function releaseId() public view virtual returns (uint32) {
        return _releaseId;
    }

    function lockDurations() public view virtual returns (uint32[] memory) {
        return _lockDurations;
    }

    function releasePercents() public view virtual returns (uint32[] memory) {
        return _releasePercents;
    }

    function releaseDates() public view virtual returns (uint64[] memory) {
        return _releaseDates;
    }

    function startTime() public view virtual returns (uint64) {
        return _startTime;
    }

    /// @notice Release unlocked tokens to user.
    /// @dev User (sender) can release unlocked tokens by calling this function.
    /// This function will release locked tokens from multiple lock phases that meets unlock requirements
       function release() public virtual returns (bool) {
        uint256 phases = _lockDurations.length;
        _preValidateRelease(phases);

        uint256 preReleaseId = _releaseId;
        uint256 releasableAmount = _releasableAmount(phases);
        
        _releasedAmount += releasableAmount;
        _token.transfer(_beneficiary, releasableAmount);

        uint64 releaseDate = uint64(block.timestamp);

        for (uint256 i = preReleaseId; i < _releaseId; ++i) {
            _releaseDates[i] = releaseDate;
        }

        emit Released(
            releasableAmount,
            _releaseId
        );

        return true;
    }

    /// @dev This is for safety.
    /// For example, when someone setup the contract with wrong data and accidentally transfer token to the lockup contract.
    /// The owner can get the token back by calling this function.
    /// The ownership is renounced right after the setup is done safely.
    function safeSetup() public virtual onlyOwner returns (bool) {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(owner(), balance);

        return true;
    }

    function _preValidateRelease(uint256 phases) internal view virtual {
        require(
            _releaseId < phases,
            "All phases have already been released"
        );
        require(
            block.timestamp >=
                _startTime + _lockDurations[_releaseId] * 1 seconds,
            "Current time is before release time"
        );
    }

    function _releasableAmount(uint256 phases) internal virtual returns (uint256) {
        uint256 releasableAmount;      
        while (
            _releaseId < phases && block.timestamp >=
            _startTime + _lockDurations[_releaseId] * 1 seconds
        ) {
            uint256 stepReleaseAmount;
            if (_releaseId == phases - 1) {
                releasableAmount = _totalAllocation - _releasedAmount;
            } else {
                stepReleaseAmount = _totalAllocation.mulScale(
                    _releasePercents[_releaseId]
                );
                releasableAmount += stepReleaseAmount;

            }
            _releaseId++;
        }
        return releasableAmount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
pragma solidity ^0.8.9;


library SafeMathX {
    // Calculate x * y / 100 rounding down.
    function mulScale(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        uint256 a = x / 100;
        uint256 b = x % 100;
        uint256 c = y / 100;
        uint256 d = y % 100;

        return a * c * 100 + a * d + b * c + (b * d) / 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.9;

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