/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


//modification: wordings: sign->receive
//gas reduction
//added modifier

contract NewContract_6_5 {

    uint256 contractID;
    string nameOfContract;
    // uint8 decimalsOfToken = 0;
    // uint256 totalSupplyOfToken; //total token supply =0 //duplicate with userLimit
    string IpfsURI;
    string nameOfOwner;

    uint256 userLimit;
    address[] userList; //can be used to get user number
    uint receivedUserNum;
    mapping(address=>uint256) claimingProcessPercentage; //stores the users' balance with their address
    //1: received (9-29-2022)
    //0: original, 50:askedToReceive 50: received  //previous  0: original, 1:askedToReceive 2: received
    bool paused;

    // address public owner;  //only the owner can set who can receive doc of this contract 
    address public admin;  //admin is the one who can pause this contract, the admin contract creating this contract
    address public linkedContract;

    // modifier onlyOwner(){
    //     require (msg.sender == owner);
    //     _;
    // }

    modifier onlyUser(address userAddress){
    require (claimingProcessPercentage[userAddress] >= 50 || msg.sender == admin);
        _;
    }

    constructor(uint ID, string memory name, string memory OwnerName, string memory URI, uint userLimitNum)
    {
        admin = msg.sender; //set the person who launch the contract the contract owner
        nameOfOwner = OwnerName;

        contractID=ID;
        nameOfContract = name;
        IpfsURI=URI;
        userLimit = userLimitNum;

    }   //

    function _1_setNameOfOwner(string calldata name) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin");

        nameOfOwner = name;
    }   //

    function _2_setLinkedContract(address contractAddress) public
    {
        // require(paused == false, "paused by admin"); //saved 2300 gas by voiding this
        require(msg.sender == admin, "not admin");

        // require(contractAddress != 0x0000000000000000000000000000000000000000, "null address"); 
        //optional, as still can change another address if input wrong, but waste more gas when wrong input
        
        linkedContract = contractAddress;
    }   //

    function _4_pauseEverything() public{
        require(msg.sender == admin, "not admin");
        paused = true;
    }   //

    function _5_resumeFromPause() public{
        require(msg.sender == admin, "not admin");
        paused = false;
    }   //

    function _6_set_askedToReceive(address[] memory input) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin of this contract");


        uint addressLength = input.length;

        require(addressLength    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");
        // require(input.length    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");


        uint successNum=0;      //stores the number of users successfully added 
        for(uint i=0; i<addressLength; ++i)
        {
            address temp = input[i];
            // if(askedToReceive[input[i]] ==false && input[i] != 0x0000000000000000000000000000000000000000)
            if(claimingProcessPercentage[temp] ==0)
            //meaning that this person has not been added to receive list, and address is not null, so we need to add this
            {
                userList.push(temp);
                // claimingProcessPercentage[temp] =50;
                claimingProcessPercentage[temp] =1;
                ++successNum;
            }
            //else case:
            //this person has already been added to receive list, so we ignore it
        }
        return successNum;
    }

/*  //removed as similar function as _9_SendMultipleThroughAdmin with single user
    function _8_SendThroughAdmin(address user) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        require(claimingProcessPercentage[user] ==50, "the user is not asked to receive or already received doc of this contract");

        // require(user != 0x0000000000000000000000000000000000000000, "null address");
        //optional, as user could not be set to be 0x000000... in _6_
        
        receivedUserNum++;
        claimingProcessPercentage[user] = 100; 
    }
*/

/*
    function _9_SendMultipleThroughAdmin(address[] memory users) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        uint successNum=0;

        uint length = users.length;

        for(uint i = 0; i < length; ++i)
        {
            address temp = users[i];
            if(claimingProcessPercentage[temp] == 50)
            //that user is in the list and not yet received, so we send a token from this contract
            {

                ++successNum;
                //in _6_ the askedToReceive[] list is set a limit, so the claimingProcessPercentage address(this) would >=0

                claimingProcessPercentage[temp] = 100;
            }
        }
        receivedUserNum= receivedUserNum + successNum;

        return successNum;  //return the successful received user number 
    }
*/

    //viewers

    function _20_getID() public view returns (uint){
        return contractID;
    }

    function _21_getName() public view onlyUser(msg.sender) returns (string memory)
    {
        return nameOfContract;
    }

    // function _22_totalSupply() public view returns (uint256) //duplicate with _25_
    // {
    //     return totalSupplyOfToken;
    // }

    function _23_getURI() public view onlyUser(msg.sender) returns (string memory)
    {
        return IpfsURI;
    }

    function _24_getNameOfOwner() public view onlyUser(msg.sender) returns(string memory)
    {
        return nameOfOwner;
    }

    function _25_getUserLimit() public view returns (uint)
    {
        return userLimit;
    }

    function _26_checkUserList() public view onlyUser(msg.sender) returns (address[] memory)
    {
        return userList;
    }

    function _27_checkUserListNum() public view returns (uint)
    {
        return userList.length;
    }

    function _28_checkReceivedNum() public view onlyUser(msg.sender) returns (uint)
    {
        return receivedUserNum;
    }

    function _29_processPercentage(address _owner) public view returns (uint256)
    {
        return claimingProcessPercentage[_owner];  
        //1 means completed

        //0 means not asked to sign, 50 means asked to sign, 100 means received token
        //
        //0 means not asked to sign or 1/2->0 means asked to sign, 2/2->1 means received token
    }


    function _35_checkReceivedByAll() public view returns (bool)
    {
        require(receivedUserNum>0, "no user received");
        return userList.length == receivedUserNum;
    }

    function _30_checkReceivedByPerson(address user) public view returns (bool)
    {
        return claimingProcessPercentage[user] == 1; //100;
    }

    function _31_checkPaused() public view returns (bool)
    {
        return paused;
    }

    function _32_getAdmin() public view returns (address)
    {
        return admin;
    }

    function _33_getLinkedContract() public view returns (address)
    {
        return linkedContract;
    }

}