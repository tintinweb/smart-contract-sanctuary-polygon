// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLock {
    address public manager;

    address public locker;
    address lockedToken;
    uint256 public lockedAmount;
    uint256 public claimed;
    uint256 public releaseStartTime;
    uint256 public releaseEndTime;
    uint256 public releaseRate;

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    constructor(address _lockedToken) {
        require(_lockedToken != address(0), "Locked token address is zero");
        lockedToken = _lockedToken;
        manager = msg.sender;
    }

    function lock(
        uint256 _lockedAmount,
        uint256 _releaseStartTime,
        uint256 _releaseEndTime,
        address _locker
    ) external {
        require(
            IERC20(lockedToken).balanceOf(address(this)) == _lockedAmount,
            "lockedAmount invalid"
        );
        require(
            _releaseStartTime > block.timestamp,
            "releaseStartTime must be greater than current time"
        );
        require(
            _releaseStartTime < _releaseEndTime,
            "releaseStartTime must be less than releaseEndTime"
        );
        require(_locker != address(0), "lock address invalid");
        lockedAmount = _lockedAmount;
        releaseStartTime = _releaseStartTime;
        releaseEndTime = _releaseEndTime;
        releaseRate = lockedAmount / (_releaseEndTime - _releaseStartTime);
        locker = _locker;
    }

    function canClaim() public view returns (uint256) {
        require(block.timestamp >= releaseStartTime, "not start");
        require(lockedAmount > 0, "not locked");
        uint256 canClaimTotal = (block.timestamp - releaseStartTime) *
            releaseRate;
        return canClaimTotal - claimed;
    }

    function claim() public returns (uint256) {
        require(msg.sender == locker, "Only locker");
        uint256 canClaimAmount = canClaim();
        require(canClaimAmount > 0, "can't claim");

        // TODO math check
        if (IERC20(lockedToken).balanceOf(address(this)) < canClaimAmount) {
            canClaimAmount = IERC20(lockedToken).balanceOf(address(this));
        }

        claimed += canClaimAmount;
        IERC20(lockedToken).transfer(msg.sender, canClaimAmount);
        return canClaimAmount;
    }
}