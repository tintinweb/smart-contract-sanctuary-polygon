// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Owner{

    event OwnershipTransferred(address _previousOwner,address _newOwner);

    address _owner;

    constructor(){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0),_owner);
    }

    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner returns(bool){
        _owner = _newOwner;
        emit OwnershipTransferred(_owner,_newOwner);
        return true;

    }

    function renounceOwnership() public onlyOwner returns(bool){
          transferOwnership(address(0));
          return true;
    }

}

contract Dcube{

    event CidGenerate(address indexed User,string indexed CID,uint TimeStamp,string FileName);


    struct uploadedFile{
        string CID;
        uint timeStamp;
        string fileName;
    }

    struct importedFile{
        string CID;
        uint timeStamp;
        string fileName;
    }



    mapping(address => mapping(uint=>uploadedFile)) public userUploads;
    mapping(address => mapping(uint=>importedFile)) public userImports;
    mapping(address=> uint) public fileCount;

    
    function uploadfile(string calldata _cid,string memory _fileName) public returns(bool){
        userUploads[msg.sender][fileCount[msg.sender]] = uploadedFile(_cid,block.timestamp,_fileName);
        fileCount[msg.sender]++;
        emit CidGenerate(msg.sender,_cid,block.timestamp,_fileName);
        return true;
    }


    function getUploadFile() external payable returns(uploadedFile[] memory){
         uploadedFile[] memory temp = new uploadedFile[](fileCount[msg.sender]);
         for(uint i=0;i<fileCount[msg.sender];i++) temp[i] = userUploads[msg.sender][i];
         return temp;
    }

}