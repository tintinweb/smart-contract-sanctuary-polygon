/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

pragma solidity 0.5.6;

interface ImplGetter {
    function _setImplementation(address payable) external;
    function _setExchangeImplementation(address payable) external;
}

contract Governance {
    address public owner;
    address public nextOwner;
    address public implAdmin;
    address public executor;
    address public teamAdmin;

    address public factory;
    address public mesh;
    address public votingMESH;
    address public poolVoting;
    address public treasury;
    address public buyback;
    address public governor;
    address public ecoPotVoting;
    address public singlePoolFactory;

    address payable public implementation; 
    uint public vMESHMiningRate = 0; 
    uint public feeShareRate = 0;

    bool public isInitialized = false;
    bool public entered = false;

    uint public transactionCount = 0;
    mapping (uint => bool) public transactionExecuted;
    mapping (uint => address) public transactionDestination;
    mapping (uint => uint) public transactionValue;
    mapping (uint => bytes) public transactionData;

    uint public interval;
    uint public nextTime;
    uint public prevTime;
    uint public epoch;
    mapping(uint => uint) public epochMined;
    mapping(address => uint) public lastEpoch;
    mapping(uint => mapping(address => uint)) public epochRates;

    uint public singlePoolMiningRate;

    uint public miningShareRate;
    uint public rateNumerator;

    constructor(address payable _implementation, address _owner, address _implAdmin, address _executor) public {
        implementation = _implementation;
        owner = _owner;
        implAdmin = _implAdmin;
        executor = _executor;
    }

    modifier onlyImplAdmin {
        require(msg.sender == owner
                || msg.sender == implAdmin
                || msg.sender == address(this));
        _;
    }

    function _setImplementation(address payable _newImp) public onlyImplAdmin {
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setFactoryImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(factory)._setImplementation(_newImp);
    }

    function _setExchangeImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(factory)._setExchangeImplementation(_newImp);
    }

    function _setVotingMESHImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(votingMESH)._setImplementation(_newImp); 
    }

    function _setPoolVotingImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(poolVoting)._setImplementation(_newImp); 
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

interface IVotingMESH {
    function governance() external view returns (address);
    function _setImplementation(address payable) external;
}

interface IPoolVoting {
    function governance() external view returns (address);
    function _setImplementation(address payable) external;
    function getPoolVotingMining(address, uint, uint) external view returns (uint);
    function update() external;
}

interface IFactory {
    function implementation() external view returns (address);
    function exchangeImplementation() external view returns (address);
    function owner() external view returns (address);
    function nextOwner() external view returns (address);
    function poolExist(address) external view returns (bool);
    function _setImplementation(address payable) external;
    function _setExchangeImplementation(address payable) external;
    function changeOwner() external;
    function getPoolCount() external view returns (uint);
    function getPoolAddress(uint) external view returns (address);
    function changeCreateFee(uint) external;
    function changePoolFee(address, address, uint) external;
}

interface IGovernor {
    function governance() external view returns (address);
    function executed(uint, bool) external;
}

interface IBuybackFund {
    function getBuybackMining(address, uint, uint) external view returns (uint);
    function epochBurn() external;
}

interface IMESH {
    function teamWallet() external view returns (address);
    function changeOwner() external;
    function changeTeamWallet(address) external;
    function sendReward(address, uint) external;
    function mined() external view returns (uint);
}

interface IExchange {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract GovernanceImpl is Governance {

    using SafeMath for uint256;

    event Submission(uint transactionId, address destination, uint value, bytes data);
    event Execution(uint transactionId);
    event ExecutionFailure(uint transactionId);

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event ChangeImplAdmin(address implAdmin);
    event ChangeExecutor(address executor);
    event ChangeKaiAdmin(address kaiAdmin);
    event ChangeVotingMESHMiningRate(uint vMESHMiningRate);
    event ChangeFeeShareRate(uint feeShareRate);
    event ChangeMaxMiningPoolCount(uint maxPoolCount);
    event ChangeSinglePoolMiningRate(uint singlePoolMiningRate);
    event ChangeMiningShareRate(uint miningShareRate);

