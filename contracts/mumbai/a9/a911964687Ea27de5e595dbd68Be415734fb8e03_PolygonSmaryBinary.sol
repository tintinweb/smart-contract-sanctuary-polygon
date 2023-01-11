// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EnumerableArrays.sol";
import "./PriceFeed.sol";

import "./LotteryPool/LotteryPool.sol";
import "./ExtraPool/ExtraPool.sol";
import "./SystemPool/SystemPool.sol";

abstract contract DataStorage is EnumerableArrays, PriceFeed {

    LotteryPool public LPool;
    ExtraPool public XPool;
    SystemPool SPool;   

    address payable rewardAddr;
    address payable lotteryAddr;
    address payable extraAddr;
    address payable systemAddr;


// data and info -----------------------------------------------------------------

    struct NodeData {
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint16 maxPoints;
        uint16 todayPoints;
        uint16 childs;
        uint16 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => uint256) public userAllEarned;
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(uint256 => address) idToAddr;


    uint256 public allPayments;
    uint256 public todayPayments;
    uint256 public lastReward24h;
    uint256 public lastReward7d;
    uint256 public lastReward30d;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public todayPointOverFlow;

    address public lastRewardWriter;

// checking -------------------------------------------------------------
    mapping(address => bool) public registered;




    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint + todayPointOverFlow;
        denominator = denominator > 0 ? denominator : 1;
        return address(this).balance / denominator;
    }

    function userData(address userAddr) public view returns(NodeData memory) {
        return _userData[userAddr];
    }

    function userInfo(address userAddr) public view returns(NodeInfo memory) {
        return _userInfo[userAddr];
    }


    function userUpAddr(address userAddr) public view returns(address) {
        return _userInfo[userAddr].uplineAddress;
    }

    function userChilds(address userAddr)
        public
        view
        returns (address left, address right)
    {
        left = _userInfo[userAddr].leftDirectAddress;
        right = _userInfo[userAddr].rightDirectAddress;        
    } 

    function userChildsCount(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].childs;        
    } 

    function userDepth(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].depth;        
    } 
    
    function userTodayPoints(address userAddr) public view returns (uint256) {
        return _userData[userAddr].todayPoints;
    }
    
    function userTodayDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        uint256 points = userTodayPoints(userAddr);

        left = _userData[userAddr].leftVariance + points;
        right = _userData[userAddr].rightVariance + points;
    }
    
    function userAllTimeDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        left = _userData[userAddr].allLeftDirect;
        right = _userData[userAddr].allRightDirect;
    }












