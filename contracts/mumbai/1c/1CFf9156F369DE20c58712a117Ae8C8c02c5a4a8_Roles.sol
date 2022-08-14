// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles {

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event RoleMinted(string  role , bytes32  roleHash);
    event DataMinted(string title,string dataHash,string thumbnailURL,string shortDescription);

    struct SpatialData{
        string title;
        string description;
        string shortDescription;
        string dataHash;
        string imageURL;
        string thumbnailURL;
        string fileURL;
        string dataDate;
        address owner;
        uint256 timestamp;
        string longitude;
        string lattitude;
        string[] visibility;
    }
    struct DefinedRoled{
        bytes32 role;
        string title;
    }

    DefinedRoled[] rolesDefinedByAdmin;
    SpatialData[] spatialDataArray;

    mapping(bytes32 => mapping(address => bool)) public roles;
    mapping(string=> SpatialData) public mapSpatialData;
    
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    constructor(){
        _grantRole(ADMIN, msg.sender);
    }

    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "You don't have the role");
        _;
    }

    function _grantRole(bytes32 _role,address _account) internal{
        roles[_role][_account] = true;
        emit GrantRole(_role,_account);
    }

    function grantRole(bytes32 _role,address _account) external onlyRole(ADMIN){
        _grantRole(_role,_account);
    }
    function revokeRole(bytes32 _role,address _account) external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RevokeRole(_role,_account);
    }

    function burnRole(bytes32 _roleHash) external onlyRole(ADMIN){
        for(uint i=0;i<rolesDefinedByAdmin.length;i++){
            if(rolesDefinedByAdmin[i].role == _roleHash){
                rolesDefinedByAdmin[i] = rolesDefinedByAdmin[rolesDefinedByAdmin.length-1];
                rolesDefinedByAdmin.pop();
            }
        }
    }

    function mintRole(string memory _title) external onlyRole(ADMIN){
        // rolesDefinedByAdmin.push(keccak256(abi.encodePacked(_title)),_title);
        rolesDefinedByAdmin.push(DefinedRoled(
            keccak256(abi.encodePacked(_title)),
            _title
        ));
        emit RoleMinted(_title,keccak256(abi.encodePacked(_title)));
    }
    
    function getAllRoles() public view returns(DefinedRoled[] memory){
        return rolesDefinedByAdmin;
    }

    function TellTheRole() public view returns(string memory){
        string memory res="NONE";
        for(uint i=0;i<rolesDefinedByAdmin.length;i++){
            if(roles[rolesDefinedByAdmin[i].role][msg.sender]==true){
                res = rolesDefinedByAdmin[i].title;
            }
            
        }
        return res;
    }
  

    function createSpatialData(string memory _title,
     string memory _description,string memory _shortDescription,string memory _dataHash,
    string memory _imageURL,string memory _thumnailURL,
    string memory _fileURL, string memory _dataDate,
    string memory _longitude,string memory _lattitude,string[] memory _visibility) public{
        spatialDataArray.push(
            SpatialData(
                _title,
            _description,
            _shortDescription,
            _dataHash,
            _imageURL,
            _thumnailURL,
            _fileURL,
            _dataDate,
            msg.sender,
            block.timestamp,
            _longitude,
            _lattitude,
            _visibility
            )
        );

        mapSpatialData[_dataHash] = spatialDataArray[spatialDataArray.length-1];

        emit DataMinted(_title,_dataHash,_thumnailURL,_shortDescription);
    }

    function getSpatialData(string memory _dataHash) public view returns(SpatialData memory){
        SpatialData memory res = mapSpatialData[_dataHash];
       return res;
    }
}