/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


contract NewContract {

    uint contractID;
    string nameOfContract;
    uint8 decimalsOfToken = 0;
    uint256 totalSupplyOfToken = 0; //total token supply
    string IpfsURI;
    string nameOfOwner;

    uint userLimit;
    address[] userList; //can be used to get user number
    uint signedUserNum;
    mapping(address=>bool)  askedToSign;
    mapping(address=>uint256) balanceOfUser; //stores the users' balance with their address
    bool paused;

    // address public owner;  //only the owner can set who can sign this contract 
    address public admin;  //admin is the one who can pause this contract, the admin contract creating this contract
    address public linkedContract;

    constructor(uint ID, string memory name, string memory OwnerName, string memory URI, uint userLimitNum)
    {
        admin = msg.sender; //set the person who launch the contract the contract owner
        nameOfOwner = OwnerName;

        contractID=ID;
        nameOfContract = name;
        IpfsURI=URI;
        userLimit = userLimitNum;
        totalSupplyOfToken = userLimitNum;
        balanceOfUser[address(this)] = userLimitNum;    //so this contract owns all the tokens minted
    }

    function _1_setNameOfOwner(string memory name) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin");

        nameOfOwner = name;
    }

    function _2_setLinkedContract(address contractAddress) public
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin");

        require(contractAddress != 0x0000000000000000000000000000000000000000, "null address"); 
        //optional, as still can change another address if input wrong, but waste more gas when wrong input
        
        linkedContract = contractAddress;
    }

    function _4_pauseEverything() public{
        require(msg.sender == admin, "not admin");
        paused = true;
    }

    function _5_resumeFromPause() public{
        require(msg.sender == admin, "not admin");
        paused = false;
    }

    function _6_set_askedToSign(address[] memory input) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin of this contract");

        require(input.length    +   userList.length <= userLimit, "number of users required to sign exceed limit of number of users of this contract");
        
        uint successNum=0;      //stores the number of users successfully added 
        for(uint i=0; i<input.length; i++)
        {
            if(askedToSign[input[i]] ==false && input[i] != 0x0000000000000000000000000000000000000000)
            //meaning that this person has not been added to sign list, and address is not null, so we need to add this
            {
                userList.push(input[i]);
                askedToSign[input[i]] =true;
                successNum++;
            }
            //else case:
            //this person has already been added to sign list, so we ignore it
        }
        return successNum;
    }

    function _8_signThroughAdmin(address user) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        require(askedToSign[user] ==true, "the user is not asked to sign this contract");
        require(balanceOfUser[user] == 0, "the user already signed this contract");

        require(user != 0x0000000000000000000000000000000000000000, "null address");
        //optional, as user could not be set to be 0x000000... in _6_
        
        signedUserNum++;
        balanceOfUser[address(this)] -=1;
        balanceOfUser[user] +=1; 
    }

    function _9_signMultiple(address[] memory users) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        uint successNum=0;
        for(uint i = 0; i < users.length; i++)
        {
            if(askedToSign[users[i]] ==true && balanceOfUser[users[i]] == 0)
            //that user is in the list and not yet signed, so we send a token from this contract
            {
                signedUserNum++;
                successNum++;
                //in _6_ the askedToSign[] list is set a limit, so the balanceOfUser address(this) would >=0

                balanceOfUser[address(this)]    -=1;    
                balanceOfUser[users[i]]         +=1;
            }
        }

        return successNum;  //return the successful signed user number 
    }
    
    //viewers

    function _20_getID() public view returns (uint){
        return contractID;
    }

    function _21_getName() public view returns (string memory)
    {
        return nameOfContract;
    }

    function _22_totalSupply() public view returns (uint256)
    {
        return totalSupplyOfToken;
    }

    function _23_getURI() public view returns (string memory)
    {
        return IpfsURI;
    }

    function _24_getNameOfOwner() public view returns(string memory)
    {
        return nameOfOwner;
    }

    function _25_getUserLimit() public view returns (uint)
    {
        return userLimit;
    }

    function _26_checkUserList() public view returns (address[] memory)
    {
        return userList;
    }

    function _27_checkUserListNum() public view returns (uint)
    {
        return userList.length;
    }

    function _28_checkSignedNum() public view returns (uint)
    {
        return signedUserNum;
    }

    function _29_balanceOf(address _owner) public view returns (uint256)
    {
        return balanceOfUser[_owner];
    }

    function _35_checkSignedByAll() public view returns (bool)
    {
        require(signedUserNum>0, "no user");
        return userList.length == signedUserNum;
    }

    function _30_checkSignedByPerson(address user) public view returns (bool)
    {
        require(user != address(this));
        return balanceOfUser[user]==1;
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