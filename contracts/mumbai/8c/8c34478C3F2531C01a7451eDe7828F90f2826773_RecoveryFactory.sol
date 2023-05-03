// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity 0.8.17;
import "./interface/IAgentPayrollWallet.sol";
import "./EZR/interface/IEZR.sol";
import "./YousovAccessControl.sol";

import "./YousovRoles.sol";
import "./Controller/interface/IManagerController.sol";

contract AgentPayrollWallet is IAgentPayrollWallet,YousovRoles {
    address ezr;
    address yousovAccessControl;
    address managerController;
    mapping (address=> uint256 ) public lastClaimFreeTokens;
    constructor (address _ezr, address _yousovAccessControl, address _managerController) {
        ezr = _ezr;
        managerController = _managerController;
        yousovAccessControl= _yousovAccessControl;
        YousovAccessControl(_yousovAccessControl).setAgentPayrolWalletAddressAsMinter(address(this));
    }

    function activateTemporaryWallet() public {
        require(!YousovAccessControl(yousovAccessControl).hasRole(TEMPORARY_YOUSOV_USER_ROLE,msg.sender),"YOUSOV: You are already a temporary yousov user");
        YousovAccessControl(yousovAccessControl).grantRole(TEMPORARY_YOUSOV_USER_ROLE,msg.sender);
        lastClaimFreeTokens[msg.sender] = block.timestamp;
    }

    // Mint 0.05 free EZR
    function claimFreeEZR() external override {
        require((block.timestamp >= lastClaimFreeTokens[msg.sender] + 1 days) && YousovAccessControl(yousovAccessControl).hasRole(TEMPORARY_YOUSOV_USER_ROLE, msg.sender) , "YOUSOV : Not authorized to claim");
        IEZR(ezr).mint(msg.sender,IManagerController(managerController).getValueDec("amountFaucet"));
        lastClaimFreeTokens[msg.sender] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../Controller/interface/IManagerController.sol";
contract YousovAgregator {
    AggregatorV3Interface internal priceFeed;
    address managerController;
    constructor(address _managerController) {
        managerController = _managerController;
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // Matic/USD Chainlink price feed
    }

    function getMaticPrice() public view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        uint256 maticPrice = uint256(price) * 10 ** 10; // convert Chainlink price to wei
        return maticPrice;
    }

    function getMaticPriceInUSDC() public view returns (uint256) {
        uint256 maticPrice = getMaticPrice();
        AggregatorV3Interface usdcPriceFeed = AggregatorV3Interface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0); // USDC/USD Chainlink price feed
        (, int256 usdcPrice, , ,) = usdcPriceFeed.latestRoundData();
        uint256 usdcPriceWei = uint256(usdcPrice) * 10 ** 10; // convert Chainlink price to wei
        uint256 maticPriceInUSDC = (maticPrice * usdcPriceWei) / (10 ** 18); // calculate Matic price in USDC
        return maticPriceInUSDC;
    }
    // 1 $EZR -> 50 USDC
    function getAmountEZROut(bool isMatic,uint256 amountIn) public view returns(uint256) {
        if (isMatic) {
           uint256 maticInUSDCPrice=  getMaticPriceInUSDC();
           return (maticInUSDCPrice * amountIn) / (IManagerController(managerController).getValueInt("minimumRecoveryPriceUsd") * 10**18);
        } else {
           return amountIn / IManagerController(managerController).getValueInt("minimumRecoveryPriceUsd") ;      
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;

import "../../interface/IYousovStructs.sol";

interface IManagerController is IYousovStructs{
    function getAllValues() external returns (string memory values);
    function updateVariables(VariablesInt[] memory changedVariablesInt, VariablesDec[] memory changedVariablesDec, VariablesString[] memory changedVariablesString, VariablesBool[] memory changedVariablesBool, address _treasuryAddress) external;
    function getValueInt(string memory variableName) external view returns(uint256);
    function getValueDec(string memory variableName) external view returns(uint256);
    function treasuryAddress() external view returns(address treasuryAddress);
    function getValueString(string memory variableName) external returns(string memory);
    function getValueBool(string memory variableName) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../YousovAccessControl.sol';
import '../interface/IYousovStructs.sol';
import './interface/IManagerController.sol';
import '../lib/ManagerHelper.sol';

contract ManagerController is YousovRoles, IManagerController  {


    VariablesInt[] variablesInt;
    string[] variableNamesInt;
    uint[] valuesInt;


    VariablesDec[] variablesDec;
    string[] variableNamesDec;
    uint[] valuesDec;


    VariablesString[] variablesString;
    string[] variableNamesString;
    string[] valuesString;

    VariablesBool[] variablesBool;
    string[] variableNamesBool;
    bool[] valuesBool;


    address public treasuryAddress;

    address yousovAccessControl;

    constructor(address _youSovAccessControl, address _treasuryAddress) {
        treasuryAddress=_treasuryAddress;
        yousovAccessControl = _youSovAccessControl;
        variableNamesInt = [
            "minimumRecoveryPriceUsd",
            "minimumRecoveryPriceEzr",
            "zeroEZRBalancePriceFactor",//TODO v2
            "numberOfTestsAgentsMo",//TODO v2
            "maximumNumberOfAgents",
            "maxLottery",//TODO v2
            "attempt2Price",//TODO v2
            "attempt3Price",//TODO v2
            "attempt4Price",//TODO v2
            "attempt5Price",//TODO v2
            "minimumAgentsAppear",
            "timeLimitFaucet", // TODO when manage timers
            "bundleOfferExpiration",
            "emptyWalletRecovery" //TODO v2
        ];
        valuesInt = [
            50,
            10**18,
            2,
            12,
            40000,
            1000000,
            75,
            100,
            200,
            500,
            500,
            86400,
            5184000,
            2
        ];

        for (uint256 i = 0; i < variableNamesInt.length; i++) {
            variablesInt.push(VariablesInt(variableNamesInt[i], valuesInt[i]));
        }

         variableNamesDec = [
            "testRecoveryRewardRatio",//TODO v2
            "totalAgentsRatio",//TODO v2
            "seniorAgentsRatio",//TODO v2
            "stakingRewardPerYear",//TODO v2
            "seniorAgentRate",//TODO v2
            "juniorAgentRate",//TODO v2
            "standardsRate",//TODO v2
            "deniedRate",//TODO v2
            "agentPayrollWalletFromJunior",//TODO v2
            "agentPayrollWalletFromDenied",//TODO v2
            "agentPayrollWalletFromRecovery",
            "bonusShare",//TODO v2
            "seniorAgentsBonusShare",//TODO v2
            "senioAgentsLotteryOdds",//TODO v2
            "juniorAgentsLotteryOdds",//TODO v2
            "standards",//TODO v2
            "burn",
            "amountFaucet"
            ];
         valuesDec = [
            2500,
            30000,
            150000,
            6000,
            1200000,
            900000,
            750000,
            0,
            800000,
            500000,
            50,
            800000,
            700000,
            600000,
            150000,
            200000,
            30,
            5 * 10**16
            ];

         for (uint256 i = 0; i < variableNamesDec.length; i++) {
            variablesDec.push(VariablesDec(variableNamesDec[i], valuesDec[i]));
        }

        variableNamesString = [
            "agentType",
            "urlFaucet"
        ];

        valuesString = [
            "human",//TODO v2
            "http://yousov.com/faucet" //TODO v2
        ];

         for (uint256 i = 0; i < variableNamesString.length; i++) {
            variablesString.push(VariablesString(variableNamesString[i], valuesString[i]));
        }

        variableNamesBool = [
            "stakingRewardsPanic",//TODO v2
            "agentRewardsPanic",//TODO v2
            "recoveriesPanic"
        ];

        valuesBool = [
            false,
            false,
            false
        ];

        for (uint256 i = 0; i < variableNamesBool.length; i++) {
            variablesBool.push(VariablesBool(variableNamesBool[i], valuesBool[i]));
        }

    }

    function updateVariables(VariablesInt[] memory changedVariablesInt, VariablesDec[] memory changedVariablesDec, VariablesString[] memory changedVariablesString, VariablesBool[] memory changedVariablesBool, address _treasuryAddress) external override {
      require(
            YousovAccessControl(yousovAccessControl).hasRole(
                MANAGER_ROLE,
                tx.origin
            ),
            "You dont have the rights to change variables"
        );
        treasuryAddress = _treasuryAddress;
        for (uint i = 0; i < changedVariablesInt.length; i++) {
            for (uint j = 0; j < variablesInt.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesInt[i].variableNameInt)
                    ) == keccak256(abi.encodePacked(variablesInt[j].variableNameInt))
                ) {
                    variablesInt[j].valueInt = changedVariablesInt[i].valueInt;
                }
            }
        }
        for (uint i = 0; i < changedVariablesDec.length; i++) {
            for (uint j = 0; j < variablesDec.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesDec[i].variableNameDec)
                    ) == keccak256(abi.encodePacked(variablesDec[j].variableNameDec))
                ) {
                    variablesDec[j].valueDec = changedVariablesDec[i].valueDec;
                }
            }
        }
        for (uint i = 0; i < changedVariablesString.length; i++) {
            for (uint j = 0; j < variablesString.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesString[i].variableNameString)
                    ) == keccak256(abi.encodePacked(variablesString[j].variableNameString))
                ) {
                    variablesString[j].valueString = changedVariablesString[i].valueString;
                }
            }
        }
        for (uint i = 0; i < changedVariablesBool.length; i++) {
            for (uint j = 0; j < variablesBool.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariablesBool[i].variableNameBool)
                    ) == keccak256(abi.encodePacked(variablesBool[j].variableNameBool))
                ) {
                    variablesBool[j].valueBool = changedVariablesBool[i].valueBool;
                }
            }
        }
    }



    function getValueString(
        string memory variableName
    ) external view override returns (string memory) {
        string memory vr = "";
        for (uint i = 0; i < variablesString.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesString[i].variableNameString)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesString[i].valueString;
            }
        }
        return vr;
    }

    function getValueBool(
        string memory variableName
    ) external view override returns (bool) {
        bool vr = false;
        for (uint i = 0; i < variablesBool.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesBool[i].variableNameBool)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesBool[i].valueBool;
            }
        }
        return vr;
    }

    function getValueInt(
        string memory variableName
    ) external view override returns (uint256) {
        uint vr;
        for (uint i = 0; i < variablesInt.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesInt[i].variableNameInt)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesInt[i].valueInt;
            }
        }
        return vr;
    }

    function getValueDec(
        string memory variableName
    ) external view override returns (uint256) {
        uint vr;
        for (uint i = 0; i < variablesDec.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesDec[i].variableNameDec)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesDec[i].valueDec;
            }
        }
        return vr;
    }

    function getAllValues() external view override returns (string memory) {
        string memory resultInt;
        for (uint i = 0; i < variablesInt.length; i++) {
            VariablesInt memory v = variablesInt[i];
            resultInt = string(
                abi.encodePacked(
                    resultInt,
                    "{'name': '",
                    v.variableNameInt,
                    "', 'value': '",
                    ManagerHelper.uint2str(v.valueInt),
                    "'}, "
                )
            );
        }
        string memory resultDec;
        for (uint i = 0; i < variablesDec.length; i++) {
            VariablesDec memory v = variablesDec[i];
            resultDec = string(
                abi.encodePacked(
                    resultDec,
                    "{'name': '",
                    v.variableNameDec,
                    "', 'value': '",
                    ManagerHelper.uint2str(v.valueDec),
                    "'}, "
                )
            );
        } 
        string memory resultString;
        for (uint i = 0; i < variablesString.length; i++) {
            VariablesString memory v = variablesString[i];
            resultString = string(
                abi.encodePacked(
                    resultString,
                    "{'name': '",
                    v.variableNameString,
                    "', 'value': '",
                    v.valueString,
                    "'}, "
                )
            );
        }
        string memory resultBool;
        for (uint i = 0; i < variablesBool.length; i++) {
            VariablesBool memory v = variablesBool[i];
            resultBool = string(
                abi.encodePacked(
                    resultBool,
                    "{'name': '",
                    v.variableNameBool,
                    "', 'value': '",
                    ManagerHelper.boolToString(v.valueBool),
                    "'}, "
                )
            );
        }
        string memory result;
        result = string(
            abi.encodePacked(
                resultInt,
                resultDec,
                resultString,
                resultBool
            )
        );
        return result;
     }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./interface/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EZRContext.sol";
