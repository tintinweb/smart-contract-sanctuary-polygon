// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WasteVerification is Ownable {
    /*
    This is added as enum and not boolean due to the reasoning 
    that boolean default is false which might lead to some confusion on the actual verification status
    It will also help us to avoid a lot of if conditions and all the conditional checks can be done on this flag
    */
    enum GarbageQuantityVerificationStatus {
        UNINITIALIZED,
        PENDING,
        SUCCESS,
        FAILED
    }

    struct TripInfo {
        uint256 tripId;
        uint256[] houseIds;
        uint256 userId;
        uint256 vehicleId;
        uint256 tripStartTimestamp;
        uint256 dumpyardId;
        uint256 totalCollectedWaste;
        uint256 tripEndTimestamp;
        GarbageQuantityVerificationStatus garbageQuantityVerificationStatus;
        //add more params based on their requirements like appId and seprate vars for liquid/solid waste etc if needed
        //add all waste in gms and then scaled up to 1e12 again so there is no confusion related to decimals
    }

    mapping(uint256 => TripInfo) public tripInfo;

    uint256 public averageWasteCollectedPerHouse = 875 * 1e12;

    event AggregatedHouseholdTripData(
        uint256 indexed tripId,
        uint256 indexed userId,
        uint256 indexed totalHousesInTrip
    );

    event DumpyardTripData(
        uint256 indexed tripId,
        uint256 indexed dumpyardId,
        uint256 indexed totalCollectedWaste
    );

    event TripGarbageQuantityVerificationStatus(
        uint256 indexed tripId,
        GarbageQuantityVerificationStatus indexed garbageQuantityVerificationStatus
    );

    event AverageWasteCollectedPerHouseUpdated(uint256 indexed newAverageWasteCollectedPerHouse);

    constructor() {}

    //Common logic nahi nikaala to avoid gas if API mistakenly calling this function twice (before verification status)
    function addAggregatedHouseholdTripData(
        uint256 _tripId,
        uint256[] calldata _houseIds,
        uint256 _userId,
        uint256 _vehicleId,
        uint256 _tripStartTimestamp
    ) external onlyOwner {
        TripInfo storage trip = tripInfo[_tripId];
        require(
            trip.garbageQuantityVerificationStatus ==
                GarbageQuantityVerificationStatus.UNINITIALIZED &&
                trip.garbageQuantityVerificationStatus == GarbageQuantityVerificationStatus.PENDING,
            "Verfication already processed for this tripId"
        );

        if (
            trip.garbageQuantityVerificationStatus ==
            GarbageQuantityVerificationStatus.UNINITIALIZED &&
            trip.tripId == uint256(0) &&
            trip.dumpyardId == uint256(0) //This is added to confirm that aggregated household API is called for the first time for this tripId
        ) {
            //Household API is called first and thus no trip related data exists

            //Save Household waste data
            trip.tripId = _tripId;
            trip.houseIds = _houseIds;
            trip.userId = _userId;
            trip.vehicleId = _vehicleId;
            trip.tripStartTimestamp = _tripStartTimestamp;
            trip.garbageQuantityVerificationStatus = GarbageQuantityVerificationStatus.PENDING;
            emit AggregatedHouseholdTripData(_tripId, _userId, _houseIds.length);
        }

        if (
            trip.garbageQuantityVerificationStatus == GarbageQuantityVerificationStatus.PENDING &&
            trip.tripId != uint256(0) &&
            trip.dumpyardId != uint256(0) //This is added to avoid aggregated household API to be called on the same tripId by mistake
        ) {
            //Household API is called after dumpyard API and thus trip related data exists

            //Save Household waste data
            trip.houseIds = _houseIds;
            trip.userId = _userId;
            trip.vehicleId = _vehicleId;
            trip.tripStartTimestamp = _tripStartTimestamp;
            trip.garbageQuantityVerificationStatus = processGarbageQuantityVerificationStatus(
                _houseIds.length,
                trip.totalCollectedWaste
            );
            emit TripGarbageQuantityVerificationStatus(
                _tripId,
                trip.garbageQuantityVerificationStatus
            );
            emit AggregatedHouseholdTripData(_tripId, _userId, _houseIds.length);
        }
    }

    //Common logic nahi nikaala to avoid gas if API mistakenly calling this function twice (before verification status)
    function addDumpyardTripData(
        uint256 _tripId,
        uint256 _dumpyardId,
        uint256 _totalCollectedWaste,
        uint256 _tripEndTimestamp
    ) external onlyOwner {
        TripInfo storage trip = tripInfo[_tripId];
        require(
            trip.garbageQuantityVerificationStatus ==
                GarbageQuantityVerificationStatus.UNINITIALIZED ||
                trip.garbageQuantityVerificationStatus == GarbageQuantityVerificationStatus.PENDING,
            "Verfication already processed for this tripId"
        );

        if (
            trip.garbageQuantityVerificationStatus ==
            GarbageQuantityVerificationStatus.UNINITIALIZED &&
            trip.tripId == uint256(0) &&
            trip.userId == uint256(0) //This is added to confirm that dumpyard API is called before aggregated household API
        ) {
            //Dumpyard API is called first and thus no trip related data exists

            //Save Dumpyard data
            trip.tripId = _tripId;
            trip.dumpyardId = _dumpyardId;
            trip.totalCollectedWaste = _totalCollectedWaste;
            trip.tripEndTimestamp = _tripEndTimestamp;
            trip.garbageQuantityVerificationStatus = GarbageQuantityVerificationStatus.PENDING;
            emit DumpyardTripData(_tripId, _dumpyardId, _totalCollectedWaste);
        }

        if (
            trip.garbageQuantityVerificationStatus == GarbageQuantityVerificationStatus.PENDING &&
            trip.tripId != uint256(0) &&
            trip.userId != uint256(0) //This is added to avoid dumpyard API to be called on the same tripId by mistake
        ) {
            //Dumpyard API is called after Aggregated Household API and thus trip related data exists

            //Save Dumpyard data
            trip.dumpyardId = _dumpyardId;
            trip.totalCollectedWaste = _totalCollectedWaste;
            trip.tripEndTimestamp = _tripEndTimestamp;
            trip.garbageQuantityVerificationStatus = processGarbageQuantityVerificationStatus(
                trip.houseIds.length,
                _totalCollectedWaste
            );
            emit TripGarbageQuantityVerificationStatus(
                _tripId,
                trip.garbageQuantityVerificationStatus
            );
            emit DumpyardTripData(_tripId, _dumpyardId, _totalCollectedWaste);
        }
    }

    function updateAverageWasteCollectedPerHouseValue(uint256 _newAverageWasteCollectedPerHouse)
        external
        onlyOwner
    {
        averageWasteCollectedPerHouse = _newAverageWasteCollectedPerHouse;
        emit AverageWasteCollectedPerHouseUpdated(_newAverageWasteCollectedPerHouse);
    }

    function getTripData(uint256 _tripId) external view returns (TripInfo memory) {
        return tripInfo[_tripId];
    }

    function calclulateTentativeWasteForHouses(uint256 _totalHouses)
        public
        view
        returns (uint256 totalTentativeWaste)
    {
        totalTentativeWaste = _totalHouses * averageWasteCollectedPerHouse;
    }

    function processGarbageQuantityVerificationStatus(
        uint256 _totalHouses,
        uint256 _totalCollectedWaste
    ) public view returns (GarbageQuantityVerificationStatus garbageQuantityVerificationStatus) {
        uint256 totalTentativeWaste = calclulateTentativeWasteForHouses(_totalHouses);
        garbageQuantityVerificationStatus = _totalCollectedWaste >= totalTentativeWaste
            ? GarbageQuantityVerificationStatus.SUCCESS
            : GarbageQuantityVerificationStatus.FAILED;
    }
}