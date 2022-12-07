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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {IArchChamber} from "./interfaces/IArchChamber.sol";
import {IIssuerWizard} from "./interfaces/IIssuerWizard.sol";
import {IVault} from "./interfaces/IVault.sol";

contract TradeIssuer is Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IArchChamber;
    using PreciseUnitMath for uint256;

    /*//////////////////////////////////////////////////////////////
                                  STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable wrappedNativeToken;
    address public immutable dexAggregator;
    uint8 public immutable slippageAmount;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TradeIssuerTokenMinted(
        address indexed archChamber,
        address indexed recipient,
        address indexed inputToken,
        uint256 totalTokensUsed,
        uint256 mintAmount
    );

    event TradeIssuerTokenRedeemed(
        address indexed archChamber,
        address indexed recipient,
        address indexed outputToken,
        uint256 totalTokensReturned,
        uint256 redeemAmount
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _dexAggregator        Address of the dex aggregator that will be called to make the swaps.
     * @param _wrappedNativeToken   Native token address of the chain where the contract will be deployed.
     * @param _slippageAmount       Maximum slippage tolerance for the swapped components [10 = 1% with max of 100 = 10%].
     */
    constructor(
        address payable _dexAggregator,
        address _wrappedNativeToken,
        uint8 _slippageAmount
    ) {
        require(_slippageAmount <= 100, "Slippage must be below 10%");
        slippageAmount = _slippageAmount;
        dexAggregator = _dexAggregator;
        wrappedNativeToken = _wrappedNativeToken;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Transfer the total balance of the specified token to the owner address
     *
     * @param _tokenToWithdraw     The ERC20 token address to withdraw
     */
    function transferERC20ToOwner(address _tokenToWithdraw) external onlyOwner {
        require(IERC20(_tokenToWithdraw).balanceOf(address(this)) > 0, "No ERC20 Balance");

        IERC20(_tokenToWithdraw).safeTransfer(
            owner(), IERC20(_tokenToWithdraw).balanceOf(address(this))
        );
    }

    /**
     * Transfer all Ether to the owner of the contract
     */
    function transferEthToOwner() external onlyOwner {
        require(address(this).balance > 0, "No ETH balance");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Mints chamber tokens from the network's native token
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _mintAmount                           Amount of the chamber token to be minted.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _hasVaults                            Flag to check if deposits at vaults are needed.
     * @param _components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalNativeTokenUsed                 Total amount of native token spent on the whole operation.
     */
    function mintChamberFromNativeToken(
        bytes[] memory _dexQuotes,
        uint256 _mintAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        bool _hasVaults,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) external payable nonReentrant returns (uint256 totalNativeTokenUsed) {
        require(msg.value > 0, "No ETH sent");
        WETH(payable(wrappedNativeToken)).deposit{value: msg.value}();

        totalNativeTokenUsed = _mintChamber(
            _dexQuotes,
            IERC20(wrappedNativeToken),
            msg.value,
            _mintAmount,
            _archChamber,
            _issuerWizard,
            _hasVaults,
            _components,
            _componentsQuantities,
            _vaults,
            _vaultAssets,
            _vaultQuantities
        );

        _archChamber.safeTransfer(msg.sender, _mintAmount);

        uint256 ethReturnAmount = msg.value - totalNativeTokenUsed;
        if (ethReturnAmount > 0) {
            WETH(payable(wrappedNativeToken)).withdraw(ethReturnAmount);
            payable(msg.sender).sendValue(ethReturnAmount);
        }

        emit TradeIssuerTokenMinted(
            address(_archChamber), msg.sender, wrappedNativeToken, totalNativeTokenUsed, _mintAmount
            );

        return totalNativeTokenUsed;
    }

    /**
     * Mint chamber tokens from an ERC-20 token.
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _inputToken                           Token to use to pay for issuance.
     * @param _maxAmountInputToken                  Maximum amount of input tokens to be used for the whole operation.
     * @param _mintAmount                           Amount of the chamber token to be minted.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _hasVaults                            Flag to check if deposits at vaults are needed.
     * @param _components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalInputTokenUsed                  Total amount of input token spent on this issuance.
     */
    function mintChamberFromToken(
        bytes[] memory _dexQuotes,
        IERC20 _inputToken,
        uint256 _maxAmountInputToken,
        uint256 _mintAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        bool _hasVaults,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) external nonReentrant returns (uint256 totalInputTokenUsed) {
        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);

        totalInputTokenUsed = _mintChamber(
            _dexQuotes,
            _inputToken,
            _maxAmountInputToken,
            _mintAmount,
            _archChamber,
            _issuerWizard,
            _hasVaults,
            _components,
            _componentsQuantities,
            _vaults,
            _vaultAssets,
            _vaultQuantities
        );

        _archChamber.safeTransfer(msg.sender, _mintAmount);

        _inputToken.safeTransfer(msg.sender, _maxAmountInputToken - totalInputTokenUsed);

        emit TradeIssuerTokenMinted(
            address(_archChamber),
            msg.sender,
            address(_inputToken),
            totalInputTokenUsed,
            _mintAmount
            );

        return totalInputTokenUsed;
    }

    /**
     * Redeem chamber tokens for the network's native token
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _minAmountNativeToken                 Minimum amount of native tokens the caller expects to receive.
     * @param _redeemAmount                         Amount of the chamber tokens to be redeemed.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalNativeTokenReturned             Total amount of output tokens returned to the user.
     */
    function redeemChamberToNativeToken(
        bytes[] memory _dexQuotes,
        uint256 _minAmountNativeToken,
        uint256 _redeemAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) external nonReentrant returns (uint256 totalNativeTokenReturned) {
        IERC20(address(_archChamber)).safeTransferFrom(msg.sender, address(this), _redeemAmount);

        totalNativeTokenReturned = _redeemChamber(
            _dexQuotes,
            IERC20(wrappedNativeToken),
            _redeemAmount,
            _archChamber,
            _issuerWizard,
            _components,
            _componentsQuantities,
            _vaults,
            _vaultAssets,
            _vaultQuantities
        );

        require(
            totalNativeTokenReturned > _minAmountNativeToken,
            "Redeemed for less tokens than expected"
        );

        WETH(payable(wrappedNativeToken)).withdraw(totalNativeTokenReturned);
        payable(msg.sender).sendValue(totalNativeTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_archChamber),
            msg.sender,
            wrappedNativeToken,
            totalNativeTokenReturned,
            _redeemAmount
            );

        return totalNativeTokenReturned;
    }

    /**
     * Redeem chamber tokens for an ERC-20 token.
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _outputToken                          Token to deposit the caller
     * @param _minAmountOutputToken                 Minimum amount of output tokens the caller expects to receive.
     * @param _redeemAmount                         Amount of the chamber tokens to be redeemed.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalOutputTokenReturned             Total amount of output tokens returned to the user.
     */
    function redeemChamberToToken(
        bytes[] memory _dexQuotes,
        IERC20 _outputToken,
        uint256 _minAmountOutputToken,
        uint256 _redeemAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) external nonReentrant returns (uint256 totalOutputTokenReturned) {
        IERC20(address(_archChamber)).safeTransferFrom(msg.sender, address(this), _redeemAmount);

        totalOutputTokenReturned = _redeemChamber(
            _dexQuotes,
            _outputToken,
            _redeemAmount,
            _archChamber,
            _issuerWizard,
            _components,
            _componentsQuantities,
            _vaults,
            _vaultAssets,
            _vaultQuantities
        );

        require(
            totalOutputTokenReturned > _minAmountOutputToken,
            "Redeemed for less tokens than expected"
        );

        IERC20(_outputToken).safeTransfer(msg.sender, totalOutputTokenReturned);

        emit TradeIssuerTokenRedeemed(
            address(_archChamber),
            msg.sender,
            address(_outputToken),
            totalOutputTokenReturned,
            _redeemAmount
            );

        return totalOutputTokenReturned;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Redeems chamber tokens for its underlying constituents, withdraws the underlying assets of ERC4626 compliant valuts,
     * and then swaps all those tokens for an output token. The msg.sender must approve this contract to use it's chamber tokens
     * beforehand.
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _outputToken                          Token to use to pay for issuance.
     * @param _redeemAmount                         Amount of the chamber token to be minted.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _components                           Constituents addresses needed for deposits to vaults or mint chamber token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalOutputTokenReturned             Total amount of input token spent on this issuance.
     */
    function _redeemChamber(
        bytes[] memory _dexQuotes,
        IERC20 _outputToken,
        uint256 _redeemAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) internal returns (uint256 totalOutputTokenReturned) {
        require(_redeemAmount > 0, "Redeem amount cannot be zero");
        require(_components.length == _dexQuotes.length, "Const. and quotes must match");
        require(_components.length == _componentsQuantities.length, "Const. and qtys. must match");
        require(_vaults.length == _vaultAssets.length, "Vaults and Assets must match");
        require(_vaultAssets.length == _vaultQuantities.length, "Vault and Deposits must match");

        _issuerWizard.redeem(_archChamber, _redeemAmount);

        if (_vaults.length > 0) {
            _withdrawConstituentsInVault(_vaults, _vaultQuantities, _archChamber, _redeemAmount);
        }

        totalOutputTokenReturned =
            _sellAssetsForTokenInDex(_dexQuotes, _outputToken, _components, _componentsQuantities);

        return totalOutputTokenReturned;
    }

    /**
     * Swaps and Deposits (if needed) required constituents using an ERC20 input token. Smart contract deposits
     * must be ERC4626 compliant, otherwise the deposit function will revert. After swaps and deposits. Chamber
     * tokens are issued.
     *
     * @param _dexQuotes                            The encoded calldata array to execute in a dex aggregator.
     * @param _inputToken                           Token to use to pay for issuance.
     * @param _maxAmountInputToken                  Maximum amount of input tokens to be used for the whole operation.
     * @param _mintAmount                           Amount of the chamber token to be minted.
     * @param _archChamber                          Chamber token address to call the issue function.
     * @param _issuerWizard                         Instance of the issuerWizard at the _archChamber.
     * @param _hasVaults                            Flag to check if deposits at vaults are needed.
     * @param _components                           Constituents addresses that are needed for deposits to vaults or mint chamber
     *                                              token.
     * @param _componentsQuantities                 Constituent quantities needed for deposits to vaults or mint chamber token.
     * @param _vaults                               Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets                          Vault underlying asset address.
     * @param _vaultQuantities                      Vault constituent quantities needed.
     *
     * @return totalInputTokenUsed                  Total amount of input token spent on this issuance.
     */
    function _mintChamber(
        bytes[] memory _dexQuotes,
        IERC20 _inputToken,
        uint256 _maxAmountInputToken,
        uint256 _mintAmount,
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        bool _hasVaults,
        address[] memory _components,
        uint256[] memory _componentsQuantities,
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities
    ) internal returns (uint256 totalInputTokenUsed) {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(_components.length > 0, "Components array cannot be empty");
        require(_components.length == _dexQuotes.length, "Const. and quotes must match");
        require(_components.length == _componentsQuantities.length, "Const. and qtys. must match");
        require(_vaults.length == _vaultAssets.length, "Vaults and Assets must match");
        require(_vaultAssets.length == _vaultQuantities.length, "Vault and Deposits must match");

        uint256 currentAllowance = IERC20(_inputToken).allowance(address(this), dexAggregator);

        if (currentAllowance < _maxAmountInputToken) {
            _inputToken.safeIncreaseAllowance(
                dexAggregator, _maxAmountInputToken - currentAllowance
            );
        }

        totalInputTokenUsed =
            _buyAssetsInDex(_dexQuotes, _inputToken, _components, _componentsQuantities);

        require(_maxAmountInputToken >= totalInputTokenUsed, "Overspent input/native token");

        if (_hasVaults) {
            _depositConstituentsInVault(
                _vaults, _vaultAssets, _vaultQuantities, _archChamber, _mintAmount
            );
        }

        _checkAndIncreaseAllowance(_archChamber, _issuerWizard, _mintAmount);

        _issuerWizard.issue(_archChamber, _mintAmount);

        return totalInputTokenUsed;
    }

    /**
     * Swap components using a DEX aggregator. Some of the assets may be deposited to an ERC4626 compliant contract.
     *
     * @param _dexQuotes                The encoded array with calldata to execute in a dex aggregator contract.
     * @param _inputToken               Token to use to pay for issuance. Must be the sellToken of the DEX Aggregator trades.
     * @param _components               Constituents required for the chamber token or for a vault deposit.
     * @param _componentsQuantities     Constituent units needed for the chamber token or for a vault deposit.
     *
     * @return totalInputTokensUsed     Total amount of input token spent.
     */
    function _buyAssetsInDex(
        bytes[] memory _dexQuotes,
        IERC20 _inputToken,
        address[] memory _components,
        uint256[] memory _componentsQuantities
    ) internal returns (uint256 totalInputTokensUsed) {
        uint256 componentAmountBought = 0;
        uint256 inputTokenBalanceBefore = _inputToken.balanceOf(address(this));

        for (uint256 i = 0; i < _components.length; i++) {
            // If the constituent is equal to the input token we don't have to trade
            if (_componentsQuantities[i] > 0) {
                if (_components[i] == address(_inputToken)) {
                    totalInputTokensUsed += _componentsQuantities[i];
                    componentAmountBought = _componentsQuantities[i];
                } else {
                    uint256 componentBalanceBefore = IERC20(_components[i]).balanceOf(address(this));
                    _fillQuote(_dexQuotes[i]);
                    componentAmountBought =
                        IERC20(_components[i]).balanceOf(address(this)) - componentBalanceBefore;
                }
            }
            require(
                componentAmountBought <= (_componentsQuantities[i] * (1000 + slippageAmount)) / 1000,
                "Overbought dex asset"
            );
            require(componentAmountBought >= _componentsQuantities[i], "Underbought dex asset");
        }
        totalInputTokensUsed += inputTokenBalanceBefore - _inputToken.balanceOf(address(this));
    }

    /**
     * Swap components for a single output token using a DEX aggregator
     *
     * @param _dexQuotes                The encoded array with calldata to execute in a dex aggregator contract
     * @param _outputToken              Token to receive on trades
     * @param _components               Constituents to be swapped. Must be the sellToken of the DEX Aggregator trades
     * @param _componentsQuantities     Constituent units to be swapped
     *
     * @return totalOutputTokenReturned Total amount of input token spent
     */
    function _sellAssetsForTokenInDex(
        bytes[] memory _dexQuotes,
        IERC20 _outputToken,
        address[] memory _components,
        uint256[] memory _componentsQuantities
    ) internal returns (uint256 totalOutputTokenReturned) {
        uint256 componentBalanceBefore = 0;
        uint256 outputTokenBalanceBefore = _outputToken.balanceOf(address(this));

        for (uint256 i = 0; i < _components.length; i++) {
            if (_componentsQuantities[i] > 0 && _components[i] != address(_outputToken)) {
                _checkAndIncreaseAllowanceForDex(_components[i], _componentsQuantities[i]);
                componentBalanceBefore = IERC20(_components[i]).balanceOf(address(this));
                _fillQuote(_dexQuotes[i]);
                require(
                    IERC20(_components[i]).balanceOf(address(this))
                        <= (_componentsQuantities[i] * (slippageAmount)) / 1000,
                    "Undersold dex asset"
                );
            }
        }
        totalOutputTokenReturned += _outputToken.balanceOf(address(this)) - outputTokenBalanceBefore;
    }

    /**
     * Execute a DEX Aggregator swap quote.
     *
     * @param _quote       CallData to be executed on a DEX aggregator.
     */
    function _fillQuote(bytes memory _quote) internal returns (bytes memory response) {
        response = address(dexAggregator).functionCall(_quote);
        require(response.length > 0, "Low level functionCall failed");
        return (response);
    }

    /**
     * Deposits the underlying asset to an ERC4626 compliant smart contract (Vault).
     *
     * @param _vaults             Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultAssets        Vault underlying asset address.
     * @param _vaultQuantities    Vault underlying asset quantity needed for issuance.
     * @param _mintAmount         Amount of the chamber token to be minted.
     * @param _archChamber        Chamber token address to call the issue function.
     */
    function _depositConstituentsInVault(
        address[] memory _vaults,
        address[] memory _vaultAssets,
        uint256[] memory _vaultQuantities,
        IArchChamber _archChamber,
        uint256 _mintAmount
    ) internal {
        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 vaultDepositAmount = _vaultQuantities[i];
            address vault = _vaults[i];
            uint256 constituentIssueQuantity = _archChamber.getConstituentQuantity(vault)
                .preciseMulCeil(_mintAmount, ERC20(address(_archChamber)).decimals());
            if (constituentIssueQuantity > 0) {
                require(vaultDepositAmount > 0, "Deposit amount cannot be zero");
                uint256 vaultConstituentIssued;
                address vaultAsset = _vaultAssets[i];
                uint256 constituentBalanceBefore = IERC20(vault).balanceOf(address(this));
                IERC20(vaultAsset).safeIncreaseAllowance(vault, vaultDepositAmount);
                IVault(vault).deposit(vaultDepositAmount);
                uint256 constituentBalanceAfter = IERC20(vault).balanceOf(address(this));
                vaultConstituentIssued = constituentBalanceAfter - constituentBalanceBefore;
                require(
                    vaultConstituentIssued
                        <= (constituentIssueQuantity * (1000 + slippageAmount)) / 1000,
                    "Overbought vault constituent"
                );
                require(
                    vaultConstituentIssued >= constituentIssueQuantity,
                    "Underbought vault constituent"
                );
            }
        }
    }

    /**
     * Withdraws the underlying asset of ERC4626 compliant smart contract vaults.
     *
     * @param _vaults             Vault constituents addresses that are part of the archChamber constituents.
     * @param _vaultQuantities    Vault underlying asset quantity needed for issuance.
     * @param _redeemAmount       Amount of the chamber token to be minted.
     * @param _archChamber        Chamber token address to call the issue function.
     */
    function _withdrawConstituentsInVault(
        address[] memory _vaults,
        uint256[] memory _vaultQuantities,
        IArchChamber _archChamber,
        uint256 _redeemAmount
    ) internal {
        uint256 chamberDecimals = ERC20(address(_archChamber)).decimals();
        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 vaultWithdrawAmount = _vaultQuantities[i];
            require(vaultWithdrawAmount > 0, "Deposit amount cannot be zero");
            address vault = _vaults[i];
            uint256 constituentIssueQuantity = _archChamber.getConstituentQuantity(vault)
                .preciseMulCeil(_redeemAmount, chamberDecimals);
            if (constituentIssueQuantity > 0) {
                uint256 vaultConstituentRedeemed;
                uint256 constituentBalanceBefore = IERC20(vault).balanceOf(address(this));
                IVault(vault).withdraw(vaultWithdrawAmount);
                uint256 constituentBalanceAfter = IERC20(vault).balanceOf(address(this));
                vaultConstituentRedeemed = constituentBalanceBefore - constituentBalanceAfter;
                require(
                    vaultConstituentRedeemed >= constituentIssueQuantity,
                    "Underwithdraw vault constituent"
                );
            }
        }
    }

    /**
     * Checks the allowance for issuance of a chamberToken, if allowance is not enough it's increased.
     *
     * @param _archChamber      Arch chamber token address for mint.
     * @param _issuerWizard     Issuer wizard used at _archChamber.
     * @param _mintAmount       Amount to mint.
     */
    function _checkAndIncreaseAllowance(
        IArchChamber _archChamber,
        IIssuerWizard _issuerWizard,
        uint256 _mintAmount
    ) internal {
        (address[] memory requiredConstituents, uint256[] memory requiredConstituentsQuantities) =
            _issuerWizard.getConstituentsQuantitiesForIssuance(_archChamber, _mintAmount);

        for (uint256 i = 0; i < requiredConstituents.length; i++) {
            uint256 currentAllowance =
                IERC20(requiredConstituents[i]).allowance(address(this), address(_issuerWizard));
            if (currentAllowance < requiredConstituentsQuantities[i]) {
                IERC20(requiredConstituents[i]).safeIncreaseAllowance(
                    address(_issuerWizard), type(uint256).max - currentAllowance
                );
            }
        }
    }

    /**
     * For the specified token and amount, checks the allowance between the TraderIssuer and the Dex aggreator,
     * If not enough, it sets the maximum for good.
     */
    function _checkAndIncreaseAllowanceForDex(address _tokenAddress, uint256 _requiredAmount)
        internal
    {
        uint256 currentAllowance =
            IERC20(_tokenAddress).allowance(address(this), address(dexAggregator));
        if (currentAllowance < _requiredAmount) {
            IERC20(_tokenAddress).safeIncreaseAllowance(
                address(dexAggregator), type(uint256).max - currentAllowance
            );
        }
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArchChamber is IERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external;

    function removeConstituent(address _constituent) external;

    function isChamberManager(address _manager) external view returns (bool);

    function isWizard(address _wizard) external view returns (bool);

    function isConstituent(address _constituent) external view returns (bool);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getConstituentsAddresses() external view returns (address[] memory);

    function getQuantities() external view returns (uint256[] memory);

    function getConstituentQuantity(address _constituent) external view returns (uint256);

    function getWizards() external view returns (address[] memory);

    function mint(address _recipient, uint256 _quantity) external;

    function burn(address _from, uint256 _quantity) external;

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity) external;

    function updateQuantities() external;

    function addAllowedContract(address target) external;

    function removeAllowedContract(address target) external;

    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        bytes memory _tradeQuoteData,
        address payable dexAggregator
    ) external;
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {IArchChamber} from "./IArchChamber.sol";

