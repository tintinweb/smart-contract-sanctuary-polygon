// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IConditionalTokens} from "./interfaces/IConditionalTokens.sol";
import {IBenchmarks} from "./interfaces/IBenchmarks.sol";
import {Admin} from "./modules/Admin.sol";
import {IAdapter, IAdapterEE, QuestionData} from "./interfaces/IAdapter.sol";

uint256 constant SAFETY_PERIOD = 2 hours;

/// @title Adapter
/// @author Mike Shrieve ([email protected])
/// @notice Initializes and resolves binary price markets using Pyth benchmark prices as a resolution source
/// @notice Payouts:
/// @notice   [1,0] if the benchmark price is greater than or equal to the strike price
/// @notice   [0,1] if the benchmark price is strickly less than the strike price
/// @notice Note: zero is a valid strike even though a benchmark price of zero is not allowed to be recorded
contract Adapter is Admin, IAdapter {
    /// @notice Benchmarks contract
    IBenchmarks public immutable benchmarks;
    /// @notice CTF contract
    IConditionalTokens public immutable ctf;
    /// @notice (questionId => questionData)
    mapping(bytes32 => QuestionData) public questions;

    /// @param _benchmarks - Benchmarks contract address
    /// @param _ctf        - CTF contract address
    constructor(address _benchmarks, address _ctf) Admin(SAFETY_PERIOD) {
        benchmarks = IBenchmarks(_benchmarks);
        ctf = IConditionalTokens(_ctf);
    }

    /// @notice Internal decimals used for strikes and benchmarks storage
    function DECIMALS() external view returns (uint256) {
        return benchmarks.DECIMALS();
    }

    /// @notice Returns question data
    /// @param _questionId   - questionId
    /// @return questionData - QuestionData struct
    function getQuestionData(bytes32 _questionId) external view returns (QuestionData memory) {
        return questions[_questionId];
    }

    /// @notice Computes the question Id
    /// @param _benchmarkId - benchmark Id
    /// @param _strike      - strike price
    /// @return questionId  - question Id
    function computeQuestionId(bytes32 _benchmarkId, uint256 _strike)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_benchmarkId, _strike));
    }

    /// @notice Prepares the ctf condition and stores the question data
    /// @param _priceId    - Pyth price Id
    /// @param _timestamp  - expiry timsestamp
    /// @param _strike     - stike price
    /// @return questionId - question Id
    function initialize(bytes32 _priceId, uint256 _timestamp, uint256 _strike)
        external
        returns (bytes32)
    {
        bytes32 benchmarkId = benchmarks.computeBenchmarkId(_priceId, _timestamp);
        bytes32 questionId = computeQuestionId(benchmarkId, _strike);

        questions[questionId] = QuestionData(benchmarkId, _strike);

        ctf.prepareCondition(address(this), questionId, 2);

        emit QuestionInitialized(questionId, _priceId, _timestamp, _strike);
        return questionId;
    }

    /// @notice Reports payouts according to the recorded benchmark price
    /// @param _questionId - question Id
    /// @return payouts    - array of payouts
    function resolve(bytes32 _questionId)
        external
        onlyIfUnpaused(_questionId)
        returns (uint256[] memory)
    {
        QuestionData memory question = questions[_questionId];
        uint256 price = benchmarks.prices(question.benchmarkId);

        if (price == 0) {
            revert PriceIsNotRecorded();
        }

        uint256[] memory payouts = _constructPayouts(price, question.strike);
        ctf.reportPayouts(_questionId, payouts);
        emit QuestionResolved(_questionId, payouts);
        return payouts;
    }

    /// @notice Emergency resolves the market by reporting the provided payouts
    /// @param _questionId - question ID
    /// @param _payouts    - array of payouts
    function emergencyResolve(bytes32 _questionId, uint256[] calldata _payouts)
        external
        onlyAdmin
        onlyIfEmergencyResolutionIsAllowed(_questionId)
    {
        if (_payouts.length != 2) {
            revert PayoutsHaveInvalidLength(_payouts);
        }

        if (_payouts[0] + _payouts[1] == 0) {
            revert PayoutsCannotSumToZero();
        }

        ctf.reportPayouts(_questionId, _payouts);

        emit QuestionEmergencyResolved(_questionId, _payouts);
    }

    /// @notice Constructs an array of payouts
    /// @param _price  - recorded price
    /// @param _strike - stike price
    function _constructPayouts(uint256 _price, uint256 _strike)
        internal
        pure
        returns (uint256[] memory)
    {
        // Payouts: [YES, NO]
        uint256[] memory payouts = new uint256[](2);

        if (_price >= _strike) {
            // YES: Report [Yes, No] as [1, 0]
            payouts[0] = 1;
            payouts[1] = 0;
        } else {
            // NO: Report [Yes, No] as [0, 1]
            payouts[0] = 0;
            payouts[1] = 1;
        }
        return payouts;
    }
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

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function payoutNumerators(bytes32 conditionId, uint256 index) external view returns (uint256);

    function payoutDenominator(bytes32 conditionId) external view returns (uint256);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount)
        external;

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external;

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
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint256 outcomeSlotCount)
        external
        pure
        returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint256 indexSet)
        external
        view
        returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBenchmarksEE {
    error PriceIsAlreadyRecorded(bytes32 priceId, uint256 timestamp);
    error FeeIsNotExact(uint256 received, uint256 expected);
    error PriceIsInvalid(int64 price);
    error ExponentIsInvalid(int32 exponent);

    event PriceRecorded(
        bytes32 indexed priceId, uint256 indexed timestamp, uint256 price, uint256 publishTime
    );
}

