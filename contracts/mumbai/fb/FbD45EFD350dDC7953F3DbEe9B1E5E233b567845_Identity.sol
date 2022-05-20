/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

/// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

/// @author Aman035 & Nilesh46
/// @title Identification And Verification System

contract Identity {
    
/// STRUCTS

    /// @dev Identity Structure
    /// @notice Hash Contains IPFS hash in encrypted form - can be decrypted only by owner address
    struct identity {
        string Name;
        string Hash;
        address Owner;
        address Issuer;
        string OwnerSignature;
        string IssuerSignature;
    }

    /// @dev User Structure which keeps its identities and encryption public key
    /// @notice A User can hold multiple identities
    struct user {
        address UserAddress;
        string PublicKey;
        bool Registered;
        uint IdCount;
        mapping(uint => identity) Ids;
    }

    /// @dev Identity Verification Structure used to verify an Identity
    /// @notice A User can hold multiple identities
    struct verifyIdRequest {
        address Owner;
        string Hash;
        uint Status;
    }

     /// @dev Issuer Verification Structure used to verify Issuer Account
    /// @notice Status - 0->rejected , 1->pending , 2->Accepted
    struct issuerVerificationRequest {
        address Owner;
        uint Status;
        string Id;
        string Desc;
    }

    /// @dev Issuer Structure having details about Issuer Account
    /// @notice An Issuer Can Verify only 1 identity , Status - 0->unverified , 1->pending , 2->Accepted
    struct issuer {
        address IssuerAddress;
        string Desc;
        uint Status; //0->unverified , 1->pending , 2->Accepted
        string IssueId;
        uint ReqCount;
        mapping(uint => verifyIdRequest) Request;
    }

/// GLOBAL VARIABLES

    address public Owner;
    issuer[] public Issuer;
    issuerVerificationRequest[] public IssuerVerificationRequest;
    mapping(address => user) public UserDetail;
    mapping(address => issuer) public IssuerDetail;


    constructor() public {
        Owner = msg.sender;
    }


/// MODIFIERS

    /// check message sent by owner
    modifier restricted() {
        require(msg.sender == Owner,"Not Authorized");
        _;
    }

    /// check Account Registeration
    modifier registered(address account) {
        require(UserDetail[account].Registered == true,"This Account is not Registered");
        _;
    }

    /// check an account is issuer
    modifier issue(address account) {
        require(IssuerDetail[account].Status == 2,"This Account does not issue any Id");
        _;
    }

/// FUNCTIONS

    /// @notice Register User Account
    /// @param _PublicKey Public Encyption Key 
    function registerUser(string memory _PublicKey) public {
        require(UserDetail[msg.sender].Registered == false,"Account Already Registered");
        user memory newUser;
        newUser.UserAddress = msg.sender;
        newUser.IdCount = 0;
        newUser.PublicKey = _PublicKey;
        newUser.Registered = true;
        UserDetail[msg.sender] = newUser;
    }

    /// @notice Request An Issuer Account
    /// @param _Desc Account Description
    /// @param _IssueId Id Issued
    function requestIssuerAccount(string memory _Desc, string memory _IssueId) registered(msg.sender) public {
        require(IssuerDetail[msg.sender].Status == 0,
        "Either Account is already an Issuer or has a pending issuer request");

        issuer memory newIssuer;
        newIssuer.IssuerAddress = msg.sender;
        newIssuer.Status = 1;
        newIssuer.Desc = _Desc;
        newIssuer.IssueId = _IssueId;
        newIssuer.ReqCount = 0;  
        IssuerDetail[msg.sender] = newIssuer; 

        /// create a issuer account verification request
        issuerVerificationRequest memory NewRequest;
        NewRequest.Owner = msg.sender;
        NewRequest.Status = 1;
        NewRequest.Id = _IssueId;
        NewRequest.Desc = _Desc;
        IssuerVerificationRequest.push(NewRequest);
    }

    /// @notice Verify/accept Issuer Account by owner
    /// @param _RqNo Request No. of Account
    function verifyIssuerAccount(uint _RqNo) restricted public {
        require(_RqNo < IssuerVerificationRequest.length , "Request Not Found");
        address IssuerAddress = IssuerVerificationRequest[_RqNo].Owner;
        require(IssuerVerificationRequest[_RqNo].Status == 1 , "Request Already Processed");
        require(IssuerDetail[IssuerAddress].Status == 1,
        "Either Account is already an Issuer or did not wish to be an issuer currently");
        
        IssuerDetail[IssuerAddress].Status = 2;
        Issuer.push(IssuerDetail[IssuerAddress]);
        IssuerVerificationRequest[_RqNo].Status = 2;
    }

    /// @notice Reject Issuer Account by owner
    /// @param _RqNo Request No. of Account
    function rejectIssuerAccount(uint _RqNo) restricted public {
        require(_RqNo < IssuerVerificationRequest.length , "Request Not Found");
        address IssuerAddress = IssuerVerificationRequest[_RqNo].Owner;
        require(IssuerVerificationRequest[_RqNo].Status == 1 , "Request Already Processed");
        require(IssuerDetail[IssuerAddress].Status == 1,
        "Either Account is already an Issuer or did not wish to be an issuer currently");
        
        IssuerDetail[IssuerAddress].Status = 0;
        IssuerVerificationRequest[_RqNo].Status = 0;
    }

    /// @notice Add a New Identity
    /// @param _Hash Encrypted IPFS hash containing ID details for owner
    /// @param _Issuer Issuer of Identity
    /// @param _Sign Identity Owner Signature - used for id verification
    /// @param _IssuerHash Encrypted copy of IPFS hash for Issuer
    function newId(string memory _Hash, address _Issuer,string memory _Sign, string memory _IssuerHash) 
    registered(msg.sender) issue(_Issuer) public{
        identity memory NewId;
        NewId.Name = IssuerDetail[_Issuer].IssueId;
        NewId.Hash = _Hash;
        NewId.Owner = msg.sender;
        NewId.Issuer = _Issuer;
        NewId.OwnerSignature = _Sign;
        NewId.IssuerSignature = "Pending";
        UserDetail[msg.sender].Ids[UserDetail[msg.sender].IdCount++] = NewId;

        //create a verification request
        verifyIdRequest memory NewRequest;
        NewRequest.Owner = msg.sender;
        NewRequest.Hash = _IssuerHash;
        NewRequest.Status = 1;
        IssuerDetail[_Issuer].Request[IssuerDetail[_Issuer].ReqCount++] = NewRequest;
    }

    /// @notice Delete an Identity
    /// @param _IdNum Id no. to be deleted 
    function deleteId(uint _IdNum) registered(msg.sender) public {
        require(_IdNum < UserDetail[msg.sender].IdCount  , "Id does not Exist");

        for(uint i = _IdNum; i<UserDetail[msg.sender].IdCount-1 ; i++)
        UserDetail[msg.sender].Ids[i] = UserDetail[msg.sender].Ids[i+1];

        delete UserDetail[msg.sender].Ids[UserDetail[msg.sender].IdCount-1];
        UserDetail[msg.sender].IdCount--;
    }
    
    /// @notice Verify/Accept User Identity -By Issuer
    /// @param _ReqNo Request No. of Identity
    /// @param _Sign Issuer Signature - Serves As proof of ID verification
    function AcceptIdRequest(uint _ReqNo , string memory _Sign) 
    public registered(msg.sender) issue(msg.sender){
        require(_ReqNo < IssuerDetail[msg.sender].ReqCount, "Request Not Found");
        require(IssuerDetail[msg.sender].Request[_ReqNo].Status == 1 , 
        "Request Already Accepted or Rejected");

        bool flag = false;
        address User = IssuerDetail[msg.sender].Request[_ReqNo].Owner;

        for(uint i=0 ; i< UserDetail[User].IdCount ; i++){
            if(keccak256(bytes(UserDetail[User].Ids[i].Name)) == keccak256(bytes(IssuerDetail[msg.sender].IssueId)) && 
                keccak256(bytes(UserDetail[User].Ids[i].IssuerSignature)) == keccak256(bytes("Pending"))){
                UserDetail[User].Ids[i].IssuerSignature = _Sign;
                flag = true;
                break;
            }
        }
        if(flag == false)
        revert("User Identity Not Found");

        IssuerDetail[msg.sender].Request[_ReqNo].Status = 2;
    }

    /// @notice Reject User Identity -By Issuer
    /// @param _ReqNo Request No. of Identity
    function RejectIdRequest(uint _ReqNo) public registered(msg.sender) issue(msg.sender){
        require(_ReqNo < IssuerDetail[msg.sender].ReqCount, "Request Not Found");
        require(IssuerDetail[msg.sender].Request[_ReqNo].Status == 1 , "Request Already Accepted or Rejected");

        IssuerDetail[msg.sender].Request[_ReqNo].Status = 0;

        bool flag = false;
        address User = IssuerDetail[msg.sender].Request[_ReqNo].Owner;

        for(uint i=0 ; i< UserDetail[User].IdCount ; i++){
            if(keccak256(bytes(UserDetail[User].Ids[i].Name)) == keccak256(bytes(IssuerDetail[msg.sender].IssueId)) &&
                keccak256(bytes(UserDetail[User].Ids[i].IssuerSignature)) == keccak256(bytes("Pending"))){
                UserDetail[User].Ids[i].IssuerSignature = "Rejected";
                flag = true;
                break;
            }
        }
    }

    /// @return uint Total no. of Identities of Function Caller
    function totalId() public view returns (uint){
        return UserDetail[msg.sender].IdCount;
    }

    /// @param _IdNo Requested Identity No.
    /// @param account User Account
    /// @return Identity Identity of a User Account
    function getId(uint _IdNo, address account) public view returns (identity memory){
        require(_IdNo < UserDetail[account].IdCount, "Id does not exist");
        return UserDetail[account].Ids[_IdNo];
    }

    /// @return uint Total No. of Issuers
    function totalIssuer() public view returns (uint){
        return Issuer.length;
    }

    /// @return uint Total Identity Verification Requests for an Issuer
    function totalRequest() public view returns (uint){
        return IssuerDetail[msg.sender].ReqCount;
    }

    /// @param _RqNo Identity Verification Request No.
    /// @return verifyIdRequest Identity Request
    function getRequest(uint _RqNo) issue(msg.sender) public view returns (verifyIdRequest memory){
        require(_RqNo < IssuerDetail[msg.sender].ReqCount, "Request does not exist");
        return IssuerDetail[msg.sender].Request[_RqNo];
    }

    /// @return uint Total Issuer Account Verification Requests
    function issuerVerificationRequestCount() public view returns (uint){
        return IssuerVerificationRequest.length;
    }
}