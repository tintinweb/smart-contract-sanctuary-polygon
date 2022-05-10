/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;


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


// File contracts/child/MelalieStakingToken.sol

pragma solidity ^0.8.0;




contract MelalieStakingToken is ERC20, Ownable, Pausable
{
    using SafeMath for uint256;
    // matic / polygon
    address public childChainManagerProxy;
    address deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    constructor(string memory name, string memory symbol, address _childChainManagerProxy) ERC20(name, symbol) {
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }
    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
         require(_stake >= 1000000000000000000000, "Minimum of 1000 MEL for staking required");
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
        emit StakeCreated(msg.sender, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public whenNotPaused
    {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
        emit StakeRemoved(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) 
        public
        view
        returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder,uint256 _fees)
        public
        view
        returns(uint256)
    {
        return (stakes[_stakeholder] * _fees).div(totalStakes());
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards(uint256 _fees) 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_fees);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    /**
     * @notice 
     * A method to distribute rewards to all stakeholders from the contracts funds in MEL (a distribution pool)
     * Ideally we distribute everyday manually the same (or a slowly decreasing) amount until the pool is empty.
     * When we distribute pool MEL we burn it. The received rewards can be later on withdrawn by the staker.
     * In this moment the rewards get freshly minted to the user.
     * 
     * Remark: Distributing only every week or every month would make it necessary to check if a staker was staking his 
     * MEL the full month! We don't check this at the moment.   
     *  
     */
    function distributeRewardsAmountFromPool(uint256 _distributionAmount) 
        public
        onlyOwner
    {
        _burn(address(this), _distributionAmount);

        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice
     * A method to distribute rewards based on a percentage per year too all stakeholders from the contracts funds in MEL (the distribution pool)
     * We should distribute it daily, by manually calling this method (e.g. browser frontend) e.g. 10% 
     * The percentage ist divided by 360 this is the daily percentage. 
     * 
     * We distribute then from the current total stakes the daily percentage.
     * Before we distribute the amount we burn the tokens since the rewards get minted when they get withdrawn.
     * 
     */
    function distributeRewardsPercentageFromPool(uint256 _percentagePerYear) 
        public
        onlyOwner
    {   
        uint256 _distributionAmount = (totalStakes() * _percentagePerYear).div(360*100);

        _burn(address(this), _distributionAmount);

        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() 
        public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
        emit RewardWithdrawn(msg.sender,reward);
    }
    /**
    * @notice The owner of this smart conectract should be able to mint new MelalieToken anytime.
    */
    // function mintToken (address _account,uint256 supply) public onlyOwner {
    //     _mint(_account, supply);
    // }

    /**
     *  @notice The owner of this smart contract should be able to transfer MelalieToken to any other address  
     */
    function transferToken (address sender,address recipient,uint256 amount) public onlyOwner {
        _transfer(sender, recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH to any other address from this smart contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/child/MelalieDistributionPool.sol

pragma solidity ^0.8.0;

contract MelalieDistributionPool  {

    receive() payable external {}
    

}


// File contracts/child/MelalieStakingTokenUpgradable.sol

pragma solidity ^0.8.0;





contract MelalieStakingTokenUpgradable is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    /**
     * @notice initialize function of the upgradable contract 
     */
    function initialize(string memory name,string memory symbol, address _childChainManagerProxy) initializer public {
       __ERC20_init(name, symbol);
       __Ownable_init();
       __Pausable_init();
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;
        minimumStake = 1000000000000000000000;
        distributionPoolContract = address(0);
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        require(msg.sender == deployer, "You're not allowed");
        distributionPoolContract = _distributionPoolContract;
    }

   /**
    * @notice as the token bridge calls this function, 
    * we mint the amount to the users balance and 
    * immediately creating a stake with this amount.
    * The letter function is getting removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        createStake(user,amount);
    }

   /**
    * Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");
        
        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake. Amount gets unlocked from this contract
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public whenNotPaused
    { 
        require(_stake >= minimumStake, "Minimum Stake not reached");
        stakes[msg.sender] = stakes[msg.sender].sub(_stake); //if unstake amount is negative an error is thrown
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        //when removing a stake we unlock the stake from this contract and give it back to the owner 
        _transfer(address(this), msg.sender, _stake);
        emit StakeRemoved(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _amount The amount to be distributed
     */
    function calculateReward(address _stakeholder,uint256 _amount)
        public
        view
        returns(uint256)
    {
        return (stakes[_stakeholder] * _amount).div(totalStakes());
    }

    /**
     * @notice
     * A method to distribute rewards based on a percentage per year too all stakeholders from the contracts funds in MEL (the distribution pool)
     * We should distribute it daily, by manually calling this method (e.g. browser frontend) e.g. 10% 
     * The percentage ist divided by 360 this is the daily percentage. 
     * 
     * We distribute then from the current total stakes the daily percentage.
     * Before we distribute the amount we burn the tokens since the rewards get minted when they get withdrawn.
     * 
     */
    function distributeRewardsPercentageFromPool(uint256 _percentagePerYear) 
        public onlyOwner whenNotPaused
    {   
        uint256 _distributionAmount = (totalStakes() * _percentagePerYear).div(360*100);
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
        _transfer(distributionPoolContract, msg.sender, reward);

        rewards[msg.sender] = 0;
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken to any other address
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner whenNotPaused {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH to any other address from this smart contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner whenNotPaused{
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File contracts/child/MelalieStakingTokenUpgradableV2.sol

pragma solidity ^0.8.0;





contract MelalieStakingTokenUpgradableV2 is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    //new variable v2
    bool private _upgradedV2;
    address rewardDistributor;
    bool public autostake;

    /**
     * @notice initialize function of the upgradable contract 
     */
    function initialize(string memory name,string memory symbol, address _childChainManagerProxy) initializer public {
       __ERC20_init(name, symbol);
       __Ownable_init();
       __Pausable_init();
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;
        minimumStake = 1000000000000000000000;
        distributionPoolContract = address(0);
    }

    function upgrade() public {
        require(!_upgradedV2, "MelalieStakingTokenUpgradableV2: already upgraded");
        _upgradedV2 = true;
        rewardDistributor = msg.sender;

        /*
        1. distributionPoolContract should contain following amounts: 
                - total stakes (old contract was: 1086026210091837526600000 / new contract is: 1065797210091837526600000)
                - total rewards (old contract was     794063807637144565908)
                - total balances (old contract was at block 17386211: 1815457759082812094567 MEL <-- without 0x6e and other exiters!
                - sum of old distribution pool 2998342.392799415984103501 should be 3.000.000 = totalDistributions+balanceOf(0x1F70A6Ebe74f202d1eC02124A7179fa7CE0D122f) )

        2. Upgrade the contract 
                -  initialize stakes, rewards of all accounts without exits (all except: 
                            0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E, 
                            0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c, 
                            0x1F70A6Ebe74f202d1eC02124A7179fa7CE0D122f,
                            0xB94a1473F2C418AAa06bf664C76D13685c559362 - has still registered rewards 
                -  transfer stake amount of all acounts to staking contract (where it gets locked)
                -  transfer all account balances back from distributionPool (which holds those funds too)

        3. initialize totalDistributions
                - either get all distribut events or 
                - red this variable from smart contract

        totalDistributions = 
        4. transfer stakes from distributionContract to Melalieaddress(this)
        5. transfer account balances from distributionContract bac to the acccounts 
        6. execute missing (19) distributions since #RewardDistribution 4 / 2021-07-23 
                   /* Distributed MEL: 534 
                    REST POOL: 2.998.342  MEL 
                    TOTAL STAKES: 1.924.368 MEL
                    https://polygonscan.com/tx/0x8c1110f697d01cccaaad01d2fd799b609494ba58e0b3a5b3c489421434913684 */
    
        ///7. implement the autotask with defender */
        sendMelFromDistributionPool(distributionPoolContract,2998342392799415984103501); //2.998 Million MEL to distribution contract

        // addStakeholder(0xB94a1473F2C418AAa06bf664C76D13685c559362);
        rewards[address(0xB94a1473F2C418AAa06bf664C76D13685c559362)] =  2108333333333333333; //stake and belance withdrawn - only rewards
        
        addStakeholder(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c);   
        stakes[address(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c)] =   1290284042557023600000; //token owner account which discovered and handeld the recovery of v1 
        rewards[address(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c)] =     1433760047285581776;
        sendMelFromDistributionPool(address(this),1290284042557023600000);

    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  12639.0
    addStakeholder(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC);
    stakes[address(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC)] = 12639000000000000000000;
    sendMelFromDistributionPool(address(this),12639000000000000000000);
    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  14.043333333333333332
    rewards[address(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC)] = 14043333333333333332;
    //0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC  0.091456440198947603
    sendMelFromDistributionPool(0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC,91456440198947603);

    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  89928.9792489785
    addStakeholder(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2);
    stakes[address(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2)] = 89928979248978500000000;
    sendMelFromDistributionPool(address(this),89928979248978500000000);
    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  99.921088054420555552
    rewards[address(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2)] = 99921088054420555552;
    //0xB8b58B248e975A76d147404454F6aA07d2A4E3e2  0.000000000002449489
    sendMelFromDistributionPool(0xB8b58B248e975A76d147404454F6aA07d2A4E3e2,2449489);

    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1000.0
    addStakeholder(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5);
    stakes[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 1000000000000000000000;
    sendMelFromDistributionPool(address(this),1000000000000000000000);
    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1.111111111111111108
    rewards[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 1111111111111111108;
    //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  1000.0
    sendMelFromDistributionPool(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5,1000000000000000000000);

    //0xF95720db004d94922Abb904222f02bc0793b589d  4000.0
    addStakeholder(0xF95720db004d94922Abb904222f02bc0793b589d);
    stakes[address(0xF95720db004d94922Abb904222f02bc0793b589d)] = 4000000000000000000000;
    sendMelFromDistributionPool(address(this),4000000000000000000000);
    //0xF95720db004d94922Abb904222f02bc0793b589d  4.444444444444444444
    rewards[address(0xF95720db004d94922Abb904222f02bc0793b589d)] = 4444444444444444444;

    //0x3d2596AEDCfef405F04eb78C38426113d19AADda  300000.0
    addStakeholder(0x3d2596AEDCfef405F04eb78C38426113d19AADda);
    stakes[address(0x3d2596AEDCfef405F04eb78C38426113d19AADda)] = 300000000000000000000000;
    sendMelFromDistributionPool(address(this),300000000000000000000000);
    //0x3d2596AEDCfef405F04eb78C38426113d19AADda  249.999999999999999999
    rewards[address(0x3d2596AEDCfef405F04eb78C38426113d19AADda)] = 249999999999999999999;
    //0x90e0C41B5B4B769e78c740b5f0F11E61cfbDD5F9  7056.0
    sendMelFromDistributionPool(0x90e0C41B5B4B769e78c740b5f0F11E61cfbDD5F9,7056000000000000000000);
    //0xF32719Bd3683Ba776fE060B0a216B6f95Acd2805  102290.796548951105460435
    sendMelFromDistributionPool(0xF32719Bd3683Ba776fE060B0a216B6f95Acd2805,102290796548951105460435);

    //0xde9a65d3F549EDD70163795479a7c88d13DbB15C  7589.0
    addStakeholder(0xde9a65d3F549EDD70163795479a7c88d13DbB15C);
    stakes[address(0xde9a65d3F549EDD70163795479a7c88d13DbB15C)] = 7589000000000000000000;
    sendMelFromDistributionPool(address(this),7589000000000000000000);
    //0xde9a65d3F549EDD70163795479a7c88d13DbB15C  8.43222222222222222
    rewards[address(0xde9a65d3F549EDD70163795479a7c88d13DbB15C)] = 8432222222222222220;

    //0xEE02C646939F0d518a6C1DF19DCec96145347Af4  5295.0
    addStakeholder(0xEE02C646939F0d518a6C1DF19DCec96145347Af4);
    stakes[address(0xEE02C646939F0d518a6C1DF19DCec96145347Af4)] = 5295000000000000000000;
    sendMelFromDistributionPool(address(this),5295000000000000000000);
    //0xEE02C646939F0d518a6C1DF19DCec96145347Af4  1.470833333333333333
    rewards[address(0xEE02C646939F0d518a6C1DF19DCec96145347Af4)] = 1470833333333333333;

    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  22000.0
    addStakeholder(0x2C2ADD1C863551A0644876be227604C8E458dD7e);
    stakes[address(0x2C2ADD1C863551A0644876be227604C8E458dD7e)] = 22000000000000000000000;
    sendMelFromDistributionPool(address(this),22000000000000000000000);
    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  24.444444444444444444
    rewards[address(0x2C2ADD1C863551A0644876be227604C8E458dD7e)] = 24444444444444444444;
    //0x2C2ADD1C863551A0644876be227604C8E458dD7e  500.0
    sendMelFromDistributionPool(0x2C2ADD1C863551A0644876be227604C8E458dD7e,500000000000000000000);

    //0xa92A96fe994f7F0E73593f4d88877636aA7790Ba  7590.0
    addStakeholder(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba);
    stakes[address(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0xa92A96fe994f7F0E73593f4d88877636aA7790Ba  8.433333333333333332
    rewards[address(0xa92A96fe994f7F0E73593f4d88877636aA7790Ba)] = 8433333333333333332;

    //0xA1a506bB6442d763362291076911EDBaE1222CF1  7590.0
    addStakeholder(0xA1a506bB6442d763362291076911EDBaE1222CF1);
    stakes[address(0xA1a506bB6442d763362291076911EDBaE1222CF1)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0xA1a506bB6442d763362291076911EDBaE1222CF1  8.433333333333333332
    rewards[address(0xA1a506bB6442d763362291076911EDBaE1222CF1)] = 8433333333333333332;

    //0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064  7590.0
    addStakeholder(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064);
    stakes[address(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064)] = 7590000000000000000000;
    sendMelFromDistributionPool(address(this),7590000000000000000000);
    //0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064  8.433333333333333332
    rewards[address(0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064)] = 8433333333333333332;

    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  40083.0
    addStakeholder(0x65d55B28264131473Fa09BA9e0403350952aC1ce);
    stakes[address(0x65d55B28264131473Fa09BA9e0403350952aC1ce)] = 40083000000000000000000;
    sendMelFromDistributionPool(address(this),40083000000000000000000);
    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  11.134166666666666666
    rewards[address(0x65d55B28264131473Fa09BA9e0403350952aC1ce)] = 11134166666666666666;
    //0x65d55B28264131473Fa09BA9e0403350952aC1ce  22.268333333333333332
    sendMelFromDistributionPool(0x65d55B28264131473Fa09BA9e0403350952aC1ce,22268333333333333332);
    //0x2a61D756637e7cEB89076947800EB5CC52624c9b  7590.0
    sendMelFromDistributionPool(0x2a61D756637e7cEB89076947800EB5CC52624c9b,7590000000000000000000);

    //0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35  11010.0
    addStakeholder(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35);
    stakes[address(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35)] = 11010000000000000000000;
    sendMelFromDistributionPool(address(this),11010000000000000000000);
    //0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35  3.058333333333333333
    rewards[address(0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35)] = 3058333333333333333;

    //0x012601876006aFa5EDaED3C75275689Aa71D8cD2  42461.0
    addStakeholder(0x012601876006aFa5EDaED3C75275689Aa71D8cD2);
    stakes[address(0x012601876006aFa5EDaED3C75275689Aa71D8cD2)] = 42461000000000000000000;
    sendMelFromDistributionPool(address(this),42461000000000000000000);
    //0x012601876006aFa5EDaED3C75275689Aa71D8cD2  47.178888888888888888
    rewards[address(0x012601876006aFa5EDaED3C75275689Aa71D8cD2)] = 47178888888888888888;

    //0x09A84adF034E5901B80e68508E4FDc7931D9a7C9  4000.0
    addStakeholder(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9);
    stakes[address(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9)] = 4000000000000000000000;
    sendMelFromDistributionPool(address(this),4000000000000000000000);
    //0x09A84adF034E5901B80e68508E4FDc7931D9a7C9  1.111111111111111111
    rewards[address(0x09A84adF034E5901B80e68508E4FDc7931D9a7C9)] = 1111111111111111111;
    //0x6ec04CBe2f8e192d8df0BCf94aFb58A4094F7C91  3201.0
    sendMelFromDistributionPool(0x6ec04CBe2f8e192d8df0BCf94aFb58A4094F7C91,3201000000000000000000);

    //0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA  6208.16772
    addStakeholder(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA);
    stakes[address(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA)] = 6208167720000000000000;
    sendMelFromDistributionPool(address(this),6208167720000000000000);
    //0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA  3.448982066666666666
    rewards[address(0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA)] = 3448982066666666666;

    //0x7d7D8baee84bCA250fa1A61813EC2322f9f88751  2000.0
    addStakeholder(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751);
    stakes[address(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751)] = 2000000000000000000000;
    sendMelFromDistributionPool(address(this),2000000000000000000000);
    //0x7d7D8baee84bCA250fa1A61813EC2322f9f88751  2.22222222222222222
    rewards[address(0x7d7D8baee84bCA250fa1A61813EC2322f9f88751)] = 2222222222222222220;

    //0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C  88755.0
    addStakeholder(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C);
    stakes[address(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C)] = 88755000000000000000000;
    sendMelFromDistributionPool(address(this),88755000000000000000000);
    //0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C  65.419444444444444443
    rewards[address(0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C)] = 65419444444444444443;
    //0x189Bf18FD03edfE7046D03eA2f3A563366A3f48E  51000.0
    sendMelFromDistributionPool(0x189Bf18FD03edfE7046D03eA2f3A563366A3f48E,51000000000000000000000);

    //0x34062Df52BA70F88868377159c849A43ba89e21F  6072.0
    addStakeholder(0x34062Df52BA70F88868377159c849A43ba89e21F);
    stakes[address(0x34062Df52BA70F88868377159c849A43ba89e21F)] = 6072000000000000000000;
    sendMelFromDistributionPool(address(this),6072000000000000000000);
    //0x34062Df52BA70F88868377159c849A43ba89e21F  5.059999999999999998
    rewards[address(0x34062Df52BA70F88868377159c849A43ba89e21F)] = 5059999999999999998;

    //0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414  5335.0
    addStakeholder(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414);
    stakes[address(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414  4.445833333333333332
    rewards[address(0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414)] = 4445833333333333332;
    //0x4A52b132a00330fa03c87a563D7909A38d8afee8  272202.637672010812245853
    sendMelFromDistributionPool(0x4A52b132a00330fa03c87a563D7909A38d8afee8,272202637672010812245853);

    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  93000.0
    addStakeholder(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6);
    stakes[address(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6)] = 93000000000000000000000;
    sendMelFromDistributionPool(address(this),93000000000000000000000);
    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  77.499999999999999999
    rewards[address(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6)] = 77499999999999999999;
    //0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6  119.425447074028542367
    sendMelFromDistributionPool(0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6,119425447074028542367);

    //0x35969973D0C9015183B4591692866319b0227c63  2000.0
    addStakeholder(0x35969973D0C9015183B4591692866319b0227c63);
    stakes[address(0x35969973D0C9015183B4591692866319b0227c63)] = 2000000000000000000000;
    sendMelFromDistributionPool(address(this),2000000000000000000000);
    //0x35969973D0C9015183B4591692866319b0227c63  1.666666666666666665
    rewards[address(0x35969973D0C9015183B4591692866319b0227c63)] = 1666666666666666665;

    //0xa4804e097552867c442Bc42B5Ac17810dB8518b6  5335.0
    addStakeholder(0xa4804e097552867c442Bc42B5Ac17810dB8518b6);
    stakes[address(0xa4804e097552867c442Bc42B5Ac17810dB8518b6)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0xa4804e097552867c442Bc42B5Ac17810dB8518b6  4.445833333333333332
    rewards[address(0xa4804e097552867c442Bc42B5Ac17810dB8518b6)] = 4445833333333333332;

    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  77262.06990363817
    addStakeholder(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9);
    stakes[address(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9)] = 77262069903638170000000;
    sendMelFromDistributionPool(address(this),77262069903638170000000);
    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  64.385058253031808333
    rewards[address(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9)] = 64385058253031808333;
    //0x533a04903DADe8B86cC01FCb29204d273fc9f9B9  0.000000000002252811
    sendMelFromDistributionPool(0x533a04903DADe8B86cC01FCb29204d273fc9f9B9,2252811);
    
    
    //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  51411.877275152098120059
    addStakeholder(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D);
    stakes[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 51411877275152098120059;
    sendMelFromDistributionPool(address(this),51411877275152098120059);
    // sendMelFromDistributionPool(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D,51411877275152098120059); //he didn't stake but was waiting for it the whole time

    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  102218.65
    addStakeholder(0x8Bb9ac4086df14f7977DA0537367E312618A1480);
    stakes[address(0x8Bb9ac4086df14f7977DA0537367E312618A1480)] = 102218650000000000000000;
    sendMelFromDistributionPool(address(this),102218650000000000000000);
    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  28.394069444444444444
    rewards[address(0x8Bb9ac4086df14f7977DA0537367E312618A1480)] = 28394069444444444444;
    //0x8Bb9ac4086df14f7977DA0537367E312618A1480  0.000723809394329539
    sendMelFromDistributionPool(0x8Bb9ac4086df14f7977DA0537367E312618A1480,723809394329539);
    //0xe85Ee15145bF0c8155A7Dfa0f200e8f497104aFD  6262.020240979984765333
    sendMelFromDistributionPool(0xe85Ee15145bF0c8155A7Dfa0f200e8f497104aFD,6262020240979984765333);

    //0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1  5335.0
    addStakeholder(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1);
    stakes[address(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1)] = 5335000000000000000000;
    sendMelFromDistributionPool(address(this),5335000000000000000000);
    //0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1  2.963888888888888888
    rewards[address(0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1)] = 2963888888888888888;

    //0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab  58762.0
    addStakeholder(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab);
    stakes[address(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab)] = 58762000000000000000000;
    sendMelFromDistributionPool(address(this),58762000000000000000000);
    //0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab  32.645555555555555554
    rewards[address(0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab)] = 32645555555555555554;

    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  14039.215674629722
    addStakeholder(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718);
    stakes[address(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718)] = 14039215674629722000000;
    sendMelFromDistributionPool(address(this),14039215674629722000000);
    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  3.899782131841589444
    rewards[address(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718)] = 3899782131841589444;
    //0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718  0.000000000001007319
    sendMelFromDistributionPool(0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718,1007319);

    //0xba20aD613983407ad50557c60773494A438f7A8a  8547.843502034111
    addStakeholder(0xba20aD613983407ad50557c60773494A438f7A8a);
    stakes[address(0xba20aD613983407ad50557c60773494A438f7A8a)] = 8547843502034111000000;
    sendMelFromDistributionPool(address(this),8547843502034111000000);
    //0xba20aD613983407ad50557c60773494A438f7A8a  2.374400972787253055
    rewards[address(0xba20aD613983407ad50557c60773494A438f7A8a)] = 2374400972787253055;
    //0xba20aD613983407ad50557c60773494A438f7A8a  0.000000000001115894
    sendMelFromDistributionPool(0xba20aD613983407ad50557c60773494A438f7A8a,1115894);
    //0x20D525051A2017CB043a351621cbb9B6b61f98B9  3301.812402020496251436
    sendMelFromDistributionPool(0x20D525051A2017CB043a351621cbb9B6b61f98B9,3301812402020496251436);

    //0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B  39500.0
    addStakeholder(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B);
    stakes[address(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B)] = 39500000000000000000000;
    sendMelFromDistributionPool(address(this),39500000000000000000000);
    //0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B  173.763254866049063816
    sendMelFromDistributionPool(0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B,173763254866049063816);
    
    totalDistributions = 1657607200584015896499;
    autostake=true;
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner{
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external onlyOwner {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        distributionPoolContract = _distributionPoolContract;
    }

    /**
     * @notice Owner should but able to change the address which is allowed to distribute rewards
     * function: distributeRewardsPercentageFromPool (uint256 _percentagePerYear)
     */
    function updateRewardDistributor(address _rewardDistributor) external onlyOwner {
        rewardDistributor = _rewardDistributor;
    }

    /**
     * @notice setAutoStake true/false
     */
    function updateAutoStake(bool _autostake) external onlyOwner {
        autostake = _autostake;
    }


   /**
    * @notice as the token bridge calls this function, 
    * we mint the amount to the users balance and 
    * immediately creating a stake with this amount.
    * 
    * The latter function is getting removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        
        if(autostake)
            createStake(user,amount);
    }

   /**
    * @notice Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");
        
        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake. Amount gets unlocked from this contract
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public whenNotPaused
    { 
        require(_stake >= minimumStake, "Minimum Stake not reached");
        stakes[msg.sender] = stakes[msg.sender].sub(_stake); //if unstake amount is negative an error is thrown
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        //when removing a stake we unlock the stake from this contract and give it back to the owner 
        _transfer(address(this), msg.sender, _stake);
        emit StakeRemoved(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _amount The amount to be distributed
     */
    function calculateReward(address _stakeholder,uint256 _amount)
        public
        view
        returns(uint256)
    {
        return (stakes[_stakeholder] * _amount).div(totalStakes());
    }

    /**
     * @notice The method to distribute rewards based on a percentage per year to all stakeholders from 
     * the distribution contract account funds in MEL (the distribution pool)
     * We distribute it daily. 10% - is divided by 360. 
     * 
     * We distribute (register a reward) then from the current total stakes the daily percentage.
     * Only rewardDistributor account is allowed to execute
     * 
     */
    function distributeRewardsPercentageFromPool(uint256 _percentagePerYear) public whenNotPaused
    {   
        require((rewardDistributor == msg.sender), "only reward distributor is allowed");
        
        uint256 _distributionAmount = (totalStakes() * _percentagePerYear).div(360*100);
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
        _transfer(distributionPoolContract, msg.sender, reward);

        rewards[msg.sender] = 0;
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken from this contract
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice 
     * the owner of this smart contract should be able to transfer MelalieToken 
     * from the distribution pool contract
     */
    function sendMelFromDistributionPool(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(distributionPoolContract), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH 
     * to any other address from this contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File contracts/child/MelalieStakingTokenUpgradableV2_1.sol

pragma solidity ^0.8.0;

contract MelalieStakingTokenUpgradableV2_1 is MelalieStakingTokenUpgradableV2
{

bool private _upgradedV2_1;

 function upgradeV2_1() public {
    require(!_upgradedV2_1, "MelalieStakingTokenUpgradableV2_1: already upgraded");

    uint256 rewardManual01 = 1290284042557023600000;
    addStakeholder(0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c);
    rewards[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c] = rewards[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c] + rewardManual01*10/100/360*31;

    uint256 rewardManual02 = 51411877275152098120059;
    addStakeholder(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D);
    rewards[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D] = rewards[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D] + rewardManual02*10/100/360*31;

    //13d 9500 MEL for 0x56DB2160EAFc73050FAD08FdB8159c08d11634Ea staked in transaction: 0xa8d6e5c274be96acadcd9c007c97d334ad3dabc37d7dcc60e438ade32bb4bd89 Aug-12-2021
    uint256 rewardManual03 = 9500000000000000000000;
    addStakeholder(0x56DB2160EAFc73050FAD08FdB8159c08d11634Ea);
    rewards[0x56DB2160EAFc73050FAD08FdB8159c08d11634Ea] = rewards[0x56DB2160EAFc73050FAD08FdB8159c08d11634Ea] + rewardManual03*10/100/360*13;

    //1d 997272.31083843059 MEL for 0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E staked in tx https://polygonscan.com/tx/0x0845caf24ff25de6e20597b10baa205fb9e8685b658aa084132289b504e37c90 Aug-24-2021
    uint256 rewardManual04 = 997272310838430590000000;
    addStakeholder(0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E);
    rewards[0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E] = rewards[0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E] + rewardManual04*10/100/360;
    
    //generated standard rewards for 31 days
    rewards[0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC] = rewards[0x4a21040B18Ba0e18B48Fb69233982756A67A0dcC] + 108835833333333333323;
    rewards[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2] = rewards[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2] + 774388432421759305528;
    rewards[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5] = rewards[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5] + 8611111111111111087;
    rewards[0xF95720db004d94922Abb904222f02bc0793b589d] = rewards[0xF95720db004d94922Abb904222f02bc0793b589d] + 34444444444444444441;
    rewards[0x3d2596AEDCfef405F04eb78C38426113d19AADda] = rewards[0x3d2596AEDCfef405F04eb78C38426113d19AADda] + 2583333333333333333323;
    rewards[0xde9a65d3F549EDD70163795479a7c88d13DbB15C] = rewards[0xde9a65d3F549EDD70163795479a7c88d13DbB15C] + 65349722222222222205;
    rewards[0xEE02C646939F0d518a6C1DF19DCec96145347Af4] = rewards[0xEE02C646939F0d518a6C1DF19DCec96145347Af4] + 45595833333333333323;
    rewards[0x2C2ADD1C863551A0644876be227604C8E458dD7e] = rewards[0x2C2ADD1C863551A0644876be227604C8E458dD7e] + 189444444444444444441;
    rewards[0xa92A96fe994f7F0E73593f4d88877636aA7790Ba] = rewards[0xa92A96fe994f7F0E73593f4d88877636aA7790Ba] + 65358333333333333323;
    rewards[0xA1a506bB6442d763362291076911EDBaE1222CF1] = rewards[0xA1a506bB6442d763362291076911EDBaE1222CF1] + 65358333333333333323;
    rewards[0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064] = rewards[0x5dfe825d9F7aFC54E5464124Ee6a98DCFfdF0064] + 65358333333333333323;
    rewards[0x65d55B28264131473Fa09BA9e0403350952aC1ce] = rewards[0x65d55B28264131473Fa09BA9e0403350952aC1ce] + 345159166666666666646;
    rewards[0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35] = rewards[0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35] + 94808333333333333323;
    rewards[0x012601876006aFa5EDaED3C75275689Aa71D8cD2] = rewards[0x012601876006aFa5EDaED3C75275689Aa71D8cD2] + 365636388888888888882;
    rewards[0x09A84adF034E5901B80e68508E4FDc7931D9a7C9] = rewards[0x09A84adF034E5901B80e68508E4FDc7931D9a7C9] + 34444444444444444441;
    rewards[0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA] = rewards[0xD8C4b5A7D05d61D6e275c410C61a01DE2b08F6BA] + 53459222033333333323;
    rewards[0x7d7D8baee84bCA250fa1A61813EC2322f9f88751] = rewards[0x7d7D8baee84bCA250fa1A61813EC2322f9f88751] + 17222222222222222205;
    rewards[0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C] = rewards[0x32c32acb7C4ba8f83579852DD97eB0e066A4EC3C] + 764279166666666666646;
    rewards[0x34062Df52BA70F88868377159c849A43ba89e21F] = rewards[0x34062Df52BA70F88868377159c849A43ba89e21F] + 52286666666666666646;
    rewards[0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414] = rewards[0x325bA2dcfa2BA5ceD7E73d2939f1741F62760414] + 45940277777777777764;
    rewards[0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6] = rewards[0x8e2C205eF5335d3F8b05bA81EBf9B1148D89dab6] + 800833333333333333323;
    rewards[0x35969973D0C9015183B4591692866319b0227c63] = rewards[0x35969973D0C9015183B4591692866319b0227c63] + 17222222222222222205;
    rewards[0xa4804e097552867c442Bc42B5Ac17810dB8518b6] = rewards[0xa4804e097552867c442Bc42B5Ac17810dB8518b6] + 45940277777777777764;
    rewards[0x533a04903DADe8B86cC01FCb29204d273fc9f9B9] = rewards[0x533a04903DADe8B86cC01FCb29204d273fc9f9B9] + 665312268614662019441;
    rewards[0x8Bb9ac4086df14f7977DA0537367E312618A1480] = rewards[0x8Bb9ac4086df14f7977DA0537367E312618A1480] + 880216152777777777764;
    rewards[0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1] = rewards[0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1] + 45940277777777777764;
    rewards[0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab] = rewards[0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab] + 506006111111111111087;
    rewards[0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718] = rewards[0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718] + 120893246087089272764;
    rewards[0xba20aD613983407ad50557c60773494A438f7A8a] = rewards[0xba20aD613983407ad50557c60773494A438f7A8a] + 73606430156404844705;

    
    autostake = true;
    _upgradedV2_1 = true;
 }

 function version() public virtual pure returns (string memory){ //override
     return "2.1.0";
 }
}


// File contracts/child/MelalieStakingTokenUpgradableV2_2.sol

pragma solidity ^0.8.0;






contract MelalieStakingTokenUpgradableV2_2 is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    //new variable v2
    bool private _upgradedV2;
    address rewardDistributor; //now deprecated since v2_2 - removed function updateRewardDistribution / distributeRewards
    bool public autostake;

    //new variable v2_1
    bool private _upgradedV2_1;
    
    //new variable v2_2
    bool private _upgradedV2_2;
    uint256 public lastDistributionTimestamp; 

   
   function upgradeV2_2() public {
      require(!_upgradedV2_2, "MelalieStakingTokenUpgradableV2_1: already upgraded");
      _upgradedV2_2 = true;
      _mint(0xAfB767A3a634d22a518289D23f29Ad591eA9C0E9, 7056000000000000000000); //MEL of user never arrived on Polygon during emergency stop of the contract https://etherscan.io/tx/0x09aebbc492d2dfba7de684c89b9adc39580aaab77835b17386d19fb35771a9f6
      lastDistributionTimestamp = 1629938335; //Aug-26-2021 05:38:55 PM +UTC (Mumbai testnet!) block.timestamp - 60-60*24;
   }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner{
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external onlyOwner {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        distributionPoolContract = _distributionPoolContract;
    }

    /**
     * @notice setAutoStake true/false
     */
    function updateAutoStake(bool _autostake) external onlyOwner {
        autostake = _autostake;
    }


   /**
    * @notice as the token bridge calls this function,
    * we mint the amount to the users balance and
    * immediately creating a stake with this amount.
    *
    * The latter function might get removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        
        if(autostake)
            createStake(user,amount);
    }

   /**
    * @notice Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");
        
        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake. Amount gets unlocked from this contract
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public whenNotPaused
    { 
        require(_stake >= minimumStake, "Minimum Stake not reached");
        stakes[msg.sender] = stakes[msg.sender].sub(_stake); //if unstake amount is negative an error is thrown
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
         //when removing a stake we unlock the stake from this contract and give it back to the owner 
        _transfer(address(this), msg.sender, _stake);
        emit StakeRemoved(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _amount The amount to be distributed
     */
    function calculateReward(address _stakeholder,uint256 _amount)
        public
        view
        returns(uint256)
    {
        return (stakes[_stakeholder] * _amount).div(totalStakes());
    }

    /**
     * @notice The method to distribute rewards based on 10% per year to all stakeholders from 
     * the distribution contract account funds in MEL (the distribution pool)
     * We distribute it daily. 10% - is divided by 360. 
     * 
     * We distribute (register a reward) then from the current total stakes the daily percentage.
     * Only rewardDistributor account is allowed to execute
     * 
     */
    function distributeRewards() public whenNotPaused
    {   
        //require((rewardDistributor == msg.sender), "only reward distributor is allowed");
        require(lastDistributionTimestamp <= block.timestamp-60-60*24, "distributions should be done only once every 24h");
        lastDistributionTimestamp = block.timestamp;

        uint256 _distributionAmount = (totalStakes() * 10).div(360*100); //10% _percentagePerYear
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder,_distributionAmount);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
         rewards[msg.sender] = 0;
        _transfer(distributionPoolContract, msg.sender, reward);
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken from this contract
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice 
     * the owner of this smart contract should be able to transfer MelalieToken 
     * from the distribution pool contract
     */
    function sendMelFromDistributionPool(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(distributionPoolContract), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH 
     * to any other address from this contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

   function version() public virtual pure returns (string memory){ 
      return "2.2.0";
   }
    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File contracts/child/MelalieStakingTokenUpgradableV2_3_1.sol

pragma solidity ^0.8.1;





contract MelalieStakingTokenUpgradableV2_3_1 is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address private deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    //new variable v2
    bool private _upgradedV2;
    address private rewardDistributor; //now deprecated since v2_2 - removed function updateRewardDistribution / distributeRewards
    bool public autostake;

    //new variable v2_1
    bool private _upgradedV2_1;
    
    //new variable v2_2
    bool private _upgradedV2_2;
    uint256 public lastDistributionTimestamp; 

    //new variable v2_3
    bool private _upgradedV2_3;
    struct Stake{
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => Stake[]) internal stake_times; //time when last stake was created by stake holder
    
    //new variable v2_3_1
    bool private _upgradedV2_3_1;
   
   function upgradeV2_3_1() public {
      require(!_upgradedV2_3_1, "MelalieStakingTokenUpgradableV2_3_1: already upgraded");

        stake_times[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2].push(Stake(1626684348,89928979248978500000000)); //Mon Jul 19 2021 10:45:48 GMT+0200 (Central European Summer Time)
        stake_times[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2].push(Stake(1631133936,1249013600680259300000)); //Wed Sep 08 2021 22:45:36 GMT+0200 (Central European Summer Time)
        stake_times[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2].push(Stake(1636233535,1494305993924963000000)); //Sat Nov 06 2021 22:18:55 GMT+0100 (Central European Standard Time)
        stake_times[0xB8b58B248e975A76d147404454F6aA07d2A4E3e2].push(Stake(1639912894,1081000000000000000000)); //Sun Dec 19 2021 12:21:34 GMT+0100 (Central European Standard Time)
        stake_times[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c].push(Stake(1626856141,1290284042557023600000)); //Wed Jul 21 2021 10:29:01 GMT+0200 (Central European Summer Time)
        stake_times[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c].push(Stake(1627809993,100000000000000000)); //Sun Aug 01 2021 11:26:33 GMT+0200 (Central European Summer Time)
        stake_times[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c].push(Stake(1629927109,1500000000000000000000)); //Wed Aug 25 2021 23:31:49 GMT+0200 (Central European Summer Time)
        stake_times[0xd6bAEC21fEFB4ad64d29d3d20527c37c757F409c].push(Stake(1631611142,2762945065017675000)); //Tue Sep 14 2021 11:19:02 GMT+0200 (Central European Summer Time)
        stake_times[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5].push(Stake(1626708483,1000000000000000000000)); //Mon Jul 19 2021 17:28:03 GMT+0200 (Central European Summer Time)
        stake_times[0xF95720db004d94922Abb904222f02bc0793b589d].push(Stake(1626710417,4000000000000000000000)); //Mon Jul 19 2021 18:00:17 GMT+0200 (Central European Summer Time)
        stake_times[0xde9a65d3F549EDD70163795479a7c88d13DbB15C].push(Stake(1626711571,7589000000000000000000)); //Mon Jul 19 2021 18:19:31 GMT+0200 (Central European Summer Time)
        stake_times[0xA1a506bB6442d763362291076911EDBaE1222CF1].push(Stake(1640259821,7811000000000000000000)); //Thu Dec 23 2021 12:43:41 GMT+0100 (Central European Standard Time)
        stake_times[0x7d7D8baee84bCA250fa1A61813EC2322f9f88751].push(Stake(1633877022,2002222222222222200000)); //Sun Oct 10 2021 16:43:42 GMT+0200 (Central European Summer Time)
        stake_times[0x34062Df52BA70F88868377159c849A43ba89e21F].push(Stake(1626815886,6072000000000000000000)); //Tue Jul 20 2021 23:18:06 GMT+0200 (Central European Summer Time)
        stake_times[0x35969973D0C9015183B4591692866319b0227c63].push(Stake(1626846313,2000000000000000000000)); //Wed Jul 21 2021 07:45:13 GMT+0200 (Central European Summer Time)
        stake_times[0x65d55B28264131473Fa09BA9e0403350952aC1ce].push(Stake(1626858998,40083000000000000000000)); //Wed Jul 21 2021 11:16:38 GMT+0200 (Central European Summer Time)
        stake_times[0x65d55B28264131473Fa09BA9e0403350952aC1ce].push(Stake(1626985159,22268333333333333332)); //Thu Jul 22 2021 22:19:19 GMT+0200 (Central European Summer Time)
        stake_times[0x65d55B28264131473Fa09BA9e0403350952aC1ce].push(Stake(1635608878,1068000000000000000000)); //Sat Oct 30 2021 17:47:58 GMT+0200 (Central European Summer Time)
        stake_times[0x65d55B28264131473Fa09BA9e0403350952aC1ce].push(Stake(1644273419,1119000000000000000000)); //Mon Feb 07 2022 23:36:59 GMT+0100 (Central European Standard Time)
        stake_times[0xa4804e097552867c442Bc42B5Ac17810dB8518b6].push(Stake(1626868455,5335000000000000000000)); //Wed Jul 21 2021 13:54:15 GMT+0200 (Central European Summer Time)
        stake_times[0x3d2596AEDCfef405F04eb78C38426113d19AADda].push(Stake(1626873949,300000000000000000000000)); //Wed Jul 21 2021 15:25:49 GMT+0200 (Central European Summer Time)
        stake_times[0x533a04903DADe8B86cC01FCb29204d273fc9f9B9].push(Stake(1626881077,77262069903638170000000)); //Wed Jul 21 2021 17:24:37 GMT+0200 (Central European Summer Time)
        stake_times[0x3fFd6dB0801A2C18eb4f0e8b81F79AD2205dF6a1].push(Stake(1647174284,5668000000000000000000)); //Sun Mar 13 2022 13:24:44 GMT+0100 (Central European Standard Time)
        stake_times[0xc09bf29796EcCF7FDD2Fb1F777fE6EAFEE9460Ab].push(Stake(1626961560,58762000000000000000000)); //Thu Jul 22 2021 15:46:00 GMT+0200 (Central European Summer Time)
        stake_times[0xDbF3F4e39814b0B0164aE4cC90D98720b2Bd0718].push(Stake(1626977678,14039215674629722000000)); //Thu Jul 22 2021 20:14:38 GMT+0200 (Central European Summer Time)
        stake_times[0xB94a1473F2C418AAa06bf664C76D13685c559362].push(Stake(1626991004,7590000000000000000000)); //Thu Jul 22 2021 23:56:44 GMT+0200 (Central European Summer Time)
        stake_times[0x09A84adF034E5901B80e68508E4FDc7931D9a7C9].push(Stake(1626991008,4000000000000000000000)); //Thu Jul 22 2021 23:56:48 GMT+0200 (Central European Summer Time)
        stake_times[0xba20aD613983407ad50557c60773494A438f7A8a].push(Stake(1627022130,8547843502034111000000)); //Fri Jul 23 2021 08:35:30 GMT+0200 (Central European Summer Time)
        stake_times[0x90cC11dA18b204885a5C15A3B2aaf16e8516AD35].push(Stake(1636456745,11340000000000000000000)); //Tue Nov 09 2021 12:19:05 GMT+0100 (Central European Standard Time)
        stake_times[0xEE02C646939F0d518a6C1DF19DCec96145347Af4].push(Stake(1627044391,5295000000000000000000)); //Fri Jul 23 2021 14:46:31 GMT+0200 (Central European Summer Time)
        stake_times[0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B].push(Stake(1627083747,39500000000000000000000)); //Sat Jul 24 2021 01:42:27 GMT+0200 (Central European Summer Time)
        stake_times[0x89bDe2F32dd0f30c6952Ec73F373f2789d604f8B].push(Stake(1639316203,1369735477088271200000)); //Sun Dec 12 2021 14:36:43 GMT+0100 (Central European Standard Time)
        stake_times[0xFbC0B4D50C8707A094ebb0a54E3609e369345C03].push(Stake(1629529158,7543167720000000000000)); //Sat Aug 21 2021 08:59:18 GMT+0200 (Central European Summer Time)
        stake_times[0xF32719Bd3683Ba776fE060B0a216B6f95Acd2805].push(Stake(1630477394,102290000000000000000000)); //Wed Sep 01 2021 08:23:14 GMT+0200 (Central European Summer Time)
        stake_times[0xAfB767A3a634d22a518289D23f29Ad591eA9C0E9].push(Stake(1630691834,7056000000000000000000)); //Fri Sep 03 2021 19:57:14 GMT+0200 (Central European Summer Time)
        stake_times[0xAfB767A3a634d22a518289D23f29Ad591eA9C0E9].push(Stake(1631591300,7056000000000000000000)); //Tue Sep 14 2021 05:48:20 GMT+0200 (Central European Summer Time)
        stake_times[0x2a61D756637e7cEB89076947800EB5CC52624c9b].push(Stake(1630787671,7590000000000000000000)); //Sat Sep 04 2021 22:34:31 GMT+0200 (Central European Summer Time)
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1645193481,10600000000000000000000)); //Fri Feb 18 2022 15:11:21 GMT+0100 (Central European Standard Time)
        stake_times[0xe7D272bb27CF524b5222bE9E8d9eecdd7c24B50f].push(Stake(1638418378,1104000000000000000000)); //Thu Dec 02 2021 05:12:58 GMT+0100 (Central European Standard Time)
        stake_times[0x81C7F8c0d9aa3cC48020e3e7650b8F2B6781e98b].push(Stake(1641043148,2712953391164322500000)); //Sat Jan 01 2022 14:19:08 GMT+0100 (Central European Standard Time)
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1643645856,75000000000000000000000)); //Mon Jan 31 2022 17:17:36 GMT+0100 (Central European Standard Time)
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1648645833,10000000000000000000000)); //Wed Mar 30 2022 15:10:33 GMT+0200 (Central European Summer Time)
        stake_times[0x29F6e022bBEB70400EBEF313d92D4D466ee9AaE0].push(Stake(1644425666,122691000000000000000000)); //Wed Feb 09 2022 17:54:26 GMT+0100 (Central European Standard Time)
        stake_times[0x05Eb9926B701Cce39a7aF01bf699Bc171bcA8B9f].push(Stake(1644425828,122000000000000000000000)); //Wed Feb 09 2022 17:57:08 GMT+0100 (Central European Standard Time)
        stake_times[0x19fFD6bea98c22EB62c286b173a5879831e0536a].push(Stake(1644425882,122000000000000000000000)); //Wed Feb 09 2022 17:58:02 GMT+0100 (Central European Standard Time)
        stake_times[0x3A5DDbeC1049d05069Ea6D21c110C5342fde4193].push(Stake(1644425924,122000000000000000000000)); //Wed Feb 09 2022 17:58:44 GMT+0100 (Central European Standard Time)
        stake_times[0x687BE562C7a4b294Db54D1045B63C1268ae383a2].push(Stake(1644425978,122000000000000000000000)); //Wed Feb 09 2022 17:59:38 GMT+0100 (Central European Standard Time)
        stake_times[0x5fCaa32587eA0FE8C1B869B576Bcb80B54058882].push(Stake(1644426128,122000000000000000000000)); //Wed Feb 09 2022 18:02:08 GMT+0100 (Central European Standard Time)
        stake_times[0x76f708b3D1E2540A6a6c32a97356c2068f564D4C].push(Stake(1645119162,19996000000000000000000)); //Thu Feb 17 2022 18:32:42 GMT+0100 (Central European Standard Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1648463411,10700000000000000000000)); //Mon Mar 28 2022 12:30:11 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1648733925,1555000000000000000000)); //Thu Mar 31 2022 15:38:45 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1648734123,2517966991658723000000)); //Thu Mar 31 2022 15:42:03 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1648734349,1670000000000000000000)); //Thu Mar 31 2022 15:45:49 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1648735481,1674000000000000000000)); //Thu Mar 31 2022 16:04:41 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1649689778,2805000000000000000000)); //Mon Apr 11 2022 17:09:38 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650527150,4760000000000000000000)); //Thu Apr 21 2022 09:45:50 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650527228,2626000000000000000000)); //Thu Apr 21 2022 09:47:08 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650527586,1420000000000000000000)); //Thu Apr 21 2022 09:53:06 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650556369,10000000000000000000000)); //Thu Apr 21 2022 17:52:49 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650556805,30000000000000000000000)); //Thu Apr 21 2022 18:00:05 GMT+0200 (Central European Summer Time)
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650557221,4273000000000000000000)); //Thu Apr 21 2022 18:07:01 GMT+0200 (Central European Summer Time)
        //manually 10.05.20 
        stake_times[0x65d55B28264131473Fa09BA9e0403350952aC1ce].push(Stake(1651785798,1010000000000000000000));
        _upgradedV2_3 = true;
   }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner{
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external onlyOwner {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        distributionPoolContract = _distributionPoolContract;
    }

    /**
     * @notice setAutoStake true/false
     */
    function updateAutoStake(bool _autostake) external onlyOwner {
        autostake = _autostake;
    }


   /**
    * @notice as the token bridge calls this function,
    * we mint the amount to the users balance and
    * immediately creating a stake with this amount.
    *
    * The latter function might get removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        
        if(autostake)
            createStake(user,amount);
    }

   /**
    * @notice Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");
        // require(stakes[_stakeHolder] == 0 , "Stake was already created - please remove stake first");

        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        stake_times[_stakeHolder].push(Stake(block.timestamp,_stake));  //should contain each single stake

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to completely remove his stake. 
     * All stakes are removed, in case he was increasing his stakes over time! 
     */
    function removeStake() 
        public whenNotPaused
    { 
        uint256 oldStake = stakes[msg.sender];

        delete stakes[msg.sender]; 
        delete stake_times[msg.sender];
        removeStakeholder(msg.sender);

        _transfer(address(this), msg.sender, oldStake);

        emit StakeRemoved(msg.sender, oldStake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

    function stakeTimeOf(address _stakeholder, uint256 index) public view returns(uint256)
    {
        return stake_times[_stakeholder][index].timestamp;
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * - a normal apy is 10%
     * - after 1 month apy is 15%
     * - after 3 month apy is 20%
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {

        uint256 summedReward = 0;
        Stake[] memory stakeList = stake_times[_stakeholder];
        //0. Loop over all stakes of the stakeholder
        for (uint256 s = 0; s < stakeList.length; s += 1){
        
            //1. we find out how long he was staking
            uint256 timeElapsed = block.timestamp - stakeList[s].timestamp;
            uint256 apy = 10;
        
            //2. depending on his staking time we decide the APY (10%, 15% or 20%)
            if ( timeElapsed > 60*60*24*(30+1) && timeElapsed < 60*60*24*(30*3+1)) apy = 15;
            if ( timeElapsed > 60*60*24*(30*3+1)) apy = 20;

            //3. we calculate the reward for 1 day according to the selected APY
            // summedReward = summedReward.add((stakeList[s].amount.mul(apy)).div(36000));
             summedReward = (stakeList[s].amount * apy/36000) + summedReward;
        }
        return summedReward;
    }

    /**
     * @notice The method to distribute rewards to all stakeholders from 
     * the distribution contract accounts funds in MEL ("the distribution pool")
     * We distribute it daily. 10% - is divided by 360. 
     * 
     * We distribute (register a reward) then from the current total stakes the daily percentage.
     * Only rewardDistributor account is allowed to execute
     * 
     */
    function distributeRewards() public whenNotPaused
    {
        require(lastDistributionTimestamp <= block.timestamp-60-60*24, "distributions should be done only once every 24h");
        lastDistributionTimestamp = block.timestamp;
        uint256 _distributionAmount = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];

            uint256 reward = calculateReward(stakeholder);
            _distributionAmount = _distributionAmount.add(reward);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }

        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
         rewards[msg.sender] = 0;
        _transfer(distributionPoolContract, msg.sender, reward);
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken from this contract
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice 
     * the owner of this smart contract should be able to transfer MelalieToken 
     * from the distribution pool contract
     */
    function sendMelFromDistributionPool(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(distributionPoolContract), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH 
     * to any other address from this contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

   function version() public virtual pure returns (string memory){ 
      return "2.3.1";
   }
    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
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
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/root/MelalieRoot.sol

pragma solidity ^0.8.0;
//Sample from https://docs.matic.network/docs/develop/ethereum-matic/mintable-assets/




contract MelalieRootToken is ERC20, AccessControl
{
    // bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // _setupRole(PREDICATE_ROLE, _msgSender());

        _mint(_msgSender(), 10**10 * (10**18));
    }

    // function mint(address user, uint256 amount) external { 
    //  require(hasRole(PREDICATE_ROLE, msg.sender));
    //     _mint(user, amount);
    // }
}


// File contracts/recovery/MelalieBalances.sol


pragma solidity ^0.8.0;

contract MelalieBalances  {

    receive() payable external {}
   
}