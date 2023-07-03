/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SmartParking {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can access this");
        _;
    }

    mapping(uint256 => User) users;
    mapping(uint256 => Order) orders;

    enum Status {
        NOT_PAID,
        PAID
    }

    struct User {
        uint256 user_id;
        uint256 balance;
        string plate_number;
        string nik;
        string username;
        string phone_number;
        uint256[] order_id;
    }

    struct Order {
        uint256 user_id;
        uint256 time_enter;
        uint256 time_exit;
        uint256 price;
        Status status;
    }

    function userRegister(
        uint256 _user_id,
        string memory _plate_number,
        string memory _nik,
        string memory _username,
        string memory _phone_number
    ) public onlyAdmin {
        User storage user = users[_user_id];
        require(user.user_id == 0, "User already exists");

        user.user_id = _user_id;
        user.plate_number = _plate_number;
        user.nik = _nik;
        user.username = _username;
        user.phone_number = _phone_number;
    }

    function topUpBalance(uint256 _user_id, uint256 _value) public onlyAdmin {
        User storage user = users[_user_id];
        require(user.user_id != 0, "User does not exist");

        user.balance += _value;
    }

    function addOrder(
        uint256 _user_id,
        uint256 _order_id,
        uint256 _time_enter
    ) public onlyAdmin {
        User storage user = users[_user_id];
        Order storage order = orders[_order_id];
        require(user.user_id != 0, "User does not exist");
        require(order.user_id == 0, "Can't override this order");

        user.order_id.push(_order_id);

        order.user_id = _user_id;
        order.time_enter = _time_enter;
        order.price = 4000;
        order.status = Status.NOT_PAID;
    }

    function insertExit(
        uint256 _order_id,
        uint256 _time_exit,
        uint256 _price
    ) public onlyAdmin {
        Order storage order = orders[_order_id];
        User storage user = users[order.user_id];

        require(order.user_id != 0, "Not check in yet");
        require(
            _time_exit > order.time_enter,
            "Time exit must greater than enter"
        );
        require(user.balance >= _price, "Balance not enough to pay");

        user.balance -= _price;
        order.time_exit = _time_exit;
        order.price = _price;
        order.status = Status.PAID;
    }

    function getUserInfo(
        uint256 _user_id
    )
        public
        view
        onlyAdmin
        returns (
            uint256 user_id,
            uint256 balance,
            string memory plate_number,
            string memory nik,
            string memory username,
            string memory phone_number,
            uint256[] memory order_id
        )
    {
        User storage user = users[_user_id];
        require(user.user_id != 0, "User does not exist");
        return (
            user.user_id,
            user.balance,
            user.plate_number,
            user.nik,
            user.username,
            user.phone_number,
            user.order_id
        );
    }

    function getOrderDetail(
        uint256 _order_id
    )
        public
        view
        onlyAdmin
        returns (
            uint256 user_id,
            uint256 time_enter,
            uint256 time_exit,
            uint256 price,
            Status status
        )
    {
        Order storage order = orders[_order_id];
        require(order.time_enter != 0, "Not check in yet");
        require(order.time_exit != 0, "Not check out yet");
        return (
            order.user_id,
            order.time_enter,
            order.time_exit,
            order.price,
            order.status
        );
    }
}