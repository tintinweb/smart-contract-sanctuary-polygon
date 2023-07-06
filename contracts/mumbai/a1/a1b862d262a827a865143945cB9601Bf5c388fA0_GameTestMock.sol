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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DerbyToken is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _totalSupply
  ) ERC20(_name, _symbol) {
    _mint(msg.sender, _totalSupply);
  }
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IVault {
  function swapTokens(uint256 _amountIn, address _tokenIn) external returns (uint256);

  function rebalancingPeriod() external view returns (uint256);

  function price(uint256) external view returns (uint256);

  function setDeltaAllocations(uint256 _protocolNum, int256 _allocation) external;

  function historicalPrices(
    uint256 _rebalancingPeriod,
    uint256 _protocolNum
  ) external view returns (uint256);

  function rewardPerLockedToken(
    uint256 _rebalancingPeriod,
    uint256 _protocolNum
  ) external view returns (int256);

  function performanceFee() external view returns (uint256);

  function getTotalUnderlying() external view returns (uint256);

  function getTotalUnderlyingIncBalance() external view returns (uint256);

  function vaultCurrencyAddress() external view returns (address);

  function setXChainAllocation(
    uint256 _amountToSend,
    uint256 _exchangeRate,
    bool _receivingFunds
  ) external;

  function setVaultState(uint256 _state) external;

  function receiveFunds() external;

  function receiveProtocolAllocations(int256[] memory _deltas) external;

  function toggleVaultOnOff(bool _state) external;

  function decimals() external view returns (uint256);

  function redeemRewardsGame(uint256 _amount, address _user) external;

  function name() external view returns (string memory);

  function vaultNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IXProvider {
  // function xSendCallback() external; // sending a (permissioned) vaule crosschain and receive a callback to a specified address.
  function xReceive(uint256 _value) external; // receiving a (permissioned) value crosschain.

  function pushAllocations(uint256 _vaultNumber, int256[] memory _deltas) external payable;

  function receiveTotalUnderlying(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _underlying
  ) external;

  function pushSetXChainAllocation(
    address _vault,
    uint32 _chainId,
    uint256 _amountToWithdraw,
    uint256 _exchangeRate,
    bool _receivingFunds
  ) external payable;

  function xTransferToController(
    uint256 _vaultNumber,
    uint256 _amount,
    address _asset
  ) external payable;

  function receiveFeedbackToXController(uint256 _vaultNumber) external;

  function xTransferToVaults(
    address _vault,
    uint32 _chainId,
    uint256 _amount,
    address _asset
  ) external payable;

  function pushProtocolAllocationsToVault(
    uint32 _chainId,
    address _vault,
    int256[] memory _deltas
  ) external payable;

  function getDecimals(address _vault) external view returns (uint256);

  function pushTotalUnderlying(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _underlying,
    uint256 _totalSupply,
    uint256 _withdrawalRequests
  ) external payable;

  function pushStateFeedbackToVault(address _vault, uint32 _chainId, bool _state) external payable;

  function pushRewardsToGame(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) external payable;

  function homeChain() external returns (uint32);

  function calculateEstimatedAmount(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../DerbyToken.sol";

import "../Interfaces/IVault.sol";
import "../Interfaces/IXProvider.sol";

contract GameTestMock is ERC721, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct Basket {
    // the vault number for which this Basket was created
    uint256 vaultNumber;
    // last period when this Basket got rebalanced
    uint256 lastRebalancingPeriod;
    // nr of total allocated tokens
    int256 nrOfAllocatedTokens;
    // total build up rewards
    int256 totalUnRedeemedRewards; // In vaultCurrency.decimals() * BASE_SCALE of 1e18
    // total redeemed rewards
    int256 totalRedeemedRewards; // In vaultCurrency.decimals()
    // (basket => vaultNumber => chainId => allocation)
    mapping(uint256 => mapping(uint256 => int256)) allocations;
  }

  struct vaultInfo {
    // number of vaults that have sent rewards
    uint256 numberOfRewardsReceived;
    // (chainId => vaultAddress)
    mapping(uint32 => address) vaultAddress;
    // (chainId => deltaAllocation)
    mapping(uint256 => int256) deltaAllocationChain;
    // (chainId => protocolNumber => deltaAllocation)
    mapping(uint256 => mapping(uint256 => int256)) deltaAllocationProtocol;
    // (chainId => rebalancing period => protocol id => rewardPerLockedToken).
    // in BASE_SCALE * vaultCurrency.decimals() nr of decimals (BASE_SCALE (same as DerbyToken.decimals()))
    mapping(uint32 => mapping(uint256 => mapping(uint256 => int256))) rewardPerLockedToken;
  }

  address private dao;
  address private guardian;
  address public xProvider;

  IERC20 public derbyToken;

  // used in notInSameBlock modifier
  uint256 private lastBlock;

  // latest basket id
  uint256 private latestBasketId;

  // array of chainIds e.g [10, 100, 1000];
  uint32[] public chainIds;

  // interval in Unix timeStamp
  uint256 public rebalanceInterval; // SHOULD BE REPLACED FOR REALISTIC NUMBER

  // last rebalance timeStamp
  mapping(uint256 => uint256) public lastTimeStamp;

  // threshold in vaultCurrency e.g USDC for when user tokens will be sold / burned. Must be negative
  int256 internal negativeRewardThreshold;
  // percentage of tokens that will be sold at negative rewards
  uint256 internal negativeRewardFactor;
  // vaultNumber => tokenPrice || price of vaultCurrency / derbyToken
  mapping(uint256 => uint256) public tokenPrice;

  // used to scale rewards
  uint256 public BASE_SCALE = 1e18;

  // vaultNumber => vaultAddress
  mapping(uint256 => address) public homeVault;

  // baskets, maps tokenID from BasketToken NFT contract to the Basket struct in this contract.
  // (basketTokenId => basket struct):
  mapping(uint256 => Basket) private baskets;

  // (chainId => latestProtocolId): latestProtocolId set by dao
  mapping(uint256 => uint256) public latestProtocolId;

  // (vaultNumber => vaultInfo struct)
  mapping(uint256 => vaultInfo) internal vaults;

  // (vaultNumber => chainid => bool): true when vault/ chainid is cross-chain rebalancing
  mapping(uint256 => mapping(uint32 => bool)) public isXChainRebalancing;

  event PushProtocolAllocations(uint32 chain, address vault, int256[] deltas);

  event PushedAllocationsToController(uint256 vaultNumber, int256[] deltas);

  event BasketId(address owner, uint256 basketId, uint256 vaultNumber, string name);

  event RebalanceBasket(
    uint256 basketId,
    uint256 rebalancingPeriod,
    int256 unredeemedRewards,
    int256 redeemedRewards
  );

  modifier onlyDao() {
    require(msg.sender == dao, "Game: only DAO");
    _;
  }

  modifier onlyBasketOwner(uint256 _basketId) {
    require(msg.sender == ownerOf(_basketId), "Game: Not the owner of the basket");
    _;
  }

  modifier onlyXProvider() {
    require(msg.sender == xProvider, "Game: only xProvider");
    _;
  }

  modifier onlyGuardian() {
    require(msg.sender == guardian, "Game: only Guardian");
    _;
  }

  modifier notInSameBlock() {
    require(block.number != lastBlock, "Cannot call functions in the same block");
    lastBlock = block.number;
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address _derbyToken,
    address _dao,
    address _guardian
  ) ERC721(name_, symbol_) {
    derbyToken = IERC20(_derbyToken);
    dao = _dao;
    guardian = _guardian;
  }

  /// @notice Setter for delta allocation in a particulair chainId
  /// @param _vaultNumber number of vault
  /// @param _chainId number of chainId
  /// @param _deltaAllocation delta allocation
  function addDeltaAllocationChain(
    uint256 _vaultNumber,
    uint256 _chainId,
    int256 _deltaAllocation
  ) internal {
    vaults[_vaultNumber].deltaAllocationChain[_chainId] += _deltaAllocation;
  }

  /// @notice Getter for delta allocation in a particulair chainId
  /// @param _vaultNumber number of vault
  /// @param _chainId number of chainId
  /// @return allocation delta allocation
  function getDeltaAllocationChain(
    uint256 _vaultNumber,
    uint256 _chainId
  ) public view returns (int256) {
    return vaults[_vaultNumber].deltaAllocationChain[_chainId];
  }

  /// @notice Setter for the delta allocation in Protocol vault e.g compound_usdc_01
  /// @dev Allocation can be negative
  /// @param _vaultNumber number of vault
  /// @param _chainId number of chainId
  /// @param _protocolNum Protocol number linked to an underlying vault e.g compound_usdc_01
  /// @param _deltaAllocation Delta allocation in tokens
  function addDeltaAllocationProtocol(
    uint256 _vaultNumber,
    uint256 _chainId,
    uint256 _protocolNum,
    int256 _deltaAllocation
  ) internal {
    vaults[_vaultNumber].deltaAllocationProtocol[_chainId][_protocolNum] += _deltaAllocation;
  }

  /// @notice Getter for the delta allocation in Protocol vault e.g compound_usdc_01
  /// @param _vaultNumber number of vault
  /// @param _chainId number of chainId
  /// @param _protocolNum Protocol number linked to an underlying vault e.g compound_usdc_01
  /// @return allocation Delta allocation in tokens
  function getDeltaAllocationProtocol(
    uint256 _vaultNumber,
    uint256 _chainId,
    uint256 _protocolNum
  ) public view returns (int256) {
    return vaults[_vaultNumber].deltaAllocationProtocol[_chainId][_protocolNum];
  }

  /// @notice Setter to set the total number of allocated tokens. Only the owner of the basket can set this.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @param _allocation Number of derby tokens that are allocated towards protocols.
  function setBasketTotalAllocatedTokens(
    uint256 _basketId,
    int256 _allocation
  ) internal onlyBasketOwner(_basketId) {
    baskets[_basketId].nrOfAllocatedTokens += _allocation;
    require(basketTotalAllocatedTokens(_basketId) >= 0, "Basket: underflow");
  }

  /// @notice function to see the total number of allocated tokens. Only the owner of the basket can view this.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @return int256 Number of derby tokens that are allocated towards protocols.
  function basketTotalAllocatedTokens(uint256 _basketId) public view returns (int256) {
    return baskets[_basketId].nrOfAllocatedTokens;
  }

  /// @notice Setter to set the allocation of a specific protocol by a basketId. Only the owner of the basket can set this.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @param _chainId number of chainId.
  /// @param _protocolId Id of the protocol of which the allocation is queried.
  /// @param _allocation Number of derby tokens that are allocated towards this specific protocol.
  function setBasketAllocationInProtocol(
    uint256 _vaultNumber,
    uint256 _basketId,
    uint32 _chainId,
    uint256 _protocolId,
    int256 _allocation
  ) internal onlyBasketOwner(_basketId) {
    baskets[_basketId].allocations[_chainId][_protocolId] += _allocation;

    int256 currentAllocation = basketAllocationInProtocol(_basketId, _chainId, _protocolId);
    require(currentAllocation >= 0, "Basket: underflow");

    int256 currentReward = getRewardsPerLockedToken(
      _vaultNumber,
      _chainId,
      getRebalancingPeriod(_vaultNumber),
      _protocolId
    );

    if (currentReward == -1) {
      require(currentAllocation == 0, "Allocations to blacklisted protocol");
    }
  }

  /// @notice function to see the allocation of a specific protocol by a basketId. Only the owner of the basket can view this
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract
  /// @param _chainId number of chainId
  /// @param _protocolId Id of the protocol of which the allocation is queried
  /// @return int256 Number of derby tokens that are allocated towards this specific protocol
  function basketAllocationInProtocol(
    uint256 _basketId,
    uint256 _chainId,
    uint256 _protocolId
  ) public view onlyBasketOwner(_basketId) returns (int256) {
    return baskets[_basketId].allocations[_chainId][_protocolId];
  }

  /// @notice Setter for rebalancing period of the basket, used to calculate the rewards
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract
  /// @param _vaultNumber number of vault
  function setBasketRebalancingPeriod(
    uint256 _basketId,
    uint256 _vaultNumber
  ) internal onlyBasketOwner(_basketId) {
    baskets[_basketId].lastRebalancingPeriod = getRebalancingPeriod(_vaultNumber) + 1;
  }

  /// @notice function to see the total unredeemed rewards the basket has built up. Only the owner of the basket can view this.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @return int256 Total unredeemed rewards. (in vaultCurrency.decimals())
  function basketUnredeemedRewards(
    uint256 _basketId
  ) public view onlyBasketOwner(_basketId) returns (int256) {
    return 10 * 1e6;
  }

  /// @notice function to see the total reeemed rewards from the basket. Only the owner of the basket can view this.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @return int256 Total redeemed rewards.
  function basketRedeemedRewards(
    uint256 _basketId
  ) public view onlyBasketOwner(_basketId) returns (int) {
    return 40 * 1e6;
  }

  /// @notice Mints a new NFT with a Basket of allocations.
  /// @dev The basket NFT is minted for a specific vault, starts with a zero allocation and the tokens are not locked here.
  /// @param _vaultNumber Number of the vault. Same as in Router.
  /// @param _name Name of your basket
  /// @return basketId The basket Id the user has minted.
  function mintNewBasket(
    uint256 _vaultNumber,
    string memory _name
  ) external nonReentrant returns (uint256) {
    // mint Basket with nrOfUnAllocatedTokens equal to _lockedTokenAmount
    baskets[latestBasketId].vaultNumber = _vaultNumber;
    baskets[latestBasketId].lastRebalancingPeriod = getRebalancingPeriod(_vaultNumber) + 1;
    _safeMint(msg.sender, latestBasketId);
    latestBasketId++;

    emit BasketId(msg.sender, latestBasketId - 1, _vaultNumber, _name);
    return latestBasketId - 1;
  }

  /// @notice Function to lock xaver tokens to a basket. They start out to be unallocated.
  /// @param _lockedTokenAmount Amount of xaver tokens to lock inside this contract.
  function lockTokensToBasket(uint256 _lockedTokenAmount) internal {
    uint256 balanceBefore = derbyToken.balanceOf(address(this));
    derbyToken.safeTransferFrom(msg.sender, address(this), _lockedTokenAmount);
    uint256 balanceAfter = derbyToken.balanceOf(address(this));

    require((balanceAfter - balanceBefore - _lockedTokenAmount) == 0, "Error lock: under/overflow");
  }

  /// @notice Function to unlock xaver tokens. If tokens are still allocated to protocols they first hevae to be unallocated.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @param _unlockedTokenAmount Amount of derby tokens to unlock and send to the user.
  function unlockTokensFromBasket(uint256 _basketId, uint256 _unlockedTokenAmount) internal {
    uint256 tokensBurned = redeemNegativeRewards(_basketId, _unlockedTokenAmount);
    uint256 tokensToUnlock = _unlockedTokenAmount -= tokensBurned;

    uint256 balanceBefore = derbyToken.balanceOf(address(this));
    derbyToken.safeTransfer(msg.sender, tokensToUnlock);
    uint256 balanceAfter = derbyToken.balanceOf(address(this));

    require((balanceBefore - balanceAfter - tokensToUnlock) == 0, "Error unlock: under/overflow");
  }

  /// @notice IMPORTANT: The negativeRewardFactor takes in account an approximation of the price of derby tokens by the dao
  /// @notice IMPORTANT: This will change to an exact price when there is a derby token liquidity pool
  /// @notice Calculates if there are any negative rewards and how many tokens to burn
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract
  /// @param _unlockedTokens Amount of derby tokens to unlock and send to user
  /// @return tokensToBurn Amount of derby tokens that are burned
  function redeemNegativeRewards(
    uint256 _basketId,
    uint256 _unlockedTokens
  ) internal returns (uint256) {
    if (baskets[_basketId].totalUnRedeemedRewards > negativeRewardThreshold) return 0;

    uint256 vaultNumber = baskets[_basketId].vaultNumber;
    uint256 unreedemedRewards = uint(-baskets[_basketId].totalUnRedeemedRewards);
    uint256 price = tokenPrice[vaultNumber];

    uint256 tokensToBurn = (((unreedemedRewards * negativeRewardFactor) / 100) / price);
    tokensToBurn = tokensToBurn < _unlockedTokens ? tokensToBurn : _unlockedTokens;

    baskets[_basketId].totalUnRedeemedRewards += int(
      (tokensToBurn * 100 * price) / negativeRewardFactor
    );

    IERC20(derbyToken).safeTransfer(homeVault[vaultNumber], tokensToBurn);

    return tokensToBurn;
  }

  /// @notice rebalances an existing Basket
  /// @dev First calculates the rewards the basket has built up, then sets the new allocations and communicates the deltas to the vault
  /// @dev Finally it locks or unlocks tokens
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  /// @param _deltaAllocations delta allocations set by the user of the basket. Allocations are scaled (so * 1E18).
  function rebalanceBasket(
    uint256 _basketId,
    int256[][] memory _deltaAllocations
  ) external onlyBasketOwner(_basketId) nonReentrant {
    uint256 vaultNumber = baskets[_basketId].vaultNumber;
    checkRebalanceAuthorization(vaultNumber);

    addToTotalRewards(_basketId);
    int256 totalDelta = settleDeltaAllocations(_basketId, vaultNumber, _deltaAllocations);

    lockOrUnlockTokens(_basketId, totalDelta);
    setBasketTotalAllocatedTokens(_basketId, totalDelta);
    setBasketRebalancingPeriod(_basketId, vaultNumber);

    emit RebalanceBasket(
      _basketId,
      getRebalancingPeriod(vaultNumber),
      basketUnredeemedRewards(_basketId),
      basketRedeemedRewards(_basketId)
    );
  }

  /// @notice Checks if the basket is allowed to be rebalanced.
  /// @param _vaultNumber The vault number to be checked.
  function checkRebalanceAuthorization(uint256 _vaultNumber) internal view {
    for (uint k = 0; k < chainIds.length; k++) {
      require(!isXChainRebalancing[_vaultNumber][chainIds[k]], "Game: vault is xChainRebalancing");
    }

    if (getRebalancingPeriod(_vaultNumber) != 0) {
      require(
        getNumberOfRewardsReceived(_vaultNumber) == chainIds.length,
        "Game: not all rewards are settled"
      );
    }
  }

  /// @notice Internal helper to calculate and settle the delta allocations from baskets
  /// @dev Sets the total allocations per ChainId, used in XChainController
  /// @dev Sets the total allocations per protocol number, used in Vaults
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract
  /// @param _vaultNumber number of vault
  /// @param _deltaAllocations delta allocations set by the user of the basket. Allocations are scaled (so * 1E18)
  /// @return totalDelta total delta allocated tokens of the basket, used in lockOrUnlockTokens
  function settleDeltaAllocations(
    uint256 _basketId,
    uint256 _vaultNumber,
    int256[][] memory _deltaAllocations
  ) internal returns (int256 totalDelta) {
    for (uint256 i = 0; i < _deltaAllocations.length; i++) {
      int256 chainTotal;
      uint32 chain = chainIds[i];
      uint256 latestProtocol = latestProtocolId[chain];
      require(_deltaAllocations[i].length == latestProtocol, "Invalid allocation length");

      for (uint256 j = 0; j < latestProtocol; j++) {
        int256 allocation = _deltaAllocations[i][j];
        if (allocation == 0) continue;
        chainTotal += allocation;
        addDeltaAllocationProtocol(_vaultNumber, chain, j, allocation);
        setBasketAllocationInProtocol(_vaultNumber, _basketId, chain, j, allocation);
      }

      totalDelta += chainTotal;
      addDeltaAllocationChain(_vaultNumber, chain, chainTotal);
    }
  }

  /// @notice rewards are calculated here.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  function addToTotalRewards(uint256 _basketId) internal onlyBasketOwner(_basketId) {
    if (baskets[_basketId].nrOfAllocatedTokens == 0) return;

    uint256 vaultNum = baskets[_basketId].vaultNumber;
    uint256 currentRebalancingPeriod = IVault(homeVault[vaultNum]).rebalancingPeriod();
    uint256 lastRebalancingPeriod = baskets[_basketId].lastRebalancingPeriod;

    require(currentRebalancingPeriod >= lastRebalancingPeriod, "Already rebalanced");

    for (uint k = 0; k < chainIds.length; k++) {
      uint32 chain = chainIds[k];
      uint256 latestProtocol = latestProtocolId[chain];
      for (uint i = 0; i < latestProtocol; i++) {
        int256 allocation = basketAllocationInProtocol(_basketId, chain, i) / 1E18;
        if (allocation == 0) continue;

        int256 currentReward = getRewardsPerLockedToken(
          vaultNum,
          chain,
          currentRebalancingPeriod,
          i
        );
        // -1 means the protocol is blacklisted
        if (currentReward == -1) continue;

        int256 lastRebalanceReward = getRewardsPerLockedToken(
          vaultNum,
          chain,
          lastRebalancingPeriod,
          i
        );

        baskets[_basketId].totalUnRedeemedRewards +=
          (currentReward - lastRebalanceReward) *
          allocation;
      }
    }
  }

  /// @notice Internal helper to lock or unlock tokens from the game contract
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract
  /// @param _totalDelta total delta allocated tokens of the basket, calculated in settleDeltaAllocations
  function lockOrUnlockTokens(uint256 _basketId, int256 _totalDelta) internal {
    if (_totalDelta > 0) {
      lockTokensToBasket(uint256(_totalDelta));
    }
    if (_totalDelta < 0) {
      int256 oldTotal = basketTotalAllocatedTokens(_basketId);
      int256 newTotal = oldTotal + _totalDelta;
      int256 tokensToUnlock = oldTotal - newTotal;
      require(oldTotal >= tokensToUnlock, "Not enough tokens locked");

      unlockTokensFromBasket(_basketId, uint256(tokensToUnlock));
    }
  }

  /// @notice Step 1 trigger; Game pushes totalDeltaAllocations to xChainController
  /// @notice Trigger for Dao to push delta allocations to the xChainController
  /// @param _vaultNumber Number of vault
  /// @dev Sends over an array that should match the IDs in chainIds array
  function pushAllocationsToController(uint256 _vaultNumber) external payable notInSameBlock {
    require(rebalanceNeeded(_vaultNumber), "No rebalance needed");
    for (uint k = 0; k < chainIds.length; k++) {
      require(
        getVaultAddress(_vaultNumber, chainIds[k]) != address(0),
        "Game: not a valid vaultnumber"
      );
      require(
        !isXChainRebalancing[_vaultNumber][chainIds[k]],
        "Game: vault is already rebalancing"
      );
      isXChainRebalancing[_vaultNumber][chainIds[k]] = true;
    }

    int256[] memory deltas = allocationsToArray(_vaultNumber);
    IXProvider(xProvider).pushAllocations{value: msg.value}(_vaultNumber, deltas);

    lastTimeStamp[_vaultNumber] = block.timestamp;
    vaults[_vaultNumber].numberOfRewardsReceived = 0;

    emit PushedAllocationsToController(_vaultNumber, deltas);
  }

  /// @notice Creates delta allocation array for chains matching IDs in chainIds array
  /// @notice Resets deltaAllocation for chainIds
  /// @return deltas Array with delta Allocations for all chainIds
  function allocationsToArray(uint256 _vaultNumber) internal returns (int256[] memory deltas) {
    deltas = new int[](chainIds.length);

    for (uint256 i = 0; i < chainIds.length; i++) {
      uint32 chain = chainIds[i];
      deltas[i] = getDeltaAllocationChain(_vaultNumber, chain);
      vaults[_vaultNumber].deltaAllocationChain[chain] = 0;
    }
  }

  /// @notice Step 6 trigger; Game pushes deltaAllocations to vaults
  /// @notice Trigger to push delta allocations in protocols to cross chain vaults
  /// @param _vaultNumber Number of vault
  /// @param _chain Chain id of the vault where the allocations need to be sent
  /// @dev Sends over an array where the index is the protocolId
  function pushAllocationsToVaults(
    uint256 _vaultNumber,
    uint32 _chain
  ) external payable notInSameBlock {
    address vault = getVaultAddress(_vaultNumber, _chain);
    require(vault != address(0), "Game: not a valid vaultnumber");
    require(isXChainRebalancing[_vaultNumber][_chain], "Vault is not rebalancing");

    int256[] memory deltas = protocolAllocationsToArray(_vaultNumber, _chain);

    IXProvider(xProvider).pushProtocolAllocationsToVault{value: msg.value}(_chain, vault, deltas);

    emit PushProtocolAllocations(_chain, getVaultAddress(_vaultNumber, _chain), deltas);

    isXChainRebalancing[_vaultNumber][_chain] = false;
  }

  /// @notice Creates array with delta allocations in protocols for given chainId
  /// @return deltas Array with allocations where the index matches the protocolId
  function protocolAllocationsToArray(
    uint256 _vaultNumber,
    uint32 _chainId
  ) internal returns (int256[] memory deltas) {
    uint256 latestId = latestProtocolId[_chainId];
    deltas = new int[](latestId);

    for (uint256 i = 0; i < latestId; i++) {
      deltas[i] = getDeltaAllocationProtocol(_vaultNumber, _chainId, i);
      vaults[_vaultNumber].deltaAllocationProtocol[_chainId][i] = 0;
    }
  }

  /// @notice See settleRewardsInt below
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _rewards Rewards per locked token per protocol (each protocol is an element in the array)
  function settleRewards(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) external onlyXProvider {
    settleRewardsInt(_vaultNumber, _chainId, _rewards);
  }

  // basket should not be able to rebalance before this step
  /// @notice Step 8 end; Vaults push rewardsPerLockedToken to game
  /// @notice Loops through the array and fills the rewardsPerLockedToken mapping with the values
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _rewards Array with rewardsPerLockedToken of all protocols in vault => index matches protocolId
  function settleRewardsInt(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) internal {
    uint256 rebalancingPeriod = getRebalancingPeriod(_vaultNumber);
    for (uint256 i = 0; i < _rewards.length; i++) {
      int256 lastReward = getRewardsPerLockedToken(
        _vaultNumber,
        _chainId,
        rebalancingPeriod - 1,
        i
      );
      vaults[_vaultNumber].rewardPerLockedToken[_chainId][rebalancingPeriod][i] =
        lastReward +
        _rewards[i];
    }

    vaults[_vaultNumber].numberOfRewardsReceived++;
  }

  /// @notice Getter for rewardsPerLockedToken for given vaultNumber => chainId => rebalancingPeriod => protocolId
  function getRewardsPerLockedToken(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _rebalancingPeriod,
    uint256 _protocolId
  ) internal view returns (int256) {
    return vaults[_vaultNumber].rewardPerLockedToken[_chainId][_rebalancingPeriod][_protocolId];
  }

  /// @notice redeem funds from basket in the game.
  /// @dev makes a call to the vault to make the actual transfer because the vault holds the funds.
  /// @param _basketId Basket ID (tokenID) in the BasketToken (NFT) contract.
  function redeemRewards(uint256 _basketId) external onlyBasketOwner(_basketId) {
    int256 amount = baskets[_basketId].totalUnRedeemedRewards / int(BASE_SCALE);
    require(amount > 0, "Nothing to claim");

    baskets[_basketId].totalRedeemedRewards += amount;
    baskets[_basketId].totalUnRedeemedRewards = 0;

    uint256 vaultNumber = baskets[_basketId].vaultNumber;
    IVault(homeVault[vaultNumber]).redeemRewardsGame(uint256(amount), msg.sender);
  }

  /// @notice Checks if a rebalance is needed based on the set interval
  /// @param _vaultNumber The vault number to check for rebalancing
  /// @return bool True if rebalance is needed, false if not
  function rebalanceNeeded(uint256 _vaultNumber) public view returns (bool) {
    return
      (block.timestamp - lastTimeStamp[_vaultNumber]) > rebalanceInterval || msg.sender == guardian;
  }

  /// @notice getter for vault address linked to a chainId
  function getVaultAddress(uint256 _vaultNumber, uint32 _chainId) internal view returns (address) {
    return vaults[_vaultNumber].vaultAddress[_chainId];
  }

  /// @notice Getter for dao address
  function getDao() public view returns (address) {
    return dao;
  }

  /// @notice Getter for guardian address
  function getGuardian() public view returns (address) {
    return guardian;
  }

  /// @notice Getter for chainId array
  function getChainIds() public view returns (uint32[] memory) {
    return chainIds;
  }

  /// @notice Getter for rebalancing period for a vault
  function getRebalancingPeriod(uint256 _vaultNumber) public view returns (uint256) {
    1;
  }

  /// @notice Retrieves the number of rewards received for a specific vault.
  /// @param _vaultNumber The vault number to get the number of rewards received for.
  /// @return The number of rewards received for the specified vault.
  function getNumberOfRewardsReceived(uint256 _vaultNumber) public view returns (uint256) {
    return vaults[_vaultNumber].numberOfRewardsReceived;
  }

  /*
  Only Dao functions
  */

  /// @notice Setter for xProvider address
  /// @param _xProvider new address of xProvider on this chain
  function setXProvider(address _xProvider) external onlyDao {
    xProvider = _xProvider;
  }

  /// @notice Setter for homeVault address
  /// @param _vaultNumber The vault number to set the home vault for
  /// @param _homeVault new address of homeVault on this chain
  function setHomeVault(uint256 _vaultNumber, address _homeVault) external onlyDao {
    homeVault[_vaultNumber] = _homeVault;
  }

  /// @notice Set minimum interval for the rebalance function
  /// @param _timestampInternal UNIX timestamp
  function setRebalanceInterval(uint256 _timestampInternal) external onlyDao {
    rebalanceInterval = _timestampInternal;
  }

  /// @notice Setter for DAO address
  /// @param _dao DAO address
  function setDao(address _dao) external onlyDao {
    dao = _dao;
  }

  /// @notice Setter for guardian address
  /// @param _guardian new address of the guardian
  function setGuardian(address _guardian) external onlyDao {
    guardian = _guardian;
  }

  /// @notice Setter Derby token address
  /// @param _derbyToken new address of Derby token
  function setDerbyToken(address _derbyToken) external onlyDao {
    derbyToken = IERC20(_derbyToken);
  }

  /// @notice Setter for threshold at which user tokens will be sold / burned
  /// @param _threshold treshold in vaultCurrency e.g USDC, must be negative
  function setNegativeRewardThreshold(int256 _threshold) external onlyDao {
    negativeRewardThreshold = _threshold;
  }

  /// @notice Setter for negativeRewardFactor
  /// @param _factor percentage of tokens that will be sold / burned
  function setNegativeRewardFactor(uint256 _factor) external onlyDao {
    negativeRewardFactor = _factor;
  }

  /*
  Only Guardian functions
  */

  /// @notice Setter for tokenPrice
  /// @param _vaultNumber Number of the vault
  /// @param _tokenPrice tokenPrice in vaultCurrency / derbyTokenPrice
  function setTokenPrice(uint256 _vaultNumber, uint256 _tokenPrice) external onlyGuardian {
    tokenPrice[_vaultNumber] = _tokenPrice;
  }

  /// @notice setter to link a chainId to a vault address for cross chain functions
  function setVaultAddress(
    uint256 _vaultNumber,
    uint32 _chainId,
    address _address
  ) external onlyGuardian {
    vaults[_vaultNumber].vaultAddress[_chainId] = _address;
  }

  /// @notice Setter for latest protocol Id for given chainId.
  /// @param _chainId number of chain id set in chainIds array
  /// @param _latestProtocolId latest protocol Id aka number of supported protocol vaults, starts at 0
  function setLatestProtocolId(uint32 _chainId, uint256 _latestProtocolId) external onlyGuardian {
    latestProtocolId[_chainId] = _latestProtocolId;
  }

  /// @notice Setter for chainId array
  /// @param _chainIds array of all the used chainIds
  function setChainIds(uint32[] memory _chainIds) external onlyGuardian {
    chainIds = _chainIds;
  }

  /// @notice Guardian function to set state when vault gets stuck for whatever reason
  function setRebalancingState(
    uint256 _vaultNumber,
    uint32 _chain,
    bool _state
  ) external onlyGuardian {
    isXChainRebalancing[_vaultNumber][_chain] = _state;
  }

  /// @notice Step 8: Guardian function
  function settleRewardsGuard(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) external onlyGuardian {
    settleRewardsInt(_vaultNumber, _chainId, _rewards);
  }

  /// @notice Sets the value of numberOfRewardsReceived for a given vault number.
  /// @param _vaultNumber The vault number for which the numberOfRewardsReceived value should be set.
  /// @param _value The new value to set for numberOfRewardsReceived.
  function setNumberOfRewardsReceived(uint256 _vaultNumber, uint256 _value) external onlyGuardian {
    vaults[_vaultNumber].numberOfRewardsReceived = _value;
  }
}