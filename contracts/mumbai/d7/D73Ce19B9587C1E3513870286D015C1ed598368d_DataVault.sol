//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum Status{
    Absent,
    Present
}

struct AadhaarHolder{
    address ssi_address;
    string AadhaarHolderName;
    string AadhaarSignature; 
    // dob
    // address
}

struct ConsumerAgency{
    uint256 agencyID;
    string agency_name;
    address[] AdminList;
    //address[] RegAadharList;
    AadhaarHolder[] RegAadharList;  // will it consume more gas fee compared to above
    mapping(address => Status) agency_AdminStatus;
    mapping(address => Status) agency_RegAadhaarStatus;
}

contract DataVault {
    uint256 ID; // later to be assigned on server
    string[]  AdharList;


    mapping(uint256 => ConsumerAgency) public RegAgencies;
    mapping(address => AadhaarHolder) public RegAadhaarHolders;
    

    event AgencyRegistered(string name, address regAdmin);
    event AadhaarHolderRegistered(address RegAadhaarAddress, string name, string AadharSig);
   

    constructor(){
        ID = 0;
    } // why we use constructor here??


//*********************MODIFIERS START***************************
    modifier isAdmin(uint256 id){
        require(RegAgencies[id].agency_AdminStatus[msg.sender] == Status.Present,
         "Access denied");
         _;
    }

    modifier isAadharHolderAlreadyRegister(address AadharHolderWalletAddress){
        require(RegAadhaarHolders[AadharHolderWalletAddress].ssi_address != 0x0000000000000000000000000000000000000000,
        "User Does Not Exist");
        _;
    }
//*********************MODIFIERS END***************************


//*******************ALL REGISTERATION FUNCTIONS START***************************
    function RegisterNewAadhaarHolder(string memory name, string memory AadharSig) public returns(bool){
        require(RegAadhaarHolders[msg.sender].ssi_address == 0x0000000000000000000000000000000000000000,"User already Exist");
        RegAadhaarHolders[msg.sender].AadhaarHolderName = name;
        RegAadhaarHolders[msg.sender].ssi_address = msg.sender;
        RegAadhaarHolders[msg.sender].AadhaarSignature = AadharSig;
        emit AadhaarHolderRegistered(msg.sender, RegAadhaarHolders[msg.sender].AadhaarHolderName, //Can be removed
        RegAadhaarHolders[msg.sender].AadhaarSignature);
        return true;  // for acknowledment LATTER TO BE REMOVED
    }

    function RegisterAgency(string memory name) public returns(uint){  // should take id as parameter
        ID += 1; // to be done in node layer
        RegAgencies[ID].agency_name = name;
        RegAgencies[ID].agencyID = ID;
        RegAgencies[ID].AdminList.push(msg.sender);
        RegAgencies[ID].agency_AdminStatus[msg.sender] = Status.Present;
        emit AgencyRegistered(RegAgencies[ID].agency_name, msg.sender);
        return RegAgencies[ID].agencyID;  // to be done in node layer
    }

    function RegisterAadhaarInAgency(uint256 id, address AadharHolderWalletAddress) public isAdmin(id) isAadharHolderAlreadyRegister(AadharHolderWalletAddress){ //Aadhaar holder registration
        RegAgencies[id].agency_RegAadhaarStatus[AadharHolderWalletAddress] = Status.Present;
        RegAgencies[id].RegAadharList.push(RegAadhaarHolders[AadharHolderWalletAddress]);
    } 
//*******************ALL REGISTERATION FUNCTIONS END***************************


//*******************ALL RETRIVAL FUNCTIONS START***************************
    function getAllAgencyAdmins(uint256 id) public view returns(address[] memory){
        return RegAgencies[id].AdminList;
    }

    function getAllAadharInAgency(uint256 id) public view returns(AadhaarHolder[] memory){
        return RegAgencies[id].RegAadharList;
    }
    // function getSSIAddressList(uint256 id) internal view returns(address[] memory){
    //     return RegAgencies[id].RegAadharList;
    // }

    // function getAgencyUsers(uint256 id) internal view returns(string[] memory){
    //     address[] memory addressList = getSSIAddressList(id);
    //     string[] memory userList = new string[](addressList.length);
    //     for(uint i = 0; i < addressList.length; i++){
    //         userList[i] = RegAadhaarHolders[addressList[i]].AadhaarSignature;
    //     }
    //     return userList;
    // }
    
    // function getAllAadharInAgency(uint256 id) public returns(string[] memory){
    //     delete AdharList;
    //     return getAgencyUsers(id);
    // }
//*******************ALL RETRIVAL FUNCTIONS END***************************


//*******************ALL ADMIN FUNCTIONS START***************************
    function MarkRegAadhaarAbsent(uint256 id, address RegAadhaarAddress) public isAdmin(id){
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status.Absent;
    }

    function MarkRegAadhaarPresent(uint256 id, address RegAadhaarAddress) public isAdmin(id){
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status.Present;
    }

    function MarkAdminAbsent(uint256 id, address RegAadhaarAddress) public isAdmin(id){
        require(RegAgencies[id].AdminList.length > 1);
        RegAgencies[id].agency_AdminStatus[RegAadhaarAddress] = Status.Absent;
    }

    function MarkAdminPresent(uint256 id, address RegAadhaarAddress) public isAdmin(id){
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status.Present;
    }

    function AddAgencyAdmin(uint256 id, address newadminAddress) public isAdmin(id){ 
        RegAgencies[id].AdminList.push(newadminAddress);
        RegAgencies[id].agency_AdminStatus[newadminAddress] = Status.Present;
    } 
//*******************ALL ADMIN FUNCTIONS END***************************
}