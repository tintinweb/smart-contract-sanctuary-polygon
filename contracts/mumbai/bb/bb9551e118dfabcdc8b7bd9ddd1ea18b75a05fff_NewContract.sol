/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

/*
contract Controller {

    address[] contractList; //start from NewContract[0]

    address admin;

    constructor()
    {
        admin = msg.sender;
    }

    function createContract(uint ID, string memory contractName, string memory OwnerName, string memory URI, uint userLimitNum) public {
        contractList.push(address(new NewContract(ID,contractName,OwnerName,URI,userLimitNum, admin)));
    }

    function getContractAddress(uint contractID)public view returns (address){
        return contractList[contractID];
    }

    function getContractNum() public view returns(uint){
        return contractList.length;
    }

    function _21_getName(uint input) public view returns (string memory){
        return NewContract(contractList[input])._21_getName();
    }

    function _21_getNameAddress(address input) public view returns (string memory){
        return NewContract(input)._21_getName();
    }


}
*/

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
        require(paused == false, "this contract has been paused by admin");
        require(msg.sender == admin, "not admin");
        nameOfOwner = name;
    }

    function _2_setLinkedContract(address contractAddress) public
    {
        require(paused == false, "this contract has been paused by admin");
        require(msg.sender == admin, "not admin");
        require(contractAddress != 0x0000000000000000000000000000000000000000, "null address");
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
        require(paused == false, "this contract has been paused by admin");
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

    function _7_sign() public 
    {
        require(paused == false, "this contract has been paused by admin");
        require(askedToSign[msg.sender] ==true, "you are not asked to sign this contract");
        require(balanceOfUser[msg.sender] == 0, "you already signed this contract");
        signedUserNum++;
        balanceOfUser[address(this)] -=1;
        balanceOfUser[msg.sender] +=1; 
    }

    function _8_signThroughAdmin(address user) public 
    {
        require(paused == false, "this contract has been paused by admin");
        require(msg.sender == admin, "only admin can perform this action ");
        require(askedToSign[user] ==true, "you are not asked to sign this contract");
        require(balanceOfUser[user] == 0, "that user already signed this contract");
        require(user != 0x0000000000000000000000000000000000000000, "null address");
        
        signedUserNum++;
        balanceOfUser[address(this)] -=1;
        balanceOfUser[user] +=1; 
    }

    
    //viewers

    function getID() public view returns (uint){
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

        function checkSignedByAll() public view returns (bool)
    {
        return userList.length == signedUserNum;
    }

    function _30_checkSignedByPerson(address user) public view returns (bool)
    {
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