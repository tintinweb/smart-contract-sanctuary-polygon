/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

//import "hardhat/console.sol";

contract Originstamp {
    address public owner;
    mapping(bytes32 => uint256) public docRegistrationTime;
    mapping(bytes32 => uint256) public validUntil;
    mapping(bytes32 => bytes32) public prevVersions;
    mapping(bytes32 => bytes32) public newVersions;

    event Registered(bytes32 indexed docHash, uint256 indexed validUntil);
    event Revoked(bytes32 indexed docHash);
    event NewVersionRegistered(
        bytes32 indexed newDocHash,
        bytes32 indexed expiredDocHash,
        uint256 newDocValidUntil,
        uint256 versionNumber
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(bytes32 _docHash, uint256 _validUntil) public onlyOwner {
        uint256 _time = docRegistrationTime[_docHash];
        require(_time == 0, "Document hash already registered");

        if (_validUntil > 0) {
            require(_validUntil > block.timestamp, "Valid until should be in future");
            validUntil[_docHash] = _validUntil;
        }

        docRegistrationTime[_docHash] = block.timestamp;
        emit Registered(_docHash, _validUntil);
    }

    function registerMultiply(bytes32[] calldata _docHashes, uint256[] calldata _validUntil) external onlyOwner {
        require(_docHashes.length == _validUntil.length, "Documents hash list and valid until list should be same size");

        for(uint i = 0; i < _docHashes.length; i++) {
            register(_docHashes[i], _validUntil[i]);
        }
    }

    function registerNewVersion(bytes32 _newDocHash, bytes32 _expiredDocHash, uint256 _newDocValidUntil) public onlyOwner {
        uint256 _newDocRegistrationTime = docRegistrationTime[_newDocHash];
        require(_newDocRegistrationTime == 0, "New document hash already registered");

        uint256 _expiredDocRegistrationTime = docRegistrationTime[_expiredDocHash];
        require(_expiredDocRegistrationTime > 0, "Expired document hash was not registered");

        bytes32 _hash = newVersions[_expiredDocHash];
        require(_hash == "", "Expired document already has new version registered");

        uint256 _version = getVersionNumber(_expiredDocHash);

        register(_newDocHash, _newDocValidUntil);

        newVersions[_expiredDocHash] = _newDocHash;
        prevVersions[_newDocHash] = _expiredDocHash;
        emit NewVersionRegistered(_newDocHash, _expiredDocHash, _newDocValidUntil, _version + 1);
    }

    function registerNewVersionMultiply(
        bytes32[] calldata _newDocHashes,
        bytes32[] calldata _expiredDocHashes,
        uint256[] calldata _newDocValidUntil
    ) external onlyOwner {
        require(_newDocHashes.length == _expiredDocHashes.length, "New documents hash list and expired documents hash list should be same size");
        require(_newDocHashes.length == _newDocValidUntil.length, "New documents hash list and valid until list should be same size");

        for(uint i = 0; i < _newDocHashes.length; i++) {
            registerNewVersion(_newDocHashes[i], _expiredDocHashes[i], _newDocValidUntil[i]);
        }
    }

    function revoke(bytes32 _docHash) external onlyOwner {
        uint256 _time = docRegistrationTime[_docHash];
        require(_time != 0, "Document hash does not registered");

        validUntil[_docHash] = block.timestamp;

        emit Revoked(_docHash);
    }

    function getVersionNumber(bytes32 _docHash) public view returns (uint versionNumber) {
        if (docRegistrationTime[_docHash] == 0) {
            return 0;
        }
        bytes32 _tmpHash = _docHash;
        do {
            versionNumber++;
            _tmpHash = prevVersions[_tmpHash];
        } while (_tmpHash != 0);

        return versionNumber;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
}