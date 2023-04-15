// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


/*
* @author Pradeep kumar
* @notice Contract for CrowdFunding 
*/
struct Sign {
    uint8 v;
    bytes32 r;
    bytes32 s;
}
struct Order{
    uint amount;
    uint id;
    address feePayer;
    address tokenContract;
    FundingType PayType;
    uint apy;
}
enum FundingType {Fiat, ETH, Token}

interface IAlmaBrook{
    function invest(Order memory order) external payable returns(bool);
    function cancel(uint _campaignId) external returns (bool);
    function withdrawFund(uint _campaignId, Sign memory sign) external returns(bool);
    function refund(uint _campaignId) external returns(bool) ;
    function getInvestorsByCampaignId(uint256 campaignId) external view returns (address[] memory);
    function StakingRecord(Order memory order) external payable returns(bool);
}

interface IStake {
    function stake(Order memory order) external payable returns(bool);
    function approveTokenTransfer(address tokenAddress, uint256 _amount) external returns (bool);
    function token() external view returns (IERC20);
}

contract AlmaBrook{
    using Counters for Counters.Counter;
    Counters.Counter private _count;
    event Canceled(bool status);
    event Invested( address indexed caller, uint amount);
    // event unInvestment(uint indexed id, address indexed caller, uint amount);
    event Claimed(bool id);
    event Refunded(address indexed caller, uint amount);

    // Creator of campaign
    address public creator;
    // Amount of tokens to raise
    uint public target;// hardcap
    // Total amount raised
    uint public raised;
    // Minimum amount
    uint public softCap;
    // Timestamp of start of campaign
    uint32 public startAt;
    // Timestamp of end of campaign
    uint32 public endAt;
    bool private claimed;
    IERC20 immutable public token;

    mapping(uint256 => address[]) investorsByCampaignId;
    // Mapping from investor => amount 
    mapping(address => uint) public investedAmount;
    // Total number of investors of Campaign
    mapping(address => uint256) public rewards;
    mapping(address => uint) public lastClaimed;

    uint public investor;
    bool public isCanceled;
    uint private campaignId;
    address public admin;
    // address public stakeContract;
    bool refunded;
    ERC20Burnable public tokens;

    uint public totalDividend;
    uint public dividendPerToken;
    mapping(address => uint) public lastDividendPaid;
    event DividendAdded(uint amount);
    event DividendPaid(address indexed investor, uint amount);


    constructor(uint id,address _token,address _creator,address _admin,uint _target, uint _softCap, uint32 _startAt, uint32 _endAt)
    {
        require(_token != address(0),"Token address cannot be zero address");
        campaignId = id;
        token = IERC20(_token);
        tokens = ERC20Burnable(_token);
        creator =  _creator;
        admin = _admin;
        target =  _target;
        softCap =  _softCap;
        startAt =  _startAt;
        endAt =  _endAt;
        claimed =  false;
    }
    

    modifier onlyOwner()  {
        require(creator == msg.sender, "Ownable: caller is not the creator");
    _   ;
    }
    modifier onlyAdmin() {
        require(admin == msg.sender, "Admin: caller is not the Admin");
    _   ;
    }
    function updateAdmin(address _admin) external onlyAdmin returns(bool){
        require(_admin != address(0), "Admin cannot the zero address");
        admin = _admin;
        return true;
    }

    function verifySign(address _caller,uint _campaignId,uint _softCap, Sign memory _sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, _caller, _campaignId,_softCap));
        require(creator == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _sign.v, _sign.r, _sign.s), "Creator sign verification failed");
    }

    function invest(Order memory order) external payable returns(bool){
        require(order.id == campaignId,"Invalid project ID.");
        require(!isCanceled,"The Project has canceled");
        require(block.timestamp >= startAt, "Investment is only allowed after the project has started.");
        require(block.timestamp <= endAt, "The project has ended");
        require(raised <=target,"Cannot invest further, target already reached");
        require(token.balanceOf(msg.sender)>=order.amount,"Insufficient Balance");
        address payer = order.feePayer;
        if ((FundingType.Fiat ==order.PayType)) {
            payer = msg.sender;
        }
        
        raised += order.amount;
        if(investedAmount[order.feePayer]==0){
         _count.increment();
        investor = _count.current();
        }
        investedAmount[order.feePayer] += order.amount;
        token.transferFrom(payer,address(this), order.amount);
        // token.transferFrom(msg.sender,address(this), _amount);
        lastClaimed[order.feePayer] = block.timestamp;
        investorsByCampaignId[order.id].push(order.feePayer);
        emit Invested(order.feePayer, order.amount);
        return true;
    }

    function cancel(uint _campaignId) external onlyOwner returns (bool){
        require(_campaignId == campaignId,"Invalid project ID");
        require(creator == msg.sender, "OnlyCreator: caller is not the creator");
        require(block.timestamp < startAt, "The project has already started");
        isCanceled = true;
        emit Canceled(isCanceled);
        return true;
    }
   
    function withdrawFund(uint _campaignId, Sign memory sign) external onlyOwner returns(bool){
        require(_campaignId == campaignId,"Invalid project ID");
        require(block.timestamp > endAt, "The project has not ended yet.");
        require(raised >= softCap, "The amount raised is below the minimum required threshold.");
        require(!claimed, "Already claimed");
        require(!refunded, "Already refunded");
        verifySign(msg.sender, _campaignId, softCap, sign);
        claimed = true;
        //uint bal = raised;
        // raised = 0;
        //token.transfer(creator, bal);
        // tokens.burn(bal);
        emit Claimed(claimed);
        return true;
    }

    function refund(uint _campaignId) external onlyAdmin returns(bool) {
        require(_campaignId == campaignId,"Invalid project ID");
        require(!refunded,"Already refunded");
        require(block.timestamp > endAt, "cannot refund before ending");
        require(raised < softCap, "Raised fund is already greater than or equal to the minimum amount.");
        require(!claimed, "Already claimed");
        uint bal = raised;
        raised = 0;
        tokens.burn(bal);
        /*
        for(uint96 i =0; i<investorsByCampaignId[_campaignId].length;i++)
        {
            address investorAddress = investorsByCampaignId[_campaignId][i];
            uint bal = investedAmount[investorAddress];
            if(bal>0){
                investedAmount[investorAddress] = 0;
                // token.transfer(investorAddress, bal);
                tokens.burnFrom(investorAddress,bal);
            }
            emit Refunded(investorAddress, bal);
        } */
        refunded = true;
        
        return true;
    }
    function getInvestorsByCampaignId(uint256 _campaignId) external view returns (address[] memory) {
        require(_campaignId == campaignId,"Invalid project ID");
        return investorsByCampaignId[_campaignId];
    } 

        function addDividend(uint _amount) external onlyOwner {
        require(_amount > 0, "Dividend amount must be greater than zero");
        // Transfer the dividend from the owner to the contract
        token.transferFrom(msg.sender, address(this), _amount);
        // Update the total dividend amount and the dividend per token value
        totalDividend += _amount;
        dividendPerToken += (_amount) / raised;
        // Emit an event for the dividend
        emit DividendAdded(_amount);
    }
    function distributeDividend(address _investor) external {
        require(totalDividend > 0, "No dividend available to distribute");
        // Calculate the dividend owed to the investor
        uint owedDividend = calculateDividend(_investor);
        // Transfer the dividend from the contract to the investor
        token.transfer(_investor, owedDividend);
        // Update the last dividend paid for the investor
        lastDividendPaid[_investor] = investedAmount[_investor];
        // Emit an event for the dividend payment
        emit DividendPaid(_investor, owedDividend);
    }

    function calculateDividend(address _investor) internal view returns (uint) {
        uint dividendOwed = dividendPerToken * (investedAmount[_investor] - lastDividendPaid[_investor]);
        return dividendOwed;
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./AlmaBrook.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract FactoryAlma {
    event Deployed(address owner, address contractAddress);
    event Launched(uint id,address indexed creator,uint target,uint softcap,uint32 startAt,uint32 endAt);
    struct Campaign{
        uint id;
        address token;
        address creator;
        // Amount of tokens to raise
        uint target;// hardcap
        // Minimum amount
        uint softCap;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if target was reached and creator has claimed the tokens.

    }
    using Counters for Counters.Counter;
    Counters.Counter private _campaignId;
    //Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    uint public campaignId;
    mapping(uint => address) public campaignAddress;
    address public owner;

    constructor (){
        owner = msg.sender;
    }
    
    function launch(
        address _token,
        uint _target,
        uint _softCap, 
        uint32 _startAt, 
        uint32 _endAt
    ) external returns (address addr) {

        require(_startAt >= block.timestamp, "Invalid start time:please set a start time that is equal to or later than the current time.");
        require(_endAt >= _startAt, "Invalid end time: please set an end time that is equal to or later than the start time.");
        require(_endAt <= block.timestamp + 90 days, "Invalid end time: the maximum duration allowed is 90 days from the current time.");
        _campaignId.increment();
        campaignId = _campaignId.current();

        addr = address(
            new AlmaBrook(
                campaignId,
                _token,
                msg.sender,
                owner,
                _target,
                _softCap,
                _startAt,
                _endAt
            )
        );
        campaigns[campaignId] = Campaign({
            id:campaignId,
            token:_token,
            creator: msg.sender,
            target: _target,
            softCap: _softCap,
            startAt: _startAt,
            endAt: _endAt
        });

        campaignAddress[campaignId] = addr;
        emit Deployed(msg.sender, addr);
        emit Launched(campaignId, msg.sender, _target, _softCap, _startAt, _endAt);
    }

}