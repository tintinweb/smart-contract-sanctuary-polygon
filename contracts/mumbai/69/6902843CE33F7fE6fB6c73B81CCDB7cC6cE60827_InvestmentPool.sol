// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InvestmentPoolFactoryInterface.sol";
import "../utils/Constants.sol";

contract InvestmentPool is Ownable {
    using SafeMath for uint256;

    address public poolManagerAddress;
    uint256 public exchangeRatio;
    uint256 public startTimestamp;
    uint256 public maxSupply;
    uint256 public minContribution;
    uint256 public contributionFee;
    uint256 public currentValue; // Current value in USDC
    uint256 public poolDuration;
    InvestmentPoolFactoryInterface public investmentPoolFactory;

    InvestmentPoolStatus public poolStatus = InvestmentPoolStatus.CLOSED;


    struct Investment {
        address _investorAddress;
        address _referralAddress;
        uint256 _baseAmount; // IUX
        uint256 _quoteAmount; // USDC
        uint256 _totalValue; // In USDC
        uint256 _contributionFee;
        uint256 _rewardsPaid;
        uint256 _affiliateRewardsPaid;
        uint256 _createdTime;
        Yield _yield;
        bool _processed;
    }

    uint256 public yieldIndex;
    struct Yield {
        uint256 _apr;
        uint256 _referralApr;
        uint256 _rewardLockingTime;
        uint256 _principalVestingDuration;
        uint256 _principalVestingReleaseBP;
        bool _open;
    }


    Investment[] public investments;
    uint256 public investmentIndex;
    Yield[] public yields;

    modifier onlyPoolManager() {
        require(
            poolManagerAddress == msg.sender,
            "Only the pool manager call this function"
        );
        _;
    } 

    modifier onlyOpenPool() {
        require(
            (poolStatus == InvestmentPoolStatus.OPEN),
            "You can only make investments if the pool is open"
        );
        _;        
    }

    constructor(
        address _poolManagerAddress,
        uint256 _exchangeRatio,
        uint256 _startTimestamp,
        uint256 _maxSupply,
        uint256 _minContribution,
        uint256 _contributionFee,
        uint256 _poolDuration
    ) {
        poolManagerAddress = _poolManagerAddress;
        exchangeRatio = _exchangeRatio;
        startTimestamp = _startTimestamp;
        maxSupply = _maxSupply;
        minContribution = _minContribution;
        contributionFee = _contributionFee;
        poolDuration = _poolDuration;
        investmentPoolFactory = InvestmentPoolFactoryInterface(msg.sender);
    }   

    function addYield(
        uint256 _apr,
        uint256 _referralApr,
        uint256 _rewardLockingTime,
        uint256 _principalVestingDuration,
        uint256 _principalVestingReleaseBP
    ) public onlyPoolManager {
        Yield memory yield = Yield(
            _apr,
            _referralApr,
            _rewardLockingTime,
            _principalVestingDuration,
            _principalVestingReleaseBP,
            true
        );
        yields.push(yield);
        yieldIndex++;
    }

    function updateYieldStatus(
        uint256 _yieldIndex,
        bool _yieldOpen
    ) public onlyPoolManager {
        Yield memory yield = yields[_yieldIndex];
        yield._open = _yieldOpen;
        yields[_yieldIndex] = yield;
    }

    function changeInvestmentPoolStatus(InvestmentPoolStatus _poolStatus) external onlyPoolManager {
        poolStatus = _poolStatus;
    }
    
    function createInvestment(
        uint8 _yieldIndex, 
        uint256 _quoteAmount) external onlyOpenPool {
        Yield memory yield = yields[_yieldIndex];
        require(yield._open, "Yield is not open or configured");
        require(_quoteAmount >= minContribution, "Minimum contribution not satisfied");
        require(currentValue.add(_quoteAmount) >= maxSupply, "Max supply was reached");

        uint256 _investmentValue = _quoteAmount.add(_quoteAmount.mul(exchangeRatio).div(BASIS_POINT)); // Investment amount in USDC
        uint256 _baseAmount = investmentPoolFactory.getQuoteToBase(_quoteAmount);
        _baseAmount = _baseAmount.mul(exchangeRatio).div(BASIS_POINT);

        uint256 _contributionFee = _investmentValue.mul(contributionFee).div(BASIS_POINT);        

        investmentPoolFactory.claimTokens(msg.sender, _baseAmount, _quoteAmount.add(_contributionFee));
        address _referralAddress = investmentPoolFactory.getReferral(msg.sender);

        Investment memory _investment = Investment(
            msg.sender,
            _referralAddress,
            _baseAmount,
            _quoteAmount,
            _investmentValue,
            _contributionFee,
            0,
            0,
            block.timestamp,
            yield,
            false
        );
        investments.push(_investment);
        investmentIndex++;
        currentValue = currentValue.add(_quoteAmount);
        if (currentValue == maxSupply) {
            poolStatus = InvestmentPoolStatus.COMPLETED;
        }
    }    

    function calculateAffiliateRewards(uint256 _investmentIndex) public view returns (uint256 _affiliateRewardAmount) {
        Investment memory investment = investments[_investmentIndex];
        if (investment._referralAddress == address(0)) {
            return 0;
        }
        Yield memory yield = investment._yield;
        uint256 elapsedTime = block.timestamp.sub(investment._createdTime);
        _affiliateRewardAmount = (investment._totalValue.mul(elapsedTime).div(SECONDS_IN_YEAR).mul(yield._referralApr).div(BASIS_POINT)).sub(investment._affiliateRewardsPaid);
        return _affiliateRewardAmount;
    }

    function retrieveAffiliateRewards(uint256 _investmentIndex) external {
        Investment memory investment = investments[_investmentIndex];
        require(investment._referralAddress != address(0),"Investment doesn't have referral");
        uint256 retrievable = calculateAffiliateRewards(_investmentIndex);
        if (retrievable > 0) {
            investmentPoolFactory.payAffiliateRewards(investment._referralAddress,retrievable);
            investment._affiliateRewardsPaid = investment._affiliateRewardsPaid.add(retrievable);
        }
    }

    function calculateRetrievable(uint256 _investmentIndex) public view returns (uint256 _retrievableAmount) {
        Investment memory investment = investments[_investmentIndex];
        Yield memory yield = investment._yield;
        uint256 rewardReleaseTime = investment._createdTime.add(yield._rewardLockingTime);
        if (rewardReleaseTime > block.timestamp) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp.sub(investment._createdTime);
        _retrievableAmount = (investment._totalValue.mul(elapsedTime).div(SECONDS_IN_YEAR).mul(yield._apr).div(BASIS_POINT)).sub(investment._rewardsPaid);
        return _retrievableAmount;
    }

    function retrieveRewards(uint256 _investmentIndex) external {
        Investment memory investment = investments[_investmentIndex];
        uint256 retrievable = calculateRetrievable(_investmentIndex);
        investmentPoolFactory.payRewards(investment._investorAddress,retrievable);
        investment._rewardsPaid = investment._rewardsPaid.add(retrievable);
    }

    function calculateElapsedTime(uint256 _investmentIndex) public view returns (uint256 _elapsedTime) {
        Investment memory investment = investments[_investmentIndex];
        Yield memory yield = investment._yield;
        uint256 rewardReleaseTime = investment._createdTime + yield._rewardLockingTime;
        if (rewardReleaseTime > block.timestamp) {
            return 0;
        }

        _elapsedTime = block.timestamp.sub(investment._createdTime);        
        return _elapsedTime;
    }

    function previewInvestment(uint256 _quoteAmount) public view returns (uint256 quoteAmount, uint256 baseAmount) {
        baseAmount = investmentPoolFactory.getQuoteToBase(_quoteAmount);
        baseAmount = baseAmount.mul(exchangeRatio).div(BASIS_POINT);    

        uint256 _investmentValue = _quoteAmount.add(_quoteAmount.mul(exchangeRatio).div(BASIS_POINT)); // Investment amount in USDC    
        uint256 _contributionFee = _investmentValue.mul(contributionFee).div(BASIS_POINT);        
        return (
            _quoteAmount.add(_contributionFee),
            baseAmount
        );
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.14;

interface InvestmentPoolFactoryInterface {
    function getQuoteToBase(uint256 _quoteAmount) external view returns(uint256 _baseAmount);
    function claimTokens(address _investorAddress, uint256 _baseAmount, uint256 _quoteAmount) external;
    function getReferral(address _investorAddress) external view returns (address parentAddress);
    function payRewards(address _investorAddress, uint256 _amount) external;
    function payAffiliateRewards(address _referralAddress, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
uint256 constant BASIS_POINT = 10000;
uint256 constant WEI_IN_ETHER = 1000000000000000000;
uint256 constant SECONDS_IN_YEAR = 60 * 60 * 24 * 365;
enum InvestmentPoolStatus {
    CLOSED,
    OPEN,
    COMPLETED
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