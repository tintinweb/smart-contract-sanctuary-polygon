/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FileOriginVerifier {

    event AddFile(address _addedBy, bytes32 _fileHash);

    struct FileMetadata {
      address origin;
      uint256 blockNumber;
      bool exists;
    }

    mapping (bytes32 => FileMetadata) hashToFileMetadata;

    function addFile(bytes32 _fileHash) external returns (bool) {
        require(!hashToFileMetadata[_fileHash].exists, 'File already exists');

        hashToFileMetadata[_fileHash] = FileMetadata(
          msg.sender,
          block.number,
          true
        );

        emit AddFile(msg.sender, _fileHash);
        return true;
    }

    function verifyFileOrigin(
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