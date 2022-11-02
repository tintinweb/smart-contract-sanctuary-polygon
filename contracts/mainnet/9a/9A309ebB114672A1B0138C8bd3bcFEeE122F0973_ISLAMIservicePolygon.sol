/**
 *Submitted for verification at polygonscan.com on 2022-11-02
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.15;


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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.15;




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

// File: contracts/ISLAMI_ERC20_Polygon.sol



/*
@dev: This code is developed by Jaafar Krayem and is free to be used by anyone
Use under your own responsibility!
*/

/*
@dev: Lock your tokens in a safe place use recovery wallet option
*/



pragma solidity = 0.8.15;

contract ISLAMIservicePolygon {
    using SafeMath for uint256;

    address public feeReceiver; //0.5% of 1% total fee
    address public developers; //0.5% of 1% total fee
    /*
    Address recoverHolder:
    holds recovered token amount if user added
    this contract address as recover wallet
    user should contact ISLAMI owner to receive
    their tokens to a new desired wallet
    */
    address public recoveryHolder; 
    ERC20 public ISLAMI;

/*
@dev: Private values
*/  
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    uint256 private currencyID;

/*
@dev: public values
*/
    address public owner;
    uint256 public investorVaultCount;
    uint256 public constant ewFee = 1; //1% of locked amount

/*
@dev: Events
*/
    event InvestorAdded(address Investor, uint256 Amount);
    event tokenAdded(ERC20 Token, string Symbol);
    event tokenClaimed(address Token, address Receiver, uint256 Amount);
    event SelfLockInvestor2(address Investor,uint256 vaultID, ERC20 Token, uint256 Amount);
    event SelfLockInvestor(address Investor, ERC20 Token, uint256 Amount);
    event EditSelfLock(address Investor, ERC20 Token, uint256 Amount);
    event ExtendSelfLock(address Investor, ERC20 Token, uint256 Time);
    event EmergencyWithdraw(address Investor, address NewWallet, uint256 Amount);
    event ownerShipChanged(address indexed newOwner);
    event feeReceiverChanged(address indexed newReceiver);
    event devChanged(address indexed newDev);
    event recoveryHolderChanged(address indexed newRecoverHolder);
/*
@dev: Investor Vault
*/   
    struct VaultInvestor{
        uint256 vaultID;
        ERC20 tokenAddress;
        uint256 amount;
        address recoveryWallet;
        uint256 lockTime;
        uint256 timeStart;
    }
/*
@dev: Currency Vault
*/   
    struct cryptocurrency{
        uint256 currencyID;
        ERC20 tokenAddress;
        string symbol;
        uint256 fractions;
        uint256 currencyVault;
    }

/*
 @dev: Mappings
*/
    mapping(address => bool) public Investor;
    
    //mapping the address of the token with the user address to user Vault
    mapping(address => mapping(address=> VaultInvestor)) public lT;
    mapping(address => bool) public blackList;

    mapping(ERC20 => cryptocurrency) public crypto;
    mapping(ERC20 => bool) public isCrypto; 


/* @dev: Check if feReceiver */
    modifier onlyOwner (){
        require(msg.sender == owner, "Only ISLAMICOIN owner can add Coins");
        _;
    }
/*
    @dev: check if user is investor
*/
    modifier isInvestor(address _investor){
        require(Investor[_investor] == true, "Not an Investor!");
        _;
    }
/*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    constructor(address _feeReceiver, address _developers, address _recoveryHolder, ERC20 _ISLAMI) {
        owner = msg.sender;
        ISLAMI = _ISLAMI;
        feeReceiver = _feeReceiver;
        developers = _developers;
        recoveryHolder = _recoveryHolder;
        investorVaultCount = 0;
        currencyID = 0;
        _status = _NOT_ENTERED;
    }
    function changeOwner(address _newOwner) external onlyOwner{
        owner = _newOwner;
        emit ownerShipChanged(_newOwner);
    }
    function changeFeeReceiver(address _newReceiver) external onlyOwner{
        feeReceiver = _newReceiver;
        emit feeReceiverChanged(_newReceiver);
    }
    function changeDev(address _newDev) external onlyOwner{
        developers = _newDev;
        emit devChanged(_newDev);
    }
    function changeRecoveryHolder(address _newRecoveryHolder) external onlyOwner{
        recoveryHolder = _newRecoveryHolder;
        emit recoveryHolderChanged(_newRecoveryHolder);
    }
    function cryptoID(address _token) public view returns(uint256 _cryptoID){
        if(isCrypto[ERC20(_token)]== true){
            _cryptoID = crypto[ERC20(_token)].currencyID;
            return _cryptoID;
        }
        else{
            return 0; //token should not have ID equal to zero user has not locked tokens
        }
    }
    function hasLockedTokens(address _token, address _investor) public view returns(bool){
        if(lT[_token][_investor].tokenAddress == ERC20(_token)){
            return true;
        }
        else{
            return false;
        }
    }
    function addCrypto(address _token, string memory _symbol, uint256 _fractions) external onlyOwner{
        currencyID++;
        ERC20 token = ERC20(_token);
        crypto[token].currencyID = currencyID;
        crypto[token].tokenAddress = token;
        crypto[token].symbol = _symbol;
        crypto[token].fractions = _fractions;
        isCrypto[token] = true;
        emit tokenAdded(token, _symbol);
    }
/*
    @dev: require approval on spend allowance from token contract
    this function for investors who want to lock their tokens
    usage: 
           1- if usrr want to use recovery wallet service
           2- if user want to vote on projects!
*/
    function selfLock(address _token, uint256 _amount, uint256 _lockTime, address _recoveryWallet) external nonReentrant{
        ERC20 token = ERC20(_token);
        require(isCrypto[token] == true,"Not listed");
        uint256 _vaultID = crypto[token].currencyID;
        require(_recoveryWallet != address(0), "Burn!");
        require(lT[_token][msg.sender].amount == 0,"Please use editSeflLock!");
        uint256 amount = _amount;
        uint256 lockTime = _lockTime.mul(1 days);//(1 days);
        require(token.balanceOf(msg.sender) >= amount,"Need token!");
        token.transferFrom(msg.sender, address(this), amount);
        emit SelfLockInvestor(msg.sender, token, amount);
        lT[_token][msg.sender].vaultID = _vaultID;
        lT[_token][msg.sender].tokenAddress = token;
        lT[_token][msg.sender].amount = amount; 
        lT[_token][msg.sender].timeStart = block.timestamp;
        lT[_token][msg.sender].lockTime = lockTime.add(block.timestamp);
        lT[_token][msg.sender].recoveryWallet = _recoveryWallet;
        Investor[msg.sender] = true;
        crypto[token].currencyVault += amount;
        investorVaultCount++;
    }
/*
    @dev: require approval on spend allowance from token contract
    this function is to edit the amount locked by user
    usage: if user want to raise his voting power
*/
    function editSelfLock(address _token, uint256 _amount) external isInvestor(msg.sender) nonReentrant{
        uint256 amount = _amount;
        ERC20 token = lT[_token][msg.sender].tokenAddress;
        require(token.balanceOf(msg.sender) >= amount,"ERC20 balance!");
        token.transferFrom(msg.sender, address(this), amount);
        lT[_token][msg.sender].amount += amount;
        crypto[token].currencyVault += amount;
        emit EditSelfLock(msg.sender, token, amount);
    }
/*
    @dev: Extend the period of locking, used if user wants
    to vote and the period is less than 30 days
*/
    function extendSelfLock(address _token, uint256 _lockTime) external isInvestor(msg.sender) nonReentrant{
        uint256 lockTime = _lockTime.mul(1 days);
        ERC20 token = lT[_token][msg.sender].tokenAddress;
        lT[_token][msg.sender].lockTime += lockTime;
        emit ExtendSelfLock(msg.sender, token, lockTime);
    }
/*
    @dev: Investor lost his phone or wallet, or passed away!
    only the wallet registered as recovery can claim tokens after lock is done
*/
    function recoverWallet(address _token, address _investor) external isInvestor(_investor) nonReentrant{
        require(msg.sender == lT[_token][_investor].recoveryWallet &&
        lT[_token][_investor].lockTime < block.timestamp,
        "Not allowed");
        useRecovery(_token, _investor);
    }
/*
    @dev: Unlock locked tokens for user
    only the original sender can call this function
*/
    function selfUnlock(address _token, uint256 _amount) external isInvestor(msg.sender) nonReentrant{
        require(lT[_token][msg.sender].lockTime <= block.timestamp, "Not yet");
        uint256 amount = _amount;
        ERC20 token = lT[_token][msg.sender].tokenAddress;
        require(lT[_token][msg.sender].amount >= amount, "Amount!");
        lT[_token][msg.sender].amount -= amount;
        crypto[token].currencyVault -= amount;
        if(lT[_token][msg.sender].amount == 0){
            delete lT[_token][msg.sender];
            investorVaultCount--;
        }
        emit tokenClaimed(msg.sender, address(token), amount);
        token.transfer(msg.sender, amount);
    }
/*
    @dev: If self lock investor wallet was hacked!
    Warning: this will blacklist the message sender!
*/
    function emergencyWithdrawal(address _token) external isInvestor(msg.sender) nonReentrant{
        useRecovery(_token, msg.sender);
    }
/*
    @dev: Recover Wallet Service, also used by emergencyWithdrawal!
    * Check if statment
    if user didn't add a recovery wallet when locking his tokens
    the recovery wallet is set this contract and tokens are safe 
    and released to the contract itself.
    This contract does not have a function to release the tokens
    in case of emerergency it is only done by the user.
    if(newWallet == address(this))
    Release tokens to smart contract, investor should contact project owner on Telegram @jeffrykr
*/
    function useRecovery(address _token, address _investor) internal {
        require(lT[_token][_investor].amount > 0, "no tokens");
        ERC20 token = lT[_token][_investor].tokenAddress;
        uint256 feeToPay = lT[_token][_investor].amount.mul(ewFee).div(200);
        uint256 feeToDev = lT[_token][_investor].amount.mul(ewFee).div(200);
        uint256 totalFee = feeToPay.add(feeToDev);
        address newWallet = lT[_token][_investor].recoveryWallet;
        uint256 fullBalance = lT[_token][_investor].amount.sub(totalFee);
        crypto[token].currencyVault -= lT[_token][_investor].amount;
        delete lT[_token][_investor];
        emit EmergencyWithdraw(_investor, newWallet, fullBalance);
        if(newWallet == address(this)){
            newWallet = recoveryHolder;
        }
        investorVaultCount--;
        token.transfer(developers, feeToDev);
        token.transfer(feeReceiver, feeToPay);
        token.transfer(newWallet, fullBalance);
    }


/*
   @dev: people who send Matic by mistake to the contract can withdraw them
*/
    mapping(address => uint) public balanceReceived;

    function receiveMoney() public payable {
        assert(balanceReceived[msg.sender] + msg.value >= balanceReceived[msg.sender]);
        balanceReceived[msg.sender] += msg.value;
    }

    function withdrawMoney(address payable _to, uint256 _amount) public {
        require(_amount <= balanceReceived[msg.sender], "not enough funds.");
        assert(balanceReceived[msg.sender] >= balanceReceived[msg.sender] - _amount);
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    } 

    receive() external payable {
        receiveMoney();
    }
}


               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2022
               **********************************************************/