import "../Controller/interface/IManagerController.sol";
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
contract ERC20 is EZRContext, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address public managerController;
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, address _managerController) {
        _name = name_;
        _symbol = symbol_;
        managerController = _managerController;
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
        address owner = msgSender();
        
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
        address owner = msgSender();
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
        address spender = msgSender();
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
        address owner = msgSender();
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
        address owner = msgSender();
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

            uint256 _feesAmount = 0;
            if(!isContract(from) && !isContract(to) && from != IManagerController(managerController).treasuryAddress()) {
                _feesAmount = SafeMath.div(SafeMath.mul(10, amount), 100);
                _balances[address(0)] += SafeMath.div(_feesAmount, 2); 
                // TODO : EST address 
                _balances[IManagerController(managerController).treasuryAddress()] += SafeMath.div(_feesAmount, 2); 
            }
            _balances[to] += amount-_feesAmount;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./EZRContext.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is EZRContext, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msgSender(), amount);
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
        _spendAllowance(account, msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;
import "../YousovAccessControl.sol";

import "./ERC20.sol";
import "./interface/IEZR.sol";
import "./ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Users/interface/IUser.sol";
import "../Users/interface/IUserFactory.sol";
import "../Agregator/YousovAgregator.sol";
import "../Controller/interface/IManagerController.sol";

contract EZR is IEZR, ERC20, ERC20Burnable, Pausable , YousovRoles{
    address yousovAccessControl;
    address userFactoryContract;
    address matic;
    address usdc;
    address yousovAgregator;
    address recoveryFactory;

    mapping (address => Transaction[]) public transactionList;
    mapping (address => bool) public userBoughtHisBundle;
    constructor(address _yousovAccessControl, address _userFactoryContract, address _matic, address _usdc, address _yousovAgregator, address _managerController) ERC20("EZR", "EZR",_managerController) {
        userFactoryContract=_userFactoryContract;
        yousovAccessControl = _yousovAccessControl;
        matic = _matic;
        usdc = _usdc;
        yousovAgregator = _yousovAgregator;
        if (YousovAccessControl(yousovAccessControl).hasRole(MINTER_ROLE,msg.sender )) {
            _mint(msg.sender, 1000000 * 10 ** decimals());
        }
        else{
            revert("YOUSOV : Caller must have the Minter role");
        }
    }

     modifier onlyRole(bytes32 role, address sender) {
        YousovAccessControl(yousovAccessControl).checkRole(role,sender);
        _;
    }

    function setRecoveryFactory(address _recoveryFactory) external override {
        // recoveryFactory
        require(recoveryFactory == address(0), "YOUSOV : Operation not authorized");
        recoveryFactory = _recoveryFactory;
    }

    function pause() public onlyRole(PAUSER_ROLE, tx.origin) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE, tx.origin) {
        _unpause();
    }

    function mint(address to, uint256 amount) external override {
        require( YousovAccessControl(yousovAccessControl).hasRole(MINTER_ROLE, tx.origin ) || YousovAccessControl(yousovAccessControl).hasRole(MINTER_ROLE, msg.sender ), "YOUSOV : Address not authorised to mint");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        transactionList[from].push(Transaction(TransactionType.TRANSACTION_OUT, block.timestamp, amount, from, to));
        transactionList[to].push(Transaction(TransactionType.TRANSACTION_IN , block.timestamp, amount, from, to));
        super._afterTokenTransfer(from, to, amount);
    }

        function userTransactionsList(address yousovuser)
        external
        view
        override
        returns (Transaction[] memory _userTransactions)
    {
        return transactionList[yousovuser];
    }

    function purchaseEZR(bool isMatic, uint256 amountIn ) public {
        require(YousovAccessControl(yousovAccessControl).hasRole(YOUSOV_USER_ROLE,msg.sender ) || YousovAccessControl(yousovAccessControl).hasRole(TEMPORARY_YOUSOV_USER_ROLE,msg.sender ),"YOUSOV : not allowed to buy out tokens");
        IERC20(isMatic ? matic: usdc).transferFrom(msg.sender,IManagerController(managerController).treasuryAddress(), amountIn);
        uint256 amountEZROut = YousovAgregator(yousovAgregator).getAmountEZROut(isMatic,amountIn);
        _transfer(IManagerController(managerController).treasuryAddress(), msg.sender, amountEZROut);
    }

    function getBundle(uint256 bundleType) public {
        require(YousovAccessControl(yousovAccessControl).hasRole(YOUSOV_USER_ROLE,msg.sender ) && !userBoughtHisBundle[msg.sender] && block.timestamp - IUser(IUserFactory(userFactoryContract).userContract(msg.sender)).creationDate() <= IManagerController(managerController).getValueInt("bundleOfferExpiration"),"YOUSOV : not allowed to buy bundles");
        IERC20(usdc).transferFrom(msg.sender,IManagerController(managerController).treasuryAddress(), pricePerBundleType(bundleType));
        _mint(msg.sender, bundleType * 10**18);
        userBoughtHisBundle[msg.sender] = true;
    }
    function pricePerBundleType(uint256 bundleType) pure internal returns(uint256){
        if (bundleType ==  3) {
            return 75 * 10**18;
        } else {
            if (bundleType == 7) {
               return 175 * 10**18;
            } else {
                if (bundleType == 15) {
                    return 350 * 10**18;
                } else {
                    revert("bundle type error");
                }
            }
        }
    }
    function transferFromFromRecoveryFactory(address from, address to, uint256 amount) external override {
        require(msg.sender == recoveryFactory, "YOUSOV : Operation not authorized");
        _transfer(from, to, amount);
    }

    function burnFromFromRecoveryFactory(address from, uint256 amount) external override {
        require(msg.sender == recoveryFactory, "YOUSOV : Operation not authorized");
        _burn(from, amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity 0.8.17;

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
contract EZRContext  {
    function msgSender() internal view  returns (address) {
        if (isContract(msg.sender)) {
            return tx.origin;
        } else {
            return msg.sender;
        }
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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

import "./IERC20.sol";

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

pragma solidity ^0.8.17;

import "../../interface/IYousovStructs.sol";

interface IEZR is IYousovStructs {
  function mint(address to, uint256 amount) external ;
  function userTransactionsList(address yousovuser) view external returns(Transaction[] memory _userTransactions) ;
  function setRecoveryFactory(address _recoveryFactory) external;
  function transferFromFromRecoveryFactory(address from, address to, uint256 amount) external;
  function burnFromFromRecoveryFactory(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "./IYousovStructs.sol";
interface IAgentPayrollWallet is IYousovStructs {
   function claimFreeEZR() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IYousovStructs {
    enum SecretStatus{
        LOCK,
        UNLOCK
    }
    enum AccountType {
        REGULAR,
        PSEUDO
     }
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    enum UserStatus {
        OPT_IN,
        OPT_OUT

    }
    enum UserRole {
        SENIOR,
        JUNIOR,
        STANDARD,
        DENIED
    }
    enum RecoveryStatus {
        CREATED,
        READY_TO_START,
        IN_PROGRESS,
        OVER,
        CANCELED
    }
    enum RecoveryRole{
        QUESTION_AGENT,
        ANSWER_AGENT
    }
    enum AnswerStatus{
        ANSWERED,
        NOT_ANSWERED
        
    }
    struct SecretVault {
        string secret;
        SecretStatus secretStatus;
    }
    struct AnswerAgentsDetails{
        string initialAnswer;
        string actualAnswer;
        string challengeID;
        bool answer;
        AnswerStatus answerStatus;
    }
    struct RecoveryStats {
        bool isAllAnswersAgentsAnswered;
        uint256 totoalValidAnswers;
        
    }
    struct PII {
        string firstName;
        string middelName;
        string lastName;
        string cityOfBirth;
        string countryOfBirth;
        string countryOfCitizenship;
        string uid;
        uint256 birthDateTimeStamp;
        Gender gender;
    }
    struct Wallet{
        address publicAddr;
        string walletPassword;
        string privateKey;
    }
    struct Challenge {
        string question;
        string answer;
        string id;
    }
    enum TransactionType {
        TRANSACTION_IN, TRANSACTION_OUT
    }
    struct Transaction {
    TransactionType transactionType;
    uint256 transactionDate;
    uint256 amount;
    address from;
    address to;
    }

    struct VariablesInt {
        string variableNameInt;
        uint valueInt;
    }

    struct VariablesDec{
        string variableNameDec;
        uint valueDec;
    }

    struct VariablesString{
        string variableNameString;
        string valueString;
    }

    struct VariablesBool{
        string variableNameBool;
        bool valueBool;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ManagerHelper {

    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

function boolToString(bool _bool) internal pure returns (string memory) {
    return _bool ? "true" : "false";
}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Matic is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("MATIC", "MATIC") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

import "../../interface/IYousovStructs.sol";
interface IRecovery is IYousovStructs{
    event AgentAddedToRecovery(address recoveryAddress,address user);
    event RecoveryReadyToStart(address userRecovery);
    event AgentAssignedAnswerForRecovery(address[] agents, address recovery);
    event SendAnswersToAnswerAgents(address[] agents, address recovery);
    event VaultAccessAccepted(address recoveryAddress);
    event VaultAccessDenied(address recoveryAddress);
    event RecoveryIsOver(address recovery);
    function user() view external returns (address user);
    function contenderAgentsList() view external returns (address[] memory);
    function recoveryAgents() view external returns (address[] memory);
    function addContenderAgent(address contenderAgent) external;
    function addNewAgentToRecovery() external;
    function deleteAgentFromRecovery(address _agentAddress) external;
    function getRecoveryStatus() external  returns (RecoveryStatus currentRecoveryStatus) ;
    function clearContenderAgents() external;
    function isUserIsAnActifAgent(address userAgent) external returns (bool);
    function startTheRecovery() external;
    function sendRecoveryAnswerToAnswerAgent(Challenge[] memory _challenges) external;
    function agentCheckUserAnswer(address answerAgent,bool userAnswer) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "../../interface/IYousovStructs.sol";

interface IRecoveryFactory is IYousovStructs{
    event RecoveryCreated(address currentAddress, address recoveryAddress);
    event LegalAgentsToNotify(address recovery,address[] legalSelectableAgents);
    function createRecovery() external;
    function userFactory() external view returns (address);
    function addActiveAgent(address newActiveAgent, address linkedRecovery) external;
    function deleteActiveAgent(address _agentAddress) external;
    function yousovRecoveries() external view returns (address[] memory);
    function yousovActiveAgentsInRecoveries() external view returns (address[] memory);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IRecovery.sol";
import "./interface/IRecoveryFactory.sol";
import "../Users/interface/IUser.sol";
import "../Users/interface/IUserFactory.sol";
import "../YousovAccessControl.sol";
import "../YousovRoles.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../Controller/interface/IManagerController.sol";

contract Recovery is IRecovery, YousovRoles, ERC2771Context {
    address public user;
    address[] public agentList;
    address public recoveryFactory;
    address public yousovAccessControl;
    address[] public contenderAgents;
    address public managerController;
    RecoveryStatus public recoveryStatus = RecoveryStatus.CREATED;
    mapping(address => AnswerAgentsDetails) public answerAgentsDetails;

    constructor(
        address _user,
        address _recoveryFactory,
        address _yousovAccessControl,
        address _forwarder,
        address _managerController
    ) ERC2771Context(_forwarder) {
        recoveryFactory = _recoveryFactory;
        user = _user;
        yousovAccessControl = _yousovAccessControl;
        managerController=_managerController;
    }
    modifier recoveryPanicOff() {
        require(!IManagerController(managerController).getValueBool("recoveriesPanic"),"Yousov : Recoveries are stopped for emergency security");
        _;
    }
    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function cancelCurrentRecovery() recoveryPanicOff public {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        require(
            _msgSender() == user && recoveryStatus != RecoveryStatus.CANCELED,
            "YOUSOV : Operation not authorized"
        );
        recoveryStatus = RecoveryStatus.CANCELED;
    }

    function clearContenderAgents() external recoveryPanicOff override {
        require(
            msg.sender == recoveryFactory,
            "YOUSOV : Operation not authorized"
        );
        if (contenderAgents.length > 0) {
            delete contenderAgents;
        }
    }

    function addContenderAgent(address contenderAgent) external recoveryPanicOff override {
        require(
            msg.sender == recoveryFactory,
            "YOUSOV : Operation not authorized"
        );
        contenderAgents.push(contenderAgent);
    }

    function contenderAgentsList()
        external
        view
        override
        returns (address[] memory)
    {
        return contenderAgents;
    }

    function recoveryAgents()
        external
        view
        override
        returns (address[] memory)
    {
        return agentList;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function addNewAgentToRecovery() external recoveryPanicOff override {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        require(
            YousovAccessControl(yousovAccessControl).hasRole(
                YOUSOV_USER_ROLE,
                _msgSender()
            ),
            "YOUSOV : Recovery user is not a yousov user"
        );

        require(
            agentList.length <
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).userChallenges().length,
            "YOUSOV : Recovery selection is over"
        );
        require(
            !this.isUserIsAnActifAgent(_msgSender()),
            "User is already an actif agent"
        );
        agentList.push(_msgSender());
        IRecoveryFactory(recoveryFactory).addActiveAgent(
            _msgSender(),
            address(this)
        );
        if (
            agentList.length ==
            IUser(
                IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                    .userContract(user)
            ).userChallenges().length
        ) {
            recoveryStatus = RecoveryStatus.READY_TO_START;
            emit RecoveryReadyToStart(address(this));
        } else {
            emit AgentAddedToRecovery(address(this), _msgSender());
        }
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function deleteAgentFromRecovery(address _agentAddress) external recoveryPanicOff override {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(
            _agentAddress == _msgSender(),
            "YOUSOV : Operation not authorized"
        );  // to avoid checking the for loop if identity theft
        
        require(
            YousovAccessControl(yousovAccessControl).hasRole(
                YOUSOV_USER_ROLE,
                _msgSender()
            ),
            "YOUSOV : Recovery user is not a yousov user"
        );
        
        bool _agentExists = false;
        for (uint i = 0; i < agentList.length; ++i) {
            if (agentList[i] == _agentAddress) {
                agentList[i] = agentList[agentList.length - 1];
                _agentExists = true;
                break;
            }
        }
        if (_agentExists) {
            agentList.pop();
        }
        IRecoveryFactory(recoveryFactory).deleteActiveAgent(_agentAddress);
    }

    function getRecoveryStatus()
        external
        view
        override
        returns (RecoveryStatus currentRecoveryStatus)
    {
        return recoveryStatus;
    }

    function isUserIsAnActifAgent(
        address userAgent
    ) external view override returns (bool) {
        for (uint i = 0; i < agentList.length; ++i) {
            if (agentList[i] == userAgent) {
                return true;
            }
        }
        return false;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function startTheRecovery() external recoveryPanicOff override {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(
            recoveryStatus == RecoveryStatus.READY_TO_START &&
                _msgSender() == user 
                &&
                (agentList.length ==
                    IUser(
                        IUserFactory(
                            IRecoveryFactory(recoveryFactory).userFactory()
                        ).userContract(user)
                    ).userChallenges().length),
            "YOUSOV : Operation not authorized"
        );
        string[] memory userChallengesShuffled = IUser(
            IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                .userContract(user)
        ).shuffleChallenges();
        for (uint256 i = 0; i < agentList.length; ++i) {
            Challenge memory affectedChallenge = IUser(
                IUserFactory(IRecoveryFactory(recoveryFactory).userFactory())
                    .userContract(user)
            ).userChallengesDetails(userChallengesShuffled[i]);
            answerAgentsDetails[agentList[i]] = AnswerAgentsDetails(
                affectedChallenge.answer,
                "",
                affectedChallenge.id,
                false,
                AnswerStatus.NOT_ANSWERED
            );
        }
        recoveryStatus = RecoveryStatus.IN_PROGRESS;
        emit AgentAssignedAnswerForRecovery(agentList, address(this));
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function sendRecoveryAnswerToAnswerAgent(
        Challenge[] memory _challenges
    ) external recoveryPanicOff override {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        
        require(
            _msgSender() == user &&
                recoveryStatus == RecoveryStatus.IN_PROGRESS,
            "YOUSOV : Not authorized operation"
        );
        for (uint i = 0; i < agentList.length; ++i) {
            address answerAgent = agentList[i];
            for (uint j = 0; j < _challenges.length; ++j) {
                if (
                    keccak256(
                        abi.encodePacked(
                            answerAgentsDetails[answerAgent].challengeID
                        )
                    ) == keccak256(abi.encodePacked(_challenges[j].id))
                ) {
                    AnswerAgentsDetails memory lastStat = answerAgentsDetails[
                        answerAgent
                    ];
                    answerAgentsDetails[answerAgent] = AnswerAgentsDetails(
                        lastStat.initialAnswer,
                        _challenges[j].answer,
                        lastStat.challengeID,
                        false,
                        AnswerStatus.NOT_ANSWERED
                    );
                    break;
                }
            }
        }
        emit SendAnswersToAnswerAgents(agentList, address(this));
    }

    function _isAllAnswersAgentsHaveAnswered()
        private
        view
        returns (RecoveryStats memory)
    {
        uint256 totalValidAnswers = 0;
        for (uint i = 0; i < agentList.length; ++i) {
            if (
                answerAgentsDetails[agentList[i]].answerStatus ==
                AnswerStatus.NOT_ANSWERED
            ) {
                return RecoveryStats(false, 0);
            }
            if (answerAgentsDetails[agentList[i]].answer) {
                totalValidAnswers = totalValidAnswers + 1;
            }
        }
        return RecoveryStats(true, totalValidAnswers);
    }

    function _deleteRecoveryFactoryCurrentRecoveryActiveAgents() private {
        for (uint i = 0; i < agentList.length; ++i) {
            IRecoveryFactory(recoveryFactory).deleteActiveAgent(agentList[i]);
        }
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function agentCheckUserAnswer(
        address answerAgent,
        bool userAnswer
    ) external recoveryPanicOff override {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        require(
            _msgSender() == answerAgent &&
                recoveryStatus == RecoveryStatus.IN_PROGRESS &&
                answerAgentsDetails[answerAgent].answerStatus ==
                AnswerStatus.NOT_ANSWERED,
            "YOUSOV : Not authorized operation"
        );
        answerAgentsDetails[answerAgent] = AnswerAgentsDetails(
            answerAgentsDetails[answerAgent].initialAnswer,
            answerAgentsDetails[answerAgent].actualAnswer,
            answerAgentsDetails[answerAgent].challengeID,
            userAnswer,
            AnswerStatus.ANSWERED
        );
        // check if all answers agents have answered than
        RecoveryStats
            memory actualRecoveryStats = _isAllAnswersAgentsHaveAnswered();
        if (actualRecoveryStats.isAllAnswersAgentsAnswered) {
            if (
                actualRecoveryStats.totoalValidAnswers >=
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).threashold()
            ) {
                // Give access to the vault
                IUser(
                    IUserFactory(
                        IRecoveryFactory(recoveryFactory).userFactory()
                    ).userContract(user)
                ).unlockSecretVault();
                emit VaultAccessAccepted(address(this));
            } else {
                //  don't give access to the vault
                emit VaultAccessDenied(address(this));
            }
            recoveryStatus = RecoveryStatus.OVER;
            // reset all recovery parameters
            _deleteRecoveryFactoryCurrentRecoveryActiveAgents();
            emit RecoveryIsOver(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IRecoveryFactory.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Recovery.sol";
import "../Users/interface/IUserFactory.sol";
import "../Users/interface/IUser.sol";

import "../YousovAccessControl.sol";
import "../YousovRoles.sol";

import "../Recovery/Recovery.sol";

import "../EZR/EZR.sol";
import "../lib/TransferHelper.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "../Controller/interface/IManagerController.sol";

contract RecoveryFactory is IRecoveryFactory, YousovRoles, ERC2771Context {

    using SafeMath for uint256;
    address public ezr;
    address[] public recoveries;
    address public agentPayrollWallet ;
    address[] public activeAgentsInRecoveries;
    address public userFactory;
    address public yousovAccessControl;
    mapping(address => address) public actifAgentsRecoveries;
    address private immutable forwarder;
    address public managerController;

    mapping (address=>address) public currentCreatedRecoveries;
    constructor(address _ezr, address _agentPayrollWallet, address _userFactory, address _yousovAccessControl, address _forwarder, address _managerController ) ERC2771Context(_forwarder){
        ezr = _ezr;
        IEZR(ezr).setRecoveryFactory(address(this));
        agentPayrollWallet = _agentPayrollWallet;
        userFactory = _userFactory;
        yousovAccessControl = _yousovAccessControl;
        forwarder = _forwarder;
        managerController = _managerController;
    }

    modifier recoveryPanicOff() {
        require(!IManagerController(managerController).getValueBool("recoveriesPanic"),"Yousov : Recoveries are stopped for emergency security");
        _;
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function createRecovery() external recoveryPanicOff override {
        require(
            IUserFactory(userFactory).yousovUserList().length >= IManagerController(managerController).getValueInt("minimumAgentsAppear") &&
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(!userHasRecovery(_msgSender()) && (YousovAccessControl(yousovAccessControl).hasRole(TEMPORARY_YOUSOV_USER_ROLE, _msgSender()) || YousovAccessControl(yousovAccessControl).hasRole(YOUSOV_USER_ROLE, _msgSender())), "YOUSOV : Not authorized to do this action" );
        uint256 recoveryPriceEZR = IManagerController(managerController).getValueInt("minimumRecoveryPriceEzr");
        uint256 toAgentAPW = (recoveryPriceEZR * IManagerController(managerController).getValueDec("agentPayrollWalletFromRecovery")) / 100 ;
        uint256 toBurn = (recoveryPriceEZR * IManagerController(managerController).getValueDec("burn")) / 100 ;
        uint256 toEST = recoveryPriceEZR - (toAgentAPW + toBurn) ;
        
        IEZR(ezr).transferFromFromRecoveryFactory(_msgSender(), agentPayrollWallet, toAgentAPW);

        IEZR(ezr).burnFromFromRecoveryFactory(_msgSender(), toBurn);

        IEZR(ezr).transferFromFromRecoveryFactory(_msgSender(), IManagerController(managerController).treasuryAddress(), toEST);

        // //  create the recovery
        
        address _newRecovery = address(new Recovery(_msgSender(), address(this), yousovAccessControl, forwarder,managerController));
        recoveries.push(_newRecovery);
        currentCreatedRecoveries[_msgSender()] = _newRecovery;
        emit RecoveryCreated(_msgSender(), _newRecovery);
        getLegalSelectableAgents(_newRecovery);
    }
    
     function userHasRecovery(address userAddress) public  returns (bool) {
        for (uint i = 0; i < recoveries.length; ++i) {
            if (userAddress == IRecovery(recoveries[i]).user() && (IRecovery(recoveries[i]).getRecoveryStatus() == RecoveryStatus.CREATED || IRecovery(recoveries[i]).getRecoveryStatus() == RecoveryStatus.IN_PROGRESS)) {
                return true;
            }
        }
        return false;
    }

    function recoveryExist(address _recovery) internal view returns (bool) {
        for (uint i = 0; i < recoveries.length; ++i) {
            if (_recovery == recoveries[i]) {
                return true;
            }
        }
        return false;
    }

    function addActiveAgent(address newActiveAgent, address linkedRecovery) external recoveryPanicOff override {
        activeAgentsInRecoveries.push(newActiveAgent);
        actifAgentsRecoveries[newActiveAgent] = linkedRecovery;
    }
    function deleteActiveAgent(address _agentAddress) external recoveryPanicOff override {
        bool _agentExists = false;
        for (uint i = 0; i < activeAgentsInRecoveries.length; ++i) {
            if (activeAgentsInRecoveries[i] == _agentAddress) {
              activeAgentsInRecoveries[i] =  activeAgentsInRecoveries[activeAgentsInRecoveries.length-1];
              _agentExists = true;
              break;  
            }
        }
        if (_agentExists) {
            activeAgentsInRecoveries.pop();
            // delete from mapping to recovery
            delete actifAgentsRecoveries[_agentAddress];
        }
    }

    /*******************************************************************************
     **	@notice This may only be called by the forwarder.
     *******************************************************************************/
    function getLegalSelectableAgents(
        address _currentRecovery
    ) public recoveryPanicOff {
        require(
            isTrustedForwarder(msg.sender),
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );

        require(
            recoveryExist(_currentRecovery) &&
                _msgSender() == IRecovery(_currentRecovery).user() &&
                IRecovery(_currentRecovery).getRecoveryStatus() !=
                RecoveryStatus.OVER,
            "YOUSOV : Recovery don't exist"
        );
        address[] memory _userList = IUserFactory(userFactory).yousovUserList();
        IRecovery(_currentRecovery).clearContenderAgents();
        for (uint i = 0; i < _userList.length; ++i) {
            bool excludAgent = false;
            // don't select users that are currently in an agent role doing a recovery
            for (uint j = 0; j < activeAgentsInRecoveries.length; ++j) {
                if (
                    activeAgentsInRecoveries[j] ==
                    IUser(_userList[i]).getWalletDetails().publicAddr
                ) {
                    excludAgent = true;
                    break;
                }
            }
            if (excludAgent) {
                continue;
            }

            // don't select users that are lunching recoveries
            for (uint y = 0; y < recoveries.length; ++y) {
                if (
                    IRecovery(recoveries[y]).user() ==
                    IUser(_userList[i]).getWalletDetails().publicAddr &&
                    IRecovery(recoveries[y]).getRecoveryStatus() !=
                    RecoveryStatus.OVER
                ) {
                    excludAgent = true;
                    break;
                }
            }

            if (excludAgent) {
                continue;
            }

            if (!excludAgent) {
                IRecovery(_currentRecovery).addContenderAgent(_userList[i]);
            }
        }

        emit LegalAgentsToNotify(
            _currentRecovery,
            IRecovery(_currentRecovery).contenderAgentsList()
        );
    }

    /*******************************************************************************
     **	@notice Get the recoveries list.
     *******************************************************************************/
    function yousovRecoveries()
        external
        view
        override
        returns (address[] memory)
    {
        return recoveries;
    }

    /*******************************************************************************
     **	@notice Get the active agents list in recoveries.
     *******************************************************************************/
    function yousovActiveAgentsInRecoveries()
        external
        view
        override
        returns (address[] memory)
    {
        return activeAgentsInRecoveries;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Usdc is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
pragma experimental ABIEncoderV2;
import "../../interface/IYousovStructs.sol";
interface IUser is IYousovStructs {
    function pseudonym() view external returns (string memory pseudonym);
    function creationDate() view external returns (uint256 creationDate);
    function threashold() view external returns (uint256 threashold);
    function userChallenges() view external returns(string[] memory _userChallenges) ;
    function setSecret(string memory newSecret) external ;
    function setPseudoym(string memory newPseudonym) external ;
    function setPII(PII memory newPII) external ;
    function setWallet(string memory walletPassword) external ;
    function getWalletDetails() external view  returns (Wallet memory);
    function getAccountType() external view  returns (AccountType);
    function setThreashold(uint256 newThreashold) external;
    function getPII() external view  returns (PII memory);
    function switchUserStatus(UserStatus newStatus) external;
    function lockSecretVault() external;
    function updateUserAccountTypeFromPiiToPseudo(string memory pseudo) external;
    function updateUserAccountTypeFromPseudoToPii(PII memory newPII) external;
    function setChallenges(Challenge[] memory newChallenges , uint256 newThreashold ) external;
    function checkWalletPassword(string memory walletPassword) view external  returns (Wallet memory wallet);
    function userChallengesDetails(string memory challengID) external view returns (Challenge memory challengDetail);
    function unlockSecretVault() external;
    function isSecretUnlocked() external  returns(bool);
    function shuffleChallenges() external returns (string[] memory);
    function setAccountType(AccountType newAccountType) external;
    event SecretUpdated();
    event PseudonymUpdated();
    event PIIUpdated();
    event ChallengesUpdated();
    event WalletUpdated();
    event AccountTypeUpdated();
    event ThreasholdUpdated();
    event StatusUpdated();
    event UpdateUserIdentityFromPIIToPseudo();
    event UpdateUserIdentityFromPseudoToPII();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserFactory is IYousovStructs {
    function yousovUserList() external view returns (address[] memory );
    function userContract(address) external view returns (address userContract);
    function newUser(PII memory pii , Wallet memory wallet, Challenge[] memory challenges, string memory pseudonym , AccountType accountType, uint256 threashold ) external;
    function deleteUser() external;
    function checkUnicity(AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
    event UserCreated();
    event UserDeleted(address userDeletedAddress);
   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserUnicity is IYousovStructs {
    function checkUnicity(address[] memory userList,AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;
import "./interface/IUser.sol";
import "../EZR/EZRContext.sol";
import "../YousovAccessControl.sol";

import "../YousovRoles.sol";
import "../Recovery/interface/IRecoveryFactory.sol";
import "../Recovery/interface/IRecovery.sol";

contract User is IUser, EZRContext, YousovRoles {
    PII public pii;
    string public pseudonym;
    string[] public challenges;
    mapping(string => Challenge) public challengeDetails;
    mapping(string => string) public challengeToAnswer;
    address currentRecovery;
    Wallet public wallet;
    SecretVault public secret;
    uint256 public threashold;
    AccountType public accountType;
    UserStatus public userStatus;
    address public yousovAccessControl;
    string[5] oldWalletPasswords;   
    address userFactory; 
    uint256 public indexToStoreNextPassword;
    uint256 public immutable creationDate; 
    constructor(
        address _yousovAccessControl,
        PII memory _pii,
        Wallet memory _wallet,
        Challenge[] memory _challenges,
        string memory _pseudonym,
        AccountType _accountType,
        uint256 _threashold,
        address _userFactory
    ) {
        if (_accountType == AccountType.PSEUDO) {
            pseudonym = _pseudonym;
        }
        if (_accountType == AccountType.REGULAR) {
            pii = _pii;
        }
        wallet = _wallet;
        accountType = _accountType;
        threashold = _threashold;
        yousovAccessControl = _yousovAccessControl;
        for (uint i = 0; i < _challenges.length; i++) {
            challenges.push(_challenges[i].id);
            challengeDetails[_challenges[i].id] = _challenges[i];
            challengeToAnswer[_challenges[i].id] = _challenges[i].question;
        }
        userStatus = UserStatus.OPT_IN;
        secret.secretStatus = SecretStatus.LOCK;
        userFactory = _userFactory;
        creationDate= block.timestamp;
        savePassword(wallet.walletPassword);
    }

    modifier onlyUser() {
        require(
            tx.origin == wallet.publicAddr &&
                YousovAccessControl(yousovAccessControl).hasRole(
                    YOUSOV_USER_ROLE,
                    tx.origin
                ),
            "Yousov : Update not authorized"
        );
        _;
    }

    /*******************************************************************************
     **	@notice Set the secret of a user. This may only be called by the user.
     **	@param newSecret The new secret of the user. The previous secret will be replaced by the new secret. 
     *******************************************************************************/
    function setSecret(string memory newSecret) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked(),"YOUSOV : Operation not authorized");
        secret.secret = newSecret;
        emit SecretUpdated();
    }


    function lockSecretVault() external override {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        secret.secretStatus = SecretStatus.LOCK;
    }


    function unlockSecretVault() external override {
        require(wallet.publicAddr == IRecovery(msg.sender).user() && !this.isSecretUnlocked(),"YOUSOV : Operation not authorized");
        secret.secretStatus = SecretStatus.UNLOCK;
    }

    function isSecretUnlocked() external view override returns(bool){
        return secret.secretStatus == SecretStatus.UNLOCK;
    }

    /*******************************************************************************
     **	@notice Set the challenges and the threashold of a user. This may only be called by the user.
     **	@param newChallenges The new challenges of the user (array of challenge that contains (question, answer, id).
     **	@param newThreashold The new threashold of the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function setChallenges(
        Challenge[] memory newChallenges,
        uint256 newThreashold
    ) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        delete challenges;
        for (uint i = 0; i < newChallenges.length; ++i) {
            challenges.push(newChallenges[i].id);
            challengeDetails[newChallenges[i].id] = newChallenges[i];
            challengeToAnswer[newChallenges[i].id] = newChallenges[i].question;
        }
        emit ChallengesUpdated();
        this.setThreashold(newThreashold);
    }

    /*******************************************************************************
     **	@notice Set the pseudonym of a user. This may only be called by the user.
     **	@param newPseudonym The new pseudonym of the user. The previous pseudonym will be replaced by the new pseudonym. 
     *******************************************************************************/
    function setPseudoym(
        string memory newPseudonym
    ) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        require(
            accountType == AccountType.PSEUDO,
            "Yousov : Update not authorized"
        );
        pseudonym = newPseudonym;
        emit PseudonymUpdated();
    }

    /*******************************************************************************
     **	@notice Set the pii of a user. This may only be called by the user.
     **	@param newPII The new pii of the user that contains (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender). The previous pii will be replaced by the new pii. 
     *******************************************************************************/
    function setPII(PII memory newPII) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        require(
            accountType == AccountType.REGULAR,
            "Yousov : Update not authorized"
        );
        pii = newPII;
        emit PIIUpdated();
    }

    /*******************************************************************************
     **	@notice Check if the new wallet password of a user was already used, return true if the new wallet password is not in the oldWalletPasswords array.
     **	@param newWalletPassword The new wallet password of the user. 
     *******************************************************************************/
    function checkValidNewWalletPassword(string memory newWalletPassword) view private returns(bool) {
        for (uint i=0; i < oldWalletPasswords.length; ++i) {
            if (keccak256(abi.encodePacked(newWalletPassword)) == keccak256(abi.encodePacked(oldWalletPasswords[i]))) {
                return false;
            }
        }
        return true;
    }

    /*******************************************************************************
     **	@notice Save the wallet password of a user. Only the oldWalletPasswords.length most recent passwords are kept.
     **	@param newWalletPassword The new wallet password of the user. 
     *******************************************************************************/
    function savePassword(string memory newWalletPassword) private {
        oldWalletPasswords[indexToStoreNextPassword] = newWalletPassword;
        indexToStoreNextPassword = uint256((indexToStoreNextPassword + 1) % oldWalletPasswords.length);
    }

    /*******************************************************************************
     **	@notice Set the wallet password of a user. This may only be called by the user.
     **	@param walletPassword The new wallet password of the user. The previous wallet password will be replaced by the new one.
     *******************************************************************************/
    function setWallet(
        string memory walletPassword
    ) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        require(checkValidNewWalletPassword(walletPassword), "Yousov : Please do not use an already used password");
        wallet.walletPassword = walletPassword;
        savePassword(walletPassword);
        emit WalletUpdated();
    }

    /*******************************************************************************
     **	@notice Set the account type of a user. This may only be called by the user.
     **	@param newAccountType The new account type the user (example: AccountType.REGULAR or AccountType.PSEUDO).
     *******************************************************************************/
    function setAccountType(AccountType newAccountType) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        accountType = newAccountType;
        emit AccountTypeUpdated();
    }

    /*******************************************************************************
     **	@notice Set the threashold of a user. This may only be called by the user.
     **	@param newThreashold The new threashold of the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function setThreashold(uint256 newThreashold) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        threashold = newThreashold;
        emit ThreasholdUpdated();
    }

    /*******************************************************************************
     **	@notice Get the wallet details of a user (publicAddr, walletPassword, privateKey).
     *******************************************************************************/
    function getWalletDetails() external view override returns (Wallet memory) {
        return wallet;
    }

    /*******************************************************************************
     **	@notice Get the account type a user.
     *******************************************************************************/
    function getAccountType() external view override returns (AccountType) {
        return accountType;
    }

    /*******************************************************************************
     **	@notice Get the pii a user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     *******************************************************************************/
    function getPII() external view override returns (PII memory) {
        return pii;
    }

    /*******************************************************************************
     **	@notice Switch from regular account type to pseudo account type and set the pseudonym of a user. This may only be called by the user.
     **	@param pseudo The new pseudonym of the user. The previous pseudonym will be replaced by the new pseudonym. 
     *******************************************************************************/
    function updateUserAccountTypeFromPiiToPseudo(
        string memory pseudo
    ) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked() && accountType == AccountType.REGULAR, "Yousov : Update not authorized");
        _switchAccountType();
        this.setPseudoym(pseudo);
        emit UpdateUserIdentityFromPIIToPseudo();
    }

    /*******************************************************************************
     **	@notice Switch from pseudo account type to regular account type and set the pii of a user. This may only be called by the user.
     **	@param newPII The new pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender). The previous pii will be replaced by the new pii.
     *******************************************************************************/
    function updateUserAccountTypeFromPseudoToPii(
        PII memory newPII
    ) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked() && accountType == AccountType.PSEUDO, "Yousov : Update not authorized");
        _switchAccountType();
        this.setPII(newPII);
        emit UpdateUserIdentityFromPseudoToPII();
    }

    /*******************************************************************************
     **	@notice Check the wallet password. Return the user wallet if the wallet password is correct, revert if it is uncorrect.
     **	@param walletPassword The wallet password the user.
     *******************************************************************************/
    function checkWalletPassword(string memory walletPassword) external view override returns (Wallet memory userWallet) {
        if (
            keccak256(abi.encodePacked(walletPassword)) ==
            keccak256(abi.encodePacked(wallet.walletPassword))
        ) {
            return wallet;
        } else {
            revert("Yousov : Wrong password");
        }
    }

    /*******************************************************************************
     **	@notice Set the status of a user. This may only be called by the user.
     **	@param newStatus The new status of the user (OPT_IN, OPT_OUT). The previous pii will be replaced by the new pii.
     *******************************************************************************/
    function switchUserStatus(UserStatus newStatus) external override onlyUser {
        require(tx.origin == wallet.publicAddr && this.isSecretUnlocked()  ,"YOUSOV : Operation not authorized");
        userStatus = newStatus;
        emit StatusUpdated();
    }

    /*******************************************************************************
     **	@notice Switch the account type of a user.
     *******************************************************************************/
    function _switchAccountType() internal {
        if (accountType == AccountType.PSEUDO) {
            accountType = AccountType.REGULAR;
        } else {
            accountType = AccountType.PSEUDO;
        }
        emit AccountTypeUpdated();
    }

    /*******************************************************************************
     **	@notice Get the array of challenges id of a user.
     *******************************************************************************/
    function userChallenges()
        external
        view
        override
        returns (string[] memory _userChallenges)
    {
        return challenges;
    }

     function shuffleChallenges() external view override returns (string[] memory) {
        uint256 n = challenges.length;
        string[] memory listToShuufle = challenges;
        for (uint256 i = n - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % (i + 1);
            (listToShuufle[i], listToShuufle[j]) = (listToShuufle[j], listToShuufle[i]);
        }
        return listToShuufle;
    }

    function userChallengesDetails(string memory challengID)
        external
        view
        override
        returns (Challenge memory challengDetail)
    {
        return challengeDetails[challengID];
    }



}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IUserFactory.sol";
import "./interface/IUserUnicity.sol";
import "./User.sol";
import "../YousovAccessControl.sol";
import "../YousovRoles.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract UserFactory is IUserFactory, YousovRoles, ERC2771Context {
    address[] public userList;
    mapping(address => address) public userContract;
    address public yousovAccessControl;
    address public userUnicity;
    constructor(
        address _yousovAccessControl,
        address _forwarder,
        address _userUnicity
    ) ERC2771Context(_forwarder) {
        yousovAccessControl = _yousovAccessControl;
        YousovAccessControl(_yousovAccessControl).setUserFactory(address(this));
        userUnicity = _userUnicity;
    }

    /*******************************************************************************
     **	@notice Create a new user. This may only be called by the forwarder.
     **	@param pii The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param wallet The wallet of the user (publicAddr, walletPassword, privateKey).
     **	@param challenges The challenges of the user (array of challenge that contains (question, answer, id).
     **	@param newPseudonym The new pseudonym of the user.
     **	@param accountType The account type of the user (example: AccountType.REGULAR or AccountType.PSEUDO).
     **	@param threashold The threashold fixed by the user. It sets the minimum correct answers needed to access to the vault.
     *******************************************************************************/
    function newUser(
        PII memory pii,
        Wallet memory wallet,
        Challenge[] memory challenges,
        string memory newPseudonym,
        AccountType accountType,
        uint256 threashold
    ) external override {
        require(
            isTrustedForwarder(msg.sender),
            "Yousov : Operation not authorized, not the trustedForwarder"
        );
        (bool userExist, ) = this.checkUnicity(
            accountType,
            pii,
            newPseudonym
        );
        if (userExist) {
            revert("Yousov : User already exist");
        }
        address newUserContract = address(
            new User(
                yousovAccessControl,
                pii,
                wallet,
                challenges,
                newPseudonym,
                accountType,
                threashold,
                address(this)
            )
        );

        YousovAccessControl(yousovAccessControl).grantRole(
            YOUSOV_USER_ROLE,
            wallet.publicAddr
        );

        userList.push(newUserContract);

        userContract[wallet.publicAddr] = newUserContract;

        emit UserCreated();
    }

    /*******************************************************************************
     **	@notice Delete a user. This may only be called by the user.
     *******************************************************************************/
    function deleteUser() external override {
        bool _userToDeleteExists;
        for (uint i = 0; i < userList.length; ++i) {
            if (tx.origin == IUser(userList[i]).getWalletDetails().publicAddr) {
                _userToDeleteExists = true;
                userList[i] = userList[userList.length - 1];
                userList.pop();
                delete userContract[tx.origin];
                YousovAccessControl(yousovAccessControl).revokeRole(
                    YOUSOV_USER_ROLE,
                    tx.origin
                );
                emit UserDeleted(tx.origin);
                break;
            }
        }
        if (!_userToDeleteExists) {
            revert("YOUSOV : User don't exist");
        }
    }

    /*******************************************************************************
     **	@notice Check the unicity of the user. Returns true if the pii or pseudo already exists, return false instead.
     **	@param userAccountType The account type of the user (AccountType.REGULAR or AccountType.PSEUDO).
     **	@param userPII The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param userPseudo The pseudo of the user.
     *******************************************************************************/
    function checkUnicity(
        AccountType userAccountTpe,
        PII memory userPII,
        string memory userPseudo
    ) external view override returns (bool exists, address userContractAddr) {
        return IUserUnicity(userUnicity).checkUnicity(userList,userAccountTpe,userPII,userPseudo);
    }

    /*******************************************************************************
     **	@notice Get the user list.
     *******************************************************************************/
    function yousovUserList()
        external
        view
        override
        returns (address[] memory)
    {
        return userList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IUserUnicity.sol";
import "./interface/IUser.sol";

contract UserUnicity is IUserUnicity {
   /*******************************************************************************
     **	@notice Check the unicity of the user. Returns true if the pii or pseudo already exists, return false instead.
     **	@param userAccountType The account type of the user (AccountType.REGULAR or AccountType.PSEUDO).
     **	@param userPII The pii of the user (firstName, middelName, lastName, cityOfBirth, countryOfBirth, countryOfCitizenship, uid, birthDateTimeStamp, gender).
     **	@param userPseudo The pseudo of the user.
     *******************************************************************************/
    function checkUnicity(
        address[] memory userList,
        AccountType userAccountTpe,
        PII memory userPII,
        string memory userPseudo
    ) external view override returns (bool exists, address userContractAddr) {
        for (uint i = 0; i < userList.length; ++i) {
            IUser _currentUser = IUser(userList[i]);

            if (userAccountTpe == AccountType.REGULAR) {
                if (
                    keccak256(
                        abi.encodePacked(
                            userPII.firstName,
                            userPII.middelName,
                            userPII.lastName,
                            userPII.cityOfBirth,
                            userPII.countryOfBirth,
                            userPII.countryOfCitizenship,
                            userPII.uid,
                            userPII.birthDateTimeStamp,
                            userPII.gender
                        )
                    ) ==
                    keccak256(
                        abi.encodePacked(
                            _currentUser.getPII().firstName,
                            _currentUser.getPII().middelName,
                            _currentUser.getPII().lastName,
                            _currentUser.getPII().cityOfBirth,
                            _currentUser.getPII().countryOfBirth,
                            _currentUser.getPII().countryOfCitizenship,
                            _currentUser.getPII().uid,
                            _currentUser.getPII().birthDateTimeStamp,
                            _currentUser.getPII().gender
                        )
                    )
                ) {
                    return (true, userList[i]);
                }
            } else if (userAccountTpe == AccountType.PSEUDO) {
                if (
                    keccak256(abi.encodePacked(userPseudo)) ==
                    keccak256(abi.encodePacked(_currentUser.pseudonym()))
                ) {
                    return (true, userList[i]);
                }
            }
        }
        return (false, address(0));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./YousovRoles.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
 
 contract YousovAccessControl is Context, IAccessControl, ERC165, YousovRoles {
    address userFactory;
    
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor (address _defaultAdmin, address _ezrMinter, address _ezrPauser) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(PAUSER_ROLE, _defaultAdmin);
        _setupRole(MANAGER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _ezrMinter);
        _setupRole(PAUSER_ROLE, _ezrPauser);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function checkRole(bytes32 role, address sender) public view {
        _checkRoleAccount(role, sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRoleAccount(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory );
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE , msg.sender) || hasRole(DEFAULT_ADMIN_ROLE,tx.origin) || msg.sender == userFactory);
        _revokeRole(role, account);
    }
    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == tx.origin, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }


    function setAgentPayrolWalletAddressAsMinter(address _apwAddress) public {
        require(msg.sender == _apwAddress, "Yousov: Incorrect Address");
        _setupRole(MINTER_ROLE, _apwAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _apwAddress);
    }
    function setUserFactory(address newUserFactoryAddress)  public{
        require(msg.sender == newUserFactoryAddress, "Yousov: Incorrect Address");
        userFactory = newUserFactoryAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./YousovRoles.sol";
import "./YousovAccessControl.sol";

/**
 * @dev Simple forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract YousovForwarder is EIP712, YousovRoles {
    using ECDSA for bytes32;
    address private yousovAccessControl;
    address private relayer;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor(address _relayer, address _yousovAccessControl) EIP712("YousovForwarder", "0.0.1") {
        relayer = _relayer;
        yousovAccessControl = _yousovAccessControl;
    }

    function setRelayer(address _relayer) public {
        require(YousovAccessControl(yousovAccessControl).hasRole(
                    MANAGER_ROLE, msg.sender) || YousovAccessControl(yousovAccessControl).hasRole(
                    DEFAULT_ADMIN_ROLE, msg.sender),
                    "YOUSOV : Operation not authorized"
                );
        relayer = _relayer;
    }

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        require(tx.origin == relayer, "YOUSOV : Operation not authorized");

        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "YousovForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract YousovRoles {
    bytes32 public constant YOUSOV_USER_ROLE = keccak256("YOUSOV_USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant TEMPORARY_YOUSOV_USER_ROLE = keccak256("TEMPORARY_YOUSOV_USER_ROLE");
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
}

// SPDX-License-Identifier: GPL-3.0-or-later

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

pragma solidity >=0.5.0;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function failed() public returns (bool) {
        if (_failed) {
            return _failed;
        } else {
            bool globalFailed = false;
            if (hasHEVMContext()) {
                (, bytes memory retdata) = HEVM_ADDRESS.call(
                    abi.encodePacked(
                        bytes4(keccak256("load(address,bytes32)")),
                        abi.encode(HEVM_ADDRESS, bytes32("failed"))
                    )
                );
                globalFailed = abi.decode(retdata, (bool));
            }
            return globalFailed;
        }
    }

    function fail() internal virtual {
        if (hasHEVMContext()) {
            (bool status, ) = HEVM_ADDRESS.call(
                abi.encodePacked(
                    bytes4(keccak256("store(address,bytes32,bytes32)")),
                    abi.encode(HEVM_ADDRESS, bytes32("failed"), bytes32(uint256(0x01)))
                )
            );
            status; // Silence compiler warnings
        }
        _failed = true;
    }

    function hasHEVMContext() internal view returns (bool) {
        uint256 hevmCodeSize = 0;
        assembly {
            hevmCodeSize := extcodesize(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D)
        }
        return hevmCodeSize > 0;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("      Left", a);
            emit log_named_address("     Right", b);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("      Left", a);
            emit log_named_bytes32("     Right", b);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("      Left", a);
            emit log_named_int("     Right", b);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("      Left", a);
            emit log_named_uint("     Right", b);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("      Left", a, decimals);
            emit log_named_decimal_int("     Right", b, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("      Left", a, decimals);
            emit log_named_decimal_uint("     Right", b, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("      Left", a);
            emit log_named_string("     Right", b);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("      Left", a);
            emit log_named_bytes("     Right", b);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {StdStorage} from "./StdStorage.sol";
import {Vm, VmSafe} from "./Vm.sol";

abstract contract CommonBase {
    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    // console.sol and console2.sol work by executing a staticcall to this address.
    address internal constant CONSOLE = 0x000000000000000000636F6e736F6c652e6c6f67;
    // Default address for tx.origin and msg.sender, 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38.
    address internal constant DEFAULT_SENDER = address(uint160(uint256(keccak256("foundry default caller"))));
    // Address of the test contract, deployed by the DEFAULT_SENDER.
    address internal constant DEFAULT_TEST_CONTRACT = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
    // Deterministic deployment address of the Multicall3 contract.
    address internal constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    Vm internal constant vm = Vm(VM_ADDRESS);
    StdStorage internal stdstore;
}

abstract contract TestBase is CommonBase {}

abstract contract ScriptBase is CommonBase {
    // Used when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    VmSafe internal constant vmSafe = VmSafe(VM_ADDRESS);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @dev The original console.sol uses `int` and `uint` for computing function selectors, but it should
/// use `int256` and `uint256`. This modified version fixes that. This version is recommended
/// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
/// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
/// Reference: https://github.com/NomicFoundation/hardhat/issues/2178
library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, int256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,int256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

interface IMulticall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes[] memory returnData);

    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData);

    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData);

    function blockAndAggregate(Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);

    function getBasefee() external view returns (uint256 basefee);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getBlockNumber() external view returns (uint256 blockNumber);

    function getChainId() external view returns (uint256 chainid);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function tryAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (Result[] memory returnData);

    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls)
        external
        payable
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {DSTest} from "ds-test/test.sol";
import {stdMath} from "./StdMath.sol";

abstract contract StdAssertions is DSTest {
    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);

    function fail(string memory err) internal virtual {
        emit log_named_string("Error", err);
        fail();
    }

    function assertFalse(bool data) internal virtual {
        assertTrue(!data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        assertTrue(!data, err);
    }

    function assertEq(bool a, bool b) internal virtual {
        if (a != b) {
            emit log("Error: a == b not satisfied [bool]");
            emit log_named_string("      Left", a ? "true" : "false");
            emit log_named_string("     Right", b ? "true" : "false");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal virtual {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes memory a, bytes memory b) internal virtual {
        assertEq0(a, b);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertEq0(a, b, err);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [uint[]]");
            emit log_named_array("      Left", a);
            emit log_named_array("     Right", b);
            fail();
        }
    }

    function assertEq(int256[] memory a, int256[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [int[]]");
            emit log_named_array("      Left", a);
            emit log_named_array("     Right", b);
            fail();
        }
    }

    function assertEq(address[] memory a, address[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [address[]]");
            emit log_named_array("      Left", a);
            emit log_named_array("     Right", b);
            fail();
        }
    }

    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(address[] memory a, address[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    // Legacy helper
    function assertEqUint(uint256 a, uint256 b) internal virtual {
        assertEq(uint256(a), uint256(b));
    }

    function assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("      Left", a);
            emit log_named_uint("     Right", b);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta, string memory err) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbsDecimal(uint256 a, uint256 b, uint256 maxDelta, uint256 decimals) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_decimal_uint("      Left", a, decimals);
            emit log_named_decimal_uint("     Right", b, decimals);
            emit log_named_decimal_uint(" Max Delta", maxDelta, decimals);
            emit log_named_decimal_uint("     Delta", delta, decimals);
            fail();
        }
    }

    function assertApproxEqAbsDecimal(uint256 a, uint256 b, uint256 maxDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbsDecimal(a, b, maxDelta, decimals);
        }
    }

    function assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_int("       Left", a);
            emit log_named_int("      Right", b);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta, string memory err) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbsDecimal(int256 a, int256 b, uint256 maxDelta, uint256 decimals) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_decimal_int("      Left", a, decimals);
            emit log_named_decimal_int("     Right", b, decimals);
            emit log_named_decimal_uint(" Max Delta", maxDelta, decimals);
            emit log_named_decimal_uint("     Delta", delta, decimals);
            fail();
        }
    }

    function assertApproxEqAbsDecimal(int256 a, int256 b, uint256 maxDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string("Error", err);
            assertApproxEqAbsDecimal(a, b, maxDelta, decimals);
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta // An 18 decimal fixed point number, where 1e18 == 100%
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("        Left", a);
            emit log_named_uint("       Right", b);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRelDecimal(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_decimal_uint("        Left", a, decimals);
            emit log_named_decimal_uint("       Right", b, decimals);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRelDecimal(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 decimals,
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRelDecimal(a, b, maxPercentDelta, decimals);
        }
    }

    function assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta) internal virtual {
        if (b == 0) return assertEq(a, b); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_int("        Left", a);
            emit log_named_int("       Right", b);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta, string memory err) internal virtual {
        if (b == 0) return assertEq(a, b, err); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRelDecimal(int256 a, int256 b, uint256 maxPercentDelta, uint256 decimals) internal virtual {
        if (b == 0) return assertEq(a, b); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [int]");
            emit log_named_decimal_int("        Left", a, decimals);
            emit log_named_decimal_int("       Right", b, decimals);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRelDecimal(int256 a, int256 b, uint256 maxPercentDelta, uint256 decimals, string memory err)
        internal
        virtual
    {
        if (b == 0) return assertEq(a, b, err); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string("Error", err);
            assertApproxEqRelDecimal(a, b, maxPercentDelta, decimals);
        }
    }

    function assertEqCall(address target, bytes memory callDataA, bytes memory callDataB) internal virtual {
        assertEqCall(target, callDataA, target, callDataB, true);
    }

    function assertEqCall(address targetA, bytes memory callDataA, address targetB, bytes memory callDataB)
        internal
        virtual
    {
        assertEqCall(targetA, callDataA, targetB, callDataB, true);
    }

    function assertEqCall(address target, bytes memory callDataA, bytes memory callDataB, bool strictRevertData)
        internal
        virtual
    {
        assertEqCall(target, callDataA, target, callDataB, strictRevertData);
    }

    function assertEqCall(
        address targetA,
        bytes memory callDataA,
        address targetB,
        bytes memory callDataB,
        bool strictRevertData
    ) internal virtual {
        (bool successA, bytes memory returnDataA) = address(targetA).call(callDataA);
        (bool successB, bytes memory returnDataB) = address(targetB).call(callDataB);

        if (successA && successB) {
            assertEq(returnDataA, returnDataB, "Call return data does not match");
        }

        if (!successA && !successB && strictRevertData) {
            assertEq(returnDataA, returnDataB, "Call revert data does not match");
        }

        if (!successA && successB) {
            emit log("Error: Calls were not equal");
            emit log_named_bytes("  Left call revert data", returnDataA);
            emit log_named_bytes(" Right call return data", returnDataB);
            fail();
        }

        if (successA && !successB) {
            emit log("Error: Calls were not equal");
            emit log_named_bytes("  Left call return data", returnDataA);
            emit log_named_bytes(" Right call revert data", returnDataB);
            fail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {VmSafe} from "./Vm.sol";

/**
 * StdChains provides information about EVM compatible chains that can be used in scripts/tests.
 * For each chain, the chain's name, chain ID, and a default RPC URL are provided. Chains are
 * identified by their alias, which is the same as the alias in the `[rpc_endpoints]` section of
 * the `foundry.toml` file. For best UX, ensure the alias in the `foundry.toml` file match the
 * alias used in this contract, which can be found as the first argument to the
 * `setChainWithDefaultRpcUrl` call in the `initialize` function.
 *
 * There are two main ways to use this contract:
 *   1. Set a chain with `setChain(string memory chainAlias, ChainData memory chain)` or
 *      `setChain(string memory chainAlias, Chain memory chain)`
 *   2. Get a chain with `getChain(string memory chainAlias)` or `getChain(uint256 chainId)`.
 *
 * The first time either of those are used, chains are initialized with the default set of RPC URLs.
 * This is done in `initialize`, which uses `setChainWithDefaultRpcUrl`. Defaults are recorded in
 * `defaultRpcUrls`.
 *
 * The `setChain` function is straightforward, and it simply saves off the given chain data.
 *
 * The `getChain` methods use `getChainWithUpdatedRpcUrl` to return a chain. For example, let's say
 * we want to retrieve `mainnet`'s RPC URL:
 *   - If you haven't set any mainnet chain info with `setChain`, you haven't specified that
 *     chain in `foundry.toml` and no env var is set, the default data and RPC URL will be returned.
 *   - If you have set a mainnet RPC URL in `foundry.toml` it will return that, if valid (e.g. if
 *     a URL is given or if an environment variable is given and that environment variable exists).
 *     Otherwise, the default data is returned.
 *   - If you specified data with `setChain` it will return that.
 *
 * Summarizing the above, the prioritization hierarchy is `setChain` -> `foundry.toml` -> environment variable -> defaults.
 */
abstract contract StdChains {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    bool private initialized;

    struct ChainData {
        string name;
        uint256 chainId;
        string rpcUrl;
    }

    struct Chain {
        // The chain name.
        string name;
        // The chain's Chain ID.
        uint256 chainId;
        // The chain's alias. (i.e. what gets specified in `foundry.toml`).
        string chainAlias;
        // A default RPC endpoint for this chain.
        // NOTE: This default RPC URL is included for convenience to facilitate quick tests and
        // experimentation. Do not use this RPC URL for production test suites, CI, or other heavy
        // usage as you will be throttled and this is a disservice to others who need this endpoint.
        string rpcUrl;
    }

    // Maps from the chain's alias (matching the alias in the `foundry.toml` file) to chain data.
    mapping(string => Chain) private chains;
    // Maps from the chain's alias to it's default RPC URL.
    mapping(string => string) private defaultRpcUrls;
    // Maps from a chain ID to it's alias.
    mapping(uint256 => string) private idToAlias;

    bool private fallbackToDefaultRpcUrls = true;

    // The RPC URL will be fetched from config or defaultRpcUrls if possible.
    function getChain(string memory chainAlias) internal virtual returns (Chain memory chain) {
        require(bytes(chainAlias).length != 0, "StdChains getChain(string): Chain alias cannot be the empty string.");

        initialize();
        chain = chains[chainAlias];
        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(string): Chain with alias \"", chainAlias, "\" not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    function getChain(uint256 chainId) internal virtual returns (Chain memory chain) {
        require(chainId != 0, "StdChains getChain(uint256): Chain ID cannot be 0.");
        initialize();
        string memory chainAlias = idToAlias[chainId];

        chain = chains[chainAlias];

        require(
            chain.chainId != 0,
            string(abi.encodePacked("StdChains getChain(uint256): Chain with ID ", vm.toString(chainId), " not found."))
        );

        chain = getChainWithUpdatedRpcUrl(chainAlias, chain);
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, ChainData memory chain) internal virtual {
        require(
            bytes(chainAlias).length != 0,
            "StdChains setChain(string,ChainData): Chain alias cannot be the empty string."
        );

        require(chain.chainId != 0, "StdChains setChain(string,ChainData): Chain ID cannot be 0.");

        initialize();
        string memory foundAlias = idToAlias[chain.chainId];

        require(
            bytes(foundAlias).length == 0 || keccak256(bytes(foundAlias)) == keccak256(bytes(chainAlias)),
            string(
                abi.encodePacked(
                    "StdChains setChain(string,ChainData): Chain ID ",
                    vm.toString(chain.chainId),
                    " already used by \"",
                    foundAlias,
                    "\"."
                )
            )
        );

        uint256 oldChainId = chains[chainAlias].chainId;
        delete idToAlias[oldChainId];

        chains[chainAlias] =
            Chain({name: chain.name, chainId: chain.chainId, chainAlias: chainAlias, rpcUrl: chain.rpcUrl});
        idToAlias[chain.chainId] = chainAlias;
    }

    // set chain info, with priority to argument's rpcUrl field.
    function setChain(string memory chainAlias, Chain memory chain) internal virtual {
        setChain(chainAlias, ChainData({name: chain.name, chainId: chain.chainId, rpcUrl: chain.rpcUrl}));
    }

    function _toUpper(string memory str) private pure returns (string memory) {
        bytes memory strb = bytes(str);
        bytes memory copy = new bytes(strb.length);
        for (uint256 i = 0; i < strb.length; i++) {
            bytes1 b = strb[i];
            if (b >= 0x61 && b <= 0x7A) {
                copy[i] = bytes1(uint8(b) - 32);
            } else {
                copy[i] = b;
            }
        }
        return string(copy);
    }

    // lookup rpcUrl, in descending order of priority:
    // current -> config (foundry.toml) -> environment variable -> default
    function getChainWithUpdatedRpcUrl(string memory chainAlias, Chain memory chain) private returns (Chain memory) {
        if (bytes(chain.rpcUrl).length == 0) {
            try vm.rpcUrl(chainAlias) returns (string memory configRpcUrl) {
                chain.rpcUrl = configRpcUrl;
            } catch (bytes memory err) {
                string memory envName = string(abi.encodePacked(_toUpper(chainAlias), "_RPC_URL"));
                if (fallbackToDefaultRpcUrls) {
                    chain.rpcUrl = vm.envOr(envName, defaultRpcUrls[chainAlias]);
                } else {
                    chain.rpcUrl = vm.envString(envName);
                }
                // distinguish 'not found' from 'cannot read'
                bytes memory notFoundError =
                    abi.encodeWithSignature("CheatCodeError", string(abi.encodePacked("invalid rpc url ", chainAlias)));
                if (keccak256(notFoundError) != keccak256(err) || bytes(chain.rpcUrl).length == 0) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, err), mload(err))
                    }
                }
            }
        }
        return chain;
    }

    function setFallbackToDefaultRpcUrls(bool useDefault) internal {
        fallbackToDefaultRpcUrls = useDefault;
    }

    function initialize() private {
        if (initialized) return;

        initialized = true;

        // If adding an RPC here, make sure to test the default RPC URL in `testRpcs`
        setChainWithDefaultRpcUrl("anvil", ChainData("Anvil", 31337, "http://127.0.0.1:8545"));
        setChainWithDefaultRpcUrl(
            "mainnet", ChainData("Mainnet", 1, "https://mainnet.infura.io/v3/f4a0bdad42674adab5fc0ac077ffab2b")
        );
        setChainWithDefaultRpcUrl(
            "goerli", ChainData("Goerli", 5, "https://goerli.infura.io/v3/f4a0bdad42674adab5fc0ac077ffab2b")
        );
        setChainWithDefaultRpcUrl(
            "sepolia", ChainData("Sepolia", 11155111, "https://sepolia.infura.io/v3/f4a0bdad42674adab5fc0ac077ffab2b")
        );
        setChainWithDefaultRpcUrl("optimism", ChainData("Optimism", 10, "https://mainnet.optimism.io"));
        setChainWithDefaultRpcUrl("optimism_goerli", ChainData("Optimism Goerli", 420, "https://goerli.optimism.io"));
        setChainWithDefaultRpcUrl("arbitrum_one", ChainData("Arbitrum One", 42161, "https://arb1.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl(
            "arbitrum_one_goerli", ChainData("Arbitrum One Goerli", 421613, "https://goerli-rollup.arbitrum.io/rpc")
        );
        setChainWithDefaultRpcUrl("arbitrum_nova", ChainData("Arbitrum Nova", 42170, "https://nova.arbitrum.io/rpc"));
        setChainWithDefaultRpcUrl("polygon", ChainData("Polygon", 137, "https://polygon-rpc.com"));
        setChainWithDefaultRpcUrl(
            "polygon_mumbai", ChainData("Polygon Mumbai", 80001, "https://rpc-mumbai.maticvigil.com")
        );
        setChainWithDefaultRpcUrl("avalanche", ChainData("Avalanche", 43114, "https://api.avax.network/ext/bc/C/rpc"));
        setChainWithDefaultRpcUrl(
            "avalanche_fuji", ChainData("Avalanche Fuji", 43113, "https://api.avax-test.network/ext/bc/C/rpc")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain", ChainData("BNB Smart Chain", 56, "https://bsc-dataseed1.binance.org")
        );
        setChainWithDefaultRpcUrl(
            "bnb_smart_chain_testnet",
            ChainData("BNB Smart Chain Testnet", 97, "https://rpc.ankr.com/bsc_testnet_chapel")
        );
        setChainWithDefaultRpcUrl("gnosis_chain", ChainData("Gnosis Chain", 100, "https://rpc.gnosischain.com"));
    }

    // set chain info, with priority to chainAlias' rpc url in foundry.toml
    function setChainWithDefaultRpcUrl(string memory chainAlias, ChainData memory chain) private {
        string memory rpcUrl = chain.rpcUrl;
        defaultRpcUrls[chainAlias] = rpcUrl;
        chain.rpcUrl = "";
        setChain(chainAlias, chain);
        chain.rpcUrl = rpcUrl; // restore argument
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {StdStorage, stdStorage} from "./StdStorage.sol";
import {Vm} from "./Vm.sol";

abstract contract StdCheatsSafe {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bool private gasMeteringOff;

    // Data structures to parse Transaction objects from the broadcast artifact
    // that conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawTx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        // json value name = function
        string functionSig;
        bytes32 hash;
        // json value name = tx
        RawTx1559Detail txDetail;
        // json value name = type
        string opcode;
    }

    struct RawTx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        bytes gas;
        bytes nonce;
        address to;
        bytes txType;
        bytes value;
    }

    struct Tx1559 {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        bytes32 hash;
        Tx1559Detail txDetail;
        string opcode;
    }

    struct Tx1559Detail {
        AccessList[] accessList;
        bytes data;
        address from;
        uint256 gas;
        uint256 nonce;
        address to;
        uint256 txType;
        uint256 value;
    }

    // Data structures to parse Transaction objects from the broadcast artifact
    // that DO NOT conform to EIP1559. The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct TxLegacy {
        string[] arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        string hash;
        string opcode;
        TxDetailLegacy transaction;
    }

    struct TxDetailLegacy {
        AccessList[] accessList;
        uint256 chainId;
        bytes data;
        address from;
        uint256 gas;
        uint256 gasPrice;
        bytes32 hash;
        uint256 nonce;
        bytes1 opcode;
        bytes32 r;
        bytes32 s;
        uint256 txType;
        address to;
        uint8 v;
        uint256 value;
    }

    struct AccessList {
        address accessAddress;
        bytes32[] storageKeys;
    }

    // Data structures to parse Receipt objects from the broadcast artifact.
    // The Raw structs is what is parsed from the JSON
    // and then converted to the one that is used by the user for better UX.

    struct RawReceipt {
        bytes32 blockHash;
        bytes blockNumber;
        address contractAddress;
        bytes cumulativeGasUsed;
        bytes effectiveGasPrice;
        address from;
        bytes gasUsed;
        RawReceiptLog[] logs;
        bytes logsBloom;
        bytes status;
        address to;
        bytes32 transactionHash;
        bytes transactionIndex;
    }

    struct Receipt {
        bytes32 blockHash;
        uint256 blockNumber;
        address contractAddress;
        uint256 cumulativeGasUsed;
        uint256 effectiveGasPrice;
        address from;
        uint256 gasUsed;
        ReceiptLog[] logs;
        bytes logsBloom;
        uint256 status;
        address to;
        bytes32 transactionHash;
        uint256 transactionIndex;
    }

    // Data structures to parse the entire broadcast artifact, assuming the
    // transactions conform to EIP1559.

    struct EIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        Receipt[] receipts;
        uint256 timestamp;
        Tx1559[] transactions;
        TxReturn[] txReturns;
    }

    struct RawEIP1559ScriptArtifact {
        string[] libraries;
        string path;
        string[] pending;
        RawReceipt[] receipts;
        TxReturn[] txReturns;
        uint256 timestamp;
        RawTx1559[] transactions;
    }

    struct RawReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        bytes blockNumber;
        bytes data;
        bytes logIndex;
        bool removed;
        bytes32[] topics;
        bytes32 transactionHash;
        bytes transactionIndex;
        bytes transactionLogIndex;
    }

    struct ReceiptLog {
        // json value = address
        address logAddress;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes data;
        uint256 logIndex;
        bytes32[] topics;
        uint256 transactionIndex;
        uint256 transactionLogIndex;
        bool removed;
    }

    struct TxReturn {
        string internalType;
        string value;
    }

    function assumeNoPrecompiles(address addr) internal virtual {
        // Assembly required since `block.chainid` was introduced in 0.8.0.
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        assumeNoPrecompiles(addr, chainId);
    }

    function assumeNoPrecompiles(address addr, uint256 chainId) internal pure virtual {
        // Note: For some chains like Optimism these are technically predeploys (i.e. bytecode placed at a specific
        // address), but the same rationale for excluding them applies so we include those too.

        // These should be present on all EVM-compatible chains.
        vm.assume(addr < address(0x1) || addr > address(0x9));

        // forgefmt: disable-start
        if (chainId == 10 || chainId == 420) {
            // https://github.com/ethereum-optimism/optimism/blob/eaa371a0184b56b7ca6d9eb9cb0a2b78b2ccd864/op-bindings/predeploys/addresses.go#L6-L21
            vm.assume(addr < address(0x4200000000000000000000000000000000000000) || addr > address(0x4200000000000000000000000000000000000800));
        } else if (chainId == 42161 || chainId == 421613) {
            // https://developer.arbitrum.io/useful-addresses#arbitrum-precompiles-l2-same-on-all-arb-chains
            vm.assume(addr < address(0x0000000000000000000000000000000000000064) || addr > address(0x0000000000000000000000000000000000000068));
        } else if (chainId == 43114 || chainId == 43113) {
            // https://github.com/ava-labs/subnet-evm/blob/47c03fd007ecaa6de2c52ea081596e0a88401f58/precompile/params.go#L18-L59
            vm.assume(addr < address(0x0100000000000000000000000000000000000000) || addr > address(0x01000000000000000000000000000000000000ff));
            vm.assume(addr < address(0x0200000000000000000000000000000000000000) || addr > address(0x02000000000000000000000000000000000000FF));
            vm.assume(addr < address(0x0300000000000000000000000000000000000000) || addr > address(0x03000000000000000000000000000000000000Ff));
        }
        // forgefmt: disable-end
    }

    function readEIP1559ScriptArtifact(string memory path)
        internal
        view
        virtual
        returns (EIP1559ScriptArtifact memory)
    {
        string memory data = vm.readFile(path);
        bytes memory parsedData = vm.parseJson(data);
        RawEIP1559ScriptArtifact memory rawArtifact = abi.decode(parsedData, (RawEIP1559ScriptArtifact));
        EIP1559ScriptArtifact memory artifact;
        artifact.libraries = rawArtifact.libraries;
        artifact.path = rawArtifact.path;
        artifact.timestamp = rawArtifact.timestamp;
        artifact.pending = rawArtifact.pending;
        artifact.txReturns = rawArtifact.txReturns;
        artifact.receipts = rawToConvertedReceipts(rawArtifact.receipts);
        artifact.transactions = rawToConvertedEIPTx1559s(rawArtifact.transactions);
        return artifact;
    }

    function rawToConvertedEIPTx1559s(RawTx1559[] memory rawTxs) internal pure virtual returns (Tx1559[] memory) {
        Tx1559[] memory txs = new Tx1559[](rawTxs.length);
        for (uint256 i; i < rawTxs.length; i++) {
            txs[i] = rawToConvertedEIPTx1559(rawTxs[i]);
        }
        return txs;
    }

    function rawToConvertedEIPTx1559(RawTx1559 memory rawTx) internal pure virtual returns (Tx1559 memory) {
        Tx1559 memory transaction;
        transaction.arguments = rawTx.arguments;
        transaction.contractName = rawTx.contractName;
        transaction.functionSig = rawTx.functionSig;
        transaction.hash = rawTx.hash;
        transaction.txDetail = rawToConvertedEIP1559Detail(rawTx.txDetail);
        transaction.opcode = rawTx.opcode;
        return transaction;
    }

    function rawToConvertedEIP1559Detail(RawTx1559Detail memory rawDetail)
        internal
        pure
        virtual
        returns (Tx1559Detail memory)
    {
        Tx1559Detail memory txDetail;
        txDetail.data = rawDetail.data;
        txDetail.from = rawDetail.from;
        txDetail.to = rawDetail.to;
        txDetail.nonce = _bytesToUint(rawDetail.nonce);
        txDetail.txType = _bytesToUint(rawDetail.txType);
        txDetail.value = _bytesToUint(rawDetail.value);
        txDetail.gas = _bytesToUint(rawDetail.gas);
        txDetail.accessList = rawDetail.accessList;
        return txDetail;
    }

    function readTx1559s(string memory path) internal view virtual returns (Tx1559[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".transactions");
        RawTx1559[] memory rawTxs = abi.decode(parsedDeployData, (RawTx1559[]));
        return rawToConvertedEIPTx1559s(rawTxs);
    }

    function readTx1559(string memory path, uint256 index) internal view virtual returns (Tx1559 memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".transactions[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawTx1559 memory rawTx = abi.decode(parsedDeployData, (RawTx1559));
        return rawToConvertedEIPTx1559(rawTx);
    }

    // Analogous to readTransactions, but for receipts.
    function readReceipts(string memory path) internal view virtual returns (Receipt[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".receipts");
        RawReceipt[] memory rawReceipts = abi.decode(parsedDeployData, (RawReceipt[]));
        return rawToConvertedReceipts(rawReceipts);
    }

    function readReceipt(string memory path, uint256 index) internal view virtual returns (Receipt memory) {
        string memory deployData = vm.readFile(path);
        string memory key = string(abi.encodePacked(".receipts[", vm.toString(index), "]"));
        bytes memory parsedDeployData = vm.parseJson(deployData, key);
        RawReceipt memory rawReceipt = abi.decode(parsedDeployData, (RawReceipt));
        return rawToConvertedReceipt(rawReceipt);
    }

    function rawToConvertedReceipts(RawReceipt[] memory rawReceipts) internal pure virtual returns (Receipt[] memory) {
        Receipt[] memory receipts = new Receipt[](rawReceipts.length);
        for (uint256 i; i < rawReceipts.length; i++) {
            receipts[i] = rawToConvertedReceipt(rawReceipts[i]);
        }
        return receipts;
    }

    function rawToConvertedReceipt(RawReceipt memory rawReceipt) internal pure virtual returns (Receipt memory) {
        Receipt memory receipt;
        receipt.blockHash = rawReceipt.blockHash;
        receipt.to = rawReceipt.to;
        receipt.from = rawReceipt.from;
        receipt.contractAddress = rawReceipt.contractAddress;
        receipt.effectiveGasPrice = _bytesToUint(rawReceipt.effectiveGasPrice);
        receipt.cumulativeGasUsed = _bytesToUint(rawReceipt.cumulativeGasUsed);
        receipt.gasUsed = _bytesToUint(rawReceipt.gasUsed);
        receipt.status = _bytesToUint(rawReceipt.status);
        receipt.transactionIndex = _bytesToUint(rawReceipt.transactionIndex);
        receipt.blockNumber = _bytesToUint(rawReceipt.blockNumber);
        receipt.logs = rawToConvertedReceiptLogs(rawReceipt.logs);
        receipt.logsBloom = rawReceipt.logsBloom;
        receipt.transactionHash = rawReceipt.transactionHash;
        return receipt;
    }

    function rawToConvertedReceiptLogs(RawReceiptLog[] memory rawLogs)
        internal
        pure
        virtual
        returns (ReceiptLog[] memory)
    {
        ReceiptLog[] memory logs = new ReceiptLog[](rawLogs.length);
        for (uint256 i; i < rawLogs.length; i++) {
            logs[i].logAddress = rawLogs[i].logAddress;
            logs[i].blockHash = rawLogs[i].blockHash;
            logs[i].blockNumber = _bytesToUint(rawLogs[i].blockNumber);
            logs[i].data = rawLogs[i].data;
            logs[i].logIndex = _bytesToUint(rawLogs[i].logIndex);
            logs[i].topics = rawLogs[i].topics;
            logs[i].transactionIndex = _bytesToUint(rawLogs[i].transactionIndex);
            logs[i].transactionLogIndex = _bytesToUint(rawLogs[i].transactionLogIndex);
            logs[i].removed = rawLogs[i].removed;
        }
        return logs;
    }

    // Deploy a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
    function deployCode(string memory what, bytes memory args) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes): Deployment failed.");
    }

    function deployCode(string memory what) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string): Deployment failed.");
    }

    /// @dev deploy contract with value on construction
    function deployCode(string memory what, bytes memory args, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,bytes,uint256): Deployment failed.");
    }

    function deployCode(string memory what, uint256 val) internal virtual returns (address addr) {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "StdCheats deployCode(string,uint256): Deployment failed.");
    }

    // creates a labeled address and the corresponding private key
    function makeAddrAndKey(string memory name) internal virtual returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    // creates a labeled address
    function makeAddr(string memory name) internal virtual returns (address addr) {
        (addr,) = makeAddrAndKey(name);
    }

    function deriveRememberKey(string memory mnemonic, uint32 index)
        internal
        virtual
        returns (address who, uint256 privateKey)
    {
        privateKey = vm.deriveKey(mnemonic, index);
        who = vm.rememberKey(privateKey);
    }

    function _bytesToUint(bytes memory b) private pure returns (uint256) {
        require(b.length <= 32, "StdCheats _bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    function isFork() internal view virtual returns (bool status) {
        try vm.activeFork() {
            status = true;
        } catch (bytes memory) {}
    }

    modifier skipWhenForking() {
        if (!isFork()) {
            _;
        }
    }

    modifier skipWhenNotForking() {
        if (isFork()) {
            _;
        }
    }

    modifier noGasMetering() {
        vm.pauseGasMetering();
        // To prevent turning gas monitoring back on with nested functions that use this modifier,
        // we check if gasMetering started in the off position. If it did, we don't want to turn
        // it back on until we exit the top level function that used the modifier
        //
        // i.e. funcA() noGasMetering { funcB() }, where funcB has noGasMetering as well.
        // funcA will have `gasStartedOff` as false, funcB will have it as true,
        // so we only turn metering back on at the end of the funcA
        bool gasStartedOff = gasMeteringOff;
        gasMeteringOff = true;

        _;

        // if gas metering was on when this modifier was called, turn it back on at the end
        if (!gasStartedOff) {
            gasMeteringOff = false;
            vm.resumeGasMetering();
        }
    }

    // a cheat for fuzzing addresses that are payable only
    // see https://github.com/foundry-rs/foundry/issues/3631
    function assumePayable(address addr) internal virtual {
        (bool success,) = payable(addr).call{value: 0}("");
        vm.assume(success);
    }
}

// Wrappers around cheatcodes to avoid footguns
abstract contract StdCheats is StdCheatsSafe {
    using stdStorage for StdStorage;

    StdStorage private stdstore;
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) internal virtual {
        vm.warp(block.timestamp + time);
    }

    function rewind(uint256 time) internal virtual {
        vm.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address msgSender) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.prank(msgSender);
    }

    function hoax(address msgSender, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.prank(msgSender);
    }

    function hoax(address msgSender, address origin) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.prank(msgSender, origin);
    }

    function hoax(address msgSender, address origin, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.prank(msgSender, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address msgSender) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.startPrank(msgSender);
    }

    function startHoax(address msgSender, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.startPrank(msgSender);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address msgSender, address origin) internal virtual {
        vm.deal(msgSender, 1 << 128);
        vm.startPrank(msgSender, origin);
    }

    function startHoax(address msgSender, address origin, uint256 give) internal virtual {
        vm.deal(msgSender, give);
        vm.startPrank(msgSender, origin);
    }

    function changePrank(address msgSender) internal virtual {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }

    function changePrank(address msgSender, address txOrigin) internal virtual {
        vm.stopPrank();
        vm.startPrank(msgSender, txOrigin);
    }

    // The same as Vm's `deal`
    // Use the alternative signature for ERC20 tokens
    function deal(address to, uint256 give) internal virtual {
        vm.deal(to, give);
    }

    // Set the balance of an account for any ERC20 token
    // Use the alternative signature to update `totalSupply`
    function deal(address token, address to, uint256 give) internal virtual {
        deal(token, to, give, false);
    }

    // Set the balance of an account for any ERC1155 token
    // Use the alternative signature to update `totalSupply`
    function dealERC1155(address token, address to, uint256 id, uint256 give) internal virtual {
        dealERC1155(token, to, id, give, false);
    }

    function deal(address token, address to, uint256 give, bool adjust) internal virtual {
        // get current balance
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, to));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore.target(token).sig(0x70a08231).with_key(to).checked_write(give);

        // update total supply
        if (adjust) {
            (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
            uint256 totSup = abi.decode(totSupData, (uint256));
            if (give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore.target(token).sig(0x18160ddd).checked_write(totSup);
        }
    }

    function dealERC1155(address token, address to, uint256 id, uint256 give, bool adjust) internal virtual {
        // get current balance
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x00fdd58e, to, id));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore.target(token).sig(0x00fdd58e).with_key(to).with_key(id).checked_write(give);

        // update total supply
        if (adjust) {
            (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0xbd85b039, id));
            require(
                totSupData.length != 0,
                "StdCheats deal(address,address,uint,uint,bool): target contract is not ERC1155Supply."
            );
            uint256 totSup = abi.decode(totSupData, (uint256));
            if (give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore.target(token).sig(0xbd85b039).with_key(id).checked_write(totSup);
        }
    }

    function dealERC721(address token, address to, uint256 id) internal virtual {
        // check if token id is already minted and the actual owner.
        (bool successMinted, bytes memory ownerData) = token.staticcall(abi.encodeWithSelector(0x6352211e, id));
        require(successMinted, "StdCheats deal(address,address,uint,bool): id not minted.");

        // get owner current balance
        (, bytes memory fromBalData) = token.call(abi.encodeWithSelector(0x70a08231, abi.decode(ownerData, (address))));
        uint256 fromPrevBal = abi.decode(fromBalData, (uint256));

        // get new user current balance
        (, bytes memory toBalData) = token.call(abi.encodeWithSelector(0x70a08231, to));
        uint256 toPrevBal = abi.decode(toBalData, (uint256));

        // update balances
        stdstore.target(token).sig(0x70a08231).with_key(abi.decode(ownerData, (address))).checked_write(--fromPrevBal);
        stdstore.target(token).sig(0x70a08231).with_key(to).checked_write(++toPrevBal);

        // update owner
        stdstore.target(token).sig(0x6352211e).with_key(id).checked_write(to);
    }
}

// SPDX-License-Identifier: MIT
// Panics work for versions >=0.8.0, but we lowered the pragma to make this compatible with Test
pragma solidity >=0.6.2 <0.9.0;

library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

contract StdInvariant {
    struct FuzzSelector {
        address addr;
        bytes4[] selectors;
    }

    address[] private _excludedContracts;
    address[] private _excludedSenders;
    address[] private _targetedContracts;
    address[] private _targetedSenders;

    string[] private _excludedArtifacts;
    string[] private _targetedArtifacts;

    FuzzSelector[] private _targetedArtifactSelectors;
    FuzzSelector[] private _targetedSelectors;

    // Functions for users:
    // These are intended to be called in tests.

    function excludeContract(address newExcludedContract_) internal {
        _excludedContracts.push(newExcludedContract_);
    }

    function excludeSender(address newExcludedSender_) internal {
        _excludedSenders.push(newExcludedSender_);
    }

    function excludeArtifact(string memory newExcludedArtifact_) internal {
        _excludedArtifacts.push(newExcludedArtifact_);
    }

    function targetArtifact(string memory newTargetedArtifact_) internal {
        _targetedArtifacts.push(newTargetedArtifact_);
    }

    function targetArtifactSelector(FuzzSelector memory newTargetedArtifactSelector_) internal {
        _targetedArtifactSelectors.push(newTargetedArtifactSelector_);
    }

    function targetContract(address newTargetedContract_) internal {
        _targetedContracts.push(newTargetedContract_);
    }

    function targetSelector(FuzzSelector memory newTargetedSelector_) internal {
        _targetedSelectors.push(newTargetedSelector_);
    }

    function targetSender(address newTargetedSender_) internal {
        _targetedSenders.push(newTargetedSender_);
    }

    // Functions for forge:
    // These are called by forge to run invariant tests and don't need to be called in tests.

    function excludeArtifacts() public view returns (string[] memory excludedArtifacts_) {
        excludedArtifacts_ = _excludedArtifacts;
    }

    function excludeContracts() public view returns (address[] memory excludedContracts_) {
        excludedContracts_ = _excludedContracts;
    }

    function excludeSenders() public view returns (address[] memory excludedSenders_) {
        excludedSenders_ = _excludedSenders;
    }

    function targetArtifacts() public view returns (string[] memory targetedArtifacts_) {
        targetedArtifacts_ = _targetedArtifacts;
    }

    function targetArtifactSelectors() public view returns (FuzzSelector[] memory targetedArtifactSelectors_) {
        targetedArtifactSelectors_ = _targetedArtifactSelectors;
    }

    function targetContracts() public view returns (address[] memory targetedContracts_) {
        targetedContracts_ = _targetedContracts;
    }

    function targetSelectors() public view returns (FuzzSelector[] memory targetedSelectors_) {
        targetedSelectors_ = _targetedSelectors;
    }

    function targetSenders() public view returns (address[] memory targetedSenders_) {
        targetedSenders_ = _targetedSenders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

pragma experimental ABIEncoderV2;

import {VmSafe} from "./Vm.sol";

// Helpers for parsing and writing JSON files
// To parse:
// ```
// using stdJson for string;
// string memory json = vm.readFile("some_peth");
// json.parseUint("<json_path>");
// ```
// To write:
// ```
// using stdJson for string;
// string memory json = "deploymentArtifact";
// Contract contract = new Contract();
// json.serialize("contractAddress", address(contract));
// json = json.serialize("deploymentTimes", uint(1));
// // store the stringified JSON to the 'json' variable we have been using as a key
// // as we won't need it any longer
// string memory json2 = "finalArtifact";
// string memory final = json2.serialize("depArtifact", json);
// final.write("<some_path>");
// ```

library stdJson {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function parseRaw(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJson(json, key);
    }

    function readUint(string memory json, string memory key) internal returns (uint256) {
        return vm.parseJsonUint(json, key);
    }

    function readUintArray(string memory json, string memory key) internal returns (uint256[] memory) {
        return vm.parseJsonUintArray(json, key);
    }

    function readInt(string memory json, string memory key) internal returns (int256) {
        return vm.parseJsonInt(json, key);
    }

    function readIntArray(string memory json, string memory key) internal returns (int256[] memory) {
        return vm.parseJsonIntArray(json, key);
    }

    function readBytes32(string memory json, string memory key) internal returns (bytes32) {
        return vm.parseJsonBytes32(json, key);
    }

    function readBytes32Array(string memory json, string memory key) internal returns (bytes32[] memory) {
        return vm.parseJsonBytes32Array(json, key);
    }

    function readString(string memory json, string memory key) internal returns (string memory) {
        return vm.parseJsonString(json, key);
    }

    function readStringArray(string memory json, string memory key) internal returns (string[] memory) {
        return vm.parseJsonStringArray(json, key);
    }

    function readAddress(string memory json, string memory key) internal returns (address) {
        return vm.parseJsonAddress(json, key);
    }

    function readAddressArray(string memory json, string memory key) internal returns (address[] memory) {
        return vm.parseJsonAddressArray(json, key);
    }

    function readBool(string memory json, string memory key) internal returns (bool) {
        return vm.parseJsonBool(json, key);
    }

    function readBoolArray(string memory json, string memory key) internal returns (bool[] memory) {
        return vm.parseJsonBoolArray(json, key);
    }

    function readBytes(string memory json, string memory key) internal returns (bytes memory) {
        return vm.parseJsonBytes(json, key);
    }

    function readBytesArray(string memory json, string memory key) internal returns (bytes[] memory) {
        return vm.parseJsonBytesArray(json, key);
    }

    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bool[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function write(string memory jsonKey, string memory path) internal {
        vm.writeJson(jsonKey, path);
    }

    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeJson(jsonKey, path, valueKey);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

library stdMath {
    int256 private constant INT256_MIN = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == INT256_MIN) {
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        }

        return uint256(a > 0 ? a : -a);
    }

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);

        return absDelta * 1e18 / absB;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {Vm} from "./Vm.sol";

struct StdStorage {
    mapping(address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping(address => mapping(bytes4 => mapping(bytes32 => bool))) finds;
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorageSafe {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint256 slot);
    event WARNING_UninitedSlot(address who, uint256 slot);

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(StdStorage storage self) internal returns (uint256) {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }

        (bytes32[] memory reads,) = vm.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(
                    false,
                    "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
                );
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32 * field_depth);
                }

                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm.store(who, reads[i], prev);
                    break;
                }
                vm.store(who, reads[i], prev);
            }
        } else {
            revert("stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))],
            "stdStorage find(StdStorage): Slot(s) not found."
        );

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

library stdStorage {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function sigs(string memory sigStr) internal pure returns (bytes4) {
        return stdStorageSafe.sigs(sigStr);
    }

    function find(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.find(self);
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        return stdStorageSafe.target(self, _target);
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        return stdStorageSafe.sig(self, _sig);
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, who);
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, amt);
    }

    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        return stdStorageSafe.with_key(self, key);
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        return stdStorageSafe.depth(self, _depth);
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(StdStorage storage self, bytes32 set) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32 * field_depth);
        }
        bytes32 curr = vm.load(who, slot);

        if (fdat != curr) {
            require(
                false,
                "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported."
            );
        }
        vm.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return stdStorageSafe.read_bytes32(self);
    }

    function read_bool(StdStorage storage self) internal returns (bool) {
        return stdStorageSafe.read_bool(self);
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return stdStorageSafe.read_address(self);
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return stdStorageSafe.read_uint(self);
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return stdStorageSafe.read_int(self);
    }

    // Private function so needs to be copied over
    function bytesToBytes32(bytes memory b, uint256 offset) private pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint256 i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // Private function so needs to be copied over
    function flatten(bytes32[] memory b) private pure returns (bytes memory) {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Vm} from "./Vm.sol";

library StdStyle {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    string constant RED = "\u001b[91m";
    string constant GREEN = "\u001b[92m";
    string constant YELLOW = "\u001b[93m";
    string constant BLUE = "\u001b[94m";
    string constant MAGENTA = "\u001b[95m";
    string constant CYAN = "\u001b[96m";
    string constant BOLD = "\u001b[1m";
    string constant DIM = "\u001b[2m";
    string constant ITALIC = "\u001b[3m";
    string constant UNDERLINE = "\u001b[4m";
    string constant INVERSE = "\u001b[7m";
    string constant RESET = "\u001b[0m";

    function styleConcat(string memory style, string memory self) private pure returns (string memory) {
        return string(abi.encodePacked(style, self, RESET));
    }

    function red(string memory self) internal pure returns (string memory) {
        return styleConcat(RED, self);
    }

    function red(uint256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(int256 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(address self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function red(bool self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function redBytes(bytes memory self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function redBytes32(bytes32 self) internal pure returns (string memory) {
        return red(vm.toString(self));
    }

    function green(string memory self) internal pure returns (string memory) {
        return styleConcat(GREEN, self);
    }

    function green(uint256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(int256 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(address self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function green(bool self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function greenBytes(bytes memory self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function greenBytes32(bytes32 self) internal pure returns (string memory) {
        return green(vm.toString(self));
    }

    function yellow(string memory self) internal pure returns (string memory) {
        return styleConcat(YELLOW, self);
    }

    function yellow(uint256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(int256 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(address self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellow(bool self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellowBytes(bytes memory self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function yellowBytes32(bytes32 self) internal pure returns (string memory) {
        return yellow(vm.toString(self));
    }

    function blue(string memory self) internal pure returns (string memory) {
        return styleConcat(BLUE, self);
    }

    function blue(uint256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(int256 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(address self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blue(bool self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blueBytes(bytes memory self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function blueBytes32(bytes32 self) internal pure returns (string memory) {
        return blue(vm.toString(self));
    }

    function magenta(string memory self) internal pure returns (string memory) {
        return styleConcat(MAGENTA, self);
    }

    function magenta(uint256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(int256 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(address self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magenta(bool self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magentaBytes(bytes memory self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function magentaBytes32(bytes32 self) internal pure returns (string memory) {
        return magenta(vm.toString(self));
    }

    function cyan(string memory self) internal pure returns (string memory) {
        return styleConcat(CYAN, self);
    }

    function cyan(uint256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(int256 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(address self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyan(bool self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyanBytes(bytes memory self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function cyanBytes32(bytes32 self) internal pure returns (string memory) {
        return cyan(vm.toString(self));
    }

    function bold(string memory self) internal pure returns (string memory) {
        return styleConcat(BOLD, self);
    }

    function bold(uint256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(int256 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(address self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function bold(bool self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function boldBytes(bytes memory self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function boldBytes32(bytes32 self) internal pure returns (string memory) {
        return bold(vm.toString(self));
    }

    function dim(string memory self) internal pure returns (string memory) {
        return styleConcat(DIM, self);
    }

    function dim(uint256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(int256 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(address self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dim(bool self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dimBytes(bytes memory self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function dimBytes32(bytes32 self) internal pure returns (string memory) {
        return dim(vm.toString(self));
    }

    function italic(string memory self) internal pure returns (string memory) {
        return styleConcat(ITALIC, self);
    }

    function italic(uint256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(int256 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(address self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italic(bool self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italicBytes(bytes memory self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function italicBytes32(bytes32 self) internal pure returns (string memory) {
        return italic(vm.toString(self));
    }

    function underline(string memory self) internal pure returns (string memory) {
        return styleConcat(UNDERLINE, self);
    }

    function underline(uint256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(int256 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(address self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underline(bool self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underlineBytes(bytes memory self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function underlineBytes32(bytes32 self) internal pure returns (string memory) {
        return underline(vm.toString(self));
    }

    function inverse(string memory self) internal pure returns (string memory) {
        return styleConcat(INVERSE, self);
    }

    function inverse(uint256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(int256 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(address self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverse(bool self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverseBytes(bytes memory self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }

    function inverseBytes32(bytes32 self) internal pure returns (string memory) {
        return inverse(vm.toString(self));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {IMulticall3} from "./interfaces/IMulticall3.sol";
// TODO Remove import.
import {VmSafe} from "./Vm.sol";

abstract contract StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IMulticall3 private constant multicall = IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11);
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant CONSOLE2_ADDRESS = 0x000000000000000000636F6e736F6c652e6c6f67;
    uint256 private constant INT256_MIN_ABS =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // Used by default when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    address private constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /*//////////////////////////////////////////////////////////////////////////
                                 INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _bound(uint256 x, uint256 min, uint256 max) internal pure virtual returns (uint256 result) {
        require(min <= max, "StdUtils bound(uint256,uint256,uint256): Max is less than min.");
        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        // If the value is 0, 1, 2, 3, warp that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x) return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
    }

    function bound(uint256 x, uint256 min, uint256 max) internal view virtual returns (uint256 result) {
        result = _bound(x, min, max);
        console2_log("Bound Result", result);
    }

    function bound(int256 x, int256 min, int256 max) internal view virtual returns (int256 result) {
        require(min <= max, "StdUtils bound(int256,int256,int256): Max is less than min.");

        // Shifting all int256 values to uint256 to use _bound function. The range of two types are:
        // int256 : -(2**255) ~ (2**255 - 1)
        // uint256:     0     ~ (2**256 - 1)
        // So, add 2**255, INT256_MIN_ABS to the integer values.
        //
        // If the given integer value is -2**255, we cannot use `-uint256(-x)` because of the overflow.
        // So, use `~uint256(x) + 1` instead.
        uint256 _x = x < 0 ? (INT256_MIN_ABS - ~uint256(x) - 1) : (uint256(x) + INT256_MIN_ABS);
        uint256 _min = min < 0 ? (INT256_MIN_ABS - ~uint256(min) - 1) : (uint256(min) + INT256_MIN_ABS);
        uint256 _max = max < 0 ? (INT256_MIN_ABS - ~uint256(max) - 1) : (uint256(max) + INT256_MIN_ABS);

        uint256 y = _bound(_x, _min, _max);

        // To move it back to int256 value, subtract INT256_MIN_ABS at here.
        result = y < INT256_MIN_ABS ? int256(~(INT256_MIN_ABS - y) + 1) : int256(y - INT256_MIN_ABS);
        console2_log("Bound result", vm.toString(result));
    }

    function bytesToUint(bytes memory b) internal pure virtual returns (uint256) {
        require(b.length <= 32, "StdUtils bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }

    /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
    /// @notice adapted from Solmate implementation (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce) internal pure virtual returns (address) {
        // forgefmt: disable-start
        // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))));
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))));
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));
        // forgefmt: disable-end

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bytes.
        return addressFromLast20Bytes(
            keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce)))
        );
    }

    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash, address deployer)
        internal
        pure
        virtual
        returns (address)
    {
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initcodeHash)));
    }

    /// @dev returns the address of a contract created with CREATE2 using the default CREATE2 deployer
    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash) internal pure returns (address) {
        return computeCreate2Address(salt, initCodeHash, CREATE2_FACTORY);
    }

    /// @dev returns the hash of the init code (creation code + no args) used in CREATE2 with no constructor arguments
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    function hashInitCode(bytes memory creationCode) internal pure returns (bytes32) {
        return hashInitCode(creationCode, "");
    }

    /// @dev returns the hash of the init code (creation code + ABI-encoded args) used in CREATE2
    /// @param creationCode the creation code of a contract C, as returned by type(C).creationCode
    /// @param args the ABI-encoded arguments to the constructor of C
    function hashInitCode(bytes memory creationCode, bytes memory args) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }

    // Performs a single call with Multicall3 to query the ERC-20 token balances of the given addresses.
    function getTokenBalances(address token, address[] memory addresses)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256 tokenCodeSize;
        assembly {
            tokenCodeSize := extcodesize(token)
        }
        require(tokenCodeSize > 0, "StdUtils getTokenBalances(address,address[]): Token address is not a contract.");

        // ABI encode the aggregate call to Multicall3.
        uint256 length = addresses.length;
        IMulticall3.Call[] memory calls = new IMulticall3.Call[](length);
        for (uint256 i = 0; i < length; ++i) {
            // 0x70a08231 = bytes4("balanceOf(address)"))
            calls[i] = IMulticall3.Call({target: token, callData: abi.encodeWithSelector(0x70a08231, (addresses[i]))});
        }

        // Make the aggregate call.
        (, bytes[] memory returnData) = multicall.aggregate(calls);

        // ABI decode the return data and return the balances.
        balances = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            balances[i] = abi.decode(returnData[i], (uint256));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addressFromLast20Bytes(bytes32 bytesValue) private pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    // Used to prevent the compilation of console, which shortens the compilation time when console is not used elsewhere.

    function console2_log(string memory p0, uint256 p1) private view {
        (bool status,) = address(CONSOLE2_ADDRESS).staticcall(abi.encodeWithSignature("log(string,uint256)", p0, p1));
        status;
    }

    function console2_log(string memory p0, string memory p1) private view {
        (bool status,) = address(CONSOLE2_ADDRESS).staticcall(abi.encodeWithSignature("log(string,string)", p0, p1));
        status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// 💬 ABOUT
// Standard Library's default Test

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {StdAssertions} from "./StdAssertions.sol";
import {StdChains} from "./StdChains.sol";
import {StdCheats} from "./StdCheats.sol";
import {stdError} from "./StdError.sol";
import {StdInvariant} from "./StdInvariant.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorage} from "./StdStorage.sol";
import {StdUtils} from "./StdUtils.sol";
import {Vm} from "./Vm.sol";
import {StdStyle} from "./StdStyle.sol";

// 📦 BOILERPLATE
import {TestBase} from "./Base.sol";
import {DSTest} from "ds-test/test.sol";

// ⭐️ TEST
abstract contract Test is DSTest, StdAssertions, StdChains, StdCheats, StdInvariant, StdUtils, TestBase {
// Note: IS_TEST() must return true.
// Note: Must have failure system, https://github.com/dapphub/ds-test/blob/cd98eff28324bfac652e63a239a60632a761790b/src/test.sol#L39-L76.
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// Cheatcodes are marked as view/pure/none using the following rules:
// 0. A call's observable behaviour includes its return value, logs, reverts and state writes,
// 1. If you can influence a later call's observable behaviour, you're neither `view` nor `pure (you are modifying some state be it the EVM, interpreter, filesystem, etc),
// 2. Otherwise if you can be influenced by an earlier call, or if reading some state, you're `view`,
// 3. Otherwise you're `pure`.

interface VmSafe {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    struct Rpc {
        string key;
        string url;
    }

    struct FsMetadata {
        bool isDir;
        bool isSymlink;
        uint256 length;
        bool readOnly;
        uint256 modified;
        uint256 accessed;
        uint256 created;
    }

    // Loads a storage slot from an address
    function load(address target, bytes32 slot) external view returns (bytes32 data);
    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    // Gets the address for a given private key
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    // Gets the nonce of an account
    function getNonce(address account) external view returns (uint64 nonce);
    // Performs a foreign function call via the terminal
    function ffi(string[] calldata commandInput) external returns (bytes memory result);
    // Sets environment variables
    function setEnv(string calldata name, string calldata value) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata name) external view returns (bool value);
    function envUint(string calldata name) external view returns (uint256 value);
    function envInt(string calldata name) external view returns (int256 value);
    function envAddress(string calldata name) external view returns (address value);
    function envBytes32(string calldata name) external view returns (bytes32 value);
    function envString(string calldata name) external view returns (string memory value);
    function envBytes(string calldata name) external view returns (bytes memory value);
    // Reads environment variables as arrays
    function envBool(string calldata name, string calldata delim) external view returns (bool[] memory value);
    function envUint(string calldata name, string calldata delim) external view returns (uint256[] memory value);
    function envInt(string calldata name, string calldata delim) external view returns (int256[] memory value);
    function envAddress(string calldata name, string calldata delim) external view returns (address[] memory value);
    function envBytes32(string calldata name, string calldata delim) external view returns (bytes32[] memory value);
    function envString(string calldata name, string calldata delim) external view returns (string[] memory value);
    function envBytes(string calldata name, string calldata delim) external view returns (bytes[] memory value);
    // Read environment variables with default value
    function envOr(string calldata name, bool defaultValue) external returns (bool value);
    function envOr(string calldata name, uint256 defaultValue) external returns (uint256 value);
    function envOr(string calldata name, int256 defaultValue) external returns (int256 value);
    function envOr(string calldata name, address defaultValue) external returns (address value);
    function envOr(string calldata name, bytes32 defaultValue) external returns (bytes32 value);
    function envOr(string calldata name, string calldata defaultValue) external returns (string memory value);
    function envOr(string calldata name, bytes calldata defaultValue) external returns (bytes memory value);
    // Read environment variables as arrays with default value
    function envOr(string calldata name, string calldata delim, bool[] calldata defaultValue)
        external
        returns (bool[] memory value);
    function envOr(string calldata name, string calldata delim, uint256[] calldata defaultValue)
        external
        returns (uint256[] memory value);
    function envOr(string calldata name, string calldata delim, int256[] calldata defaultValue)
        external
        returns (int256[] memory value);
    function envOr(string calldata name, string calldata delim, address[] calldata defaultValue)
        external
        returns (address[] memory value);
    function envOr(string calldata name, string calldata delim, bytes32[] calldata defaultValue)
        external
        returns (bytes32[] memory value);
    function envOr(string calldata name, string calldata delim, string[] calldata defaultValue)
        external
        returns (string[] memory value);
    function envOr(string calldata name, string calldata delim, bytes[] calldata defaultValue)
        external
        returns (bytes[] memory value);
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address target) external returns (bytes32[] memory readSlots, bytes32[] memory writeSlots);
    // Gets the _creation_ bytecode from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata artifactPath) external view returns (bytes memory creationBytecode);
    // Gets the _deployed_ bytecode from an artifact file. Takes in the relative path to the json file
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);
    // Labels an address in call traces
    function label(address account, string calldata newLabel) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address signer) external;
    // Has the next call (at this call depth only) create a transaction with the private key provided as the sender that can later be signed and sent onchain
    function broadcast(uint256 privateKey) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;
    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    // Reads the entire content of file to string
    function readFile(string calldata path) external view returns (string memory data);
    // Reads the entire content of file as binary. Path is relative to the project root.
    function readFileBinary(string calldata path) external view returns (bytes memory data);
    // Get the path of the current project root
    function projectRoot() external view returns (string memory path);
    // Get the metadata for a file/directory
    function fsMetadata(string calldata fileOrDir) external returns (FsMetadata memory metadata);
    // Reads next line of file to string
    function readLine(string calldata path) external view returns (string memory line);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    function writeFile(string calldata path, string calldata data) external;
    // Writes binary data to a file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // Path is relative to the project root.
    function writeFileBinary(string calldata path, bytes calldata data) external;
    // Writes line to file, creating a file if it does not exist.
    function writeLine(string calldata path, string calldata data) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    function closeFile(string calldata path) external;
    // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - Path points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    function removeFile(string calldata path) external;
    // Convert values to a string
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes calldata value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function toString(bool value) external pure returns (string memory stringifiedValue);
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(int256 value) external pure returns (string memory stringifiedValue);
    // Convert values from a string
    function parseBytes(string calldata stringifiedValue) external pure returns (bytes memory parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseInt(string calldata stringifiedValue) external pure returns (int256 parsedValue);
    function parseBytes32(string calldata stringifiedValue) external pure returns (bytes32 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata mnemonic, uint32 index) external pure returns (uint256 privateKey);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at {derivationPath}{index}
    function deriveKey(string calldata mnemonic, string calldata derivationPath, uint32 index)
        external
        pure
        returns (uint256 privateKey);
    // Adds a private key to the local forge wallet and returns the address
    function rememberKey(uint256 privateKey) external returns (address keyAddr);
    //
    // parseJson
    //
    // ----
    // In case the returned value is a JSON object, it's encoded as a ABI-encoded tuple. As JSON objects
    // don't have the notion of ordered, but tuples do, they JSON object is encoded with it's fields ordered in
    // ALPHABETICAL order. That means that in order to successfully decode the tuple, we need to define a tuple that
    // encodes the fields in the same order, which is alphabetical. In the case of Solidity structs, they are encoded
    // as tuples, with the attributes in the order in which they are defined.
    // For example: json = { 'a': 1, 'b': 0xa4tb......3xs}
    // a: uint256
    // b: address
    // To decode that json, we need to define a struct or a tuple as follows:
    // struct json = { uint256 a; address b; }
    // If we defined a json struct with the opposite order, meaning placing the address b first, it would try to
    // decode the tuple in that order, and thus fail.
    // ----
    // Given a string of JSON, return it as ABI-encoded
    function parseJson(string calldata json, string calldata key) external pure returns (bytes memory abiEncodedData);
    function parseJson(string calldata json) external pure returns (bytes memory abiEncodedData);

    // The following parseJson cheatcodes will do type coercion, for the type that they indicate.
    // For example, parseJsonUint will coerce all values to a uint256. That includes stringified numbers '12'
    // and hex numbers '0xEF'.
    // Type coercion works ONLY for discrete values or arrays. That means that the key must return a value or array, not
    // a JSON object.
    function parseJsonUint(string calldata, string calldata) external returns (uint256);
    function parseJsonUintArray(string calldata, string calldata) external returns (uint256[] memory);
    function parseJsonInt(string calldata, string calldata) external returns (int256);
    function parseJsonIntArray(string calldata, string calldata) external returns (int256[] memory);
    function parseJsonBool(string calldata, string calldata) external returns (bool);
    function parseJsonBoolArray(string calldata, string calldata) external returns (bool[] memory);
    function parseJsonAddress(string calldata, string calldata) external returns (address);
    function parseJsonAddressArray(string calldata, string calldata) external returns (address[] memory);
    function parseJsonString(string calldata, string calldata) external returns (string memory);
    function parseJsonStringArray(string calldata, string calldata) external returns (string[] memory);
    function parseJsonBytes(string calldata, string calldata) external returns (bytes memory);
    function parseJsonBytesArray(string calldata, string calldata) external returns (bytes[] memory);
    function parseJsonBytes32(string calldata, string calldata) external returns (bytes32);
    function parseJsonBytes32Array(string calldata, string calldata) external returns (bytes32[] memory);

    // Serialize a key and value to a JSON object stored in-memory that can be later written to a file
    // It returns the stringified version of the specific JSON file up to that moment.
    function serializeBool(string calldata objectKey, string calldata valueKey, bool value)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256 value)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256 value)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address value)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32 value)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string calldata value)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes calldata value)
        external
        returns (string memory json);

    function serializeBool(string calldata objectKey, string calldata valueKey, bool[] calldata values)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256[] calldata values)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256[] calldata values)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address[] calldata values)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32[] calldata values)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string[] calldata values)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes[] calldata values)
        external
        returns (string memory json);

    //
    // writeJson
    //
    // ----
    // Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    // Let's assume we want to write the following JSON to a file:
    //
    // { "boolean": true, "number": 342, "object": { "title": "finally json serialization" } }
    //
    // ```
    //  string memory json1 = "some key";
    //  vm.serializeBool(json1, "boolean", true);
    //  vm.serializeBool(json1, "number", uint256(342));
    //  json2 = "some other key";
    //  string memory output = vm.serializeString(json2, "title", "finally json serialization");
    //  string memory finalJson = vm.serialize(json1, "object", output);
    //  vm.writeJson(finalJson, "./output/example.json");
    // ```
    // The critical insight is that every invocation of serialization will return the stringified version of the JSON
    // up to that point. That means we can construct arbitrary JSON objects and then use the return stringified version
    // to serialize them as values to another JSON object.
    //
    // json1 and json2 are simply keys used by the backend to keep track of the objects. So vm.serializeJson(json1,..)
    // will find the object in-memory that is keyed by "some key".
    function writeJson(string calldata json, string calldata path) external;
    // Write a serialized JSON object to an **existing** JSON file, replacing a value with key = <value_key>
    // This is useful to replace a specific value of a JSON file, without having to parse the entire thing
    function writeJson(string calldata json, string calldata path, string calldata valueKey) external;
    // Returns the RPC url for the given alias
    function rpcUrl(string calldata rpcAlias) external view returns (string memory json);
    // Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external view returns (string[2][] memory urls);
    // Returns all rpc urls and their aliases as structs.
    function rpcUrlStructs() external view returns (Rpc[] memory urls);
    // If the condition is false, discard this run's fuzz inputs and generate new ones.
    function assume(bool condition) external pure;
    // Pauses gas metering (i.e. gas usage is not counted). Noop if already paused.
    function pauseGasMetering() external;
    // Resumes gas metering (i.e. gas usage is counted again). Noop if already on.
    function resumeGasMetering() external;
}

interface Vm is VmSafe {
    // Sets block.timestamp
    function warp(uint256 newTimestamp) external;
    // Sets block.height
    function roll(uint256 newHeight) external;
    // Sets block.basefee
    function fee(uint256 newBasefee) external;
    // Sets block.difficulty
    function difficulty(uint256 newDifficulty) external;
    // Sets block.chainid
    function chainId(uint256 newChainId) external;
    // Stores a value to an address' storage slot.
    function store(address target, bytes32 slot, bytes32 value) external;
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address account, uint64 newNonce) external;
    // Sets the *next* call's msg.sender to be the input address
    function prank(address msgSender) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address msgSender) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address msgSender, address txOrigin) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address msgSender, address txOrigin) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance
    function deal(address account, uint256 newBalance) external;
    // Sets an address' code
    function etch(address target, bytes calldata newRuntimeBytecode) external;
    // Expects an error on next call
    function expectRevert(bytes calldata revertData) external;
    function expectRevert(bytes4 revertData) external;
    function expectRevert() external;

    // Prepare an expected log with all four checks enabled.
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data.
    // Second form also checks supplied address against emitting contract.
    function expectEmit() external;
    function expectEmit(address) external;

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans).
    // Second form also checks supplied address against emitting contract.
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address callee, uint256 msgValue, bytes calldata data, bytes calldata returnData) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address callee, bytes calldata data) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data) external;
    // Expect a call to an address with the specified msg.value, gas, and calldata.
    function expectCall(address callee, uint256 msgValue, uint64 gas, bytes calldata data) external;
    // Expect a call to an address with the specified msg.value and calldata, and a *minimum* amount of gas.
    function expectCallMinGas(address callee, uint256 msgValue, uint64 minGas, bytes calldata data) external;
    // Sets block.coinbase
    function coinbase(address newCoinbase) external;
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns (uint256 snapshotId);
    // Revert the state of the EVM to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256 snapshotId) external returns (bool success);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before the transaction,
    // and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates _and_ also selects new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before
    // the transaction, returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256 forkId) external;
    /// Returns the identifier of the currently active fork. Reverts if no fork is currently active.
    function activeFork() external view returns (uint256 forkId);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256 blockNumber) external;
    // Updates the currently active fork to given transaction
    // this will `rollFork` with the number of the block the transaction was mined in and replays all transaction mined before it in the block
    function rollFork(bytes32 txHash) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    // Updates the given fork to block number of the given transaction and replays all transaction mined before it in the block
    function rollFork(uint256 forkId, bytes32 txHash) external;
    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address account) external;
    function makePersistent(address account0, address account1) external;
    function makePersistent(address account0, address account1, address account2) external;
    function makePersistent(address[] calldata accounts) external;
    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address account) external;
    function revokePersistent(address[] calldata accounts) external;
    // Returns true if the account is marked as persistent
    function isPersistent(address account) external view returns (bool persistent);
    // In forking mode, explicitly grant the given address cheatcode access
    function allowCheatcodes(address account) external;
    // Fetches the given transaction from the active fork and executes it on the current state
    function transact(bytes32 txHash) external;
    // Fetches the given transaction from the given fork and executes it on the current state
    function transact(uint256 forkId, bytes32 txHash) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../contracts/AgentPayrollWallet.sol";
import "../../contracts/EZR/EZR.sol";
import "../../contracts/Users/UserUnicity.sol";
import "../../contracts/YousovForwarder.sol";
import "../../contracts/Users/UserFactory.sol";

contract AgentPayrollWalletTest is Test, YousovRoles {
    UserFactory public userFactoryContract;
    UserUnicity public userUnicity = new UserUnicity();
    YousovForwarder forwarder;
    AgentPayrollWallet public APW;
    address matic =0xEFE0797f5a14A53f5dc5E227060EcEF3934Eda1b ;
    address usdc = 0xA0374327EEAdfbA2c68346AC72E44c6B60F3cB6F ;
    address yousovAgregator= 0x5AD719C0BEC6559FA69f2b2F48e71b293c8B490C;
    address managerCOntroller = 0xcBDc0578ae9FFEe3bc605d6a037584d546562Dbe;
    EZR public EZRToken;
    YousovAccessControl public yousovAccessControlContract;

    address default_admin = vm.addr(1);
    address EZR_minter = vm.addr(2);
    address EZR_Pauser = vm.addr(3);
    address user4 = vm.addr(4);

    function setUp() public {
        vm.label(default_admin, "default_admin");
        vm.label(EZR_minter, "EZR_minter");
        vm.label(EZR_Pauser, "EZR_Pauser");
        vm.label(user4, "user4");

        yousovAccessControlContract = new YousovAccessControl(default_admin, EZR_minter, EZR_Pauser);
        userFactoryContract = new UserFactory(
            address(yousovAccessControlContract),
            address(forwarder),
            address(userUnicity)
        );
        vm.prank(EZR_minter);
        EZRToken = new EZR(address(yousovAccessControlContract), address(userFactoryContract),matic,usdc,yousovAgregator,managerCOntroller);
        APW = new AgentPayrollWallet(address(EZRToken), address(yousovAccessControlContract),managerCOntroller);
    }

    function testClaimFreeEZRWithoutActivation() public {
     
        // expect agentPayrollWallet.claimFreeEZR() to revert when called by user4
        vm.prank(user4);
        vm.expectRevert(abi.encodePacked("YOUSOV : Not authorized to claim"));
        APW.claimFreeEZR();
    }

    function testFailClaimFreeEZRWithoutActivation() public {
     
        // expect agentPayrollWallet.claimFreeEZR() to revert when called by user4
        vm.prank(user4);
        APW.claimFreeEZR();
    }

    function testActivateTemporaryWallet() public {
        // expect user4 to not have TEMPORARY_YOUSOV_USER_ROLE before activation
        assertEq(yousovAccessControlContract.hasRole(TEMPORARY_YOUSOV_USER_ROLE, user4), false);

        // // activate user4's temporary wallet
        vm.startPrank(user4);
        APW.activateTemporaryWallet();
      
        // // expect user4 to have TEMPORARY_YOUSOV_USER_ROLE after activation
        assertEq(yousovAccessControlContract.hasRole(TEMPORARY_YOUSOV_USER_ROLE, user4), true);

        // expect agentPayrollWallet.claimFreeEZR() to revert when called by user4
        vm.expectRevert(abi.encodePacked("YOUSOV : Not authorized to claim"));
        APW.claimFreeEZR();

        // increase time and mine block to move past temporary wallet activation window
        // NOTE: depending on the actual implementation, the duration of the activation window and the way time is handled may be different
        // make sure to adjust this code accordingly
        uint activationWindowDuration = 96400;
        uint currentBlockTimestamp = block.timestamp;
        vm.warp(currentBlockTimestamp + activationWindowDuration);
        vm.roll(block.number + 1);

        // expect agentPayrollWallet.claimFreeEZR() to succeed when called by user4 after activation window has passed
        uint previousBalance = EZRToken.balanceOf(user4);
        APW.claimFreeEZR();
        // Expected user4 to have 0.5 EZR after claiming
        assertEq(EZRToken.balanceOf(user4), (previousBalance + 5 * 10**16));
        // Expected user4 to have 1 transaction after claiming
        assertEq(EZRToken.userTransactionsList(user4).length, 1);

        vm.stopPrank();
    }

    function testFailDoubleActivateTemporaryWallet() public {
        // expect user4 to not have TEMPORARY_YOUSOV_USER_ROLE before activation
        assertEq(yousovAccessControlContract.hasRole(TEMPORARY_YOUSOV_USER_ROLE, user4), false);
        // activate user4's temporary wallet
        vm.startPrank(user4);
        APW.activateTemporaryWallet();
        APW.activateTemporaryWallet();  // should revert
        vm.stopPrank();
    }

    function testCannotDoubleClaim() public {
        
        // activate user4's temporary wallet
        vm.startPrank(user4);
        APW.activateTemporaryWallet();
        // expect agentPayrollWallet.claimFreeEZR() to revert when called by user4
        vm.expectRevert(abi.encodePacked("YOUSOV : Not authorized to claim"));
        APW.claimFreeEZR();

        // increase time and mine block to move past temporary wallet activation window
        // NOTE: depending on the actual implementation, the duration of the activation window and the way time is handled may be different
        // make sure to adjust this code accordingly
        uint activationWindowDuration = 96400;
        uint currentBlockTimestamp = block.timestamp;
        vm.warp(currentBlockTimestamp + activationWindowDuration);
        vm.roll(block.number + 1);

        // expect agentPayrollWallet.claimFreeEZR() to succeed when called by user4 after activation window has passed
        uint previousBalance = EZRToken.balanceOf(user4);
        APW.claimFreeEZR();
        // Expected user4 to have 0.5 EZR after claiming
        assertEq(EZRToken.balanceOf(user4), (previousBalance + 5 * 10**16));
        // Expected user4 to have 1 transaction after claiming
        assertEq(EZRToken.userTransactionsList(user4).length, 1);

        // expect agentPayrollWallet.claimFreeEZR() to revert when called by user4 another time
        vm.expectRevert(abi.encodePacked("YOUSOV : Not authorized to claim"));
        APW.claimFreeEZR();
        // Expected user4 to still have 0.5 EZR after claiming
        assertEq(EZRToken.balanceOf(user4), (previousBalance + 5 * 10**16));
        // Expected user4 to still have 1 transaction after claiming
        assertEq(EZRToken.userTransactionsList(user4).length, 1);
        vm.stopPrank();
    }



}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "forge-std/src/Test.sol";
import "forge-std/Test.sol";

import "../../contracts/Users/UserFactory.sol";
import "./../../contracts/YousovAccessControl.sol";
import "../../contracts//YousovRoles.sol";
import "./../../contracts/interface/IYousovStructs.sol";
import "../../contracts/EZR/EZR.sol";
import "../../contracts/Users/UserUnicity.sol";
import "../../contracts/YousovForwarder.sol";


contract TestEZR is Test, YousovRoles{
    EZR ezr; 
    UserFactory public userFactoryContract;
    YousovAccessControl public yousovAccessControlContract;
    UserUnicity public userUnicity = new UserUnicity();
    YousovForwarder forwarder;

    address default_admin = vm.addr(1);
    address EZR_minter = vm.addr(2);
    address EZR_Pauser = vm.addr(3);
    address user4 = vm.addr(4);
 address matic = 0xEFE0797f5a14A53f5dc5E227060EcEF3934Eda1b ;
    address usdc = 0xA0374327EEAdfbA2c68346AC72E44c6B60F3cB6F ;
    address yousovAgregator= 0x5AD719C0BEC6559FA69f2b2F48e71b293c8B490C;
    address managerCOntroller = 0xcBDc0578ae9FFEe3bc605d6a037584d546562Dbe;


    function setUp() public {
        vm.label(default_admin, "default_admin");
        vm.label(EZR_minter, "EZR_minter");
        vm.label(EZR_Pauser, "EZR_Pauser");
        vm.label(user4, "user4");
        yousovAccessControlContract = new YousovAccessControl(default_admin, EZR_minter, EZR_Pauser);
        userFactoryContract = new UserFactory(
            address(yousovAccessControlContract),
            address(forwarder),
            address(userUnicity)
        );
        vm.prank(EZR_minter);
        ezr = new EZR(address(yousovAccessControlContract), address(userFactoryContract),matic,usdc,
yousovAgregator,managerCOntroller);
    }

    function test_constructor() public {
        assertEq(ezr.name(), "EZR");
        assertEq(ezr.symbol(), "EZR");
        assertEq(ezr.decimals(), 18);
        assertEq(ezr.totalSupply(), 1000000 * 10 ** 18);
        assertEq(ezr.balanceOf(EZR_minter), 1000000 * 10 ** 18);
        assertEq(ezr.balanceOf(user4), 0);
    }

    function test_mint() public {
        vm.prank(EZR_minter);
        uint256 amount = 1000;
        ezr.mint(user4, amount);
        assertEq(ezr.balanceOf(user4), amount);
    }

    function test_mint_not_authorized() public {
        uint256 amount = 1000;
        vm.prank(default_admin);
        yousovAccessControlContract.revokeRole(MINTER_ROLE, EZR_minter);
        vm.prank(EZR_minter);
        vm.expectRevert(abi.encodePacked("YOUSOV : Address not authorised to mint"));
        ezr.mint(EZR_minter, amount);
    }
    
    function test_pause_unpause() public {
        vm.prank(default_admin);
        yousovAccessControlContract.grantRole(PAUSER_ROLE, tx.origin);
        ezr.pause();
        assertEq(ezr.paused(), true);
        ezr.unpause();
        assertEq(ezr.paused(), false);
    }

    function testFail_pause() public {
        ezr.pause();
    }

    function testFail_unpause() public {
        vm.prank(default_admin);
        yousovAccessControlContract.grantRole(PAUSER_ROLE, tx.origin);
        ezr.pause();
        assertEq(ezr.paused(), true);
        yousovAccessControlContract.revokeRole(PAUSER_ROLE, tx.origin);
        ezr.unpause();
    }

    function test_whenPaused_before_and_after_transfer() public {
        vm.prank(default_admin);
        yousovAccessControlContract.grantRole(PAUSER_ROLE, tx.origin);
        ezr.pause();
        vm.prank(EZR_minter);
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        ezr.transfer(user4, 500);
    }

    /**
    @dev we test that our list stored the tx
    * there is two tx because we make a tx and we have the first one that is the token mint from the constructor
    */
    function testFuzz_before_and_after_transfer(uint16 _amount) public {
        vm.prank(EZR_minter);
        ezr.transfer(user4, _amount);

        // Verify that the transaction list is correct
        IYousovStructs.Transaction[] memory transactions = ezr.userTransactionsList(EZR_minter);
        assertEq(transactions.length, 2);

        //verify that the tx struct is correct
        IYousovStructs.Transaction memory transaction2 = transactions[1];
        assertEq(uint8(transaction2.transactionType), uint8(IYousovStructs.TransactionType.TRANSACTION_OUT));
        assertEq(transaction2.transactionDate, block.timestamp);
        assertEq(transaction2.amount, _amount);
        assertEq(transaction2.from, EZR_minter);
        assertEq(transaction2.to, user4);

        // Verify that the account balances are correct
        uint256 balanceAfter = ezr.balanceOf(EZR_minter);
        assertEq(balanceAfter, 1000000 * 10 ** 18 -_amount);
        uint _feesAmount = SafeMath.div(SafeMath.mul(10, _amount), 100);
        uint256 balanceAfter2 = ezr.balanceOf(user4);
        assertEq(balanceAfter2, _amount-_feesAmount);
    }
  

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "forge-std/src/Test.sol";
import "forge-std/Test.sol";
import {EZRContext} from "./../../contracts/EZR/EZRContext.sol";


/// @dev Allows to test functions that are set internal in the EZRContext by setting them external inside this contract
contract EZRContextHarness is EZRContext {
  function exposed_msgSender() external view returns (address) {
    return msgSender();
  }
  function exposed_msgData() external pure returns (bytes calldata) {
    return msgData();
  }
}

contract TestEZRContext is Test {
    EZRContext context;
    EZRContextHarness contextHarness; 

    function setUp() public {
        context = new EZRContext();
        contextHarness = new EZRContextHarness();
    }

    function testMsgSenderAsContract() public {
        // Create a mock contract to simulate msg.sender being a contract
        address mockContract = address(this);
        vm.prank(mockContract);
        // Verify that msgSender returns the tx.origin for contract callers
        assertEq(address(contextHarness.exposed_msgSender()), tx.origin, "msgSender should return tx.origin for contract callers");
    }

    function testMsgSenderAsUser() public {
        // Create a mock user to simulate msg.sender being a user
        address mockUser = address(0x1234567890123456789012345678901234567890);
        vm.prank(mockUser);
        assertEq(address(contextHarness.exposed_msgSender()), mockUser, "msgSender should return the sender of the message for user callers");
    }

    function testIsContract() public{
        address contractAddress = address(this);    
        bool contractAddress_res = context.isContract(contractAddress);
        assertEq(contractAddress_res, true, "isContract should return true for a contract address");
    }

    function testIsNotContract() public{
        address nonContractAddress = address(0x0);
        bool nonContractAddress_res = context.isContract(nonContractAddress);
        assertEq(nonContractAddress_res, false, "isContract should return false for a non-contract address");
    }

    function testIsContractV2() public {
        address addr1 = address(0x123);
        address addr2 = address(this);
        address addr3 = address(contextHarness);
        assertFalse(context.isContract(addr1), "isContract should return false for an EOA");
        assertTrue(context.isContract(addr2), "isContract should return true for a contract");
        assertTrue(context.isContract(addr3), "isContract should return true for a contract with code");
    }

    function test_msgData() public {
        bytes memory expected = abi.encodeWithSignature("exposed_msgData()");
        bytes memory result = contextHarness.exposed_msgData();
        assertTrue(result.length > 0, "msgData should return non-empty bytes");
        assertTrue(keccak256(result) == keccak256(expected), "msgData should return the correct data");
    }

}

// // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../lib/forge-std/src/Test.sol";
import "../../contracts/Controller/ManagerController.sol";
import "../../contracts/Controller/interface/IManagerController.sol";
import "./../../contracts/YousovAccessControl.sol";
import "../../contracts//YousovRoles.sol";
import "../../contracts/interface/IYousovStructs.sol";

contract ManagementAccessTest is Test, YousovRoles, IYousovStructs {

    ManagerController managementAccess;
    YousovAccessControl public yousovAccessControlContract;
    address default_admin = vm.addr(1);
    address EZR_minter = vm.addr(2);
    address EZR_Pauser = vm.addr(3);

    IManagerController public manager;

    VariablesInt[] variablesInt;
    VariablesDec[] variablesDec;
    VariablesString[] variablesString;
    VariablesBool[] variablesBool;

    function setUp() public {
        vm.label(default_admin, "default_admin");
        vm.label(EZR_minter, "EZR_minter");
        vm.label(EZR_Pauser, "EZR_Pauser");
        yousovAccessControlContract = new YousovAccessControl(default_admin, EZR_minter, EZR_Pauser);
        managementAccess = new ManagerController(address(yousovAccessControlContract),0xD44d5088f6eb0a0Aed56B2065478737030acEA94);
        manager = IManagerController(address(managementAccess));
        variablesInt.push(VariablesInt("minimumRecoveryPriceUsd", 60));
        variablesDec.push(VariablesDec("testRecoveryRewardRatio", 3000));
        variablesString.push(VariablesString("agentType", "auto"));
        variablesBool.push(VariablesBool("stakingRewardsPanic", true));
    }

    function test_updateVariables() public {
        vm.prank(default_admin);
        yousovAccessControlContract.grantRole(MANAGER_ROLE, tx.origin);
        manager.updateVariables(variablesInt, variablesDec, variablesString, variablesBool,0xD44d5088f6eb0a0Aed56B2065478737030acEA94 );
        assertEq(manager.getValueInt("minimumRecoveryPriceUsd"), 60);
        assertEq(manager.getValueDec("testRecoveryRewardRatio"), 3000);
        assertEq(manager.getValueString("agentType"), "auto");
        assertEq(manager.getValueBool("stakingRewardsPanic"), true);
    }

    function testManagerRole() public{
        vm.prank(default_admin);
        vm.expectRevert(abi.encodePacked("You dont have the rights to change variables"));
        manager.updateVariables(variablesInt, variablesDec, variablesString, variablesBool ,0xD44d5088f6eb0a0Aed56B2065478737030acEA94);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import "../../contracts/Recovery/RecoveryFactory.sol";
import "../../contracts/Recovery/Recovery.sol";
import "../../contracts/Users/UserFactory.sol";
import "../../contracts/Users/User.sol";
import "../../contracts/Users/UserUnicity.sol";
import "../../contracts/YousovAccessControl.sol";
import "../../contracts/YousovRoles.sol";
import "../../contracts/YousovForwarder.sol";
import "../../contracts/EZR/EZR.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RecoveryFactoryTest is Test, YousovRoles {
    RecoveryFactory public recoveryFactory;
    Recovery public recovery1;
    UserFactory public userFactory;
    YousovAccessControl public yousovAccessControlContract;
    EZR public ezr;
    UserUnicity public userUnicity = new UserUnicity();
    YousovForwarder forwarder;
    address managerCOntroller = 0xcBDc0578ae9FFEe3bc605d6a037584d546562Dbe;

    address default_admin = vm.addr(1);
    address relayer = vm.addr(123);
    address agentPayrollWallet = vm.addr(200);
    address EZR_minter = vm.addr(2);
    address EZR_Pauser = vm.addr(3);
    address treasury = address(0xD44d5088f6eb0a0Aed56B2065478737030acEA94);
    address user1 =
        vm.addr(
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        );
    address user2Temporary = vm.addr(0x5);
    address user3 = vm.addr(0x6);
    address user4 = vm.addr(0x7);
    address user5 = vm.addr(0x8);
    address user6 = vm.addr(0x9); // has not enough EZR
    address user7 = vm.addr(0x10);
    address user8 = vm.addr(0x11);
    address user9 = vm.addr(0x12);
    address user10 = vm.addr(0x13);
    address user11 = vm.addr(0x14);
    address user12 = vm.addr(0x15);
    address user13 = vm.addr(0x16);
    event RecoveryCreated(address currentAddress, address recoveryAddress);
    event LegalAgentsToNotify(
        address recovery,
        address[] legalSelectableAgents
    );

    //Recovery
    event AgentAddedToRecovery(address recoveryAddress,address user);
    event RecoveryReadyToStart(address userRecovery);
    event AgentAssignedAnswerForRecovery(address[] agents, address recovery);
    event SendAnswersToAnswerAgents(address[] agents, address recovery);
    event VaultAccessAccepted(address recoveryAddress);
    event VaultAccessDenied(address recoveryAddress);
    event RecoveryIsOver(address recovery);
address matic = stringToAddress("0xEFE0797f5a14A53f5dc5E227060EcEF3934Eda1b") ;
    address usdc = stringToAddress("0xA0374327EEAdfbA2c68346AC72E44c6B60F3cB6F") ;
    address yousovAgregator= stringToAddress("0x5AD719C0BEC6559FA69f2b2F48e71b293c8B490C");
   function stringToAddress(string memory _address) public pure returns (address) {
    bytes memory _addressBytes = bytes(_address);
    uint256 _addressLength = _addressBytes.length;
    require(_addressLength == 42, "Invalid address length");
    bytes memory _addressArray = new bytes(20);
    for (uint256 i = 0; i < 20; i++) {
        uint256 _hex = 16 * hexCharToUint(_addressBytes[2*i+2]) + hexCharToUint(_addressBytes[2*i+3]);
        _addressArray[i] = bytes1(uint8(_hex));
    }
    return address(bytes20(_addressArray));
}

function hexCharToUint(bytes1 _char) private pure returns (uint256) {
    if (_char >= 0x30 && _char <= 0x39) {
        return uint256(uint8(_char) - 48);
    }
    if (_char >= 0x41 && _char <= 0x46) {
        return uint256(uint8(_char) - 55);
    }
    if (_char >= 0x61 && _char <= 0x66) {
        return uint256(uint8(_char) - 87);
    }
    revert("Invalid hex character");
}
    function setUp() public {
        yousovAccessControlContract = new YousovAccessControl(
            default_admin,
            EZR_minter,
            EZR_Pauser
        );

        forwarder = new YousovForwarder(
            relayer,
            address(yousovAccessControlContract)
        );

        userFactory = new UserFactory(
            address(yousovAccessControlContract),
            address(forwarder),
            address(userUnicity)
        );

        vm.prank(EZR_minter);
        ezr = new EZR(
            address(yousovAccessControlContract),
            address(userFactory),matic,usdc,
yousovAgregator,managerCOntroller
        );
        vm.prank(EZR_minter);
        ezr.transfer(user1, 20 * 10 ** 18); //Warning: user1 receive 0.9 * 20 = 18, because 10% tax from wallet to wallet
        vm.prank(EZR_minter);
        ezr.transfer(user2Temporary, 50 * 10 ** 18);
        vm.prank(EZR_minter);
        ezr.transfer(user3, 30 * 10 ** 18);
        vm.prank(EZR_minter);
        ezr.transfer(user4, 30 * 10 ** 18);
        vm.prank(EZR_minter);
        ezr.transfer(user6, 10 * 10 ** 17); // not enough, user6 receive 0.9 EZR, so it should trigger error when doing recovery

        recoveryFactory = new RecoveryFactory(
            address(ezr),
            agentPayrollWallet,
            address(userFactory),
            address(yousovAccessControlContract),
            address(forwarder),managerCOntroller
        );

        newUserViaMetatxPseudo(
            user1,
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028,
            "testPseudo"
        );

        newUserViaMetatxPII(user3, 0x6, "uid3");
        newUserViaMetatxPseudo(user4, 0x7, "testPseudo4");
        newUserViaMetatxPseudo(user5, 0x8, "testPseudo5");
        newUserViaMetatxPseudo(user6, 0x9, "testPseudo6");
        newUserViaMetatxPseudo(user7, 0x10, "testPseudo7");
        newUserViaMetatxPseudo(user8, 0x11, "testPseudo8");
        newUserViaMetatxPseudo(user9, 0x12, "testPseudo9");
        newUserViaMetatxPseudo(user10, 0x13, "testPseudo10");

        vm.prank(default_admin);
        yousovAccessControlContract.grantRole(
            TEMPORARY_YOUSOV_USER_ROLE,
            user2Temporary   // icii it's not a real UserFactory User, just used for trying the TEMPORARY_YOUSOV_USER_ROLE for recovery 
        );
        uint256 recoveriesLength = recoveryFactory.yousovRecoveries().length;
        // vm.expectEmit();
        // emit RecoveryCreated(userPublicAddress, recoveryFactory.currentCreatedRecoveries(userPublicAddress));
        // iciiii, in previous emit, recoveryFactory.currentCreatedRecoveries(user1) has not the correct value before the execute function
        uint256 user1BalanceEZR = ezr.balanceOf(user1);
        uint256 agentPayrollWalletBalanceEZR = ezr.balanceOf(agentPayrollWallet);
        uint256 treasuryBalanceEZR = ezr.balanceOf(treasury);
        createRecoveryViaMetatx(
            user1,
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        );
        // yousovRecoveries() test
        assertEq(
            recoveryFactory.currentCreatedRecoveries(user1),
            recoveryFactory.yousovRecoveries()[recoveriesLength],
            "createRecovery didn't work well"
        );
        assertEq(
            ++recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );
        assertEq(
            recoveryFactory.yousovRecoveries()[recoveriesLength - 1],
            recoveryFactory.currentCreatedRecoveries(user1),
            "createRecovery didn't work well"
        );
        // test transfer EZR
        assertEq(user1BalanceEZR - 10 ** 18, ezr.balanceOf(user1));  // -1 EZR
        assertEq(agentPayrollWalletBalanceEZR + (5 * 10 ** 17) * 9 / 10, ezr.balanceOf(agentPayrollWallet)); // + 5% EZR * 0.9
        assertEq(treasuryBalanceEZR + ((2 * 10 ** 17) * 95 / 100) + ((5 * 10 ** 17) * 5 / 100), ezr.balanceOf(treasury)); // + 2% EZR * (0.9 + 0.05) + (5% EZR * 0.9) * 5%

        uint256 user2BalanceEZR = ezr.balanceOf(user2Temporary);
        agentPayrollWalletBalanceEZR = ezr.balanceOf(agentPayrollWallet);
        treasuryBalanceEZR = ezr.balanceOf(treasury);
        recovery1 = Recovery(recoveryFactory.currentCreatedRecoveries(user1));
        //recovery with temporary user
        createRecoveryViaMetatx(user2Temporary, 0x5);
        assertEq(
            recoveryFactory.currentCreatedRecoveries(user2Temporary),
            recoveryFactory.yousovRecoveries()[recoveriesLength],
            "createRecovery didn't work well"
        );
        assertEq(
            ++recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );
        assertEq(
            recoveryFactory.yousovRecoveries()[recoveriesLength - 1],
            recoveryFactory.currentCreatedRecoveries(user2Temporary),
            "createRecovery didn't work well"
        );
        // test transfer EZR
        assertEq(user2BalanceEZR - 10 ** 18, ezr.balanceOf(user2Temporary));  // -1 EZR
        assertEq(agentPayrollWalletBalanceEZR + (5 * 10 ** 17) * 9 / 10, ezr.balanceOf(agentPayrollWallet)); // + 5% EZR * 0.9
        assertEq(treasuryBalanceEZR + ((2 * 10 ** 17) * 95 / 100) + ((5 * 10 ** 17) * 5 / 100), ezr.balanceOf(treasury)); // + 2% EZR * (0.9 + 0.05) + (5% EZR * 0.9) * 5%

    }

    function testCreateRecoveryWithUnauthorizedCaller() public {
        vm.expectRevert(
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        vm.prank(user1, user1);
        recoveryFactory.createRecovery();
    }

    function testUserHasRecovery() public {
        assertTrue(recoveryFactory.userHasRecovery(user1));
        assertTrue(recoveryFactory.userHasRecovery(user2Temporary));
        assertFalse(recoveryFactory.userHasRecovery(user4));
    }

    // yousovActiveAgentsInRecoveries() is tested inside
    // test addActiveAgent and deleteActiveAgent
    function testAddActiveAgentAndDeleteActiveAgent() public {
        uint256 activeAgentsInRecoveries = recoveryFactory
            .yousovActiveAgentsInRecoveries()
            .length;
        recoveryFactory.addActiveAgent(
            user4,
            recoveryFactory.currentCreatedRecoveries(user1)
        );

        assertEq(
            user4,
            recoveryFactory.yousovActiveAgentsInRecoveries()[
                activeAgentsInRecoveries
            ]
        );
        assertEq(
            ++activeAgentsInRecoveries,
            recoveryFactory.yousovActiveAgentsInRecoveries().length
        );
        assertEq(
            recoveryFactory.actifAgentsRecoveries(user4),
            recoveryFactory.currentCreatedRecoveries(user1)
        );

        // deleteActiveAgent
        recoveryFactory.deleteActiveAgent(user4);
        assertEq(
            --activeAgentsInRecoveries,
            recoveryFactory.yousovActiveAgentsInRecoveries().length
        );
        assertFalse(
            recoveryFactory.actifAgentsRecoveries(user4) ==
                recoveryFactory.currentCreatedRecoveries(user1)
        );
    }

    struct InputData {
        address from;
        address to;
        bytes data; // correspond to encodedData
    }

    // For Metatx
    function buildRequest(
        InputData memory inputData
    ) public view returns (YousovForwarder.ForwardRequest memory) {
        uint256 nonce = forwarder.getNonce(inputData.from);
        YousovForwarder.ForwardRequest memory request = YousovForwarder
            .ForwardRequest(
                inputData.from,
                inputData.to,
                0,
                9e6,
                nonce,
                inputData.data
            );
        return request;
    }

    // For Metatx
    // return the signature of the transaction
    function signMetaTxRequest(
        YousovForwarder.ForwardRequest memory request,
        uint256 privateKey,
        address forwarderAddress
    ) public view returns (bytes memory) {
        bytes32 forwardRequestTypeHash = keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );
        bytes32 forwardRequestHash = keccak256(
            abi.encode(
                forwardRequestTypeHash,
                request.from,
                request.to,
                request.value,
                request.gas,
                request.nonce,
                keccak256(request.data)
            )
        );

        //from EIP712
        bytes32 domainTypeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 domainHash = keccak256(
            abi.encode(
                domainTypeHash,
                keccak256(bytes("YousovForwarder")),
                keccak256(bytes("0.0.1")),
                block.chainid,
                forwarderAddress
            )
        );
        bytes32 hashTypedDataV4 = ECDSA.toTypedDataHash(
            domainHash,
            forwardRequestHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hashTypedDataV4);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    //yousovRecoveries is tested inside
    //Via metatx
    function createRecoveryViaMetatx(
        address userPublicAddress,
        uint256 userPrivateKey
    ) public {
        bytes memory encodedData = abi.encodeWithSelector(
            recoveryFactory.createRecovery.selector
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(recoveryFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(inputData);
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
    }

    //Via metatx
    function testCreateRecoveryViaMetatx() public {
        uint256 recoveriesLength = recoveryFactory.yousovRecoveries().length;
        // don't create another recovery that is still not ended
        createRecoveryViaMetatx(user2Temporary, 0x5);
        assertEq(
            recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );

        // createRecovery for a PII user
        uint256 user3BalanceEZR = ezr.balanceOf(user3);
        uint256 agentPayrollWalletBalanceEZR = ezr.balanceOf(agentPayrollWallet);
        uint256 treasuryBalanceEZR = ezr.balanceOf(treasury);
        createRecoveryViaMetatx(user3, 0x6);
        assertEq(
            recoveryFactory.currentCreatedRecoveries(user3),
            recoveryFactory.yousovRecoveries()[recoveriesLength],
            "createRecovery didn't work well"
        );
        assertEq(
            ++recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );
        assertEq(
            recoveryFactory.yousovRecoveries()[recoveriesLength - 1],
            recoveryFactory.currentCreatedRecoveries(user3),
            "createRecovery didn't work well"
        );
        // test transfer EZR
        assertEq(user3BalanceEZR - 10 ** 18, ezr.balanceOf(user3));  // -1 EZR
        assertEq(agentPayrollWalletBalanceEZR + (5 * 10 ** 17) * 9 / 10, ezr.balanceOf(agentPayrollWallet)); // + 5% EZR * 0.9
        assertEq(treasuryBalanceEZR + ((2 * 10 ** 17) * 95 / 100) + ((5 * 10 ** 17) * 5 / 100), ezr.balanceOf(treasury)); // + 2% EZR * (0.9 + 0.05) + (5% EZR * 0.9) * 5%
        // user5 doesn't have EZR, expect recoveryFactory.yousovRecoveries().length to stay the same
        createRecoveryViaMetatx(user5, 0x8);
        assertEq(
            recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );

        // user6, not enough EZR
        uint256 user6BalanceEZR = ezr.balanceOf(user6);
        createRecoveryViaMetatx(user6, 0x9);
        assertEq(
            recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );
        // test transfer EZR
        assertEq(user6BalanceEZR, ezr.balanceOf(user6));  // keep the same amount of EZR
    }

    //Via metatx
    function getLegalSelectableAgentsViaMetatx(
        address userPublicAddress,
        uint256 userPrivateKey,
        address _currentRecovery
    ) public {
        bytes memory encodedData = abi.encodeWithSelector(
            recoveryFactory.getLegalSelectableAgents.selector,
            _currentRecovery
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(recoveryFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(inputData);
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
    }

    // Via Metatx
    function testGetLegalSelectableAgents() public {
        address currentRecovery = recoveryFactory.currentCreatedRecoveries(
            user1);
        
        uint256 currentRecoveryContenderAgentsLength = IRecovery(
            currentRecovery
        ).contenderAgentsList().length;
        
        // 8 because we created 9 users from UserFactory (-1 that is doing recovery)
        assertEq(
            currentRecoveryContenderAgentsLength, 8,
            "getLegalSelectableAgents didn't work well"
        );

        // create new users after the creation of previous recovery
        newUserViaMetatxPseudo(user11, 0x14, "testPseudo11");
        newUserViaMetatxPseudo(user12, 0x15, "testPseudo12");
        newUserViaMetatxPseudo(user13, 0x16, "testPseudo13");

        //test here getLegalSelectableAgents
        vm.expectRevert(
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        vm.prank(user1, user1);
        recoveryFactory.getLegalSelectableAgents(currentRecovery);

        getLegalSelectableAgentsViaMetatx(
            user1,
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028,
            currentRecovery
        );
        currentRecoveryContenderAgentsLength = IRecovery(currentRecovery)
            .contenderAgentsList()
            .length;
        // 11 because we created 9+3 users from UserFactory (-1 that is doing recovery)
        assertEq(
            currentRecoveryContenderAgentsLength,
            11,
            "getLegalSelectableAgents didn't work well"
        );

        uint256 recoveriesLength = recoveryFactory.yousovRecoveries().length;
        uint256 user3BalanceEZR = ezr.balanceOf(user3);
        uint256 agentPayrollWalletBalanceEZR = ezr.balanceOf(agentPayrollWallet);
        uint256 treasuryBalanceEZR = ezr.balanceOf(treasury);
        createRecoveryViaMetatx(user3, 0x6);
        assertEq(
            recoveryFactory.currentCreatedRecoveries(user3),
            recoveryFactory.yousovRecoveries()[2],
            "createRecovery didn't work well"
        );
        assertEq(
            ++recoveriesLength,
            recoveryFactory.yousovRecoveries().length,
            "createRecovery didn't work well"
        );
        assertEq(
            recoveryFactory.yousovRecoveries()[recoveriesLength - 1],
            recoveryFactory.currentCreatedRecoveries(user3),
            "createRecovery didn't work well"
        );
        // test transfer EZR
        assertEq(user3BalanceEZR - 10 ** 18, ezr.balanceOf(user3));  // -1 EZR
        assertEq(agentPayrollWalletBalanceEZR + (5 * 10 ** 17) * 9 / 10, ezr.balanceOf(agentPayrollWallet)); // + 5% EZR * 0.9
        assertEq(treasuryBalanceEZR + ((2 * 10 ** 17) * 95 / 100) + ((5 * 10 ** 17) * 5 / 100), ezr.balanceOf(treasury)); // + 2% EZR * (0.9 + 0.05) + (5% EZR * 0.9) * 5%
        

        currentRecovery = recoveryFactory.currentCreatedRecoveries(user3);
        currentRecoveryContenderAgentsLength = IRecovery(currentRecovery)
            .contenderAgentsList()
            .length;
        // 10 because we created 9 users + 3 users -user1 and -user3 that are performing recoveries
        assertEq(
            currentRecoveryContenderAgentsLength,
            10,
            "getLegalSelectableAgents didn't work well"
        );
    }











    /////////////////// Test Recovery  //////////////////////////

    // Via Metatx
    function callFunctionViaMetatx(
        address targetContractAddress,
        bytes memory encodedData,
        address userPublicAddress,
        uint256 userPrivateKey
    ) public {
        InputData memory inputData = InputData(
            userPublicAddress,
            targetContractAddress,
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(inputData);
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
    }

    function testCancelCurrentRecovery() public {
        vm.expectRevert(
            "YOUSOV : Operation not authorized, not the trustedForwarder"
        );
        vm.prank(user1, user1);
        recovery1.cancelCurrentRecovery();

        bytes memory cancelCurrentRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.cancelCurrentRecovery.selector
        );
        // this will not cancel the recovery1 of user1
        callFunctionViaMetatx(
            address(recovery1),
            cancelCurrentRecoveryEncodedData,
            user2Temporary,
            0x5
        );
        assertTrue(
            recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.CREATED
        );

        callFunctionViaMetatx(
            address(recovery1),
            cancelCurrentRecoveryEncodedData,
            user1,
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        );
        assertTrue(
            recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.CANCELED
        );
    }

    function testClearContenderAgents() public {
        vm.expectRevert("YOUSOV : Operation not authorized");
        vm.prank(user1, user1);
        recovery1.clearContenderAgents();
        // clearContenderAgents only used in getLegalSelectableAgents in userFactory, not "classically" checkable
    }

    function testAddContenderAgent() public {
        vm.expectRevert("YOUSOV : Operation not authorized");
        vm.prank(user1, user1);
        recovery1.addContenderAgent(user4);
        // addContenderAgent only used in getLegalSelectableAgents in userFactory, not "classically" checkable
    }

    function testContenderAgentsList() public {
        uint256 currentRecoveryContenderAgentsLength = recovery1
            .contenderAgentsList()
            .length;
        // 8 because we created 9 users from UserFactory (-1 that is doing recovery)
        assertEq(
            currentRecoveryContenderAgentsLength,
            8,
            "getLegalSelectableAgents didn't work well"
        );
    }

    function testGetRecoveryStatus() public {
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.CREATED);
    }

    // test addNewAgentToRecovery, deleteAgentFromRecovery, recoveryAgents(),  startTheRecovery(), agentCheckUserAnswer, isUserIsAnActifAgent
    function testIntegrationRecovery() public {
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.addNewAgentToRecovery();

        bytes memory addNewAgentToRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.addNewAgentToRecovery.selector
        );
        uint256 agentListLength = recovery1.recoveryAgents().length;
        address recovery1Address = address(recovery1);
        
        //test recoveryAgents
        // it should not work, user that perform recovery cannot be agent ! need to modify the smart contract
        // callFunctionViaMetatx(
        //     recovery1Address,
        //     addNewAgentToRecoveryEncodedData,
        //     user1,
        //     0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        // );
        // assertEq(
        //     ++agentListLength,
        //     recovery1.recoveryAgents().length,
        //     "addNewAgentToRecovery didn't work well"
        // );

        // test isUserIsAnActifAgent
        assertFalse(recovery1.isUserIsAnActifAgent(user4));
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user4);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user4,0x7);
        assertEq(recovery1.recoveryAgents()[agentListLength], user4, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        assertTrue(recovery1.isUserIsAnActifAgent(user4));

        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user5);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user5,0x8);
        assertEq(recovery1.recoveryAgents()[agentListLength], user5, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user6);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user6,0x9);
        assertEq(recovery1.recoveryAgents()[agentListLength], user6, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user7);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user7,0x10);
        assertEq(recovery1.recoveryAgents()[agentListLength], user7, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        
        vm.expectEmit();
        emit RecoveryReadyToStart(recovery1Address);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user8,0x11);
        assertEq(recovery1.recoveryAgents()[agentListLength], user8, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.READY_TO_START);

        // should not accept more agents than the number of challenges
        uint256 nbChallengesUser1 = User(userFactory.userContract(user1)).userChallenges().length;
        // recovery1.recoveryAgents().length should not be greater than nbChallengesUser1 after addNewAgentToRecovery
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user9,0x12);
        assertEq(nbChallengesUser1, recovery1.recoveryAgents().length, "addNewAgentToRecovery accepted more than nbChallenges agents");
        
        
        // deleteAgentFromRecovery
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user3, user3);
        recovery1.deleteAgentFromRecovery(user3);
        bytes memory deleteAgentFromRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.deleteAgentFromRecovery.selector, user3);
        
        agentListLength = recovery1.recoveryAgents().length;
        uint256 activeAgentsInRecoveriesLength = recoveryFactory.yousovActiveAgentsInRecoveries().length;

        // deleting an agent (user3) that is not in the recovery1 should not reduce recovery1.recoveryAgents().length
        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user3, 0x6);
        assertEq(agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting a not active agent");
        
        deleteAgentFromRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.deleteAgentFromRecovery.selector, user4);
        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user5, 0x8);
        assertEq(agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting an active agent is trying to delete another active agent");

        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user4, 0x7);
        assertEq(--agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting an active agent");
        assertEq(--activeAgentsInRecoveriesLength, recoveryFactory.yousovActiveAgentsInRecoveries().length, "deleteAgentFromRecovery didn't work well when deleting an active agent");
        assertTrue(recoveryFactory.actifAgentsRecoveries(user4) == address(0), "deleteAgentFromRecovery didn't work well when deleting an active agent");


        // testStartTheRecovery
        //add again the user that has been deleted
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user4,0x7);

            
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.startTheRecovery();

        bytes memory startTheRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.startTheRecovery.selector);
        
        // other user cannot start the recovery
        callFunctionViaMetatx(recovery1Address, startTheRecoveryEncodedData, user3, 0x6);
        assertTrue(recovery1.recoveryStatus() != IYousovStructs.RecoveryStatus.IN_PROGRESS);
        address[] memory agentList = recovery1.recoveryAgents();
        vm.expectEmit();
        emit AgentAssignedAnswerForRecovery(agentList, recovery1Address);
        callFunctionViaMetatx(recovery1Address, startTheRecoveryEncodedData, user1, 0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028);
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.IN_PROGRESS);


        // test sendRecoveryAnswerToAnswerAgent
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge(
            "questions1",
            "answers1",
            "my id1"
        );
        challenges[1] = IYousovStructs.Challenge(
            "questions2",
            "answers2",
            "my id2"
        );
        challenges[2] = IYousovStructs.Challenge(
            "questions3",
            "answers3",
            "my id3"
        );
        challenges[3] = IYousovStructs.Challenge(
            "questions4",
            "answers4",
            "my id4"
        );
        challenges[4] = IYousovStructs.Challenge(
            "questions5",
            "answers5",
            "my id5"
        );

        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.sendRecoveryAnswerToAnswerAgent(challenges);


        bytes memory sendRecoveryAnswerToAnswerAgentEncodedData = abi.encodeWithSelector(
            recovery1.sendRecoveryAnswerToAnswerAgent.selector,
            challenges
        );

        // other user cannot sendRecoveryAnswerToAnswerAgent
        callFunctionViaMetatx(recovery1Address, sendRecoveryAnswerToAnswerAgentEncodedData, user3, 0x6);
        string memory emptyString = "";
        string memory actualAnswer;
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user4);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user5);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user6);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user7);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user8);
        assertTrue(compareString(actualAnswer, emptyString));
        
        vm.expectEmit();
        emit SendAnswersToAnswerAgents(recovery1.recoveryAgents(), recovery1Address);
        callFunctionViaMetatx(recovery1Address, sendRecoveryAnswerToAnswerAgentEncodedData, user1, 0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028);
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user4);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user5);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user6);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user7);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user8);
        assertFalse(compareString(actualAnswer, emptyString));

        // test agentCheckUserAnswer
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user4, user4);
        recovery1.agentCheckUserAnswer(user4, true);

        bytes memory agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user4, true);

        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user4, 0x7);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user5, true);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user5, 0x8);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user6, true);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user6, 0x9);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user7, false);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user7, 0x10);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user8, false);
        // an agent cannot agentCheckUserAnswer on behalf of another agent
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user7, 0x10);

        uint256 activeAgentInRecoveries = recoveryFactory.yousovActiveAgentsInRecoveries().length;
        vm.expectEmit();
        emit VaultAccessAccepted(recovery1Address);
        vm.expectEmit();
        emit RecoveryIsOver(recovery1Address);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user8, 0x11);
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.OVER);
        assertTrue((activeAgentInRecoveries - 5) == recoveryFactory.yousovActiveAgentsInRecoveries().length);
    }

    // copy past of previous test: testIntegrationRecovery, but with access vault denied
    function testIntegrationRecoveryAccessVaultDenied() public {
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.addNewAgentToRecovery();

        bytes memory addNewAgentToRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.addNewAgentToRecovery.selector
        );
        uint256 agentListLength = recovery1.recoveryAgents().length;
        address recovery1Address = address(recovery1);
        
        //test recoveryAgents
        // it should not work, user that perform recovery cannot be agent ! need to modify the smart contract
        // callFunctionViaMetatx(
        //     recovery1Address,
        //     addNewAgentToRecoveryEncodedData,
        //     user1,
        //     0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        // );
        // assertEq(
        //     ++agentListLength,
        //     recovery1.recoveryAgents().length,
        //     "addNewAgentToRecovery didn't work well"
        // );

        // test isUserIsAnActifAgent
        assertFalse(recovery1.isUserIsAnActifAgent(user4));
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user4);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user4,0x7);
        assertEq(recovery1.recoveryAgents()[agentListLength], user4, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        assertTrue(recovery1.isUserIsAnActifAgent(user4));

        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user5);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user5,0x8);
        assertEq(recovery1.recoveryAgents()[agentListLength], user5, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user6);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user6,0x9);
        assertEq(recovery1.recoveryAgents()[agentListLength], user6, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        vm.expectEmit();
        emit AgentAddedToRecovery(recovery1Address, user7);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user7,0x10);
        assertEq(recovery1.recoveryAgents()[agentListLength], user7, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        
        vm.expectEmit();
        emit RecoveryReadyToStart(recovery1Address);
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user8,0x11);
        assertEq(recovery1.recoveryAgents()[agentListLength], user8, "addNewAgentToRecovery didn't work well");
        assertEq(++agentListLength, recovery1.recoveryAgents().length, "addNewAgentToRecovery didn't work well");
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.READY_TO_START);

        // should not accept more agents than the number of challenges
        uint256 nbChallengesUser1 = User(userFactory.userContract(user1)).userChallenges().length;
        // recovery1.recoveryAgents().length should not be greater than nbChallengesUser1 after addNewAgentToRecovery
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user9,0x12);
        assertEq(nbChallengesUser1, recovery1.recoveryAgents().length, "addNewAgentToRecovery accepted more than nbChallenges agents");
        
        
        // deleteAgentFromRecovery
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user3, user3);
        recovery1.deleteAgentFromRecovery(user3);
        bytes memory deleteAgentFromRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.deleteAgentFromRecovery.selector, user3);
        
        agentListLength = recovery1.recoveryAgents().length;
        uint256 activeAgentsInRecoveriesLength = recoveryFactory.yousovActiveAgentsInRecoveries().length;

        // deleting an agent (user3) that is not in the recovery1 should not reduce recovery1.recoveryAgents().length
        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user3, 0x6);
        assertEq(agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting a not active agent");
        
        deleteAgentFromRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.deleteAgentFromRecovery.selector, user4);
        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user5, 0x8);
        assertEq(agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting an active agent is trying to delete another active agent");

        callFunctionViaMetatx(recovery1Address, deleteAgentFromRecoveryEncodedData, user4, 0x7);
        assertEq(--agentListLength, recovery1.recoveryAgents().length, "deleteAgentFromRecovery didn't work well when deleting an active agent");
        assertEq(--activeAgentsInRecoveriesLength, recoveryFactory.yousovActiveAgentsInRecoveries().length, "deleteAgentFromRecovery didn't work well when deleting an active agent");
        assertTrue(recoveryFactory.actifAgentsRecoveries(user4) == address(0), "deleteAgentFromRecovery didn't work well when deleting an active agent");


        // testStartTheRecovery
        //add again the user that has been deleted
        callFunctionViaMetatx(
            recovery1Address,
            addNewAgentToRecoveryEncodedData,
            user4,0x7);

            
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.startTheRecovery();

        bytes memory startTheRecoveryEncodedData = abi.encodeWithSelector(
            recovery1.startTheRecovery.selector);
        
        // other user cannot start the recovery
        callFunctionViaMetatx(recovery1Address, startTheRecoveryEncodedData, user3, 0x6);
        assertTrue(recovery1.recoveryStatus() != IYousovStructs.RecoveryStatus.IN_PROGRESS);
        address[] memory agentList = recovery1.recoveryAgents();
        vm.expectEmit();
        emit AgentAssignedAnswerForRecovery(agentList, recovery1Address);
        callFunctionViaMetatx(recovery1Address, startTheRecoveryEncodedData, user1, 0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028);
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.IN_PROGRESS);


        // test sendRecoveryAnswerToAnswerAgent
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge(
            "questions1",
            "answers1",
            "my id1"
        );
        challenges[1] = IYousovStructs.Challenge(
            "questions2",
            "answers2",
            "my id2"
        );
        challenges[2] = IYousovStructs.Challenge(
            "questions3",
            "answers3",
            "my id3"
        );
        challenges[3] = IYousovStructs.Challenge(
            "questions4",
            "answers4",
            "my id4"
        );
        challenges[4] = IYousovStructs.Challenge(
            "questions5",
            "answers5",
            "my id5"
        );

        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user1, user1);
        recovery1.sendRecoveryAnswerToAnswerAgent(challenges);


        bytes memory sendRecoveryAnswerToAnswerAgentEncodedData = abi.encodeWithSelector(
            recovery1.sendRecoveryAnswerToAnswerAgent.selector,
            challenges
        );

        // other user cannot sendRecoveryAnswerToAnswerAgent
        callFunctionViaMetatx(recovery1Address, sendRecoveryAnswerToAnswerAgentEncodedData, user3, 0x6);
        string memory emptyString = "";
        string memory actualAnswer;
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user4);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user5);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user6);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user7);
        assertTrue(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user8);
        assertTrue(compareString(actualAnswer, emptyString));
        
        vm.expectEmit();
        emit SendAnswersToAnswerAgents(recovery1.recoveryAgents(), recovery1Address);
        callFunctionViaMetatx(recovery1Address, sendRecoveryAnswerToAnswerAgentEncodedData, user1, 0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028);
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user4);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user5);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user6);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user7);
        assertFalse(compareString(actualAnswer, emptyString));
        (, actualAnswer, , ,) = recovery1.answerAgentsDetails(user8);
        assertFalse(compareString(actualAnswer, emptyString));

        // test agentCheckUserAnswer
        vm.expectRevert("YOUSOV : Operation not authorized, not the trustedForwarder");
        vm.prank(user4, user4);
        recovery1.agentCheckUserAnswer(user4, true);

        bytes memory agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user4, true);

        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user4, 0x7);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user5, true);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user5, 0x8);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user6, false);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user6, 0x9);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user7, false);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user7, 0x10);
        agentCheckUserAnswerEncodedData = abi.encodeWithSelector(
            recovery1.agentCheckUserAnswer.selector, user8, false);
        // an agent cannot agentCheckUserAnswer on behalf of another agent
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user7, 0x10);

        uint256 activeAgentInRecoveries = recoveryFactory.yousovActiveAgentsInRecoveries().length;
        vm.expectEmit();
        emit VaultAccessDenied(recovery1Address);
        vm.expectEmit();
        emit RecoveryIsOver(recovery1Address);
        callFunctionViaMetatx(recovery1Address, agentCheckUserAnswerEncodedData, user8, 0x11);
        assertTrue(recovery1.recoveryStatus() == IYousovStructs.RecoveryStatus.OVER);
        assertTrue((activeAgentInRecoveries - 5) == recoveryFactory.yousovActiveAgentsInRecoveries().length);
    }



    //test isUserIsAnActifAgent

    // function testIsUserIsAnActifAgent() public {
    // }

    // function test() public {

    // }

    //////////////////////////////////////////////////////////////













    //////////////////// TestUserFactory functions ////////////////////////////////////
    //
    function getEncodedData(
        IYousovStructs.PII memory pii,
        IYousovStructs.Wallet memory wallet,
        IYousovStructs.Challenge[] memory challenges,
        string memory newPseudo,
        IYousovStructs.AccountType accountType,
        uint256 threashold
    ) public view returns (bytes memory) {
        bytes memory data = abi.encodeWithSelector(
            userFactory.newUser.selector,
            pii,
            wallet,
            challenges,
            newPseudo,
            accountType,
            threashold
        );

        return data;
    }

    //Via metatx
    function newUserViaMetatxPseudo(
        address userPublicAddress,
        uint256 userPrivateKey,
        string memory pseudo
    ) public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "",
            "",
            "",
            "",
            "",
            "",
            "my uid",
            90829232,
            IYousovStructs.Gender.FEMALE
        );
        IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
            userPublicAddress,
            "my wallet password",
            "zedadzadzada"
        );
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge(
            "questions1",
            "answers1",
            "my id1"
        );
        challenges[1] = IYousovStructs.Challenge(
            "questions2",
            "answers2",
            "my id2"
        );
        challenges[2] = IYousovStructs.Challenge(
            "questions3",
            "answers3",
            "my id3"
        );
        challenges[3] = IYousovStructs.Challenge(
            "questions4",
            "answers4",
            "my id4"
        );
        challenges[4] = IYousovStructs.Challenge(
            "questions5",
            "answers5",
            "my id5"
        );
        uint256 threashold = 3;

        bytes memory encodedData = getEncodedData(
            pii,
            wallet,
            challenges,
            pseudo,
            IYousovStructs.AccountType.PSEUDO,
            threashold
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(userFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(inputData);
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        // address[] memory userList = userFactory.yousovUserList();  //not enough memory in this test
        uint256 userListLength = userFactory.yousovUserList().length;
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        // userFactory.yousovUserList().length should be incremented by 1
        assertEq(
            ++userListLength,
            userFactory.yousovUserList().length,
            "newUserViaMetatxPseudo didn't work well"
        );
        assertEq(
            userFactory.yousovUserList()[userListLength - 1],
            userFactory.userContract(userPublicAddress),
            "newUserViaMetatxPseudo didn't work well"
        );
        yousovAccessControlContract.checkRole(
            YOUSOV_USER_ROLE,
            userPublicAddress
        );

        // Don't create the same pseudo user a second time
        // next request (nonce is updated in buildRequest function)
        request = buildRequest(inputData);
        signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        assertEq(
            userListLength,
            userFactory.yousovUserList().length,
            "newUserViaMetatxPseudo didn't work well, it should not create the same user a second time"
        );
    }

    //Via metatx
    function newUserViaMetatxPII(
        address userPublicAddress,
        uint256 userPrivateKey,
        string memory uid //for unique pii
    ) public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "my first name",
            "my middelName",
            "my lastName",
            "my cityOfBirth",
            "my countryOfBirth",
            "my countryOfCitizenship",
            uid,
            90829232,
            IYousovStructs.Gender.FEMALE
        );
        IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
            userPublicAddress,
            "my wallet password",
            "zedadzadzada"
        );
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](11);
        challenges[0] = IYousovStructs.Challenge(
            "questions1","answers1","my id1");
        challenges[1] = IYousovStructs.Challenge(
            "questions2","answers2","my id2");
        challenges[2] = IYousovStructs.Challenge(
            "questions3","answers3","my id3");
        challenges[3] = IYousovStructs.Challenge(
            "questions4","answers4","my id4");
        challenges[4] = IYousovStructs.Challenge(
            "questions5","answers5","my id5");
        challenges[5] = IYousovStructs.Challenge(
            "questions6","answers6","my id6");
        challenges[6] = IYousovStructs.Challenge(
            "questions7","answers7","my id7");
        challenges[7] = IYousovStructs.Challenge(
            "questions8","answers8","my id8");
        challenges[8] = IYousovStructs.Challenge(
            "questions9","answers9","my id9");
        challenges[9] = IYousovStructs.Challenge(
            "questions10","answers10","my id10");
        challenges[10] = IYousovStructs.Challenge(
            "questions11","answers11","my id11");
        uint256 threashold = 6;

        bytes memory encodedData = getEncodedData(
            pii,
            wallet,
            challenges,
            "", //pseudo
            IYousovStructs.AccountType.REGULAR,
            threashold
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(userFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(inputData);
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        uint256 userListLength = userFactory.yousovUserList().length;
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer

        // userFactory.yousovUserList().length should be incremented by 1
        assertEq(
            ++userListLength,
            userFactory.yousovUserList().length,
            "newUserViaMetatxRegular didn't work well"
        );
        assertEq(
            userFactory.yousovUserList()[userListLength - 1],
            userFactory.userContract(userPublicAddress),
            "newUserViaMetatxRegular didn't work well"
        );
        yousovAccessControlContract.checkRole(
            YOUSOV_USER_ROLE,
            userPublicAddress
        );

        // Don't create the same regular user a second time
        // next request (nonce is updated in buildRequest function)
        request = buildRequest(inputData);
        signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        assertEq(
            userListLength,
            userFactory.yousovUserList().length,
            "newUserViaMetatxPII didn't work well, it should not create the same user a second time"
        );
    }

    ///////////////////////////////////////////////////////////////////
    // Other functions

    function compareString(
        string memory string1,
        string memory string2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "../../contracts/YousovAccessControl.sol";
// import "../../contracts/Users/User.sol";
// import "../../contracts/Users/UserFactory.sol";
// import "../../contracts/Users/UserUnicity.sol";
// import "../../contracts/YousovRoles.sol";
// import "../../contracts/YousovForwarder.sol";
// import "../../lib/forge-std/src/Test.sol";

// contract UserTest is Test, YousovRoles {
//     User public userRegular;
//     User public userPseudo;
//     YousovAccessControl public yousovAccessControlContract;
//     UserUnicity public userUnicity = new UserUnicity();
//     YousovForwarder forwarder;
//     UserFactory userFactory;
//     address default_admin = vm.addr(1);
//     address relayer = vm.addr(123);
//     address EZR_minter = vm.addr(2);
//     address EZR_Pauser = vm.addr(3);
//     address user1 = vm.addr(4);
//     address user2 = vm.addr(5);
//     event SecretUpdated();
//     event PseudonymUpdated();
//     event PIIUpdated();
//     event ChallengesUpdated();
//     event WalletUpdated();
//     event AccountTypeUpdated();
//     event ThreasholdUpdated();
//     event StatusUpdated();
//     event UpdateUserIdentityFromPIIToPseudo();
//     event UpdateUserIdentityFromPseudoToPII();
    

//     function setUp() public {
//         yousovAccessControlContract = new YousovAccessControl(
//             default_admin,
//             EZR_minter,
//             EZR_Pauser
//         );

//         forwarder = new YousovForwarder(relayer, address(yousovAccessControlContract));
//         IYousovStructs.PII memory pii = IYousovStructs.PII(
//             "my first name",
//             "my middelName",
//             "my lastName",
//             "my cityOfBirth",
//             "my countryOfBirth",
//             "my countryOfCitizenship",
//             "my uid",
//             90829232,
//             IYousovStructs.Gender.FEMALE
//         );
//         IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
//             user1,
//             "my wallet password",
//             "zedadzadzada"
//         );
//         IYousovStructs.Challenge[]
//             memory challenges = new IYousovStructs.Challenge[](5);
//         challenges[0] = IYousovStructs.Challenge(
//             "questions1",
//             "answers1",
//             "my id1"
//         );
//         challenges[1] = IYousovStructs.Challenge(
//             "questions2",
//             "answers2",
//             "my id2"
//         );
//         challenges[2] = IYousovStructs.Challenge(
//             "questions3",
//             "answers3",
//             "my id3"
//         );
//         challenges[3] = IYousovStructs.Challenge(
//             "questions4",
//             "answers4",
//             "my id4"
//         );
//         challenges[4] = IYousovStructs.Challenge(
//             "questions5",
//             "answers5",
//             "my id5"
//         );
//         string memory pseudonym = "testPseudo";
//         IYousovStructs.AccountType accountType = IYousovStructs
//             .AccountType
//             .PSEUDO;
//         uint256 threashold = 3;

//         userPseudo = new User(
//             address(yousovAccessControlContract),
//             pii,
//             wallet,
//             challenges,
//             pseudonym,
//             accountType,
//             threashold,
//             address(userFactory)
//         );
// //         userRegular = new User(
// //             address(yousovAccessControlContract),
// //             pii,
// //             wallet,
// //             challenges,
// //             pseudonym,
// //             IYousovStructs.AccountType.REGULAR,
// //             threashold,
// //             address(userFactory)
// //         );
// //     }

//         userRegular = new User(
//             address(yousovAccessControlContract),
//             pii,
//             wallet,
//             challenges,
//             pseudonym,
//             IYousovStructs.AccountType.REGULAR,
//             threashold,
//             address(userFactory)
//         );
//     }
// //     function compareString(
// //         string memory string1,
// //         string memory string2
// //     ) public pure returns (bool) {
// //         return
// //             keccak256(abi.encodePacked(string1)) ==
// //             keccak256(abi.encodePacked(string2));
// //     }

//     function compareString(
//         string memory string1,
//         string memory string2
//     ) public pure returns (bool) {
//         return
//             keccak256(abi.encodePacked(string1)) ==
//             keccak256(abi.encodePacked(string2));
//     }

//     function comparePII(
//         IYousovStructs.PII memory pii1,
//         IYousovStructs.PII memory pii2
//     ) public pure returns (bool) {
//         return (keccak256(
//             abi.encodePacked(
//                 pii1.firstName,
//                 pii1.middelName,
//                 pii1.lastName,
//                 pii1.cityOfBirth,
//                 pii1.countryOfBirth,
//                 pii1.countryOfCitizenship,
//                 pii1.uid,
//                 pii1.birthDateTimeStamp,
//                 pii1.gender
//             )
//         ) ==
//             keccak256(
//                 abi.encodePacked(
//                     pii2.firstName,
//                     pii2.middelName,
//                     pii2.lastName,
//                     pii2.cityOfBirth,
//                     pii2.countryOfBirth,
//                     pii2.countryOfCitizenship,
//                     pii2.uid,
//                     pii2.birthDateTimeStamp,
//                     pii2.gender
//                 )
//             ));
//     }

//     function compareChallengesId(
//         string[] memory challengesId1,
//         string[] memory challengesId2
//     ) public pure returns (bool) {
//         if (challengesId1.length != challengesId2.length) {
//             return false;
//         }
//         for (uint i = 0; i < challengesId1.length; ++i) {
//             if (
//                 keccak256(abi.encodePacked(challengesId1[i])) !=
//                 keccak256(abi.encodePacked(challengesId2[i]))
//             ) {
//                 return false;
//             }
//         }
//         return true;
//     }

//     //compare single challenge details with another one
//     function compareChallengeDetails(
//         string memory question1, string memory answer1, string memory id1,
//         IYousovStructs.Challenge memory challengeDetails2
//     ) public pure returns (bool) {
//         return (
//             keccak256(abi.encodePacked(question1)) == keccak256(abi.encodePacked(challengeDetails2.question)) 
//             &&
//             keccak256(abi.encodePacked(answer1)) == keccak256(abi.encodePacked(challengeDetails2.answer)) 
//             &&
//             keccak256(abi.encodePacked(id1)) == keccak256(abi.encodePacked(challengeDetails2.id))
//         );
//     }

//     function compareAllChallenges(
//         User user,
//         IYousovStructs.Challenge[] memory challengesDetails2
//     ) public view returns (bool) {
//         // userPseudo
//         string[] memory userChallenges = user.userChallenges();
//         if (userChallenges.length != challengesDetails2.length) {
//             return false;
//         }
        
//         for (uint i = 0; i < userChallenges.length; ++i) {
//             (string memory question, string memory answer, string memory id) = user.challengeDetails(userChallenges[i]);
//             if(!compareChallengeDetails(question, answer, id, challengesDetails2[i])) {
//                 return false;
//             }
//         }
//         return true;
//     }

//     function testConstructorPseudo() public {
//         // Test pseudo account
//         assertTrue(
//             compareString(userPseudo.pseudonym(), "testPseudo"),
//             "Pseudo account : pseudonym is not correct in instanciation"
//         );
//         (
//             string memory firstName,
//             string memory middelName,
//             string memory lastName,
//             string memory cityOfBirth,
//             string memory countryOfBirth,
//             string memory countryOfCitizenship,
//             string memory uid,
//             uint256 birthDateTimeStamp,
//             IYousovStructs.Gender gender
//         ) = userPseudo.pii();
//         IYousovStructs.PII memory userPii = IYousovStructs.PII(
//             firstName,
//             middelName,
//             lastName,
//             cityOfBirth,
//             countryOfBirth,
//             countryOfCitizenship,
//             uid,
//             birthDateTimeStamp,
//             gender
//         );
//         IYousovStructs.PII memory pii = IYousovStructs.PII(
//             "",
//             "",
//             "",
//             "",
//             "",
//             "",
//             "",
//             0,
//             IYousovStructs.Gender.MALE
//         );
//         assertTrue(
//             comparePII(userPii, pii),
//             "Pseudo account : PII should be empty when the user register a pseudo account"
//         );
//     }

//     function testConstructorRegular() public {
//         // Test regular account
//         assertTrue(
//             compareString(userRegular.pseudonym(), ""),
//             "Regular account : pseudonym should be empty"
//         );
//         (
//             string memory firstName,
//             string memory middelName,
//             string memory lastName,
//             string memory cityOfBirth,
//             string memory countryOfBirth,
//             string memory countryOfCitizenship,
//             string memory uid,
//             uint256 birthDateTimeStamp,
//             IYousovStructs.Gender gender
//         ) = userRegular.pii();
//         IYousovStructs.PII memory userPii = IYousovStructs.PII(
//             firstName,
//             middelName,
//             lastName,
//             cityOfBirth,
//             countryOfBirth,
//             countryOfCitizenship,
//             uid,
//             birthDateTimeStamp,
//             gender
//         );
//         IYousovStructs.PII memory pii = IYousovStructs.PII(
//             "my first name",
//             "my middelName",
//             "my lastName",
//             "my cityOfBirth",
//             "my countryOfBirth",
//             "my countryOfCitizenship",
//             "my uid",
//             90829232,
//             IYousovStructs.Gender.FEMALE
//         );
//         assertTrue(
//             comparePII(userPii, pii),
//             "Regular account : PII is not correct"
//         );
//     }

//     // function testSetSecret() public {
//     //     string memory newSecret = "NewSecret";
//     //     vm.expectRevert("Yousov : Update not authorized");
//     //     userPseudo.setSecret(newSecret);
//     //     vm.prank(user1, user1);
//     //     vm.expectRevert("Yousov : Update not authorized");
//     //     userPseudo.setSecret(newSecret);
//     //     vm.prank(default_admin);
//     //     yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1);
//     //     vm.prank(default_admin);
//     //     yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2);
//     //     vm.expectRevert("Yousov : Update not authorized");
//     //     vm.prank(user2, user2);
//     //     userPseudo.setSecret(newSecret);

//     //     vm.expectEmit();
//     //     emit SecretUpdated();
//     //     vm.prank(user1, user1);
//     //     userPseudo.setSecret(newSecret);
//     //     assertTrue(
//     //         compareString(userPseudo.secret(), newSecret),
//     //         "setSecret didn't work"
//     //     );
//     // }

//     //this is a get function
//     function testUserChallenges() public {
//         string[] memory userChallenges = userPseudo.userChallenges(); // get the array of challenges id
//         string[] memory challengesId = new string[](5);
//         challengesId[0] = "my id1";
//         challengesId[1] = "my id2";
//         challengesId[2] = "my id3";
//         challengesId[3] = "my id4";
//         challengesId[4] = "my id11111";
//         assertFalse(compareChallengesId(userChallenges, challengesId));
//         challengesId[4] = "my id5";
//         assertTrue(compareChallengesId(userChallenges, challengesId));
//     }

//     function testSetChallenges() public {
//         IYousovStructs.Challenge[]
//             memory newChallenges = new IYousovStructs.Challenge[](5);
//         newChallenges[0] = IYousovStructs.Challenge(
//             "questions1",
//             "answers1",
//             "my id1"
//         );
//         newChallenges[1] = IYousovStructs.Challenge(
//             "questions2",
//             "answers2",
//             "my id2"
//         );
//         newChallenges[2] = IYousovStructs.Challenge(
//             "questions3",
//             "answers3",
//             "my id3"
//         );
//         newChallenges[3] = IYousovStructs.Challenge(
//             "questions4",
//             "answers4",
//             "my id4"
//         );
//         newChallenges[4] = IYousovStructs.Challenge(
//             "questions5",
//             "answers5",
//             "my id5"
//         );

//         assertTrue(compareAllChallenges(userPseudo, newChallenges), "initial challenges are not correct");
//         (uint256 userThreashold) = userPseudo.threashold();
//         assertEqUint(userThreashold, 3);


//         newChallenges[0] = IYousovStructs.Challenge(
//             "new questions1",
//             "new answers1",
//             "new my id1"
//         );

//         uint256 newThreashold = 5;
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setChallenges(newChallenges, newThreashold);
//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setChallenges(newChallenges, newThreashold);
        
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1);
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2);
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user2, user2);
//         userPseudo.setChallenges(newChallenges, newThreashold);

