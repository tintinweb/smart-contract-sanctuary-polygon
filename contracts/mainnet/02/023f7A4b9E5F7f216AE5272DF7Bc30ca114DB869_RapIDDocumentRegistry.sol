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
        bytes32 docHash;
        address signer;
        uint256 index;
        uint8 status;
    }

    mapping(bytes => Document) public document; // signature => Document
    mapping(address => bytes[]) public documentByIssuer; // issuer address => list of signatures
    mapping(address => uint256) public issuedDocuments; // issuer address => amount of issued documents

    event DocumentActivated(bytes indexed signature);
    event DocumentSuspended(bytes indexed signature);
    event DocumentUnsuspended(bytes indexed signature);
    event DocumentRevoked(bytes indexed signature);

    modifier isValidSignature(bytes memory signature) {
        require(
            signature.length == 65,
            "Invalid operation: Not a valid signature!"
        );
        _;
    }

    modifier isSigner(bytes memory signature) {
        address signer = document[signature].signer;
        require(
            signer == msg.sender,
            "Invalid operation: Not the document Signer!"
        );
        _;
    }

    modifier isSignerWithDocHash(bytes memory signature, bytes32 docHash) {
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signature);
        address signer = ecrecover(docHash, v, r, s);
        require(
            signer == msg.sender,
            "Invalid operation: Not the document Signer!"
        );
        _;
    }

    modifier isNotIssued(bytes memory signature) {
        require(
            document[signature].status == STATUS_NOT_ISSUED,
            "Invalid operation: Document already issued!"
        );
        _;
    }

    modifier isActive(bytes memory signature) {
        require(
            document[signature].status == STATUS_ACTIVE,
            "Invalid operation: Document is not active!"
        );
        _;
    }

    modifier isSuspended(bytes memory signature) {
        require(
            document[signature].status == STATUS_SUSPENDED,
            "Invalid operation: Document is not suspended!"
        );
        _;
    }

    function activateDocument(bytes memory _signature, bytes32 _docHash)
        external
        isValidSignature(_signature)
        isSignerWithDocHash(_signature, _docHash)
        isNotIssued(_signature)
    {
        document[_signature].docHash = _docHash;
        document[_signature].signer = msg.sender;
        document[_signature].index = issuedDocuments[msg.sender]++;
        document[_signature].status = STATUS_ACTIVE;

        documentByIssuer[msg.sender].push(_signature);

        emit DocumentActivated(_signature);
    }

    function suspendDocument(bytes memory signature)
        external
        isSigner(signature)
        isActive(signature)
    {
        document[signature].status = STATUS_SUSPENDED;

        emit DocumentSuspended(signature);
    }

    function unsuspendDocument(bytes memory signature)
        external
        isSigner(signature)
        isSuspended(signature)
    {
        document[signature].status = STATUS_ACTIVE;

        emit DocumentUnsuspended(signature);
    }

    function revokeDocument(bytes memory signature)
        external
        isSigner(signature)
    {
        document[signature].status = STATUS_REVOKED;

        emit DocumentRevoked(signature);
    }

    function signatureSplit(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signature, 0x41)), 0xff)
        }
    }
}