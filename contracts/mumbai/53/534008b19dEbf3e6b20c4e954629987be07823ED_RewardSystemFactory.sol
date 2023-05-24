/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// File: ReferralCodeManager.sol

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
// File: MainDriver.sol



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
// File: RewardSystemFactory.sol





contract RewardSystemFactory {

//events
    event newDriverInstanceCreated (string _orgName, uint256 instanceId, address _orgAdmin);

//State variables
    address SuperAdmin;
    uint256 InstanceId;

    struct S_OrgDetails{  
        uint256 orgInstanceId;
        address owner;
        MainDriver mainDriverContract;
        ReferralCodeManager referralCodeContract;
        address promoCodeContract;
        bool accessAllowed;  
    }

//mappings
    mapping (uint256 => S_OrgDetails) public m_instanceInfo;
    mapping (address => uint256) public m_ownerInstanceId; 
    
//check functions
    function allowSuperAdmin() private view {
        require(msg.sender == SuperAdmin, "unauthorized call");
    }

    function checkIfInstanceIdExists(address _orgAdminAddress) private view returns(bool) {
        return getInstanceId(_orgAdminAddress) == 0 ? false : true ;
    }
 
//constructor
    constructor() {
        SuperAdmin = msg.sender;
    }

//modifiers
    modifier isSuperAdmin() {
        allowSuperAdmin();
        _;
    }

//compulsory creations
    function createNewMainDriverInstance(uint256 _instanceId, address _refCodeContract) private  returns(MainDriver){
       MainDriver mainDriver =  m_instanceInfo[_instanceId].mainDriverContract = new MainDriver(_refCodeContract);
    }   

    function createNewreferralCodeInstance(uint256 _instanceId) private returns (ReferralCodeManager) {
        ReferralCodeManager refCodeContract = new ReferralCodeManager();
        m_instanceInfo[_instanceId].referralCodeContract = refCodeContract; 
        return refCodeContract;
    }   

    function createNewPromoCodeInstance(uint256 _instanceId) private {}      //pc could be too      
    function createNewRewardsTokenPool( uint256 _instanceId) private {}

//main 
    function createNewInstanceSet(address _orgAdmin ) public isSuperAdmin {
        require ( !checkIfInstanceIdExists(_orgAdmin), "instance not found");

        ++InstanceId;
        m_ownerInstanceId[_orgAdmin] = InstanceId;
        m_instanceInfo[InstanceId].orgInstanceId = InstanceId;
        m_instanceInfo[InstanceId].owner         = _orgAdmin;
        m_instanceInfo[InstanceId].accessAllowed = true;
        ReferralCodeManager refCodeInstanceAddress = createNewreferralCodeInstance(InstanceId);
        createNewMainDriverInstance(InstanceId, address(refCodeInstanceAddress));     
    }

    function banAccessforOrg ( address _orgAdmin) external isSuperAdmin{
        require ( checkIfInstanceIdExists(_orgAdmin), "instance not found");
        m_instanceInfo[getInstanceId(_orgAdmin)].accessAllowed = false;    
        
    }

    function allowAccessforOrg ( address _orgAdmin ) external isSuperAdmin {
        require ( checkIfInstanceIdExists(_orgAdmin), "instance not found");
        m_instanceInfo[getInstanceId(_orgAdmin)].accessAllowed = true;     
        
    }

    function replaceInstanceAdmin( address _oldAdminAddress, address _newAdminAddress) external {
       require ( !checkIfInstanceIdExists(_newAdminAddress), "admin exists" );
       require ( checkIfInstanceIdExists(_oldAdminAddress), "instance not found");

       uint256 instanceId = m_ownerInstanceId[_oldAdminAddress]; 
       S_OrgDetails memory orgDetail = m_instanceInfo[instanceId];
    //    m_instanceInfo[_oldAdminAddress].accessAllowed = false;
       m_instanceInfo[instanceId] = orgDetail;
    }

//view funcs
    function getInstanceId( address _orgAdmin) public view isSuperAdmin returns (uint256) {
        return m_ownerInstanceId[_orgAdmin]; 
    }
}




/* 
1. deploy reward
2. deploy promo
3. pass params in the main Driver and deploy
4. give access to relayer
5. // address promoCodeInstanceAddress = createNewPromoCodeInstance(InstanceId); 

*/