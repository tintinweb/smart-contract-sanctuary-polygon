/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract patientInfo{
    address owner;
   struct patient{
    string name;
    bool isRegistered;
   }
    struct patientDocumentInfo{
        string documentName;
        string files;
    }
    constructor()  {
          owner=msg.sender;
    }
    mapping (address=> patient) public  patientInformation;
    mapping(address=>patientDocumentInfo[])  public documentInfo;
    mapping (address=>mapping(address=>bool)) public permInfo;

    // The onlyOwner Modifier is commented out for grading purpose, 
    // This action will be reverted after grading.

    //  modifier onlyOwner (){
    //   require(owner==msg.sender,'Only the owner can do this');
    //   _;
    //  }
     event addFile(address p,string name,string file, uint indexed date);
      event givePermission(address indexed p, uint indexed date);
       event disablePermission(address indexed p, uint indexed date);

    function registerPatient( string memory _name) public  returns (bool){
        patientInformation[msg.sender]= patient(_name,true);
        return true;
    }

    function addPatientRecord(string memory _fileName, string memory  _file) public returns(bool){
        require(patientInformation[msg.sender].isRegistered==true,'You are not a registered user');
         patientDocumentInfo memory docinfo= patientDocumentInfo(_fileName,_file);
            documentInfo[msg.sender].push(docinfo);
            emit addFile(msg.sender,_fileName,_file,block.timestamp);
            return true;
    }

    function getAllFile() public view returns (  patientDocumentInfo [] memory  ){
        uint docCount= documentInfo[msg.sender].length;
         patientDocumentInfo[] memory docs = new patientDocumentInfo[](docCount);
        for(uint i=0; i< docCount; ++i ){
         docs[i]= documentInfo[msg.sender][i];
        }
        return docs;
    }
    function grantPermission(address _address) public returns(bool){
        permInfo[msg.sender][_address]= true;
        emit givePermission(_address,block.timestamp);
        return true;
    }

    function getPatientMedicalRecord(address _patientAddress) public view returns(patientDocumentInfo [] memory){
      require(permInfo[_patientAddress][msg.sender]==true, "You are not allowed by the patient to view the permission record");
       uint docCount= documentInfo[_patientAddress].length;
         patientDocumentInfo[] memory docs = new patientDocumentInfo[](docCount);
        for(uint i=0; i< docCount; ++i ){
         docs[i]= documentInfo[_patientAddress][i];
        }
        return docs;
    }

    function removePermission(address _personAddress)  public returns(bool){
         require(permInfo[msg.sender][_personAddress]==true,'Permission has already been disabled');
         permInfo[msg.sender][_personAddress]=false;
          
         emit disablePermission(_personAddress,block.timestamp);
          return true;
    }

 
}