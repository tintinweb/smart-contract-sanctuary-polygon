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

/// @title A smart contract to calculate waste verification status for waste collected from households and average waste generated for household.
/// @author Cryption Network
contract WasteVerification is Ownable {
    /*
    This is added as enum and not boolean due to the reasoning 
    that boolean default is false which might lead to some confusion on the actual verification status
    It will also help us to avoid a lot of if conditions and all the conditional checks can be done on this flag
    */
    enum GarbageQuantityVerificationStatus {
        UNINITIALIZED,
        SUCCESS,
        FAILED
    }

    /// @dev add all waste in gms and then scaled up to 1e12 again so there is no confusion related to decimals
    struct TripInfo {
        uint256 tripId;
        string transId;
        uint256 startDateTime;
        uint256 endDateTime;
        uint256 userId;
        string dyId;
        string[] houseList;
        uint256 tripNo;
        string vehicleNumber;
        uint256 totalGcWeight;
        uint256 totalDryWeight;
        uint256 totalWetWeight;
        GarbageQuantityVerificationStatus garbageQuantityVerificationStatus;
    }

    mapping(uint256 => TripInfo) public tripInfo;

    uint256 public averageWasteCollectedPerHouse = 875 * 1e12;

    uint256 public tolerancePercentage = 5;

    event TripData(uint256 indexed tripId, uint256 indexed totalHousesInTrip);

    event TripGarbageQuantityVerificationStatus(
        uint256 indexed tripId,
        GarbageQuantityVerificationStatus indexed garbageQuantityVerificationStatus
    );

    event AverageWasteCollectedPerHouseUpdated(uint256 indexed newAverageWasteCollectedPerHouse);

    event TolerancePercentageUpdated(uint256 indexed newTolerancePercentage);

    /// @notice Save Trip Collection Data to contract storage. Same API to be used for updating fields as well.
    /// @dev No zero checks added and should be done at API level.
    /// @param _tripId TripId Primary Key of the dumpyard details db.
    /// @param _transId TransId Generated key based on AppId, UserId etc.
    /// @param _startDateTime Trip Start time based on first house scanned.
    /// @param _endDateTime Trip End Time based on the time when the waste is processed at dumpyard.
    /// @param _userId Waste Collector UserId.
    /// @param _dyId Dumpyard Id.
    /// @param _houseList List of houses from which the waste is collected.
    /// @param _tripNo Number of trips completed for this tripId
    /// @param _vehicleNumber Vehicle Number of the mode of transport used for waste collection.
    /// @param _totalGcWeight Total Weight Collected for the trip.
    /// @param _totalDryWeight Total Dry Weight Collected for the trip.
    /// @param _totalWetWeight Total Wet Weight Collected for the trip.
    function upsertTripData(
        uint256 _tripId,
        string memory _transId,
        uint256 _startDateTime,
        uint256 _endDateTime,
        uint256 _userId,
        string memory _dyId,
        string[] memory _houseList,
        uint256 _tripNo,
        string memory _vehicleNumber,
        uint256 _totalGcWeight,
        uint256 _totalDryWeight,
        uint256 _totalWetWeight
    ) external onlyOwner {
        TripInfo storage trip = tripInfo[_tripId];
        trip.tripId = _tripId;
        trip.transId = _transId;
        trip.startDateTime = _startDateTime;
        trip.endDateTime = _endDateTime;
        trip.userId = _userId;
        trip.dyId = _dyId;
        trip.houseList = _houseList;
        trip.tripNo = _tripNo;
        trip.vehicleNumber = _vehicleNumber;
        trip.totalGcWeight = _totalGcWeight;
        trip.totalDryWeight = _totalDryWeight;
        trip.totalWetWeight = _totalWetWeight;
        trip.garbageQuantityVerificationStatus = processGarbageQuantityVerificationStatus(
            _houseList.length,
            trip.totalGcWeight
        );

        emit TripGarbageQuantityVerificationStatus(_tripId, trip.garbageQuantityVerificationStatus);
        emit TripData(_tripId, _houseList.length);
    }

    /// @notice Update the average value of waste collected per household.
    /// @param _newAverageWasteCollectedPerHouse New value for average waste collected per house
    function updateAverageWasteCollectedPerHouseValue(uint256 _newAverageWasteCollectedPerHouse)
        external
        onlyOwner
    {
        averageWasteCollectedPerHouse = _newAverageWasteCollectedPerHouse;
        emit AverageWasteCollectedPerHouseUpdated(_newAverageWasteCollectedPerHouse);
    }

    /// @notice Update the tolerance percentage allowed for verification of waste collection.
    /// @param _newTolerancePercentage New tolerance percentage value.
    function updateTolerancePercentage(uint256 _newTolerancePercentage) external onlyOwner {
        tolerancePercentage = _newTolerancePercentage;
        emit TolerancePercentageUpdated(_newTolerancePercentage);
    }

    /// @notice Fetch all trip data based on tripId
    /// @param _tripId TripId Primary Key of the dumpyard details db.
    /// @return trip TripData for the tripId
    function getTripData(uint256 _tripId) external view returns (TripInfo memory trip) {
        trip = tripInfo[_tripId];
    }

    /// @notice Function to calculate tentative waste possible for houses.
    /// @param _totalHouses Number of houses
    /// @return totalTentativeWaste Tentative waste possible for the number of houses
    function calclulateTentativeWasteForHouses(uint256 _totalHouses)
        public
        view
        returns (uint256 totalTentativeWaste)
    {
        totalTentativeWaste =
            (_totalHouses * averageWasteCollectedPerHouse * (100 - tolerancePercentage)) /
            100;
    }

    /// @notice Function to process verification status based on tentative weight and collected waste.
    /// @param _totalHouses Number of houses.
    /// @param _totalCollectedWaste Total collected waste for the trip.
    /// @return garbageQuantityVerificationStatus Garbage Verification status for the trip
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