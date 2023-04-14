// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
// Importing from local contracts
import { PoolTokenV2 } from "./PoolTokenV2.sol";
import { PoolObject, DistributionObject, DepositSource, DataType} from "./PoolLibrary.sol";

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";

contract EthPool {
    using SafeMath for uint256;

    PoolTokenV2 private token;

    PoolObject private basicInfo;
    DistributionObject private distributionInfo;

    address payable private creator; 
    address payable private owner;
    address payable private poolMasterAddress;
    address payable private operationalAddress;

    uint8 private commissionPercent;
    uint256 private currentAmount;
    uint256 private currentDistAmount;
    uint256 private prePaidCostAmount;
    uint256 private gasCostEth;

    mapping (address => uint256) private distributions;

    address private poolToDeposit;
    bool private iAmPoolToDeposit;

    uint256 private coef;
    uint256 private intercept;

    // ---------------------------------------------
    // new transaction related events (deposts, distributions, transfers, withdraws)
    // in the future these will replace old events

    // replace prev events with these events
    // fromTo is the related address to this record. If none, use contract address
    event addRecord(
        address executor, address fromTo, DepositSource source, DataType dtype,
        uint256 amount, uint256 total, uint256 date
    );
    event subRecord(
        address executor, address fromTo, DataType dtype,
        uint256 amount, uint256 total, uint256 date
    );
    // ---------------------------------------------

    // event DepositReceived(address executor, uint amount, uint currentTotal, 
    //                       uint date, DepositSource source);

    // event PrePaidReceived(address executor, uint amount, uint currentTotal, 
    //                       uint date, DepositSource source);

    // event distributionSent(address receiver, uint256 amount, 
    //                             uint currentTotal, uint date);

    // event distributionCostSent(address executor, address receiver, uint256 amount, 
    //                               uint currentTotal, uint date);
    
    // event updateDistributionAmount(address executor, address to, uint256 currentTotal, 
    //                                uint256 amount, uint256 gasCost, uint date);
    
    event updateNextLastDistributionDate(address executor, address poolAddress, 
                                         uint256 nextDistribution, uint256 lastDistribution, 
                                         uint date);

    event updateLinearRegression(address executor, uint date, uint256 coef, uint256 intercept);

    // event transferPrePayToDistribute(address executor, uint date, uint256 prePayOut, 
    //                                  uint256 finalDistAmount);

    event updateOperationalAddress(
        address executor, address opAddress, uint date);

    modifier isPoolMaster(){
        require(msg.sender == poolMasterAddress,"Not pool master");
        _;
    }

    modifier isCreator(){
        require(msg.sender == creator,"Not pool master");
        _;
    }

    // Modifier to check if the function caller is the pool owner (should be pool master)
    modifier isOwner() {
        require(msg.sender == owner,"Not pool owner" );
        _;
    }

    modifier hasPermission(){
        require(msg.sender == creator 
                || msg.sender == operationalAddress, 
                "You do not have permissions");
        _;
    }

    modifier isParticipant() {
        bool _isParticipant;
        uint256 _balance;

        (_isParticipant, _balance) = _hasParticipation(msg.sender);

        require(_isParticipant, "You have no participation");
        _;
    }

    modifier isAllowedUser(){
        bool _isParticipant;
        uint256 _balance;

        (_isParticipant, _balance) = _hasParticipation(msg.sender);

        require(_isParticipant
                || msg.sender == creator 
                || msg.sender == owner 
                || msg.sender == operationalAddress
                || basicInfo.publicAccess, "Not allowed user");
        _;
    }

    constructor (
        PoolObject memory newPoolObj, // ? delete
        DistributionObject memory newDitrInfo,
        address[] memory usersAddress, uint256[] memory shares,
        address[5] memory othersAddress,
        uint8 commission,
        uint256 _coef, uint256 _intercept
    ) {
        creator = payable(othersAddress[0]);
        owner = payable(othersAddress[1]);
        poolMasterAddress = payable(othersAddress[3]);
        basicInfo = newPoolObj;

        distributionInfo = newDitrInfo;
        distributionInfo.addressObject = address(this);
        distributionInfo.isExternaltoken = false;
        distributionInfo.isFirstDistribution = true;
        distributionInfo.lastDistribution = 0;
        
        commissionPercent = commission;
        //poolMaster = PoolMasterI(payable(msg.sender));
        iAmPoolToDeposit = false;
        //_setPoolToken(participationToken);
        string memory token_name   = string("Distribution Pool Token");
        string memory token_symbol = string("DPT");

        token = new PoolTokenV2(
            token_name, token_symbol, basicInfo.tokenAmount, 
            usersAddress, shares);

        poolToDeposit = othersAddress[2];
        //----------------------------------------
        // set the regression parameters
        // coef = 37170;
        // intercept = 375620;
        coef = _coef;
        intercept = _intercept;
        emit updateLinearRegression(othersAddress[0], block.timestamp, coef, intercept);
        operationalAddress = payable(othersAddress[4]);
        emit updateOperationalAddress(msg.sender, operationalAddress, block.timestamp);
    }

    function _hasParticipation(address userAddress) 
        internal view returns(bool, uint256){
        
        uint256 balance = token.balanceOf(userAddress);
        if (balance > 0){
            return (true, balance);
        } else {
            return (false, 0);
        }
    }

    /** @dev Function to receive ether from metamask.
    */
    receive() external payable {
        currentAmount = currentAmount.add(msg.value);
        currentDistAmount = currentDistAmount.add(msg.value);
        // emit DepositReceived(
        //     msg.sender, msg.value, currentAmount, 
        //     block.timestamp, DepositSource.Metamask);
        emit addRecord(
            msg.sender, msg.sender, DepositSource.Metamask, DataType.CurrentAmount,
            msg.value, currentDistAmount, block.timestamp);
        emit addRecord(
            msg.sender, msg.sender, DepositSource.Metamask, DataType.CurrentDistAmount,
            msg.value, currentAmount, block.timestamp);

    }

    /** @dev Function to deposit to a certain pool.
      */
    function deposit() external payable {
        currentAmount = currentAmount.add(msg.value);
        currentDistAmount = currentDistAmount.add(msg.value);
        // emit DepositReceived(msg.sender, msg.value, currentAmount, 
        // block.timestamp, DepositSource.Platform);
        emit addRecord(
            msg.sender, msg.sender, DepositSource.Platform, DataType.CurrentAmount,
            msg.value, currentAmount, block.timestamp);
        emit addRecord(
            msg.sender, msg.sender, DepositSource.Platform, DataType.CurrentDistAmount,
            msg.value, currentDistAmount, block.timestamp);
        
    }

    function prePay() external payable {
        prePaidCostAmount = prePaidCostAmount.add(msg.value);
        // emit PrePaidReceived(
        //     msg.sender, msg.value, prePaidCostAmount,
        //     block.timestamp, DepositSource.Platform);
        emit addRecord(
            msg.sender, msg.sender, DepositSource.Platform, DataType.PrePay,
            msg.value, prePaidCostAmount, block.timestamp);
    }

    function transferPrePay() external isAllowedUser {
        require(prePaidCostAmount > 0, "Not enough prePaid funds to transfer");
        currentAmount = currentAmount.add(prePaidCostAmount);
        currentDistAmount = currentDistAmount.add(prePaidCostAmount);
        // emit transferPrePayToDistribute(
        //     msg.sender, block.timestamp, prePaidCostAmount, currentDistAmount);
        emit addRecord(
            msg.sender, address(this), DepositSource.Internal, DataType.CurrentAmount,
            prePaidCostAmount, currentAmount, block.timestamp);
        emit addRecord(
            msg.sender, address(this), DepositSource.Internal, DataType.CurrentDistAmount,
            prePaidCostAmount, currentDistAmount, block.timestamp);
        emit subRecord(
            msg.sender, address(this), DataType.PrePay,
            prePaidCostAmount, 0, block.timestamp);

        prePaidCostAmount = 0;
    }

    function _getTotalParticipation(address[] calldata usersAddress) 
        internal view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < usersAddress.length; i++) {
            total += token.balanceOf(usersAddress[i]);
        }
        return total;
    }

    function _getBalancesFromAddress(address[] calldata usersAddress) 
        internal view returns (uint){
        uint totalPercent = 0;
        bool hasBalance;
        uint256 balance;
        for(uint i = 0; i < usersAddress.length; i++) {
            (hasBalance, balance) = _hasParticipation(usersAddress[i]);
            require(hasBalance, "User address has no participation");
            totalPercent += balance;
        }
        return totalPercent.mul(100).div(basicInfo.tokenAmount);
    }

    function _transferCase(address _to, uint256 amountToSend) internal returns (bool, uint256){
        bool success;
        if (_to == poolToDeposit) {
            (success,) = payable(poolToDeposit).call{value:amountToSend}("");
        } else {
            success = payable(_to).send(amountToSend);
        }
        return (success, amountToSend);
    }

    function _gasTransferTo(address _to) internal returns (bool, uint256){
        uint256 amountToSend = gasCostEth;
        require(amountToSend > 0, "Insuffiecient balance");
        gasCostEth = 0;
        return _transferCase(_to, amountToSend);
    }

    function _ethTransferTo(address _to) internal returns (bool, uint256){
        uint256 amountToSend = distributions[_to];
        require(amountToSend > 0, "Insuffiecient balance");
        distributions[_to] = 0;
        return _transferCase(_to, amountToSend);
    }


    function withDraw() 
        external isParticipant {
        uint256 amountToSend;
        bool success;

        (success, amountToSend) = _ethTransferTo(msg.sender);
        require(success, "Failed to send ether");
        currentAmount = currentAmount.sub(amountToSend);

        // emit distributionSent(msg.sender, amountToSend, 
        //                       currentAmount, block.timestamp);
        emit subRecord(
            msg.sender, msg.sender, DataType.CurrentAmount,
            amountToSend, currentAmount, block.timestamp);
        emit subRecord(
            msg.sender, msg.sender, DataType.UserDistribute,
            amountToSend, 0, block.timestamp);
    }

    function withDrawCommission() 
        external hasPermission {
        uint256 amountToSend;
        bool success;

        (success, amountToSend) = _ethTransferTo(poolToDeposit);
        require(success, "Failed to send Commission amount");
        currentAmount = currentAmount.sub(amountToSend);

        // emit distributionCostSent(msg.sender, poolToDeposit, amountToSend,
        //                              currentAmount, block.timestamp);
        emit subRecord(
            msg.sender, poolToDeposit, DataType.CurrentAmount,
            amountToSend, currentAmount, block.timestamp);
        emit subRecord(
            msg.sender, poolToDeposit, DataType.UserDistribute,
            amountToSend, 0, block.timestamp);

        if (gasCostEth > 0){
            (success, amountToSend) = _gasTransferTo(operationalAddress);
            require(success, "Failed to send Gas amount");

            emit subRecord(
                msg.sender, operationalAddress, DataType.GasCost,
                amountToSend, 0, block.timestamp);
        }   
    }

    function _getDistAmounts() internal view 
        returns(uint256 _commissionValue,
                uint256 _efectiveValue) {
        _commissionValue = currentDistAmount.mul(commissionPercent).div(100);
        _efectiveValue   = currentDistAmount.sub(_commissionValue);
    }

    function getDistAmounts(uint256 nParticipants) isAllowedUser public view 
        returns(uint256 gas,
                uint256 commissionValue,
                uint256 efectiveValue,
                uint256 prePayAmount) {
        bool _isCreator = (msg.sender == creator || msg.sender == poolMasterAddress);
        if ( _isCreator ) {
            gas = coef.mul(nParticipants).add(intercept);
        } else {
            gas = 0;
        }

        ( commissionValue, efectiveValue ) = _getDistAmounts();
        prePayAmount = prePaidCostAmount;
    }

    function getUserAmounts(address userAddress) isAllowedUser public view
        returns(uint256) {
        return distributions[userAddress];
    }

    function getCostAmounts() public view 
        returns(uint256) {
        return distributions[poolToDeposit];
    }

    function getTotalParticipation(address[] calldata usersAddress) public view
        returns(uint256) {
        return _getTotalParticipation(usersAddress);
    }

    function canDistributeByDates() public view 
        returns(bool) {
        return _canDistribute();
    }

    function _canDistribute()
            internal view returns(bool){
        uint256 currT = block.timestamp;
        // ***********************
        // use this line for special test
        // bool conditionLast = distributionInfo.lastDistribution <= currT;
        // ***********************
        // use this line for production
        bool conditionLast = distributionInfo.lastDistribution + 12 hours <= currT;
        // ***********************
        if (distributionInfo.isFirstDistribution ||
                distributionInfo.distributionDates.length == 0){
            return conditionLast;
        } else {
            return (conditionLast && distributionInfo.distributionDates[0] <= currT);
        }
    }
    
    function _updateEthDistUserAmount(address userAddress, uint256 efectiveValue, 
                                      uint256 total)
        internal {
        uint256 amountDist = token.balanceOf(userAddress).mul(efectiveValue).div(total);
        distributions[userAddress] += amountDist;

        currentDistAmount = currentDistAmount.sub(amountDist);

        // emit updateDistributionAmount(
        //     msg.sender, userAddress, currentDistAmount, distributions[userAddress], 
        //     gasCost, block.timestamp);

        emit subRecord(
            msg.sender, userAddress, DataType.CurrentDistAmount,
            amountDist, currentDistAmount, block.timestamp);
        emit addRecord(
            msg.sender, userAddress, DepositSource.Internal, DataType.UserDistribute,
            amountDist, distributions[userAddress], block.timestamp);

    }

    function _updateEthDistPdtAmount(uint256 commissionValue)
        internal {
        uint256 amountDist = commissionValue;
        distributions[poolToDeposit] += amountDist;
        currentDistAmount = currentDistAmount.sub(amountDist);
        // emit updateDistributionAmount(
        //     msg.sender, poolToDeposit, currentDistAmount, distributions[poolToDeposit], 
        //     gasCost, block.timestamp);
        emit addRecord(
            msg.sender, poolToDeposit, DepositSource.Internal, DataType.UserDistribute,
            amountDist, distributions[poolToDeposit], block.timestamp);
        emit subRecord(
            msg.sender, poolToDeposit, DataType.CurrentDistAmount,
            amountDist, currentDistAmount, block.timestamp);
    }

    function _updateDistributionsAmounts(address[] calldata usersAddress, uint256 total, 
                                         uint256 gasCost)
        internal {
        
        require(prePaidCostAmount >= gasCost, "Not enough funds to distribute");
        prePaidCostAmount -= gasCost;
        gasCostEth += gasCost;
        
        emit subRecord(
            msg.sender, address(this), DataType.PrePay,
            gasCost, prePaidCostAmount, block.timestamp);
        emit addRecord(
            msg.sender, address(this), DepositSource.Internal, DataType.GasCost,
            gasCost, gasCostEth, block.timestamp);
        
        uint256 _commissionValue;
        uint256 _efectiveValue;

        (_commissionValue, _efectiveValue ) = _getDistAmounts();
        
        for ( uint i = 0; i < usersAddress.length; i++) {
            _updateEthDistUserAmount(usersAddress[i], _efectiveValue, total);
        }
        if (_commissionValue > 0){
            _updateEthDistPdtAmount(_commissionValue);
        }
    }

    function _updateEthDistributionsAmounts(address[] calldata usersAddress, 
        bool _isCreator, bool _isOperational) internal {
        uint256 _gasCost;

        if (_isCreator || _isOperational) {
            _gasCost = coef.mul(usersAddress.length).add(intercept);
            _gasCost = _gasCost.mul(tx.gasprice);
        } else {
            _gasCost = 0;
        }
        uint256 _total = _getTotalParticipation(usersAddress);
        _updateDistributionsAmounts(usersAddress, _total, _gasCost);
    }

    function _updateNextDistribution(DistributionObject storage _distributionInfo) 
        internal {
        // transform the list of distributionDates
        // by removing all its date that are in the past

        // first set the last distribution to current date
        uint256 currT = block.timestamp;
        uint initialLen = _distributionInfo.distributionDates.length;
        uint256 lastDistDate = _distributionInfo.lastDistribution;
        _distributionInfo.lastDistribution = currT;

        //then find the index where its date is higher than current date;
        uint index;
        for (index = 0; index < initialLen; index++){
            if (_distributionInfo.distributionDates[index] > currT ){
                break;
            }
        }
        uint256 nextDistDate;
        if (index == initialLen){
            // this means we didnt found a match, all dates will be discarded
            delete _distributionInfo.distributionDates;
            nextDistDate = 0;
        } else {
            // otherwise, delete its first 'index' elements
            // to do this first move the tail to the front element by element
            for (uint i = 0; i < initialLen - index; i++){
                _distributionInfo.distributionDates[i] = _distributionInfo.distributionDates[i + index];
            }
            // then delete the tail
            for (uint i = 0; i < index; i++){
                _distributionInfo.distributionDates.pop();
            }
            nextDistDate = _distributionInfo.distributionDates[0];
        }

        // this event has redudant info, lastDistribution is the same as block.timestamp)
        // i think it should include the last date from the list that was < block.timestamp
        emit updateNextLastDistributionDate(
            msg.sender, _distributionInfo.addressObject, 
            nextDistDate, lastDistDate, block.timestamp);
    }

    function distribute(address[] calldata usersAddress)
        isAllowedUser public {
        
        bool _isCreator = (msg.sender == poolMasterAddress || msg.sender == creator);
        bool _isOperational = (msg.sender == operationalAddress);

        uint userIntputParticipation = _getBalancesFromAddress(usersAddress);
        require(userIntputParticipation > 99, "Not enough participation");
        require(userIntputParticipation <= 100, "Exceeded 100 participation");
        
        bool canDistribute = _canDistribute();
        require(canDistribute == true, "Cannot distribute in the current timestamp");

        _updateEthDistributionsAmounts(usersAddress, _isCreator, _isOperational);
        _updateNextDistribution(distributionInfo);
        if (distributionInfo.isFirstDistribution) distributionInfo.isFirstDistribution = false;
    }

    function _getDeadline(DistributionObject storage _distributionInfo)
        internal view returns (uint256) {
        uint256 deadline;

        if (_distributionInfo.distributionDates.length > 0) {
            uint256 lastDate = 
                _distributionInfo.distributionDates[_distributionInfo.distributionDates.length - 1];
            uint256 _now = block.timestamp;
            if (lastDate > _now) {
                deadline = lastDate.sub(_now);
            } else {
                deadline = 0;
            }
        } else {
            deadline = 0;
        }
        return deadline;
    }

    function getDetails() public view returns 
    (
        address payable creatorAddress,
        address payable ownerAddress,
        string memory name,
        uint256 deadline,
        uint256 totalVolume,
        uint256 maxTotalToken,
        string memory tokenSymbol,
        bool isPublic,
        address tokenAddress
    ) {
        creatorAddress = creator;
        ownerAddress = owner;
        name = basicInfo.poolName;
        
        deadline = _getDeadline(distributionInfo);
        totalVolume = currentAmount + prePaidCostAmount;
        maxTotalToken = basicInfo.tokenAmount;
        tokenSymbol = basicInfo.tokenSymbol;
        tokenAddress = address(token);
        isPublic = basicInfo.publicAccess;
    }

    function getDistributionDetails() public view returns 
    (
        uint256[] memory ditrDates
    ) {
        ditrDates = distributionInfo.distributionDates;
    }

    function getPoolToDeposit() public view returns ( address  )  {
        return address(poolToDeposit);
    }       
    
    function getPoolToken() external view returns ( address  )  {
        return address(token);
    }

    function setLinnearRegression(uint256 newCoef, uint256 newIntercept) external isCreator{
        coef = newCoef;
        intercept = newIntercept;
        emit updateLinearRegression(msg.sender, block.timestamp, coef, intercept);
    }

    function setOperationalAddress(address opAddress) isCreator external{
        operationalAddress = payable(opAddress);
        emit updateOperationalAddress(msg.sender, opAddress, block.timestamp);
    }

    function getOperationalAddress() external view returns(address){
        return operationalAddress;
    }

    function getGasCostEth() external view returns (uint256){
        return gasCostEth;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { EthPool} from "./EthPool.sol";
import { PoolObject, DistributionObject } from "./PoolLibrary.sol";
// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EthPoolMaster {
    using SafeMath for uint256;

    mapping (address => EthPool) pools;

    uint8 private commissionPercent;
    address private creator;
    bool private ptdAlreadyCreated;
    EthPool private poolToDeposit;
    address[] private allowedUsers;
    address private operationalAddress;

    uint256 private balance;

    uint256 private coef;
    uint256 private intercept;

    // * Events
    event DepositReceived(address sender, uint256 balance);
    
    event CreatePool(address poolStarter, address contractAddress, uint date);
    
    event CreatePoolToDeposit(address poolStarter, address contractAddress, uint date);

    event updateMasterLinearRegression(
        address executor, uint date, uint256 coef, uint256 intercept);

    event updateMasterOperationalAddress(
        address executor, address opAddress, uint date);

    modifier isCreator() {
        require(msg.sender == creator, "Not pool master creator");
        _;
    }

    modifier hasPermissions() {
        require(msg.sender == creator || checkpermission(msg.sender) == true, "Not allowed");
        _;
    }

    modifier pdtNoCreatedYet() {
        require(!ptdAlreadyCreated, "Pool to deposite already created");
        _;
    }

    constructor(uint256 _coef, uint256 _intercept, address opAddress) {
        commissionPercent = 3;  // AGREGAR AL initializer
        creator = payable(msg.sender);
        balance = 0;
        ptdAlreadyCreated = false;
        coef = _coef;
        intercept = _intercept;
        operationalAddress = opAddress;
        emit updateMasterLinearRegression(msg.sender, block.timestamp, coef, intercept);
        emit updateMasterOperationalAddress(msg.sender, opAddress, block.timestamp);
    }

    function getCreator() external view returns (address){
        return creator;
    }

    function checkPool(address poolAddress) public view returns(bool){
        return address(pools[poolAddress]) == poolAddress;
    }

    function checkpermission( address user ) internal view returns(bool){
        bool allowed = false;

        for (uint i = 0; i < allowedUsers.length; i++){
            if (allowedUsers[i] == user){
                allowed = true;
                break;
            }
        }
        return allowed;
    }

    function createPoolToDeposit(
        string memory name,
        uint256[] calldata ditributionDates,
        string memory tokenSymbol,
        address[] memory usersAddress,
        uint256[] memory shares,
        uint256 initialSupply
    ) external pdtNoCreatedYet payable {
        PoolObject memory newPoolObj; 
        newPoolObj.poolName = name;
        newPoolObj.tokenSymbol = tokenSymbol;
        newPoolObj.publicAccess = false;
        newPoolObj.tokenAmount = initialSupply;

        address[5] memory addressList = [
            creator,
            msg.sender,
            address(0),
            address(this),
            operationalAddress
        ];

        DistributionObject memory newDitrInfo;
        newDitrInfo.distributionDates = ditributionDates;
        newDitrInfo.lastDistribution = 0;
        newDitrInfo.lastDebt = 0;
        
        poolToDeposit = new EthPool(
            newPoolObj, newDitrInfo, usersAddress, shares, addressList,
            0, // commissionPercent; ESTO TIENE Q SER CERO
            coef, intercept);

        balance = balance.add(msg.value);
        
        ptdAlreadyCreated = true;
        emit CreatePool(msg.sender, address(poolToDeposit), block.timestamp);
        emit CreatePoolToDeposit(msg.sender, address(poolToDeposit), block.timestamp);
    }

    function createPool(
        string memory name,
        uint256[] calldata ditributionDates,
        string memory tokenSymbol,
        bool publicAccess,
        uint256 gasAmount,
        address[] calldata usersAddress,
        uint256[] calldata shares,
        uint256 initialSupply

    ) external payable {
        require(msg.value >=0 , 'You have to pay for first distribution costs');
        PoolObject memory newPoolObj; 
        newPoolObj.poolName = name;
        newPoolObj.publicAccess = publicAccess;
        newPoolObj.tokenAmount = initialSupply;

        address[5] memory addressList = [
            creator,
            msg.sender,
            address(poolToDeposit),
            address(this),
            operationalAddress
        ];

        DistributionObject memory newDitrInfo;
        newPoolObj.tokenSymbol = tokenSymbol;
        newDitrInfo.distributionDates = ditributionDates;
        newDitrInfo.lastDistribution = 0;
        newDitrInfo.lastDebt = gasAmount;
        

        EthPool newPool = new EthPool(
            newPoolObj, newDitrInfo, usersAddress, shares, addressList,
            commissionPercent,
            coef, intercept);

        balance = balance.add(msg.value);
        
        pools[address(newPool)] = newPool;

        emit CreatePool(msg.sender, address(newPool), block.timestamp);
    }

    function getPoolToDeposit() public view returns ( address  )  {
        return address(poolToDeposit);
    }

    function doPoolDistribution(address poolAddress, address[] calldata usersAddress) //mapping
        hasPermissions public {
        pools[poolAddress].distribute(usersAddress);
    }

    receive() external payable {
        balance = balance.add(msg.value);
        emit DepositReceived(msg.sender, balance);
    }

    function getAllowedUsers () external view returns ( address[] memory ){
        return allowedUsers;
    }

    function addAllowedUser (address userAddress) isCreator public {
        allowedUsers.push(userAddress);
    }

    function removeAllowedUser (address userAddress) isCreator public {
        require(allowedUsers.length > 0, "There are no allowed users");
        bool found = false;
        if (allowedUsers.length == 1){
            if (allowedUsers[0] == userAddress){
                allowedUsers.pop();
                found = true;
            }
        } else {
            for (uint i = 0; i < allowedUsers.length; i++){
                if (allowedUsers[i] == userAddress){
                    found = true;
                    allowedUsers[i] = allowedUsers[allowedUsers.length-1];
                    allowedUsers.pop();
                    break;
                }
            }            
        }
        require(found == true, "That user is not an allowed user");
    }


    function setLinnearRegression(uint256 newCoef, uint256 newIntercept) isCreator public{
        coef = newCoef;
        intercept = newIntercept;
        emit updateMasterLinearRegression(msg.sender, block.timestamp, coef, intercept);
    }

    function getRegressionParamSet() external view
        returns(uint256, uint256){
            return (coef, intercept);
    }

    function setOperationalAddress(address opAddress) isCreator external{
        operationalAddress = opAddress;
        emit updateMasterOperationalAddress(msg.sender, opAddress, block.timestamp);
    }

    function getOperationalAddress() external view returns(address){
        return operationalAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

struct PoolObject{
    string poolName;
    uint256 tokenAmount;
    string tokenSymbol;
    bool publicAccess;
    address[] usersAddress;
    uint256[] shares;
}

struct DistributionObjectOld{
    uint256 comissionFee;
    bool isFirstDistribution;
    bool isExternaltoken;
    address addressObject;
    uint256 lastDistribution;
    uint256 nextDistribution;
    uint256[] distributionDates;
    uint256 lastDebt;
    uint256 lastGasPrice;
    uint256 debt;
}

struct DistributionObject{
    bool isFirstDistribution;
    bool isExternaltoken;
    address addressObject;
    uint256 lastDistribution;
    uint256[] distributionDates;
    uint256 lastDebt;
    uint256 lastGasPrice;
}

struct DistributionAmountObject{
    uint rawAmount;
    uint gasDiscount;
}

enum State {
    Active,
    Expired
}

enum DepositSource {
    Metamask,  //source:0
    Platform,  //source:1
    Internal  //source:2
}

struct PoolShare {
    address user; //gg
    uint participation;
    bool firstDistribution;
    uint listPointer;
}

struct ETokenDistribution {
    uint nextDistribution;
}


// main enumerator used for events addRecord and subRecord,
// DO NOT REMOVE TYPES FROM THIS ENUM, JUST ADD MORE IF NEEDED.
enum DataType {
    CurrentAmount,  //dtype:0 ethPool
    CurrentDistAmount, //dtype:1 ethPool
    PrePay, //dtype:2 ethPool, tokenPool
    GasCost,  //dtype:3 ethPool, tokenPool
    Distribute, //dtype:4 tokenPool
    UserDistribute //dtype:5 ethPool, tokenPool
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PoolTokenV2 is ERC20 {
    using SafeMath for uint256;

    constructor(string memory name, 
                string memory symbol,
                uint256 initialSupply,
                address[] memory usersAddress,
                uint256[] memory shares) 
        ERC20(name, symbol) {
        _sendParticipation(initialSupply, usersAddress, shares);
    }

    function _sendParticipation(uint256 initialSupply, address[] memory usersAddress, uint256[] memory shares)
        internal {
        
        require(usersAddress.length == shares.length, "Input inconsitcy");
        uint256 _totalShare = 0;
        for (uint i = 0; i < shares.length; i++) {
            _totalShare += shares[i];
        }
        require(_totalShare == 100, "shares sum must be equal to 100 percent");

        uint256 _amount;
        for (uint i = 0; i < usersAddress.length; i++) {
            _amount = shares[i].mul(initialSupply).div(100);
            _mint(usersAddress[i], _amount);
            
        }

    }

}