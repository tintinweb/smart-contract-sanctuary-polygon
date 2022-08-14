//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum Status{
    Absent,
    Present
}

struct ConsumerAgency{ 
    string agency_name;
    uint256 agencyID; // primary key
    mapping(address => Status) agency_AdminStatus;
    mapping(address => Status) agency_UserStatus;
    // mapping(uint256 => AdharHolder[]) AdhartoAgency;
    address[] AdminList;
    address[] UserList; //Commenting to check a dictionary ka solution
}

struct AdharHolder{
    string AadharName;
    address ssi_address;// primary key

    string AadharNo; 
}
contract DataVault {
    mapping(uint256 => ConsumerAgency) public RegAgencies; // Primary key of struct is the key of this dict
    mapping(address => AdharHolder) public RegAdharHolders;
    uint256 ID;

    event AgencyRegistered(string name, address regAdmin);
    event AadharHolderRegistered(address user, string name, string Aadharno);
    // event Test(Status status,address[] adarray);
    constructor(){
        ID = 0;
    }
        // @samyak : There is a problem in this function that user can 
        // can register with same details but different ssi address
    modifier isAdmin(uint256 id){
        require(RegAgencies[id].agency_AdminStatus[msg.sender] == Status.Present,
         "Access denied");
         _;
    }     
    function RegisterUser(string memory name, string memory aadharno) public returns(address){
        require(RegAdharHolders[msg.sender].ssi_address == 0x0000000000000000000000000000000000000000,
        "User already registered");
            RegAdharHolders[msg.sender].AadharName = name;
            RegAdharHolders[msg.sender].ssi_address = msg.sender;
            RegAdharHolders[msg.sender].AadharNo = aadharno;
            emit AadharHolderRegistered(msg.sender, RegAdharHolders[msg.sender].AadharName, 
            RegAdharHolders[msg.sender].AadharNo);
            return msg.sender;
        }

    function RegisterAgency(string memory name) public returns(uint){
        ID += 1;
        RegAgencies[ID].agency_name = name;
        RegAgencies[ID].agencyID = ID;
        RegAgencies[ID].AdminList.push(msg.sender);
        RegAgencies[ID].agency_AdminStatus[msg.sender] = Status.Present;
        
        emit AgencyRegistered(RegAgencies[ID].agency_name, msg.sender);
        return RegAgencies[ID].agencyID;
    }
//, If primary key is changed to adhar no then this has to be changed
// tested for 3 crucial cases
    function RegisterAgencyUser(uint256 id, address useraddress) public {
        require(RegAgencies[id].agency_AdminStatus[msg.sender] == Status.Present &&
         RegAdharHolders[useraddress].ssi_address !=  0x0000000000000000000000000000000000000000,
        "Only Admin can add user in the consumer agency or user does not exist");
        RegAgencies[id].agency_UserStatus[useraddress] = Status.Present;
        RegAgencies[id].UserList.push(useraddress);// Analyse Redundancy
        // RegAgencies[ID].AdhartoAgency[ID] = ;
    }

    function AddAgencyAdmin(uint256 id, address newadmin) public isAdmin(id){
         
         RegAgencies[id].agency_AdminStatus[newadmin] = Status.Present;
         RegAgencies[id].AdminList.push(newadmin);
        //  emit Test(RegAgencies[id].agency_AdminStatus[newadmin],RegAgencies[id].AdminList);
    }

    function MarkUserAbsent(uint256 id, address user) public isAdmin(id){
        RegAgencies[id].agency_UserStatus[user] = Status.Absent;
    }

    function MarkUserPresent(uint256 id, address user) public isAdmin(id){
        RegAgencies[id].agency_UserStatus[user] = Status.Present;
    }

    function MarkAdminAbsent(uint256 id, address user) public isAdmin(id){
        require(RegAgencies[id].AdminList.length > 1);
        RegAgencies[id].agency_AdminStatus[user] = Status.Absent;
    }

    function MarkAdminPresent(uint256 id, address user) public isAdmin(id){
        RegAgencies[id].agency_UserStatus[user] = Status.Present;
    }

    // function RetrieveAgencyAdharHolders(uint256 id) public view returns(string memory){
    //     return RegAgencies[id].AdhartoAgency[id].AadharNo;
    // }
    function AgencyAdmins(uint256 id) public view returns(address[] memory){
        return RegAgencies[id].AdminList;
    } 

    // function getAgencyAdharHolderAddress(uint256 id) public view returns(address[] memory){
    //    return RegAgencies[id].UserList;
    // }

    // function getAadharHolder(address a) public view returns (AdharHolder memory) {
    //     return RegAdharHolders[a];
    // }

    // function getAgencyHolderStruct(uint256 id)public view returns (AdharHolder[] memory){
    //     AdharHolder[] memory agencyAdharList;
    //     address[] memory temp = getAgencyAdharHolderAddress(id);
    //     for(uint256 i = 0;i<temp.length;i+=1){
    //         agencyAdharList.push(getAadharHolder(temp[i]));
    //     }
    //     return agencyAdharList;
    // }

    

}