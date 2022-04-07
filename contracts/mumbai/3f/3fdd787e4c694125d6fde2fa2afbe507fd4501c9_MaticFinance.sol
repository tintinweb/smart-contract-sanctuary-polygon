/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IInsuranceContract {
	function initiate40() external;
	function initiate60() external;
	function getBalance() external view returns(uint256);
	function getMainContract() external view returns(address);
}

contract INSURANCE {

	receive() external payable {}
	address payable public MAINCONTRACT;

	constructor() {
		MAINCONTRACT = payable(msg.sender);
	}

	function initiate40() public {
		require(msg.sender == MAINCONTRACT, "Forbidden");
		uint256 balance = address(this).balance;
		if(balance==0) return;
		MAINCONTRACT.transfer(balance);
	}

	function initiate60() public {
		require(msg.sender == MAINCONTRACT, "Forbidden");
		uint256 balance = address(this).balance;
		if(balance==0) return;
		MAINCONTRACT.transfer(balance / 2);
	}

	function getBalance() public view returns(uint256) {
		return address(this).balance;
	}

	function getMainContract() public view returns(address) {
		return MAINCONTRACT;
	}

}

contract MaticFinance {
	receive() external payable {}
	uint256 constant public INVEST_MIN_AMOUNT = 0.1 ether; // 0.1 MATIC
	uint256 constant public WITHDRAW_MIN_AMOUNT = 0.000001 ether; // 0.000001 Matic
	uint256 constant public WITHDRAW_MAX_AMOUNT = 20000 ether; // 20,000 MATIC
	uint256 constant public MAX_DEPOSITS = 200;
	uint256[] public REFERRAL_PERCENTS = [50, 25, 15, 5, 5];
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PROJECT_WITHDRAW_FEE = 50;
	uint256 constant public MARKET_FEE = 50;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public AUTO_REINVEST = 250;
	uint8   constant public DEFAULT_REINVEST_PLAN = 1;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public WITHDRAW_STEP = TIME_STEP / 86400;

	address payable public				INSURANCE_CONTRACT;
	mapping (uint256 => uint256) public	INSURANCE_MAXBALANCE;
	uint256 constant public				INSURANCE_PERCENT				= 250;
	uint256 constant public				INSURANCE_LOWBALANCE60_PERCENT	= 600;
	uint256 constant public				INSURANCE_LOWBALANCE40_PERCENT	= 400;
	bool insurance60 = false;

	uint256 public totalUsers;
	uint256 public totalStaked;
	uint256 public totalReinvest;
	uint256 public totalRefBonus;
	uint256 public INSURANCE_TRIGGER_BALANCE;

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
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalWithdraw;
		uint256 reserved;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public projectWallet;
	address payable public marketWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event InitiateInsurance(uint256 high, uint256 current);
	event InsuranseFeePaid(uint amount);

	constructor(address payable pWallet, address payable mWallet) {
		require(!isContract(pWallet) && !isContract(mWallet) );
		projectWallet = pWallet;
		marketWallet = mWallet;
		startUNIX = 1649163600; //Tue Apr 05 2022 13:00:00 GMT+0000

		INSURANCE_CONTRACT = payable(new INSURANCE());

        plans.push(Plan(14, 200));
        plans.push(Plan(21, 200));
        plans.push(Plan(28, 200));
        plans.push(Plan(14, 250));
        plans.push(Plan(21, 250));
        plans.push(Plan(28, 250));
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startUNIX, "not luanched yet");
		require(msg.value >= INVEST_MIN_AMOUNT, "the min amount is 0.000001 matic");
        require(plan < 6, "Invalid plan");

		User storage user = users[msg.sender];
		require(user.deposits.length < MAX_DEPOSITS, "max 200 deposits");

		uint256 fee = msg.value * PROJECT_FEE / PERCENTS_DIVIDER;
		projectWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		if (user.deposits.length == 0) {
			if (user.referrer == address(0)) {
				if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
					user.referrer = referrer;
				}

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						users[upline].levels[i] = users[upline].levels[i] + 1;
						upline = users[upline].referrer;
					} else break;
				}
			}

			if (user.referrer != address(0)) {
				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						uint256 amount = msg.value * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;
						users[upline].bonus = users[upline].bonus + amount;
						users[upline].totalBonus = users[upline].totalBonus + amount;
						emit RefBonus(upline, msg.sender, i, amount);
						upline = users[upline].referrer;
					} else break;
				}
			}
			totalUsers += 1;
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked + msg.value;
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);

		_insuranceTrigger();
	}

	function reinvest(uint256 amount) internal {
		require(block.timestamp > startUNIX, "not luanched yet");
		require(amount >= INVEST_MIN_AMOUNT, "the min amount is 1 matic");

		User storage user = users[msg.sender];
		if(user.deposits.length < MAX_DEPOSITS)
		{
			(uint256 percent, uint256 profit, uint256 finish) = getResult(DEFAULT_REINVEST_PLAN, amount);
			user.deposits.push(Deposit(DEFAULT_REINVEST_PLAN, percent, amount, profit, block.timestamp, finish));
			totalReinvest = totalReinvest + amount;
			emit NewDeposit(msg.sender, DEFAULT_REINVEST_PLAN, percent, amount, profit, block.timestamp, finish);			
		}
		else{
			return;
		}

	}

	function withdraw() public {
		require(block.timestamp > startUNIX, "not luanched yet");
		User storage user = users[msg.sender];
		require( (user.checkpoint + WITHDRAW_STEP) < block.timestamp ,"only each 12 hours" );
		(uint256 totalAmountU, uint256 totalAmountL) = getUserDividends(msg.sender);

		require((totalAmountL + totalAmountU) >= WITHDRAW_MIN_AMOUNT, "min withdraw is 0.000001 Matic");

		uint256 fee = totalAmountL * PROJECT_WITHDRAW_FEE / PERCENTS_DIVIDER;
		if(address(this).balance > fee){
			projectWallet.transfer(fee);
			emit FeePayed(msg.sender, fee);
			totalAmountL = totalAmountL - fee;
		}

		//autoreinvest
		if(totalAmountU > 0){
			uint256 reinvestAmount = totalAmountU * AUTO_REINVEST / PERCENTS_DIVIDER;
			reinvest(reinvestAmount);
			totalAmountU = totalAmountU - reinvestAmount;
		}

		uint256 totalAmount = totalAmountL + totalAmountU;
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount + referralBonus;
		}

		if(user.reserved > 0){
			totalAmount += user.reserved;
			user.reserved = 0;
		}
		
		if(totalAmount > WITHDRAW_MAX_AMOUNT){
			user.reserved = totalAmount - WITHDRAW_MAX_AMOUNT;
			totalAmount = WITHDRAW_MAX_AMOUNT;
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.reserved += (totalAmount - contractBalance);
			totalAmount = contractBalance;
		}

		//insurance
		uint256 insuranceAmount = totalAmount * INSURANCE_PERCENT / PERCENTS_DIVIDER;
		payable(INSURANCE_CONTRACT).transfer( insuranceAmount );
		emit InsuranseFeePaid(insuranceAmount);

		totalAmount = totalAmount - insuranceAmount;
		user.checkpoint = block.timestamp;
		payable(msg.sender).transfer(totalAmount);
		user.totalWithdraw += totalAmount;
		emit Withdrawn(msg.sender, totalAmount);

		_insuranceTrigger();
	}

	function _insuranceTrigger() internal {

		uint256 balance = address(this).balance;
		uint256 todayIdx = block.timestamp/TIME_STEP;

		//new high today
		if ( INSURANCE_MAXBALANCE[todayIdx] < balance ) {
			INSURANCE_MAXBALANCE[todayIdx] = balance;
		}

		//high of past 7 days
		uint256 rangeHigh;
		for( uint256 i=0; i<7; i++) {
			if( INSURANCE_MAXBALANCE[todayIdx-i] > rangeHigh ) {
				rangeHigh = INSURANCE_MAXBALANCE[todayIdx-i];
			}
		}

		//insurance 60%
		if(!insurance60){
			INSURANCE_TRIGGER_BALANCE = rangeHigh*INSURANCE_LOWBALANCE60_PERCENT/PERCENTS_DIVIDER;
			if( balance < INSURANCE_TRIGGER_BALANCE ) {
				emit InitiateInsurance( rangeHigh, balance );
				IInsuranceContract(INSURANCE_CONTRACT).initiate60();
				insurance60 = true;
			}
		}
		else{
			// insurance 40%
			INSURANCE_TRIGGER_BALANCE = rangeHigh*INSURANCE_LOWBALANCE40_PERCENT/PERCENTS_DIVIDER;
			if( balance < INSURANCE_TRIGGER_BALANCE ) {
				emit InitiateInsurance( rangeHigh, balance );
				IInsuranceContract(INSURANCE_CONTRACT).initiate40();
			}
		}


	}

	function getInsuranceInfo() public view returns(uint256 o_ensBalance, uint256 o_ensTriggerBalance) {
		uint256 insuranceBalance = IInsuranceContract(INSURANCE_CONTRACT).getBalance();
		return( insuranceBalance, INSURANCE_TRIGGER_BALANCE );
	}

	function getContractInfo() public view returns(uint256 tUsers, uint256 tStake, uint256 tReinvest, uint256 tReferral, uint256 cBalance) {
		return( totalUsers, totalStaked, totalReinvest, totalRefBonus, getContractBalance() );
	}

	function getContractBalance() public view returns(uint) {
		uint insuranceBalance = IInsuranceContract(INSURANCE_CONTRACT).getBalance();
		return address(this).balance + insuranceBalance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent + (PERCENT_STEP * (block.timestamp - startUNIX) / TIME_STEP);
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit * percent / PERCENTS_DIVIDER * plans[plan].time;
		finish = block.timestamp + (plans[plan].time * TIME_STEP);
	}

	function getUserDividends(address userAddress) public view returns (uint256, uint256) {
		User storage user = users[userAddress];

		uint256 totalAmountU;
		uint256 totalAmountL;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount * user.deposits[i].percent / PERCENTS_DIVIDER;
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmountU = totalAmountU + (share * (to - from) / TIME_STEP);
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmountL = totalAmountL + user.deposits[i].profit;
				}
			}
		}

		return (totalAmountU,totalAmountL);
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus - users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		(uint256 U, uint256 L ) = getUserDividends(userAddress);
		return getUserReferralBonus(userAddress) + U + L + users[userAddress].reserved;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount + users[userAddress].deposits[i].amount;
		}
	}

	function getUserInfo(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256){
		return (
			getUserAmountOfDeposits(userAddress),
			getUserTotalDeposits(userAddress),
			users[userAddress].totalWithdraw,
			getUserAvailable(userAddress),
			getUserCheckpoint(userAddress)
		);
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
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

/* © 2022 by MaticFinance. All rights reserved. */