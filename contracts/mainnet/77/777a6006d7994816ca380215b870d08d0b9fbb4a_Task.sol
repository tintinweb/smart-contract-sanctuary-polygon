/**
 *Submitted for verification at polygonscan.com on 2023-03-01
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/detask_v3_short.sol


pragma solidity ^0.8.9;



/// @author DeTask team
/// @title Interface to access the TaskRewardTreasuryConfig smart contract in the blockchain
interface ITaskRewardTreasuryConfig {
    function calcFee(uint256 _value, uint256 _percent) external pure returns(uint256);
    function getTreasuryFeePercent(address _sender, address _payWithToken) external view returns (uint256);
    function getTreasuryFeeValue(uint256 _value, address _sender) external view returns (uint256);
    function getTreasuryAddress() external view returns (address);
    function getAffiliateCommision(address _affiliate) external view returns (uint256);
    function canArbitrate(address _sender) external view returns (bool);
    function getTokenAllowance(address _token) external view returns (bool, uint256);
    function isTokenAllowed(address _token) external view returns (bool);
    function chargeCancelationFee(address _sender) external view returns (bool);
    function getManagerTaskArbitration(address _manager) external view returns (bool);
    function getPartnerTaskApprovers(address _partner) external view returns (address[] memory);
}

/// @author DeTask team
/// @title The configuration was created to adjust fees and manage affiliate, partner, and treasury addresses when creating a task
contract TaskRewardTreasuryConfig {
    ///Address responsable for administrate the smart contract data
    address private owner;
    ///The percentage that will be charged on each task
    uint256 private treasuryFee;
    ///ADO address that will receive the task fees
    address private treasuryAddress;
    ///Activate task cancelation fee
    bool private chargeFeeOnCancel;
    ///Affiliated commission fee. The fee will be deducted from the DeTask fee
    mapping(address => uint256) private affiliateCommision;
    ///Partner addresses that will pay a different fee
    mapping(address => uint256) private partnerFee;
    ///Partner related to an address
    mapping(address => address) private partners;
    //Arbitrators that has power over tasks
    mapping(address => bool) private arbitrators;
    //Enabled arbitrators to an address
    mapping(address => bool) private managerTaskWithArbitrate;
    //List of allowed tokens
    mapping(address => bool) private tokensAllowed;
    //The commission fee to use the token
    mapping(address => uint256) private tokensFee;
    //List of sender and token fee
    mapping(address => mapping(address => uint256)) private partnerTokenFee;
    //List of sender to charge cancelation fee
    mapping(address => bool) private chargeCancelationSenderFee;
    //List of task approvers
    mapping(address => mapping(address => bool)) private managerTaskApprovers;
    mapping(address => address[]) private managerTaskApproversAddress;

    ///Public events on the blockchain
    event TreasuryChanged(address indexed _approver, address _treasuryAddress, uint256 _treasuryFee, uint256 indexed _date);
    event SetupAffiliateCommission(address indexed _sender, address _affiliate, uint256 _commission, uint256 indexed _date);
    event SetupPartnerFee(address indexed _sender, address _partner, uint256 _fee, uint256 indexed _date);
    event SetupArbitrators(address indexed _sender, address _arbitrator, bool _permission, uint256 indexed _date);
    event SetupManagerTaskWithArbitration(address indexed _sender, address _manager, bool _arbitrate, uint256 indexed _date);
    event AddPartner(address indexed _sender, address _partner, address _wallet, uint256 indexed _date);
    event AllowTokens(address indexed _sender, address _token, bool _allowed, uint256 _fee, uint256 indexed _date);
    event SetupPartnerTokensFee(address indexed _sender, address _partner, address _token, uint256 _fee, uint256 indexed _date);
    event SetupPartnerTaskApprovers(address indexed _sender, address _partner, address _approver, bool _allow, uint256 indexed _date);
    event ChangeOwner(address indexed _old, address indexed _new, uint256 indexed _date);

    /// @notice Only owner who create the task is allowed
    modifier restricted() {
        require(msg.sender == owner, "Only owner can change config!");
        _;
    }

    /// @notice No zero address allowed
    modifier noZeroAddress(address _newOwner) {
        require(_newOwner != address(0), "Address cannot be zero!");
        _;
    }

    /** @notice config initialization
      * @dev Initialize the contract with a owner, set the default treasury fee for 4% in bips, and the treasury address that will receive the commisstion
      */
    constructor() {
        owner = msg.sender;
        treasuryFee = 200; //2% = 200bips, 1.80% = 180 
        treasuryAddress = 0x4b82503658269FF9b1B9BE83ffc26FBa76335f25;
    }

    /** @notice Change the ADO treasury address
      * @dev Store the address on the variable `treasuryAddress`
      * @param _newAddress The new ADO treasury address value to receive the task’s fee
      */
    function changeTreasuryAddress(address _newAddress) public restricted {
        treasuryAddress = _newAddress;
        emit TreasuryChanged(owner, _newAddress, treasuryFee, getDateTime());
    }

    /** @notice Change the config fee that is calculated on each task
      * @dev Store the number on the variable `treasuryFee`
      * @param _newFeeInBips The new fee value, in bips = 100, that will be used to charge new tasks
      */
    function changeTreasuryFee(uint256 _newFeeInBips) public restricted {
        treasuryFee = _newFeeInBips;
        emit TreasuryChanged(owner, treasuryAddress, _newFeeInBips, getDateTime());
    }

    /** @notice Change the factory owner address to a new owner
      * @dev Update the owner address
      * @param _newOwner is the address of the new owner
      */
    function changeOwner(address _newOwner) external restricted noZeroAddress(_newOwner) {
        emit ChangeOwner(msg.sender, _newOwner, getDateTime());
        owner = _newOwner;
    }

    /** @notice Add or update an affiliate address and commission on the config list. The commission will be calculated over the treasury fee value
      * @dev Store the affiliate address and commision inside the mapping `affiliateCommision`
      * @param _affiliate is the address of a wallet or DAO that will receive the affiliated commission 
      * @param _commissionInBips is the affiliate commission percentage number, in bips = 100
      */
    function setupAffiliateCommission(address _affiliate, uint256 _commissionInBips) public restricted noZeroAddress(_affiliate){
        affiliateCommision[_affiliate] = _commissionInBips;
        emit SetupAffiliateCommission(msg.sender, _affiliate, _commissionInBips, getDateTime());
    }

    /** @notice Add or update a partner address and fee on the config list
      * @dev Store the partner address and fee inside the mapping `partnerFee`
      * @param _partner is the address of a wallet that will receive a special fee during a task creation 
      * @param _feeInBips is the partner special fee percentage number, in bips = 100
      */
    function setupPartnerFee(address _partner, uint256 _feeInBips) public restricted noZeroAddress(_partner){
        partnerFee[_partner] = _feeInBips;
        emit SetupPartnerFee(msg.sender, _partner, _feeInBips, getDateTime());
    }

    /** @notice Add or update a partner token address and fee on the config list
      * @dev Store the partner address and fee inside the mapping `partnerFee`
      * @param _partner is the address of a wallet that will receive a special fee during a task creation 
      * @param _token is the address of a token that will receive a special fee during a task creation 
      * @param _feeInBips is the partner special fee percentage number, in bips = 100
      */
    function setupPartnerTokenFee(address _partner, address _token, uint256 _feeInBips) public restricted noZeroAddress(_partner){
        partnerTokenFee[_partner][_token] = _feeInBips;
        emit SetupPartnerTokensFee(msg.sender, _partner, _token, _feeInBips, getDateTime());
    }

    /** @notice Add or update a partner approvers address list
      * @dev Store the partner approver address inside the mapping `managerTaskApprovers`
      * @param _partner is the manager address of a wallet will create a task
      * @param _approver is the address of a wallet that may approver tasks 
      * @param _allow used to aneble or disable the approver
      */
    function setupPartnerTaskApprovers(address _partner, address _approver, bool _allow) public restricted noZeroAddress(_partner){
        managerTaskApprovers[_partner][_approver] = _allow;
        managerTaskApproversAddress[_partner].push(_approver);
        emit SetupPartnerTaskApprovers(msg.sender, _partner, _approver, _allow, getDateTime());
    }    

    /** @notice Add or update a arbitrator address
      * @dev Store the arbitrator address and permission inside the mapping `arbitrators`
      * @param _arbitrator is the address of a wallet that will arbitrate some tasks function 
      * @param _permission is the permission arbitrate
      */
    function setupArbitrator(address _arbitrator, bool _permission) public restricted noZeroAddress(_arbitrator){
        arbitrators[_arbitrator] = _permission;
        emit SetupArbitrators(msg.sender, _arbitrator, _permission, getDateTime());
    }

    /** @notice Add or update a manager task to initialize with arbitration
      * @dev Store the arbitrator setup inside the mapping `managerTaskWithArbitrate`
      * @param _manager is the address of a manager wallet that will enable the arbitration 
      * @param _arbitrate is the permission to create a task with arbitration
      */
    function setupManagerTaskWithArbitration(address _manager, bool _arbitrate) public restricted noZeroAddress(_manager){
        managerTaskWithArbitrate[_manager] = _arbitrate;
        emit SetupManagerTaskWithArbitration(msg.sender, _manager, _arbitrate, getDateTime());
    }

    /** @notice Active cancelation fee on task
      * @dev Store the cancel charge fee on the variable `chargeFeeOnCancel`
      * @param _charge is the activation fee charge
      */
    function setupCancelationFee(bool _charge) public restricted {
        chargeFeeOnCancel = _charge;
    }

    /** @notice Active cancelation fee on task
      * @dev Store the cancel charge fee option on the mapping `chargeCancelationSenderFee`
      * @param _sender is the address that will receive the benefit
      * @param _charge is the boolean to set the fee charge
      */
    function setupCancelationSenderFee(address _sender, bool _charge) public restricted {
        chargeCancelationSenderFee[_sender] = _charge;
    }

    /** @notice Add a partner to an address to have multiple wallet to one partner main address
      * @dev Store the partner to the mapping `partners`
      * @param _partner is the address that be associated with an wallet
      * @param _sender is the user wallet
      */
    function addPartner(address _partner, address _sender) public restricted noZeroAddress(_partner) noZeroAddress(_sender){
        partners[_sender] = _partner;
        emit AddPartner(msg.sender, _partner, _sender, getDateTime());
    }

    /** @notice Allow token to be used on SeTask
      * @dev Store the allow to the mapping `tokensAllowed` and fee on `tokensFee`
      * @param _token is the address the token that can be used on DeTask
      * @param _allow is boolean that allow a token to be used
      @ @param _feeInBips is the commission, in bips = 100, the manager will pay when use a token on the platform
      */
    function allowToken(address _token, bool _allow, uint256 _feeInBips) public restricted noZeroAddress(_token){
        tokensAllowed[_token] = _allow;
        tokensFee[_token] = _feeInBips;
        emit AllowTokens(msg.sender, _token, _allow, _feeInBips, getDateTime());
    }

    /** @notice Calculate the fee that will be used on the task
      * @dev Verify if the partner is valid and calculate the appropriate fee for the task
      * @param _partner The wallet address of the manager who is creating the task
      * @return the fee number value, in bips = 100
      */
    function calculateFeePercent(address _partner) private view returns(uint256){
        if (_partner == address(0)){
            return treasuryFee;
        }
        else{
            uint256 fee = partnerFee[_partner];
            if (fee == 0)
            {
                return treasuryFee;
            }
            else
            {
                return fee;
            }
        }
    }

    /** @notice Calculate the percentage of a giving number
      * @dev Calculate a percentage of a number
      * @param _value the number you want to calculate the percentage
      * @param _percentInBips the percentage you want to calculate in bips, 100 = 1 bips
      * @return The calculated percentage value o a number 
      */
    function calculateTreasuryFee(uint256 _value, uint256 _percentInBips) private pure returns(uint256){
      (bool workedTreasuryFee, uint256 feeValue) = SafeMath.tryMul(_value, _percentInBips);
      (bool workedTreasuryFeeFinal, uint256 finalFeeValue) = SafeMath.tryDiv(feeValue, 10000);
      return workedTreasuryFee && workedTreasuryFeeFinal ? finalFeeValue : 0;
    }

    /** @notice Return the datetime
      * @dev Return the timestamp of the block
      * @return the block time stamp
      */
    function getDateTime() private view returns (uint256){
      return block.timestamp;
    }

    /** @notice Calculate the fee that will be used on the task
      * @dev Verify if the partner is valid and calculate the appropriate fee for the task
      * @param _value the value the fee will be calculated
      * @param _sender The wallet address of the manager who is creating the task
      * @return the fee number value
      */
    function getTreasuryFeeValue(uint256 _value, address _sender) external view returns (uint256) {
      uint256 fee = calculateFeePercent(partners[_sender]);
      return calculateTreasuryFee(_value, fee);
    }

    /** @notice Retrieve the fee that will be used on the task (main => partner => token => token parnet)
      * @dev call the function `calculateFeePercent`
      * @param _sender The wallet address of the manager who is creating the task
      * @param _payWithToken The token address used to pay the task
      * @return the fee number value
      */
    function getTreasuryFeePercent(address _sender, address _payWithToken) external view returns (uint256) {
      uint256 fee = calculateFeePercent(partners[_sender]);

      //Get the token fee
      if (_payWithToken != address(0) && tokensAllowed[_payWithToken]){
        fee = tokensFee[_payWithToken];
        //get the partner token fee
        if (partnerTokenFee[_sender][_payWithToken] > 0)
          fee = partnerTokenFee[_sender][_payWithToken];
      }

      return fee;
    }

    /** @notice Retrieve the cancelation charge by sender that will be used on the task
      * @dev check if the sender has the benefit `chargeCancelationSenderFee` and the `chargeFeeOnCancel` 
      * @param _sender The wallet address of the manager who has the benefit
      * @return the sender charge cancelation option
      */
    function chargeCancelationFee(address _sender) external view returns (bool){
        bool _cancelFee = chargeCancelationSenderFee[_sender];
        if (_cancelFee == false){
          return chargeFeeOnCancel;
        }
        else {
          return true;
        }
    }

    /** @notice Calculate the percentage of a giving number
      * @dev Calculate a percentage of a number
      * @param _value the number you want to calculate the percentage
      * @param _percentInBips the percentage, in bips = 100, you want to calculate
      * @return The calculated percentage value o a number 
      */
    function calcFee(uint256 _value, uint256 _percentInBips) external pure returns(uint256){
        return calculateTreasuryFee(_value, _percentInBips);
    }

    /** @notice Get the current DAO treasury address
      * @dev retrieves the value of the variable `treasuryAddress`
      * @return the treasury address value
      */
    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
    }

    /** @notice Get an affiliate commission percentage fee
      * @dev retrieves the number out of the mapping `affiliateCommision`
      * @param _affiliate is the address of a wallet or DAO 
      * @return the commission number value of an affiliate
      */
    function getAffiliateCommision(address _affiliate) external view returns (uint256) {
        return affiliateCommision[_affiliate];
    }

    /** @notice Get a partner fee
      * @dev retrieves the number out of the mapping `partnerFee`
      * @param _partner is the address of a wallet
      * @param _token is the address of a token
      * @return the fee number value of a partner
      */
    function getPartnerTokenFee(address _partner, address _token) external view returns (uint256) {
        return partnerTokenFee[_partner][_token];
    }

    /** @notice Get a partner allow approver by approver
      * @dev retrieves the number out of the mapping `partnerFee`
      * @param _partner is the address of a partner wallet
      * @param _approver is the address of the approver
      * @return the approver status
      */
    function getPartnerTaskApproverStatus(address _partner, address _approver) external view returns (bool) {
        return managerTaskApprovers[_partner][_approver];
    }
    
    /** @notice Get a partner task approvers list
      * @dev retrieves the number out of the mapping `partnerFee`
      * @param _partner is the address of a partner wallet
      * @return the mapping of approvers
      */
    function getPartnerTaskApprovers(address _partner) external view returns (address[] memory) {
      uint allowed = 0;
      for (uint i=0; i < managerTaskApproversAddress[_partner].length; i++)
      {
        if (managerTaskApprovers[_partner][managerTaskApproversAddress[_partner][i]])
          allowed++;
      }

      address[] memory partnerApprovers = new address[](allowed);
      uint added = 0;
      for (uint i=0; i < managerTaskApproversAddress[_partner].length; i++)
      {
        if (managerTaskApprovers[_partner][managerTaskApproversAddress[_partner][i]]){
          partnerApprovers[added] = managerTaskApproversAddress[_partner][i];
          added++;
        }
      }
        return partnerApprovers;
    }

    /** @notice Get the manager task to initialize with arbitration setup
      * @dev retrieves the setup inside the mapping `managerTaskWithArbitrate`
      * @param _manager is the address of a wallet
      * @return the setup value of manager wallet
      */
    function getManagerTaskArbitration(address _manager) external view returns (bool) {
        return managerTaskWithArbitrate[_manager];
    }

    /** @notice Get a partner fee
      * @dev retrieves the number out of the mapping `partnerFee`
      * @param _partner is the address of a wallet
      * @return the fee number value of a partner
      */
    function getPartnerFee(address _partner) external view returns (uint256) {
        return partnerFee[_partner];
    }

    /** @notice Get a partner address
      * @dev retrieves the partner address from mapping `partners`
      * @param _sender is the address of a user wallet
      * @return the partner address
      */
    function getPartner(address _sender) external view returns (address) {
        return partners[_sender];
    }

    /** @notice Check if the sender can arbitrate
      * @dev retrieves the arbitrate address from mapping `arbitrators`
      * @param _sender is the address of a user wallet
      * @return a if the address can arbitrate
      */
    function canArbitrate(address _sender) external view returns (bool) {
        return arbitrators[_sender];
    }

    /** @notice Return the data if a token can be used on DeTask
      * @dev Retrieves if a token is allowed to be used on the task
      * @return allowed return if a token can be used on the contract
      */
    function isTokenAllowed(address _token) external view returns (bool){
        return tokensAllowed[_token];
    }

    /** @notice Return the data if a token can be used on DeTask
      * @dev Retrieves a list of variables from the token mappin contract
      * @return allowed return if a token can be used on the contract
      * @return fee is the number in percentage that a task should pay when use the token 
      */
    function getTokenAllowance(address _token) external view returns (bool, uint256) {
        return (
          tokensAllowed[_token],
          tokensFee[_token]
        );
    }

    /** @notice Return the data from the contract
      * @dev Retrieves a list of variables from the contract
      * @return owner is the address of who creates the contract
      * @return treasuryAddress is the address of the treasury that will receive the task's fee
      * @return treasuryFee is the number in percentage that a task should pay when approved 
      */
    function getSummary() public view returns (address, address, uint256) {
        return (
          owner,
          treasuryAddress,
          treasuryFee
        );
    }
}

