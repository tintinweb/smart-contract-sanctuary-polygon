/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
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
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
    //   require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}



// **************************
// **************************
// **************************
// **************************
// **************************
// **************************
// only owner need to fix
// **************************
contract XXXX is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// address private tokenAddr = 0x55d398326f99059fF775485246999027B3197955; // USDT
	address private tokenAddr = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747; // BUSD testnet
	IERC20 public token;

	// uint256[] public INVEST_AMOUNT = [500 ether, 1000 ether, 2000 ether, 3000 ether, 5000 ether, 7000 ether, 10_000 ether, 15_000 ether, 20_000 ether, 30_000 ether, 40_000 ether, 50_000 ether, 75_000 ether, 100_000 ether];
	uint256[] public INVEST_AMOUNT = [5 * 1e6, 10 * 1e6, 2000 * 1e6, 3000 * 1e6, 5000 * 1e6, 7000 * 1e6, 10_000 * 1e6, 15_000 * 1e6, 20_000 * 1e6, 30_000 * 1e6, 40_000 * 1e6, 50_000 * 1e6, 75_000 * 1e6, 100_000 * 1e6]; //test
	uint256[] public REFERRAL_PERCENTS = [30, 20, 20];
	uint256[] public REFERRAL_DIVIDENDS_PERCENTS = [200, 75, 50];
	uint256 constant public REFERRAL_DIVIDENDS = 325;
	// uint256 constant public MIN_WITHDRAW = 75 ether;
	// uint256 constant public MIN_COMPOUND = 75 ether;
	uint256 constant public MIN_WITHDRAW = 0.01 * 1e6;
	uint256 constant public MIN_COMPOUND = 0.01 * 1e6;
	uint256 constant public MAX_DEPOSITS = 100;
	uint256 constant public RATE = 150;
	uint256 constant public TOTAL_RETURN = 2500;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	// uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_STEP = 30; //test
	uint256 constant public A_MONTH = 30 * TIME_STEP;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalReinvest;
	uint256 public totalReferral;
	uint256 public totalDividendsReferral;
	uint256 public totalActiveDeposits;
	uint256 public totalInsertDividends;

	uint256 public currentRound = 1;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		bool    reinvest;
	}

	struct Round {
		uint256 tDeposit;
		uint256 tActiveDeposit;
		uint256 tWithdraw;
		uint256 tUsers;
		uint256 date;
		uint256 rate;
		uint256 tProfitDeposit;
		uint256 tProfitAffiliate;
	}

	struct Withdrawal {
		uint256 amount;
		uint256 date;
		bool    status;
		bool    reinvest;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 totalBonus;
		uint256 dividendsBonus;
		uint256 totalDividendsBonus;
		uint256 totalDeposit;
		uint256 totalWithdrawn;
		uint256 totalReinvest;
		uint256 reserve;
	}
 
	mapping (address => User) public users;
	mapping (address => mapping(uint256 => Withdrawal)) public withdrawals;
    mapping (uint256 => uint256) public roundRates;
    mapping (uint256 => Round) public roundStats;

	uint256 public startDate;
	uint256 public launchDate;


	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(uint256 start) {
		token = IERC20(tokenAddr);
		if(start > 0){
			launchDate = start.sub(5 * TIME_STEP);
			startDate  = start.sub(A_MONTH);
		}
	}

	function invest(address referrer, uint256 amountId) public {
		require(block.timestamp > startDate,  "round does not launch yet");
		require(block.timestamp > launchDate, "contract does not launch yet");

		uint256 amount = INVEST_AMOUNT[amountId];
		require(amount <= token.allowance(msg.sender, address(this)),"low allowance");
		token.safeTransferFrom(msg.sender, address(this), amount);

		User storage user = users[msg.sender];
		require(user.deposits.length <= MAX_DEPOSITS, "max 100 deposits");
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					token.safeTransfer(upline, refAmount);
					users[upline].totalBonus = users[upline].totalBonus.add(refAmount);
					totalReferral = totalReferral.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers++;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(amount, 0, block.timestamp, false));
		totalInvested = totalInvested.add(amount);
		totalActiveDeposits = totalActiveDeposits.add(amount);
		emit NewDeposit(msg.sender, amount, block.timestamp);

		updateRoundStats();
	}

	function withdraw() public {
		require(block.timestamp > startDate,  "round does not launch yet");
		require(block.timestamp > launchDate, "contract does not launch yet");
		require(withdrawals[msg.sender][cRound()].status == false, "dividends withdrawn");
		User storage user = users[msg.sender];

		uint256 totalAmount = calUserDividends(msg.sender);
		uint256 amount = totalAmount;
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_DIVIDENDS_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].dividendsBonus = users[upline].dividendsBonus.add(refAmount);
					users[upline].totalDividendsBonus = users[upline].totalDividendsBonus.add(refAmount);
					totalDividendsReferral = totalDividendsReferral.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		uint256 referralDividendsBonus = user.dividendsBonus;
		if (referralDividendsBonus > 0) {
			user.dividendsBonus = 0;
			totalAmount = totalAmount.add(referralDividendsBonus);
		}
		
		uint256 reserveAmount = user.reserve;
		if (reserveAmount > 0) {
			user.reserve = 0;
			totalAmount = totalAmount.add(reserveAmount);
		}

		require(totalAmount >= MIN_WITHDRAW, "less than min amount");

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.reserve = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}


		user.checkpoint = block.timestamp;
		user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		withdrawals[msg.sender][cRound()].amount = totalAmount;
		withdrawals[msg.sender][cRound()].date = block.timestamp;
		withdrawals[msg.sender][cRound()].status = true;
		token.safeTransfer(msg.sender, totalAmount);
		emit Withdrawn(msg.sender, totalAmount, block.timestamp);

		updateRoundStats();
	}

	function reinvest() public {	
		require(block.timestamp > startDate,  "round does not launch yet");
		require(block.timestamp > launchDate, "contract does not launch yet");
		require(withdrawals[msg.sender][cRound()].status == false, "dividends withdrawn");
		User storage user = users[msg.sender];
		require(user.deposits.length <= MAX_DEPOSITS, "max 100 deposits");

		uint256 totalAmount = calUserDividends(msg.sender);
		uint256 amount = totalAmount;
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 refAmount = amount.mul(REFERRAL_DIVIDENDS_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].dividendsBonus = users[upline].dividendsBonus.add(refAmount);
					users[upline].totalDividendsBonus = users[upline].totalDividendsBonus.add(refAmount);
					totalDividendsReferral = totalDividendsReferral.add(refAmount);
					emit RefBonus(upline, msg.sender, i, refAmount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		
		
		uint256 referralDividendsBonus = user.dividendsBonus;
		if (referralDividendsBonus > 0) {
			user.dividendsBonus = 0;
			totalAmount = totalAmount.add(referralDividendsBonus);
		}
		
		uint256 reserveAmount = user.reserve;
		if (reserveAmount > 0) {
			user.reserve = 0;
			totalAmount = totalAmount.add(reserveAmount);
		}

		require(totalAmount >= MIN_WITHDRAW, "less than min amount");

		user.deposits.push(Deposit(totalAmount, 0, block.timestamp, true));
		totalReinvest = totalReinvest.add(totalAmount);
		totalActiveDeposits = totalActiveDeposits.add(totalAmount);

		user.checkpoint = block.timestamp;
		user.totalReinvest = user.totalReinvest.add(totalAmount);

		withdrawals[msg.sender][cRound()].amount = totalAmount;
		withdrawals[msg.sender][cRound()].date = block.timestamp;
		withdrawals[msg.sender][cRound()].status = true;
		withdrawals[msg.sender][cRound()].reinvest = true;

		emit NewDeposit(msg.sender, totalAmount, block.timestamp);

		updateRoundStats();
	}

	function getContractBalance() public view returns (uint256) {
		return token.balanceOf(address(this));
	}

	function calUserDividends(address userAddress) internal returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		uint256 dividends = 0;
		uint256 cR = cRound();
		
		if(cR > 1){
			for (uint256 i = 0; i < user.deposits.length; i++) {
				uint256 max = user.deposits[i].amount.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
				if(user.deposits[i].withdrawn < max){
					for (uint256 j = 1; j < 4; j++) {
						if(j < cR && (cR-j) > 1){
							uint256 startRound = roundStart(cR-j);
							uint256 endRound = roundStart(cR-(j-1));
							if(startRound >= user.checkpoint && startRound >= user.deposits[i].start && roundRates[cR-j] > 0){
								uint256 share = user.deposits[i].amount.mul(roundRates[cR-j]).div(PERCENTS_DIVIDER);
								if (startRound < endRound) {
									dividends = dividends.add(share.mul(endRound.sub(startRound)).div(A_MONTH));
								}
							}
						}
					}
					if(user.deposits[i].withdrawn.add(dividends) > max){
						dividends = max.sub(user.deposits[i].withdrawn);
						user.deposits[i].withdrawn = max;
						totalActiveDeposits = totalActiveDeposits.sub(user.deposits[i].amount);
					}
				}
				totalAmount = totalAmount.add(dividends);
				dividends = 0;
			}
		}

		return totalAmount;
	}
	
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		uint256 dividends = 0;
		uint256 cR = cRound();
		if(cR > 1){
			for (uint256 i = 0; i < user.deposits.length; i++) {
				uint256 max = user.deposits[i].amount.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
				if(user.deposits[i].withdrawn < max){
					for (uint256 j = 1; j < 4; j++) {
						if(j < cR && (cR-j) > 1){
							uint256 startRound = roundStart(cR-j);
							uint256 endRound = roundStart(cR-(j-1));
							if(startRound >= user.checkpoint && startRound >= user.deposits[i].start && roundRates[cR-j] > 0){
								uint256 share = user.deposits[i].amount.mul(roundRates[cR-j]).div(PERCENTS_DIVIDER);
								if (startRound < endRound) {
									dividends = dividends.add(share.mul(endRound.sub(startRound)).div(A_MONTH));
								}
							}
						}
					}
					if(user.deposits[i].withdrawn.add(dividends) > max){
						dividends = max.sub(user.deposits[i].withdrawn);
					}
				}
				totalAmount = totalAmount.add(dividends);
				dividends = 0;
			}
		}
		return totalAmount;
	}
	
	function getUserDividendsCR(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		uint256 dividends = 0;
		uint256 cR = cRound();
		if(cR > 1){
			for (uint256 i = 0; i < user.deposits.length; i++) {
				uint256 max = user.deposits[i].amount.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
				if(user.deposits[i].withdrawn < max){
					uint256 startRound = roundStart(cR);
					uint256 endRound = roundStart(cR+1);
					if(startRound >= user.checkpoint && startRound >= user.deposits[i].start){
						uint256 share = user.deposits[i].amount.mul(RATE).div(PERCENTS_DIVIDER);
						if (startRound < endRound) {
							dividends = dividends.add(share.mul(endRound.sub(startRound)).div(A_MONTH));
						}
					}
						
					if(user.deposits[i].withdrawn.add(dividends) > max){
						dividends = max.sub(user.deposits[i].withdrawn);
					}
				}
				totalAmount = totalAmount.add(dividends);
				dividends = 0;
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].totalWithdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[3] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2];
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralDividendsBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].dividendsBonus;
	}

	function getUserReferralTotalDividendsBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalDividendsBonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralDividendsBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start, uint256 withdrawn, bool _reinvest) {
	    User storage user = users[userAddress];

		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		withdrawn = user.deposits[index].withdrawn;
		_reinvest = user.deposits[index].reinvest;
	}

	function getSiteInfo() public view returns(
		uint256 _totalInvested,
		uint256 _totalWithdrawn,
		uint256 _totalReinvest,
		uint256 _totalReferral,
		uint256 _totalDividendsReferral,
		uint256 _totalActiveDeposits
	) {
		return(
			totalInvested,
			totalWithdrawn,
			totalReinvest,
			totalReferral,
			totalDividendsReferral,
			totalActiveDeposits
		);
	}

	function getRequiredDividends() public view returns(
		uint256 _investors, 
		uint256 _affiliates
		) {

		uint256 r = roundRates[cRound() - 1] > 0 ? roundRates[cRound() - 1] : RATE;

		_investors  = totalActiveDeposits.mul(r).div(PERCENTS_DIVIDER);
		_affiliates = _investors.mul(REFERRAL_DIVIDENDS).div(PERCENTS_DIVIDER);
		
	}

	function getUserInfo(address userAddress) public view returns(
		uint256 checkpoint, 
		uint256 tDeposit, 
		uint256 tWithdrawn, 
		uint256 tReferrals,
		uint256 tDReferrals,
		uint256 tReinvests,
		uint256 tReserve
		) {
		return(
			getUserCheckpoint(userAddress), 
			getUserTotalDeposits(userAddress), 
			getUserTotalWithdrawn(userAddress), 
			getUserTotalReferrals(userAddress),
			users[userAddress].totalDividendsBonus,
			users[userAddress].totalDividendsBonus,
			users[userAddress].reserve
		);
	}

	function updateRoundStats() public {
		if(currentRound < cRound()){
			roundStats[currentRound].tDeposit = totalInvested;
			roundStats[currentRound].tActiveDeposit = totalActiveDeposits;
			roundStats[currentRound].tWithdraw = totalWithdrawn;
			roundStats[currentRound].tUsers = totalUsers;
			roundStats[currentRound].date = block.timestamp;
			roundStats[currentRound].tProfitDeposit;
			roundStats[currentRound].tProfitAffiliate;
			currentRound = cRound();
		}
    }

	function getRoundStats(uint256 index) public view returns (
		uint256 __tDeposit,
		uint256 __tActiveDeposit,
		uint256 __tWithdraw,
		uint256 __tUsers,
		uint256 __date,
		uint256 __tProfitDeposit,
		uint256 __tProfitAffiliate
	){
		return (
		roundStats[index].tDeposit,
		roundStats[index].tActiveDeposit,
		roundStats[index].tWithdraw,
		roundStats[index].tUsers,
		roundStats[index].date,
		roundStats[index].tProfitDeposit,
		roundStats[index].tProfitAffiliate
		);
	}

	function cRound() public view returns (uint256) {
		if(block.timestamp > startDate){
        	return ((block.timestamp - startDate) / A_MONTH) + 1;
		}
		else{
			return 0;
		}
    }

	function cRoundStart() public view returns (uint256) {
		if(block.timestamp > startDate){
        	return ((cRound() - 1) * A_MONTH) + startDate;
		}
		else{
			return startDate;
		}
    }

	function roundStart(uint256 index) public view returns (uint256) {
		if(block.timestamp > startDate && index > 0){
        	return ((index - 1) * A_MONTH) + startDate;
		}
		else{
			return startDate;
		}
    }

	function nextRoundStart() public view returns (uint256) {
        return cRoundStart() + A_MONTH;
    }

	function getRoundRate(uint256 index) public view returns (uint256) {
        return roundRates[index];
    }

	function setRoundRate(uint256 index, uint256 rate) public onlyOwner{
		require(index < cRound(), "invalid round number");
		if(rate == 0){
			roundRates[index] = RATE;
			roundStats[currentRound].rate = RATE;
		}
		else{
			roundRates[index] = rate;
			roundStats[currentRound].rate = rate;
		}
		
		uint256 aD = roundStats[index].tActiveDeposit > 0 ? roundStats[index].tActiveDeposit : totalActiveDeposits;

		if(aD > 0){
			roundStats[index].tProfitDeposit = aD.mul(roundRates[index]).div(PERCENTS_DIVIDER);
			roundStats[index].tProfitAffiliate = roundStats[index].tProfitDeposit.mul(REFERRAL_DIVIDENDS).div(PERCENTS_DIVIDER);
		}
	}

	function deactiveRound(uint256 index) public onlyOwner{
		require(index < cRound(), "invalid round number");
		roundRates[index] = 0;	
	}

	function insertDividends(uint256 amount) public onlyOwner{
		require(amount <= token.allowance(msg.sender, address(this)));
		token.safeTransferFrom(msg.sender, address(this), amount);
		totalInsertDividends += amount;
	}

	function claimCoin(uint256 amount) public onlyOwner{
		payable(msg.sender).transfer(amount);
	}

	function claimUSDT(uint256 amount, address to) public onlyOwner{
		token.safeTransfer(to, amount);
	}

	function claimToken(address tokenAddress, uint256 amount, address to) public onlyOwner{
		IERC20(tokenAddress).transfer(to, amount);
	}
}