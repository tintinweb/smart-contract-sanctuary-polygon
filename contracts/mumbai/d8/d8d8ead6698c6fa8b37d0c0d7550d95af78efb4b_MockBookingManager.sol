/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// File: SwixMocks/interfaces/ISwixCity.sol


// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ISwixCity {

    event AddLease(address indexed leaseContract, uint256 indexed newLeaseIndex);
    event UpdateNights(address indexed leaseContract, uint256[] indexed nights, uint256[] indexed prices, bool[] availabilities);
    event UpdateCancelPolicy(uint256 indexed leaseIndex, uint256 cancelPolicy, bool allow);
    event UpdateAvailability(uint256 indexed leaseIndex, uint256[] indexed nights, bool indexed available);
    event UpdatedPriceManager(address indexed newPriceManager);
}
// File: SwixMocks/mocks/MockBookingManager.sol


// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;


contract MockBookingManager {
    /// Booking struct
    struct Booking {
        /// Contract of city in which the booking takes place
        ISwixCity city;
        /// Index of Lease in the chosen City
        uint256 leaseIndex;
        /// Start night number
        uint256 start;
        /// End night number
        uint256 end;
        /// Timestamp until which user will get full refund on cancellation
        uint256 fullRefundUntil;
        /// Timestamp until which user will get 50% refund on cancellation
        uint256 halfRefundUntil;
        /// Total price of booking
        uint256 bookingPrice;
        /// Percentage rate of tokenback, 100 = 1%
        uint256 tokenbackRate;
        /// User's address
        address user;
        /// Marker if funds were released from booking
        bool released;
    }

    /// Event emitted on book()
    event Book(
        uint256 indexed bookingIndex,
        address city,
        uint256 leaseIndex,
        uint256 startNight
    );

    /// Event emitted on cancel()
    event Cancel(uint256 indexed bookingIndex);
    /// Event emitted on claimTokenback()
    event ClaimTokenback(uint256 indexed bookingIndex);
    /// Event emitted on updating booking index
    event BookingIndexUpdated(uint256 indexed newBookingIndex, uint256 indexed oldBoookingIndex);
    /// Event emitted on releaseFunds()
    event ReleaseFunds(uint256 indexed bookingIndex);
    /// Event emitted on reject()
    event Reject(uint256 indexed bookingIndex);

    ISwixCity public city;
    Booking public booking;

    constructor(ISwixCity setCity) {
        city = setCity;
        booking = Booking(
            city,
            1,
            10,
            20,
            1648731600,
            0,
            2000000000000000000000,
            300,
            msg.sender,
            false
        );
    }

    function book(uint256 bookingIndex)
        external
    {
        emit Book(
            bookingIndex,
            address(city),
            1,
            10
        );
    }

    function bookings(uint256 bookingIndex)
        external
        view
        returns (Booking memory)
    {
        return booking;
    }

    function cancel(uint256 bookingIndex)
        external
    {
        emit Cancel(bookingIndex);
    }

    function claimTokenback(uint256 bookingIndex)
        external
    {
        emit ClaimTokenback(bookingIndex);
    }

    function releaseFunds(uint256 bookingIndex)
        external
    {
        emit ReleaseFunds(bookingIndex);
    }

    function reject(uint256 bookingIndex)
        external
    {
        emit Reject(bookingIndex);
    }

    function bookingIndexUpdated(uint256 newBookingIndex, uint256 oldBookingIndex)
        external
    {
        emit BookingIndexUpdated(newBookingIndex, oldBookingIndex);
    }

    function changeCity(ISwixCity newCity)
        external
    {
        city = newCity;
    }
}