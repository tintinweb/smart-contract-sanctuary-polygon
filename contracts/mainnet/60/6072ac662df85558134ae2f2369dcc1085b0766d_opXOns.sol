/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract CryptoValueCalculator {
    AggregatorV3Interface internal priceUSDTUSDFeed;
    AggregatorV3Interface internal priceEURUSDFeed;


    constructor() {
        priceUSDTUSDFeed = AggregatorV3Interface(address(0x0A6513e40db6EB1b165753AD52E80663aeA50545));
        priceEURUSDFeed = AggregatorV3Interface(address(0x73366Fe0AA0Ded304479862808e02506FE556a98));

    }

    function getTotalValue() public view returns (uint256) {
        (, int256 usdtusdPrice, , ,) = priceUSDTUSDFeed.latestRoundData();
        (, int256 eurusdPrice, , ,) = priceEURUSDFeed.latestRoundData();

        uint256 usdtusdActualPrice = uint256(usdtusdPrice) * 10**10;
        uint256 eurusdActualPrice = uint256(eurusdPrice) * 10**10;

        uint256 sum = usdtusdActualPrice + eurusdActualPrice;
        uint256 PercentOfSum = sum; 

    return PercentOfSum / 10e6;
}
    function getTokensUsed() public pure returns (string[] memory) {
    string[] memory tokensUsed = new string[](2);
    tokensUsed[0] = "USDTUSD";
    tokensUsed[1] = "EURUSD";

    return tokensUsed;
}
}

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract opXOns is CryptoValueCalculator {
    string public constant name = "opXOns";
    string public constant symbol = "TOK5";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10000000 * 10**uint256(decimals);
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    address public constant USDT_ADDRESS = 0x79567e5Cc47ce5e53110eDb7e851123282670Cc8; // insert the USDT token address here
    address public constant EUR_ADDRESS = 0x92a44F53e15bcC1Db1534E380c2B2700c1c90035; // insert the EUR token address here

    uint256 public constant DEPOSIT_RATE = 10**18; // deposit rate is 1 per token, which is equal to 10**18 in wei
    
    mapping(address => uint256) public usdtDeposits;
    mapping(address => uint256) public eurDeposits;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    address payable public feeReceiver = payable(0x432Ab1D67b473B1B14e173EA13E238E4522B2400);
    uint256 public burnFee = 35e12; // Set the burn fee per token burned to 0.000035 BNB
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[msg.sender], "ERC20: insufficient balance");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[_from], "ERC20: insufficient balance");
        require(_value <= allowed[_from][msg.sender], "ERC20: insufficient allowance");
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

function burn(uint256 _value) public payable {
    uint256 tokensToBurn = _value / (10**18);
    uint256 totalFee = burnFee * tokensToBurn;
    
    require(msg.value == totalFee, "tok5Token: incorrect burn fee provided");
    feeReceiver.transfer(msg.value);

    require(_value > 0, "tok5Token: value must be greater than zero");
    require(_value <= balances[msg.sender], "tok5Token: insufficient balance");

    uint256 usdtAmount = ERC20(USDT_ADDRESS).balanceOf(address(this)) * _value / totalSupply;
    uint256 eurAmount = ERC20(EUR_ADDRESS).balanceOf(address(this)) * _value / totalSupply;


    balances[msg.sender] -= _value;
    totalSupply -= _value;

    require(ERC20(USDT_ADDRESS).transfer(msg.sender, usdtAmount), "tok5Token: failed to transfer USDT");
    require(ERC20(EUR_ADDRESS).transfer(msg.sender, eurAmount), "tok5Token: failed to transfer EUR");


    emit Transfer(msg.sender, address(0), _value);
}

}