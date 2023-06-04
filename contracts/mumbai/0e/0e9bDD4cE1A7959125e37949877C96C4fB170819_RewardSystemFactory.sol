// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./RewardTokenPool.sol";

contract MainDriver {

    //////////////////////////// ReferralCodeStorage //////////////////////////////////
    enum e_refCodeType {
        none,
        tokens,
        NFTs
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
        uint256 personalRefCodeId; //the RCID assigned when the user is assigned rc (to give others)
        uint16 numOfReferrals; //
        bool isActive;
        address[] referredUsers;
    }

    struct S_ReferralCode {
        string name;                    //rc name
        address owner;                  //owner of rc
        uint64 limitOfUse;              //total no. of times rc can be used. rc becomes unusable at 0.
        e_refCodeType rewardType;       //token/NFT etc
        uint256[2] minimumUsers;        //[ counter, criteria]   //min criteria for owner to receive the reward. 
        uint256 tokensForOwner;         //tokens sent to the referralCode owner once criteria is met.
        uint256 tokensForUser;          //tokens for each use.
    }
    
    struct s_usedCodes {
        //History?
        uint256[] referralCodeIds;
        uint256[] promoCodeIds;
        uint256[] personalReferralCodeIds;
    }

    /////////////////////////////////// Promo code storage ///////////////////////////////////////////
    struct S_PromoCode { 
        string name;
        uint256 limitOfUse;
        uint256 erc20Tokens;
        uint256[3] nftTokens;
        uint256 endTime;
    }

    mapping (uint256 => S_PromoCode) public m_promoCodes;
    mapping (string => uint256) public m_promoCodeIds; 
    mapping (address => mapping(uint256 => uint256)) m_userAvailedPromocodes; 
    uint256[] AllPromoCodes;
    uint256 CurrentPromoCodeId;

    //////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address _relayerContract, string memory _organizationName, address _promoCodeContract, address _referralCodeContract, RewardTokenPool _rewardPoolContract) {
        OrganizationName = _organizationName;
        PromoCodeContract = _promoCodeContract;
        ReferralCodeContract = _referralCodeContract;
        PoolContract = _rewardPoolContract;
        RelayerContract = _relayerContract;
    }

    modifier isRelayerContract{
        require(msg.sender == RelayerContract, "only Relayer can call");
        _;
    }
    //local state
    address PromoCodeContract;
    address ReferralCodeContract;
    address RelayerContract;
    string  OrganizationName;
    RewardTokenPool PoolContract;
    
    /////////////////////////////// PromoCodes //////////////////////////////////////////////

    function addPromoCode( string memory _name,  uint256 _limitOfUse,  uint256 _erc20Tokens, uint256[3] memory _nftTokens, uint256 _endTime ) private {
        require ( m_promoCodeIds[_name] == 0, "pc exists");
        require ( _endTime > block.timestamp, "pc validity > current time");                  //promocode should atleast be a day long. 
        
        (bool success, ) = PromoCodeContract.delegatecall (
            abi.encodeWithSignature("addPromoCode(string,uint256,uint256,uint256[3],uint256)", 
                                    _name,_limitOfUse,_erc20Tokens,_nftTokens,_endTime)
                                    );
        require(success, "dc failed");
    }

    function addMultiplePromoCodes( S_PromoCode[] memory _promoCodes) isRelayerContract external {
        uint8 i; //less than 255 allowed //put check
        uint256 length = _promoCodes.length;
        for (i ; i<length ; i++ ){
            S_PromoCode memory promoCode = _promoCodes[i];
            addPromoCode(
                            promoCode.name,
                            promoCode.limitOfUse,
                            promoCode.erc20Tokens,
                            promoCode.nftTokens,
                            promoCode.endTime
                        );
        }
    }

    function redeemPromoCode( string memory _promoCodeName, address _promoCodeUser) isRelayerContract external{
        uint256 promoCodeId = m_promoCodeIds[_promoCodeName];
        
        (bool success,) = PromoCodeContract.delegatecall(
            abi.encodeWithSignature("redeemPromoCode(uint256,address)", promoCodeId, _promoCodeUser )
        );
        require(success, "dc failed");

        PoolContract.sendTokens(_promoCodeUser, m_promoCodes[promoCodeId].erc20Tokens);
    } 


