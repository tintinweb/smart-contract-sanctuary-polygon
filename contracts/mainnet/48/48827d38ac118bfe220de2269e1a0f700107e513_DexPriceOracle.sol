/**
 *Submitted for verification at polygonscan.com on 2023-03-10
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

// File: Oracle1.sol

pragma solidity ^0.8.0;


// Declare the interface for the ERC20 token contract
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract DexPriceOracle {
    // Declare the address of the ERC20 token contract
    address public tokenAddress;

    // Declare the price aggregator interface for Chainlink
    AggregatorV3Interface internal priceFeed;

    // Declare the constructor
    constructor(address _tokenAddress, address _priceFeedAddress) {
        tokenAddress = _tokenAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Declare the function for getting the current token price
    function getPrice() external view returns (uint256) {
        // Get the latest price of the token from the price feed
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // Convert the price to units of wei, the smallest unit of the token
        uint256 priceWei = uint256(price);

        // Create an instance of the ERC20 token contract
        IERC20 token = IERC20(tokenAddress);

        // Get the balance of the contract's tokens
        uint256 contractBalance = token.balanceOf(address(this));

        // Get the number of decimal places for the token
        uint8 decimals = token.decimals();

        // Calculate the current token price based on the price feed, the contract's token balance, and the token decimals
        return (contractBalance * priceWei) / (10**uint256(decimals));
    }
}