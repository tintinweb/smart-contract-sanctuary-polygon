// SPDX-License-Identifier: MIT
/*
/$$      /$$                  /$$                  /$$$$$$                      /$$                    
|  $$   /$$/                 | $$                 /$$__  $$                    |__/                    
 \  $$ /$$//$$$$$$  /$$   /$$| $$  /$$$$$$       | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$  /$$$$$$$ 
  \  $$$$//$$__  $$|  $$ /$$/| $$ /$$__  $$      | $$$$$$$$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$
   \  $$/| $$$$$$$$ \  $$$$/ | $$| $$$$$$$$      | $$__  $$| $$  \ $$| $$  \ $$| $$  /$$$$$$$| $$  \ $$
    | $$ | $$_____/  >$$  $$ | $$| $$_____/      | $$  | $$| $$  | $$| $$  | $$| $$ /$$__  $$| $$  | $$
    | $$ |  $$$$$$$ /$$/\  $$| $$|  $$$$$$$      | $$  | $$| $$$$$$$/| $$$$$$$/| $$|  $$$$$$$| $$  | $$
    |__/  \_______/|__/  \__/|__/ \_______/      |__/  |__/| $$____/ | $$____/ |__/ \_______/|__/  |__/
                                                           | $$      | $$                              
                                                           | $$      | $$                              
                                                           |__/      |__/                                                                                                                                                                   
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
    error notL1Address();
    error approverAlreadyExist();
    error notOwner();
    
    address[] private pushUsers;
    address[] private adminAddresses;
    address public owner;
    address private L1Approver;
    uint private totalUsersCount;
    
    mapping(address => bool) private isUser;
    mapping(address => bool) private adminAddress;
    mapping(address => bool) private approverAddress;

    struct userBulkData{
        address _ad;
    }

    struct userAdd{
        address _l1;
        address _ad;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    /**
        *  whitelistApproverL1
        * @param _approverAd - Enter the L1 approver address to the smart contract.
    */
    function whitelistApproverL1(address _approverAd) external onlyOwner{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }
    
    /**
        *  addUser
        * @param _data - Admin has the access to enter the user address to the blockchain.
    */
    function addUser(userAdd memory _data) external onlyOwner{
        if(_data._l1 != L1Approver){ revert notL1Address();}
        if(isUser[_data._ad] == true){ revert addressAlreadyRegistered();}
        isUser[_data._ad] = true;
        totalUsersCount += 1;
        pushUsers.push(_data._ad);
    }

    /**
        * addUserBulk
        * @param _userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(address l1Address, userBulkData[] memory _userData) external onlyOwner{
        if(l1Address != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]._ad] = true;
            totalUsersCount += 1;
            pushUsers.push(_userData[i]._ad);
        }
    }

    /**
        * addUserBulk1.
        * @param l1Address - Enter the Level 1 approver address.
        * @param _userData - Enter the array of user addresses.
    */
    function addUserBulk1(address l1Address, address[] memory _userData) external onlyOwner{
        if(l1Address != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]] = true;
            totalUsersCount += 1;
            pushUsers.push(_userData[i]);
        }
    }

    /**
        * verifyUser
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
        * getAllUserAddress
        * outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    /**
        * L1ApproverAddress
        * Get the L1 approver address. 
    */
    function L1ApproverAddress() external view returns(address){
        return L1Approver;
    }

    /**
        * UserCounts  
    */ 
    function UserCounts() external view returns(uint totalCountOfUsers){
        return totalUsersCount;
    }
}