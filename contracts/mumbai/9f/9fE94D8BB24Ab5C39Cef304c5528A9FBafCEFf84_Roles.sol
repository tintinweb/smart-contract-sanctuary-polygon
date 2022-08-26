// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles{

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event DataMinted(string title,string dataHash,string thumbnailURL,string description,int32 imageryDate,string country,string state,string district,string cordinates);
    event PrivateDataMinted(string title,string dataHash,string thumbnailURL,string description,int32 imageryDate,string country,string state,string district,address owner);
    event PermessionGranted(address add,string dataHash);
    event PermessionRevoke(address add,string dataHash);
    struct SpatialData {
        string title;
        string description;
        string fileURL;
        string thumbnailURL;
        string imageURL;
        string dataHash;
        address owner;
        string country;
        string state;
        string district;
        int32 imageryDate;
        string cordinates;
    }
    struct PrivateaSpatialData {
        string title;
        string description;
        string fileURL;
        string thumbnailURL;
        string imageURL;
        string dataHash;
        address owner;
        
        string country;
        string state;
        string district;
        int32 imageryDate;
        string cordinates;
    }
    constructor(){
        _grantRole(ADMIN, msg.sender);
        _grantRole(CREATOR,msg.sender);
    }
    mapping(bytes32 => mapping(address => bool)) public roles;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    mapping(string => mapping(address => bool)) public isAuthenticate;
    bytes32 private constant CREATOR = keccak256(abi.encodePacked("CREATOR"));
    mapping(string=> SpatialData) public mapSpatialData;
    mapping(string=> PrivateaSpatialData) public privateMapSpatialData;
    SpatialData[] spatialDataArray;
    PrivateaSpatialData[] privateSpatialDataArray;

    
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

    function createSpatialData(string memory _title,string memory _description,string memory _fileURL,string memory _thumnailURL,string memory _imageURL,int32 _imageryDate,string memory _dataHash,string memory _country,string memory _state,string memory _district,string memory _cordinates) public{
        spatialDataArray.push(
            SpatialData(
            _title,
            _description,
            _fileURL,
            _thumnailURL,
            _imageURL,
            _dataHash,
            msg.sender,
            
            _country,
            _state,
            _district,
            _imageryDate,
            _cordinates
            )
        );

        mapSpatialData[_dataHash] = spatialDataArray[spatialDataArray.length-1];

        emit DataMinted(_title,_dataHash,_thumnailURL,_description,_imageryDate,_country,_state,_district,_cordinates);
    }

    function TellMeMyRole() public view returns(string[] memory){
         string[]    memory response = new string[](3);
        if(roles[ADMIN][msg.sender]){
            response[0] = "ADMIN";
        }
        if(roles[CREATOR][msg.sender]){
            response[1] = "CREATOR";
        }
        return response;
    }

    function createPrivateSpatialData(string memory _title,string memory _description,string memory _fileURL,string memory _thumnailURL,string memory _imageURL,int32 _imageryDate,string memory _dataHash,string memory _country,string memory _state,string memory _district,string memory _cordinates) public{
        privateSpatialDataArray.push(
            PrivateaSpatialData(
            _title,
            _description,
            _fileURL,
            _thumnailURL,
            _imageURL,
            _dataHash,
            msg.sender,
            _country,
            _state,
            _district,
            _imageryDate,
            _cordinates
            )
        );

        privateMapSpatialData[_dataHash] = privateSpatialDataArray[privateSpatialDataArray.length-1];

        emit PrivateDataMinted(_title,_dataHash,_thumnailURL,_description,_imageryDate,_country,_state,_district,msg.sender);
    }
    
    function getSpatialData(string memory _dataHash) public view returns(SpatialData memory){
        SpatialData memory res = mapSpatialData[_dataHash];
       return res;
    }

    function grantAccess(address add,string memory dataHash)public{
        isAuthenticate[dataHash][add] = true;
        emit PermessionGranted(add,dataHash);
    }

    function revokeAccess(address add,string memory dataHash) public{
        isAuthenticate[dataHash][add] = false;
        emit PermessionRevoke(add,dataHash);
    }
    
   
}