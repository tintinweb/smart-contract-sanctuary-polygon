/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/Price Feeds Level/Manager.sol


pragma solidity 0.8.9;


interface IAddWinner {
    function addWinner(address, address) external;
    function owner() external view returns (address);
}

contract PriceFeedManager {
    AggregatorV3Interface internal priceFeed;
    address public NFTContract;
    mapping (address => uint256) public answerValue;

    /**
     * Network: Polygon Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */

    //TASK: Send 0.01 USD worth of MATIC to the manager contract.
    constructor(address _nftContract) {
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        NFTContract = _nftContract;
    }

    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8 decimals) {
        decimals = priceFeed.decimals();
    }

    function getValidatedValue() public view returns (uint256){
        uint256 price = uint256(getLatestPrice());
        uint256 value = ((10**18 * 1*10**(getDecimals()-2)) / (price));
        return value;
    }

    function receiveAnswer() external payable {
        require(msg.value == getValidatedValue());

        //Validate if the msg.sender (solution contract) is
        //owned by the address that initiates the tx (tx.origin)
        require(tx.origin == IAddWinner(msg.sender).owner()); 
        answerValue[tx.origin] = msg.value;
        IAddWinner(NFTContract).addWinner(tx.origin, msg.sender);
    }

    function withdrawAnswer() external {
        require(answerValue[msg.sender] > 0, "No locked answer");

        address payable _to = payable(msg.sender);
        uint256 lockedValue = answerValue[msg.sender];
        
        answerValue[msg.sender] = 0;
        (bool result, )= _to.call{value: lockedValue}("");
        require(result, "Transfer failed");
    }
}