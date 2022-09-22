//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0                                                                                      ;
import "./PricingLibrary.sol" 

//contract deployment gas amount before
/*
gas amount : 979476 gas 
transaction cost : 851718 gas
*/          
//contract deployment gas amount before
/*
gas amount : 957246 gas
transaction cost : 832387 gas
*/                                                  ;
contract FundMe {

    using PriceFeed for uint256                                                                             ;
    address public owner_of_this_contract                                                                          ;
    uint256 public constant  MIN_USD = 50 * 1e18                                                                  ;
    address [] public funders                                                                               ;
    mapping(address => uint256) public  funded_amount                                                       ;
    AggregatorV3Interface public pricefeed;

    constructor(address pricefeed_address) {
        owner_of_this_contract = msg.sender                                                                 ;
        pricefeed = AggregatorV3Interface(pricefeed_address);
    }  

    function fund_deposit () public payable {
        require(msg.value.conversion(pricefeed) >= MIN_USD, "Minimum Ether/Gwei value Provided is incorrect ")     ;
        address funder = msg.sender                                                                          ;
        funders.push(funder)                                                                                 ;
        funded_amount[funder] = msg.value                                                                    ;
    } 

    function fund_withdraw () public onlyOwner {
        for(uint256 funder_POINTER = 0; funder_POINTER < funders.length; funder_POINTER++){
            address funder_address = funders[funder_POINTER]                                                 ;
            funded_amount[funder_address] = 0                                                                ;
        } //0x12bE07624a8F5A9d53AFBf1c0E9052B19293b287
        funders = new address [] (0)                                                                         ;
        (bool transfer_state,) = payable(msg.sender).call{value: address(this).balance}("")                  ;
        require(transfer_state, "UnAuthorized Withdrawer!!!")                                                ;
    }

    modifier onlyOwner {
        require(owner_of_this_contract == msg.sender, "UnAuthorized to withdraw funds!!!")                   ;
        _                                                                                                    ;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0      ;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"                                         ;

library PriceFeed {

     function priceUSD (AggregatorV3Interface chainlink_datafeed) view internal returns(uint256){ 
        (,int256 answer,,,) = chainlink_datafeed.latestRoundData()                                                           ;
        return(uint256(answer * 1e10))                                                                              ;
    }

    function conversion(uint256 ethAmount, AggregatorV3Interface chainlink_datafeed) view internal returns(uint256){
        return(priceUSD(chainlink_datafeed) * ethAmount) / 1e18                                                                       ;
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