/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/ERC20.sol


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

// File: contracts/HlalStaking.sol

pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";


contract HlalStaking {


    using SafeMath for uint256;
   // using SafeERC20 for IERC20;


    uint256 public rewardRate1 = 2;
    uint256 public rewardsDuration1 = 3 days;
    uint256 public rewardRate2 = 3;
    uint256 public rewardsDuration2 = 5 days;
    uint256 public rewardRate3 = 5;
    uint256 public rewardsDuration3 = 7 days;
    uint256 public TIME_STEP = 1 days;
    uint256 constant public INVEST_MIN_AMOUNT = 1 * 10**1;
     uint256 constant public PERCENTS_DIVIDER = 100;
    
    IERC20 public stakingToken;

    uint256 public totalUsers;
    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 public totalInvested;

    struct Deposit {
        uint256 amount;
        uint256 start;
        uint256 finish;
        uint256 stakingtype;
        uint256 stakingapy;
        uint256 depostatus;
    }

    struct User {
        Deposit[]  deposits;
        uint256 checkpoint;
        uint256 endpoint;
        uint256 totalWithdrawn;
        uint256 currentStakingAmount;
        uint256 currentStakingType;
        uint256 currentStakingPeriod;
        uint256 currentStakingApy;
    }

    mapping  (address => User)  internal users;

    event  Newbie(address user);
    event NewDeposit(address indexed user,  uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor() {
       stakingToken = IERC20(0x59bFB89F870F9B5e409feA66e893bb533579C78F);
    }


    function invest() public payable {
       require(msg.value >= INVEST_MIN_AMOUNT);
       User  storage user = users[msg.sender];
         user.checkpoint = block.timestamp;
         user.endpoint = block.timestamp.add(rewardsDuration1);
         user.currentStakingAmount = msg.value;
         user.currentStakingType = 1;
         user.currentStakingPeriod = rewardRate1;
         user.currentStakingApy = rewardsDuration1;
         user.totalWithdrawn = 0;

         if(user.deposits.length == 0) {
             totalUsers = totalUsers.add(1);
             emit Newbie(msg.sender);
            
         }

         uint256  a = block.timestamp.add(rewardsDuration1);

         user.deposits.push(Deposit(msg.value,block.timestamp,a, 1, rewardsDuration1, 1 ));

         totalInvested = totalInvested.add(msg.value);
         totalDeposits = totalDeposits.add(1);
         stakingToken.transferFrom(msg.sender, address(this), msg.value);
         emit NewDeposit(msg.sender, msg.value);
    }


function secondInvest() public payable {
       require(msg.value >= INVEST_MIN_AMOUNT);
       User  storage user = users[msg.sender];
         user.checkpoint = block.timestamp;
         user.endpoint = block.timestamp.add(rewardsDuration2);
         user.currentStakingAmount = msg.value;
         user.currentStakingType = 1;
         user.currentStakingPeriod = rewardRate2;
         user.currentStakingApy = rewardsDuration2;
         user.totalWithdrawn = 0;

         if(user.deposits.length == 0) {
             totalUsers = totalUsers.add(1);
             emit Newbie(msg.sender);
            
         }

         uint256  a1 = block.timestamp.add(rewardsDuration2);

         user.deposits.push(Deposit(msg.value,block.timestamp,a1, 2, rewardsDuration2, 1 ));

         totalInvested = totalInvested.add(msg.value);
         totalDeposits = totalDeposits.add(1);
         stakingToken.transferFrom(msg.sender, address(this), msg.value);
         emit NewDeposit(msg.sender, msg.value);
    }


    function thirdInvest() public payable {
       require(msg.value >= INVEST_MIN_AMOUNT);
       User  storage user = users[msg.sender];
         user.checkpoint = block.timestamp;
         user.endpoint = block.timestamp.add(rewardsDuration3);
         user.currentStakingAmount = msg.value;
         user.currentStakingType = 1;
         user.currentStakingPeriod = rewardRate3;
         user.currentStakingApy = rewardsDuration3;
         user.totalWithdrawn = 0;

         if(user.deposits.length == 0) {
             totalUsers = totalUsers.add(1);
             emit Newbie(msg.sender);
            
         }

         uint256  a2 = block.timestamp.add(rewardsDuration3);

         user.deposits.push(Deposit(msg.value,block.timestamp,a2, 3, rewardsDuration3, 1 ));

         totalInvested = totalInvested.add(msg.value);
         totalDeposits = totalDeposits.add(1);
         stakingToken.transferFrom(msg.sender, address(this), msg.value);
         emit NewDeposit(msg.sender, msg.value);
    }


     function firstWithdraw() public {
		User storage user = users[msg.sender];
		
		uint256 dividends;
		uint256 toSend;
	


		for (uint256 i = 0; i < user.deposits.length; i++) {
					if ( block.timestamp  > user.deposits[i].finish) {
                        if(user.deposits[i].depostatus == 1) {
                            if(user.deposits[i].stakingtype == 1) {
                         user.deposits[i].depostatus = 0;
						dividends = (user.deposits[i].amount.mul(rewardRate1).div(PERCENTS_DIVIDER))
                        .mul(user.deposits[i].finish.sub(user.deposits[i].start))
                        .div(TIME_STEP);
						
					} else {
						dividends = (user.deposits[i].amount.mul(rewardRate1).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
					}
                        }
                    }
            }
				//ADD cuurent Calculated Divedends to TOSEnd
            
            	toSend = toSend.add(dividends);

			
		uint256 contractBalance = address(this).balance;

		require(toSend > 0, "No balance available");
		
		
		if (contractBalance < toSend) {
			toSend = contractBalance;
		}
	
	
		
		stakingToken.transfer(msg.sender, toSend);
		totalWithdrawn = totalWithdrawn.add(toSend);
		user.totalWithdrawn = user.totalWithdrawn.add(toSend);
		
		
		emit Withdrawal(msg.sender, toSend);
	}    


    function secondWithdraw() public {
		User storage user = users[msg.sender];
		
		uint256 dividends;
		uint256 toSend;
	


		for (uint256 i = 0; i < user.deposits.length; i++) {
					if ( block.timestamp  > user.deposits[i].finish) {
                        if(user.deposits[i].depostatus == 1) {
                            if(user.deposits[i].stakingtype == 2) {
                         user.deposits[i].depostatus = 0;
						dividends = (user.deposits[i].amount.mul(rewardRate2).div(PERCENTS_DIVIDER))
                        .mul(user.deposits[i].finish.sub(user.deposits[i].start))
                        .div(TIME_STEP);
						
					} else {
						dividends = (user.deposits[i].amount.mul(rewardRate1).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
					}
                        }
                    }
            }
				//ADD cuurent Calculated Divedends to TOSEnd
            
            	toSend = toSend.add(dividends);

			
		uint256 contractBalance = address(this).balance;

		require(toSend > 0, "No balance available");
		
		
		if (contractBalance < toSend) {
			toSend = contractBalance;
		}
	
	
		
		stakingToken.transfer(msg.sender, toSend);
		totalWithdrawn = totalWithdrawn.add(toSend);
		user.totalWithdrawn = user.totalWithdrawn.add(toSend);
		
		
		emit Withdrawal(msg.sender, toSend);
	} 


     function thirdWithdraw() public {
		User storage user = users[msg.sender];
		
		uint256 dividends;
		uint256 toSend;
	


		for (uint256 i = 0; i < user.deposits.length; i++) {
					if ( block.timestamp  > user.deposits[i].finish) {
                        if(user.deposits[i].depostatus == 1) {
                            if(user.deposits[i].stakingtype == 3) {
                         user.deposits[i].depostatus = 0;
						dividends = (user.deposits[i].amount.mul(rewardRate1).div(PERCENTS_DIVIDER))
                        .mul(user.deposits[i].finish.sub(user.deposits[i].start))
                        .div(TIME_STEP);
						
					} else {
						dividends = (user.deposits[i].amount.mul(rewardRate3).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
					}
                        }
                    }
            }
				//ADD cuurent Calculated Divedends to TOSEnd
            
            	toSend = toSend.add(dividends);

			
		uint256 contractBalance = address(this).balance;

		require(toSend > 0, "No balance available");
		
		
		if (contractBalance < toSend) {
			toSend = contractBalance;
		}
	
	
		
		stakingToken.transfer(msg.sender, toSend);
		totalWithdrawn = totalWithdrawn.add(toSend);
		user.totalWithdrawn = user.totalWithdrawn.add(toSend);
		
		
		emit Withdrawal(msg.sender, toSend);
	} 


    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


function getUserDividends(address userAddress) public view returns (uint256) {


        User storage user = users[userAddress];
        

        
        uint256 dividends;
        

                for (uint256 i = 0; i < user.deposits.length; i++) {
					if ( block.timestamp  > user.deposits[i].finish) {
                        if(user.deposits[i].depostatus == 1) {
						dividends = (user.deposits[i].amount.mul(user.deposits[i].stakingapy).div(PERCENTS_DIVIDER))
                        .mul(user.deposits[i].finish.sub(user.deposits[i].start))
                        .div(TIME_STEP);
						
					} else {
						dividends = (user.deposits[i].amount.mul(user.deposits[i].stakingapy).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
					}
                        }
                    }
            
				//ADD cuurent Calculated Divedends to TOSEnd
            
            	

        return dividends;
    }

function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }


    function getUserEndpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].endpoint;
    }

    function getUserCurrentStakingType(address userAddress) public view returns(uint256) {
        return users[userAddress].currentStakingType;
    }

    function getUserCurrentStakingAmount(address userAddress) public view returns(uint256) {
        return users[userAddress].currentStakingAmount;
    }
 
    function getUserCurrentStakingPeriod(address userAddress) public view returns(uint256) {
        return users[userAddress].currentStakingPeriod;
    }

    function getUserCurrentStakingApy(address userAddress) public view returns(uint256) {
        return users[userAddress].currentStakingApy;
    }

    function getUserTotalWithdrwan(address userAddress) public view returns(uint256) {
        return users[userAddress].totalWithdrawn;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].start, user.deposits[index].finish, user.deposits[index].stakingtype, user.deposits[index].stakingapy, user.deposits[index].depostatus);
    }


    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalActiveDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if(user.deposits[i].depostatus == 1){
            amount = amount.add(user.deposits[i].amount);
            }
        }

        return amount;
    }

    function getUserAmountOfActiveDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amountL;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if(user.deposits[i].depostatus == 1){
            amountL = amountL.add(i);
            }
        }

        return amountL;
    }

}