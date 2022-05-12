/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

pragma solidity =0.5.8;


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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @title Crowdsale
 * @notice This contract is similar to Openzeppelin Crowdsale contract with the difference that
 * option to update rate has been added.
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event RateAdjusted(uint256 adjustedRate);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }


    /**
     * @dev Validation of an incoming purchase.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal pure {
        require(beneficiary != address(0), "Sale: beneficiary is the zero address");
        require(weiAmount > 0, "Crowdsale: weiAmount  can't be  0");
        
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
    * @dev This function has been added to this original contract to update rate of token
    * should this become necessary due to legal requirements.
    * @param newRate new rate of token price
    */
    function adjustRate(uint256 newRate) public {
        require(newRate > 0, "Crowdsale-adjustRate: Rate has to be non-zero");
        _rate = newRate;
        emit RateAdjusted(newRate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

/**
 * @title TimedCrowdsale
 * @notice This contract is similar to OpenZeppelin TimedCrowdsale with the difference that
 * it is inherited from modified Crowdsale contract.
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    // function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256  DAIAmount) internal view onlyWhileOpen {
    //     super._preValidatePurchase(beneficiary, weiAmount, DAIAmount);
    // }

    
    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

/**
 * @dev A Secondary contract can only be used by its primary account (the one that created it).
 */
contract Secondary {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(msg.sender == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title Manager Role
 * @dev This contract is developed based on the Manager contract of OpenZeppelin.
 * The key difference is the management of the manager roles is restricted to one owner
 * account. At least one manager should exist in any situation.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
contract ManagerRole is Ownable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private managers;
    uint256 private _numManager;

    constructor() internal {
        _addManager(msg.sender);
        _numManager = 1;
    }

    /**
     * @notice Only manager can take action
     */
    modifier onlyManager() {
        require(isManager(msg.sender), "ManagerRole-onlyManager: The account is not a manager");
        _;
    }

    /**
     * @notice This function allows to add managers in batch with control of the number of
     * iterations
     * @param accounts The accounts to be added in batch
     */
    // solhint-disable-next-line
    function addManagers(address[] calldata accounts) external onlyOwner {
        uint256 length = accounts.length;
        require(length <= 256, "ManagerRole-addManagers:too many accounts");
        for (uint256 i = 0; i < length; i++) {
            _addManager(accounts[i]);
        }
    }
    
    /**
     * @notice Add an account to the list of managers,
     * @param account The account address whose manager role needs to be removed.
     */
    function removeManager(address account) external onlyOwner {
        _removeManager(account);
    }

    /**
     * @notice Check if an account is a manager
     * @param account The account to be checked if it has a manager role
     * @return true if the account is a manager. Otherwise, false
     */
    function isManager(address account) public view returns (bool) {
        return managers.has(account);
    }

    /**
     *@notice Get the number of the current managers
     */
    function numManager() public view returns (uint256) {
        return _numManager;
    }

    /**
     * @notice Add an account to the list of managers,
     * @param account The account that needs to tbe added as a manager
     */
    function addManager(address account) public onlyOwner {
        require(account != address(0), "ManagerRole-addManager: account is zero");
        _addManager(account);
    }

    /**
     * @notice Renounce the manager role
     * @dev This function was not explicitly required in the specs. There should be at
     * least one manager at any time. Therefore, at least two when one manage renounces
     * themselves.
     */
    function renounceManager() public {
        require(_numManager >= 2, "ManagerRole-renounceManager: Managers are fewer than 2");
        _removeManager(msg.sender);
    }

    /** OVERRIDE
    * @notice Allows the current owner to relinquish control of the contract.
    * @dev Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        revert("ManagerRole-renounceOwnership: Cannot renounce ownership");
    }

    /**
     * @notice Internal function to be called when adding a manager
     * @param account The address of the manager-to-be
     */
    function _addManager(address account) internal {
        _numManager = _numManager.add(1);
        managers.add(account);
        emit ManagerAdded(account);
    }

    /**
     * @notice Internal function to remove one account from the manager list
     * @param account The address of the to-be-removed manager
     */
    function _removeManager(address account) internal {
        _numManager = _numManager.sub(1);
        managers.remove(account);
        emit ManagerRemoved(account);
    }
}

/**
 * @title Pausable Manager Role
 * @dev This manager can also pause a contract. This contract is developed based on the
 * Pause contract of OpenZeppelin.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
contract PausableManager is ManagerRole {

    event BePaused(address manager);
    event BeUnpaused(address manager);

    bool private _paused;   // If the crowdsale contract is paused, controled by the manager...

    constructor() internal {
        _paused = false;
    }

   /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!_paused, "PausableManager-whenNotPaused: paused");
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(_paused, "PausableManager-whenPaused: not paused");
        _;
    }

    /**
    * @return true if the contract is paused, false otherwise.
    */
    function paused() public view returns(bool) {
        return _paused;
    }

    /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function pause() public onlyManager whenNotPaused {
        _paused = true;
        emit BePaused(msg.sender);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyManager whenPaused {
        _paused = false;
        emit BeUnpaused(msg.sender);
    }
}

/**
 * @title modifier contract that checks if the address is valid
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
contract ValidAddress {
    /**
     * @notice Check if the address is not zero
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "ValidAddress-onlyValidAddress:Not a valid address");
        _;
    }

    /**
     * @notice Check if the address is not the sender's address
    */
    modifier isSenderNot(address _address) {
        require(_address != msg.sender, "ValidAddress-isSenderNot:Address is the same as the sender");
        _;
    }

    /**
     * @notice Check if the address is the sender's address
    */
    modifier isSender(address _address) {
        require(_address == msg.sender, "ValidAddress-isSender: Address is different from the sender");
        _;
    }
}

/**
 * @title Whitelist
 * @dev this contract enables whitelisting of users, sets max amount allowed to be contributed by member 
 * and provides a way to navigate through this list.
 */
contract Whitelist is ValidAddress, PausableManager {

    mapping (address => bool) private _isWhitelisted;       // white listed flag
    mapping(address => uint) public _contributionAmounts;   // max amount allowed to be contributed
    uint public totalWhiteListed;                           // white listed users number
    address[] public holdersIndex;                          // iterable index of holders

    event AdddWhitelisted(address indexed user);
    event RemovedWhitelisted(address indexed user);


    /**
     * @dev Add an account to the whitelist,
     * @param user The address of the investor
     */
    function addWhitelisted(address user, uint256 maxAllowed) external onlyManager {
        _addWhitelisted(user, maxAllowed);
    }

    /**
     * @notice This function allows to whitelist investors in batch
     * with control of number of iterations
     * @param users The accounts to be whitelisted in batch
     */
    // solhint-disable-next-line
    function addWhitelistedMultiple(address[] calldata users, uint256[] calldata maxAllowed) external onlyManager {
        uint256 length = users.length;
        require(length <= 256, "Whitelist-addWhitelistedMultiple: List too long");
        for (uint256 i = 0; i < length; i++) {
            _addWhitelisted(users[i], maxAllowed[i]);
        }
    }

    /**
     * @notice Remove an account from the whitelist, calling the corresponding internal
     * function
     * @param user The address of the investor that needs to be removed
     */
    function removeWhitelisted(address user)
        external
        onlyManager
    {
        _removeWhitelisted(user);
    }

    /**
     * @notice This function allows to whitelist investors in batch
     * with control of number of iterations
     * @param users The accounts to be whitelisted in batch
     */
    // solhint-disable-next-line
    function removeWhitelistedMultiple(address[] calldata users)
        external
        onlyManager
    {
        uint256 length = users.length;
        require(length <= 256, "Whitelist-removeWhitelistedMultiple: List too long");
        for (uint256 i = 0; i < length; i++) {
            _removeWhitelisted(users[i]);
        }
    }

    /**
     * @notice Check if an account is whitelisted or not
     * @param user The account to be checked
     * @return true if the account is whitelisted. Otherwise, false.
     */
    function isWhitelisted(address user) public view returns (bool) {
        return _isWhitelisted[user];
    }

    /**
     * @notice it will return max amount allowed to be contributed by this user
     * @param user {address} address of the contributor
    */
    function returnMaxAmountForUser(address user) public view returns (uint256) {
        return  _contributionAmounts[user];
    }

    /**
     * @notice Add an investor to the whitelist
     * @param user The address of the investor that has successfully passed KYC
     * @param maxToContribute Max amount user can contribute based on KYC
     */
    function _addWhitelisted(address user, uint maxToContribute)
        internal
        onlyValidAddress(user)
    {
        require(_isWhitelisted[user] == false, "Whitelist-_addWhitelisted: account already whitelisted");
        _isWhitelisted[user] = true;
        _contributionAmounts[user] = maxToContribute;
        totalWhiteListed++;
        holdersIndex.push(user);
        emit AdddWhitelisted(user);
    }

    /**
     * @notice Remove an investor from the whitelist
     * @param user The address of the investor that needs to be removed
     */
    function _removeWhitelisted(address user)
        internal
        onlyValidAddress(user)
    {
        require(_isWhitelisted[user] == true, "Whitelist-_removeWhitelisted: account was not whitelisted");
        _isWhitelisted[user] = false;
        _contributionAmounts[user] = 0;
        totalWhiteListed--;
        emit RemovedWhitelisted(user);
    }
}

/**
 * @title Crowdsale with whitelists
 * @dev This contract is similar to OpenZeppelin's WhitelistCrowdsale, yet with different
 * contract inherited to implement better manager role
 */
/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistCrowdsale is Whitelist, Crowdsale {
    /**
    * @notice Extend parent behavior requiring beneficiary to be whitelisted.
    * @param beneficiary Token beneficiary
    * @param weiAmount Amount of wei contributed
    */
    // function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 DaiAmount)
    //     internal
    //     pure
    // {
    //     require(isWhitelisted(beneficiary), "WhitelistCrowdsale-_preValidatePurchase: beneficiary is not whitelisted");
    //     super._preValidatePurchase(beneficiary, weiAmount, DaiAmount);
    // }
}

/**
 * @title PostDeliveryCrowdsale
 * @dev This contract is similar to OpenZeppelin's PostDeliveryCrowdsale, yet with different
 * contract inherited for whitelistCrowdsale
 */
/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale, WhitelistCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    __unstable__TokenVault private _vault;

    constructor() public {
        _vault = new __unstable__TokenVault();
         // this is required due to the constraint that every token recipient has to be whitelisted
        _addWhitelisted(address(_vault), 0);
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address beneficiary) public {
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        uint256 amount = _balances[beneficiary];
        require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");

        _balances[beneficiary] = 0;
        _vault.transfer(token(), beneficiary, amount);
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault), tokenAmount);
    }
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}

