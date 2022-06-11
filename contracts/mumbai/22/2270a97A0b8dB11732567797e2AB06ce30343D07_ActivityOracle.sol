// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../system/CrudKeySet.sol';
import '../system/HSystemChecker.sol';
import '../items/IItemFactory.sol';
import './IEnergyLevel.sol';
import '../../common/Multicall.sol';

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

    /// @dev Activity -> persistent activity threshold ID (from above the id represent a persistent activity)
    uint16 public constant PA_THRESHOLD = 10000;

    /// @dev Activity types in bytes
    bytes32 constant QUEST = keccak256('QUEST');
    bytes32 constant STAKING = keccak256('STAKING');
    bytes32 constant UNSTAKING = keccak256('UNSTAKING');

    /// @dev Token types in bytes
    bytes32 constant CAT_TOKEN = keccak256('CAT');
    bytes32 constant PET_TOKEN = keccak256('PET');

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
        /// @dev packed uint16[16], currently only first 4 are used
        uint64 energyConsumption;
        uint256[] petStageBonus;
    }

    mapping(bytes32 => ActivityData) public _activityData;
    /// @dev Explanation:
    // token_type => token_id => packed TokenData
    // uint16 energyConsumption #1
    // uint16 energyConsumption #2
    // uint16 energyConsumption #3
    // uint16 energyConsumption #4
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
    /// @param newEnergy - Energy consumed by a give activity
    event LogEditActivityEnergy(bytes32 activityType, uint64 newEnergy);

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
    /// @param itemTokenId - Token id of the item which is burnt
    /// @param energyBoost - The boost whch was applied
    event LogTokenBoostedWithItem(
        address user,
        bytes32 tokenType,
        uint256 tokenId,
        uint256 itemTokenId,
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

    /// @notice Updates the token's activity count. In case an activity has mapped a persistent activity to it
    /// @notice then it also toggles the respective toggle switch.
    /// @dev checks that activityType exists
    /// @dev checks that tokenType exists
    /// @dev checks that midnightTime to log does not exceed block.timestamp to avoid updating past entries
    /// @param reqActivityType - Name of activity in bytes32
    /// @param tokenType - Type of token id
    /// @param tokenId - Token id
    function updateTokenActivity(
        bytes32 reqActivityType,
        bytes32 tokenType,
        uint256 tokenId
    ) public activityExists(reqActivityType) tokenTypeExists(tokenType) onlyRole(CONTRACT_ROLE) {
        ActivityData memory reqActivityData = _activityData[reqActivityType];

        /// @dev Activity is paused
        require(_activityData[reqActivityType].paused == false, 'AO 100 - Activity is paused');

        /// @dev Unpack TokenData
        (uint64 energy, uint64 currentTimestamp, uint128 currentActivityId) = unpack(
            tokenType,
            tokenId
        );

        // ============================== //
        //   STEP 1 - Check activity IDs  //
        // ============================== //
        /// @dev Check is current activity will allow for req. activity base solely on activity ids
        require(
            _canDoActivity(reqActivityData.id, currentTimestamp, currentActivityId),
            'AO 101 - Unable to start activity'
        );

        // ============================== //
        //    STEP 2 - Check Timestamp    //
        // ============================== //
        /// @dev Not done any activities yet, default energy is 100
        /// @dev or reset energy due to midnight
        if (currentActivityId == 0 || currentTimestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        // =========================================== //
        //    STEP 3 - Check Timestamp vs PA ON/OFF    //
        // =========================================== //
        /// @dev check current energy vs required
        bool isSufficientEnergy = true;
        uint64 remainingTokenEnergy;

        /// @dev Requesting OFF for a PA on a new day the tokens energy needs to be drained to reflect that they have "UNSTAKED".
        /// @dev This needs to happen to ensure that users arent able to double Milk
        /**
            - Day 1 = STAKE >> Consumes 100 Energy >> Token 0
            - Day 7 = UNSTAKE >> Consumes 100 Energy >> Token 0
            - Day 7 = Quest >> Not enough energy to Quest
        */
        /// @dev  Token has requested a PA OFF for the current PA ON
        if (_isReqActivityOFF(reqActivityData.id)) {
            /// @dev If we are on the same day (so same day STAKE and UNSTAKE) than dont deduct
            remainingTokenEnergy = energy;

            /// @dev If token is STAKING on day 1 and then UNSTAKING on day 2, we have to ensure that UNSTAKING drains the energy
            /// @dev as the activity of STAKING spans multiple days
            if (currentTimestamp < getCurrentMidnight()) {
                remainingTokenEnergy -= reqActivityData.energyConsumption;
            }
        }
        /// @dev Token has requested a quick activity like QUEST
        /// @dev or token has no activity history and requested PA ON
        else {
            /// @dev Currently only 4 of the uint16 is used (=uint64) as 'energy' but maybe in the future there will be
            /// @dev more energy types, so that might require to change this code i.e. to uint128(energy) if we are handling 8 of them.
            /// @dev reqActivityData.energyConsumption is also a uint64, so that one has to be handled as well - in case of future updates.
            (isSufficientEnergy, remainingTokenEnergy) = _isSufficientEnergyAndGetRemainingEnergy(
                energy,
                reqActivityData.energyConsumption,
                (reqActivityData.id > PA_THRESHOLD)
            );
        }

        require(isSufficientEnergy, 'AO 102 - Not enough energy');

        /// @dev pack and save data in a single write :)
        pack(tokenType, tokenId, remainingTokenEnergy, uint64(block.timestamp), reqActivityData.id);

        emit LogUpdateTokenActivity(reqActivityType, tokenType, tokenId);
    }

    /// @notice Check if a token can start an activity
    /// @param reqActivityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
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
        (uint64 energy, uint64 timestamp, uint128 currentActivityId) = unpack(tokenType, tokenId);

        result = _canDoActivity(reqActivityData.id, timestamp, currentActivityId);

        /// @dev Exit early and save gas
        if (!result) return false;

        /// @dev If result is true, it does not necessarily means it CAN do, from energy point of view, so have to check that as well
        /// @dev If token has no activity history, or 1 day elapsed since the last, re-charge its activity
        if (currentActivityId == 0 || timestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        /// @dev If activity is a PA and the same as current PA just an OFF version (otherwise)
        /// @dev the result would already be false !! (cannot switch off a PA with another PA's off request)
        if (_isReqActivityOFF(reqActivityData.id)) return true;

        (result, ) = _isSufficientEnergyAndGetRemainingEnergy(
            energy,
            reqActivityData.energyConsumption,
            (reqActivityData.id > PA_THRESHOLD)
        );
    }

    /// @notice Check if a token can start an activity
    /// @param reqActivityType - Key for requested activity
    /// @param tokenType - Token type as key
    /// @param tokenId - Id of token
    /// return (bool, uint256) - Bool if activity is doable and (data packed) reason if not (first byte is a simple ENUM reason, next 128bit is the activity causing the conflict)
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
        (uint64 energy, uint64 timestamp, uint128 currentActivityId) = unpack(tokenType, tokenId);
        (result, reason) = _canDoActivityTuple(reqActivityData.id, timestamp, currentActivityId);

        /// @dev exit early and save gas
        if (!result) return (false, reason);

        /// @dev If result is true, it does not necessarily means it CAN do req. activity, from an energy point of view, so have to check that as well
        /// @dev If token has no activity history, or 1 day elapsed since the last, re-charge its energy
        if (currentActivityId == 0 || timestamp < getCurrentMidnight()) {
            energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));
        }

        /// @dev If activity consumes no energy, return true
        if (_isReqActivityOFF(reqActivityData.id)) return (true, uint8(REASON.NONE));

        (result, ) = _isSufficientEnergyAndGetRemainingEnergy(
            energy,
            reqActivityData.energyConsumption,
            (reqActivityData.id > PA_THRESHOLD)
        );

        if (result == false) reason = uint8(REASON.NOT_ENOUGH_ENERGY);
    }

    /** INTERNAL */

    /// @notice Check if an activity is an OFF & persistent
    /// @dev Was used on multiple places so best to have a common function
    /// @param reqActivityId - Id of activity being requested
    /// return bool - Returns true if activity is OFF and persistent
    function _isReqActivityOFF(uint128 reqActivityId) internal pure returns (bool result) {
        return ((reqActivityId % 2 == 0) && (reqActivityId > PA_THRESHOLD));
    }

    /// @notice Check if a token can start an activity
    /// @param reqActivityId - Id of activity being requested
    /// @param currentTimestamp - Timestamp of current activity
    /// @param currentActivityId - Id of current activity
    /// return bool - True if activity is doable (excluding energy consumption) false otherwise
    function _canDoActivity(
        uint128 reqActivityId,
        uint64 currentTimestamp,
        uint128 currentActivityId
    ) internal pure returns (bool) {
        /// @dev xxxxx1 = On
        /// @dev xxxxx2 = Off
        bool reqOff = (reqActivityId % 2 == 0);

        /// @dev Never done an activity
        if (currentTimestamp == 0) {
            /// @dev We have no data but if it is a persistent activity and requesting an OFF -> reuturn false
            if (reqActivityId > PA_THRESHOLD && reqOff == true) return false;

            /// @dev accept cause this has no activity at all
            return true;
        }

        /// @dev requesting a quick activity
        if (reqActivityId < PA_THRESHOLD) {
            /// @dev not currently in a PA
            if (currentActivityId < PA_THRESHOLD) return true;

            /// @dev PA is in OFF state
            if (currentActivityId % 2 == 0) return true;

            /// @dev PA is in ON state
            return false;
        }

        /// @dev requesting another PA state
        /// @dev Current state is OFF
        if (currentActivityId % 2 == 0) {
            /// @dev Currently OFF and req, ON from same PA
            if (reqActivityId + 1 == currentActivityId) return true;

            /// @dev Currently OFF and requesting OFF
            /// @dev Can never have OFF + OFF
            if (reqActivityId > PA_THRESHOLD && reqOff) return false;

            /// @dev Currently OFF and requesting ON -> It's ok for now,
            /// @dev because energy will be 0 if the OFF request was done on that same day OR
            /// @dev token might have energy
            return true;
        }

        /// @dev Currently ON and req OFF for same PA
        if (currentActivityId + 1 == reqActivityId) {
            // Check if diff day, if so consume the same energy as for the ON
            return true;
        }

        /// @dev Currently ON and req OFF for different PA
        return false;
    }

    /// @notice Check if a token can start an activity
    /// @dev Functionally the same as _canDoActivity but to save gas internal updateTokenActivity does not
    /// @dev necessarily need to know the fail reason, while backend does so it returns info on it
    /// @param reqActivityId - Id of activity being requested
    /// @param currentTimestamp - Timestamp of current activity
    /// @param currentActivityId - Id of current activity
    /// return (bool, uint8) - Bool if activity is doable and (data packed) reason if not (first byte is a simple ENUM reason)
    function _canDoActivityTuple(
        uint128 reqActivityId,
        uint64 currentTimestamp,
        uint128 currentActivityId
    ) internal pure returns (bool, uint8) {
        /// @dev xxxxx1 = On
        /// @dev xxxxx2 = Off
        bool reqOff = (reqActivityId % 2 == 0);

        /// @dev Never done an activity
        if (currentTimestamp == 0) {
            /// @dev We have no data but if it is a persistent activity and requesting an OFF -> reuturn false
            if (reqActivityId > PA_THRESHOLD && reqOff == true)
                return (false, uint8(REASON.REQUEST_OFF_WHILE_OFF));

            /// @dev accept cause this has no activity at all
            return (true, uint8(REASON.NONE));
        }

        /// @dev requesting a quick activity
        if (reqActivityId < PA_THRESHOLD) {
            /// @dev not currently in a PA
            if (currentActivityId < PA_THRESHOLD) return (true, uint8(REASON.NONE));

            /// @dev PA is in OFF state
            if (currentActivityId % 2 == 0) return (true, uint8(REASON.NONE));

            /// @dev PA is in ON state
            return (false, uint8(REASON.PA_ON));
        }

        /// @dev requesting another PA state
        /// @dev Current state is OFF
        if (currentActivityId % 2 == 0) {
            // Currently OFF and req, ON from same PA
            if (reqActivityId + 1 == currentActivityId) return (true, uint8(REASON.NONE));

            // Currently OFF and requesting OFF
            // Can never have OFF + OFF
            if (reqActivityId > PA_THRESHOLD && reqOff)
                return (false, uint8(REASON.REQUEST_OFF_WHILE_OFF));

            /// @dev Currntely OFF and requesting ON -> It's ok for now,
            /// @dev because energy will be 0 if the OFF request was done on that same day OR
            /// @dev token might have
            return (true, uint8(REASON.NONE));
        }

        /// @dev Currently ON and req OFF for same PA
        if (currentActivityId + 1 == reqActivityId) {
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
    function unpack(bytes32 tokenType, uint256 tokenId)
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

    /// @notice Internal function which checks if the current token's energy is enough to do the requested activity and if so
    /// @notice deducts from the number
    /// @param tokenEnergy - The actual energy level of the token
    /// @param requiredEnergy - The required energy to be able to proceed further
    /// @param isPA - Flag indicating if an activitiy is P or not
    /// return bool, uint64 - First return param indicates if token has enough energy second is about how much the new energy value shall be for that token
    function _isSufficientEnergyAndGetRemainingEnergy(
        uint64 tokenEnergy,
        uint64 requiredEnergy,
        bool isPA
    ) internal pure returns (bool sufficientEnergy, uint64 remainingValue) {
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
            return (true, isPA ? 0 : (tokenEnergy - requiredEnergy));
        }
    }

    /** GETTERS */

    /// @notice Returns the energy for a given token
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return uint64 - Energy
    function getPackedEnergy(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint64)
    {
        (uint64 energy, , uint128 currentActivityId) = unpack(tokenType, tokenId);

        //Has not done any activity yet return default '100' or '200'
        if (currentActivityId == 0) return uint64(_energyLevel.getPackedMaxEnergy(tokenType));

        return energy;
    }

    /// @notice Returns the energy for a given token as an array
    /// @dev Currently returns an array of 4 uint16 energy levels
    /// @param tokenType - Type of token to check
    /// @param tokenId - Id of token to check
    /// @return result - Energy
    function getUnpackedEnergy(bytes32 tokenType, uint256 tokenId)
        external
        view
        tokenTypeExists(tokenType)
        returns (uint16[4] memory result)
    {
        (uint64 energy, , uint128 currentActivityId) = unpack(tokenType, tokenId);

        //Has not done any activity yet return default '100' or '200'
        if (currentActivityId == 0) energy = uint64(_energyLevel.getPackedMaxEnergy(tokenType));

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
        (, uint64 timestamp, ) = unpack(tokenType, tokenId);
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
        (, , uint128 activityId) = unpack(tokenType, tokenId);
        return activityId;
    }

    /// @notice Returns the daily allowance for an activity type
    /// @param activityType - Name of activity in bytes
    /// @return unit128 - The daily allowed count for an activity
    function getActivityEnergyConsumption(bytes32 activityType)
        external
        view
        activityExists(activityType)
        returns (uint64)
    {
        return _activityData[activityType].energyConsumption;
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
    /// @return time - The daily reset time
    function getCurrentMidnight() public view returns (uint256) {
        return START + ((((block.timestamp - START) / DAY_IN_SECONDS)) * DAY_IN_SECONDS);
    }

    /// @notice Returns the Id of the given activity
    /// @dev 0 means not possible to match cause ID starts from 1
    /// @param activityType - Type of activity (QUEST, STAKE, etc.)
    /// @return id - The daily reset time
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
    /// @param itemTokenId - Id of the item being used in the interaction in uint256
    function boostEnergy(
        address user,
        bytes32 tokenType,
        uint256 tokenId,
        uint256 itemTokenId
    ) external onlyRole(GAME_ROLE) {
        /// @dev Burn permissions is checked in ItemFactory
        _itemFactory.burnItem(user, itemTokenId, 1);

        uint256 energyBoost = _energyLevel.getPackedEnergiesByItem(itemTokenId);

        /// @dev Get current energy per given token type & id and boost its energy level
        uint256 packedData = _tokenActivityData[tokenType][tokenId];
        packedData |= uint64(packedData + energyBoost);

        _tokenActivityData[tokenType][tokenId] = packedData;

        emit LogTokenBoostedWithItem(user, tokenType, tokenId, itemTokenId, energyBoost);
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
    /// @param energyConsumption - Energy consumed by activity
    /// @param paused - Paused state for activity
    /// @param petStageBonuses - Array of bp values, eg; [0, 500, 1000, 1000]
    function addActivity(
        bytes32 newActivityType,
        uint128 newActivityId,
        uint64 energyConsumption,
        bool paused,
        uint256[] calldata petStageBonuses
    ) external onlyRole(ADMIN_ROLE) {
        /// @dev id == 0 means activity does not exist yet
        require(_activityData[newActivityType].id == 0, 'AO 103 - Activity exist');
        require(petStageBonuses.length == 4, 'AO 104 - Stage bonus length shall be 4');

        _activityData[newActivityType] = ActivityData(
            newActivityId,
            paused,
            energyConsumption,
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

    /// @notice Sets an activity's daily allowance
    /// @param activityType - Type of activity in bytes32
    /// @param energyConsumption - Maximum activity completions per day
    function editEnergyConsumption(bytes32 activityType, uint64 energyConsumption)
        public
        activityExists(activityType)
        onlyRole(ADMIN_ROLE)
    {
        _activityData[activityType].energyConsumption = energyConsumption;

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
    /// @param energyLevelContractAddress - Address of the Energy LEvel
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