//         vm.expectEmit();
//         emit ChallengesUpdated();
//         vm.expectEmit();
//         emit ThreasholdUpdated();
//         vm.prank(user1, user1);
//         userPseudo.setChallenges(newChallenges, newThreashold);
//         (uint256 userThreasholdAfter) = userPseudo.threashold();
//         assertTrue(compareAllChallenges(userPseudo, newChallenges), "setChallenges didn't work");
//         assertEqUint(userThreasholdAfter, newThreashold);
//     }

//     function testSetPseudoym() public {
//         string memory newPseudonym = "newPseudonym";
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setPseudoym(newPseudonym);
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user1, user1);
//         userPseudo.setPseudoym(newPseudonym);
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); // need to grant role once again
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2);
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user2, user2);
//         userPseudo.setPseudoym(newPseudonym);

//         vm.prank(user1, user1);
//         vm.expectEmit();
//         emit PseudonymUpdated();
//         userPseudo.setPseudoym(newPseudonym);
        
//         assertTrue(
//             compareString(userPseudo.pseudonym(), newPseudonym),
//             "setPseudoym didn't work"
//         );

    
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user1, user1);
//         userRegular.setPseudoym(newPseudonym); //regular account cannot set pseudonym
//     }

//     function testSetPII() public {
//         (
//             string memory firstName,
//             string memory middelName,
//             string memory lastName,
//             string memory cityOfBirth,
//             string memory countryOfBirth,
//             string memory countryOfCitizenship,
//             string memory uid,
//             uint256 birthDateTimeStamp,
//             IYousovStructs.Gender gender
//         ) = userRegular.pii();
//         IYousovStructs.PII memory userPii = IYousovStructs.PII(
//             firstName,
//             middelName,
//             lastName,
//             cityOfBirth,
//             countryOfBirth,
//             countryOfCitizenship,
//             uid,
//             birthDateTimeStamp,
//             gender
//         );
//         IYousovStructs.PII memory pii = IYousovStructs.PII(
//             "my first name",
//             "my middelName",
//             "my lastName",
//             "my cityOfBirth",
//             "my countryOfBirth",
//             "my countryOfCitizenship",
//             "my uid",
//             90829232,
//             IYousovStructs.Gender.FEMALE
//         );
//         // Before setPII
//         assertTrue(
//             comparePII(userPii, pii), "Regular account : PII is not correct"
//         );


