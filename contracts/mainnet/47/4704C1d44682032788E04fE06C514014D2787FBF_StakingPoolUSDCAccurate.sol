/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT

// 
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


interface IBEP20Mintable {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external returns (bool);
    function burnFrom(address who, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// 
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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract StakingPoolUSDCAccurate is Ownable{
    
    using SafeMath for uint256;
    bool public fundsAreSafu = true; // always 
    IBEP20 public poolToken;
    IBEP20Mintable public returnPoolToken;
    uint256 public totalStaked;


    event Deposit(uint256 _amount, uint256 _time);
    event BoosterDeposit(uint256 _amount, uint256 _time);
    event WithdrawalRequest(address indexed user, uint256 _amount, uint256 _time);

    struct Account {
        uint256 balance;
        uint256 blockDeposited;
        uint256 blockWithdrawal;
        uint256 earningEstimated; // every block is 0.000000754830917874% 
        uint256 booster; // how much boost return (100 is 1%, 200 2%, etc)
    }
    mapping(address => Account) public deposits;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public requests;

    constructor(IBEP20 _addr, IBEP20Mintable _addr2) public {
        poolToken = _addr;
        returnPoolToken = _addr2;
    }

    uint256 public valueRate = 754830917874; //  3019323671497

    function whitelistBlacklist(address _addr, bool _status) public onlyOwner{
        whitelist[_addr] = _status;
    }

    function changeValueRate(uint256 _newVal) public onlyOwner {
        valueRate = _newVal;
    }

    function deposit(uint256 _amount) public {
        require(whitelist[msg.sender] == true, "Accurate: not whitelisted. If you KYCd contact us");
        require(poolToken.allowance(msg.sender, address(this)) >= _amount, "not allowed");
        // require(_amount >= 250000000, "min investment not met");
        require(_amount >= 1, "min investment not met");
        deposits[msg.sender].blockDeposited = block.number;
        // on Matic there are 43200 blocks a day, as there is one block every 2 seconds
        // we want to lock funds for 92 days (3 months), 43200 x 92 = 3974400
        deposits[msg.sender].blockWithdrawal = block.number.add(3974400);
        poolToken.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].balance = deposits[msg.sender].balance.add(_amount);

        uint256 boostAmount = boost(deposits[msg.sender].balance);
        deposits[msg.sender].booster = boostAmount;
        returnPoolToken.mint(msg.sender, _amount);
        totalStaked = totalStaked.add(_amount);
        emit Deposit(_amount, block.number);
    }

    function satisfyRequest(address _user) public onlyOwner {
        uint256 _amount = requests[msg.sender];
        requests[msg.sender] = 0;
        poolToken.transferFrom(msg.sender, _user, _amount);
        returnPoolToken.burnFrom(_user, _amount);
        totalStaked = totalStaked.sub(_amount);
    }

    function withdraw(uint256 _amount) public {
        require(whitelist[msg.sender] == true, "Accurate: not whitelisted. If you KYCd contact us");
        uint256 withdrawalTime = deposits[msg.sender].blockWithdrawal;
        require(block.number <= withdrawalTime, "Accurate: not withdrawal time");
        require(returnPoolToken.allowance(msg.sender, address(this)) >= _amount, "not allowed");
        uint256 userDeposit = deposits[msg.sender].balance;
        require(_amount <= userDeposit, "you can't withdraw more than your balance");
        poolToken.transferFrom(msg.sender, address(this), _amount);
        (,, uint256 earnings) = checkEarningsCummulative(msg.sender);
        uint256 toReturn = _amount.mul(earnings);
        requests[msg.sender] = requests[msg.sender].add(_amount);
        emit WithdrawalRequest(msg.sender, toReturn, block.number);

    }

    function adminWithdraw(uint256 _amount) public onlyOwner {
        poolToken.transfer(msg.sender, _amount);
    }

    function boost(uint256 _amount) internal pure returns(uint256){
        if(_amount < 5000000000) {
            return 0;
        } else {
            if(_amount >= 5000000000 && _amount < 50000000000){
                return 100; // 1% 
            }else {
                if(_amount >= 50000000000 && _amount < 500000000000){
                    return 300; // 3%
                } else {
                    // amounts above 500k 
                    return 600;
                }
            }
        }
    }

    function checkEarningsNormal(address earner) public view returns(uint256) {
        uint256 currentBlock = block.number;
        uint256 depositBlock = deposits[earner].blockDeposited;
        if(depositBlock >0){
        uint256 difference = currentBlock.sub(depositBlock);
        return (difference.mul(valueRate)); // divide by 1e18 to get in decimals 
        } else {
            return 0;
        }

    }
    
    function checkPercentageBooster(address earner) public view returns(uint256){
        return deposits[earner].booster;
    }

    function checkEarningsCummulative(address earner) public view returns(uint256, uint256, uint256){
        uint256 currentBlock = block.number;
        uint256 depositBlock = deposits[earner].blockDeposited;
        if(depositBlock > 0){
                    uint256 difference = currentBlock.sub(depositBlock);
        uint256 totalNoBooster = difference.mul(valueRate);
        uint256 boosterPercentage = checkPercentageBooster(earner);
        uint256 bootsterEarnings = 0;
        if(boosterPercentage > 0){
            bootsterEarnings = totalNoBooster.mul(boosterPercentage).div(10000);
        }
        uint256 total = totalNoBooster.add(bootsterEarnings);
        return (totalNoBooster, bootsterEarnings, total);
        } else {
            return (0,0,0);
        }

    }
}