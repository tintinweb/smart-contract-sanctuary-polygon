// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Owned.sol";

contract AdamoSignatureRecorder is Owned {
    struct SignatureMetadata {
        string signatureOwnerName;
        address signatureOwnerPublicKey;
        string signatureOwnerHashedKey;
        string signatureAuditorHashedKey;
        string signatureOwnerDocumentType;
        string signatureOwnerEncryptedString;
        uint256 signatureRegistrationTimestamp;
        string signatureAuditorEncryptedString;
        uint256 signatureRegistrationBlockNumber;
    }

    struct SignatureValidationMetadata {
        bool signatureValid;
        bool signatureUsedInDocument;
        uint64 signatureOwnerDocumentNumber;
    }

    mapping(uint64 => SignatureMetadata) /* signatureOwnerDocumentNumber */ /* SignatureMetadata */
        private s_signatureMetadata;
    mapping(uint64 => string) /* signatureOwnerDocumentNumber */ /* signatureHashDigest */
        private s_signatureHashDigest;
    mapping(string => SignatureValidationMetadata) /* signatureHashDigest */ /* SignatureValidationMetadata */
        private s_isValidSignature;
    mapping(uint64 => bool)
        public isRegisteredSignature; /* signatureOwnerDocumentNumber */ /* isRegister */
    uint64[] private s_signatureOwners;
    uint64 private s_currentSignatureId;

    error SignatureIsNotRegistered();
    error SignatureIsAlredyRegistered();
    error SignatureOwnerPublicKeyZero();
    error SignatureToDeleteIsNotRegistered();
    error SignatureWasAlreadyUsedInDocument();

    event SignatureDeleted(uint64 indexed signatureOwnerDocumentNumber);

    function getCurrentSignatureId() external view returns (uint64) {
        return s_currentSignatureId;
    }

    function getCurrentSignatureOwners()
        external
        view
        returns (uint64[] memory _signatureOwners)
    {
        return s_signatureOwners;
    }

    function getSignatureHashDigestByDocumentNumber(
        uint64 _signatureOwnerDocumentNumber
    ) public view returns (string memory _signatureHashDigest) {
        return s_signatureHashDigest[_signatureOwnerDocumentNumber];
    }

    function getIfIsValidSignature(
        string memory _signatureHashDigest
    )
        public
        view
        returns (
            bool _signatureValid,
            bool _signatureUsedInDocument,
            uint64 _signatureOwnerDocumentNumber
        )
    {
        return (
            s_isValidSignature[_signatureHashDigest].signatureValid,
            s_isValidSignature[_signatureHashDigest].signatureUsedInDocument,
            s_isValidSignature[_signatureHashDigest]
                .signatureOwnerDocumentNumber
        );
    }

    function getSignatureMetadataByDocumentNumber(
        uint64 _signatureDocumentNumber
    )
        external
        view
        returns (
            string[4] memory _signatureOwnerData,
            string[2] memory _signatureAuditorData,
            string memory _signatureHashDigest,
            address _signatureOwnerPublicKey,
            uint256 _signatureRegistrationTimestamp,
            uint256 _signatureRegistrationBlockNumber
        )
    {
        if (!isRegisteredSignature[_signatureDocumentNumber])
            revert SignatureIsNotRegistered();

        return (
            [
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureOwnerName,
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureOwnerHashedKey,
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureOwnerDocumentType,
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureOwnerEncryptedString
            ],
            [
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureAuditorHashedKey,
                s_signatureMetadata[_signatureDocumentNumber]
                    .signatureAuditorEncryptedString
            ],
            s_signatureHashDigest[_signatureDocumentNumber],
            s_signatureMetadata[_signatureDocumentNumber]
                .signatureOwnerPublicKey,
            s_signatureMetadata[_signatureDocumentNumber]
                .signatureRegistrationTimestamp,
            s_signatureMetadata[_signatureDocumentNumber]
                .signatureRegistrationBlockNumber
        );
    }

    function registerSignature(
        address _signatureOwnerPublicKey,
        string memory _signatureOwnerName,
        string memory _signatureHashDigest,
        uint64 _signatureOwnerDocumentNumber,
        string memory _signatureOwnerHashedKey,
        string memory _signatureAuditorHashedKey,
        string memory _signatureOwnerDocumentType,
        string memory _signatureOwnerEncryptedString,
        string memory _signatureAuditorEncryptedString
    ) external onlySignatureRecorderOwner returns (bool _success) {
        if (address(_signatureOwnerPublicKey) == address(0x0))
            revert SignatureOwnerPublicKeyZero();

        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureOwnerName = _signatureOwnerName;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureRegistrationBlockNumber = block.number;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureRegistrationTimestamp = block.timestamp;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureOwnerPublicKey = _signatureOwnerPublicKey;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureOwnerHashedKey = _signatureOwnerHashedKey;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureAuditorHashedKey = _signatureAuditorHashedKey;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureOwnerDocumentType = _signatureOwnerDocumentType;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureOwnerEncryptedString = _signatureOwnerEncryptedString;
        s_signatureMetadata[_signatureOwnerDocumentNumber]
            .signatureAuditorEncryptedString = _signatureAuditorEncryptedString;
        s_signatureHashDigest[
            _signatureOwnerDocumentNumber
        ] = _signatureHashDigest;

        s_isValidSignature[_signatureHashDigest].signatureValid = true;
        s_isValidSignature[_signatureHashDigest]
            .signatureUsedInDocument = false;
        s_isValidSignature[_signatureHashDigest]
            .signatureOwnerDocumentNumber = _signatureOwnerDocumentNumber;

        s_currentSignatureId++;
        s_signatureOwners.push(_signatureOwnerDocumentNumber);

        isRegisteredSignature[_signatureOwnerDocumentNumber] = true;

        return true;
    }

    function deleteSignature(
        uint64 _signatureDocumentNumberToDelete
    ) external onlySignatureRecorderOwner {
        if (!isRegisteredSignature[_signatureDocumentNumberToDelete])
            revert SignatureToDeleteIsNotRegistered();

        string
            memory signatureHashDigest = getSignatureHashDigestByDocumentNumber(
                _signatureDocumentNumberToDelete
            );
        (, bool signatureUsedInDocument, ) = getIfIsValidSignature(
            signatureHashDigest
        );

        if (signatureUsedInDocument) revert SignatureWasAlreadyUsedInDocument();

        isRegisteredSignature[_signatureDocumentNumberToDelete] = false;
        emit SignatureDeleted(_signatureDocumentNumberToDelete);
    }

    function getHashKeyToSecureSignature(
        string memory _keyToHash
    ) public pure returns (bytes32 _keyHashed) {
        return keccak256(abi.encodePacked(_keyToHash));
    }
}