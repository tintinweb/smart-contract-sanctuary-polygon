// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IHotelRegistration.sol";

contract CustomerRegistration {
    struct Customer {
        string name;
        string email;
        string phoneNumber;
        uint256 registrationDate;
        bool isRegistered;
    }

    mapping(address => Customer) public customers;
    mapping(string => bool) public emailUsed;
    mapping(string => bool) public phoneNumberUsed;

    function registerCustomer(
        string memory _name,
        string memory _email,
        string memory _phoneNumber
    ) public {
        require(!emailUsed[_email], "Email already registered");
        require(
            !phoneNumberUsed[_phoneNumber],
            "Phone number already registered"
        );

        customers[msg.sender] = Customer({
            name: _name,
            email: _email,
            phoneNumber: _phoneNumber,
            registrationDate: block.timestamp,
            isRegistered: true
        });

        emailUsed[_email] = true;
        phoneNumberUsed[_phoneNumber] = true;
    }

    function unregisterCustomer() public {
        require(
            customers[msg.sender].isRegistered,
            "Customer is not registered"
        );

        emailUsed[customers[msg.sender].email] = false;
        phoneNumberUsed[customers[msg.sender].phoneNumber] = false;
        delete customers[msg.sender];
    }

    // getter functions
    function getCustomer(
        address _customerAddress
    )
        public
        view
        returns (string memory, string memory, string memory, uint256, bool)
    {
        Customer memory customer = customers[_customerAddress];
        return (
            customer.name,
            customer.email,
            customer.phoneNumber,
            customer.registrationDate,
            customer.isRegistered
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHotelRegistration {
    enum HotelRegistrationStatus {
        Pending,
        Approved,
        Rejected
    }

    function getHotelOwnerData(
        address _hotelOwnerAddress
    )
        external
        view
        returns (
            string memory,
            string memory,
            address,
            string memory,
            uint256,
            uint256,
            HotelRegistrationStatus
        );
}