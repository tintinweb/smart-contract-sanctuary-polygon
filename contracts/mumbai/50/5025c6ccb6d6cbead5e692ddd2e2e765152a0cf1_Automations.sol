// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAdapter} from "./interfaces/IAdapter.sol";
import {IBenchmarks} from "./interfaces/IBenchmarks.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IConditionalTokens} from "./interfaces/IConditionalTokens.sol";

/// @title Automations
/// @author Mike Shrieve ([email protected])
/// @notice Helper contract for deployment and resolution of price markets
contract Automations {
    IAdapter public immutable adapter;
    IBenchmarks public immutable benchmarks;
    IFactory public immutable factory;
    IConditionalTokens public immutable ctf;
    address public immutable collateral;
    uint256 public immutable fee;

    constructor(
        address _adapter,
        address _benchmarks,
        address _factory,
        address _ctf,
        address _collateral
    ) {
        adapter = IAdapter(_adapter);
        benchmarks = IBenchmarks(_benchmarks);
        factory = IFactory(_factory);

        fee = 2 * 10 ** 16;
        ctf = IConditionalTokens(_ctf);
        collateral = _collateral;
    }

    function deployMarket(
        bytes32 _priceId,
        uint256 _expiry,
        uint256 _strike
    ) public returns (address) {
        bytes32 questionId = adapter.initialize(_priceId, _expiry, _strike);

        bytes32[] memory conditionIds = new bytes32[](1);
        conditionIds[0] = keccak256(
            abi.encode(address(adapter), questionId, 2)
        );

        address marketMaker = factory.createFixedProductMarketMaker(
            address(ctf),
            collateral,
            conditionIds,
            fee
        );

        return marketMaker;
    }

    function resolveEvent(
        bytes32 _priceId,
        uint256 _expiry,
        bytes calldata _priceData,
        bytes32[] memory _questionIds
    ) public payable {
        benchmarks.recordPrice{value: msg.value}(_priceId, _expiry, _priceData);

        uint256 i = 0;
        uint256 length = _questionIds.length;
        for (; i < length; ) {
            adapter.resolve(_questionIds[i]);

            unchecked {
                ++i;
            }
        }
    }
}

pragma solidity ^0.8.10;

interface IAdapter {
    event ContractGloballyPaused();
    event ContractGloballyUnpaused();
    event NewAdmin(address indexed admin, address indexed newAdminAddress);
    event QuestionEmergencyResolved(
        bytes32 indexed questionId,
        uint256[] payouts
    );
    event QuestionInitialized(
        bytes32 indexed questionId,
        bytes32 indexed priceId,
        uint256 indexed timestamp,
        uint256 strike
    );
    event QuestionPaused(bytes32 indexed questionID);
    event QuestionResolved(bytes32 indexed questionId, uint256[] payouts);
    event QuestionUnpaused(bytes32 indexed questionID);
    event RemovedAdmin(address indexed admin, address indexed removedAdmin);

    struct QuestionData {
        bytes32 benchmarkId;
        uint256 strike;
    }

    function DECIMALS() external view returns (uint256);

    function addAdmin(address admin) external;

    function admins(address) external view returns (uint256);

    function benchmarks() external view returns (address);

    function computeQuestionId(
        bytes32 _benchmarkId,
        uint256 _strike
    ) external pure returns (bytes32);

    function ctf() external view returns (address);

    function emergencyResolutionTimestamps(
        bytes32
    ) external view returns (uint256);

    function emergencyResolve(
        bytes32 _questionId,
        uint256[] memory _payouts
    ) external;

    function getQuestionData(
        bytes32 _questionId
    ) external view returns (QuestionData memory);

    function initialize(
        bytes32 _priceId,
        uint256 _timestamp,
        uint256 _strike
    ) external returns (bytes32);

    function isAdmin(address addr) external view returns (bool);

    function isGloballyPaused() external view returns (bool);