//         pii = IYousovStructs.PII(
//             "FIRSTNAME100",
//             "my middelName",
//              "LASTNAME100",
//             "my cityOfBirth",
//             "ITALY",
//             "my countryOfCitizenship",
//             "my uid",
//             123,
//             IYousovStructs.Gender.MALE
//         );
        
//         vm.expectRevert("Yousov : Update not authorized");
//         userRegular.setPII(pii);
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user1, user1);
//         userRegular.setPII(pii);
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user2, user2);
//         userRegular.setPII(pii);

//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user1, user1);
//         userPseudo.setPII(pii);   //user Pseudo cannot setPii
//         vm.expectEmit();
//         emit PIIUpdated();
//         vm.prank(user1, user1);
//         userRegular.setPII(pii);
//         // After setPII
//         (
//             string memory firstName2,
//             string memory middelName2,
//             string memory lastName2,
//             string memory cityOfBirth2,
//             string memory countryOfBirth2,
//             string memory countryOfCitizenship2,
//             string memory uid2,
//             uint256 birthDateTimeStamp2,
//             IYousovStructs.Gender gender2
//         ) = userRegular.pii();

//         IYousovStructs.PII memory userPiiAfter = IYousovStructs.PII(
//             firstName2,
//             middelName2,
//             lastName2,
//             cityOfBirth2,
//             countryOfBirth2,
//             countryOfCitizenship2,
//             uid2,
//             birthDateTimeStamp2,
//             gender2
//         );

