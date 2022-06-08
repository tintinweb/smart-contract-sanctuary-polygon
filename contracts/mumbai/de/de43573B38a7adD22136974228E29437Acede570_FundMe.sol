// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/**@title Acontract for crowd funding
*  @author Kcpele
*  @notice This is a crowd funds
*  @dev This impliment price feed
 */
contract FundMe {
    //using a library
    using PriceConverter for uint256;

    //immutable for setting it pemanent after declering it once
    address private immutable i_owner;
    //constant for setting direct no more changing
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address => uint256) private s_amountToAccountFunded;

    modifier onlyOwner() {
        if(msg.sender != i_owner) {
            revert FundMe__NotOwner() ;
            }
        _;

    }

    

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    //when someone sends eth to save the eth the sents
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }

    

   function fund() public payable {
       //want to be able to set minimun value in usd
       require(msg.value.getConvertionRate(s_priceFeed) >= MINIMUM_USD, "You need to send more ETH!");
       s_funders.push(msg.sender);
       s_amountToAccountFunded[msg.sender] = msg.value;

   }

   function withdraw() public payable onlyOwner{
        for(uint funderIndex =0; funderIndex < s_funders.length; funderIndex++){
            delete s_amountToAccountFunded[s_funders[funderIndex]];
        }
        //reset the array to be blank
        delete s_funders;
        // funders = new address[](0);
        //or loop throug and set the address to address(0)

        //sending funds
        //transer
        // payable(msg.sender).transfer(address(this).balance);
        // //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        //call
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "call failed");
    }

    
 function cheaperWidthraw() public payable onlyOwner{
     address[] memory funders = s_funders;
     for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
         address funder = funders[funderIndex];
         s_amountToAccountFunded[funder] = 0;
     }
     //this is expensive
    //  s_funders = new address[](0);
    //this is cheaper
    delete s_funders;
     (bool success, ) = payable(i_owner).call{value: address(this).balance}("");
     require(success);

 }

 function getOwner() public view returns(address){
     return i_owner;
 }
 
 function getFunders(uint256 _index) public view returns(address){
     return s_funders[_index];
 }

function getAmountToAccountFunded(address _address) public view returns(uint256){
    return s_amountToAccountFunded[_address];
}
function getPriceFeed() public view returns(AggregatorV3Interface){
    return s_priceFeed;
}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//creating a library 
//they only use internal, no state variable
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
       //address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
       
       (, int256 price,,,) = priceFeed.latestRoundData();
       return uint256(price * 1e10);
       
   }


   function getVersion() internal view returns (uint){
       AggregatorV3Interface version = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
       return version.version();

   }

   function getConvertionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
       uint256 ethPrice = getPrice(priceFeed);
       uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
       return ethAmountInUsd;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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