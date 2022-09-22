//SPDX-License-Identifier: MIT
/*
pragma
*/
pragma solidity ^0.8.0  ;
/*
Imports: Libraries-Contracts
*/
import "./PricingLibrary.sol"  ;
/*  
ErrorCodes                    
*/
error FundMe_NotOwner()   ;
error FundMe_InsufficientFund() ;


/**@title Medical Ememrgency Funding Contract
 * @author HealthCare Inc
 * @notice Solidity Main Contract Transaction Getway
 * @dev This implements PriceFeed Library
 */                                        
contract FundMe {
    /*
    TypeDeclarations
    */
    using PriceFeed for uint256   ;
    /*
    |StateVariables|
    */
    address public owner_of_this_contract  ;
    uint256 public constant  MIN_USD = 50 * 1e18  ;
    address [] public funders   ;
    mapping(address => uint256) public  funded_amount   ;
    AggregatorV3Interface public pricefeed  ;
    /*
    |Modifiers|
    */
    modifier onlyOwner {
    if(msg.sender != owner_of_this_contract) revert FundMe_NotOwner();
    _ ;
    }  
    //  Functions Order:
    /// constructor
    /// receive
    /// fallback
    /// external
    /// public
    /// internal
    /// private
    /// view /pure
    constructor(address pricefeed_address) {
        owner_of_this_contract = msg.sender                                                                 ;
        pricefeed = AggregatorV3Interface(pricefeed_address);
    }
    /**
     * @notice this is the standard solidity receive legacy function
     * @dev this function will get called when funder funds contract but without passing any calldata 
     */    
    receive() external payable{
        fund_deposit();       
    }
    /**
     * @notice this is the standard solidity fallback legacy function
     * @dev this function will get called when funder funds contract but providing with different calldata that doesnt exist in contract
     */  
    fallback() external payable{
        fund_deposit();
    }
    /**
     * @notice This is the main funding point
     * @dev This implements price feed
    */
    function fund_deposit () public payable {
        if(msg.value.conversion(pricefeed) >= MIN_USD) revert FundMe_InsufficientFund()     ;
        address funder = msg.sender                                                                          ;
        funders.push(funder)                                                                                 ;
        funded_amount[funder] = msg.value                                                                    ;
    } 
    /**
     * @notice this contract is for withdrawing assets from the upholded contract 
     * @dev will check on it further
    */
    function fund_withdraw () public onlyOwner {
        for(uint256 funder_POINTER = 0; funder_POINTER < funders.length; funder_POINTER++){
            address funder_address = funders[funder_POINTER]                                                 ;
            funded_amount[funder_address] = 0                                                                ;
        } //0x12bE07624a8F5A9d53AFBf1c0E9052B19293b287
        funders = new address [] (0)                                                                         ;
        (bool transfer_state,) = payable(msg.sender).call{value: address(this).balance}("")                  ;
        require(transfer_state, "UnAuthorized Withdrawer!!!")                                                ;
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