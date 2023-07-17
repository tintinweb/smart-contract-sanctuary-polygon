// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAggregatorV3Custom {
    // @param the number of digits of precision for the stored answer. Answers are stored in fixed-point format.
    function decimals() external view returns (uint8);

    //@param a description for this data feed. Usually this is an asset pair for a price feed.
    function description() external view returns (string memory);

    //@param a data provider for this data feed.
    function provider() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IAggregatorV3Custom } from "./interfaces/IAggregatorV3Custom.sol";
// import { ICegaState } from "./interfaces/ICegaState.sol";
import { RoundData } from "./Structs.sol";

contract OracleV2 is IAggregatorV3Custom {
    event OracleCreated(address indexed cegaState, uint8 decimals, string description);
    event RoundDataAdded(int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    event RoundDataUpdated(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    uint8 public decimals;
    string public description;
    string public provider;
    uint256 public version = 1;
    // ICegaState public cegaState;
    RoundData[] public oracleData;
    uint80 public nextRoundId;

    /**
     * @notice Creates a new oracle for a given asset / data source pair
     * @param _decimals is the number of decimals for the asset
     * @param _description is the aset
     * @param _provider a data provider for this data feed.
     */
    constructor(uint8 _decimals, string memory _description, string memory _provider) {
        // cegaState = ICegaState(_cegaState);
        decimals = _decimals;
        description = _description;
        provider = _provider;
        // emit OracleCreated(_decimals, _description, _provider);
    }

    // /**
    //  * @notice Asserts whether the sender has the SERVICE_ADMIN_ROLE
    //  */
    // modifier onlyServiceAdmin() {
    //     require(cegaState.isServiceAdmin(msg.sender), "403:SA");
    //     _;
    // }

    // /**
    //  * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
    //  */
    // modifier onlyDefaultAdmin() {
    //     require(cegaState.isDefaultAdmin(msg.sender), "403:DA");
    //     _;
    // }

    /**
     * @notice Adds the pricing data for the next round
     * @param _roundData is the data to be added
     */
    function addNextRoundData(RoundData calldata _roundData) public {
        if (nextRoundId != 0) {
            (, , , uint256 updatedAt, ) = latestRoundData();
            require(updatedAt <= _roundData.startedAt, "400:P");
        }
        require(block.timestamp - 1 days <= _roundData.startedAt, "400:T"); // Within 1 days

        oracleData.push(_roundData);
        nextRoundId++;
        emit RoundDataAdded(_roundData.answer, _roundData.startedAt, _roundData.updatedAt, _roundData.answeredInRound);
    }

    /**
     * @notice Updates the pricing data for a given round
     * @param _roundData is the data to be updated
     */
    function updateRoundData(uint80 roundId, RoundData calldata _roundData) public {
        oracleData[roundId] = _roundData;
        emit RoundDataUpdated(
            roundId,
            _roundData.answer,
            _roundData.startedAt,
            _roundData.updatedAt,
            _roundData.answeredInRound
        );
    }

    /**
     * @notice Gets the pricing data for a given round Id
     * @param _roundId is the id of the round
     */
    function getRoundData(
        uint80 _roundId
    )
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }

    /**
     * @notice Gets the pricing data for the latest round
     */
    function latestRoundData()
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 _roundId = nextRoundId - 1;
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

struct LeverageMetadata {
    bool isAllowed;
    bool isDepositQueueOpen;
    uint256 maxDepositAmountLimit;
    uint256 sumVaultUnderlyingAmounts;
    uint256 queuedDepositsTotalAmount;
    address[] vaultAddresses;
}

struct FCNVaultAssetInfo {
    address vaultAddress;
    uint256 totalAssets;
    uint256 totalSupply;
    uint256 inputAssets;
    uint256 outputShares;
    uint256 inputShares;
    uint256 outputAssets;
}