/**
 * @title FinalizableCrowdsale
 * @notice this contract is similar to Openzeppelin FinalizableCrowdsale with the difference
 * that inheritance is made from modified TimedCrowdsale.
 * @dev Extension of TimedCrowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor () internal {
        _finalized = false;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() public {
        require(!_finalized, "FinalizableCrowdsale: already finalized");
        require(hasClosed(), "FinalizableCrowdsale: not closed");

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super._finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function _finalization() internal {
        // solhint-disable-previous-line no-empty-blocks
    }
}

/**
 * @title modifier contract that guards certain properties only triggered once
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
contract CounterGuard {
    /**
     * @notice Control if a boolean attribute (false by default) was updated to true.
     * @dev This attribute is designed specifically for recording an action.
     * @param criterion The boolean attribute that records if an action has taken place
     */
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "CounterGuard-onlyOnce: Already been set");
        _;
    }
}

/**
 * @title Crowdsale with check of pausable status
 * @notice This contract is similar to openZeppling PausableCrwodsale with the differnce
 * that it is inheriting from modified Crowdsale contract.
 * @dev  This contract is similar to OpenZeppelin's PausableCrowdsale, yet with different
 * contract inherited for manager role.
 */
contract PausableCrowdsale is PausableManager, Crowdsale {

    /**
     * @notice Validation of an incoming purchase.
     * @dev Use require statements to revert state when conditions are not met. Adding
     * the validation that the crowdsale must not be paused.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    // function _preValidatePurchase(
    //     address _beneficiary,
    //     uint256 _weiAmount,
    //     uint256 _daiAmount
    // )
    //     internal
    //     view
    //     whenNotPaused
    // {
    //     return super._preValidatePurchase(_beneficiary, _weiAmount, _daiAmount);
    // }

}

// SPDX-License-Identifier: MIT
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mumbai Testnet 
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     * Network: Polygon
     * Address main: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor() public{
        // replace address for Mumbai or Main Polygon
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {

        // TODO: uncoment this for deployment 
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;

    // TODO: comment this for deployment. Use this only for running tests.     
    // return 134225467;
    }

}

/**
 * @title MAJI Crowdsale
 */
contract ECrowdsale is CounterGuard, WhitelistCrowdsale,
                          PostDeliveryCrowdsale, FinalizableCrowdsale,
                          PausableCrowdsale {

    using SafeMath for uint256;
    
   
    bool private _setRole;              // flag to indicate that roles are set
    uint256 private _maxCryptoSale;     // limit of tokens available for crypto sale as opposed to FIAT
    uint256 private _cryptoSaleAmount;  // current amount of tokens available during STOs for crypto sales
    bool private _noCryptoLimits;       // flag indicating if limits on crypto sale should be enforced
    address payable private _wallet;    // address of wallet to which proceeds are transferred
    uint256 private _DAIRaised;         // Amount of DAI raised
    uint256 private _weiRaised;
    IERC20 private _DAI;
    PriceConsumerV3 private _priceConsumerV3;   // Smart contract checking fof price of DAI/ETH

    event WithdrawTokens(address beneficiary, uint256 value);
    event RefundExtra(address beneficiary, uint256 value);
    event NonEthTokenPurchased(address indexed beneficiary, uint256 tokenAmount);
    event FundsForwarded(uint256 eth, uint256 dai);
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 daiAmount, uint256 tokensIssued );
    event test(uint256 dai, uint256 balance);


    /**
     * @param startingTime The starting time of the crowdsale
     * @param endingTime The ending time of the crowdsale
     * @param rate Token per weiDAIAmount.
     * @param wallet The address of the team which receives investors ETH payment.
     * @param token The address of the token.
     */

    constructor(
        uint256 startingTime,
        uint256 endingTime,
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint maxCryptoSale,
        address DAI,
        address oracle
    )
        public
        Crowdsale(rate, wallet, token)
        TimedCrowdsale(startingTime, endingTime)
         {
            _wallet = wallet;
            _maxCryptoSale = maxCryptoSale;
            _noCryptoLimits = false;
            _DAI = IERC20(DAI);
            _priceConsumerV3 = PriceConsumerV3(oracle);
        }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender, 0);
    }

    /**
     * @notice Allows onlyManager to allocate token for beneficiary.
     * @param beneficiary Recipient of the token purchase
     * @param tokenAmount Amount of token purchased
     */
    function nonEthPurchase(address beneficiary, uint256 tokenAmount)
        public onlyManager
    {
        require(beneficiary != address(0), "ECrowdsale-nonEthPurchase: beneficiary is the zero address");
        _processPurchase(beneficiary, tokenAmount);
        emit NonEthTokenPurchased(beneficiary, tokenAmount);
    }

    /**
    * @notice Calculate investors remaining allowable amount to invest and validate,
    * than call parent validation.
    * @param beneficiary investor account
    * @param tokensToPurchase amount of tokens being bought.
     */
    function _preValidatePurchaseCrypto(address beneficiary, uint256 tokensToPurchase) private view {
         require(returnMaxAmountForUser(beneficiary).sub(balanceOf(beneficiary)) >= tokensToPurchase,
                "ECrowdsale-_preValidatePurchaseCrypto: contribution exceeds allowed amount");
    }


     /**
     * @notice Batch allocation tokens for investors paid with non-ETH
     * @param beneficiaries Recipients of the token purchase
     * @param amounts Amounts of token purchased
     */
    function nonEthPurchaseMulti(
        address[] calldata beneficiaries,
        uint256[] calldata amounts
    )
        external
    {
        uint256 length = amounts.length;
        require(beneficiaries.length == length, "length !=");
        require(length <= 256, "ECrowdsale-nonEthPurchaseMulti: List too long, please shorten the array");
        for (uint256 i = 0; i < length; i++) {
            nonEthPurchase(beneficiaries[i], amounts[i]);
        }
    }

    /**
     * @notice setup roles and contract addresses for the crowdsale contract
     * @dev This function can only be called once by the owner.
     * @param newOwner The address of the new owner/manager.
     */
    function roleSetup(
        address newOwner
    )
        public
        onlyOwner
        onlyOnce(_setRole)
    {
         if (address(newOwner) != address(msg.sender) ) {
            addManager(newOwner);
            _removeManager(msg.sender);
            transferOwnership(newOwner);
         }
        _setRole = true;
    }

    /**
    * @dev Override parent function to ensure that finalization has occurred
    * before beneficiaries can claim their tokens.
    * @param beneficiary address or token beneficiary
     */
    function withdrawTokens(address beneficiary) public {

        require(finalized(), "ECrowdsale:withdrawTokens - Crowdsale is not finalized");

        uint256 balanceOf = balanceOf(beneficiary);
        super.withdrawTokens(beneficiary);
        emit WithdrawTokens(beneficiary, balanceOf);
    }

     /**
     * @dev create an alternative way to claim tokens without passing of beneficiary
     */
    function claimTokens() public {

        address payable beneficiary = msg.sender;
        withdrawTokens(beneficiary);
    }

    /**
    * @dev return amount of current tokens sold due to crypto sales
    * @return amount of tokens sold due to crypto sales
     */
    function cryptoSaleAmount() public view returns(uint256) {

        return _cryptoSaleAmount;
    }

    /**
    * @dev allow to sell tokens for ETH above initial set values
     */
    function allowRemainingTokensForCrypto() public onlyManager {

        _noCryptoLimits = true;

    }

    /**
    * @dev Allow only manager to call this function
    * @param newClosingTime new time to close the sale
     */
    function extendTime(uint256 newClosingTime) public onlyManager {
       super._extendTime(newClosingTime);
    }

    /**
     * @return Overwrite parent to verify  amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return Overwrite parent to verify  amount of wei raised.
     */
    function daiRaised() public view returns (uint256) {
        return _DAIRaised;
    }
    /**
    * @dev Override to ensure that onlyManager can execute this function
    */
    function finalize() public  onlyManager {
        super.finalize();
    }

    /**
    * @dev Overwrite parent function to deal with refunding uneven amounts which
    * might be sent to the contract. Tokens have no decimals and only full tokens
    * can be sold.
    * @param beneficiary user for whom tokens are bought
    * @param DAIAmountContributed amount of DAI contributed 
     */
    function buyTokens(address beneficiary, uint256 DAIAmountContributed) public payable nonReentrant whenNotPaused  {

        uint256 extra;
        uint256 DAIAmount;
        uint256 valueInDai;
        uint256 weiAmount;

        if (msg.value > 0 ){
            extra = msg.value % calculateEthRate();
            weiAmount = msg.value.sub(extra);
        }
        else{
            extra = DAIAmountContributed % rate();
            DAIAmount = DAIAmountContributed.sub(extra);
        }

        _preValidatePurchase(beneficiary, weiAmount, DAIAmount);

        if (weiAmount > 0) {
            valueInDai =  calculateDAIForEther(msg.value);
           _weiRaised = _weiRaised.add(weiAmount);
        } else if (DAIAmount > 0)
        {
            valueInDai = DAIAmount;
            _DAIRaised = _DAIRaised.add(DAIAmount);
            IERC20(_DAI).safeTransferFrom(msg.sender, address(this), DAIAmount);
        }

        uint256 tokensToPurchase = getTokenAmount(valueInDai);

        _preValidatePurchaseCrypto(beneficiary, tokensToPurchase);

        _cryptoSaleAmount += tokensToPurchase;  // track tokensToPurchase sold through crypto

        require(_cryptoSaleAmount <= _maxCryptoSale || _noCryptoLimits, 
        "ECrowdsale-buyTokens: Max available for crypto sale has been reached");

        _processPurchase(beneficiary, tokensToPurchase);
        emit TokensPurchased(msg.sender,beneficiary, weiAmount, DAIAmount, tokensToPurchase);

        _forwardFunds(DAIAmount, weiAmount);

        if (extra > 0 && weiAmount > 0) {
           
            msg.sender.transfer(extra);
            emit RefundExtra(msg.sender, extra);
        }
    }


    /**
     * @dev Validation of an incoming purchase.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param DAIAmount value of DAI involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 DAIAmount) internal view {
        require(beneficiary != address(0), "ECrowdsale:_preValidatePurchase beneficiary is the zero address");
        require(weiAmount != 0 || DAIAmount != 0, "ECrowdsale:_preValidatePurchase Both weiAmount and DAIAmount  can't be  0");
        require(isWhitelisted(beneficiary), "WhitelistCrowdsale-_preValidatePurchase: beneficiary is not whitelisted");
        
    }

     /**
     * @dev Forward funds to wallet. 
     * @param _DAIAmount - amount of DAI to be transferred to the campaign wallet
     * @param _weiAmount - amonunt of ETH to be transferred to the campaign wallet
     */
    function _forwardFunds(uint256 _DAIAmount, uint256 _weiAmount) internal {

        emit test(_DAIAmount, rate());
        if (_weiAmount > 0)
            _wallet.transfer(_weiAmount);
        else if (_DAIAmount > 0)
            IERC20(_DAI).safeTransfer(_wallet, 1000000000000000000);

        emit FundsForwarded(_weiAmount, _DAIAmount);

    }

    /**
     * @dev calculate amount of tokens for available DAI
     * @param DAIAmount - amount of DAI
     * @return amount of tokens to be sent to contributor 
     */
    function getTokenAmount(uint DAIAmount) public view returns(uint256){

            return DAIAmount.div(rate());
    }


    /**
     * @dev find out ETH/DAI price
     * @param amount - amount of ether to be checked against DAI 
     * @return amount of DAI
     */
    function calculateDAIForEther(uint256 amount) public view returns (uint256) {

       int256 price = _priceConsumerV3.getLatestPrice();
       return amount.mul(uint256(price)).div(1e8);
    }

    /**
     * dev calculate eth rate based on Oracle price aginst DAI
     */
    function calculateEthRate() public view returns (uint256){

       int256 price = _priceConsumerV3.getLatestPrice();
       return (rate().mul(1e8)).div(uint256(price));

    }


    /**
    * @notice overwrite parent to enforce onlyManager role for this call
    * @param newRate  new value for rate of token price in Wei.
     */
    function adjustRate(uint256 newRate) public onlyManager {
        super.adjustRate(newRate);
    }
}