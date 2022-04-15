/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED


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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

interface IStrategy {
    //Returns the token sent to the fee dist contract, which is used to calculate the amount of ADDY to mint when claiming rewards
    function getFeeDistToken() external view returns (address);

    //Returns the harvested token, which is not guaranteed to be the fee dist token
    function getHarvestedToken() external view returns (address);

    function lastHarvestTime() external view returns (uint256);

    function rewards() external view returns (address);

    function want() external view returns (address);

    function deposit() external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function getHarvestable() external view returns (uint256);

    function harvest() external;

    function setJar(address _jar) external;
}

//A Jar is a contract that users deposit funds into.
//Jar contracts are paired with a strategy contract that interacts with the pool being farmed.
interface IJar {
    function token() external view returns (IERC20);

    function getRatio() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function depositAll() external;

    function deposit(uint256) external;

    //function depositFor(address user, uint256 amount) external;

    function withdrawAll() external;

    //function withdraw(uint256) external;

    //function earn() external;

    function strategy() external view returns (address);

    //function decimals() external view returns (uint8);

    //function getLastTimeRestaked(address _address) external view returns (uint256);

    //function notifyReward(address _reward, uint256 _amount) external;

    //function getPendingReward(address _user) external view returns (uint256);
}
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
interface IUniswapRouterV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}


