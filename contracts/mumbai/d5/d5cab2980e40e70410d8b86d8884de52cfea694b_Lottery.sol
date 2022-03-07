pragma solidity ^0.5.0;

import "./OracleInterface.sol";

/**
 * @title Lottery
 * @dev oracle服务请求示例合约，接收用户下注，并从oracle服务中获取抽奖结果
 */
contract Lottery {
    
    uint8 constant MIN_NUMBER = 0; // 下注的最小数字
    uint8 public oneRoundPlayers = 3; // 一轮中包含的下注个数
    uint8 public MAX_NUMBER = oneRoundPlayers * 10; // 下注的最大数字
    uint256 constant MIN_BET = 100 szabo; // 下注时最低的以太币
    uint256 public ORACLE_FEE = 1000 szabo; // 调用oracle服务时的费用
    
    uint256 public roundTimes = 0; // 第几轮
    uint8[] public numbers; // 下注的数字
    
    address public owner; // 合约所有者
    OracleInterface public oracle; // oracle合约
    
    // 第几轮=>中奖者id 一轮中的中奖者
    mapping (uint256 => uint256[]) public roundWinner;
    // 玩家id=>玩家地址 玩家映射表
    mapping (uint256 => address payable) public players;
    // 第几轮=>oracle结果 oracle服务请求结果
    mapping (uint256 => int256) public oracleRequests;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner!");
        _;
    }
    
    modifier onlyOracle() {
        require(msg.sender == address(oracle),"only oracle!");
        _;
    }
    

    event NewRound(uint256 roundTimes);
    event OracleResponse(bytes32 _reqId, uint64 _stateCode, uint256 _randomNum);
    event DistributeFunds(address _winner, uint256 _funds, uint256 _roundTimes, uint256 playId);
    
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * @dev 配置oracle合约地址
     */
    function setOracle(OracleInterface _oracle) public onlyOwner {
        oracle = _oracle;
    }
    
    /**
     * @dev 玩家投注
     */
    function enterNumber(uint8 _number) payable public {
        require(_number <= MAX_NUMBER && _number >= MIN_NUMBER, "invalid number!");
        require(msg.value >= MIN_BET, "min bet is 1 szabo!");
        numbers.push(_number);
        players[numbers.length-1] = msg.sender;
        if (numbers.length == roundTimes*oneRoundPlayers+oneRoundPlayers) {
            roundTimes++;
            oracleRequests[roundTimes] = -3; // 表示可以请求oracle服务来开奖
            emit NewRound(roundTimes);
        }
    }
    
    /**
     * @dev 开奖
     */
    function runRound(uint256 _roundTimes) public onlyOwner {
        require(oracleRequests[_roundTimes] == -3, "oracle random request has send or not ready!");
        bytes memory requestData = bytes("{\"url\":\"https://www.random.org/integers/?num=1&min=0&max=2&col=1&base=10&format=plain&rnd=new\",\"responseParams\":[]}");
        oracle.query.value(ORACLE_FEE)(bytes32(_roundTimes), address(this), "getOracelRandom(bytes32,uint64,uint256)", requestData);
        oracleRequests[_roundTimes] = -2; // 表示已请求oracle服务，等待返回结果
    }
    
    /**
     * @dev oracle服务回调函数
     */   
    function getOracelRandom(bytes32 _reqId, uint64 _stateCode, uint256 _randomNum) external onlyOracle returns(bool) {
        emit OracleResponse(_reqId, _stateCode, _randomNum);
        uint256 _roundTimes = uint256(_reqId);
        require(numbers.length >= _roundTimes*oneRoundPlayers, "invalid reqId!");
        require(oracleRequests[_roundTimes] == -2, "not ready to get oracle random response!");
        if (_stateCode == 1) {
            oracleRequests[_roundTimes] = int256(_randomNum);
            for (uint256 i = (_roundTimes-1)*oneRoundPlayers; i < _roundTimes*oneRoundPlayers; i++) {
                if (numbers[i] == _randomNum) {
                    roundWinner[_roundTimes].push(i);
                }
            }
        } else {
            oracleRequests[_roundTimes] = -1;
        }
    }
}