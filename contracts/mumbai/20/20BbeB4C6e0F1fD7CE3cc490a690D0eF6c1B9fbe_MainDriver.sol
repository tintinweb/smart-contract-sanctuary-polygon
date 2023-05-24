/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MainDriver {

    event ReferralCodesRejected(string[] rejectedRefCodes);
    event ReferralCodeAdded(
        string indexed name,
        address indexed owner,
        uint256 indexed referralCodeId
    );
    enum e_refCodeType {
        none,
        tokens,
        NFTs,
        promoCodes
    }

    //user details
    mapping(address => s_userDetails) public m_userInfo;
    //refCodeName => refCodeId
    mapping(string => uint256) public m_userReferralCodeId;
    //user => refCodeId => redeemed(1)/!redeemed(0)
    mapping(address => mapping(uint256 => uint256)) public m_redeemedRefCodes;
    //user => History of PC & RCs
    mapping(address => s_usedCodes) m_usedCodesPerUser;
    //id => referralCode
    mapping(uint256 => S_ReferralCode) public m_referralCode;

    uint256 userId;
    bool ContractIsPaused;
    uint256[] public UsedUpRefCodes;
    uint256 public refCodeIdForUsers;

    struct s_userDetails {
        string name;
        uint256 id; //userId
        uint256 personalRefCodeId; //the RCID assigned when the user is assigned rc (to give others)
        uint16 numOfReferrals; //
        bool isActive;
        address[] referredUsers;
    }

    struct S_ReferralCode {
        string name;
        address owner;
        e_refCodeType rewardType;
        uint8 numOfTokens;
        uint64 limitOfUse; //how many referrals are allowed.
    }
    
    struct s_usedCodes {
        //History?
        uint256[] refCodeIds;
        uint256[] promoCodeIds;
        uint256[] personalRefCodeIds;
    }

    constructor( address _referralCodeContract) {
        ReferralCodeContract = _referralCodeContract;
    }
    //local state
    address ReferralCodeContract;
    address FactoryContract;

    function registerUser ( address _newUser, string calldata _name ) external {
        (bool success, bytes memory data) = ReferralCodeContract.delegatecall(
            abi.encodeWithSignature("registerUser(address,string)", _newUser, _name)
        );
        require(success, "dc failed");
    } 

    function addReferralCode( string calldata _name, address _userAddress, uint8 _rewardType, uint8 _numOfTokens ,uint64 _limitOfUse) external {
        (bool success, bytes memory data) = ReferralCodeContract.delegatecall (
            abi.encodeWithSignature("addReferralCode(string,address,uint8,uint8,uint64)", _name,_userAddress,_rewardType,_numOfTokens,_limitOfUse)
        );
        require(success, "dc failed");
    }

    // function addMultipleReferralCodes(S_ReferralCode[] calldata _userReferralCodes) external {
    //     (bool success, bytes memory data) = ReferralCodeContract.delegatecall (
    //         abi.encodeWithSignature("addMultipleReferralCodes()", _userReferralCodes )
    //     );
    //     require(success, "dc failed");
    // }    
}