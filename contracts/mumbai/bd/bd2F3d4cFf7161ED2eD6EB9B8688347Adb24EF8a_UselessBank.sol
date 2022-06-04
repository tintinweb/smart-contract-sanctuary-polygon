// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./abstract/Base.sol";
import "./interfaces/IUselessBank.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UselessBank is IUselessBank, Base {
    address private immutable i_owner;

    /// @notice Stores the user's balance of a certain token.
    /// User -> Token -> Balance
    mapping(address => mapping(IERC20 => uint256)) private s_balanceOf;

    /// @notice Stores whether a certain token is allowed to be used.
    mapping(IERC20 => bool) private s_allowedTokens;

    constructor() {
        i_owner = msg.sender;
    }

    /* -------------------------------- Modifiers ------------------------------- */
    modifier checkAllowedToken(IERC20 _token) {
        if (!s_allowedTokens[_token]) revert UnauthorizedToken(_token);
        _;
    }

    /* -------------------------------- Functions ------------------------------- */
    function deposit(IERC20 _token, uint256 _amount)
        external
        override
        checkNonZeroAddress(address(_token))
        checkNonZeroValue(_amount)
        checkAllowedToken(_token)
    {
        s_balanceOf[msg.sender][_token] += _amount;
        _token.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _token, _amount);
    }

    function withdraw(IERC20 _token, uint256 _amount)
        external
        override
        checkAllowedToken(_token)
    {
        if (s_balanceOf[msg.sender][_token] < _amount)
            revert NotEnoughBalance();

        s_balanceOf[msg.sender][_token] -= _amount;
        _token.transfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _token, _amount);
    }

    function authorizeToken(IERC20 _token, bool _allow)
        external
        override
        checkExpectedCaller(msg.sender, i_owner)
    {
        s_allowedTokens[_token] = _allow;

        emit TokenUpdated(_token, _allow);
    }

    /* ---------------------------------- Views --------------------------------- */
    function getBalanceOf(IERC20 _token, address _user)
        external
        view
        override
        returns (uint256 balance)
    {
        balance = s_balanceOf[_user][_token];
    }

    function getOwner() external view returns (address owner) {
        owner = i_owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../error/Errors.sol";

/// @title Base
/// @author @C-Mierez
/// @notice Base contract that defines commonly used modifiers for other contracts
/// to inherit.
abstract contract Base {
    /* -------------------------------- Modifiers ------------------------------- */
    modifier checkNonZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    modifier checkNonZeroValue(uint256 value) {
        if (value == 0) revert ZeroValue();
        _;
    }

    modifier checkExpectedCaller(address caller, address expected) {
        if (caller != expected) revert UnexpectedCaller(caller, expected);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUselessBank {
    /* --------------------------------- Structs -------------------------------- */

    /* --------------------------------- Events --------------------------------- */
    event Deposited(address user, IERC20 token, uint256 amount);
    event Withdrawn(address user, IERC20 token, uint256 amount);
    event TokenUpdated(IERC20 token, bool allow);

    /* --------------------------------- Errors --------------------------------- */
    /// @notice Emitted when the user's balance is lower than requested.
    error NotEnoughBalance();

    /// @notice Emitted when the submitted token is not allowed.
    error UnauthorizedToken(IERC20 token);

    /* -------------------------------- Functions ------------------------------- */

    function deposit(IERC20 _token, uint256 _amount) external;

    function withdraw(IERC20 _token, uint256 _amount) external;

    function authorizeToken(IERC20 _token, bool _allow) external;

    /* ---------------------------------- Views --------------------------------- */

    function getBalanceOf(IERC20 _token, address _user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* -------------------------- Global Custom Errors -------------------------- */

/// @notice Emitted when the submitted address is the zero address
error ZeroAddress();

/// @notice Emitted when the submitted value is zero.
error ZeroValue();

/// @notice Emitted when the submitted value is zero or less
/// @dev Technically uint can't be negative, so it wouldn't make
/// sense for this error to happen when [value] is an uint.
/// Hence I'm defining it as an int256 instead.
error ZeroOrNegativeValue(int256 value);

/// @notice Emitted when the caller is not the expected address
error UnexpectedCaller(address caller, address expected);

/// @notice Emitted when the caller does not have the required permissions
error UnauthorizedCaller(address caller);

/* ---------------------------- ERC Token Errors ---------------------------- */

/// @notice Emitted when the address does not have enough token balance
error NotEnoughBalance(address caller, uint256 expected);

/// @notice Emitted when an ERC20 transfer fails. Catching boolean return from
/// the transfer methods.
/// @dev I believe it makes sense to return all the information below, since this
/// error just catches any kind of failure. It'd likely be useful to have this
/// information to understand what exactly went wrong.
error ERC20TransferFailed(address from, address to, uint256 amount);

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