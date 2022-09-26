// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract AadharReg {

    //Structure of Aadhar feilds
    struct Aadhar {
        string _name;
        string _address;
        string _dob;
    }

    mapping(address => Aadhar) public person;

    //Create Aadhar Function
    function createAadhar(
        address _user,
        string memory _name,
        string memory _address,
        string memory _dob
    ) public {
        Aadhar storage aadhar = person[_user];

        aadhar._name = _name;
        aadhar._address = _address;
        aadhar._dob = _dob;
    }

    //Retrieve The aahar details using the Address
    function getAadhar(address _user) public view returns (Aadhar memory) {
        return person[_user];
    }
}