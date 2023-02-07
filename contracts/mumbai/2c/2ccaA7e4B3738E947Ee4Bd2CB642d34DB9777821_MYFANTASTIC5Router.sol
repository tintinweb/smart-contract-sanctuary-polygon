// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import "./ERC20.sol";
import "./ChainlinkClient.sol";

contract MYFANTASTIC5Router is ChainlinkClient {
    struct fantasyTeam {
        address owner;
        uint8 captain;
        uint8 player2;
        uint8 player3;
        uint8 player4;
        uint8 player5;
        uint32 timestamp;
        bool isClaimed;
        uint8 point;
        uint32 rank;
    }
    //========================================
    //START static PART
    //========================================
    address public _owner;

    uint8 private constant playerLength = 30;

    //for marking if the result is announced
    uint8 private constant pointPerAssist = 3;
    uint8 private constant pointPerGoal = 6;

    //percents
    uint8 private constant _firstPrizePercent = 50;
    uint8 private constant _secondPrizePercent = 20;
    uint8 private constant _otherTop10PrizePercent = 24;
    uint8 private constant _devPercent = 6;

    //ticket_index => fantasyTeam
    mapping(uint32 => fantasyTeam) private _teamSubmitedList;
    //recent length of _teamSubmitedList
    uint32 private _teamSubmitedLength;

    //owner's address => recent length of _teamHeldList for this address
    mapping(address => uint32) private _teamHeldLength;

    //#goal for all playerLength players //init with 255
    uint8[playerLength] private _goalScored = [
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255
    ];
    //#assist for all 30 players //init with 255
    uint8[playerLength] private _assistMade = [
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255,
        255
    ];
    bytes32[playerLength] private _goalAssistReqId;

    //prize pool
    uint256 public _prizePool;
    //if this round is announced
    bool public _isAnnounced;
    //if dev has claimed reward
    bool private _isDevClaimed;
    //========================================
    //START dynamic PART changed by round
    //========================================
    string private constant round = "5";
    //deadline sale time for each round
    uint32 public _closedSaleTimestamp = 1676404800; //1st Leg
    //player Id in UCL official website
    string[playerLength] private _playerId = [
        "250076574",
        "250052469",
        "250103758",
        "250061119",
        "93321",
        "95803",
        "250008901",
        "250016833",
        "250043463",
        "250039508",
        "250121533",
        "250003318",
        "250070687",
        "250024795",
        "250063984",
        "250076654",
        "250080471",
        "250010802",
        "250116654",
        "250132811",
        "54694",
        "250087938",
        "250041770",
        "250129539",
        "250089228",
        "250063447",
        "250118281",
        "250101534",
        "250144965",
        "250059115"
    ];

    //========================================
    //START chainlink  PART
    //========================================
    address private constant _LINK = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    using Chainlink for Chainlink.Request;
    event RequestFulfilledBytes(bytes32 indexed requestId, bytes response);
    event RequestFulfilledUint256Pair(
        bytes32 indexed requestId,
        uint256 response1,
        uint256 response2
    );
    //chainlink fee per request
    uint256 constant LINK_fee = (LINK_DIVISIBILITY / 10) * 1; // 0.1LINK
    //========================================
    //END chainlink  PART
    //========================================

    modifier ensure(uint32 deadline) {
        require(deadline >= block.timestamp, "MYFANTASTIC5Router: EXPIRED");
        _;
    }
    modifier isOwner() {
        require(
            msg.sender == _owner,
            "MYFANTASTIC5Router: AUTHORIZATION_FAILED"
        );
        _;
    }

    constructor() {
        _owner = msg.sender;

        setChainlinkToken(_LINK);
        setChainlinkOracle(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434);
    }

    function getPrice() public view virtual returns (uint256 price) {
        return 1 * (10**16);
    }

    function getAllTeamsByHolder(address holder)
        public
        view
        virtual
        returns (uint32[] memory indices, fantasyTeam[] memory teams)
    {
        teams = new fantasyTeam[](_teamHeldLength[holder]);
        indices = new uint32[](_teamHeldLength[holder]);
        uint32 counter = 0;
        for (uint32 i = 0; i < _teamSubmitedLength; i++) {
            if (_teamSubmitedList[i].owner == holder) {
                teams[counter] = _teamSubmitedList[i];
                indices[counter] = i;
                counter++;
            }
            if (counter == _teamHeldLength[holder]) {
                break;
            }
        }
        return (indices, teams);
    }

    function getAllTeams()
        public
        view
        virtual
        returns (fantasyTeam[] memory teams)
    {
        teams = new fantasyTeam[](_teamSubmitedLength);
        for (uint32 i = 0; i < _teamSubmitedLength; i++) {
            teams[i] = _teamSubmitedList[i];
        }
        return teams;
    }

    function getSharePercents()
        public
        view
        virtual
        returns (
            uint8 firstPrizePercent,
            uint8 secondPrizePercent,
            uint8 otherTop10PrizePercent,
            uint8 devPercent
        )
    {
        return (
            _firstPrizePercent,
            _secondPrizePercent,
            _otherTop10PrizePercent,
            _devPercent
        );
    }

    function getClaimableAmountByTeamIndex(uint32 teamIndex)
        public
        view
        virtual
        returns (uint256 claimable)
    {
        if (!_isAnnounced) {
            return 0;
        }
        fantasyTeam memory team = _teamSubmitedList[teamIndex];
        if (team.rank == 1) {
            claimable = (_prizePool * _firstPrizePercent) / 100;
        } else if (team.rank == 2) {
            claimable = (_prizePool * _secondPrizePercent) / 100;
        } else if (team.rank >= 3 && team.rank <= 10) {
            //share with 8 winners
            claimable = (_prizePool * _otherTop10PrizePercent) / 100 / 8;
        }

        return claimable;
    }

    function submitTeam(
        uint8 captain,
        uint8 player2,
        uint8 player3,
        uint8 player4,
        uint8 player5,
        address teamOwner,
        uint32 deadline
    ) external payable virtual ensure(deadline) returns (bool success) {
        require(
            block.timestamp < _closedSaleTimestamp,
            "MYFANTASTIC5Router: TICKET_SALE_IS_CLOSED"
        );
        require(
            !_isAnnounced,
            "MYFANTASTIC5Router: TICKETS_ARE_NOT_ON_SALE_AFTER_ANNOUNCING"
        );
        require(
            msg.value >= getPrice(),
            "MYFANTASTIC5Router: OFFERED_PRICE_IS_TOO_LOW"
        );

        //init fantasyTeam
        fantasyTeam memory thisTeam = fantasyTeam({
            owner: teamOwner,
            captain: captain,
            player2: player2,
            player3: player3,
            player4: player4,
            player5: player5,
            timestamp: uint32(block.timestamp),
            isClaimed: false,
            point: 0,
            rank: 0
        });

        //increment to this ticketTaker
        _teamHeldLength[teamOwner]++;

        //add this team to the sold ticket list
        uint32 curSoldLength = _teamSubmitedLength;
        _teamSubmitedList[curSoldLength] = thisTeam;
        _teamSubmitedLength = curSoldLength + 1;

        //increase _prizePool by offered ticketPrice
        _prizePool += msg.value;

        return true;
    }

    function claimReward(uint16 teamIndex, uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amount)
    {
        require(
            !_teamSubmitedList[teamIndex].isClaimed,
            "MYFANTASTIC5Router: THIS_TEAM_IS_CLAIMED"
        );
        require(
            _teamSubmitedList[teamIndex].owner == msg.sender,
            "MYFANTASTIC5Router: THIS_TEAM_IS_NOT_YOURS"
        );
        amount = getClaimableAmountByTeamIndex(teamIndex);
        //transfer reward to the ticket holder
        (bool success, ) = payable( _teamSubmitedList[teamIndex].owner).call{value: amount}("");
        require(success, "MYFANTASTIC5Router: TEAM_CLAIM_PAYMENT_FAILED");

        //mark that this team is claimed
        _teamSubmitedList[teamIndex].isClaimed = true;

        return amount;
    }

    function claimRewardDev(uint32 deadline)
        external
        virtual
        ensure(deadline)
        returns (uint256 amount)
    {
        require(
            _isAnnounced,
            "MYFANTASTIC5Router: DEVS_CANT_CLAIM_BEFORE_ANNOUNCING"
        );
        require(!_isDevClaimed, "MYFANTASTIC5Router: DEVS_CLAIMED_ALREADY");

        amount = (_prizePool * _devPercent) / 100;

        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "MYFANTASTIC5Router: DEVS_CLAIM_PAYMENT_FAILED");

        //mark that devs claimed
        _isDevClaimed = true;

        return amount;
    }

    //==============
    //Update point for All teams
    //==============
    function updatePointAllTeams() private {
        for (uint32 i = 0; i < _teamSubmitedLength; i++) {
            fantasyTeam memory team = _teamSubmitedList[i];
            uint8 point = 0;
            point += _goalScored[team.captain] * pointPerGoal * 2;
            point += _goalScored[team.player2] * pointPerGoal;
            point += _goalScored[team.player3] * pointPerGoal;
            point += _goalScored[team.player4] * pointPerGoal;
            point += _goalScored[team.player5] * pointPerGoal;

            point += _assistMade[team.captain] * pointPerAssist * 2;
            point += _assistMade[team.player2] * pointPerAssist;
            point += _assistMade[team.player3] * pointPerAssist;
            point += _assistMade[team.player4] * pointPerAssist;
            point += _assistMade[team.player5] * pointPerAssist;

            team.point = point;
            //save
            _teamSubmitedList[i] = team;
        }
    }

    //==============
    //Update rank for All teams
    //==============
    function updateRankAllTeams() private {
        for (uint32 j = 0; j < _teamSubmitedLength; j++) {
            uint32 betterTeamCount = 0;
            for (uint32 k = 0; k < _teamSubmitedLength; k++) {
                if (j != k) {
                    if (
                        _teamSubmitedList[k].point > _teamSubmitedList[j].point
                    ) {
                        betterTeamCount++;
                    } else if (
                        _teamSubmitedList[k].point ==
                        _teamSubmitedList[j].point &&
                        k < j
                    ) {
                        betterTeamCount++;
                    }
                }
            }
            uint32 rank = betterTeamCount + 1;
            _teamSubmitedList[j].rank = rank;
        }
        _isAnnounced = true;
    }

    function updatePandR(uint32 deadline) public ensure(deadline) {
        bool isDataReady = true;
        for (uint32 i = 0; i < playerLength; i++) {
            if (_goalScored[i] == 255 || _assistMade[i] == 255) {
                isDataReady = false;
            }
        }
        require(isDataReady, "MYFANTASTIC5Router: DATA_IS_NOT_READY");
        updatePointAllTeams();
        updateRankAllTeams();
    }

    function getGoalAndAssist()
        public
        view
        virtual
        returns (
            uint8[playerLength] memory goalScored,
            uint8[playerLength] memory assistMade
        )
    {
        return (_goalScored, _assistMade);
    }

    //========================================
    //START chainlink  PART
    //========================================
    function reqDataWithChainLink(bytes32 jobIdUint256Pair, uint32 deadline)
        public
        ensure(deadline)
        returns (bool success)
    {
        //transfer LINK from caller to this contract
        IERC20(_LINK).transferFrom(
            msg.sender,
            address(this),
            (LINK_fee * playerLength)
        );
        //check LINK amount in this contract
        require(
            IERC20(_LINK).balanceOf(address(this)) >= (LINK_fee * playerLength),
            "MYFANTASTIC5Router: NOT_ENOUGH_LINK_TO_PAY_AS_FEE(playerLength x FEE)"
        );

        Chainlink.Request memory req;

        for (uint32 i = 0; i < playerLength; i++) {
            string memory url = string(
                abi.encodePacked(
                    "https://gaming.uefa.com/en/uclfantasy/services/feeds/popupstats/popupstats_50_",
                    _playerId[i],
                    ".json"
                )
            );
            req = buildChainlinkRequest(
                jobIdUint256Pair,
                address(this),
                this.fulfillUint256Pair.selector
            );
            req.add("get", url);
            req.add(
                "path1",
                string(abi.encodePacked("data,value,stats,", round, ",gS"))
            );
            req.add(
                "path2",
                string(abi.encodePacked("data,value,stats,", round, ",gA"))
            );
            req.addInt("multiply", 1);
            _goalAssistReqId[i] = sendOperatorRequest(req, LINK_fee);
        }
        return true;
    }

    function fulfillUint256Pair(
        bytes32 requestId,
        uint256 response1,
        uint256 response2
    ) public recordChainlinkFulfillment(requestId) {
        emit RequestFulfilledUint256Pair(requestId, response1, response2);
        for (uint32 i = 0; i < playerLength; i++) {
            if (requestId == _goalAssistReqId[i]) {
                _goalScored[i] = uint8(response1);
                _assistMade[i] = uint8(response2);
                break;
            }
        }
    }

    //test fulfillUint256PairManual
    function fulfillUint256PairManual(
        uint8[30] memory goalScored,
        uint8[30] memory assistMade
    ) public {
        _goalScored = goalScored;
        _assistMade = assistMade;
    }
}