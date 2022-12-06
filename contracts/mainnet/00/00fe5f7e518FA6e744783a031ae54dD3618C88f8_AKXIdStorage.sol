// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract AKXIdStorage {

    bytes32 private AKXID_STORAGE_SLOT = keccak256("akx.akxid.store");

    mapping(bytes32 => bool) private _nonce;

    address public owner;

    struct AKXIds {
        mapping(string => string) _ids;
        mapping(string => string) _names;
    }

    constructor() {
        owner = msg.sender;
    }

    function akxStore() internal pure returns(AKXIds storage s) {

            assembly {
                s.slot := AKXID_STORAGE_SLOT.slot
            }

    }

    function storeID(string memory _name, string memory _id) public onlyOwner {
        AKXIds storage s = akxStore();
        s._ids[_name] = _id;
        s._names[_id] = _name;

    }

    function getID(string memory _name) public view returns(string memory) {
        AKXIds storage s = akxStore();
        return s._ids[_name];
    }

    function getName(string memory _id) public view returns(string memory) {
        AKXIds storage s = akxStore();
        return s._names[_id];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not allowed");
        _;
    }

}