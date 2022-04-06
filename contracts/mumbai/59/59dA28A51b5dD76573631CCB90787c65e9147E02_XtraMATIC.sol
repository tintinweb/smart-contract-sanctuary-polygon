// SPDX-License-Identifier: MIT 
 
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract XtraMATIC is Ownable {
	using SafeMath for uint256;

	uint256 constant public BENEFICIARY_FEE = 100; // 10%
    uint256 constant public MINIMUM_INVESTMENT_AMOUNT = 0.1 ether;
    uint256 constant public MINIMUM_WITHDRAW_AMOUNT = 0.01 ether;
    uint256 private constant MAX_INVESTMENT_COUNT = 100;
	uint256[] public REFERRAL_PERCENTS = [30, 15, 5];
    uint256 constant public TOTAL_REF = 50;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	// uint256 constant public TIME_STEP = 1 minutes;
    uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalReferralReward;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

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
		uint256 totalInvestment;
        uint256 totalWithdraw;
        uint256 investmentCount;
		uint256 totalReferralBonus;
	}

	mapping (address => User) public users;

	uint256 public startUNIX;
	address payable public beneficiaryWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet,uint256 _startTime) {
		require(!isContract(wallet));
		beneficiaryWallet = wallet;
		startUNIX = _startTime;

        // Active Investment Plans
        plans.push(Plan(14, 110));
        plans.push(Plan(21, 80));
        plans.push(Plan(28, 75));

        // Passive Investment Plans
        plans.push(Plan(14, 110));
        plans.push(Plan(21, 80));
        plans.push(Plan(28, 75));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startUNIX, "Not launched yet!");
		require(msg.value >= MINIMUM_INVESTMENT_AMOUNT, "The minimum investment amount is 0.1 MATIC.");
        require(plan < 6, "Invalid plan!");
        require(referrer != msg.sender, "Referer cannot be same with the caller.");
        require(users[msg.sender].investmentCount < MAX_INVESTMENT_COUNT, "Cannot invest more than 100 times from single wallet.");

		uint256 fee = msg.value.mul(BENEFICIARY_FEE).div(PERCENTS_DIVIDER);
		beneficiaryWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0) {
                user.referrer = referrer;
            }

            address upLine = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upLine != address(0)) {
                    users[upLine].levels[i] = users[upLine].levels[i].add(
                        1
                    );
                    upLine = users[upLine].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upLine = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upLine != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upLine].totalReferralBonus = users[upLine].totalReferralBonus.add(
                        amount
                    );
                    totalReferralReward = totalReferralReward.add(amount);
                    payable(upLine).transfer(amount);
                    upLine = users[upLine].referrer;
                } else break;
            }
        } else {
            uint256 amount = msg.value.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
            beneficiaryWallet.transfer(amount);
            totalReferralReward = totalReferralReward.add(amount);
        }

        user.investmentCount = user.investmentCount.add(1);
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		user.totalInvestment = user.totalInvestment.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		require(block.timestamp > startUNIX, "Not launched yet!");
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
        require(totalAmount >= MINIMUM_WITHDRAW_AMOUNT, "Cannot withdraw less than 0.02.");

		require(totalAmount > 0, "User has no dividends.");

        user.totalWithdraw = user.totalWithdraw.add(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		payable(msg.sender).transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

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

		for (uint256 i = 0; i < user.deposits.length; i++) {
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

	function getUserDownLineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalReferralBonus;
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

	function getContractInformation() public view returns(uint256, uint256, uint256, uint256) {
        uint256 contractBalance = getContractBalance();
        return (
            contractBalance,
            totalInvested,
            totalWithdrawn,
            totalReferralReward
        );
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
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