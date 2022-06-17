// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vehicle.sol";

contract Ride is Ownable, Vehicle {
    uint256 rideCount;

    enum appUser {
        Driver,
        Customer,
        NONE
    }

    // Ride data type
    struct USERS {
        address customer;
        address driver;
    }

    struct STATUS {
        bool isCancelled;
        bool isComplete;
        bool isConfirmed;
        appUser wasCancelledBy;
    }

    struct RIDE_DETAILS {
        string pickup;
        string destination;
        uint256 distance;
        uint256 price;
    }

    struct RIDE {
        uint id;
        USERS users;
        STATUS status;
        RIDE_DETAILS ride;
        VEHICLE_INFO vehicle;
        string timestamp;
    }

    mapping(uint256 => RIDE) private _rides;

    function confirmRide(USERS memory _user, STATUS memory _status, RIDE_DETAILS memory _details, string memory _timestamp)
        public
        returns (uint256)
    {
        rideCount++;
        USERS memory user = _user;
        STATUS memory status = _status;
        RIDE_DETAILS memory details = _details;
        RIDE memory ride;
        ride.id = rideCount;
        ride.users = user;
        ride.status = status;
        ride.ride = details;
        ride.vehicle = _vehicles[_user.driver];
        ride.timestamp = _timestamp;

        _rides[rideCount] = ride;

        return rideCount;
    }

    function getAllRides(uint256[] memory rideIds)
        public
        view
        returns (RIDE[] memory)
    {
        RIDE[] memory allRides;
        uint256 count = 0;

        for (uint256 i = 0; i < rideIds.length; i++) {
            uint256 rideId = rideIds[i];
            allRides[count] = _rides[rideId];
            count++;
        }

        return allRides;
    }

    function getRide(uint256 _rideId) public view returns (RIDE memory) {
        return _rides[_rideId];
    }

    function cancelRide(uint256 _rideId, appUser _wasCancelledBy, string memory _timestamp) public {
        RIDE memory ride = _rides[_rideId];
        ride.status.isCancelled = true;
        ride.status.wasCancelledBy = _wasCancelledBy;
        ride.timestamp = _timestamp;
        _rides[_rideId] = ride;
    }

    function completeRide(uint256 _rideId, string memory _timestamp) public {
        RIDE memory ride = _rides[_rideId];
        ride.status.isComplete = true;
        ride.timestamp = _timestamp;
        _rides[_rideId] = ride;
    }

    function getRideCount() public view returns(uint256) {
        return rideCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vehicle is Ownable {
    enum VEHICLE_TYPE {
        MINI,
        PRIME,
        SEDAN,
        SUV
    }

    struct VEHICLE_INFO {
        string vehicle_no;
        string RC;
        string vehicleImages;
        VEHICLE_TYPE vehicleType;
        address driver;
    }

    mapping(address => VEHICLE_INFO) internal _vehicles;

    function addVehicle(address driver, VEHICLE_INFO memory _vehicle)
        public
        onlyOwner
    {
        VEHICLE_INFO memory vehicle;
        vehicle = _vehicle;
        _vehicles[driver] = vehicle;
    }
    function updateVehicle(address driver, VEHICLE_INFO memory _vehicle)
        public
        onlyOwner
    {
        VEHICLE_INFO memory vehicle;
        vehicle = _vehicle;
        _vehicles[driver] = vehicle;
    }

    function getVehicle(address driver)
        public
        view
        onlyOwner
        returns (VEHICLE_INFO memory)
    {
        return _vehicles[driver];
    }
}