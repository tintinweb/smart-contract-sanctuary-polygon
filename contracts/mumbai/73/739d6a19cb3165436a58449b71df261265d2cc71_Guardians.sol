// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev {Guardians}. Guardians management contract.
 * Allows to set guardians parameters, fees, info
 * by guardians themselves and the protocol.
 */
contract Guardians is Initializable, OwnableUpgradeable {
    /// Guardian class struct.
    struct GuardianClass {
        /// Maximum insurance on-chain coverage.
        uint256 maximumCoverage;
        /// Minting fee.
        uint256 mintingFee;
        /// Redemption fee.
        uint256 redemptionFee;
        /// Storage fee rate per second.
        uint256 storageFeeRate;
        /// Last storage fee rate increase update timestamp.
        uint256 lastStorageFeeRateIncrease;
        /// Is guardian class active.
        bool isActive;
        /// Class name
        string name;
        /// Description including location, information, attributes, etc.
        string description;
        /// Guardian URI for metadata.
        string uri;
    }

    /// Percentage factor with 0.01% precision.
    uint256 public constant PERCENTAGE_FACTOR = 10000;

    uint256 public minimumRequestFee;
    uint256 public storageFeeSetWindow;
    /// Maximum storage fee rate percentage increase during single fee set, 0.01% precision.
    uint256 public maximumStorageFeeSet;
    /// Guardians info.
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isActive;
    mapping(address => string) public logos;
    mapping(address => string) public names;
    mapping(address => bytes32) public addressHashes;
    mapping(address => string) public redirects;
    mapping(address => bool) public isPrivate;
    mapping(address => string) public policies;
    mapping(address => uint256) public requestFees;
    mapping(address => uint256) public redemptionFees;
    mapping(address => mapping(address => bool)) public guardianWhitelist;
    mapping(address => address) public delegated;
    /// Guardian classes of a particular guardian.
    mapping(address => GuardianClass[]) public guardiansClasses;

    /// Events
    event GuardianRegistered(
        address indexed guardian,
        string name,
        string logo,
        string policy,
        bool privacy,
        string redirect,
        bytes32 addressHash,
        uint256 requestFee,
        uint256 redemptionFee
    );
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event GuardianClassAdded(
        address indexed guardian,
        uint256 classID,
        string name
    );

    modifier onlyWhitelisted(address guardian) {
        require(isWhitelisted[guardian], "Guardians: not whitelisted");
        _;
    }

    /**
     * @dev Init Guardians.
     */
    function initialize(
        uint256 minimumRequestFee_,
        uint256 storageFeeSetWindow_,
        uint256 maximumStorageFeeSet_
    ) external initializer {
        __Ownable_init();
        minimumRequestFee = minimumRequestFee_;
        storageFeeSetWindow = storageFeeSetWindow_;
        maximumStorageFeeSet = maximumStorageFeeSet_;
    }

    /**
     * @dev Sets minimum mining fee.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setMinimumRequestFee(uint256 minimumRequestFee_)
        external
        onlyOwner
    {
        minimumRequestFee = minimumRequestFee_;
    }

    /**
     * @dev Sets maximum storage fee rate set percentage.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setMaximumStorageFeeSet(uint256 maximumStorageFeeSet_)
        external
        onlyOwner
    {
        maximumStorageFeeSet = maximumStorageFeeSet_;
    }

    /**
     * @dev Sets minimum storage fee.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setStorageFeeSetWindow(uint256 storageFeeSetWindow_)
        external
        onlyOwner
    {
        storageFeeSetWindow = storageFeeSetWindow_;
    }

    /**
     * @dev Sets activity mode for the guardian. Either active or not.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setActivity(bool activity) external onlyWhitelisted(_msgSender()) {
        isActive[_msgSender()] = activity;
    }

    /**
     * @dev Sets privacy mode for the guardian. Either public `false` or private `true`.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setPrivacy(bool privacy) external onlyWhitelisted(_msgSender()) {
        isPrivate[_msgSender()] = privacy;
    }

    /**
     * @dev Sets logo for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setLogo(string calldata logo)
        external
        onlyWhitelisted(_msgSender())
    {
        logos[_msgSender()] = logo;
    }

    /**
     * @dev Sets name for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setName(string calldata name)
        external
        onlyWhitelisted(_msgSender())
    {
        names[_msgSender()] = name;
    }

    /**
     * @dev Sets physical address hash for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setPhysicalAddressHash(bytes32 physicalAddressHash)
        external
        onlyWhitelisted(_msgSender())
    {
        addressHashes[_msgSender()] = physicalAddressHash;
    }

    /**
     * @dev Sets policy for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setPolicy(string calldata policy)
        external
        onlyWhitelisted(_msgSender())
    {
        policies[_msgSender()] = policy;
    }

    /**
     * @dev Sets redirects for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setRedirect(string calldata redirect)
        external
        onlyWhitelisted(_msgSender())
    {
        redirects[_msgSender()] = redirect;
    }

    /**
     * @dev Sets minting fee for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setRequestFee(uint256 requestFee)
        external
        onlyWhitelisted(_msgSender())
    {
        require(
            requestFee >= minimumRequestFee,
            "Guardians: lower than mininum"
        );
        requestFees[_msgSender()] = requestFee;
    }

    /**
     * @dev Sets redemption fee for the guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setRedemptionFee(uint256 redemptionFee)
        external
        onlyWhitelisted(_msgSender())
    {
        redemptionFees[_msgSender()] = redemptionFee;
    }

    /**
     * @dev Adds users addressHashes to guardian whitelist.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function whitelistUsers(address[] calldata users)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[_msgSender()][users[i]] = true;
        }
    }

    /**
     * @dev Removes users addressHashes from guardian whitelist.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function unwhitelistUsers(address[] calldata users)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[_msgSender()][users[i]] = false;
        }
    }

    /**
     * @dev Adds guardian to the whitelist.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function removeGuardian(address guardian) external virtual onlyOwner {
        isWhitelisted[guardian] = false;
        emit GuardianRemoved(guardian);
    }

    /**
     * @dev Removes guardian from the whitelist.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function addGuardian(address guardian) external virtual onlyOwner {
        isWhitelisted[guardian] = true;
        emit GuardianAdded(guardian);
    }

    /**
     * @dev Sets name for the a guardian.
     *
     * Requirements:
     *
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setNameForGuardian(address guardian, string calldata name)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        names[guardian] = name;
    }

    /**
     * @dev Sets logo for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setLogoForGuardian(address guardian, string calldata logo)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        logos[guardian] = logo;
    }

    /**
     * @dev Sets policy for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setPolicyForGuardian(address guardian, string calldata policy)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        policies[guardian] = policy;
    }

    /**
     * @dev Sets redirects for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setRedirectForGuardian(address guardian, string calldata redirect)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        redirects[guardian] = redirect;
    }

    /**
     * @dev Sets physical address hash for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setPhysicalAddressHashForGuardian(
        address guardian,
        bytes32 physicalAddressHash
    ) external onlyOwner onlyWhitelisted(guardian) {
        addressHashes[guardian] = physicalAddressHash;
    }

    /**
     * @dev Sets minting fee for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setRequestFeeForGuardian(address guardian, uint256 requestFee)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        require(
            requestFee >= minimumRequestFee,
            "Guardians: lower than mininum"
        );
        requestFees[guardian] = requestFee;
    }

    /**
     * @dev Sets redemption fee for a guardian.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setRedemptionFeeForGuardian(
        address guardian,
        uint256 redemptionFee
    ) external onlyOwner onlyWhitelisted(guardian) {
        redemptionFees[guardian] = redemptionFee;
    }

    /**
     * @dev Sets privacy mode for a guardian. Either public `false` or private `true`.
     *
     * Requirements:
     * - the caller must be owner
     * - address passed must be a guardian
     */
    function setPrivacyForGuardian(address guardian, bool privacy)
        external
        onlyOwner
        onlyWhitelisted(guardian)
    {
        isPrivate[guardian] = privacy;
    }

    /**
     * @dev Adds users addressHashes to a guardian whitelist.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function whitelistUsersForGuardian(
        address guardian,
        address[] calldata users
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[guardian][users[i]] = true;
        }
    }

    /**
     * @dev Removes users addressHashes from a guardian whitelist.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function unwhitelistUsersForGuardian(
        address guardian,
        address[] calldata users
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[guardian][users[i]] = false;
        }
    }

    /**
     * @dev Delegates whole minting/redemption process `to`.
     */
    function delegate(address to)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        delegated[_msgSender()] = to;
    }

    /**
     * @dev Sets minting fee for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassMintingFee(uint256 classID, uint256 mintingFee)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        require(
            mintingFee >= minimumRequestFee,
            "Guardians: lower than mininum"
        );
        guardiansClasses[_msgSender()][classID].mintingFee = mintingFee;
    }

    /**
     * @dev Sets minting fee for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassMintingFeeForGuardian(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        require(
            mintingFee >= minimumRequestFee,
            "Guardians: lower than mininum"
        );
        guardiansClasses[guardian][classID].mintingFee = mintingFee;
    }

    /**
     * @dev Sets redemption fee for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassRedemptionFee(
        uint256 classID,
        uint256 redemptionFee
    ) external virtual onlyWhitelisted(_msgSender()) {
        guardiansClasses[_msgSender()][classID].redemptionFee = redemptionFee;
    }

    /**
     * @dev Sets redemption fee for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassRedemptionFeeForGuardian(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].redemptionFee = redemptionFee;
    }

    /**
     * @dev Sets description for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassDescription(
        uint256 classID,
        string calldata description
    ) external virtual onlyWhitelisted(_msgSender()) {
        guardiansClasses[_msgSender()][classID].description = description;
    }

    /**
     * @dev Sets description for guardian class by contract onwer.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassDescriptionForGuardian(
        address guardian,
        uint256 classID,
        string calldata description
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].description = description;
    }

    /**
     * @dev Sets storage fee rate for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassStorageFeeRate(
        uint256 classID,
        uint256 storageFeeRate
    ) external virtual onlyWhitelisted(_msgSender()) {
        _setGuardianClassStorageFeeRate(_msgSender(), classID, storageFeeRate);
    }

    /**
     * @dev Sets storage fee rate for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassStorageFeeRateForGuardian(
        address guardian,
        uint256 classID,
        uint256 storageFeeRate
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        _setGuardianClassStorageFeeRate(guardian, classID, storageFeeRate);
    }

    /**
     * @dev Sets name for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassName(uint256 classID, string calldata name)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        guardiansClasses[_msgSender()][classID].name = name;
    }

    /**
     * @dev Sets name for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassNameForGuardian(
        address guardian,
        uint256 classID,
        string calldata name
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].name = name;
    }

    /**
     * @dev Sets URI for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassURI(uint256 classID, string calldata uri)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        guardiansClasses[_msgSender()][classID].uri = uri;
    }

    /**
     * @dev Sets URI for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassURIForGuardian(
        address guardian,
        uint256 classID,
        string calldata uri
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].uri = uri;
    }

    /**
     * @dev Sets guardian class as active by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassActive(uint256 classID)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        guardiansClasses[_msgSender()][classID].isActive = true;
    }

    /**
     * @dev Sets guardian class as active by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassActiveForGuardian(
        address guardian,
        uint256 classID
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].isActive = true;
    }

    /**
     * @dev Sets guardian class as inactive by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassInactive(uint256 classID)
        external
        virtual
        onlyWhitelisted(_msgSender())
    {
        guardiansClasses[_msgSender()][classID].isActive = false;
    }

    /**
     * @dev Sets guardian class as inactive by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassInactiveForGuardian(
        address guardian,
        uint256 classID
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].isActive = false;
    }

    /**
     * @dev Sets maximum insurance coverage for guardian class by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function setGuardianClassMaximumCoverage(
        uint256 classID,
        uint256 maximumCoverage
    ) external virtual onlyWhitelisted(_msgSender()) {
        guardiansClasses[_msgSender()][classID]
            .maximumCoverage = maximumCoverage;
    }

    /**
     * @dev Sets maximum insurance coverage for guardian class by contract owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardianClassMaximumCoverageForGuardian(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    ) external virtual onlyOwner onlyWhitelisted(guardian) {
        guardiansClasses[guardian][classID].maximumCoverage = maximumCoverage;
    }

    /**
     * @dev Adds guardian class to guardian by guardian.
     *
     * Requirements:
     *
     * - the caller must be a whitelisted guardian.
     */
    function addGuardianClass(
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 storageFeeRate,
        string calldata name,
        string calldata description
    ) external virtual onlyWhitelisted(_msgSender()) returns (uint256 classID) {
        classID = _addGuardianClass(
            _msgSender(),
            maximumCoverage,
            mintingFee,
            redemptionFee,
            storageFeeRate,
            name,
            description
        );
    }

    /**
     * @dev Adds guardian class to guardian by owner.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function addGuardianClassForGuardian(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 storageFeeRate,
        string calldata name,
        string calldata description
    )
        external
        virtual
        onlyOwner
        onlyWhitelisted(guardian)
        returns (uint256 classID)
    {
        classID = _addGuardianClass(
            guardian,
            maximumCoverage,
            mintingFee,
            redemptionFee,
            storageFeeRate,
            name,
            description
        );
    }

    /**
     * @dev Returns true if the guardian is active and whitelisted.
     */
    function isAvailable(address guardian) external view returns (bool) {
        return isWhitelisted[guardian] && isActive[guardian];
    }

    /**
     * @dev Returns guardian class maximum coverage.
     */
    function getMaximumCoverage(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].maximumCoverage;
    }

    /**
     * @dev Returns guardian class name.
     */
    function getName(address guardian, uint256 classID)
        external
        view
        virtual
        returns (string memory)
    {
        return guardiansClasses[guardian][classID].name;
    }

    /**
     * @dev Returns guardian class URI.
     */
    function getURI(address guardian, uint256 classID)
        external
        view
        virtual
        returns (string memory)
    {
        return guardiansClasses[guardian][classID].uri;
    }

    /**
     * @dev Returns guardian class redemption fee.
     */
    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].redemptionFee;
    }

    /**
     * @dev Returns guardian class minting fee.
     */
    function getMintingFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].mintingFee;
    }

    /**
     * @dev Returns guardian class description.
     */
    function getDescription(address guardian, uint256 classID)
        external
        view
        virtual
        returns (string memory)
    {
        return guardiansClasses[guardian][classID].description;
    }

    /**
     * @dev Returns guardian class storage fee rate.
     */
    function getStorageFeeRate(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].storageFeeRate;
    }

    /**
     * @dev Returns guardian class last storage fee rate update timestamp.
     */
    function getLastStorageFeeRateIncrease(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].lastStorageFeeRateIncrease;
    }

    /**
     * @dev Returns guardian class activity true/false.
     */
    function isClassActive(address guardian, uint256 classID)
        external
        view
        virtual
        returns (bool)
    {
        return guardiansClasses[guardian][classID].isActive;
    }

    /**
     * @dev Returns guardian classes number.
     */
    function guardianClassesCount(address guardian)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian].length;
    }

    /**
     * @dev Registers guardian.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function registerGuardian(
        address guardian,
        string memory name,
        string memory logo,
        string memory policy,
        string memory redirect,
        bytes32 physicalAddressHash,
        bool privacy,
        uint256 requestFee,
        uint256 redemptionFee
    ) public virtual onlyOwner {
        isWhitelisted[guardian] = true;
        isActive[guardian] = true;
        names[guardian] = name;
        logos[guardian] = logo;
        policies[guardian] = policy;
        isPrivate[guardian] = privacy;
        redirects[guardian] = redirect;
        redemptionFees[guardian] = redemptionFee;
        requestFees[guardian] = requestFee;
        addressHashes[guardian] = physicalAddressHash;
        emit GuardianRegistered(
            guardian,
            name,
            logo,
            policy,
            privacy,
            redirect,
            physicalAddressHash,
            requestFee,
            redemptionFee
        );
    }

    /**
     * @dev Internal call, sets storage fee rate for guardian class by guardian.
     */
    function _setGuardianClassStorageFeeRate(
        address guardian,
        uint256 classID,
        uint256 storageFeeRate
    ) internal virtual {
        require(storageFeeRate > 0, "Guardians: storage fee rate is zero");
        if (
            storageFeeRate >= guardiansClasses[guardian][classID].storageFeeRate
        ) {
            require(
                block.timestamp >=
                    guardiansClasses[guardian][classID]
                        .lastStorageFeeRateIncrease +
                        storageFeeSetWindow,
                "Guardians: set storage fee window hasn't passed"
            );
            require(
                storageFeeRate <=
                    (guardiansClasses[guardian][classID].storageFeeRate *
                        maximumStorageFeeSet) /
                        PERCENTAGE_FACTOR,
                "Guardians: cannot exceed increase limit"
            );
            guardiansClasses[guardian][classID]
                .lastStorageFeeRateIncrease = block.timestamp;
        }
        guardiansClasses[guardian][classID].storageFeeRate = storageFeeRate;
    }

    /**
     * @dev Internal call, adds guardian class.
     */
    function _addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 storageFeeRate,
        string calldata name,
        string calldata description
    ) internal virtual returns (uint256 classID) {
        require(storageFeeRate > 0, "Guardians: storage fee rate is zero");
        classID = guardiansClasses[guardian].length;
        guardiansClasses[guardian].push(
            GuardianClass(
                maximumCoverage,
                mintingFee,
                redemptionFee,
                storageFeeRate,
                block.timestamp,
                true,
                name,
                description,
                ""
            )
        );
        emit GuardianClassAdded(guardian, classID, name);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}