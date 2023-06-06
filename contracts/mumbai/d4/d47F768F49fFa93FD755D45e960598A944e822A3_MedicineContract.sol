//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MedicineContract {
    struct Medicine {
        string name;
        uint256 price;
        uint256 manufacturingDate;
        uint256 batchNumber;
        string manufacturingCompany;
        uint256 expiryDate;
    }
    
    mapping(address => Medicine) public medicines;
   
    
    // Function to add a new medicine to the contract
    function addMedicine(
        string memory _name,
        uint256 _price,
        uint256 _manufacturingDate,
        uint256 _batchNumber,
        string memory _manufacturingCompany,
        uint256 _expiryDate
    ) public {
        
        
        medicines[msg.sender] = Medicine({
            name: _name,
            price: _price,
            manufacturingDate: _manufacturingDate,
            batchNumber: _batchNumber,
            manufacturingCompany: _manufacturingCompany,
            expiryDate: _expiryDate
        });
    }
    
    // Function to get the details of a specific medicine
      function getMedicinesDetails(address _address) public view returns(Medicine memory) {
        return medicines[_address];
    }
    
}