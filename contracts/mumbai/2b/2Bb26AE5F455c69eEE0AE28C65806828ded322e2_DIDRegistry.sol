//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DIDRegistry {

    struct DID {
        address controller;
        string didString;
        string didDocumentUrl;
        string didDocumentChecksum;
        bool deleted;
    }

    event DIDRegistered(DID newDID);
    event DIDUpdated(DID oldDID, DID newDID);
    event DIDControllerUpdated(DID newDID, address oldController, address newController);
    event DIDDeleted(DID deletedDID);

    mapping(string => DID) public dids;

    function registerDID(address _controller, string memory _didString, string memory _didDocumentUrl, string memory _didDocumentChecksum) public {
        DID memory existingDID = dids[_didString];
        require(bytes(existingDID.didString).length == 0, "This DID has already been registered");

        DID memory newDID = DID({
            controller: _controller,
            didString: _didString,
            didDocumentUrl: _didDocumentUrl,
            didDocumentChecksum: _didDocumentChecksum,
            deleted: false
        });

        dids[_didString] = newDID;
        emit DIDRegistered(newDID);
    }

    function updateDID(string memory _didString, string memory _didDocumentUrl, string memory _didDocumentChecksum) public {
        DID memory existingDID = dids[_didString];
        require(msg.sender == existingDID.controller, "You are not the DID controller");
        require(!existingDID.deleted, "The DID has been deleted");

        DID memory newDID = DID({
            controller: existingDID.controller,
            didString: _didString,
            didDocumentUrl: _didDocumentUrl,
            didDocumentChecksum: _didDocumentChecksum,
            deleted: false
        });

        dids[_didString] = newDID;
        emit DIDUpdated(existingDID, newDID);
    }

    function updateDIDController(string memory _didString, address _newController) public {
        DID memory existingDID = dids[_didString];
        require(msg.sender == existingDID.controller, "You are not the DID controller");
        require(!existingDID.deleted, "The DID has been deleted");

        DID memory newDID = DID({
            controller: _newController,
            didString: _didString,
            didDocumentUrl: existingDID.didDocumentUrl,
            didDocumentChecksum: existingDID.didDocumentChecksum,
            deleted: false
        });

        dids[_didString] = newDID;
        emit DIDControllerUpdated(newDID, existingDID.controller, _newController);
    }

    function deleteDID(string memory _didString) public {
        DID memory existingDID = dids[_didString];
        require(msg.sender == existingDID.controller, "You are not the DID controller");
        require(!existingDID.deleted, "The DID has been deleted");

        DID memory deletedDID = DID({
            controller: existingDID.controller,
            didString: existingDID.didString,
            didDocumentUrl: existingDID.didDocumentUrl,
            didDocumentChecksum: existingDID.didDocumentChecksum,
            deleted: true
        });

        dids[_didString] = deletedDID;
        emit DIDDeleted(deletedDID);
    }

    function resolveDID(string memory _didString) public view returns (DID memory) {
        return dids[_didString];
    }
}