//         assertTrue(
//             comparePII(userPiiAfter, pii), "setPII did't work"
//         );
//     }

//     function testSetWallet() public {
//         string memory oldPassword = "my wallet password";
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setWallet(oldPassword);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setWallet(oldPassword);

//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user2, user2);
//         userPseudo.setWallet(oldPassword);
//         vm.expectRevert("Yousov : Please do not use an already used password");
//         vm.startPrank(user1);
//         userPseudo.setWallet(oldPassword);

//         string memory newPassword;
//         string memory userPassword;

//         newPassword = "new password1";
//         vm.expectEmit();
//         emit WalletUpdated();
//         userPseudo.setWallet(newPassword);
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, newPassword), "setWallet didn't work");

//         newPassword = "new password2";
//         vm.expectEmit();
//         emit WalletUpdated();
//         userPseudo.setWallet(newPassword);
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, newPassword), "setWallet didn't work");

//         newPassword = "new password3";
//         vm.expectEmit();
//         emit WalletUpdated();
//         userPseudo.setWallet(newPassword);
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, newPassword), "setWallet didn't work");

//         newPassword = "new password4";
//         vm.expectEmit();
//         emit WalletUpdated();
//         userPseudo.setWallet(newPassword);
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, newPassword), "setWallet didn't work");

