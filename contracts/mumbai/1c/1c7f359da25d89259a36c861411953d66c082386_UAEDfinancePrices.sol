// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

contract UAEDfinancePrices{

    address public protocolRequestor;
    address[] public priceFeed;
    uint public immutable USDC2UAEDratio;   // 6 decimals  

    constructor(address _protocolRequestor){
        protocolRequestor = _protocolRequestor;

        // collateral priceFeed on Polygon Mainnet, address checked in polygonscan.io 
        // https://docs.chain.link/data-feeds/price-feeds/addresses?network=polygon
        // Notice that priceFeed of UAED with assetId == 0 is set to USDC/USD priceFeed
        // but later in calculating UAED price we apply USDC2UAEDratio
        priceFeed = [                                     // decimals => 8 
            0xc3637C0832Db5942f52302a23E605ff33f925e3c,   // UAED    0      (USDC/USD)
            0x95E6ecaEff87E9dc291A32286E32f2D219f86726,   // BTC     1      (BTC/USD)
            0xAC88E744c1bdaed7F603A1aC634862508997eFcE,   // ETH     2
            0x4152293f4FD779E71Bc8011F754D7827a1bab978,   // WETH    3
            0x1e92aDF83A1236659db1f48d80d783ae3C9DC6b0,   // LINK    4
            0x830a31CCeDF1d44c7449bF461bdA75e11aC3F881,   // Aave    5
            0xAC88E744c1bdaed7F603A1aC634862508997eFcE,   // WMATIC  6 
            0x8698b6607Eb02f2023D9b2B29C8ad3827B72CFaB,   // CRV     7
            0xBDDD146261B59aB916D8F5bFA8a9aCfD435c5c8D,   // SUSHI   8 
            0xcf253bdCB601Fe817f69b444c14b4C0E8d39C49F,   // UNI     9 
            0x88DB193926A9177e4B622C11ca7e01C94824066f    // SHIBA   10 
        ];

        USDC2UAEDratio = 27000000;                        // can be get from UAED contract directly
    }

    modifier onlyProtocolRequestor() {
        require(msg.sender == address(protocolRequestor), "onlyProtocolRequestor");
        _;
    }

    modifier validateAssetId(uint8 _assetId){
        require(_assetId < priceFeed.length);
        _;
    }

    function changePriceFeed(address _priceFeed, uint8 _assetId) external onlyProtocolRequestor validateAssetId(_assetId) {
        priceFeed[_assetId] = _priceFeed;
    }

    function addPriceFeed(address _priceFeed) external onlyProtocolRequestor {
        priceFeed.push(_priceFeed);
    }

    function getPriceInUSD(uint8 _assetId) public view validateAssetId(_assetId) returns (uint) {          // getting assets' price
        (
            /*uint80 roundID*/,
            int256 _price, 
            /*uint startedAt*/,
            /*uint timestamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed[_assetId]).latestRoundData();

        if (_assetId == 0) {
            return uint(_price) * USDC2UAEDratio/ 1e8;                    // UAED/USD = UAED/USDC * USDC/USD
        } else {
            return uint(_price);
        }
    } 

}