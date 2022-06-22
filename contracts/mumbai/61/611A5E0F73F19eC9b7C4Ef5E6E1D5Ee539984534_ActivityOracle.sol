// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../system/CrudKeySet.sol';
import '../system/HSystemChecker.sol';
import '../items/IItemFactory.sol';
import './IEnergyLevel.sol';
import '../../common/Multicall.sol';

/// @dev There are two types of activity groups used in the ActivityOracle - Persistent vs. Quick activities
/// @dev Persistent Activity (PA) - activity that is state sensitive
/// @dev - PAs have an ON and OFF version, eg. STAKING, UNSTAKING
/// @dev - Has activity IDs above the PA_THRESHOLD of 10000 (ON has odd ID numbers, OFF has even ID numbers)
/// @dev - A token doing an ON PA needs to do the subsequent OFF PA before being able to do any other activity
/// @dev Quick Activity (QA) - activity that is not state sensitive
/// @dev - Does not have ON or OFF versions
/// @dev - Can be done repeatedly as long as the token has sufficient energy

/// @dev There are also 4 power levels tied to each activity (energy, comfort, playfulness, social)

contract ActivityOracle is Multicall, HSystemChecker {
    using CrudKeySetLib for CrudKeySetLib.Set;
    CrudKeySetLib.Set _tokenTypeSet;

    IEnergyLevel _energyLevel;
    IItemFactory _itemFactory;

    address public _energyLevelContractAddress;
    address public _itemFactoryContractAddress;

    /// @dev MUST be set as midnight at some date before contract deployment
    /// @dev The date incremented by 24 hours (in seconds) at each reset
    uint48 public constant START = 1638662400;
    uint48 public constant DAY_IN_SECONDS = 86400;

    /// @dev Activity's PA threshold ID (any activity ID above this threshold is a PA)
    uint16 public constant PA_THRESHOLD = 10000;

    /// @dev Activity types in bytes
    bytes32 constant QUEST = keccak256('QUEST');
    bytes32 constant STAKING = keccak256('STAKING');
    bytes32 constant UNSTAKING = keccak256('UNSTAKING');

    /// @dev Token types in bytes
    bytes32 constant CAT_TOKEN = keccak256('CAT');
    bytes32 constant PET_TOKEN = keccak256('PET');

    /// @dev Mapping of reasons an activity cannot do an activity for backend
    enum REASON {
        NONE,
        PAUSED,
        REQUEST_OFF_WHILE_OFF,
        PA_ON,
        NOT_ENOUGH_ENERGY
    }

    struct ActivityData {
        uint128 id;
        bool paused;
        /// @dev packed uint16[4] of power consumption
        uint64 packedEnergyConsumption;
        uint256[] petStageBonus;
    }

    /// @dev Mapping of an activity name in bytes to its data
    mapping(bytes32 => ActivityData) public _activityData;

    /// @dev Explanation:
    // token_type => token_id => packed TokenData
    // uint16 current power amount #1 (energy)
    // uint16 current power amount #2 (comfort)
    // uint16 current power amount #3 (playfulness)
    // uint16 current power amount #4 (social)
    // uint64 timestamp
    // uint128 activityId
    mapping(bytes32 => mapping(uint256 => uint256)) public _tokenActivityData;

    /// @notice Emitted when a new token type is set
    /// @param tokenType - Name of token type in bytes32
    event LogSetTokenType(bytes32 tokenType);

    /// @notice Emitted when a token type is removed
    /// @param tokenType - Name of token type in bytes32
    event LogRemoveTokenType(bytes32 tokenType);

    /// @notice Emitted when new activity is added
    /// @param activityData - Activity data struct
    event LogAddActivity(ActivityData activityData);

    /// @notice Emitted when stage bonus changes
    /// @param petStageBonus - Type of activity in uint16[]
    event LogEditPetStageBonuses(bytes32 activityType, uint256[] petStageBonus);

    /// @notice Emitted when an activity's allowance is set
    /// @param activityType - Type of activity in bytes32
    /// @param newEnergy - Energy consumed by a given activity
    event LogEditActivityEnergy(bytes32 activityType, uint16[] newEnergy);

    /// @notice Emitted when an activity's state is paused or reactivated
    /// @param activityType - Type of activity in bytes32
    /// @param isPaused - Status of activity
    event LogEditActivityPaused(bytes32 activityType, bool isPaused);

    /// @notice Emitted when activity is removed
    /// @param activityType - Type of activity in bytes32
    event LogRemoveActivity(bytes32 activityType);

    /// @notice Emitted when a token's activity count is updated
    /// @param activityType - Name of activity in bytes32
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    event LogUpdateTokenActivity(bytes32 activityType, bytes32 tokenType, uint256 tokenId);

    /// @notice Emitted when a token is boosted
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    /// @param itemTokenIds - Array of token ids of the items which are burnt
    /// @param energyBoost - The boost which was applied
    event LogTokenBoostedWithItem(
        address user,
        bytes32 tokenType,
        uint256 tokenId,
        uint256[] itemTokenIds,
        uint256 energyBoost
    );

    /// @notice Emitted when the ItemFactory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryContractAddress(address itemFactoryContractAddress);

    /// @notice Emitted when the EnergyLEvel contract address is updated
    /// @param energyLevelContractAddress - Energy Level contract address
    event LogSetEnergyLevelContractAddress(address energyLevelContractAddress);

    constructor(
        address systemCheckerContractAddress,
        address itemFactoryContractAddress,
        address energyLevelContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        /// @dev To be compatible with pets & cats immediately
        _tokenTypeSet.insert(PET_TOKEN);
        _tokenTypeSet.insert(CAT_TOKEN);

        /// @dev Item factory variables
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        /// @dev Energy level variables
        _energyLevelContractAddress = energyLevelContractAddress;
        _energyLevel = IEnergyLevel(energyLevelContractAddress);
    }

    /// @notice Checks if an activity exists
    /// @param activityType - Name of activity in bytes32
    modifier activityExists(bytes32 activityType) {
        require(_activityData[activityType].id > 0, "AO 400 - Activity doesn't exist");
        _;
    }

    /// @notice Checks if a token type exists
    /// @param tokenType - Name of token type in bytes32
    modifier tokenTypeExists(bytes32 tokenType) {
        require(_tokenTypeSet.exists(tokenType), "AO 401 - Token type doesn't exist");
        _;
    }

    /// @notice Updates the token's activity
    /// @dev checks that activityType exists
    /// @dev checks that tokenType exists
    /// @dev checks that midnightTime to log does not exceed block.timestamp to avoid updating past entries
    /// @dev checks if the requested activity to update against can be done by the token - read details in function
    /// @param reqActivityType - Name of activity in bytes32
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    function updateTokenActivity(
        bytes32 reqActivityType,
        bytes32 tokenType,
        uint256 tokenId
    ) public activityExists(reqActivityType) tokenTypeExists(tokenType) onlyRole(CONTRACT_ROLE) {
        ActivityData memory reqActivityData = _activityData[reqActivityType];

        /// @dev Check if activity is paused
        require(_activityData[reqActivityType].paused == false, 'AO 100 - Activity is paused');

        /// @dev Unpack token activity data for the requested token based on its type and id
        (
            uint64 packedCurrentTokenPower,
            uint64 lastActivityTimestamp,
            uint128 lastActivityId
        ) = unpackTokenActivityData(tokenType, tokenId);

        /// @dev Three necessary checks here:
        /// 1. Check if an activity can be carried out first based on IDs (not energy considerations yet), require true
        /// 2. If token is able to do the activity based on ID, check timestamp, if new day, replenish a token's energy to max
        /// 3. Finally, check token's power level against activity's power requirement

        /// @dev 1. Check if token's latest activity will allow requested activity to be done solely on activity ids
        require(
            _canDoActivityById(reqActivityData.id, lastActivityTimestamp, lastActivityId),
            'AO 101 - Unable to start activity'
        );

        /// @dev 2. Check timestamp
        /// @dev If token has not done any activities yet, fetch the default max energy
        /// @dev or reset energy due to midnight
        if (lastActivityId == 0 || lastActivityTimestamp < getCurrentMidnight()) {
            packedCurrentTokenPower = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        /// @dev 3. Check current power vs required
        bool isSufficientEnergy = true;
        uint64 remainingPackedTokenPower;

        /// @dev Requesting OFF PA on a new day, the token's energy needs to be drained (reduced by the required energy).
        /// @dev This needs to happen to ensure that users aren't able to double MILK. eg:
        /**
            - Day 1 = STAKE >> Consumes 100 Energy >> Token 0
            - Day 7 = UNSTAKE >> Consumes 100 Energy >> Token 0
            - Day 7 = Quest >> Not enough energy to Quest
        **/

        /// @dev  Token has requested the OFF PA for the current ON PA
        if (_isReqActivityOFF(reqActivityData.id)) {
            /// @dev If request is on the same day than don't deduct - it is already drained from doing the ON PA today
            /// @dev otherwise, token will not have enough power to do the OFF PA on the same day it did the ON PA
            remainingPackedTokenPower = packedCurrentTokenPower;

            /// @dev If token did ON PA on day 1 and then OFF PA on day 2, we have to ensure that OFF PA drains the energy
            /// @dev as the OFF PA spans multiple days
            /// @dev eg. STAKING on day 1, UNSTAKING on day 2 should drain the required energy of UNSTAKING
            if (lastActivityTimestamp < getCurrentMidnight()) {
                remainingPackedTokenPower -= reqActivityData.packedEnergyConsumption;
            }
        }
        /// @dev Token has requested a QA or has no activity history and requested an ON PA
        else {
            /// @dev Checks if token has sufficient energy and returns its remaining energy after deductions
            (
                isSufficientEnergy,
                remainingPackedTokenPower
            ) = _isSufficientEnergyAndGetRemainingEnergy(
                packedCurrentTokenPower,
                reqActivityData.packedEnergyConsumption
            );
        }

        /// @dev If token does not have sufficient energy, revert
        require(isSufficientEnergy, 'AO 102 - Not enough energy');

        ///@dev If token has sufficient energy, pack and save data in a single write :)
        pack(
            tokenType,
            tokenId,
            remainingPackedTokenPower,
            uint64(block.timestamp),
            reqActivityData.id
        );

        emit LogUpdateTokenActivity(reqActivityType, tokenType, tokenId);
    }

    /// @notice Check if a token can start an activity and accounts for energy level as well
    /// @param reqActivityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
    /// @return result - Boolean if token can do the requested activity
    function canDoActivity(
        bytes32 reqActivityType,
        bytes32 tokenType,
        uint256 tokenId
    )
        external
        view
        activityExists(reqActivityType)
        tokenTypeExists(tokenType)
        returns (bool result)
    {
        ActivityData memory reqActivityData = _activityData[reqActivityType];

        /// @dev Activity is paused
        if (_activityData[reqActivityType].paused == true) return false;

        /// @dev unpack TokenData
        (uint64 energy, uint64 timestamp, uint128 lastActivityId) = unpackTokenActivityData(
            tokenType,
            tokenId
        );

        /// @dev Four checks requires here
        /// @dev 1. Check if activity can be done based on ID alone
        /// @dev 2. Check against timestamp
        /// @dev 3. Check if its an OFF PA
        /// @dev 4. Check against power

        /// @dev 1. Check if activity can be done based on ID
        result = _canDoActivityById(reqActivityData.id, timestamp, lastActivityId);

        /// @dev Exit early and save gas
        if (!result) return false;

        /// @dev 2. Check against timestamp
        /// @dev At this point, the token has not been checked against its power yet
        /// @dev If token has no activity history, or 1 day elapsed since the last, re-charge its activity
        if (lastActivityId == 0 || timestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        /// @dev 3. Check if it an OFF PA
        /// @dev If activity is an OFF PA but not the same as current ON PA, result will be false
        if (_isReqActivityOFF(reqActivityData.id)) return true;

        /// @dev 4. Check against power
        (result, ) = _isSufficientEnergyAndGetRemainingEnergy(
            energy,
            reqActivityData.packedEnergyConsumption
        );
    }

    /// @notice Check if a token can start an activity
    /// @notice Same as canDoActivity but also returns a reason index if result is false for backend
    /// @param reqActivityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
    /// @return result - bool, Bool if activity is doable
    /// @return reason - uin256, If false bool is false data packed reason (first byte is a simple ENUM reason, next 128bit is the activity causing the conflict)
    function canDoActivityForBackend(
        bytes32 reqActivityType,
        bytes32 tokenType,
        uint256 tokenId
    )
        external
        view
        activityExists(reqActivityType)
        tokenTypeExists(tokenType)
        returns (bool result, uint8 reason)
    {
        ActivityData memory reqActivityData = _activityData[reqActivityType];

        /// @dev req. activity is paused
        if (_activityData[reqActivityType].paused == true) {
            return (false, uint8(REASON.PAUSED));
        }

        /// @dev unpack TokenData
        (uint64 energy, uint64 timestamp, uint128 lastActivityId) = unpackTokenActivityData(
            tokenType,
            tokenId
        );

        /// @dev Four checks requires here
        /// @dev 1. Check if activity can be done based on ID alone
        /// @dev 2. Check against timestamp
        /// @dev 3. Check if its an OFF PA
        /// @dev 4. Check against power

        /// @dev 1. Check if activity can be done based on ID and get tuple reason
        (result, reason) = _canDoActivityByIdTuple(reqActivityData.id, timestamp, lastActivityId);

        /// @dev exit early and save gas
        if (!result) return (false, reason);

        /// @dev 2. Check against timestamp
        /// @dev At this point, the token has not been checked against its power yet
        /// @dev If token has no activity history, or 1 day elapsed since the last, re-charge its activity
        if (lastActivityId == 0 || timestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        /// @dev 3. Check if its an OFF PA
        /// @dev If activity consumes no energy, return true
        if (_isReqActivityOFF(reqActivityData.id)) return (true, uint8(REASON.NONE));

        /// @dev 4. Check against power
        (result, ) = _isSufficientEnergyAndGetRemainingEnergy(
            energy,
            reqActivityData.packedEnergyConsumption
        );

        if (result == false) reason = uint8(REASON.NOT_ENOUGH_ENERGY);
    }

    /** INTERNAL */

    /// @notice Check if an activity is an OFF PA
    /// @dev Was used on multiple places so best to have a common function
    /// @param reqActivityId - Id of activity being requested
    /// @return bool - Returns true if activity is an OFF PA
    function _isReqActivityOFF(uint128 reqActivityId) internal pure returns (bool) {
        return ((reqActivityId % 2 == 0) && (reqActivityId > PA_THRESHOLD));
    }

    /// @notice Check if a token can start an activity without considering energy levels
    /// @param reqActivityId - Id of activity being requested
    /// @param lastActivityTimestamp - Timestamp of current activity
    /// @param lastActivityId - Id of current activity
    /// @return bool - Boolean of true if activity is doable (excluding energy consumption) false otherwise
    function _canDoActivityById(
        uint128 reqActivityId,
        uint64 lastActivityTimestamp,
        uint128 lastActivityId
    ) internal pure returns (bool) {
        /// @dev Three scenario checks necessary here:
        /// @dev 1. Token has never done any activity before - also handle if requested activity is an OFF PA
        /// @dev 2. Token has done an activity before and is requesting to do a QA now
        /// @dev 3. Token has done an activity before and is requesting to do another PA now

        /// @dev Identify if request activity is an OFF PA
        /// @dev xxxxx1 = On
        /// @dev xxxxx2 = Off
        bool reqOff = (reqActivityId > PA_THRESHOLD && reqActivityId % 2 == 0);

        /// @dev 1. Never done any activity
        /// @dev If last activity timestamp is 0, token has never done any activity before
        if (lastActivityTimestamp == 0) {
            /// @dev If an OFF PA is requested -> return false as token has to do an ON PA first to do an OFF PA
            if (reqOff) return false;

            /// @dev Accept because this has no activity at all
            return true;
        }

        /// @dev 2. Requesting a QA
        /// @dev If requested activity id is lower than the PA_THRESHOLD, it is a QA
        if (reqActivityId < PA_THRESHOLD) {
            /// @dev Token is not currently not doing a PA
            if (lastActivityId < PA_THRESHOLD) return true;

            /// @dev If the last activity is an OFF PA, it is allowed to do a QA
            if (lastActivityId % 2 == 0) return true;

            /// @dev Token is current doing an ON PA so it cannot do a QA
            return false;
        }

        /// @dev 3. Requesting another PA
        /// @dev Current state is OFF
        if (lastActivityId % 2 == 0) {
            /// @dev Currently OFF and request an ON from same PA
            if (reqActivityId + 1 == lastActivityId) return true;

            /// @dev Currently OFF and requesting OFF
            /// @dev Can never have OFF then OFF PA
            if (reqOff) return false;

            /// @dev Currently OFF and requesting ON
            /// @dev This passes but will subsequently will be checked against its energy,
            /// @dev because energy will be 0 if the OFF was done on that same day but
            /// @dev token might have replenished its energy if it's on the next day
            return true;
        }

        /// @dev Currently ON and req OFF for same PA
        if (lastActivityId + 1 == reqActivityId) {
            // Check if diff day, if so consume the same energy as for the ON
            return true;
        }

        /// @dev Currently ON and req OFF for different PA
        return false;
    }

    /// @notice Check if a token can start an activity based solely on activity ID
    /// @dev Functionally the same as _canDoActivityById but to save gas internal updateTokenActivity does not
    /// @dev Refer to _canDoActivityById for details
    /// @dev necessarily need to know the fail reason, while backend does so it returns info on it
    /// @param reqActivityId - Id of activity being requested
    /// @param lastActivityTimestamp - Timestamp of current activity
    /// @param lastActivityId - Id of current activity
    /// @return (bool, uint8) - Bool if activity is doable and (data packed) reason if not (first byte is a simple ENUM reason)
    function _canDoActivityByIdTuple(
        uint128 reqActivityId,
        uint64 lastActivityTimestamp,
        uint128 lastActivityId
    ) internal pure returns (bool, uint8) {
        /// @dev xxxxx1 = On
        /// @dev xxxxx2 = Off
        bool reqOff = (reqActivityId > PA_THRESHOLD && reqActivityId % 2 == 0);

        /// @dev Never done an activity
        /// @dev If last activity timestamp is 0, token has never done any activity before
        if (lastActivityTimestamp == 0) {
            /// @dev If an OFF PA is requested -> return false as token has to do an ON PA first to do an OFF PA
            if (reqOff == true) return (false, uint8(REASON.REQUEST_OFF_WHILE_OFF));

            /// @dev Accept because this has no activity at all
            return (true, uint8(REASON.NONE));
        }

        /// @dev Requesting a QA
        if (reqActivityId < PA_THRESHOLD) {
            /// @dev not currently in a PA
            if (lastActivityId < PA_THRESHOLD) return (true, uint8(REASON.NONE));

            /// @dev PA is in OFF state
            if (lastActivityId % 2 == 0) return (true, uint8(REASON.NONE));

            /// @dev PA is in ON state
            return (false, uint8(REASON.PA_ON));
        }

        /// @dev requesting another PA state
        /// @dev Current state is OFF
        if (lastActivityId % 2 == 0) {
            /// @dev Currently OFF and req, ON from same PA
            if (reqActivityId + 1 == lastActivityId) return (true, uint8(REASON.NONE));

            /// @dev Currently OFF and requesting OFF
            /// @dev Can never have OFF then OFF PA
            if (reqOff) return (false, uint8(REASON.REQUEST_OFF_WHILE_OFF));

            /// @dev Currently OFF and requesting ON
            /// @dev This passes but will subsequently will be checked against its energy,
            /// @dev because energy will be 0 if the OFF was done on that same day but
            /// @dev token might have replenished its energy if it's on the next day
            return (true, uint8(REASON.NONE));
        }

        /// @dev Currently ON and req OFF for same PA
        if (lastActivityId + 1 == reqActivityId) {
            /// @dev Check if diff day, if so consume the same energy as for the ON
            return (true, uint8(REASON.NONE));
        }

        /// @dev Currently ON a PA and req is an ON / OFF for different PA
        return (false, uint8(REASON.PA_ON));
    }

    /// @notice Pack token activity data
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @param energy - Energy of token
    /// @param timestamp - Timestamp activity started
    /// @param activityId - Id of current activity
    function pack(
        bytes32 tokenType,
        uint256 tokenId,
        uint64 energy,
        uint64 timestamp,
        uint128 activityId
    ) internal {
        uint256 packedData = uint256(uint64(energy));
        packedData |= uint256(timestamp) << 64;
        packedData |= uint256(activityId) << 128;
        _tokenActivityData[tokenType][tokenId] = packedData;
    }

    /// @notice Unpack token activity data
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return [uint64, uint64, uint128] - Energy, Timestamp, activity id
    function unpackTokenActivityData(bytes32 tokenType, uint256 tokenId)
        internal
        view
        returns (
            uint64,
            uint64,
            uint128
        )
    {
        uint256 data = _tokenActivityData[tokenType][tokenId];
        return (
            uint64(data), /// @dev energy: represents 4 diff energy types X 16 uint value
            uint64(data >> 64), /// @dev timestamp
            uint128(data >> 128) /// @dev activity id
        );
    }

    /// @notice Pack array of energy consumption into a uint64
    /// @param energyConsumption - uint16[] of powers' energy consumption
    /// @return uint64 - The packed power levels
    function _packEnergy(uint16[] calldata energyConsumption) internal pure returns (uint64) {
        uint64 packedEnergyConsumption = uint64(energyConsumption[0]);
        packedEnergyConsumption |= uint64(energyConsumption[1]) << 16;
        packedEnergyConsumption |= uint64(energyConsumption[2]) << 32;
        packedEnergyConsumption |= uint64(energyConsumption[3]) << 48;

        return packedEnergyConsumption;
    }

    /// @notice Internal function which checks if the current token's energy is enough to do the requested activity and if so
    /// @notice deducts from the number
    /// @param tokenEnergy - The actual energy level of the token
    /// @param requiredEnergy - The required energy to be able to proceed further
    /// @return sufficientEnergy - Boolean if token has enough energy
    /// @return remainingValue - uint64, How much the new energy value shall be for that token
    function _isSufficientEnergyAndGetRemainingEnergy(uint64 tokenEnergy, uint64 requiredEnergy)
        internal
        pure
        returns (bool sufficientEnergy, uint64 remainingValue)
    {
        if (tokenEnergy == 0) return (false, 0);

        uint16 energy_1 = uint16(tokenEnergy);
        uint16 energy_2 = uint16(tokenEnergy >> 16);
        uint16 energy_3 = uint16(tokenEnergy >> 32);
        uint16 energy_4 = uint16(tokenEnergy >> 48);

        uint16 energy_req1 = uint16(requiredEnergy);
        uint16 energy_req2 = uint16(requiredEnergy >> 16);
        uint16 energy_req3 = uint16(requiredEnergy >> 32);
        uint16 energy_req4 = uint16(requiredEnergy >> 48);

        if (
            energy_1 >= energy_req1 &&
            energy_2 >= energy_req2 &&
            energy_3 >= energy_req3 &&
            energy_4 >= energy_req4
        ) {
            return (true, (tokenEnergy - requiredEnergy));
        }
    }

    /** GETTERS */

    /// @notice Returns the energy for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - The packed power levels of a token
    function getPackedEnergy(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint64)
    {
        (uint64 energy, , uint128 lastActivityId) = unpackTokenActivityData(tokenType, tokenId);

        //Has not done any activity yet return default '100' or '200'
        if (lastActivityId == 0) return uint64(_energyLevel.getPackedMaxEnergy(tokenType));

        return energy;
    }

    /// @notice Returns the energy for a given token as an array
    /// @dev Currently returns an array of 4 uint16 energy levels
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return result - Array of power levels for energy, comfort, playfulness, social
    function getUnpackedEnergy(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint16[4] memory result)
    {
        (uint64 energy, , uint128 lastActivityId) = unpackTokenActivityData(tokenType, tokenId);

        //Has not done any activity yet return default '100' or '200'
        if (lastActivityId == 0) energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));

        result[0] = uint16(energy);
        result[1] = uint16(energy >> 16);
        result[2] = uint16(energy >> 32);
        result[3] = uint16(energy >> 48);
    }

    /// @notice Returns the energy for a given token as an array taking into consideration midnight
    /// @dev Currently returns an array of 4 uint16 energy levels
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return result - Array of power levels for energy, comfort, playfulness, social
    function getUnpackedEnergyWithTimeCheck(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint16[4] memory result)
    {
        // unpack token data
        (uint64 energy, uint64 timestamp, uint128 lastActivityId) = unpackTokenActivityData(
            tokenType,
            tokenId
        );

        // token recharged or never used - max energy
        if (lastActivityId == 0 || timestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        result[0] = uint16(energy);
        result[1] = uint16(energy >> 16);
        result[2] = uint16(energy >> 32);
        result[3] = uint16(energy >> 48);
    }

    /// @notice Returns the timestamp for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - Timestamp
    function getLastActivityTimestamp(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint64)
    {
        (, uint64 timestamp, ) = unpackTokenActivityData(tokenType, tokenId);
        return timestamp;
    }

    /// @notice Returns the last activity id for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint128 - Activity id
    function getLastActivityId(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint128)
    {
        (, , uint128 activityId) = unpackTokenActivityData(tokenType, tokenId);
        return activityId;
    }

    /// @notice Returns the unpacked energy consumption for an activity type
    /// @param activityType - Name of activity in bytes
    /// @return uint16[4] - Array of power levels for energy, comfort, playfulness, social
    function getActivityEnergyConsumption(bytes32 activityType)
        external
        view
        activityExists(activityType)
        returns (uint16[4] memory)
    {
        uint64 packedEnergyConsumption = _activityData[activityType].packedEnergyConsumption;

        uint16[4] memory unpacked = [
            uint16(packedEnergyConsumption),
            uint16(uint64(packedEnergyConsumption) >> 16),
            uint16(uint64(packedEnergyConsumption) >> 32),
            uint16(uint64(packedEnergyConsumption) >> 48)
        ];

        return unpacked;
    }

    /// @notice Returns if the activity is paused or not
    /// @param activityType - Name of activity in bytes
    /// @return bool - True if paused, false if not
    function isActivityPaused(bytes32 activityType)
        external
        view
        activityExists(activityType)
        returns (bool)
    {
        return _activityData[activityType].paused;
    }

    /// @notice Returns the daily reset time
    /// @return uint256 - The daily reset time
    function getCurrentMidnight() public view returns (uint256) {
        return START + ((((block.timestamp - START) / DAY_IN_SECONDS)) * DAY_IN_SECONDS);
    }

    /// @notice Returns the Id of the given activity
    /// @dev 0 means not possible to match cause ID starts from 1
    /// @param activityType - Type of activity (QUEST, STAKE, etc.)
    /// @return uint128 - The activity's id
    function getIdFromActivity(bytes32 activityType)
        external
        view
        activityExists(activityType)
        returns (uint128)
    {
        return _activityData[activityType].id;
    }

    /// @notice Get the bonuses given for questing for different pet stages
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @param activityType - Type of activity (QUEST, STAKE, etc.)
    /// @return uint256[] - Array of the current pet stage bonuses
    function getPetStageBonus(bytes32 activityType)
        external
        view
        activityExists(activityType)
        returns (uint256[] memory)
    {
        return _activityData[activityType].petStageBonus;
    }

    /** SETTERS */

    /// @notice Boost a pet/cat with respective energies - data coming from Energy Level Contract
    /// @dev Only takes calls from the system
    /// @dev burnItem() handles the revert if user has not enough item balance
    /// @param user - Address of user performing the interaction
    /// @param tokenType - Type of token to check (cat, pet , etc.)
    /// @param tokenId - The tokenId of the pet being interacted with
    /// @param itemTokenIds - Array of ids of the items being used in the interaction in uint256
    function boostEnergy(
        address user,
        bytes32 tokenType,
        uint256 tokenId,
        uint256[] calldata itemTokenIds
    ) external onlyRole(GAME_ROLE) {
        uint256 energyBoost;
        for (uint256 index; index < itemTokenIds.length; ) {
            /// @dev Burn permissions is checked in ItemFactory
            _itemFactory.burnItem(user, itemTokenIds[index], 1);

            energyBoost += _energyLevel.getPackedEnergiesByItem(itemTokenIds[index]);

            unchecked {
                index++;
            }
        }

        _tokenActivityData[tokenType][tokenId] += energyBoost;

        emit LogTokenBoostedWithItem(user, tokenType, tokenId, itemTokenIds, energyBoost);
    }

    /// @notice Sets a new token type
    /// @param tokenType - Name of tokenType in bytes32
    function setTokenType(bytes32 tokenType) external onlyRole(ADMIN_ROLE) {
        _tokenTypeSet.insert(tokenType);

        emit LogSetTokenType(tokenType);
    }

    /// @notice Removes an existing token type
    /// @dev CrudKeySet handles the exist() check
    /// @param tokenType - Name of tokenType in bytes32
    function removeTokenType(bytes32 tokenType) external onlyRole(ADMIN_ROLE) {
        _tokenTypeSet.remove(tokenType);

        emit LogRemoveTokenType(tokenType);
    }

    /// @notice Add a new activity
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @dev PA activities start from 10000
    /// @param newActivityType - Type of activity in bytes32
    /// @param newActivityId - Id of activity
    /// @param energyConsumption - uint16[] of powers' energy consumption
    /// @param paused - Paused state for activity
    /// @param petStageBonuses - Array of bp values, eg; [0, 500, 1000, 1000]
    function addActivity(
        bytes32 newActivityType,
        uint128 newActivityId,
        uint16[] calldata energyConsumption,
        bool paused,
        uint256[] calldata petStageBonuses
    ) external onlyRole(ADMIN_ROLE) {
        /// @dev id == 0 means activity does not exist yet
        require(_activityData[newActivityType].id == 0, 'AO 103 - Activity exist');
        require(petStageBonuses.length == 4, 'AO 104 - Stage bonus length shall be 4');

        _activityData[newActivityType] = ActivityData(
            newActivityId,
            paused,
            _packEnergy(energyConsumption),
            petStageBonuses
        );

        emit LogAddActivity(_activityData[newActivityType]);
    }

    /// @notice Set the bonuses given for questing for different pet stages
    /// @dev All values should be basis points 1 = 0.01%, 100 = 1%
    /// @param activityType - Type of activity in bytes32
    /// @param petStageBonus - Array of bp values, eg; [0, 500, 1000, 1000]
    function editPetStageBonus(bytes32 activityType, uint256[] memory petStageBonus)
        external
        activityExists(activityType)
        onlyRole(ADMIN_ROLE)
    {
        _activityData[activityType].petStageBonus = petStageBonus;

        emit LogEditPetStageBonuses(activityType, petStageBonus);
    }

    /// @notice Sets an activity's state if paused or not
    /// @param activityType - Type of activity in bytes32
    /// @param isPaused - If an activity shall be paused or not
    function editActivityPaused(bytes32 activityType, bool isPaused)
        public
        activityExists(activityType)
        onlyRole(ADMIN_ROLE)
    {
        _activityData[activityType].paused = isPaused;

        emit LogEditActivityPaused(activityType, isPaused);
    }

    /// @notice Sets an activity's energy consumption
    /// @param activityType - Type of activity in bytes32
    /// @param energyConsumption - uint16[] of powers' energy consumption
    function editEnergyConsumption(bytes32 activityType, uint16[] calldata energyConsumption)
        public
        activityExists(activityType)
        onlyRole(ADMIN_ROLE)
    {
        _activityData[activityType].packedEnergyConsumption = _packEnergy(energyConsumption);

        emit LogEditActivityEnergy(activityType, energyConsumption);
    }

    /// @notice Remove an activity type
    /// @dev Should only be used while preparing activities, not once they are live
    /// @param activityType - Type of activity in bytes32
    function removeActivity(bytes32 activityType)
        external
        activityExists(activityType)
        onlyRole(ADMIN_ROLE)
    {
        delete _activityData[activityType];

        emit LogRemoveActivity(activityType);
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _itemFactory = IItemFactory(itemFactoryContractAddress);

        emit LogSetItemFactoryContractAddress(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Energy Level Contract
    /// @param energyLevelContractAddress - Address of the Energy Level
    function setEnergyLevelContractAddress(address energyLevelContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _energyLevelContractAddress = energyLevelContractAddress;
        _energyLevel = IEnergyLevel(energyLevelContractAddress);

        emit LogSetEnergyLevelContractAddress(energyLevelContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/
// Edited to suit our needs

library CrudKeySetLib {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, 'UnorderedKeySet 100 - Key cannot be 0x0');
        require(!exists(self, key), 'UnorderedKeySet 101 - Key already exists in the set.');
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), 'UnorderedKeySet 102 - Key does not exist in the set.');
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint256 index) internal view returns (bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) internal {
        for (uint256 i; i < self.keyList.length; i++) {
            delete self.keyPointers[self.keyList[i]];
        }
        delete self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISystemChecker.sol';
import './RolesAndKeys.sol';

contract HSystemChecker is RolesAndKeys {
    ISystemChecker _systemChecker;
    address public _systemCheckerContractAddress;

    constructor(address systemCheckerContractAddress) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }

    /// @notice Check if an address is a registered user or not
    /// @dev Triggers a require in systemChecker
    modifier isUser(address user) {
        _systemChecker.isUser(user);
        _;
    }

    /// @notice Check that the msg.sender has the desired role
    /// @dev Triggers a require in systemChecker
    modifier onlyRole(bytes32 role) {
        require(_systemChecker.hasRole(role, _msgSender()), 'SC: Invalid transaction source');
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IItemFactory {
    function burnItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function mintItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function gameSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function getItemById(uint256 itemTokenId)
        external
        returns (bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnergyLevel {
    /// @notice Set an item's energy level
    /// @param itemTokenId - Item token id being set (item's id from ItemFactory)
    /// @param energyLevels - Array of energy level of an an item
    function setItemEnergyLevel(uint256 itemTokenId, uint16[] calldata energyLevels) external;

    /// @notice Set an item's max energy level
    /// @param tokenType - Token type being set
    /// @param maxEnergy - Max energy level for the token type
    function setTokenMaxEnergy(bytes32 tokenType, uint16[] calldata maxEnergy) external;

    /// @notice Set the current max energy count
    /// @param newMaxEnergyCount - New max energy count to set
    function setTokenMaxEnergyCount(uint256 newMaxEnergyCount) external;

    /// @notice Gets an item's energy levels by its token id
    /// @param itemTokenId - Item token id requested (item's id from ItemFactory)
    function getPackedEnergiesByItem(uint256 itemTokenId) external view returns (uint64);

    /// @notice Gets an item's energy levels by its token id
    /// @param tokenType - Token type being requested in bytes
    function getPackedMaxEnergy(bytes32 tokenType) external view returns (uint64);

    /// @notice Gets an item's energy levels by its token id
    /// @param itemTokenId - Item token id requested
    /// @return energyLevel1 - Energy Level 1 in uint16
    /// @return energyLevel2 - Energy Level 2 in uint16
    /// @return energyLevel3 - Energy Level 3 in uint16
    /// @return energyLevel4 - Energy Level 4 in uint16
    function getUnpackedEnergiesByItem(uint256 itemTokenId)
        external
        view
        returns (
            uint16 energyLevel1,
            uint16 energyLevel2,
            uint16 energyLevel3,
            uint16 energyLevel4
        );

    /// @notice Gets an item's energy levels by its token id
    /// @param tokenType - Token type being requested in bytes
    /// @return energyLevel1 - Energy Level 1 in uint16
    /// @return energyLevel2 - Energy Level 2 in uint16
    /// @return energyLevel3 - Energy Level 3 in uint16
    /// @return energyLevel4 - Energy Level 4 in uint16
    function getUnpackedMaxEnergy(bytes32 tokenType)
        external
        view
        returns (
            uint16 energyLevel1,
            uint16 energyLevel2,
            uint16 energyLevel3,
            uint16 energyLevel4
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /**
     * @dev mostly lifted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    /**
     * @inheritdoc IMulticall
     * @dev does a basic multicall to any function on this contract
     */
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        override
        returns (bytes[] memory returning)
    {
        returning = new bytes[](data.length);
        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
            returning[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemChecker {
    function createNewRole(bytes32 role) external;

    function hasRole(bytes32 role, address account) external returns (bool);

    function hasPermission(bytes32 role, address account) external;

    function isUser(address user) external;

    function getSafeAddress(bytes32 key) external returns (address);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract RolesAndKeys is Context {
    // ROLES
    bytes32 constant MASTER_ROLE = keccak256('MASTER_ROLE');
    bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 constant GAME_ROLE = keccak256('GAME_ROLE');
    bytes32 constant CONTRACT_ROLE = keccak256('CONTRACT_ROLE');
    bytes32 constant TREASURY_ROLE = keccak256('TREASURY_ROLE');

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256('MARKETPLACE');
    bytes32 constant SYSTEM_KEY_BYTES = keccak256('SYSTEM');
    bytes32 constant QUEST_KEY_BYTES = keccak256('QUEST');
    bytes32 constant BATTLE_KEY_BYTES = keccak256('BATTLE');
    bytes32 constant HOUSE_KEY_BYTES = keccak256('HOUSE');
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256('QUEST_GUILD');

    // COMMON
    bytes32 public constant PET_BYTES =
        0x5065740000000000000000000000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        returns (bytes[] memory results);
}