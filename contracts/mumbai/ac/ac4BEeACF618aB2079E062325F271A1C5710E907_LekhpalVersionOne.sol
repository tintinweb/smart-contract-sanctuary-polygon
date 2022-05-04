/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract LekhpalVersionOne {

    mapping(bytes32 => mapping(address => bool)) private roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    address private a;

    uint public docCount = 0;
    mapping(uint => Document) public docs;

    struct Document {
        uint id;
        bytes32 hash;
        string department;
        string name;
    }

    event DocumentCreated(
        uint indexed id,
        bytes32 indexed hash,
        string department,
        string name
    );

    constructor() {
        _grantRole(ADMIN, msg.sender);
        a = msg.sender;
    }

    function createDocument(string memory _content, string memory _department, string memory _name) external onlyRole(ADMIN) {
        require(bytes(_content).length > 0);
        docCount ++;
        docs[docCount] = Document(docCount, getMessageHash(_content), _department, _name);
        emit DocumentCreated(docCount, getMessageHash(_content), _department, _name);
    }

    function verifyDocument(bytes memory _key, string memory _content) view public returns (bool) {
        return verify(a, _content, _key);
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Access Denied");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
    }

    function getMessageHash(string memory _content) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_content));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, string memory _content, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_content);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    internal
    pure
    returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}