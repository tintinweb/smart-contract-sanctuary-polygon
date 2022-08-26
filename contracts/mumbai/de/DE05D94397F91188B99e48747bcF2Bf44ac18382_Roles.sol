// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles{
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event DataMinted(string title,string description,string dataHash,string fileURL,int32 imageryDate,string country,string state,string district,string geoJSON);
    event PrivateDataMinted(string title,string description,string dataHash,string fileURL,int32 imageryDate,string country,string state,string district,string geoJSON);


    // Declaration of the data arrays   
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
        address[] whishlist;
    }
    constructor(){
        _grantRole(ADMIN, msg.sender);
        _grantRole(CREATOR,msg.sender);
    }

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
    mapping(bytes32 => mapping(address => bool)) public roles;
    mapping(string => mapping(address => bool)) public isAuthenticate;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant CREATOR = keccak256(abi.encodePacked("CREATOR"));
    mapping(string=> SpatialData) public mapSpatialData;
    mapping(string => PrivateSpatialData) public mapPrivateSpatialData;
    SpatialData[] spatialDataArray;
    PrivateSpatialData[] PrivateSpatialDataArray;

    function createSpatialData(
        string[] memory _titleDesc,
        string memory _fileURL,
        string[] memory _imageURL,
        string memory _dataHash,
        string[] memory _location,
        int32 _imageryDate,
        string[] memory _cordinates,
        string memory _geoJSON
    )public onlyRole(CREATOR){
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

    function createPrivateSpatialData(
        string[] memory _titleDesc,
        string memory _fileURL,
        string[] memory _imageURL,
        string memory _dataHash,
        string[] memory _location,
        int32 _imageryDate,
        string[] memory _cordinates,
        string memory _geoJSON
    )public onlyRole(CREATOR){
        address[] memory _whitelist;
        _whitelist[0] = msg.sender;
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
                _geoJSON,
                _whitelist

            )
        );
        isAuthenticate[_dataHash][msg.sender]= true;
        emit PrivateDataMinted(_titleDesc[0],_titleDesc[1],_dataHash,_fileURL,_imageryDate,_location[0],_location[1],_location[2],_geoJSON);

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

    function provideAccess(string memory _dataHash,address  _address)public{
       
        isAuthenticate[_dataHash][_address] = true;
    }

    function revokeAccess(string memory _dataHash,address  _address) public{
        
        isAuthenticate[_dataHash][_address] = false;
        
    }



}