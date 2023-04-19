/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockBeneficiary {
    struct Beneficiary {
        uint256 id;
        uint256 id_beneficiary; // For example the DNI if it is a person or the CUIT if it is a company
        string name;
        string homeAddress;
        string nationality;
        string id_mongo; // This allows to relation the mongo record to the blockchain record
    }

    event idEmitted(uint256 _id);
    mapping(uint256 => Beneficiary) public beneficiaries;
    uint256 id;

    constructor() {
        id = 0;
    }

    function addBeneficiary(
        uint256 _id_beneficiary,
        string memory _name,
        string memory _homeAddress,
        string memory _nationality,
        string memory _id_mongo
    ) public returns (uint256 identifier) {
        id++;
        beneficiaries[id] = Beneficiary(id, _id_beneficiary, _name, _homeAddress, _nationality, _id_mongo);
        emit idEmitted(id);
        return id;
    }
}