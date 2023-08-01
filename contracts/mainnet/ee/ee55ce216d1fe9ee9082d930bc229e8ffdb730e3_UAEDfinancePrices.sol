// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

contract UAEDfinancePrices {
    address public protocolRequestor;
    address[] public priceFeed;
    uint public immutable USDC2UAEDratio; // 6 decimals

    constructor(address _protocolRequestor) {
        protocolRequestor = _protocolRequestor;

        // collateral priceFeed on Polygon Mainnet, address checked in polygonscan.io
        // https://docs.chain.link/data-feeds/price-feeds/addresses?network=polygon
        // Notice that priceFeed of UAED with assetId == 0 is set to USDC/USD priceFeed
        // but later in calculating UAED price we apply USDC2UAEDratio
        priceFeed = [
            // decimals => 8
            0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7, // UAED    0      (USDC/USD)
            0xc907E116054Ad103354f2D350FD2514433D57F6f, // BTC     1      (BTC/USD)
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0, // ETH     2
            0xF9680D99D6C9589e2a93a78A04A279e509205945, // WETH    3
            0xd9FFdb71EbE7496cC440152d43986Aae0AB76665, // LINK    4
            0x72484B12719E23115761D5DA1646945632979bB6, // Aave    5
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0, // WMATIC  6
            0x336584C8E6Dc19637A5b36206B1c79923111b405, // CRV     7
            0x49B0c695039243BBfEb8EcD054EB70061fd54aa0, // SUSHI   8
            0xdf0Fb4e4F928d2dCB76f438575fDD8682386e13C, // UNI     9
            0x3710abeb1A0Fc7C2EC59C26c8DAA7a448ff6125A // SHIBA   10
        ];

        USDC2UAEDratio = 27000000; // can be get from UAED contract directly
    }

    modifier onlyProtocolRequestor() {
        require(
            msg.sender == address(protocolRequestor),
            "onlyProtocolRequestor"
        );
        _;
    }

    modifier validateAssetId(uint8 _assetId) {
        require(_assetId < priceFeed.length);
        _;
    }

    function changePriceFeed(
        address _priceFeed,
        uint8 _assetId
    ) external onlyProtocolRequestor validateAssetId(_assetId) {
        priceFeed[_assetId] = _priceFeed;
    }

    function addPriceFeed(address _priceFeed) external onlyProtocolRequestor {
        priceFeed.push(_priceFeed);
    }

    function getPriceInUSD(
        uint8 _assetId
    ) public view validateAssetId(_assetId) returns (uint) {
        // getting assets' price
        (
            ,
            /*uint80 roundID*/ int256 _price,
            ,
            ,

        ) = /*uint startedAt*/ /*uint timestamp*/ /*uint80 answeredInRound*/
            AggregatorV3Interface(priceFeed[_assetId]).latestRoundData();

        if (_assetId == 0) {
            return (uint(_price) * USDC2UAEDratio) / 1e8; // UAED/USD = UAED/USDC * USDC/USD
        } else {
            return uint(_price);
        }
    }
}