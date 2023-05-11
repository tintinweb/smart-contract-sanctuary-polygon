/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

//SPDX-License-Identifier: 0BSD
/// @author Exsis Digital Angels
/// @dev Specifies the version of Solidity, using semantic versioning.
pragma solidity ^0.8.0;

contract FileRegistryRecruitment{
    address public _contractOwner;
    mapping (string => FileInfo) private files;
    struct FileInfo{
        uint256 fileSize; // File size in KB
        uint256 createdAt; // Date of file creation
        string fileName; // Name of the file
        string fileType; // Type of the file
        string uploadedBy; // Name of the user that uploaded the file
        string fileHash; // File hash
    }
    event FileVerified (string fileHash, bool verified, uint256 verifiedAt, string evaluationResult);
    constructor(){
        _contractOwner = msg.sender;
    }
    function storeFile(
        string memory _fileHash, 
        string memory _fileName, 
        string memory _fileType, 
        string memory _uploadedBy, 
        uint256 _fileSize, 
        uint256 _createdAt
    ) public {
        require(msg.sender == _contractOwner, "You are not authorized to use this function.");
        require(bytes(files[_fileHash].fileHash).length == 0, "This file was previously stored in the file registry.");
        files[_fileHash] = FileInfo({
            fileHash: _fileHash,
            fileName: _fileName,
            fileType: _fileType,
            fileSize: _fileSize,
            createdAt: _createdAt,
            uploadedBy: _uploadedBy
        });
    }
    function verifyFile(
        string memory _fileHash, 
        string memory _fileName, 
        string memory _fileType, 
        string memory _uploadedBy, 
        uint256 _fileSize, 
        uint256 _createdAt
    ) public returns (bool) {
        require(msg.sender == _contractOwner, "You are not authorized to use this function.");
        if(bytes(files[_fileHash].fileHash).length != 0){
            FileInfo storage fileInfo = files[_fileHash];
            if (keccak256(bytes(fileInfo.fileName)) != keccak256(bytes(_fileName))) {
                emit FileVerified(_fileHash, false, block.timestamp, "Partial match: Correct hash, incorrect file name");
                return false;
            }
            if (keccak256(bytes(fileInfo.fileType)) != keccak256(bytes(_fileType))) {
                emit FileVerified(_fileHash, false, block.timestamp, "Partial match: Correct hash, incorrect file type");
                return false;
            }
            if (keccak256(bytes(fileInfo.uploadedBy)) != keccak256(bytes(_uploadedBy))) {
                emit FileVerified(_fileHash, false, block.timestamp, "Partial match: Correct hash, incorrect uploader");
                return false;
            }
            if (fileInfo.fileSize != _fileSize) {
                emit FileVerified(_fileHash, false, block.timestamp, "Partial match: Correct hash, incorrect file size");
                return false;
            }
            if (fileInfo.createdAt != _createdAt) {
                emit FileVerified(_fileHash, false, block.timestamp, "Partial match: Correct hash, incorrect creation date");
                return false;
            }
            emit FileVerified(_fileHash, true, block.timestamp, "Exact match: hash and metadata verified");
            return true;
        }
        emit FileVerified(_fileHash, false, block.timestamp, "Hash not found in the blockchain");
        return false;
    }
    function getFile(string memory _fileHash) public view returns(FileInfo memory file){
        require(msg.sender == _contractOwner, "You are not authorized to use this function.");
        require(bytes(files[_fileHash].fileHash).length != 0, "File not found.");
        return files[_fileHash];
    }
    function deleteFile(string memory _fileHash) public {
        require(msg.sender == _contractOwner, "You are not authorized to use this function.");
        require(bytes(files[_fileHash].fileHash).length != 0, "File not found.");
        delete files[_fileHash];
    }
}