interface IBenchmarks is IBenchmarksEE {
    function DECIMALS() external view returns (uint256);

    function prices(bytes32 _benchmarkId) external view returns (uint256);

    function computeBenchmarkId(bytes32 _priceId, uint256 _timestamp)
        external
        pure
        returns (bytes32);

    function getFee(bytes calldata _priceData) external view returns (uint256);

    function recordPrice(bytes32 _priceId, uint256 _timestamp, bytes calldata _priceData)
        external
        payable
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Auth} from "./Auth.sol";
import {IAdmin} from "./interfaces/IAdmin.sol";

/// @title Admin
/// @author Mike Shrieve ([email protected])
/// @notice Admin module for pausing and emergency resolution
abstract contract Admin is Auth, IAdmin {
    /*////////////////////////////////////////////////////////////////////
                            ADMIN ONLY FUNCTIONS 
    ///////////////////////////////////////////////////////////////////*/

    mapping(bytes32 => uint256) public emergencyResolutionTimestamps;
    bool public isGloballyPaused;

    /// @notice Time period after which an admin can emergency resolve a condition
    uint256 public immutable safetyPeriod;

    constructor(uint256 _safetyPeriod) {
        safetyPeriod = _safetyPeriod;
    }

    /// @notice Reverts if the question is paused.
    /// @param _questionId - The bytes32 Id of the question

    modifier onlyIfUnpaused(bytes32 _questionId) {
        if (isGloballyPaused) revert ContractIsGloballyPaused();
        if (_isPaused(_questionId)) revert QuestionIsPaused();
        _;
    }

    /// @notice Reverts if the question is not paused, or if the safety period has not passed.
    /// @param _questionId - The bytes32 Id of the question
    modifier onlyIfEmergencyResolutionIsAllowed(bytes32 _questionId) {
        uint256 resolutionTimestamp = emergencyResolutionTimestamps[_questionId];
        if (!_isPaused(_questionId)) revert QuestionIsNotPaused();
        if (block.timestamp < resolutionTimestamp) {
            revert SafetyPeriodNotPassed();
        }
        _;
    }

    /// @notice Pause a question's resolution
    /// @param _questionId - The bytes32 Id of the question
    function pause(bytes32 _questionId) external onlyAdmin {
        if (_isPaused(_questionId)) revert QuestionIsPaused();

        emergencyResolutionTimestamps[_questionId] = block.timestamp + safetyPeriod;

        emit QuestionPaused(_questionId);
    }

    /// @notice Unpause a question
    /// @param _questionId - The bytes32 Id of the question
    function unpause(bytes32 _questionId) external onlyAdmin {
        if (!_isPaused(_questionId)) revert QuestionIsNotPaused();

        emergencyResolutionTimestamps[_questionId] = 0;

        emit QuestionUnpaused(_questionId);
    }

    function pauseGlobally() external onlyAdmin {
        if (isGloballyPaused) revert ContractIsGloballyPaused();

        isGloballyPaused = true;

        emit ContractGloballyPaused();
    }

    function unpauseGlobally() external onlyAdmin {
        if (!isGloballyPaused) revert ContractIsNotGloballyPaused();

        isGloballyPaused = false;

        emit ContractGloballyUnpaused();
    }

    /// @notice Returns true if the question is paused.
    /// @param _questionId - The bytes32 Id of the question
    function _isPaused(bytes32 _questionId) internal view returns (bool) {
        return emergencyResolutionTimestamps[_questionId] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAdmin, IAdminEE} from "../modules/interfaces/IAdmin.sol";

struct QuestionData {
    bytes32 benchmarkId;
    uint256 strike;
}

interface IAdapterEE is IAdminEE {
    error PayoutsHaveInvalidLength(uint256[] payouts);
    error PayoutsCannotSumToZero();
    error PriceIsNotRecorded();

    event QuestionInitialized(
        bytes32 indexed questionId,
        bytes32 indexed priceId,
        uint256 indexed timestamp,
        uint256 strike
    );
    event QuestionResolved(bytes32 indexed questionId, uint256[] payouts);
    event QuestionEmergencyResolved(bytes32 indexed questionId, uint256[] payouts);
}

interface IAdapter is IAdmin, IAdapterEE {
    function DECIMALS() external view returns (uint256);

    function getQuestionData(bytes32 _questionId) external view returns (QuestionData memory);

    function computeQuestionId(bytes32 _benchmarkId, uint256 _strike)
        external
        pure
        returns (bytes32);

    function initialize(bytes32 _priceId, uint256 _timestamp, uint256 _strike)
        external
        returns (bytes32);

    function resolve(bytes32 _questionId) external returns (uint256[] memory);

    function emergencyResolve(bytes32 _questionId, uint256[] calldata _payouts) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAuth} from "./interfaces/IAuth.sol";

/// @title Auth
/// @author Jon Amenechi ([email protected])
/// @notice Provides access control modifiers
abstract contract Auth is IAuth {
    /// @notice Auth
    mapping(address => uint256) public admins;

    modifier onlyAdmin() {
        if (admins[msg.sender] != 1) revert NotAdmin();
        _;
    }

    constructor() {
        admins[msg.sender] = 1;
    }

    /// @notice Adds an Admin
    /// @param admin - The address of the admin
    function addAdmin(address admin) external onlyAdmin {
        admins[admin] = 1;
        emit NewAdmin(msg.sender, admin);
    }

    /// @notice Removes an admin
    /// @param admin - The address of the admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(msg.sender, admin);
    }

    /// @notice Renounces Admin privileges from the caller
    function renounceAdmin() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }

    /// @notice Checks if an address is an admin
    /// @param addr - The address to be checked
    function isAdmin(address addr) external view returns (bool) {
        return admins[addr] == 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAuth, IAuthEE} from "./IAuth.sol";

interface IAdminEE is IAuthEE {
    error QuestionIsPaused();
    error QuestionIsNotPaused();
    error SafetyPeriodNotPassed();

    error ContractIsGloballyPaused();
    error ContractIsNotGloballyPaused();

    /// @notice Emitted when a question is paused by an authorized user
    event QuestionPaused(bytes32 indexed questionID);

    /// @notice Emitted when a question is unpaused by an authorized user
    event QuestionUnpaused(bytes32 indexed questionID);

    event ContractGloballyPaused();
    event ContractGloballyUnpaused();
}

interface IAdmin is IAuth, IAdminEE {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAuthEE {
    error NotAdmin();

    /// @notice Emitted when a new admin is added
    event NewAdmin(address indexed admin, address indexed newAdminAddress);

    /// @notice Emitted when an admin is removed
    event RemovedAdmin(address indexed admin, address indexed removedAdmin);
}

interface IAuth is IAuthEE {
    function isAdmin(address) external view returns (bool);

    function addAdmin(address) external;

    function removeAdmin(address) external;

    function renounceAdmin() external;
}