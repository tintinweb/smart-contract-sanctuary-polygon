pragma solidity ^0.8.5;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RXHSALE {
    AggregatorV3Interface internal priceFeed;
    address owner;
    uint256 price = 10000000000000000; // Price in cents
    mapping(address => mapping(address => uint256)) public allowance;
    struct stakeData {
        address owner;
        uint256 amount;
        uint256 quantity;
        uint256 usdAmount;
        uint256 startDate;
        uint256 endDate;
    }
    mapping(address => stakeData) public stakes;

    event Stake(
        address owner,
        uint256 amount,
        uint256 quantity,
        uint256 usdAmount,
        uint256 startDate,
        uint256 endDate
    );

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        owner = 0xaA89b450b023763f5B30a4326681Da0D13930e2d;
    }
    function setPrice(uint256 _price) public returns(uint){

        require(msg.sender == owner,"Only Owner");
        price = _price;
        return price;
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
        uint256 newPrice = (uint256(currentPrice)  * 10000000000) * dollar;
        return newPrice;
    }

    function buy(
        uint256 amount,
        uint256 quantity,
        uint256 usdAmount
    ) external payable {
        uint256 value = getMatic(usdAmount);
        uint256 rx = getMatic(price);
        require(msg.value >= value, "Invalid Amount"); 
        require(rx * quantity == msg.value, "Invalid Details");
        require(quantity  == (price * usdAmount ) );
        uint256 estimatedDate = block.timestamp + 365 days;
        require(amount == msg.value, "Invalid Data");
        payable(address(owner)).transfer(msg.value);
        stakes[msg.sender] = stakeData(
            msg.sender,
            amount,
            quantity,
            usdAmount,
            block.timestamp,
            estimatedDate
        );
        emit Stake(
            msg.sender,
            amount,
            quantity,
            usdAmount,
            block.timestamp,
            estimatedDate
        );
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