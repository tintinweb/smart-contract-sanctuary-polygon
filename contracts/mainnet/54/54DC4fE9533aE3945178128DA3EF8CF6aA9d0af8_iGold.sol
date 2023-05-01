/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity 0.8.19;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.19;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.19;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.19;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.19;




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

// File: Contracts/old_iGold.sol



// ISLAMI Gold iGold

pragma solidity 0.8.19;







interface IPMMContract {
    enum RState {
        ONE,
        ABOVE_ONE,
        BELOW_ONE
    }

    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            RState newRState,
            uint256 newQuoteTarget
        );
}

interface IiGoldNFT {
    function mint(address) external returns (uint256);

    function burn(address, uint256) external;

    function ownerOf(uint256) external returns (address);

    function totalSupply() external view returns (uint256);
}

contract iGold is ERC20, Ownable {
    using SafeMath for uint256;

    IPMMContract public pmmContract;
    IiGoldNFT public iGoldNFT;

    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;

    address public goldBuyer;

    IERC20 public iGoldToken;
    IERC20 public islamiToken;
    IERC20 public usdtToken;
    AggregatorV3Interface public goldPriceFeed;

    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not admin");
        _;
    }

    modifier notPausedTrade() {
        require(!isPaused, "Trading is paused");
        _;
    }

    // Define a modifier that checks if it's between Monday 00:00 GMT and Friday 20:55 GMT
    modifier onlyWeekdays() {
        uint256 dayOfWeek = (block.timestamp / 86400 + 4) % 7; // Monday as day 0
        uint256 timeOfDay = block.timestamp % 86400; // Seconds since midnight

        // Monday to Thursday are allowed, and Friday before 20:55 GMT is allowed
        require(
            (dayOfWeek >= 0 && dayOfWeek <= 3) || (dayOfWeek == 4 && timeOfDay < (20 * 3600 + 55 * 60)),
            "iGold trading between Monday 00:00 GMT and Friday 20:55 GMT."
        );
        _;
    }

    event iGoldNFTMinted(address indexed user, uint256 nftId);
    event iGoldNFTReturned(address indexed user, uint256 indexed nftId);
    event goldReserved(
        string Type,
        uint256 goldAddedInGrams,
        uint256 totalGoldInGrams
    );
    event trade(
        string Type,
        uint256 iGold,
        int256 priceInUSD,
        uint256 amountPay,
        uint256 feesInISLAMI
    );
    event PhysicalGoldRequest(
        address indexed user,
        uint256 goldAmount,
        string deliveryDetails
    );
    event TokensWithdrawn(
        address indexed token,
        address indexed owner,
        uint256 amount
    );
    event tradingPaused(bool status);

    uint256 public constant iGoldTokensPerOunce = 31103476800;
    uint256 public goldReserve; // in grams
    uint256 public usdtVault;
    uint256 public feesBurned;
    uint256 public physicalGoldFee = 50 * 1e6;
    uint256 public physicalGoldFeeSwiss = 200 * 1e6;

    bool isPaused;

    function decimals() public view virtual override returns (uint8) {
        return 8; //same decimals as price of gold returned from ChainLink
    }

    constructor(
        address _islamiToken,
        address _usdtToken,
        address _pmmContract,
        address _goldPriceFeed,
        address _iGoldNFT
    ) ERC20("iGold", "iGold") {
        islamiToken = IERC20(_islamiToken);  // 0x9c891326Fd8b1a713974f73bb604677E1E63396D
        usdtToken = IERC20(_usdtToken);  // 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        iGoldToken = IERC20(address(this));
        pmmContract = IPMMContract(_pmmContract); // 0x14afbB9E6Ab4Ab761f067fA131e46760125301Fc
        goldPriceFeed = AggregatorV3Interface(_goldPriceFeed); //(0x0C466540B2ee1a31b441671eac0ca886e051E410);
        iGoldNFT = IiGoldNFT(_iGoldNFT); //0xB6aD219F3b0951AFF903bc763210599d852205Bd
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0), "zero address");
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0), "zero address");
        admins[_admin] = false;
    }

    function addUSDT(uint256 _amount) external {
        require(
            usdtToken.transferFrom(msg.sender, address(this), _amount),
            "Check USDT balance or allowance"
        );
        usdtVault += _amount;
    }

    function setNFTContractAddress(address _iGoldNFT) external onlyOwner {
        require(_iGoldNFT != address(0x0), "Zero address");
        iGoldNFT = IiGoldNFT(_iGoldNFT);
    }

    function pause(bool _status) external onlyOwner returns (bool) {
        int256 _goldPrice = getLatestGoldPriceOunce();
        if (_status) {
            require(_goldPrice == 0, "gold price is not zero");
        } else {
            require(_goldPrice > 0, "gold price is zero");
        }
        isPaused = _status;
        emit tradingPaused(_status);
        return (_status);
    }

    function setPhysicalGoldFee(uint256 newFeeLocal, uint256 newFeeSwiss)
        external
        onlyOwner
    {
        physicalGoldFee = newFeeLocal * 1e6;
        physicalGoldFeeSwiss = newFeeSwiss * 1e6;
    }

    function setUSDTAddress(address _USDT) external onlyOwner {
        require(_USDT != address(0x0), "Zero address");
        usdtToken = IERC20(_USDT);
    }

    function setISLAMIAddress(address _ISLAMI) external onlyOwner {
        require(_ISLAMI != address(0x0), "Zero address");
        islamiToken = IERC20(_ISLAMI);
    }

    function setIslamiPriceAddress(address _pmmContract) external onlyOwner {
        require(_pmmContract != address(0x0), "Zero address");
        pmmContract = IPMMContract(_pmmContract);
    }

    function setGoldPriceAddress(address _goldPriceFeed) external onlyOwner {
        require(_goldPriceFeed != address(0x0), "Zero address");
        goldPriceFeed = AggregatorV3Interface(_goldPriceFeed);
    }

    function getIslamiPrice(uint256 payQuoteAmount)
        public
        view
        returns (uint256 _price)
    {
        address trader = address(this);
        // Call the querySellQuote function from the PMMContract
        (uint256 receiveBaseAmount, , , ) = pmmContract.querySellQuote(
            trader,
            payQuoteAmount
        );
        _price = receiveBaseAmount;
        return _price;
    }

    function getLatestGoldPriceOunce() public view returns (int256) {
        (, int256 pricePerOunce, , , ) = goldPriceFeed.latestRoundData();
        return pricePerOunce;
    }

    function getLatestGoldPriceGram() public view returns (int256) {
        int256 pricePerGram = (getLatestGoldPriceOunce() * 1e8) / 3110347680; // Multiplied by 10^8 to handle decimals

        return pricePerGram;
    }

    function getIGoldPrice() public view returns (int256) {
        int256 iGoldPrice = (getLatestGoldPriceGram()) / 10;
        return iGoldPrice;
    }

    function addGoldReserve(uint256 amountGold) external onlyAdmin {
        //The function is always tracked by Crypto Halal Office after physical gold check
        goldReserve += amountGold;
        emit goldReserved("Add", amountGold, goldReserve);
    }

    function removeGoldReserve(uint256 amountGold) external onlyOwner {
        //The function is always tracked by Crypto Halal Office after physical gold check
        goldReserve -= amountGold;
        emit goldReserved("Remove", amountGold, goldReserve);
    }

    function buy(uint256 _usdtAmount)
        external
        notPausedTrade
        onlyWeekdays
        returns (uint256)
    {
        require(
            totalSupply() <= goldReserve.mul(1e8).div(10),
            "gold reserve reached"
        );
        int256 goldPrice = getLatestGoldPriceGram();
        require(goldPrice > 0, "Invalid gold price");

        uint256 _iGoldAmount = _usdtAmount.mul(1e2).mul(1e1).mul(1e8).div(
            uint256(goldPrice)
        ); // 0.1g per token
        uint256 islamiFee = getIslamiPrice(_usdtAmount.div(100)); // 1% fee

        emit trade(
            "Buy",
            _iGoldAmount.div(1e8),
            goldPrice / (1e8),
            _usdtAmount / (1e6),
            islamiFee / (1e7)
        );

        require(
            usdtToken.transferFrom(msg.sender, address(this), _usdtAmount),
            "Check USDT allowance or user balance"
        );
        require(
            islamiToken.transferFrom(msg.sender, deadWallet, islamiFee),
            "Check ISLAMI allowance or user balance"
        );

        usdtVault = usdtVault.add(_usdtAmount);

        feesBurned = feesBurned.add(islamiFee);

        _mint(msg.sender, _iGoldAmount);
        return _iGoldAmount;
    }

    function sell(uint256 _iGoldAmount) public notPausedTrade onlyWeekdays {
        int256 goldPrice = getLatestGoldPriceGram();
        require(goldPrice > 0, "Invalid gold price");

        uint256 _usdtAmount = _iGoldAmount
            .mul(uint256(goldPrice))
            .div(1e4)
            .div(1e1)
            .div(1e6); // 0.1g per token
        uint256 islamiFee = getIslamiPrice(_usdtAmount.div(100)); // 1% fee

        emit trade("Sell", _iGoldAmount, goldPrice, _usdtAmount, islamiFee);

        _burn(msg.sender, _iGoldAmount);
        require(
            usdtToken.transfer(msg.sender, _usdtAmount),
            "USDT amount in contract does not cover your sell!"
        );
        require(
            islamiToken.transferFrom(msg.sender, deadWallet, islamiFee),
            "Check ISLAMI allowance or user balance"
        );

        usdtVault = usdtVault.sub(_usdtAmount);

        feesBurned = feesBurned.add(islamiFee);
    }

    function receivePhysicalGold(
        uint256 ounceId,
        uint256 ounceType,
        string calldata deliveryDetails
    ) external notPausedTrade {
        uint256 feeInUSDT;
        if (ounceType == 0) {
            feeInUSDT = physicalGoldFee;
        } else {
            feeInUSDT = physicalGoldFeeSwiss;
        }

        require(
            usdtToken.balanceOf(msg.sender) >= feeInUSDT,
            "Insufficient USDT balance"
        );
        require(
            usdtToken.allowance(msg.sender, address(this)) >= feeInUSDT,
            "Insufficient USDT allowance"
        );

        iGoldNFT.burn(msg.sender, ounceId);
        goldReserve = goldReserve.sub(iGoldTokensPerOunce);

        usdtToken.transferFrom(msg.sender, address(this), feeInUSDT);
        usdtVault = usdtVault.add(feeInUSDT);

        emit PhysicalGoldRequest(
            msg.sender,
            iGoldTokensPerOunce,
            deliveryDetails
        );
    }

    function checkReserves()
        public
        view
        returns (uint256 goldValue, uint256 usdtInVault)
    {
        int256 goldPrice = getLatestGoldPriceGram();
        require(goldPrice > 0, "Invalid gold price");
        uint256 iGoldInNFT = iGoldTokensPerOunce * (iGoldNFT.totalSupply());
        uint256 totalMintedGold = totalSupply() + iGoldInNFT; // Total minted iGold tokens (each token represents 0.1g of gold)
        goldValue = totalMintedGold
            .mul(uint256(goldPrice))
            .div(1e4)
            .div(1e1)
            .div(1e6); // Calculate the value of minted iGold tokens in USDT
        usdtInVault = usdtVault; // Current USDT in the contract

        return (goldValue, usdtInVault);
    }

    function mintIGoldNFT() external {
        uint256 iGoldBalance = balanceOf(msg.sender);

        require(
            iGoldBalance >= iGoldTokensPerOunce,
            "iGold balance not sufficient for an iGoldNFT"
        );
        _burn(msg.sender, iGoldTokensPerOunce);
        uint256 nftId = iGoldNFT.mint(msg.sender);

        emit iGoldNFTMinted(msg.sender, nftId);
    }

    function returnIGoldNFT(uint256 nftId) external {
        require(
            iGoldNFT.ownerOf(nftId) == msg.sender,
            "Caller is not the owner of this NFT"
        );

        iGoldNFT.burn(msg.sender, nftId);
        _mint(msg.sender, iGoldTokensPerOunce);

        emit iGoldNFTReturned(msg.sender, nftId);
    }

    function withdrawTokens(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            tokenAddress == address(0x0)
                ? address(this).balance >= amount
                : IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );

        if (tokenAddress == address(usdtToken)) {
            (uint256 _goldValue, ) = checkReserves();
            uint256 difference = usdtVault.sub(_goldValue);
            require(amount <= difference, "No extra USDT in contract");
            usdtVault -= amount;

            IERC20(usdtToken).transfer(msg.sender, amount);
        } else if (tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(msg.sender, amount);
        }

        emit TokensWithdrawn(tokenAddress, msg.sender, amount);
    }
}

                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/