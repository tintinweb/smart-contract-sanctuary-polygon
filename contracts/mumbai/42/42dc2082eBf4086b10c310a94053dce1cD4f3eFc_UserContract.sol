// SPDX-License-Identifier: MIT
/*
  /$$$$$$  /$$$$$$$  /$$$$$$$  /$$$$$$  /$$$$$$  /$$   /$$
 /$$__  $$| $$__  $$| $$__  $$|_  $$_/ /$$__  $$| $$$ | $$
| $$  \ $$| $$  \ $$| $$  \ $$  | $$  | $$  \ $$| $$$$| $$
| $$$$$$$$| $$$$$$$/| $$$$$$$/  | $$  | $$$$$$$$| $$ $$ $$
| $$__  $$| $$____/ | $$____/   | $$  | $$__  $$| $$  $$$$
| $$  | $$| $$      | $$        | $$  | $$  | $$| $$\  $$$
| $$  | $$| $$      | $$       /$$$$$$| $$  | $$| $$ \  $$
|__/  |__/|__/      |__/      |______/|__/  |__/|__/  \__/                                                                                                                                                                   
*/

pragma solidity ^0.8.9;

contract UserContract{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notAdminAddress();
    
    address[] private pushUsers;
    address[] private adminAddresses;
    address private owner;
    mapping(address => bool) private isUser;
    mapping(address => bool) private adminAddress;

    struct userBulkData{
        address _ad;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }
    
    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
    */
    function addUser(address _ad) external {
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        isUser[_ad] = true;
        pushUsers.push(_ad);
    }

    /**
        * addUserBulk
        * @param _userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(userBulkData[] memory _userData) external {
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]._ad] = true;
            pushUsers.push(_userData[i]._ad);
        }
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool){
        if(isUser[_ad]){
            return true;
        }else{
            return false;
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    function allAdmins() external view returns(address[] memory){
        return adminAddresses;
    } 
}