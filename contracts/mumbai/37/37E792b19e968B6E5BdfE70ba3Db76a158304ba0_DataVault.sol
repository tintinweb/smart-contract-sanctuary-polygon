//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

enum Status {
    Absent,
    Present
}
struct certificate{
        uint256 idFrom;
        uint256 idTo;
        bool status;
        address generatedBy;
}

struct AadhaarHolder {
    address ssi_address;
    string AadhaarHolderName;
    string AadhaarSignature;
    uint256[] subscribedAgencies;
    string phoneNumber;
    string residancyAddress;
}

struct ConsumerAgency {
    uint256 agencyID;
    string agency_name;
    bool ApprovalStatus;
    // Index :: 0 -> ssi address , 1-> AadharHolderName, 2-> AadharSignature,3 -> phoneNumber,4 -> address
    uint256[] Permission; // 0: Not granted , 1 : Granted
    address[] AdminList;
    AadhaarHolder[] RegAadharList;
    uint256 activeAdmincount;
    mapping(address => Status) agency_AdminStatus;
    mapping(address => Status) agency_RegAadhaarStatus;
    mapping(uint256 => address[]) GrantRequests;
}

contract DataVault {
    address public _UIDAI;
    uint256 private ID;

    constructor() {
        ID = 0;
        _UIDAI = msg.sender; // Contract owner
    }

    mapping(uint256 => ConsumerAgency) private RegAgencies;
    mapping(address => AadhaarHolder) private RegAadhaarHolders;
    mapping(address=>uint256) private alreadyRegAgency;
    mapping(uint256 => certificate) Cert;
    mapping(string=>address) private aadhaarCheck;
    string[] checkAadhaar; 
    mapping(uint256 => string) giveName;
    

    //*********************MODIFIERS START***************************
    modifier isAdmin(uint256 id) {
        require(
            RegAgencies[id].ApprovalStatus == true &&
                RegAgencies[id].agency_AdminStatus[msg.sender] ==
                Status.Present,
            "Reverted due to isAdmin modifier.Possible cause : msg.sender not admin or agency is not approved by UIDAI"
        );
        _;
    }

    modifier isAadharHolderAlreadyRegister(address AadharHolderWalletAddress) {
        require(
            RegAadhaarHolders[AadharHolderWalletAddress].ssi_address !=
                0x0000000000000000000000000000000000000000,
            "User Does Not Exist"
        );
        _;
    }

    //*********************MODIFIERS END***************************


    //*******************UIDAI FUNCTIONS START***************************

    function ApproveAgency(uint256 id, bool status) public returns (bool) {
        require(
            msg.sender == _UIDAI,
            "Only UIDAI can submit the approval Status"
        );
        RegAgencies[id].ApprovalStatus = status;
        return RegAgencies[id].ApprovalStatus;
    }
    //*******************UIDAI FUNCTIONS START***************************


    //*******************ALL REGISTERATION FUNCTIONS START***************************
    function RegisterNewAadhaarHolder(
        string memory name,
        string memory AadharSig,
        string memory phoneNumber,
        string memory residancyAddress

    ) public {
        require(
            RegAadhaarHolders[msg.sender].ssi_address ==
                0x0000000000000000000000000000000000000000,
            "User already Exist"
        );
        RegAadhaarHolders[msg.sender].AadhaarHolderName = name;
        RegAadhaarHolders[msg.sender].ssi_address = msg.sender;
        RegAadhaarHolders[msg.sender].AadhaarSignature = AadharSig;
        RegAadhaarHolders[msg.sender].phoneNumber = phoneNumber;
        RegAadhaarHolders[msg.sender].residancyAddress = residancyAddress;
        aadhaarCheck[AadharSig]=msg.sender;
        checkAadhaar.push(AadharSig);
    }

    function RegisterAgency(string memory name, uint256 govtId,uint256[] memory permission)
        public
        returns (uint256)
    {
        require(alreadyRegAgency[msg.sender]==0,"already register");
        ID += 1;
        RegAgencies[ID].agency_name = name;
        RegAgencies[ID].agencyID = govtId;
        RegAgencies[ID].AdminList.push(msg.sender);
        RegAgencies[ID].agency_AdminStatus[msg.sender] = Status.Present;
        RegAgencies[ID].activeAdmincount += 1;
        RegAgencies[ID].Permission = permission;
        RegAgencies[ID].ApprovalStatus = false;
        alreadyRegAgency[msg.sender] = ID;
        giveName[ID] = name;
        return RegAgencies[ID].agencyID;
    }

    function RegisterAadhaarInAgency(
        uint256 id,
        address AadharHolderWalletAddress
    )
        public
        isAdmin(id)
        isAadharHolderAlreadyRegister(AadharHolderWalletAddress)
    {
        require(
            RegAgencies[id].agency_RegAadhaarStatus[
                AadharHolderWalletAddress
            ] != Status.Present,
            "Duplication prohibited"
        );
        RegAgencies[id].agency_RegAadhaarStatus[
            AadharHolderWalletAddress
        ] = Status.Present;

        RegAgencies[id].RegAadharList.push(
        RegAadhaarHolders[AadharHolderWalletAddress]
        );

        
        RegAadhaarHolders[AadharHolderWalletAddress].subscribedAgencies.push(
            id
        );
    }
    

    //*******************ALL REGISTERATION FUNCTIONS END***************************


    //*******************ALL RETRIVAL FUNCTIONS START***************************

    function giveAadhaar()public view returns (string[] memory){
        return checkAadhaar;
    }

    // function getAllRegisteredAgencyName()public view returns(uint256[] memory,string[] memory){
    //     uint256[] memory idarray = new uint256[](ID + 1);
    //     string[] memory namearray = new string[](ID + 1);
    //     for (uint256 i = 1; i <= ID; i += 1) {
    //         idarray[i] = i;
    //         namearray[i] = RegAgencies[i].agency_name;
    //     }
    //     return(idarray,namearray);
    // }

    //function getAllAgencyDetails() public view returns

    function getAadharHolderData(uint256 id, address AadharHolderWalletAddress)
        public
        view
        returns (AadhaarHolder memory)
    {
        AadhaarHolder memory response;
        if (RegAgencies[id].Permission[0] == 1) {
            response.ssi_address = RegAadhaarHolders[AadharHolderWalletAddress]
                .ssi_address;
        }
        if (RegAgencies[id].Permission[1] == 1) {
            response.AadhaarHolderName = RegAadhaarHolders[
                AadharHolderWalletAddress
            ].AadhaarHolderName;
        }
        if (RegAgencies[id].Permission[2] == 1) {
            response.AadhaarSignature = RegAadhaarHolders[
                AadharHolderWalletAddress
            ].AadhaarSignature;
        }
        if (RegAgencies[id].Permission[3] == 1) {
            response.phoneNumber = RegAadhaarHolders[
                AadharHolderWalletAddress
            ].phoneNumber;
        }
        if (RegAgencies[id].Permission[4] == 1) {
            response.residancyAddress = RegAadhaarHolders[
                AadharHolderWalletAddress
            ].residancyAddress;
        }
        return response;
    }
    function getAadharHolderData(uint256 id) internal view  returns (AadhaarHolder[] memory) {
        AadhaarHolder[] memory response = new AadhaarHolder[](RegAgencies[id].RegAadharList.length);
        for (uint256 i = 0; i < RegAgencies[id].RegAadharList.length; i++) {
            response[i] = getAadharHolderData(id, RegAgencies[id].RegAadharList[i].ssi_address);  
                 }
        return response;
    }
    
    function getMyAadharData(address AadharHolderWalletAddress)
        public
        view
        returns (AadhaarHolder memory)
    {
        require(
            msg.sender == AadharHolderWalletAddress,
            "Only user can access their entire data"
        );
        return RegAadhaarHolders[AadharHolderWalletAddress];
    }

    function CheckPermissionAccess(address AadharHolderWalletAddress)
        public
        view
        returns (uint256[][] memory)
    {
        uint256[] memory temp = RegAadhaarHolders[AadharHolderWalletAddress]
            .subscribedAgencies;
        uint256[][] memory array = new uint256[][](temp.length);
        for (uint256 i = 0; i < temp.length; i += 1) {
            array[i] = RegAgencies[temp[i]].Permission;
        }
        return array;
    }

    function getAllAgencyData()
        public
        view
        returns (
            uint256[] memory,
            string[] memory,
            bool[] memory,
            uint256[][] memory,
            address[][] memory,
            AadhaarHolder[][] memory
        )
    {
        uint256[] memory array = new uint256[](ID + 1);
        string[] memory array1 = new string[](ID + 1);
        bool[] memory array2 = new bool[](ID + 1);
        uint256[][] memory array3 = new uint256[][](ID + 1);
        address[][] memory array4 = new address[][](ID + 1);
        AadhaarHolder[][] memory array5 = new AadhaarHolder[][](ID + 1);
        for (uint256 i = 1; i <= ID; i += 1) {
            array[i] = i;
            array1[i] = RegAgencies[i].agency_name;
            array2[i] = RegAgencies[i].ApprovalStatus;
            array3[i] = RegAgencies[i].Permission;
            array4[i] = RegAgencies[i].AdminList;
        }
        return (array, array1, array2, array3, array4,array5);
    }
    
    function getAllAgencyRegAadhaarCount()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](ID + 1);
        for (uint256 i = 1; i <= ID; i += 1) {
            array[i] = RegAgencies[i].RegAadharList.length;
        }
        return array;
    }

    //*******************ALL RETRIVAL FUNCTIONS END***************************

    //*******************ALL ADMIN FUNCTIONS START***************************
    function MarkRegAadhaarAbsent(uint256 id, address RegAadhaarAddress)
        public
        isAdmin(id)
    {
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status
            .Absent;
    }

    function MarkRegAadhaarPresent(uint256 id, address RegAadhaarAddress)
        public
        isAdmin(id)
    {
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status
            .Present;
    }

    function MarkAdminAbsent(uint256 id, address RegAadhaarAddress)
        public 
        isAdmin(id)
    {
        require(
            RegAgencies[id].activeAdmincount > 1,
            "Admins list cannot be zero"
        );
        RegAgencies[id].agency_AdminStatus[RegAadhaarAddress] = Status.Absent;
        RegAgencies[id].activeAdmincount -= 1;
    }

    function MarkAdminPresent(uint256 id, address RegAadhaarAddress)
        public
        isAdmin(id)
    {
        RegAgencies[id].agency_RegAadhaarStatus[RegAadhaarAddress] = Status
            .Present;
    }

    function AddAgencyAdmin(uint256 id, address newadminAddress)
        public
        isAdmin(id)
    {
        require(
        RegAgencies[id].agency_AdminStatus[newadminAddress] == Status.Absent,
            "Duplicate Admins"
        );
        RegAgencies[id].AdminList.push(newadminAddress);
        RegAgencies[id].agency_AdminStatus[newadminAddress] = Status.Present;
        RegAgencies[id].activeAdmincount += 1;
    }
    //*******************ALL ADMIN FUNCTIONS END***************************
}