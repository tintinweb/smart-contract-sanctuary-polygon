/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Prescribe {
    address owner;
    struct prescriptionForm {
        uint256 datePrescribed;
        bytes32 place;
        bytes32 hash;
    }

    struct history {
        uint256 dateVisited;
        bytes32 place;
        bytes32 comments;
        address patient;
    }

    mapping(address => history[]) public medicalHistory;
    mapping(address => bool) public trustedOrganisations;

    constructor() {
        owner = msg.sender;
    }

    modifier organisationAllowed() {
        require(
            trustedOrganisations[msg.sender] == true,
            "This isn't a trusted organisation. Send us a request and we'll verify you"
        );
        _;
    }

    function markVisit(
        bytes32 _place,
        bytes32 _comments,
        address patient
    ) public organisationAllowed {
        medicalHistory[patient].push(
            history(block.timestamp, _place, _comments, patient)
        );
    }

    function showAllVisits(
        address patient
    ) public view returns (history[] memory) {
        require(trustedOrganisations[msg.sender]==true || msg.sender== medicalHistory[patient][0].patient);
        return medicalHistory[patient];
    }

    function addOrganisations(address organisation) public {
        trustedOrganisations[organisation] = true;
    }

    function isTrusted(address organisation) public view returns (bool) {
        return trustedOrganisations[organisation] == true;
    }
    // function addPrescription(
    //     bytes32 _place,
    //     bytes32 _hash,
    //     address patient
    // ) external {
    //     markVisit(_place, "", patient);
    //     prescriptions[patient].push(
    //         prescriptionForm(block.timestamp, _place, _hash)
    //     );
    //  }

    // function viewPrescriptions()
    //     external
    //     view
    //     returns (prescriptionForm[] memory)
    // {
    //     return prescriptions[msg.sender];
    // }

    // function viewHistory(
    //     uint256 _uid
    // ) public view returns (prescriptionForm memory) {
    //     return uniquePrescriptions[_uid];
    // }
}