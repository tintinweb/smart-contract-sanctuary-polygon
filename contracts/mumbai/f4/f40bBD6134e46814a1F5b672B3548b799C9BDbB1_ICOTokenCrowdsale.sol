// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract ICOTokenCrowdsale is ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;
    IERC20 internal _token;
    IERC20 internal _usdc;
    IERC20 internal _usdt;
    
    bool public crowdsaleFinalized;     // token sale status
    uint256 private _icoCap;            // ico max limit
    uint256 public soldTokens;          // Amount of tokens sold
    uint256 public weiRaised;           // Amount of wei raised
    uint256 public usdRaised;           // Amount of usd raised    

    address payable private _wallet;    // Address where funds are collected
    uint256 private _rate;              // wei rate of token    
    uint256 private _usdRate;           // usd rate of token
    uint256 public lockPeriod;          // token Lock period
    
    mapping(address => uint256) public totalTokensPurchased;
    mapping(address => uint256) public claimCount;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event paymentProccessed(address receiver, uint256 amount, bytes info);
    
    constructor (uint256 rate_,uint256 usdRate ,address token_, uint256 icocap_, 
        address usdc, address usdt, address adminWallet, uint256 lockPeriod_) Ownable()
    {
        _rate = rate_;
        _usdRate = usdRate;
        _wallet = payable(adminWallet);
        _token = IERC20(token_);
        _usdc = IERC20(usdc);
        _usdt = IERC20(usdt);
        crowdsaleFinalized = false;
        _icoCap = icocap_;
        lockPeriod = lockPeriod_;
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return bool after setting the address where funds are collected.
     */ 
    function setWallet(address payable wallet_)public onlyOwner returns(bool) {
        require(wallet_ != address(0),"Invalid minter address!");
        _wallet = wallet_;
        return true;
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

    function updateRate(uint256 rate_)public onlyOwner{
        _rate = rate_;
    }

    function updateUsdRate(uint256 rate_)public onlyOwner{
        _usdRate = rate_;
    }

    function updateLockPeriod(uint256 lockPeriod_)public onlyOwner{
        require(block.timestamp < lockPeriod, "Can not update lock period once it is passed");
        lockPeriod = lockPeriod_;
    }
    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        
        require(!crowdsaleFinalized,"Crowdsale is finalized!");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(msg.value != 0, "Crowdsale: weiAmount is 0");
        
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount, true);

        weiRaised = weiRaised.add(weiAmount);
        _processPayment(_wallet, msg.value);
        _processPurchase(beneficiary, tokens);
        
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    }

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param usdAmount_ amount of usdc or usdt tokens used to buy floyx.
     * @param usdc boolean variable to check payment will be in usdc or usdt
     */
    function buyTokenswithUsd(address beneficiary, uint256 usdAmount_,bool usdc, bool usdt) public nonReentrant {
        require(usdc != usdt , "Crowdsale: One of the value should be passed true");
        require(usdAmount_ > 0 , "Crowdsale: UsdAmount is 0");
        require(!crowdsaleFinalized,"Crowdsale is finalized!");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");

        uint256 tokens = _getTokenAmount(usdAmount_, false);
        usdRaised = usdRaised.add(usdAmount_);

        usdc ? _usdc.transferFrom(msg.sender, address(this), usdAmount_) : _usdt.transferFrom(msg.sender, address(this), usdAmount_);
        _processPurchase(beneficiary, tokens);
        
        emit TokensPurchased(msg.sender, beneficiary, usdAmount_, tokens);
    }

    function claimTokens()public{
        require(block.timestamp > lockPeriod, "Crowdsale: Can not claim during lock period");
        require(claimCount[msg.sender] < 13, "Crowdsale: No more claims left");

        // uint256 monthDiff = (block.timestamp.sub(lockPeriod)).div(30 days);
        uint256 monthDiff = (block.timestamp.sub(lockPeriod)).div(3600);
        require(monthDiff > claimCount[msg.sender], "Crowdsale: Nothing to claim yet");
        if (monthDiff > 12){ monthDiff = 12;}

        for(uint i = claimCount[msg.sender]; i < monthDiff; i ++){
            claimCount[msg.sender] += 1;
            _token.transfer(msg.sender, (totalTokensPurchased[msg.sender].mul(6).div(100)));
        }

        if (claimCount[msg.sender] == 12 && monthDiff == 12){
            claimCount[msg.sender] += 1;
            _token.transfer(msg.sender, (totalTokensPurchased[msg.sender].mul(8).div(100)));
        }
        
    }
    
    function finalizeCrowdsale() public onlyOwner{
        require(!crowdsaleFinalized,"Crowdsale: Crowdsale is finalized!");
        crowdsaleFinalized = true;
    }
    
    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        require(soldTokens.add(tokenAmount) <= _icoCap , "ICO limit reached");
        
        soldTokens = soldTokens.add(tokenAmount);
        _token.transfer(beneficiary, (tokenAmount.mul(20).div(100)));
        totalTokensPurchased[beneficiary] = tokenAmount;
    }
    
    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param amount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 amount, bool eth) internal view returns (uint256) {
        
        return eth ? (amount.mul(_rate)).div(1e10) : (amount.mul(_usdRate)).div(1e10); 
    }
    
    /**
     * @dev Determines how MATIC is forwarded to admin.
     */
    function adminMaticWithdrawal(uint256 amount_) public onlyOwner {
        _processPayment(_wallet, amount_);
    }

    function adminFloyxWithdrawal(uint256 _amount)public onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Contract does not have enough balance");
        _token.transfer(msg.sender, _amount);
    }

    function adminUsdcWithdrawal(uint256 _amount)public onlyOwner {
        require(_usdc.balanceOf(address(this)) >= _amount, "Contract does not have enough balance");
        _usdc.transfer(msg.sender, _amount);
    }

    function adminUsdtWithdrawal(uint256 _amount)public onlyOwner {
        require(_usdt.balanceOf(address(this)) >= _amount, "Contract does not have enough balance");
        _usdt.transfer(msg.sender, _amount);
    }
    /**
     * @dev function to transfer matic to recepient account
     */
    function _processPayment(address payable recepient, uint256 amount_)private{
        
        (bool sent, bytes memory data) = recepient.call{value: amount_}("");
        require(sent, "Failed to send Ether");
        
        emit paymentProccessed(recepient, amount_, data);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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