    function pause(bytes32 _questionId) external;

    function pauseGlobally() external;

    function questions(
        bytes32
    ) external view returns (bytes32 benchmarkId, uint256 strike);

    function removeAdmin(address admin) external;

    function renounceAdmin() external;

    function resolve(bytes32 _questionId) external returns (uint256[] memory);

    function safetyPeriod() external view returns (uint256);

    function unpause(bytes32 _questionId) external;

    function unpauseGlobally() external;
}

pragma solidity ^0.8.10;

interface IBenchmarks {
    event PriceRecorded(
        bytes32 indexed priceId,
        uint256 indexed timestamp,
        uint256 price,
        uint256 publishTime
    );

    function DECIMALS() external view returns (uint256);

    function VALIDITY_PERIOD_MAX() external view returns (uint256);

    function VALIDITY_PERIOD_SCALE() external view returns (uint256);

    function computeBenchmarkId(
        bytes32 _priceId,
        uint256 _timestamp
    ) external pure returns (bytes32);

    function getFee(bytes memory _priceData) external view returns (uint256);

    function prices(bytes32) external view returns (uint256);

    function pyth() external view returns (address);

    function recordPrice(
        bytes32 _priceId,
        uint256 _timestamp,
        bytes memory _priceData
    ) external payable returns (uint256);
}

pragma solidity ^0.8.10;

interface IFactory {
    event CloneCreated(address indexed target, address clone);
    event FPMMBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );
    event FPMMFundingAdded(
        address indexed funder,
        uint256[] amountsAdded,
        uint256 sharesMinted
    );
    event FPMMFundingRemoved(
        address indexed funder,
        uint256[] amountsRemoved,
        uint256 collateralRemovedFromFeePool,
        uint256 sharesBurnt
    );
    event FPMMSell(
        address indexed seller,
        uint256 returnAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensSold
    );
    event FixedProductMarketMakerCreation(
        address indexed creator,
        address fixedProductMarketMaker,
        address indexed conditionalTokens,
        address indexed collateralToken,
        bytes32[] conditionIds,
        uint256 fee
    );

    function cloneConstructor(bytes memory consData) external;

    function createFixedProductMarketMaker(
        address conditionalTokens,
        address collateralToken,
        bytes32[] memory conditionIds,
        uint256 fee
    ) external returns (address);

    function implementationMaster() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "./IERC20.sol";

/// @notice Interface for Gnosis Conditional Tokens
interface IERC1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] memory owners,
        uint256[] memory ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

interface IConditionalTokensEE {
    event ConditionPreparation(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount
    );

    event ConditionResolution(
        bytes32 indexed conditionId,
        address indexed oracle,
        bytes32 indexed questionId,
        uint256 outcomeSlotCount,
        uint256[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 amount
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder,
        IERC20 collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 indexed conditionId,
        uint256[] partition,
        uint256 amount
    );
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        bytes32 indexed parentCollectionId,
        bytes32 conditionId,
        uint256[] indexSets,
        uint256 payout
    );
}

interface IConditionalTokens is IConditionalTokensEE, IERC1155 {
    function payoutNumerators(
        bytes32 conditionId,
        uint256 index
    ) external view returns (uint256);

    function payoutDenominator(
        bytes32 conditionId
    ) external view returns (uint256);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(
        address oracle,
        bytes32 questionId,
        uint256 outcomeSlotCount
    ) external;

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(
        bytes32 questionId,
        uint256[] calldata payouts
    ) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata indexSets
    ) external;

    /// @dev Gets the outcome slot count of a condition.
    /// @param conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(
        bytes32 conditionId
    ) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(
        address oracle,
        bytes32 questionId,
        uint256 outcomeSlotCount
    ) external pure returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256 indexSet
    ) external view returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(
        IERC20 collateralToken,
        bytes32 collectionId
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @title IERC20
/// @notice Interface for solmate's ERC20
interface IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}