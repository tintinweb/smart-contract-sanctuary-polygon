// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles{

    
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event DataMinted(string title,string description,string dataHash,string fileURL,int32 imageryDate,string country,string state,string district,string geoJSON);
    event PrivateDataMinted(string title,string description,string dataHash,string fileURL,int32 imageryDate,string country,string state,string district,string geoJSON);

    struct SpatialData {
        string[] titleDesc;
        string fileURL;
        string[] iamgeURL;
        string dataHash;
        address owner;
        uint256 timestamp;
        string[] location;
        int32 imageryDate;
        string[] cordinates;
        string geoJSON;
    }

    struct PrivateSpatialData{
        string[] titleDesc;
        string fileURL;
        string[] iamgeURL;
        string dataHash;
        address owner;
        uint256 timestamp;
        string[] location;
        int32 imageryDate;
        string[] cordinates;
        string geoJSON;
    }
    PrivateSpatialData[] PrivateSpatialDataArray;
    constructor(){
        _grantRole(ADMIN, msg.sender);
        _grantRole(CREATOR,msg.sender);
        
        
    }
    
    mapping(bytes32 => mapping(address => bool)) public roles;
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant PRIVATEUSER = keccak256(abi.encodePacked("USER"));
    bytes32 public constant CREATOR = keccak256(abi.encodePacked("CREATOR"));
    mapping(string => SpatialData) public mapSpatialData;
    mapping(string => PrivateSpatialData) public PrivateSpatialDataMap;
    // mapping(address => mapping( uint => PrivateSpatialData)) public PrivateSpatialDataMap;
    SpatialData[] spatialDataArray;

    
    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "You don't have the role");
        _;
    }

    // map => array[ownData]
    
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

    function createSpatialData(string[] memory _titleDesc,string memory _fileURL,string[] memory _imageURL,string memory _dataHash,string[] memory _location,int32 _imageryDate,string[] memory _cordinates,string memory _geoJSON) public onlyRole(CREATOR){   
        spatialDataArray.push(
            SpatialData(
            _titleDesc,
            _fileURL,
            _imageURL,
            _dataHash,
            msg.sender,
            block.timestamp,
            _location,
            _imageryDate,
            _cordinates,
            _geoJSON            
            )
        );
        mapSpatialData[_dataHash] = spatialDataArray[spatialDataArray.length-1];
        emit DataMinted(_titleDesc[0],_titleDesc[1],_dataHash,_fileURL,_imageryDate,_location[0],_location[1],_location[2],_geoJSON);
    }
    

    function getMySpataialData() public view returns(PrivateSpatialData[] memory){
        
        return PrivateSpatialDataArray;
    }

    function createPrivateData(string[] memory _titleDesc,string memory _fileURL,string[] memory _imageURL,string memory _dataHash,string[] memory _location,int32 _imageryDate,string[] memory _cordinates,string memory _geoJSON) public onlyRole(PRIVATEUSER){
        
        PrivateSpatialDataArray.push(
            PrivateSpatialData(
            _titleDesc,
            _fileURL,
            _imageURL,
            _dataHash,
            msg.sender,
            block.timestamp,
            _location,
            _imageryDate,
            _cordinates,
            _geoJSON            
            )
        );

        PrivateSpatialDataMap[_dataHash] = PrivateSpatialDataArray[spatialDataArray.length-1];
        emit PrivateDataMinted(_titleDesc[0],_titleDesc[1],_dataHash,_fileURL,_imageryDate,_location[0],_location[1],_location[2],_geoJSON);
    }

    

    function TellMeMyRole() public view returns(string[] memory){
         string[]    memory response = new string[](3);
        if(roles[ADMIN][msg.sender]){
            response[0] = "ADMIN";
        }
        if(roles[PRIVATEUSER][msg.sender]){
            response[1] = "PRIVATEUSER";
        }
        if(roles[CREATOR][msg.sender]){
            response[2] = "CREATOR";
        }
        return response;
    }
    
    function getSpatialData(string memory _dataHash) public view returns(SpatialData memory){
        SpatialData memory res = mapSpatialData[_dataHash];
       return res;
    }
   
}