//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract C2EDID {
    uint256 autoID;

    struct DID {
        uint256 id;
        string didDoc;
    }

    modifier onlyController() {
        require(
            _isArrayContain(controllers[dids[msg.sender].id], msg.sender),
            "message sender is not the controller of the DID Doc"
        );
        _;
    }

    mapping(address => DID) public dids;
    mapping(uint256 => address[]) controllers;

    event DIDCreated(address sender, uint256 didID, string doc);
    event DIDUpdated(
        address sender,
        uint256 didID,
        string doc,
        address[] addedAddresses
    );
    event DIDDeleted(address sender, uint256 didID);

    event TransferOwnership(address newOwner);

    function createDID(string memory _doc) external {
        require(dids[msg.sender].id == 0, "address already had did");
        uint256 _didID = ++autoID;
        DID memory _did = DID(_didID, _doc);
        dids[msg.sender] = _did;
        controllers[_didID].push(msg.sender);

        emit DIDCreated(msg.sender, _didID, _doc);
    }

    function updateDIDDoc(
        string memory _doc,
        address[] memory _addresses
    ) external onlyController {
        DID storage _did = dids[msg.sender];
        address[] storage _controllers = controllers[_did.id];
        require(
            !_isArrayMatched(controllers[_did.id], _addresses),
            "address already added"
        );

        _did.didDoc = _doc;

        for (uint i = 0; i < _addresses.length; i++) {
            _controllers.push(_addresses[i]);
            dids[_addresses[i]] = _did;
        }

        emit DIDUpdated(msg.sender, _did.id, _doc, _addresses);
    }

    function deleteDIDDoc() external onlyController {
        DID memory _did = dids[msg.sender];
        address[] memory _controllers = controllers[_did.id];

        for (uint i = 0; i < _controllers.length; i++) {
            delete dids[_controllers[i]];
        }

        delete controllers[_did.id];
        emit DIDDeleted(msg.sender, _did.id);
    }

    function getDIDDoc(address _address) external view returns (string memory) {
        return dids[_address].didDoc;
    }

    function _isArrayMatched(
        address[] memory _arr,
        address[] memory _items
    ) private pure returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            for (uint j = 0; j < _items.length; j++) {
                if (_arr[i] == _items[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _isArrayContain(
        address[] memory _arr,
        address _item
    ) private pure returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _item) {
                return true;
            }
        }
        return false;
    }
}