/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Storage {
    event FileUploaded(
        uint256 fileId,
        string fileHash,
        uint256 fileSize,
        string fileType,
        string fileName,
        uint256 uploadTime,
        address uploader
    );
    struct File {
        uint256 fileId;
        string fileHash;
        uint256 fileSize;
        string fileType;
        string fileName;
        uint256 uploadTime;
        address uploader;
    }

    constructor() {}

    uint256 public fileCount = 0;
    mapping(address => File[]) public files;

    function uploadFile(
        string memory _fileHash,
        uint _fileSize,
        string memory _fileType,
        string memory _fileName
    ) public {
        // Make sure the file hash exists
        require(bytes(_fileHash).length > 0);
        require(bytes(_fileType).length > 0);
        require(bytes(_fileName).length > 0);
        require(msg.sender != address(0));
        require(_fileSize > 0);

        fileCount++;
        files[msg.sender].push(
            File(
                fileCount,
                _fileHash,
                _fileSize,
                _fileType,
                _fileName,
                block.timestamp,
                msg.sender
            )
        );

        emit FileUploaded(
            fileCount,
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            block.timestamp,
            msg.sender
        );
    }
}