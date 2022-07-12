/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

pragma solidity 0.5.10;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract DiamondMiner {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public token;

	uint256[] public REFERRAL_PERCENTS = [30, 20, 10, 5, 2, 1];
	uint256 constant public MINER_FEE = 50;
	uint256 constant public RE_MINER_FEE = 30;
	uint256 constant public WITHDRAW_FEE = 50;
	uint256 constant public CONTRACT_WD_CAPITAL_FEE = 50;
	uint256 constant public CONTRACT_FORCE_WD_CAPITAL_FEE = 250;
	uint256 constant public TOTAL_REF = 68;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;

    struct Plan {
        uint256 time;
        uint256 percent;
		uint256 minimum;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		uint256 withdrawn;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 checkpointWithdraw;
        uint256 checkpointReinvest;
		address referrer;
		uint256[6] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 withdrawnCapital;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address tokenAddr, address payable wallet) public {
		require(!isContract(wallet) && isContract(tokenAddr));
		token = IERC20(tokenAddr);
		commissionWallet = wallet;

        plans.push(Plan(1000, 10, 100000000000000000));
        plans.push(Plan(300, 15, 5000000000000000000));
		plans.push(Plan(100, 20, 25000000000000000000));
	}

	function invest(address referrer, uint8 plan, uint256 value) public {
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		uint256 minimum_invest = plans[plan].minimum;
		require(value >= minimum_invest, "Minimum Invest");
        require(plan < 2, "Invalid plan");

		require(value <= token.allowance(msg.sender, address(this)));
		token.safeTransferFrom(msg.sender, address(this), value);

		uint256 fee = value.mul(MINER_FEE).div(PERCENTS_DIVIDER);
		token.safeTransfer(commissionWallet, fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 6; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 6; i++) {
				if (upline != address(0)) {
					uint256 amount = value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, value, block.timestamp, 0));

		totalInvested = totalInvested.add(value);

		emit NewDeposit(msg.sender, plan, value);
	}

	function reinvest(uint8 plan) public {
		User storage user = users[msg.sender];

        require(user.checkpointReinvest + TIME_STEP < block.timestamp , "Reinvest allowed only once a day" );
		
		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

		uint256 minimum_invest = plans[plan].minimum;
		require(totalAmount >= minimum_invest, "Minimum Invest");
        require(plan < 2, "Invalid plan");

		user.checkpoint = block.timestamp;
		user.checkpointReinvest = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		uint256 fee = totalAmount.mul(RE_MINER_FEE).div(PERCENTS_DIVIDER);
		uint256 totalAmountMinFee = totalAmount.sub(fee);

		token.safeTransfer(commissionWallet, fee);
		user.deposits.push(Deposit(plan, totalAmountMinFee, block.timestamp, 0));
		totalInvested = totalInvested.add(totalAmountMinFee);

		emit FeePayed(msg.sender, fee);
		emit Withdrawn(msg.sender, totalAmountMinFee);
		emit NewDeposit(msg.sender, plan, totalAmountMinFee);
    }

	function withdraw() public {
		User storage user = users[msg.sender];

        require(user.checkpointWithdraw + TIME_STEP < block.timestamp , "withdraw allowed only once a day" );

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.checkpointWithdraw = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		uint256 fee = totalAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
		uint256 totalAmountMinFee = totalAmount.sub(fee);

		token.safeTransfer(msg.sender, totalAmountMinFee);
		token.safeTransfer(commissionWallet, fee);

		emit FeePayed(msg.sender, fee);
		emit Withdrawn(msg.sender, totalAmountMinFee);
	}

	function withdrawCapital() public {
		User storage user = users[msg.sender];

		uint256 totalAmount;
		uint256 totalAmountRegular;
		uint256 totalAmountForce;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 start = user.deposits[i].start;
			uint256 withdrawn = user.deposits[i].withdrawn;
			uint256 amount = user.deposits[i].amount;
			if (withdrawn == 0) {
				if(block.timestamp > start.add(604800)) {
					totalAmount = totalAmount.add(amount);
					totalAmountRegular = totalAmountRegular.add(amount);
				}
				if(block.timestamp < start.add(604800)) {
					totalAmount = totalAmount.add(amount);
					totalAmountForce = totalAmountForce.add(amount);
				}
				user.deposits[i].withdrawn = 1;
			}
		}
		require(totalAmount > 0, "User has no deposits");

		uint256 contractBalance = token.balanceOf(address(this));
		require(contractBalance < totalAmount, "Contract balance limited");

		user.withdrawnCapital = user.withdrawnCapital.add(totalAmount);
		
		if(totalAmountRegular > 0) {
			uint256 fee1 = totalAmountRegular.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
			uint256 fee2 = totalAmountRegular.mul(CONTRACT_WD_CAPITAL_FEE).div(PERCENTS_DIVIDER);
			uint256 totalFee = fee1.add(fee2);
			uint256 totalAmountMinFee = totalAmountRegular.sub(totalFee);

			token.safeTransfer(msg.sender, totalAmountMinFee);
			token.safeTransfer(commissionWallet, fee1);

			emit FeePayed(msg.sender, fee1);
			emit Withdrawn(msg.sender, totalAmountMinFee);
		}

		if(totalAmountForce > 0) {
			uint256 fee1 = totalAmountForce.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
			uint256 fee2 = totalAmountForce.mul(CONTRACT_FORCE_WD_CAPITAL_FEE).div(PERCENTS_DIVIDER);
			uint256 totalFee = fee1.add(fee2);
			uint256 totalAmountMinFee = totalAmountForce.sub(totalFee);

			token.safeTransfer(msg.sender, totalAmountMinFee);
			token.safeTransfer(commissionWallet, fee1);

			emit FeePayed(msg.sender, fee1);
			emit Withdrawn(msg.sender, totalAmountMinFee);
		}
	}

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimum) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimum = plans[plan].minimum;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			uint256 withdrawn = user.deposits[i].withdrawn;
			if(withdrawn == 0) {
				if (user.checkpoint < finish) {
					uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = finish < block.timestamp ? finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserTotalWithdrawnCapital(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawnCapital;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserCheckpointWithdraw(address userAddress) public view returns (uint256) {
       return users[userAddress].checkpointWithdraw;
    }

    function getUserCheckpointReinvest(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpointReinvest;
    }

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[6] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4]+users[userAddress].levels[5];
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

	function getUserTotalDepositsActive(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			uint256 withdrawn = users[userAddress].deposits[i].withdrawn;
			if(withdrawn == 0) {
				amount = amount.add(users[userAddress].deposits[i].amount);
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, uint256 withdrawn) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
		withdrawn = user.deposits[index].withdrawn;
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
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