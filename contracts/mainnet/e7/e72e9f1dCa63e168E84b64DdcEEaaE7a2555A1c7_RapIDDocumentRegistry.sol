// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract RapIDDocumentRegistry {
    //                  --------------
    //                  |            |
    //                  V            |
    // NOT ISSUED --> ACTIVE --> SUSPENDED --> REVOKED
    //     |            |                       ^  ^
    //     |            |                       |  |
    //     |            -------------------------  |
    //     |                                       |
    //     -----------------------------------------

    // The usage of Enums can be unpredictable. (I dunno, should check again later)
    uint8 STATUS_NOT_ISSUED = 0;
    uint8 STATUS_ACTIVE = 1;
    uint8 STATUS_SUSPENDED = 2;
    uint8 STATUS_REVOKED = 3;

    struct Document {
        address signer;
        uint8 status;
    }

    mapping(bytes32 => Document) public document; // docHash => Document

    event DocumentActivated(bytes32 indexed signature);
    event DocumentSuspended(bytes32 indexed signature);
    event DocumentUnsuspended(bytes32 indexed signature);
    event DocumentRevoked(bytes32 indexed signature);

    modifier isSigner(bytes32 docHash) {
        address signer = document[docHash].signer;
        require(
            signer == msg.sender,
            "Invalid operation: Not the document Signer!"
        );
        _;
    }

    modifier isNotIssued(bytes32 docHash) {
        require(
            document[docHash].status == STATUS_NOT_ISSUED,
            "Invalid operation: Document already issued!"
        );
        _;
    }

    modifier isActive(bytes32 docHash) {
        require(
            document[docHash].status == STATUS_ACTIVE,
            "Invalid operation: Document is not active!"
        );
        _;
    }

    modifier isSuspended(bytes32 docHash) {
        require(
            document[docHash].status == STATUS_SUSPENDED,
            "Invalid operation: Document is not suspended!"
        );
        _;
    }

    function activateDocument(bytes32 docHash) external isNotIssued(docHash) {
        document[docHash].signer = msg.sender;
        document[docHash].status = STATUS_ACTIVE;

        emit DocumentActivated(docHash);
    }

    function suspendDocument(bytes32 docHash)
        external
        isSigner(docHash)
        isActive(docHash)
    {
        document[docHash].status = STATUS_SUSPENDED;

        emit DocumentSuspended(docHash);
    }

    function unsuspendDocument(bytes32 docHash)
        external
        isSigner(docHash)
        isSuspended(docHash)
    {
        document[docHash].status = STATUS_ACTIVE;

        emit DocumentUnsuspended(docHash);
    }

    function revokeDocument(bytes32 docHash) external isSigner(docHash) {
        document[docHash].status = STATUS_REVOKED;

        emit DocumentRevoked(docHash);
    }
}