//         newPassword = "new password5";
//         vm.expectEmit();
//         emit WalletUpdated();
//         userPseudo.setWallet(newPassword);
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, newPassword), "setWallet didn't work");

//         vm.expectRevert("Yousov : Please do not use an already used password");
//         userPseudo.setWallet("new password1");

        
//         vm.expectEmit();
//         emit WalletUpdated();
//         // oldPassword should not be in the oldWalletPasswords array now
//         userPseudo.setWallet(oldPassword);
        
//         (, userPassword, ) = userPseudo.wallet();
//         assertTrue(compareString(userPassword, oldPassword), "setWallet didn't work");
//         vm.stopPrank();
//     }

//     function testSetThreashold() public {
//         uint256 newThreashold = 4;
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setThreashold(newThreashold);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.setThreashold(newThreashold);

//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 
//         vm.expectRevert("Yousov : Update not authorized");
//         vm.prank(user2, user2);
//         userPseudo.setThreashold(newThreashold);

//         vm.expectEmit();
//         emit ThreasholdUpdated();
//         vm.prank(user1, user1);
//         userPseudo.setThreashold(newThreashold);
//         uint256 userThreashold;
//         (userThreashold) = userPseudo.threashold();
//         assertTrue(userThreashold == newThreashold, "setThreashold didn't work");
//     }

