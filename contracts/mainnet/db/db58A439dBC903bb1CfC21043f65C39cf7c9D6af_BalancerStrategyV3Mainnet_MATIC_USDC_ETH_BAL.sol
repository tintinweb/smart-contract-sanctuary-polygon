// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewarder.sol";

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function rewarder(uint256 _pid) external view returns (IRewarder);
    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function lpToken(uint256 _pid) external view returns (IERC20);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function pendingBanana(uint256 _pid, address _user) external view returns (uint256 pending);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onBananaReward(uint256 pid, address user, address recipient, uint256 bananaAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 bananaAmount) external view returns (IERC20[] memory, uint256[] memory);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interface/IMiniChefV2.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";


contract MiniApeV2Strategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant apeswapRouterV2 = address(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  mapping (address => address[]) public uniswapRoutes;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolID
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    require(address(IMiniChefV2(rewardPool()).lpToken(_poolID)) == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);

    address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

    // these would be required to be initialized separately by governance
    uniswapRoutes[uniLPComponentToken0] = new address[](0);
    uniswapRoutes[uniLPComponentToken1] = new address[](0);

  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).withdrawAndHarvest(poolId(), bal, address(this));
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).emergencyWithdraw(poolId(), address(this));
      }
  }

  function harvestReward() internal {
      IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMiniChefV2(rewardPool()).deposit(poolId(), entireBalance, address(this));
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setLiquidationPath(address _token, address [] memory _route) public onlyGovernance {
    uniswapRoutes[_token] = _route;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Uniswap to sell our reward
    IERC20(rewardToken()).safeApprove(apeswapRouterV2, 0);
    IERC20(rewardToken()).safeApprove(apeswapRouterV2, remainingRewardBalance);


    address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    uint256 token0Amount;

    if (uniswapRoutes[uniLPComponentToken0].length > 1) {
      // if we need to liquidate the token0
      IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
        toToken0,
        amountOutMin,
        uniswapRoutes[uniLPComponentToken0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(uniLPComponentToken0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;

    if (uniswapRoutes[uniLPComponentToken1].length > 1) {
      // sell reward token to token1
      IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
        toToken1,
        amountOutMin,
        uniswapRoutes[uniLPComponentToken1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(uniLPComponentToken1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    // provide token1 and token2 to ape
    IERC20(uniLPComponentToken0).safeApprove(apeswapRouterV2, 0);
    IERC20(uniLPComponentToken0).safeApprove(apeswapRouterV2, token0Amount);

    IERC20(uniLPComponentToken1).safeApprove(apeswapRouterV2, 0);
    IERC20(uniLPComponentToken1).safeApprove(apeswapRouterV2, token1Amount);

    // we provide liquidity to ape
    uint256 liquidity;
    (,,liquidity) = IUniswapV2Router02(apeswapRouterV2).addLiquidity(
      uniLPComponentToken0,
      uniLPComponentToken1,
      token0Amount,
      token1Amount,
      1,  // we are willing to take whatever the pair gives us
      1,  // we are willing to take whatever the pair gives us
      address(this),
      block.timestamp
    );

  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMiniChefV2(rewardPool()).withdraw(poolId(), toWithdraw, address(this));
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    harvestReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming BANANA rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of reward needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
    // reset the liquidation paths
    // they need to be re-set manually
    uniswapRoutes[IUniswapV2Pair(underlying()).token0()] = new address[](0);
    uniswapRoutes[IUniswapV2Pair(underlying()).token1()] = new address[](0);
  }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./interface/IController.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./FeeRewardForwarder.sol";
import "./inheritance/Governable.sol";

contract Controller is IController, Governable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Address for address;
    using SafeMath for uint256;

    // external parties
    address public override feeRewardForwarder;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public override greyList;

    uint256 public constant override profitSharingNumerator = 5;
    uint256 public constant override profitSharingDenominator = 100;

    event SharePriceChangeLog(
      address indexed vault,
      address indexed strategy,
      uint256 oldSharePrice,
      uint256 newSharePrice,
      uint256 timestamp
    );

    mapping (address => bool) public hardWorkers;

    modifier onlyHardWorkerOrGovernance() {
        require(hardWorkers[msg.sender] || (msg.sender == governance()),
        "only hard worker can call this");
        _;
    }

    constructor(address _storage, address _feeRewardForwarder)
    Governable(_storage) public {
        require(_feeRewardForwarder != address(0), "feeRewardForwarder should not be empty");
        feeRewardForwarder = _feeRewardForwarder;
    }

    function addHardWorker(address _worker) public onlyGovernance {
      require(_worker != address(0), "_worker must be defined");
      hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) public onlyGovernance {
      require(_worker != address(0), "_worker must be defined");
      hardWorkers[_worker] = false;
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function setFeeRewardForwarder(address _feeRewardForwarder) public override onlyGovernance {
      require(_feeRewardForwarder != address(0), "new reward forwarder should not be empty");
      feeRewardForwarder = _feeRewardForwarder;
    }

    function addVaultAndStrategy(address _vault, address _strategy) external override onlyGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        // adding happens while setting
        IVault(_vault).setStrategy(_strategy);
    }

    function doHardWork(address _vault) external override onlyHardWorkerOrGovernance {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        emit SharePriceChangeLog(
          _vault,
          IVault(_vault).strategy(),
          oldSharePrice,
          IVault(_vault).getPricePerFullShare(),
          block.timestamp
        );
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external override onlyGovernance {
        IERC20Upgradeable(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(address _strategy, address _token, uint256 _amount) external override onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvagable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }

    function notifyFee(address underlying, uint256 fee) external override {
      if (fee > 0) {
        IERC20Upgradeable(underlying).safeTransferFrom(msg.sender, address(this), fee);
        IERC20Upgradeable(underlying).safeApprove(feeRewardForwarder, 0);
        IERC20Upgradeable(underlying).safeApprove(feeRewardForwarder, fee);
        FeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying, fee);
      }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IPoolFactory {
  function deploy(address _storage, address _vault) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IStrategyFactory {
  function deploy(address _storage, address _vault, address _providedStrategyAddress) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVaultFactory {
  function deploy(address _storage, address _underlying) external returns (address);
  function info(address vault) external view returns(address Underlying, address NewVault);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IStrategyFactory.sol";
import "./interface/IVaultFactory.sol";
import "./interface/IPoolFactory.sol";

import "../interface/IVault.sol";
import "../inheritance/Governable.sol";

contract MegaFactory is Ownable {

  enum VaultType {
    None,
    Regular
  }

  enum StrategyType {
    None,
    Upgradable
  }

  address public potPoolFactory;
  mapping(uint256 => address) public vaultFactories;
  mapping(uint256 => address) public strategyFactories;

  struct CompletedDeployment {
    VaultType vaultType;
    address Underlying;
    address NewVault;
    address NewStrategy;
    address NewPool;
  }

  event DeploymentCompleted(string id);

  mapping (string => CompletedDeployment) public completedDeployments;
  mapping (address => bool) public authorizedDeployers;

  address public multisig;
  address public actualStorage;

  /* methods to make compatible with Storage */
  function governance() external view returns (address) {
    return address(this); // fake governance
  }

  function isGovernance(address addr) external view returns (bool) {
    return addr == address(this); // fake governance
  }

  function isController(address addr) external view returns (bool) {
    return addr == address(this); // fake controller
  }

  modifier onlyAuthorizedDeployer(string memory id) {
    require(completedDeployments[id].vaultType == VaultType.None, "cannot reuse id");
    require(authorizedDeployers[msg.sender], "unauthorized deployer");
    _;
    emit DeploymentCompleted(id);
  }

  constructor(address _storage, address _multisig) public {
    multisig = _multisig;
    actualStorage = _storage;
    setAuthorization(owner(), true);
    setAuthorization(multisig, true);
  }

  function setAuthorization(address userAddress, bool isDeployer) public onlyOwner {
    authorizedDeployers[userAddress] = isDeployer;
  }

  function setVaultFactory(uint256 vaultType, address factoryAddress) external onlyOwner {
    vaultFactories[vaultType] = factoryAddress;
  }

  function setStrategyFactory(uint256 strategyType, address factoryAddress) external onlyOwner {
    strategyFactories[strategyType] = factoryAddress;
  }

  function setPotPoolFactory(address factoryAddress) external onlyOwner {
    potPoolFactory = factoryAddress;
  }

  function createRegularVault(string calldata id, address underlying) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     actualStorage,
     underlying
    );

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      address(0),
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }

  function createRegularVaultUsingUpgradableStrategy(string calldata id, address underlying, address strategyImplementation) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     address(this), // using this as initial storage, then switching to actualStorage
     underlying
    );

    address strategy = IStrategyFactory(strategyFactories[uint256(StrategyType.Upgradable)]).deploy(actualStorage, vault, strategyImplementation);
    IVault(vault).setStrategy(strategy);
    Governable(vault).setStorage(actualStorage);

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      strategy,
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../inheritance/Governable.sol";
import "../../inheritance/OwnableWhitelist.sol";
import "../interface/IPoolFactory.sol";
import "../../PotPool.sol";

contract PotPoolFactory is OwnableWhitelist, IPoolFactory {
  address public iFARM = 0xab0b2ddB9C7e440fAc8E140A89c0dbCBf2d7Bbff;
  address public wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  uint256 public poolDefaultDuration = 604800; // 7 days

  function setPoolDefaultDuration(uint256 _value) external onlyOwner {
    poolDefaultDuration = _value;
  }

  function deploy(address actualStorage, address vault) override external onlyWhitelisted returns (address) {
    address actualGovernance = Governable(vault).governance();

    string memory tokenSymbol = ERC20(vault).symbol();
    address[] memory rewardDistribution = new address[](1);
    rewardDistribution[0] = actualGovernance;
    address[] memory rewardTokens = new address[](2);
    rewardTokens[0] = iFARM;
    rewardTokens[1] = wMATIC;
    PotPool pool = new PotPool(
      rewardTokens,
      vault,
      poolDefaultDuration,
      rewardDistribution,
      actualStorage,
      string(abi.encodePacked("p", tokenSymbol)),
      string(abi.encodePacked("p", tokenSymbol)),
      ERC20(vault).decimals()
    );

    Ownable(pool).transferOwnership(actualGovernance);

    return address(pool);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../interface/IStrategyFactory.sol";
import "../../upgradability/StrategyProxy.sol";
import "../../inheritance/OwnableWhitelist.sol";

interface IInitializableStrategy {
  function initializeStrategy(address _storage, address _vault) external;
}

contract UpgradableStrategyFactory is OwnableWhitelist, IStrategyFactory {
  function deploy(address actualStorage, address vault, address upgradableStrategyImplementation) override external onlyWhitelisted returns (address) {
    StrategyProxy proxy = new StrategyProxy(upgradableStrategyImplementation);
    IInitializableStrategy strategy = IInitializableStrategy(address(proxy));
    strategy.initializeStrategy(actualStorage, vault);
    return address(proxy);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../VaultProxy.sol";
import "../../interface/IVault.sol";
import "../interface/IVaultFactory.sol";
import "../../inheritance/OwnableWhitelist.sol";

contract RegularVaultFactory is OwnableWhitelist, IVaultFactory {
  address public vaultImplementation = 0xCf5F83F8FE0AB0f9E9C1db07E6606dD598b2bbf5;
  address public lastDeployedAddress = address(0);

  function deploy(address _storage, address underlying) override external onlyWhitelisted returns (address) {
    lastDeployedAddress = address(new VaultProxy(vaultImplementation));
    IVault(lastDeployedAddress).initializeVault(
      _storage,
      underlying,
      10000,
      10000
    );

    return lastDeployedAddress;
  }

  function changeDefaultImplementation(address newImplementation) external onlyOwner {
    require(newImplementation != address(0), "Must be set");
    vaultImplementation = newImplementation;
  }

  function info(address vault) override external view returns(address Underlying, address NewVault) {
    Underlying = IVault(vault).underlying();
    NewVault = vault;
  }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./inheritance/Governable.sol";
import "./interface/IRewardPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FeeRewardForwarder is Governable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);

  address constant public ifarm = address(0xab0b2ddB9C7e440fAc8E140A89c0dbCBf2d7Bbff);
  address constant public sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
  address constant public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address constant public aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);


  mapping (address => mapping (address => address[])) public routes;
  mapping (address => mapping (address => address[])) public routers;

  address constant public quickswapRouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address constant public sushiswapRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // the targeted reward token to convert everything to
  address public targetToken = weth;
  address public profitSharingPool;

  event TokenPoolSet(address token, address pool);

  constructor(address _storage) public Governable(_storage) {
    profitSharingPool = governance();

    routes[quick][weth] = [quick, weth];
    routers[quick][weth] = [quickswapRouter];

    routes[sushi][weth] = [sushi, weth];
    routers[sushi][weth] = [sushiswapRouter];

    routes[wmatic][weth] = [wmatic, weth];
    routers[wmatic][weth] = [quickswapRouter];
  }

  /*
  *   Set the pool that will receive the reward token
  *   based on the address of the reward Token
  */
  function setEOA(address _eoa) public onlyGovernance {
    profitSharingPool = _eoa;
    targetToken = weth;
    emit TokenPoolSet(targetToken, _eoa);
  }

  /**
  * Sets the path for swapping tokens to the to address
  * The to address is not validated to match the targetToken,
  * so that we could first update the paths, and then,
  * set the new target
  */
  function setConversionPath(address[] memory _route, address[] memory _routers)
    public
    onlyGovernance
  {
    require(
      _routers.length == 1 || _routers.length == _route.length-1,
      "Provide either 1 router in total, or 1 router per intermediate pair"
    );
    address from = _route[0];
    address to = _route[_route.length-1];
    routes[from][to] = _route;
    routers[from][to] = _routers;
  }

  // Transfers the funds from the msg.sender to the pool
  // under normal circumstances, msg.sender is the strategy
  function poolNotifyFixedTarget(address _token, uint256 _amount) external {
    uint256 remainingAmount = _amount;

    if (_token == weth) {
      // this is already the right token
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
    } else {

      // we need to convert _token to WETH
      if (routes[_token][targetToken].length > 1) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
        uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
        if (routers[_token][targetToken].length == 1) {
          liquidate(_token, targetToken, balanceToSwap);
        } else if (routers[_token][targetToken].length > 1) {
          liquidateMultiRouter(_token, targetToken, balanceToSwap);
        } else {
          revert("FeeRewardForwarder: liquidation routers not set");
        }

        // now we can send this token forward
        uint256 convertedRewardAmount = IERC20(targetToken).balanceOf(address(this));

        IERC20(targetToken).safeTransfer(profitSharingPool, convertedRewardAmount);
      } else {
        // else the route does not exist for this token
        // do not take any fees and revert.
        // It's better to set the liquidation path then perform it again,
        // rather then leaving the funds in controller
        revert("FeeRewardForwarder: liquidation path doesn't exist");
      }
    }
  }

  function liquidate(address _from, address _to, uint256 balanceToSwap) internal {
    if(balanceToSwap > 0){
      address router = routers[_from][_to][0];
      IERC20(_from).safeApprove(router, 0);
      IERC20(_from).safeApprove(router, balanceToSwap);

      IUniswapV2Router02(router).swapExactTokensForTokens(
        balanceToSwap,
        0,
        routes[_from][_to],
        address(this),
        block.timestamp
      );
    }
  }

  function liquidateMultiRouter(address _from, address _to, uint256 balanceToSwap) internal {
    if(balanceToSwap > 0){
      address[] memory _routers = routers[_from][_to];
      address[] memory _route = routes[_from][_to];
      for (uint256 i; i < _routers.length; i++ ) {
        address router = _routers[i];
        address[] memory route = new address[](2);
        route[0] = _route[i];
        route[1] = _route[i+1];
        uint256 amount = IERC20(route[0]).balanceOf(address(this));
        IERC20(route[0]).safeApprove(router, 0);
        IERC20(route[0]).safeApprove(router, amount);

        IUniswapV2Router02(router).swapExactTokensForTokens(
          amount,
          0,
          route,
          address(this),
          block.timestamp
        );
      }
    }
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./NotifyHelperStateful.sol";
import "./NotifyHelperGeneric.sol";
import "./inheritance/Controllable.sol";

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract GlobalIncentivesHelper is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public helperControlStorage;
  address public notifyHelperGeneric;
  address public escrow;
  address public reserve;
  address public farm;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  mapping (address => address) public tokenToHelper;
  mapping (address => bool) public changer;
  mapping (address => bool) public notifier;

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender] || msg.sender == governance(), "Only notifier");
    _;
  }

  constructor(address _storage, address _farm, address _farmHelper, address _notifyHelperGeneric, address _escrow, address _reserve) public Controllable(_storage) {
    tokenToHelper[_farm] = _farmHelper;
    farm = _farm;
    notifyHelperGeneric = _notifyHelperGeneric;
    helperControlStorage = address(new Storage());
    escrow = _escrow;
    reserve = _reserve;
  }

  function notifyPools(address[] calldata tokens, uint256[] calldata totals, uint256 timestamp) external onlyNotifier {
    for (uint256 i = 0; i < tokens.length; i++) {
      // IERC20Upgradeable(tokens[i]).safeTransferFrom(msg.sender, address(this), totals[i]);
      IERC20Upgradeable(tokens[i]).approve(tokenToHelper[tokens[i]], totals[i]);
      NotifyHelperStateful(tokenToHelper[tokens[i]]).notifyPools(totals[i], timestamp);
    }
  }

  // uses generic helper
  function newToken(address token) external onlyChanger {
    newTokenWithHelper(token, notifyHelperGeneric);
  }

  // uses a specific notify helper
  function newTokenWithHelper(address token, address notifyHelper) public onlyChanger {
    require(tokenToHelper[token] == address(0), "Token already initialized");
    tokenToHelper[token] = address(new NotifyHelperStateful(
      helperControlStorage,
      notifyHelper, // the universal helper should be sufficient in all cases
      token,
      address(0), // no iFARM/ampliFARM notify helper is needed
      escrow,
      reserve
    ));
    if (notifyHelper == notifyHelperGeneric) {
      NotifyHelperGeneric(notifyHelper).setWhitelist(tokenToHelper[token], true);
    }
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(governance(), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(governance(), true);
  }

  function resetToken(address token) public onlyChanger {
    tokenToHelper[token] = address(0);
  }

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(
    address[] calldata tokens,
    address[] calldata poolAddress,
    uint256[] calldata poolPercentage,
    NotificationType[] calldata notificationType,
    bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(tokens[i], poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(
    address token,
    address poolAddress,
    uint256 poolPercentage,
    NotificationType notificationType,
    bool vests
  ) public onlyChanger {
    if (token == farm) {
      require(notificationType != NotificationType.TOKEN, "With FARM, use FARM, AMPLIFARM, or TRANSFER");
    }
    if (notificationType == NotificationType.TOKEN) {
      // we use type translation so that we can use the same contract
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(NotificationType.FARM)), vests);
    } else {
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(notificationType)), vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address token, address _escrow) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVestingEscrow(_escrow);
  }

  /// Configuration method for vesting for governance
  function setVesting(address token, uint256 _numerator, uint256 _denominator) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVesting(_numerator, _denominator);
  }

  function notificationExists(address token, address poolAddress) public view returns(bool) {
    return NotifyHelperStateful(tokenToHelper[token]).notificationExists(poolAddress);
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./Governable.sol";

contract Controllable is Governable {

  constructor(address _storage) Governable(_storage) public {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableWhitelist is Ownable {
  mapping (address => bool) public whitelist;

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender] || msg.sender == owner(), "not allowed");
    _;
  }

  function setWhitelist(address target, bool isWhitelisted) public onlyOwner {
    whitelist[target] = isWhitelisted;
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IController.sol";
import "./Controllable.sol";

contract RewardTokenProfitNotifier is Controllable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public profitSharingNumerator;
  uint256 public profitSharingDenominator;
  address public rewardToken;

  constructor(
    address _storage,
    address _rewardToken
  ) public Controllable(_storage){
    rewardToken = _rewardToken;
    // persist in the state for immutability of the fee
    profitSharingNumerator = 80;
    profitSharingDenominator = 1000;
    require(profitSharingNumerator < profitSharingDenominator, "invalid profit share");
  }

  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator).div(profitSharingDenominator);
      emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
      IERC20(rewardToken).safeApprove(controller(), 0);
      IERC20(rewardToken).safeApprove(controller(), feeAmount);

      IController(controller()).notifyFee(
        rewardToken,
        feeAmount
      );
    } else {
      emit ProfitLogInReward(0, 0, block.timestamp);
    }
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function user_checkpoint(address) external;
    function claim_rewards() external;
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}

interface ICurveLP {
    function minter() external view returns(address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_2token {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount
  ) external payable;
  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[2] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external payable;
  function calc_token_amount(
    uint256[2] calldata amounts,
    bool deposit
  ) external view returns(uint);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function feeRewardForwarder() external view returns(address);
    function setFeeRewardForwarder(address _value) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IFeeRewardForwarder {
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;
    function profitSharingPool() external view returns (address);
    function setConversionPath(address[] calldata _route, address[] calldata _routers) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

// Unifying the interface with the Synthetix Reward Pool
interface IRewardPool {
  function rewardToken() external view returns (address);
  function lpToken() external view returns (address);
  function duration() external view returns (uint256);

  function periodFinish() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);

  function stake(uint256 amountWei) external;

  // `balanceOf` would give the amount staked.
  // As this is 1 to 1, this is also the holder's share
  function balanceOf(address holder) external view returns (uint256);
  // total shares & total lpTokens staked
  function totalSupply() external view returns(uint256);

  function withdraw(uint256 amountWei) external;
  function exit() external;

  // get claimed rewards
  function earned(address holder) external view returns (uint256);

  // claim rewards
  function getReward() external;

  // notify
  function notifyRewardAmount(uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IVault {

    function initializeVault(
      address _storage,
      address _underlying,
      uint256 _toInvestNumerator,
      uint256 _toInvestDenominator
    ) external ;

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function announceStrategyUpdate(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interfaces/IMasterChef.sol";
import "../PotPool.sol";

contract MasterChefHodlStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _HODLVAULT_SLOT = 0xc26d330f887c749cb38ae7c37873ff08ac4bba7aec9113c82d48a0cf6cc145f2;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_HODLVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
  }


  function initializeMasterChefHodlStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolId,
    address _hodlVault,
    address _potPool
  ) public initializer {
    require(_rewardPool != address(0), "reward pool is empty");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(rewardPool()).poolInfo(_poolId);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolId);
    setAddress(_HODLVAULT_SLOT, _hodlVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).withdraw(poolId(), bal);
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).emergencyWithdraw(poolId());
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMasterChef(rewardPool()).deposit(poolId(), entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  // We Hodl all the rewards
  function _hodlAndNotify() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if(rewardBalance > 0) {
      IERC20(rewardToken()).safeApprove(hodlVault(), 0);
      IERC20(rewardToken()).safeApprove(hodlVault(), rewardBalance);
      IVault(hodlVault()).deposit(rewardBalance);
      uint256 fRewardBalance = IERC20(hodlVault()).balanceOf(address(this));
      IERC20(hodlVault()).safeTransfer(potPool(), fRewardBalance);
      PotPool(potPool()).notifyTargetRewardAmount(hodlVault(), fRewardBalance);
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    exitRewardPool();
    _hodlAndNotify();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    exitRewardPool();
    _hodlAndNotify();
    investAllUnderlying();
  }

  function setHodlVault(address _value) public onlyGovernance {
    require(hodlVault() == address(0), "Hodl vault already set");
    setAddress(_HODLVAULT_SLOT, _value);
  }

  function hodlVault() public view returns (address) {
    return getAddress(_HODLVAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interfaces/IMasterChef.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";


contract MasterChefStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _USE_QUICK_SLOT = 0x189f8e6d384b6a451390d61330a1995a733994439125cd881a1bdac25fe65ea2;
  bytes32 internal constant _IS_LP_ASSET_SLOT = 0xc2f3dabf55b1bdda20d5cf5fcba9ba765dfc7c9dbaf28674ce46d43d60d58768;

  // this would be reset on each upgrade
  mapping (address => address[]) public swapRoutes;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_USE_QUICK_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useQuick")) - 1));
    assert(_IS_LP_ASSET_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.isLpAsset")) - 1));
  }

  function initializeStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolID,
    bool _isLpAsset,
    bool _useQuick
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(rewardPool()).poolInfo(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);

    if (_isLpAsset) {
      address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      // these would be required to be initialized separately by governance
      swapRoutes[LPComponentToken0] = new address[](0);
      swapRoutes[LPComponentToken1] = new address[](0);
    } else {
      swapRoutes[underlying()] = new address[](0);
    }

    setBoolean(_USE_QUICK_SLOT, _useQuick);
    setBoolean(_IS_LP_ASSET_SLOT, _isLpAsset);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).withdraw(poolId(), bal);
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).emergencyWithdraw(poolId());
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMasterChef(rewardPool()).deposit(poolId(), entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setLiquidationPath(address _token, address [] memory _route) public onlyGovernance {
    swapRoutes[_token] = _route;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address routerV2;
    if(useQuick()) {
      routerV2 = quickswapRouterV2;
    } else {
      routerV2 = sushiswapRouterV2;
    }

    // allow Uniswap to sell our reward
    IERC20(rewardToken()).safeApprove(routerV2, 0);
    IERC20(rewardToken()).safeApprove(routerV2, remainingRewardBalance);

    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    if (isLpAsset()) {
      address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      uint256 toToken0 = remainingRewardBalance.div(2);
      uint256 toToken1 = remainingRewardBalance.sub(toToken0);

      uint256 token0Amount;

      if (swapRoutes[LPComponentToken0].length > 1) {
        // if we need to liquidate the token0
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          toToken0,
          amountOutMin,
          swapRoutes[LPComponentToken0],
          address(this),
          block.timestamp
        );
        token0Amount = IERC20(LPComponentToken0).balanceOf(address(this));
      } else {
        // otherwise we assme token0 is the reward token itself
        token0Amount = toToken0;
      }

      uint256 token1Amount;

      if (swapRoutes[LPComponentToken1].length > 1) {
        // sell reward token to token1
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          toToken1,
          amountOutMin,
          swapRoutes[LPComponentToken1],
          address(this),
          block.timestamp
        );
        token1Amount = IERC20(LPComponentToken1).balanceOf(address(this));
      } else {
        token1Amount = toToken1;
      }

      // provide token1 and token2 to SUSHI
      IERC20(LPComponentToken0).safeApprove(routerV2, 0);
      IERC20(LPComponentToken0).safeApprove(routerV2, token0Amount);

      IERC20(LPComponentToken1).safeApprove(routerV2, 0);
      IERC20(LPComponentToken1).safeApprove(routerV2, token1Amount);

      // we provide liquidity to sushi
      uint256 liquidity;
      (,,liquidity) = IUniswapV2Router02(routerV2).addLiquidity(
        LPComponentToken0,
        LPComponentToken1,
        token0Amount,
        token1Amount,
        1,  // we are willing to take whatever the pair gives us
        1,  // we are willing to take whatever the pair gives us
        address(this),
        block.timestamp
      );
    } else {
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        swapRoutes[underlying()],
        address(this),
        block.timestamp
      );
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    exitRewardPool();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function setUseQuick(bool _value) public onlyGovernance {
    setBoolean(_USE_QUICK_SLOT, _value);
  }

  function useQuick() public view returns (bool) {
    return getBoolean(_USE_QUICK_SLOT);
  }

  function isLpAsset() public view returns (bool) {
    return getBoolean(_IS_LP_ASSET_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
    // reset the liquidation paths
    // they need to be re-set manually
    if (isLpAsset()) {
      swapRoutes[IUniswapV2Pair(underlying()).token0()] = new address[](0);
      swapRoutes[IUniswapV2Pair(underlying()).token1()] = new address[](0);
    } else {
      swapRoutes[underlying()] = new address[](0);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IJPYCSwap {
  function swap() external;
}

contract VaultMigratable_2JPYv2 is Vault {
  using SafeERC20 for IERC20;

  address public constant __jjpy = address(0x8343091F2499FD4b6174A46D067A920a3b851FF9);
  address public constant __jpyc = address(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
  address public constant __jpycv2 = address(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
  address public constant __2jpy = address(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
  address public constant __2jpyv2 = address(0xaA91CDD7abb47F821Cf07a2d38Cc8668DEAf1bdc);
  address public constant __2jpyv2_strategy = address(0x45257F1c56bE3D381f49371b47c3EEb1E8358431);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  address public constant __jpyc_swap = address(0x382d78E8BcEa98fA04b63C19Fe97D8138C3bfC5D);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountJJPY, uint256 amountJPYC);
  event LiquidityProvided(uint256 JPYCv2Contributed, uint256 JJPYContributed, uint256 v2Liquidity);

  constructor() public {
  }

  /**
  * Migrates the vault from the 2JPY underlying to 2JPYv2 underlying
  */
  function migrateUnderlying(
    uint256 minJJPYOut, uint256 minJPYCOut,
    uint256 min2JPYv2Mint
  ) public onlyControllerOrGovernance {
    require(underlying() == __2jpy, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__2jpy).balanceOf(address(this));

    ICurveDeposit_2token(__2jpy).remove_liquidity(v1Liquidity, [minJJPYOut, minJPYCOut]);
    uint256 amountJJPY = IERC20(__jjpy).balanceOf(address(this));
    uint256 amountJPYC = IERC20(__jpyc).balanceOf(address(this));

    emit LiquidityRemoved(v1Liquidity, amountJJPY, amountJPYC);

    require(IERC20(__2jpy).balanceOf(address(this)) == 0, "Not all underlying was converted");

    IERC20(__jpyc).safeApprove(__jpyc_swap, 0);
    IERC20(__jpyc).safeApprove(__jpyc_swap, uint256(-1));
    IJPYCSwap(__jpyc_swap).swap();
    uint256 jpycv2Balance = IERC20(__jpycv2).balanceOf(address(this));

    IERC20(__jpycv2).safeApprove(__2jpyv2, 0);
    IERC20(__jpycv2).safeApprove(__2jpyv2, jpycv2Balance);
    IERC20(__jjpy).safeApprove(__2jpyv2, 0);
    IERC20(__jjpy).safeApprove(__2jpyv2, amountJJPY);

    ICurveDeposit_2token(__2jpyv2).add_liquidity([amountJJPY, jpycv2Balance], min2JPYv2Mint);
    uint256 v2Liquidity = IERC20(__2jpyv2).balanceOf(address(this));

    emit LiquidityProvided(jpycv2Balance, amountJJPY, v2Liquidity);

    _setUnderlying(__2jpyv2);
    require(underlying() == __2jpyv2, "underlying switch failed");
    _setStrategy(__2jpyv2_strategy);
    require(strategy() == __2jpyv2_strategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 jjpyLeft = IERC20(__jjpy).balanceOf(address(this));
    if (jjpyLeft > 0) {
      IERC20(__jjpy).transfer(__governance, jjpyLeft);
    }
    uint256 jpycv2Left = IERC20(__jpycv2).balanceOf(address(this));
    if (jpycv2Left > 0) {
      IERC20(__jpycv2).transfer(strategy(), jpycv2Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_bal2EUR_agEUR is Vault {
  using SafeERC20 for IERC20;

  address public constant __token0 = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
  address public constant __token1 = address(0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4);
  address public constant __lpOld = address(0x2fFbCE9099cBed86984286A54e5932414aF4B717);
  address public constant __lpNew = address(0xa48D164F6eB0EDC68bd03B56fa59E12F24499aD1);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x044b1CfaDa044f9389DA761af520574E197dCCA4);

  bytes32 public constant __poolIdNew = 0xa48d164f6eb0edc68bd03b56fa59e12f24499ad10000000000000000000007c4;

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountToken0, uint256 amountToken1);
  event LiquidityProvided(uint256 amountToken0, uint256 amountToken1, uint256 v2Liquidity);

  constructor() public {
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, __bVault, amountIn);
    IBVault(__bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  /**
  * Migrates the vault from the old Curve LP underlying to new Balancer LP underlying
  */
  function migrateUnderlying(
    uint256 minToken0Out,
    uint256 minToken1Out,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is lpOld");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);

    ICurveDeposit_2token(__lpOld).remove_liquidity(v1Liquidity, [minToken0Out, minToken1Out]);
    uint256 amount0 = IERC20(__token0).balanceOf(address(this));
    uint256 amount1 = IERC20(__token1).balanceOf(address(this));
    console.log("token0 out:      ", amount0);
    console.log("token1 out:      ", amount1);

    emit LiquidityRemoved(v1Liquidity, amount0, amount1);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__token0, __lpNew, __poolIdNew, amount0, 1);
    _balancerSwap(__token1, __lpNew, __poolIdNew, amount1, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amount0, amount1, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 token0Left = IERC20(__token0).balanceOf(address(this));
    if (token0Left > 0) {
      IERC20(__token0).transfer(strategy(), token0Left);
    }
    uint256 token1Left = IERC20(__token1).balanceOf(address(this));
    if (token1Left > 0) {
      IERC20(__token1).transfer(__governance, token1Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_bal2EUR_PAR is Vault {
  using SafeERC20 for IERC20;

  address public constant __token0 = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
  address public constant __token1 = address(0xE2Aa7db6dA1dAE97C5f5C6914d285fBfCC32A128);
  address public constant __lpOld = address(0x0f110c55EfE62c16D553A3d3464B77e1853d0e97);
  address public constant __lpNew = address(0x7d60a4Cb5cA92E2Da965637025122296ea6854f9);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x222E14Dc2f82d1d903e539C39B0C578B7353be7E);

  bytes32 public constant __poolIdNew = 0x7d60a4cb5ca92e2da965637025122296ea6854f900000000000000000000085e;

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountToken0, uint256 amountToken1);
  event LiquidityProvided(uint256 amountToken0, uint256 amountToken1, uint256 v2Liquidity);

  constructor() public {
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, __bVault, amountIn);
    IBVault(__bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  /**
  * Migrates the vault from the old Curve LP underlying to new Balancer LP underlying
  */
  function migrateUnderlying(
    uint256 minToken0Out,
    uint256 minToken1Out,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is lpOld");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);

    ICurveDeposit_2token(__lpOld).remove_liquidity(v1Liquidity, [minToken0Out, minToken1Out]);
    uint256 amount0 = IERC20(__token0).balanceOf(address(this));
    uint256 amount1 = IERC20(__token1).balanceOf(address(this));
    console.log("token0 out:      ", amount0);
    console.log("token1 out:      ", amount1);

    emit LiquidityRemoved(v1Liquidity, amount0, amount1);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__token0, __lpNew, __poolIdNew, amount0, 1);
    _balancerSwap(__token1, __lpNew, __poolIdNew, amount1, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amount0, amount1, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 token0Left = IERC20(__token0).balanceOf(address(this));
    if (token0Left > 0) {
      IERC20(__token0).transfer(strategy(), token0Left);
    }
    uint256 token1Left = IERC20(__token1).balanceOf(address(this));
    if (token1Left > 0) {
      IERC20(__token1).transfer(__governance, token1Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_balMaticX is Vault {
  using SafeERC20 for IERC20;

  address public constant __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant __maticx = address(0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6);
  address public constant __lpOld = address(0xC17636e36398602dd37Bb5d1B3a9008c7629005f);
  address public constant __lpNew = address(0xb20fC01D21A50d2C734C4a1262B4404d41fA7BF0);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x5A42FEDdD5e330AD857A17724543C5ef7FC7C9Cd);

  bytes32 public constant __poolIdOld = 0xc17636e36398602dd37bb5d1b3a9008c7629005f0002000000000000000004c4;
  bytes32 public constant __poolIdNew = 0xb20fc01d21a50d2c734c4a1262b4404d41fa7bf000000000000000000000075c;

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountToken0, uint256 amountToken1);
  event LiquidityProvided(uint256 amountToken0, uint256 amountToken1, uint256 v2Liquidity);

  constructor() public {
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerWithdraw(
    bytes32 poolId,
    uint256 amountIn,
    uint256[] memory minAmountsOut
  ) internal {
    (address[] memory poolTokens,,) = IBVault(__bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
    }

    IBVault.ExitKind exitKind = IBVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT;
    bytes memory userData = abi.encode(exitKind, amountIn);

    IBVault.ExitPoolRequest memory request;
    request.assets = assets;
    request.minAmountsOut = minAmountsOut;
    request.userData = userData;

    IBVault(__bVault).exitPool(
      poolId,
      address(this),
      payable(address(this)),
      request
    );
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, __bVault, amountIn);
    IBVault(__bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  /**
  * Migrates the vault from the old MaticX BPT underlying to new MaticX BPT underlying
  */
  function migrateUnderlying(
    uint256 minWMaticOut,
    uint256 minMaticXOut,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);
    uint256[] memory minOutput = new uint256[](2);
    minOutput[0] = minWMaticOut;
    minOutput[1] = minMaticXOut;

    _balancerWithdraw(__poolIdOld, v1Liquidity, minOutput);
    uint256 amountWMatic = IERC20(__wmatic).balanceOf(address(this));
    uint256 amountMaticX = IERC20(__maticx).balanceOf(address(this));
    console.log("WMatic out:      ", amountWMatic);
    console.log("MaticX out:      ", amountMaticX);

    emit LiquidityRemoved(v1Liquidity, amountWMatic, amountMaticX);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__wmatic, __lpNew, __poolIdNew, amountWMatic, 1);
    _balancerSwap(__maticx, __lpNew, __poolIdNew, amountMaticX, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amountWMatic, amountMaticX, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 wMaticLeft = IERC20(__wmatic).balanceOf(address(this));
    if (wMaticLeft > 0) {
      IERC20(__wmatic).transfer(strategy(), wMaticLeft);
    }
    uint256 maticXLeft = IERC20(__maticx).balanceOf(address(this));
    if (maticXLeft > 0) {
      IERC20(__maticx).transfer(__governance, maticXLeft);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_balStMatic is Vault {
  using SafeERC20 for IERC20;

  address public constant __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant __stmatic = address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4);
  address public constant __lpOld = address(0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D);
  address public constant __lpNew = address(0x8159462d255C1D24915CB51ec361F700174cD994);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x9674AdE8257BEeC0f8c6fbdEAE279EA92543D989);

  bytes32 public constant __poolIdOld = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;
  bytes32 public constant __poolIdNew = 0x8159462d255c1d24915cb51ec361f700174cd99400000000000000000000075d;

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountToken0, uint256 amountToken1);
  event LiquidityProvided(uint256 amountToken0, uint256 amountToken1, uint256 v2Liquidity);

  constructor() public {
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerWithdraw(
    bytes32 poolId,
    uint256 amountIn,
    uint256[] memory minAmountsOut
  ) internal {
    (address[] memory poolTokens,,) = IBVault(__bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
    }

    IBVault.ExitKind exitKind = IBVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT;
    bytes memory userData = abi.encode(exitKind, amountIn);

    IBVault.ExitPoolRequest memory request;
    request.assets = assets;
    request.minAmountsOut = minAmountsOut;
    request.userData = userData;

    IBVault(__bVault).exitPool(
      poolId,
      address(this),
      payable(address(this)),
      request
    );
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, __bVault, amountIn);
    IBVault(__bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  /**
  * Migrates the vault from the old MaticX BPT underlying to new MaticX BPT underlying
  */
  function migrateUnderlying(
    uint256 minWMaticOut,
    uint256 minStMaticOut,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);
    uint256[] memory minOutput = new uint256[](2);
    minOutput[0] = minWMaticOut;
    minOutput[1] = minStMaticOut;

    _balancerWithdraw(__poolIdOld, v1Liquidity, minOutput);
    uint256 amountWMatic = IERC20(__wmatic).balanceOf(address(this));
    uint256 amountStMatic = IERC20(__stmatic).balanceOf(address(this));
    console.log("WMatic out:      ", amountWMatic);
    console.log("stMatic out:     ", amountStMatic);

    emit LiquidityRemoved(v1Liquidity, amountWMatic, amountStMatic);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__wmatic, __lpNew, __poolIdNew, amountWMatic, 1);
    _balancerSwap(__stmatic, __lpNew, __poolIdNew, amountStMatic, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amountWMatic, amountStMatic, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 wMaticLeft = IERC20(__wmatic).balanceOf(address(this));
    if (wMaticLeft > 0) {
      IERC20(__wmatic).transfer(strategy(), wMaticLeft);
    }
    uint256 stMaticLeft = IERC20(__stmatic).balanceOf(address(this));
    if (stMaticLeft > 0) {
      IERC20(__stmatic).transfer(__governance, stMaticLeft);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../inheritance/Controllable.sol";
import "../interface/IVault.sol";


contract NoopStrategy is Controllable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IERC20 public underlying;
  IVault public vault;

  // These tokens cannot be claimed by the controller
  mapping(address => bool) public unsalvagableTokens;

  modifier restricted() {
    require(msg.sender == address(vault) || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  constructor(address _storage, address _vault) public
  Controllable(_storage) {
    address _underlying = IVault(_vault).underlying();
    require(_underlying != address(0), "_underlying cannot be empty");
    require(_vault != address(0), "_vault cannot be empty");
    underlying = IERC20(_underlying);
    vault = IVault(_vault);
    unsalvagableTokens[_underlying] = true;
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  /*
  * Returns the total invested amount.
  */
  function investedUnderlyingBalance() view public returns (uint256) {
    // for real strategies, need to calculate the invested balance
    return underlying.balanceOf(address(this));
  }

  /*
  * Invests all tokens that were accumulated so far
  */
  function investAllUnderlying() external restricted {
    // no-op
  }

  /*
  * Cashes everything out and withdraws to the vault
  */
  function withdrawAllToVault() external restricted {
    if (underlying.balanceOf(address(this)) > 0) {
      underlying.safeTransfer(address(vault), underlying.balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 underlyingAmount) external restricted {
    require(underlying.balanceOf(address(this)) >= underlyingAmount,
      "insufficient balance for the withdrawal");
    if (underlyingAmount > 0) {
      underlying.safeTransfer(address(vault), underlyingAmount);
    }
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external restricted {
    // a no-op
  }

  // should only be called by controller
  function salvage(address destination, address token, uint256 amount) external onlyController {
    IERC20(token).safeTransfer(destination, amount);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";

contract NoopStrategyUpgradeable is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  constructor() public BaseUpgradeableStrategy() {}

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault
  ) public initializer {

    require(_vault != address(0), "_vault cannot be empty");
    require(_underlying == IVault(_vault).underlying(), "underlying mismatch");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(0),
      address(0),
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function investedUnderlyingBalance() external view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() external restricted {
    if (IERC20(underlying()).balanceOf(address(this)) > 0) {
      IERC20(underlying()).safeTransfer(address(vault()), IERC20(underlying()).balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 amount) external restricted {
    require(IERC20(underlying()).balanceOf(address(this)) >= amount,
      "insufficient balance for the withdrawal");
    if (amount > 0) {
      IERC20(underlying()).safeTransfer(address(vault()), amount);
    }
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external restricted {
    // a no-op
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interface/IStrategy.sol";
import "./inheritance/Controllable.sol";
import "./interface/IVault.sol";


contract NoopStrategy is IStrategy, Controllable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public override underlying;
  address public override vault;

  // These tokens cannot be claimed by the controller
  mapping(address => bool) public override unsalvagableTokens;

  bool public withdrawAllCalled = false;

  constructor(address _storage, address _underlying, address _vault) public
  Controllable(_storage) {
    require(_underlying != address(0), "_underlying cannot be empty");
    require(_vault != address(0), "_vault cannot be empty");
    underlying = _underlying;
    vault = _vault;
  }

  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  /*
  * Returns the total invested amount.
  */
  function investedUnderlyingBalance() public override view returns (uint256) {
    // for real strategies, need to calculate the invested balance
    return IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Invests all tokens that were accumulated so far
  */
  function investAllUnderlying() public {
  }

  /*
  * Cashes everything out and withdraws to the vault
  */
  function withdrawAllToVault() external override restricted {
    withdrawAllCalled = true;
    if (IERC20(underlying).balanceOf(address(this)) > 0) {
      IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 amount) external override restricted {
    if (amount > 0) {
      IERC20(underlying).safeTransfer(vault, amount);
    }
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external override restricted {
    // a no-op
  }

  // should only be called by controller
  function salvage(address destination, address token, uint256 amount) external override onlyControllerOrGovernance {
    IERC20(token).safeTransfer(destination, amount);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./inheritance/Controllable.sol";
import "./PotPool.sol";

contract NotifyHelperGeneric is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event WhitelistSet(address who, bool value);

  mapping (address => bool) public alreadyNotified;
  mapping (address => bool) public whitelist;

  modifier onlyWhitelisted {
    require(whitelist[msg.sender] || msg.sender == governance(), "Only whitelisted");
    _;
  }

  constructor(address _storage)
  Controllable(_storage) public {
    setWhitelist(governance(), true);
  }

  function setWhitelist(address who, bool value) public onlyWhitelisted {
    whitelist[who] = value;
    emit WhitelistSet(who, value);
  }

  /**
  * Notifies all the pools, safe guarding the notification amount.
  */
  function notifyPools(uint256[] memory amounts,
    address[] memory pools,
    uint256 sum, address _token
  ) public onlyWhitelisted {
    require(amounts.length == pools.length, "Amounts and pools lengths mismatch");
    for (uint i = 0; i < pools.length; i++) {
      alreadyNotified[pools[i]] = false;
    }

    uint256 check = 0;
    for (uint i = 0; i < pools.length; i++) {
      require(amounts[i] > 0, "Notify zero");
      require(!alreadyNotified[pools[i]], "Duplicate pool");
      IERC20Upgradeable token = IERC20Upgradeable(_token);
      token.safeTransferFrom(msg.sender, pools[i], amounts[i]);
      PotPool(pools[i]).notifyTargetRewardAmount(_token, amounts[i]);
      check = check.add(amounts[i]);
      alreadyNotified[pools[i]] = true;
    }
    require(sum == check, "Wrong check sum");
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./inheritance/Controllable.sol";
import "./PotPool.sol";

interface INotifyHelperGeneric {
  function feeRewardForwarder() external view returns (address);

  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum, address token
  ) external;
}

interface INotifyHelperAmpliFARM {
  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum
  ) external;
}

contract NotifyHelperStateful is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  struct Notification {
    address poolAddress;
    NotificationType notificationType;
    uint256 percentage;
    bool vests;
  }

  struct WorkingNotification {
    address[] pools;
    uint256[] amounts;
    uint256 checksum;
    uint256 counter;
  }

  uint256 public VESTING_DENOMINATOR = 3;
  uint256 public VESTING_NUMERATOR = 2;

  mapping (address => bool) changer;
  mapping (address => bool) notifier;

  address public notifyHelperRegular;
  address public notifyHelperAmpliFARM;
  address public rewardToken;

  Notification[] public notifications;
  mapping (address => uint256) public poolToIndex;
  mapping (uint256 => uint256) public numbers; // NotificationType to the number of pools

  address public reserve;
  address public vestingEscrow;
  uint256 public totalPercentage; // maintain state to not have to calculate during emissions

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender], "Only notifier");
    _;
  }

  constructor(address _storage,
    address _notifyHelperRegular,
    address _rewardToken,
    address _notifyHelperAmpliFARM,
    address _escrow,
    address _reserve)
  Controllable(_storage) public {
    // used for getting a reference to FeeRewardForwarder
    notifyHelperRegular = _notifyHelperRegular;
    rewardToken = _rewardToken;
    notifyHelperAmpliFARM = _notifyHelperAmpliFARM;
    vestingEscrow = _escrow;
    reserve = _reserve;
    require(_reserve != address(0), "invalid reserve");
    require(_escrow != address(0), "invalid escrow");
  }

  /// Whitelisted entities can notify pools based on the state, both for FARM and iFARM
  /// The only whitelisted entity here would be the minter helper
  function notifyPools(uint256 total, uint256 timestamp) public onlyNotifier {
    // transfer the tokens from the msg.sender to here
    IERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, address(this), total);

    // prepare the notification data
    WorkingNotification memory ampliFARM = WorkingNotification(
      new address[](numbers[uint256(NotificationType.AMPLIFARM)]),
      new uint256[](numbers[uint256(NotificationType.AMPLIFARM)]),
      0,
      0
    );
    WorkingNotification memory regular = WorkingNotification(
      new address[](numbers[uint256(NotificationType.FARM)]),
      new uint256[](numbers[uint256(NotificationType.FARM)]),
      0,
      0
    );
    uint256 vestingAmount = 0;
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      if (notification.notificationType == NotificationType.TRANSFER) {
        // simple transfer
        IERC20Upgradeable(rewardToken).safeTransfer(
          notification.poolAddress,
          total.mul(notification.percentage).div(totalPercentage)
        );
      } else {
        // FARM or ampliFARM notification
        WorkingNotification memory toUse = notification.notificationType == NotificationType.FARM ? regular : ampliFARM;
        toUse.amounts[toUse.counter] = total.mul(notification.percentage).div(totalPercentage);
        if (notification.vests) {
          uint256 toVest = toUse.amounts[toUse.counter].mul(VESTING_NUMERATOR).div(VESTING_DENOMINATOR);
          toUse.amounts[toUse.counter] = toUse.amounts[toUse.counter].sub(toVest);
          vestingAmount = vestingAmount.add(toVest);
          emit Vesting(notification.poolAddress, toVest);
        }
        toUse.pools[toUse.counter] = notification.poolAddress;
        toUse.checksum = toUse.checksum.add(toUse.amounts[toUse.counter]);
        toUse.counter = toUse.counter.add(1);
      }
    }

    // handle vesting
    if (vestingAmount > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(vestingEscrow, vestingAmount);
    }

    // ampliFARM notifications
    if (ampliFARM.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperAmpliFARM, ampliFARM.checksum);
      INotifyHelperAmpliFARM(notifyHelperAmpliFARM).notifyPools(ampliFARM.amounts, ampliFARM.pools, ampliFARM.checksum);
    }

    // regular notifications
    if (regular.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperRegular, regular.checksum);
      INotifyHelperGeneric(notifyHelperRegular).notifyPools(
        regular.amounts, regular.pools, regular.checksum, rewardToken
      );
    }

    // send rest to the reserve
    uint256 remainingBalance = IERC20Upgradeable(rewardToken).balanceOf(address(this));
    if (remainingBalance > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(reserve, remainingBalance);
    }
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(address[] calldata poolAddress, uint256[] calldata poolPercentage, NotificationType[] calldata notificationType, bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(address poolAddress, uint256 poolPercentage, NotificationType notificationType, bool vests) public onlyChanger {
    require(notificationType != NotificationType.VOID, "Use valid indication");
    require(notificationType != NotificationType.TOKEN, "We do not use TOKEN here");
    if (notificationExists(poolAddress) && poolPercentage == 0) {
      // remove
      removeNotification(poolAddress);
    } else if (notificationExists(poolAddress)) {
      // update
      updateNotification(poolAddress, notificationType, poolPercentage, vests);
    } else if (poolPercentage > 0) {
      // add because it does not exist
      addNotification(poolAddress, poolPercentage, notificationType, vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address _escrow) external onlyGovernance {
    vestingEscrow = _escrow;
  }

  /// Configuration method for vesting for governance
  function setVesting(uint256 _numerator, uint256 _denominator) external onlyGovernance {
    VESTING_DENOMINATOR = _numerator;
    VESTING_NUMERATOR = _denominator;
  }

  function notificationExists(address poolAddress) public view returns(bool) {
    if (notifications.length == 0) return false;
    if (poolToIndex[poolAddress] != 0) return true;
    return (notifications[0].poolAddress == poolAddress);
  }

  function removeNotification(address poolAddress) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    uint256 index = poolToIndex[poolAddress];
    Notification storage notification = notifications[index];

    totalPercentage = totalPercentage.sub(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].sub(1);

    // move the last element here and pop from the array
    notifications[index] = notifications[notifications.length.sub(1)];
    poolToIndex[notifications[index].poolAddress] = index;
    poolToIndex[poolAddress] = 0;
    notifications.pop();
  }

  function updateNotification(address poolAddress, NotificationType notificationType, uint256 percentage, bool vesting) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    require(percentage > 0, "notification is 0");
    uint256 index = poolToIndex[poolAddress];
    totalPercentage = totalPercentage.sub(notifications[index].percentage).add(percentage);
    notifications[index].percentage = percentage;
    notifications[index].vests = vesting;
    if (notifications[index].notificationType != notificationType) {
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].sub(1);
      notifications[index].notificationType = notificationType;
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].add(1);
    }
  }

  function addNotification(address poolAddress, uint256 percentage, NotificationType notificationType, bool vesting) internal {
    require(!notificationExists(poolAddress), "notification exists");
    require(percentage > 0, "notification is 0");
    require(PotPool(poolAddress).getRewardTokenIndex(rewardToken) != uint256(-1), "Token not configured on pot pool");
    Notification memory notification = Notification(poolAddress, notificationType, percentage, vesting);
    notifications.push(notification);
    totalPercentage = totalPercentage.add(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].add(1);
    poolToIndex[notification.poolAddress] = notifications.length.sub(1);
    require(notificationExists(poolAddress), "notification was not added");
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  function getConfig(uint256 totalAmount) external view returns(address[] memory, uint256[] memory, uint256[] memory) {
    address[] memory pools = new address[](notifications.length);
    uint256[] memory percentages = new uint256[](notifications.length);
    uint256[] memory amounts = new uint256[](notifications.length);
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      pools[i] = notification.poolAddress;
      percentages[i] = notification.percentage.mul(1000000).div(totalPercentage);
      amounts[i] = notification.percentage.mul(totalAmount).div(totalPercentage);
    }
    return (pools, percentages, amounts);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./inheritance/Controllable.sol";
import "./interface/IController.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {

    mapping (address => bool) public rewardDistribution;

    constructor(address[] memory _rewardDistributions) public {
        // multisig on Matic
        rewardDistribution[0x39cC360806b385C96969ce9ff26c23476017F652] = true;
        // NotifyHelper
        rewardDistribution[0xF71042C88458ff1702c3870f62F4c764712Cc9F0] = true;

        for(uint256 i = 0; i < _rewardDistributions.length; i++) {
          rewardDistribution[_rewardDistributions[i]] = true;
        }
    }

    function notifyTargetRewardAmount(address rewardToken, uint256 reward) external virtual;
    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(rewardDistribution[_msgSender()], "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address[] calldata _newRewardDistribution, bool _flag)
        external
        onlyOwner
    {
        for(uint256 i = 0; i < _newRewardDistribution.length; i++){
          rewardDistribution[_newRewardDistribution[i]] = _flag;
        }
    }
}

contract PotPool is IRewardDistributionRecipient, Controllable, ERC20 {

    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public lpToken;
    uint256 public duration; // making it not a constant is less gas efficient, but portable

    mapping(address => uint256) public stakedBalanceOf;

    mapping (address => bool) smartContractStakers;
    address[] public rewardTokens;
    mapping(address => uint256) public periodFinishForToken;
    mapping(address => uint256) public rewardRateForToken;
    mapping(address => uint256) public lastUpdateTimeForToken;
    mapping(address => uint256) public rewardPerTokenStoredForToken;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
    mapping(address => mapping(address => uint256)) public rewardsForToken;

    event RewardAdded(address rewardToken, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address rewardToken, uint256 reward);
    event RewardDenied(address indexed user, address rewardToken, uint256 reward);
    event SmartContractRecorded(address indexed smartContractAddress, address indexed smartContractInitiator);

    modifier onlyGovernanceOrRewardDistribution() {
      require(msg.sender == governance() || rewardDistribution[msg.sender], "Not governance nor reward distribution");
      _;
    }

    modifier updateRewards(address account) {
      for(uint256 i = 0; i < rewardTokens.length; i++ ){
        address rt = rewardTokens[i];
        rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
        lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
        if (account != address(0)) {
            rewardsForToken[rt][account] = earned(rt, account);
            userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
        }
      }
      _;
    }

    modifier updateReward(address account, address rt){
      rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
      lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
      if (account != address(0)) {
          rewardsForToken[rt][account] = earned(rt, account);
          userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
      }
      _;
    }

    /** View functions to respect old interface */
    function rewardToken() public view returns(address) {
      return rewardTokens[0];
    }

    function rewardPerToken() public view returns(uint256) {
      return rewardPerToken(rewardTokens[0]);
    }

    function periodFinish() public view returns(uint256) {
      return periodFinishForToken[rewardTokens[0]];
    }

    function rewardRate() public view returns(uint256) {
      return rewardRateForToken[rewardTokens[0]];
    }

    function lastUpdateTime() public view returns(uint256) {
      return lastUpdateTimeForToken[rewardTokens[0]];
    }

    function rewardPerTokenStored() public view returns(uint256) {
      return rewardPerTokenStoredForToken[rewardTokens[0]];
    }

    function userRewardPerTokenPaid(address user) public view returns(uint256) {
      return userRewardPerTokenPaidForToken[rewardTokens[0]][user];
    }

    function rewards(address user) public view returns(uint256) {
      return rewardsForToken[rewardTokens[0]][user];
    }

    // [Hardwork] setting the reward, lpToken, duration, and rewardDistribution for each pool
    constructor(
        address[] memory _rewardTokens,
        address _lpToken,
        uint256 _duration,
        address[] memory _rewardDistribution,
        address _storage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
      ) public
      ERC20(_name, _symbol)
      IRewardDistributionRecipient(_rewardDistribution)
      Controllable(_storage) // only used for referencing the grey list
    {
        require(_decimals == ERC20(_lpToken).decimals(), "decimals has to be aligned with the lpToken");
        require(_rewardTokens.length != 0, "should initialize with at least 1 rewardToken");
        rewardTokens = _rewardTokens;
        lpToken = _lpToken;
        duration = _duration;
    }

    function lastTimeRewardApplicable(uint256 i) public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[i]);
    }

    function lastTimeRewardApplicable(address rt) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishForToken[rt]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[0]);
    }

    function rewardPerToken(uint256 i) public view returns (uint256) {
        return rewardPerToken(rewardTokens[i]);
    }

    function rewardPerToken(address rt) public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredForToken[rt];
        }
        return
            rewardPerTokenStoredForToken[rt].add(
                lastTimeRewardApplicable(rt)
                    .sub(lastUpdateTimeForToken[rt])
                    .mul(rewardRateForToken[rt])
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(uint256 i, address account) public view returns (uint256) {
        return earned(rewardTokens[i], account);
    }

    function earned(address account) public view returns (uint256) {
        return earned(rewardTokens[0], account);
    }

    function earned(address rt, address account) public view returns (uint256) {
        return
            stakedBalanceOf[account]
                .mul(rewardPerToken(rt).sub(userRewardPerTokenPaidForToken[rt][account]))
                .div(1e18)
                .add(rewardsForToken[rt][account]);
    }

    function stake(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        recordSmartContract();
        super._mint(msg.sender, amount); // ERC20 is used as a staking receipt
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].add(amount);
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super._burn(msg.sender, amount);
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].sub(amount);
        IERC20(lpToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(Math.min(stakedBalanceOf[msg.sender], balanceOf(msg.sender)));
        getAllRewards();
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    /// The implementation is semantically analogous to getReward(), but uses a push pattern
    /// instead of pull pattern.
    function pushAllRewards(address recipient) public updateRewards(recipient) onlyGovernance {
      bool rewardPayout = (!smartContractStakers[recipient] || !IController(controller()).greyList(recipient));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        uint256 reward = earned(rewardTokens[i], recipient);
        if (reward > 0) {
            rewardsForToken[rewardTokens[i]][recipient] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            if (rewardPayout) {
                IERC20(rewardTokens[i]).safeTransfer(recipient, reward);
                emit RewardPaid(recipient, rewardTokens[i], reward);
            } else {
                emit RewardDenied(recipient, rewardTokens[i], reward);
            }
        }
      }
    }

    function getAllRewards() public updateRewards(msg.sender) {
      recordSmartContract();
      bool rewardPayout = (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        _getRewardAction(rewardTokens[i], rewardPayout);
      }
    }

    function getReward(address rt) public updateReward(msg.sender, rt) {
      recordSmartContract();
      _getRewardAction(
        rt,
        // don't payout if it is a grey listed smart contract
        (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender))
      );
    }

    function getReward() public {
      getReward(rewardTokens[0]);
    }

    function _getRewardAction(address rt, bool rewardPayout) internal {
      uint256 reward = earned(rt, msg.sender);
      if (reward > 0 && IERC20(rt).balanceOf(address(this)) >= reward ) {
          rewardsForToken[rt][msg.sender] = 0;
          // If it is a normal user and not smart contract,
          // then the requirement will pass
          // If it is a smart contract, then
          // make sure that it is not on our greyList.
          if (rewardPayout) {
              IERC20(rt).safeTransfer(msg.sender, reward);
              emit RewardPaid(msg.sender, rt, reward);
          } else {
              emit RewardDenied(msg.sender, rt, reward);
          }
      }
    }

    function addRewardToken(address rt) public onlyGovernanceOrRewardDistribution {
      require(getRewardTokenIndex(rt) == uint256(-1), "Reward token already exists");
      rewardTokens.push(rt);
    }

    function removeRewardToken(address rt) public onlyGovernanceOrRewardDistribution {
      uint256 i = getRewardTokenIndex(rt);
      require(i != uint256(-1), "Reward token does not exists");
      require(periodFinishForToken[rewardTokens[i]] < block.timestamp, "Can only remove when the reward period has passed");
      require(rewardTokens.length > 1, "Cannot remove the last reward token");
      uint256 lastIndex = rewardTokens.length - 1;

      // swap
      rewardTokens[i] = rewardTokens[lastIndex];

      // delete last element
      rewardTokens.pop();
    }

    // If the return value is MAX_UINT256, it means that
    // the specified reward token is not in the list
    function getRewardTokenIndex(address rt) public view returns(uint256) {
      for(uint i = 0 ; i < rewardTokens.length ; i++){
        if(rewardTokens[i] == rt)
          return i;
      }
      return uint256(-1);
    }

    function notifyTargetRewardAmount(address _rewardToken, uint256 reward)
        public override
        onlyRewardDistribution
        updateRewards(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

        uint256 i = getRewardTokenIndex(_rewardToken);
        require(i != uint256(-1), "rewardTokenIndex not found");

        if (block.timestamp >= periodFinishForToken[_rewardToken]) {
            rewardRateForToken[_rewardToken] = reward.div(duration);
        } else {
            uint256 remaining = periodFinishForToken[_rewardToken].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRateForToken[_rewardToken]);
            rewardRateForToken[_rewardToken] = reward.add(leftover).div(duration);
        }
        lastUpdateTimeForToken[_rewardToken] = block.timestamp;
        periodFinishForToken[_rewardToken] = block.timestamp.add(duration);
        emit RewardAdded(_rewardToken, reward);
    }

    function notifyRewardAmount(uint256 reward)
        external override
        onlyRewardDistribution
        updateRewards(address(0))
    {
      notifyTargetRewardAmount(rewardTokens[0], reward);
    }

    function rewardTokensLength() public view returns(uint256){
      return rewardTokens.length;
    }

    // Harvest Smart Contract recording
    function recordSmartContract() internal {
      if( tx.origin != msg.sender ) {
        smartContractStakers[msg.sender] = true;
        emit SmartContractRecorded(msg.sender, tx.origin);
      }
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "../interface/uniswap/IUniswapV2Router02.sol";
import "./interface/IStakingDualRewards.sol";
import "./interface/IDragonLair.sol";
import "../interface/uniswap/IUniswapV2Pair.sol";

contract DualRewardsLPStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant dragonLair = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
  address public constant quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // this would be reset on each upgrade
  mapping (address => address[]) public BASE2deposit;
  mapping (address => address[]) public reward2BASE;
  mapping (address => bool) public useQuick;
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    bool _isQuickPair
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt = IStakingDualRewards(rewardPool()).stakingToken();
    require(_lpt == underlying(), "StakingToken does not match underlying");
    if (_isQuickPair) {
      useQuick[underlying()] = true;
    }
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      bal = IStakingDualRewards(rewardPool()).balanceOf(address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
        IStakingDualRewards(rewardPool()).exit();
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IStakingDualRewards(rewardPool()).withdraw(bal);
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IStakingDualRewards(rewardPool()).stake(entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setDepositLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with baseReward");
    address finalToken = _route[_route.length-1];
    address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();
    require(finalToken == LPComponentToken0 || finalToken == LPComponentToken1, "Path should end with LP component");
    BASE2deposit[finalToken] = _route;
    useQuick[finalToken] = _useQuick;
  }

  function setRewardLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    address startToken = _route[0];
    address finalToken = _route[_route.length-1];
    require(finalToken == rewardToken(), "Path should end with baseReward");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (startToken == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2BASE[startToken] = _route;
    useQuick[startToken] = _useQuick;
  }

  /**
   * if the pool gets dQuick as reward token it has to first be converted to QUICK
   * by leaving the dragonLair
   */
  function convertDQuickToQuick() internal {
    uint256 dQuickBalance = IERC20(dragonLair).balanceOf(address(this));
    if (dQuickBalance > 0){
      IDragonLair(dragonLair).leave(dQuickBalance);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapoolId exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      if (token == quick){
        convertDQuickToQuick();
      }
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0 || reward2BASE[token].length < 2) {
        continue;
      }

      address routerV2;
      if(useQuick[token]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(token).safeApprove(routerV2, 0);
      IERC20(token).safeApprove(routerV2, rewardBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        rewardBalance, 1, reward2BASE[token], address(this), block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();
    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);
    uint256 token0Amount;
    uint256 token1Amount;
    uint256 amountOutMin = 1;

    if (BASE2deposit[LPComponentToken0].length > 1) {
      address routerV2;
      if(useQuick[LPComponentToken0]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, toToken0);
      // if we need to liquidate the token0
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        toToken0,
        amountOutMin,
        BASE2deposit[LPComponentToken0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(LPComponentToken0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    if (BASE2deposit[LPComponentToken1].length > 1) {
      address routerV2;
      if(useQuick[LPComponentToken1]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, toToken1);
      // sell reward token to token1
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        toToken1,
        amountOutMin,
        BASE2deposit[LPComponentToken1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(LPComponentToken1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }
    address routerV2;
    if(useQuick[underlying()]) {
      routerV2 = quickswapRouterV2;
    } else {
      routerV2 = sushiswapRouterV2;
    }

    // provide token1 and token2 to SUSHI
    IERC20(LPComponentToken0).safeApprove(routerV2, 0);
    IERC20(LPComponentToken0).safeApprove(routerV2, token0Amount);

    IERC20(LPComponentToken1).safeApprove(routerV2, 0);
    IERC20(LPComponentToken1).safeApprove(routerV2, token1Amount);

    // we provide liquidity to sushi
    IUniswapV2Router02(routerV2).addLiquidity(
      LPComponentToken0,
      LPComponentToken1,
      token0Amount,
      token1Amount,
      1,  // we are willing to take whatever the pair gives us
      1,  // we are willing to take whatever the pair gives us
      address(this),
      block.timestamp
    );
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IStakingDualRewards(rewardPool()).withdraw(toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IStakingDualRewards(rewardPool()).getReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair {

  function quick() external view returns (IERC20);

  // Enter the lair. Pay some QUICK. Earn some dragon QUICK.
  function enter(uint256 _quickAmount) external;

  // Leave the lair. Claim back your QUICK.
  function leave(uint256 _dQuickAmount) external;

  // returns the total amount of QUICK an address has in the contract including fees earned
  function QUICKBalance(address _account) external view returns (uint256 quickAmount_);

  //returns how much QUICK someone gets for depositing dQUICK
  function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint256 quickAmount_);

  //returns how much dQUICK someone gets for depositing QUICK
  function QUICKForDQUICK(uint256 _quickAmount) external view returns (uint256 dQuickAmount_);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IStakingDualRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerTokenA() external view returns (uint256);
    function rewardPerTokenB() external view returns (uint256);

    function earnedA(address account) external view returns (uint256);

    function earnedB(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardsTokenA() external view returns (address);
    function rewardsTokenB() external view returns (address);
    function stakingToken() external view returns (address);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface SNXRewardInterface {
    function withdraw(uint) external;
    function getReward() external;
    function stake(uint) external;
    function balanceOf(address) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function exit() external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interface/SNXRewardInterface.sol";
import "../StrategyBase.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SNXRewardStrategy is StrategyBase {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bool pausedInvesting = false; // When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.
  bool getRewardWhenExit = true;
  SNXRewardInterface public rewardPool;

  address[] public liquidationPath;

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting, "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardToken,
    address _router
  )
  StrategyBase(_storage, _underlying, _vault, _rewardToken, _router)
  public {
    rewardToken = _rewardToken;
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    if(getRewardWhenExit){
      rewardPool.exit();
    } else {
      rewardPool.withdraw(rewardPool.balanceOf(address(this)));
    }
    pausedInvesting = true;
  }

  function setGetRewardWhenExit(bool flag) public onlyGovernance {
    getRewardWhenExit = flag;
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    pausedInvesting = false;
  }

  /**
  * Sets the route for liquidating the reward token to the underlying token
  */
  function setLiquidationPath(address[] memory _newPath) public onlyGovernance {
    liquidationPath = _newPath;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));

    if (rewardAmount > 0 // we have tokens to swap
      && liquidationPath.length > 1 // and we have a route to do the swap
    ) {
      notifyProfitInRewardToken(rewardAmount);
      rewardAmount = IERC20(rewardToken).balanceOf(address(this));

      // we can accept 1 as minimum because this is called only by a trusted role
      uint256 amountOutMin = 1;

      IERC20(rewardToken).safeApprove(routerV2, 0);
      IERC20(rewardToken).safeApprove(routerV2, rewardAmount);

      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        rewardAmount,
        amountOutMin,
        liquidationPath,
        address(this),
        block.timestamp
      );
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).

    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if(underlyingBalance > 0) {
      IERC20(underlying).safeApprove(address(rewardPool), 0);
      IERC20(underlying).safeApprove(address(rewardPool), underlyingBalance);
      rewardPool.stake(underlyingBalance);
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool) != address(0)) {
      if (rewardPool.balanceOf(address(this)) > 0) {
        rewardPool.exit();
      }
    }
    _liquidateReward();
    if (IERC20(underlying).balanceOf(address(this)) > 0) {
      IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit

    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if(amount > underlyingBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(underlyingBalance);
      rewardPool.withdraw(Math.min(rewardPool.balanceOf(address(this)), needToWithdraw));
    }

    IERC20(underlying).safeTransfer(vault, amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (address(rewardPool) == address(0)) {
      return IERC20(underlying).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPool.balanceOf(address(this)).add(IERC20(underlying).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  *   Those are protected by the "unsalvagableTokens". To check, see where those are being flagged.
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    rewardPool.getReward();
    _liquidateReward();
    investAllUnderlying();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../StrategyBase.sol";
import "../interface/uniswap/IUniswapV2Router02.sol";
import "../interface/IVault.sol";
import "./interface/SNXRewardInterface.sol";
import "./interface/IDragonLair.sol";
import "../interface/uniswap/IUniswapV2Pair.sol";

contract SNXRewardUniLPStrategy is StrategyBase {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public uniLPComponentToken0;
  address public uniLPComponentToken1;

  bool public pausedInvesting = false; // When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.

  SNXRewardInterface public rewardPool;
  bool public isDragonLairPool = true;
  address constant public dragonLair = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

  // a flag for disabling selling for simplified emergency exit
  bool public sell = true;
  uint256 public sellFloor = 0;

  mapping (address => address[]) public uniswapRoutes;

  event ProfitsNotCollected();

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting, "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _routerV2,
    bool _isDragonLairPool
  )
  StrategyBase(_storage, _underlying, _vault, _rewardToken, _routerV2)
  public {
    uniLPComponentToken0 = IUniswapV2Pair(underlying).token0();
    uniLPComponentToken1 = IUniswapV2Pair(underlying).token1();
    rewardPool = SNXRewardInterface(_rewardPool);
    isDragonLairPool = _isDragonLairPool;
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    rewardPool.exit();
    pausedInvesting = true;
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    pausedInvesting = false;
  }


  function setLiquidationPaths(address [] memory _uniswapRouteToToken0, address [] memory _uniswapRouteToToken1) public onlyGovernance {
    uniswapRoutes[uniLPComponentToken0] = _uniswapRouteToToken0;
    uniswapRoutes[uniLPComponentToken1] = _uniswapRouteToToken1;
  }

  /**
   * if the pool gets dQuick as reward token it has to first be converted to QUICK
   * by leaving the dragonLair
   */
  function convertDQuickToQuickIfNecessary() internal {
    if(isDragonLairPool) {
        uint256 dQuickBalance = IERC20(dragonLair).balanceOf(address(this));
        IDragonLair(dragonLair).leave(dQuickBalance);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    convertDQuickToQuickIfNecessary();

    uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
    if (!sell || rewardBalance < sellFloor) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected();
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken).balanceOf(address(this));

    if (remainingRewardBalance > 0) {

      // allow Uniswap to sell our reward
      uint256 amountOutMin = 1;

      IERC20(rewardToken).safeApprove(routerV2, 0);
      IERC20(rewardToken).safeApprove(routerV2, remainingRewardBalance);

      // sell reward token to token1
      // we can accept 1 as minimum because this is called only by a trusted role

      uint256 token0Amount;

      if (uniswapRoutes[uniLPComponentToken0].length > 1) {
        // in some cases, the reward token is the same as one of the components
        // only swap when this is NOT the case

        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          remainingRewardBalance/2,
          amountOutMin,
          uniswapRoutes[address(uniLPComponentToken0)],
          address(this),
          block.timestamp
        );

        token0Amount = IERC20(uniLPComponentToken0).balanceOf(address(this));
        remainingRewardBalance = IERC20(rewardToken).balanceOf(address(this));
      } else {
        // no swap, just adjust the numbers
        token0Amount = remainingRewardBalance/2;
        remainingRewardBalance = remainingRewardBalance.sub(token0Amount);
      }

      // sell reward token to token2
      // we can accept 1 as minimum because this is called only by a trusted role

      if (uniswapRoutes[uniLPComponentToken1].length > 1) {
        // in some cases, the reward token is the same as one of the components
        // only swap when this is NOT the case
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          remainingRewardBalance,
          amountOutMin,
          uniswapRoutes[uniLPComponentToken1],
          address(this),
          block.timestamp
        );
      }
      uint256 token1Amount = IERC20(uniLPComponentToken1).balanceOf(address(this));

      // provide token1 and token2 to UniLPToken

      IERC20(uniLPComponentToken0).safeApprove(routerV2, 0);
      IERC20(uniLPComponentToken0).safeApprove(routerV2, token0Amount);

      IERC20(uniLPComponentToken1).safeApprove(routerV2, 0);
      IERC20(uniLPComponentToken1).safeApprove(routerV2, token1Amount);

      uint256 liquidity;
      (,,liquidity) = IUniswapV2Router02(routerV2).addLiquidity(
        uniLPComponentToken0,
        uniLPComponentToken1,
        token0Amount,
        token1Amount,
        1,  // we are willing to take whatever the pair gives us
        1,
        address(this),
        block.timestamp
      );
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying).balanceOf(address(this)) > 0) {
      IERC20(underlying).approve(address(rewardPool), IERC20(underlying).balanceOf(address(this)));
      rewardPool.stake(IERC20(underlying).balanceOf(address(this)));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool) != address(0)) {
      if (rewardPool.balanceOf(address(this)) > 0) {
        rewardPool.exit();
      }
    }
    _liquidateReward();

    if (IERC20(underlying).balanceOf(address(this)) > 0) {
      IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    if(amount > IERC20(underlying).balanceOf(address(this))){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(IERC20(underlying).balanceOf(address(this)));
      rewardPool.withdraw(Math.min(rewardPool.balanceOf(address(this)), needToWithdraw));
    }

    IERC20(underlying).safeTransfer(vault, amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (address(rewardPool) == address(0)) {
      return IERC20(underlying).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPool.balanceOf(address(this)).add(IERC20(underlying).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  *   Those are protected by the "unsalvagableTokens". To check, see where those are being flagged.
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    rewardPool.getReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    sell = s;
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    sellFloor = floor;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "hardhat/console.sol";

import "./inheritance/RewardTokenProfitNotifier.sol";
import "./interface/IStrategy.sol";

abstract contract StrategyBase is RewardTokenProfitNotifier  {

  event ProfitsNotCollected(address);
  event Liquidating(address, uint256);

  address public underlying;
  address public vault;
  mapping (address => bool) public unsalvagableTokens;
  address public routerV2;

  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardToken,
    address _routerV2
  ) RewardTokenProfitNotifier(_storage, _rewardToken) public {
    underlying = _underlying;
    vault = _vault;
    unsalvagableTokens[_rewardToken] = true;
    unsalvagableTokens[_underlying] = true;
    routerV2 = _routerV2;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewarder.sol";

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function rewarder(uint256 _pid) external view returns (IRewarder);
    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function lpToken(uint256 _pid) external view returns (IERC20);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "../lib/BoringERC20.sol";
interface IRewarder {
    using BoringERC20 for IERC20;
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interface/IMiniChefV2.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";


contract MiniChefV2Strategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _IS_LP_ASSET_SLOT = 0xc2f3dabf55b1bdda20d5cf5fcba9ba765dfc7c9dbaf28674ce46d43d60d58768;
  bytes32 internal constant _SECOND_REWARD_TOKEN_SLOT = 0xd06e5f1f8ce4bdaf44326772fc9785917d444f120d759a01f1f440e0a42d67a3;

  // this would be reset on each upgrade
  mapping (address => address[]) public uniswapRoutes;
  address[] public secondRewardRoute;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_IS_LP_ASSET_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.isLpAsset")) - 1));
    assert(_SECOND_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.secondRewardToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _secondRewardToken,
    uint256 _poolID,
    bool _isLpAsset
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    IERC20 _lpt;
    _lpt = IMiniChefV2(rewardPool()).lpToken(_poolID);
    require(address(_lpt) == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);

    _setSecondRewardToken(_secondRewardToken);

    if (_isLpAsset) {
      address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      // these would be required to be initialized separately by governance
      uniswapRoutes[uniLPComponentToken0] = new address[](0);
      uniswapRoutes[uniLPComponentToken1] = new address[](0);
    } else {
      uniswapRoutes[underlying()] = new address[](0);
    }

    setBoolean(_IS_LP_ASSET_SLOT, _isLpAsset);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).withdrawAndHarvest(poolId(), bal, address(this));
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).emergencyWithdraw(poolId(), address(this));
      }
  }

  function harvestReward() internal {
      IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMiniChefV2(rewardPool()).deposit(poolId(), entireBalance, address(this));
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setLiquidationPath(address _token, address [] memory _route) public onlyGovernance {
    uniswapRoutes[_token] = _route;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    // swap second reward token to reward token
    uint256 secondRewardBalance = IERC20(secondRewardToken()).balanceOf(address(this));

    // allow Uniswap to sell our reward
    IERC20(secondRewardToken()).safeApprove(sushiswapRouterV2, 0);
    IERC20(secondRewardToken()).safeApprove(sushiswapRouterV2, secondRewardBalance);

    if (secondRewardBalance > 0) {
      IUniswapV2Router02(sushiswapRouterV2).swapExactTokensForTokens(
        secondRewardBalance,
        amountOutMin,
        secondRewardRoute,
        address(this),
        block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Uniswap to sell our reward
    IERC20(rewardToken()).safeApprove(sushiswapRouterV2, 0);
    IERC20(rewardToken()).safeApprove(sushiswapRouterV2, remainingRewardBalance);

    if (isLpAsset()) {
      address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      uint256 toToken0 = remainingRewardBalance.div(2);
      uint256 toToken1 = remainingRewardBalance.sub(toToken0);

      uint256 token0Amount;

      if (uniswapRoutes[uniLPComponentToken0].length > 1) {
        // if we need to liquidate the token0
        IUniswapV2Router02(sushiswapRouterV2).swapExactTokensForTokens(
          toToken0,
          amountOutMin,
          uniswapRoutes[uniLPComponentToken0],
          address(this),
          block.timestamp
        );
        token0Amount = IERC20(uniLPComponentToken0).balanceOf(address(this));
      } else {
        // otherwise we assme token0 is the reward token itself
        token0Amount = toToken0;
      }

      uint256 token1Amount;

      if (uniswapRoutes[uniLPComponentToken1].length > 1) {
        // sell reward token to token1
        IUniswapV2Router02(sushiswapRouterV2).swapExactTokensForTokens(
          toToken1,
          amountOutMin,
          uniswapRoutes[uniLPComponentToken1],
          address(this),
          block.timestamp
        );
        token1Amount = IERC20(uniLPComponentToken1).balanceOf(address(this));
      } else {
        token1Amount = toToken1;
      }

      // provide token1 and token2 to SUSHI
      IERC20(uniLPComponentToken0).safeApprove(sushiswapRouterV2, 0);
      IERC20(uniLPComponentToken0).safeApprove(sushiswapRouterV2, token0Amount);

      IERC20(uniLPComponentToken1).safeApprove(sushiswapRouterV2, 0);
      IERC20(uniLPComponentToken1).safeApprove(sushiswapRouterV2, token1Amount);

      // we provide liquidity to sushi
      uint256 liquidity;
      (,,liquidity) = IUniswapV2Router02(sushiswapRouterV2).addLiquidity(
        uniLPComponentToken0,
        uniLPComponentToken1,
        token0Amount,
        token1Amount,
        1,  // we are willing to take whatever the pair gives us
        1,  // we are willing to take whatever the pair gives us
        address(this),
        block.timestamp
      );
    } else {
      IUniswapV2Router02(sushiswapRouterV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        uniswapRoutes[underlying()],
        address(this),
        block.timestamp
      );
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMiniChefV2(rewardPool()).withdraw(poolId(), toWithdraw, address(this));
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    harvestReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  // complexRewarder second reward
  function _setSecondRewardToken(address _address) internal {
    setAddress(_SECOND_REWARD_TOKEN_SLOT, _address);
  }

  function secondRewardToken() public view returns (address) {
    return getAddress(_SECOND_REWARD_TOKEN_SLOT);
  }

  function isLpAsset() public view returns (bool) {
    return getBoolean(_IS_LP_ASSET_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
    // reset the liquidation paths
    // they need to be re-set manually
    if (isLpAsset()) {
      uniswapRoutes[IUniswapV2Pair(underlying()).token0()] = new address[](0);
      uniswapRoutes[IUniswapV2Pair(underlying()).token1()] = new address[](0);
    } else {
      uniswapRoutes[underlying()] = new address[](0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../inheritance/ControllableInit.sol";
import "../interface/IController.sol";
import "../interface/IFeeRewardForwarder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _profitSharingNumerator,
    uint256 _profitSharingDenominator,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    _setProfitSharingNumerator(_profitSharingNumerator);
    _setProfitSharingDenominator(_profitSharingDenominator);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  // reward notification

  function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
      IERC20(rewardToken()).safeApprove(controller(), 0);
      IERC20(rewardToken()).safeApprove(controller(), feeAmount);

      IController(controller()).notifyFee(
        rewardToken(),
        feeAmount
      );
    } else {
      emit ProfitLogInReward(0, 0, block.timestamp);
    }
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BaseUpgradeableStrategyStorage {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public virtual view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public virtual view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function _setProfitSharingNumerator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_NUMERATOR_SLOT, _value);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_NUMERATOR_SLOT);
  }

  function _setProfitSharingDenominator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_DENOMINATOR_SLOT, _value);
  }

  function profitSharingDenominator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_DENOMINATOR_SLOT);
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  receive () payable external {}

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "../inheritance/IUpgradeSource.sol";
import "./BaseUpgradeabilityProxy.sol";

contract StrategyProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the strategy
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success,) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./interface/IController.sol";
import "./interface/IUpgradeSource.sol";
import "./inheritance/ControllableInit.sol";
import "./VaultStorage.sol";

contract Vault is ERC20Upgradeable, IVault, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);


  constructor() public {
  }

  // the function is name differently to not cause inheritance clash in truffle and allows tests
  function initializeVault(
    address _storage,
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator
  ) public override initializer {
    require(_toInvestNumerator <= _toInvestDenominator, "cannot invest more than 100%");
    require(_toInvestDenominator != 0, "cannot divide by 0");

    __ERC20_init(
      string(abi.encodePacked("miFARM_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("bf", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initialize(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    uint256 implementationDelay = 12 hours;
    uint256 strategyChangeDelay = 12 hours;
    VaultStorage.initialize(
      _underlying,
      _toInvestNumerator,
      _toInvestDenominator,
      underlyingUnit,
      implementationDelay,
      strategyChangeDelay
    );
  }

  function strategy() public view override returns(address) {
    return _strategy();
  }

  function underlying() public view override returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  function vaultFractionToInvestNumerator() public view returns(uint256) {
    return _vaultFractionToInvestNumerator();
  }

  function vaultFractionToInvestDenominator() public view returns(uint256) {
    return _vaultFractionToInvestDenominator();
  }

  function nextImplementation() public view returns(address) {
    return _nextImplementation();
  }

  function nextImplementationTimestamp() public view returns(uint256) {
    return _nextImplementationTimestamp();
  }

  function nextImplementationDelay() public view returns(uint256) {
    return _nextImplementationDelay();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "Strategy must be defined");
    _;
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "This smart contract has been grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined onlyControllerOrGovernance external override {
    // ensure that new funds are invested too
    invest();
    IStrategy(strategy()).doHardWork();
  }

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInVault() view public override returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() view public override returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function getPricePerFullShare() public view override returns (uint256) {
    return totalSupply() == 0
        ? underlyingUnit()
        : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /* get the user's share (in underlying)
  */
  function underlyingBalanceWithInvestmentForHolder(address holder) view external override returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function futureStrategy() public view returns (address) {
    return _futureStrategy();
  }

  function strategyUpdateTime() public view returns (uint256) {
    return _strategyUpdateTime();
  }

  function strategyTimeLock() public view returns (uint256) {
    return _strategyTimeLock();
  }

  function canUpdateStrategy(address _strategy) public view returns(bool) {
    return strategy() == address(0) // no strategy was set yet
      || (_strategy == futureStrategy()
          && block.timestamp > strategyUpdateTime()
          && strategyUpdateTime() > 0); // or the timelock has passed
  }

  /**
  * Indicates that the strategy update will happen in the future
  */
  function announceStrategyUpdate(address _strategy) public override onlyControllerOrGovernance {
    // records a new timestamp
    uint256 when = block.timestamp.add(strategyTimeLock());
    _setStrategyUpdateTime(when);
    _setFutureStrategy(_strategy);
    emit StrategyAnnounced(_strategy, when);
  }

  /**
  * Finalizes (or cancels) the strategy update by resetting the data
  */
  function finalizeStrategyUpdate() public onlyControllerOrGovernance {
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
  }

  function setStrategy(address _strategy) public override onlyControllerOrGovernance {
    require(canUpdateStrategy(_strategy),
      "The strategy exists and switch timelock did not elapse yet");
    require(_strategy != address(0), "new _strategy cannot be empty");
    require(IStrategy(_strategy).underlying() == address(underlying()), "Vault underlying must match Strategy underlying");
    require(IStrategy(_strategy).vault() == address(this), "the strategy does not belong to this vault");

    emit StrategyChanged(_strategy, strategy());
    if (address(_strategy) != address(strategy())) {
      if (address(strategy()) != address(0)) { // if the original strategy (no underscore) is defined
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IStrategy(strategy()).withdrawAllToVault();
      }
      _setStrategy(_strategy);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }
    finalizeStrategyUpdate();
  }

  function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external override onlyGovernance {
    require(denominator > 0, "denominator must be greater than 0");
    require(numerator <= denominator, "denominator must be greater than or equal to the numerator");
    _setVaultFractionToInvestNumerator(numerator);
    _setVaultFractionToInvestDenominator(denominator);
  }

  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
        .mul(vaultFractionToInvestNumerator())
        .div(vaultFractionToInvestDenominator());
    uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInVault()
        // TODO: we think that the "else" branch of the ternary operation is not
        // going to get hit
        ? remainingToInvest : underlyingBalanceInVault();
    }
  }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares.
  * Approval is assumed.
  */
  function deposit(uint256 amount) external override defense {
    _deposit(amount, msg.sender, msg.sender);
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares
  * assigned to the holder.
  * This facilitates depositing for someone else (using DepositHelper)
  */
  function depositFor(uint256 amount, address holder) public override defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance override whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) override external {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");

    if (address(strategy()) != address(0)) {
      require(IStrategy(strategy()).depositArbCheck(), "Too much arb");
    }

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, amount);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function shouldUpgrade() external view override returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./interface/IUpgradeSource.sol";
import "./upgradability/BaseUpgradeabilityProxy.sol";

contract VaultProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the vault
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success,) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract VaultStorage is Initializable {

  bytes32 internal constant _STRATEGY_SLOT = 0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
  bytes32 internal constant _UNDERLYING_SLOT = 0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
  bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;
  bytes32 internal constant _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT = 0x39122c9adfb653455d0c05043bd52fcfbc2be864e832efd3abc72ce5a3d7ed5a;
  bytes32 internal constant _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT = 0x469a3bad2fab7b936c45eecd1f5da52af89cead3e2ed7f732b6f3fc92ed32308;
  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xb1acf527cd7cd1668b30e5a9a1c0d845714604de29ce560150922c9d8c0937df;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x3bc747f4b148b37be485de3223c90b4468252967d2ea7f9fcbd8b6e653f434c9;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82ddc3be3f0c1a6870327f78f4979a0b37b21b16736ef5be6a7a7a35e530bcf0;
  bytes32 internal constant _STRATEGY_TIME_LOCK_SLOT = 0x6d02338b2e4c913c0f7d380e2798409838a48a2c4d57d52742a808c82d713d8b;
  bytes32 internal constant _FUTURE_STRATEGY_SLOT = 0xb441b53a4e42c2ca9182bc7ede99bedba7a5d9360d9dfbd31fa8ee2dc8590610;
  bytes32 internal constant _STRATEGY_UPDATE_TIME_SLOT = 0x56e7c0e75875c6497f0de657009613a32558904b5c10771a825cc330feff7e72;
  bytes32 internal constant _ALLOW_SHARE_PRICE_DECREASE_SLOT = 0x22f7033891e85fc76735ebd320e0d3f546da431c4729c2f6d2613b11923aaaed;
  bytes32 internal constant _WITHDRAW_BEFORE_REINVESTING_SLOT = 0x4215fbb95dc0890d3e1660fb9089350f2d3f350c0a756934874cae6febf42a79;

  constructor() public {
    assert(_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1));
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
    assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
    assert(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestNumerator")) - 1));
    assert(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestDenominator")) - 1));
    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementationDelay")) - 1));
    assert(_STRATEGY_TIME_LOCK_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategyTimeLock")) - 1));
    assert(_FUTURE_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.futureStrategy")) - 1));
    assert(_STRATEGY_UPDATE_TIME_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategyUpdateTime")) - 1));
    assert(_ALLOW_SHARE_PRICE_DECREASE_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allowSharePriceDecrease")) - 1));
    assert(_WITHDRAW_BEFORE_REINVESTING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.withdrawBeforeReinvesting")) - 1));
  }

  function initialize(
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator,
    uint256 _underlyingUnit,
    uint256 _implementationChangeDelay,
    uint256 _strategyChangeDelay
  ) public initializer {
    _setUnderlying(_underlying);
    _setVaultFractionToInvestNumerator(_toInvestNumerator);
    _setVaultFractionToInvestDenominator(_toInvestDenominator);
    _setUnderlyingUnit(_underlyingUnit);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setStrategyTimeLock(_strategyChangeDelay);
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
    _setAllowSharePriceDecrease(false);
    _setWithdrawBeforeReinvesting(false);
  }

  function _setStrategy(address _address) internal {
    setAddress(_STRATEGY_SLOT, _address);
  }

  function _strategy() internal view returns (address) {
    return getAddress(_STRATEGY_SLOT);
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    setUint256(_UNDERLYING_UNIT_SLOT, _value);
  }

  function _underlyingUnit() internal view returns (uint256) {
    return getUint256(_UNDERLYING_UNIT_SLOT);
  }

  function _setVaultFractionToInvestNumerator(uint256 _value) internal {
    setUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT, _value);
  }

  function _vaultFractionToInvestNumerator() internal view returns (uint256) {
    return getUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT);
  }

  function _setVaultFractionToInvestDenominator(uint256 _value) internal {
    setUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT, _value);
  }

  function _vaultFractionToInvestDenominator() internal view returns (uint256) {
    return getUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT);
  }

  function _setAllowSharePriceDecrease(bool _value) internal {
    setBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT, _value);
  }

  function _allowSharePriceDecrease() internal view returns (bool) {
    return getBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT);
  }

  function _setWithdrawBeforeReinvesting(bool _value) internal {
    setBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT, _value);
  }

  function _withdrawBeforeReinvesting() internal view returns (bool) {
    return getBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT);
  }

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function _nextImplementation() internal view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function _nextImplementationTimestamp() internal view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function _nextImplementationDelay() internal view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function _setStrategyTimeLock(uint256 _value) internal {
    setUint256(_STRATEGY_TIME_LOCK_SLOT, _value);
  }

  function _strategyTimeLock() internal view returns (uint256) {
    return getUint256(_STRATEGY_TIME_LOCK_SLOT);
  }

  function _setFutureStrategy(address _value) internal {
    setAddress(_FUTURE_STRATEGY_SLOT, _value);
  }

  function _futureStrategy() internal view returns (address) {
    return getAddress(_FUTURE_STRATEGY_SLOT);
  }

  function _setStrategyUpdateTime(uint256 _value) internal {
    setUint256(_STRATEGY_UPDATE_TIME_SLOT, _value);
  }

  function _strategyUpdateTime() internal view returns (uint256) {
    return getUint256(_STRATEGY_UPDATE_TIME_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private ______gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "./interface/IBVault.sol";

contract BalancerStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
  address public constant wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BVAULT_SLOT = 0x85cbd475ba105ca98d9a2db62dcf7cf3c0074b36303ef64160d68a3e0fdd3c67;
  bytes32 internal constant _LIQUIDATION_RATIO_SLOT = 0x88a908c31cfd33a7a64870721e6da89f529116031d2cb9ed0bf1c4ba0873d19f;
  bytes32 internal constant _USE_QUICK_SLOT = 0x189f8e6d384b6a451390d61330a1995a733994439125cd881a1bdac25fe65ea2;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _BAL2WETH_POOLID_SLOT = 0x45ba019d7bbdedd3bc4822691e4d804339c1a4b73290d1f7370a432fe65381d4;
  bytes32 internal constant _DEPOSIT_ARRAY_INDEX_SLOT = 0xf5304231d5b8db321cd2f83be554278488120895d3326b9a012d540d75622ba3;
  bytes32 internal constant _NTOKENS_SLOT = 0xbb60b35bae256d3c1378ff05e8d7bee588cd800739c720a107471dfa218f74c1;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  address[] public poolAssets;
  mapping (address => address[]) public reward2WETH;
  mapping (address => bool) public useQuick;
  address[] public rewardTokens;


  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bVault")) - 1));
    assert(_LIQUIDATION_RATIO_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.liquidationRatio")) - 1));
    assert(_USE_QUICK_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useQuick")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_BAL2WETH_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bal2WethPoolId")) - 1));
    assert(_DEPOSIT_ARRAY_INDEX_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayIndex")) - 1));
    assert(_NTOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nTokens")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _bVault,
    bytes32 _poolID,
    uint256 _liquidationRatio,
    address _depositToken,
    uint256 _depositArrayIndex,
    bytes32 _bal2wethpid,
    uint256 _nTokens
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(this),
      weth,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    (address _lpt,) = IBVault(_bVault).getPool(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");
    require(_liquidationRatio <= 1000, "Invalid ratio"); //Ratio base = 1000

    setUint256(_LIQUIDATION_RATIO_SLOT, _liquidationRatio);
    _setPoolId(_poolID);
    _setBal2WethPoolId(_bal2wethpid);
    _setBVault(_bVault);
    _setDepositToken(_depositToken);
    _setNTokens(_nTokens);
    _setDepositArrayIndex(_depositArrayIndex);
    WETH2deposit = new address[](0);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function underlyingBalance() internal view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
    useQuick[_route[_route.length-1]] = _useQuick;
  }

  function setRewardLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
    useQuick[_route[0]] = _useQuick;
  }

  function addRewardToken(address _token, address[] memory _path2WETH, bool _useQuick) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH, _useQuick);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath, bool _useQuick, uint256 _depositArrayIndex) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath, _useQuick);
    _setDepositArrayIndex(_depositArrayIndex);
  }

  function _bal2WETH(uint256 balAmount) internal {
    //swap bal to weth on balancer
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = bal2WethPoolId();
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(bal);
    singleSwap.assetOut = IAsset(weth);
    singleSwap.amount = balAmount;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    IERC20(bal).safeApprove(bVault(), 0);
    IERC20(bal).safeApprove(bVault(), balAmount);

    IBVault(bVault()).swap(singleSwap, funds, 1, block.timestamp);
  }

  function _liquidateReward(uint256 _liquidationRatio) internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      uint256 toLiquidate = rewardBalance.mul(_liquidationRatio).div(1000);
      if (toLiquidate == 0) {
        continue;
      }
      if (token == bal) {
        _bal2WETH(toLiquidate);
      } else {
        if (reward2WETH[token].length < 2) {
          continue;
        }
        address routerV2;
        if(useQuick[token]) {
          routerV2 = quickswapRouterV2;
        } else {
          routerV2 = sushiswapRouterV2;
        }
        IERC20(token).safeApprove(routerV2, 0);
        IERC20(token).safeApprove(routerV2, toLiquidate);
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          toLiquidate, 1, reward2WETH[token], address(this), block.timestamp
        );
      }
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (WETH2deposit.length > 1) { //else we assume WETH is the deposit token, no need to swap
      address routerV2;
      if(useQuick[depositToken()]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      // allow Uniswap to sell our reward
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, remainingRewardBalance);

      // we can accept 1 as minimum because this is called only by a trusted role
      uint256 amountOutMin = 1;

      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        WETH2deposit,
        address(this),
        block.timestamp
      );
    }

    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositLP();
    }
  }

  function depositLP() internal {
    uint256 depositTokenBalance = IERC20(depositToken()).balanceOf(address(this));

    IERC20(depositToken()).safeApprove(bVault(), 0);
    IERC20(depositToken()).safeApprove(bVault(), depositTokenBalance);

    IAsset[] memory assets = new IAsset[](nTokens());
    for (uint256 i = 0; i < nTokens(); i++) {
      assets[i] = IAsset(poolAssets[i]);
    }

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
    uint256[] memory amountsIn = new uint256[](nTokens());
    amountsIn[depositArrayIndex()] = depositTokenBalance;
    uint256 minAmountOut = 1;

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    IBVault(bVault()).joinPool(
      poolId(),
      address(this),
      address(this),
      request
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _liquidateReward(1000);
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if (amount >= entireBalance){
      withdrawAllToVault();
    } else {
      IERC20(underlying()).safeTransfer(vault(), amount);
    }
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return underlyingBalance();
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _liquidateReward(liquidationRatio());
  }

  function liquidateAll() external onlyGovernance {
    _liquidateReward(1000);
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(bytes32 _value) internal {
    setBytes32(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (bytes32) {
    return getBytes32(_POOLID_SLOT);
  }

  function _setBVault(address _address) internal {
    setAddress(_BVAULT_SLOT, _address);
  }

  function bVault() public view returns (address) {
    return getAddress(_BVAULT_SLOT);
  }

  function setLiquidationRatio(uint256 _ratio) public onlyGovernance {
    require(_ratio <= 1000, "Invalid ratio"); //Ratio base = 1000
    setUint256(_LIQUIDATION_RATIO_SLOT, _ratio);
  }

  function liquidationRatio() public view returns (uint256) {
    return getUint256(_LIQUIDATION_RATIO_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setBal2WethPoolId(bytes32 _value) internal {
    setBytes32(_BAL2WETH_POOLID_SLOT, _value);
  }

  function bal2WethPoolId() public view returns (bytes32) {
    return getBytes32(_BAL2WETH_POOLID_SLOT);
  }

  function _setDepositArrayIndex(uint256 _value) internal {
    require(_value <= nTokens(), "Invalid index");
    setUint256(_DEPOSIT_ARRAY_INDEX_SLOT, _value);
  }

  function depositArrayIndex() public view returns (uint256) {
    return getUint256(_DEPOSIT_ARRAY_INDEX_SLOT);
  }

  function _setNTokens(uint256 _value) internal {
    setUint256(_NTOKENS_SLOT, _value);
  }

  function nTokens() public view returns (uint256) {
    return getUint256(_NTOKENS_SLOT);
  }

  function setBytes32(bytes32 slot, bytes32 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_BTC is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFeadd389a5c427952D8fdb8057D6C8ba1156cC56);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address renBTC = address(0xDBf31dF14B66535aF65AaC99C32e9eA844e14501);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xfeadd389a5c427952d8fdb8057d6c8ba1156cc5600020000000000000000001e,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      wbtc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wbtc, renBTC];
    WETH2deposit = [weth, wbtc];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
    useQuick[wbtc] = false;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_POLYBASE is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0297e37f1873D2DAb4487Aa67cD56B58E2F27875);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [wmatic, usdc, weth, bal];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_POLYDEFI is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x36128D5436d2d70cab39C9AF9CcE146C38554ff0);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address link = address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x36128d5436d2d70cab39c9af9cce146c38554ff0000100000000000000000008,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      5 //nTokens
    );
    poolAssets = [usdc, link, weth, bal, aave];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_POLYDEFI2 is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xce66904B68f1f070332Cbc631DE7ee98B650b499);
    address link = address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xce66904b68f1f070332cbc631de7ee98b650b499000100000000000000000009,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [link, weth, bal, aave];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_QIPOOL is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xf461f2240B66D55Dcf9059e26C022160C06863BF);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address qi = address(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address mimatic = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xf461f2240b66d55dcf9059e26c022160c06863bf000100000000000000000006,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      usdc,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      5 //nTokens
    );
    poolAssets = [wmatic, usdc, qi, bal, mimatic];
    WETH2deposit = [weth, usdc];
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[qi] = [qi, mimatic, usdc, weth];
    rewardTokens = [bal, wmatic, qi];
    useQuick[wmatic] = true;
    useQuick[qi] = true;
    useQuick[usdc] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_STABLE is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x06Df3b2bbB68adc8B0e302443692037ED9f91b42);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address mimatic = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000012,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      usdc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [usdc, dai, mimatic, usdt];
    WETH2deposit = [weth, usdc];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
    useQuick[usdc] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_TRICRYPTO is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x03cD191F589d12b0582a99808cf19851E468E6B5);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x03cd191f589d12b0582a99808cf19851e468e6b500010000000000000000000a,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      3 //nTokens
    );
    poolAssets = [wbtc, usdc, weth];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_TUSD_STABLE is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0d34e5dD4D8f043557145598E4e2dC286B35FD4f);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address tusd = address(0x2e1AD108fF1D8C782fcBbB89AAd783aC49586756);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x0d34e5dd4d8f043557145598e4e2dc286b35fd4f000000000000000000000068,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      usdc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [usdc, tusd, dai, usdt];
    WETH2deposit = [weth, usdc];
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[tusd] = [tusd, usdc, weth];
    rewardTokens = [bal, wmatic, tusd];
    useQuick[wmatic] = true;
    useQuick[usdc] = true;
    useQuick[tusd] = false;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_USDC_WETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x10f21C9bD8128a29Aa785Ab2dE0d044DCdd79436);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x10f21c9bd8128a29aa785ab2de0d044dcdd79436000200000000000000000059,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [usdc, weth];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_WBTC_WETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xCF354603A9AEbD2Ff9f33E1B04246d8Ea204ae95);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xcf354603a9aebd2ff9f33e1b04246d8ea204ae9500020000000000000000005a,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wbtc, weth];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "./interface/IBVault.sol";
import "../../base/interface/curve/Gauge.sol";

contract BalancerStrategyV2 is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
  address public constant wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BVAULT_SLOT = 0x85cbd475ba105ca98d9a2db62dcf7cf3c0074b36303ef64160d68a3e0fdd3c67;
  bytes32 internal constant _USE_QUICK_SLOT = 0x189f8e6d384b6a451390d61330a1995a733994439125cd881a1bdac25fe65ea2;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _BAL2WETH_POOLID_SLOT = 0x45ba019d7bbdedd3bc4822691e4d804339c1a4b73290d1f7370a432fe65381d4;
  bytes32 internal constant _DEPOSIT_ARRAY_INDEX_SLOT = 0xf5304231d5b8db321cd2f83be554278488120895d3326b9a012d540d75622ba3;
  bytes32 internal constant _NTOKENS_SLOT = 0xbb60b35bae256d3c1378ff05e8d7bee588cd800739c720a107471dfa218f74c1;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  address[] public poolAssets;
  mapping (address => address[]) public reward2WETH;
  mapping (address => bool) public useQuick;
  address[] public rewardTokens;


  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bVault")) - 1));
    assert(_USE_QUICK_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useQuick")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_BAL2WETH_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bal2WethPoolId")) - 1));
    assert(_DEPOSIT_ARRAY_INDEX_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayIndex")) - 1));
    assert(_NTOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nTokens")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _bVault,
    bytes32 _poolID,
    address _depositToken,
    uint256 _depositArrayIndex,
    bytes32 _bal2wethpid,
    uint256 _nTokens
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    (address _lpt,) = IBVault(_bVault).getPool(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolID);
    _setBal2WethPoolId(_bal2wethpid);
    _setBVault(_bVault);
    _setDepositToken(_depositToken);
    _setNTokens(_nTokens);
    _setDepositArrayIndex(_depositArrayIndex);
    WETH2deposit = new address[](0);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = Gauge(rewardPool()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    address rewardPool_ = rewardPool();
    Gauge(rewardPool_).withdraw(
      Math.min(Gauge(rewardPool_).balanceOf(address(this)), amount)
    );
  }
  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    Gauge(rewardPool_).deposit(entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
    useQuick[_route[_route.length-1]] = _useQuick;
  }

  function setRewardLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
    useQuick[_route[0]] = _useQuick;
  }

  function addRewardToken(address _token, address[] memory _path2WETH, bool _useQuick) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH, _useQuick);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath, bool _useQuick, uint256 _depositArrayIndex) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath, _useQuick);
    _setDepositArrayIndex(_depositArrayIndex);
  }

  function _bal2WETH(uint256 balAmount) internal {
    //swap bal to weth on balancer
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = bal2WethPoolId();
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(bal);
    singleSwap.assetOut = IAsset(weth);
    singleSwap.amount = balAmount;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    IERC20(bal).safeApprove(bVault(), 0);
    IERC20(bal).safeApprove(bVault(), balAmount);

    IBVault(bVault()).swap(singleSwap, funds, 1, block.timestamp);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (rewardBalance == 0) {
        continue;
      }
      if (token == bal) {
        _bal2WETH(rewardBalance);
      } else {
        if (reward2WETH[token].length < 2) {
          continue;
        }
        address routerV2;
        if(useQuick[token]) {
          routerV2 = quickswapRouterV2;
        } else {
          routerV2 = sushiswapRouterV2;
        }
        IERC20(token).safeApprove(routerV2, 0);
        IERC20(token).safeApprove(routerV2, rewardBalance);
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          rewardBalance, 1, reward2WETH[token], address(this), block.timestamp
        );
      }
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (WETH2deposit.length > 1) { //else we assume WETH is the deposit token, no need to swap
      address routerV2;
      if(useQuick[depositToken()]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      // allow Uniswap to sell our reward
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, remainingRewardBalance);

      // we can accept 1 as minimum because this is called only by a trusted role
      uint256 amountOutMin = 1;

      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        WETH2deposit,
        address(this),
        block.timestamp
      );
    }

    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositLP();
    }
  }

  function depositLP() internal {
    uint256 depositTokenBalance = IERC20(depositToken()).balanceOf(address(this));

    IERC20(depositToken()).safeApprove(bVault(), 0);
    IERC20(depositToken()).safeApprove(bVault(), depositTokenBalance);

    IAsset[] memory assets = new IAsset[](nTokens());
    for (uint256 i = 0; i < nTokens(); i++) {
      assets[i] = IAsset(poolAssets[i]);
    }

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
    uint256[] memory amountsIn = new uint256[](nTokens());
    amountsIn[depositArrayIndex()] = depositTokenBalance;
    uint256 minAmountOut = 1;

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    IBVault(bVault()).joinPool(
      poolId(),
      address(this),
      address(this),
      request
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    Gauge(rewardPool()).claim_rewards();
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(bytes32 _value) internal {
    setBytes32(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (bytes32) {
    return getBytes32(_POOLID_SLOT);
  }

  function _setBVault(address _address) internal {
    setAddress(_BVAULT_SLOT, _address);
  }

  function bVault() public view returns (address) {
    return getAddress(_BVAULT_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setBal2WethPoolId(bytes32 _value) internal {
    setBytes32(_BAL2WETH_POOLID_SLOT, _value);
  }

  function bal2WethPoolId() public view returns (bytes32) {
    return getBytes32(_BAL2WETH_POOLID_SLOT);
  }

  function _setDepositArrayIndex(uint256 _value) internal {
    require(_value <= nTokens(), "Invalid index");
    setUint256(_DEPOSIT_ARRAY_INDEX_SLOT, _value);
  }

  function depositArrayIndex() public view returns (uint256) {
    return getUint256(_DEPOSIT_ARRAY_INDEX_SLOT);
  }

  function _setNTokens(uint256 _value) internal {
    setUint256(_NTOKENS_SLOT, _value);
  }

  function nTokens() public view returns (uint256) {
    return getUint256(_NTOKENS_SLOT);
  }

  function setBytes32(bytes32 slot, bytes32 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_MaticX is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xC17636e36398602dd37Bb5d1B3a9008c7629005f);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address maticx = address(0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x48534d027f8962692122dB440714fFE88Ab1fA85);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xc17636e36398602dd37bb5d1b3a9008c7629005f0002000000000000000004c4,  // Pool id
      wmatic,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wmatic, maticx];
    rewardTokens = [bal];
    WETH2deposit = [weth, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_POLYBASE is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0297e37f1873D2DAb4487Aa67cD56B58E2F27875);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x068Ff98072d3eB848D012e3390703BB507729ed6);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002,  // Pool id
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [wmatic, usdc, weth, bal];
    rewardTokens = [bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_STABLE is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x06Df3b2bbB68adc8B0e302443692037ED9f91b42);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address mimatic = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0x72843281394E68dE5d55BCF7072BB9B2eBc24150);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000012,  // Pool id
      usdc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [usdc, dai, mimatic, usdt];
    WETH2deposit = [weth, usdc];
    rewardTokens = [bal];
    useQuick[usdc] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_stMatic is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address stmatic = address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x9928340f9E1aaAd7dF1D95E27bd9A5c715202a56);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366,  // Pool id
      wmatic,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wmatic, stmatic];
    rewardTokens = [bal];
    WETH2deposit = [weth, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_USDC_WETH is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x10f21C9bD8128a29Aa785Ab2dE0d044DCdd79436);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address gauge = address(0xD3Fdd06285d2649337800f00B41D07801C9f5715);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x10f21c9bd8128a29aa785ab2de0d044dcdd79436000200000000000000000059,  // Pool id
      weth,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [usdc, weth];
    rewardTokens = [bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "./interface/IBVault.sol";
import "./interface/IBalanceMinter.sol";
import "./interface/Gauge.sol";

contract BalancerStrategyV3 is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BVAULT_SLOT = 0x85cbd475ba105ca98d9a2db62dcf7cf3c0074b36303ef64160d68a3e0fdd3c67;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _BOOSTED_POOL = 0xd816e748a078d825fa9cc9dc9335909f9baa20dc1b5619211972fc7e672bd2fb;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  mapping(address => mapping(address => bytes32)) public poolIds;
  address[] public rewardTokens;
  mapping(address => mapping(address => bool)) public deposit;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bVault")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_BOOSTED_POOL == bytes32(uint256(keccak256("eip1967.strategyStorage.boostedPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _bVault,
    bytes32 _poolID,
    address _depositToken,
    bool _boosted
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );

    (address _lpt,) = IBVault(_bVault).getPool(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolID);
    _setBVault(_bVault);
    _setDepositToken(_depositToken);
    _setBoostedPool(_boosted);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = Gauge(rewardPool()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    address rewardPool_ = rewardPool();
    Gauge(rewardPool_).withdraw(
      Math.min(Gauge(rewardPool_).balanceOf(address(this)), amount)
    );
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    Gauge(rewardPool_).deposit(entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
  }

  function addRewardToken(address _token, address[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath);
  }

  function setBalancerSwapPoolId(address _sellToken, address _buyToken, bytes32 _poolId) public onlyGovernance {
    poolIds[_sellToken][_buyToken] = _poolId;
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _quickSwap(
    address sellToken,
    address buyToken,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address[] memory path = new address[](2);
    path[0] = sellToken;
    path[1] = buyToken;
    IERC20(sellToken).safeApprove(quickswapRouterV2, 0);
    IERC20(sellToken).safeApprove(quickswapRouterV2, amountIn);
    // we can accept 1 as the minimum because this will be called only by a trusted worker
    IUniswapV2Router02(quickswapRouterV2).swapExactTokensForTokens(
      amountIn, minAmountOut, path, address(this), block.timestamp
    );
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address _bVault = bVault();
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, _bVault, amountIn);
    IBVault(_bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  function _balancerDeposit(
    address tokenIn,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address _bVault = bVault();
    (address[] memory poolTokens,,) = IBVault(_bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
    }

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;

    uint256[] memory amountsIn = new uint256[](_nTokens);
    for (uint256 j = 0; j < amountsIn.length; j++) {
      amountsIn[j] = address(assets[j]) == tokenIn ? amountIn : 0;
    }

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    _approveIfNeed(tokenIn, _bVault, amountIn);
    IBVault(_bVault).joinPool(
      poolId,
      address(this),
      address(this),
      request
    );
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (rewardBalance == 0) {
        continue;
      }
      if (reward2WETH[token].length < 2) {
        continue;
      }
      for (uint256 j = 0; j < reward2WETH[token].length - 1; j++) {
        address sellToken = reward2WETH[token][j];
        address buyToken = reward2WETH[token][j+1];
        uint256 sellTokenBalance = IERC20(sellToken).balanceOf(address(this));
        if (poolIds[sellToken][buyToken] == bytes32(0)) {
          _quickSwap(sellToken, buyToken, sellTokenBalance, 1);
        } else {
          if (deposit[sellToken][buyToken]) {
            _balancerDeposit(
              sellToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          } else {
            _balancerSwap(
              sellToken,
              buyToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          }
        }
      }
    }

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (WETH2deposit.length > 1) { //else we assume WETH is the deposit token, no need to swap
      for(uint256 i = 0; i < WETH2deposit.length - 1; i++){
        address sellToken = WETH2deposit[i];
        address buyToken = WETH2deposit[i+1];
        uint256 sellTokenBalance = IERC20(sellToken).balanceOf(address(this));
        if (poolIds[sellToken][buyToken] == bytes32(0)) {
          _quickSwap(sellToken, buyToken, sellTokenBalance, 1);
        } else {
          if (deposit[sellToken][buyToken]) {
            _balancerDeposit(
              sellToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          } else {
            _balancerSwap(
              sellToken,
              buyToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          }
        }
      }
    }

    address _depositToken = depositToken();
    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0 && !(_depositToken == underlying())) {
      depositLP();
    }
  }

  function depositLP() internal {
    address _depositToken = depositToken();
    bytes32 _poolId = poolId();
    uint256 depositTokenBalance = IERC20(_depositToken).balanceOf(address(this));

    if (boostedPool()) {
      _balancerSwap(
        _depositToken,
        underlying(),
        _poolId,
        depositTokenBalance,
        1
      );
    } else {
      _balancerDeposit(
        _depositToken,
        _poolId,
        depositTokenBalance,
        1
      );
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    address _rewardPool = rewardPool();
    IBalancerMinter(Gauge(_rewardPool).bal_pseudo_minter()).mint(_rewardPool);
    Gauge(_rewardPool).claim_rewards();
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(bytes32 _value) internal {
    setBytes32(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (bytes32) {
    return getBytes32(_POOLID_SLOT);
  }

  function _setBVault(address _address) internal {
    setAddress(_BVAULT_SLOT, _address);
  }

  function bVault() public view returns (address) {
    return getAddress(_BVAULT_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setBoostedPool(bool _boosted) internal {
    setBoolean(_BOOSTED_POOL, _boosted);
  }

  function boostedPool() public view returns (bool) {
    return getBoolean(_BOOSTED_POOL);
  }

  function setBytes32(bytes32 slot, bytes32 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_2BRL is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE22483774bd8611bE2Ad2F4194078DaC9159F4bA);
    address bbamusd = address(0x48e6B98ef6329f8f0A30eBB8c7C960330d648085);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address bbamdai = address(0x178E029173417b1F9C8bC16DCeC6f697bC323746);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0xbDb8DA6156722a3D583ee679988B35cacCd86BC3);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xe22483774bd8611be2ad2f4194078dac9159f4ba0000000000000000000008f0,  // Pool id
      underlying,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, dai, bbamdai, bbamusd, underlying];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[dai][bbamdai] = 0x178e029173417b1f9c8bc16dcec6f697bc323746000000000000000000000758;
    poolIds[bbamdai][bbamusd] = 0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b;
    poolIds[bbamusd][underlying] = 0x4a0b73f0d13ff6d43e304a174697e3d5cfd310a400020000000000000000091c;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_2BRLUSD is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4A0b73f0D13fF6d43e304a174697e3d5CFd310a4);
    address bbamusd = address(0x48e6B98ef6329f8f0A30eBB8c7C960330d648085);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address bbamdai = address(0x178E029173417b1F9C8bC16DCeC6f697bC323746);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0x75108A554A34BB2846ABfb00D889BFD0Bb34E1d6);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x4a0b73f0d13ff6d43e304a174697e3d5cfd310a400020000000000000000091c,  // Pool id
      bbamusd,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, dai, bbamdai, bbamusd];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[dai][bbamdai] = 0x178e029173417b1f9c8bc16dcec6f697bc323746000000000000000000000758;
    poolIds[bbamdai][bbamusd] = 0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_2EUR_agEUR is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa48D164F6eB0EDC68bd03B56fa59E12F24499aD1);
    address jeur = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x8c73C7A998F54e3A936885C752c9955c78A5Febb);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xa48d164f6eb0edc68bd03b56fa59e12f24499ad10000000000000000000007c4,  // Pool id
      jeur,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, jeur];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_2EUR_PAR is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x7d60a4Cb5cA92E2Da965637025122296ea6854f9);
    address jeur = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0xD14875e2C65A46d15501C9296A9bCC0E17510978);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x7d60a4cb5ca92e2da965637025122296ea6854f900000000000000000000085e,  // Pool id
      jeur,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, jeur];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_2EUR_PARv2 is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x513CdEE00251F39DE280d9E5f771A6eaFebCc88E);
    address jeur = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x5c13C3b72b031b6405046C319B2D840d3C1403c7);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x513cdee00251f39de280d9e5f771a6eafebcc88e000000000000000000000a6b,  // Pool id
      jeur,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, jeur];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_bbamusd is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x48e6B98ef6329f8f0A30eBB8c7C960330d648085);
    address bbamdai = address(0x178E029173417b1F9C8bC16DCeC6f697bC323746);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0x1c514fEc643AdD86aeF0ef14F4add28cC3425306);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b,  // Pool id
      bbamdai,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, dai, bbamdai];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[dai][bbamdai] = 0x178e029173417b1f9c8bc16dcec6f697bc323746000000000000000000000758;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_frxETH_amWETH is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xD00f9Ca46ce0E4A63067c4657986f0167b0De1E5);
    address bbaWETH = address(0x43894DE14462B421372bCFe445fA51b1b4A0Ff3D);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x83Ed440E7122FE3EFA28d3BC9d9eFca1952Ccb4b);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xd00f9ca46ce0e4a63067c4657986f0167b0de1e5000000000000000000000b42,  // Pool id
      bbaWETH,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, bbaWETH];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[weth][bbaWETH] = 0x43894de14462b421372bcfe445fa51b1b4a0ff3d000000000000000000000b36;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_frxETH is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5DEe84FfA2DC27419Ba7b3419d7146E53e4F7dEd);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0xF75Bf196b64f2FCf942C29b5bE7f4742e4fD16Bd);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x5dee84ffa2dc27419ba7b3419d7146e53e4f7ded000200000000000000000a4e,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_MATIC_USDC_ETH_BAL is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0297e37f1873D2DAb4487Aa67cD56B58E2F27875);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x0aea1abC694a3608C8aC5F131d8310f95039111A);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_MaticX_amMatic is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE78b25c06dB117fdF8F98583CDaaa6c92B79E917);
    address maticX = address(0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address sd = address(0x1d734A02eF1e1f5886e66b0673b71Af5B53ffA94);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0x956074628A64a316086f7125074a8A52d3306321);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xe78b25c06db117fdf8f98583cdaaa6c92b79e917000000000000000000000b2b,  // Pool id
      maticX,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, sd];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[sd] = [sd, usdc, weth];
    WETH2deposit = [weth, wmatic, maticX];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_MaticX is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xb20fC01D21A50d2C734C4a1262B4404d41fA7BF0);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address sd = address(0x1d734A02eF1e1f5886e66b0673b71Af5B53ffA94);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0xdFFe97094394680362Ec9706a759eB9366d804C2);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xb20fc01d21a50d2c734c4a1262b4404d41fa7bf000000000000000000000075c,  // Pool id
      wmatic,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, sd];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[sd] = [sd, usdc, weth];
    WETH2deposit = [weth, wmatic];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_SPHERE_MATIC is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xf3312968c7D768C19107731100Ece7d4780b47B2);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address gauge = address(0xFB0243ffDC5309A4ec13b9de9111Da02294b2571);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xf3312968c7d768c19107731100ece7d4780b47b2000200000000000000000a50,  // Pool id
      wmatic,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, wmatic];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_stETH is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x65Fe9314bE50890Fb01457be076fAFD05Ff32B9A);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address ldo = address(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756);
    address gauge = address(0x94e5C0270250d9E13B0545279807eF8c6c4Ed2a3);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x65fe9314be50890fb01457be076fafd05ff32b9a000000000000000000000a96,  // Pool id
      weth,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wmatic, weth];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_stMatic_amMatic is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x216690738Aac4aa0C4770253CA26a28f0115c595);
    address stMatic = address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address ldo = address(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0x1e916950A659Da9813EE34479BFf04C732E03deb);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x216690738aac4aa0c4770253ca26a28f0115c595000000000000000000000b2c,  // Pool id
      stMatic,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, ldo, usdc];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wmatic, weth];
    reward2WETH[usdc] = [usdc, weth];
    WETH2deposit = [weth, wmatic, stMatic];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_stMatic is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8159462d255C1D24915CB51ec361F700174cD994);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address ldo = address(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756);
    address gauge = address(0x2Aa6fB79EfE19A3fcE71c46AE48EFc16372ED6dD);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x8159462d255c1d24915cb51ec361f700174cd99400000000000000000000075d,  // Pool id
      wmatic,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wmatic, weth];
    WETH2deposit = [weth, wmatic];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_tetuBal is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xB797AdfB7b268faeaA90CAdBfEd464C76ee599Cd);
    address wethBal = address(0x3d468AB2329F296e1b9d8476Bb54Dd77D8c2320f);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0xAA59736b80cf77d1E7D56B7bbA5A8050805F5064);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xb797adfb7b268faeaa90cadbfed464c76ee599cd0002000000000000000005ba,  // Pool id
      wethBal,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, wethBal];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[weth][wethBal] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    deposit[weth][wethBal] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_TNGBL_USDC is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9F9F548354B7C66Dc9a9f3373077D86AAACCF8F2);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0xb2A8f0f477Aae4D78Ea78d85234233285c91bB08);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x9f9f548354b7c66dc9a9f3373077d86aaaccf8f2000200000000000000000a4a,  // Pool id
      usdc,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, usdc];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_WBTC_ETH_USDC is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x03cD191F589d12b0582a99808cf19851E468E6B5);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x219b3a4a2D2351582277A87048995034ca7e9aEF);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x03cd191f589d12b0582a99808cf19851e468e6b500010000000000000000000a,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_wstETH_amWETH is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4a77eF015ddcd972fd9BA2C7D5D658689D090f1A);
    address bbaWETH = address(0x43894DE14462B421372bCFe445fA51b1b4A0Ff3D);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0xB95397A17ACbb5824535ebE69Cd9DCF8fA7aFC50);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x4a77ef015ddcd972fd9ba2c7d5d658689d090f1a000000000000000000000b38,  // Pool id
      bbaWETH,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, usdc];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[usdc] = [usdc, weth];
    WETH2deposit = [weth, bbaWETH];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[weth][bbaWETH] = 0x43894de14462b421372bcfe445fa51b1b4a0ff3d000000000000000000000b36;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_wUSDR_USDC is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x34A81e8956BF20b7448b31990A2c06F96830a6e4);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x80f392Bf3FA6973C3e14bb276e04931Ec12DE05E);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x34a81e8956bf20b7448b31990a2c06f96830a6e4000200000000000000000a14,  // Pool id
      usdc,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, usdc];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function user_checkpoint(address) external;
    function claim_rewards() external;
    function bal_pseudo_minter() external view returns (address);
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}

