// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract Booking {
    address public owner;
    mapping(address => uint256) public TotalAppointments;

    constructor() {
        owner = msg.sender;
        TotalAppointments[address(this)] = 5;
    }

    function getremainingAppointments() public view returns (uint256) {
        return TotalAppointments[address(this)];
    }

    function UpdateAppointments(uint256 amount) public {
        require(msg.sender == owner, "Only Hospital can update Appointments.");
        TotalAppointments[address(this)] += amount;
    }

    mapping(address => bool) UserBookings;

    function BookAppointment(uint256 amount) public payable {
        require(
            msg.value >= amount * 1,
            "you must pay 1 ether to make an appointment"
        );
        require(
            !UserBookings[msg.sender],
            "You have already booked an appointment"
        );
        TotalAppointments[address(this)] -= amount;
        TotalAppointments[msg.sender] += amount;
        UserBookings[msg.sender] = true;
    }
}