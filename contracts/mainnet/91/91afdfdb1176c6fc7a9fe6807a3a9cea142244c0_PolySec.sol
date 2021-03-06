/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT

/*
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect browser extension Metamask
 *   2) Choose one of the tariff plans, enter the MATIC amount (10 MATIC minimum) using our website "Stake MATIC" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +0.3% every 24 hours (~0.0125% hourly) - only for new deposits
 *   - Minimal deposit: 10 MATIC, no maximal limit
 *   - Total income: based on your tarrif plan (from 4% to 8% daily!!!) + Basic interest rate !!!
 *   - Earnings every moment, withdraw any time (if you use capitalization of interest you can withdraw only after end of your deposit or you can terminate their stakes and get 50% of their fund back while the remaining goes into the pool. (plan 1,2,3,4 are not allowed to terminate after withdrawing interest)
 *
 *   [AFFILIATE PROGRAM]
 *
 *   referral commission: 6%
 *
 *   [DEV + CONTRACT FEE]
 *    - Dev fee:      5%
 *    - Contract fee: 6%
*/

pragma solidity >=0.4.22 <0.9.0;

contract PolySec {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 10 ether;
	uint256[] public REFERRAL_PERCENTS = [60];
	uint256 constant public PERCENT_STEP = 3;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public constant PENALTY_STEP = 500;

  // PolyAnon edit (1)
  // (1) We make the dev and contract fees explicit and publicly accessible
  // (2) We reduce the dev fee from 6% to 5%.
  uint256 public constant DEV_FEE      = 50;
  uint256 public constant CONTRACT_FEE = 60;

	uint256 public totalStaked;
	uint256 public totalRefBonus;

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
		uint256[1] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public dev;
	address payable public pro;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event ForceWithdrawn(address indexed user, uint256 amount, uint256 penaltyAmount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _dev, address payable _pro, uint256 startDate) public {
		require(!isContract(_dev));
		require(startDate > 0);
		dev = _dev;
     	pro = _pro;
		startUNIX = startDate;

        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 55));
		plans.push(Plan(35, 45));
        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 55));
		plans.push(Plan(35, 45));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 8, "Invalid plan");

        // PolyAnon edit (1)
        // Here you see the dev and contract fees being deducted from the contract balance:
        //
        //   E.g., DEV_FEE = 50; PERCENTS_DIVIDER = 1000
        //
        //   50 / 1000 = 0.05, which is 5% in decimal form
        //
        //   'msg.value' contains the amount of matic an investor wishes to invest
        //
        dev.transfer(msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER));
        pro.transfer(msg.value.mul(CONTRACT_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 1; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}
		uint256 refsamount;

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 1; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else {
				    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				    refsamount = refsamount.add(amount);
				}
			}
      // PolyAnon edit (3)
      // This code will never be executed, but we remove it for our investors' peace of mind.
      // Notice there is a transfer here to the dev's wallet? See below for more details.
      //
			// if (refsamount > 0){
      //
			// dev.transfer(refsamount.div(1));
			// }
		}
		else{
        // PolyAnon edit (3)
        // This code was used to transfer an additional 6% 'referal fee' to the dev's wallet.
        // PolySec's dev is the referrer of all investors who did not specify an alternative referrer.
        // So we have reduced the dev fee from 12% to 5% in a large number of cases.
        //
		    //uint256 refsbkp = 60;
		    //uint256 amount = msg.value.mul(refsbkp).div(PERCENTS_DIVIDER);
		    //dev.transfer(amount.div(1));
        }
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function forceWithdraw(uint256 index) public {
        User storage user = users[msg.sender];

        require(index < user.deposits.length, "Invalid index");

        require(user.deposits[index].plan >= 4 && user.deposits[index].plan < 8, 'force withdraw not valid');

        require(user.deposits[index].finish > block.timestamp, 'you can not force withdraw');

        uint256 depositAmount = user.deposits[index].amount;
        uint256 penaltyAmount =
            depositAmount.mul(PENALTY_STEP).div(PERCENTS_DIVIDER);

        msg.sender.transfer(depositAmount.sub(penaltyAmount));

        user.deposits[index] = user.deposits[user.deposits.length - 1];
        user.deposits.pop();

        emit ForceWithdrawn(
            msg.sender,
            depositAmount,
            penaltyAmount
        );
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
    // PolyAnon edit (2)
    // The previus code returned 'plans[plan].percent', which is the initial
    // daily % profit, i.e., when the contract is launched. However, this doesn't account for the
    // 0.3% daily increase.
    // 'getPercent' returns the up to date value, which is displayed on our vFAT page.
		percent = getPercent(plan);
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

		if (plan < 4) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 8) {
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
				if (user.deposits[i].plan < 4) {
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