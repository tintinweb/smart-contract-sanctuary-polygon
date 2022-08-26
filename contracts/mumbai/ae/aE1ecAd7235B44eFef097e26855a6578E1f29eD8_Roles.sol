// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles{

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event DataMinted(string title,string dataHash,string thumbnailURL,string description,int32 imageryDate,string country,string state,string district);

    struct SpatialData {
        string title;
        string description;
        string fileURL;
        string thumbnailURL;
        string imageURL;
        string dataHash;
        address owner;
        uint256 timestamp;
        string country;
        string state;
        string district;
        int32 imageryDate;
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
    SpatialData[] spatialDataArray;

    
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

    function createSpatialData(string memory _title,string memory _description,string memory _fileURL,string memory _thumnailURL,string memory _imageURL,int32 _imageryDate,string memory _dataHash,string memory _country,string memory _state,string memory _district) public{
        spatialDataArray.push(
            SpatialData(
            _title,
            _description,
            _fileURL,
            _thumnailURL,
            _imageURL,
            _dataHash,
            msg.sender,
            block.timestamp,
            _country,
            _state,
            _district,
            _imageryDate
            )
        );

        mapSpatialData[_dataHash] = spatialDataArray[spatialDataArray.length-1];

        emit DataMinted(_title,_dataHash,_thumnailURL,_description,_imageryDate,_country,_state,_district);
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

    
    function getSpatialData(string memory _dataHash) public view returns(SpatialData memory){
        SpatialData memory res = mapSpatialData[_dataHash];
       return res;
    }
   
}