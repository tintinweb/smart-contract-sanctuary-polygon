// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface IMesosphere {
    function submitValue(uint requestId, uint ethPrice) external;
    function getCurrentValue(uint requestId) external view returns (uint);
}

interface IREXMarket {
    function updateTokenPrices() external;
    function distribute(bytes calldata data) external;
}

contract PriceProxy {

    // Polygon Mainnet Constants
    IChainlink private constant CHAINLINK_ETH_USD_FEED = IChainlink(0xF9680D99D6C9589e2a93a78A04A279e509205945);
    IChainlink private constant CHAINLINK_BTC_USD_FEED = IChainlink(0xc907E116054Ad103354f2D350FD2514433D57F6f);
    IChainlink private constant CHAINLINK_USDC_USD_FEED = IChainlink(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);

    // REX Mainnet Constants
    IREXMarket private constant ETH_REX_MARKET = IREXMarket(0x56aCA122d439365B455cECb14B4A39A9d1B54621);
    IREXMarket private constant BTC_REX_MARKET = IREXMarket(0xbB5C64B929b1E60c085dcDf88dfe41c6b9dcf65B);

    IMesosphere private constant MESOSPHERE = IMesosphere(0xACC2d27400029904919ea54fFc0b18Bf07C57875);

    uint public immutable ethRequestId = 1;
    uint public immutable btcRequestId = 60;
    uint public immutable usdcRequestId = 78;
    uint public immutable ricRequestId = 77;

    mapping (uint => IChainlink) public requestToChainlinkFeed;
    mapping (uint => IREXMarket) public requestToREXMarket;

    constructor() {
        requestToChainlinkFeed[ethRequestId] = CHAINLINK_ETH_USD_FEED;
        requestToChainlinkFeed[btcRequestId] = CHAINLINK_BTC_USD_FEED;
        requestToChainlinkFeed[usdcRequestId] = CHAINLINK_USDC_USD_FEED;

        requestToREXMarket[ethRequestId] = ETH_REX_MARKET;
        requestToREXMarket[btcRequestId] = BTC_REX_MARKET;
    }

    function update() public {
        uint256 ethPrice = uint(requestToChainlinkFeed[ethRequestId].latestAnswer()) / 100;
        uint256 btcPrice = uint(requestToChainlinkFeed[btcRequestId].latestAnswer()) / 100;
        uint256 usdcPrice = uint(requestToChainlinkFeed[usdcRequestId].latestAnswer()) / 100;
        MESOSPHERE.submitValue(ethRequestId, ethPrice);
        MESOSPHERE.submitValue(btcRequestId, btcPrice);
        MESOSPHERE.submitValue(usdcRequestId, usdcPrice);
        MESOSPHERE.submitValue(ricRequestId, 1e18);
        requestToREXMarket[ethRequestId].updateTokenPrices();
        requestToREXMarket[btcRequestId].updateTokenPrices();
    }
}