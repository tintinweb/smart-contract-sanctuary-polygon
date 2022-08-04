pragma solidity ^0.8.5;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Ownable {
    address public owner;
    AggregatorV3Interface internal priceFeed;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract RXHEAL is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    mapping(address => bool) public blackListMap;
    uint256 public MaxFee; // in 10**8
    bool mintAllowed = true;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    struct stakeData {
        uint256 amount;
        uint256 quantity;
    }
    mapping(address => stakeData) public stakes;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Stake(address indexed from, address indexed to, uint256 value);

    constructor(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS,
        address MINT_ADDRESS
    ) {
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 10000000000 * decimalfactor;
        mint(MINT_ADDRESS, 10000000000 * decimalfactor);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(
            !blackListMap[_from],
            "Your address is blocked from transferring tokens."
        );
        require(
            !blackListMap[_to],
            "Your address is blocked from transferring tokens."
        );
        require(_to != address(0));
        uint256 adminCommission = (MaxFee * _value) / 10**10;
        uint256 amountSend = _value - adminCommission;
        balanceOf[_from] -= _value;
        balanceOf[_to] += amountSend;
        if (adminCommission > 0) {
            balanceOf[owner] += (adminCommission);
            emit Transfer(_from, owner, adminCommission);
        }

        emit Transfer(_from, _to, amountSend);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Only Owner Can Burn");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        Max_Token -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function buy(
        address _to,
        uint256 _value,
        uint256 _quant
    ) external payable returns (bool success) {
        uint256 reBnb = getMatic(_value);
        require(reBnb <= msg.value, "Invalid Amount sent");
        stakes[_to] = stakeData(_value, _quant);
        payable(address(owner)).transfer(msg.value);
        // require(balanceOf[_to] >= _value);
        emit Stake(address(0), _to, _value);
        return true;
    }

    function addBlacklist(address _blackListAddress) external onlyOwner {
        blackListMap[_blackListAddress] = true;
    }

    function removeBlacklist(address _blackListAddress) external onlyOwner {
        blackListMap[_blackListAddress] = false;
    }

    function updateMaxFee(uint256 _MaxFee) external onlyOwner {
        MaxFee = _MaxFee;
    }

    function destroyBlackFunds(address _blackListAddress) public onlyOwner {
        require(blackListMap[_blackListAddress]);
        Max_Token -= balanceOf[_blackListAddress];
        totalSupply -= balanceOf[_blackListAddress];
        balanceOf[_blackListAddress] = 0;
        emit Burn(_blackListAddress, balanceOf[_blackListAddress]);
    }

    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function getMatic(uint256 dollar) public view returns (uint256) {
        int256 currentPrice = getLatestPrice();
        uint256 newPrice = uint256(currentPrice) / dollar;
        return newPrice;
    }
}

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