    event UpdateEpoch(uint epoch, uint mined, uint vMESHMining, uint singlePoolMining, uint miningShare, uint rateNumerator, uint prevTime, uint nextTime);

    constructor() public Governance(address(0), address(0), address(0), address(0)){}

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyExecutor {
        require(msg.sender == owner || msg.sender == executor);
        _;
    }

    modifier onlyWallet {
        require(msg.sender == owner || msg.sender == address(this));
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == governor);
        _;
    }

    function version() public pure returns (string memory) {
        return "GovernanceImpl20220502";
    }
    
    function changeNextOwner(address _nextOwner) public onlyOwner {
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);

        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function changeTeamWallet(address _teamWallet) public {
        require(msg.sender == teamAdmin);
        IMESH meshToken = IMESH(mesh);

        meshToken.changeTeamWallet(_teamWallet);
        require(meshToken.teamWallet() == _teamWallet);
    }

    function setImplAdmin(address _implAdmin) public onlyOwner {
        implAdmin = _implAdmin;

        emit ChangeImplAdmin(implAdmin);
    }

    function setExecutor(address _executor) public onlyOwner {
        require(_executor != address(0));

        executor = _executor;

        emit ChangeExecutor(executor);
    }

    function setTeamAdmin(address _teamAdmin) public onlyOwner {
        require(_teamAdmin != address(0));

        teamAdmin = _teamAdmin;
    }

    function setTimeParams(uint _interval, uint _nextTime) public onlyOwner {
        require(_interval != 0);
        require(_nextTime > now);

        interval = _interval;
        nextTime = _nextTime;
    }

    function setFeeShareRate(uint rate) public onlyWallet {
        require(rate < 100);

        feeShareRate = rate;

        emit ChangeFeeShareRate(feeShareRate);
    }

    function setVotingMESHMiningRate(uint rate) public onlyWallet {
        require(rate <= 10000);

        vMESHMiningRate = rate;
        emit ChangeVotingMESHMiningRate(vMESHMiningRate);
    }

    function setSinglePoolMiningRate(uint rate) public onlyWallet {
        require(rate <= 10000);

        singlePoolMiningRate = rate;
        emit ChangeSinglePoolMiningRate(singlePoolMiningRate);
    }

    function setMiningShareRate(uint rate) public onlyWallet {
        require(rate <= 10000);

        miningShareRate = rate;
        emit ChangeMiningShareRate(miningShareRate);
    }

    function changeMiningRates(uint singlePoolRate, uint pairPoolRate, uint vMESHRate) public {
        require(msg.sender == address(this));
        require(singlePoolRate.add(pairPoolRate).add(vMESHRate) == 10000);

        setVotingMESHMiningRate(vMESHRate);
        setSinglePoolMiningRate(singlePoolRate);
    }

    function setEcoPotVoting(address _ecoPotVoting) public onlyOwner {
        require(_ecoPotVoting != address(0));
        require(IGovernor(_ecoPotVoting).governance() == address(this));

        ecoPotVoting = _ecoPotVoting;
    }

    function changeCreateFee(uint _createFee) public onlyOwner {
        IFactory(factory).changeCreateFee(_createFee);
    }

    function changePoolFee(address pool, uint fee) public onlyOwner {
        require(IFactory(factory).poolExist(pool));
        IFactory(factory).changePoolFee(IExchange(pool).token0(), IExchange(pool).token1(), fee);
    }

    function addTransaction(address destination, uint value, bytes memory data) public onlyGovernor {
        uint tid = transactionCount;
        transactionDestination[tid] = destination;
        transactionValue[tid] = value;
        transactionData[tid] = data;

        transactionCount = tid + 1;

        emit Submission(tid, destination, value, data);
    }

