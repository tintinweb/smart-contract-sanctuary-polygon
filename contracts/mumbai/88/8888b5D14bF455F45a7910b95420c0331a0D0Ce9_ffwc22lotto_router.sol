pragma solidity =0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./ERC20.sol";
import "./ChainlinkClient.sol";

contract ffwc22lotto_router is ChainlinkClient {

    address public _owner;
    address private _announcer;
    address public _USD;
    address private _LINK;

    //for marking if the result is announced
    bool public _isAnnounced;
    uint8 private _teamLength = 32;

    //percents
    uint8 private _superChampionPrizePercent;
    uint8 private _championPrizePercent;
    uint8 private _runnerupPrizePercent;
    uint8 private _announcerPercent;
    uint8 private _devPercent;

    //start sale time
    uint32 private _startedSaleTimestamp;
    //deadline sale time
    uint32 public _closedSaleTimestamp;

    //start ticket price
    uint256 private _initTicketPrice;
    //start ticket price
    uint256 private _ticketPriceRaisePerDay;

    //prize pool
    uint256 public _prizePool;

    //ticket_index => ticket's number (that is sold)
    mapping(uint32 => uint32) private _ticketSoldList;
    //recent length of _ticketSoldList
    uint32 private _ticketSoldLength;

    //holder's address => ticket_index => number
    mapping(address => mapping(uint32 => uint32)) private _ticketHoldingList;
    //recent length of _ticketHoldingList[ holder's address ]
    mapping(address => uint32) private _ticketHoldingLength;

    //ticket's number => status (true = sold,false = available)
    mapping(uint32 => bool) private _isTicketSold;
    //ticket's number => status (true = claimed, false = unclaimed)
    mapping(uint32 => bool) private _isTicketClaimed;

    //to count how many holder in each nation_id
    //nation_id to #ticket
    mapping(uint8 => uint32) private _nationIdTicketHolderLength;
    //hard mapper nationCode To NationId
    mapping(string => uint8) private _nationCodeToNationId;

    //number that won super prize
    uint16 private _superChampionCodeWC22;
    //nation_id that won the prize
    uint8 private _championNationIdWC22;
    uint8 private _runnerupNationIdWC22;
    //timestamp that the data last updated
    uint32 private _lastFulFillTimestampWC22;

    //old winning prize (WC2018)
    uint16 private _superChampionCodeWC18;
    uint8 private _championNationIdWC18;
    uint8 private _runnerupNationIdWC18;
    uint32 private _lastFulFillTimestampWC18;

    //chainlink => sportdataapi.com PART
    using Chainlink for Chainlink.Request;
    event RequestFulfilledString(bytes32 indexed requestId, string response);
    event RequestFulfilledUint256(bytes32 indexed requestId, uint256 response);
    //chainlink jobId for HTTP GET
    bytes32 jobIdString = "7d80a6386ef543a3abb52817f6707e3b";
    bytes32 jobIdUint256 = "ca98366cc7314957b8c012c72f05aeeb";
    //chainlink fee per request
    uint256 LINK_fee = (1 * LINK_DIVISIBILITY) / 10;

    //current loading season 
    string private _SEASONID;
    //pending data from chainlink => sportdataapi.com
    //team name in final
    string private _HOMENATIONCODE;
    bytes32 private _HOMENATIONCODEReqId;
    string private _AWAYNATIONCODE;
    bytes32 private _AWAYNATIONCODEReqId;
    //team #goal in final of sportdataapi
    uint8 private _HOMEGOAL = 255; // to check if #goal is fulfilled in case #goal is 0
    bytes32 private _HOMEGOALReqId;
    uint8 private _AWAYGOAL = 255; // to check if #goal is fulfilled in case #goal is 0
    bytes32 private _AWAYGOALReqId;
    // First 4 Top scorers' #goal
    uint8 private _TOPSCORE1;
    uint8 private _TOPSCORE2;
    uint8 private _TOPSCORE3;
    uint8 private _TOPSCORE4;
    bytes32 private _TOPSCORE1ReqId;
    bytes32 private _TOPSCORE2ReqId;
    bytes32 private _TOPSCORE3ReqId;
    bytes32 private _TOPSCORE4ReqId;

    //sportdataapi.com ids
    // string WC22FinalMatchID = "429770"; 
    string WC22SeasonID = "3072"; 
    string WC22FinalDateFrom = "2022-12-18"; 
    // string WC18FinalMatchID = "129920"; 
    string WC18SeasonID = "1193"; 
    string WC18FinalDateFrom = "2018-07-15"; 
    
    modifier ensure(uint32 deadline) {
        require(deadline >= block.timestamp, "FFWC22LTRouter: EXPIRED");
        _;
    }
    modifier isOwner() {
        require(msg.sender == _owner, "FFWC22LTRouter: AUTHORIZATION_FAILED");
        _;
    }

    /**
     * @notice Initialize the link token and target oracle
     *
     * Goerli Testnet details:
     * Test USD Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB (Link)
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
     *
     */
    /**
     * @notice Initialize the link token and target oracle
     *
     * Binance Testnet details:
     * Test USD Token: 0xFa60D973F7642B748046464e165A65B7323b0DEE (Cake)
     * Link Token: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
     * Oracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7 (Chainlink DevRel)
     *
     */
    /**
     * @notice Initialize the link token and target oracle
     *
     * Mumbai Testnet details:
     * Test USD Token: 0xe0F0ffA1e897C566BC721353FF4C64FC8ACd77E0 (CoinMegaTrend)
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3 (Chainlink DevRel)
     *
     */
    constructor() {
        _owner = msg.sender;
        //setup currency token for ticket purchasing
        _USD = 0xe0F0ffA1e897C566BC721353FF4C64FC8ACd77E0;

        //setup Chainlink oracle for pulling result
        _LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        setChainlinkToken(_LINK);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);

        //setup ticket price
        _initTicketPrice = 2000000000000000000; //start at 2 USD / ticket
        _ticketPriceRaisePerDay = 500000000000000000; //raise 0.5 USD / ticket / day

        //setup percents
        _superChampionPrizePercent = 20;
        _championPrizePercent = 60;
        _runnerupPrizePercent = 15;
        _announcerPercent = 1;
        _devPercent = 4;

        //set sale period
        _startedSaleTimestamp = uint32(block.timestamp); // deploy time
        _closedSaleTimestamp = 1671375600; // FIFA World Cup 2022 Final start

        //setup nation code to nation ID (Order by string as frontend)
        _nationCodeToNationId["ARG"] = 0;
        _nationCodeToNationId["AUS"] = 1;
        _nationCodeToNationId["BEL"] = 2;
        _nationCodeToNationId["BRA"] = 3;
        _nationCodeToNationId["CAN"] = 4;
        _nationCodeToNationId["CMR"] = 5;
        _nationCodeToNationId["CRC"] = 6;
        _nationCodeToNationId["CRO"] = 7;
        _nationCodeToNationId["DEN"] = 8;
        _nationCodeToNationId["ECU"] = 9;
        _nationCodeToNationId["ENG"] = 10;
        _nationCodeToNationId["ESP"] = 11;
        _nationCodeToNationId["FRA"] = 12;
        _nationCodeToNationId["GER"] = 13;
        _nationCodeToNationId["GHA"] = 14;
        _nationCodeToNationId["IRN"] = 15;
        _nationCodeToNationId["JPN"] = 16;
        _nationCodeToNationId["KOR"] = 17;
        _nationCodeToNationId["KSA"] = 18;
        _nationCodeToNationId["MAR"] = 19;
        _nationCodeToNationId["MEX"] = 20;
        _nationCodeToNationId["NED"] = 21;
        _nationCodeToNationId["POL"] = 22;
        _nationCodeToNationId["POR"] = 23;
        _nationCodeToNationId["QAT"] = 24;
        _nationCodeToNationId["SEN"] = 25;
        _nationCodeToNationId["SRB"] = 26;
        _nationCodeToNationId["SUI"] = 27;
        _nationCodeToNationId["TUN"] = 28;
        _nationCodeToNationId["URU"] = 29;
        _nationCodeToNationId["USA"] = 30;
        _nationCodeToNationId["WAL"] = 31;
    }

    function numberToNationId(uint32 number)
        private
        view
        returns (uint8 nationId)
    {
        return uint8(number % _teamLength);
    }

    function numberToTicketCode(uint32 number)
        private
        view
        returns (uint16 code)
    {
        return uint16(number / _teamLength);
    }

    function nationIdTicketCodeToNumber(uint8 nationId, uint16 ticketCode)
        private
        view
        returns (uint32 number)
    {
        return  uint32(ticketCode * _teamLength) + uint32(nationId);
    }

    function getIfOnSale() public view virtual returns (bool isOnSale) {
        return (block.timestamp < _closedSaleTimestamp);
    }

    function getPriceByTimestamp(uint32 timestamp) public view virtual returns (uint256 price) {
        uint8 passedDays = uint8((timestamp - _startedSaleTimestamp) / 86400);
        if(passedDays < 3){
            return _initTicketPrice;
        }
        return _initTicketPrice + (passedDays * _ticketPriceRaisePerDay);
    }

    function getAllTicketsByHolder(address holder)
        public
        view
        virtual
        returns (uint32[] memory number)
    {
        number = new uint32[](_ticketHoldingLength[holder]);
        for (uint32 i = 0; i < _ticketHoldingLength[holder]; i++) {
            number[i] = _ticketHoldingList[holder][i];
        }
        return (number);
    }

    function getAllSoldTickets()
        public
        view
        virtual
        returns (uint32[] memory number)
    {
        number = new uint32[](_ticketSoldLength);
        for (uint32 i = 0; i < _ticketSoldLength; i++) {
            number[i] = _ticketSoldList[i];
        }
        return (number);
    }

    function getSharePercents()
        public
        view
        virtual
        returns (
            uint8 superChampionPrizePercent,
            uint8 championPrizePercent,
            uint8 runnerupPrizePercent,
            uint8 announcerPercent,
            uint8 devPercent
        )
    {
        return (
            _superChampionPrizePercent,
            _championPrizePercent,
            _runnerupPrizePercent,
            _announcerPercent,
            _devPercent
        );
    }

    function getAllClaimableAmountByHolder(address holder)
        public
        view
        virtual
        returns (uint256 claimable)
    {
        if (!_isAnnounced) {
            return 0;
        }
        claimable = 0;
        for (uint32 i = 0; i < _ticketHoldingLength[holder]; i++) {
            uint32 number = _ticketHoldingList[holder][i];
            //check if this ticket is claimed
            if (!_isTicketClaimed[number]) {
                claimable += getClaimableAmountByTicket(number);
            }
        }
    }

    function getClaimableAmountByTicket(uint32 number)
        public
        view
        virtual
        returns (uint256 claimable)
    {
        if (!_isAnnounced) {
            return 0;
        }
        //check if this ticket is claimed
        if (_isTicketClaimed[number]) {
            return 0;
        }
        claimable = 0;
        uint8 nationId = numberToNationId(number);
        //check if winning Super Champion Prize
        {
            uint16 ticketCode = numberToTicketCode(number);
            if (
                nationId == _championNationIdWC22 &&
                ticketCode == _superChampionCodeWC22
            ) {
                //super champion win xx% of Pool
                claimable += (_prizePool * _superChampionPrizePercent) / 100;
            }
        }
        //check if winning Other Prizes
        {
            uint256 wholePrize = 0;
            if (nationId == _championNationIdWC22) {
                //champion prize win yy% of Pool
                wholePrize = (_prizePool * _championPrizePercent) / 100;
            } else if (nationId == _runnerupNationIdWC22) {
                //runnerup prize win zz% of Pool
                wholePrize = (_prizePool * _runnerupPrizePercent) / 100;
            }
            //add reward ( wholePrize of the share / number of that nation's ticket holder)
            claimable += wholePrize / _nationIdTicketHolderLength[nationId];
        }
        return claimable;
    }

    function buyTicket( uint32 number, uint256 ticketPrice, address ticketTaker, uint32 deadline
    ) external virtual ensure(deadline) returns (bool success) {
        require( getIfOnSale(), "FFWC22LTRouter: TICKET_SALE_IS_CLOSED");
        require( !_isAnnounced, "FFWC22LTRouter: TICKETS_ARE_NOT_ON_SALE_AFTER_ANNOUNCING");
        require( !_isTicketSold[number], "FFWC22LTRouter: THIS_TICKET_IS_SOLD_OUT");
        //cannot buy ticket with price lower than getPriceByTimestamp(now)
        require(
            ticketPrice >= getPriceByTimestamp(uint32(block.timestamp)),
            "FFWC22LTRouter: OFFERED_TICKET_PRICE_IS_TOO_LOW"
        );

        //transfer token from the caller to this contract
        IERC20(_USD).transferFrom(msg.sender, address(this), ticketPrice);

        //add this ticket to this ticketTaker
        uint32 curLength = _ticketHoldingLength[ticketTaker];
        _ticketHoldingList[ticketTaker][curLength] = number;
        _ticketHoldingLength[ticketTaker] = curLength + 1;

        //add this ticket to the sold ticket list
        uint32 curSoldLength = _ticketSoldLength;
        _ticketSoldList[curSoldLength] = number;
        _ticketSoldLength = curSoldLength + 1;

        //increase #holders of this nation_id
        _nationIdTicketHolderLength[numberToNationId(number)] += 1;

        //increase _prizePool by offered ticketPrice
        _prizePool += ticketPrice;

        return true;
    }

    function claimTicket(uint32 number, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amounts)
    {
        require( !_isTicketClaimed[number], "FFWC22LTRouter: THIS_TICKET_IS_CLAIMED");

        amounts = getClaimableAmountByTicket(number);
        //transfer reward to the ticket holder
        IERC20(_USD).transfer(msg.sender, amounts);
        //mark that this ticket is claimed
        _isTicketClaimed[number] = true;

        return amounts;
    }

    function claimAllTickets(uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amounts)
    {
        amounts = 0;
        for (uint32 i = 0; i < _ticketHoldingLength[msg.sender]; i++) {
            uint32 number = _ticketHoldingList[msg.sender][i];
            //check if this ticket is claimed
            if (!_isTicketClaimed[number]) {
                amounts += getClaimableAmountByTicket(number);
                //mark that this ticket is claimed
                _isTicketClaimed[number] = true;
            }
        }
        //transfer reward to the ticket holder
        IERC20(_USD).transfer(msg.sender, amounts);

        return amounts;
    }

    function devClaimReward(uint32 deadline)
        external
        virtual
        ensure(deadline)
        isOwner
        returns (uint256 amounts)
    {
        require( _isAnnounced, "FFWC22LTRouter: DEV_CAN_CLAIM_ONLY_AFTER_ANNOUNCING");
        require(_devPercent > 0, "FFWC22LTRouter: NO_REWARD_FOR_DEV");

        amounts = (_prizePool * _devPercent) / 100;
        //transfer the reward to the dev
        IERC20(_USD).transfer(_owner, amounts);

        return amounts;
    }

    function getWC22()
        public
        view
        virtual
        returns (
            uint32 lastFulFillTimestampWC22,
            uint16 superChampionCodeWC22,
            uint8 championNationIdWC22,
            uint8 runnerupNationIdWC22
        )
    {
        require( _isAnnounced, "FFWC22LTRouter: THE_RESULT_IS_NOT_ANNOUCED_YET");
        return ( _lastFulFillTimestampWC22, _superChampionCodeWC22, _championNationIdWC22, _runnerupNationIdWC22);
    }
    
    function getWC18()
        public
        view
        virtual
        returns (
            uint32 lastFulFillTimestampWC18,
            uint16 superChampionCodeWC18,
            uint8 championNationIdWC18,
            uint8 runnerupNationIdWC18
        )
    {
        return ( _lastFulFillTimestampWC18, _superChampionCodeWC18, _championNationIdWC18, _runnerupNationIdWC18 );
    }

    //===================================
    //chainlink PART
    //===================================
    function reqWC22(string memory sportdataAPIKEY, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (bool success)
    {
        require(
            block.timestamp - _closedSaleTimestamp > 86400,
            "TicketRouter : ANNOUNCING_IS_ONLY_ABLE_24HRS_AFTER_CLOSED"
        );
        require( !_isAnnounced, "TicketRouter : THE_RESULT_IS_ALREADY_ANNOUNCED");

        //only reward to the first announcer
        if(_announcer == address(0)){
            _announcer = msg.sender;
        }

        //chainlink => sportdataapi
        return reqSportdataWithChainLink( sportdataAPIKEY, WC22SeasonID, WC22FinalDateFrom);
    }

    function reqWC18( string memory sportdataAPIKEY, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (bool success)
    {
        require(
            block.timestamp < _closedSaleTimestamp ,
            "TicketRouter : DEMO_ANNOUNCING_IS_ONLY_ABLE_BEFORE_MARKET_CLOSED"
        );

        //chainlink => sportdataapi
        return reqSportdataWithChainLink( sportdataAPIKEY, WC18SeasonID, WC18FinalDateFrom);
    }

    function reqSportdataWithChainLink(string memory APIKEY,string memory seasonID, string memory dateFrom)
        private
        returns (bool success)
    {
        require( IERC20(_LINK).balanceOf(address(this)) >= (LINK_fee * 8) , "FFWC22LTRouter: NOT_ENOUGH_LINK_TOKEN_TO_PAY_AS_FEE_(FEE x 8)");

        string memory matchUrl = string( abi.encodePacked( "https://app.sportdataapi.com/api/v1/soccer/matches?apikey=", APIKEY, "&season_id=", seasonID, "&date_from=", dateFrom));        
        string memory topscorerUrl = string( abi.encodePacked( "https://app.sportdataapi.com/api/v1/soccer/topscorers?apikey=", APIKEY, "&season_id=", seasonID));        
        
        Chainlink.Request memory req;

        //set requesting seasonId
        _SEASONID = seasonID;

        //reset 2 team nation code (String)
        _HOMENATIONCODE = "";
        _AWAYNATIONCODE = "";
        //request 2 team nation code (String)
        {
            //get HOMENATIONCODE
            req = buildChainlinkRequest(
                jobIdString,
                address(this),
                this.fulfillString.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,home_team,short_code");
            _HOMENATIONCODEReqId = sendChainlinkRequest(req, LINK_fee);

            //get AWAYNATIONCODE
            req = buildChainlinkRequest(
                jobIdString,
                address(this),
                this.fulfillString.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,away_team,short_code");
            _AWAYNATIONCODEReqId = sendChainlinkRequest(req, LINK_fee);
        }
        
        //reset 2 team #goal (Int)
        _HOMEGOAL = 255;
        _AWAYGOAL = 255;
        //request 2 team #goal (Int)
        {
            //get HOME #GOAL
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,stats,home_score");
            req.addInt("times", 1);
            _HOMEGOALReqId = sendChainlinkRequest(req, LINK_fee);

            //get AWAY #GOAL
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", matchUrl);
            req.add("path", "data,0,stats,away_score");
            req.addInt("times", 1);
            _AWAYGOALReqId = sendChainlinkRequest(req, LINK_fee);
        }

        //reset first 4 top scorer #goal (Int)
        _TOPSCORE1 = 0;
        _TOPSCORE2 = 0;
        _TOPSCORE3 = 0;
        _TOPSCORE4 = 0;
        //request first 4 top scorer #goal (Int)
        {
            //get TOPSCORE1
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,0,goals,overall");
            req.addInt("times", 1);
            _TOPSCORE1ReqId  = sendChainlinkRequest(req, LINK_fee);

            //get TOPSCORE2
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,1,goals,overall");
            req.addInt("times", 1);
            _TOPSCORE2ReqId  = sendChainlinkRequest(req, LINK_fee);

            //get TOPSCORE3
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,2,goals,overall");
            req.addInt("times", 1);
           _TOPSCORE3ReqId  = sendChainlinkRequest(req, LINK_fee);

           //get TOPSCORE4
            req = buildChainlinkRequest(
                jobIdUint256,
                address(this),
                this.fulfillUint256.selector
            );
            req.add("get", topscorerUrl);
            req.add("path", "data,3,goals,overall");
            req.addInt("times", 1);
           _TOPSCORE4ReqId  = sendChainlinkRequest(req, LINK_fee);
        }

        return true;
    }

    function fulfillString(bytes32 requestId, string memory response)
        public
        recordChainlinkFulfillment(requestId)
    {
        emit RequestFulfilledString(requestId, response);

        if (requestId == _HOMENATIONCODEReqId) {
            _HOMENATIONCODE = response;
        } else if (requestId == _AWAYNATIONCODEReqId) {
            _AWAYNATIONCODE = response;
        }

        updateIfFullyFulfill();
    }

    function fulfillUint256(bytes32 requestId, uint256 response)
        public
        recordChainlinkFulfillment(requestId)
    {
        emit RequestFulfilledUint256(requestId, response);

        if (requestId == _HOMEGOALReqId) {
            _HOMEGOAL = uint8(response);
        } else if (requestId == _AWAYGOALReqId) {
            _AWAYGOAL = uint8(response);
        } else if (requestId == _TOPSCORE1ReqId) {
            _TOPSCORE1 = uint8(response);
        } else if (requestId == _TOPSCORE2ReqId) {
            _TOPSCORE2 = uint8(response);
        } else if (requestId == _TOPSCORE3ReqId) {
            _TOPSCORE3 = uint8(response);
        } else if (requestId == _TOPSCORE4ReqId) {
            _TOPSCORE4 = uint8(response);
        }

        updateIfFullyFulfill();
    }
    
    function updateIfFullyFulfill() private {
        //all 4 top scorers' #goal multiplied , if there is any 0 => result = 0
        uint256 SQUAREMULSCORE = uint256 ( _TOPSCORE1 * _TOPSCORE2 * _TOPSCORE3 * _TOPSCORE4 );
        
        //UPDATE PRIZING NUMBER if data is enough to know who is the winner and the champion code
        if(
            SQUAREMULSCORE > 0 && //all SCOREs must not be 0
            (
                keccak256(abi.encodePacked(_SEASONID)) == keccak256(abi.encodePacked(WC22SeasonID)) || 
                keccak256(abi.encodePacked(_SEASONID)) == keccak256(abi.encodePacked(WC18SeasonID))
            ) && //SEASONID is either WC18 / WC22
            bytes(_HOMENATIONCODE).length != 0 && //NATIONCODE of both teams are obtained
            bytes(_AWAYNATIONCODE).length != 0 &&
            _HOMEGOAL != 255 && //means _HOMEGOAL is fulfilled
            _AWAYGOAL != 255 &&  //means _AWAYGOAL is fulfilled
            _HOMEGOAL != _AWAYGOAL //ended match shouldn't have equal scores
        ){
            //READY TO ANNOUNCE
            bool isWC22 =  (keccak256(abi.encodePacked((_SEASONID))) == keccak256(abi.encodePacked((WC22SeasonID)))); // else WC18
            uint8 homeNationId = _nationCodeToNationId[_HOMENATIONCODE];
            uint8 awayNationId = _nationCodeToNationId[_AWAYNATIONCODE];
            uint8 championNationId;
            uint8 runnerupNationId;
            if( _HOMEGOAL > _AWAYGOAL){//home won
                championNationId = homeNationId;
                runnerupNationId = awayNationId;
            }else{//away won
                championNationId = awayNationId;
                runnerupNationId = homeNationId;
            }
            uint8 SUMSCORE = uint8 ( _TOPSCORE1 + _TOPSCORE2 + _TOPSCORE3 + _TOPSCORE4 );
            uint16 superChampionCode = uint16 ( ( (SQUAREMULSCORE * SQUAREMULSCORE) + SUMSCORE) % 31250 );

            if(isWC22){//save data for WC22
                _lastFulFillTimestampWC22 = uint32( block.timestamp );
                _superChampionCodeWC22 = superChampionCode;                          
                _championNationIdWC22 = championNationId;
                _runnerupNationIdWC22 = runnerupNationId;  
        
                //mark that the result is announced
                _isAnnounced = true;

                //check if no one winning Super Champion Prize
                {
                    uint32 winningNumber = nationIdTicketCodeToNumber( championNationId, superChampionCode);
                    if (
                        !_isTicketSold[winningNumber]
                    ) {
                        //change share percent
                        _superChampionPrizePercent = 0;
                        _championPrizePercent = 70;
                        _runnerupPrizePercent = 20;
                        _devPercent = 9;
                    }
                }

                //transfer the reward to the first annoucer
                {
                    uint256 annoucerReward = ( _prizePool * _announcerPercent) / 100;
                    IERC20(_USD).transfer( _announcer , annoucerReward);
                }
            }else{//save data for WC18
                _lastFulFillTimestampWC18 = uint32( block.timestamp );
                _superChampionCodeWC18 = superChampionCode;
                _championNationIdWC18 = championNationId;
                _runnerupNationIdWC18 = runnerupNationId;
            }
        }
    }

     function getWCPENDING()
        public
        view
        virtual
        returns (
            string memory SEASONID,
            string memory HOMENATIONCODE,
            string memory AWAYNATIONCODE,
            uint8 HOMEGOAL,
            uint8 AWAYGOAL,
            uint8 TOPSCORE1,
            uint8 TOPSCORE2,
            uint8 TOPSCORE3,
            uint8 TOPSCORE4
        ){
        return (
            _SEASONID,
            _HOMENATIONCODE,
            _AWAYNATIONCODE,
            _HOMEGOAL,
            _AWAYGOAL,
            _TOPSCORE1,
            _TOPSCORE2,
            _TOPSCORE3,
            _TOPSCORE4
        );
    }
}