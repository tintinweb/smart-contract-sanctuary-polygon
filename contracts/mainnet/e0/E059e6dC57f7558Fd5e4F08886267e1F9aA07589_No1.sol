// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ReentrancyGuard.sol";
import "./Bucket.sol";
import "./IERC20.sol";

contract No1 is ReentrancyGuard, Bucket {
    uint256 public constant PRINCIPAL_RATIO = 650000;  
    uint256 public constant INVEST_RATIO = 260000; 
    uint256 public constant PLATFORM_RATIO = 20000;  
    uint256 public constant REFERRER_RATIO = 70000;  
    uint256 public constant INCENTIVE_RATIO = 0; 
    uint256 public constant PRICE_PRECISION = 1e6;
    uint256 public start_time;
    uint256 public start_hour;
    uint256 public limit_order = 30;
    uint256 public day_number = 9600*10**18;//9600*10**18
    uint256 public Growth_limit = 10;
    uint256 public All_Number = 0;
    uint256 public hour_number;
  
    uint256 public limit_hours = 1 days;// 1 days
    mapping(address => uint256)public order_time;
    uint256 public constant DEFAULT_INVEST_RETURN_RATE = 10000;  
    uint256 public constant BOOST_INVEST_RETURN_RATE = 5000; 
    uint256 public hourEach;
    mapping(uint256 => uint256)public hourLimitNumber;
    uint256 public  MAX_INVEST = 1e20; 
    uint256 public  MIN_INVEST = 1e18; 
    uint256 public constant TIME_UNIT = 1 days; 

    uint256[6] public DEFAULT_TARGET_AMOUNTS = [13e21, 25e21, 35e21, 50e21, 75e21, 125e21];
    uint256 public constant MAX_SEARCH_DEPTH = 50;
    uint256 public constant RANKED_INCENTIVE = 60;
    address public platformAddress; 
    address public TokenAddress=0x5412F32CDC25c491DC2bd881131Dc3FAD620a7c8;

    uint256[6] public currentEpochs;
    mapping(uint256 => mapping(address => uint256))public isappointment;
   
    mapping(uint256 => mapping(address => PositionInfo[]))[6] public roundLedgers;
   
    mapping(uint256 => RoundInfo)[6] public roundInfos;
  
    mapping(address => UserRoundInfo[])[6] public userRoundsInfos;
    mapping(uint256 => uint256)public typeOpen;
    mapping(address => UserGlobalInfo) public userGlobalInfos;

    mapping(address => address[]) public children; 
    mapping(address => AppointmentInfo[])public UserAppointment;
    mapping(uint256 => mapping(address => AppointmentInfo[]))public AppointmentParams;
    mapping(address => address)public AppointmentAgents;

    address public tempAdmin;
    address public operator;
    bool public gamePaused;
    bool public AppointmentPaused;
    uint256 public tokenPrice = 10*10**18;
    address public fundAddress=0x93Ea25D608D285952AC9bF7B76d4Ce11Ee6065c7;
    struct FundTarget {
        uint256 lastCheckTime;
        uint256 amount;
        uint256 achievedAmount;
    }
    uint256 public limitNumber=1;
    struct UserGlobalInfo {
        // referrer chain to record the referrer relationship
        address referrer;
        // referrer rearward vault
        uint256 totalReferrerReward;
        uint256 referrerRewardClaimed;
        // boost credit
        uint256 boostCredit;
        // sales record
        uint256 maxChildrenSales;
        uint256 sales;
        uint256 totalPositionAmount;
        uint256 reportedSales;
        uint8 salesLevel;
    }

    struct PositionInfo {
        uint256 amount;
        uint256 openTime;
        uint256 expiryTime;
        uint256 investReturnRate;
        uint256 withdrawnAmount;
        uint256 incentiveAmount;
        uint256 investReturnAmount;
        uint256 index;//id
        bool incentiveClaimable;
   
    }
    struct AppointmentInfo{
        uint256 amount;
        uint256 ledgerType;
        uint256 hour_each;
        uint256 createTime;
        uint256 status;

    }
    struct LinkedPosition {
        address user;
        uint256 userPositionIndex;
    }

    struct RoundInfo {
        FundTarget fundTarget;
        uint256 totalPositionAmount; // total amount of all positions
        uint256 currentPrincipalAmount; // current principal amount
        uint256 currentInvestAmount; // current invest amount
        uint256 totalPositionCount; // total count of all positions
        uint256 currentPositionCount; // total count of all open positions
        uint256 currentIncentiveAmount; // current incentive amount
        uint256 incentiveSnapshot; // check total position of last N positions
        uint256 head; // head of linked position for last N positions
        mapping(uint256 => LinkedPosition) linkedPositions; // used for incentive track
        mapping(address => uint256) ledgerRoundToUserRoundIndex; // this round index in userRoundsInfos
        bool stopLoss; // default false means the round is running
    }

    struct UserRoundInfo {
        uint256 epoch;
        uint256 totalPositionAmount;
        uint256 currentPrincipalAmount;
        uint256 totalWithdrawnAmount;
        uint256 totalIncentiveClaimedAmount;
        uint256 totalClosedPositionCount;
        uint256 returnRateBoostedAmount;
    }

    struct ReferrerSearch {
        uint256 currentUserSales;
        uint256 currentReferrerSales;
        address currentReferrer;
        uint256 currentReferrerAmount;
        uint256 levelDiffAmount;
        uint256 leftLevelDiffAmount;
        uint256 levelDiffAmountPerLevel;
        uint256 levelSearchAmount;
        uint256 leftLevelSearchAmount;
        uint256 levelSearchAmountPerReferrer;
        uint256 levelSearchSales;
        uint256 currentReferrerMaxChildSales;
        uint256 currentUserTotalPosAmount;
        uint256 currentUserReportedSales;
        address currentUser;
        uint8 depth;
        uint8 levelSearchStep;
        uint8 currentLevelDiff;
        uint8 numLevelSearchCandidate;
        uint8 baseSalesLevel;
        uint8 currentReferrerLevel;
        bool levelDiffDone;
        bool levelSearchDone;
        bool levelSalesDone;
    }

    struct OpenPositionParams {
        uint256 principalAmount;
        uint256 investAmount;
        uint256 referrerAmount;
        uint256 incentiveAmount;
        uint256 investReturnRate;
    }

    event PositionOpened(
        address indexed user,
        uint256 indexed ledgeType,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );

    event PositionClosed(
        address indexed user,
        uint256 indexed ledgeType,
        uint256 indexed epoch,
        uint256 positionIndex,
        uint256 amount
    );
    
    event NewReferrer(address indexed user, address indexed referrer);
    event NewRound(uint256 indexed epoch, uint256 indexed ledgeType);
    event ReferrerRewardAdded(address indexed user, uint256 amount, uint256 indexed rewardType); // type 0 for levelDiff, 1 for levelSearch, 2 for levelSearch
    event ReferrerRewardClaimed(address indexed user, uint256 amount);
    event SalesLevelUpdated(address indexed user, uint8 level);
    event IncentiveClaimed(address indexed user, uint256 amount);
   
    modifier notContract() {
        require(msg.sender == tx.origin, "Contract not allowed");
        _;
    }

    /**
     * @param _platformAddress The address of the platform
     * @param _tempAdmin The address of the temp admin
     * @param _operator The address of the operator
     */
    constructor(
        address _platformAddress,
        address _tempAdmin,
        address _operator
      
    ) {
        require(
            _platformAddress != address(0) && _tempAdmin != address(0) && _operator != address(0),
            "Invalid address provided"
        );
        emit NewRound(0, 0);
        emit NewRound(0, 1);
        emit NewRound(0, 2);
        emit NewRound(0, 3);
        emit NewRound(0, 4);
        emit NewRound(0, 5);

        tempAdmin = _tempAdmin;
        operator = _operator;
        platformAddress = _platformAddress;
      
        gamePaused = false;
    }

    /**
     * @notice Set the game paused status
     * @param _paused: The game paused status  
     */
    function setPause(bool _paused) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
 
        if(_paused == false){
            start_hour = block.timestamp;
            start_time = block.timestamp;
        }
        gamePaused = _paused;
    }
 function setAppointmentPaused(bool _paused) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
 
        AppointmentPaused = _paused;
    }

     function setplatformAddress(address _platformAddress) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        platformAddress = _platformAddress;
    }
    
     function setLimit_order(uint256 _limit_order) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        limit_order = _limit_order;
    }
       
     function setDay_number(uint256 _day_number) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        day_number = _day_number;
    }
        function seNumber(uint256 _min_number,uint256 _max_number) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        MIN_INVEST = _min_number;
        MAX_INVEST = _max_number;
    }

     function seGrowth_limit(uint256 _Growth_limit) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        Growth_limit = _Growth_limit;
    }

 
    function get_hourEach()public view returns(uint256){
           require(block.timestamp > start_time);
            uint256 Interval_time = block.timestamp - start_hour;
            return Interval_time/limit_hours;
    }
 
     function setFundaddress(address _fundAddress) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        fundAddress = _fundAddress;
    }
 
   
      function settypeOpen(uint256 _typeOpen,uint256 _value) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        typeOpen[_typeOpen] = _value;
    }
   
     function setTokenPrice(uint256 _tokenPrice) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        tokenPrice = _tokenPrice;
    }
    function setlimitNumber(uint256 _limitNumber) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        limitNumber = _limitNumber;
    
    }
   
     function sethour(uint256 _limit_hours) external {
        require(msg.sender == tempAdmin, "Only tempAdmin");
        limit_hours = _limit_hours;
    
    }
    /**
     * @notice Transfer operator 
     */
    function transferOperator(address _operator) external {
        require(msg.sender == operator, "Only operator");
        require(_operator != address(0), "Invalid address");
        operator = _operator;
    }

    /**
     * @notice Drop the temp admin privilege
     */

  function setTempAdmin(address _tempAdmin) external {
        require(msg.sender == operator, "Only admin");
        tempAdmin = _tempAdmin;
    }
   function hour_limit_number()public view returns(uint256){
       uint256 day_hours = 24 hours/limit_hours;
       uint256 hour_limit_number = day_number/day_hours;
       return hour_limit_number;
   }
    /**
     * @notice Batch set referrer information for users
     * @param users: The users to set
     * @param referrers: The referrers to set
     * @param salesLevels: The sales levels to set 
     */
    function batchSetReferrerInfo(
        address[] calldata users,
        address[] calldata referrers,
        uint8[] calldata salesLevels
    ) external {
        require(msg.sender == tempAdmin, "Only admin");
        require(users.length == referrers.length && users.length == salesLevels.length, "Invalid input");
        UserGlobalInfo storage userGlobalInfo;
        uint256 userLength = users.length;
        for (uint256 i = 0; i < userLength; ++i) {
            require(users[i] != address(0), "Invalid address provided");
            userGlobalInfo = userGlobalInfos[users[i]];
            // require(userGlobalInfo.referrer == address(0), "Referrer already set");//去除上级判断
            userGlobalInfo.referrer = referrers[i];
            userGlobalInfo.salesLevel = salesLevels[i];
            children[referrers[i]].push(users[i]);
        }
    }

    /**
     * @notice Set fixed stock distribution to specific ledger type
     * @param ledgerType: The ledger type to set
     * @param typeDays: The days to set
     * @param stock: The stock to set  
     */
    function setStock(
        uint256 ledgerType,
        uint8[] calldata typeDays,
        uint16[] calldata stock
    ) external {
        require(ledgerType > 0, "Invalid ledger type");
        require(ledgerType < 6, "Invalid ledger type");
        require(msg.sender == tempAdmin, "Only admin");
        require(stock.length > 0, "Invalid stock array");
        require(typeDays.length == stock.length, "Invalid params");

        _setStock(ledgerType, typeDays, stock);
    }
 
    function setToken(
        address _TokenAddress
       
    ) external {
        require(_TokenAddress != address(0x0), "Invalid Address");
        require(msg.sender == tempAdmin, "Only admin");

      TokenAddress = _TokenAddress;
    }
 
    function appointment(uint256 ledgerType,uint256 _number,address _referrer,uint256 _hourEach)external notContract nonReentrant{
         require(order_time[msg.sender] + limit_order <= block.timestamp);
      
         require(ledgerType < 6, "Invalid ledger type");
        require(typeOpen[ledgerType] == 0);
        require(_number>= MIN_INVEST, "Too small");
        require(_number <= MAX_INVEST, "Too large");
      
        
        // for(i;i<get_hourEach() + limitNumber;i++){
        //     if( hourLimitNumber[i]+_number < hour_limit_number()){
        //          _hourEach = i;
        //         break;
        //     }
        // }
        require(get_hourEach() <_hourEach,"not hour each");
       
         IERC20(TokenAddress).transferFrom(msg.sender,address(this),_number);
         hourLimitNumber[_hourEach] = hourLimitNumber[_hourEach] + _number;
        All_Number = All_Number + _number;
        AppointmentInfo memory _AppointmentInfo;
       _AppointmentInfo = AppointmentInfo({
                amount:_number,
                ledgerType:ledgerType,
                hour_each:_hourEach,
                createTime:block.timestamp,
         
                 status:1
            });
         AppointmentAgents[msg.sender] = _referrer;
        AppointmentParams[_hourEach][msg.sender].push(_AppointmentInfo);
        isappointment[_hourEach][msg.sender] = 1;
        UserAppointment[msg.sender].push(_AppointmentInfo);
        
        order_time[msg.sender] = block.timestamp;
    }
    /**
     * @notice Open a new position
     * @param ledgerType: The ledger type to open
     * @param targetEpoch: The target epoch to open
     * @param referrer: The expected referrer    
     */
    function openPosition(
        uint256 ledgerType,
        uint256 targetEpoch,
        address referrer,
        uint256 index,
        uint256 token_number
     
    ) external payable notContract nonReentrant {     
       if(index != 100000000){
             require(AppointmentParams[get_hourEach()][msg.sender][index].status == 1);   
             require(token_number ==  AppointmentParams[get_hourEach()][msg.sender][index].amount);
             require(ledgerType ==  AppointmentParams[get_hourEach()][msg.sender][index].ledgerType);
             require(get_hourEach() ==  AppointmentParams[get_hourEach()][msg.sender][index].hour_each);    
       }else{
         require(typeOpen[ledgerType] == 0);
        require(order_time[msg.sender] + limit_order <= block.timestamp);
        if(start_time + 1 days <= block.timestamp){
            start_time = block.timestamp;
            day_number = day_number + day_number*Growth_limit/100;
        }
         require(All_Number+token_number <= day_number);
         require(hourLimitNumber[get_hourEach()] + token_number < hour_limit_number(),"Invalid place_number");
       }
        require(ledgerType < 6, "Invalid ledger type");
        require(targetEpoch == currentEpochs[ledgerType], "Invalid epoch");
        require(token_number>= MIN_INVEST, "Too small");
        require(token_number <= MAX_INVEST, "Too large");
        require(!gamePaused, "Paused");
        // uint256 _pay_type = params[0];
        // load user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];
        // load global round info
        RoundInfo storage roundInfo = roundInfos[ledgerType][targetEpoch];
        // placeholder for user round info
        UserRoundInfo storage userRoundInfo;    
        // determine referrer
        {
            address _referrer = userGlobalInfo.referrer;
            // if referrer is already set or msg.sender is the root user whose referrer is address(0)
            if (_referrer == address(0) && children[msg.sender].length == 0) {
                // if referrer is not set, set it and make sure it is a valid referrer
                require(referrer != address(0) && referrer != msg.sender, "Invalid referrer");
                // make sure referrer is registered already
                require(
                    userGlobalInfos[referrer].referrer != address(0) || children[referrer].length > 0,
                    "Invalid referrer"
                );

                // update storage
                userGlobalInfo.referrer = referrer;
                children[referrer].push(msg.sender);
                emit NewReferrer(msg.sender, referrer);
            } 
        }
        
         if(index != 100000000){
                require(AppointmentParams[get_hourEach()][msg.sender][index].status == 1);
                 AppointmentParams[get_hourEach()][msg.sender][index].status = 0;
         }else{
             IERC20(TokenAddress).transferFrom(msg.sender,address(this),token_number);
             All_Number = All_Number + token_number;
      
            hourLimitNumber[get_hourEach()] = hourLimitNumber[get_hourEach()] + token_number;
         }
     
        // // calculate each part of the amount
        OpenPositionParams memory params = OpenPositionParams({
            principalAmount: (token_number * PRINCIPAL_RATIO) / PRICE_PRECISION,
            investAmount: (token_number * INVEST_RATIO) / PRICE_PRECISION,
            referrerAmount: (token_number * REFERRER_RATIO) / PRICE_PRECISION,
            incentiveAmount: (token_number * INCENTIVE_RATIO) / PRICE_PRECISION,
            investReturnRate: _safeProcessFundTargetGetInvestReturnRate(roundInfo, ledgerType,token_number)
        });

        // check target ratio
        // require(targetRate <= params.investReturnRate, "Invalid ratio");

        // update user's current ledger and current round info
        uint256 userRoundInfoLength = userRoundsInfos[ledgerType][msg.sender].length;
        if (
            userRoundInfoLength == 0 ||
            userRoundsInfos[ledgerType][msg.sender][userRoundInfoLength - 1].epoch < targetEpoch
        ) {
            // this is users first position in this round of this ledger type
            UserRoundInfo memory _userRoundInfo;
            _userRoundInfo = UserRoundInfo({
                epoch: targetEpoch,
                totalPositionAmount: 0,
                currentPrincipalAmount: 0,
                totalWithdrawnAmount: 0,
                totalIncentiveClaimedAmount: 0,
                totalClosedPositionCount: 0,
                returnRateBoostedAmount: 0
            });
            // push roundInfo to storage
            userRoundsInfos[ledgerType][msg.sender].push(_userRoundInfo);
            roundInfo.ledgerRoundToUserRoundIndex[msg.sender] = userRoundInfoLength;
            userRoundInfoLength += 1;
        }

        // fetch back the roundInfo from storage for further direct modification
        userRoundInfo = userRoundsInfos[ledgerType][msg.sender][userRoundInfoLength - 1];
        userRoundInfo.totalPositionAmount += token_number;
        userRoundInfo.currentPrincipalAmount += params.principalAmount;

     

        // update ledger round info
        roundInfo.totalPositionAmount += token_number;
        roundInfo.currentPrincipalAmount += params.principalAmount;
        roundInfo.currentInvestAmount += params.investAmount;
        roundInfo.currentPositionCount += 1;
        roundInfo.currentIncentiveAmount += params.incentiveAmount;
        roundInfo.incentiveSnapshot += token_number;
        roundInfo.totalPositionCount += 1;

        uint256 userTotalPositionCount = roundLedgers[ledgerType][targetEpoch][msg.sender].length;
        // construct position info
        {
            uint256 expiryTime = block.timestamp;
            if (ledgerType == 0) {
                expiryTime += TIME_UNIT;
            } else {
                expiryTime += _pickDay(ledgerType, roundInfo.totalPositionCount) * TIME_UNIT;
            }
        
            PositionInfo memory positionInfo = PositionInfo({
                amount: token_number,
                openTime: block.timestamp,
                expiryTime: expiryTime,
                investReturnRate: params.investReturnRate,
                withdrawnAmount: 0,
                incentiveAmount: 0,
                investReturnAmount: 0,
                index: userTotalPositionCount,
                incentiveClaimable: true
             
            });

            // push position info to round ledgers
            roundLedgers[ledgerType][targetEpoch][msg.sender].push(positionInfo);
        }

        // distribute referrer funds
        _distributeReferrerReward(msg.sender, params.referrerAmount,token_number);

        {
            // ranked incentive track
            mapping(uint256 => LinkedPosition) storage linkedPositions = roundInfo.linkedPositions;

            // update the latest position (which is the current position) node
            LinkedPosition storage linkedPosition = linkedPositions[roundInfo.totalPositionCount - 1];
            linkedPosition.user = msg.sender;
            linkedPosition.userPositionIndex = userTotalPositionCount;

            // adjust head in order to keep track last N positions
            if (roundInfo.totalPositionCount - roundInfo.head > RANKED_INCENTIVE) {
                // fetch current head node
                LinkedPosition storage headLinkedPosition = linkedPositions[roundInfo.head];
                PositionInfo storage headPositionInfo = roundLedgers[ledgerType][targetEpoch][headLinkedPosition.user][
                    headLinkedPosition.userPositionIndex
                ];
                // previous head position now is not eligible for incentive
                headPositionInfo.incentiveClaimable = false;
                // subtract head position amount, because we only keep the last RANKED_INCENTIVE positions
                roundInfo.incentiveSnapshot -= headPositionInfo.amount;
                // shift head to next global position to keep track the last N positions
                roundInfo.head += 1;
            }
        }

        // do transfer to platform
        {
            IERC20(TokenAddress).transfer(platformAddress,token_number -
                    params.principalAmount -
                    params.investAmount -
                    params.referrerAmount -
                    params.incentiveAmount);
      
        }
        order_time[msg.sender] = block.timestamp;
        // emit event
        emit PositionOpened(msg.sender, ledgerType, targetEpoch, userTotalPositionCount, token_number);
    }

    /**
     * @notice Close position
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndex: Position index of the user
     *///
    function closePosition(
        uint256 ledgerType,
        uint256 epoch,
        uint256 positionIndex
    ) external notContract nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch <= currentEpochs[ledgerType], "Invalid epoch");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];
        require(positionIndex < positionInfos.length, "Invalid position index");

        // get position Info
        PositionInfo storage positionInfo = positionInfos[positionIndex];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        _safeClosePosition(ledgerType, epoch, positionIndex, positionInfo, roundInfo, userGlobalInfo);
    }

    /**
     * @notice Close a batch of positions
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClosePositions(
        uint256 ledgerType,
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch <= currentEpochs[ledgerType], "Invalid epoch");
        require(positionIndexes.length > 0, "Invalid position indexes");

        // check index is valid
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];

        // get roundIno
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // position info placeholder
        PositionInfo storage positionInfo;

        // user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[msg.sender];

        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            require(positionIndexes[i] < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndexes[i]];
            _safeClosePosition(ledgerType, epoch, positionIndexes[i], positionInfo, roundInfo, userGlobalInfo);
        }
    }

    /**
     * @notice Claim a batch of incentive claimable positions
     * @param ledgerType: Ledger type
     * @param epoch: Epoch of the ledger
     * @param positionIndexes: Position indexes of the user
     */
    function batchClaimPositionIncentiveReward(
        uint256 ledgerType,
        uint256 epoch,
        uint256[] calldata positionIndexes
    ) external notContract nonReentrant {
        require(ledgerType < 6, "Invalid ledger type");
        require(epoch < currentEpochs[ledgerType], "Epoch not finished");

        // get position infos
        PositionInfo[] storage positionInfos = roundLedgers[ledgerType][epoch][msg.sender];

        // get roundInfo
        RoundInfo storage roundInfo = roundInfos[ledgerType][epoch];

        // get user round info
        uint256 userRoundIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[ledgerType][msg.sender][userRoundIndex];

        // position info placeholder
        PositionInfo storage positionInfo;

        // collect payout
        uint256 payoutAmount;
        uint256 positionIndex;
        uint256 payoutToken;
        uint256 positionIndexesLength = positionIndexes.length;
        uint256 positionInfosLength = positionInfos.length;
        for (uint256 i = 0; i < positionIndexesLength; ++i) {
            positionIndex = positionIndexes[i];
            require(positionIndex < positionInfosLength, "Invalid position index");
            // get position Info
            positionInfo = positionInfos[positionIndex];
            require(positionInfo.incentiveClaimable, "Position not eligible");
            // update positionInfo
        
            payoutAmount += _safeProcessIncentiveAmount(positionInfo, roundInfo);
      
        }

 
          if(payoutAmount > 0){

            IERC20(TokenAddress).transfer(msg.sender,payoutAmount);
           }
        // update userRoundInfo
        userRoundInfo.totalIncentiveClaimedAmount += payoutAmount;
        emit IncentiveClaimed(msg.sender, payoutAmount);
    }

    /**
     * @notice Report a batch users' sales
     * @param users: list of users
     */
    function batchReportSales(address[] calldata users) external {
        uint256 usersLength = users.length;
        for (uint256 i = 0; i < usersLength; ++i) {
            _safeReportSales(users[i]);
        }
    }

    /**
     * @notice Claim referrer reward
     * @param referrer: referrer address
     */
    function claimReferrerReward(address referrer) external notContract nonReentrant {
        require(referrer != address(0), "Invalid referrer address");

        // get user global info
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[referrer];

        // get claimable amount
        uint256 claimableAmount = userGlobalInfo.totalReferrerReward - userGlobalInfo.referrerRewardClaimed;

        require(claimableAmount > 0, "No claimable amount");

        // update state
        userGlobalInfo.referrerRewardClaimed += claimableAmount;

        // do transfer
        IERC20(TokenAddress).transfer(referrer,claimableAmount);
     

        // emit event
        emit ReferrerRewardClaimed(referrer, claimableAmount);
    }
    
    function getUserAppointmentInfo(
        address _address,
       uint256 cursor,
        uint256 size
    ) external view returns (AppointmentInfo[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = getMyOfAppointmentListings(_address);
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }
        AppointmentInfo[] memory AppointmentInfos = new AppointmentInfo[](length);
       uint256 counter = 0;
        for (uint256 i = 0; i < UserAppointment[_address].length; ++i) {
            if(UserAppointment[_address][cursor + i].hour_each >= get_hourEach()){
            AppointmentInfos[counter] = UserAppointment[_address][cursor + i];
            counter++;
            }
        }
        return (AppointmentInfos, cursor + length);
    }
    function getMyOfAppointmentListings(address _address)  public
        view
        returns (uint256){
   uint256 counter = 0;
         
        for(uint256 i = 0; i < UserAppointment[_address].length; i++) {
            if(_address != address(0x0)){
             if (UserAppointment[_address][i].hour_each >= get_hourEach()){
                counter++;
            }
            }   
        }
        return counter;
        }


    function getUserRounds(
        uint256 ledgerType,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (UserRoundInfo[] memory, uint256) {
        uint256 length = size;
        uint256 roundCount = userRoundsInfos[ledgerType][user].length;
        if (cursor + length > roundCount) {
            length = roundCount - cursor;
        }

        UserRoundInfo[] memory userRoundInfos = new UserRoundInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            userRoundInfos[i] = userRoundsInfos[ledgerType][user][cursor + i];
        }

        return (userRoundInfos, cursor + length);
    }

    function getUserRoundsLength(uint256 ledgerType, address user) external view returns (uint256) {
        return userRoundsInfos[ledgerType][user].length;
    }

    function getUserRoundLedgers(
        uint256 ledgerType,
        uint256 epoch,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (PositionInfo[] memory, uint256) {
        uint256 length = size;
        uint256 positionCount = roundLedgers[ledgerType][epoch][user].length;
        if (cursor + length > positionCount) {
            length = positionCount - cursor;
        }

        PositionInfo[] memory positionInfos = new PositionInfo[](length);
        for (uint256 i = 0; i < length; ++i) {
            positionInfos[i] = roundLedgers[ledgerType][epoch][user][cursor + i];
        }

        return (positionInfos, cursor + length);
    }

    function getUserRoundLedgersLength(
        uint256 ledgerType,
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundLedgers[ledgerType][epoch][user].length;
    }

    function getChildren(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256) {
        uint256 length = size;
        uint256 childrenCount = children[user].length;
        if (cursor + length > childrenCount) {
            length = childrenCount - cursor;
        }

        address[] memory _children = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            _children[i] = children[user][cursor + i];
        }

        return (_children, cursor + length);
    }

    function getLedgerRoundToUserRoundIndex(
        uint256 ledgerType,
        uint256 epoch,
        address user
    ) external view returns (uint256) {
        return roundInfos[ledgerType][epoch].ledgerRoundToUserRoundIndex[user];
    }

    function getChildrenLength(address user) external view returns (uint256) {
        return children[user].length;
    }

    function getUserDepartSalesAndLevel(address user) external view returns (uint256, uint8) {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        return (userGlobalInfo.sales - userGlobalInfo.maxChildrenSales, userGlobalInfo.salesLevel);
    }

    /**
     * @notice close a given position
     * @param ledgerType: ledger type
     * @param epoch: epoch of the ledger
     * @param positionIndex: position index of the user
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeClosePosition(
        uint256 ledgerType,
        uint256 epoch,
        uint256 positionIndex,
        PositionInfo storage positionInfo,
        RoundInfo storage roundInfo,
        UserGlobalInfo storage userGlobalInfo
    ) internal {
        require(positionInfo.withdrawnAmount == 0, "Position already claimed");
        require(positionInfo.expiryTime <= block.timestamp || roundInfo.stopLoss, "Position not expired");

        // get user round info from storage
        uint256 targetRoundInfoIndex = roundInfo.ledgerRoundToUserRoundIndex[msg.sender];
        UserRoundInfo storage userRoundInfo = userRoundsInfos[ledgerType][msg.sender][targetRoundInfoIndex];

        // calculate the amount to withdraw
        uint256 payoutAmount;
        uint256 principalAmount = (positionInfo.amount * PRINCIPAL_RATIO) / PRICE_PRECISION;

        // get back the principal amount
        payoutAmount += principalAmount;

        // update roundInfo
        roundInfo.currentPositionCount -= 1;
        roundInfo.currentPrincipalAmount -= principalAmount;

        if (!roundInfo.stopLoss) {
            // calculate expected invest return amount
            // how many days passed
            uint256 daysPassed;
            if (ledgerType == 0) {
                // 1 day
                daysPassed = (block.timestamp - positionInfo.openTime);
            } else {
                daysPassed = (positionInfo.expiryTime - positionInfo.openTime);
            }
            uint256 expectedInvestReturnAmount = (positionInfo.amount * positionInfo.investReturnRate * daysPassed) /
                PRICE_PRECISION /
                TIME_UNIT;

            // calculate the amount should be paid back from invest pool
            // 35% to total amount + expected return amount
            uint256 investReturnAmount = positionInfo.amount - principalAmount + expectedInvestReturnAmount;

            // compare if current invest pool has enough amount
            if (roundInfo.currentInvestAmount < investReturnAmount) {
                // not enough, then just pay back the current invest pool amount
                investReturnAmount = roundInfo.currentInvestAmount;
                roundInfo.currentInvestAmount = 0;
            } else {
                // update round info
                unchecked {
                    roundInfo.currentInvestAmount -= investReturnAmount;
                }
            }

            // check round is stop loss
            if (roundInfo.currentInvestAmount == 0) {
                roundInfo.stopLoss = true;
                currentEpochs[ledgerType] += 1;
                _refillStock(ledgerType);
                emit NewRound(currentEpochs[ledgerType], ledgerType);
            }

            // update payout amount
            payoutAmount += investReturnAmount;

            // update positionInfo
            positionInfo.investReturnAmount = investReturnAmount;
        }

        uint256 incentiveAmount = 0;
        // calculate incentive amount if eligible
        if (roundInfo.stopLoss && positionInfo.incentiveClaimable) {
            incentiveAmount = _safeProcessIncentiveAmount(positionInfo, roundInfo);

            // update payout amount
            payoutAmount += incentiveAmount;

            // update incentive info to storage
            userRoundInfo.totalIncentiveClaimedAmount += incentiveAmount;

            emit IncentiveClaimed(msg.sender, incentiveAmount);
        }

        // update user round info
        userRoundInfo.totalWithdrawnAmount += payoutAmount;
        userRoundInfo.currentPrincipalAmount -= principalAmount;

        // update positionInfo
        positionInfo.withdrawnAmount = payoutAmount;

        // accumulate user's boost credit
        if (payoutAmount - incentiveAmount < positionInfo.amount) {
            userGlobalInfo.boostCredit += positionInfo.amount;
        }

        // do transfer
   
            IERC20(TokenAddress).transfer(msg.sender,payoutAmount);
     
        

        // emit event
        emit PositionClosed(msg.sender, ledgerType, epoch, positionIndex, payoutAmount);
    }

    /**
     * @notice process current round's fund target and return the updated invest return rate
     * @param roundInfo: storage of the round info
     */
    function _safeProcessFundTargetGetInvestReturnRate(RoundInfo storage roundInfo, uint256 ledgerType,uint256 _token_number)
        internal 
        returns (uint256)
    {
        FundTarget storage fundTarget = roundInfo.fundTarget;
        uint256 targetAmount = fundTarget.amount;
        uint256 achievedAmount = fundTarget.achievedAmount;
        // this is amount of total locked position
        uint256 currentTotalAmount_d6 = roundInfo.currentPrincipalAmount * PRICE_PRECISION;

        // process target fund
        {
            // check if this is the first time to process fund target
            if (fundTarget.lastCheckTime == 0) { 
                // first check will use default parameter
                targetAmount = DEFAULT_TARGET_AMOUNTS[ledgerType];

                // update check time and target amount to storage
                fundTarget.lastCheckTime = block.timestamp;
                fundTarget.amount = targetAmount;
            } else {
                // check if over 24 hours since last check
                if (block.timestamp - fundTarget.lastCheckTime > TIME_UNIT) {
          
                    // recalculate target amount
                    targetAmount =
                        (((currentTotalAmount_d6 * 361) / 1000 / PRINCIPAL_RATIO - roundInfo.currentInvestAmount) *
                            PRICE_PRECISION) /
                        260000;

                    // update check time and target amount to storage
                    fundTarget.lastCheckTime = block.timestamp;
                    fundTarget.amount = targetAmount;
                    // reset achieved amount
                    fundTarget.achievedAmount = 0; 
                    // reset achievedAmount in memory as well, because this will be the first position after adjusting the FundTarget
                    achievedAmount = 0;
                }
            }
            // update achieved amount in storage
            fundTarget.achievedAmount += _token_number;
        }

        // calculate return rate
        // notice: no need to include current invest amount
     
        if (achievedAmount <= targetAmount) {
            return DEFAULT_INVEST_RETURN_RATE;
        }

        // decrease 0.05% per 20% over target amount till 0.3%

        uint256 ratioDiff = (achievedAmount * PRICE_PRECISION) / targetAmount - PRICE_PRECISION;
        uint256 times = ratioDiff / (200000) + 1;
        if (ratioDiff % (200000) == 0) {
            times -= 1;
        }
        if (times > 14) {
            times = 14;
        }
   
        return DEFAULT_INVEST_RETURN_RATE;
    }

    /**
     * @notice process positionInfo and return incentive amount
     * @param positionInfo: storage of the position info
     * @param roundInfo: storage of the round info
     */
    function _safeProcessIncentiveAmount(PositionInfo storage positionInfo, RoundInfo storage roundInfo)
        internal
        returns (uint256)
    {
        // calculate incentive amount
        uint256 incentiveAmount = (positionInfo.amount * roundInfo.totalPositionAmount * INCENTIVE_RATIO) /
            roundInfo.incentiveSnapshot /
            PRICE_PRECISION;

        // with PRICE_PRECISION is due to the precision of division may result in a few wei left over
        if (roundInfo.currentIncentiveAmount < incentiveAmount + PRICE_PRECISION) {
            // clean up incentive amount
            incentiveAmount = roundInfo.currentIncentiveAmount;
            roundInfo.currentIncentiveAmount = 0;
        } else {
            roundInfo.currentIncentiveAmount -= incentiveAmount;
        }

        // this position is no longer eligible for incentive
        positionInfo.incentiveClaimable = false;

        // update positionInfo
        positionInfo.incentiveAmount = incentiveAmount;

        return incentiveAmount;
    }

    /**
     * @notice process user's level info and return the current level
     * @param currentLevel: user current level
     * @param user: user address
     * @param currentSales: user current sales
     * @param userGlobalInfo: storage of the user global info
     */
    function _safeProcessSalesLevel(
        uint8 currentLevel,
        address user,
        uint256 currentSales,
        UserGlobalInfo storage userGlobalInfo
    ) internal returns (uint8) {
        uint256 priceamount = currentSales*tokenPrice/1*10**18;
        uint8 newLevel = _getSalesToLevel(priceamount);
        if (newLevel > currentLevel) {
            userGlobalInfo.salesLevel = newLevel;
            emit SalesLevelUpdated(user, newLevel);
        } else {
            newLevel = currentLevel;
        }
        return newLevel;
    }

    /**
     * @notice report user's sales and update its referrer sales level
     * @param user: user address
     */
    function _safeReportSales(address user) internal {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        address referrer = userGlobalInfo.referrer;
        uint256 userSales = userGlobalInfo.sales;
        uint256 userReportedSales = userGlobalInfo.reportedSales;

        // get user's un-reported sales
        uint256 unreportedSales = userSales - userReportedSales;

        if (unreportedSales > 0) {
            // get referrer global info from storage
            UserGlobalInfo storage referrerGlobalInfo = userGlobalInfos[referrer];
            // fill up the sales to the referrer
            referrerGlobalInfo.sales += unreportedSales;
            // update user's reported sales
            userGlobalInfo.reportedSales = userSales;

            // all reported sales + user's own contributed position will be current user's final sales
            userSales += userGlobalInfo.totalPositionAmount;
            // current referrer's max children sales
            uint256 maxChildrenSales = referrerGlobalInfo.maxChildrenSales;
            // update max children sales if needed
            if (userSales > maxChildrenSales) {
                // referrer's max children sales is updated
                referrerGlobalInfo.maxChildrenSales = userSales;
                // update cache of max children sales
                maxChildrenSales = userSales;
            }
            // process referrer's sales level
            _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                referrer,
                referrerGlobalInfo.sales - maxChildrenSales, // sales for level calculation is sales - max children sales
                referrerGlobalInfo
            );
        }
    }

    /**
     * @notice distribute referrer reward
     * @param user: user address
     * @param referrerAmount: total amount of referrer reward
     */
    function _distributeReferrerReward(address user, uint256 referrerAmount,uint256 _token_number) internal virtual {
        UserGlobalInfo storage userGlobalInfo = userGlobalInfos[user];
        UserGlobalInfo storage referrerGlobalInfo;
        uint256 positionAmount = _token_number;

        // init all local variables as a search struct
        ReferrerSearch memory search;
        search.baseSalesLevel = 0;
        search.currentReferrer = userGlobalInfo.referrer;
        search.levelDiffAmount = (referrerAmount * 70) / 100;
        search.leftLevelDiffAmount = search.levelDiffAmount;
        search.levelDiffAmountPerLevel = search.levelDiffAmount / 12;
        search.levelSearchAmount = referrerAmount - search.levelDiffAmount;
        search.leftLevelSearchAmount = search.levelSearchAmount;
        search.levelSearchAmountPerReferrer = search.levelSearchAmount / 10;
        search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount + positionAmount;
        userGlobalInfo.totalPositionAmount = search.currentUserTotalPosAmount;
        search.currentUser = user;

        while (search.depth < MAX_SEARCH_DEPTH) {
            // stop if current referrer is the root
            if (search.currentReferrer == address(0)) {
                break;
            }

            // this position does not counted as reported sales for first user himself
            if (search.depth > 0) userGlobalInfo.reportedSales += positionAmount;

            // cache current user information
            search.currentUserSales = userGlobalInfo.sales;
            search.currentUserReportedSales = userGlobalInfo.reportedSales;

            // cache current referrer information
            referrerGlobalInfo = userGlobalInfos[search.currentReferrer];

            // update referrer sales
            {
                search.currentReferrerSales = referrerGlobalInfo.sales;
                // add current sales to current referrer
                search.currentReferrerSales += positionAmount;
                // check unreported sales
                if (search.currentUserReportedSales < search.currentUserSales) {
                    // update referrerSales to include unreported sales
                    search.currentReferrerSales += search.currentUserSales - search.currentUserReportedSales;
                    // update current node storage for reported sales
                    userGlobalInfo.reportedSales = search.currentUserSales;
                }
                // update sales for current referrer
                referrerGlobalInfo.sales = search.currentReferrerSales;
            }

            // update referrer max children sales
            {
                // add current user's total position amount to current user's sales
                search.currentUserSales += search.currentUserTotalPosAmount;
                // check referrer's max child sales
                search.currentReferrerMaxChildSales = referrerGlobalInfo.maxChildrenSales;
                if (search.currentReferrerMaxChildSales < search.currentUserSales) {
                    // update max child sales
                    referrerGlobalInfo.maxChildrenSales = search.currentUserSales;
                    search.currentReferrerMaxChildSales = search.currentUserSales;
                }
            }

            // process referrer's sales level
            // @notice: current referrer sales level should ignore its max child sales
            search.currentReferrerLevel = _safeProcessSalesLevel(
                referrerGlobalInfo.salesLevel,
                search.currentReferrer,
                search.currentReferrerSales - search.currentReferrerMaxChildSales,
                referrerGlobalInfo
            );

            // start level diff calculation
            if (!search.levelDiffDone) {
                // compare the current referrer's level with the base sales level
                if (search.currentReferrerLevel > search.baseSalesLevel) {
                    // level diff
                    search.currentLevelDiff = search.currentReferrerLevel - search.baseSalesLevel;

                    // update base level
                    search.baseSalesLevel = search.currentReferrerLevel;

                    // calculate the referrer amount
                    search.currentReferrerAmount = search.currentLevelDiff * search.levelDiffAmountPerLevel;

                    // check left referrer amount
              

                    // update referrer's referrer amount
                    referrerGlobalInfo.totalReferrerReward += search.currentReferrerAmount;
                    emit ReferrerRewardAdded(search.currentReferrer, search.currentReferrerAmount, 0);

                    unchecked {
                        search.leftLevelDiffAmount -= search.currentReferrerAmount;
                    }

                    if (search.leftLevelDiffAmount == 0) {
                        search.levelDiffDone = true;
                    }
                }
            }
            if (!search.levelSearchDone) {
                // level search use referrer's real level
                uint256 priceamount = (search.currentReferrerSales - search.currentReferrerMaxChildSales)*tokenPrice/1*10**18;
                search.levelSearchStep = _getLevelToLevelSearchStep(
                    _getSalesToLevel(priceamount)
                );

                if (search.numLevelSearchCandidate + 1 <= search.levelSearchStep) {
                    search.numLevelSearchCandidate += 1;

                    // check left referrer amount
                    if (search.levelSearchAmountPerReferrer + PRICE_PRECISION > search.leftLevelSearchAmount) {
                        search.levelSearchAmountPerReferrer = search.leftLevelSearchAmount;
                    }

                    // update referrer's referrer amount
                    referrerGlobalInfo.totalReferrerReward += search.levelSearchAmountPerReferrer;
                    emit ReferrerRewardAdded(search.currentReferrer, search.levelSearchAmountPerReferrer, 1);

                    unchecked {
                        search.leftLevelSearchAmount -= search.levelSearchAmountPerReferrer;
                    }

                    if (search.leftLevelSearchAmount == 0) {
                        search.levelSearchDone = true;
                    }
                }
            }

            search.currentUser = search.currentReferrer;
            search.currentReferrer = referrerGlobalInfo.referrer;

            userGlobalInfo = referrerGlobalInfo;
            search.currentUserTotalPosAmount = userGlobalInfo.totalPositionAmount;

            unchecked {
                search.depth += 1;
            }
        }

        // check residual referrer amount
        if (search.leftLevelDiffAmount > 0) {
            userGlobalInfos[fundAddress].totalReferrerReward += search.leftLevelDiffAmount;
            emit ReferrerRewardAdded(fundAddress, search.leftLevelDiffAmount, 0);
        }
        if (search.leftLevelSearchAmount > 0) {
            userGlobalInfos[fundAddress].totalReferrerReward += search.leftLevelSearchAmount;
            emit ReferrerRewardAdded(fundAddress, search.leftLevelSearchAmount, 1);
        }
    }

    /**
     * @notice get sales level from sales amount
     * @param amount: sales amount
     */
    function _getSalesToLevel(uint256 amount) internal pure virtual returns (uint8) {
        
        /* istanbul ignore else  */
        if (amount < 1*10**18) {
            return 0;
        } else if (amount < 100*10**18) {
            return 1;
        } else if (amount < 200*10**18) {
            return 2;
        } else if (amount < 400*10**18) {
            return 3;
        } else if (amount < 600*10**18) {
            return 4;
        } else if (amount < 800*10**18) {
            return 5;
        } else if (amount < 1000*10**18) {
            return 6;
        } else if (amount < 1200*10**18) {
            return 7;
        } else if (amount < 1400*10**18) {
            return 8;
        } else if (amount < 1600*10**18) {
            return 9;
        } else if (amount < 1800*10**18) {
            return 10;
        } else if (amount < 2000*10**18) {
            return 11;
        }
        return 12;
    }

    /**
     * @notice level search step from level
     * @param level: sales level (0-12)
     */
    function _getLevelToLevelSearchStep(uint8 level) internal pure returns (uint8) {
        unchecked {
            if (level < 5) return level * 2;
        }
        return 10;
    }
}