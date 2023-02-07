//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
//Contract Address: 0x890FfbCbdb6a5DebC746C6cBdb741fc5649c535B


contract KYC {

    //Data struct
    struct Data {
        address Customer_address;
        bytes32 CustomerdataHash;
        bool isAllowed;
    }

    //Mapping for custom data types
    mapping(bytes32 => Data) public CustomerData;
    mapping(address => bool) public auditoraddresses;
    mapping(address => bool) public verificatoraddresses;

    //State variables
    address admin;

    //Set admin to one who deploy this contract

    constructor () {
        admin = msg.sender;
    }

    //Modifiers

    //Check if the requestor is the admin
    modifier isAdmin {
        require(
            admin == msg.sender,
            "Only admin is allowed to operate this functionality"
        );
        _;
    }

    //Checks if the auditor has been validated and added by admin
    modifier isAuditorValid {
        require(
            auditoraddresses[msg.sender] == true,
            "Unauthenticated requestor! Only an Auditor added by the admin can operate this function."
        );
        _;
    }

    /*Check Auditor State*/
    function CheckAuditorState(address _addres) public view returns (bool){
         return auditoraddresses[_addres];
    }

    /*Check Verificator State*/
    function CheckVerificatorState(address _addres) public view returns (bool){
         return verificatoraddresses[_addres];
    }

    /*Check Customer State*/
    function CheckCustomerState(address _addr) public view returns (bool){
         bytes32 addressHash = keccak256(abi.encodePacked(_addr));
         return CustomerData[addressHash].isAllowed;
    }


    //Adds customer to customers mapping
    function addCustomer(address _addr, bytes32 _dataHash, bool State)
        public
        isAuditorValid 
    {
        bytes32 addressHash = keccak256(abi.encodePacked(_addr));   
        require(
            CustomerData[addressHash].isAllowed == false,
            "This customer is already present"
        );     
        CustomerData[addressHash].Customer_address = _addr;
        CustomerData[addressHash].CustomerdataHash = _dataHash;
        CustomerData[addressHash].isAllowed = State;
    } 


    //Remove customer mapping
    function removeCustomer(address _addr)
        external
        isAuditorValid
    {
        bytes32 addressHash = keccak256(abi.encodePacked(_addr)); 
        require(
            CustomerData[addressHash].isAllowed == true,
            "This customer does not exist"
        );
        delete CustomerData[addressHash].Customer_address;
        delete CustomerData[addressHash].CustomerdataHash;
        delete CustomerData[addressHash].isAllowed;
    }

    // ----- Admin -----

    //Add new Auditor
    function addAuditor(
        address AuditorAddress
    ) public isAdmin returns (bool) {
        require(
            auditoraddresses[AuditorAddress] == false,
            "Auditor with same address already exists"
        );

        auditoraddresses[AuditorAddress] = true;

        return true;
    }


    //Remove an Auditor from mapping
    function removeAuditor(address AuditorAddress) public isAdmin returns (bool) {
        require(
            auditoraddresses[AuditorAddress] == true,
            "Auditor doesn't exists");

        delete auditoraddresses[AuditorAddress];

        return true;
    }


    //Add new Verificator
    function addVerificator(address VerificatorAddress) public isAdmin returns (bool) {
        require(
            verificatoraddresses[VerificatorAddress] == true,
            "Verificator with same address already exists"
        );

        verificatoraddresses[VerificatorAddress] = true;

        return true;

    }


    //Remove a Verificator from mapping
    function removeVerificator(address VerificatorAddress) public isAdmin returns (bool) {
        require(
            verificatoraddresses[VerificatorAddress] == true,
            "Verificator doesn't exists"
        );

        delete verificatoraddresses[VerificatorAddress];

        return true;
    }
}