//     function testGetWalletDetails() public {
//         IYousovStructs.Wallet memory userWallet = userPseudo.getWalletDetails();
//         string memory password = "my wallet password";
//         string memory privateKey = "zedadzadzada";
//         assertTrue(userWallet.publicAddr == user1, "getWalletDetails.publicAddr is not correct");
//         assertTrue(compareString(userWallet.walletPassword, password), "getWalletDetails.walletPassword is not correct");
//         assertTrue(compareString(userWallet.privateKey, privateKey), "getWalletDetails.privateKey is not correct");
//     }

//     function testGetAccountType() public {
//         IYousovStructs.AccountType userAccountType = userPseudo.getAccountType();
//         IYousovStructs.AccountType accountType = IYousovStructs.AccountType.PSEUDO;
//         assertTrue(userAccountType == accountType);
//     }

//     function testGetPII() public {
//         IYousovStructs.PII memory userPii = userRegular.getPII();
//         IYousovStructs.PII memory pii = IYousovStructs.PII(
//             "my first name",
//             "my middelName",
//             "my lastName",
//             "my cityOfBirth",
//             "my countryOfBirth",
//             "my countryOfCitizenship",
//             "my uid",
//             90829232,
//             IYousovStructs.Gender.FEMALE
//         );
//         assertTrue(comparePII(userPii, pii), "getPII didn't work");
//     }