interface ICurveLP {
    function minter() external view returns(address);
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

pragma solidity 0.6.12;


/**
 * @dev Base minter interface, applicable to Mainnet minter or L2 pseudo minters.
 */
interface IBalancerMinter {
    event Minted(address indexed recipient, address gauge, uint256 minted);

    /**
     * @notice Returns the address of the Balancer Governance Token
     */
    function getBalancerToken() external view returns (address);

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external returns (uint256);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] calldata gauges) external returns (uint256);

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mintFor(address gauge, address user) external returns (uint256);

    /**
     * @notice Mint tokens for `user` across multiple gauges
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauges List of `LiquidityGauge` addresses
     * @param user Address to mint to
     */
    function mintManyFor(address[] calldata gauges, address user) external returns (uint256);

    /**
     * @notice The total number of tokens minted for `user` from `gauge`
     */
    function minted(address user, address gauge) external view returns (uint256);

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function getMinterApproval(address minter, address user) external view returns (bool);

    /**
     * @notice Set whether `minter` is approved to mint tokens on your behalf
     */
    function setMinterApproval(address minter, bool approval) external;

    /**
     * @notice Set whether `minter` is approved to mint tokens on behalf of `user`, who has signed a message authorizing
     * them.
     */
    function setMinterApprovalWithSignature(
        address minter,
        bool approval,
        address user,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // The below functions are near-duplicates of functions available above.
    // They are included for ABI compatibility with snake_casing as used in vyper contracts.
    // solhint-disable func-name-mixedcase

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function allowed_to_mint_for(address minter, address user) external view returns (bool);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @dev This function is not recommended as `mintMany()` is more flexible and gas efficient
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauges) external;

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mint_for(address gauge, address user) external;

    /**
     * @notice Toggle whether `minter` is approved to mint tokens for `user`
     */
    function toggle_approve_mint(address minter) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset {
}

interface IBVault {
    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external payable;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest calldata request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
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