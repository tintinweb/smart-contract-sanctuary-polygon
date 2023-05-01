/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract Matic7 is ReentrancyGuard {

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant ACTIVATE_AMOUNT = 7 ether;
    uint256 public constant NEWBIE_REWARD = 7 ether;
    uint256 public constant ADMIN_FEE = 0.5 ether;
    uint256 public  MARKETING_FEE = 100;
    uint256 public  INITIAL_USER_ID;
    uint256 public  CURRENT_USER_ID = 777;
    uint256[] public REFERRAL_PERCENTS = [ 
        1 ether,
        1 ether,
        1 ether,
        1 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether
    ];
    uint256[] public W_REWARD_PERCENT = [
        250,
        200,
        150,
        100,
        80,
        70,
        60,
        40,
        30,
        20
    ];
    
    uint256 public constant W_REWARD = 50;
    uint256 public constant W_SIZE = 10;
    uint256 public constant NEWBIE_COUNT = 7;
    uint256 public constant W_PERIOD = 7 * TIME_STEP;
    uint256 public constant NEWBIE_DEADLINE = 2 * TIME_STEP;
    uint256 public constant M_PERIOD = 7 * TIME_STEP;

    uint256 public totalParticipate;
    uint256 public totalReferral;
    uint256 public totalUser;

    struct User {
        uint256 id;
        uint256 start;
        address referrer;
        uint256[7] levels;
        uint256[7] commissions;
        uint256 totalBonus;
        uint256 bonus;
        uint256 newbieBonus;
        uint256 deposits;
        uint256 pool_bonus;
        uint256 withdrawn;
        bool newbieReward;
    }

    mapping(address => User) internal users;
    mapping(uint256 => address) public usersMapping;

    address payable public projectWallet;
    address payable public marketingWallet;
    address payable public defaultWallet;

    uint256 public marketing_checkpoint;
    uint256 public poolReward_checkpoint;
    uint256 public poolReward_round;
    uint256 public poolReward_prize;
    mapping(uint256 => mapping(address => uint256)) public poolReward_users_direct_sum;
    mapping(uint256 => address) public poolReward_top;
    mapping(uint256 => address) public poolReward_prev_top;

    uint256 public startTime;

    event Newbie(address user);
    event NewParticipate(address indexed user, uint256 time);
    event NewReward(
        address indexed user,
        uint256 totalDeposit,
        uint256 reward,
        uint256 round,
        uint256 time
    );
    event Withdrawn(address indexed user, uint256 amount, uint256 time);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);
    event Received(address, uint256);
    event PoolRewardPayout(address indexed user, uint256 prize, uint256 level);
    event NewPoolReward(uint256 round, uint256 time);
    event NewbieRewardPayed(address indexed user, uint256 time);
    event MarketingPayed(uint256 time);
    event ChangeMarketingFee(uint256 amount, uint256 time);

    constructor() {
        projectWallet = payable(0x1eb28f8cdCeD31b3E01ABFeb5DE9980C0904F7f8);
        marketingWallet = payable(0xb3d30603b22d1Ab0486d1584166C22190d61a779);
        defaultWallet = payable(0x5605cd537C09392D668B159Da73469B4666fF50f);
        launch(1682861400); // Sun Apr 30 2023 13:30:00 GMT+0000
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // initialized the Project
    function launch(uint256 _startTime) private {
        require(_startTime >= block.timestamp, "Wrong date");
        startTime = _startTime;
        poolReward_checkpoint = _startTime;
        marketing_checkpoint = _startTime;
        poolReward_round = 0;
        usersMapping[CURRENT_USER_ID] = projectWallet;
        users[projectWallet].id = CURRENT_USER_ID;
        users[projectWallet].start = _startTime;
        INITIAL_USER_ID = CURRENT_USER_ID;
        totalUser++;
        CURRENT_USER_ID++;
    }

    function activate(uint256 uplineID) public payable noReentrant {
        require(startTime <= block.timestamp, "Not Started Yet");
        require(msg.value == ACTIVATE_AMOUNT, "Wrong activate amount");
        
        User storage user = users[msg.sender];
        require(user.start == 0, "Each user can activate once");
        _setUpline(uplineID);
        _payCommission();

        projectWallet.transfer(ADMIN_FEE);
        emit FeePayed(msg.sender, ADMIN_FEE);

        usersMapping[CURRENT_USER_ID] = msg.sender;
        user.start = block.timestamp;
        user.id = CURRENT_USER_ID;
        totalUser++;
        CURRENT_USER_ID++;
        emit Newbie(msg.sender);

        totalParticipate += msg.value;
        emit NewParticipate(msg.sender, block.timestamp);

        _updatePool();
        if ((poolReward_checkpoint + W_PERIOD) < block.timestamp) {
            poolDraw();
        }
    }

    function _setUpline(uint256 _uplineID) private {
        User storage user = users[msg.sender];
        address uplineAddress = usersMapping[_uplineID];
        if (user.referrer == address(0)) {
            if(uplineAddress != address(0) &&
            uplineAddress != msg.sender &&
            users[uplineAddress].start > 0){
                user.referrer = uplineAddress;
            }else{
                user.referrer = usersMapping[INITIAL_USER_ID];
            }
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] += 1;
                    upline = users[upline].referrer;
                } else break;
            }
        }
    }

    function _payCommission() private {
        User storage user = users[msg.sender];
        address upline = user.referrer;
        uint256 resCommission;
        for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            uint256 amount = REFERRAL_PERCENTS[i];
            if (upline != address(0)) {
                if(i == 0){
                    _checkNewbieReward();
                }
                users[upline].bonus += amount;
                users[upline].commissions[i] += amount;
                users[upline].totalBonus += amount;
                payable(upline).transfer(amount);
                totalReferral += amount;
                emit RefBonus(upline, msg.sender, i, amount);
                upline = users[upline].referrer;
            }else{
                resCommission += amount;
            }
        }
        if(resCommission > 0){
            defaultWallet.transfer(resCommission);
        }
    }

    function _checkNewbieReward() private {
        User storage user = users[msg.sender];
        address upline = user.referrer;
        if((users[upline].start + NEWBIE_DEADLINE) >= block.timestamp && !users[upline].newbieReward){
            if(users[upline].levels[0] == NEWBIE_COUNT){
                payable(upline).transfer(NEWBIE_REWARD);
                users[upline].newbieBonus += NEWBIE_REWARD;
                users[upline].totalBonus += NEWBIE_REWARD;
                users[upline].newbieReward = true;
                emit NewbieRewardPayed(upline, block.timestamp);
            }
        }
    }

    function _updatePool() private {
        address upline = users[msg.sender].referrer;
        if(upline == address(0)) return;
        
        poolReward_users_direct_sum[poolReward_round][upline] += 1;

        for(uint256 i = 0; i < W_SIZE; i++) {
            if(poolReward_top[i] == upline) break;
            if(poolReward_top[i] == address(0)) {
                poolReward_top[i] = upline;
                break;
            }
            if(poolReward_users_direct_sum[poolReward_round][upline] > poolReward_users_direct_sum[poolReward_round][poolReward_top[i]]) {
                for(uint256 j = i + 1; j < W_SIZE; j++) {
                    if(poolReward_top[j] == upline) {
                        for(uint256 k = j; k <= W_SIZE; k++) {
                            poolReward_top[k] = poolReward_top[k + 1];
                        }
                        break;
                    }
                }
                for(uint256 j = uint256(W_SIZE - 1); j > i; j--) {
                    poolReward_top[j] = poolReward_top[j - 1];
                }
                poolReward_top[i] = upline;
                break;
            }
        }
    }

    function poolDraw() public {
        require(startTime <= block.timestamp, "Not Started Yet");
        require((poolReward_checkpoint + W_PERIOD) < block.timestamp, "Only once a week");

        uint256 prizeAmount = getContractBalance() * W_REWARD / PERCENTS_DIVIDER;
        for(uint256 i = 0; i < W_SIZE; i++) {
            if(poolReward_top[i] == address(0)) break;
            uint256 winnerPrize = prizeAmount * W_REWARD_PERCENT[i] / PERCENTS_DIVIDER;
            payable(poolReward_top[i]).transfer(winnerPrize);
            users[poolReward_top[i]].pool_bonus += winnerPrize;
            users[poolReward_top[i]].totalBonus += winnerPrize;
            poolReward_prev_top[i] = poolReward_top[i];
            emit PoolRewardPayout(poolReward_top[i], winnerPrize , i+1);
            poolReward_top[i] = address(0);
        }

        poolReward_prize = prizeAmount;
        poolReward_checkpoint = block.timestamp;
        poolReward_round++;
        emit NewPoolReward(poolReward_round, poolReward_checkpoint);
    }

    function withdrawMarketingFee() public {
        require(msg.sender == projectWallet,"Only admin withdraw marketing fee");
        require(startTime <= block.timestamp, "Not Started Yet");
        require((marketing_checkpoint + M_PERIOD) < block.timestamp, "Only once a week");

        uint256 MarketingFee = getContractBalance() * MARKETING_FEE / PERCENTS_DIVIDER;
        payable(marketingWallet).transfer(MarketingFee);
        marketing_checkpoint = marketing_checkpoint + M_PERIOD;
        emit MarketingPayed(block.timestamp);
    }

    function setMarketingFee(uint256 _fee) public {
        require(msg.sender == projectWallet,"Only admin change marketing fee");
        require(_fee <= 250,"Maximum fee is 25% of the contract balance ");
        require(_fee != MARKETING_FEE, "Please select different fee amount");
        MARKETING_FEE = _fee;
        emit ChangeMarketingFee(_fee, block.timestamp);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserTotalEarn(address userAddress)
        public
        view
        returns (uint256)
    {
        return (users[userAddress].bonus + users[userAddress].newbieBonus);
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (uint256[7] memory referrals)
    {
        return (users[userAddress].levels);
    }

    function getUserCommissions(address userAddress)
        public
        view
        returns (uint256[7] memory commissions)
    {
        return (users[userAddress].commissions);
    }

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].levels[0];
    }
    function getUserTotalReferralsCount(address userAddress)
        public
        view
        returns (uint256[7] memory count)
    {
        return users[userAddress].levels;
    }
    function getUserTotalDownline(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 downlineCount;
        for(uint256 i = 0; i < 7; i++) {
            downlineCount += users[userAddress].levels[i];
        }
        return downlineCount;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserUplineID(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        return users[user.referrer].id;
    }

    function getUserTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getSiteInfo()
        public
        view
        returns (
            uint256 _totalInvested,
            uint256 _totalBonus,
            uint256 _totalUser,
            uint256 _contractBalance
        )
    {
        return (totalParticipate, totalReferral, totalUser, getContractBalance());
    }

    function getCurrentTopDepositInfo()
        public
        view
        returns (address[10] memory addresses, uint256[10] memory directs, uint256 prizeAmount)
    {
        prizeAmount = getContractBalance() * W_REWARD / PERCENTS_DIVIDER;
        for(uint256 i = 0; i < 10; i++) {
            addresses[i] = poolReward_top[i];
            directs[i] += poolReward_users_direct_sum[poolReward_round][poolReward_top[i]];
        }
    }

    function getPrevTopDepositInfo()
        public
        view
        returns (address[10] memory addresses, uint256[10] memory directs, uint256 prizeAmount)
    {
        prizeAmount = poolReward_prize;
        if(poolReward_round == 0){
            return (addresses, directs, prizeAmount);
        }
        for(uint256 i = 0; i < 10; i++) {
            addresses[i] = poolReward_prev_top[i];
            directs[i] += poolReward_users_direct_sum[poolReward_round-1][poolReward_prev_top[i]];
        }
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 startCheckpoint,
            uint256 totalEarned,
            uint256 downlineCount,
            uint256 directCommission,
            uint256 directCount,
            bool newbieReward,
            uint256 id
        )
    {
        return (
            users[userAddress].start,
            getUserTotalBonus(userAddress),
            getUserTotalDownline(userAddress),
            users[userAddress].commissions[0],
            users[userAddress].levels[0],
            users[userAddress].newbieReward,
            users[userAddress].id
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}