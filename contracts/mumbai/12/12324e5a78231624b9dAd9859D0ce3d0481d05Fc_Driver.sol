//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ReferralCodeSystem.sol";

contract Driver is
    ReferralCodeSystem //company
{
    constructor(
        address _orgAdmin,
        string memory _orgName,
        address _adminContract
    ) OrgManager(_orgAdmin, _orgName, _adminContract) {}

    function simpleCheckout(uint256 _amount) public payable isUser(msg.sender) {
        require(_amount == msg.value, "incorrect amount provided");
        payable(SuperAdmin).transfer(baseFee);
        balance += msg.value - baseFee;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "./RewardSystemAdmin.sol";
contract OrgManager {

    uint256 balance; //money sent by users
    uint256 baseFee = 0; //fee charged by utility
    string public OrgName;
    address OrgAdmin;
    address SuperAdmin; // Utility Admin
    bool ContractIsPaused;
    uint256[] public UsedUpRefCodes;
    uint256 public userId = 0;
    uint256 public refCodeIdForUsers;
    enum e_refCodeType {
        discount,
        fixedDiscount,
        free,
        tokens,
        NFTs,
        promoCodes,
        customToken
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
    struct s_userDetails {
        string name;
        uint256 id; //userId
        uint256 personalRefCodeId; //the RCID assigned when the user is assigned rc (to give others)
        uint16 numOfReferrals; //
        bool isActive;
        address[] referredUsers;
    }
    struct s_usedCodes {
        //History?
        uint256[] refCodeIds;
        uint256[] promoCodeIds;
        uint256[] personalRefCodeIds;
    }
    struct S_ReferralCode {
        string name;
        address owner;
        e_refCodeType rewardType;
        uint8 discount;
        uint64 limitOfUse; //how many referrals are allowed.
        uint256 maxRedeemLimit; //max amount in wei on which the discount is to be availed/max tokens to be given/
    }

    function getUsersRefCodeHistory(address _user)
        external
        view
        isOrgAdmin
        returns (uint256[] memory)
    {
        return m_usedCodesPerUser[_user].refCodeIds;
    }

    constructor(
        address _admin,
        string memory _name,
        address _adminContract
    ) {
        //org OrgAdmin should be passsed at creation
        OrgAdmin = _admin;
        OrgName = _name;
        SuperAdmin = _adminContract;
    }

    function allowOrgAdminOnly() internal view {
        //helper
        require(
            ContractIsPaused == false && msg.sender == OrgAdmin,
            "unauthorized call"
        );
    }

    function allowUserOnly(address _user) internal view {
        //helper
        require(m_userInfo[_user].id != 0, "unregistered users");
    }

    function allowActiveUserOnly(address _user) internal view {
        require(m_userInfo[_user].isActive != false, "unregistered users");
    }

    function allowSuperAdminOnly() internal view {
        require(msg.sender == SuperAdmin, "unauthorized call");
    }

    modifier isSuperAdmin() {
        allowSuperAdminOnly();
        _;
    }

    modifier isOrgAdmin() {
        allowOrgAdminOnly();
        _;
    }

    modifier isUser(address _user) {
        allowUserOnly(_user);
        _;
    }

    modifier isActiveUser(address _user) {
        allowActiveUserOnly(_user);
        _;
    }

    function activateUser(address _user) external isUser(_user) isOrgAdmin {
        m_userInfo[_user].isActive = true;
    }

    function deActivateUser(address _user) external isUser(_user) isOrgAdmin {
        m_userInfo[_user].isActive = false;
    }

    function registerUser(address _newUser, string calldata _name)
        external
        isOrgAdmin
    {
        //SECURITY: anyone can register.      //change to OrgAdmin only
        require(m_userInfo[_newUser].id == 0, "Already registered.");
        m_userInfo[_newUser].name = _name;
        m_userInfo[_newUser].id = ++userId;
    }

    function updateInitials(string calldata _name) external isUser(msg.sender) {
        m_userInfo[msg.sender].name = _name;
    }

    function updateBaseFee(uint256 _fee) external isSuperAdmin {
        baseFee = _fee;
    }

    function pauseAccess() external isSuperAdmin {
        ContractIsPaused = true;
    }

    function unPauseAccess() external isSuperAdmin {
        ContractIsPaused = false;
    }

    function withdrawFunds() external isOrgAdmin {
        //OrgAdmin(s)
        payable(OrgAdmin).transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./Manager.sol";

abstract contract ReferralCodeSystem is OrgManager {
    event refCodeDeleted(string indexed refCodeName);
    event ReferralCodeAdded(
        string indexed name,
        address indexed owner,
        uint256 indexed referralCodeId
    );
    event ReferralCodesRejected(string[] rejectedRefCodes);
    event refCodeRedeemed(
        string indexed refCodeName,
        address redeemedBy,
        uint256 txAmount
    );

    function addReferralCode(
        //admin
        string calldata _name,
        e_refCodeType _rewardType,
        address _userAddress,
        uint8 _discount,
        uint64 _limitOfUse,
        uint256 _maxRedeemLimit
    ) private {
        m_userReferralCodeId[_name] = ++refCodeIdForUsers;
        m_usedCodesPerUser[_userAddress].personalRefCodeIds.push(refCodeIdForUsers);
        m_userInfo[_userAddress].personalRefCodeId = refCodeIdForUsers;
        m_referralCode[refCodeIdForUsers] = S_ReferralCode({
            name: _name,
            discount: _discount,
            owner: _userAddress,
            rewardType: _rewardType,
            limitOfUse: _limitOfUse,
            maxRedeemLimit: _maxRedeemLimit
        });
    }

    function addMultipleRefCodes(S_ReferralCode[] calldata _userReferralCodes)
        external
        isOrgAdmin
    {
        uint256 len = _userReferralCodes.length;
        if (len > 255) {
            revert("Max 255 refCodes allowed per tx.");
        }
        uint8 ptr = 0;
        string[] memory rejectedRefCodes = new string[](255); //check limit
        for (uint256 i; i < len; ++i) {
            S_ReferralCode calldata refCode = _userReferralCodes[i];
            if (
                m_userReferralCodeId[refCode.name] == 0 &&
                m_userInfo[refCode.owner].id != 0
            ) {
                addReferralCode(
                    refCode.name,
                    refCode.rewardType,
                    refCode.owner,
                    refCode.discount,
                    refCode.limitOfUse,
                    refCode.maxRedeemLimit
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

    function deleteReferralCode(string calldata _refCodeName)
        external
        isOrgAdmin
    {
        //do we need it?
        delete m_referralCode[m_userReferralCodeId[_refCodeName]];
        emit refCodeDeleted(_refCodeName);
    }

    function checkRefCodeExists(string memory _refCodeName) private view {
        require(m_userReferralCodeId[_refCodeName] != 0, "RC not found");
    }

    function checkRefCodeIsValid(string memory _refCodeName) private view {
        checkRefCodeExists(_refCodeName);
        require(
            m_referralCode[m_userReferralCodeId[_refCodeName]].limitOfUse != 0,
            "RC out of order"
        );
    }

    function redeemReferralCode(uint256 _txAmount, string calldata _refCodeName)
        external
        payable
        isUser(msg.sender)
    {
        checkRefCodeIsValid(_refCodeName);
        uint256 refCodeId = m_userReferralCodeId[_refCodeName];
        if (m_redeemedRefCodes[msg.sender][refCodeId] != 0) {
            revert("ReferralCode already used");
        }
        uint256 totalAmount = calculateFeeForRC(_txAmount, _refCodeName);
        if (msg.value != totalAmount) {
            revert("incorrect funds");
        }
        --m_referralCode[refCodeId].limitOfUse;
        ++m_userInfo[m_referralCode[refCodeId].owner].numOfReferrals;
        m_userInfo[m_referralCode[refCodeId].owner].referredUsers.push(
            msg.sender
        );
        m_redeemedRefCodes[msg.sender][refCodeId] = 1; 
        m_usedCodesPerUser[msg.sender].refCodeIds.push(refCodeId);
        if (totalAmount != 0) {
            (bool s, ) = SuperAdmin.call{value: baseFee}("");
            if (s == false) {
                revert("value transfer failed");
            }
            balance += totalAmount - baseFee;
        }
        emit refCodeRedeemed(_refCodeName, msg.sender, _txAmount);
    }

    function calculateFeeForRC(uint256 _txAmount, string memory _refCodeName)
        public
        view
        returns (uint256)
    {
        uint256 refCodeId = m_userReferralCodeId[_refCodeName];
        checkRefCodeIsValid(_refCodeName);
        S_ReferralCode memory refCode = m_referralCode[refCodeId];
        uint256 totalAmount;
        if (refCode.rewardType == e_refCodeType.discount) {
            uint256 discount = (_txAmount * refCode.discount) / 100;
            discount > refCode.maxRedeemLimit
                ? totalAmount = refCode.maxRedeemLimit
                : totalAmount = _txAmount - discount;
        } else if (refCode.rewardType == e_refCodeType.fixedDiscount) {
            totalAmount = refCode.maxRedeemLimit;
        } else if (refCode.rewardType == e_refCodeType.free) {
            if (_txAmount <= refCode.maxRedeemLimit) return 0;
        } else {
            revert("code inapplicable");
        }
        return totalAmount + baseFee;
    }
}