/// @author DeTask team
/// @title This DAO smart contract was created to save all fees paid from the tasks and trades
/// @notice Only authorized address can request withdraw from this treasury DAO and must have 50% approval to complete the transaction 
contract TaskRewardTreasury {
    ///Used to store withdraw request information    
    struct Request {
        ///Withdraw description
        string description;
        ///Withdraw value that will be transferred from the ADO 
        uint256 value;
        //Use different token for transfer
        address token;
        ///Destination wallet address
        address recipient;
        ///Flag to inform if the request was already completed
        bool complete;
        ///How many address approve the request
        uint256 approvalCount;
        ///List of addresses that vote to approve or disapprove the request 
        mapping(address => bool) approvals;
    }

    ///Address that creates the treasury. Only this address can add or remove provers.
    address private owner;
    ///List of all requests created
    mapping (uint256 => Request) public requests;
    ///Total number of requests created
    uint256 private requestsCount;
    ///List of addresses that can vote to approve a request
    mapping(address => bool) public approvers;
    ///Total number of approvers
    uint256 private approversCount;

    //This generates a public event on the blockchain on task update
    event AddApprovers(address indexed _approver, uint256 indexed _date);
    event DeleteApprovers(address indexed _approver, uint256 indexed _date);
    event Deposited(address indexed _sender, uint256 _amount, uint256 indexed _date);
    event RequestCreated(address indexed _sender, uint256 indexed _id, uint256 indexed _date);
    event RequestApproved(address indexed _sender, uint256 indexed _id, uint256 indexed _date);
    event RequestFinalized(address indexed _sender, uint256 indexed _id, uint256 indexed _date);

    /// @notice Only owner who create the task is allowed
    modifier restricted() {
        require(msg.sender == owner, "Only owner can add approvers!");
        _;
    }

    /// @notice Only owners and approvers can withdraw
    modifier approvereds() {
        require((msg.sender == owner) || (approvers[msg.sender]), "Only owner and approvers can request withdraw!");
        _;
    }

    /** @notice Return the datetime
      * @dev Return the timestamp of the block
      * @return the block time stamp
      */
    function getDateTime() private view returns (uint256){
      return block.timestamp;
    }

    /** @notice task reward initialization
      * @dev Initialize the contract with a owner
      */
    constructor() {
        owner = msg.sender;
    }

    /// @notice This function enable this contract to receive money from Task or any other source 
    receive() external payable {
      emit Deposited(msg.sender, msg.value, getDateTime());
    }

    /** @notice Add a wallet address to vote for the new requests
      * @dev Add an address to the mapping `approvers` and increment the numeric `approversCount`
      * @param _approver the wallet address of the voter who will be able to vote in a withdraw request
      */
    function addApprover(address _approver) public restricted {
        approvers[_approver] = true;
        approversCount++;

        emit AddApprovers(_approver, getDateTime());
    }

    /** @notice Disable a wallet address to vote for the new requests
      * @dev Flag false the approver’s address in the mapping `approvers` and decrement the numeric `approversCount`
      * @param _approver The wallet address of the voter who will not be able to vote anymore in a withdraw request
      */
    function removeApprover(address _approver) public restricted {
        approvers[_approver] = false;
        approversCount--;

        emit DeleteApprovers(_approver, getDateTime());
    }

    /** @notice Add a new withdraw request
      * @dev Increment the number of requests with the numeric `requestsCount`. Create a new request record and add on the mapping `requests` 
      * @param description The text explaining the reason the money should be withdrawn from the treasury
      * @param value The numeric amount of withdraw
      * @param recipient The wallet address that will receive the money 
      */
    function createRequest(string memory description, uint256 value, address recipient, address token) public approvereds {
        Request storage r = requests[requestsCount++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.token = token;
        r.complete = false;
        r.approvalCount = 0;

        emit RequestCreated(msg.sender, requestsCount, getDateTime());
    }

    /** @notice Vote to approve a request by index
      * @dev Locate the request by index on the mappin `requests`. Set true, approve request,  the address on the `requests` list and increment the number `approvalCount` on the `requests`
      * @param index The number that identify a request on the mappin
      */
    function approveRequest(uint256 index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender], "Only approvers can approve the request");
        require(!request.approvals[msg.sender], "Address already approved the request");

        request.approvals[msg.sender] = true;
        request.approvalCount++;

        emit RequestApproved(msg.sender, index, getDateTime());
    }

    /** @notice Validate if the majority approves the request and send the money to the destination recipient address
      * @dev Locate the request by index on the mappin `requests`. Verify if the request has more than 50% approval. Transfer the `request` money numeric field `value` to a destination address `recipient`, and update the `request` boolean field `complete` as true
      * @param index The number that identify a request on the mappin
      */
    function finalizeRequest(uint256 index) public approvereds {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2), "Not enought approval to finish the request");
        require(!request.complete, "Request was already finished");

        request.complete = true;
        emit RequestFinalized(msg.sender, index, getDateTime());

        if (request.token == address(0)){
          payable(request.recipient).transfer(request.value);
        }
        else
        {
          ERC20(address(request.token)).transfer(request.recipient, request.value);
        }

    }
    
    /** @notice Return the summary data from the contract
      * @dev Retrieves a list of variables from the contract
      * @return balance is the numeric total money stored on the smart contract
      * @return requestsCount is the numeric total requests created on the smart contract
      * @return approversCount is the numeric total addresses added to approve requests on the smart contract
      * @return owner the address that creates the smart contract and responsible to add approvers
      */    
    function getSummary() public view returns (
      uint, uint, uint, address
      ) {
        return (
          address(this).balance,
          requestsCount,
          approversCount,
          owner
        );
    }

    /** @notice Get the total requests created on the smart contract
      * @dev return the number of the field `requestsCount`
      * @return requestsCount is the numeric total requests created on the smart contract
      */
    function getRequestsCount() public view returns (uint) {
        return requestsCount;
    }
}

