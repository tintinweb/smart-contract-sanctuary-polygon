/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: 123.sol



pragma solidity ^0.8.7;




contract PriceConsumerV3 {



    AggregatorV3Interface internal priceFeed;

    AggregatorV3Interface internal priceFeed2;

    AggregatorV3Interface internal priceFeed3;

    AggregatorV3Interface internal priceFeed4;

    AggregatorV3Interface internal priceFeed5;

    AggregatorV3Interface internal priceFeed6;

    AggregatorV3Interface internal priceFeed7;

    AggregatorV3Interface internal priceFeed8;





    /**

     * Polygon Mumbai oracle

     */

    constructor() {

        priceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b); // btc -usd; 8 decimals

		priceFeed2 = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);// eth-usd; 8 decimals

		priceFeed3 = AggregatorV3Interface(	0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);// matic-usd; 8 decimals

        priceFeed4 = AggregatorV3Interface(	0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046); // dai-usd; 8 decimals

        priceFeed5 = AggregatorV3Interface(	0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0); // usdc-usd; 8 decimals

        priceFeed6 = AggregatorV3Interface(	0x9dd18534b8f456557d11B9DDB14dA89b2e52e308); // sand-usd; 8 decimals

        priceFeed7 = AggregatorV3Interface(	0x92C09849638959196E976289418e5973CC96d645); // usdt-usd; 8 decimals

        priceFeed8 = AggregatorV3Interface(	0x48785dCFe1dA7116A4aF5c8235Bbf63001f68BCD); // CelsiusX Rinkeby->Mumbai cxBTC PoR; 18 decimals

    }



    /**

     * Returns the latest price

     */

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



    /**

     * Returns the latest price

     */

    function getLatestPrice2() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed2.latestRoundData();

        return price;

    }

   /**

     * Returns the latest price

     */

    function getLatestPrice3() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed3.latestRoundData();

        return price;

    }

   

    function getLatestPrice4() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed4.latestRoundData();

        return price;

    }

        function getLatestPrice5() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed5.latestRoundData();

        return price;

    }

        function getLatestPrice6() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed6.latestRoundData();

        return price;

    }

        function getLatestPrice7() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed7.latestRoundData();

        return price;

    }

     function getLatestPrice8() public view returns (int) {

        (

            /*uint80 roundID*/,

            int price,

            /*uint startedAt*/,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/

        ) = priceFeed8.latestRoundData();

        return price;

    }

    function getBlockNumber()public view returns (uint){

          return block.number;

    }

    



    function getBlocktimestamp()public view returns (uint){

          return block.timestamp;

    }

  



}