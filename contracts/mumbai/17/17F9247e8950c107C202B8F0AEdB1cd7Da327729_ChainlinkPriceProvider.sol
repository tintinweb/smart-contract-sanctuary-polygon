/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// File: InterfacesV2.sol

interface IBufferOptions {
    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }
    enum OptionType {
        Invalid,
        Put,
        Call
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
        uint256 totalFee;
        uint256 createdAt;
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    function priceProvider() external view returns (address);

    function expiryToRoundID(uint256 timestamp) external view returns (uint256);

    function options(uint256 optionId)
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            OptionType optionType,
            uint256 totalFee,
            uint256 createdAt
        );

    function ownerOf(uint256 optionId) external view returns (address owner);

    function nextTokenId() external view returns (uint256 nextToken);

    function binaryOptionType(uint256 optionId)
        external
        view
        returns (bool isYes, bool isAbove);

    function config() external view returns (address);

    function userOptionIds(address user, uint256 index)
        external
        view
        returns (uint256 optionId);

    function userOptionCount(address user)
        external
        view
        returns (uint256 count);
}

interface IOptionsConfig {
    function impliedVolRate() external view returns (uint256);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getTimestamp(uint256 _roundId)
        external
        view
        returns (uint256 timestamp);

    function getRoundData(uint256 _roundID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function latestRoundData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function priceProvider() external view returns (address);

    function update(uint256 price) external returns (uint256 roundId);

    function transferOwnership(address newOwner) external;

    function getUsdPrice() external view returns (uint256);
}

interface AggregatorV3ChainlinkInterface {
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

    function getTimestamp(uint256 _roundId)
        external
        view
        returns (uint256 timestamp);

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

// File: ChainlinkPriceProvider.sol

contract ChainlinkPriceProvider {
    AggregatorV3ChainlinkInterface public priceProvider;

    constructor(AggregatorV3ChainlinkInterface pp) {
        priceProvider = pp;
    }

    // Should return USD price
    function getUsdPrice() external view returns (uint256 _price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        _price = uint256(latestPrice);
    }

    // Should return timestamp of corresponding round
    function getRoundData(uint256 roundID)
        external
        view
        returns (
            uint80 roundId,
            uint256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        int256 _price;
        (roundId, _price, startedAt, updatedAt, answeredInRound) = priceProvider
            .getRoundData(uint80(roundID));
        price = uint256(_price);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceProvider
            .latestRoundData();
    }

    function decimals() external view returns (uint8) {
        return priceProvider.decimals();
    }
}