//     function testUpdateUserAccountTypeFromPiiToPseudo() public {
//         string memory newPseudo = "my new pseudo";
//         vm.expectRevert("Yousov : Update not authorized");
//         userRegular.updateUserAccountTypeFromPiiToPseudo(newPseudo);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userRegular.updateUserAccountTypeFromPiiToPseudo(newPseudo);

//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 

//         vm.prank(user2, user2);
//         vm.expectRevert("Yousov : Update not authorized");
//         userRegular.updateUserAccountTypeFromPiiToPseudo(newPseudo);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         // pseudo user cannot updateUserAccountTypeFromPiiToPseudo
//         userPseudo.updateUserAccountTypeFromPiiToPseudo(newPseudo);

//         vm.expectEmit();
//         emit AccountTypeUpdated();
//         vm.expectEmit();
//         emit PseudonymUpdated();
//         vm.expectEmit();
//         emit UpdateUserIdentityFromPIIToPseudo();
//         vm.prank(user1, user1);
//         userRegular.updateUserAccountTypeFromPiiToPseudo(newPseudo);
//         assertTrue(compareString(userRegular.pseudonym(), newPseudo), "updateUserAccountTypeFromPiiToPseudo didn't work");
//         assertTrue(userRegular.accountType() == IYousovStructs.AccountType.PSEUDO);
//     }

//     function testUpdateUserAccountTypeFromPseudoToPii() public {
//         IYousovStructs.PII memory newPii = IYousovStructs.PII(
//             "my new first name",
//             "my new middelName",
//             "my new lastName",
//             "my new cityOfBirth",
//             "my new countryOfBirth",
//             "my new countryOfCitizenship",
//             "my new uid",
//             123,
//             IYousovStructs.Gender.OTHER
//         );
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.updateUserAccountTypeFromPseudoToPii(newPii);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.updateUserAccountTypeFromPseudoToPii(newPii);

//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 

//         vm.prank(user2, user2);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.updateUserAccountTypeFromPseudoToPii(newPii);

//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         // regular user cannot updateUserAccountTypeFromPseudoToPii
//         userRegular.updateUserAccountTypeFromPseudoToPii(newPii);

//         vm.expectEmit();
//         emit AccountTypeUpdated();
//         vm.expectEmit();
//         emit PIIUpdated();
//         vm.expectEmit();
//         emit UpdateUserIdentityFromPseudoToPII();
//         vm.prank(user1, user1);
//         userPseudo.updateUserAccountTypeFromPseudoToPii(newPii);
//         assertTrue(comparePII(userPseudo.getPII(), newPii), "updateUserAccountTypeFromPseudoToPii didn't work");
//         assertTrue(userPseudo.accountType() == IYousovStructs.AccountType.REGULAR);
//     }

//     function testCheckWalletPassword() public {
//         string memory password = "my wallet password efzjoizejfoijfeozufoieoi";
//         vm.expectRevert("Yousov : Wrong password");
//         userPseudo.checkWalletPassword(password);
//         password = "my wallet password";
//         IYousovStructs.Wallet memory wallet = userPseudo.checkWalletPassword(password);
//         assertTrue(wallet.publicAddr == user1);
//         assertTrue(compareString(wallet.walletPassword, password));
//         assertTrue(compareString(wallet.privateKey, "zedadzadzada"));
//     }

//     function testSwitchUserStatus() public {
//         IYousovStructs.UserStatus userStatus = userPseudo.userStatus();
//         assertTrue(userStatus == IYousovStructs.UserStatus.OPT_IN);

//         IYousovStructs.UserStatus newStatus = IYousovStructs.UserStatus.OPT_OUT;
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.switchUserStatus(newStatus);
//         vm.prank(user1, user1);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.switchUserStatus(newStatus);

//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user1); 
//         vm.prank(default_admin);
//         yousovAccessControlContract.grantRole(YOUSOV_USER_ROLE, user2); 
//         vm.prank(user2, user2);
//         vm.expectRevert("Yousov : Update not authorized");
//         userPseudo.switchUserStatus(newStatus);

//         vm.expectEmit();
//         emit StatusUpdated();
//         vm.prank(user1, user1);
//         userPseudo.switchUserStatus(newStatus);
//         assertTrue(userPseudo.userStatus() == newStatus);
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import "../../contracts/Users/UserFactory.sol";
import "../../contracts/Users/UserUnicity.sol";
import "../../contracts/Users/UserUnicity.sol";
import "../../contracts/YousovAccessControl.sol";
import "../../contracts/YousovRoles.sol";
import "../../contracts/YousovForwarder.sol";
import "../../contracts/EZR/EZR.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UserFactoryTest is Test, YousovRoles {
    UserFactory public userFactory;
    YousovAccessControl public yousovAccessControlContract;
    UserUnicity public userUnicity = new UserUnicity();
    YousovForwarder forwarder;
    address default_admin = vm.addr(1);
    address relayer = vm.addr(123);
    address EZR_minter = vm.addr(2);
    address EZR_Pauser = vm.addr(3);
    address user1PseudoForSetUp =
        vm.addr(
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028
        );
    address user2RegularForSetUp = vm.addr(0x5);
    address user3 = vm.addr(0x6);
    address user4 = vm.addr(0x7);
    address user5 = vm.addr(0x8);
    event UserCreated();
    event UserDeleted(address userDeletedAddress);
    // for event in YousovAccessControl (IAccessControl)
    // event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    // event RoleRevoked(bytes32 role, address account, address sender);


    function setUp() public {
        yousovAccessControlContract = new YousovAccessControl(
            default_admin,
            EZR_minter,
            EZR_Pauser
        );

        forwarder = new YousovForwarder(relayer, address(yousovAccessControlContract));
        userFactory = new UserFactory(
            address(yousovAccessControlContract),
            address(forwarder),
            address(userUnicity)
        );
        // Via metatx
        //Create pseudo user
        newUserViaMetatxPseudo(
            user1PseudoForSetUp,
            0x11e1deeb8f4fea396a8aa70e2d7494899cf92f6db23919288380b388c83ee028,
            "testPseudo"
        );
        //Create regular user
        newUserViaMetatxPII(user2RegularForSetUp, 0x5, "my uid");
    }

    function testYousovUserList() public {
        assertEq(userFactory.yousovUserList().length, 2, "testYousovUserList didn't work well");
        assertEq(userFactory.yousovUserList()[0], userFactory.userContract(user1PseudoForSetUp), "testYousovUserList didn't work well");
        assertEq(userFactory.yousovUserList()[1], userFactory.userContract(user2RegularForSetUp), "testYousovUserList didn't work well");
    }

    function testNewUserWithUnauthorizedCaller() public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "firstName",
            "middelName",
            "lastName",
            "cityOfBirth",
            "countryOfBirth",
            "countryOfCitizenship",
            "uid",
            block.timestamp,
            IYousovStructs.Gender.MALE
        );
        IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
            user1PseudoForSetUp,
            "my wallet password",
            "zedadzadzada"
        );
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge("question1", "answer1", "id1");
        challenges[1] = IYousovStructs.Challenge("question2", "answer2", "id2");
        challenges[2] = IYousovStructs.Challenge("question3", "answer3", "id3");
        challenges[3] = IYousovStructs.Challenge("question4", "answer4", "id4");
        challenges[4] = IYousovStructs.Challenge("question5", "answer5", "id5");
        string memory newPseudonym = "testPseudo";
        IYousovStructs.AccountType accountType = IYousovStructs
            .AccountType
            .PSEUDO;
        uint256 threshold = 3;

        vm.expectRevert("Yousov : Operation not authorized, not the trustedForwarder");
        // Call the newUser() function and expect a revert
        vm.prank(user1PseudoForSetUp);
        userFactory.newUser(
            pii,
            wallet,
            challenges,
            newPseudonym,
            accountType,
            threshold
        );
    }

    function getEncodedData(
        IYousovStructs.PII memory pii,
        IYousovStructs.Wallet memory wallet,
        IYousovStructs.Challenge[] memory challenges,
        string memory newPseudo,
        IYousovStructs.AccountType accountType,
        uint256 threashold
    ) public view returns (bytes memory) {
        bytes memory data = abi.encodeWithSelector(
            userFactory.newUser.selector,
            pii,
            wallet,
            challenges,
            newPseudo,
            accountType,
            threashold
        );

        return data;
    }

    struct InputData {
        address from;
        address to;
        bytes data; // correspond to encodedData
    }

    // For Metatx
    function buildRequest(
        InputData memory inputData
    ) public view returns (YousovForwarder.ForwardRequest memory) {
        uint256 nonce = forwarder.getNonce(inputData.from);
        YousovForwarder.ForwardRequest memory request = YousovForwarder
            .ForwardRequest(
                inputData.from,
                inputData.to,
                0,
                9e6,
                nonce,
                inputData.data
            );
        return request;
    }

    // For Metatx
    // return the signature of the transaction
    function signMetaTxRequest(
        YousovForwarder.ForwardRequest memory request,
        uint256 privateKey,
        address forwarderAddress
    ) public view returns (bytes memory) {
        bytes32 forwardRequestTypeHash = keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );
        bytes32 forwardRequestHash = keccak256(
            abi.encode(
                forwardRequestTypeHash,
                request.from,
                request.to,
                request.value,
                request.gas,
                request.nonce,
                keccak256(request.data)
            )
        );

        //from EIP712
        bytes32 domainTypeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 domainHash = keccak256(
            abi.encode(
                domainTypeHash,
                keccak256(bytes("YousovForwarder")),
                keccak256(bytes("0.0.1")),
                block.chainid,
                forwarderAddress
            )
        );
        bytes32 hashTypedDataV4 = ECDSA.toTypedDataHash(
            domainHash,
            forwardRequestHash
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hashTypedDataV4);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    //Via metatx
    function newUserViaMetatxPseudo(
        address userPublicAddress,
        uint256 userPrivateKey,
        string memory pseudo
    ) public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "",
            "",
            "",
            "",
            "",
            "",
            "my uid",
            90829232,
            IYousovStructs.Gender.FEMALE
        );
        IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
            userPublicAddress,
            "my wallet password",
            "zedadzadzada"
        );
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge(
            "questions1",
            "answers1",
            "my id1"
        );
        challenges[1] = IYousovStructs.Challenge(
            "questions2",
            "answers2",
            "my id2"
        );
        challenges[2] = IYousovStructs.Challenge(
            "questions3",
            "answers3",
            "my id3"
        );
        challenges[3] = IYousovStructs.Challenge(
            "questions4",
            "answers4",
            "my id4"
        );
        challenges[4] = IYousovStructs.Challenge(
            "questions5",
            "answers5",
            "my id5"
        );
        // IYousovStructs.AccountType accountType = 
        uint256 threashold = 3;

        bytes memory encodedData = getEncodedData(
            pii,
            wallet,
            challenges,
            pseudo,
            IYousovStructs
            .AccountType
            .PSEUDO,
            threashold
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(userFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(
            inputData
        );
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );
        
        uint256 userListLength = userFactory.yousovUserList().length;
        vm.expectEmit();
        emit UserCreated();
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        assertEq(++userListLength, userFactory.yousovUserList().length, "newUserViaMetatxPseudo didn't work well");
        assertEq(userFactory.yousovUserList()[userListLength-1], userFactory.userContract(userPublicAddress), "newUserViaMetatxPseudo didn't work well");
        yousovAccessControlContract.checkRole(YOUSOV_USER_ROLE, userPublicAddress);

        // Don't create the same pseudo user a second time
        // next request (nonce is updated in buildRequest function)
        request = buildRequest(inputData);
        signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        assertEq(userListLength, userFactory.yousovUserList().length, "newUserViaMetatxPseudo didn't work well, it should not create the same user a second time");

    }

    //Via metatx
    function testNewUserViaMetatxPseudo() public {
        newUserViaMetatxPseudo(user3, 0x6, "testPseudoUser3");
    }


    //Via metatx
    function newUserViaMetatxPII(
        address userPublicAddress,
        uint256 userPrivateKey,
        string memory uid   //for unique pii
    ) public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "my first name",
            "my middelName",
            "my lastName",
            "my cityOfBirth",
            "my countryOfBirth",
            "my countryOfCitizenship",
            uid,
            90829232,
            IYousovStructs.Gender.FEMALE
        );
        IYousovStructs.Wallet memory wallet = IYousovStructs.Wallet(
            userPublicAddress,
            "my wallet password",
            "zedadzadzada"
        );
        IYousovStructs.Challenge[]
            memory challenges = new IYousovStructs.Challenge[](5);
        challenges[0] = IYousovStructs.Challenge(
            "questions1",
            "answers1",
            "my id1"
        );
        challenges[1] = IYousovStructs.Challenge(
            "questions2",
            "answers2",
            "my id2"
        );
        challenges[2] = IYousovStructs.Challenge(
            "questions3",
            "answers3",
            "my id3"
        );
        challenges[3] = IYousovStructs.Challenge(
            "questions4",
            "answers4",
            "my id4"
        );
        challenges[4] = IYousovStructs.Challenge(
            "questions5",
            "answers5",
            "my id5"
        );
        uint256 threashold = 3;

        bytes memory encodedData = getEncodedData(
            pii,
            wallet,
            challenges,
            "",  //pseudo
            IYousovStructs
            .AccountType
            .REGULAR,
            threashold
        );

        InputData memory inputData = InputData(
            userPublicAddress,
            address(userFactory),
            encodedData
        );
        YousovForwarder.ForwardRequest memory request = buildRequest(
            inputData
        );
        bytes memory signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );

        uint256 userListLength = userFactory.yousovUserList().length;
        vm.expectEmit();
        emit UserCreated();
        
        // for the emit event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
        ////////////////iciii DOESN'T WORK//////////////////////////
        // vm.expectEmit();
        // emit RoleGranted(YOUSOV_USER_ROLE, userPublicAddress, address(userFactory)); 
        // account  = userPublicAddress et sender = userFactory ok 
        // YOUSOV_USER_ROLE not ok ???  need this bytes32 role or this bytes32 indexed role
        /////////////////////////////////////////////////////

        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        
        assertEq(++userListLength, userFactory.yousovUserList().length, "newUserViaMetatxPseudo didn't work well");
        assertEq(userFactory.yousovUserList()[userListLength-1], userFactory.userContract(userPublicAddress), "newUserViaMetatxPseudo didn't work well");
        yousovAccessControlContract.checkRole(YOUSOV_USER_ROLE, userPublicAddress);

        // Don't create the same regular user a second time
        // next request (nonce is updated in buildRequest function)
        request = buildRequest(inputData);
        signature = signMetaTxRequest(
            request,
            userPrivateKey,
            address(forwarder)
        );
        vm.prank(relayer, relayer); //relayer will pay the gas fee
        forwarder.execute(request, signature); // execute metatransaction from relayer
        assertEq(userListLength, userFactory.yousovUserList().length, "newUserViaMetatxPII didn't work well, it should not create the same user a second time");
    }

    //Via metatx
    function testNewUserViaMetatxPII() public {
        newUserViaMetatxPII(user4, 0x7, "my uid4");
    }

    function testCheckUnicity() public {
        IYousovStructs.PII memory pii = IYousovStructs.PII(
            "my first name",
            "my middelName",
            "my lastName",
            "my cityOfBirth",
            "my countryOfBirth",
            "my countryOfCitizenship",
            "my uid",
            90829232,
            IYousovStructs.Gender.FEMALE
        );

        address[] memory userList = userFactory.yousovUserList();

        //REGULAR exists
        (bool exists, address userContractAddr) = userFactory.checkUnicity(IYousovStructs.AccountType.REGULAR, pii, "");
        assertTrue(exists, "checkUnicity didn't work for regular");
        assertEq(userContractAddr, userList[1], "checkUnicity didn't work for regular");
        //PSEUDO exists
        (exists, userContractAddr) = userFactory.checkUnicity(IYousovStructs.AccountType.PSEUDO, pii, "testPseudo");
        assertTrue(exists, "checkUnicity didn't work for pseudo");
        assertEq(userContractAddr, userList[0], "checkUnicity didn't work for pseudo");
        //PSEUDO doesn't exists
        (exists, userContractAddr) = userFactory.checkUnicity(IYousovStructs.AccountType.PSEUDO, pii, "testPseudo djoizvhjoifez");
        assertFalse(exists, "checkUnicity didn't work for pseudo");
        assertEq(userContractAddr, address(0), "checkUnicity didn't work for pseudo");
        //REGULAR doesn't exists
        pii.firstName = "firstNameee";
        (exists, userContractAddr) = userFactory.checkUnicity(IYousovStructs.AccountType.REGULAR, pii, "testPseudo");
        assertFalse(exists, "checkUnicity didn't work for regular");
        assertEq(userContractAddr, address(0), "checkUnicity didn't work for regular");
    }

    function testDeleteUser() public {
        uint256 userListLength = userFactory.yousovUserList().length;
        vm.expectRevert("YOUSOV : User don't exist");
        vm.prank(user5, user5);
        userFactory.deleteUser();
        // should not delete any user
        assertEq(userListLength, userFactory.yousovUserList().length, "testDeleteUser didn't work");

        
        vm.expectEmit();
        emit UserDeleted(user1PseudoForSetUp);
        // for the emit RoleRevoked(role, account, _msgSender());
        ////////////////iciii DOESN'T WORK//////////////////////////
        // vm.expectEmit();
        // emit RoleRevoked(YOUSOV_USER_ROLE, user1PseudoForSetUp, address(userFactory));
        ///////////////////////////////////////////////
        vm.prank(user1PseudoForSetUp, user1PseudoForSetUp);
        userFactory.deleteUser();
        assertEq(userFactory.userContract(user1PseudoForSetUp), address(0), "deleteUser didn't work");

        vm.expectRevert(
            bytes(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(user1PseudoForSetUp),
                        " is missing role ",
                        Strings.toHexString(uint256(YOUSOV_USER_ROLE), 32)
                    )
                )
        );
        yousovAccessControlContract.checkRole(YOUSOV_USER_ROLE, user1PseudoForSetUp);

    }



}