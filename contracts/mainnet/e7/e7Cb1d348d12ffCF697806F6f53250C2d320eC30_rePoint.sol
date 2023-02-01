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


    struct NodeData {
        uint24 allUsersLeft;
        uint24 allUsersRight;
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint16 maxPoints;
        uint16 childs;
        uint16 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => uint256) _userAllEarned_USD;
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(string => address) public nameToAddr;
    mapping(address => string) public addrToName;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    uint256 public lastReward24h;
    uint256 public lastReward7d;
    uint256 public lastReward30d;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public todayPointOverflow;
    uint256 public todayEnteredUSD;
    uint256 public allEnteredUSD;


    function AllPayments() public view returns(
        uint256 rewardPaymentsMATIC,
        uint256 rewardPaymentsUSD,
        uint256 extraPaymentsMATIC,
        uint256 extraPaymentsUSD,
        uint256 lotteryPaymentsMATIC,
        uint256 lotteryPaymentsUSD
    ) {
        rewardPaymentsMATIC = allPayments_MATIC;
        rewardPaymentsUSD = allPayments_USD;
        extraPaymentsMATIC = XPool.allPayments_MATIC();
        extraPaymentsUSD = XPool.allPayments_USD();
        lotteryPaymentsMATIC = LPool.allPayments_MATIC();
        lotteryPaymentsUSD = LPool.allPayments_USD();
    }

    function dashboard(bool getLists) public view returns(
        uint256 userCount_,
        uint256 pointValue_,
        uint256 extraPointValue_,
        uint256 lotteryPointValue_,
        uint256 todayPoints_,
        uint256 extraPoints_,
        uint256 todayEnteredUSD_,
        uint256 allEnteredUSD_,
        uint256 lotteryTickets_,
        uint256 rewardPoolBalance_,
        uint256 extraPoolBalance_,
        uint256 lotteryPoolBalance_,
        string[] memory lastLotteryWinners_,
        string[] memory extraRewardReceivers_
    ) {
        uint256 overflowValue = todayPointOverflow * todayEveryPointValue();

        userCount_ = userCount;
        pointValue_ = todayEveryPointValue(); 
        extraPointValue_ = XPool.exPointValue(); 
        lotteryPointValue_ = LPool.lotteryFractionValue(); 
        todayPoints_ = todayTotalPoint;
        extraPoints_ = XPool.extraPointCount();
        todayEnteredUSD_ = todayEnteredUSD;
        allEnteredUSD_ = allEnteredUSD;
        lotteryTickets_ = LPool.lotteryTickets();
        rewardPoolBalance_ = balance() - overflowValue;
        extraPoolBalance_ = XPool.balance() + overflowValue * 25/100;
        lotteryPoolBalance_ = LPool.balance() + overflowValue * 25/100;
        if(getLists) {
            lastLotteryWinners_ = lastLotteryWinners();
            extraRewardReceivers_ = extraRewardReceivers();
        }
    }

    function userDashboard(string calldata username) public view returns(
        uint256 depth,
        uint256 todayPoints,
        uint256 maxPoints,
        uint256 extraPoints,
        uint256 lotteryTickets,
        uint256 todayLeft,
        uint256 todayRight,
        uint256 allTimeLeft,
        uint256 allTimeRight,
        uint256 usersLeft,
        uint256 usersRight,
        uint256 rewardEarned,
        uint256 extraEarned,
        uint256 lotteryEarned
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 points = _todayPoints[dayCounter][userAddr];

        depth = _userData[userAddr].depth;
        todayPoints = _todayPoints[dayCounter][userAddr];
        maxPoints = _userData[userAddr].maxPoints;
        extraPoints = XPool.userExtraPoints(userAddr);
        lotteryTickets = LPool.userTickets(userAddr);
        todayLeft = _userData[userAddr].leftVariance + points;
        todayRight = _userData[userAddr].rightVariance + points;
        allTimeLeft = _userData[userAddr].allLeftDirect;
        allTimeRight = _userData[userAddr].allRightDirect;
        usersLeft = _userData[userAddr].allUsersLeft;
        usersRight = _userData[userAddr].allUsersRight;
        rewardEarned = _userAllEarned_USD[userAddr];
        extraEarned = XPool._userAllEarned_USD(userAddr);
        lotteryEarned = LPool._userAllEarned_USD(userAddr);
    }

    function usernameExists(string calldata username) public view returns(bool) {
        return nameToAddr[username] != address(0);
    }

    function userAddrExists(address userAddr) public view returns(bool) {
        return bytes(addrToName[userAddr]).length != 0;
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint + todayPointOverflow;
        denominator = denominator > 0 ? denominator : 1;
        return address(this).balance / denominator;
    }

    function todayEveryPointValueUSD() public view returns(uint256) {
        return todayEveryPointValue() * MATIC_USD/10**18;
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

    function userTree(string calldata username, uint256 len) public view returns(string[] memory temp) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        address[] memory addrs = new address[](len + 1 + len % 2);
        temp = new string[](len);

        addrs[0] = userAddr;

        uint256 i = 0;
        uint256 j = 1;
        while(j < len) {
            addrs[j] = _userInfo[addrs[i]].leftDirectAddress;
            addrs[j + 1] = _userInfo[addrs[i]].rightDirectAddress;
            i++;
            j += 2;
        }
        for(uint256 a; a < len; a++) {
            temp[a] = addrToName[addrs[a + 1]];
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
        return _todayPoints[dayCounter][userAddr];
    }

    function userMonthPoints(string calldata username) public view returns(uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _monthPoints[monthCounter][userAddr] + XPool.userExtraPoints(userAddr) * 50;
    }

    function extraRewardReceivers() public view returns(string[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function extraRewardReceiversAddr() public view returns(address[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }

    function lastLotteryWinners() public view returns(string[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function lastLotteryWinnersAddr() public view returns(address[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract EnumerableArrays {

    mapping(uint256 => mapping(address => uint256)) _monthPoints;
    mapping(uint256 => mapping(address => uint16)) _todayPoints;
    mapping(uint256 => address[]) _rewardReceivers;

    uint256 rrIndex;
    uint256 monthCounter;
    uint256 dayCounter;
    
    function _resetRewardReceivers() internal {
        rrIndex++;
    }
    function _resetMonthPoints() internal {
        monthCounter ++;
    }
    function _resetDayPoints() internal {
        dayCounter ++;
    }

    function todayRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _rewardReceivers[rrIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _rewardReceivers[rrIndex][i];
        }
    }

    function todayRewardReceiversCount() public view returns(uint256) {
        return _rewardReceivers[rrIndex].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./XDataStorage.sol";

contract ExtraPool is XDataStorage{

    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        uint256 count = extraRewardReceiversCount();
        uint256 _balance = balance();
        if(count > 0) {
            uint256 balanceUSD = _balance * MATIC_USD/10**18;
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned_USD[userAddr] += earning * MATIC_USD/10**18;
                payable(userAddr).transfer(earning);
            }
            allPayments_USD += balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyrePoint {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract XDataStorage {
    
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

    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;
    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        uint256 denom = extraPointCount;
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
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


    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function lotteryWinnersCount() public view returns(uint256) {
        uint256 count = lotteryCandidatesCount();
        return count % 20 == 0 ? count * 5/100 : count * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        uint256 denom = lotteryWinnersCount();
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }


    uint256 utIndex;
    mapping(uint256 => mapping(address => uint256)) _userTickets;

    uint256 public lotteryTickets;

    function userTickets(address userAddr) public view returns(uint256) {
        return _userTickets[utIndex][userAddr];
    }

    function _resetUserTickets() internal {
        utIndex++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";

contract LotteryPool is LDataStorage {
    
    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 _balance = balance();
        uint256 _balanceUSD = _balance * MATIC_USD/10**18;

        uint256 winnersCount = lotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, MATIC_USD
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            _userAllEarned_USD[winner] += lotteryFraction * MATIC_USD/10**18;
            payable(winner).transfer(lotteryFraction);
        }
        if(balance() == 0) {
            allPayments_USD += _balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete lotteryTickets;
        _resetLotteryCandidates();
        _resetUserTickets();
    }

    function addAddr(address userAddr, uint256 numTickets) public payable onlyrePoint {
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
        lotteryTickets += numTickets;
        _userTickets[utIndex][userAddr] += numTickets;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

abstract contract PriceFeed {
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public MATIC_USD;
    uint256 public USD_MATIC;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        _updateMaticePrice();
    }

    function USD_MATIC_Multiplier(uint256 num) public view returns(uint256) {
        return num * USD_MATIC;
    }

    function get_MATIC_USD() private view returns(uint256) {
        return uint256(AGGREGATOR_MATIC_USD.latestAnswer());
    }

    function _updateMaticePrice() internal {
        uint256 MATIC_USD_8 = get_MATIC_USD();
        MATIC_USD = MATIC_USD_8 * 10 ** 10;
        USD_MATIC = 10 ** 26 / MATIC_USD_8;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";
import "./LiteralRegex.sol";

contract rePoint is DataStorage {
    using LiteralRegex for string;

    constructor(
        address _aggregator,
        address[] memory _system,
        uint256[] memory _fractions,
        string[] memory _oldNames,
        address[] memory _oldAddrs
    ) PriceFeed (_aggregator) {
        address repointAddr = address(this);

        LPool = new LotteryPool(repointAddr);
        XPool = new ExtraPool(repointAddr);
        SPool = new SystemPool(_system, _fractions);

        lotteryAddr = payable(address(LPool));        
        extraAddr = payable(address(XPool));
        systemAddr = payable(address(SPool));

        uint256 currentTime = block.timestamp;
        lastReward24h = currentTime;
        lastReward7d = currentTime;
        lastReward30d = currentTime;

        _userData[_oldAddrs[0]].maxPoints = 50;
        _newUsername(_oldAddrs[0], _oldNames[0]);
        uint256 i = 0;
        uint256 j = 1;
        while(j < _oldAddrs.length) {
            _uploadOldUsers(_oldAddrs[i], _oldAddrs[j], _oldNames[j]);
            _uploadOldUsers(_oldAddrs[i], _oldAddrs[j+1], _oldNames[j+1]);
            i++;
            j+=2;
        } 
    }


    function register(string calldata upReferral, string calldata username) public payable {
        uint256 enterPrice = msg.value;
        address userAddr = msg.sender;
        address upAddr = nameToAddr[upReferral];

        checkCanRegister(upReferral, username, upAddr, userAddr);
        (uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD) = checkEnterPrice(enterPrice);

        _payShares(enterPrice, enterPriceUSD);

        _newUsername(userAddr, username);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr);
        _setDirects(userAddr, upAddr, directUp, 1);
    }

    function checkCanRegister(
        string calldata upReferral,
        string calldata username,
        address upAddr,
        address userAddr
    ) internal view returns(bool) {
        require(
            userAddr.code.length == 0,
            "onlyEOAs can register"
        );
        uint256 usernameLen = bytes(username).length;
        require(
            usernameLen >= 4 && usernameLen <= 16,
            "the username must be between 4 and 16 characters" 
        );
        require(
            username.isLiteral(),
            "you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)" 
        );
        require(
            !usernameExists(username),
            "This username is taken!"
        );
        require(
            !userAddrExists(userAddr),
            "This address is already registered!"
        );
        require(
            usernameExists(upReferral),
            "This upReferral does not exist!"
        );
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD
    ) {
        if(enterPrice == USD_MATIC_Multiplier(20)) {
            maxPoints = 10;
            directUp = 1;
            enterPriceUSD = 20 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(60)) {
            maxPoints = 30;
            directUp = 3;
            enterPriceUSD = 60 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(100)) {
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
            enterPriceUSD = 100 * 10 ** 18;
        } else {
            revert("Wrong enter price");
        }
    }

    function _payShares(uint256 enterPrice, uint256 enterPriceUSD) internal {
        todayEnteredUSD += enterPriceUSD;
        allEnteredUSD += enterPriceUSD;
        
        lotteryAddr.transfer(enterPrice * 15/100);
        extraAddr.transfer(enterPrice * 10/100);
        systemAddr.transfer(enterPrice * 5/100);
    }

    function _newUsername(address userAddr, string memory username) internal {
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
            0,
            0,
            _userData[upAddr].depth + 1,
            maxPoints,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
        if(todayPoints == 1) {
            _rewardReceivers[rrIndex].push(userAddr);
            _monthPoints[monthCounter][userAddr] = 1;
            _todayPoints[dayCounter][userAddr] = 1;
            todayTotalPoint ++;
        }
    }

    function _setChilds(address userAddr, address upAddr) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;
    }

    function _setDirects(address userAddr, address upAddr, uint16 directUp, uint16 userUp) internal { 
        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        uint256 depth = _userData[userAddr].depth;
        uint16 _pointsOverflow;
        uint16 _totalPoints;
        uint16 points;
        uint16 v;
        uint16 userTodayPoints;
        uint16 userNeededPoints;
        for (uint256 i; i < depth; i++) {
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance += directUp;
                } else {
                    if(_userData[upAddr].rightVariance < directUp) {
                        v = _userData[upAddr].rightVariance;
                        _userData[upAddr].rightVariance = 0;
                        _userData[upAddr].leftVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].rightVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersLeft += userUp;
                _userData[upAddr].allLeftDirect += directUp;
            } else {
                if(_userData[upAddr].leftVariance == 0){
                    _userData[upAddr].rightVariance += directUp;
                } else {
                    if(_userData[upAddr].leftVariance < directUp) {
                        v = _userData[upAddr].leftVariance;
                        _userData[upAddr].leftVariance = 0;
                        _userData[upAddr].rightVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].leftVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersRight += userUp;
                _userData[upAddr].allRightDirect += directUp;
            }

            if(points > 0) {
                userTodayPoints = _todayPoints[dayCounter][upAddr];
                userNeededPoints = _userData[upAddr].maxPoints - userTodayPoints;
                if(userNeededPoints >= points) {
                    if(userTodayPoints == 0){
                        rewardReceivers.push(upAddr);
                    }
                    _todayPoints[dayCounter][upAddr] += points;
                    _addMonthPoint(upAddr, points);
                    _totalPoints += points;
                } else {
                    _todayPoints[dayCounter][upAddr] += userNeededPoints;
                    _totalPoints += userNeededPoints;
                    _addMonthPoint(upAddr, userNeededPoints);
                    _pointsOverflow += points - userNeededPoints;
                }
                points = 0;
            }
            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }

        todayTotalPoint += _totalPoints;
        todayPointOverflow += _pointsOverflow;
    }


    function topUp() public payable {
        address userAddr = msg.sender;
        uint256 topUpPrice = msg.value;

        address upAddr = _userInfo[userAddr].uplineAddress;
        (uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice, topUpPriceUSD);
        _setDirects(userAddr, upAddr, directUp, 0);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD
    ) {
        require(
            userAddrExists(userAddr),
            "You have not registered!"
        );

        if(topUpPrice == USD_MATIC_Multiplier(40)) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point possible is 50"
            );
            maxPoints = 20;
            directUp = 2;
            topUpPriceUSD = 40 * 10 ** 18;
        } else if(topUpPrice == USD_MATIC_Multiplier(80)) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            maxPoints = 40;
            directUp = 4;
            topUpPriceUSD = 80 * 10 ** 18;
        } else {
            revert("Wrong TopUp price");
        }
    }

    function distribute() public {
        uint256 currentTime = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        require(
            currentTime >= lastReward24h + 24 hours - 5 minutes,
            "The distribute Time Has Not Come"
        );
        lastReward24h = currentTime;
        _reward24h(_MATIC_USD);
        SPool.distribute();
        if(currentTime >= lastReward7d + 7 days - 35 minutes) {
            lastReward7d = currentTime;
            LPool.distribute(_MATIC_USD);
        }
        if(currentTime >= lastReward30d + 30 days - 150 minutes) {
            lastReward30d = currentTime;
            XPool.distribute(_MATIC_USD);
            _resetMonthPoints();
        }
        _updateMaticePrice();

    }

    function _reward24h(uint256 _MATIC_USD) internal {

        uint256 pointValue = todayEveryPointValue();
        uint256 pointValueUSD = pointValue * _MATIC_USD/10**18;

        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        address userAddr;
        uint256 len = rewardReceivers.length;
        uint256 userPoints;
        for(uint256 i; i < len; i++) {
            userAddr = rewardReceivers[i];
            userPoints = _todayPoints[dayCounter][userAddr];
            _userAllEarned_USD[userAddr] += userPoints * pointValueUSD;
            payable(userAddr).transfer(userPoints * pointValue);
        }

        allPayments_MATIC += todayTotalPoint * pointValue;
        allPayments_USD += todayTotalPoint * pointValueUSD;

        uint256 overflowValue = todayPointOverflow * pointValue;
        lotteryAddr.transfer(overflowValue * 25/100);
        extraAddr.transfer(overflowValue * 25/100);
        delete todayTotalPoint;
        delete todayPointOverflow;
        delete todayEnteredUSD;
        _resetRewardReceivers();
        _resetDayPoints();
    }

    function _addMonthPoint(address userAddr, uint256 points) internal {
        uint256 userNeededPoints = 50 - _monthPoints[monthCounter][userAddr];

        if(userNeededPoints >= points) {
            _monthPoints[monthCounter][userAddr] += points;
        } else {
            _monthPoints[monthCounter][userAddr] = points - userNeededPoints;
            XPool.addAddr(userAddr);
        }
    }

    function registerInLottery() public payable {
        address userAddr = msg.sender;
        uint256 paidAmount = msg.value;
        require(
            userAddrExists(userAddr),
            "This address is not registered in rePoint Contract!"
        );
        uint256 ticketPrice = 1 * USD_MATIC;
        require(
            paidAmount >= ticketPrice,
            "minimum lottery enter price is 1 USD in MATIC"
        );
        LPool.addAddr{value : paidAmount}(userAddr, paidAmount / ticketPrice);
    }

    function _uploadOldUsers(
        address upAddr,
        address userAddr,
        string memory username
    ) internal {
        _newNode(userAddr, upAddr, 50, 0);
        _setDirects(userAddr, upAddr, 0, 1);
        _setChilds(userAddr, upAddr);
        _newUsername(userAddr, username);
    }

    function emergencyMainDistribute() public {
        require(
            block.timestamp >= lastReward24h + 3 days,
            "The Emergency Time Has Not Come"
        );
        lastReward24h = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        _reward24h(_MATIC_USD);
        _updateMaticePrice();
    }

    function emergencyLPoolDistribute() public {
        require(
            block.timestamp >= lastReward7d + 10 days,
            "The Emergency Time Has Not Come"
        );
        lastReward7d = block.timestamp;
        LPool.distribute(MATIC_USD);
    }

    function emergencyXPoolDistribute() public {
        require(
            block.timestamp >= lastReward30d + 33 days,
            "The Emergency Time Has Not Come"
        );
        lastReward30d = block.timestamp;
        XPool.distribute(MATIC_USD);
    }

    function panic7d() public {
        require(
            block.timestamp > lastReward24h + 7 days,
            "The panic situation has not happend"
        );
        XPool.panicWithdraw();
        LPool.panicWithdraw();
        systemAddr.transfer(balance());
    }
    
    receive() external payable{}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address[] _members_;
    mapping(address => uint256) _fractions_;

    constructor (address[] memory _members, uint256[] memory _fractions) {
        require(
            _members.length == _fractions.length, 
            "_fractions_ and _members_ length difference"
        );
        uint256 denom;
        for(uint256 i; i < _fractions.length; i++) {
            denom += _fractions[i];
            _fractions_[_members[i]] = _fractions[i];
        }
        require(denom == 1000, "wrong denominator sum");
        _members_ = _members;
    }

    function members() public view returns(address[] memory temp) {
        uint256 len = _members_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _members_[i];
        }
    }

    function fractions() public view returns(uint256[] memory temp) {
        uint256 len = _members_.length;
        temp = new uint256[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _fractions_[_members_[i]];
        }
    }
    
    function distribute() external {
        uint256 membersLen = _members_.length;
        uint256 balance = address(this).balance;
        address member;

        for(uint256 i; i < membersLen; i++) {
            member = _members_[i];
            payable(member).transfer(balance * _fractions_[member]/1000);
        }
    }

    receive() external payable {}
}