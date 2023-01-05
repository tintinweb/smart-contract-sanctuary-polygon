/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-license-Indentifier: MIT
pragma solidity ^0.5.0;

contract Creativecopyrights {
  string public name = 'Creativecopyrights';
  uint public fileCount = 0;
  uint public transactionCount = 0;
  uint public testCount = 0;
  mapping(uint => File) public files;
  mapping(uint => Transaction) public transaction;


  struct Transaction{
    uint transactionId;
    uint imageId;
    string transactionHash;
  }

  struct File {
    uint fileId;
    string fileHash;
    uint fileSize;
    string fileType;
    string fileName;
    string fileDescription;
    uint uploadTime;
    address payable uploader;
  }

  event FileUploaded(
    uint fileId,
    string fileHash,
    uint fileSize,
    string fileType,
    string fileName, 
    string fileDescription,
    uint uploadTime,
    address payable uploader
  );

  event SaveTransactionHash(
    uint transactionId,
    uint imageId,
    string transactionHash
  );

  constructor() public {
  }

  function uploadFile(string memory _fileHash, uint _fileSize, string memory _fileType, string memory _fileName, string memory _fileDescription) public {
    // Make sure the file hash exists
    require(bytes(_fileHash).length > 0);
    // Make sure file type exists
    require(bytes(_fileType).length > 0);
    // Make sure file description exists
    require(bytes(_fileDescription).length > 0);
    // Make sure file fileName exists
    require(bytes(_fileName).length > 0);
    // Make sure uploader address exists
    require(msg.sender!=address(0));
    // Make sure file size is more than 0
    require(_fileSize>0);

    // Increment file id
    fileCount ++;

    // Add File to the contract
    files[fileCount] = File(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, now, msg.sender);
    // Trigger an event
    emit FileUploaded(fileCount, _fileHash, _fileSize, _fileType, _fileName, _fileDescription, now, msg.sender);
  }

  function saveTransaction(string memory _transactionHash) public {
    transactionCount ++;
    transaction[fileCount] = Transaction(transactionCount, fileCount, _transactionHash);
    emit SaveTransactionHash(transactionCount, fileCount, _transactionHash);

  }
}