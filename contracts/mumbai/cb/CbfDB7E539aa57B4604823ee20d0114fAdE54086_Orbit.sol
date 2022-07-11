// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Orbit{
    address private owner;
    event Response(string);
    // contructor 
    constructor(){
        owner = msg.sender;
    }

    string[] userData;
    //Orbit User Registration
    struct EncOrbitInfo{
        string encOrbitInfo;
    }

    //Orbit UserInfo Mapping
    mapping (string => EncOrbitInfo) AllOrbitUser;
    EncOrbitInfo[] allOrbitUser;

    //Setting new orbit user
    function setOrbitUserInfo(string memory _encUserData) public onlyOwner{
        if(!checkUser(_encUserData)){
            AllOrbitUser[_encUserData].encOrbitInfo = _encUserData;
            allOrbitUser.push(EncOrbitInfo({encOrbitInfo:_encUserData}));
        }else{
            emit Response("Error");
        }
        
    }

    //get single userInfo
    function getOrbitUserInfo(string memory _encUserData) public onlyOwner view returns(string memory){
        return( AllOrbitUser[_encUserData].encOrbitInfo);
    }

    //get all user
    function getAllOrbitUser() public onlyOwner view returns(EncOrbitInfo[] memory){
        return(allOrbitUser);
    }


    //check user
    function checkUser(string memory _encUserData) public onlyOwner view returns(bool){
        bool user = false;
        if(keccak256(abi.encodePacked((_encUserData))) == keccak256(abi.encodePacked((getOrbitUserInfo(_encUserData))))   ){
            user = true;
        }
        return user;
    }




     //Orbit User DRM
    struct OrbitDRM{
        string encUser;
        string encDrmText;
    }

    mapping(string=>OrbitDRM) orbitDrm;
    OrbitDRM[] orbitDRM;

    //Set User Drm
    function setUserDRM(string memory _encUserData,string memory _encDrmText) public  onlyOwner{
        orbitDRM.push(OrbitDRM({encUser:_encUserData,encDrmText:_encDrmText}));
    } 

    //Get All Drm
    function getAllDRM() public onlyOwner view returns(OrbitDRM[] memory){
        return orbitDRM;
    }

    //Get Drm of the user
    function getUserDrm(string memory _encUserData) public onlyOwner view returns(string[] memory){
        string[] memory userDrm = new string[](orbitDRM.length);
        for(uint i =0;i<orbitDRM.length;i++){
            if( keccak256(abi.encodePacked((_encUserData)))  ==  keccak256(abi.encodePacked((orbitDRM[i].encUser))) ){
                userDrm[i] = orbitDRM[i].encDrmText;
            }
        }

        return userDrm;
    }

    //Get user name form the drm
    function getDrmUsr(string memory _encDrmText) public onlyOwner view returns(string[] memory){
         string[] memory userName = new string[](orbitDRM.length);
         for(uint i =0;i<orbitDRM.length;i++){
            if( keccak256(abi.encodePacked((_encDrmText)))  ==  keccak256(abi.encodePacked((orbitDRM[i].encDrmText))) ){
                userName[i] = orbitDRM[i].encUser;
            }
        }

        return userName;
    }


    //only owner modifier
    modifier onlyOwner(){
        require(owner == msg.sender,"Only Owner Can Access The Data");
        _;
    }

}