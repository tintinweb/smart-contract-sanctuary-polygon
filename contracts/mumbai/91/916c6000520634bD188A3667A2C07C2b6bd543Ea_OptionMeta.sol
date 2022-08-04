/**
 *Submitted for verification at polygonscan.com on 2022-08-03
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

    function nextTokenId() external view returns (uint256 nextToken);

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

    function priceProvider() external view returns (address);

    function getUsdPrice() external view returns (uint256);
}

// File: OptionMeta.sol

contract OptionMeta {
    struct Input {
        uint256 optionId;
        address contractAddress;
    }
    struct OptionMetaData {
        uint256 optionId;
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
        address owner;
        address contractAddress;
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

                ) = AggregatorV3Interface(priceProviderContract.priceProvider())
                        .getRoundData(roundId);
                if ((roundTimestamp > 0) && (roundTimestamp <= timestamp)) {
                    isCorrectRoundId = true;
                    answer = roundAnswer;
                }
            }
        }
        return answer;
    }

    function get_current_prices(address[] calldata assets)
        public
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            AggregatorV3Interface priceProviderContract = AggregatorV3Interface(
                assets[i]
            );
            prices[i] = priceProviderContract.getUsdPrice();
        }
    }

    function get_option_data(Input[] memory options)
        public
        view
        returns (OptionMetaData[] memory allOptions)
    {
        allOptions = new OptionMetaData[](options.length);

        for (uint256 i = 0; i < options.length; i++) {
            uint256 optionId = options[i].optionId;
            address optionsContractAddress = options[i].contractAddress;
            if (optionId > 0) {
                IBufferOptions binaryOptionsContract = IBufferOptions(
                    optionsContractAddress
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
                (bool isYes, bool isAbove) = binaryOptionsContract
                    .binaryOptionType(optionId);

                allOptions[i] = OptionMetaData(
                    optionId,
                    state,
                    strike,
                    amount,
                    lockedAmount,
                    premium,
                    expiration,
                    optionType,
                    isYes,
                    isAbove,
                    IOptionsConfig(binaryOptionsContract.config())
                        .impliedVolRate(),
                    state == IBufferOptions.State.Active
                        ? binaryOptionsContract.ownerOf(optionId)
                        : address(0),
                    optionsContractAddress
                );
            }
        }
        return allOptions;
    }

    function get_latest_options(Input calldata latestOptionIds)
        external
        view
        returns (OptionMetaData[] memory allOptions)
    {
        uint256 counter;
        uint256 optionId = latestOptionIds.optionId;
        address optionsContractAddress = latestOptionIds.contractAddress;
        IBufferOptions binaryOptionsContract = IBufferOptions(
            optionsContractAddress
        );
        uint256 latestOptionIdOnChain = binaryOptionsContract.nextTokenId() - 1;
        Input[] memory optionsToProcess = new Input[](latestOptionIdOnChain);

        if (optionId != latestOptionIdOnChain) {
            for (uint256 j = 0; j < (latestOptionIdOnChain - optionId); j++) {
                optionsToProcess[counter] = Input(
                    optionId + j + 1,
                    optionsContractAddress
                );
                counter++;
            }
        }
        return get_option_data(optionsToProcess);
    }
}