// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Gacert {
    struct Certificate {
        address applier;
        address approver;
        bool isApproved;
    }

    Certificate[] public certificates;
    mapping(uint256 => Certificate) public idToCertificate;

    constructor() {}

    function applyCert(uint256 id, address _approver) public {
        Certificate memory certificate = Certificate(
            msg.sender,
            _approver,
            false
        );
        idToCertificate[id] = certificate;
        certificates.push(certificate);
    }

    function approveCert(uint256 id) public {
        Certificate storage certificate = idToCertificate[id];

        require(certificate.approver == msg.sender, "You are not the approver");
        certificate.isApproved = true;
    }
}