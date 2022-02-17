/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract FoodStake is Ownable {

	IERC20 public erctoken;
	address public projectWallet = 0x8596Ff28E69b2212D51Ab7a3348623b710850C39;
	address private token = 0x6F06e6beD64cF4c4187c06Ee2a4732f6a171BC4e; /** token **/
	/** default percentages **/
	uint256 public projectFee = 80;
	uint256 public REFERRAL_PERCENT = 30;
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	/* whale control features. **/
	uint256 public CUTOFF_STEP = 240 * 60 * 60;
	uint256 public WITHDRAW_COOLDOWN = 0 * 60 * 60;
	uint256 public MAX_WITHDRAW = 120000000000 * 1e18;

    /** deposits after this timestamp timestamp get additional percentages **/
    uint256 public PERCENTAGE_BONUS_STARTTIME = 0;
	uint256 public PERCENTAGE_BONUS_PLAN_1 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_2 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_3 = 0;
    uint256 public PERCENTAGE_BONUS_PLAN_4 = 0;

	/* RAFFLE */
    uint256 public RAFFLE_START_TIME;
	uint256 public RAFFLE_STEP = 7 days;
    uint256 public RAFFLE_PERCENT = 20;
	uint256 public RAFFLE_TICKET_PRICE = 900 * 1e18;
    uint256 public MANLottoPrice = 1000 * 1e18;
    uint256 public MAX_RAFFLE_TICKET = 100;
    uint256 public MAX_RAFFLE_PARTICIPANTS = 100;
    uint256 public RAFFLERound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

    /* project statistics **/
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalRefBonus;
    uint256 public totalRAFFLEBonus;
	uint256 public totalInvestorCount;
    uint256 public investGate = 1;
    //save storage - opt.
    bool public RAFFLE_ENABLED;
	uint8 public PLAN_FOR_RAFFLE = 0;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 mininvest;

        /** plan statistics **/
        uint256 planTotalInvestorCount;
        uint256 planTotalInvestments;
        uint256 planTotalReInvestorCount;
        uint256 planTotalReInvestments;
        
        bool planActivated;
    }
    
	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		bool reinvested;
	}
	
	struct RAFFLEHistory {
        uint256 round;
        uint256 pot;
        uint256 totalRAFFLEParticipants;
        uint256 totalRAFFLETickets;
        uint8 investedPlan;
        address winnerAddress; 
    }
    
    Plan[] internal plans;
    RAFFLEHistory[] internal RaffleHistory;

	struct User {
		Deposit[] deposits;
		mapping (uint8 => uint256) checkpoints; /** a checkpoint for each plan **/
		uint256 cutoff;
		uint256 totalInvested;
		uint256 referralsCount;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 reinvested;
        uint256 RAFFLEBonus;
        uint256 totalRAFFLEBonus;
		uint256 totalDepositAmount;
		address referrer;
	}

	mapping (address => User) internal users;

	/* RAFFLE */
	mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned tickets
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address
    event RAFFLEWinner(address indexed investor, uint256 pot, uint256 indexed round);

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    bool public started;

	constructor() {erctoken = IERC20(token);}
	
	function pushPlan(
	uint256 p1day, uint256 p1per, uint256 p1min,
	uint256 p2day, uint256 p2per, uint256 p2min,
	uint256 p3day, uint256 p3per, uint256 p3min,
	uint256 p4day, uint256 p4per, uint256 p4min)
	public onlyOwner {
	plans.push(Plan(p1day, p1per, p1min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p2day, p2per, p2min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p3day, p3per, p3min * 1e18, 0, 0, 0, 0, true));
    plans.push(Plan(p4day, p4per, p4min * 1e18, 0, 0, 0, 0, true));
	}
	
	function startContract() public onlyOwner{
        require(started == false, "Contract already started");
        started = true;
		RAFFLE_ENABLED = true;
		RAFFLE_START_TIME = block.timestamp;
    }

	function invest(address referrer, uint8 plan, uint256 amounterc) public {
        require(investGate == 1);
		require(started, "Contract not yet started");
        require(plan < plans.length, "Invalid Plan.");
        require(amounterc >= plans[plan].mininvest, "Less than minimum amount required for the selected Plan.");
		require(plans[plan].planActivated, "Plan selected is disabled");


		User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount+(1);
            }
        }
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = amounterc*(REFERRAL_PERCENT)/(PERCENTS_DIVIDER);
                users[upline].bonus = users[upline].bonus+(amount);
                users[upline].totalBonus = users[upline].totalBonus+(amount);
                totalRefBonus = totalRefBonus+(amount);
                emit RefBonus(upline, msg.sender, amount);
            }
        }

        /** new user gets current time + CUTOFF_STEP for initial time window **/
		if (user.deposits.length == 0) {
			user.checkpoints[plan] = block.timestamp;
			user.cutoff = block.timestamp+(CUTOFF_STEP);
			emit Newbie(msg.sender);
		}

        /** deposit from new invest **/
		user.deposits.push(Deposit(plan, amounterc, block.timestamp, false));

		user.totalInvested = user.totalInvested+(amounterc);
		totalInvested = totalInvested+(amounterc);

		/** statistics **/
		totalInvestorCount = totalInvestorCount+(1);
		plans[plan].planTotalInvestorCount = plans[plan].planTotalInvestorCount+(1);
		plans[plan].planTotalInvestments = plans[plan].planTotalInvestments+(amounterc);

		emit NewDeposit(msg.sender, plan, amounterc);
	}

	function reinvest(uint8 plan) public {
		require(investGate == 1);
		require(started, "Not started yet");
        require(plan < plans.length, "Invalid plan");
        require(plans[plan].planActivated, "Plan selected is disabled.");


        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender, int8(plan));

		user.deposits.push(Deposit(plan, totalAmount, block.timestamp, true));

        user.reinvested = user.reinvested+(totalAmount);
        user.checkpoints[plan] = block.timestamp;
        user.cutoff = block.timestamp+(CUTOFF_STEP);

        /** statistics **/
		totalReInvested = totalReInvested+(totalAmount);
		plans[plan].planTotalReInvestments = plans[plan].planTotalReInvestments+(totalAmount);
		plans[plan].planTotalReInvestorCount = plans[plan].planTotalReInvestorCount+(1);

		emit ReinvestedDeposit(msg.sender, plan, totalAmount);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount+(referralBonus);
		}

        uint256 RAFFLEBonus = getUserRAFFLEBonus(msg.sender);
        if (RAFFLEBonus > 0) {
			user.RAFFLEBonus = 0;
			totalAmount = totalAmount+(RAFFLEBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = erctoken.balanceOf(address(this));

		if (contractBalance < totalAmount) {
			user.bonus = totalAmount-(contractBalance);
			user.totalBonus = user.totalBonus+(user.bonus);
			totalAmount = contractBalance;
		}

        for(uint8 i = 0; i < plans.length; i++){

            /** user can only withdraw every after 8 hours from last withdrawal. **/
            if(user.checkpoints[i]+(WITHDRAW_COOLDOWN) > block.timestamp){
               revert("Withdrawals can only be made every after 8 hours.");
            }

            /** global withdraw will reset checkpoints on all plans **/
		    user.checkpoints[i] = block.timestamp;
        }

        /** Excess dividends are sent back to the user's account available for the next withdrawal. **/
        if(totalAmount > MAX_WITHDRAW) {
            user.bonus = totalAmount-(MAX_WITHDRAW);
            totalAmount = MAX_WITHDRAW;
        }

        /** global withdraw will also reset CUTOFF **/
        user.cutoff = block.timestamp+(CUTOFF_STEP);
		user.withdrawn = user.withdrawn+(totalAmount);

        erctoken.transfer(msg.sender, totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	

	function getUserDividends(address userAddress, int8 plan) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		uint256 endPoint = block.timestamp < user.cutoff ? block.timestamp : user.cutoff;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(plan > -1){
		        if(user.deposits[i].plan != uint8(plan)){
		            continue;
		        }
		    }
			uint256 finish = user.deposits[i].start+(plans[user.deposits[i].plan].time*(1 days));
			/** check if plan is not yet finished. **/
			if (user.checkpoints[user.deposits[i].plan] < finish) {

			    uint256 percent = plans[user.deposits[i].plan].percent;
			    if(user.deposits[i].start >= PERCENTAGE_BONUS_STARTTIME){
                    if(user.deposits[i].plan == 0){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_1);
                    }else if(user.deposits[i].plan == 1){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_2);
                    }else if(user.deposits[i].plan == 2){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_3);
                    }else if(user.deposits[i].plan == 3){
                        percent = percent+(PERCENTAGE_BONUS_PLAN_4);
                    }
			    }

				uint256 share = user.deposits[i].amount*(percent)/(PERCENTS_DIVIDER);

				uint256 from = user.deposits[i].start > user.checkpoints[user.deposits[i].plan] ? user.deposits[i].start : user.checkpoints[user.deposits[i].plan];
				/** uint256 to = finish < block.timestamp ? finish : block.timestamp; **/
				uint256 to = finish < endPoint ? finish : endPoint;
				if (from < to) {
					totalAmount = totalAmount+(share*(to-(from))/(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	// RAFFLE section!
    function _buyTickets(address userAddress, uint256 amount) private {

        uint256 userTickets = ticketOwners[RAFFLERound][userAddress];
        uint256 numTickets = amount;
        
        //if the user has no tickets before this point, but they just purchased a ticket
        if(userTickets == 0) {
            participantAdresses[RAFFLERound][participants] = userAddress;
            
            if(numTickets > 0){
              participants = participants+(1);
            }
        }
        
        if (userTickets+(numTickets) > MAX_RAFFLE_TICKET) {
            numTickets = MAX_RAFFLE_TICKET-(userTickets);
        }

        ticketOwners[RAFFLERound][userAddress] = userTickets+(numTickets);
        uint256 RAFFLEAmount = amount*RAFFLE_TICKET_PRICE;
        currentPot = currentPot+(RAFFLEAmount);
        totalTickets = totalTickets+(numTickets);

        if(block.timestamp-(RAFFLE_START_TIME) >= RAFFLE_STEP || participants == MAX_RAFFLE_PARTICIPANTS) {
            chooseWinner();
        }
    }

        function buyTickets(uint256 amount) public {
        require(amount != 0, "zero purchase amount");
        require(amount + totalTickets <= MAX_RAFFLE_TICKET);
        if(users[msg.sender].deposits.length == 0) {
            require(
            erctoken.transferFrom(
                address(msg.sender),
                address(this),
                amount * MANLottoPrice
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
        } else {
            require(
            erctoken.transferFrom(
                address(msg.sender),
                address(this),
                amount * RAFFLE_TICKET_PRICE
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
        }
         _buyTickets(msg.sender,amount);
    }
    
    // will auto execute, when condition is met.
    function chooseWinner() public {
		require(
            ((block.timestamp-(RAFFLE_START_TIME) >= RAFFLE_STEP) || participants == MAX_RAFFLE_PARTICIPANTS),
            "RAFFLE much run for RAFFLE_STEP or there must be MAX_RAFFLE_PARTICIPANTS particpants"
        );
		uint256[] memory init_range = new uint256[](participants);
		uint256[] memory end_range = new uint256[](participants);

		uint256 last_range = 0;

		for(uint256 i = 0; i < participants; i++){
			uint256 range0 = last_range+(1);
			uint256 range1 = range0+(ticketOwners[RAFFLERound][participantAdresses[RAFFLERound][i]]/(1e18));

			init_range[i] = range0;
			end_range[i] = range1;
			last_range = range1;
		}

		uint256 random = _getRandom()%(last_range)+(1);
		for(uint256 i = 0; i < participants; i++){
			if((random >= init_range[i]) && (random <= end_range[i])) {
				// winner found
				address winnerAddress = participantAdresses[RAFFLERound][i];
                _payRAFFLEWinner(winnerAddress);
				
				// reset RAFFLERound
				currentPot = 0;
				participants = 0;
				totalTickets = 0;
				RAFFLE_START_TIME = block.timestamp;
				RAFFLERound = RAFFLERound+(1);
				break;
			}
      	}
    }

    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp, currentPot, block.difficulty, totalInvested, erctoken.balanceOf(address(this)))));
    }

    function _payRAFFLEWinner(address userAddress) private {
        User storage user = users[userAddress];
        uint8 plan = PLAN_FOR_RAFFLE;
        uint256 totalFee = currentPot * (1/projectFee);
        //% of the current pot will be put into the project wallet.
		erctoken.transfer(projectWallet, totalFee);
		
		currentPot = currentPot-(totalFee);

        // half is added to available rewards balance
        user.RAFFLEBonus = user.RAFFLEBonus+(currentPot);
        user.totalRAFFLEBonus = user.totalRAFFLEBonus+(currentPot);

        /** statistics **/
        totalRAFFLEBonus = totalRAFFLEBonus+(currentPot);
        //record RAFFLE round and winner
        RaffleHistory.push(RAFFLEHistory(RAFFLERound, currentPot, participants, totalTickets, plan, userAddress));
        emit RAFFLEWinner(userAddress, currentPot, RAFFLERound);
    }	
    
	function getUserActiveProjectInvestments(address userAddress) public view returns (uint256){
	    uint256 totalAmount;

		/** get total active investments in all plans. **/
        for(uint8 i = 0; i < plans.length; i++){
              totalAmount = totalAmount+(getUserActiveInvestments(userAddress, i));  
        }
        
	    return totalAmount;
	}

	function getUserActiveInvestments(address userAddress, uint8 plan) public view returns (uint256){
	    User storage user = users[userAddress];
	    uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {

	        if(user.deposits[i].plan != uint8(plan)){
	            continue;
	        }

			uint256 finish = user.deposits[i].start+(plans[user.deposits[i].plan].time*(1 days));
			if (user.checkpoints[uint8(plan)] < finish) {
			    /** sum of all unfinished deposits from plan **/
				totalAmount = totalAmount+(user.deposits[i].amount);
			}
		}
	    return totalAmount;
	}

	function getRAFFLEHistory(uint256 index) public view returns(uint256 round, address winnerAddress, uint256 pot, 
	  uint256 totalRAFFLEParticipants, uint256 totalRAFFLETickets, uint8 investedPlan) {
		round = RaffleHistory[index].round;
		winnerAddress = RaffleHistory[index].winnerAddress;
		pot = RaffleHistory[index].pot;
		totalRAFFLEParticipants = RaffleHistory[index].totalRAFFLEParticipants;
		totalRAFFLETickets = RaffleHistory[index].totalRAFFLETickets;
		investedPlan = RaffleHistory[index].investedPlan;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent, uint256 minimumInvestment,
	  uint256 planTotalInvestorCount, uint256 planTotalInvestments , uint256 planTotalReInvestorCount, uint256 planTotalReInvestments, bool planActivated) {
		time = plans[plan].time;
		percent = plans[plan].percent;
		minimumInvestment = plans[plan].mininvest;
		planTotalInvestorCount = plans[plan].planTotalInvestorCount;
		planTotalInvestments = plans[plan].planTotalInvestments;
		planTotalReInvestorCount = plans[plan].planTotalReInvestorCount;
		planTotalReInvestments = plans[plan].planTotalReInvestments;
		planActivated = plans[plan].planActivated;
	}
	
	function getRAFFLEInfo() public view returns (uint256 getRAFFLERound, uint256 getRAFFLEStartTime,  uint256 getRAFFLEStep, uint256 getRAFFLETicketPrice, uint256 getRAFFLECurrentPot, 
	  uint256 getRAFFLEParticipants, uint256 getMaxRAFFLEParticipants, uint256 getTotalRAFFLETickets, uint256 getRAFFLEPercent, uint256 getMaxRAFFLETicket, uint8 getPlanForRAFFLE){
		getRAFFLEStartTime = RAFFLE_START_TIME;
		getRAFFLEStep = RAFFLE_STEP;
		getRAFFLETicketPrice = RAFFLE_TICKET_PRICE;
		getMaxRAFFLEParticipants = MAX_RAFFLE_PARTICIPANTS;
		getRAFFLERound = RAFFLERound;
		getRAFFLECurrentPot = currentPot;
		getRAFFLEParticipants = participants;
	    getTotalRAFFLETickets = totalTickets;
		getRAFFLEPercent = RAFFLE_PERCENT;
    	getMaxRAFFLETicket = MAX_RAFFLE_TICKET;
	    getPlanForRAFFLE = PLAN_FOR_RAFFLE;
	}

	function getContractBalance() public view returns (uint256) {
		return erctoken.balanceOf(address(this));
	}
	
	function getContractBalanceLessRAFFLEPot() public view returns (uint256) {
		return erctoken.balanceOf(address(this));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
	    return getUserDividends(userAddress, -1);
	}

	function getUserCutoff(address userAddress) public view returns (uint256) {
      return users[userAddress].cutoff;
    }

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress, uint8 plan) public view returns(uint256) {
		return users[userAddress].checkpoints[plan];
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

    function getUserTotalReferrals(address userAddress) public view returns (uint256){
        return users[userAddress].referralsCount;
    }

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
	    return users[userAddress].bonus;
	}

    function getUserRAFFLEBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].RAFFLEBonus;
	}

    function getUserTotalRAFFLEBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRAFFLEBonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus-(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress)+(getUserDividends(userAddress))+(getUserRAFFLEBonus(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount+(users[userAddress].deposits[i].amount);
		}
	}

	function getUserActiveRAFFLETickets(address userAddress) public view returns(uint256 ticketCount) {
	   ticketCount = ticketOwners[RAFFLERound][userAddress];
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, bool reinvested) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start+(plans[user.deposits[index].plan].time*(1 days));
		reinvested = user.deposits[index].reinvested;
	}

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus, uint256 _totalRAFFLEBonus) {
        return (totalInvested, totalRefBonus, totalRAFFLEBonus);
    }

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals, uint256 totalRAFFLE) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress), getUserTotalRAFFLEBonus(userAddress));
	}

	/** Get Block Timestamp **/
	function getBlockTimeStamp() public view returns (uint256) {
	    return block.timestamp;
	}

	/** Get Plans Length **/
	function getPlansLength() public view returns (uint256) {
	    return plans.length;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /** Add additional plans in the Plan structure. **/
    function ADD_NEW_PLAN(uint256 time, uint256 percent, uint256 mininvest, bool planActivated) external onlyOwner{
        plans.push(Plan(time, percent, mininvest, 0, 0, 0, 0, planActivated));
    }

    function ADD_PERCENT_STARTTIME(uint256 value) external onlyOwner {
        PERCENTAGE_BONUS_STARTTIME = value;
    }

    function ADD_PLAN1_BONUS(uint256 value) external onlyOwner{
        PERCENTAGE_BONUS_PLAN_1 = value;
    }

    function ADD_PLAN2_BONUS(uint256 value) external onlyOwner {
        PERCENTAGE_BONUS_PLAN_2 = value;
    }

    function ADD_PLAN3_BONUS(uint256 value) external onlyOwner{
        PERCENTAGE_BONUS_PLAN_3 = value;
    }

    function ADD_PLAN4_BONUS(uint256 value) external onlyOwner{
        PERCENTAGE_BONUS_PLAN_4 = value;
    }

    function CHANGE_PROJECT_WALLET(address value) external onlyOwner{
        projectWallet = value;
    }

    function CHANGE_PROJECT_FEE(uint256 value) external onlyOwner{
        projectFee = value;
    }

    function setPercentDiv(uint256 value) external onlyOwner{
        PERCENTS_DIVIDER = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external onlyOwner{
        REFERRAL_PERCENT = value;
    }

    function SET_PLAN_PERCENT(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].percent = value;
    }

    function SET_PLAN_TIME(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].time = value;
    }

    function SET_PLAN_MIN(uint8 plan, uint256 value) external onlyOwner{
        plans[plan].mininvest = value * 1e18;
    }

    function SET_PLAN_ACTIVE(uint8 plan, bool value) external onlyOwner{
        plans[plan].planActivated = value;
    }

    function SET_CUTOFF_STEP(uint256 value) external onlyOwner{
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external onlyOwner{
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_MAX_WITHDRAW(uint256 value) external onlyOwner{
        MAX_WITHDRAW = value * 1e18;
    }

    /* RAFFLE setters */
	function SET_RAFFLE_ENABLED(bool value) external onlyOwner{
        RAFFLE_ENABLED = value;
    }

    function SET_RAFFLE_START_TIME(uint256 value) external onlyOwner{
        RAFFLE_START_TIME = value * 1 days;
    }

    function SET_RAFFLE_STEP(uint256 value) external onlyOwner{
        require(value >= 1 && value < 31); /** 1 month max **/
        RAFFLE_STEP = value * 1 days;
    }

    function SET_RAFFLE_PERCENT(uint256 value) external onlyOwner{
        RAFFLE_PERCENT = value;
    }

    function SET_RAFFLE_TICKET_PRICE(uint256 value) external onlyOwner{
        RAFFLE_TICKET_PRICE = value * 1e18;
    }

    function SET_MAX_RAFFLE_TICKET(uint256 value) external onlyOwner{
        MAX_RAFFLE_TICKET = value;
    }

    function SET_MAX_RAFFLE_PARTICIPANTS(uint256 value) external onlyOwner{
        MAX_RAFFLE_PARTICIPANTS = value;
    }

    function SET_PLAN_FOR_RAFFLE(uint8 plan) external onlyOwner{
        require(plan < plans.length, "Invalid plan");
        require(plans[plan].planActivated, "Plan selected is disabled.");
        PLAN_FOR_RAFFLE = plan;
    }

    function setManLottoPrice(uint256 value) external onlyOwner{
        MANLottoPrice = value;
    }

    function adminDepo(uint256 amount) external onlyOwner{
           require(
            erctoken.transferFrom(
                address(msg.sender),
                address(this),
                amount
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
    }
    function adminWithdraw(uint256 amount) external onlyOwner{
        require(
            erctoken.transfer(
                address(msg.sender),
                amount
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
    }

    function setInvestGate(uint256 value) external onlyOwner {
        investGate = value;
    }
}