interface IIssuerWizard {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberTokenMinted(
        address indexed archChamber, address indexed recipient, uint256 quantity
    );

    event ChamberTokenBurned(
        address indexed archChamber,
        address indexed issuer,
        address indexed recipient,
        uint256 quantity
    );

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getConstituentsQuantitiesForIssuance(IArchChamber archChamber, uint256 quantity)
        external
        view
        returns (address[] memory, uint256[] memory);

    function issue(IArchChamber archChamber, uint256 quantity) external;

    function redeem(IArchChamber _archChamber, uint256 _quantity) external;
}

// SPDX-License-Identifier: Apache License 2.0

pragma solidity ^ 0.8.13.0;

// TODO: WIP complete full interface and resolve with 4626
interface IVault {
    function deposit(uint256 _depositAmount) external;
    function withdraw(uint256 _withdrawAmount) external;
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

library PreciseUnitMath {
    /**
     * Multiplies value _a by value _b (result is rounded down). It's assumed that the value _b is the significand
     * of a number with _deicmals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMul(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 preciseUnit = 10 ** _decimals;
        return (_a * _b) / preciseUnit;
    }

    /**
     * Multiplies value _a by value _b (result is rounded up). It's assumed that the value _b is the significand
     * of a number with _decimals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result will never reach zero. The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMulCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint256 preciseUnit = 10 ** _decimals;
        return (((_a * _b) - 1) / preciseUnit) + 1;
    }

    /**
     * Divides value _a by value _b (result is rounded down). Value _a is scaled up to match value _b decimals.
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDiv(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return (_a * preciseUnit) / _b;
    }

    /**
     * Divides value _a by value _b (result is rounded up or away from 0). Value _a is scaled up to match
     * value _b decimals. The result will never be zero, except when _a is zero. The result can be interpreted
     * as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDivCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return _a > 0 ? ((((_a * preciseUnit) - 1) / _b) + 1) : 0;
    }
}