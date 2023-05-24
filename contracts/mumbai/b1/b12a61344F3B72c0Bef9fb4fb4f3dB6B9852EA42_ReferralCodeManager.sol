/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ReferralCodeManager{
    
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

    function registerUser(address _newUser, string calldata _name ) external {
        require(m_userInfo[_newUser].id == 0, "Already registered.");
        m_userInfo[_newUser].name = _name;
        m_userInfo[_newUser].id = ++userId;
    }

    function addReferralCode( string memory _name, address _userAddress, e_refCodeType _rewardType, uint8 _numOfTokens ,uint64 _limitOfUse) public {
        m_userReferralCodeId[_name] = ++refCodeIdForUsers;
        m_usedCodesPerUser[_userAddress].personalRefCodeIds.push(refCodeIdForUsers);
        m_userInfo[_userAddress].personalRefCodeId = refCodeIdForUsers;
        m_referralCode[refCodeIdForUsers] = S_ReferralCode({
            name: _name,
            owner: _userAddress,
            rewardType: _rewardType,
            numOfTokens: _numOfTokens,
            limitOfUse: _limitOfUse
        });
    }

    function discardReferralCode(string memory _refCodeName) external {

        uint256 refCode = m_userReferralCodeId[_refCodeName];
        m_referralCode[refCode].limitOfUse = 0;
    }

    function addMultipleReferralCodes(S_ReferralCode[] memory _userReferralCodes) external {
        uint256 len = _userReferralCodes.length;
        if (len > 255) {
            revert("Max 255 refCodes allowed per tx.");
        }
        uint8 ptr = 0;
        string[] memory rejectedRefCodes = new string[](255); //check limit
        for (uint256 i; i < len; ++i) {
            S_ReferralCode memory refCode = _userReferralCodes[i];
            if (
                // m_userReferralCodeId[refCode.name] == 0 &&
                m_userInfo[refCode.owner].id != 0
            ) {
                addReferralCode(
                    refCode.name,
                    refCode.owner,
                    refCode.rewardType,
                    refCode.numOfTokens,
                    refCode.limitOfUse 
                );
                emit ReferralCodeAdded(
                    refCode.name,
                    refCode.owner,
                    m_userReferralCodeId[refCode.name]
                );
            } else {
                rejectedRefCodes[ptr] = refCode.name;
                ++ptr;
            }
        }
        if (ptr > 0) {
            if (ptr >= 200) {
                emit ReferralCodesRejected(rejectedRefCodes);
            } else {
                string[] memory rejectedRefCodesTrimmed = new string[](ptr);
                for (uint256 i = 0; i < ptr; ++i) {
                    rejectedRefCodesTrimmed[i] = rejectedRefCodes[i];
                }
                emit ReferralCodesRejected(rejectedRefCodesTrimmed);
            }
        }
    } 

    function getUsersRefCodeHistory() external {
    }

    function distributeRewards() external {
        
    }
}