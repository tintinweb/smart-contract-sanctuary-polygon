// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract variables {
    address public constant platformTokenETH =
        0xF063fE1aB7a291c5d06a86e14730b00BF24cB589; // Sale token address valid for mainnet ETH
    address public constant platformTokenBSC =
        0x04F73A09e2eb410205BE256054794fB452f0D245; // Sale token address valid for mainnet BSC
    address public team_acc = 0xC14fb72518E67B008f1BD8E195861472f8128090; //valid for mainnet
    uint256 public minPlatTokenReq = 1000000000000000000000; //1000 sale tokens
    address public dead = 0x000000000000000000000000000000000000dEaD;
    bool public burn = false;
    bool public feesEnabled = false;
    uint256 public verifyFees = 1000000000000000000;
}

contract AuditKYCVerify is variables, Ownable {
    mapping(address => bool) public KYC;
    mapping(address => bool) public KYCAdded;
    mapping(address => address) public KYCedBy;
    mapping(address => string) public KYCedByName;
    mapping(address => bool) public KYCVerfied;
    mapping(address => string) public KYCComment;
    mapping(address => string) public KYCComment1;
    mapping(address => string) public KYCComment2;
    mapping(address => string) public KYCScore;
    mapping(address => string) public KYCName;
    mapping(address => bool) public verifiedKYCAlready;
    mapping(address => uint256) public KYCNumbers;
    mapping(address => mapping(uint256 => address)) public KYCTotalList;
    mapping(uint256 => address) public AllKYCWallets;
    mapping(uint256 => string) public dynamicBadge;
    mapping(address => bool) public badgeAccess;
    mapping(address => string) public badge;
    uint256 public KYCsverifiedNumber;
    uint256 public dynamicBadgeNumber;

    // DYNAMIC BADGE CODE START

    function addDynamicBadgeToken(address _token, uint256 _badgeNum) public {
        require(badgeAccess[msg.sender], "no badge add access");
        badge[_token] = dynamicBadge[_badgeNum];
    }

    function addDynamicBadgeKYC(address _wallet, uint256 _badgeNum) public {
        require(badgeAccess[msg.sender], "no badge add access");
        badge[_wallet] = dynamicBadge[_badgeNum];
    }

    // DYNAMIC BADGE CODE END

    function verifyKYC(
        address _wallet,
        string memory _score,
        string memory _comment,
        string memory _comment1,
        string memory _comment2
    ) public payable {
        require(KYC[msg.sender], "NO KYC Authorization");
        require(!verifiedKYCAlready[_wallet], "already verified!");

        if (feesEnabled) {
            if (burn) {
                require(
                    IERC20(platformTokenBSC).transferFrom(
                        msg.sender,
                        dead,
                        minPlatTokenReq
                    ),
                    "sale token transfer fail"
                );
            } else {
                require(
                    msg.value >= verifyFees,
                    "msg.value must be >= drop fees"
                );
                payable(team_acc).transfer(verifyFees);
            }
        }

        KYCVerfied[_wallet] = true;
        KYCComment[_wallet] = _comment;
        KYCComment1[_wallet] = _comment1;
        KYCComment2[_wallet] = _comment2;
        KYCScore[_wallet] = _score;
        KYCedBy[_wallet] = msg.sender;
        KYCedByName[_wallet] = KYCName[msg.sender];
        verifiedKYCAlready[_wallet] = true;
        AllKYCWallets[KYCsverifiedNumber] = _wallet;
        KYCsverifiedNumber++;

        KYCTotalList[msg.sender][KYCNumbers[msg.sender]] = _wallet;
        KYCNumbers[msg.sender]++;
    }

    function enableKYCbyProvider(address _walletAddress) public {
        require(KYC[msg.sender], "NOT KYC provider");
        require(
            KYCedBy[_walletAddress] == msg.sender,
            "Incorrect KYC provider"
        );
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCVerfied[_walletAddress] = true;
    }

    function disableKYCbyProvider(address _walletAddress) public {
        require(KYC[msg.sender], "NOT KYC provider");
        require(
            KYCedBy[_walletAddress] == msg.sender,
            "Incorrect KYC provider"
        );
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCVerfied[_walletAddress] = false;
    }

    function updateCommentKYC(address _walletAddress, string memory _newComment)
        public
    {
        require(KYC[msg.sender], "NOT KYC provider");
        require(
            KYCedBy[_walletAddress] == msg.sender,
            "Incorrect KYC provider"
        );
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCComment[_walletAddress] = _newComment;
    }

    function updateComment1KYC(
        address _walletAddress,
        string memory _newComment1
    ) public {
        require(KYC[msg.sender], "NOT KYC");
        require(KYCedBy[_walletAddress] == msg.sender, "Incorrect KYC");
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCComment1[_walletAddress] = _newComment1;
    }

    function updateComment2KYC(
        address _walletAddress,
        string memory _newComment2
    ) public {
        require(KYC[msg.sender], "NOT KYC");
        require(KYCedBy[_walletAddress] == msg.sender, "Incorrect KYC");
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCComment2[_walletAddress] = _newComment2;
    }

    function updateScoreKYC(address _walletAddress, string memory _newScore)
        public
    {
        require(KYC[msg.sender], "NOT KYC");
        require(KYCedBy[_walletAddress] == msg.sender, "Incorrect KYC");
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCScore[_walletAddress] = _newScore;
    }

    function addToKYC(address _KYCAddress, string memory _name)
        public
        onlyOwner
    {
        require(!KYC[_KYCAddress], "KYC already exist");
        KYC[_KYCAddress] = true;
        KYCAdded[_KYCAddress] = true;
        KYCName[_KYCAddress] = _name;
    }

    function addToKYCInternal(address _KYCAddress, string memory _name)
        internal
    {
        require(!KYC[_KYCAddress], "KYC already exist");
        KYC[_KYCAddress] = true;
        KYCAdded[_KYCAddress] = true;
        KYCName[_KYCAddress] = _name;
    }

    function updateKYCName(address _KYCAddress, string memory _newName)
        public
        onlyOwner
    {
        require(KYCAdded[_KYCAddress], "KYC doesn't exist");
        KYCName[_KYCAddress] = _newName;
    }

    function enableKYC(address _KYCAddress) public onlyOwner {
        require(KYCAdded[_KYCAddress], "KYC doesnot exist!");
        require(!KYC[_KYCAddress], "KYC already enabled");
        KYC[_KYCAddress] = true;
    }

    function disableKYC(address _KYCAddress) public onlyOwner {
        require(KYCAdded[_KYCAddress], "KYC doesnot exist!");
        require(KYC[_KYCAddress], "KYC already disabled");
        KYC[_KYCAddress] = false;
    }

    function disableKYCInternal(address _KYCAddress) internal {
        require(KYCAdded[_KYCAddress], "KYC doesnot exist!");
        require(KYC[_KYCAddress], "KYC already disabled");
        KYC[_KYCAddress] = false;
    }

    mapping(address => bool) public Auditors;
    mapping(address => bool) public AuditorsAdded;
    mapping(address => address) public auditedBy;
    mapping(address => string) public auditedByName;
    mapping(address => bool) public AuditVerfied;
    mapping(address => string) public auditorComment;
    mapping(address => string) public auditorComment1;
    mapping(address => string) public auditorComment2;
    mapping(address => string) public auditorScore;
    mapping(address => string) public AuditorName;
    mapping(address => bool) public verifiedAuditAlready;
    mapping(address => uint256) public AuditorNumbers;
    mapping(address => mapping(uint256 => address)) public AuditorTotalList;
    mapping(uint256 => address) public AllAuditTokens;
    uint256 public auditsverifiedNumber;

    function verifyAudit(
        address _token,
        string memory _score,
        string memory _comment,
        string memory _comment1,
        string memory _comment2
    ) public payable {
        require(Auditors[msg.sender], "NOT auditor");
        require(!verifiedAuditAlready[_token], "already audit verified!");

        if (feesEnabled) {
            if (burn) {
                require(
                    IERC20(platformTokenBSC).transferFrom(
                        msg.sender,
                        dead,
                        minPlatTokenReq
                    ),
                    "sale token transfer fail"
                );
            } else {
                require(
                    msg.value >= verifyFees,
                    "msg.value must be >= drop fees"
                );
                payable(team_acc).transfer(verifyFees);
            }
        }

        AuditVerfied[_token] = true;
        auditorComment[_token] = _comment;
        auditorComment1[_token] = _comment1;
        auditorComment2[_token] = _comment2;
        auditorScore[_token] = _score;
        auditedBy[_token] = msg.sender;
        auditedByName[_token] = AuditorName[msg.sender];
        verifiedAuditAlready[_token] = true;
        AllAuditTokens[auditsverifiedNumber] = _token;
        auditsverifiedNumber++;

        AuditorTotalList[msg.sender][AuditorNumbers[msg.sender]] = _token;
        AuditorNumbers[msg.sender]++;
    }

    function enableAuditbyProvider(address _tokenAddress) public {
        require(Auditors[msg.sender], "NOT Audit provider");
        require(
            auditedBy[_tokenAddress] == msg.sender,
            "Incorrect Audit provider"
        );
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not Audit verified yet"
        );
        AuditVerfied[_tokenAddress] = true;
    }

    function disableAuditbyProvider(address _tokenAddress) public {
        require(Auditors[msg.sender], "NOT Audit provider");
        require(
            auditedBy[_tokenAddress] == msg.sender,
            "Incorrect Audit provider"
        );
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not Audit verified yet"
        );
        AuditVerfied[_tokenAddress] = false;
    }

    function updateCommentAudit(
        address _tokenAddress,
        string memory _newComment
    ) public {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        auditorComment[_tokenAddress] = _newComment;
    }

    function updateComment1Audit(
        address _tokenAddress,
        string memory _newComment1
    ) public {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        auditorComment1[_tokenAddress] = _newComment1;
    }

    function updateComment2Audit(
        address _tokenAddress,
        string memory _newComment2
    ) public {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        auditorComment2[_tokenAddress] = _newComment2;
    }

    function updateScoreAudit(address _tokenAddress, string memory _newScore)
        public
    {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        auditorScore[_tokenAddress] = _newScore;
    }

    function addToAuditors(address _auditorAddress, string memory _name)
        public
        onlyOwner
    {
        require(!Auditors[_auditorAddress], "auditor already exist");
        Auditors[_auditorAddress] = true;
        AuditorsAdded[_auditorAddress] = true;
        AuditorName[_auditorAddress] = _name;
    }

    function addToAuditorsInternal(address _auditorAddress, string memory _name)
        internal
    {
        require(!Auditors[_auditorAddress], "auditor already exist");
        Auditors[_auditorAddress] = true;
        AuditorsAdded[_auditorAddress] = true;
        AuditorName[_auditorAddress] = _name;
    }

    function changeAuditorName(address _auditorAddress, string memory _newName)
        public
        onlyOwner
    {
        require(AuditorsAdded[_auditorAddress], "auditor doesn't exist");
        AuditorName[_auditorAddress] = _newName;
    }

    function enableAuditor(address _auditorAddress) public onlyOwner {
        require(AuditorsAdded[_auditorAddress], "auditor doesnot exist!");
        require(!Auditors[_auditorAddress], "Auditor already enabled");
        Auditors[_auditorAddress] = true;
    }

    function disableAuditor(address _auditorAddress) public onlyOwner {
        require(AuditorsAdded[_auditorAddress], "auditor doesnot exist!");
        require(Auditors[_auditorAddress], "Auditor already disabled");
        Auditors[_auditorAddress] = false;
    }

    function disableAuditorInternal(address _auditorAddress) internal {
        require(AuditorsAdded[_auditorAddress], "auditor doesnot exist!");
        require(Auditors[_auditorAddress], "Auditor already disabled");
        Auditors[_auditorAddress] = false;
    }

    function updateAuditorName(address _auditorAddress, string memory _newName)
        public
        onlyOwner
    {
        AuditorName[_auditorAddress] = _newName;
    }

    function updateDeadAddress(address _newDeadAddress) public onlyOwner {
        dead = _newDeadAddress;
    }

    function AddToKYCInMass(
        address[] memory _KYCAddresses,
        string[] memory _KYCNames
    ) public onlyOwner {
        for (uint256 i = 0; i < _KYCAddresses.length; i++) {
            addToKYCInternal(_KYCAddresses[i], _KYCNames[i]);
        }
    }

    function RemoveFromKYCInMass(address[] memory _KYCAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _KYCAddresses.length; i++) {
            disableKYCInternal(_KYCAddresses[i]);
        }
    }

    function AddToAuditorsInMass(
        address[] memory _auditorAddresses,
        string[] memory _auditorNames
    ) public onlyOwner {
        for (uint256 i = 0; i < _auditorAddresses.length; i++) {
            addToAuditorsInternal(_auditorAddresses[i], _auditorNames[i]);
        }
    }

    function RemoveFromAuditorsInMass(address[] memory _auditorAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _auditorAddresses.length; i++) {
            disableAuditorInternal(_auditorAddresses[i]);
        }
    }

    function changeSaleRequired(uint256 _newFeeAmount) public onlyOwner {
        require(_newFeeAmount >= 0, "invalid amount");
        minPlatTokenReq = _newFeeAmount;
    }

    function changeFees(uint256 _newFeeAmount) public onlyOwner {
        require(_newFeeAmount >= 0, "invalid amount");
        verifyFees = _newFeeAmount;
    }

    function removeKYCVerifiedByProvider(address _walletAddress) public {
        require(KYC[msg.sender], "NOT KYC provider");
        require(
            KYCedBy[_walletAddress] == msg.sender,
            "Incorrect KYC provider"
        );
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCVerfied[_walletAddress] = false;
    }

    function removeAuditVerifiedByProvider(address _tokenAddress) public {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        AuditVerfied[_tokenAddress] = false;
    }

    function reinstateKYCVerifiedByProvider(address _walletAddress) public {
        require(KYC[msg.sender], "NOT KYC provider");
        require(
            KYCedBy[_walletAddress] == msg.sender,
            "Incorrect KYC provider"
        );
        require(
            verifiedKYCAlready[_walletAddress],
            "token not KYC verified yet"
        );
        KYCVerfied[_walletAddress] = true;
    }

    function reinstateAuditVerifiedByProvider(address _tokenAddress) public {
        require(Auditors[msg.sender], "NOT auditor");
        require(auditedBy[_tokenAddress] == msg.sender, "Incorrect Auditor");
        require(
            verifiedAuditAlready[_tokenAddress],
            "token not audit verified yet"
        );
        AuditVerfied[_tokenAddress] = true;
    }

    function removeKYCVerified(address _walletAddress) public onlyOwner {
        KYCVerfied[_walletAddress] = false;
    }

    function removeAuditVerified(address _tokenAddress) public onlyOwner {
        AuditVerfied[_tokenAddress] = false;
    }

    function reinstateKYCVerified(address _walletAddress) public onlyOwner {
        KYCVerfied[_walletAddress] = true;
    }

    function reinstateAuditVerified(address _tokenAddress) public onlyOwner {
        AuditVerfied[_tokenAddress] = true;
    }

    function enableFees() public onlyOwner {
        feesEnabled = true;
    }

    function disableFees() public onlyOwner {
        feesEnabled = false;
    }

    function enableBurn() public onlyOwner {
        burn = true;
    }

    function disableBurn() public onlyOwner {
        burn = false;
    }

    function addBadge(string memory _badge) public onlyOwner {
        dynamicBadge[dynamicBadgeNumber] = _badge;
        dynamicBadgeNumber++;
    }

    function removeBadge(uint256 _badgeNumToRemove) public onlyOwner {
        dynamicBadge[_badgeNumToRemove] = " ";
    }

    function updateDynamicBadge(address _tokenOrWallet, uint256 _badgeNum)
        public
        onlyOwner
    {
        require(badgeAccess[msg.sender], "no badge add access");
        badge[_tokenOrWallet] = dynamicBadge[_badgeNum];
    }

    function changeBadge(uint256 _badgeNumToChange, string memory _newBadgeName)
        public
        onlyOwner
    {
        dynamicBadge[_badgeNumToChange] = _newBadgeName;
    }

    function addBadgeAccess(address _wallet) public onlyOwner {
        require(!badgeAccess[_wallet], "already added access");
        badgeAccess[_wallet] = true;
    }

    function removeBadgeAccess(address _wallet) public onlyOwner {
        require(badgeAccess[_wallet], "not in access list");
        badgeAccess[_wallet] = false;
    }

    function getAuditKycBool(address _auditInput, address _kycInput)
        public
        view
        returns (bool[2] memory)
    {
        return ([AuditVerfied[_auditInput], KYCVerfied[_kycInput]]);
    }

    function getTotalWalletsByKYC(address _KYC)
        public
        view
        returns (address[] memory)
    {
        address[] memory KYCedTokenList = new address[](KYCNumbers[_KYC]);
        for (uint256 i = 0; i < KYCNumbers[_KYC]; i++) {
            KYCedTokenList[i] = KYCTotalList[_KYC][i];
        }

        return KYCedTokenList;
    }

    function getTotalTokensByAuditor(address _Auditor)
        public
        view
        returns (address[] memory)
    {
        address[] memory auditedTokenList = new address[](
            AuditorNumbers[_Auditor]
        );
        for (uint256 i = 0; i < AuditorNumbers[_Auditor]; i++) {
            auditedTokenList[i] = AuditorTotalList[_Auditor][i];
        }

        return auditedTokenList;
    }

    function getDataKYC(address _wallet)
        public
        view
        returns (
            bool,
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            KYCVerfied[_wallet],
            KYCedBy[_wallet],
            KYCedByName[_wallet],
            KYCComment[_wallet],
            KYCComment1[_wallet],
            KYCComment2[_wallet],
            KYCScore[_wallet]
        );
    }

    function getDataArrKYCAudit(address _wallet, address _token)
        public
        view
        returns (
            bool,
            address,
            string[5] memory,
            bool,
            address,
            string[5] memory
        )
    {
        string[5] memory KYCInfo;
        string[5] memory AuditInfo;
        KYCInfo = [
            KYCedByName[_wallet],
            KYCComment[_wallet],
            KYCComment1[_wallet],
            KYCComment2[_wallet],
            KYCScore[_wallet]
        ];
        AuditInfo = [
            auditedByName[_token],
            auditorComment[_token],
            auditorComment1[_token],
            auditorComment2[_token],
            auditorScore[_token]
        ];
        return (
            KYCVerfied[_wallet],
            KYCedBy[_wallet],
            KYCInfo,
            AuditVerfied[_token],
            auditedBy[_token],
            AuditInfo
        );
    }

    function getAllKYCWallets() public view returns (address[] memory) {
        address[] memory WalletList = new address[](KYCsverifiedNumber);
        for (uint256 i = 0; i < KYCsverifiedNumber; i++) {
            WalletList[i] = AllKYCWallets[i];
        }

        return WalletList;
    }

    function getDataAudit(address _token)
        public
        view
        returns (
            bool,
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            AuditVerfied[_token],
            auditedBy[_token],
            auditedByName[_token],
            auditorComment[_token],
            auditorComment1[_token],
            auditorComment2[_token],
            auditorScore[_token]
        );
    }

    function getAllAuditTokens() public view returns (address[] memory) {
        address[] memory TokenList = new address[](auditsverifiedNumber);
        for (uint256 i = 0; i < auditsverifiedNumber; i++) {
            TokenList[i] = AllAuditTokens[i];
        }

        return TokenList;
    }
}