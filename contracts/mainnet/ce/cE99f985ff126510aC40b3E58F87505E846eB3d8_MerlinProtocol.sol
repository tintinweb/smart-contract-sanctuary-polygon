// Import della libreria Chainlink
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MerlinProtocol {
  // Indirizzo dell'Oracle Chainlink per il prezzo WETH/USDT su Polygon
  AggregatorV3Interface private priceFeed;

  // Costruttore: impostiamo l'indirizzo dell'Oracle Chainlink all'inizio
  constructor() {
    // Indirizzo dell'Oracle Chainlink per il prezzo WETH/USDT su Polygon
    priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
  }

  // Funzione per ottenere il prezzo corrente WETH/USDT
  function getWETHUSDTPrice() public view returns (uint256) {
    // Otteniamo l'ultimo round di prezzo dal Chainlink Oracle
    (, int price, , , ) = priceFeed.latestRoundData();

    // Convertiamo il prezzo Chainlink da 8 decimali a 18 decimali (la precisione di Ethereum)
    uint256 priceScaled = uint256(price) * 10 ** 10;

    // Restituiamo il prezzo convertito in wei (la più piccola unità di Ethereum)
    return priceScaled;
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