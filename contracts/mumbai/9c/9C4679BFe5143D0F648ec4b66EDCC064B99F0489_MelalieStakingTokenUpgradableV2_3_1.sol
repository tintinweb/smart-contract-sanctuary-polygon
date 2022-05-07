/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]



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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]



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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/child/MelalieDistributionPool.sol

pragma solidity ^0.8.0;

contract MelalieDistributionPool  {

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