/// @author DeTask team
/// @title Use this contract to administrate and access all tasks created in the blockchain
/// @notice Task's owners and affiliates can filter all tasks associated to them 
contract TaskFactory {

    /// @notice This struct contains the information to initiate a task parentTask, payWithToken, affiliate
    struct Setup {
          address parentTask;
          address payWithToken;
          address affiliate;
      }

    ///Address that creates the factory. Only this address can change data in this smart contract
    address private owner;
    ///The address that points to the Treasury Configuration. The configuration has all fees, affiliate, and partner value
    address private treasuryConfig;
    ///The address that points to the main empty task created on the block chain. The empty task will be used to generate a clone and avoid high fees
    address private masterContract;
    ///Array of all tasks deployed on the factory smart contract
    address[] private deployedTasks;
    ///Total number deployed tasks
    uint256 private totalDeployedTasks;
    ///Store all tasks created for an affiliate address
    mapping(address => address[]) private affiliateTasks;
    ///Total number of tasks created to an affiliate
    mapping(address => uint256) private totalAffiliateTasks;
    ///Store all tasks created for a manager address or job creator
    mapping(address => address[]) private managerTasks;
    ///Total number of tasks created to a manager
    mapping(address => uint256) private totalManagerTasks;

    event ChangeOwner(address indexed _old, address indexed _new, uint256 indexed _date);

    /// @notice Only owner who create the task is allowed
    modifier restricted() {
        require(msg.sender == owner, "Only the Owner can change or call the Factory Contract!");
        _;
    }

    /// @notice No zero address allowed
    modifier noZeroAddress(address _newOwner) {
        require(_newOwner != address(0), "Address cannot be zero!");
        _;
    }

    /** @notice task factory initialization
      * @dev Store the data wallet owner that can control and manipulate the factory, the empty task contract that will be cloned, and the treasury config that will load all configuration values
      * @param _masterContract is the empty task config that will be clonned
      * @param _treasuryConfig is the configuration that contains all fess setup
      */
    constructor(address _masterContract, address _treasuryConfig){
        owner = msg.sender;
        masterContract = _masterContract;
        treasuryConfig = _treasuryConfig;
    }

    /** @notice Return the datetime
      * @dev Return the timestamp of the block
      * @return the block time stamp
      */
    function getDateTime() private view returns (uint256){
      return block.timestamp;
    }

    /** @notice Create a new task and add on the factory
      * @dev Clone the master task address `masterContract` from the block chain. Add the new task on the factory array `deployedTasks` and increment the numeric field `totalDeployedTasks`.  Add the new task to the manager array inside the mapping `managerTasks` and increment the mapping numeric field `totalManagerTasks`. If there is a valid affiliated address, add the new task to the array inside the mapping `affiliateTasks` and increment the numeric field `totalAffiliateTasks` . Call the setup method `setTaskConfig` for the new task to store and calculate the fees. Call `init` to initialize the task and transfer the balance to the task.
      * @param _setup initial info parentTask, payWithToken, affiliate, and arbitration
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */
    function createTask(Setup memory _setup, string memory _category, string memory _description, address _developer, uint256 _regularReward, uint16 _regularDueTime, uint16 _speederDueTime, uint8 _dueTimeType, bool _publicDescription, string memory _title) external payable {
        require(masterContract != address(0), "Master contract is not register!");
        address newTask = address(Task(createClone(masterContract)));
        uint256 timeComplete = Task(newTask).getTimeCompleted();
        require(timeComplete == 0, "This address was not cloned from MasterTask");
        setupFactory(msg.sender, _setup.affiliate, newTask);
        Task.Setup memory setupTask = Task.Setup(_setup.parentTask, address(0), _setup.affiliate, msg.sender, treasuryConfig);
        Task(newTask).setTaskConfig(setupTask);
        Task(newTask).init{value: msg.value}(_category, _description, _developer, _regularReward, _regularDueTime, _speederDueTime, msg.sender, _dueTimeType, _publicDescription, _title);
    }

    /** @notice Fill the empty task
      * @dev Add informaction to the new task except money. It should be added on the next step
      * @param _setup initial info parentTask, payWithToken, affiliate, and arbitration
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _speederReward is the amount the specialist will receive if he or she complete the task sooner
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */  
    function createTaskWithUtilToken(Setup memory _setup, string memory _category, string memory _description, address _developer, uint256 _regularReward, uint256 _speederReward, uint16 _regularDueTime, uint16 _speederDueTime, uint8 _dueTimeType, bool _publicDescription, string memory _title) external returns(address) {
        require(masterContract != address(0), "Master contract is not register!");
        require(_setup.payWithToken != address(0), "Payment token cannot be zero!");
        require(ITaskRewardTreasuryConfig(treasuryConfig).isTokenAllowed(_setup.payWithToken), "This token is not allowed as payment!");
        address newTask = address(Task(createClone(masterContract)));
        require(Task(newTask).getTimeCompleted() == 0, "This address was not cloned from MasterTask");
        setupFactory(msg.sender, _setup.affiliate, newTask);
        Task.Setup memory setupTask = Task.Setup(_setup.parentTask, _setup.payWithToken, _setup.affiliate, msg.sender, treasuryConfig);
        Task(newTask).setTaskConfigWithPayment(setupTask);
        Task(newTask).initToken(_category, _description, _developer, _regularReward, _speederReward, _regularDueTime, _speederDueTime, msg.sender, _dueTimeType, _publicDescription, _title);
        return newTask;
    }

    /** @notice Update factory task information
      * @dev Add the new task on the factory array `deployedTasks` and increment the numeric field `totalDeployedTasks`.  Add the new task to the manager array inside the mapping `managerTasks` and increment the mapping numeric field `totalManagerTasks`. If there is a valid affiliated address, add the new task to the array inside the mapping `affiliateTasks` and increment the numeric field `totalAffiliateTasks`. 
      * @param _sender the manager address that creates the task
      * @param _affiliate the affiliate address that may receive a commission when the task is completed
      * @param _newTask task address 
      */
    function setupFactory(address _sender, address _affiliate, address _newTask) private {
        deployedTasks.push(_newTask);
        managerTasks[_sender].push(_newTask);
        totalManagerTasks[_sender] += 1;
        totalDeployedTasks += 1;

        if (_affiliate != address(0))
        {
            affiliateTasks[_affiliate].push(_newTask);
            totalAffiliateTasks[_affiliate] += 1;
        }
    }

    /** @notice Create a clone from an existing address on the block chain. This function reduce the block chain fee in 90% compared to the `create` smart contract function 
      * @dev Search for an existing contract address and make a clone for it. Deploys and returns the address of a clone that mimics the behavior of `implementation`.
      * @param target the address we want to clone from the block chain
      * @return result the new address that was cloned
      */
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
        
    }

    /** @notice Get the list of task address deployed in the factory
      * @dev return the array address of the field `deployedTasks`
      * @return all address save on the array `deployedTasks`
      */
    function getDeployedTasks() external view returns(address[] memory){
        return deployedTasks;
    }

    /** @notice Get the total number of tasks created in the factory 
      * @dev return the number of the field `totalDeployedTasks`
      * @return totalDeployedTasks is the numeric total tasks created on the factory
      */
    function getTotalDeployedTasks() external view returns(uint256){
        return totalDeployedTasks;
    }

    /** @notice Retrieve the task by an specific index 
      * @dev return the address of a task on the array `deployedTasks`
      * @param _index The number that identify a task on the array
      * @return the task address located in the array `deployedTasks`
      */
    function getDeployedTasksByIndex(uint256 _index) external view returns(address){
        return deployedTasks[_index];
    }

    /** @notice Get the total number of tasks by manager wallet address
      * @dev return the number of tasks from mapping `totalManagerTasks`
      * @param _manager is a wallet address to get the total task created for it
      * @return The numeric total tasks by manager
      */
    function getTotalDeployedTasksByManager(address _manager) external view returns(uint){
        return totalManagerTasks[_manager];
    }

    /** @notice Get the list of task addresses by manager
      * @dev return the array of address inside the mapping `managerTasks` by manager wallet address
      * @param _manager is a wallet address to get the associated list of tasks
      * @return The list of task addresses stored by manager
      */
    function getDeployedTasksByManager(address _manager) external view returns(address[] memory){
        return managerTasks[_manager];
    }

    /** @notice Get the total number of tasks by affiliate wallet address
      * @dev return the number of tasks from mapping `totalAffiliateTasks`
      * @param _affiliate is a wallet address to get the total task created for it
      * @return The numeric total tasks by affiliate
      */
    function getTotalDeployedTasksByAffiliate(address _affiliate) external view returns(uint){
        return totalAffiliateTasks[_affiliate];
    }

    /** @notice Get the list of task addresses by affiliate
      * @dev return the array of address inside the mapping `affiliateTasks` by affiliate wallet address
      * @param _affiliate is a wallet address to get the associated list of tasks
      * @return The list of task addresses stored by affiliate
      */
    function getDeployedTasksByAffiliate(address _affiliate) external view returns(address[] memory){
        return affiliateTasks[_affiliate];
    }

    /** @notice Retrieve the task address by manager address and index
      * @dev return a task address from the mapping `managerTasks` by address and array index   
      * @param _manager is a wallet address to get the list of tasks
      * @param _index is the task position inside the array
      * @return A task address
      */
    function getDeployedTaskByManagerAndIndex(address _manager, uint256 _index) external view returns(address){
        return managerTasks[_manager][_index];
    }

    /** @notice Return the address of the task master contract used to create a clone
      * @dev get the task master address contract field `masterContract`
      * @return The task master contract
      */
    function getMasterContract() external view restricted returns(address){
        return masterContract;
    }

    /** @notice Retrieve the current treasury fee
      * @dev return the numerical fee from the Treasury Configuration through the interface `ITaskRewardTreasuryConfig`  
      * @param _partner is the partner wallet address that may have a special fee
      * @return The fee that will be paid by the user
      */
    function getTreasuryFeePercent(address _partner) external view returns(uint256){
        return ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeePercent(_partner, address(0));
    }

    /** @notice Retrieve the treasury commission fee value
      * @dev Return the numerical fee from the Treasury Configuration through the interface `ITaskRewardTreasuryConfig`  
      * @param _value the base amount used to calculate the fee
      * @param _sender is the wallet address that may have a special fee
      @ @param _payWithToken token used on payment
      * @return The fee that will be paid by the user
      */
    function getTreasuryFeeValue(uint256 _value, address _sender, address _payWithToken) external view returns(uint256){
      uint256 tokenFee = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeePercent(_sender, _payWithToken);
      return ITaskRewardTreasuryConfig(treasuryConfig).calcFee(_value, tokenFee);
    }

    /** @notice Return fee value from the utility token
      * @dev Retrieves and calculate the token fee
      * @param _token is the utility token
      * @param _value the amount of the task
      * @return token is enabled
      * @return fee value is the number in amount that a task should pay when use the token 
      */
    function getTokenFeeValue(address _token, uint256 _value) external view returns (bool, uint256) {
      (bool enabled, uint256 tokenFee) = ITaskRewardTreasuryConfig(treasuryConfig).getTokenAllowance(_token);
      return 
      (
        enabled,
        ITaskRewardTreasuryConfig(treasuryConfig).calcFee(_value, tokenFee)
      );
    }

    /** @notice Return the address of the owner that creates the factory
      * @dev get the owner address that create the contract field `owner`
      * @return The address of factory the contract owner
      */
    function getOwner() external view returns(address){
        return owner;
    }

    /** @notice Return the address of the treasury configuration that has the tasks fees, affiliate commission, and partner fee discount
      * @dev get the treasury address that calculates the task fees field `treasuryConfig`
      * @return The address of the treasury configuration
      */
    function getTreasuryConfig() external view restricted returns(address){
        return treasuryConfig;
    }

    /** @notice Update the master contract task address with a new address
      * @dev Update the master contract task address in the field `masterContract`. Test if the new address is a valid empty task contract
      * @param _newMasterContract is the address of an empty task publicated on the block chain 
      */
    function setMasterContract(address _newMasterContract) external restricted {
      uint256 timeComplete = Task(_newMasterContract).getTimeCompleted();
      require(timeComplete == 0, "The new address is not Task contract");
      masterContract = _newMasterContract;
    }

    /** @notice Change the factory owner address to a new owner
      * @dev Update the owner address
      * @param _newOwner is the address of the new owner
      */
    function setNewOwner(address _newOwner) external restricted noZeroAddress(_newOwner) {
        emit ChangeOwner(msg.sender, _newOwner, getDateTime());
        owner = _newOwner;
    }

    /** @notice Update the treasury address with a new address
      * @dev Update the treasury address in the field `treasuryConfig`
      * @param _newTreasuryConfig is the address of a new treasure configuration that has the tasks fees, affiliate commission, and partner fee discount
      */
    function setTreasuryConfig(address _newTreasuryConfig) external restricted {
        treasuryConfig = _newTreasuryConfig;
    }

    /** @notice Return balance of the Factory 
      * @dev get the actual balance of the Factory. This balance should be always zero because the factory transfer all received balance to the task during the create method
      * @return balance of the Factory
      */
    function getBalance() external view returns(uint){
        return address(this).balance;
    }

}

