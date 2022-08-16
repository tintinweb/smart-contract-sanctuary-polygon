/**
 *Submitted for verification at polygonscan.com on 2022-08-16
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

    function getUsdPrice() external view returns (uint256);
}

// File: OptionMeta.sol

contract OptionMeta {
    struct UserOptionInput {
        uint256 lastStoredOptionIndex;
        address contractAddress;
        address userAddress;
        bool isNull;
    }
    struct GenricOptionInput {
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
        uint256 totalFee;
        uint256 createdAt;
        uint256 iv;
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
            uint256 roundId,
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

    function get_option_data(GenricOptionInput memory option)
        public
        view
        returns (OptionMetaData memory optionDetails)
    {
        uint256 optionId = option.optionId;
        IBufferOptions binaryOptionsContract = IBufferOptions(
            option.contractAddress
        );
        (
            IBufferOptions.State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            IBufferOptions.OptionType optionType,
            uint256 totalFee,
            uint256 createdAt
        ) = binaryOptionsContract.options(optionId);
        (bool isYes, bool isAbove) = binaryOptionsContract.binaryOptionType(
            optionId
        );
        optionDetails = OptionMetaData(
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
            totalFee,
            createdAt,
            IOptionsConfig(binaryOptionsContract.config()).impliedVolRate()
        );
    }

    function get_bulk_option_data(GenricOptionInput[] memory options)
        public
        view
        returns (OptionMetaData[] memory allOptions)
    {
        allOptions = new OptionMetaData[](options.length);

        for (uint256 i = 0; i < options.length; i++) {
            allOptions[i] = get_option_data(options[i]);
        }
        return allOptions;
    }

    function get_latest_options_for_user(
        UserOptionInput calldata userOptionInput
    ) external view returns (OptionMetaData[] memory allOptions) {
        uint256 counter;
        uint256 lastStoredOptionIndex = userOptionInput.lastStoredOptionIndex;
        address optionsContractAddress = userOptionInput.contractAddress;
        IBufferOptions binaryOptionsContract = IBufferOptions(
            optionsContractAddress
        );
        uint256 onChainUserOptions = binaryOptionsContract.userOptionCount(
            userOptionInput.userAddress
        );
        uint256 firstOptionIndexToProcess = (
            userOptionInput.isNull ? 0 : lastStoredOptionIndex + 1
        );

        if (firstOptionIndexToProcess < onChainUserOptions) {
            allOptions = new OptionMetaData[](
                onChainUserOptions - firstOptionIndexToProcess
            );

            for (
                uint256 index = firstOptionIndexToProcess;
                index < onChainUserOptions;
                index++
            ) {
                allOptions[counter] = get_option_data(
                    GenricOptionInput(
                        binaryOptionsContract.userOptionIds(
                            userOptionInput.userAddress,
                            index
                        ),
                        optionsContractAddress
                    )
                );
                counter++;
            }
        }
    }
}