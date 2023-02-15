// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Dropbox {
    struct File {
        string fileName;
        string fileType;
        string fileHash;
        uint timestamp;
    }

    mapping(address => File[]) public files;

    function uploadFile(
        string memory _fileName,
        string memory _fileType,
        string memory _fileHash
    ) public {
        files[msg.sender].push(
            File(_fileName, _fileType, _fileHash, block.timestamp)
        );
    }

    function getFileCount(address _user) public view returns (uint) {
        return files[_user].length;
    }

    function getFileByIndex(address _user, uint _index)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint
        )
    {
        require(_index < files[_user].length, "Invalid file index");
        return (
            files[_user][_index].fileName,
            files[_user][_index].fileType,
            files[_user][_index].fileHash,
            files[_user][_index].timestamp
        );
    }
}