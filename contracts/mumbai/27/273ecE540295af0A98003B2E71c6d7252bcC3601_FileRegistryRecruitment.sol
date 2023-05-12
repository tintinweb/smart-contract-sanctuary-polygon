/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

//SPDX-License-Identifier: Proprietary
/// @author Exsis Digital Angels
/// @dev Specifies the version of Solidity, using semantic versioning.
pragma solidity ^0.8.0;
/// @dev Contract developed to verify file hashes and metadata, basic functions like store, verify and delete are provided.
contract FileRegistryRecruitment{
    address public _contractOwner;
    mapping (string => FileInfo) private files;
    struct FileInfo{
        uint256 fileSize; // File size in KB
        string fileName; // Name of the file
        string fileType; // Type of the file
        string uploadedBy; // Name of the user that uploaded the file
        string fileHash; // File hash
    }
    event fileVerified (string fileHash, uint256 verifiedAt);
    event fileCreated (string fileHash);
    event fileDeleted (string fileHash);
    constructor(){
        _contractOwner = msg.sender;
    }
    function storeFile(
        string memory _fileHash, 
        string memory _fileName, 
        string memory _fileType, 
        string memory _uploadedBy, 
        uint256 _fileSize
    ) public {
        require(msg.sender == _contractOwner, "Error: You are not authorized to use this function.");
        require(bytes(files[_fileHash].fileHash).length == 0, "Error: This file was previously stored in the file registry.");
        files[_fileHash] = FileInfo({
            fileHash: _fileHash,
            fileName: _fileName,
            fileType: _fileType,
            fileSize: _fileSize,
            uploadedBy: _uploadedBy
        });
        emit fileCreated(_fileHash);
    }
    function verifyFile(
        string memory _fileHash, 
        string memory _fileName, 
        string memory _fileType, 
        string memory _uploadedBy, 
        uint256 _fileSize
    ) public returns (bool) {
        require(msg.sender == _contractOwner, "Error: You are not authorized to use this function.");
        
        FileInfo storage fileInfo = files[_fileHash];
        
        require(bytes(fileInfo.fileHash).length != 0, "No match: Hash not found in the blockchain");
        
        require(keccak256(bytes(fileInfo.fileName)) == keccak256(bytes(_fileName)), "Partial match: Correct hash, incorrect file name");
        require(keccak256(bytes(fileInfo.fileType)) == keccak256(bytes(_fileType)), "Partial match: Correct hash, incorrect file type");
        require(keccak256(bytes(fileInfo.uploadedBy)) == keccak256(bytes(_uploadedBy)), "Partial match: Correct hash, incorrect uploader");
        require(fileInfo.fileSize == _fileSize, "Partial match: Correct hash, incorrect file size");

        emit fileVerified(_fileHash, block.timestamp);
        return true;
    }
    function getFile(string memory _fileHash) public view returns(FileInfo memory file){
        require(msg.sender == _contractOwner, "Error: You are not authorized to use this function.");
        require(bytes(files[_fileHash].fileHash).length != 0, "File not found.");
        return files[_fileHash];
    }
    function deleteFile(string memory _fileHash) public {
        require(msg.sender == _contractOwner, "Error: You are not authorized to use this function.");
        FileInfo storage fileInfo = files[_fileHash];
        require(bytes(fileInfo.fileHash).length != 0, "Error: File not found in the blockchain.");
        delete files[_fileHash];
        emit fileDeleted(_fileHash);
    }
}