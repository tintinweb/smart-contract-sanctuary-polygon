/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract PoolVoting {
    uint public constant MAX_VOTING_POOL_COUNT = 10;

    mapping(address => mapping(uint => address)) public userVotingPoolAddress;
    mapping(address => mapping(uint => uint)) public userVotingPoolAmount;
    mapping(address => uint) public userVotingPoolCount;

    mapping(address => uint) public poolAmount;
    mapping(uint => address) public poolRanking;
    uint public poolCount = 0;

    mapping(address => uint) public marketIndex0;
    mapping(address => uint) public marketIndex1;
    mapping(address => mapping(address => uint)) public userLastIndex0;
    mapping(address => mapping(address => uint)) public userLastIndex1;
    mapping(address => mapping(address => uint)) public userRewardSum0;
    mapping(address => mapping(address => uint)) public userRewardSum1;

    address public validPoolOperator;

    uint public totalVotingAmount;
    mapping (uint => mapping (address => uint)) public prevPoolAmount;

    mapping (address => bool) public poolRankingExist;
    mapping (uint => uint) public prevTotalAmount;

    mapping (address => bool) public isValidToken;
    mapping (address => bool) public isBoostingToken;

    uint public boostingPowerMESH_A;
    uint public boostingPowerA_A;
    uint public boostingPowerMESH_B;
    uint public boostingPowerA_B;

    mapping (address => uint) public boostingAmount;
    mapping (uint => mapping (address => uint)) public prevBoostingAmount;
    mapping (address => mapping (uint => mapping (address => bool))) public epochVoted;
    
    bool public entered = false;

    address public governance;
    address payable public implementation;

    constructor(address payable _implementation, address _governance) public {
        implementation = _implementation;
        governance = _governance;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == governance);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IGovernance {
    function votingMESH() external view returns (address);
    function factory() external view returns (address);
    function mesh() external view returns (address);
    function MAX_MINING_POOL_COUNT() external view returns (uint);
    function owner() external view returns (address);
    function epoch() external view returns (uint);
    function lastEpoch(address) external view returns (uint);
    function executor() external view returns (address);
    function isInitialized() external view returns (bool);
    function prevTime() external view returns (uint);
    function governor() external view returns (address);
}

interface IFactory {
    function poolExist(address) external view returns (bool);
    function getPoolCount() external view returns (uint);
    function getPoolAddress(uint) external view returns (address);
}

interface IExchange {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IGovernor {
    function canDelisting(address) external view returns (bool);
    function queueDelisting(address, bool) external;
}

contract PoolVotingImpl is PoolVoting {

    using SafeMath for uint256;

    event AddVoting(address user, address exchange, uint amount);
    event RemoveVoting(address user, address exchange, uint amount);
    event PoolVotingStat(address exchange, uint epoch, uint boostingPower, uint poolAmount);

    event UpdateMarketIndex(address exchange, address token, uint amount, uint lastMined, uint miningIndex);
    event GiveReward(address user, address exchange, address token, uint amount, uint lastIndex, uint rewardSum);

    event SetValidToken(address token, bool valid);
    event SetBoostingToken(address token, bool valid);
    event SetBoostingPower(uint MESH_A, uint A_A, uint MESH_B, uint A_B);

    constructor() public PoolVoting(address(0), address(0)){}

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    function version() public pure returns (string memory) {
        return "PoolVotingImpl20220322";
    }

    function setValidPoolOperator(address _validPoolOperator) public {
        require(msg.sender == IGovernance(governance).owner());

        validPoolOperator = _validPoolOperator;
    }

    function delisting(address token) public {
        IGovernor governor = IGovernor(IGovernance(governance).governor());
        require(isValidToken[token]);
        require(!isBoostingToken[token]);
        require(governor.canDelisting(token));

        isValidToken[token] = false;
        governor.queueDelisting(token, false);

        emit SetValidToken(token, false);
    }

    function setValidToken(address token, bool valid) public {
        require(msg.sender == governance || msg.sender == validPoolOperator);
        require(isValidToken[token] != valid);
        require(!isBoostingToken[token]);

        isValidToken[token] = valid;
        if(valid)
            IGovernor(IGovernance(governance).governor()).queueDelisting(token, true);
        else
            IGovernor(IGovernance(governance).governor()).queueDelisting(token, false);

        emit SetValidToken(token, valid);
    }

    function setBoostingToken(address token, bool valid) public {
        require(msg.sender == governance || msg.sender == validPoolOperator);
        require(isBoostingToken[token] != valid);

        isBoostingToken[token] = valid;
        if(valid) {
            if(isValidToken[token]){
                IGovernor(IGovernance(governance).governor()).queueDelisting(token, false);
            }
            else{
                isValidToken[token] = true;
                emit SetValidToken(token, valid);
            }
        }
        else{
            IGovernor(IGovernance(governance).governor()).queueDelisting(token, true);
        }

        emit SetBoostingToken(token, valid);
    }

    function setBoostingPower(uint _bpMESH_A, uint _bpA_A, uint _bpMESH_B, uint _bpA_B) public {
        require(msg.sender == governance || msg.sender == validPoolOperator);
        require(_bpA_A != 0 && _bpA_A < _bpMESH_A);
        require(_bpMESH_B != 0 && _bpMESH_B < _bpA_A);
        require(_bpA_B != 0 && _bpA_B < _bpMESH_B);

        boostingPowerMESH_A = _bpMESH_A;
        boostingPowerA_A = _bpA_A;
        boostingPowerMESH_B = _bpMESH_B;
        boostingPowerA_B = _bpA_B;

        emit SetBoostingPower(boostingPowerMESH_A, boostingPowerA_A, boostingPowerMESH_B, boostingPowerA_B);
    }

    function getPoolBoosting(address pool) public view returns (uint boostingPower) {
        require(pool > address(2));

        address token0 = IExchange(pool).token0();
        address token1 = IExchange(pool).token1();

        address mesh = IGovernance(governance).mesh();
        if((isBoostingToken[token0] && token1 == mesh) || (token0 == mesh && isBoostingToken[token1])){
            boostingPower = boostingPowerMESH_A;
        }else if(isBoostingToken[token0] && isBoostingToken[token1]){
            boostingPower = boostingPowerA_A;
        }else if((token0 == mesh && isValidToken[token1]) || (isValidToken[token0] && token1 == mesh)){
            boostingPower = boostingPowerMESH_B;
        }else if((isBoostingToken[token0] && isValidToken[token1]) || (isValidToken[token0] && isBoostingToken[token1])){
            boostingPower = boostingPowerA_B;
        }else{
            boostingPower = 0;
        }
    }

    function getPoolVotingMining(address pool, uint epoch, uint rate) public view returns (uint){
        require(pool > address(2));
        require(epoch <= IGovernance(governance).epoch());
        require(epoch > IGovernance(governance).lastEpoch(pool));

        uint poolAmt = prevBoostingAmount[epoch][pool];
        uint totalPoolAmt = prevTotalAmount[epoch];

        return rate.mul(poolAmt).div(totalPoolAmt);
    }

    function writePoolVotingStatList(address[] memory pools) public nonReentrant {
        require(pools.length != 0);

        uint nextEpoch = IGovernance(governance).epoch().add(1);
        for(uint i = 0; i < pools.length; i++){
            address pool = pools[i];
            uint boostingPower = getPoolBoosting(pool);
            writePoolVotingStat(pool, nextEpoch, boostingPower);
        }
    }

    function writePoolVotingStatRange(uint si, uint ei) public nonReentrant {
        require(si < poolCount);
        require(si < ei);
        ei = ei > poolCount ? poolCount : ei;

        uint nextEpoch = IGovernance(governance).epoch().add(1);
        for(uint i=si; i<ei; i++){
            address pool = poolRanking[i];
            uint boostingPower = getPoolBoosting(pool);
            writePoolVotingStat(pool, nextEpoch, boostingPower);
        }
    }

    function writePoolVotingStat(address pool, uint nextEpoch, uint boostingPower) private {
        uint poolAmt = poolAmount[pool];
        prevPoolAmount[nextEpoch][pool] = poolAmt;

        totalVotingAmount = totalVotingAmount.sub(boostingAmount[pool]);

        uint boostingAmt = poolAmt.mul(boostingPower);
        totalVotingAmount = totalVotingAmount.add(boostingAmt);
        boostingAmount[pool] = boostingAmt;
        prevBoostingAmount[nextEpoch][pool] = boostingAmt;

        prevTotalAmount[nextEpoch] = totalVotingAmount;

        emit PoolVotingStat(pool, nextEpoch, boostingPower, poolAmt);
    }

    function addVoting(address exchange, uint amount) public nonReentrant {
        require(IFactory(IGovernance(governance).factory()).poolExist(exchange));
        require(amount != 0);

        uint boostingPower = getPoolBoosting(exchange);
        require(boostingPower != 0);

        _giveReward(msg.sender, exchange);
        epochVoted[msg.sender][IGovernance(governance).epoch()][exchange] = true;

        amount = amount.mul(10 ** 18);

        bool isVotedPool = false;
        uint votedAmount = 0;
        uint exchangeIndex;

        for(uint i=0; i<userVotingPoolCount[msg.sender]; i++){
            if(userVotingPoolAddress[msg.sender][i] == exchange){
                isVotedPool = true;
                exchangeIndex = i;
            }
            votedAmount = votedAmount.add(userVotingPoolAmount[msg.sender][i]);
        }
        require(IERC20(IGovernance(governance).votingMESH()).balanceOf(msg.sender) >= votedAmount.add(amount));

        if(isVotedPool){
            userVotingPoolAmount[msg.sender][exchangeIndex] = userVotingPoolAmount[msg.sender][exchangeIndex].add(amount);
        }else{
            require(userVotingPoolCount[msg.sender] < MAX_VOTING_POOL_COUNT);
            exchangeIndex = userVotingPoolCount[msg.sender];
            userVotingPoolAddress[msg.sender][exchangeIndex] = exchange;
            userVotingPoolAmount[msg.sender][exchangeIndex] = amount;
            userVotingPoolCount[msg.sender] = exchangeIndex.add(1);
        }

        poolAmount[exchange] = poolAmount[exchange].add(amount);

        if(!poolRankingExist[exchange]){
            poolRankingExist[exchange] = true;
            poolRanking[poolCount] = exchange;
            poolCount = poolCount.add(1);
        }

        writePoolVotingStat(exchange, IGovernance(governance).epoch().add(1), boostingPower);

        emit AddVoting(msg.sender, exchange, amount);
    }

    function removeVoting(address exchange, uint amount) public nonReentrant {
        require(IFactory(IGovernance(governance).factory()).poolExist(exchange));
        require(amount != 0);

        uint boostingPower = getPoolBoosting(exchange);
        if(boostingPower != 0)
            require(!epochVoted[msg.sender][IGovernance(governance).epoch()][exchange]);

        _giveReward(msg.sender, exchange);

        amount = amount.mul(10 ** 18);

        bool isVotedPool = false;
        uint exchangeIndex;

        for(uint i=0; i<userVotingPoolCount[msg.sender]; i++){
            if(userVotingPoolAddress[msg.sender][i] == exchange){
                isVotedPool = true;
                exchangeIndex = i;
            }
        }
        require(isVotedPool);

        if (amount >= userVotingPoolAmount[msg.sender][exchangeIndex])
            amount = userVotingPoolAmount[msg.sender][exchangeIndex];

        userVotingPoolAmount[msg.sender][exchangeIndex] = userVotingPoolAmount[msg.sender][exchangeIndex].sub(amount);

        if(userVotingPoolAmount[msg.sender][exchangeIndex] == 0){
            uint lastIndex = userVotingPoolCount[msg.sender].sub(1);
            userVotingPoolAddress[msg.sender][exchangeIndex] = userVotingPoolAddress[msg.sender][lastIndex];
            userVotingPoolAddress[msg.sender][lastIndex] = address(0);

            userVotingPoolAmount[msg.sender][exchangeIndex] = userVotingPoolAmount[msg.sender][lastIndex];
            userVotingPoolAmount[msg.sender][lastIndex] = 0;

            userVotingPoolCount[msg.sender] = lastIndex;
        }

        poolAmount[exchange] = poolAmount[exchange].sub(amount);

        writePoolVotingStat(exchange, IGovernance(governance).epoch().add(1), boostingPower);

        emit RemoveVoting(msg.sender, exchange, amount);
    }

    function removeAllVoting() public nonReentrant {
        _removeAllVoting(msg.sender, false);
    }

    function removeAllVoting(address user, bool force) public nonReentrant {
        require(msg.sender == IGovernance(governance).votingMESH());
        require(user != address(0));

        _removeAllVoting(user, force);
    }

    function _removeAllVoting(address user, bool force) internal{
        uint epoch = IGovernance(governance).epoch();

        uint i;
        for(i=0; i<userVotingPoolCount[user]; i++){
            address exchange = userVotingPoolAddress[user][i];
            if(!force){
                require(!epochVoted[user][epoch][exchange]);
            }

            _giveReward(user, exchange);

            uint amount = userVotingPoolAmount[user][i];

            userVotingPoolAddress[user][i] = address(0);
            userVotingPoolAmount[user][i] = 0;

            poolAmount[exchange] = poolAmount[exchange].sub(amount);
            writePoolVotingStat(exchange, IGovernance(governance).epoch().add(1), getPoolBoosting(exchange));

            emit RemoveVoting(user, exchange, amount);
        }

        userVotingPoolCount[user] = 0;
    }

    function marketUpdate0(uint amount) public nonReentrant {
        address factory = IGovernance(governance).factory();
        address exchange = msg.sender;

        require(IFactory(factory).poolExist(exchange));

        uint lastMined = marketIndex0[exchange];
        address token = IExchange(exchange).token0();

        if(amount != 0 && poolAmount[exchange] != 0){
            marketIndex0[exchange] = marketIndex0[exchange].add(amount.mul(10 ** 18).div(poolAmount[exchange]));
        }

        emit UpdateMarketIndex(exchange, token, amount, lastMined, marketIndex0[exchange]);
    }

    function marketUpdate1(uint amount) public nonReentrant {
        address factory = IGovernance(governance).factory();
        address exchange = msg.sender;

        require(IFactory(factory).poolExist(exchange));

        uint lastMined = marketIndex1[exchange];
        address token = IExchange(exchange).token1();

        if(amount != 0 && poolAmount[exchange] != 0){
            marketIndex1[exchange] = marketIndex1[exchange].add(amount.mul(10 ** 18).div(poolAmount[exchange]));
        }

        emit UpdateMarketIndex(exchange, token, amount, lastMined, marketIndex1[exchange]);
    }

    function _giveReward(address user, address exchange) internal {
        bool poolExist;
        uint poolIndex;
        uint i;

        for(i=0; i<userVotingPoolCount[user]; i++){
            if(userVotingPoolAddress[user][i] == exchange){
                poolExist = true;
                poolIndex = i;
                break;
            }
        }

        if(!poolExist){
            userLastIndex0[exchange][user] = marketIndex0[exchange];
            userLastIndex1[exchange][user] = marketIndex1[exchange];
            return;
        }

        uint have = userVotingPoolAmount[user][poolIndex];

        if(marketIndex0[exchange] > userLastIndex0[exchange][user]){
            uint lastIndex0 = userLastIndex0[exchange][user];
            uint currentIndex0 = marketIndex0[exchange];
            userLastIndex0[exchange][user] = currentIndex0;

            if(have != 0){
                address token = IExchange(exchange).token0();
                uint amount = have.mul(currentIndex0.sub(lastIndex0)).div(10 ** 18);

                require(IERC20(token).transfer(user, amount));

                uint rewardSum = 0;
                {
                    rewardSum = userRewardSum0[exchange][user].add(amount);
                    userRewardSum0[exchange][user] = rewardSum;
                }

                emit GiveReward(user, exchange, token, amount, currentIndex0, rewardSum);
            }
        }
        if(marketIndex1[exchange] > userLastIndex1[exchange][user]){
            uint lastIndex1 = userLastIndex1[exchange][user];
            uint currentIndex1 = marketIndex1[exchange];
            userLastIndex1[exchange][user] = currentIndex1;

            if(have != 0){
                address token = IExchange(exchange).token1();
                uint amount = have.mul(currentIndex1.sub(lastIndex1)).div(10 ** 18);

                require(IERC20(token).transfer(user, amount));

                uint rewardSum = 0;
                {
                    rewardSum = userRewardSum1[exchange][user].add(amount);
                    userRewardSum1[exchange][user] = rewardSum;
                }

                emit GiveReward(user, exchange, token, amount, currentIndex1, rewardSum);
            }
        }
    }

    function claimReward(address exchange) public nonReentrant {
        _giveReward(msg.sender, exchange);
    }

    function claimRewardAll() public nonReentrant {
        _giveRewardAll(msg.sender);
    }

    function _giveRewardAll(address user) internal {
        uint i;
        for(i=0; i<userVotingPoolCount[user]; i++){
            _giveReward(user, userVotingPoolAddress[user][i]);
        }
    }

    function () payable external {
        revert();
    }
}