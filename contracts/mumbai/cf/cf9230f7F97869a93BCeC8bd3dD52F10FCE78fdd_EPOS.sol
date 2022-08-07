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
        // priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

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

contract EPOS is Ownable {
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    event Distribution(
        address receiver,
        address refferedBy,
        uint256 levelIncome,
        uint256 incomeReceived
    );
    event Registeration(
        address userAddress,
        address referredBy,
        uint256 amountPaid,
        uint256 joingDate
    );
    struct userData {
        uint256 id;
        address userAddress;
        address referredBy;
        uint256 amountPaid;
        uint256 joingDate;
        bool activeAllLevel;
        bool isExist;
    }
    uint256 public _currentId = 1;
    mapping(address => userData) public users;
    address firstId;
    uint256 _minInvestment = 10;
    uint256 _amountForAccessAllLevel = 100;
    uint256[] levelDistribution = [3, 2, 1, 1];

    uint256 price = 10;

    constructor(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS
    ) {
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 200000 * decimalfactor;

        users[msg.sender] = userData(
            _currentId,
            msg.sender,
            address(0),
            100,
            block.timestamp,
            true,
            true
        );
        firstId = msg.sender;
        _currentId++;

        // mint(MINT_ADDRESS, 1000000 * decimalfactor);
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

    function mint(address _to, uint256 _value) internal returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        // uint256 reBnb = getBNB(_value);
        // require(reBnb >= msg.value, "Invalid Amount sent");
        require(msg.sender == owner, "Only Owner Can Mint");
        // require(BNB * value == msg.value);
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        // require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        balanceOf[owner] += (_value / 15);
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function _mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value), "Max Supply reached");
        require(mintAllowed, "Max supply reached");
        // uint256 reBnb = getBNB(_value);
        // require(reBnb >= msg.value, "Invalid Amount sent");

        // require(BNB * value == msg.value);
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        // require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        balanceOf[owner] += (_value / 15);
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
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

    function register(address referredBy) external payable {
        require(checkUserExists(referredBy) == true, "Invalid refer address");
        require(msg.sender != address(0));
        require(msg.value >= _minInvestment, "Can't be less than Min Amount");
        bool _activeAllLevel = false;
        if (msg.value >= _amountForAccessAllLevel) {
            _activeAllLevel = true;
        }

        //Now we will distribute income

        payable(referredBy).transfer((msg.value * 5) / 100);
        address uplineUserAddress = getUplineAddress(referredBy);
        uint256 currentLevelDistribute = 0;

        for (uint256 i = 0; i <= _currentId; i++) {
            if (uplineUserAddress == firstId) {
                break;
            } else {
                if (currentLevelDistribute < 4) {
                    if (users[uplineUserAddress].activeAllLevel == true) {
                        payable(uplineUserAddress).transfer(
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );
                        emit Distribution(
                            uplineUserAddress,
                            referredBy,
                            currentLevelDistribute,
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );
                        uplineUserAddress = getUplineAddress(uplineUserAddress);
                        currentLevelDistribute++;
                    } else {
                        uplineUserAddress = getUplineAddress(uplineUserAddress);
                    }
                } else {
                    break;
                }
            }
        }
        _mint(msg.sender, (msg.value * 100000000) / price);
        users[msg.sender] = userData(
            _currentId,
            msg.sender,
            referredBy,
            msg.value,
            block.timestamp,
            _activeAllLevel,
            true
        );
        _currentId++;
        emit Registeration(msg.sender, referredBy, msg.value, block.timestamp);
    }

    function getUplineAddress(address _userAddress)
        internal
        view
        returns (address)
    {
        return users[_userAddress].referredBy;
    }

    function checkUserExists(address _userAddress) internal returns (bool) {
        return users[_userAddress].isExist;
    }
    // function getLatestPrice() public view returns (int256) {
    //     (
    //         ,
    //         /*uint80 roundID*/
    //         int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
    //         ,
    //         ,

    //     ) = priceFeed.latestRoundData();
    //     return price;
    // }

    // function getBNB(uint256 dollar) public view returns (uint256) {
    //     int256 currentPrice = getLatestPrice();
    //     uint256 newPrice = uint256(currentPrice) / dollar;
    //     return newPrice;
    // }
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