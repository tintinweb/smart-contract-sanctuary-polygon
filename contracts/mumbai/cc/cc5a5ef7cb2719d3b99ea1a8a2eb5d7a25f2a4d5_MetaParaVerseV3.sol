/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract MetaParaVerseV3 is ERC20, Ownable {
    using SafeMath for uint256;
    uint8 internal constant DECIMALS = 18;
    uint256 internal constant ZEROES = 10**DECIMALS;
    uint256 internal constant TOTAL_SUPPLY = 50000000 * ZEROES; // 50 million tokens
    uint256 internal DISTRIBUTION_SUPPLY = 12500000 * ZEROES; // 12.5 million tokens
    uint256 internal TOTAL_SELL = 0 * ZEROES; // 12.5 million tokens
    uint256 internal BURNING_SUPPLY = 37500000 * ZEROES; // 37.5 million tokens to be burned
    uint256 internal BURN_STEP = 0;
    uint256 internal PRICE_ZEROES = 10**6;
    uint256 internal PRICE = 1 * PRICE_ZEROES; // 1USDT
    uint256 internal SLOT = 1;
    uint256 internal BURN_SLOT = 1;
    uint256 internal PRICE_SLOT = 0;
    mapping(address => uint) public stakingBalance;
    address internal usdtAddress = 0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0;
    address internal withdrawAddress = 0xff5B66dBa63FAbFd71C5033837090bEe66B91b0B;

    address public _owner;

    event BurnAmount(uint256 _amount);
    event BuyToken(address recipient, uint256 amount, uint256 price, address walletAddress);

    constructor() ERC20("MetaParaVerse", "MPV") {
        _owner = msg.sender;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    // function transfer(address recipient, uint256 amount) public override returns (bool) {
    //     uint256 newAmount = amount;
    //     require(DISTRIBUTION_SUPPLY >= 1, "MVP: Insufficient Supply");
    //     require(amount <= DISTRIBUTION_SUPPLY, "MVP: Amount is greater that Supply");
    //     _transfer(_msgSender(), recipient, newAmount);
    //     return true;
    // }

    function setUSDTAddress(address _usdtAddress) external returns(bool) {
        usdtAddress = _usdtAddress;
        return true;
    }

    function getUSDTAddres() external view returns(address) {
        return usdtAddress;
    }

    function setWithdraAwAddress(address _withdrawAddress) external returns(bool) {
        withdrawAddress = _withdrawAddress;
        return true;
    }

    function getWithdrawAddres() external view returns(address) {
        return withdrawAddress;
    }

    function totalSell() external view returns(uint256) {
        return TOTAL_SELL;
    }

    function distributionSupply() external view returns(uint256) {
        return DISTRIBUTION_SUPPLY;
    }

    function burningSupply() external view returns(uint256) {
        return BURNING_SUPPLY;
    }

    function currentSlot() external view returns(uint256) {
        return SLOT;
    }

    function currentBurnSlot() external view returns(uint256) {
        return BURN_SLOT;
    }

    function tokenPriceConversion(uint256 usdtAmount) public view returns(uint256) {
        uint256 numerator = 1 * PRICE_ZEROES;
        uint256 denominator = PRICE;
        uint256 fraction = numerator.mul(usdtAmount);
        uint256 tokenAmount = fraction.div(denominator);
        return tokenAmount;
    }

    function buyToken(uint256 amount) external {
        // require(withdrawEnabled, "No wallet found. Please set wallet first!");
        uint256 buyPrice = amount * PRICE_ZEROES;
        uint256 convertAmount = tokenPriceConversion(amount);
        uint256 tokenAmount = convertAmount * ZEROES;
        // require(msg.value == buyPrice, "Insufficient balance");
        // payable(walletAddress).transfer(address(this).balance);
        
        require(DISTRIBUTION_SUPPLY >= 1, "MVP: Insufficient Supply");
        require(amount <= DISTRIBUTION_SUPPLY, "MVP: Amount is greater that Supply");
        // transfer USDC to this contract
        IERC20(usdtAddress).transferFrom(msg.sender, address(this), buyPrice);

        // Transfer USDC tokens to the users wallet
        IERC20(usdtAddress).transfer(withdrawAddress, buyPrice);
        DISTRIBUTION_SUPPLY = DISTRIBUTION_SUPPLY - tokenAmount;
        TOTAL_SELL = TOTAL_SELL + tokenAmount;
        slotIncrease();
        priceIncrease();
        burn();
        _transfer(_owner, msg.sender, tokenAmount);
        emit BuyToken(msg.sender, tokenAmount, address(this).balance, withdrawAddress);
    }

    function slotIncrease() internal {
        if(TOTAL_SELL >= 150000 * ZEROES) {
            SLOT = 2;
        }else if(TOTAL_SELL >= 300000 * ZEROES) {
            SLOT = 3;
        }else if(TOTAL_SELL >= 450000 * ZEROES) {
            SLOT = 4;
        }else if(TOTAL_SELL >= 600000 * ZEROES) {
            SLOT = 5;
        }else if(TOTAL_SELL >= 750000 * ZEROES) {
            SLOT = 6;
        }else if(TOTAL_SELL >= 900000 * ZEROES) {
            SLOT = 7;
        }else if(TOTAL_SELL >= 1050000 * ZEROES) {
            SLOT = 8;
        }else if(TOTAL_SELL >= 1200000 * ZEROES) {
            SLOT = 9;
        }else if(TOTAL_SELL >= 1350000 * ZEROES) {
            SLOT = 10;
        }else if(TOTAL_SELL >= 1500000 * ZEROES) {
            SLOT = 11;
        }else if(TOTAL_SELL >= 1850000 * ZEROES) {
            SLOT = 12;
        }else if(TOTAL_SELL >= 2200000 * ZEROES) {
            SLOT = 13;
        }else if(TOTAL_SELL >= 2550000 * ZEROES) {
            SLOT = 14;
        }else if(TOTAL_SELL >= 2900000 * ZEROES) {
            SLOT = 15;
        }else if(TOTAL_SELL >= 3250000 * ZEROES) {
            SLOT = 16;
        }else if(TOTAL_SELL >= 3600000 * ZEROES) {
            SLOT = 17;
        }else if(TOTAL_SELL >= 3950000 * ZEROES) {
            SLOT = 18;
        }else if(TOTAL_SELL >= 4300000 * ZEROES) {
            SLOT = 19;
        }else if(TOTAL_SELL >= 4650000 * ZEROES) {
            SLOT = 20;
        }else{
            SLOT = 1;
        }
    }

    function priceIncrease() internal {
        uint256 firstModular = 750 * ZEROES;
        uint256 secondModular = 500 * ZEROES;
        uint256 newFMPriceSlot = TOTAL_SELL / firstModular;
        uint256 newSMPriceSlot = TOTAL_SELL / secondModular;
        if(SLOT == 1) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 10000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 2) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 20000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 3) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 40000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 4) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 80000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 5) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 160000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 6) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 320000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 7) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 640000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 8) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 1280000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 9) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 2560000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 10) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 5120000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 11) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 10240000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 12) {
            if(newFMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 20480000;
                PRICE_SLOT = newFMPriceSlot;
            }
        }else if(SLOT == 13) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 40960000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 14) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 81920000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 15) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 163840000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 16) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 327680000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 17) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 655360000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 18) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 1310720000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 19) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 26214400000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }else if(SLOT == 20) {
            if(newSMPriceSlot != PRICE_SLOT) {
                PRICE = PRICE + 5242880000;
                PRICE_SLOT = newSMPriceSlot;
            }
        }
        
    }

    function burn() internal {
        uint256 burnAmount = 0;
        if(SLOT == 2 && BURN_SLOT == 1) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 2;
        }else if(SLOT == 3 && BURN_SLOT == 2) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 3;
        }else if(SLOT == 4 && BURN_SLOT == 3) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 4;
        }else if(SLOT == 5 && BURN_SLOT == 4) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 5;
        }else if(SLOT == 6 && BURN_SLOT == 5) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 6;
        }else if(SLOT == 7 && BURN_SLOT == 6) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 7;
        }else if(SLOT == 8 && BURN_SLOT == 7) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 8;
        }else if(SLOT == 9 && BURN_SLOT == 8) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 9;
        }else if(SLOT == 10 && BURN_SLOT == 9) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 10;
        }else if(SLOT == 11 && BURN_SLOT == 10) {
            burnAmount = 75000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 11;
        }else if(SLOT == 12 && BURN_SLOT == 11) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 12;
        }else if(SLOT == 13 && BURN_SLOT == 12) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 13;
        }else if(SLOT == 14 && BURN_SLOT == 13) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 14;
        }else if(SLOT == 15 && BURN_SLOT == 14) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 15;
        }else if(SLOT == 16 && BURN_SLOT == 13) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 16;
        }else if(SLOT == 17 && BURN_SLOT == 16) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 17;
        }else if(SLOT == 18 && BURN_SLOT == 17) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 18;
        }else if(SLOT == 19 && BURN_SLOT == 18) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 19;
        }else if(SLOT == 20 && BURN_SLOT == 19) {
            burnAmount = 300000 * ZEROES;
            _burn(_owner, burnAmount);
            BURNING_SUPPLY = BURNING_SUPPLY - burnAmount;
            BURN_SLOT = 20;
        }
    }

    function getCurrentPrice() external view returns(uint256) {
        return PRICE;
    }
}