/// @author DeTask team
/// @title Contract used to store information such as payment, due date, and job description that was negotiated between a manager and a specialist 
contract Task {

    /// @notice This struct contains the information to initiate a task parentTask, payWithToken, affiliate, manager, treasury, arbitration
    struct Setup {
          address parentTask;
          address payWithToken;
          address affiliate;
          address manager;
          address treasury;
      }

    /// Status type
    uint8 private constant STATUS_CREATED = 0;
    uint8 private constant STATUS_STARTED = 1;
    uint8 private constant STATUS_COMPLETED = 2;
    uint8 private constant STATUS_APPROVED = 3;
    uint8 private constant STATUS_CANCELED = 4;
    uint8 private constant STATUS_CANCEL_ARBITRATE = 5;
    /// Time calculation type (Days or Hours)
    uint8 private constant TASK_BY_HOUR = 0;
    uint8 private constant TASK_BY_DAY = 1;

    //Task’s owner wallet address
    address private manager;
    ///Specialist’s wallet address who will execute the task 
    address private developer;
    ///Descriptive info about what should be execute in the task
    string private title;
    string private category;
    ///If false, the description will be visible only to the manager and specialist
    bool private publicDescription;
    string private description;
    ///Amount of money the manager should pay to the specialist when complete the task prior the express time
    uint256 private speederReward;
    ///Amount to be paid if the express time expire
    uint256 private regularReward;
    ///Total amount already anticipated to the specialist
    uint256 private anticipatedReward;
    ///Current status of the task
    uint8 private status;
    ///Regular time to complete the task
    uint16 private regularDueTime;
    ///Express time to complete the task get the extra reward
    uint16 private speederDueTime;
    ///Type of due time for the task (Hour or Days)
    uint8 private dueTimeType;
    ///Dates to control the task
    uint256 private startDate;
    uint256 private endDate;
    ///Rate the task's completion job. Number from 1 to 5
    uint8 private developerRate;
    uint8 private managerRate;
    ///Treasury info
    address private treasuryAddress;
    uint256 private treasuryFee;
    uint256 private treasuryFeeValue;
    ///Treasury Config
    address private treasuryConfig;
    ///Task relation
    address private parentTask;
    ///Task Affiliate info 
    address private affiliateAddress;
    uint256 private affiliateCommission;
    uint256 private affiliateCommissionValue;
    ///Task partner info 
    address private partnerAddress;
    //Enable contract arbitration option
    bool private arbitration;
    //Developer agreement to arbitrate
    bool private arbitrationAgreed;
    //Undo status prior the arbitration
    uint8 private statusPriorArbitrate;
    //Use different token for payment
    address private payWithToken;
    //Charge fee even if the task is canceled
    bool private chargeFeeOnCancelation;
    ///Total number of tasks created to an affiliate
    mapping(address => bool) private approvers;

    //********** TASK LOG EVENTS **********
    //This generates a public event on the blockchain on task update
    event DeveloperChanged(address indexed _old, address indexed _new, uint256 indexed _date);
    event RewardAdded(address _from, uint256 indexed _reward, string _reason, uint256 indexed _date);
    event DueTimeChanged(uint16 indexed _old, uint16 indexed _new, uint256 indexed _date);
    event RateAdded(address indexed _from, uint8 indexed _rate, string _reason, uint256 indexed _date);
    event ParentTaskChanged(address indexed _manager, address indexed _old, address _new, uint256 indexed _date);
    event PublicDescriptionChanged(address indexed _manager, bool indexed _public, uint256 indexed _date);
    event DescriptionChanged(address _manager, string  _reason, uint256 indexed _date);
    event CategoryChanged(address _manager, string _old, string _new, uint256 indexed _date);
    event TitleChanged(address _manager, string _old, string _new, uint256 indexed _date);
    event ArbitrationChanged(address _manager, bool _enable, uint256 indexed _date);
    event ArbitrationAgreed(address _developer, bool _agree, uint256 indexed _date);
    //This generates a public event on the blockchain for task status
    event Created(address indexed _manager, uint256 indexed _date);
    event Started(address indexed _manager, uint256 indexed _date);
    event Completed(address indexed _developer, string _notes, uint256 indexed _date);
    event UndoCompleted(address indexed _sender, address indexed _developer, string _reason, uint256 indexed _date);
    event Approved(address indexed _manager, address indexed _developer, uint256 _reward, uint256 indexed _date);
    event Canceled(address indexed _manager, address indexed _developer, string _reason, uint256 _refund, uint256 indexed _date);
    event Arbitrate(address indexed _arbitrate, string _reason, bool _approve, uint256 indexed _date);
    event RequestArbitration(address indexed _manager, string _reason, uint256 indexed _date);
    event AnticipatedReward(address indexed _developer, uint256 _value, string _reason, uint256 indexed _date);
    event SetApprovers(address indexed _approver, bool _allow, uint256 indexed _date);
    //Treasury Events
    event PaidCommission(address indexed _address, uint256 _treasuryFee, uint256 _treasureValue, uint256 _affiliateFee, uint256 _affiliateValue, uint256 indexed _date);

    //********** RULES TO CHANGE THE TASK **********
    /// @notice Only owner who create the task is allowed
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can change the task!");
        _;
    }

    /// @notice Only owner who create the task and approvers is allowed
    modifier restrictedAndApprovers() {
        require(msg.sender == manager || approvers[msg.sender], "Only the manager and approvers can approve the task!");
        _;
    }

    /// @notice The task status was not started yet
    modifier notStarted() {
        require(status == STATUS_CREATED, "This task was already started and can not be updated!");
        _;
    }

    /// @notice The task is with the start status
    modifier isStarted() {
        require(status == STATUS_STARTED, "This task is not started!");
        _;
    }

    /// @notice The task is with the complete status
    modifier isCompleted() {
        require(status == STATUS_COMPLETED, "This task is not completed!");
        _;
    }

    /// @notice The task is with the approved status
    modifier isApproved() {
        require(status != STATUS_APPROVED, "This task is already approved!");
        _;
    }

    /// @notice The task is with the approved or canceled status
    modifier isApprovedOrCanceled() {
        require((status == STATUS_APPROVED) || (status == STATUS_CANCELED), "This task is not approved or canceled!");
        _;
    }

    /// @notice The task is not with the approved or canceled status
    modifier isNotApprovedAndCanceled() {
        require((status != STATUS_APPROVED) && (status != STATUS_CANCELED), "This task is already approved or canceled!");
        _;
    }

    /// @notice Only developer address is allowed
    modifier validateDeveloper() {
        require(developer == msg.sender, "You are not the developer for this task!");
        _;
    }

    /// @notice No zero address set to developer
    modifier noDeveloperZeroAddress() {
        require(developer != address(0), "There is not developer for this task!");
        _;
    }

    /// @notice The task has money deposited on it
    modifier hasReward(){
        require(getTaskBalance() > 0, "There is not reward balance for this contract!");
        _;
    }

    /// @notice The task is marked to user arbitration
    modifier isArbitrated() {
        require(arbitration, "This task is not arbitrated!");
        _;
    }

    /// @notice The arbitration was approved by the manager and developer
    modifier arbitrationApproved() {
        require((arbitration == false) || ((arbitration) && (arbitrationAgreed)), "Task needs to approve arbitration!");
        _;
    }

    /// @notice Check if wallet address can arbitrate
    modifier canArbitrate() {
        bool canAribitrate = ITaskRewardTreasuryConfig(treasuryConfig).canArbitrate(msg.sender);
        require((status == STATUS_CANCEL_ARBITRATE) && canAribitrate, "This task is not arbitrated or address does not have permission to arbitrate!");
        _;
    }

    //********** FUNCTIONS FOR TREASURY **********
    /** @notice Calculate if the task has a fee
      * @dev Verify if the task has fee to avoid error during the payment
      * @return True if the task has any fee
      */    
    function shouldTakeFee() private view returns(bool){
        return ((treasuryAddress != address(0)) && (treasuryFeeValue > 0));
    }

    /** @notice Calculate the affiliate commissions 
      * @dev Check if the affiliate has commission `affiliateCommission`. The affiliate commision will be calculated after deducted from the treasure fee. 
      */    
    function calcAffiliateCommission() private returns(uint256) {

      uint256 affiliateValue = 0;

      if (affiliateAddress != address(0) && affiliateCommission > 0)
      {
        if (affiliateCommissionValue == 0)
          affiliateCommissionValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(treasuryFeeValue, affiliateCommission);
          affiliateValue = affiliateCommissionValue;
      } 

      return affiliateValue;
    }

    /** @notice Transfer the fee from the task to the affiliate and treasury
      * @dev Verify if there is a fee to charge using the function `shouldTakeFee`. The treasure fee `treasuryFeeValue` will be calculated and transferred deducting the `affiliateCommission`. Transfer the affiliate commission value.
      */    
    function transferTreasuryFee() private {
        //Transfer fee to treasury
        bool resultDiff = false;
        uint256 diffSub = 0;
        uint256 affiliateValue = 0;

        if (shouldTakeFee()){

            affiliateValue = calcAffiliateCommission();

            emit PaidCommission(treasuryAddress, treasuryFee, treasuryFeeValue, affiliateCommission, affiliateValue, getDateTime());

            (resultDiff, diffSub) = SafeMath.trySub(treasuryFeeValue, affiliateValue);

            //Transfer the treasury fee
            if (payWithToken == address(0)){
              resultDiff ? payable(treasuryAddress).transfer(diffSub) : revert("Integer payWithToken resultDiff Overflow/Underflow");
            }
            else {
              if (resultDiff)
              {
                ERC20(address(payWithToken)).transfer(treasuryAddress, diffSub);
              }
              else
              {
                revert("Integer resultDiff Overflow/Underflow");
              }
            }

            //Transfer the affiliate commission
            if (affiliateValue > 0){
              if (payWithToken == address(0)){
                  payable(affiliateAddress).transfer(affiliateValue);
              }
              else {
                  ERC20(address(payWithToken)).transfer(affiliateAddress, affiliateValue);
              }
            }
        }
    }

    //********** FUNCTIONS TO UPDATE TASK **********
    function initializeTaskConfig(address _treasuryAddress, address _managerAddress, address _affiliateAddress, address _parentTask, address _payWithToken) private {
        require(treasuryConfig == address(0), "Treasury config already setup!");
        require(manager == address(0), "Manager in the task already setup!");
        treasuryConfig = _treasuryAddress;
        manager = _managerAddress;
        parentTask = _parentTask;
        arbitration = ITaskRewardTreasuryConfig(treasuryConfig).getManagerTaskArbitration(_managerAddress);
        treasuryAddress = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryAddress();
        treasuryFee = ITaskRewardTreasuryConfig(treasuryConfig).getTreasuryFeePercent(_managerAddress, _payWithToken);
        affiliateAddress = _affiliateAddress;
        affiliateCommission = ITaskRewardTreasuryConfig(treasuryConfig).getAffiliateCommision(_affiliateAddress);
        chargeFeeOnCancelation = ITaskRewardTreasuryConfig(treasuryConfig).chargeCancelationFee(_managerAddress);
        getPartnerApprovers();
    }

    /** @notice call the Treasury configuration to return all approvers from the manager 
      * @dev set the approve to the mapping `approvers`
      */
    function getPartnerApprovers() private {
      address[] memory approversList = ITaskRewardTreasuryConfig(treasuryConfig).getPartnerTaskApprovers(manager);
      for (uint i=0; i < approversList.length; i++)
      {
        approvers[approversList[i]] = true;
      }
    }

    /** @notice Set address that can approve or disapprove the task when it is delivered by the dev
      * @dev set the approve to the mapping `approvers`
      * @param _approver address that can approve or disapprove the task
      * @param _allow permission to approve the task
      */
    function setApprovers(address _approver, bool _allow) restricted isNotApprovedAndCanceled external {
        emit SetApprovers(_approver, _allow, getDateTime());
        approvers[_approver] = _allow;
    }

    /** @notice Load and save all the fees and addresses from the configuration smart contract. It is executed as soon as the contract is created
      * @dev Store the data treasury config address at `treasuryConfig`, task owner address at `manager`, treasury address at `treasuryAddress`, task fee at `treasuryFee`, affiliated address and commission at `affiliateAddress` and `affiliateCommission`
      * @param setup has treasury: the DAO address where the fees will be deposited; manager: the owner of the task. Only owner can manipulate the task after creation; affiliate: the wallet address that will receive a commission over the task fee if the address is setup on the config file; parentTask associated with a parent task;
      */
    function setTaskConfig(Setup memory setup) external {
        initializeTaskConfig(setup.treasury, setup.manager, setup.affiliate, setup.parentTask, address(0));
    }

    /** @notice Load and save all the fees and addresses from the configuration smart contract. It is executed as soon as the contract is created and setup the new payment
      * @dev call the method `initializeTaskConfig` and load the payment token info from the configuration file
      * @param setup initial parameter to setup the task
      */
    function setTaskConfigWithPayment(Setup memory setup) external {
        initializeTaskConfig(setup.treasury, setup.manager, setup.affiliate, setup.parentTask, setup.payWithToken);
        bool enabled = ITaskRewardTreasuryConfig(treasuryConfig).isTokenAllowed(setup.payWithToken);
        require(enabled, "Payment token not valid!");
        payWithToken = setup.payWithToken;
    }

    /** @notice Set the public description visibility. If the flag is false, only the task’s owner and specialist can see the description
      * @dev Update the public description field `publicDescription`
      * @param _publicDescription boolean to set the description public
      */
    function setPublicDescription(bool _publicDescription) external restricted {
        emit PublicDescriptionChanged(msg.sender, _publicDescription, getDateTime());
        publicDescription = _publicDescription;
    }

    /** @notice Replace the task‘s description
      * @dev Set the new value to the field `description`. This field can only be changed if the task is not started
      * @param _description is the new description
      * @param _reason is a text info explaining why the owner needs to change the description
      */
    function setDescription(string memory _description, string memory _reason) external restricted notStarted{
        emit DescriptionChanged(msg.sender, _reason, getDateTime());
        description = _description;
    }

    /** @notice Replace the task‘s category
      * @dev Set the new value to the field `category`. This field can only be changed if the task is not started
      * @param _category is the new task's category
      */
    function setCategory(string memory _category) external restricted notStarted{
        emit CategoryChanged(msg.sender, category, _category, getDateTime());
        category = _category;
    }

    /** @notice Replace the task‘s title
      * @dev Set the new value to the field `title`. This field can only be changed if the task is not started
      * @param _title is the new task's title
      */
    function setTitle(string memory _title) external restricted notStarted{
        emit TitleChanged(msg.sender, title, _title, getDateTime());
        title = _title;
    }

    /** @notice Update the task‘s arbitration
      * @dev Set the new value to the field `arbitration`. This field can only be changed if the task is not started
      * @param _enable true or false to enable task arbitration
      */
    function createArbitration(bool _enable) external restricted notStarted{
        emit ArbitrationChanged(msg.sender, _enable, getDateTime());
        arbitration = _enable;
    }

    /** @notice Confirme the task‘s arbitration
      * @dev Developer set the new value to the field `arbitrationAgreed`. This field can only be changed if the task is not started
      * @param _agree true or false to confirm task arbitration
      */
    function agreeArbitration(bool _agree) external noDeveloperZeroAddress validateDeveloper notStarted isArbitrated{
        emit ArbitrationAgreed(msg.sender, _agree, getDateTime());
        arbitrationAgreed = _agree;
    }

    /** @notice Replace the specialist wallet address
      * @dev Set the new value to the field `title`. This field can only be changed if the task is not started
      * @param _developer si the new developer wallet address
      */
    function setDeveloper(address _developer) external restricted notStarted{
        emit DeveloperChanged(developer, _developer, getDateTime());
        developer = _developer;
    }

    /** @notice This function creates a relationship with an existing task
      * @dev Set the new value for the field `parentTask`
      * @param _parentTask is the task's address you need to associate the current task
      */
    function setParentTask(address _parentTask) external restricted {
        emit ParentTaskChanged(msg.sender, parentTask, _parentTask, getDateTime());
        parentTask = _parentTask;
    }

    /** @notice Update the due time the specialist has to complete the task
      * @dev The due time cannot be greater than speeder time. It will set a new value for the variable `regularDueTime`. This field can only be changed if the task is not started
      * @param _regularDueTime the new int value for the field `regularDueTime`
      */
    function setRegurarDueTime(uint16 _regularDueTime) external restricted notStarted{
        require(_regularDueTime > 0, "Regurar Due Day must be greater than zero!");
        require(_regularDueTime >= speederDueTime, "Regurar Due Time cannot be less then Speeder Due Day!");
        emit DueTimeChanged(regularDueTime, _regularDueTime, getDateTime());
        regularDueTime = _regularDueTime;
    }

    /** @notice Update the due time the specialist has to complete the task faster
      * @dev The faster due time must be greater than regular time. It will set a new value for the variable `speederDueTime`. This field can only be changed if the task is not started
      * @param _speederDueTime the new int value for the field `speederDueTime`
      */
    function setSpeederDueTime(uint16 _speederDueTime) external restricted notStarted{
        require(regularDueTime >= _speederDueTime, "Speeder Due Time cannot be greater than Regular Due Day!");
        require(_speederDueTime > 0, "Speeder Due Day must be greater than zero!");
        emit DueTimeChanged(speederDueTime, _speederDueTime, getDateTime());
        speederDueTime = _speederDueTime;
    }

    /** @notice This function will add more money to the task
      * @dev Validate if the parameter `_regularRewardIncrement` is less than the amount received. Add the `regularReward` with the parameter `_regularRewardIncrement`. Increment the task’s balance with the amount received. Add the amount received to the variable `speederReward`. This function can only run if the task is not started
      * @param _regularRewardIncrement the amount to be added to the current field `regularReward`
      */
    function addReward(uint256 _regularRewardIncrement, string memory _reason) external payable restricted isNotApprovedAndCanceled {
        require(_regularRewardIncrement <= msg.value, "Regular reward can not be greater than speeder reward!");
        require(payWithToken == address(0), "Task initialized with other token!");
        emit RewardAdded(manager, msg.value, _reason, getDateTime());
        regularReward += _regularRewardIncrement;
        speederReward += msg.value;
    }

    /** @notice This function will add more money to the task
      * @dev Validate if the parameter `_regularRewardIncrement` is less than the amount of `_speerderRewardIncrement`. Add the `regularReward` with the parameter `_regularRewardIncrement`. Increment the task’s balance with the amount received. Add the speeder amount received to the variable `speederReward`. This function can only run if the task is not started
      * @param _regularRewardIncrement the amount to be added to the current field `regularReward`
      * @param _speerderRewardIncrement the amount to be added to the current field `speederReward`
      */
    function addRewardToken(uint256 _regularRewardIncrement, uint256 _speerderRewardIncrement, string memory _reason) external restricted isNotApprovedAndCanceled {
        require(_regularRewardIncrement <= _speerderRewardIncrement, "Regular reward can not be greater than speeder reward!");
        uint256 taskBal = getTaskBalance();
        require(taskBal == 0, "Balance already deposited to this contract!");
        require(payWithToken != address(0), "Task initialized with main token");
        emit RewardAdded(manager, _speerderRewardIncrement, _reason, getDateTime());
        regularReward += _regularRewardIncrement;
        speederReward += _speerderRewardIncrement;
    }

    /** @notice Only the owner can give a score from 1 to 5 to the specialist, and also a reason for the rate.
      * @dev Rate should be from 1 to 5. The rate value will be stored in the variable `developerRate`. A log will be created in the task  with the parameter `_reason`. This function can only be called when the contract is approved or canceled.
      * @param _rate is the integer score from 1 to 5
      * @param _reason is the description that justify the rate
      */
    function rateDeveloper(uint8 _rate, string memory _reason) external restricted isApprovedOrCanceled{
        require((_rate >= 0) && (_rate <= 500), "Rate should be between 1 to 500!");
        require(developerRate == 0, "Developer has a rate already!");
        developerRate = _rate;
        emit RateAdded(manager, _rate, _reason, getDateTime());
    }

    /** @notice Only the specialist can give a score from 1 to 5 to the owner, and also a reason for the rate. 
      * @dev Rate should be from 1 to 5. The rate value will be stored in the variable `developerRate`. A log will be created in the task  with the parameter `_reason`. This function can only be called when the contract is approved or canceled.
      * @param _rate is the integer score from 1 to 5
      * @param _reason is the description that justify the rate
      */
    function rateManager(uint8 _rate, string memory _reason) external noDeveloperZeroAddress validateDeveloper isApprovedOrCanceled{
        require((_rate >= 0) && (_rate <= 500), "Rate should be between 1 to 500!");
        require(managerRate == 0, "Manager has a rate already!");
        managerRate = _rate;
        emit RateAdded(developer, _rate, _reason, getDateTime());
    }

    //********** FUNCTIONS TO CREATE ACTIONS ON TASK **********
    /** @notice Transfer partial money from the task to the specialist wallet
      * @dev Anticipation cannot be greater than regular reward. The specialist address must be filled. Transfer the amount informed in the variable `_value` from the task to the specialist wallet, and increase the amount transferred to the variable `anticipatedReward`
      * @param _value is the amount that should be transferred from the task
      * @param _reason is the justification for transferring the amount from the task
      */
    function anticipateReward(uint256 _value, string memory _reason) external restricted noDeveloperZeroAddress hasReward {
        require(_value < (regularReward - anticipatedReward), "Antecipation cannot be greater or equal regular reward!");

        anticipatedReward += _value;
        emit AnticipatedReward(developer, _value, _reason, getDateTime());

       if (payWithToken == address(0)){
            payable(developer).transfer(_value);
        }
        else {
            ERC20(address(payWithToken)).transfer(developer, _value);
        }

    }

    /** @notice Initiate the job and the clock to complete the task
      * @dev Update the task’s variable status `status` to start. Set the date and time `startDate` of the task to started. The task can only be stated once and there must be a specialist wallet address setup. Only the owner can start the task
      */
    function start() external notStarted restrictedAndApprovers hasReward arbitrationApproved noDeveloperZeroAddress{
        status = STATUS_STARTED;
        startDate = getDateTime();
        emit Started(msg.sender, startDate);
    }

    /** @notice Update the task status from started to completed
      * @dev Update the task’s variable status `status` to completion. Set the date and time `endDate` the task completed. Only the specialist can set the task as completed
      * @param _notes any observation about the delivery
      */
    function complete(string memory _notes) external isStarted noDeveloperZeroAddress validateDeveloper{
        status = STATUS_COMPLETED;
        endDate = getDateTime();
        emit Completed(developer, _notes, endDate);
    }

    /** @notice This function invalidate the specialist job task completion
      * @dev Update the task’s variable status `status` to start again. Reset the date and time `endDate` to zero. Log the specification from the parameter `_reason` explaining why the task was not approved. Only the owner can reset this function 
      * @param _reason explanation of why the task was not approved
      */
    function undoComplete(string memory _reason) external restrictedAndApprovers isCompleted{
        status = STATUS_STARTED;
        endDate = 0;
        emit UndoCompleted(msg.sender, developer, _reason, getDateTime());
    }

    /** @notice Cancelation of the task validating
      * @dev Update the task’s variable status `status` to cancel or wait for arbitrage. If canceled, all the money saved on the task will be transferred back to the  owner's wallet and a treasury fee can be charged. Only the owner can cancel the task. Log the description from the parameter `_reason` explaining why the task was canceled. There is no undo after cancelation
      */
    function executeCancelation() private {

        status = STATUS_CANCELED;

        uint256 amountCanceled = getTaskBalance();

        if (chargeFeeOnCancelation){
          bool workedDiff = false;
          (workedDiff, amountCanceled) = SafeMath.trySub(amountCanceled, treasuryFeeValue);
          if (workedDiff == false)
            revert("Integer workedDiff Overflow/Underflow");
        }

        if (payWithToken == address(0)){
            payable(manager).transfer(amountCanceled);
        }
        else {
            ERC20(address(payWithToken)).transfer(manager, amountCanceled);
        }

        if (chargeFeeOnCancelation)
          transferTreasuryFee();

    }

    /** @notice Cancelation of the task
      * @dev Update the task’s variable status `status` to cancel or wait for arbitrage. If canceled, call the function `executeCancelation`
      * @param _reason explanation of why the task was canceled
      */
    function cancel(string memory _reason) external restricted isApproved{
        if (arbitration && (status != STATUS_CREATED)) {
          if (status != STATUS_CANCEL_ARBITRATE){
            statusPriorArbitrate = status;
          }
          status = STATUS_CANCEL_ARBITRATE;
          emit RequestArbitration(manager, _reason, getDateTime());
        }
        else{
          emit Canceled(manager, developer, _reason, getTaskBalance(), getDateTime());
          executeCancelation();
        }
    }

    /** @notice DeTask team approve arbitration
      * @dev Update the task’s variable status `status` to the previews status if not approved. If approved, all the money on the task will be transferred back to the manager's wallet. Only the auth wallet can arbitrage the task. Log the description from the parameter `_reason` explaining the reason.
      * @param _reason explanation of why the task was arbitrated
      * @param _approve true or false about the arbitration
      */
    function arbitrate(string memory _reason, bool _approve) external canArbitrate{
      emit Arbitrate(msg.sender, _reason, _approve, getDateTime());
      if (_approve == false) {
        status = statusPriorArbitrate;
      }
      else{
        executeCancelation();
      }
    }

    /** @notice Approve the specialist job
      * @dev Update the task’s variable status `status` to approval. Calculate and transfer the DeTask fee using the function `transferTreasuryFee`. Calculate the task completion time using the function `getTimeCompleted`. Transfer all task’s money to the specialist if the completion time `completedTime` was prior to the speeder time `speederDueTime`. If the completion time was after the speeder time, the task will transfer the regular reward `regularReward` minus the anticipated money `anticipatedReward` to the specialist and transfer the left over balance back to the owner wallet address. Any smart contract that uses transfer() or send() is taking a hard dependency on gas costs by forwarding a fixed amount of gas: 2300.
      */
    function approve() external restrictedAndApprovers isCompleted hasReward noDeveloperZeroAddress{
        uint16 completedTime = getTimeCompleted();
        uint256 amountTransferToDev = 0;
        uint256 amountTransferBack = 0;
        bool workedRegular = false;
        bool workedTransfDev = false;
        bool workedTaskBanlance = false;
        bool workedERC20 = false;
        
        status = STATUS_APPROVED;

        //Verify if the contract was created with the main coin or secondary token        
        //Rule 1: Delivery day =< speederDueDay: Transfer full amount to the developer
        //Rule 2: Delivery day > speederDueDay: Transfer regularReward to the developer, the rest send back to the manager 
        if (completedTime <= speederDueTime)
            amountTransferToDev = getTaskBalance();
        else
        {
          (workedRegular, amountTransferToDev) = SafeMath.trySub(regularReward, anticipatedReward);
          if (workedRegular == false)
            revert("Integer workedRegular Overflow/Underflow");
        }

        if (shouldTakeFee()){
          (workedTransfDev, amountTransferToDev) = SafeMath.trySub(amountTransferToDev, treasuryFeeValue);
          if (workedTransfDev == false)
            revert("Integer workedTransfDev Overflow/Underflow");
        }

        emit Approved(msg.sender, developer, amountTransferToDev, getDateTime());

        if (completedTime <= speederDueTime){

            if (payWithToken == address(0)){
                payable(developer).transfer(amountTransferToDev);
            }
            else {
                ERC20(address(payWithToken)).transfer(developer, amountTransferToDev);
            }

        } else {

            if (payWithToken == address(0)){
                payable(developer).transfer(amountTransferToDev);

                //Remove DeTask commission from balance left
                if (shouldTakeFee()){
                  (workedTaskBanlance, amountTransferBack) = SafeMath.trySub(getTaskBalance(), treasuryFeeValue);
                  if (workedTaskBanlance == false)
                    revert("Integer workedTaskBanlance Overflow/Underflow");
                }

                payable(manager).transfer(amountTransferBack);
            }
            else {
              
                ERC20(address(payWithToken)).transfer(developer, amountTransferToDev);

                //Remove DeTask commission from balance left
                if (shouldTakeFee()){
                  (workedERC20, amountTransferBack) = SafeMath.trySub(getTaskBalance(), treasuryFeeValue);
                  if (workedERC20 == false)
                    revert("Integer workedERC20 Overflow/Underflow");
                }

                ERC20(address(payWithToken)).transfer(manager, amountTransferBack);
            }
        }

      //Transfer fee to treasury after transfer all payments
      transferTreasuryFee();

    }

    //********** FUNCTIONS TO RETRIEVE DATA FROM TASK **********
    /** @notice Return the task's description
      * @dev Validate if the description is public by checking the field `publicDescription`. If it is not public, only the owner or specialist will get the description
      * @return The task description
      */
    function returnDescription() private view returns(string memory){
        string memory _description = "";
        if ((publicDescription) || ((publicDescription == false) && (msg.sender == manager || msg.sender == developer))) {
            _description = description;
        }

        return _description;
    }

    /** @notice Calculate the completion time of the task
      * @dev Check to see if the completion date is filled. Verify if the task was set up per date or hour by variable `dueTimeType`. Calculate the difference of the dates
      * @return the difference between the start and completion date
      */
    function getTimeCompleted() public view returns(uint16){
        uint256 divFinal = 0;
        uint256 diffDate = 0;
        bool workedDiffDate;
        bool workedDiff;

        if (endDate > 0)
        {
            if (dueTimeType == TASK_BY_HOUR){
             (workedDiffDate, diffDate) = SafeMath.trySub(endDate, startDate);
             (workedDiff, divFinal) = SafeMath.tryDiv(diffDate, 3600);
            } 
            else
            {
             (workedDiffDate, diffDate) = SafeMath.trySub(endDate, startDate);
             (workedDiff, divFinal) = SafeMath.tryDiv(diffDate, 86400);
            }
        }

        return uint16(workedDiffDate && workedDiff ? divFinal : 0);
    }
    
    /** @notice Return the true if the address can approve this task
      * @dev call the method mapping `approvers`
      * @return boolean with the address approve status
      */
    function isApprover(address _approver) restrictedAndApprovers external view returns(bool){
        return approvers[_approver];
    }

    /** @notice Return the task's description
      * @dev call the method `returnDescription()`
      * @return The task description
      */
    function getDescription() external view returns(string memory){
        return returnDescription();
    }

    /** @notice Return the task's balance based on the payment token
      * @dev Check if the task has a specific payment 
      * @return The task current balance
      */
    function getTaskBalance() private view returns(uint256){
        if (payWithToken == address(0))
        {
            return address(this).balance;
        }
        else
        {
            return ERC20(address(payWithToken)).balanceOf(address(this));
        }
    }

   /** @notice Return the task's token symbol
     * @dev Check if the task was paid with the main net or specific payment token 
     * @return The task payment token symbol
     */
    function getTokenSymbol() private view returns(string memory){
       if (payWithToken == address(0)){
          return "MainNet";
        }
        else {
          return ERC20(address(payWithToken)).symbol();
        }
    }    

    /** @notice Return the task’s main fields
      * @dev Get the task basic information
      * @return category is the task's tags
      * @return title is the task's title
      * @return manager is the address wallet's owner who create the task 
      * @return developer is the specialist who will delivery the task
      * @return regularReward is the amount the specialist will receive when complete the task
      * @return speederReward is the amount the specialist will receive if he or she complete the task sooner
      * @return balance the current money stored on the task 
      * @return regularDueTime the time the task should be completed
      * @return speederDueTime the speeder time the task should be completed
      * @return status the current status of the task
      * @return startDate is the date and time the task was started
      * @return endDate is the date and time the task was completed
      */
    function getSummary() external view returns(string memory, string memory, address, address, uint256, uint256, uint256, uint16, uint16, uint8, uint256, uint256){

        return (
            category,
            title,
            manager,
            developer,
            regularReward,
            speederReward,
            getTaskBalance(),
            regularDueTime,
            speederDueTime,
            status,
            startDate,
            endDate
        );
    }

    /** @notice Return the task’s fees values
      * @dev Get the information related to task’s
      * @return treasuryAddress is the DAO address of the treasury that will receive the fee
      * @return treasuryFee is the percentage the task will pay to the treasury
      * @return treasuryFeeValue is the amount the treasury will receive when complete the task 
      * @return affiliateAddress wallet address of the affiliate
      * @return affiliateCommission the percentage commission that affiliate will receive
      * @return the calculate commission fee the affiliate will receive
      * @return developerRate the rate score the owner of the task give to the specialist
      * @return managerRate the rate score the specialist of the task give to the owner
      * @return anticipatedReward is the amount of money the owner of the task anticipate to the specialist 
      * @return dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @return timeCompleted the calculated time to complete the task
      * returnDescription() Validate if the description is public by checking the field `publicDescription`. If it is not public, only the owner or specialist will get the description
      */
    function getSummary2() external view returns(address, uint256, uint256, address, uint256, uint256, uint8, uint8, uint256, uint8, uint16, string memory){

        uint16 timeCompleted = getTimeCompleted();

        return(
            treasuryAddress,
            treasuryFee,
            treasuryFeeValue,
            affiliateAddress,
            affiliateCommission,
            affiliateCommissionValue,
            developerRate,
            managerRate,
            anticipatedReward,
            dueTimeType,
            timeCompleted,
            returnDescription()
        );
    }

    /** @notice Return the task’s fees values
      * @dev Get the information related to task’s
      * @return treasuryAddress is the DAO address of the treasury that will receive the fee
      * @return treasuryFee is the percentage the task will pay to the treasury
      * @return ParentTask is the address of an associated task
      * @return payWithToken is the token used to receive the task payment
      * @return getTokenSymbol is the token symbol used to pay the task
      @ @return chargeFeeOnCancelation is the boolean that activate the charge on cancelation fee
      */
    function getSummary3() external view returns(bool, bool, address, address, string memory, bool){

        return(
            arbitration,
            arbitrationAgreed,
            parentTask,
            payWithToken,
            getTokenSymbol(),
            chargeFeeOnCancelation
        );
    }

    /** @notice Return the datetime
      * @dev Return the timestamp of the block
      * @return the block time stamp
      */
    function getDateTime() private view returns (uint256){
      return block.timestamp;
    }

    /** @notice Enter the basic information on the task and receive the task’s money from the owner’s wallet
      * @dev Fill the information from the task by parameters and calculate the treasury fee by calling the function `calculateFee`. The payment received from owners wallet is collected from this method and saved on the task and in the field `speederReward`
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _sender the contract manager
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */
    function init(string memory _category, string memory _description, address _developer, uint256 _regularReward, uint16 _regularDueTime, uint16 _speederDueTime, address _sender, uint8 _dueTimeType, bool _publicDescription, string memory _title) external payable {
        require(_regularReward <= msg.value, "Regular reward can not be greater than speeder reward pluss fee!");
        require(manager == _sender, "This is not the manager for this task!");
        require(regularReward == 0, "This task was already initialized!");
        require(payWithToken == address(0), "Task initialized with other payment token");
        bool workedDiff;
        uint256 taskValue = msg.value;
        description = _description;
        category = _category;
        developer = _developer;
        regularReward = _regularReward;
        treasuryFeeValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(_regularReward, treasuryFee);
        (workedDiff, speederReward) = SafeMath.trySub(taskValue, treasuryFeeValue);
        if (workedDiff == false)
          revert("Integer Overflow/Underflow");
        regularDueTime = _regularDueTime;
        speederDueTime = _speederDueTime;
        status = STATUS_CREATED;
        publicDescription = _publicDescription;
        dueTimeType = _dueTimeType;
        title = _title;
        affiliateCommissionValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(treasuryFeeValue, affiliateCommission);

        emit Created(_sender, getDateTime());
    }

    /** @notice Enter the basic information on the task and receive the task’s money from the owner’s wallet
      * @dev Fill the information from the task by parameters and calculate the treasury fee by calling the function `calculateFee`. The payment received from owners wallet is collected from this method and saved on the task and in the field `speederReward`
      * @param _category is the task's tag
      * @param _description is the task's description used and agreement between the owner and specialist. It should contain the detailed information about the task’s job
      * @param _developer is the specialist's waller address that will receive the payment
      * @param _regularReward is the amount the specialist will receive when complete the task
      * @param _speederReward is the amount the specialist will receive if he or she complete the task sooner
      * @param _regularDueTime the time the task should be completed
      * @param _speederDueTime the speeder time the task should be completed
      * @param _sender the contract manager
      * @param _dueTimeType is the type of task time (TASK_BY_HOUR or TASK_BY_DAY)
      * @param _publicDescription specifies if the description can be visible for anyone. If false, only the owner and specialist can see the information on the description field
      * @param _title is the task's title that is visible for anyone
      */
    function initToken(string memory _category, string memory _description, address _developer, uint256 _regularReward, uint256 _speederReward, uint16 _regularDueTime, uint16 _speederDueTime, address _sender, uint8 _dueTimeType, bool _publicDescription, string memory _title) external {
        require(_regularReward <= _speederReward, "Regular reward can not be greater than speeder reward pluss fee!");
        require(manager == _sender, "This is not the manager for this task!");
        require(regularReward == 0, "This task was already initialized!");
        require(payWithToken != address(0), "There is not payment token setup");
        bool workedDiff;
        description = _description;
        category = _category;
        developer = _developer;
        regularReward = _regularReward;
        treasuryFeeValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(_regularReward, treasuryFee);
        (workedDiff, speederReward) = SafeMath.trySub(_speederReward, treasuryFeeValue);
        if (workedDiff == false)
          revert("Integer Overflow/Underflow");
        regularDueTime = _regularDueTime;
        speederDueTime = _speederDueTime;
        status = STATUS_CREATED;
        publicDescription = _publicDescription;
        dueTimeType = _dueTimeType;
        title = _title;
        affiliateCommissionValue = ITaskRewardTreasuryConfig(treasuryConfig).calcFee(treasuryFeeValue, affiliateCommission);

        emit Created(_sender, getDateTime());
    }    

}