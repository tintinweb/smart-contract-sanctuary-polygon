/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract OMS_COVID {
    
    //State variables
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "You don't have permissions");
        _;
    }

    //Mapping for to relate a clinic with the system validation (OMS)
    //true -> permission to creat a smart contract
    mapping (address => bool) public Clinic_Validation;
    //Mapping to relate a clinic with their contract
    mapping (address => address) public ClinicTo_Contract;

    //Array to save the valid clinics
    address [] public clinic_directions;
    //Array with the directions that apply to acces
    address [] Requests;
    //Evetns
    event NewRequest(address);
    event NewValidatedContract(address);
    event NewContract(address, address);

    //Function to validate new clinics that can self-manage
    function Clinics(address _clinic) public onlyOwner {
        Clinic_Validation[_clinic] = true;
        emit NewValidatedContract(_clinic);
    }

    //Function to apply for acces to the clinic system
    function Apply() public{
        Requests.push(msg.sender);
        emit NewRequest(msg.sender);
    }

    //Function to see the candidates
    function seeCandidates() public view onlyOwner returns(address [] memory){
        return Requests;
    }

    //Function to create a new smart contract for each clinic
    function ClinicFactory() public {
        //Only the validated centers can acces to this function
        require(Clinic_Validation[msg.sender] == true, "You don't have persmissions");
        //Generate a smart contract
        address clinic_Contract = address (new Clinic(msg.sender));
        //Save the contract direction to the array
        clinic_directions.push(clinic_Contract);
        //Save the realtion between the clinic direction and theit smart contract
        ClinicTo_Contract[msg.sender] = clinic_Contract;
        emit NewContract(clinic_Contract, msg.sender);
    }

}

//Samart contract self-managed for the clinics
contract Clinic {

    address public Clinic_Direction;
    address public SmartContract_Direction;
    
    //Struct Results
    struct Results {
        bool diagnostic;
        string IPFS_code;
    }

    constructor (address _direction) {
        Clinic_Direction = _direction;
        SmartContract_Direction = address(this);
    }

    modifier onlyClinic {
        require(Clinic_Direction == msg.sender, "You don't have permissions");
        _;
    }

    //Mapping to relate the person hash with their Results structure
    mapping (bytes32 => Results) COVIDresults;

    //Events
    event NewResult(string, bool);

    //Function to emit a result of a COVID test
    function resultsCovidTest(string memory _personID, bool _resultTest, string memory _IPFScode) public onlyClinic {
        //ID hash of the patient
        bytes32 hash_personID = keccak256(abi.encodePacked(_personID));
        COVIDresults[hash_personID] = Results(_resultTest, _IPFScode);
        emit NewResult(_IPFScode, _resultTest);
    }

    //Function to see the results
    function seeResults(string memory _personID) public view returns(string memory, string memory) {
        //Hash of the person identity
        bytes32 hash_personID = keccak256(abi.encodePacked(_personID));
        //Return a bool like a string
        string memory TestResult;

        if (COVIDresults[hash_personID].diagnostic == true) {
            TestResult = "Positive";
        }else {
            TestResult = "Negative";
        }

        return(COVIDresults[hash_personID].IPFS_code, TestResult);

    }






}