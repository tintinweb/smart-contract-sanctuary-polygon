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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/MintableToken.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/common/IRepricingToken.sol";
import "../interfaces/common/IMintableToken.sol";
import "./CommonEventsAndErrors.sol";
import "./access/Operators.sol";

/// @notice A re-pricing token which implements the ERC20 interface.
/// Each minted RepricingToken represents 1 share.
/// 
///  pricePerShare = numShares * totalReserves / totalSupply
/// So operators can increase the totalReserves in order to increase the pricePerShare
abstract contract RepricingToken is IRepricingToken, ERC20, Ownable, Operators {
    using SafeERC20 for IERC20;

    /// @notice The token used to track reserves for this investment
    address public override immutable reserveToken;

    /// @notice The total number of `reserveToken()` this investment holds.
    uint256 public override totalReserves;

    event IssueSharesFromReserves(address indexed user, address indexed recipient, uint256 reserveTokenAmount, uint256 sharesAmount);
    event RedeemReservesFromShares(address indexed user, address indexed recipient, uint256 sharesAmount, uint256 reserveTokenAmount);
    event ReservesAdded(uint256 amount);
    event ReservesRemoved(uint256 amount);

    constructor(string memory _name, string memory _symbol, address _reserveToken) ERC20(_name, _symbol) {
        reserveToken = _reserveToken;
    }

    /// @notice Grant `_account` the operator role
    function addOperator(address _account) external override onlyOwner {
        _addOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    function removeOperator(address _account) external override onlyOwner {
        _removeOperator(_account);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /// @notice Returns the number of decimals used to get its user representation.
    /// @dev Uses the underlying reserve token's decimals
    function decimals() public view override returns (uint8) {
        return ERC20(reserveToken).decimals();
    }

    /// @notice The price for a single share in terms of the `reserveToken`
    function reservesPerShare() external view override returns (uint256) {
        return sharesToReserves(10 ** decimals());
    }
    
    // How many reserve tokens given a number of shares
    function sharesToReserves(uint256 shares) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        // Returns 0 if no shares yet allocated
        return (_totalSupply == 0)
            ? 0
            : shares * totalReserves / _totalSupply;
    }

    // How many reserve tokens given a number of shares
    function reservesToShares(uint256 reserves) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        // Returns shares = 1:1 if no shares yet allocated
        // Not worth having a special check for totalReserves=0, it can revert
        return (_totalSupply == 0)
            ? reserves
            : reserves * _totalSupply / totalReserves;
    }

    function _issueSharesFromReserves(
        uint256 reserveTokenAmount, 
        address recipient, 
        uint256 minSharesAmount
    ) internal returns (uint256 sharesAmount) {
        sharesAmount = reservesToShares(reserveTokenAmount);
        if (sharesAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        if (sharesAmount < minSharesAmount) revert CommonEventsAndErrors.Slippage(minSharesAmount, sharesAmount);

        // Mint shares to the user and add to the total reserves
        _mint(recipient, sharesAmount);
        _addReserves(reserveTokenAmount);
    }

    function _redeemReservesFromShares(
        uint256 sharesAmount, 
        address from, 
        uint256 minReserveTokenAmount
    ) internal returns (uint256 reserveTokenAmount) {
        if (balanceOf(from) < sharesAmount) revert CommonEventsAndErrors.InsufficientBalance(address(this), sharesAmount, balanceOf(from));

        reserveTokenAmount = sharesToReserves(sharesAmount);
        if (reserveTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        if (reserveTokenAmount < minReserveTokenAmount) revert CommonEventsAndErrors.Slippage(minReserveTokenAmount, reserveTokenAmount);

        // Burn the users shares and remove the reserves
        _burn(from, sharesAmount);
        _removeReserves(reserveTokenAmount);
    }

    function addReserves(uint256 amount) external override onlyOperators {
        _addReserves(amount);
        IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _addReserves(uint256 amount) private {
        totalReserves += amount;
        emit ReservesAdded(amount);
    }

    function removeReserves(uint256 amount) external override onlyOperators {
        _removeReserves(amount);
        IERC20(reserveToken).safeTransfer(msg.sender, amount);
    }

    function _removeReserves(uint256 amount) private {
        totalReserves -= amount;
        emit ReservesRemoved(amount);
    }        
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/IMintableToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice An ERC20 token which can be minted/burnt, granted by the CAN_MINT role.
interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/IRepricingToken.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice A re-pricing token which implements the ERC20 interface.
/// Each minted RepricingToken represents 1 share.
/// 
///  pricePerShare = numShares * totalReserves / totalSupply
/// So operators can increase the totalReserves in order to increase the pricePerShare
interface IRepricingToken is IERC20 {
    /// @notice The token used to track reserves for this investment
    function reserveToken() external view returns (address);

    /// @notice The total number of `reserveToken()` this investment holds.
    function totalReserves() external view returns (uint256);

    /// @notice The price for a single share in terms of the `reserveToken`
    function reservesPerShare() external view returns (uint256);

    /// @notice Add reserve tokens, increasing the pricePerShare()
    function addReserves(uint256 amount) external;

    /// @notice Remove reserve tokens, reducing the pricePerShare()
    function removeReserves(uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/ITokenPrices.sol)

/// @title Token Prices
/// @notice A utility contract to pull token prices from on-chain.
/// @dev composable functions (uisng encoded function calldata) to build up price formulas
interface ITokenPrices {
    /// @notice How many decimals places are the token prices reported in
    function decimals() external view returns (uint8);

    /// @notice Retrieve the price for a given token.
    /// @dev If not mapped, or an underlying error occurs, FailedPriceLookup will be thrown.
    /// @dev 0x000...0 is the native chain token (ETH/AVAX/etc)
    function tokenPrice(address token) external view returns (uint256 price);

    /// @notice Retrieve the price for a list of tokens.
    /// @dev If any aren't mapped, or an underlying error occurs, FailedPriceLookup will be thrown.
    /// @dev Not particularly gas efficient - wouldn't recommend to use on-chain
    function tokenPrices(address[] memory tokens) external view returns (uint256[] memory prices);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/IOrigamiInvestment.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Origami Investment
 * @notice Users invest in the underlying protocol and receive a number of this Origami investment in return.
 * Origami will apply the accepted investment token into the underlying protocol in the most optimal way.
 */
interface IOrigamiInvestment is IERC20 {
    /** 
     * @notice Emitted when a user makes a new investment
     * @param user The user who made the investment
     * @param fromTokenAmount The number of `fromToken` used to invest
     * @param fromToken The token used to invest, one of `acceptedInvestTokens()`
     * @param investmentAmount The number of investment tokens received, after fees
     **/
    event Invested(address indexed user, uint256 fromTokenAmount, address indexed fromToken, uint256 investmentAmount);

    /**
     * @notice Emitted when a user exists a position in an investment
     * @param user The user who exited the investment
     * @param investmentAmount The number of Origami investment tokens sold
     * @param toToken The token the user exited into
     * @param toTokenAmount The number of `toToken` received, after fees
     * @param recipient The receipient address of the `toToken`s
     **/
    event Exited(address indexed user, uint256 investmentAmount, address indexed toToken, uint256 toTokenAmount, address indexed recipient);

    /// @notice Errors for unsupported functions - for example if native chain ETH/AVAX/etc isn't a vaild investment
    error Unsupported();

    /**
     * @notice The set of accepted tokens which can be used to invest.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedInvestTokens() external view returns (address[] memory);

    /**
     * @notice The set of accepted tokens which can be used to exit into.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedExitTokens() external view returns (address[] memory);

    /**
     * @notice Quote data required when entering into this investment.
     */
    struct InvestQuoteData {
        /// @notice The token used to invest, which must be one of `acceptedInvestTokens()`
        address fromToken;

        /// @notice The quantity of `fromToken` to invest with
        uint256 fromTokenAmount;

        /// @notice The expected amount of this Origami Investment token to receive in return
        /// @dev Note slippage is applied to this when calling `invest()`
        uint256 expectedInvestmentAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Quote data required when exoomg this investment.
     */
    struct ExitQuoteData {
        /// @notice The amount of this investment to sell
        uint256 investmentTokenAmount;

        /// @notice The token to sell into, which must be one of `acceptedExitTokens()`
        address toToken;

        /// @notice The expected amount of `toToken` to receive in return
        /// @dev Note slippage is applied to this when calling `invest()`
        uint256 expectedToTokenAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Get a quote to buy this Origami investment using one of the accepted tokens. 
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return investFeeBps Any fees expected when investing with the given token, either from Origami or from the underlying investment.
     */
    function investQuote(
        uint256 fromTokenAmount, 
        address fromToken
    ) external view returns (
        InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );

    /** 
      * @notice User buys this Origami investment with an amount of one of the approved ERC20 tokens. 
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithToken(
        InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external returns (
        uint256 investmentAmount
    );

    /** 
      * @notice User buys this Origami investment with an amount of native chain token (ETH/AVAX)
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithNative(
        InvestQuoteData calldata quoteData, 
        uint256 slippageBps
    ) external payable returns (
        uint256 investmentAmount
    );

    /**
     * @notice Get a quote to sell this Origami investment to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentAmount The number of Origami investment tokens to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return exitFeeBps Any fees expected when exiting the investment to the nominated token, either from Origami or from the underlying investment.
     */
    function exitQuote(
        uint256 investmentAmount,
        address toToken
    ) external view returns (
        ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );

    /** 
      * @notice Sell this Origami investment to receive one of the accepted tokens.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmount The number of `toToken` tokens received upon selling the Origami investment tokens.
      */
    function exitToToken(
        ExitQuoteData calldata quoteData,
        uint256 slippageBps, 
        address recipient
    ) external returns (
        uint256 toTokenAmount
    );

    /** 
      * @notice Sell this Origami investment to native ETH/AVAX.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the native chain token.
      * @return nativeAmount The number of native chain ETH/AVAX/etc tokens received upon selling the Origami investment tokens.
      */
    function exitToNative(
        ExitQuoteData calldata quoteData, 
        uint256 slippageBps,
        address payable recipient
    ) external returns (
        uint256 nativeAmount
    );
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/staking/IOrigamiInvestmentManager.sol)

interface IOrigamiInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
    function performanceFeeRates(uint256 rewardTokenIndex) external view returns (
        uint128 numerator,
        uint128 denominator
    );
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/IOrigamiInvestmentShares.sol)

import "./IOrigamiInvestment.sol";
import "../common/IRepricingToken.sol";

/**
 * @title Origami Investment Shares
 * @notice A repricing Origami Investment. Users invest in the underlying protocol and receive Origami Investment Shares.
 * Origami will apply the supplied token into the underlying protocol in the most optimal way.
 * The pricePerShare() will increase over time as upstream rewards are claimed by the protocol added to the reserves.
 * This makes the Origami Investment Shares auto-compounding.
 */
interface IOrigamiInvestmentShares is IOrigamiInvestment, IRepricingToken {
    /**
     * @notice Annual Percentage Rate (APR) in basis points for this investment,
     * based on the projected rewards per share
     * @dev APR == [the total USD value of rewards (less fees) for one per year at current rates] / [USD value of the Origami investment shares total supply]
     */
    function apr() external view returns (uint256 aprBps);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (investments/OrigamiInvestmentShares.sol)

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/investments/IOrigamiInvestmentShares.sol"; 
import "../interfaces/investments/IOrigamiInvestmentManager.sol";
import "../interfaces/common/ITokenPrices.sol";
import "../common/RepricingToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Origami Investment Shares
 * @notice A repricing Origami Investment. Users invest in the underlying protocol and receive Origami Investment Shares.
 * Origami will apply the supplied token into the underlying protocol in the most optimal way.
 * The pricePerShare() will increase over time as upstream rewards are claimed by the protocol added to the reserves.
 * This makes the Origami Investment Shares auto-compounding.
 */
contract OrigamiInvestmentShares is IOrigamiInvestmentShares, RepricingToken, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The quote data required to exit from the underlying Origami Investment reserve token
    struct UnderlyingExitQuoteData {
        uint256 expectedReserveAmount;
        ExitQuoteData underlyingExitQuoteData;
    }

    /// @notice The helper contract to retrieve Origami USD prices
    ITokenPrices public tokenPrices;

    /// @notice The Origami investment manager contract, which can give apr/apy based rates 
    IOrigamiInvestmentManager public investmentManager;

    event InvestmentManagerSet(address indexed _investmentManager);
    event TokenPricesSet(address indexed _tokenPrices);

    constructor(
        string memory _name,
        string memory _symbol,
        address _origamiInvestment,
        address _tokenPrices
    ) RepricingToken(_name, _symbol, _origamiInvestment) {
        tokenPrices = ITokenPrices(_tokenPrices);
    }
    
    /** 
     * @notice Protocol can pause the investment.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /** 
     * @notice Protocol can unpause the investment.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function setInvestmentManager(address _investmentManager) external onlyOwner {
        if (_investmentManager == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        investmentManager = IOrigamiInvestmentManager(_investmentManager);
        emit InvestmentManagerSet(_investmentManager);
    }

    function setTokenPrices(address _tokenPrices) external onlyOwner {
        if (_tokenPrices == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        tokenPrices = ITokenPrices(_tokenPrices);
        emit TokenPricesSet(_tokenPrices);
    }
    
    /// @dev The reseve token is a valid invest/exit token, and needs to be appended.
    /// Unforunately needs to copy the input array as this is memory defined storage.
    function appendReserveToken(address[] memory items) private view returns (address[] memory newItems) {
        newItems = new address[](items.length+1);

        uint256 i;
        for (; i < items.length; ++i) {
            newItems[i] = items[i];
        }
        newItems[i] = reserveToken;
    }

    /**
     * @notice The set of accepted tokens which can be used to invest.
     * For the Origami Investment Shares, this is the underlying OrigamiInvestment's acceptedInvestTokens()
     * Plus the reserve token.
     */
    function acceptedInvestTokens() external override view returns (address[] memory) {
        return appendReserveToken(IOrigamiInvestment(reserveToken).acceptedInvestTokens());
    }

    /**
     * @notice The set of accepted tokens which can be used to exit into.
     * For the Origami Investment Shares, this is the underlying OrigamiInvestment's acceptedExitTokens()
     * Plus the reserve token.
     */
    function acceptedExitTokens() external override view returns (address[] memory tokens) {
        return appendReserveToken(IOrigamiInvestment(reserveToken).acceptedExitTokens());
    }

    /**
     * @notice Get a quote to buy Origami investment shares using one of the accepted tokens. 
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return investFeeBps Any fees expected when investing with the given token, either from Origami or from the underlying investment.
     */
    function investQuote(
        uint256 fromTokenAmount, 
        address fromToken
    ) external override view returns (
        InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    ) {
        if (fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // If investing with the reserve token, it's based off the current pricePerShare()
        // Otherwise first get a quote for the number of underlying reserve tokens using the fromToken
        // and then calculate the number of shares based off the current pricePerShare
        if (fromToken == reserveToken) {
            quoteData.fromToken = fromToken;
            quoteData.fromTokenAmount = fromTokenAmount;
            quoteData.expectedInvestmentAmount = reservesToShares(fromTokenAmount);
            // quoteData.underlyingInvestmentQuoteData remains as bytes(0)
        } else {
            // Get the underlying quote and encode into underlyingInvestmentQuoteData
            (quoteData, investFeeBps) = IOrigamiInvestment(reserveToken).investQuote(fromTokenAmount, fromToken);
            quoteData.underlyingInvestmentQuoteData = abi.encode(quoteData);

            // Now calculate how many shares that translates to.
            quoteData.expectedInvestmentAmount = reservesToShares(quoteData.expectedInvestmentAmount);
        }
    }

    function applySlippage(uint256 quote, uint256 slippageBps) internal pure returns (uint256) {
        return quote * (10_000 - slippageBps) / 10_000;
    }

    /** 
      * @notice User buys these Origami investment shares with an amount of one of the approved ERC20 tokens. 
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithToken(
        InvestQuoteData calldata quoteData,
        uint256 slippageBps
    ) external override whenNotPaused returns (
        uint256 investmentAmount
    ) {
        if (quoteData.fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // If investing with the reserve token, pull them from the user
        // Otherwise pull the fromToken and use to invest in the underlying Origami Investment
        uint256 reservesAmount;
        if (quoteData.fromToken == reserveToken) {
            // Pull the `reserveToken` from the user
            reservesAmount = quoteData.fromTokenAmount;
            IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), reservesAmount);
        } else {
            // Pull the `fromToken` into this contract and approve the reserveToken to pull it.
            IERC20(quoteData.fromToken).safeTransferFrom(msg.sender, address(this), quoteData.fromTokenAmount);
            IERC20(quoteData.fromToken).approve(reserveToken, quoteData.fromTokenAmount);

            // Use the `fromToken` to invest in the underlying and receive `reserveToken`           
            InvestQuoteData memory underlyingQuoteData = abi.decode(
                quoteData.underlyingInvestmentQuoteData, (InvestQuoteData)
            );
            reservesAmount = IOrigamiInvestment(reserveToken).investWithToken(
                underlyingQuoteData,
                slippageBps
            );
        }

        // Now issue shares to the user based off the `reserveAmount`
        investmentAmount = _issueSharesFromReserves(
            reservesAmount,
            msg.sender,
            applySlippage(quoteData.expectedInvestmentAmount, slippageBps)
        );
        emit Invested(msg.sender, quoteData.fromTokenAmount, quoteData.fromToken, investmentAmount);
    }

    /** 
      * @notice User buys these Origami investment shares with an amount of native chain token (ETH/AVAX)
      * @param quoteData The quote data received from investQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithNative(
        InvestQuoteData calldata quoteData,
        uint256 slippageBps
    ) external override whenNotPaused nonReentrant payable returns (
        uint256 investmentAmount
    ) {
        if (quoteData.fromTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        if (quoteData.fromTokenAmount != msg.value) revert CommonEventsAndErrors.InvalidAmount(address(0), msg.value);
        if (quoteData.fromToken != address(0)) revert CommonEventsAndErrors.InvalidToken(quoteData.fromToken);

        // Invest in the underlying first using the user supplied native ETH/AVAX
        InvestQuoteData memory underlyingQuoteData = abi.decode(
            quoteData.underlyingInvestmentQuoteData, (InvestQuoteData)
        );
        uint256 reservesAmount = IOrigamiInvestment(reserveToken).investWithNative{value: msg.value}(
            underlyingQuoteData,
            slippageBps
        );

        // Now issue shares to the user based off the `reserveAmount`
        investmentAmount = _issueSharesFromReserves(
            reservesAmount,
            msg.sender,
            applySlippage(quoteData.expectedInvestmentAmount, slippageBps)
        );
        emit Invested(msg.sender, quoteData.fromTokenAmount, address(0), investmentAmount);
    }

    /**
     * @notice Get a quote to sell Origami investment shares to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentAmount The number of Origami investment tokens to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return exitFeeBps Any fees expected when exiting the investment to the nominated token, either from Origami or from the underlying investment.
     */
    function exitQuote(
        uint256 investmentAmount, 
        address toToken
    ) external override view returns (
        ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    ) {
        if (investmentAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // If exiting to the reserve token, it's based off the current pricePerShare()
        // Otherwise first find the expected amount of reserves based on the current pricePerShare()
        // and then get a quote from the underlying Origami Investment for the number of toTokens to expect
        if (toToken == reserveToken) {
            // If it's the reserves, can redeem reserves directly from the shares.
            quoteData.investmentTokenAmount = investmentAmount;
            quoteData.toToken = toToken;
            quoteData.expectedToTokenAmount = sharesToReserves(investmentAmount);
            // quoteData.underlyingInvestmentQuoteData remains as bytes(0)
        } else {
            uint256 expectedReserveAmount = sharesToReserves(investmentAmount);
            (quoteData, exitFeeBps) = IOrigamiInvestment(reserveToken).exitQuote(
                expectedReserveAmount, toToken
            );

            // The underlyingInvestmentQuoteData also contains the expected amount of reserves such that
            // the intermediate slippage can be checked
            quoteData = ExitQuoteData({
                investmentTokenAmount: investmentAmount,
                toToken: toToken,
                expectedToTokenAmount: quoteData.expectedToTokenAmount,
                underlyingInvestmentQuoteData: abi.encode(
                    UnderlyingExitQuoteData({
                        expectedReserveAmount: expectedReserveAmount, 
                        underlyingExitQuoteData: quoteData
                    })
                )
            });
        }
    }

    /** 
      * @notice Sell these Origami investment shares to receive one of the accepted tokens.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmount The number of `toToken` tokens received upon selling the Origami investment tokens.
      */
    function exitToToken(
        ExitQuoteData calldata quoteData, 
        uint256 slippageBps, 
        address recipient
    ) external override whenNotPaused returns (
        uint256 toTokenAmount
    ) {
        if (quoteData.investmentTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();

        // If exiting to the reserve token, redeem and send them to the user
        // Otherwise first redeem the reserve tokens and then exit the underlying Origami investment
        if (quoteData.toToken == reserveToken) {
            toTokenAmount = _redeemReservesFromShares(
                quoteData.investmentTokenAmount,
                msg.sender,
                applySlippage(quoteData.expectedToTokenAmount, slippageBps)
            );
            IERC20(reserveToken).safeTransfer(msg.sender, toTokenAmount);
        } else {
            UnderlyingExitQuoteData memory underlyingQuoteData = abi.decode(
                quoteData.underlyingInvestmentQuoteData, (UnderlyingExitQuoteData)
            );
            uint256 reserveAmount = _redeemReservesFromShares(
                quoteData.investmentTokenAmount,
                msg.sender,
                applySlippage(underlyingQuoteData.expectedReserveAmount, slippageBps)
            );

            // Update the underlying quote data with the actual amount of reserves we received.
            underlyingQuoteData.underlyingExitQuoteData.investmentTokenAmount = reserveAmount;

            // Now exchange the reserve token to the actual token the user requested.
            toTokenAmount = IOrigamiInvestment(reserveToken).exitToToken(
                underlyingQuoteData.underlyingExitQuoteData,
                slippageBps,
                recipient
            );
        }
        emit Exited(msg.sender, quoteData.investmentTokenAmount, quoteData.toToken, toTokenAmount, recipient);
    }

    /** 
      * @notice Sell this Origami investment to native ETH/AVAX.
      * @param quoteData The quote data received from exitQuote()
      * @param slippageBps Acceptable slippage, applied to the `quoteData` params
      * @param recipient The receiving address of the native chain token.
      * @return nativeAmount The number of native chain ETH/AVAX/etc tokens received upon selling the Origami investment tokens.
      */
    function exitToNative(
        ExitQuoteData calldata quoteData, 
        uint256 slippageBps, 
        address payable recipient
    ) external override whenNotPaused nonReentrant returns (uint256 nativeAmount) {
        if (quoteData.investmentTokenAmount == 0) revert CommonEventsAndErrors.ExpectedNonZero();
        if (quoteData.toToken != address(0)) revert CommonEventsAndErrors.InvalidToken(quoteData.toToken);

        // Otherwise first redeem the reserve tokens and then exit the underlying Origami investment
        UnderlyingExitQuoteData memory underlyingQuoteData = abi.decode(
            quoteData.underlyingInvestmentQuoteData, (UnderlyingExitQuoteData)
        );
        uint256 reserveAmount = _redeemReservesFromShares(
            quoteData.investmentTokenAmount,
            msg.sender,
            applySlippage(underlyingQuoteData.expectedReserveAmount, slippageBps)
        );

        // Update the underlying quote data with the actual amount of reserves we received.
        underlyingQuoteData.underlyingExitQuoteData.investmentTokenAmount = reserveAmount;

        // Now exchange the reserve token to the actual token the user requested.
        nativeAmount = IOrigamiInvestment(reserveToken).exitToNative(
            underlyingQuoteData.underlyingExitQuoteData,
            slippageBps, 
            recipient
        );
        emit Exited(msg.sender, quoteData.investmentTokenAmount, address(0), nativeAmount, recipient);
    }

    /**
     * @notice Annual Percentage Rate (APR) in basis points for this investment,
     * based on the projected reward rates as of now.
     * @dev APR == [the total USD value of rewards (less fees) for one per year at current rates] / [USD value of the Origami investment shares total supply]
     */
    function apr() public override view returns (uint256 aprBps) {
        uint256[] memory projectedRewardRates = investmentManager.projectedRewardRates();  // 1e18 precision
        uint256[] memory rewardTokenPricesUsd = tokenPrices.tokenPrices(investmentManager.rewardTokensList()); // 1e30 precision

        // Accumulate the USD value of rewards for the year, based on the current projected reward rates per second.
        uint256 projectedRewardsUsdPerSec;
        for (uint256 i; i < projectedRewardRates.length; ++i) {
            projectedRewardsUsdPerSec += projectedRewardRates[i] * rewardTokenPricesUsd[i];
        }
        uint256 projectedRewardsUsdPerYear = projectedRewardsUsdPerSec * 365 days; // 1e48 precision

        // Calculate the USD value of all shares
        // 1e48 precision (18 + 30)
        uint256 totalSharesUsd = 
            totalSupply() *
            tokenPrices.tokenPrice(address(this));

        aprBps = (totalSharesUsd == 0) ? 0 : 10_000 * projectedRewardsUsdPerYear / totalSharesUsd;
    }
}