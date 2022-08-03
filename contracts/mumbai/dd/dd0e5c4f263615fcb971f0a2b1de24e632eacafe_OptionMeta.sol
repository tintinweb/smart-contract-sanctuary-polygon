/**
 *Submitted for verification at polygonscan.com on 2022-08-02
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
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    function priceProvider() external view returns (address);

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
            OptionType optionType
        );

    function ownerOf(uint256 optionId) external view returns (address owner);

    function binaryOptionType(uint256 optionId)
        external
        view
        returns (bool isYes, bool isAbove);

    function config() external view returns (address);
}

interface IOptionsConfig {
    function impliedVolRate() external view returns (uint256);
}

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
            uint256 answer,
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
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getUsdPrice() external view returns (uint256);
}

// File: OptionMeta.sol

contract OptionMeta {
    struct Input {
        uint256 optionId;
        address contractAddress;
    }
    struct OptionMetaData {
        IBufferOptions.State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        IBufferOptions.OptionType optionType;
        bool isYes;
        bool isAbove;
        uint256 iv;
        uint256 assetPrice;
        uint256 priceAtExpiration;
        address owner;
    }

    function get_price_at_timestamp(address priceProvider, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceProviderContract = AggregatorV3Interface(
            priceProvider
        );
        (
            uint80 roundId,
            uint256 answer,
            ,
            uint256 latestTimestamp,

        ) = priceProviderContract.latestRoundData();

        if (latestTimestamp > timestamp) {
            bool isCorrectRoundId;
            while (!isCorrectRoundId) {
                roundId = roundId - 1;
                require(roundId > 0, "Wrong round id");
                (
                    ,
                    uint256 roundAnswer,
                    ,
                    uint256 roundTimestamp,

                ) = priceProviderContract.getRoundData(roundId);
                if ((roundTimestamp > 0) && (roundTimestamp <= timestamp)) {
                    isCorrectRoundId = true;
                    answer = roundAnswer;
                }
            }
        }
        return answer;
    }

    function get_option_data(Input[] calldata options)
        public
        view
        returns (OptionMetaData[] memory allOptions)
    {
        allOptions = new OptionMetaData[](options.length);

        for (uint256 i = 0; i < options.length; i++) {
            uint256 optionId = options[i].optionId;
            IBufferOptions binaryOptionsContract = IBufferOptions(
                options[i].contractAddress
            );
            (
                IBufferOptions.State state,
                uint256 strike,
                uint256 amount,
                uint256 lockedAmount,
                uint256 premium,
                uint256 expiration,
                IBufferOptions.OptionType optionType
            ) = binaryOptionsContract.options(optionId);
            (bool isYes, bool isAbove) = binaryOptionsContract.binaryOptionType(
                optionId
            );

            allOptions[i] = OptionMetaData(
                state,
                strike,
                amount,
                lockedAmount,
                premium,
                expiration,
                optionType,
                isYes,
                isAbove,
                IOptionsConfig(binaryOptionsContract.config()).impliedVolRate(),
                AggregatorV3Interface(binaryOptionsContract.priceProvider())
                    .getUsdPrice(),
                (state == IBufferOptions.State.Active &&
                    block.timestamp > expiration)
                    ? get_price_at_timestamp(
                        binaryOptionsContract.priceProvider(),
                        expiration
                    )
                    : 0,
                state == IBufferOptions.State.Active
                    ? binaryOptionsContract.ownerOf(optionId)
                    : address(0)
            );
        }
        return allOptions;
    }
}