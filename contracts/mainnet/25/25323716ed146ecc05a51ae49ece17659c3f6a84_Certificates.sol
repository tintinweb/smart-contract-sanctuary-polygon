/**
 *Submitted for verification at polygonscan.com on 2023-07-19
*/

// SPDX-License-Identifier: GPL-3.0
// Copyright (C) 2023 Justin J Daniel, TrackGenesis Pvt. Ltd.

pragma solidity ^0.8.20;

contract Certificates {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized");
        _;
    }

    event AdminUpdated(address newAdmin);

    function updateAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    // Define a struct for a certificate
    struct Certificate {
        string certificateId;
        string surname;
        string issuedBy;
        string issuedDate;
        string certificateType;
        mapping(string => string) dynamicData;
    }

    // Mapping to store certificates by uniqueId
    mapping(string => Certificate) private certificates;
    mapping(string => string[]) private dynamicDataKeys;

    // Event to be emitted when a new certificate is added
    event CertificateAdded(string uniqueId);

    // Helper struct to store key-value pairs for dynamic data
    struct KeyValuePair {
        string key;
        string value;
    }

    // Function to add a new certificate
    function addCertificate(
        string memory _uniqueId,
        string memory _certificateId,
        string memory _surname,
        string memory _issuedBy,
        string memory _issuedDate,
        string memory _certificateType,
        KeyValuePair[] memory _dynamicData
    ) public onlyAdmin {
        // Validate input data
        require(
            bytes(_uniqueId).length > 0 &&
                bytes(_certificateId).length > 0 &&
                bytes(_surname).length > 0 &&
                bytes(_issuedBy).length > 0 &&
                bytes(_issuedDate).length > 0,
            "Required fields are missing"
        );

        // Check if the certificate with the given ID already exists
        require(
            bytes(certificates[_uniqueId].certificateId).length == 0,
            "Certificate with this ID already exists"
        );

        // Create a new certificate and store it in the mapping
        Certificate storage newCertificate = certificates[_uniqueId];
        newCertificate.certificateId = _certificateId;
        newCertificate.surname = _surname;
        newCertificate.issuedBy = _issuedBy;
        newCertificate.issuedDate = _issuedDate;
        newCertificate.certificateType = _certificateType;

        // Add the dynamic data to the certificate
        uint256 dynamicDataLength = _dynamicData.length;
        for (uint256 i = 0; i < dynamicDataLength; i++) {
            newCertificate.dynamicData[_dynamicData[i].key] = _dynamicData[i]
                .value;
            dynamicDataKeys[_uniqueId].push(_dynamicData[i].key);
        }

        // Emit the CertificateAdded event
        emit CertificateAdded(_uniqueId);
    }

    // Function to get the certificate details by passing a uniqueId
    function getCertificateDetails(string memory _uniqueId)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            KeyValuePair[] memory
        )
    {
        // Check if the certificate with the given ID exists
        require(
            bytes(certificates[_uniqueId].certificateId).length > 0,
            "Certificate not found"
        );

        // Retrieve the certificate from the mapping
        Certificate storage certificate = certificates[_uniqueId];

        uint256 dynamicDataLength = dynamicDataKeys[_uniqueId].length;
        KeyValuePair[] memory dynamicData = new KeyValuePair[](
            dynamicDataLength
        );

        for (uint256 i = 0; i < dynamicDataLength; i++) {
            string memory key = dynamicDataKeys[_uniqueId][i];
            dynamicData[i] = KeyValuePair({
                key: key,
                value: certificate.dynamicData[key]
            });
        }

        // Return the certificate details
        return (
            certificate.certificateId,
            certificate.surname,
            certificate.issuedBy,
            certificate.issuedDate,
            certificate.certificateType,
            dynamicData
        );
    }
}