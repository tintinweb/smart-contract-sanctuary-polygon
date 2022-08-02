// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./facets/AccessControlFacet.sol";
import "./facets/ClaimFacet.sol";
import "./facets/DataFacet.sol";
import "./facets/FlightStatusFacet.sol";
import "./facets/PolicyCreationFacet.sol";
import "./facets/ProductCreationFacet.sol";

contract OmakaseCore is
    AccessControlFacet,
    ClaimFacet,
    DataFacet,
    FlightStatusFacet,
    PolicyCreationFacet,
    ProductCreationFacet
{
    constructor(address admin_, address oracle_) {
        s.admin = admin_;
        s.claimExpireTime = 30 days;
        s.oracle = oracle_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibValidations.sol";

contract AccessControlFacet is Modifiers, InheritedStorage {
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    function oracle() external view returns (address) {
        return s.oracle;
    }

    function setOracle(address _oracle) external onlyAdmin {
        LibValidations.validateAddress(_oracle);

        address oldOracle = s.oracle;
        s.oracle = _oracle;
        emit OracleChanged(oldOracle, _oracle);
    }

    function admin() external view returns (address) {
        return s.admin;
    }

    function setAdmin(address _admin) external onlyAdmin {
        LibValidations.validateAddress(_admin);

        address oldAdmin = s.admin;
        s.admin = _admin;
        emit AdminChanged(oldAdmin, _admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../enums/BenefitName.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/entities/BenefitFlightDelay.sol";
import "../libraries/LibValidations.sol";

contract ClaimFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibPolicy for Policy;
    using LibFlight for Flight;
    using LibBenefitFlightDelay for BenefitFlightDelay;

    error ClaimExpired(uint64 timeInitiated, uint64 expiredTime);
    error BenefitClaimNotImplemented(BenefitName benefitName);
    error FlightHasNotDeparted(bytes32 flightId);
    error ProductDoesNotHaveTheBenefit(
        bytes32 productId,
        BenefitName benefitName
    );
    error BenefitAlreadyClaimed(
        bytes32 policyId,
        bytes32 flightId,
        BenefitName benefitName
    );

    event ClaimExpireTimeChanged(uint64 previousTime, uint64 newTime);
    event BenefitClaimed(
        bytes32 indexed policyId,
        bytes32 indexed flightId,
        BenefitName indexed benefitName,
        uint64 amount
    );

    function setClaimExpireTime(uint64 claimExpireTime) external onlyAdmin {
        uint64 previousTime = s.claimExpireTime;
        s.claimExpireTime = claimExpireTime;

        emit ClaimExpireTimeChanged(previousTime, claimExpireTime);
    }

    function claimBenefit(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) external onlyOracle {
        LibValidations.ensureFlightExists(flightId);
        LibValidations.ensurePolicyExists(policyId);
        ensureClaimIsNotExpired(flightId);
        ensureHasNotBeenClaimed(flightId, policyId, benefitName);

        uint64 amount = calculateClaim(flightId, policyId, benefitName);
        s.policies[policyId].claimedAmounts[benefitName] += amount;
        s.policies[policyId].hasClaimed[flightId][benefitName] = true;

        emit BenefitClaimed(policyId, flightId, benefitName, amount);
    }

    function calculateClaim(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) public view returns (uint64) {
        Policy storage policy = s.policies[policyId];

        if (benefitName == BenefitName.FlightDelay) {
            return
                calculateClaimForFlightDelay(
                    flightId,
                    policy.productId,
                    policy.claimedAmounts[BenefitName.FlightDelay]
                );
        } else {
            revert BenefitClaimNotImplemented(benefitName);
        }
    }

    function calculateClaimForFlightDelay(
        bytes32 flightId,
        bytes32 productId,
        uint64 claimedAmount
    ) private view returns (uint64) {
        ensureProductHasBenefit(productId, BenefitName.FlightDelay);

        Flight storage flight = s.flights[flightId];

        if (!flight.hasDeparted()) revert FlightHasNotDeparted(flightId);

        return
            uint64(
                s.products[productId].benefitFlightDelay.calculateIndemnity(
                    claimedAmount,
                    flight.scheduledDepartureTime,
                    flight.actualDepartureTime
                )
            );
    }

    function ensureProductHasBenefit(bytes32 productId, BenefitName benefitName)
        private
        view
    {
        if (!s.products[productId].hasBenefit(benefitName)) {
            revert ProductDoesNotHaveTheBenefit(productId, benefitName);
        }
    }

    function ensureClaimIsNotExpired(bytes32 flightId) internal view {
        uint64 timeInitiated = s.flights[flightId].timeChecked;
        uint64 timeExpired = timeInitiated + s.claimExpireTime;
        if (block.timestamp >= timeExpired) {
            revert ClaimExpired(timeInitiated, timeExpired);
        }
    }

    function ensureHasNotBeenClaimed(
        bytes32 flightId,
        bytes32 policyId,
        BenefitName benefitName
    ) internal view {
        if (s.policies[policyId].hasClaimed[flightId][benefitName]) {
            revert BenefitAlreadyClaimed(policyId, flightId, benefitName);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";
import "../libraries/entities/BenefitFlightDelay.sol";
import "../libraries/entities/BenefitBaggageDelay.sol";
import "../libraries/entities/BenefitFlightPostponement.sol";
import "../libraries/LibFlightsToCheck.sol";

contract DataFacet is InheritedStorage {
    using LibProduct for Product;
    using LibFlight for Flight;

    function hasProduct(bytes32 productId) external view returns (bool) {
        return !s.products[productId].isEmpty();
    }

    function getBenefitPersonalAccident(bytes32 productId)
        external
        view
        returns (BenefitPersonalAccident memory)
    {
        return s.products[productId].benefitPersonalAccident;
    }

    function getBenefitFlightDelay(bytes32 productId)
        external
        view
        returns (BenefitFlightDelay memory)
    {
        return s.products[productId].benefitFlightDelay;
    }

    function getBenefitBaggageDelay(bytes32 productId)
        external
        view
        returns (BenefitBaggageDelay memory)
    {
        return s.products[productId].benefitBaggageDelay;
    }

    function getBenefitFlightPostponement(bytes32 productId)
        external
        view
        returns (BenefitFlightPostponement memory)
    {
        return s.products[productId].benefitFlightPostponement;
    }

    function getProductBenefits(bytes32 productId)
        external
        view
        returns (BenefitName[] memory)
    {
        return s.products[productId].benefits;
    }

    /*-------------------------------------------------------------------------*/
    // Oracle

    function pendingRequest(bytes32 requestId) external view returns (uint256) {
        return s.pendingRequest[requestId];
    }

    /*-------------------------------------------------------------------------*/
    // Policy

    function getPolicyUserHash(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].userHash;
    }

    function getPolicyProductId(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].productId;
    }

    function totalPolicies() external view returns (uint256) {
        return s.totalPolicies;
    }

    /*-------------------------------------------------------------------------*/
    // Claim

    function getClaimedAmount(bytes32 policyId, BenefitName benefitName)
        external
        view
        returns (uint64)
    {
        return s.policies[policyId].claimedAmounts[benefitName];
    }

    /*-------------------------------------------------------------------------*/
    // Flight

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return s.flights[flightId];
    }

    function hasFlight(bytes32 flightId) external view returns (bool) {
        return !s.flights[flightId].isEmpty();
    }

    function totalFlights() external view returns (uint256) {
        return s.totalFlights;
    }

    function getFlightsToCheck() external pure returns (bytes32[] memory) {
        return LibFlightsToCheck.getArray();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../dependencies/KeeperCompatibleInterface.sol";
import "../libraries/LibFlightsToCheck.sol";
import "../libraries/LibOracle.sol";
import "../libraries/LibValidations.sol";
import "../libraries/helpers/LibBytes.sol";
import "../libraries/entities/Flight.sol";
import "../enums/FlightStatus.sol";

contract FlightStatusFacet is
    Modifiers,
    InheritedStorage,
    KeeperCompatibleInterface
{
    using LibFlight for Flight;
    using LibBytes for bytes;

    error FlightTimeHasAlreadyBeenAssigned(bytes32 id);
    error InvalidArrivalTime(bytes32 id, uint64 time);
    error InvalidScheduledDepartureTime(bytes32 id, uint64 time);
    error UpdateExceedsMaximumRetries(bytes32 flightId, uint8 nRetries);

    event MissingFlightStatus(bytes32 indexed flightId);
    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        FsFlightStatus status,
        uint256 actualDepartureTime
    );
    event FlightTimeChanged(
        bytes32 indexed id,
        uint64 newScheduledDepartureTime,
        uint64 newArrivalTime
    );

    function updateFlightTime(
        bytes32 id,
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) external onlyAdmin {
        if (
            scheduledDepartureTime == 0 ||
            scheduledDepartureTime == LibFlight.NULL_SCHEDULED_DEPARTURE_TIME
        ) {
            revert InvalidScheduledDepartureTime(id, scheduledDepartureTime);
        }
        if (arrivalTime == 0 || arrivalTime <= scheduledDepartureTime) {
            revert InvalidArrivalTime(id, arrivalTime);
        }

        LibValidations.ensureFlightExists(id);
        Flight storage flight = s.flights[id];

        if (
            flight.scheduledDepartureTime !=
            LibFlight.NULL_SCHEDULED_DEPARTURE_TIME
        ) {
            revert FlightTimeHasAlreadyBeenAssigned(id);
        }

        flight.scheduledDepartureTime = scheduledDepartureTime;
        LibFlightsToCheck.insert(id, arrivalTime);

        emit FlightTimeChanged(id, scheduledDepartureTime, arrivalTime);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32[] storage arr = LibFlightsToCheck.getArray();

        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 flightId = arr[i];
            if (!s.flights[flightId].needCheck()) {
                continue;
            } else if (performData.length / 32 > 60) {
                break;
            }

            performData = abi.encodePacked(performData, flightId);
        }

        upkeepNeeded = performData.length >= 32;
    }

    function performUpkeep(bytes memory performData) external override {
        performData.loopBytes32(checkFlight);
    }

    function checkFlight(bytes32 flightId) private {
        Flight storage flight = s.flights[flightId];

        if (!flight.needCheck()) {
            return;
        }

        LibOracle.requestStatusUpdate(flightId);
        LibFlightsToCheck.remove(flightId);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        FsFlightStatus status,
        uint256 actualDepartureTime
    ) external oracleCallback(requestId) {
        if (isCancelled(status)) {
            emit FlightStatusUpdate(
                requestId,
                flightId,
                status,
                actualDepartureTime
            );
            return;
        }

        Flight storage flight = s.flights[flightId];
        if (isDeparted(status)) {
            flight.actualDepartureTime = uint64(actualDepartureTime);
            flight.timeChecked = uint64(block.timestamp);
        } else if (flight.nRetries >= 4) {
            emit MissingFlightStatus(flightId);
        } else {
            LibFlightsToCheck.insert(
                flightId,
                uint64(block.timestamp + 12 hours)
            );
            flight.nRetries++;
        }

        emit FlightStatusUpdate(
            requestId,
            flightId,
            status,
            actualDepartureTime
        );
    }

    function isDeparted(FsFlightStatus status) private pure returns (bool) {
        return
            status == FsFlightStatus.Active || status == FsFlightStatus.Landed;
    }

    function isCancelled(FsFlightStatus status) private pure returns (bool) {
        return
            status == FsFlightStatus.Canceled ||
            status == FsFlightStatus.Diverted ||
            status == FsFlightStatus.Redirected;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/LibFlightsToCheck.sol";
import "../libraries/LibValidations.sol";

struct CreatePolicyInput {
    bytes32 userHash;
    bytes32 productId;
    bytes32 transactionId1;
    bytes32 transactionId2;
}

struct CreateFlightInput {
    bytes32 id;
    uint64 scheduledDepartureTime;
    uint64 arrivalTime;
}

contract PolicyCreationFacet is Modifiers, InheritedStorage {
    using LibPolicy for Policy;
    using LibProduct for Product;
    using LibFlight for Flight;

    error FlightPolicyHasAlreadyBeenClaimed(bytes32 flightId, bytes32 policyId);
    error PolicyAlreadyHasFlight(bytes32 id);
    error UnmatchedFlightsArrayLength(
        uint256 prevArrayLen,
        uint256 newArrayLen
    );
    error InvalidPolicyId(bytes32 id);
    error InvalidUserHash(bytes32 userHash);
    error InvalidFlightId(bytes32 id);
    error UnknownProduct(bytes32 id);
    error PolicyAlreadyExists(bytes32 id);
    error FlightPolicyAlreadyExists(bytes32 flightId, bytes32 policyId);
    error UnknownFlightPolicy(bytes32 flightId, bytes32 policyId);
    error InvalidDepartureTime(uint64 departureTime);

    event PolicyCreated(bytes32 indexed policyId);
    event NewFlight(bytes32 indexed flightId);

    event FlightPolicyUpdated(
        bytes32 indexed policyId,
        bytes32 previousFlightId,
        bytes32 newFlightId
    );
    event FlightPolicyAdded(bytes32 indexed policyId, bytes32 indexed flightId);

    function createPolicy(bytes32 policyId, CreatePolicyInput calldata input)
        external
        onlyOracle
    {
        _createPolicy(policyId, input);
    }

    function createPolicyWithFlights(
        bytes32 policyId,
        CreatePolicyInput calldata policyInput,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        _createPolicy(policyId, policyInput);
        _setFlightPolicies(policyId, flightsInput);
    }

    function setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        LibValidations.ensurePolicyExists(policyId);

        if (s.policies[policyId].hasFlight) {
            revert PolicyAlreadyHasFlight(policyId);
        }

        _setFlightPolicies(policyId, flightsInput);
    }

    function updateFlightPolicies(
        bytes32 policyId,
        bytes32[] calldata prevFlightIds,
        CreateFlightInput[] calldata newFlightsInput
    ) external onlyOracle {
        LibValidations.ensurePolicyExists(policyId);

        if (prevFlightIds.length != newFlightsInput.length) {
            revert UnmatchedFlightsArrayLength(
                prevFlightIds.length,
                newFlightsInput.length
            );
        }

        for (uint256 i = 0; i < prevFlightIds.length; i++) {
            removeFlightPolicy(policyId, prevFlightIds[i]);
            addFlightPolicy(policyId, newFlightsInput[i]);

            emit FlightPolicyUpdated(
                policyId,
                prevFlightIds[i],
                newFlightsInput[i].id
            );
        }
    }

    function _createPolicy(bytes32 id, CreatePolicyInput calldata input)
        private
    {
        if (id == 0) revert InvalidPolicyId(id);
        if (s.products[input.productId].isEmpty())
            revert UnknownProduct(input.productId);
        if (input.userHash == 0) revert InvalidUserHash(input.userHash);

        Policy storage policy = s.policies[id];
        if (!policy.isEmpty()) revert PolicyAlreadyExists(id);

        policy.initialize(
            input.userHash,
            input.productId,
            input.transactionId1,
            input.transactionId2
        );
        s.totalPolicies++;

        emit PolicyCreated(id);
    }

    function _setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) private {
        Policy storage policy = s.policies[policyId];

        for (uint256 i = 0; i < flightsInput.length; i++) {
            if (policy.hasParticularFlight[flightsInput[i].id]) {
                revert FlightPolicyAlreadyExists(flightsInput[i].id, policyId);
            }

            addFlightPolicy(policyId, flightsInput[i]);
        }

        policy.hasFlight = true;
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function addFlightPolicy(
        bytes32 policyId,
        CreateFlightInput calldata flightInput
    ) private {
        Flight storage flight = s.flights[flightInput.id];
        if (flight.isEmpty()) {
            createFlight(
                flightInput.id,
                flightInput.scheduledDepartureTime,
                flightInput.arrivalTime
            );
        }

        s.policies[policyId].hasParticularFlight[flightInput.id] = true;

        emit FlightPolicyAdded(policyId, flightInput.id);
    }

    /**
     * @dev Flight is expected to be empty
     */
    function createFlight(
        bytes32 id,
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) private {
        if (id == 0) revert InvalidFlightId(id);

        Flight storage flight = s.flights[id];

        if (
            scheduledDepartureTime != 0 &&
            scheduledDepartureTime != LibFlight.NULL_SCHEDULED_DEPARTURE_TIME &&
            arrivalTime != 0
        ) {
            flight.scheduledDepartureTime = scheduledDepartureTime;
            LibFlightsToCheck.insert(id, arrivalTime);
        } else {
            flight.scheduledDepartureTime = LibFlight
                .NULL_SCHEDULED_DEPARTURE_TIME;
        }

        s.totalFlights++;

        emit NewFlight(id);
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function removeFlightPolicy(bytes32 policyId, bytes32 flightId) private {
        Policy storage policy = s.policies[policyId];

        if (!policy.hasParticularFlight[flightId])
            revert UnknownFlightPolicy(flightId, policyId);
        if (policy.hasClaimed[flightId][BenefitName.FlightDelay])
            revert FlightPolicyHasAlreadyBeenClaimed(flightId, policyId);

        delete policy.hasParticularFlight[flightId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";

contract ProductCreationFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibBenefitPersonalAccident for BenefitPersonalAccident;

    error InvalidProductId(bytes32 id);
    error ProductAlreadyExists(bytes32 id);
    error MissingBenefitPersonalAccident();

    event NewProduct(bytes32 indexed productId, BenefitName[] benefits);

    function createProduct(
        bytes32 productId,
        BenefitInitInput[] calldata benefits
    ) external onlyOracle {
        Product storage product = s.products[productId];

        if (!product.isEmpty()) revert ProductAlreadyExists(productId);

        product.initialize(benefits);

        if (product.benefitPersonalAccident.isEmpty()) {
            revert MissingBenefitPersonalAccident();
        }

        emit NewProduct(productId, product.benefits);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibOracle.sol";
import "../libraries/LibAppStorage.sol";

abstract contract Modifiers {
    error CallerIsNotAdmin(address caller);

    modifier onlyOracle() {
        LibOracle.enforceCallerIsOracle();
        _;
    }

    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        if (msg.sender != s.admin) revert CallerIsNotAdmin(msg.sender);
        _;
    }

    modifier oracleCallback(bytes32 requestId) {
        LibOracle.handleOracleCallback(requestId);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";

abstract contract InheritedStorage {
    AppStorage internal s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => Product) products;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
    address admin;
    uint64 claimExpireTime;
    // Oracle
    mapping(bytes32 => uint256) pendingRequest;
    uint256 requestCount;
    address oracle;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LibAppStorage.sol";
import "./entities/Flight.sol";
import "./entities/Policy.sol";

library LibValidations {
    using LibFlight for Flight;
    using LibPolicy for Policy;

    error UnknownFlight(bytes32 id);
    error UnknownPolicy(bytes32 id);
    error InvalidAddress(address addr);

    function ensureFlightExists(bytes32 id) internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.flights[id].isEmpty()) {
            revert UnknownFlight(id);
        }
    }

    function ensurePolicyExists(bytes32 id) internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.policies[id].isEmpty()) {
            revert UnknownPolicy(id);
        }
    }

    function validateAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidAddress(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../enums/OracleJob.sol";
import "./LibAppStorage.sol";

library LibOracle {
    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);

    error CallerIsNotOracle(address caller);
    error UnknownOracleRequest(bytes32 id);

    function enforceCallerIsOracle() internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        if (msg.sender != s.oracle) revert CallerIsNotOracle(msg.sender);
    }

    function handleOracleCallback(bytes32 requestId) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        enforceCallerIsOracle();
        if (s.pendingRequest[requestId] == 0)
            revert UnknownOracleRequest(requestId);

        emit OracleFulfilled(requestId);
        delete s.pendingRequest[requestId];
    }

    function requestStatusUpdate(bytes32 flightId) internal {
        bytes32 requestId = createRequest();

        emit OracleRequested(
            requestId,
            OracleJob.StatusUpdate,
            abi.encodePacked(flightId)
        );
    }

    function createRequest() private returns (bytes32 requestId) {
        AppStorage storage s = LibAppStorage.appStorage();

        s.requestCount += 1;
        requestId = keccak256(abi.encodePacked(s.requestCount));
        s.pendingRequest[requestId] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum OracleJob {
    StatusUpdate
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../enums/BenefitName.sol";

struct Policy {
    bytes32 userHash;
    bytes32 productId;
    bytes32 transactionId1;
    bytes32 transactionId2;
    bool hasFlight;
    mapping(BenefitName => uint64) claimedAmounts;
    mapping(bytes32 => mapping(BenefitName => bool)) hasClaimed;
    mapping(bytes32 => bool) hasParticularFlight;
}

library LibPolicy {
    function initialize(
        Policy storage self,
        bytes32 userHash,
        bytes32 productId,
        bytes32 transactionId1,
        bytes32 transactionId2
    ) internal {
        self.userHash = userHash;
        self.productId = productId;
        self.transactionId1 = transactionId1;
        self.transactionId2 = transactionId2;
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.userHash == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../enums/BenefitName.sol";
import "./BenefitFlightDelay.sol";
import "./BenefitPersonalAccident.sol";
import "./BenefitBaggageDelay.sol";
import "./BenefitFlightPostponement.sol";

struct BenefitInitInput {
    BenefitName name;
    bytes data;
}

struct Product {
    BenefitName[] benefits;
    BenefitPersonalAccident benefitPersonalAccident;
    BenefitFlightDelay benefitFlightDelay;
    BenefitBaggageDelay benefitBaggageDelay;
    BenefitFlightPostponement benefitFlightPostponement;
}

library LibProduct {
    using LibBenefitPersonalAccident for BenefitPersonalAccident;
    using LibBenefitFlightDelay for BenefitFlightDelay;
    using LibBenefitBaggageDelay for BenefitBaggageDelay;
    using LibBenefitFlightPostponement for BenefitFlightPostponement;

    error DuplicateBenefit(BenefitName benefitName);
    error UnknownBenefitName(uint8 benefitName);

    function initialize(
        Product storage self,
        BenefitInitInput[] calldata benefits
    ) internal {
        for (uint256 i = 0; i < benefits.length; i++) {
            if (benefits[i].name == BenefitName.PersonalAccident) {
                if (!self.benefitPersonalAccident.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitPersonalAccident.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightDelay) {
                if (!self.benefitFlightDelay.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitFlightDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.BaggageDelay) {
                if (!self.benefitBaggageDelay.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitBaggageDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightPostponement) {
                if (!self.benefitFlightPostponement.isEmpty()) {
                    revert DuplicateBenefit(benefits[i].name);
                }

                self.benefitFlightPostponement.initialize(benefits[i].data);
            } else if (
                benefits[i].name == BenefitName.TripCancellation
            ) {} else {
                revert UnknownBenefitName(uint8(benefits[i].name));
            }

            self.benefits.push(benefits[i].name);
        }
    }

    function hasBenefit(Product storage self, BenefitName benefitName)
        internal
        view
        returns (bool)
    {
        uint256 len = self.benefits.length;
        for (uint256 i = 0; i < len; i++) {
            if (self.benefits[i] == benefitName) {
                return true;
            }
        }

        return false;
    }

    function isEmpty(Product storage self) internal view returns (bool) {
        return self.benefitPersonalAccident.isEmpty();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Flight {
    uint64 scheduledDepartureTime;
    uint64 actualDepartureTime;
    uint64 timeChecked;
    uint64 nextCheck;
    uint8 nRetries;
    uint256 idxInFlightsToCheck;
}

library LibFlight {
    uint64 constant NULL_SCHEDULED_DEPARTURE_TIME = type(uint64).max;

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.scheduledDepartureTime == 0;
    }

    function needCheck(Flight storage self) internal view returns (bool) {
        if (self.actualDepartureTime != 0) {
            return false;
        }

        // Gas eficient way to check if flight is valid
        // since `nextCheck` will always be assigned in creation
        // Otherwise, actualDepartureTime won't be zero
        uint64 nextCheck = self.nextCheck;
        if (nextCheck == 0) {
            revert("Unknown flight");
        }

        return block.timestamp >= nextCheck;
    }

    function hasDeparted(Flight storage self) internal view returns (bool) {
        return self.actualDepartureTime != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum BenefitName {
    PersonalAccident,
    FlightDelay,
    BaggageDelay,
    TripCancellation,
    FlightPostponement
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitFlightDelay {
    uint8 delayInterval;
    uint64 maximumAmount;
    uint64 amountPerInterval;
}

library LibBenefitFlightDelay {
    error InvalidDelayInterval(uint8 delayInterval);
    error InvalidAmountPerInterval(uint64 amountPerInterval);

    function initialize(BenefitFlightDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayInterval;
        uint64 amountPerInterval;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayInterval := mload(add(data, 9))
            amountPerInterval := mload(add(data, 17))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }
        if (delayInterval == 0) revert InvalidDelayInterval(delayInterval);
        if (amountPerInterval == 0)
            revert InvalidAmountPerInterval(amountPerInterval);

        self.maximumAmount = uint64(maximumAmount);
        self.delayInterval = uint8(delayInterval);
        self.amountPerInterval = uint64(amountPerInterval);
    }

    /**
     * @dev Should only be called if it's `eligibleForClaim`.
     * Otherwise, it could throw a 'division by zero' error or
     * returns zero
     */
    function calculateIndemnity(
        BenefitFlightDelay storage self,
        uint64 claimedIndemnity,
        uint64 scheduledTime,
        uint64 actualTime
    ) internal view returns (uint64 indemnity) {
        int64 diff = int64(actualTime - scheduledTime);
        if (diff < 1 hours) return 0;

        indemnity = uint64(
            ((uint64(diff) / 1 hours) / self.delayInterval) *
                self.amountPerInterval
        );

        uint64 remaining = self.maximumAmount - claimedIndemnity;
        if (indemnity > remaining) {
            indemnity = remaining;
        }
    }

    function isEmpty(BenefitFlightDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitPersonalAccident {
    uint64 maximumAmount;
}

library LibBenefitPersonalAccident {
    function initialize(BenefitPersonalAccident storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
    }

    function isEmpty(BenefitPersonalAccident storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitBaggageDelay {
    uint8 delayHour;
    uint64 maximumAmount;
}

library LibBenefitBaggageDelay {
    error InvalidDelayHour(uint8 delayHour);

    function initialize(BenefitBaggageDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayHour;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayHour := mload(add(data, 9))
        }

        if (delayHour == 0) revert InvalidDelayHour(delayHour);
        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
        self.delayHour = delayHour;
    }

    function isEmpty(BenefitBaggageDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

struct BenefitFlightPostponement {
    uint64 maximumAmount;
}

library LibBenefitFlightPostponement {
    function initialize(
        BenefitFlightPostponement storage self,
        bytes memory data
    ) internal {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            revert InvalidMaximumAmount(maximumAmount);
        }

        self.maximumAmount = maximumAmount;
    }

    function isEmpty(BenefitFlightPostponement storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error InvalidMaximumAmount(uint256 maximumAmount);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";
import "./entities/Flight.sol";

library LibFlightsToCheck {
    using LibFlight for Flight;

    bytes32 constant DATA_STORAGE_POSITION =
        keccak256("omakase.flight.lib_flights_to_check.storage");

    function getArray() internal pure returns (bytes32[] storage arr) {
        bytes32 position = DATA_STORAGE_POSITION;
        assembly {
            arr.slot := position
        }
    }

    function insert(bytes32 flightId, uint64 timeToCheck) internal {
        Flight storage flight = LibAppStorage.appStorage().flights[flightId];
        bytes32[] storage arr = getArray();

        flight.nextCheck = timeToCheck;
        flight.idxInFlightsToCheck = arr.length;

        arr.push(flightId);
    }

    function remove(bytes32 flightId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32[] storage arr = getArray();

        uint256 idx = s.flights[flightId].idxInFlightsToCheck;
        delete s.flights[flightId].idxInFlightsToCheck;

        uint256 lastIdx = arr.length - 1;
        if (idx != lastIdx) {
            bytes32 replacementData = arr[lastIdx];
            arr[idx] = replacementData;
            s.flights[replacementData].idxInFlightsToCheck = idx;
        }

        arr.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice checks if the contract requires work to be done.
     * @param checkData data passed to the contract when checking for upkeep.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with,
     * if upkeep is needed.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs work on the contract. Executed by the keepers, via the registry.
     * @param performData is the data which was passed back from the checkData
     * simulation.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibBytes {
    function loopBytes32(bytes memory self, function(bytes32) func) internal {
        uint256 len = self.length / 32;
        bytes32 dataStartPos;
        bytes32 dataEndPos;
        assembly {
            dataStartPos := add(self, 32)
            dataEndPos := add(dataStartPos, mul(sub(len, 1), 32))
        }

        while (dataStartPos <= dataEndPos) {
            bytes32 item;
            assembly {
                item := mload(dataStartPos)
                dataStartPos := add(dataStartPos, 32)
            }

            func(item);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum FsFlightStatus {
    Active,
    Landed,
    Canceled,
    Diverted,
    Unknown,
    Redirected,
    NotOperational,
    Scheduled,
    DataSourceNeeded
}