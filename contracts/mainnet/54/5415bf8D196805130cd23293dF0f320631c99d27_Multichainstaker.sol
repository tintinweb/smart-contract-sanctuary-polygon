// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LastStand.sol";

contract Multichainstaker {
	using SafeMath for uint256;

	LastStand public lastStand;


	uint constant public INVEST_MIN_AMOUNT = 25 ether;
	uint constant public MINIMAL_WITHDRAW = INVEST_MIN_AMOUNT / 2;
	uint[3] public REFERRAL_PERCENTS = [30, 20, 5];
	uint constant public PERCENT_STEP = 5;
	uint constant public WITHDRAW_FEE = 100;
	uint constant internal FORCE_WITHDRAW_PERCENT = 700;
	uint constant public PERCENTS_DIVIDER = 1000;
	uint constant public TIME_STEP = 1 days;
	
	uint constant public MARKETING_FEE = 55;
	uint constant public OWNERS_FEE = 5;
	uint constant public DEV_DEE = 40;
	uint constant public POOL_FEE = 50;

	uint constant public PROJECT_FEE = 50;


	uint public totalStaked;
	uint public totalUsers;
	uint public totalWithdrawn;
	uint public totalDeposits;
	uint public totalRefBonus;

	struct Plan {
		uint256 time;
		uint256 percent;
	}

	Plan[] public plans;

	struct Deposit {
		uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint forceDeposit;
		uint256 totalWithdrawn;

	}

	mapping (address => User) public users;

	uint256 public startUNIX;
	address public marketingAddress;
	address public devAddress;
	address public projectAddress;
	address public ownersAddress;

	bool public poolIsActive = true;


	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event ForceWithdraw(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event Unpaused(address account, uint timestamp);

	constructor(address _marketing, address _project, address _ownersAddress, address _lastStand) {
		devAddress = msg.sender;
		marketingAddress = _marketing;
		projectAddress = _project;
		ownersAddress = _ownersAddress;
		lastStand = LastStand(_lastStand);
		plans.push(Plan(14, 104));
		plans.push(Plan(21, 97));
		plans.push(Plan(28, 90));
		plans.push(Plan(14, 104));
		plans.push(Plan(21, 97));
		plans.push(Plan(28, 90));
	}

	modifier onlyOwner() {
		require(devAddress == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	modifier whenNotPaused() {
		require(startUNIX > 0, "Pausable: paused");
		_;
	}

	modifier whenPaused() {
		require(startUNIX == 0, "Pausable: not paused");
		_;
	}

	function unpause() external whenPaused onlyOwner{
		startUNIX = block.timestamp;
		emit Unpaused(msg.sender, block.timestamp);
	}

	function isPaused() external view returns(bool) {
		return (startUNIX == 0);
	}

	function payHandler(address _wallet, uint _amount) internal {
		payable(_wallet).transfer(_amount);
	}

	function invest(address referrer, uint8 plan) public payable whenNotPaused {
		require(block.timestamp > startUNIX, "We are not live yet!");
		require(msg.value >= INVEST_MIN_AMOUNT, "Minimum investment is 0.1");
		//require(msg.value <= INVEST_MAX_AMOUNT, "You can not invest more than 10000 at once");
		require(plan < 6, "Invalid plan");

		User storage user = users[msg.sender];
		//uint toOwners = msg.value.mul(INVEST_FEE).div(PERCENTS_DIVIDER);
		uint toDev = msg.value.mul(DEV_DEE).div(PERCENTS_DIVIDER);
		uint toMarketing = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		uint toPool = msg.value.mul(POOL_FEE).div(PERCENTS_DIVIDER);
		uint toOwners = msg.value.mul(OWNERS_FEE).div(PERCENTS_DIVIDER);

		payHandler(devAddress, toDev);
		payHandler(marketingAddress, toMarketing);
		payHandler(ownersAddress, toOwners);

		if(poolIsActive) {
			lastStand.deposit{value: toPool}(msg.sender);
		} else {
			 payHandler(projectAddress, toPool);
		}
		emit FeePayed(msg.sender, toDev + toMarketing + toPool);

		if (user.referrer == address(0)) {
			if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline;
			if(user.referrer == address(0)) {
				upline = projectAddress;
			} else {
				upline = user.referrer;
			}
			for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers++;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalDeposits++;
		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function forceWithdraw() public whenNotPaused {
		User storage user = users[msg.sender];
		require(user.totalWithdrawn == 0, "forceWithdraw disabled");

		uint256 totalAmount;
		uint toFee;

		for (uint256 i = user.forceDeposit; i < user.deposits.length; i++) {
			if (user.deposits[i].start > user.checkpoint && user.checkpoint < user.deposits[i].finish) {
				uint _amount = user.deposits[i].amount.mul(FORCE_WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
				toFee += user.deposits[i].amount.sub(_amount);
				totalAmount += _amount;
			}
		}
		require(totalAmount > 0, "You have no have dividends to withdraw");
		uint256 contractBalance = getContractBalance();
		if(contractBalance < totalAmount + toFee) {
			totalAmount = contractBalance.mul(FORCE_WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
			toFee = contractBalance.sub(totalAmount, "sub error 2");
			if(poolIsActive) {
				poolIsActive = false;
				lastStand.activeClaim();
			}
		}

		user.checkpoint = block.timestamp;
		user.forceDeposit = user.deposits.length;
		user.totalWithdrawn += totalAmount;

		payHandler(msg.sender, totalAmount);
		payHandler(projectAddress, toFee);
		emit ForceWithdraw(msg.sender, totalAmount);
		emit FeePayed(msg.sender, toFee);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		address _addr = msg.sender;
		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			delete user.bonus;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount >= MINIMAL_WITHDRAW, "User has no dividends");

		uint256 contractBalance = getContractBalance();
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
			if(poolIsActive) {
				poolIsActive = false;
				lastStand.activeClaim();
			}
		}


		uint fees = totalAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
		uint projectFee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint marketingFee = fees.mul(60).div(100);
		uint devFee = fees.mul(40).div(100);
		fees += projectFee;
		totalAmount = totalAmount.sub(fees);

		user.checkpoint = block.timestamp;
		user.totalWithdrawn += totalAmount;

		payHandler(_addr, totalAmount);
		payHandler(projectAddress, projectFee);
		payHandler(devAddress, devFee);
		payHandler(marketingAddress, marketingFee);
		emit Withdrawn(_addr, totalAmount);
	}



	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
	}

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = user.forceDeposit; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory) {
		return users[userAddress].levels;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
		User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}

	function getPublicData() external view returns(
		uint256 totalUsers_,
		uint256 totalInvested_,
		// uint256 totalReinvested_,
		uint256 totalWithdrawn_,
		uint256 totalDeposits_,
		uint256 balance_,
		// uint256 roiBase,
		// uint256 maxProfit,
		uint256 minDeposit,
		uint256 daysFormdeploy
		) {
		totalUsers_ = totalUsers;
		totalInvested_ = totalStaked;
		// totalReinvested_ = totalReinvested;
		totalWithdrawn_ = totalWithdrawn;
		totalDeposits_ = totalDeposits;
		balance_ = getContractBalance();
		// roiBase = ROI_BASE;
		// maxProfit = MAX_PROFIT;
		minDeposit = INVEST_MIN_AMOUNT;
		daysFormdeploy = block.timestamp.sub(startUNIX).div(TIME_STEP);
	}

	function getUserData(address userAddress) external view returns(
		uint256 totalWithdrawn_,
		uint256 totalDeposits_,
		uint256 amountDeposits_,
		uint256 totalBonus_,
		// uint256 totalReinvest_,
		uint256 balance_,
		uint256 nextAssignment_,
		// uint256 amountOfDeposits,
		uint256 checkpoint,
		bool isUser_,
		address referrer_,
		uint256[3] memory referrerCount_,
		uint256 referrerBonus_
	) {
		User memory user = users[userAddress];
		totalWithdrawn_ = user.totalWithdrawn;
		amountDeposits_=getUserAmountOfDeposits(userAddress);
		totalDeposits_ = getUserTotalDeposits(userAddress);
		
		balance_ = getUserDividends(userAddress);
		totalBonus_ = user.totalBonus;
		
		// totalReinvest_ = user.reinvest;
		// amountOfDeposits = getUserAmountOfDeposits(userAddress);

		
		checkpoint = getUserCheckpoint(userAddress);
		nextAssignment_ = checkpoint.add(TIME_STEP);
		isUser_ = amountDeposits_ > 0;
		referrer_ = user.referrer;
		referrerCount_ = user.levels;
		referrerBonus_ =  user.bonus;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LastStand is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    bool public canClaim;
    uint public totalInvested;
    uint constant public MAX_INVESTORS = 50;
    EnumerableSet.AddressSet internal lastInvestors;
    mapping(address => uint) public totalInvestedBy;
    mapping(address => bool) public hasClaimed;
    mapping(address => uint) public userWithdrawals;
    uint public totalWithdrawn;
    uint public finishDate;
    uint constant public ACTIVE_DAYS = 5 days;
    address public operator;
    address public contractMaster;

    modifier onlyContractMaster {
        require(msg.sender == contractMaster, "Only contract master");
        _;
    }

    function setContractMaster(address _contractMaster) public onlyOwner {
        require(contractMaster == address(0), "Contract master already set");
        contractMaster = _contractMaster;
    }

    function activeClaim() public onlyContractMaster {
        canClaim = true;
        finishDate = block.timestamp + ACTIVE_DAYS;
    }

    function canFinish() public view returns (bool) {
        if(canClaim && block.timestamp > finishDate) {
            return true;
        }
        return false;
    }

    function deposit(address _investor) public payable onlyContractMaster {
        if(!canClaim) {
            totalInvested += msg.value;
            if(lastInvestors.length() >= MAX_INVESTORS) {
                lastInvestors.remove(lastInvestors.at(0));
            }
            lastInvestors.remove(_investor);
            lastInvestors.add(_investor);
            totalInvestedBy[_investor] += msg.value;
        } else {
            payable(owner()).transfer(msg.value);
        }
    }

    function getLastStandInvest() public view returns (uint) {
        uint _totalInvested;
        for(uint i; i < lastInvestors.length(); i++) {
            _totalInvested += totalInvestedBy[lastInvestors.at(i)];
        }
        return _totalInvested;
    }

    function getDividendsTo(address _investor) public view returns (uint) {
        if(lastInvestors.contains(_investor)) {
            uint dividends = (totalInvested * totalInvestedBy[_investor]) / getLastStandInvest();
            if(dividends > getContractBalance()) {
                dividends = getContractBalance();
            }
            return dividends;
        }
        return 0;
    }

    function withdraw() public {
        require(canClaim, "cant withdraw before claim");
        require(hasClaimed[msg.sender] == false, "you have already claimed");
        require(lastInvestors.contains(msg.sender), "you are not an investor");
        hasClaimed[msg.sender] = true;
        uint toWithdraw = getDividendsTo(msg.sender);
        totalWithdrawn += toWithdraw;
        payable(msg.sender).transfer(toWithdraw);
    }

    function isInvestor(address _investor) public view returns (bool) {
        return lastInvestors.contains(_investor);
    }

    function investorPosition(address _investor) public view returns (uint) {
        uint _position;
        for(uint i; i < lastInvestors.length(); i++) {
            if(lastInvestors.at(i) == _investor) {
                _position = i;
                return _position;
            }
        }
        return _position;
    }

    function getUserData(address _user) external view returns(uint _totalInvested, uint _totalWithdrawn,
        uint _investorPosition, bool _hasClaimed, uint _dividendsTo) {
        _totalInvested = totalInvestedBy[_user];
        _totalWithdrawn = userWithdrawals[_user];
        _investorPosition = investorPosition(_user);
        _hasClaimed = hasClaimed[_user];
        _dividendsTo = getDividendsTo(_user);
    }

    function getData() external view returns(uint _totalInvest, uint _standInvested, uint _totalWithdrawn, uint _investorsCount, uint _maxInversors, uint _contractBalance, bool _canClaim) {
        _totalInvest = totalInvested;
        _standInvested = getLastStandInvest();
        _totalWithdrawn = totalWithdrawn;
        _investorsCount = lastInvestors.length();
        _canClaim = canClaim;
        _maxInversors = MAX_INVESTORS;
        _contractBalance = getContractBalance();
    }

    function lastInvestorsLegth() external view returns(uint) {
        return lastInvestors.length();
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function finish() external onlyOwner {
        require(canFinish(), "cant finish");
        payable(msg.sender).transfer(getContractBalance());
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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