    function executeTransaction(uint tid) public onlyExecutor nonReentrant {
        require(!transactionExecuted[tid]);

        transactionExecuted[tid] = true;

        address dest = transactionDestination[tid];
        uint value = transactionValue[tid];
        bytes memory data = transactionData[tid];

        (bool result, ) = dest.call.value(value)(data);
        if (result)
            emit Execution(tid);
        else {
            emit ExecutionFailure(tid);
        }

        IGovernor(governor).executed(tid, result);
    }

    function sendReward(address user, uint amount) public nonReentrant {
        require(msg.sender == votingMESH || msg.sender == singlePoolFactory);
        IMESH(mesh).sendReward(user, amount);
    }

    function setMiningRate() public {
        require(msg.sender == tx.origin);
        require(vMESHMiningRate != 0);
        require(nextTime < now);

        epoch = epoch + 1;
        epochMined[epoch] = IMESH(mesh).mined();
        epochRates[epoch][address(0)] = vMESHMiningRate;
        epochRates[epoch][address(1)] = singlePoolMiningRate;
        epochRates[epoch][address(2)] = miningShareRate;
        epochRates[epoch][address(3)] = rateNumerator;

        prevTime = nextTime;
        nextTime = nextTime.add(now.sub(prevTime).div(interval).add(1).mul(interval));

        IBuybackFund(buyback).epochBurn();

        emit UpdateEpoch(epoch, epochMined[epoch], epochRates[epoch][address(0)], epochRates[epoch][address(1)], epochRates[epoch][address(2)], epochRates[epoch][address(3)], prevTime, nextTime);
    }

    function acceptEpoch() public {
        require(IFactory(factory).poolExist(msg.sender) || msg.sender == votingMESH || msg.sender == singlePoolFactory);

        address pool = msg.sender;
        if (pool == votingMESH) {
            pool = address(0);
        } else if (pool == singlePoolFactory) {
            pool = address(1);
        }

        lastEpoch[pool] = epoch;
    }

    function getEpochMining(address pool) public view returns (uint curEpoch, uint prevEpoch, uint[] memory rates, uint[] memory mined) {
        require(pool != address(2) && pool != address(3));

        curEpoch = epoch;
        prevEpoch = lastEpoch[pool];

        uint len = curEpoch.sub(prevEpoch);
        mined = new uint[](len);
        rates = new uint[](len);
        for(uint i = 0; i < len; i++){
            mined[i] = epochMined[i + prevEpoch + 1];
            rates[i] = epochRates[i + prevEpoch + 1][pool];
        }
    }

    function getBoostingMining(address pool) public view returns (uint curEpoch, uint prevEpoch, uint[] memory mined, uint[] memory rates, uint[] memory rateNumerators) {
        require(IFactory(factory).poolExist(pool));
        require(pool > address(3));

        curEpoch = epoch;
        prevEpoch = lastEpoch[pool];

        uint len = curEpoch.sub(prevEpoch);
        mined = new uint[](len);
        rates = new uint[](len);
        rateNumerators = new uint[](len + 1);

        uint e = 0;
        for(uint i = 0; i < len; i++){
            e = i + prevEpoch + 1;

            mined[i] = epochMined[e];

            rateNumerators[i] = epochRates[e - 1][address(3)];

            uint epochLP = uint(10000).sub(epochRates[e][address(0)].add(epochRates[e][address(1)]));

            uint epochBuyback = epochLP.mul(epochRates[e][address(2)]).div(10000);
            uint epochPoolVoting = epochLP.sub(epochBuyback);

            uint bRate = IBuybackFund(buyback).getBuybackMining(pool, e, epochBuyback.mul(epochRates[e][address(3)]));
            uint pvRate = IPoolVoting(poolVoting).getPoolVotingMining(pool, e, epochPoolVoting.mul(epochRates[e][address(3)]));

            rates[i] = bRate.add(pvRate);
        }

        rateNumerators[len] = epochRates[curEpoch][address(3)];
    }

    function getCurrentRateNumerator(address pool) public view returns (uint) {
        require(IFactory(factory).poolExist(pool));
        require(pool > address(3));
        require(lastEpoch[pool] == epoch);

        return epochRates[epoch][address(3)];
    }

    function () payable external {
        revert();
    }
}