// reward 30 days -------------------------------------------------------

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract EnumerableArrays {

    mapping(uint256 => mapping(address => uint256)) _monthPoints;
    mapping(uint256 => address[]) _rewardReceivers;

    uint256 rcIndex;
    uint256 monthCounter;
    
    function _resetRewardReceivers() internal {
        rcIndex++;
    }
    function _resetMonthPoints() internal {
        monthCounter ++;
    }

    function todayRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _rewardReceivers[rcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _rewardReceivers[rcIndex][i];
        }
    }

    function todayRewardReceiversCount() public view returns(uint256) {
        return _rewardReceivers[rcIndex].length;
    }

    function monthPoints(address userAddr) public view returns(uint256) {
        return _monthPoints[monthCounter][userAddr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract EDataStorage {
    
    uint256 erIndex;
    uint256 epIndex;

    mapping(uint256 => address[]) _extraRewardReceivers;
    mapping(uint256 => mapping(address => uint256)) _userExtraPoints;

    function _resetExtraPoints() internal {
        epIndex ++;
    }
    function _resetExtraRewardReceivers() internal {
        erIndex++;
    }

    function extraRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _extraRewardReceivers[erIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _extraRewardReceivers[erIndex][i];
        }
    }

    function extraRewardReceiversCount() public view returns(uint256) {
        return _extraRewardReceivers[erIndex].length;
    }

// -----------------------------------------------------------------------------------------

    mapping(address => uint256) public userAllEarned;

    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        return balance() / extraPointCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EDataStorage.sol";

// in contract hame chizesh bayad test she
contract ExtraPool is EDataStorage{

    address polygonSb;

    constructor (address _polygonSb) {
        polygonSb = _polygonSb;
    }

    modifier onlyPolygonSb() {
        require(msg.sender == polygonSb, "only polygonSb can call this function");
        _;
    }

/// bayad check she
    function distribute() public onlyPolygonSb {
        uint256 count = extraRewardReceiversCount();
        if(count > 0) {
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                userAllEarned[userAddr] += earning;
                payable(userAddr).transfer(earning);
            }
        } else {
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyPolygonSb {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPolygonSb {
    function registered(address userAddr) external view returns(bool);
    function userTodayPoints(address userAddr) external view returns(uint256);
    function USD_MATIC() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract LDataStorage {

    uint256 lcIndex;
    uint256 lwIndex;

    mapping(uint256 => address[]) _lotteryCandidates;
    mapping(uint256 => address[]) _lotteryWinners;

    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }

    function todayLotteryCandidates() public view returns(address[] memory addr) {
        uint256 len = _lotteryCandidates[lcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryCandidates[lcIndex][i];
        }
    }

    function lastLotteryWinners() public view returns(address[] memory addr) {
        uint256 len = _lotteryWinners[lwIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryWinners[lwIndex][i];
        }
    }

    function lotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length;
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length;
    }


// ---------------------------------------------------------------------------------------

    mapping(address => uint256) public userAllEarned;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayLotteryWinnersCount() public view returns(uint256) {
        return lotteryCandidatesCount() * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        return balance() / todayLotteryWinnersCount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";
import "../IPolygonSb.sol";

contract LotteryPool is LDataStorage {
    
    address polygonSb;
    IPolygonSb PSB;

    constructor (address _polygonSb) {
        polygonSb = _polygonSb;
        PSB = IPolygonSb(_polygonSb);
    }

    modifier onlyPolygonSb() {
        require(msg.sender == polygonSb, "only polygonSb can call this function");
        _;
    }

// shadidan test lazem
    function distribute() public onlyPolygonSb {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 winnersCount = todayLotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, PSB.USD_MATIC()
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            userAllEarned[winner] += lotteryFraction;
            payable(winner).transfer(lotteryFraction);
        }
        
        _resetLotteryCandidates();
    }

    function registerInLottery() public payable {
        address userAddr = msg.sender;
        require(
            PSB.registered(userAddr),
            "This address is not registered in Smart Binary Contract!"
        );
        require(
            PSB.userTodayPoints(userAddr) == 0,
            "You Have Points Today"
        );
        uint256 ticketPrice = 1 * PSB.USD_MATIC();
        require(
            msg.value >= ticketPrice,
            "minimum lottery enter price is 1 USD in MATIC"
        );
        uint256 numTickets = msg.value / ticketPrice;
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";

contract PolygonSmaryBinary is DataStorage {

    constructor(
        address _aggregator
    ) PriceFeed(_aggregator) {

        address polygonSbAddr = address(this);
        _updateMaticePrice();

        LPool = new LotteryPool(polygonSbAddr);
        XPool = new ExtraPool(polygonSbAddr);
        SPool = new SystemPool(polygonSbAddr);

        lotteryAddr = payable(address(LPool));        
        extraAddr = payable(address(XPool));
        systemAddr = payable(address(SPool));
    }


// register ---------------------------------------------------------------------------------
    function register(address upAddr) public payable {
        address userAddr = msg.sender;
        uint256 enterPrice = msg.value;

        checkCanRegister(userAddr, upAddr);
        (uint16 todayPoints, uint16 maxPoints, uint16 directUp) = checkEnterPrice(enterPrice);
        registered[userAddr] = true;

        _payShares(enterPrice);

        _newUserId(userAddr);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr, todayPoints);
        _setDirects(userAddr, upAddr, directUp);
    }

    function checkCanRegister(
        address userAddr, 
        address upAddr
    ) public view returns(bool) {
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            userAddr != upAddr,
            "You can not enter your own address!"
        );
        require(
            !registered[userAddr],
            "This address is already registered!"
        );
        require(
            registered[upAddr],
            "This Upline address does Not Exist!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint16 todayPoints, uint16 maxPoints, uint16 directUp
    ) {
        if(enterPrice == 20 * USD_MATIC) {
            maxPoints = 10;
            directUp = 1;
        } else if(enterPrice == 60 * USD_MATIC) {
            maxPoints = 30;
            directUp = 3;
        } else if(enterPrice == 100 * USD_MATIC) {
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
        } else {
            revert("Wrong enter price");
        }
    }

    // todayPayments ro bayad tooye reward24 delete konam
    function _payShares(uint256 enterPrice) internal {
        allPayments += enterPrice;
        todayPayments += enterPrice;

        lotteryAddr.transfer(enterPrice * 15/100);
        extraAddr.transfer(enterPrice * 10/100);
        systemAddr.transfer(enterPrice * 5/100);
    }

    function _newUserId(address userAddr) internal {
        idToAddr[userCount] = userAddr;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr, uint16 maxPoints, uint16 todayPoints) internal {
        _userData[userAddr] = NodeData (
            0,
            0,
            0,
            0,
            _userData[upAddr].depth + 1,
            maxPoints,
            todayPoints,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
    }

    function _setChilds(address userAddr, address upAddr, uint16 todayPoints) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;

        if(todayPoints != 0) {
            if(_userData[userAddr].todayPoints == 0) {
                _rewardReceivers[rcIndex].push(userAddr);
            }
            _userData[userAddr].todayPoints++;
        }
    }

    function _setDirects(address userAddr, address upAddr, uint16 directUp) internal { 
        address[] storage rewardReceivers = _rewardReceivers[rcIndex];

        uint256 depth = _userData[userAddr].depth;
        uint16 _pointsOverFlow;
        uint16 _totalPoints;
        for (uint256 i; i < depth; i++) {
            uint16 points;
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance += directUp;
                } else {
                    if(_userData[upAddr].rightVariance < directUp) {
                        uint16 v = _userData[upAddr].rightVariance;
                        _userData[upAddr].rightVariance = 0;
                        _userData[upAddr].leftVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].rightVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allLeftDirect += directUp;
            } else {
                if(_userData[upAddr].leftVariance == 0){
                    _userData[upAddr].rightVariance += directUp;
                } else {
                    if(_userData[upAddr].leftVariance < directUp) {
                        uint16 v = _userData[upAddr].leftVariance;
                        _userData[upAddr].leftVariance = 0;
                        _userData[upAddr].rightVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].leftVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allRightDirect += directUp;
            }

            uint16 userNeededPoints = _userData[upAddr].maxPoints - _userData[upAddr].todayPoints;
            if(userNeededPoints >= points) {
                if(userNeededPoints == 50){
                    rewardReceivers.push(upAddr);
                }
                _userData[upAddr].todayPoints += points;
                _totalPoints += points;
            } else {
                _userData[upAddr].todayPoints += userNeededPoints;
                _totalPoints += userNeededPoints;
                _pointsOverFlow += points - userNeededPoints;
            }

            _addMonthPoint(upAddr, points);

            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }

        todayTotalPoint += _totalPoints;
        todayPointOverFlow += _pointsOverFlow;
    }

// topUp --------------------------------------------------------------------------------------

    function topUp() public payable {
        address userAddr = msg.sender;
        uint256 topUpPrice = msg.value;

        address upAddr = _userInfo[userAddr].uplineAddress;
        (uint16 maxPoints, uint16 directUp) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice);
        _setDirects(userAddr, upAddr, directUp);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint16 maxPoints, uint16 directUp
    ) {
        require(
            registered[userAddr],
            "You have not registered!"
        );

        if(topUpPrice == 40 * USD_MATIC) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point is 50"
            );
            maxPoints = 20;
            directUp = 2;
        } else if(topUpPrice == 80 * USD_MATIC) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            maxPoints = 40;
            directUp = 4;
        } else {
            revert("Wrong TopUp price");
        }
    }

// reward24 -----------------------------------------------------------------------------------

    function trigger() public {
        require(
            block.timestamp >= lastReward24h + 24 hours,
            "The Reward_24 Time Has Not Come"
        );
        _reward24h();

        if(block.timestamp >= lastReward7d + 7 days) {
            LPool.distribute();
        }
        if(block.timestamp >= lastReward30d + 30 days) {
            XPool.distribute();
            lastReward30d = block.timestamp;
            _resetMonthPoints();
        }
        _updateMaticePrice();
    }

// writer o call lottery ro azash keshidam biroon. bayad ba noskhe qabli moqayese konam bebinam bedone bug bashe.
    function _reward24h() internal {
        lastReward24h = block.timestamp;

        uint256 pointValue = todayEveryPointValue();

        address[] storage rewardReceivers = _rewardReceivers[rcIndex];

        address userAddr;
        uint256 len = rewardReceivers.length;
        for(uint256 i; i < len; i++) {
            userAddr = rewardReceivers[i];
            uint256 userEarning = _userData[userAddr].todayPoints * pointValue;
            userAllEarned[userAddr] += userEarning;
            payable(userAddr).transfer(userEarning);
            delete _userData[userAddr].todayPoints;
        }
        systemAddr.transfer(todayPointOverFlow * pointValue);
        delete todayTotalPoint;
        delete todayPayments;
        delete todayPointOverFlow;
        _resetRewardReceivers();
    }

// bayad test she
    function _addMonthPoint(address userAddr, uint256 points) internal {
        uint256 userNeededPoints = 50 - _monthPoints[monthCounter][userAddr];

        if(userNeededPoints >= points) {
            _monthPoints[monthCounter][userAddr] += points;
        } else {
            _monthPoints[monthCounter][userAddr] = points - userNeededPoints;
            XPool.addAddr(userAddr);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

abstract contract PriceFeed {
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public USD_MATIC;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        _updateMaticePrice();
    }

    function _updateMaticePrice() internal {
        USD_MATIC = 10 ** 26 / uint256(AGGREGATOR_MATIC_USD.latestAnswer());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address polygonSb;

    constructor (address _polygonSb) {
        polygonSb = _polygonSb;
    }

    modifier onlyPolygonSb() {
        require(msg.sender == polygonSb, "only polygonSb can call this function");
        _;
    }
}