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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity 0.8.13;

import "./DSMath.sol";

/**
 * @title Core
 * @notice Handles math operations of Platypus protocol.
 * @dev Uses DSMath to compute using WAD and RAY.
 */
contract Core {
    using DSMath for uint256;

    /// @notice WAD unit. Used to handle most numbers.
    uint256 internal constant WAD = 10**18;

    /// @notice RAY unit. Used for rpow function.
    uint256 internal constant RAY = 10**27;

    /// @notice Accommodates unforeseen upgrades to Core.
    bytes32[64] internal emptyArray;

    /**
     * @notice Yellow Paper Def. 2.4 (Price Slippage Curve)
     * @dev Calculates g(xr,i) or g(xr,j). This function always returns >= 0
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param x coverage ratio of asset in WAD
     * @return The result of price slippage curve
     */
    function _slippageFunc(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 x
    ) internal pure returns (uint256) {
        if (x < xThreshold) {
            return c1 - x;
        } else {
            return k.wdiv((((x * RAY) / WAD).rpow(n) * WAD) / RAY); // k / (x ** n)
        }
    }

    /**
     * @notice Yellow Paper Def. 2.4 (Asset Slippage)
     * @dev Calculates -Si or -Sj (slippage from and slippage to)
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param cashChange cashChange of asset in WAD
     * @param addCash true if we are adding cash, false otherwise
     * @return The result of one-sided asset slippage
     */
    function _slippage(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 cashChange,
        bool addCash
    ) internal pure returns (int256) {
        uint256 covBefore = cash.wdiv(liability);
        uint256 covAfter;
        if (addCash) {
            covAfter = (cash + cashChange).wdiv(liability);
        } else {
            covAfter = (cash - cashChange).wdiv(liability);
        }

        // if cov stays unchanged, slippage is 0
        if (covBefore == covAfter) {
            return 0;
        }

        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);

        if (covBefore > covAfter) {
            uint256 relativeSlippage = (slippageAfter - slippageBefore).wdiv(
                covBefore - covAfter
            );
            return int256(cash.wmul(relativeSlippage));
            // returns relative slippage
            // returns cash.wmul(relative slippage)
            // return (slippageAfter - slippageBefore).wdiv(covBefore - covAfter);
        } else {
            uint256 relativeSlippage = (slippageBefore - slippageAfter).wdiv(
                covAfter - covBefore
            );
            // returns  cash.wmul(relative slippage)
            return -int256(cash.wmul(relativeSlippage));
            // return  (slippageBefore - slippageAfter).wdiv(covAfter - covBefore);
        }
    }

    /**
     * @notice Yellow Paper Def. 2.5 (Swapping Slippage). Calculates 1 - (Si - Sj).
     * Uses the formula 1 + (-Si) - (-Sj), with the -Si, -Sj returned from _slippage
     * @dev Adjusted to prevent dealing with underflow of uint256
     * @param si -si slippage parameter in WAD
     * @param sj -sj slippage parameter
     * @return The result of swapping slippage (1 - Si->j)
     */
    function _swappingSlippage(uint256 si, uint256 sj)
        internal
        pure
        returns (uint256)
    {
        return WAD + si - sj;
    }

    /**
     * @notice Yellow Paper Def. 4.0 (Haircut).
     * @dev Applies haircut rate to amount
     * @param amount The amount that will receive the discount
     * @param rate The rate to be applied
     * @return The result of operation.
     */
    function _haircut(uint256 amount, uint256 rate)
        internal
        pure
        returns (uint256)
    {
        return amount.wmul(rate);
    }

    /**
     * @notice Applies dividend to amount
     * @param amount The amount that will receive the discount
     * @param ratio The ratio to be applied in dividend
     * @return The result of operation.
     */
    function _dividend(uint256 amount, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        return amount.wmul(WAD - ratio);
    }

    /**
     * @dev When covBefore >= 1, fee is 0
     * @dev When covBefore < 1, we apply a fee to prevent withdrawal arbitrage
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param liability liability position of asset in WAD
     * @param amount amount to be withdrawn in WAD
     * @return The final fee to be applied
     */
    function _withdrawalFee(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 amount
    ) internal pure returns (int256) {
        uint256 covBefore = cash.wdiv(liability);
        if (covBefore >= WAD) {
            return 0;
        }

        if (liability <= amount) {
            return 0;
        }

        uint256 cashAfter;
        // Cover case where cash <= amount
        if (cash > amount) {
            cashAfter = cash - amount;
        } else {
            cashAfter = 0;
        }

        uint256 covAfter = (cashAfter).wdiv(liability - amount);
        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);
        uint256 slippageNeutral = _slippageFunc(k, n, c1, xThreshold, WAD); // slippage on cov = 1

        // calculate fee
        // fee = a - b
        // fee = [(Li - Di) * SlippageAfter] + [g(1) * Di] - [Li * SlippageBefore]
        uint256 a = ((liability - amount).wmul(slippageAfter) +
            slippageNeutral.wmul(amount));
        uint256 b = liability.wmul(slippageBefore);

        return int256(a) - int256(b);
    }

    /**
     * @notice Yellow Paper Def. 6.2 (Arbitrage Fee) / Deposit fee
     * @dev When covBefore <= 1, fee is 0
     * @dev When covBefore > 1, we apply a fee to prevent deposit arbitrage
     * @param k K slippage parameter in WAD
     * @param n N slippage parameter
     * @param c1 C1 slippage parameter in WAD
     * @param xThreshold xThreshold slippage parameter in WAD
     * @param cash cash position of asset in WAD
     * @param liability liability position of asset in WAD
     * @param amount amount to be deposited in WAD
     * @return The final fee to be applied
     */
    function _depositFee(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 amount
    ) internal pure returns (int256) {
        // cover case where the asset has no liquidity yet
        if (liability == 0) {
            return 0;
        }

        uint256 covBefore = cash.wdiv(liability);
        if (covBefore <= WAD) {
            return 0;
        }

        uint256 covAfter = (cash + amount).wdiv(liability + amount);
        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);

        // (Li + Di) * g(cov_after) - Li * g(cov_before)
        return
            int256(((liability + amount).wmul(slippageAfter)) -
            (liability.wmul(slippageBefore)));
    }
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library DSMath {
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    function reciprocal(uint256 x) internal pure returns (uint256) {
        return wdiv(WAD, x);
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (RAY / 2)) / RAY;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapPoolPermissioned.sol";
import "./Core.sol";


contract SwapPool is
    ERC20,
    Pausable,
    ReentrancyGuard,
    Ownable,
    Core,
    ISwapPoolPermissioned
{
    uint256 private constant ETH_UNIT = 10**18;

    address public chef;
    address public oracle;
    IERC20 immutable asset;

    /// @notice Slippage parameters K, N, C1 and xThreshold
    uint256 private _slippageParamK;
    uint256 private _slippageParamN;
    uint256 private _c1;
    uint256 private _xThreshold;

    modifier onlyChef() {
        // require(msg.sender == address(chef), "SwapPool: ONLY_CHEF");
        _;
    }

    constructor(
        address _oracle,
        address _asset,
        address _chef,
        string memory _name,
        string memory sybol
    ) ERC20(_name, sybol) {
        asset = IERC20(_asset);
        oracle = _oracle;
        chef = _chef;

        // set variables
        _slippageParamK = 0.00002e18; //2 * 10**13 == 0.00002 * WETH
        _slippageParamN = 7; // 7
        _c1 = 376927610599998308; // ((k**(1/(n+1))) / (n**((n)/(n+1)))) + (k*n)**(1/(n+1))
        _xThreshold = 329811659274998519; // (k*n)**(1/(n+1))
    }

    /**
     * @notice Changes the pools slippage params. Can only be set by the contract owner.
     * @param k_ new pool's slippage param K
     * @param n_ new pool's slippage param N
     * @param c1_ new pool's slippage param C1
     * @param xThreshold_ new pool's slippage param xThreshold
     */
    function setSlippageParams(
        uint256 k_,
        uint256 n_,
        uint256 c1_,
        uint256 xThreshold_
    ) external onlyOwner {
        require(k_ <= ETH_UNIT); // k should not be set bigger than 1
        require(n_ > 0); // n should be bigger than 0

        _slippageParamK = k_;
        _slippageParamN = n_;
        _c1 = c1_;
        _xThreshold = xThreshold_;
    }

    /**
     * @notice Deposits amount of tokens into pool
     * @notice will change cov ratio of pool, will increase delta to 0
     * @param _amount The amount to be deposited
     * @return liablityToMint Total asset liquidity minted
     */
    function deposit(uint256 _amount)
        external
        returns (uint256 liablityToMint)
    {
        uint256 tSMemory = totalSupply();

        if(tSMemory == 0) {
             liablityToMint = _amount;
        } else {
            uint256 balanceBefore = asset.balanceOf(address(this));
            int256 slippage = _depositFee(
                _slippageParamK,
                _slippageParamN,
                _c1,
                _xThreshold,
                balanceBefore,
                tSMemory,
                _amount
            );
            liablityToMint = uint256(int256(_amount * tSMemory / balanceBefore) + slippage);
        }


        require(liablityToMint > 0, "INSUFFICIENT_SHARES_MINT");
        _mint(msg.sender, liablityToMint);
        asset.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraws liquidity amount of asset ensuring minimum amount required
     * @param _shares The liquidity to be withdrawn
     * @param _minimumAmount The minimum amount that will be accepted by user
     */
    function withdraw(uint256 _shares, uint256 _minimumAmount)
        external
        nonReentrant
        returns (uint256 finalAmount, int256 slippage)
    {
        require(balanceOf(msg.sender) >= _shares, "SwapPool#withdraw: BALANCE");
        uint256 balanceBefore = asset.balanceOf(address(this));

        int256 amountInt256 = int256((_shares  * balanceBefore) / totalSupply());
        require(amountInt256 > 0, "INSUFFICIENT_LIQ_BURN");

        slippage = _withdrawalFee(
            _slippageParamK,
            _slippageParamN,
            _c1,
            _xThreshold,
            balanceBefore,
            totalSupply(),
            uint256(amountInt256)
        );
        // need to revise this section, as not known if this case is possible
        require(amountInt256 > slippage, "SwapPool#withdraw: SLIPPAGE_TO_HIGH");        

        require(
            amountInt256 - slippage >= int256(_minimumAmount),
            "SwapPool#withdraw: MINIMUM_AMOUNT"
        );

        finalAmount = uint256(amountInt256 - slippage);
        _burn(msg.sender, _shares);
        IERC20(asset).transfer(msg.sender, finalAmount);
    }

    /**
     * @notice Burns LP tokens of owner while imporiving coverage ratio
     * @notice Can only be called by IChef, as IChef will call in case of backstop-pool-withdrawal
     * @param _owner The address the LP's should be burned of
     * @param _amount The amount of LP's to burn
     * @return burned The amount burned
     */
    function burn(address _owner, uint256 _amount)
        external
        onlyChef
        returns (uint256 burned)
    {
        require(balanceOf(_owner) >= _amount, "SwapPool#burn: BALANCE_TO_LOW");
        _burn(_owner, _amount);
        return _amount;
    }

    /**
     * @notice get called by IChef to deposit an amount of pool asset
     * @notice Can only be called by IChef
     * @param _amount The amount of asset to deposit
     * @return rewardOrPenalty depending on improving or worsening cov ratio
     * @return effectiveAmount actual deposited amount
     */
    function swapIntoFromChef(uint256 _amount)
        external
        onlyChef
        returns (int256 rewardOrPenalty, uint256 effectiveAmount)
    {
        asset.transferFrom(msg.sender, address(this), _amount);

        rewardOrPenalty = _slippage(
            _slippageParamK,
            _slippageParamN,
            _c1,
            _xThreshold,
            asset.balanceOf(address(this)),
            totalSupply(),
            _amount,
            true
        );

        effectiveAmount = uint256(int256(_amount) + rewardOrPenalty);
    }

    /**
     * @notice get called by IChef to withdraw amount of pool asset
     * @notice Can only be called by IChef
     * @param _amount The amount of asset to withdraw
     * @return rewardOrPenalty depending on improving or worsening cov ratio
     * @return effectiveAmount actual withdraw amount
     */
    function swapOutFromChef(uint256 _amount)
        external
        onlyChef
        returns (int256 rewardOrPenalty, uint256 effectiveAmount)
    {

        rewardOrPenalty = _slippage(
            _slippageParamK,
            _slippageParamN,
            _c1,
            _xThreshold,
            asset.balanceOf(address(this)),
            totalSupply(),
            _amount,
            true
        );

        effectiveAmount = uint256(int256(_amount) + rewardOrPenalty);
        asset.transfer(msg.sender, effectiveAmount);
    }

    /**
     * @notice gets pool coverage ratio
     * @return numerator as total liabilities and denominator as total cash
     */
    function getCoverage()
        external
        view
        returns (uint256 numerator, uint256 denominator)
    {
        numerator = totalSupply();
        denominator = asset.balanceOf(address(this));
    }

    // // Just forwards call to IRewardTreasury
    // function harvest() external returns (uint256);

    //   // Attention: Bad API. Loss of precision for assets ar very low price.
    // function price() external view returns (address, uint256);

    // function pendingReward() external view returns (uint256);
    // function rewardToken() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapPoolPermissioned {
    // for backstop withdrawal
    function burn(address owner, uint256 amount)
        external
        returns (uint256 burned);

    function swapIntoFromChef(uint256 amount)
        external
        returns (int256 rewardOrPenalty, uint256 effectiveAmount);

    function swapOutFromChef(uint256 amount)
        external
        returns (int256 rewardOrPenalty, uint256 effectiveAmount);
}