// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./token/VEGA.sol";

contract FootballBets is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint8;

    VEGAERC20Token public tokenAddress;
    uint256 public maxBetAmount = 10000000 ether;
    uint256 public standardPrice  = 10 ether;
    uint16 public oddsRate = 10000;
    uint256 public totalFundAmount = 0;
    uint16 public fee = 20; // rate 1000  - 2%
    address public marketingAddress;

    struct MatchInfo {
        uint256 matchId;
        string title;
        string teamA;
        string teamB;
        uint256 startBettingTime;
        uint256 endBettingTime;
        uint256 timeMatchStart;
        uint8 homeTeamGoals;
        uint8 awayTeamGoals;
        uint8 status; // 0-NEW 1-FINISH 9-CANCEL/POSTPONE
    }

    struct BetType { // id 0,1,2  1x2, handicap, over-under
        string description;
        uint8 numDoors;
        uint32[] odds;
        int32 goalRate;
        uint8 status; // 0-NEW 1-FINISH
    }

    struct Ticket {
        uint256 index;
        address player;
        uint256 matchId;
        uint8 betTypeId;
        uint8 betDoor;
        uint32 betOdd;
        uint256 betAmount;
        uint256 payout;
        int32 goalRate;
        uint256 bettingTime;
        uint256 claimedTime;
        uint8 status; // 0-PENDING 1-FINISH
    }

    struct PlayerStat {
        uint256 totalBet;
        uint256 payout;
    }

    mapping(uint256 => MatchInfo) public matchInfos; // All matches
    mapping(uint256 => BetType[]) public matchBetTypes; // Store all match bet types: matchId => array of BetType
    Ticket[] public tickets; // All tickets of player

    mapping(address => uint256[]) public ticketsOf; // Store all ticket of player: player => ticket_id

    mapping(address => PlayerStat) public playerStats;
    mapping(address => bool) public blackLists;

    mapping(address=>bool) public admin;
    uint256 public totalBetAmount;

    // event log
    event AddMatchInfo(uint256 matchId, string title, string teamA, string teamB, uint256 startBettingTime, uint256 endBettingTime, uint256 timeMatchStart);
    event AddBetType(uint256 matchId, uint8 betTypeId, string betDescription, uint8 numDoors, uint32[] odds, int32 goalRate);
    event EditBetTypeOdds(uint256 matchId, uint8 betTypeId, uint32[] odds);
    event EditBetOddsByMatch(uint256 matchId,uint32[] odds1x2, uint32[] oddsHandicap, uint32[] oddsOverUnder, int32 goalRateHandicap, int32 goalRateOverUnder, uint256 timestamp);
    event CancelMatch(uint256 matchId);
    event SettleMatchResult(uint256 matchId, uint8 betTypeId, uint8 _homeTeamGoals, uint8 _awayTeamGoals, uint256 timestamp);
    event NewTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 betAmount,uint256 betDoor, uint256 betOdd, int32 goalRate, uint256 bettingTime);
    event DrawTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 payout, uint256 fee, uint256 claimedTime);
    event DrawAllTicket(address player, uint256 payout, uint256 fee, uint256 claimedTime);
    event SetLimitBetAmount(string name, uint256 amount, uint256 timestamp);
    event WithdrawFund(uint256 amount, uint256 timestamp);
    event CancelTicket(uint256 ticketId, uint256 matchId, uint256 timestamp);

    constructor(VEGAERC20Token _token, address _marketingAddress) {
        admin[msg.sender] = true;
        tokenAddress = _token;
        marketingAddress = _marketingAddress;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "!admin");
        _;
    }

    modifier checkBlackList(){
        require(blackLists[msg.sender] != true, "player in black list");
        _;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin[_admin] = true;
    }

    function setFee(uint16 _fee) external onlyOwner {
        require(_fee >= 0, "fee must greater 0");
        fee = _fee;
    }

    function addNewMatch(uint256 _matchId, string memory _title, string memory _teamA, string memory _teamB, uint256 _startBettingTime,
        uint256 _endBettingTime, uint256 _timeMatchStart, uint32[] memory _odds1x2, uint32[] memory _oddsHandicap, uint32[] memory _oddsOverUnder, int32 _goalRateHandicap, int32 _goalRateOverUnder) external onlyAdmin {
        // _goalRateHandicap x oddsRate, _goalRateOverUnder x oddsRate
        require(_odds1x2.length == 3, "Invalid _odds1x2 length");
        require(_oddsHandicap.length == 2, "Invalid _oddsHandicap length");
        require(_oddsOverUnder.length == 2, "Invalid _oddsOverUnder length");

        require(_odds1x2[0] >= 0 && _odds1x2[1] >=0 && _odds1x2[2] >=0, "_odds1x2 must be greater than 0");
        require(_oddsHandicap[0] >=0 && _oddsHandicap[1] >=0, "_oddsHandicap must be greater than 0");
        require(_oddsOverUnder[0] >=0 && _oddsOverUnder[1] >=0, "_oddsOverUnder must be greater than 0");

        require(_goalRateOverUnder >= 0, "_goalRateOverUnder must be greater than 0");

        require(bytes(_title).length > 0, "_title required");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(bytes(matchInfo.title).length == 0, "_matchId already exist");

        // add matchinfo
        matchInfos[_matchId] = MatchInfo({
            matchId: _matchId,
            title: _title,
            teamA: _teamA,
            teamB: _teamB,
            startBettingTime: _startBettingTime,
            endBettingTime: _endBettingTime,
            timeMatchStart: _timeMatchStart,
            homeTeamGoals: 0,
            awayTeamGoals: 0,
            status: 0
        });

        // add bet 1x2
        matchBetTypes[_matchId].push(
            BetType({
                description: "Bet 1x2",
                numDoors: 3,
                odds: _odds1x2,
                goalRate: 0,
                status : 0
            })
        );

        // add bet handicap
        matchBetTypes[_matchId].push(
            BetType({
                    description: "Bet Handicap",
                    numDoors: 2,
                    odds: _oddsHandicap,
                    goalRate: _goalRateHandicap, // home/away = 1 1/2:0 <=> 15000, 0:1 <=> -10000
                    status : 0
            })
        );

        // add bet up/down
        matchBetTypes[_matchId].push(
            BetType({
                description: "Bet Over/Under",
                numDoors: 2,
                odds: _oddsOverUnder,
                goalRate: _goalRateOverUnder, // 2 goal <=> 20000
                status : 0
            })
        );
        emit AddMatchInfo(_matchId, _title, _teamA, _teamB, _startBettingTime, _endBettingTime, _timeMatchStart);
        emit AddBetType(_matchId, 0, "Bet 1x2", 3, _odds1x2, 0);
        emit AddBetType(_matchId, 1, "Bet Handicap", 2, _oddsHandicap, _goalRateHandicap);
        emit AddBetType(_matchId, 2, "Bet Over/Under", 2, _oddsOverUnder, _goalRateOverUnder);
    }

    function editMatchBetTypeOdds(uint256 _matchId, uint8 _betTypeId, uint32[] memory _odds, int32 goalRate) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp <= matchInfo.endBettingTime, "Late");

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(betType.odds.length == _odds.length, "Invalid _odds");

        uint256 _numDoors = _odds.length;
        for (uint256 i = 0; i < _numDoors; i++) {
            require(_odds[i] > oddsRate, "Odd must be greater than x1");
        }
        betType.odds = _odds;
        if(_betTypeId != 0) betType.goalRate = goalRate; // not type 1x2
        emit EditBetTypeOdds(_matchId, _betTypeId, _odds);
    }

    // edit 3 type bet
    function editMatchBetByMatch(uint256 _matchId, uint32[] memory _odds1x2, uint32[] memory _oddsHandicap, uint32[] memory _oddsOverUnder, int32 _goalRateHandicap, int32 _goalRateOverUnder) external onlyAdmin {
        require(_odds1x2.length == 3, "Invalid _odds1x2 length");
        require(_oddsHandicap.length == 2, "Invalid _oddsHandicap length");
        require(_oddsOverUnder.length == 2, "Invalid _oddsOverUnder length");

        require(_odds1x2[0] >= 0 && _odds1x2[1] >=0 && _odds1x2[2] >=0, "_odds1x2 must be greater than 0");
        require(_oddsHandicap[0] >=0 && _oddsHandicap[1] >=0, "_oddsHandicap must be greater than 0");
        require(_oddsOverUnder[0] >=0 && _oddsOverUnder[1] >=0, "_oddsOverUnder must be greater than 0");

        require(_goalRateOverUnder >= 0, "_goalRateOverUnder must be greater than 0");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp <= matchInfo.endBettingTime, "Too late");

        BetType storage betType1x2 = matchBetTypes[_matchId][0];
        BetType storage betTypeHandicap = matchBetTypes[_matchId][1];
        BetType storage betTypeOverUder = matchBetTypes[_matchId][2];

        betType1x2.odds = _odds1x2;

        betTypeHandicap.odds = _oddsHandicap;
        betTypeHandicap.goalRate = _goalRateHandicap;

        betTypeOverUder.odds = _oddsOverUnder;
        betTypeOverUder.goalRate = _goalRateOverUnder;

        emit EditBetOddsByMatch(_matchId, _odds1x2, _oddsHandicap, _oddsOverUnder, _goalRateHandicap, _goalRateOverUnder, block.timestamp);
    }

    function setStartBettingTime(uint256 _matchId, uint256 _startBettingTime) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.startBettingTime = _startBettingTime;
    }

    function setEndBettingTime(uint256 _matchId, uint256 _endBettingTime) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.endBettingTime = _endBettingTime;
    }

    function setTimeMatchStart(uint256 _matchId, uint256 _timeMatchStart) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.timeMatchStart = _timeMatchStart;
    }

    function setAndRemoveBlackList(address _player, bool _value) external onlyAdmin {
        blackLists[_player] = !!_value;
    }

    function setMaxBetAmount(uint256 _amount) external onlyAdmin {
        require(_amount > 0, "Amount must > 0");
        maxBetAmount = _amount;
        emit SetLimitBetAmount("Set max bet", _amount, block.timestamp);
    }

    function setMinBetAmount(uint256 _amount) external onlyAdmin {
        require(_amount > 0, "Amount must > 0");
        standardPrice = _amount;
        emit SetLimitBetAmount("Set min bet", _amount, block.timestamp);
    }

    function depositFund(uint256 _amount) external {
        require(_amount > 0, "Amount must > 0");
        SafeERC20.safeTransferFrom(tokenAddress, msg.sender, address(this), _amount);
        totalFundAmount += _amount;
    }

    function withdrawFund(uint256 _amount) external onlyOwner{
        require(_amount > 0, "Amount must > 0");
        SafeERC20.safeTransfer(tokenAddress, msg.sender, _amount);
        emit WithdrawFund(_amount, block.timestamp);
    }

    function cancelMatch(uint256 _matchId) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "Match is not new"); // 0-NEW 1-FINISH 9-CANCEL/POSTPONE
        matchInfo.status = 9;
        emit CancelMatch(_matchId);
    }

    function changeMarketingAddress(address _marketing) external onlyOwner {
        require(_marketing != address(0), "_marketing is null");
        marketingAddress = _marketing;
    }

    function changeTokenAddress(VEGAERC20Token _token) external onlyOwner {
        tokenAddress = _token;
    }

    function settleMatchResult(uint256 _matchId, uint8 _homeTeamGoals, uint8 _awayTeamGoals) external onlyAdmin {
        // 0-PENDING 1-WIN 2-LOSE 3-WIN-HALF 4-LOSE-HALF 5-DRAW 9-REFUND
        require(_homeTeamGoals >= 0, "Invalid _homeTeamGoals");
        require(_awayTeamGoals >= 0, "Invalid _awayTeamGoals");

        MatchInfo storage matchInfo = matchInfos[_matchId];

        require(block.timestamp > matchInfo.endBettingTime, "settleMatchResult too early");

        matchInfo.status = 1;
        matchInfo.homeTeamGoals = _homeTeamGoals;
        matchInfo.awayTeamGoals = _awayTeamGoals;

        // bet 1x2
        BetType storage betType = matchBetTypes[_matchId][0];
        betType.status = 1;

        // bet handicap
        betType = matchBetTypes[_matchId][1];
        betType.status = 1;

        // bet over/under
        betType = matchBetTypes[_matchId][2];
        betType.status = 1;

        emit SettleMatchResult(_matchId, 0, _homeTeamGoals, _awayTeamGoals, block.timestamp);
        emit SettleMatchResult(_matchId, 1, _homeTeamGoals, _awayTeamGoals, block.timestamp);
        emit SettleMatchResult(_matchId, 2, _homeTeamGoals, _awayTeamGoals, block.timestamp);
    }

    // user function bet
    function buyTicket(uint256 _matchId, uint8 _betTypeId, uint8 _betDoor, uint32 _betOdd, uint256 _betAmount) public checkBlackList  returns (uint256 _ticketIndex) {
        require(_betAmount >= standardPrice, "_betAmount less than standard price");

        uint256 _maxBetAmount = maxBetAmount;
        require(_betAmount <= _maxBetAmount, "_betAmount exceeds _maxBetAmount");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(block.timestamp >= matchInfo.startBettingTime, "early");
        require(block.timestamp <= matchInfo.endBettingTime, "late");
        require(matchInfo.status == 0, "Match not opened for ticket"); // 0-NEW 1-FINISH 9-CANCEL/POSTPONE

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(_betDoor < betType.numDoors, "Invalid _betDoor");
        require(_betOdd > 0, "_betOdd must be greater than 0"); // <=> betType.odds[_betDoor] > 0
        require(_betOdd == betType.odds[_betDoor], "Invalid _betOdd");

        address _player = msg.sender;
        SafeERC20.safeTransferFrom(tokenAddress, _player, address(this), _betAmount);

        _ticketIndex = tickets.length;

        tickets.push(
            Ticket({
                index : _ticketIndex,
                player : _player,
                matchId : _matchId,
                betTypeId : _betTypeId,
                betDoor : _betDoor,
                betOdd : _betOdd,
                betAmount : _betAmount,
                bettingTime : block.timestamp,
                payout: 0,
                goalRate: betType.goalRate,
                claimedTime : 0,
                status : 0 // 0-PENDING 1-WIN 2-LOSE 3-REFUND
            })
        );

        totalBetAmount = totalBetAmount.add(_betAmount);
        playerStats[_player].totalBet = playerStats[_player].totalBet.add(_betAmount);
        ticketsOf[_player].push(_ticketIndex);

        emit NewTicket(_player, _ticketIndex, _matchId, _betTypeId, _betAmount, _betDoor, _betOdd, betType.goalRate, block.timestamp);
    }

    // cancel buyticket
    function cancelBuyTicket(uint256 _ticketId) external checkBlackList {

        require(_ticketId < tickets.length, "_ticketIndex out of range");
        Ticket storage ticketInfo = tickets[_ticketId];
        uint256 _matchId = ticketInfo.matchId;
        MatchInfo memory matchInfo = matchInfos[_matchId];

        require(msg.sender == ticketInfo.player, "User not owner ticket");
        require(ticketInfo.status == 0, "Ticket settled");
        require(block.timestamp < matchInfo.endBettingTime, "cancel ticket late");
        SafeERC20.safeTransfer(tokenAddress, msg.sender, ticketInfo.betAmount);
        ticketInfo.status = 10; // CANCEL
        emit CancelTicket(_ticketId, ticketInfo.matchId, block.timestamp);
    }

    // get payout
    function getPayoutOfTicket(uint256 _ticketIndex) external view returns (uint256 _payout) {
        if(_ticketIndex >= tickets.length) return 0;

        Ticket storage ticket = tickets[_ticketIndex];
        if(ticket.status != 0) return 0;

        uint256 _matchId = ticket.matchId;

        MatchInfo memory matchInfo = matchInfos[_matchId];
        if(block.timestamp <= matchInfo.endBettingTime) return 0;

        uint8 _betTypeId = ticket.betTypeId;
        BetType storage betType = matchBetTypes[_matchId][_betTypeId];

        uint256 _betAmount = ticket.betAmount;

        if(matchInfo.status == 9) return _betAmount; // CANCEL/POSTPONE
        if(matchInfo.status != 1) return 0;

        uint8 _betDoor = ticket.betDoor;
        if(ticket.betTypeId == 0){
            if(matchInfo.homeTeamGoals > matchInfo.awayTeamGoals && _betDoor == 0) _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate); // door 0 win
            if(matchInfo.homeTeamGoals == matchInfo.awayTeamGoals && _betDoor == 1) _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate); // door 1 win
            if(matchInfo.homeTeamGoals < matchInfo.awayTeamGoals && _betDoor == 2) _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate); // door 2 win
        }

        if(ticket.betTypeId == 1){
            int64 delta = int64(matchInfo.homeTeamGoals * uint64(oddsRate)) + int64(betType.goalRate) - int64(matchInfo.awayTeamGoals * uint64(oddsRate));
            if(delta == 0) _payout = _betAmount; // draw
            if(delta > 0 && delta < 5000) {
                if(_betDoor == 0){
                    uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                    _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                } // door 0 win half
                if(_betDoor == 1){
                    _payout+= _betAmount.div(2);
                } // door 1 lost half
            }
            if(delta >= 5000) {
                if(_betDoor == 0) _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate); // door 0 win
            }
            if(delta < 0 && delta > -5000) {
                if(_betDoor == 0){
                    _payout+= _betAmount.div(2);
                } // door 0 lost half
                if(_betDoor == 1){
                    uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                    _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                } // door 1 win half
            }
            if(delta <= -5000) {
                if(_betDoor == 1) _payout = _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate); // door 1 win
            }
        }

        if(ticket.betTypeId == 2){
            uint32 totalGoal = (matchInfo.homeTeamGoals + matchInfo.awayTeamGoals) * oddsRate;
            if(uint32(betType.goalRate) == totalGoal) _payout = _betAmount; // draw
            if(totalGoal < uint32(betType.goalRate)) {
                if(_betDoor == 1){
                    _payout =  _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                } // under win
            }
            if(totalGoal > uint32(betType.goalRate)){
                if(_betDoor == 0){
                    _payout =  _betAmount.mul(uint256(ticket.betOdd)).div(oddsRate);
                } // over win
            }
        }
        return _payout;
    }

    // get value user claim all
    function getTotalPayout(address _address) external view returns (uint256){
        uint256 _payout = 0;
        for(uint k=0; k<ticketsOf[_address].length; k++){
            Ticket storage ticket = tickets[ticketsOf[_address][k]];
            _payout+= this.getPayoutOfTicket(ticket.index);
        }
        return _payout;
    }
    // user function claim all
    function claimAllPayout() external checkBlackList {
         uint256 _payout = 0;
         for(uint k=0; k<ticketsOf[msg.sender].length; k++){
             Ticket storage ticket = tickets[ticketsOf[msg.sender][k]];
             _payout+= this.getPayoutOfTicket(ticket.index);
             if(ticket.status == 0){
                 ticket.status = 1;
             }
         }
        uint256 _fee = _payout.mul(fee).div(1000); // fee
        if (_payout > 0) {
            SafeERC20.safeTransfer(tokenAddress, msg.sender, _payout);
            playerStats[msg.sender].payout = playerStats[msg.sender].payout.add(_payout);
            tokenAddress._claim(marketingAddress, _fee);
        }
        emit DrawAllTicket(msg.sender, _payout, _fee, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract VEGAERC20Token is ERC20, ERC20Burnable, AccessControl {
    using SafeMath for uint256;
    using Address for address;

    bool private initialized = false;

    address public _pairAddr;
    address public _marketingAddr;
    uint256 private _feeBuyPercent = 0;
    uint256 private _feeSellPercent = 0;
    uint256 private _feeTransactionPercent = 0;
    uint256 private _feeClaimPercent = 5;
    uint256 private _feeBuyTicketPercent = 5;
    uint256 private _walletMKTBuyPercent = 0;
    uint256 private _walletMKTSellPercent = 0;

    uint8 public constant INITIAL_DECIMAL = 18; // 9;
    uint256 public constant INITIAL_SUPPLY = 100 * 10 ** 9 * 10 ** INITIAL_DECIMAL;
    uint256 public _maxTxAmount = 3 * 10 ** 8 * 10 ** INITIAL_DECIMAL;
    uint256 public _maxTokenHolder = 2 * 10 ** 9 * 10 ** INITIAL_DECIMAL;

    bytes32 public constant CONTRACT_BET_ROLE = keccak256("CONTRACT_BET_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    bytes32 public constant MMER_ROLE = keccak256("MMER_ROLE");

    event UpdateTaxInfo(string action, address sender, uint256 feePercent);
    event Claim(address player, uint256 amount);
    event BuyTicket(address player, uint256 amount);

    constructor(address marketing_) ERC20("VEGA", "VEGA", INITIAL_DECIMAL, INITIAL_SUPPLY)  {
        require(!initialized, "Initialized first time");

        _marketingAddr = marketing_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MMER_ROLE, msg.sender);

        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
        excludeFromFee(address(0));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function getBuyTax() public view returns (uint256) {
        return _feeBuyPercent;
    }

    function getSellTax() public view returns (uint256) {
        return _feeSellPercent;
    }

    function getTransactionTax() public view returns (uint256) {
        return _feeTransactionPercent;
    }

    function getClaimTax() public view returns (uint256) {
        return _feeClaimPercent;
    }

    function getBuyTicketTax() public view returns (uint256) {
        return _feeBuyTicketPercent;
    }

    function getMarketingBuyTax() public view returns (uint256) {
        return _walletMKTBuyPercent;
    }

    function getMarketingSellTax() public view returns (uint256) {
        return _walletMKTSellPercent;
    }

    function setPair(address pairAddr_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pairAddr = pairAddr_;
    }

    function setMarketingWallet(address mktAddr_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _marketingAddr = mktAddr_;
    }

    function _claim(address to, uint256 amount) external onlyRole(CONTRACT_BET_ROLE) {
        require(to != address(0), "Transfer to the zero address");
        require(_marketingAddr != address(0), "Marketing Wallet to the zero address");
        require(hasRole(CONTRACT_BET_ROLE, _msgSender()), "Must be call from main contract");
        require(hasRole(BLACKLISTER_ROLE, to) != true, "To wallet address in blacklist transaction");
        uint256 balance = balanceOf(_msgSender());
        require(balance >= amount, "Transfer amount exceeds balance");

        uint256 tMarketing = calculateMarketingFee(amount, _walletMKTSellPercent);
        super._takeWalletTax(_marketingAddr, tMarketing);

        super.setFeePercent(_feeClaimPercent);
        super._transferStandard(_msgSender(), to, amount.sub(tMarketing));

        _afterTokenTransfer(_msgSender(), to, amount);
        emit Claim(to, amount);
    }

    function _buy(address player, uint256 amount) external {
        require(player != address(0), "Transfer to the zero address");
        require(_marketingAddr != address(0), "Marketing Wallet to the zero address");
        _spendAllowance(player, _msgSender(), amount);

        require(hasRole(CONTRACT_BET_ROLE, _msgSender()), "Must be call from main contract");
        require(hasRole(BLACKLISTER_ROLE, player) != true, "To wallet address in blacklist transaction");

        uint256 balance = balanceOf(player);
        require(balance >= amount, "Transfer amount exceeds balance");

        uint256 tMarketing = calculateMarketingFee(amount, _walletMKTBuyPercent);
        super._takeWalletTax(_marketingAddr, tMarketing);

        super.setFeePercent(_feeBuyTicketPercent);
        super._transferStandard(_msgSender(), player, amount.sub(tMarketing));

        _afterTokenTransfer(player, _msgSender(), amount);
        emit BuyTicket(player, amount);
    }


    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(hasRole(BLACKLISTER_ROLE, from) != true, "From wallet address in blacklist transaction");
        require(hasRole(BLACKLISTER_ROLE, to) != true, "To wallet address in blacklist transaction");
        require(amount > 0, "Transfer amount must be greater than zero");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "Transfer amount exceeds balance");

        if (isExcludedFromFee(from) || isExcludedFromFee(to)) {
            super.setFeePercent(uint256(0));
        } else if (from == _pairAddr) {
            super.setFeePercent(_feeBuyPercent);
        } else if (to == _pairAddr) {
            super.setFeePercent(_feeSellPercent);
        } else {
            super.setFeePercent(_feeTransactionPercent);
        }

        super._transferStandard(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20) {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if (from == _pairAddr) {
            require(balanceOf(to).add(amount) < _maxTokenHolder, "You can not hold more than limit holder Total supply");
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
        emit Transfer(from, to, amount);
    }

    function setTaxBuy(uint256 fee_) external onlyRole(MMER_ROLE) {
        _feeBuyPercent = fee_;
        emit UpdateTaxInfo("Buy Fee", _msgSender(), _feeBuyPercent);
    }

    function setTaxSell(uint256 fee_) external onlyRole(MMER_ROLE) {
        _feeSellPercent = fee_;
        emit UpdateTaxInfo("Sell Fee", _msgSender(), _feeSellPercent);
    }

    function setTaxTransfer(uint256 fee_) external onlyRole(MMER_ROLE) {
        _feeTransactionPercent = fee_;
        emit UpdateTaxInfo("Transaction Fee", _msgSender(), _feeTransactionPercent);
    }

    function setClaimTax(uint256 fee_) external onlyRole(MMER_ROLE) {
        _feeClaimPercent = fee_;
        emit UpdateTaxInfo("ClaimReward Fee", _msgSender(), _feeClaimPercent);
    }

    function setBuyTicketTax(uint256 fee_) external onlyRole(MMER_ROLE) {
        _feeBuyTicketPercent = fee_;
        emit UpdateTaxInfo("BuyTicket Fee", _msgSender(), _feeBuyTicketPercent);
    }

    function setMarketingBuyTax(uint256 fee_) external onlyRole(MMER_ROLE) {
        _walletMKTBuyPercent = fee_;
        emit UpdateTaxInfo("Marketing BuyTicket Fee", _msgSender(), _walletMKTBuyPercent);
    }

    function setMarketingSellTax(uint256 fee_) external onlyRole(MMER_ROLE) {
        _walletMKTSellPercent = fee_;
        emit UpdateTaxInfo("Marketing ClaimReward Fee", _msgSender(), _walletMKTSellPercent);
    }

    function calculateMarketingFee(uint256 _amount, uint256 fee) private pure returns (uint256) {
        return _amount.mul(fee).div(10 ** 2);
    }

    function isExcludedFromFee(address account) public view override returns (bool) {
        return super.isExcludedFromFee(account);
    }

    function excludeFromFee(address account) public onlyRole(MMER_ROLE) {
        super._excludeFromFee(account);
    }

    function includeInFee(address account) public onlyRole(MMER_ROLE) {
        return super._includeInFee(account);
    }

    function setMaxTokenHolder(uint256 newMaxTokenHolder) external onlyRole(MMER_ROLE) {
        _maxTokenHolder = newMaxTokenHolder;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyRole(MMER_ROLE) {
        _maxTxAmount = maxTxAmount;
    }

    function isWalletBlacklist() public view returns (bool){
        return hasRole(BLACKLISTER_ROLE, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant MAX = ~uint256(0);

    mapping(address => uint256) private _rOwned;
    uint256 private _rTotalSupply;
    uint256 private _totalSupply;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 public _taxPercent;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 9;
    address internal burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        require(decimals_ > 0, "ERC20: decimal must be larger than 0");
        require(totalSupply_ > 0, "ERC20: total must be larger than 0");

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _rTotalSupply = (MAX - (MAX % _totalSupply));
        _rOwned[_msgSender()] = _rTotalSupply;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
    }

    function setFeePercent(uint256 fee) internal {
        _taxPercent = fee;
    }

    function isExcludedFromFee(address account) public view virtual returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _excludeFromFee(address account) public virtual {
        _isExcludedFromFee[account] = true;
    }

    function _includeInFee(address account) public virtual {
        _isExcludedFromFee[account] = false;
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotalSupply, "ERC20: Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        return (_rTotalSupply, _totalSupply);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee);
    }


    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxPercent).div(10 ** 2);
    }

    function _reflectFee(uint256 rFee) private {
        _rTotalSupply = _rTotalSupply.sub(rFee);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {}

    function _transferStandard(address from, address to, uint256 tAmount) internal {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _reflectFee(rFee);
    }

    function _takeWalletTax(address walletMKT, uint256 tMKTAmount) internal {
        uint256 currentRate = _getRate();
        uint256 rMKTAmount = tMKTAmount.mul(currentRate);
        _rOwned[walletMKT] = _rOwned[walletMKT].add(rMKTAmount);
    }


    function _mint(address account, uint256 amount) internal virtual {}

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, burnAddress, amount);

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        uint256 rBurnAmount = amount.mul(_getRate());
    unchecked {
        _rOwned[account] = _rOwned[account].sub(rBurnAmount);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurnAmount);
    }
        _afterTokenTransfer(account, burnAddress, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "./ERC20.sol";

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}