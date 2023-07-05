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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "../utils/Context.sol";

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title ERC20 utility token contract from CretorsPRO ecosystem */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev third party ERC20 implementation
import {ERC20} from "./@openzeppelin/token/ERC20.sol";

///@dev security settings.
import {Security, IManagement} from "./Security.sol";

contract CreatorsCoin is ERC20, Security {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when REPUTATION_TOKEN burn fails.
    error CreatorsCoin__RepTokenBurnFailed();

    ///@dev error for when new repPerCRP is 0.
    error CreatorsCoin__InvalidRepPerCRP();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    ///@dev amount of REPUTATION_TOKEN for 1 CRP token
    uint256 private s_repPerCRP;

    uint256 private constant MAX_UINT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a swap is performed
        @param account: account that swapped tokens
        @param repTokenAmount: amount of REPUTATION_TOKEN swapped 
        @param CRPTokenAmount: resultant amount of CRP token after swap */
    event Swap(
        address indexed account,
        uint256 repTokenAmount,
        uint256 CRPTokenAmount
    );

    /** @dev event for when a new value for repPerCRP storage variable is set
        @param manager: manager address that called the function
        @param repPerCRP: new value for repPerCRP storage variable */
    event NewRepPerCRPSet(address indexed manager, uint256 repPerCRP);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @dev contract constructor. It also calls the costructors from ERC2o and Security contracts.
        @param management: CreatorsPRO management contract address */
    constructor(
        address management,
        uint256 repPerCRP
    ) ERC20("CreatorsPRO Token", "CRP") Security(management) {
        s_repPerCRP = repPerCRP;
    }

    /** @notice mints given amount of CRPREP tokens to given address.
        @dev _onlyAuthorized and _nonReentrant "modifiers" added. Function will return false if contract paused.
        @param to: address for which CRPREP tokens will be minted.
        @param amount: amount of CRPREP tokens to mint. */
    function mint(address to, uint256 amount) external {
        _onlyManagers();
        _whenNotPaused();
        _nonReentrant();

        _mint(to, amount);
        _approve(to, msg.sender, MAX_UINT);
        _approve(to, i_management.getMultiSig(), MAX_UINT);
        _approve(to, address(this), MAX_UINT);
    }

    /** @notice burns given amount of CRPREP tokens from given account address.
        @dev _onlyManagers and _nonReentrant "modifiers" added. Function will return false if contract paused.
        @param account: account address from which CRPREP tokens will be burned.
        @param amount: amount of CRPREP tokens to burn. */
    function burn(address account, uint256 amount) external {
        _onlyManagers();
        _whenNotPaused();
        _nonReentrant();

        _burn(account, amount);
    }

    /** @notice swaps given amount of REPUTATION_TOKEN for CRP.
        @dev _nonReentrant "modifier" added. Function will return false if contract paused.
        @param account: account address for which the swap will be transferred.
        @param amount: amount of REPUTATION_TOKEN tokens to swap. */
    function swap(address account, uint256 amount) public {
        _nonReentrant();
        _whenNotPaused();

        uint256 amountOfCRP = amount / s_repPerCRP;

        bool success = i_management
            .getTokenContract(IManagement.Coin.REPUTATION_TOKEN)
            .burn(account, amount);

        if (!success) {
            revert CreatorsCoin__RepTokenBurnFailed();
        }

        _mint(account, amountOfCRP);
        _approve(account, msg.sender, MAX_UINT);
        _approve(account, i_management.getMultiSig(), MAX_UINT);
        _approve(account, address(this), MAX_UINT);

        emit Swap(account, amount, amountOfCRP);
    }

    /** @notice swaps given amount of REPUTATION_TOKEN for CRP.
        @dev calls swap(address account, uint256 amount) public function.
        @param amount: amount of REPUTATION_TOKEN tokens to swap. */
    function swap(uint256 amount) public {
        swap(msg.sender, amount);
    }

    /** @notice swaps all callers balance of REPUTATION_TOKEN for CRP.
        @dev calls swap(uint256 amount) public function. */
    function swap() external {
        swap(
            i_management
                .getTokenContract(IManagement.Coin.REPUTATION_TOKEN)
                .balanceOf(msg.sender)
        );
    }

    /** @notice sets new value for repPerCRP storage variable.
        @dev _onlyManagers, _whenNotPaused, and _nonReentrant "modifiers" added.
        @param repPerCRP: new amount of REPUTATION_TOKEN equivalent to 1 CRP. */
    function setRepPerCRP(uint256 repPerCRP) external {
        _onlyManagers();
        _whenNotPaused();
        _nonReentrant();

        if (repPerCRP == 0) {
            revert CreatorsCoin__InvalidRepPerCRP();
        }

        s_repPerCRP = repPerCRP;

        emit NewRepPerCRPSet(msg.sender, repPerCRP);
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only managers
    are allowed to execute this function. */
    /// @inheritdoc Security
    function pause() public override(Security) {
        _onlyManagers();

        Security.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only managers 
    are allowed to execute this function. */
    /// @inheritdoc Security
    function unpause() public override(Security) {
        _onlyManagers();

        Security.unpause();
    }

    /// @dev modified function to return 6 instead of 18.
    /// @inheritdoc ERC20
    function decimals() public pure override(ERC20) returns (uint8) {
        return 6;
    }

    /** @notice reads the repPerCRP storage variable.       
        @return uint256 current value stored in repPerCRP variable */
    function getRepPerCRP() external view returns (uint256) {
        return s_repPerCRP;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the reward contract of CreatorsPRO NFTs */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICRPReward {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error CRPReward__NotAllowed();

    ///@dev error for when the input arrays have not the same length
    error CRPReward__InputArraysNotSameLength();

    ///@dev error for when time unit is zero
    error CRPReward__TimeUnitZero();

    ///@dev error for when there are no rewards
    error CRPReward__NoRewards();

    ///@dev error for when an invalid coin is given
    error CRPReward__InvalidCoin();

    ///@dev error for when an invalid collection is calling a function
    error CRPReward__InvalidCollection();

    ///@dev error for when new interaction points precision is 0
    error CRPReward__InteracPointsPrecisionIsZero();

    ///@dev error for when new max reward claim value is 0
    error CRPReward__InvalidMaxRewardClaimValue();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct to store important token infos
        @param index: index of the token ID in the tokenIdsPerUser mapping
        @param hashpower: CreatorsPRO hashpower
        @param characteristId: CreatorsPRO characterist ID */
    struct TokenInfo {
        uint256 index; // 0 is for no longer listed
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to store user's info
        @param index: user index in usersArray storage array
        @param score: sum of the hashpowers from the NFTs owned by the user
        @param points: sum of interactions points done by the user
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update 
        @param collections: array of collection addresses of the user's NFTs */
    struct User {
        uint256 index; // 0 is for address no longer a user
        uint256 score;
        uint256 points;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
        address[] collections;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct RewardCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when points are added/increased
        @param user: user address
        @param tokenId: ID of the token
        @param points: amount of points increased
        @param value: value added/subtracted */
    event PointsSet(
        address indexed user,
        uint256 indexed tokenId,
        uint256 points,
        uint256 value
    );

    /** @dev event for when a token has been removed from tokenInfo mapping for
    the given user address
        @param user: user address
        @param tokenId: ID of the token */
    event TokenRemoved(address indexed user, uint256 indexed tokenId);

    /** @dev event for when rewards are claimed
        @param caller: address of the function caller (user)
        @param amount: amount of reward tokens claimed */
    event RewardsClaimed(address indexed caller, uint256 amount);

    /** @dev event for when the hash object for the tokenId is set.
        @param manager: address of the manager that has set the hash object
        @param collection: address of the collection
        @param tokenId: array of IDs of ERC721 token
        @param hashpower: array of hashpowers set by manager
        @param characteristId: array of IDs of the characterist */
    event HashObjectSet(
        address indexed manager,
        address indexed collection,
        uint256[] indexed tokenId,
        uint256[] hashpower,
        uint256[] characteristId
    );

    /** @dev event for when a new reward condition is set
        @param caller: function caller address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    event NewRewardCondition(
        address indexed caller,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    );

    /** @dev event for when new interacion points precision is set
        @param manager: manager address
        @param precision: array of precision values */
    event InteracPointsPrecisionSet(
        address indexed manager,
        uint256[3] precision
    );

    /** @dev event for when new max reward claim value is set
        @param manager: manager address
        @param maxRewardClaim: value for maximum reward claim */
    event MaxRewardClaimSet(address indexed manager, uint256 maxRewardClaim);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param management: Management contract address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time
        @param interacPoints: array of interaction points for each interaction (0: min, 1: send transfer, 2: receive transfer)
        @param maxRewardClaim:  maximum amount of claimable rewards */
    function initialize(
        address management,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime,
        uint256[3] calldata interacPoints,
        uint256 maxRewardClaim
    ) external;

    /** @notice increases the user score by the given amount
        @param user: user address
        @param tokenId: ID of the token 
        @param value: value added/subtracted
        @param coin: coin of transfer
        @param isSell: bool that specifies if is selling (true) or not (false) */
    function setPoints(
        address user,
        uint256 tokenId,
        uint256 value,
        uint8 coin,
        bool isSell
    ) external;

    /** @notice removes given token ID from given user address
        @param user: user address
        @param tokenId: token ID to be removed 
        @param emitEvent: true to emit event (external call), false otherwise (internal call)*/
    function removeToken(
        address user,
        uint256 tokenId,
        bool emitEvent
    ) external;

    /** @notice claims rewards to the caller wallet */
    function claimRewards() external;

    /** @notice sets hashpower and characterist ID for the given token ID
        @param collection: collection address
        @param tokenId: array of token IDs
        @param hashPower: array of hashpowers for the token ID
        @param characteristId: array of characterit IDs */
    function setHashObject(
        address collection,
        uint256[] memory tokenId,
        uint256[] memory hashPower,
        uint256[] memory characteristId
    ) external;

    /** @notice sets new reward condition
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    function setRewardCondition(
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    ) external;

    /** @notice sets new interaction points precision
        @param precision: array of new precision values */
    function setInteracPointsPrecision(uint256[3] calldata precision) external;

    /** @notice sets new maximum value for rewards claim
        @param maxRewardClaim: value for maximum reward claim */
    function setMaxRewardClaim(uint256 maxRewardClaim) external;

    // --- From storage variables ---

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function getNextConditionId() external view returns (uint256);

    // /** @notice reads totalScore public storage variable
    //     @return uint256 value for the sum of scores from all CreatorsPRO users */
    // function totalScore() external view returns (uint256);

    /** @notice reads usersArray public storage array 
        @param index: index of the array
        @return address of a user */
    function getUsersArray(uint256 index) external view returns (address);

    /** @notice reads collectionIndex public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 value for the collection index in User struct */
    function getCollectionIndex(
        address user,
        address collection
    ) external view returns (uint256);

    /** @notice reads tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @param index: index value for token IDs array
        @return uint256 value for the token ID  */
    function getTokenIdsPerUser(
        address user,
        address collection,
        uint256 index
    ) external view returns (uint256);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection
        @return uint256 values for hashpower and characterist ID */
    function getHashObject(
        address collection,
        uint256 tokenId
    ) external view returns (uint256, uint256);

    /** @notice reads tokenInfo public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection 
        @return TokenInfo struct with token infos */
    function getTokenInfo(
        address collection,
        uint256 tokenId
    ) external view returns (TokenInfo memory);

    /** @notice reads users public storage mapping 
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUser(address user) external view returns (User memory);

    /** @notice reads users public storage mapping, but the values are updated
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUserUpdated(address user) external view returns (User memory);

    /** @notice reads rewardCondition public storage mapping 
        @return RewardCondition struct with current reward condition info */
    function getCurrentRewardCondition()
        external
        view
        returns (RewardCondition memory);

    /** @notice reads rewardCondition public storage mapping 
        @param conditionId: condition ID
        @return RewardCondition struct with reward condition info */
    function getRewardCondition(
        uint256 conditionId
    ) external view returns (RewardCondition memory);

    /** @notice reads all token IDs from the array of tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 array for the token IDs  */
    function getAllTokenIdsPerUser(
        address user,
        address collection
    ) external view returns (uint256[] memory);

    /** @notice reads interacPointsPrecision storage variable
        @return uint256[3] array with interaction points precision values */
    function getInteracPointsPrecision()
        external
        view
        returns (uint256[3] memory);

    /** @notice reads maxRewardClaim storage variable
        @return uint256 value for maximum allowed rewards claim */
    function getMaxRewardClaim() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC20 burnable contract */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Metadata} from "../@openzeppelin/token/IERC20Metadata.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC20Burnable is IERC20Metadata {
    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @notice mints given amount of tokens to given address.       
        @param to: address for which tokens will be minted.
        @param amount: amount of tokens to mint .
        @return bool that specifies if mint was successful (true) or not (false). */
    function mint(address to, uint256 amount) external returns (bool);

    /** @notice burns given amount tokens from given account address.      
        @param account: account address from which tokens will be burned
        @param amount: amount of tokens to burn
        @return bool that specifies if tokens burn was successful (true) or not (false) */
    function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the management contract from CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Burnable} from "./IERC20Burnable.sol";
import {ICRPReward} from "./ICRPReward.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IManagement {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error Management__NotAllowed();

    ///@dev error for when collection name is invalid
    error Management__InvalidName();

    ///@dev error for when collection symbol is invalid
    error Management__InvalidSymbol();

    ///@dev error for when the input is an invalid address
    error Management__InvalidAddress();

    ///@dev error for when the resulting max supply is 0
    error Management__FundMaxSupplyIs0();

    ///@dev error for when a token contract address is set for ETH/MATIC
    error Management__CannotSetAddressForETH();

    ///@dev error for when creator is corrupted
    error Management__CreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error Management__InvalidCollection();

    ///@dev error for when not the collection creator address calls function
    error Management__NotCollectionCreator();

    ///@dev error for when given address is not allowed creator
    error Management__AddressNotCreator();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the coin/token of transfer 
        @param ETH_COIN: ETH
        @param USD_TOKEN: a US dollar stablecoin        
        @param CREATORS_TOKEN: ERC20 token from CreatorsPRO
        @param REPUTATION_TOKEN: ERC20 token for reputation */
    enum Coin {
        ETH_COIN,
        USD_TOKEN,
        CREATORS_TOKEN,
        REPUTATION_TOKEN
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract   
        @param valuesLowQuota: array of values for the low class quota in ETH, USD token, and CreatorsPRO token
        @param valuesRegQuota: array of values for the regular class quota in ETH, USD token, and CreatorsPRO token 
        @param valuesHighQuota: array of values for the high class quota in ETH, USD token, and CreatorsPRO token 
        @param amountLowQuota: amount of low class quotas available 
        @param amountRegQuota: amount of low regular quotas available
        @param amountHighQuota: amount of low high quotas available 
        @param donationReceiver: address for the donation receiver 
        @param donationFee: fee value for the donation
        @param minSoldRate: minimum rate of sold quotas */
    struct CrowdFundParams {
        uint256[3] valuesLowQuota;
        uint256[3] valuesRegQuota;
        uint256[3] valuesHighQuota;
        uint256 amountLowQuota;
        uint256 amountRegQuota;
        uint256 amountHighQuota;
        address donationReceiver;
        uint256 donationFee;
        uint256 minSoldRate;
    }

    /** @dev struct used for store creators info
        @param escrow: escrow address for a creator
        @param isAllowed: defines if address is an allowed creator (true) or not (false) */
    struct Creator {
        address escrow;
        bool isAllowed;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event ArtCollection(
        address indexed collection,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator,
        address caller
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a creator address is set
        @param creator: the creator address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event CreatorSet(
        address indexed creator,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new beacon admin address for ERC721 art collection contract is set
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new multisig wallet address is set
        @param multisig: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed multisig, address indexed manager);

    /** @dev event for when a new royalty fee is set
        @param newFee: new royalty fee
        @param manager: the manager address that has done the setting */
    event NewFee(uint256 indexed newFee, address indexed manager);

    /** @dev event for when a creator address is set
        @param setManager: the manager address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event ManagerSet(
        address indexed setManager,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new token contract address is set
        @param manager: address of the manager that has set the hash object
        @param token: address of the token contract 
        @param coin: coin/token of the contract */
    event TokenContractSet(
        address indexed manager,
        address indexed token,
        Coin coin
    );

    /** @dev event for when a new ERC721 staking contract is instantiated
        @param staking: new ERC721 staking contract address
        @param creator: contract creator address 
        @param caller: caller address of the function */
    event CRPStaking(
        address indexed staking,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a creator's address is set to corrupted (true) or not (false) 
        @param manager: maanger's address
        @param creator: creator's address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    event CorruptedAddressSet(
        address indexed manager,
        address indexed creator,
        bool corrupted
    );

    /** @dev event for when a new beacon admin address for ERC721 staking contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminStaking(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new proxy address for reward contract is set 
        @param proxy: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewProxyReward(address indexed proxy, address indexed manager);

    /** @dev event for when a CreatorsPRO collection is set
        @param collection: collection address
        @param set: true if collection is from CreatorsPRO, false otherwise */
    event CollectionSet(address indexed collection, bool set);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param erc20USD: address of a stablecoin contract (USDC/USDT/DAI)
        @param multiSig: address of the Multisig smart contract
        @param fee: royalty fee */
    function initialize(
        address beaconAdminArt,
        address beaconAdminFund,
        address beaconAdminCreators,
        address erc20USD,
        address multiSig,
        uint256 fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
        @param owner: owner address of the collection */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty,
        address owner
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param owner: owner address of the collection
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        address owner,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSDC,
        uint256 priceInCreatorsCoin,
        string memory baseURI
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward
        @param owner: owner address of the collection */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime,
        address owner
    ) external;

    // --- Setter functions ---

    /** @notice sets creator permission.
        @param creator: creator address
        @param allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address creator, bool allowed) external;

    /** @notice sets manager permission.
        @param manager: manager address
        @param allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address manager, bool allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param beacon: new address */
    function setBeaconAdminArt(address beacon) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param beacon: new address */
    function setBeaconAdminFund(address beacon) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param beacon: new address */
    function setBeaconAdminCreators(address beacon) external;

    /** @notice sets new address for the Multisig smart contract.
        @param multisig: new address */
    function setMultiSig(address multisig) external;

    /** @notice sets new fee for NFT minting.
        @param fee: new fee */
    function setFee(uint256 fee) external;

    /** @notice sets new contract address for the given token 
        @param coin: coin/token for the given contract address
        @param token: new address of the token contract */
    function setTokenContract(Coin coin, address token) external;

    /** @notice sets given creator address to corrupted (true) or not (false)
        @param creator: creator address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    function setCorrupted(address creator, bool corrupted) external;

    /** @notice sets new beacon admin address for the ERC721 staking smart contract.
        @param beacon: new address */
    function setBeaconAdminStaking(address beacon) external;

    /** @notice sets new proxy address for the reward smart contract.
        @param proxy: new address */
    function setProxyReward(address proxy) external;

    /** @notice sets new collection address
        @param collection: collection address
        @param set: true (collection from CreatorsPRO) or false */
    function setCollections(address collection, bool set) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- Getter functions ---

    // --- From storage variables ---

    /** @notice reads beaconAdminArt storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function getBeaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function getBeaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function getBeaconAdminCreators() external view returns (address);

    /** @notice reads beaconAdminStaking storage variable
        @return address of the beacon admin for staking contract */
    function getBeaconAdminStaking() external view returns (address);

    /** @notice reads proxyReward storage variable
        @return address of the beacon admin for staking contract */
    function getProxyReward() external view returns (ICRPReward);

    /** @notice reads multiSig storage variable 
        @return address of the multisig wallet */
    function getMultiSig() external view returns (address);

    /** @notice reads fee storage variable 
        @return the royalty fee */
    function getFee() external view returns (uint256);

    /** @notice reads managers storage mapping
        @param caller: address to check if is manager
        @return boolean if the given address is a manager */
    function getManagers(address caller) external view returns (bool);

    /** @notice reads tokenContract storage mapping
        @param coin: coin/token for the contract address
        @return IERC20 instance for the given coin/token */
    function getTokenContract(Coin coin) external view returns (IERC20Burnable);

    /** @notice reads isCorrupted storage mapping 
        @param creator: creator address
        @return bool that sepcifies if creator is corrupted (true) or not (false) */
    function getIsCorrupted(address creator) external view returns (bool);

    /** @notice reads collections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if collection is from CreatorsPRO (true) or not (false)  */
    function getCollections(address collection) external view returns (bool);

    /** @notice reads stakingCollections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if staking collection is from CreatorsPRO (true) or not (false)  */
    function getStakingCollections(
        address collection
    ) external view returns (bool);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads creators storage mapping
        @param caller: address to check if is allowed creator
        @return Creator struct with creator info */
    function getCreator(address caller) external view returns (Creator memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Security settings for non-upgradeable smart contracts */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IManagement} from "./interfaces/IManagement.sol";

///@dev security settings.
import {Ownable} from "./@openzeppelin/access/Ownable.sol";
import {Pausable} from "./@openzeppelin/utils/Pausable.sol";
import {ReentrancyGuard} from "./@openzeppelin/security/ReentrancyGuard.sol";

/// -----------------------------------------------------------------------
/// Errors
/// -----------------------------------------------------------------------

///@dev error for when the crowdfund has past due data
error Security__NotAllowed();

///@dev error for when the collection/creator has been corrupted
error Security__CollectionOrCreatorCorrupted();

///@dev error for when ETH/MATIC transfer fails
error Security__TransferFailed();

///@dev error for when ERC20 transfer fails
error Security__ERC20TransferFailed();

///@dev error for when an invalid coin is used
error Security__InvalidCoin();

///@dev error for when given coin is ETH or REPUTATION_TOKEN
error Security__CreatorNotAllowed();

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract Security is Ownable, ReentrancyGuard, Pausable {
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    ///@dev Management contract
    IManagement internal immutable i_management;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    ///@dev internal function for whenNotPaused modifier
    function _whenNotPaused() internal view whenNotPaused {}

    ///@dev internal function for nonReentrant modifier
    function _nonReentrant() internal nonReentrant {}

    ///@dev internal function for onlyOwner modifier
    function _onlyOwner() internal view onlyOwner {}

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function _onlyManagers() internal view {
        if (!i_management.getManagers(msg.sender)) {
            revert Security__NotAllowed();
        }
    }

    ///@dev checks if caller is authorized
    function _onlyAuthorized() internal view virtual {
        if (!i_management.getIsCorrupted(owner())) {
            if (
                !(i_management.getManagers(msg.sender) ||
                    msg.sender == address(i_management) ||
                    msg.sender == owner())
            ) {
                revert Security__NotAllowed();
            }
        } else {
            if (
                !(i_management.getManagers(msg.sender) ||
                    msg.sender == address(i_management))
            ) {
                revert Security__NotAllowed();
            }
        }
    }

    ///@dev checks if collection/creator is corrupted
    function _notCorrupted() internal view virtual {
        if (i_management.getIsCorrupted(owner())) {
            revert Security__CollectionOrCreatorCorrupted();
        }
    }

    ///@dev checks if used coin is valid
    function _onlyValidCoin(IManagement.Coin coin) internal pure {
        if (
            coin == IManagement.Coin.ETH_COIN ||
            coin == IManagement.Coin.REPUTATION_TOKEN
        ) {
            revert Security__InvalidCoin();
        }
    }

    /// @dev checks if creator is still allowed
    function _isAllowedCreator() internal view virtual {
        if (!i_management.getCreator(owner()).isAllowed) {
            revert Security__CreatorNotAllowed();
        }
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    constructor(address management) {
        i_management = IManagement(management);
    }

    // --- Pause and Unpause functions ---

    /** @notice pauses the contract so that functions cannot be executed.
        Uses _pause internal function from PausableUpgradeable. */
    function pause() public virtual {
        _nonReentrant();

        _pause();
    }

    /** @notice unpauses the contract so that functions can be executed        
        Uses _pause internal function from PausableUpgradeable. */
    function unpause() public virtual {
        _nonReentrant();

        _unpause();
    }

    // --- Implemented functions ---

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferTo(address to, uint256 amount) internal virtual {
        (bool success, ) = payable(to).call{value: amount}("");

        if (!success) {
            revert Security__TransferFailed();
        }
    }

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to transfer
        @param from: transfer sender address
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferERC20To(
        IManagement.Coin coin,
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert Security__InvalidCoin();
        }

        bool success;
        if (from == address(this)) {
            success = i_management.getTokenContract(coin).transfer(to, amount);
        } else {
            success = i_management.getTokenContract(coin).transferFrom(
                from,
                to,
                amount
            );
        }

        if (!success) {
            revert Security__ERC20TransferFailed();
        }
    }

    /** @notice reads management public storage variable 
        @return IManagement instance of Management interface */
    function getManagement() external view returns (IManagement) {
        return i_management;
    }
}