////////////////////////////////////////Referral Codes/////////////////////////////////////////////
    function addReferralCode(   string memory _name, 
                                address _ownerAddress,
                                uint64 _limitOfUse,
                                uint8 _rewardType, 
                                uint256[2] memory _minimumUsers,
                                uint256 _tokensForOwner,
                                uint256 _tokensForUser) private {
        (bool success, ) = ReferralCodeContract.delegatecall (
            abi.encodeWithSignature("addReferralCode(string,address,uint64,uint8,uint256[2],uint256,uint256)", 
                                    _name,_ownerAddress,_limitOfUse,_rewardType,_minimumUsers,_tokensForOwner,_tokensForUser)
                                    );
        require(success, "dc failed");
    }

    function addMultipleReferralCodes(S_ReferralCode[] calldata _userReferralCodes) isRelayerContract external {
        
        uint8 i; //less than 255 allowed //put check
        uint256 length = _userReferralCodes.length;
        for (i ; i<length ; i++ ){
            S_ReferralCode memory referralCode = _userReferralCodes[i];
            addReferralCode(
                                referralCode.name, 
                                referralCode.owner,
                                referralCode.limitOfUse,
                                uint8(referralCode.rewardType),
                                referralCode.minimumUsers,
                                referralCode.tokensForOwner,
                                referralCode.tokensForUser  
                            );          
        }
    }

    function redeemReferralCode(string memory _referralCodeName, address _referralCodeUser ) isRelayerContract external {
        uint256 referralCodeId = m_userReferralCodeId[ _referralCodeName];
        (bool success, bytes memory returnData) = ReferralCodeContract.delegatecall(
            abi.encodeWithSignature("redeemReferralCode(uint256,address)", referralCodeId, _referralCodeUser )
        );
        require(success, "dc failed");

        S_ReferralCode memory referralCode = m_referralCode[referralCodeId];
        ( bool rewardOwner, bool rewardUser ) = abi.decode(returnData, ( bool,bool ));
        
        if ( rewardUser == true)
        PoolContract.sendTokens(_referralCodeUser, m_referralCode[referralCodeId].tokensForUser);
        if ( rewardOwner == true)
        PoolContract.sendTokens(referralCode.owner ,referralCode.tokensForOwner );
    }    

    function getPromoCodeDetails(string memory _name) public view returns(S_PromoCode memory){
        return m_promoCodes[m_promoCodeIds[_name]];
    }

    function getReferralCodeDetails(string memory _name) public view returns(S_ReferralCode memory ){
        return m_referralCode[m_userReferralCodeId[_name]];
    }

    function getUserDetails(address _user) public view returns(s_userDetails memory ){
        return m_userInfo[_user];
    }

    function getUserHistory(address _user) public view returns(s_usedCodes memory) {
        return  m_usedCodesPerUser[_user];
    }  
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PromoCodeManager{
    //////////////////////////// ReferralCodeStorage //////////////////////////////////
    enum e_refCodeType {
        none,
        tokens,
        NFTs
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
        uint256 personalRefCodeId; //the RCID assigned when the user is assigned rc (to give others)
        uint16 numOfReferrals; //
        bool isActive;
        address[] referredUsers;
    }

    struct S_ReferralCode {
        string name;                    //rc name
        address owner;                  //owner of rc
        uint64 limitOfUse;              //total no. of times rc can be used. rc becomes unusable at 0.
        e_refCodeType rewardType;       //token/NFT etc
        uint256[2] minimumUsers;        //[ counter, criteria]   //min criteria for owner to receive the reward. 
        uint256 tokensForOwner;         //tokens sent to the referralCode owner once criteria is met.
        uint256 tokensForUser;          //tokens for each use.
    }
    
    struct s_usedCodes {
        //History?
        uint256[] referralCodeIds;
        uint256[] promoCodeIds;
        uint256[] personalReferralCodeIds;
    }

    /////////////////////////////////// Promo code storage ///////////////////////////////////////////
    struct S_PromoCode { 
        string name;
        uint256 limitOfUse;
        uint256 erc20Tokens;
        uint256[3] nftTokens;
        uint256 endTime;
    }

    mapping (uint256 => S_PromoCode) public m_promoCodes;
    mapping (string => uint256) public m_promoCodeIds; 
    mapping (address => mapping(uint256 => uint256)) m_userAvailedPromocodes; 
    uint256[] AllPromoCodes;
    uint256 CurrentPromoCodeId;
    
    /////////////////////////////// PromoCodes //////////////////////////////////////////////

    function addPromoCode( string memory _name,  uint256 _limitOfUse,  uint256 _erc20Tokens, uint256[3] memory _nftTokens, uint256 _endTime ) external {
        
        m_promoCodeIds[_name] = ++CurrentPromoCodeId;
        AllPromoCodes.push(CurrentPromoCodeId);
        m_promoCodes[ CurrentPromoCodeId ] = S_PromoCode({ name: _name,
                                                             limitOfUse: _limitOfUse,
                                                             erc20Tokens: _erc20Tokens,
                                                             nftTokens: _nftTokens,
                                                             endTime: _endTime
        });
    }

    function redeemPromoCode( uint256 _promoCodeId, address _promoCodeUser) external{
        S_PromoCode memory promoCode = m_promoCodes[_promoCodeId];
        require ( m_userAvailedPromocodes[_promoCodeUser][_promoCodeId] == 0 , "pc availed" );
        require ( promoCode.limitOfUse != 0, "pc at limit" );
        require ( promoCode.endTime > block.timestamp, "pc offer ended" );

        m_userAvailedPromocodes[_promoCodeUser][_promoCodeId] = 1;
        m_usedCodesPerUser[_promoCodeUser].promoCodeIds.push(_promoCodeId);
        m_promoCodes[_promoCodeId].limitOfUse--;

    }
}

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
        NFTs
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
        string name;                    //rc name
        address owner;                  //owner of rc
        uint64 limitOfUse;              //total no. of times rc can be used. rc becomes unusable at 0.
        e_refCodeType rewardType;       //token/NFT etc
        uint256[2] minimumUsers;        //[counter,criteria]   //min criteria for owner to receive the reward. 
        uint256 tokensForOwner;         //tokens sent to the referralCode owner once criteria is met.
        uint256 tokensForUser;          //tokens for each use.
    }
    
    struct s_usedCodes {
        //History?
        uint256[] referralCodeIds;
        uint256[] promoCodeIds;
        uint256[] personalReferralCodeIds;
    }

    ////////////////////////////////////////////// Helper Functions ///////////////////////////////////////////

    
    function checkreferralCodeIsValid( uint256 _referralCodeId ) private view {
        require(m_referralCode[_referralCodeId].limitOfUse != 0,"Rc at limit");
    }
    
    ///////////////////////////////////////////// State changers ////////////////////////////////////

    function addReferralCode(   string memory _name, 
                                address _ownerAddress,
                                uint64 _limitOfUse,
                                e_refCodeType _rewardType,
                                uint256[2] memory _minimumUsers,
                                uint256 _tokensForOwner,
                                uint256 _tokensForUser) public {
    
        require(m_userReferralCodeId[_name] == 0, "rc exists" );
        m_userReferralCodeId[_name] = ++refCodeIdForUsers;
        m_usedCodesPerUser[_ownerAddress].personalReferralCodeIds.push(refCodeIdForUsers);
        m_userInfo[_ownerAddress].personalRefCodeId = refCodeIdForUsers;
        m_referralCode[refCodeIdForUsers] = S_ReferralCode({
            name: _name,
            owner: _ownerAddress,
            limitOfUse: _limitOfUse,
            rewardType: _rewardType,
            minimumUsers: _minimumUsers,
            tokensForOwner: _tokensForOwner,
            tokensForUser: _tokensForUser
        });
    }
        
    function discardReferralCode(uint256 _referralCodeId) external {
        m_referralCode[ _referralCodeId ].limitOfUse = 0;
    }

    function redeemReferralCode(uint256 _referralCodeId, address _referralCodeUser) external returns (bool, bool)  {
        bool rewardOwner;    //flags to be returned in mainDriver
        bool rewardUser; 
        S_ReferralCode memory referralCode =  m_referralCode[_referralCodeId];
        checkreferralCodeIsValid(_referralCodeId);
        m_referralCode[ _referralCodeId ].limitOfUse--; 
        m_usedCodesPerUser[_referralCodeUser].referralCodeIds.push(_referralCodeId);
        m_redeemedRefCodes[_referralCodeUser][_referralCodeId] = 1;                           //add a check
        m_userInfo[referralCode.owner].numOfReferrals++;
        m_userInfo[referralCode.owner].referredUsers.push(_referralCodeUser);
        
        if ( referralCode.rewardType != e_refCodeType(0)){
            if ( referralCode.minimumUsers[0] < referralCode.minimumUsers[1] )  
                m_referralCode[ _referralCodeId ].minimumUsers[0]++;
            else{
                m_referralCode[_referralCodeId].minimumUsers[0] = 0;
                rewardOwner = true;
            } 
            if (referralCode.tokensForUser != 0)
                rewardUser = true;    
        }           
        return (rewardOwner,rewardUser);
        
    } 

    

    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MainDriver.sol";
