// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Orbit{
    string[] userData;
    //Orbit User Registration
    struct EncOrbitInfo{
        string encOrbitInfo;
    }

    //Orbit UserInfo Mapping
    mapping (string => EncOrbitInfo) AllOrbitUser;


    //Setting new orbit user
    function setOrbitUserInfo(string memory _encUserData) public{
        AllOrbitUser[_encUserData].encOrbitInfo = _encUserData;
    }

    //get single userInfo
    function getOrbitUserInfo(string memory _encUserData) public view returns(string memory){
        return( AllOrbitUser[_encUserData].encOrbitInfo);
    }

     //Orbit User DRM
    struct OrbitDRM{
        string encUser;
        string encDrmText;
    }

    OrbitDRM[] orbitDRM;

    function setUserDRM(string memory _encUserData,string memory _encDrmText) public{
        orbitDRM.push(OrbitDRM({encUser:_encUserData,encDrmText:_encDrmText}));
    } 


    function getAllDRM() public view returns(OrbitDRM[] memory){
        return orbitDRM;
    }

}