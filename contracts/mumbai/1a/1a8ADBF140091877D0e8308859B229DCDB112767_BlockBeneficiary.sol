/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockBeneficiary {
    struct Beneficiary {
        uint256 id_beneficiary; // For example the DNI if it is a person or the CUIT if it is a company
        string name;
        string homeAddress;
        string nationality;
        string id; // Same ID as the mongo one
    }

    event idEmitted(string _id);
    mapping(string => Beneficiary) public beneficiaries;
    string id;

    constructor() {
    }

    function addBeneficiary(
        uint256 _id_beneficiary,
        string memory _name,
        string memory _homeAddress,
        string memory _nationality,
        string memory _id
    ) public returns (string memory identifier) {
        beneficiaries[_id] = Beneficiary(_id_beneficiary, _name, _homeAddress, _nationality, _id);
        emit idEmitted(_id);
        return _id;
    }
}