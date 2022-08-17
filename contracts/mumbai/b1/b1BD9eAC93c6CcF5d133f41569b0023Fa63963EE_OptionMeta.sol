/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// File: Context.sol

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    function update(uint256 price) external returns (uint256 roundId);

    function transferOwnership(address newOwner) external;

    function getUsdPrice() external view returns (uint256);
}

// File: Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: OptionMeta.sol

contract OptionMeta is Ownable {
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
    struct NewPrices {
        uint256 price;
        address priceProvider;
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

    function transferOwnership(address contract_address, address newOwner)
        public
        onlyOwner
    {
        AggregatorV3Interface priceProviderContract = AggregatorV3Interface(
            contract_address
        );
        priceProviderContract.transferOwnership(newOwner);
    }

    function bulk_price_update(NewPrices[] memory newPrices) public onlyOwner {
        for (uint256 i = 0; i < newPrices.length; i++) {
            AggregatorV3Interface priceProviderContract = AggregatorV3Interface(
                newPrices[i].priceProvider
            );
            priceProviderContract.update(newPrices[i].price);
        }
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