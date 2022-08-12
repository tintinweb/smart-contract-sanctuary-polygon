/**
 *Submitted for verification at polygonscan.com on 2022-08-12
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


//modification: wordings: sign->receive
//gas reduction
//added modifier

contract NewContract_6_6 {

    uint256 contractID;
    string nameOfContract;
    // uint8 decimalsOfToken = 0;
    uint256 totalSupplyOfToken; //total token supply =0
    string IpfsURI;
    string nameOfOwner;

    uint userLimit;
    address[] userList; //can be used to get user number
    uint receivedUserNum;
    mapping(address=>bool)  askedToReceive;
    mapping(address=>uint256) balanceOfUser; //stores the users' balance with their address
    bool paused;

    // address public owner;  //only the owner can set who can receive doc of this contract 
    address public admin;  //admin is the one who can pause this contract, the admin contract creating this contract
    address public linkedContract;

    // modifier onlyOwner(){
    //     require (msg.sender == owner);
    //     _;
    // }

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
    }   //

    function _1_setNameOfOwner(string calldata name) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin");

        nameOfOwner = name;
    }   //

    function _2_setLinkedContract(address contractAddress) public
    {
        require(paused == false, "paused by admin");
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

    function _6_set_askedToReceive(address[] memory array) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "not admin of this contract");


        address[] memory input = array;
        uint addressLength = input.length;

        require(addressLength    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");
        // require(input.length    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");


        uint successNum=0;      //stores the number of users successfully added 
        for(uint i=0; i<addressLength; i++)
        {
            // if(askedToReceive[input[i]] ==false && input[i] != 0x0000000000000000000000000000000000000000)
            if(askedToReceive[input[i]] ==false)
            //meaning that this person has not been added to receive list, and address is not null, so we need to add this
            {
                userList.push(input[i]);
                askedToReceive[input[i]] =true;
                successNum++;
            }
            //else case:
            //this person has already been added to receive list, so we ignore it
        }
        return successNum;
    }

    // function _7_set_askedToReceive(address[] calldata array) public returns (uint)
    // {
    //     require(paused == false, "paused by admin");
    //     require(msg.sender == admin, "not admin of this contract");


    //     address[] calldata input = array;
    //     uint addressLength = input.length;

    //     require(addressLength    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");
    //     // require(input.length    +   userList.length <= userLimit, "number of users required to receive exceed limit of number of users of this contract");


    //     uint successNum=0;      //stores the number of users successfully added 
    //     for(uint i=0; i<addressLength; i++)
    //     {
    //         address temp = input[i];
    //         // if(askedToReceive[input[i]] ==false && input[i] != 0x0000000000000000000000000000000000000000)
    //         if(askedToReceive[temp] ==false)
    //         //meaning that this person has not been added to receive list, and address is not null, so we need to add this
    //         {
    //             userList.push(temp);
    //             askedToReceive[temp] =true;
    //             successNum++;   
    //         }
    //         //else case:
    //         //this person has already been added to receive list, so we ignore it
    //     }
    //     return successNum;
    // }

    function _8_SendThroughAdmin(address user) public 
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        require(askedToReceive[user] ==true, "the user is not asked to receive doc of this contract");
        require(balanceOfUser[user] == 0, "the user already receive doc of this contract");

        // require(user != 0x0000000000000000000000000000000000000000, "null address");
        //optional, as user could not be set to be 0x000000... in _6_
        
        receivedUserNum++;
        balanceOfUser[address(this)] -=1;
        balanceOfUser[user] +=1; 
    }

    function _9_SendMultipleThroughAdmin(address[] memory inputUsers) public returns (uint)
    {
        require(paused == false, "paused by admin");
        require(msg.sender == admin, "admin only");

        uint successNum=0;

        address[] memory users = inputUsers;
        uint length = users.length;

        for(uint i = 0; i < length; i++)
        {
            address temp = users[i];
            if(askedToReceive[temp] ==true && balanceOfUser[temp] == 0)
            //that user is in the list and not yet received, so we send a token from this contract
            {

                successNum++;
                //in _6_ the askedToReceive[] list is set a limit, so the balanceOfUser address(this) would >=0

                balanceOfUser[address(this)]    -=1;
                balanceOfUser[temp]         +=1;
            }
        }
        receivedUserNum+=successNum;

        return successNum;  //return the successful received user number 
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

    function _28_checkReceivedNum() public view returns (uint)
    {
        return receivedUserNum;
    }

    function _29_balanceOf(address _owner) public view returns (uint256)
    {
        return balanceOfUser[_owner];
    }

    function _35_checkReceivedByAll() public view returns (bool)
    {
        require(receivedUserNum>0, "no user");
        return userList.length == receivedUserNum;
    }

    function _30_checkReceivedByPerson(address user) public view returns (bool)
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