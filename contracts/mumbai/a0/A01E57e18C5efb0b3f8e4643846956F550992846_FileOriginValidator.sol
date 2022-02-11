/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FileOriginValidator {

    event AddFile(address _addedBy, bytes32 _fileHash);

    struct FileMetadata {
      address origin;
      uint256 createdAt;
      bool exists;
    }

    mapping (bytes32 => FileMetadata) hashToFileMetadata;

    function addFile(bytes32 _fileHash) external returns (bool) {
        require(!hashToFileMetadata[_fileHash].exists, 'File already exists');

        hashToFileMetadata[_fileHash] = FileMetadata(
          msg.sender,
          block.timestamp,
          true
        );

        emit AddFile(msg.sender, _fileHash);
        return true;
    }

    function validateFileOrigin(
      address _originAddress,
      bytes32 _fileHash
    ) external view returns (bool) {
      FileMetadata memory file = hashToFileMetadata[_fileHash];
      require(file.exists, 'File doesnt exists');
      return _originAddress == file.origin;
    }

    function getFileOrigin(bytes32 _fileHash) external view returns (address) {
      FileMetadata memory file = hashToFileMetadata[_fileHash];
      require(file.exists, 'File doesnt exists');
      return file.origin;
    }

}