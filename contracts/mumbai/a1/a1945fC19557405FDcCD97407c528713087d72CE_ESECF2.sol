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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

import "../permissions/PermissionsOverwriter.sol";
import "../permissions/PermissionsAware.sol";

import "../spv/ERC20CregistryBase3Whitelisting.sol";
import "../spv/ERC20Whitelisting.sol";

contract GeSAct20v1 is Context, ERC20CregistryBase3, ERC20Whitelisting, ERC20Pausable {
    struct ContractParameters {
        string isin;
        string issuerName;
        string recordKeeping;
        string mixedRecordKeeping;
        string terms;
        string transferRestrictions;
        string thirdPartyRights;
    }

    bytes32 public constant PROP_ISIN = keccak256("ISIN");
    bytes32 public constant PROP_ISSUER_NAME = keccak256("ISSUER_NAME");
    bytes32 public constant PROP_TERMS = keccak256("TERMS");
    bytes32 public constant PROP_RECORD_KEEPING = keccak256("RECORD_KEEPING");
    bytes32 public constant PROP_MIXED_RECORD_KEEPING = keccak256("MIXED_RECORD_KEEPING");
    bytes32 public constant PROP_TRANSFER_RESTRICTIONS = keccak256("TRANSFER_RESTRICTIONS");
    bytes32 public constant PROP_THIRD_PARTY_RIGHTS = keccak256("THIRD_PARTY_RIGHTS");

    constructor(
        IPermissions55 permissions_,
        uint256 permissionSetId_,
        string memory name_,
        string memory symbol_,
        string memory denomination_,
        ContractParameters memory params_
    ) ERC20CregistryBase3(permissions_, permissionSetId_, name_, symbol_, denomination_) {
        _setParameters(params_);
    }

    function _setParameters(ContractParameters memory params) internal {
        _properties[PROP_ISIN] = params.isin;
        _properties[PROP_ISSUER_NAME] = params.issuerName;
        _properties[PROP_TERMS] = params.terms;
        _properties[PROP_RECORD_KEEPING] = params.recordKeeping;
        _properties[PROP_MIXED_RECORD_KEEPING] = params.mixedRecordKeeping;
        _properties[PROP_THIRD_PARTY_RIGHTS] = params.thirdPartyRights;
        _properties[PROP_TRANSFER_RESTRICTIONS] = params.transferRestrictions;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20CregistryBase3, ERC20Whitelisting, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (_hasRole(TOKEN_ROLE_OPERATOR, _msgSender())) {
            return;
        }

        super._spendAllowance(owner, spender, amount);
    }

    function increaseAllowanceAs(
        address owner,
        address spender,
        uint256 addedValue
    ) public virtual onlyRole(TOKEN_ROLE_OPERATOR) returns (bool) {
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowanceAs(
        address owner,
        address spender,
        uint256 subtractedValue
    ) public virtual onlyRole(TOKEN_ROLE_OPERATOR) returns (bool) {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferBatch(
        address from,
        address[] memory tos,
        uint256[] memory amounts
    ) public onlyRole(TOKEN_ROLE_OPERATOR) {
        require(tos.length == amounts.length, "GeSAct20v1: parameters length mismatch");

        for (uint256 i = 0; i < tos.length; i++) {
            _transfer(from, tos[i], amounts[i]);
        }
    }

    function _hasRole(uint256 roleTokenId, address account) internal view virtual override(ERC20CregistryBase3, PermissionsAware) returns (bool) {
        return super._hasRole(roleTokenId, account);
    }
    
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "../permissions/PermissionsAware.sol";
import "./OPUSv2.sol";

contract ESECF2 is Context, PermissionsAware {
    event ContractDeployed(address indexed result);

    address[] private _deployedTokens;
    mapping(address => address[]) private _tokenCreators;

    address private _owner;

    constructor(IPermissions55 permissions_) PermissionsAware(permissions_) {
        _owner = _msgSender();
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function create(
        uint256 permissionSetId,
        string calldata name,
        string calldata symbol,
        string calldata denomination,
        OPUSv2.ContractParameters calldata params
    ) external {
        _checkRole(TOKEN_ROLE_DEPLOYER);

        OPUSv2 token = new OPUSv2(_permissions, permissionSetId, name, symbol, denomination, params);

        _deployedTokens.push(address(token));
        _tokenCreators[_msgSender()].push(address(token));

        emit ContractDeployed(address(token));
    }

    function addToken(address token) external {
        _checkRole(TOKEN_ROLE_DEPLOYER);

        _deployedTokens.push(address(token));
        _tokenCreators[_msgSender()].push(address(token));
    }

    /**
     * @dev Returns one of the tokens. `index` must be a
     * value between 0 and {getTokenCount}, non-inclusive.
     *
     * Tokens are not sorted in any particular way, and their ordering may
     * change at any point.
     */
    function getToken(uint256 index) public view returns (address) {
        if (index >= _deployedTokens.length) {
            revert("Index out of bounds");
        }
        return _deployedTokens[index];
    }

    /**
     * @dev Returns one of the tokens of a creator. `index` must be a
     * value between 0 and {getTokenCount}, non-inclusive.
     *
     * Tokens are not sorted in any particular way, and their ordering may
     * change at any point.
     */
    function getToken(address creator, uint256 index) public view returns (address) {
        return _tokenCreators[creator][index];
    }

    function getMyToken(uint256 index) public view returns (address) {
        return _tokenCreators[_msgSender()][index];
    }

    /**
     * @dev Returns the number of deployed tokens.
     */
    function getTokenCount() public view returns (uint256) {
        return _deployedTokens.length;
    }

    /**
     * @dev Returns the number of accounts that have `creator`.
     */
    function getTokenCount(address creator) public view returns (uint256) {
        return _tokenCreators[creator].length;
    }

    function getMyTokenCount() public view returns (uint256) {
        return _tokenCreators[_msgSender()].length;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "../GeSAct/GeSAct20v1.sol";

contract OPUSv2 is GeSAct20v1 {
    constructor(
        IPermissions55 permissions_,
        uint256 permissionSetId_,
        string memory name_,
        string memory symbol_,
        string memory denomination_,
        ContractParameters memory params_
    ) GeSAct20v1(permissions_, permissionSetId_, name_, symbol_, denomination_, params_) {}
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

interface IPropertiesAware {
    function getProperty(bytes32 key) external view returns (string memory);

    function setProperty(bytes32 key, string memory val_) external;
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPropertiesAware.sol";

interface ISPVContract is IERC20, IPropertiesAware {
    function mint(address to, uint256 amount) external;

    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]
pragma solidity ^0.8.7;

interface CregistryErrors {
    /**
     * @dev Revert with an error when RoleId-overwrite did not changed anything
     */
    /// RoleId-overwrite did not changed anything
    error ErrRoleIdOverwriteNotChanged(uint256 roleId, bool overwrite);

    /**
     * @dev Revert with an error when value `val_` was already set before for the property `key`
     */
    /// The value `val_` was already set before for the property `key`
    /// @param key The name of the property
    /// @param val_ The value
    error NewValueIsEqualToOldValue(bytes32 key, string val_);

    /**
     * @dev Revert with an error when this PermissionSet has been already applied
     */
    /// This PermissionSet has been already applied
    error ErrPermissionSetIDWasAlreadySet();
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "../permissions/PermissionRoles.sol";
import "../lib/CregistryErrors.sol";
import "../interfaces/IPropertiesAware.sol";
import "../permissions/PermissionsAware.sol";

abstract contract PropertiesAware is PermissionsAware, CregistryErrors, IPropertiesAware {
    event PropertyChanged(bytes32 indexed propertyName, bytes oldValue, bytes newValue);

    mapping(bytes32 => string) internal _properties;

    function getProperty(bytes32 key) public view override returns (string memory) {
        return _properties[key];
    }

    function setProperty(bytes32 key, string memory val_) public override onlyRole(TOKEN_ROLE_ADMIN) {
        string memory oldValue = _properties[key];

        if (keccak256(bytes(oldValue)) == keccak256(bytes(val_))) {
            revert NewValueIsEqualToOldValue(key, val_);
        }

        _properties[key] = val_;

        emit PropertyChanged(key, bytes(oldValue), bytes(val_));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibSet_uint256 {
    struct set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    function length(set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    function at(set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index - 1];
    }

    function indexOf(set storage _set, uint256 _value) internal view returns (uint256) {
        return _set.indexes[_value];
    }

    function contains(set storage _set, uint256 _value) internal view returns (bool) {
        return indexOf(_set, _value) != 0;
    }

    function content(set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }

    function add(set storage _set, uint256 _value) internal returns (bool) {
        if (contains(_set, _value)) {
            return false;
        }
        _set.values.push(_value);
        _set.indexes[_value] = _set.values.length;
        return true;
    }

    function remove(set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            return false;
        }

        uint256 i = indexOf(_set, _value);
        uint256 last = length(_set);

        if (i != last) {
            uint256 swapValue = _set.values[last - 1];
            _set.values[i - 1] = swapValue;
            _set.indexes[swapValue] = i;
        }

        delete _set.indexes[_value];
        _set.values.pop();

        return true;
    }

    function clear(set storage _set) internal returns (bool) {
        for (uint256 i = _set.values.length; i > 0; --i) {
            delete _set.indexes[_set.values[i - 1]];
        }
        _set.values = new uint256[](0);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity >=0.8.7;

interface IPermissions55 {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract PermissionRoles is Context {
    // ***** Roles ********
    uint256 public constant TOKEN_ROLE_ADMIN = 1;
    uint256 public constant TOKEN_ROLE_DEPLOYER = 2;
    uint256 public constant TOKEN_ROLE_WHITELIST_ADMIN = 3;
    uint256 public constant TOKEN_ROLE_BLACKLIST_ADMIN = 4;
    uint256 public constant TOKEN_ROLE_MINTER = 5;
    uint256 public constant TOKEN_ROLE_TRANSFERER = 6;
    uint256 public constant TOKEN_ROLE_OPERATOR = 7;
    uint256 public constant TOKEN_ROLE_IS_WHITELISTED = 8;
    uint256 public constant TOKEN_ROLE_IS_BLACKLISTED = 9;

}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "../lib/solstruct/LibSet.uint256.sol";

import "./PermissionRoles.sol";
import "./IPermissions55.sol";

abstract contract PermissionsAware is PermissionRoles {
    using LibSet_uint256 for LibSet_uint256.set;

    IPermissions55 internal _permissions;

    event PermissionsChanged(IPermissions55 indexed oldValue, IPermissions55 indexed newValue);

    /**
     * @dev Modifier to make a function callable only when a specific role is met
     */
    modifier onlyRole(uint256 roleTokenId) {
        _checkRole(roleTokenId, _msgSender());
        _;
    }


    constructor(IPermissions55 permissions_) {
        _permissions = permissions_;
    }

    function _changePermissions55(IPermissions55 permissions_) internal {
        IPermissions55 old = _permissions;
        if (_permissions != permissions_) {
            _permissions = permissions_;
            emit PermissionsChanged(old, _permissions);
        }
    }

    function permissions() public view returns (IPermissions55) {
        return _permissions;
    }

    function _hasRole(uint256 tokenId, address account) internal view virtual returns (bool) {
        if (_permissions.balanceOf(account, tokenId) > 0) {
            return true;
        }

        return false;
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `roleTokenId`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(uint256 roleTokenId) internal view virtual {
        _checkRole(roleTokenId, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `roleTokenId`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(uint256 roleTokenId, address account) internal view virtual {
        if (!_hasRole(roleTokenId, account) && !_hasRole(TOKEN_ROLE_ADMIN, account)) {
            revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(account), 20),
                    " is missing role ",
                    Strings.toHexString(roleTokenId)
                )
            )
            );
        }
    }

    function hasRole(uint256 tokenId, address account) external view returns (bool) {
        return _hasRole(tokenId, account);
    }

    function hasRole(uint256 tokenId) external view returns (bool) {
        return _hasRole(tokenId, _msgSender());
    }
    
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "./PermissionsAware.sol";
import "../lib/CregistryErrors.sol";

contract PermissionsOverwriter is PermissionsAware, CregistryErrors {
    event SetRoleIdOverwritten(uint256 roleId, bool overwrite);

    uint256 public constant PERMISSION_ID_DELTA = 1000;

    event PermissionSetIdChanged(uint256 indexed oldPermissionSetId, uint256 indexed newPermissionSetId);

    uint256 private _permissionSetId;

    mapping(uint256 => bool) internal _overwrittenRoleIds;

    struct OverwriteRoleId {
        uint256 roleId;
        bool overwritten;
    }

    constructor(IPermissions55 permissions_, uint256 permissionSetId_) PermissionsAware(permissions_) {
        _permissionSetId = permissionSetId_;
    }

    function getPermissionSetId() external view returns (uint256) {
        return _permissionSetId;
    }

    function setPermissionSetId(uint256 permissionSetId) external onlyRole(TOKEN_ROLE_ADMIN) {
        if (_permissionSetId == permissionSetId) {
            revert ErrPermissionSetIDWasAlreadySet();
        }

        uint256 oldPermissionSetId = _permissionSetId;

        _permissionSetId = permissionSetId;

        emit PermissionSetIdChanged(oldPermissionSetId, permissionSetId);
    }

    function transformedRoleId(uint256 permissionSetId_, uint256 roleId) public pure returns (uint256) {
        return permissionSetId_ * PERMISSION_ID_DELTA + roleId;
    }

    function isRoleIdOverwritten(uint256 roleId) public view returns (bool) {
        return _overwrittenRoleIds[roleId];
    }

    function setRoleIdOverwrite(uint256 roleId, bool overwrite) public {
        if (_overwrittenRoleIds[roleId] == overwrite) {
            revert ErrRoleIdOverwriteNotChanged(roleId, overwrite);
        }

        _overwrittenRoleIds[roleId] = overwrite;
        emit SetRoleIdOverwritten(roleId, overwrite);

        if (roleId == TOKEN_ROLE_WHITELIST_ADMIN) {
            _overwrittenRoleIds[TOKEN_ROLE_IS_WHITELISTED] = overwrite;
            emit SetRoleIdOverwritten(TOKEN_ROLE_IS_WHITELISTED, overwrite);
        } else if (roleId == TOKEN_ROLE_BLACKLIST_ADMIN) {
            _overwrittenRoleIds[TOKEN_ROLE_IS_BLACKLISTED] = overwrite;
            emit SetRoleIdOverwritten(TOKEN_ROLE_IS_BLACKLISTED, overwrite);
        }
    }

    // Check if this was overwritten or not
    function _hasRole(uint256 roleTokenId, address account) internal view virtual override returns (bool) {
        if (super._hasRole(roleTokenId, account)) {
            return true;
        }

        if (_overwrittenRoleIds[roleTokenId]) {
            return super._hasRole(transformedRoleId(_permissionSetId, roleTokenId), account);
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../permissions/PermissionsAware.sol";
import "../lib/CregistryErrors.sol";
import "../lib/PropertiesAware.sol";
import "../permissions/PermissionsOverwriter.sol";
import "../interfaces/ISPVContract.sol";

contract ERC20CregistryBase3 is ERC20Burnable, PropertiesAware, PermissionsOverwriter, ISPVContract {
    bytes32 public constant PROP_NAME = keccak256("PROP_NAME");
    bytes32 public constant PROP_DENOMINATION = keccak256("PROP_DENOMINATION");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        IPermissions55 permissions_,
        uint256 permissionSetId_,
        string memory name_,
        string memory symbol_,
        string memory denomination_
    ) ERC20(name_, symbol_) PermissionsOverwriter(permissions_, permissionSetId_) {
        _properties[PROP_NAME] = name_;
        _properties[PROP_DENOMINATION] = denomination_;
    }

    function version() external pure virtual override returns (uint256) {
        return 3;
    }

    function changePermissions55(IPermissions55 newValue) external onlyRole(TOKEN_ROLE_ADMIN) {
        _changePermissions55(newValue);
    }

    function transferFromAs(
        address from,
        address to,
        uint256 amount
    ) public onlyRole(TOKEN_ROLE_OPERATOR) returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public override onlyRole(TOKEN_ROLE_MINTER) {
        _mint(to, amount);
    }

    function mintBatch(address[] memory to, uint256[] memory amount) public onlyRole(TOKEN_ROLE_MINTER) {
        require(
            to.length == amount.length,
            "ERC20CregistryBase3: length of to-array differs from length of amount-array"
        );

        for (uint256 i = 0; i < to.length; ++i) {
            _mint(to[i], amount[i]);
        }
    }

    function balanceOfBatch(address[] memory accounts) public view returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Destroys `amount` new tokens for `from`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function burnAs(address from, uint256 amount) public onlyRole(TOKEN_ROLE_OPERATOR) {
        _burn(from, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (from != address(0) && to != address(0)) {
            if (_hasRole(TOKEN_ROLE_IS_BLACKLISTED, from)) {
                revert(
                    string(
                        abi.encodePacked(
                            "ERC20CregistryBase3: account ",
                            Strings.toHexString(uint160(from), 20),
                            " is blacklisted"
                        )
                    )
                );
            }
        }

        if (to != address(0) && _hasRole(TOKEN_ROLE_IS_BLACKLISTED, to)) {
            revert(
                string(
                    abi.encodePacked(
                        "ERC20CregistryBase3: account ",
                        Strings.toHexString(uint160(to), 20),
                        " is blacklisted"
                    )
                )
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _hasRole(uint256 roleTokenId, address account) internal view virtual override(PermissionsOverwriter, PermissionsAware) returns (bool) {
        return super._hasRole(roleTokenId, account);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "../permissions/PermissionsOverwriter.sol";
import "../permissions/PermissionsAware.sol";

import "./ERC20CregistryBase3.sol";
import "./ERC20Whitelisting.sol";

contract ERC20CregistryBase3Whitelisting is ERC20CregistryBase3, ERC20Whitelisting {
    constructor(
        IPermissions55 permissions_,
        uint256 permissionSetId_,
        string memory name_,
        string memory symbol_,
        string memory denomination_
    ) ERC20CregistryBase3(permissions_, permissionSetId_, name_, symbol_, denomination_) {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20CregistryBase3, ERC20Whitelisting) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _hasRole(uint256 roleTokenId, address account) internal view virtual override(ERC20CregistryBase3, PermissionsAware) returns (bool) {
        return super._hasRole(roleTokenId, account);
    }


}

// SPDX-License-Identifier: UNLICENSED
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, [email protected]

pragma solidity ^0.8.7;

import "./ERC20CregistryBase3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../permissions/PermissionsAware.sol";

abstract contract ERC20Whitelisting is ERC20, PermissionsAware {
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (to != address(0) && !_hasRole(TOKEN_ROLE_IS_WHITELISTED, to)) {
            revert(
                string(
                    abi.encodePacked(
                        "ERC20Whitelisting: account ",
                        Strings.toHexString(uint160(to), 20),
                        " is not verified"
                    )
                )
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}