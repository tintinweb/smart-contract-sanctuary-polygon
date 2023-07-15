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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingPool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //Stores All User Info
    struct UserInfo {
        uint256 balance; //User Balance
        uint256 lastClaimed; //Last Claim Timestamp
        uint256 pendingRewards; //Pending Rewards from withdrawn amount
        mapping(uint256 => uint256) depositAmount; //index => amount
        mapping(uint256 => uint256) depositTimestamp; //index => timestamp
        uint256 first; //first index for deposit timestamp queue
        uint256 last; //last index for deposit timestamp queue
    }

    mapping(address => UserInfo) public userInfo;

    uint256 public constant SCALING_FACTOR = 1e10;
    uint256 public constant MAX_WITHDRAWAL_FEE = 10000;
    uint256 public constant MAX_REWARD_RATE = 10000 * SCALING_FACTOR;

    IERC20 public stakingToken; // ERC20 Staking Token Address
    IERC20 public rewardToken; // ERC20 Reward Token Address
    uint256 public startTimestamp; //Staking Pool Start Timestamp
    uint256 public withdrawalFee; // Fee * 100 Example: 2% = 200
    uint256 public poolBalance; //Total staking token in the Pool
    uint256 public lockupDuration; //Duration in days before which withdrawals will be levied withdrawal fee.

    uint256 public minDepositAmount = 1;
    uint256 public maxDepositAmount = type(uint256).max;
    uint256 public maxUserBalance = type(uint256).max;
    uint256 public maxCap = type(uint256).max;

    address public feeRecipient;

    uint256[] public rewardRate; //Array of APR values
    uint256[] public rewardRateTimestamp; //Array of APR change timestamps

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event Claim(address user, uint256 amount);

    /**
     * @dev Sets value for staking token address, reward token, withdrawal fee, lockup duration(in days),
     * address of fee recipient, reward rate (for 2% enter 200) and max user balance
     */
    constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _withdrawalFee,
        uint256 _lockupDuration,
        address _feeRecipient,
        uint256 _rewardRate,
        uint256 _maxUserBalance
    ) {
        require(_withdrawalFee < MAX_WITHDRAWAL_FEE, "Invalid fee");
        require(_rewardRate < MAX_REWARD_RATE, "Invalid reward rate");
        require(
            _feeRecipient != address(0) &&
                address(_rewardToken) != address(0) &&
                address(_stakingToken) != address(0),
            "No zero address"
        );
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        withdrawalFee = _withdrawalFee;
        lockupDuration = _lockupDuration;
        feeRecipient = _feeRecipient;
        rewardRate.push(0);
        rewardRateTimestamp.push(0);
        rewardRate.push(_rewardRate);
        maxUserBalance = _maxUserBalance;
    }

    /**
     * @dev Function to start staking allowing users to deposit
     *
     * Start block is set to current block timestamp
     *
     */
    function startStaking() external onlyOwner {
        require(startTimestamp == 0, "Staking already started");
        startTimestamp = block.timestamp;
        rewardRateTimestamp.push(startTimestamp);
    }

    /**
     * @dev Function to set withdrawalFee
     *
     * Multiply Rate by 100 for input
     * Use 200 to set withdrawalFee as 2%
     *
     */
    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        require(_withdrawalFee < MAX_WITHDRAWAL_FEE, "Invalid withdrawal fee");
        withdrawalFee = _withdrawalFee;
    }

    /**
     * @dev Sets value for lockup duration for each deposit.
     * Enter value in days
     * Withdrawals before lockupDuration ends will need to pay withdrawal fee.
     *
     */
    function setLockupDuration(uint256 _lockupDuration) external onlyOwner {
        lockupDuration = _lockupDuration;
    }

    /**
     * @dev Function to set minimum deposit amount
     */
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        require(_minDepositAmount > 0, "Invalid value");
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @dev Function to set maximum deposit amount
     */
    function setMaxDepositAmount(uint256 _maxDepositAmount) external onlyOwner {
        require(
            _maxDepositAmount > minDepositAmount,
            "Max deposit amount should be greater than mininum deposit amount"
        );
        maxDepositAmount = _maxDepositAmount;
    }

    /**
     * @dev Function to set maximum balance per user
     */
    function setMaxUserBalance(uint256 _maxUserBalance) external onlyOwner {
        require(
            _maxUserBalance > minDepositAmount,
            "Max Allowed User Balance should be greater than mininum deposit amount"
        );
        maxUserBalance = _maxUserBalance;
    }

    /**
     * @dev Sets maximum cap for pool balance.
     *
     * Set to maximum integer value by default
     *
     */
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        maxCap = _maxCap;
    }

    /**
     * @dev Set address that recieves all withdrawalFee amount
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "No zero address");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Function to set rewardRate for the pool
     *
     * To set reward rate as 0, use pause function
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate > 0 && _rewardRate < MAX_REWARD_RATE, "Invalid value");
        rewardRate.push(_rewardRate);
        rewardRateTimestamp.push(block.timestamp);
    }

    /**
     * @dev Function to pause the contract
     *
     * Sets APR to 0%
     * Does not allow new deposits
     *
     */
    function pause() external onlyOwner {
        rewardRate.push(0); //Sets APR to 0
        rewardRateTimestamp.push(block.timestamp);
        _pause();
    }

    /**
     * @dev Function to unpause the contract
     *
     * Sets APR to previous APR(before pausing)
     * Deposits are allowed again
     */
    function unpause() external onlyOwner {
        rewardRate.push(rewardRate.length - 2); //Resets to previous APR
        rewardRateTimestamp.push(block.timestamp);
        _unpause();
    }

    /**
     * @dev Emergency function
     */
    function rescueFunds(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "No zero address");
        uint256 _bal = IERC20(_token).balanceOf(address(this));
        if (_amount > _bal) _amount = _bal;

        IERC20(_token).safeTransfer(owner(), _amount);
    }

    /**
     * @dev Function to deposit tokens into the pool
     *
     * Requirements:
     *
     * Can only be done when staking has started
     * Deposit amount has to be greater than minimum deposit amount
     * Deposit amount has to be less than maximum deposit amount
     *
     */
    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(startTimestamp != 0, "Staking has not started");
        require(_amount >= minDepositAmount, "Less than minimum deposit amount");
        require(_amount <= maxDepositAmount, "Greater than maximum deposit amount");
        UserInfo storage user = userInfo[msg.sender];
        require(user.balance + _amount <= maxUserBalance, "Exceeded maximum balance per user");
        require(poolBalance + _amount <= maxCap, "Exceeded pool cap");
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.balance = user.balance + _amount;
        _addDeposit(msg.sender, _amount);
        poolBalance = poolBalance + _amount;

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Function to withdraw deposited amount from the pool
     *
     * Amount that has not completed its lockupDuration will be
     * taxed based on withdrawalFee
     *
     * All the rewards accumulated for the withdrawn amount will
     * be add to user's pendingRewards
     *
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0 && user.balance >= _amount, "Invalid amount");
        require(unlockedBalance(msg.sender) >= _amount, "Amount greater than unlocked amount");
        uint256 feeAmount = 0;
        uint256 index = user.first;
        uint256 secondsStaked = 0;
        uint256 depositTotal = 0;
        uint256 remainingAmount = _amount;
        while (depositTotal < _amount) {
            if (user.depositAmount[index] > remainingAmount) {
                user.depositAmount[index] = user.depositAmount[index] - remainingAmount;
                depositTotal = depositTotal + remainingAmount;

                uint256 rewardCalculationTime = 0;
                uint256 rewardsAccumulated = 0;

                //Calculate rewards for withdrawing amount
                rewardCalculationTime = user.lastClaimed >= user.depositTimestamp[index]
                    ? user.lastClaimed
                    : user.depositTimestamp[index];

                for (uint256 i = 0; i < rewardRateTimestamp.length - 1; i++) {
                    if (
                        rewardCalculationTime >= rewardRateTimestamp[i] &&
                        rewardCalculationTime < rewardRateTimestamp[i + 1]
                    ) {
                        secondsStaked = rewardRateTimestamp[i + 1] - rewardCalculationTime;
                        rewardsAccumulated =
                            rewardsAccumulated +
                            _calculateRewards(remainingAmount, secondsStaked, rewardRate[i]);
                    } else if (
                        rewardCalculationTime < rewardRateTimestamp[i] &&
                        rewardCalculationTime < rewardRateTimestamp[i + 1]
                    ) {
                        secondsStaked = rewardRateTimestamp[i + 1] - rewardRateTimestamp[i];
                        rewardsAccumulated =
                            rewardsAccumulated +
                            _calculateRewards(remainingAmount, secondsStaked, rewardRate[i]);
                    }
                }

                if (rewardCalculationTime >= rewardRateTimestamp[rewardRateTimestamp.length - 1]) {
                    secondsStaked = block.timestamp - rewardCalculationTime;
                    rewardsAccumulated =
                        rewardsAccumulated +
                        _calculateRewards(
                            remainingAmount,
                            secondsStaked,
                            rewardRate[rewardRateTimestamp.length - 1]
                        );
                }

                user.pendingRewards = user.pendingRewards + rewardsAccumulated;

                secondsStaked = block.timestamp - user.depositTimestamp[index];
                if (secondsStaked <= (lockupDuration * 86400))
                    feeAmount =
                        feeAmount +
                        ((remainingAmount * withdrawalFee) / MAX_WITHDRAWAL_FEE);
            } else {
                remainingAmount = remainingAmount - user.depositAmount[index];
                depositTotal = depositTotal + user.depositAmount[index];

                //Calculate rewards for withdrawing amount
                uint256 rewardCalculationTime = 0;
                uint256 rewardsAccumulated = 0;
                rewardCalculationTime = user.lastClaimed >= user.depositTimestamp[index]
                    ? user.lastClaimed
                    : user.depositTimestamp[index];

                for (uint256 i = 0; i < rewardRateTimestamp.length - 1; i++) {
                    if (
                        rewardCalculationTime >= rewardRateTimestamp[i] &&
                        rewardCalculationTime < rewardRateTimestamp[i + 1]
                    ) {
                        secondsStaked = rewardRateTimestamp[i + 1] - rewardCalculationTime;
                        rewardsAccumulated =
                            rewardsAccumulated +
                            _calculateRewards(
                                user.depositAmount[index],
                                secondsStaked,
                                rewardRate[i]
                            );
                    } else if (
                        rewardCalculationTime < rewardRateTimestamp[i] &&
                        rewardCalculationTime < rewardRateTimestamp[i + 1]
                    ) {
                        secondsStaked = rewardRateTimestamp[i + 1] - rewardRateTimestamp[i];
                        rewardsAccumulated =
                            rewardsAccumulated +
                            _calculateRewards(
                                user.depositAmount[index],
                                secondsStaked,
                                rewardRate[i]
                            );
                    }
                }

                if (rewardCalculationTime >= rewardRateTimestamp[rewardRateTimestamp.length - 1]) {
                    secondsStaked = block.timestamp - rewardCalculationTime;
                    rewardsAccumulated =
                        rewardsAccumulated +
                        _calculateRewards(
                            user.depositAmount[index],
                            secondsStaked,
                            rewardRate[rewardRateTimestamp.length - 1]
                        );
                }

                user.pendingRewards = user.pendingRewards + rewardsAccumulated;

                secondsStaked = block.timestamp - user.depositTimestamp[index];
                if (secondsStaked <= (lockupDuration * 86400))
                    feeAmount =
                        feeAmount +
                        ((user.depositAmount[index] * withdrawalFee) / MAX_WITHDRAWAL_FEE);

                delete user.depositAmount[index];
                delete user.depositTimestamp[index];
                user.first += 1;
            }

            index = index + 1;
        }

        user.balance = user.balance - _amount;
        poolBalance = poolBalance - _amount;
        if (feeAmount > 0) stakingToken.safeTransfer(feeRecipient, feeAmount);
        stakingToken.safeTransfer(address(msg.sender), _amount - feeAmount);
        
        uint256 reward = claimable(msg.sender);
        if (reward > 0) {
            user.pendingRewards = 0;
            user.lastClaimed = block.timestamp;
            uint256 claimedAmount = _safeRewardTransfer(msg.sender, reward);

            emit Claim(msg.sender, claimedAmount);
        }
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev Function to claim current claimable rewards of the sender.
     *
     * Use Claimable function to check currently accumulated rewards.
     */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 reward = claimable(msg.sender);
        if (reward > 0) {
            user.pendingRewards = 0;
            user.lastClaimed = block.timestamp;
            uint256 claimedAmount = _safeRewardTransfer(msg.sender, reward);

            emit Claim(msg.sender, claimedAmount);
        }
    }

    /**
     * @dev User calls this function to emergency withdraw all of staked amount.
     *
     * Forfeits rewards and resets state
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.balance > 0, "No staked amount");

        uint256 _amount = user.balance;
        uint256 feeAmount = 0;
        uint256 index = user.first;
        uint256 secondsStaked = 0;
        uint256 depositTotal = 0;
        uint256 remainingAmount = _amount;

        while (depositTotal < _amount) {
            if (user.depositAmount[index] > remainingAmount) {
                user.depositAmount[index] = user.depositAmount[index] - remainingAmount;
                depositTotal = depositTotal + remainingAmount;

                secondsStaked = block.timestamp - user.depositTimestamp[index];
                if (secondsStaked <= (lockupDuration * 86400))
                    feeAmount =
                        feeAmount +
                        ((remainingAmount * withdrawalFee) / MAX_WITHDRAWAL_FEE);
            } else {
                remainingAmount = remainingAmount - user.depositAmount[index];
                depositTotal = depositTotal + user.depositAmount[index];

                secondsStaked = block.timestamp - user.depositTimestamp[index];
                if (secondsStaked <= (lockupDuration * 86400))
                    feeAmount =
                        feeAmount +
                        ((user.depositAmount[index] * withdrawalFee) / MAX_WITHDRAWAL_FEE);

                delete user.depositAmount[index];
                delete user.depositTimestamp[index];
                user.first += 1;
            }

            index = index + 1;
        }

        user.balance = 0;
        user.lastClaimed = 0;
        user.pendingRewards = 0;
        poolBalance = poolBalance - _amount;
        if (feeAmount > 0) stakingToken.safeTransfer(feeRecipient, feeAmount);
        stakingToken.safeTransfer(address(msg.sender), _amount - feeAmount);
    }

    /**
     * @dev Returns value of current reward rate of the pool
     *
     * 200 = 2% APR
     *
     * Can be changed by owner using setRewardRate
     *
     */
    function currentRewardRate() external view returns (uint256) {
        return rewardRate[rewardRate.length - 1];
    }

    /**
     * @dev Returns current total deposited value by a user.
     */
    function balanceOf(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.balance;
    }

    /**
     * @dev Function to get unlocked balance for the user
     */
    function unlockedBalance(address _userAddress) public view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        uint256 index = user.first;
        uint256 unlockedAmount = 0;
        while (index <= user.last) {
            uint256 secondsStaked = block.timestamp - user.depositTimestamp[index];
            if (secondsStaked >= 86400) {
                unlockedAmount = unlockedAmount + user.depositAmount[index];
            } else {
                break;
            }
            index = index + 1;
        }
        return unlockedAmount;
    }

    /**
     * @dev Returns current claimable rewards for a user
     *
     * Includes any pending rewards from withdrawn amount
     *
     * Reward is calculated based on rewardRate
     *
     * Use Claim function to claim rewards
     */
    function claimable(address _user) public view returns (uint256) {
        require(startTimestamp > 0, "Staking not yet started");

        UserInfo storage user = userInfo[_user];
        // require(user.balance > 0, "No staked amount");
        uint256 index = user.first;
        uint256 secondsStaked = 0;
        uint256 amountStaked = 0;
        uint256 totalReward = 0;

        while (index <= user.last) {
            // Calculates accumulated rewards for deposited amount
            amountStaked = user.depositAmount[index];
            uint256 rewardCalculationTime = 0;
            uint256 rewardsAccumulated = 0;

            //Calculate from last claimed or deposit time, depending on latest value
            rewardCalculationTime = user.lastClaimed >= user.depositTimestamp[index]
                ? user.lastClaimed
                : user.depositTimestamp[index];

            for (uint256 i = 0; i < rewardRateTimestamp.length - 1; i++) {
                if (
                    rewardCalculationTime >= rewardRateTimestamp[i] &&
                    rewardCalculationTime < rewardRateTimestamp[i + 1]
                ) {
                    secondsStaked = rewardRateTimestamp[i + 1] - rewardCalculationTime;
                    rewardsAccumulated =
                        rewardsAccumulated +
                        _calculateRewards(amountStaked, secondsStaked, rewardRate[i]);
                } else if (
                    rewardCalculationTime < rewardRateTimestamp[i] &&
                    rewardCalculationTime < rewardRateTimestamp[i + 1]
                ) {
                    secondsStaked = rewardRateTimestamp[i + 1] - rewardRateTimestamp[i];
                    rewardsAccumulated =
                        rewardsAccumulated +
                        _calculateRewards(amountStaked, secondsStaked, rewardRate[i]);
                }
            }

            if (rewardCalculationTime >= rewardRateTimestamp[rewardRateTimestamp.length - 1]) {
                secondsStaked = block.timestamp - rewardCalculationTime;
                rewardsAccumulated =
                    rewardsAccumulated +
                    _calculateRewards(
                        amountStaked,
                        secondsStaked,
                        rewardRate[rewardRateTimestamp.length - 1]
                    );
            }

            totalReward = totalReward + rewardsAccumulated;

            index = index + 1;
        }

        return totalReward + user.pendingRewards;
    }

    /**
     * @dev Internal function to add deposit value and timestamp to queue.
     */
    function _addDeposit(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];

        if (user.first == 0)
            //initialize
            user.first = 1;

        user.last += 1;
        user.depositTimestamp[user.last] = block.timestamp;
        user.depositAmount[user.last] = _amount;
    }

    /**
     * @dev Private function to safeTransfer rewards from contract
     */
    function _safeRewardTransfer(address _to, uint256 _amount) private returns (uint256) {
        require(_to != address(0), "No zero address");
        require(
            rewardToken.balanceOf(address(this)) >= _amount,
            "Insufficient reward token balance"
        );
        rewardToken.safeTransfer(_to, _amount);
        return _amount;
    }

    /**
     * @dev function is used to return total amount on which penalty to be collected
     */
    function getTotalPenaltyAmount() external view returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 index = user.first;
        uint256 secondsStaked = 0;
        uint amountToPenalised = 0;
        while (index <= user.last) {
            if (user.depositAmount[index] > 0) {
                secondsStaked = block.timestamp - user.depositTimestamp[index];
                if (secondsStaked <= (lockupDuration * 86400))
                    amountToPenalised = amountToPenalised + user.depositAmount[index];
            }
            index = index + 1;
        }
        return amountToPenalised;
    }

    function _calculateRewards(
        uint256 _amountStaked,
        uint256 _secondsStaked,
        uint256 _rewardRate
    ) internal view returns (uint256 calculatedRewards) {
        uint256 stakingTokenDecimals = ERC20(address(stakingToken)).decimals();
        uint256 rewardTokenDecimals = ERC20(address(rewardToken)).decimals();

        calculatedRewards = ((_amountStaked *
            _rewardRate *
            _secondsStaked *
            (10**rewardTokenDecimals)) /
            ((10**stakingTokenDecimals) * 86400 * 365 * MAX_REWARD_RATE));
    }
}