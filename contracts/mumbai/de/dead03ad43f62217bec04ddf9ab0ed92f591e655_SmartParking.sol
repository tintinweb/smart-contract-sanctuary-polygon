/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SmartParking {
  mapping(uint256 => Booking) bookings;
  mapping(uint256 => BookingDetail) public bookingsDetail;

  struct Booking {
    uint256 user_id;
    uint256[] booking_id;
    }

  struct BookingDetail {
      uint256 time_enter;
      uint256 time_exit;
      uint256 price;
  }

  function addBooking(
      uint256 _user_id,
      uint256 _booking_id,
      uint256 _time_enter
      ) public payable {
          Booking storage booking = bookings[_user_id];
          BookingDetail storage bookingDetail = bookingsDetail[_booking_id];
          
          booking.user_id = _user_id;
          booking.booking_id.push(_booking_id);

          bookingDetail.time_enter = _time_enter;
  }

  function userBookingInfo(uint256 _user_id) public view returns (
      uint256 user_id, uint256[] memory booking_id){
        return (bookings[_user_id].user_id, bookings[_user_id].booking_id);
    }

  function insertExit(uint256 _booking_id, uint256 _time_exit) public {
      BookingDetail storage bookingDetail = bookingsDetail[_booking_id];

      require (_time_exit > bookingDetail.time_enter, "Time exit must greater than enter");

      bookingDetail.time_exit = _time_exit;
      bookingDetail.price = (_time_exit - bookingDetail.time_enter)*5;
  }

}