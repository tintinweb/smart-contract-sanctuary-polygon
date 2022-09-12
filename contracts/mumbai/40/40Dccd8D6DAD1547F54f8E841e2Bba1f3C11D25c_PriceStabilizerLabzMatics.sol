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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

address constant ETHUSDORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
string constant MATICUSDORACLE = "0xAB594600376Ec9fD91F8e885dADF0CE036862dE";
address constant MATICETHORACLE = 0x327e23A4855b6F663a28c5161541d69Af8973302;
address constant MUMBAIETHUSDORACLE = 0x0715A7794a1dc8e42615F059dD6e406A6594651A;
address constant MUMBAIMATICUSDORACLE = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
address constant MUMBAIUSDTUSD = 0x92C09849638959196E976289418e5973CC96d645;

abstract contract PriceStabilizer {

    address public oracleAddress;
    AggregatorV3Interface internal priceFeed;
    uint8 internal _defaultDecimals = 18;

    constructor(address _oracleAddress) {
        priceFeed = AggregatorV3Interface(_oracleAddress);
    }


    function getLatestPrice() public view returns (int) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getDerivedPrice(uint8 _decimals, int256 _target)
    public
    view
    returns (int256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 decimals = int256(10 ** uint256(_decimals));
        ( , int256 basePrice, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(priceFeed).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        int256 quotePrice = _target;
        uint8 quoteDecimals = baseDecimals;
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }


    function getConvertedQuote(int256 _target) public view returns(int256) {
    return getDerivedPrice(18, _target);
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
    internal
    pure
    returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

}

contract PriceStabilizerLabzMatics is PriceStabilizer {

    struct HistoricalPrice {
        uint256 timeUpdated;
        int256 _last;
        int256 _price;
    }
    HistoricalPrice[] internal _historicalQuotes;
    int256 internal _lastPrice;
    int256 internal _currentPrice;
    uint256 internal _lastUpdated;
    uint256 internal _index;

    constructor() PriceStabilizer(address(MUMBAIMATICUSDORACLE)) {
        _lastPrice = 0;
        _currentPrice = 0;
        _lastUpdated = block.timestamp;
        _index = 0;
        stabilize(1);
    }

    function _stabilize(int256 _target) internal virtual returns(int256) {
        int256 _quote= getConvertedQuote(_target);
        _lastPrice = _currentPrice;
        _currentPrice = _quote;
       // _historicalQuotes[_index] = HistoricalPrice(block.timestamp, _lastPrice, _quote);
        _index = _index + 1;
        _lastUpdated = block.timestamp;
        return _quote;
    }

    function stabilize(int256 _target) public returns(int256) {
        return _stabilize(_target);
    }

    function OneMaticToLabz(int256 _targetUSD) public view returns(uint256) {
        int256 priceUSDMatic = _currentPrice;
        uint256 priceMaticLabz = uint256(priceUSDMatic / _targetUSD) * 1e18;
        return priceMaticLabz;
    }


    function getHistoricalPrices() public view returns(HistoricalPrice[] memory) {
        return _historicalQuotes;
    }

    function lastPrice() public view returns(int256) {
        return _lastPrice;
    }

    function currentPrice() public view returns(int256) {
        return _currentPrice;
    }

    function lastUpdate() public view returns(uint256) {
        return _lastUpdated;
    }

}