// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UPIToAddress {
    mapping(bytes32 => address) private upiIds;

    event UPIAdded(bytes32 upiId, address upiAddress);

    function linkUPI(string memory _upi) external {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        require(upiIds[_hash] == address(0), "UPI already exists");
        upiIds[_hash] = msg.sender;
    }

    function transferUPI(string memory _upi, address _to) external {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        require(upiIds[_hash] == msg.sender, "You are not the owner of this UPI");
        upiIds[_hash] = _to;
    }

    function getAddress(string memory _upi) external view returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        return upiIds[_hash];
    }

    function getUPIHash(string memory _upi) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_upi));
    }
}