/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract healthcare{

    //patient structure
    struct patient{
        string patientName;
        uint patientId;
        uint age;
        uint contact;
        address patientAddress;
        
    }

    //storing multiple patients
    mapping(uint => patient) public patients;


    //medicine structure
    struct medicine{
        uint dated;
        string medicineName;
        uint dosage; //no. of medicines
        uint dosageDuration; //no. of days the medicine is given for
        string instruction; //after meal or before meal


    }

    
    //assigning medicines according to patientId
    mapping(uint=>medicine) public assignedMedicines;

    uint256 tempId=0;

    //doctor structure
    struct doctor{
        string name;
        address docAddress;
    }
    // patientId--> Doctor
    mapping(uint=>doctor) public doctors;

    //registring patients
    function registerPatient(string memory _name, uint _age ,uint _contact) public  {

        patients[tempId]= patient(_name,tempId,_age,_contact,msg.sender);
        returnId();
        tempId++;
    }

    //assigning medicines
    function patientMedicines(uint _patientId , string memory _medName, uint _dosage , uint _dosageDuration , string memory _instructions) public {
     require(doctors[_patientId].docAddress== msg.sender); 
    assignedMedicines[_patientId] = medicine(block.timestamp,_medName,_dosage,_dosageDuration,_instructions);
   }

   //patients patientId
   function returnId() private view returns(uint) {
       return patients[tempId].patientId;

   }


   //Adding doctors to patient profile
   function addDoctor(uint _patientId, address _docAddress ,string memory _docName) public{
       doctors[_patientId]= doctor(_docName,_docAddress);

   }



  





















}