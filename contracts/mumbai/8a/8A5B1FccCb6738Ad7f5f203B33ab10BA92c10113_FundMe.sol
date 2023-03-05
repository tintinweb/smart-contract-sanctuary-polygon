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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//Error Codes
error FundMe__NotOwner();
error CallFailed();
error DidNotSendEnough();

//Interfaces, Libaries, Contracts

/**
 * @title A contract for crwod funding
 * @author Me haha
 * @notice This contract is to demo a smaple funding contract
 * @dev This implements price feeds as out library 
 */
contract FundMe {
    //Type declarations
    using PriceConverter for uint256;   
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //Sate variables!
    mapping(address => uint256) public addressToAmountFunded;
    //Could we make this constant?
    address public immutable i_owner;
    address [] public funders;
    
    AggregatorV3Interface public priceFeed;
    
    //Modifiers
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not the owner");
        if(msg.sender != i_owner) {revert FundMe__NotOwner(); }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    
    /**
    * @notice This contract is to demo a smaple funding contract
    * @dev This implements price feeds as out library
    */ 
    function fund() public payable {
        //require(msg.value.getConversionRate() >= MINIMUM_USD, "Did not send enough");
        if(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD) {revert DidNotSendEnough(); }
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    /**
    * @notice This contract is to demo a smaple funding contract
    * @dev This implements price feeds as out library
    */ 
    function withdraw() public onlyOwner {

        //* starting index, ending index, step amount */
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex ++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        
        funders = new address[](0);
        

        (bool callSucces, ) = payable(msg.sender).call{value: address(this).balance}("");
        //require(callSucces, "Call failed");
        if(callSucces) {revert CallFailed(); }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

       function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256 (price * 1e10);
    }
   
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    } 

}