abstract contract BaseStrategy is IStrategy, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public override lastHarvestTime = 0;

    // Tokens
    address public override want; //The token being staked.
    address internal harvestedToken; //The token we harvest. If the reward pool emits multiple tokens, they should be converted to a single token.

    // Contracts
    address public override rewards; //The staking rewards/MasterChef contract
    address public strategist; //The address the performance fee is sent to
    address public multiHarvest; //0x3355743Db830Ed30FF4089DB8b18DEeb683F8546; //The multi harvest contract
    address public jar; //The vault/jar contract

    // Dex
    address public currentRouter; //0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Quickswap router

    constructor(
        address _want,
        address _strategist,
        address _harvestedToken,
        address _currentRouter,
        address _rewards
    ) public {
        require(_want != address(0));
        require(_strategist != address(0));
        require(_harvestedToken != address(0));
        require(_currentRouter != address(0));
        require(_rewards != address(0));

        want = _want;
        strategist = _strategist;
        harvestedToken = _harvestedToken;
        currentRouter = _currentRouter;
        rewards = _rewards;
    }

    // **** Modifiers **** //

    //prevent unauthorized smart contracts from calling harvest()
    modifier onlyHumanOrWhitelisted {
        require(msg.sender == tx.origin || msg.sender == owner() || msg.sender == multiHarvest, "not authorized");
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public override view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getHarvestedToken() public override view returns (address) {
        return harvestedToken;
    }

    // **** Setters **** //

    function setJar(address _jar) external override onlyOwner {
        require(jar == address(0), "jar already set");
        require(IJar(_jar).strategy() == address(this), "incorrect jar");
        jar = _jar;
        emit SetJar(_jar);
    }

    function setMultiHarvest(address _address) external onlyOwner {
        require(_address != address(0));
        multiHarvest = _address;
    }

    // **** State mutations **** //
    function deposit() public override virtual;

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external override {
        require(msg.sender == jar, "!jar");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(jar, _amount);
    }

    // Withdraw funds, used to swap between strategies
    // Not utilized right now, but could be used for i.e. multi stablecoin strategies
    function withdrawForSwap(uint256 _amount)
        external override
        returns (uint256 balance)
    {
        require(msg.sender == jar, "!jar");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(jar, balance);
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public override virtual;

    // **** Internal functions ****

    //Performs a swap through the current router, assuming infinite approval for the token was already given
    function _swapUniswapWithPathPreapproved(
        address[] memory path,
        uint256 _amount,
        address _router
    ) internal {
        require(path[1] != address(0));

        IUniswapRouterV2(_router).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPathPreapproved(
        address[] memory path,
        uint256 _amount
    ) internal {
        _swapUniswapWithPathPreapproved(path, _amount, currentRouter);
    }

    //Legacy swap functions left in to not break compatibility with older strategy contracts
    function _swapUniswapWithPath(
        address[] memory path,
        uint256 _amount,
        address _router
    ) internal {
        require(path[1] != address(0));

        // Swap with uniswap
        IERC20(path[0]).safeApprove(_router, 0);
        IERC20(path[0]).safeApprove(_router, _amount);

        IUniswapRouterV2(_router).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        _swapUniswapWithPath(path, _amount, currentRouter);
    }

    function _swapUniswapWithPathForFeeOnTransferTokens(
        address[] memory path,
        uint256 _amount,
        address _router
    ) internal {
        require(path[1] != address(0));

        // Swap with uniswap
        IERC20(path[0]).safeApprove(_router, 0);
        IERC20(path[0]).safeApprove(_router, _amount);

        IUniswapRouterV2(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPathForFeeOnTransferTokens(
        address[] memory path,
        uint256 _amount
    ) internal {
        _swapUniswapWithPathForFeeOnTransferTokens(path, _amount, currentRouter);
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _want = IERC20(want).balanceOf(address(this));

        if (_want > 0) {
            deposit();
        }
        lastHarvestTime = now;
    }

    // **** Events **** //
    event SetJar(address indexed jar);
}
interface IERCFund {
    function feeShareEnabled() external view returns (bool);

    function depositToFeeDistributor(address token, uint256 amount) external;

    function notifyFeeDistribution(address token) external;

    function getFee() external view returns (uint256);

    function recover(address token) external;
}

//Vaults are jars that emit ADDY rewards.
interface IVault is IJar {

    function getBoost(address _user) external view returns (uint256);

    function getPendingReward(address _user) external view returns (uint256);

    function getLastDepositTime(address _user) external view returns (uint256);

    function getTokensStaked(address _user) external view returns (uint256);

    function totalShares() external view returns (uint256);

    function getRewardMultiplier() external view returns (uint256);   

    function rewardAllocation() external view returns (uint256);   

    function totalPendingReward() external view returns (uint256);   

    function withdrawPenaltyTime() external view returns (uint256);  

    function withdrawPenalty() external view returns (uint256);   
    
    function increaseRewardAllocation(uint256 _newReward) external;

    function setWithdrawPenaltyTime(uint256 _withdrawPenaltyTime) external;

    function setWithdrawPenalty(uint256 _withdrawPenalty) external;

    function setRewardMultiplier(uint256 _rewardMultiplier) external;
}

//A normal vault is a vault where the strategy contract notifies the vault contract about the profit it generated when harvesting. 
interface IGenericVault is IVault {
    
    //Strategy calls notifyReward to let the vault know that it earned a certain amount of profit (the performance fee) for gov token stakers
    function notifyReward(address _reward, uint256 _amount) external;
}
interface IVaultFactory {
    function getPerformanceFee() external view returns (uint256);

    function getMinHealthFactor() external view returns (uint256);

    function numVaults() external view returns (uint256);

    function vaultList(uint256 index) external view returns (address);

    //Calls unsafeValueOfAsset() in price calculator contract
    function unsafeValueOfAsset(address asset, uint amount) external view returns (uint valueInETH, uint valueInUSD);

    function getErcFund() external view returns (address);

    //Returns the vault associated with a user if exists
    function getVault(address _address) external view returns (address);

    function canDeposit(address _address) external view returns (bool);

    //Returns whether an address is a vault created by this contract
    //Used by the compounder vault to allow only whitelisted contracts to deposit
    function isVault(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function initializeVault() external returns (address);

    function controller() external returns (address);
}
interface IPriceCalculator {
    //despite the name, this function uses Chainlink oracles
    function unsafeValueOfAsset(address asset, uint amount) external view returns (uint valueInETH, uint valueInUSD);
}

//Controls access to MC vault creation/deposits based on arbitrary conditions (i.e. ADDY burned in a contract)
interface IManagedVaultController {

  //Check if user fulfills a certain condition as anti-spam measure to prevent users from spam creating empty vaults
  function canCreateVault(address _factory, address _user) external view returns (bool);
  //Check if user fulfills a certain condition before letting them deposit
  function canDeposit(address _factory, address _user) external view returns (bool);

  //Function for possible future functionality
  function futureCheck(address _factory, address _user, bytes memory userData) external view returns (bool);
}

abstract contract VaultFactory is Ownable, IVaultFactory {
    using SafeERC20 for IERC20;

    uint256 public override numVaults;
    address[] public override vaultList;

    address public immutable compoundingVault; //A vault that handles the process of compounding rewards
    address public priceCalculator;
    address public ercFund;
    address public override controller; //Controls access to MC vault creation/deposits based on arbitrary conditions (i.e. ADDY burned in a contract)

    uint256 public performanceFee = 3000;
    uint256 public minHealthFactor = 1500000000000000000; //1.5

    mapping(address => bool) public guardians;
    mapping(address => address) public vaults; //user addresses -> vault contracts
    mapping(address => bool) internal vaultMap;

    constructor(address _compoundingVault, address _controller) public {
        compoundingVault = _compoundingVault;
        controller = _controller;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getPerformanceFee() external override view returns (uint256) {
        return performanceFee;
    }

    function getMinHealthFactor() external override view returns (uint256) {
        return minHealthFactor;
    }

    function unsafeValueOfAsset(address asset, uint amount) external override view returns (uint valueInETH, uint valueInUSD) {
        return IPriceCalculator(priceCalculator).unsafeValueOfAsset(asset, amount);
    }

    function getErcFund() external override view returns (address) {
        return ercFund;
    }

    function isGuardian(address _address) external override view returns (bool) {
        return guardians[_address];
    }

    function getVault(address _address) external override view returns (address) {
        return vaults[_address];
    }

    function isVault(address _address) external override view returns (bool) {
        return vaultMap[_address];
    }

    function canDeposit(address _address) external override view returns (bool) {
        return IManagedVaultController(controller).canDeposit(address(this), _address);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initializeVault() external override returns (address newVaultAddr) {
        require(vaults[msg.sender] == address(0), "vault already exists for user");
        //check if user has burned at least X ADDY as anti-spam measure to prevent users from spam creating empty vaults
        require(IManagedVaultController(controller).canCreateVault(address(this), msg.sender), "not enough ADDY burned to create vault");

        newVaultAddr = createVault();
        vaults[msg.sender] = newVaultAddr;
        vaultMap[newVaultAddr] = true;

        vaultList.push(newVaultAddr);
        numVaults += 1;

        emit VaultCreated(msg.sender, newVaultAddr);
    }

    function createVault() internal virtual returns (address);

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPerformanceFee(uint256 _fee) external onlyOwner {
        require(_fee <= 3000, "too high"); //max 30%
        performanceFee = _fee;
    }

    function setMinHealthFactor(uint256 _healthFactor) external onlyOwner {
        require(_healthFactor > 1e18, "too low");
        minHealthFactor = _healthFactor;
    }

    function setErcFund(address _address) external onlyOwner {
        ercFund = _address;
    }

    function setGuardian(address _address, bool _bool) external onlyOwner {
        guardians[_address] = _bool;
    }

    function setPriceCalculator(address _address) external onlyOwner {
        priceCalculator = _address;
    }

    function setController(address _address) external onlyOwner {
        controller = _address;
    }

    /* ========== EVENTS ========== */

    event VaultCreated(address indexed user, address vaultAddr);
}

interface ILendingPool {

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv, //maximum loan to value
        uint256 healthFactor //current health factor divided by 1e18
    );
}
interface IDataProvider {

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );
}
interface IAaveIncentivesController {

  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;


  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
  * @dev for backward compatibility with previous implementation of the Incentives controller
  */
  function REWARD_TOKEN() external view returns (address);

  function assets(address asset) external view returns (
    uint128 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 index
  );
}

//A vault that only allows whitelisted addresses to deposit
interface IWhitelistVault is IJar {
    function totalShares() external view returns (uint256);

    function withdraw(uint256) external;
}

abstract contract AaveVaultBase is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant KEEP_MAX = 10000;

    //Third party contract addresses
    address internal constant LENDING_POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address internal constant DATA_PROVIDER = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
    address internal constant INCENTIVES_CONTROLLER = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;

    //Token addresses
    address public incentiveToken; //token that AAVE distributes as liquidity incentives
    address public collateralToken; //token deposited on AAVE as collateral
    address public collateralReceiptToken; //receipt token for depositing i.e. amWETH, used by multicall to get `incentiveToken` data
    address public borrowedToken; //token deposited on Curve to get LP, USDT if Matic incentives > interest, else USDC
    address public borrowedReceiptToken; //receipt token for borrowing i.e. variableDebtmUSDT, used by multicall to get `incentiveToken` data
    address public vaultWant; //LP token deposited in the vault

    address[] internal aaveAssets; //the aTokens that we receive for depositing/borrowing, used when claiming `incentiveToken`

    address public compoundingVault; //A vault that handles the process of compounding rewards

    address public owner;
    address public vaultFactory;

    uint256 public numTokensDeposited; //used to determine if a liquidation occurred, different than what getBalance() returns since it won't account for interest gained
    uint256 public rateMode = 2; //InterestRateMode.VARIABLE

    bool public executePermission;

    constructor(
        address _owner,
        address _vault,
        address _collateralToken,
        address _collateralReceiptToken,
        address _borrowedToken,
        address _borrowedReceiptToken,
        address _incentiveToken,
        address[] memory _aaveAssets)
    public {
        vaultFactory = msg.sender;
        owner = _owner;
        compoundingVault = _vault;
        vaultWant = address(IWhitelistVault(compoundingVault).token());

        collateralToken = _collateralToken;
        collateralReceiptToken = _collateralReceiptToken;
        borrowedToken = _borrowedToken;
        borrowedReceiptToken = _borrowedReceiptToken;
        incentiveToken = _incentiveToken;

        aaveAssets = _aaveAssets;

        IERC20(vaultWant).safeApprove(_vault, uint256(-1)); //for depositing in the compounding vault
        IERC20(_collateralToken).safeApprove(LENDING_POOL, uint256(-1)); //for depositing on AAVE
        IERC20(_borrowedToken).safeApprove(LENDING_POOL, uint256(-1)); //for repaying on AAVE
    }

    /* ========== VIEW FUNCTIONS ========== */

    ///Returns current variable rate debt
    //Stable rate mode is unlikely to ever be used since it's far more expensive
    function getDebt() public view returns (uint256) {
        (,,uint256 currentVariableDebt,,,,,,) = IDataProvider(DATA_PROVIDER).getUserReserveData(borrowedToken, address(this));
        return currentVariableDebt;
    }

    function getHealthFactor() public view returns (uint256) {
        (,,,,,uint256 healthFactor) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        return healthFactor;
    }

    //Returns current balance of deposited collateral
    function getBalance() public view returns (uint256) {
        (uint256 currentATokenBalance,,,,,,,,) = IDataProvider(DATA_PROVIDER).getUserReserveData(collateralToken, address(this));
        return currentATokenBalance;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    //Deposits collateral on AAVE
    function deposit(uint256 _collatAmount) public onlyVaultOwner nonReentrant {
        require(_collatAmount > 0, "Cannot deposit 0");
        //check if user has burned at least X ADDY to create demand for it (won't be active at launch)
        require(IVaultFactory(vaultFactory).canDeposit(msg.sender), "not enough ADDY burned to cover collateral amount");

        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), _collatAmount);

        ILendingPool(LENDING_POOL).deposit(collateralToken, _collatAmount, address(this), 0);

        numTokensDeposited = numTokensDeposited.add(_collatAmount);
        emit Deposited(_collatAmount);
    }

    //Borrows `borrowedToken` from AAVE, deposits it on Curve to get LP, then deposits LP in the compounding vault
    function borrow(uint256 _borrowAmount, uint256 _min_mint_amount) public onlyVaultOwner nonReentrant {
        _borrow(_borrowAmount, _min_mint_amount);
    }

    //Borrow some more funds with the deposited collateral
    function _borrow(uint256 _borrowAmount, uint256 _min_mint_amount) internal {
        require(_borrowAmount > 0, "Cannot borrow 0");
        ILendingPool(LENDING_POOL).borrow(borrowedToken, _borrowAmount, rateMode, 0, address(this));

        //check if health factor is above X, if not, revert
        (,,,,,uint256 healthFactor) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        require(healthFactor >= IVaultFactory(vaultFactory).getMinHealthFactor(), "health factor too low");

        //deposit `borrowedToken` on Curve
        addLiquidity(_min_mint_amount);

        //deposit Curve LP tokens in the compounding vault
        IWhitelistVault(compoundingVault).depositAll();
    }

    //Allows user to withdraw some of their collateral as long as resulting `healthFactor` >= `getMinHealthFactor`
    function withdraw(uint256 amount) public onlyVaultOwner nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(amount < getBalance(), "withdrawing more than curr bal");

        //withdraw from AAVE
        ILendingPool(LENDING_POOL).withdraw(collateralToken, amount, address(this));

        //check if health factor is above X, if not, revert
        (,,,,,uint256 healthFactor) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        require(healthFactor >= IVaultFactory(vaultFactory).getMinHealthFactor(), "health factor too low");

        //send `collateralToken` to user and update numTokensDeposited
        numTokensDeposited = numTokensDeposited.sub(amount);
        IERC20(collateralToken).safeTransfer(msg.sender, amount);
        emit Withdrew(amount);
    }

    function exit(uint256 _min_amount) public onlyVaultOwner nonReentrant {
        if(IWhitelistVault(compoundingVault).totalShares() > 0) {
            IWhitelistVault(compoundingVault).withdrawAll();
            removeLiquidity(_min_amount);
        }

        //Claim `incentiveToken` rewards
        IAaveIncentivesController(INCENTIVES_CONTROLLER).claimRewards(aaveAssets, type(uint256).max, address(this));

        //a performance fee is charged on the `borrowedToken` earned if a profit was made
        //a performance fee is always charged on the `incentiveToken` earned
        bool chargePerformanceFee = true;

        //if a user was liquidated, they will have less collateral than they deposited & part of their debt would be paid
        //since value of tokens borrowed > current debt, an incorrectly high perf. fee would be deducted unless this check is here
        (uint256 totalCollateralETH,,,,,) = ILendingPool(LENDING_POOL).getUserAccountData(address(this));
        if(totalCollateralETH < numTokensDeposited) {
            chargePerformanceFee = false;
        }

        //if we can repay the debt in full, repay it
        if(getDebt() > 0) {
            if(IERC20(borrowedToken).balanceOf(address(this)) >= getDebt()) {
                ILendingPool(LENDING_POOL).repay(borrowedToken, getDebt(), rateMode, address(this));
            }
            //else, sell some `collateralToken` and then repay the debt
            else {
                chargePerformanceFee = false;

                //Repay outstanding debt first (even though this consumes more gas)
                //because our LTV might be so high that we're unable to withdraw `collateralToken` to sell
                if(IERC20(borrowedToken).balanceOf(address(this)) > 0) {
                    ILendingPool(LENDING_POOL).repay(borrowedToken, IERC20(borrowedToken).balanceOf(address(this)), rateMode, address(this));
                }

                //sell slightly more `collateralToken` than needed for `borrowedToken`
                swapCollateralForBorrowed(getDebt());

                ILendingPool(LENDING_POOL).repay(borrowedToken, getDebt(), rateMode, address(this));
            }
        }

        //if the user gets stuck on repaying the debt, they can repay some of it through the `repayFromWallet` function
        require(getDebt() == 0, "debt repayment unsuccessful");

        //Withdraw all our collateral from AAVE
        ILendingPool(LENDING_POOL).withdraw(collateralToken, type(uint256).max, address(this));

        //Any remaining `borrowedToken` is considered to be profit earned by the vault
        //deduct performance fee and send remaining `collateralToken`, `borrowedToken`, `incentiveToken` to user
        uint256 borrowedTokenBal = IERC20(borrowedToken).balanceOf(address(this));
        if(borrowedTokenBal > 0) {
            if(chargePerformanceFee) {
                uint256 feeAmount = borrowedTokenBal.mul(IVaultFactory(vaultFactory).getPerformanceFee()).div(KEEP_MAX);
                uint256 afterFeeAmount = borrowedTokenBal.sub(feeAmount);
                IERC20(borrowedToken).safeTransfer(IVaultFactory(vaultFactory).getErcFund(), feeAmount);
                IERC20(borrowedToken).safeTransfer(msg.sender, afterFeeAmount);
            }
            else {
                IERC20(borrowedToken).safeTransfer(msg.sender, borrowedTokenBal);
            }
        }

        uint256 collateralTokenBal = IERC20(collateralToken).balanceOf(address(this));
        if(collateralTokenBal > 0) {
            IERC20(collateralToken).safeTransfer(msg.sender, collateralTokenBal);
        }

        uint256 incentiveTokenBal = IERC20(incentiveToken).balanceOf(address(this));
        if(incentiveTokenBal > 0) {
            uint256 feeAmount = incentiveTokenBal.mul(IVaultFactory(vaultFactory).getPerformanceFee()).div(KEEP_MAX);
            uint256 afterFeeAmount = incentiveTokenBal.sub(feeAmount);
            IERC20(incentiveToken).safeTransfer(IVaultFactory(vaultFactory).getErcFund(), feeAmount);
            IERC20(incentiveToken).safeTransfer(msg.sender, afterFeeAmount);
        }

        numTokensDeposited = 0;
        emit Withdrew(collateralTokenBal);
    }

    //Transfers some `borrowedToken` from the user's wallet to repay the remaining debt if no profit was earned so they don't need to sell a portion of their collateral
    //This function should only be used after using `repay()` to repay as much debt as possible, because extra `borrowedToken` will be counted as profit
    function repayFromWallet() public onlyVaultOwner nonReentrant {
        uint256 amount = getDebt();
        IERC20(borrowedToken).safeTransferFrom(msg.sender, address(this), amount);
        ILendingPool(LENDING_POOL).repay(borrowedToken, amount, rateMode, address(this));
    }

    //adds liquidity to curve
    //Use `am3crv_pool.calc_token_amount()` to get `_min_mint_amount`
    function addLiquidity(uint256 _min_mint_amount) internal virtual;

    //withdraws liquidity from curve
    //Use `am3crv_pool.calc_withdraw_one_coin()` to get `_min_amount`
    function removeLiquidity(uint256 _min_amount) internal virtual;

    //swap some `collateralToken` for `borrowedToken` to pay off remaining debt when exiting
    function swapCollateralForBorrowed(uint256 _amount) internal virtual;

    /* ========== OTHER VAULT OWNER FUNCTIONS ========== */

    //Set permission for guardians to call `executeTransaction`
    //This function should not be called by end users unless an error has happened with this contract
    function grantPermission(bool _permission) external onlyVaultOwner {
        executePermission = _permission;
    }

    /* ========== VAULT OWNER + GUARDIAN FUNCTIONS ========== */

    //Withdraw some shares from the compounding vault and repay part of the loan
    function repay(uint256 _amount, uint256 _min_amount) public onlyVaultOwnerOrGuardian nonReentrant {
        IWhitelistVault(compoundingVault).withdraw(_amount);
        removeLiquidity(_min_amount);

        ILendingPool(LENDING_POOL).repay(borrowedToken, IERC20(borrowedToken).balanceOf(address(this)), rateMode, address(this));
    }

    /* ========== GUARDIAN FUNCTIONS ========== */

    //Emergency function to execute arbitrary transactions if permission has been granted
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyGuardian returns (bytes memory) {
        require(executePermission, "permission not granted");
        require(target != address(0), "!target");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        // XXX: Using ".value(...)" is deprecated. Use "{value: ...}" instead.
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, "ExecuteTransaction: Transaction execution reverted.");

        return returnData;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyVaultOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }

    modifier onlyGuardian() {
        require(IVaultFactory(vaultFactory).isGuardian(msg.sender), "Not owner or guardian");
        _;
    }

    modifier onlyVaultOwnerOrGuardian() {
        require(owner == msg.sender || IVaultFactory(vaultFactory).isGuardian(msg.sender), "Not owner or guardian");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposited(uint256 amount);
    event Withdrew(uint256 amount);
}

interface ICurvePool {

    /// @notice Deposit coins into the pool
    /// @param _amounts List of amounts of coins to deposit
    /// 0: EURT
    /// 1: DAI
    /// 2: USDC
    /// 3: USDT
    /// @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount, address _receiver) external;

    /// @notice Withdraw a single coin from the pool
    /// @param _token_amount Amount of LP tokens to burn in the withdrawal
    /// @param i Index value of the coin to withdraw
    /// @param _min_amount Minimum amount of coin to receive
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount) external;
}

contract EuroTetherVault is AaveVaultBase {

    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant amWETH = 0x28424507fefb6f7f8E9D3860F56504E4e5f5f390;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant debtUSDC = 0x248960A9d75EdFa3de94F7193eae3161Eb349a12;

    address private constant pool = 0x225FB4176f0E20CDb66b4a3DF70CA3063281E855;
    address private constant sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address[] private variableDebtmUSDC_and_amweth = [debtUSDC, amWETH];

    constructor(address _owner, address _vault)
        public
        AaveVaultBase(
            _owner,
            _vault,
            WETH,
            amWETH,
            USDC,
            debtUSDC,
            WMATIC,
            variableDebtmUSDC_and_amweth
        )
    {
        IERC20(collateralToken).safeApprove(sushiRouter, uint256(-1)); //for selling ETH for USDC
        IERC20(borrowedToken).safeApprove(pool, uint256(-1)); //for adding liquidity to Curve
        IERC20(vaultWant).safeApprove(pool, uint256(-1)); //for removing liq from Curve
    }

    //adds liquidity to curve
    function addLiquidity(uint256 _min_mint_amount) internal override {
        uint256 _balance = IERC20(borrowedToken).balanceOf(address(this));
        if (_balance > 0) {
            //need slippage check
            ICurvePool(pool).add_liquidity([0, 0, _balance, 0], _min_mint_amount, address(this));
        }
    }

    //withdraws liquidity from curve
    function removeLiquidity(uint256 _min_amount) internal override {
        uint256 _balance = IERC20(vaultWant).balanceOf(address(this));
        if (_balance > 0) {
            ICurvePool(pool).remove_liquidity_one_coin(_balance, 2, _min_amount);
        }
    }

    //withdraw and swap some `collateralToken` for `borrowedToken` to pay off debt
    function swapCollateralForBorrowed(uint256 _amount) internal override {
        //would want to use value in USD if using other collateral
        (uint valueInETH,) = IVaultFactory(vaultFactory).unsafeValueOfAsset(borrowedToken, _amount);
        //Sell 1% more of `borrowedToken` than we need just to be safe
        valueInETH = valueInETH.mul(10 ** uint(uint8(18) - ERC20(borrowedToken).decimals())).mul(101).div(100);
        ILendingPool(LENDING_POOL).withdraw(collateralToken, valueInETH, address(this));
        numTokensDeposited = numTokensDeposited.sub(valueInETH);

        //route thru WETH/USDC on Sushi
        address[] memory path = new address[](2);
        path[0] = collateralToken;
        path[1] = borrowedToken;

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            valueInETH,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}

contract EuroTetherAaveVaultFactory is Ownable, VaultFactory {

    constructor(address _compoundingVault, address _controller) public VaultFactory(_compoundingVault, _controller) {
        priceCalculator = 0xEEcE062608EEAAb52ae2Ed1938758856bCb6AC0D;
        ercFund = 0x01fE07ce760DA7a025e4Cf3f950aE236F8e62120;
    }

    function createVault() internal override returns (address) {
        return address(new EuroTetherVault(msg.sender, compoundingVault));
    }
}