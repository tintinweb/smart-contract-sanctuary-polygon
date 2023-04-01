// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AdamoSignatureRecorder.sol";
import "./AdamoBasicDocumentFactory.sol";

contract AdamoBasicDocument {
    string public rejectionCause;
    address public documentFactory;
    bool public documentRejected = false;
    bool public documentFullySigned = false;
    uint64 private s_currentDocumentVersionId;
    string[] private s_documentStampedSignatures;
    string[] private s_documentRequiredSignatures;
    mapping(string => bool) public isRequiredSignature;
    mapping(string => bool) public signatureAlreadyStamped;
    struct DocumentVersionMetadata {
        string versionHash;
        string signatureStamped;
        uint256 versionRegistrationTimestamp;
        uint256 versionRegistrationBlockNumber;
    }

    error DocumentWasRejected();
    error DocumentIsFullySigned();
    error SignatureAlreadyAdded();
    error SignaturesCantBeEmpty();
    error SignatureAlreadyStamped();
    error DocumentVersionNotValid();
    error DocumentIsAlreadyRejected();
    error SignatureIsNotRequiredInThisDocument();

    event RequiredSignetureAdded(string indexed requiredSignature);
    event RequiredSignetureRemoved(string indexed requiredSignature);

    mapping(uint64 => DocumentVersionMetadata) /* documentVersionId */ /* DocumentVersionMetadata */
        private s_documentVersionsMetadata;

    modifier onlyIfDocumentOwner() {
        require(msg.sender == documentFactory, "You are not authorized");
        _;
    }

    modifier onlyIfSignatureRecorderOwner() {
        require(
            msg.sender ==
                AdamoSignatureRecorder(
                    AdamoBasicDocumentFactory(documentFactory)
                        .currentSignatureRecorder()
                ).signatureRecorderOwner(),
            "You are not authorized"
        );
        _;
    }

    constructor() {
        documentFactory = msg.sender;
    }

    function setFirstVersionOfDocument(
        string memory _documentFirstVersionHash,
        string[] memory _documentRequiredSignatures
    ) external onlyIfDocumentOwner returns (bool _success) {
        s_documentVersionsMetadata[1].signatureStamped = "";
        s_documentVersionsMetadata[1].versionHash = _documentFirstVersionHash;
        s_documentVersionsMetadata[1].versionRegistrationBlockNumber = block
            .number;
        s_documentVersionsMetadata[1].versionRegistrationTimestamp = block
            .timestamp;
        s_documentRequiredSignatures = _documentRequiredSignatures;
        s_currentDocumentVersionId++;

        for (uint256 i = 0; i < _documentRequiredSignatures.length; ++i) {
            require(
                checkIfSignatureIsValid(_documentRequiredSignatures[i]),
                "There is a signature that is not valid or not registered."
            );
            isRequiredSignature[_documentRequiredSignatures[i]] = true;
        }

        return true;
    }

    function checkIfSignatureIsValid(
        string memory _signatureToCheck
    ) public view returns (bool _isValid) {
        (bool signatureValid, , ) = AdamoSignatureRecorder(
            AdamoBasicDocumentFactory(documentFactory)
                .currentSignatureRecorder()
        ).getIfIsValidSignature(_signatureToCheck);
        return signatureValid;
    }

    function getCurrentDocumentVersionId() public view returns (uint64) {
        return s_currentDocumentVersionId;
    }

    function getDocumentRequiredSignatures()
        public
        view
        returns (string[] memory)
    {
        return s_documentRequiredSignatures;
    }

    function getDocumentStampedSignatures()
        public
        view
        returns (string[] memory)
    {
        return s_documentStampedSignatures;
    }

    function getDocumentVersionMetadata(
        uint64 _documentVersionId
    )
        external
        view
        returns (
            string memory _versionHash,
            string memory _signatureStamped,
            uint256 _versionRegistrationTimestamp,
            uint256 _versionRegistrationBlockNumber
        )
    {
        if (
            s_documentVersionsMetadata[_documentVersionId]
                .versionRegistrationBlockNumber == 0
        ) revert DocumentVersionNotValid();

        return (
            s_documentVersionsMetadata[_documentVersionId].versionHash,
            s_documentVersionsMetadata[_documentVersionId].signatureStamped,
            s_documentVersionsMetadata[_documentVersionId]
                .versionRegistrationTimestamp,
            s_documentVersionsMetadata[_documentVersionId]
                .versionRegistrationBlockNumber
        );
    }

    function addRequiredSignature(
        string memory _requiredSignatureToAdd
    ) external onlyIfSignatureRecorderOwner returns (bool _success) {
        if (isRequiredSignature[_requiredSignatureToAdd] == true)
            revert SignatureAlreadyAdded();
        if (documentFullySigned == true) revert DocumentIsFullySigned();

        s_documentRequiredSignatures.push(_requiredSignatureToAdd);
        isRequiredSignature[_requiredSignatureToAdd] = true;

        emit RequiredSignetureAdded(_requiredSignatureToAdd);
        return true;
    }

    function removeRequiredSignature(
        string memory _requiredSignatureToRemove
    ) external onlyIfSignatureRecorderOwner returns (bool _success) {
        if (s_documentRequiredSignatures.length == 1)
            revert SignaturesCantBeEmpty();
        if (signatureAlreadyStamped[_requiredSignatureToRemove] == true)
            revert SignatureAlreadyStamped();

        uint256 lastAdminUserIndex = s_documentRequiredSignatures.length - 1;
        for (uint256 i = 0; i < s_documentRequiredSignatures.length; i++) {
            if (
                keccak256(
                    abi.encodePacked((s_documentRequiredSignatures[i]))
                ) == keccak256(abi.encodePacked((_requiredSignatureToRemove)))
            ) {
                string memory last = s_documentRequiredSignatures[
                    lastAdminUserIndex
                ];
                s_documentRequiredSignatures[i] = last;
                s_documentRequiredSignatures.pop();
                break;
            }
        }

        isRequiredSignature[_requiredSignatureToRemove] = false;
        emit RequiredSignetureRemoved(_requiredSignatureToRemove);
        return true;
    }

    function signDocument(
        string memory _documentVersionHash,
        string memory _signatureToStamp
    ) external returns (bool _success) {
        if (documentRejected == true) revert DocumentWasRejected();
        if (documentFullySigned == true) revert DocumentIsFullySigned();
        bytes memory tempEmptyStringTest = bytes(_documentVersionHash);
        require(tempEmptyStringTest.length != 0, "Send a valid document hash");
        require(
            checkIfSignatureIsValid(_signatureToStamp),
            "Signature is not valid"
        );
        if (signatureAlreadyStamped[_signatureToStamp] == true)
            revert SignatureAlreadyStamped();
        if (!isRequiredSignature[_signatureToStamp] == true)
            revert SignatureIsNotRequiredInThisDocument();

        uint64 currentDocumentVersionId = getCurrentDocumentVersionId();
        s_documentVersionsMetadata[currentDocumentVersionId + 1]
            .versionHash = _documentVersionHash;
        s_documentVersionsMetadata[currentDocumentVersionId + 1]
            .signatureStamped = _signatureToStamp;
        s_documentVersionsMetadata[currentDocumentVersionId + 1]
            .versionRegistrationBlockNumber = block.number;
        s_documentVersionsMetadata[currentDocumentVersionId + 1]
            .versionRegistrationTimestamp = block.timestamp;

        s_documentStampedSignatures.push(_signatureToStamp);
        signatureAlreadyStamped[_signatureToStamp] = true;
        s_currentDocumentVersionId++;

        if (
            s_documentRequiredSignatures.length ==
            s_documentStampedSignatures.length
        ) {
            documentFullySigned = true;
        }

        return true;
    }

    function rejectDocument(
        string memory _rejectionCause
    ) external onlyIfSignatureRecorderOwner returns (bool _success) {
        if (documentFullySigned == true) revert DocumentIsFullySigned();
        if (documentRejected == true) revert DocumentIsAlreadyRejected();

        rejectionCause = _rejectionCause;
        documentRejected = true;
        return true;
    }
}