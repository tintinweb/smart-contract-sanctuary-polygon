//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

enum Status {
    Absent,
    Present
}

struct AadhaarHolder {
    address ssi_address;
    string AadhaarHolderName;
    string AadhaarSignature;
    // string phoneno;
    // string Address;
    // string bankAccount1;
    uint256[] subscribedAgencies;
}

struct ConsumerAgency {
    uint256 agencyID;
    string agency_name;
    bool ApprovalStatus;
    // Index :: 0 -> ssi address , 1-> AadharHolderName, 2-> AadharSignature
    uint256[] Permission; // 0: Not granted , 1 : Granted
    address[] AdminList;
    uint256 activeAdmincount;
    mapping(address => Status) agency_AdminStatus;
    AadhaarHolder[] RegAadharList;
    mapping(address => Status) agency_RegAadhaarStatus;
}

contract DataVault {
    address public _UIDAI;
    uint256 private ID;

    mapping(uint256 => ConsumerAgency) private RegAgencies;
    mapping(address => AadhaarHolder) private RegAadhaarHolders;

    event AgencyRegistered(string name, address regAdmin, uint256[] permission);
    event AadhaarHolderRegistered(
        address RegAadhaarAddress,
        string name,
        string AadharSig
    );

    constructor() {
        ID = 0;
        _UIDAI = msg.sender; // Contract owner
    }

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

    //*******************ALL REGISTERATION FUNCTIONS START***************************
    function RegisterNewAadhaarHolder(
        string memory name,
        string memory AadharSig
    ) public returns (bool) {
        require(
            RegAadhaarHolders[msg.sender].ssi_address ==
                0x0000000000000000000000000000000000000000,
            "User already Exist"
        );
        RegAadhaarHolders[msg.sender].AadhaarHolderName = name;
        RegAadhaarHolders[msg.sender].ssi_address = msg.sender;
        RegAadhaarHolders[msg.sender].AadhaarSignature = AadharSig;
        emit AadhaarHolderRegistered(
            msg.sender,
            RegAadhaarHolders[msg.sender].AadhaarHolderName, //Can be removed
            RegAadhaarHolders[msg.sender].AadhaarSignature
        );
        return true; // for acknowledment LATTER TO BE REMOVED
    }

    function RegisterAgency(string memory name, uint256[] memory permission)
        public
        returns (uint256)
    {
        ID += 1;
        RegAgencies[ID].agency_name = name;
        RegAgencies[ID].agencyID = ID;
        RegAgencies[ID].AdminList.push(msg.sender);
        RegAgencies[ID].agency_AdminStatus[msg.sender] = Status.Present;
        RegAgencies[ID].activeAdmincount += 1;
        RegAgencies[ID].Permission = permission;
        RegAgencies[ID].ApprovalStatus = false;
        emit AgencyRegistered(
            RegAgencies[ID].agency_name,
            msg.sender,
            permission
        );
        return RegAgencies[ID].agencyID;
    }

    function ApproveAgency(uint256 id, bool status) public returns (bool) {
        require(
            msg.sender == _UIDAI,
            "Only UIDAI can submit the approval Status"
        );
        RegAgencies[id].ApprovalStatus = status;
        return RegAgencies[id].ApprovalStatus;
        // add event here
    }

    function RegisterAadhaarInAgency(
        uint256 id,
        address AadharHolderWalletAddress
    )
        public
        isAdmin(id)
        isAadharHolderAlreadyRegister(AadharHolderWalletAddress)
    {
        //Aadhaar holder registration
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

    // 1. To retrieve user data and reveal only specific fields.
    // 2. To retrieve entire user data only when that user fires request to reveal their own data
    // 3. To provide knowledge of which agency is accessing which data field to the user
    // 4. to get details of all registerd aadhaar users in agency

    function getAadharHolderData(uint256 id, address AadharHolderWalletAddress)
        public
        view
        isAdmin(id)
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
        return response;
    }
    function getAadharHolderData(uint256 id) public view isAdmin(id) returns (AadhaarHolder[] memory) {
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
            address[][] memory
        )
    {
        require(
            msg.sender == _UIDAI,
            "Only UIDAI can submit the approval Status"
        );
        uint256[] memory array = new uint256[](ID + 1);
        string[] memory array1 = new string[](ID + 1);
        bool[] memory array2 = new bool[](ID + 1);
        uint256[][] memory array3 = new uint256[][](ID + 1);
        address[][] memory array4 = new address[][](ID + 1);
        for (uint256 i = 1; i <= ID; i += 1) {
            array[i] = RegAgencies[i].agencyID;
            array1[i] = RegAgencies[i].agency_name;
            array2[i] = RegAgencies[i].ApprovalStatus;
            array3[i] = RegAgencies[i].Permission;
            array4[i] = RegAgencies[i].AdminList;
        }
        return (array, array1, array2, array3, array4);
    }

    //TODO Incomplete
    // function getAllAgencyAdminStatus() public view returns (Status[][] memory) {
    //     require(
    //         msg.sender == _UIDAI,
    //         "Only UIDAI can submit the approval Status"
    //     );
    //     Status[][] memory array = new Status[][](ID + 1);
    //     for (uint256 i = 1; i <= ID; i += 1) {
    //         for (uint256 j = 0; j < RegAgencies[i].AdminList.length; j += 1) {
    //             array[i][j] = RegAgencies[i].agency_AdminStatus[
    //                 RegAgencies[i].AdminList[j]
    //             ];
    //         }
    //     }
    //     return array;
    // }

    // function getAllAgencyRegAadhaarStatus()
    //     public
    //     view
    //     returns (uint256[][] memory)
    // {
    //     require(
    //         msg.sender == _UIDAI,
    //         "Only UIDAI can submit the approval Status"
    //     );
    //     uint256[][] memory array = new uint256[][](ID + 1);
    //     for (uint256 i = 1; i <= ID; i += 1) {
    //         // array[i] = RegAgencies[i].agency_RegAadhaarStatus[ msg.sender ];????
    //     }
    //     return array;
    // }

    
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