import "./RewardTokenPool.sol";
import "./ReferralCodeManager.sol";
import "./PromoCodeManager.sol";
import "./RewardSystemRelayer.sol";


contract RewardSystemFactory {

//events
    event newDriverInstanceCreated ( uint256 instanceId, address _orgAdmin);

//State variables
    address SuperAdmin;
    uint256 InstanceId;
    RewardSystemRelayer public RelayerContract;

    struct S_OrgDetails{  
        uint256 orgInstanceId;
        address owner;
        MainDriver mainDriverContract;
        ReferralCodeManager referralCodeContract;
        RewardTokenPool poolContract;
        PromoCodeManager promoCodeContract; 
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
    function createNewMainDriverInstance( uint256 _instanceId, address _relayerContract, string memory _organizationName, address _promoCodeContract, address _refCodeContract, RewardTokenPool _rewardPoolContract  ) private  returns(MainDriver){
       MainDriver mainDriver = new MainDriver(_relayerContract ,_organizationName, _promoCodeContract, _refCodeContract, _rewardPoolContract);
       m_instanceInfo[_instanceId].mainDriverContract = mainDriver;
       return mainDriver;
    }   

    function createNewReferralCodeInstance(uint256 _instanceId) private returns (ReferralCodeManager) {
        ReferralCodeManager refCodeContract = new ReferralCodeManager();
        m_instanceInfo[_instanceId].referralCodeContract = refCodeContract; 
        return refCodeContract;
    }   
          
    function createNewRewardPoolInstance( uint256 _instanceId, address _ercTokenContract) private returns (RewardTokenPool) {
        RewardTokenPool rewardPoolContract = new RewardTokenPool(_ercTokenContract);
        m_instanceInfo[_instanceId].poolContract = rewardPoolContract; 
        return rewardPoolContract;
    }

    function createNewPromoCodeInstance(uint256 _instanceId) private returns (PromoCodeManager){
        PromoCodeManager promoCodeContract = new PromoCodeManager();
        m_instanceInfo[_instanceId].promoCodeContract = promoCodeContract; 
        return promoCodeContract;
    } 

//main 
    function createNewInstanceSet(string memory _orgName, address _orgAdmin, address _ercTokenContract ) external isSuperAdmin {
        require ( !checkIfInstanceIdExists(_orgAdmin), "instance exists");
        require (address(RelayerContract) != address(0), "relayer reference missing");

        ++InstanceId;
        m_ownerInstanceId[_orgAdmin] = InstanceId;
        m_instanceInfo[InstanceId].orgInstanceId = InstanceId;
        m_instanceInfo[InstanceId].owner         = _orgAdmin; 
        ReferralCodeManager refCodeInstanceAddress = createNewReferralCodeInstance(InstanceId);
        PromoCodeManager promoCodeInstance =  createNewPromoCodeInstance(InstanceId);
        RewardTokenPool poolContractInstance = createNewRewardPoolInstance(InstanceId, _ercTokenContract);
        MainDriver mainDriverContract              = createNewMainDriverInstance(InstanceId, address(RelayerContract), _orgName, address(promoCodeInstance), address(refCodeInstanceAddress), poolContractInstance );
        RelayerContract.addNewInstanceToRecord(InstanceId,_orgAdmin,mainDriverContract);
        emit newDriverInstanceCreated(InstanceId, _orgAdmin);
    }

    function setRelayerAddress(RewardSystemRelayer _address) external isSuperAdmin{
        RelayerContract = _address;
    }

    function replaceInstanceAdmin( address _oldAdminAddress, address _newAdminAddress) external isSuperAdmin{
       require ( !checkIfInstanceIdExists(_newAdminAddress), "admin exists" );
       require ( checkIfInstanceIdExists(_oldAdminAddress), "instance not found");

       uint256 instanceId = m_ownerInstanceId[_oldAdminAddress]; 
       S_OrgDetails memory orgDetail = m_instanceInfo[instanceId];
       m_instanceInfo[instanceId] = orgDetail;
    }

//view funcs
    function getInstanceId( address _orgAdmin) public view isSuperAdmin returns (uint256) {
        return m_ownerInstanceId[_orgAdmin]; 
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./MainDriver.sol";

contract RewardSystemRelayer {
    address SuperAdmin;
    address FactoryContract;

    struct S_instanceInfo{
        address orgAdmin;
        MainDriver mainDriverContract;
        bool isAllowed;
    }
    
    mapping (uint256 => S_instanceInfo ) public m_contractInstanceInfo; 
    mapping (address => uint256) public m_orgAdminInstanceId;
    //constructor
    constructor() {
        SuperAdmin = msg.sender;
    }
    //checks
    function checkIfInstanceIdExists(uint256 _instanceId) private view {
        require ( m_contractInstanceInfo[_instanceId].orgAdmin != address(0), "Instance not found");
    }
    function checkInstanceAccessIsAllowed(uint256 _instanceId) private view{
        require ( m_contractInstanceInfo[_instanceId].isAllowed == true, "Access denied");
    }

    //modifiers
    modifier isSuperAdmin() {
        require(msg.sender == SuperAdmin, "unauthorized call");
        _;
    }
    
    modifier isFactoryContract{
        require (msg.sender == FactoryContract, "sender is not factory contract");
        _;
    }

    /* ==================================SuperAdmin========================================================*/
    function addNewInstanceToRecord( uint256 _instanceId, address _orgAdmin, MainDriver _contractAddress) external isFactoryContract {
        require( m_orgAdminInstanceId[_orgAdmin] == 0, "instance exists");
        m_orgAdminInstanceId[_orgAdmin] = _instanceId;
        m_contractInstanceInfo[_instanceId] = S_instanceInfo(_orgAdmin, MainDriver(_contractAddress), true);
    } 
    
    function banAccessforOrg ( address _orgAdmin) external isSuperAdmin{
        checkIfInstanceIdExists(m_orgAdminInstanceId[_orgAdmin]);
        m_contractInstanceInfo[m_orgAdminInstanceId[_orgAdmin]].isAllowed = false;    
    }

    function allowAccessforOrg ( address _orgAdmin ) external isSuperAdmin {
         checkIfInstanceIdExists(m_orgAdminInstanceId[_orgAdmin]);
        m_contractInstanceInfo[m_orgAdminInstanceId[_orgAdmin]].isAllowed = true;    
    }
    
    function setFactoryContractAddress(address _fcatorycontract) external isSuperAdmin{
        FactoryContract = _fcatorycontract;
    } 

    /* ==================================================================================================== */    
    
    function addMultipleReferralCodes (uint256 _instanceId, MainDriver.S_ReferralCode[] memory _referralCodes ) external isSuperAdmin{
        require( _referralCodes.length < 255, "exceeds array limit");
        m_contractInstanceInfo[_instanceId].mainDriverContract.addMultipleReferralCodes(_referralCodes);
    }

    function redeemReferralCode(uint256 _instanceId, string calldata _referralCodeName, address _referralCodeUser ) external isSuperAdmin{
       m_contractInstanceInfo[_instanceId].mainDriverContract.redeemReferralCode(_referralCodeName, _referralCodeUser);
    } 

    function addMultiplePromoCodes(uint256 _instanceId, MainDriver.S_PromoCode[] calldata _promoCodes ) external isSuperAdmin {
        m_contractInstanceInfo[_instanceId].mainDriverContract.addMultiplePromoCodes(_promoCodes);
    }

    function redeemPromoCode(uint256 _instanceId, string calldata _promoCodeName, address _promoCodeUser ) external isSuperAdmin{
        m_contractInstanceInfo[_instanceId].mainDriverContract.redeemPromoCode(_promoCodeName, _promoCodeUser);
    }

    //========================================================== getter functions ====================================================
    function getReferralCodeDetails(uint256 _instanceId, string calldata _name) external view returns(MainDriver.S_ReferralCode memory){
        return  m_contractInstanceInfo[_instanceId].mainDriverContract.getReferralCodeDetails(_name);
    }

    function getPromoCodeDetails(uint256 _instanceId, string calldata _name) external view returns(MainDriver.S_PromoCode memory){
        return  m_contractInstanceInfo[_instanceId].mainDriverContract.getPromoCodeDetails(_name);
    }
    
    function getUserDetails(uint256 _instanceId, address _user) external view returns(MainDriver.s_userDetails memory){
        return  m_contractInstanceInfo[_instanceId].mainDriverContract.getUserDetails(_user);
    }

    function getUserHistory(uint256 _instanceId, address _user) external view returns(MainDriver.s_usedCodes memory){
        return  m_contractInstanceInfo[_instanceId].mainDriverContract.getUserHistory(_user);
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardTokenPool {
    address public SuperAdmin;
    address public TokenAddress;
    address public MainDriver;

    // modifier onlySuperAdmins() {
    //     require(msg.sender == SuperAdmin || msg.sender == MainDriver , "unauthorized call");
    //     _;
    // }

    constructor( address _tokenAddress /*,address _admin, address _mainDriver */  ) {
        // SuperAdmin = _admin;
        SuperAdmin = msg.sender;
        TokenAddress = _tokenAddress;
        // MainDriver = _mainDriver;

    }

    function changeTokenAddress(address _tokenAddress) external  {
        TokenAddress = _tokenAddress;
    }

    function sendTokens(address _to, uint256 amount) external  {
        IERC20(TokenAddress).transfer(_to, amount);  
    }

    function getPoolBalance() public view  returns(uint256) {
        return IERC20(TokenAddress).balanceOf(address(this));
    }

}