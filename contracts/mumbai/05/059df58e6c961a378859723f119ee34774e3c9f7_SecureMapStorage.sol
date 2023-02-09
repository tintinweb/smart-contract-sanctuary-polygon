/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

pragma solidity ^0.8.0;

contract SecureMapStorage {
    mapping(address => bytes32) public dataMap;

    function setData(string memory _data) public {
        require(dataMap[msg.sender] == 0x0, "Data for this address already exists");
        dataMap[msg.sender] = bytes32(keccak256(abi.encodePacked(_data)));
    }

    function deleteData() public {
        require(dataMap[msg.sender] != 0x0, "Data for this address does not exist");
        dataMap[msg.sender] = 0x0;
    }

    function getData() public view returns (string memory) {
        require(dataMap[msg.sender] != 0x0, "Data for this address does not exist");
        bytes memory encodedData = abi.encodePacked(dataMap[msg.sender]);
        return abi.decode(encodedData, (string));
    }
}