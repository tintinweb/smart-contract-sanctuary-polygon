/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VensureRounds {
    address public Owner;

    constructor() {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Caller is Not the owner");
        _;
    }

    struct Organizations {
        address wallet_add;
        address parent_add;
        address[] childarray;
        // string com_name;
        uint256[] org_cert_library;
        uint256[] emp_library;
        uint256[] com_profile_library;
        uint256[] token_library;
        // string logo_ipfs;
        // string _type;
    }

    struct UserProfile {
        address wallet_add;
        string role;
        string Name;
        string log_ipfs;
    }

    struct Org_Profile {
        address org_add;
        uint256 account_id;
        uint256 ein_no;
        string division_id;
        uint256 acqui_timestamp;
        string division_type;
        string office_address;
        string division_president;
        uint256 div_pre_cont;
        // uint256 index;
    }

    struct Employees {
        string emp_name;
        string pro_image;
        address org_add;
        address wallet_add;
        string role;
        uint256[] capdata_library;
        uint256[] emp_cert_library;
        // uint256 index;
    }

    struct CapTable {
        address user_add;
        uint256 Shares;
        uint256 outstanding;
        uint256 ownership;
        uint256 diluted;
        uint256 Raised;
        // uint256 index;
    }

    struct DataBook {
        string certificatename;
        string certipfs;
        // bool isActive;
        // uint256 index;
    }

    struct TokenTable {
        address tokenadd;
        address tokenowner;
        // uint256 index;
    }

    Organizations[] orglist;

    address[] private AllUsers;
    address[] private OrgUsers;
    address[] private EmpUsers;

    mapping(address => Organizations) public organization;
    mapping(address => UserProfile) public userdata;
    mapping(uint256 => DataBook) public certificate;
    mapping(uint256 => CapTable) public capdatas;
    mapping(uint256 => TokenTable) public tokendetail;
    mapping(uint256 => Org_Profile) public Orgdetails;
    mapping(uint256 => Employees) public employee;

    //multiple Mappings

    mapping(address => Employees) public EmpAdd;

    uint256 private libraryindex;
    uint256 private captableindex;
    uint256 private tokenindex;
    uint256 private orgdetailindex;
    uint256 private employeeindex;

    function AddOrganization(
        address _wallet_add,
        address _parent_add,
        address[] memory _childarray,
        string memory _orgname,
        uint256[] memory _cert_library,
        uint256[] memory _emp_lib,
        uint256[] memory _com_profile_lib,
        uint256[] memory _tok_lib,
        string memory _role,
        string memory _logo_ipfs
    ) public {
        AllUsers.push(_wallet_add);
        OrgUsers.push(_wallet_add);
        organization[_wallet_add] = Organizations(
            _wallet_add,
            _parent_add,
            _childarray,
            // _orgname,
            _cert_library,
            _emp_lib,
            _com_profile_lib,
            _tok_lib
            // _logo_ipfs
        );
        userdata[_wallet_add] = UserProfile(
            _wallet_add,
            _role,
            _orgname,
            _logo_ipfs
        );
        orglist.push(
            Organizations(
                _wallet_add,
                _parent_add,
                _childarray,
                // _orgname,
                _cert_library,
                _emp_lib,
                _com_profile_lib,
                _tok_lib
                // _logo_ipfs
            )
        );
        organization[_parent_add].childarray.push(_wallet_add);
    }

    function AddEmployee(
        string memory _name,
        string memory _ipfsimage,
        address _orgaddress,
        address _walletaddress,
        string memory _role,
        string memory _orgname,
        uint256[] memory _caplibrary,
        uint256[] memory _certlibrary
    ) public {
        employeeindex++;
        employee[employeeindex] = Employees(
            _name,
            _ipfsimage,
            _orgaddress,
            _walletaddress,
            _role,
            _caplibrary,
            _certlibrary
        );
        userdata[_walletaddress] = UserProfile(
            _walletaddress,
            _role,
            _orgname,
            _ipfsimage
        );
        organization[_orgaddress].emp_library.push(employeeindex);
        organization[_orgaddress].childarray.push(_walletaddress);
        EmpUsers.push(_walletaddress);
    }

    function UpdateDetails(
        address _org_address,
        uint256 _account_id,
        uint256 _ein_no,
        string memory _div_id,
        uint256 _acq_timestamp,
        string memory _div_type,
        string memory _offce_address,
        string memory _div_president,
        uint256 _div_contact
    ) public {
        orgdetailindex++;
        Orgdetails[orgdetailindex] = Org_Profile(
            _org_address,
            _account_id,
            _ein_no,
            _div_id,
            _acq_timestamp,
            _div_type,
            _offce_address,
            _div_president,
            _div_contact
        );
        organization[_org_address].com_profile_library.push(orgdetailindex);
    }

    function AddCertificate(
        address user_address,
        string memory _certi_name,
        string memory _ipfslink,
        string memory _type
    ) public {
        libraryindex++;
        certificate[libraryindex] = DataBook(_certi_name, _ipfslink);

        if (
            keccak256(abi.encodePacked("Org")) ==
            keccak256(abi.encodePacked(_type))
        ) {
            organization[user_address].org_cert_library.push(libraryindex);
        } else {
            EmpAdd[user_address].emp_cert_library.push(libraryindex);
        }
    }

    function AddTokenData(address _tokenadd) public {
        tokenindex++;
        tokendetail[tokenindex] = TokenTable(_tokenadd, msg.sender);
        organization[msg.sender].token_library.push(tokenindex);
    }

    function AddCapData(
        address _useraddress,
        uint256 _Shares,
        uint256 _outstanding,
        uint256 _ownership,
        uint256 _diluted,
        uint256 _Raised
    ) public {
        // require(
        //     _useraddress == organization[_useraddress].wallet_add,
        //     "User not registered "
        // );
        captableindex++;
        capdatas[captableindex] = CapTable(
            _useraddress,
            _Shares,
            _outstanding,
            _ownership,
            _diluted,
            _Raised
        );

        EmpAdd[_useraddress].capdata_library.push(captableindex);
    }

    function GetTreeData(address _useraddress)
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            organization[_useraddress].com_profile_library,
            organization[_useraddress].childarray,
            organization[_useraddress].emp_library,
            organization[_useraddress].org_cert_library
        );
    }

    function GetCapData(address _useraddress)
        public
        view
        returns (uint256[] memory)
    {
        return EmpAdd[_useraddress].capdata_library;
    }

    /*
     * To get Certificates of user
     */
    function GetCertificateofUser(address _useraddress, string memory _type)
        public
        view
        returns (uint256[] memory)
    {
        if (
            keccak256(abi.encodePacked("Org")) ==
            keccak256(abi.encodePacked(_type))
        ) {
            return organization[_useraddress].org_cert_library;
        } else {
            return EmpAdd[_useraddress].emp_cert_library;
        }
    }

    function getAllUsers() public view returns (address[] memory) {
        return AllUsers;
    }

    function getNetworks() public view returns (address[] memory) {
        return OrgUsers;
    }

    function getEmployees() public view returns (address[] memory) {
        return EmpUsers;
    }

    // function getInvestors() public view returns (address[] memory) {
    //     return InvestorUsers;
    // }
}