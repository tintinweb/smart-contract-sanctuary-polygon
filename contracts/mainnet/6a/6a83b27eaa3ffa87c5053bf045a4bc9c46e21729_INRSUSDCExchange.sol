/**
 *Submitted for verification at polygonscan.com on 2023-01-12
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

// File: contracts/INRSUSDCExchange.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/**
*   For StableR INRS Stablecoin 
*
*   Know more about the project at StableR.in/links
*
*   This contract will make the StableR INRS as Stablecoin by pegging the value to Indian Rupee
*
*   It makes 1 INRS = 1 INR always.
*
*   This contract will  get the value of Indian Rupee via Chainlink oracle

*
*   Using this contract, Users can exchange USDC to StableR INRS and vice versa.
*   
*   Users can simply send the USDC or INRS to this contract and receive the INRS or USDC respectively
*
*/

// StableR INRS - USDC Exchange contract


contract INRSUSDCExchange {
    AggregatorV3Interface internal INRUSD;
    AggregatorV3Interface internal USDCUSD;
    address internal StableRINRS;
    address internal USDC;
    address internal owner;
    address payable USDCPayable;
    address payable StableRPayable;
    mapping (address => uint256) internal refundBalances;
    event ExchangeSuccess(uint256 inValue, uint256 outValue);
    event ExchangeFailure(uint256 inValue, uint256 outValue);

    // Timestamp of last price feed update
    uint256 public lastUpdateTimestamp;

    // Threshold for how long the price feeds can go without being updated
    uint256 public updateThreshold = 10 minutes;

    mapping(address => uint256) balanceOfINRS;
    mapping(address => uint256) balanceOfUSDC;
    mapping (address => uint256) balanceOfMATIC;


    constructor() {
        INRUSD = AggregatorV3Interface(0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60);
        USDCUSD = AggregatorV3Interface(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);
        StableRINRS = address(0xadA9C4D142B5e8A1e269B9546906804Cb934BD0D);
        USDC = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
       
        USDCPayable = payable (0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        StableRPayable = payable(0xadA9C4D142B5e8A1e269B9546906804Cb934BD0D);

        
    }
    
    function depositINRS() public payable {
    require(msg.sender == StableRINRS, "Invalid Token Address : Only INRS Token is allowed");
    require(msg.value > 0, "Deposit value must be greater than 0");

    // Add the deposit value to the contract's INRS balance
    balanceOfINRS[address(this)] += msg.value;
}

    function depositUSDC() public payable {
    require(msg.sender == USDC, "Invalid Token Address : Only USDC Token is allowed");
    require(msg.value > 0, "Deposit value must be greater than 0");

    // Add the deposit value to the contract's USDC balance
    balanceOfUSDC[address(this)] += msg.value;
}

function depositMATIC() public payable {
    require(msg.sender == owner, "Only the contract owner can deposit MATIC");
    require(msg.value > 0, "Deposit value must be greater than 0");

    // Add the deposit value to the contract's MATIC balance
    balanceOfMATIC[address(this)] += msg.value;
}

function withdrawMATIC(uint256 _value) public {
    require(msg.sender == owner, "Only the contract owner can withdraw MATIC");
    require(_value <= balanceOfMATIC[address(this)], "Insufficient MATIC balance in contract");
    // transfer the requested amount of ether to the caller
   payable (msg.sender).transfer(_value);
   
    // update the contract's MATIC balance
    balanceOfMATIC[address(this)] -= _value;
}

    
    function withdrawINRS(uint256 _value) public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");
                payable(StableRINRS).transfer(_value);
    }

    function withdrawUSDC(uint256 _value) public {
                require(msg.sender == owner, "Only the contract owner can withdraw funds");
              payable(USDC).transfer(_value);
    }

    function getINRUSDCPrice() public view returns (int) {
        (, int INRUSDPrice, , , )  = INRUSD.latestRoundData();
        (,int USDCUSDPrice, , ,) = USDCUSD.latestRoundData();
        return INRUSDPrice / USDCUSDPrice;
    }

function exchangeINRSforUSDC(uint256 _value) public payable {
    require(block.timestamp - lastUpdateTimestamp <= updateThreshold, "Price feeds have not been updated for more than minutes. Please try again later.");
    require(msg.sender == StableRINRS, "Invalid Token Address : Only INRS Token is allowed");
    require(msg.value > 0, "Deposit value must be greater than 0");
    require(_value <= refundBalances[msg.sender], "Insufficient deposit balance for exchange");

     // Perform the exchange
    uint256 USDCAmount = uint256(int(_value) * getINRUSDCPrice()); 
    payable(USDC).transfer(USDCAmount);

}
    
    function exchangeUSDCforINRS(uint256 _value) public payable {
    require(block.timestamp - lastUpdateTimestamp <= updateThreshold, "Price feeds have not been updated for more than minutes. Please try again later.");
    require(msg.sender == USDC, "Invalid Token Address : Only USDC Token is allowed");
    require(msg.value > 0, "Deposit value must be greater than 0");
    require(_value <= refundBalances[msg.sender], "Insufficient deposit balance for exchange");

    // Perform the exchange
    uint256 INRSAmount = uint256(int(_value) / getINRUSDCPrice());
    payable(StableRINRS).transfer(INRSAmount);
    }

fallback() external payable {
    if (msg.value > 0) {
        // If the msg.value is greater than 0, we check if the msg.sender is the INRS or USDC token contract
        if (msg.sender == address(StableRINRS)) {
            depositINRS();
        // Perform the exchange
        uint256 USDCAmount = uint256(int(msg.value) * getINRUSDCPrice());
        // Send the USDC to the sender
        payable(USDC).transfer(USDCAmount);
        } else if (msg.sender == address(USDC)) {
            depositUSDC();
            // Perform the exchange
        uint256 INRSAmount = uint256(int(msg.value) / getINRUSDCPrice());
        // Send the INRS to the sender
        payable(StableRINRS).transfer(INRSAmount);
        } else {
            // If the msg.sender is not the INRS or USDC token contract, we revert the transaction
            revert("Invalid Token Address: Only INRS or USDC Tokens are allowed");
        }
    } else {
        revert("Deposit value must be greater than 0");
    }
}
receive() external payable {
    if (msg.value > 0) {
        // If the msg.value is greater than 0, we check if the msg.sender is the INRS or USDC token contract
        if (msg.sender == address(StableRINRS)) {
            depositINRS();
        // Perform the exchange
        uint256 USDCAmount = uint256(int(msg.value) * getINRUSDCPrice());
        // Send the USDC to the sender
        payable(USDC).transfer(USDCAmount);
        } else if (msg.sender == address(USDC)) {
            depositUSDC();
            // Perform the exchange
        uint256 INRSAmount = uint256(int(msg.value) / getINRUSDCPrice());
        // Send the INRS to the sender
        payable(StableRINRS).transfer(INRSAmount);
        } else {
            // If the msg.sender is not the INRS or USDC token contract, we revert the transaction
            revert("Invalid Token Address: Only INRS or USDC Tokens are allowed");
        }
    } else {
        revert("Deposit value must be greater than 0");
    }
}
function updatePriceFeeds(address _INRUSD, address _USDCUSD) public {
    require(msg.sender == owner, "Only the owner can update price feeds");
    INRUSD = AggregatorV3Interface(_INRUSD);
    USDCUSD = AggregatorV3Interface(_USDCUSD);
}
mapping(address => bool) internal whitelisted;

function addWhitelist(address _address) public{
    require(msg.sender == owner, "Only the current owner can add address to whitelist");
    whitelisted[_address] = true;
}

function changeOwner(address newOwner) public {
    require(whitelisted[newOwner], "Address not whitelisted");
    require(msg.sender == owner, "Only the current owner can change the contract owner");
    owner = newOwner;
}

}