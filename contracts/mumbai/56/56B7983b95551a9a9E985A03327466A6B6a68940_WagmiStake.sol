/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// File: wagmi staking/SafeMath.sol

/**
 * SPDX-License-Identifier: MIT
 */ 

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

// File: wagmi staking/Context.sol


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
// File: wagmi staking/Ownable.sol


pragma solidity ^0.8.0;


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
// File: wagmi staking/wagmi_staking.sol


pragma solidity ^0.8.17;



abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * BEP20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WagmiStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

	struct TPlan {
		uint256 durationDays;
		uint256 investFactor;
	}

	struct TDeposit {
		uint256 planIdx;
		uint256 amount;
		uint256 timeStart;
		uint256 timeEnd;
		uint256 profit;
		uint256 checkpoint;
		uint256 depositIdx;
        uint256 claimedRewards;
		bool isDeceased;
	}

	struct TUser {
		TDeposit[] deposits;
		uint256 totalInvested;
		uint256 totalClaimed;
        uint256 totalCompounded;
	}

	mapping( address => TUser ) public users;
	TPlan[] public plans;

    // uint256 public constant TIME_STEP = 1 days;
    uint256 public constant TIME_STEP = 1 minutes; // test time step
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant SECONDS_IN_YEAR = 31536000;

    uint256 public totalDepositNo;
	uint256 public totalInvested;
	uint256 public totalClaimed;
    uint256 public totalCompounded;

    bool public launched;
    address public stakingAddress = 0xbc1A73883cF8DF902810C0140AD63f8f3CB1bf73;

    IERC20 stakingToken = IERC20(stakingAddress);

	event Claimed(address user, uint256 amount,  uint256 claimedTime);
    event Compounded(address user, uint256 amount, uint256 compoundedTime);
	event NewDeposit(address user, uint256 planIdx, uint256 amount);
    event ERC20TokensRemoved(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor(){
        // // unlocked plans
        // plans.push( TPlan(75, 35 ) ); // 3.5%
        // // locked plans
		// plans.push( TPlan(30, 40 ) ); // 4%
        // plans.push( TPlan(90, 65 ) ); // 6.5
        // plans.push( TPlan(365, 100 ) ); // 10%

        //Test Plans @dev
        // unlocked plans
        plans.push( TPlan(7, 35 ) ); // 3.5%
        // locked plans
		plans.push( TPlan(10, 40 ) ); // 4%
        plans.push( TPlan(20, 65 ) ); // 6.5
        plans.push( TPlan(25, 100 ) ); // 10%
    }


    function launch()
		external
		onlyOwner()
	{
		launched = true;
	}

    /**
     * add stake token to staking pool
     * @dev requires the token to be approved for transfer
     * @dev we assume that (our) stake token is not malicious, so no special checks
     * @param _amount of token to be staked
     */

    function lockup(uint256 _amount, uint8 _planIdx) external nonReentrant {
        require (launched, "Project is not launched.");
        require(_amount > 0, "Deposit amount can't be zero");
        require(_planIdx < plans.length, "Invalid plan index");

        // Transfer the tokens for staking
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        _createDeposit( msg.sender, _planIdx, _amount);

	}

    function _createDeposit(address _user, uint256 _planIdx, uint256 _amount)
		internal
		returns(uint256 o_depIdx)
	{

		TUser storage user = users[_user];
		TDeposit memory newDep;

		(uint256 profit) = _getResult(_planIdx, _amount);

		o_depIdx = user.deposits.length;
		newDep = TDeposit(
			_planIdx,
			_amount,
			block.timestamp,
			block.timestamp + plans[_planIdx].durationDays * TIME_STEP,
			profit,
			block.timestamp,
			o_depIdx,
            0,
			false
			);

		user.deposits.push(newDep);

		user.totalInvested += _amount;
		totalDepositNo++;
		totalInvested += _amount;

		emit NewDeposit(_user, newDep.planIdx, newDep.amount);
	}


    /**
     * Withdraw staked funds from the contract
     * @dev must be called only when `block.timestamp` >= `lockupPeriod`
     * @dev `block.timestamp` higher than or equal to `lockupPeriod` (lockupPeriod finished)
     */

    
    function withdraw(uint256 depIdx) public nonReentrant{
       unlock(depIdx);
    }

    function unlock (uint256 depIdx) private {
        TUser storage user = users[msg.sender];

		uint256 planIdx = user.deposits[depIdx].planIdx;
        uint256 lockupPeriod = user.deposits[depIdx].timeEnd;
        uint256 depositAmount = user.deposits[depIdx].amount;
        
        // Locked Packages
        if(planIdx >= 1){
            require(block.timestamp >= lockupPeriod,  "No withdraw until lockup ends");
        }
        
        require(user.deposits[depIdx].isDeceased == false, "deposit is deceased");

		(uint256 claimAmount_, uint256 checkpoint_) = _calculateDepositDividends(msg.sender, depIdx);
      
        user.deposits[depIdx].checkpoint = checkpoint_;
		user.deposits[depIdx].isDeceased = true;
        user.deposits[depIdx].claimedRewards = claimAmount_;

        uint256 withdrawableAmount = depositAmount.add(claimAmount_);

        uint256 balance = getContractBalance();
		if (withdrawableAmount > balance) {
			withdrawableAmount = balance;
		}
        require(withdrawableAmount > 0, "Nothing to withdraw");

        
        user.totalClaimed += withdrawableAmount;
		totalClaimed += withdrawableAmount;

        // Send user amount staked tokens + rewards
        stakingToken.transfer(msg.sender, withdrawableAmount);

		emit Claimed(msg.sender, withdrawableAmount, block.timestamp );
    }


     /**
     * claim reward tokens for accumulated reward credits
     * ... but do not unstake staked token
     */

    function claim(uint256 depIdx) public nonReentrant{
        TUser storage user = users[msg.sender];
        uint256 lockupPeriod = user.deposits[depIdx].timeEnd;
        uint256 claimAmount;

        // if it is passed the lockup period, then unstake deposit and rewards
        if(block.timestamp >= lockupPeriod){
                unlock(depIdx);
        }
        else{
            (uint256 claimAmount_, uint256 checkpoint_) = _calculateDepositDividends(msg.sender, depIdx);
            require(claimAmount_ > 0, "Claim Amount must be greater than zero");
            require(checkpoint_ > 0, "Checkpoint time must be greater than zero");
            
            updateCheckPoint(msg.sender, depIdx, checkpoint_);
            claimAmount =  claimAmount_;
            uint256 balance = getContractBalance();

            if (claimAmount > balance) {
                claimAmount = balance;
            }

            user.deposits[depIdx].claimedRewards = claimAmount;
            user.totalClaimed += claimAmount;
            totalClaimed += claimAmount;

            stakingToken.transfer(msg.sender, claimAmount);

            emit Claimed(msg.sender, claimAmount,block.timestamp );
        }
        
    }

    function compoundDividends(uint256 depIdx) external nonReentrant{
        TUser storage user = users[msg.sender];
        uint256 lockupPeriod = user.deposits[depIdx].timeEnd;
        uint256 amountLocked = user.deposits[depIdx].amount;

        require(block.timestamp < lockupPeriod, "Passed the lockup period");

        (uint256 claimAmount_, uint256 checkpoint_) = _calculateDepositDividends(msg.sender, depIdx);
        require(claimAmount_ > 0, "Claim Amount must be greater than zero");
        require(checkpoint_ > 0, "Checkpoint time must be greater than zero");

        updateCheckPoint(msg.sender, depIdx, checkpoint_);
      
        // compound the claimed amount
        user.deposits[depIdx].amount = amountLocked + claimAmount_;
        user.deposits[depIdx].claimedRewards = claimAmount_;

        user.totalClaimed += claimAmount_;
        totalClaimed += claimAmount_;

        user.totalCompounded += claimAmount_;
        totalCompounded += claimAmount_;

        emit Compounded(msg.sender, claimAmount_,block.timestamp);
    }

    function updateCheckPoint(address addr, uint256 deptId, uint256 checkPoint)
		internal
	{
		TUser storage user = users[addr];

		user.deposits[deptId].checkpoint = checkPoint;

		if(checkPoint >= user.deposits[deptId].timeEnd)
			user.deposits[deptId].isDeceased = true;
	}

    function _isDepositDeceased(TUser memory user_, uint256 depositIndex) internal pure returns(bool) {
		TDeposit memory userDeposits = user_.deposits[depositIndex];

		return (userDeposits.checkpoint >= userDeposits.timeEnd);
	}

    function _getResult(
		uint256 planIdx,
		uint256 amount
	)
		private
		view
		returns
		(
			uint256 profit
		)
	{
		TPlan memory plan = plans[planIdx];

		uint256 factor = plan.investFactor;

		profit = amount.div(PERCENTS_DIVIDER).mul(factor);
	}

    function _calculateDepositDividends(address _user, uint256 _depIdx) 
    public view returns (uint256 o_amount, uint256 checkPoint) {
		TUser storage user = users[_user];

		TDeposit storage deposit = user.deposits[_depIdx];

        uint256 _planIdx = deposit.planIdx;

        uint256 lockedAmount = deposit.amount;
        uint256 stakingDuration = block.timestamp - deposit.timeStart;
        uint256 lastClaimedDuration = block.timestamp - deposit.checkpoint;

        if (stakingDuration <= lastClaimedDuration) {
             o_amount = 0;
        }
        else{
            (uint256 interest) = _getResult(_planIdx, lockedAmount);
            uint256 rewardAmount = interest * (stakingDuration - lastClaimedDuration) / SECONDS_IN_YEAR;
            uint256 claimedAmount = deposit.claimedRewards;

            if (rewardAmount > claimedAmount) {
                o_amount =  rewardAmount - claimedAmount;
            } else {
                o_amount =  0;
            }
        }
        checkPoint = block.timestamp;
	}

     /**
     * @notice withdraw accidently sent ERC20 tokens
     * @param _tokenAddress address of token to withdraw
     */
    function removeOtherERC20Tokens(address _tokenAddress) external onlyOwner() {
        require(_tokenAddress != address(stakingToken), "can not withdraw staking token");
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
        emit ERC20TokensRemoved(_tokenAddress, msg.sender, balance);
    }


    function getPackageInfo(uint256 index_) external view returns(TPlan memory) {
		return plans[index_];
	}

	function getProjectInfo()
		external
		view
		returns(
			uint256 o_totDeposits,
			uint256 o_totInvested,
			uint256 contractBalance,
			uint256 o_timestamp
		)
	{
		return( totalDepositNo, totalInvested, getContractBalance(), block.timestamp );
	}

     /**
     * @return balance of reward tokens held by this contract
     */
    function getContractBalance() public view returns (uint256 balance) {
        if (stakingAddress == address(0)) return 0;
        balance = stakingToken.balanceOf(address(this));
    }

    function getUserDeposits(address _user)
		external
		view
		returns(TDeposit[] memory)
	{
		TUser storage user = users[_user];

		return user.deposits;
	}

	function getUserInfo(address _user)
		external
		view
		returns(
			uint256 stakedAmount,
			uint256 availableAmount
		)
	{
		TUser storage user = users[_user];


		stakedAmount = user.totalInvested;

		uint256 claimAmount;

		for(uint256 i = 0; i < user.deposits.length; i++) {
			if(_isDepositDeceased(user,i)) continue;
			// if(user.deposits[i].planIdx >= 1) continue; // remove this line

			(uint256 claimAmount_, uint256 checkpoint_) = _calculateDepositDividends(_user,i);

			if(claimAmount_ <= 0) continue;
			if(checkpoint_ <= 0) continue;

			claimAmount += claimAmount_;
		}

		availableAmount = claimAmount;
	}

    function getCurrentTime() public view returns(uint256){
		return block.timestamp;
	}

}