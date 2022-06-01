/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract LekhpalVersionTwo {

    mapping(bytes32 => mapping(address => bool)) private roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    address private a;

    uint public docCount = 0;
    mapping(string => Document) public docs;

    struct Document {
        uint index;
        string uid;
        bytes32 hash;
        string data;
        string doc_id;
        string doc_type;
        string event_date;
    }

    event DocumentCreated(
        uint index,
        string indexed uid,
        bytes32 indexed hash,
        string data,
        string indexed doc_id,
        string doc_type,
        string event_date
    );

    constructor() {
        _grantRole(ADMIN, msg.sender);
        a = msg.sender;
    }

    function createDocument(
        string memory _content,
        string memory _data,
        string memory _uid,
        string memory _doc_type,
        string memory _doc_id,
        string memory _event_date
    ) external onlyRole(ADMIN) {
        require(bytes(_content).length > 0);
        docCount ++;
        docs[_uid] = Document(docCount, _uid, getMessageHash(_content), _data, _doc_id, _doc_type, _event_date);
        emit DocumentCreated(docCount, _uid, getMessageHash(_content), _data, _doc_id, _doc_type, _event_date);
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