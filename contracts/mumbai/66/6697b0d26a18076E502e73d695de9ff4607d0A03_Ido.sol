// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Admin {

    address public _governance;

    mapping(address => bool) admin; 

    constructor() {
        admin[msg.sender] = true; 
    }

    modifier onlyAdmin {
        require(admin[msg.sender],"not admin");
        _;
    }

    function setAdmin(address _address,bool _isAdmin) public onlyAdmin() {
        admin[_address]=_isAdmin;
    }



}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Admin.sol";
import "./IInvite.sol";

contract Ido is Ownable,Admin{
    
    using SafeMath for uint256;
    address usdt;
    address invite;
    IERC20 public _usdt = IERC20(usdt);
    IInvite public _invite = IInvite(invite);

    address public _teamWallet = 0x3D0a845C5ef9741De999FC068f70E2048A489F2b;
    uint256 public constant DURATION = 15 days;
    uint256 public _initReward = 2100000 * 1e18;
    uint256 public _startTime =  block.timestamp + 365 days;
    uint256 public _currentTime = block.timestamp;
    uint256 public _endTime = 0;
    uint256 public _rewardRate = 0;

    uint256 public _teamRewardRate = 500;
    uint256 public _baseRate = 10000;
    uint256 public _totalAmount = 0;
    
    mapping(address => uint256) public _userPower;
    mapping(address => mapping(uint256 => uint256)) public _userTodayPaid;
    mapping(address => uint256)  public _userTotalPaid;
    mapping(address => uint256)  public _directRewards; // 直推总奖励
    mapping(address => uint256)  public _directRewardsPaid; // 已支付直推奖励
    mapping(address => uint256)  public _teamRewards;   // 团队总奖励
    mapping(address => uint256)  public _teamRewardsPaid;   // 已支付团队总奖励

    bool public _hasStart = false;

    event Buyed(address indexed user, uint256 amount);

   
    constructor(address usdt_address,address invite_address)  {
        usdt = usdt_address;
        invite = invite_address; 
    }

    function buy(uint256 amount)
    public
    checkAmount(amount)
    checkDate
    {
        _totalAmount = _totalAmount.add(amount);
        uint _runningDay = runningDay();
        _userTodayPaid[msg.sender][_runningDay] = _userTodayPaid[msg.sender][_runningDay].add(amount);
        _userTotalPaid[msg.sender] = _userTotalPaid[msg.sender].add(amount);
        setUserPower(amount);
        distributeRewards(amount);
        //_usdt.transferFrom(msg.sender, address(this), amount);
        emit Buyed(msg.sender, amount);
    }

    modifier checkDate() {
        require(block.timestamp > _startTime, "ido not start");
        require(block.timestamp < _endTime, "ido is end");
        _;
    }

    modifier checkAmount(uint256 amount) {
        uint256 _runningDay = runningDay();
        require(amount == 100 ether || amount == 300 ether || amount == 500 ether || amount == 1000 ether || amount == 2000 ether, "amount is wrong");
        require(_userTodayPaid[msg.sender][_runningDay].add(amount) <= 2000 ether,"Exceeding the amount that can be participated today");
        _;
    }


    // set fix time to start reward
    function startIDO(uint256 startTime) onlyAdmin
    external
    {
        require(_hasStart == false, "has started");
        _hasStart = true;
        _startTime = startTime;
        _endTime = _startTime.add(DURATION);
    }

    function runningDay() public view returns (uint) {
        uint day = (block.timestamp - _startTime) / uint(86400) + 1;
        return day;
    }

    function  distributeRewards(uint256 amount) private {
        address [] memory parents = _invite.getParentList(msg.sender);
        for(uint i = 0;i< parents.length ;i ++){
            if(i == 0 && parents[i] != address(0)){
                _directRewards[parents[i]] = _directRewards[parents[i]].add(amount.mul(8).div(100));
            }else if(i == 1 && parents[i] != address(0)){
                _teamRewards[parents[i]] = _teamRewards[parents[i]].add(amount.mul(5).div(100));
            }else if(i == 2 && parents[i] != address(0)){
                _teamRewards[parents[i]] = _teamRewards[parents[i]].add(amount.mul(3).div(100));
            }else if(i == 3 && parents[i] != address(0)){
                _teamRewards[parents[i]] = _teamRewards[parents[i]].add(amount.mul(1).div(100));
            }else if(i >= 4 && parents[i] != address(0)){
                _teamRewards[parents[i]] = _teamRewards[parents[i]].add(amount.mul(5).div(1000));
            }
        }
    }

    function  getParents() public view returns(address[] memory) {
        address [] memory parents = _invite.getParentList(msg.sender);
        return parents;
    }

    function setUserPower(uint256 amount) private  {
        uint day = runningDay();
        uint power ;
        if(day <= 5 ){
            power = amount.mul(130).div(100);
        }else if ( day > 5 && day <= 10){
            power = amount.mul(120).div(100);
        }else if (day > 10 && day <= 15){
            power = amount.mul(110).div(100);
        }else{
            power = amount;
        }
        _userPower[msg.sender] = _userPower[msg.sender].add(power);
    }


    function withdrawUsdt() external onlyAdmin {
        _usdt.transfer(msg.sender,_usdt.balanceOf(address(this)));
    }

    function claimDirectRewards() public {
        require(_directRewards[msg.sender] >= 10 ether, "Rewards are not enough to claim");
        uint256 rewards = _directRewards[msg.sender];
        _directRewards[msg.sender] = 0;
        _directRewardsPaid[msg.sender] = _directRewardsPaid[msg.sender].add(rewards); 
        _usdt.transfer(msg.sender,rewards);
    }

    function claimTeamRewards() public {
        require(_directRewards[msg.sender] >= 10 ether, "Rewards are not enough to claim");
        uint256 rewards = _teamRewards[msg.sender];
        _teamRewards[msg.sender] = 0;
        _teamRewardsPaid[msg.sender] = _teamRewardsPaid[msg.sender].add(rewards); 
        _usdt.transfer(msg.sender,rewards);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IInvite  {
    function bind(address account, address parentAccount) external ;
    function getParent(address account) external view returns(address);
    function getParentList(address account) external view returns(address[] memory);
    function getSubNum(address account) external view returns(uint256);
    function getSubList(address account) external view returns(address[] memory);
    function getSubPage(address account, uint256 start, uint256 size) external view returns(address[] memory);
}