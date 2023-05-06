// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./relayers/ETSRelayerV1.sol";
import "./interfaces/IETSAccessControls.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

/**
 * @title ETS Relayer Factory
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice Relayer factory contract that provides public function for creating new ETS Relayers.
 */
contract ETSRelayerFactory is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    // Public variables

    /// @dev ETS access controls contract.
    IETSAccessControls public etsAccessControls;

    /// @dev Address and interface for ETS Core.
    IETS public ets;

    /// @dev Address and interface for ETS Token
    IETSToken public etsToken;

    /// @dev Address and interface for ETS Target.
    IETSTarget public etsTarget;

    /// Public constants

    string public constant NAME = "ETS Relayer Factory";

    /// Modifiers

    /// @dev When applied to a method, only allows execution when the sender has the admin role.
    modifier onlyAdmin() {
        require(etsAccessControls.isAdmin(_msgSender()), "Caller not Administrator");
        _;
    }

    // ============ UUPS INTERFACE ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IETSAccessControls _etsAccessControls,
        IETS _ets,
        IETSToken _etsToken,
        IETSTarget _etsTarget
    ) public initializer {
        etsAccessControls = _etsAccessControls;
        ets = _ets;
        etsToken = _etsToken;
        etsTarget = _etsTarget;
    }

    // Ensure that only address with admin role can upgrade.
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    // ============ OWNER INTERFACE ============

    // ============ PUBLIC INTERFACE ============

    function addRelayerV1(string calldata _relayerName) public payable {
        // require(!isRelayerByAddress(_relayer), "Relayer exists");
        // TODO: If [relayername].ens exists, _msgSender() to be owner.
        require(!etsAccessControls.isRelayerByName(_relayerName), "Relayer name exists");
        ETSRelayerV1 relayer = new ETSRelayerV1(
            _relayerName,
            ets,
            etsToken,
            etsTarget,
            payable(_msgSender()),
            payable(_msgSender())
        );

        etsAccessControls.addRelayer(address(relayer), _relayerName);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @title IETSAccessControls
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETSAccessControls contract which allows ETS Core Dev
 * Team to administer roles and control access to various parts of the ETS Platform.
 * ETSAccessControls contract contains a mix of public and administrator only functions.
 */
interface IETSAccessControls is IAccessControlUpgradeable {
    /**
     * @dev emitted when the ETS Platform address is set.
     *
     * @param newAddress wallet address platform is being set to.
     * @param prevAddress previous platform address.
     */
    event PlatformSet(address newAddress, address prevAddress);

    /**
     * @dev emitted when a Relayer contract is added & enabled in ETS.
     *
     * Relayer contracts are not required implement all ETS Core API functions. Therefore, to ease
     * testing of ETS Core API fuinctions, ETS permits addition of ETS owned wallet addresses as Relayers.
     *
     * @param relayer Relayer contract address.
     * @param isAdmin Relayer address is ETS administrator (used for testing).
     */
    event RelayerAdded(address relayer, bool isAdmin);

    /**
     * @dev emitted when a Relayer contract is paused or unpaused.
     *
     * @param relayer Address that had pause toggled.
     */
    event RelayerPauseToggled(address relayer);

    /**
     * @notice Sets the Platform wallet address. Can only be called by address with DEFAULT_ADMIN_ROLE.
     *
     * @param _platform The new Platform address to set.
     */
    function setPlatform(address payable _platform) external;

    /**
     * @notice Adds a Relayer contract to ETS. Can only be called by address
     * with DEFAULT_ADMIN_ROLE.
     *
     * @param _relayer Address of the Relayer contract. Must conform to IETSRelayer.
     * @param _name Human readable name of the Relayer.
     */
    function addRelayer(address _relayer, string calldata _name) external;

    /**
     * @notice Pauses/Unpauses a Relayer contract. Can only be called by address
     * with DEFAULT_ADMIN_ROLE.
     *
     * @param _relayer Address of the Relayer contract.
     */
    function toggleIsRelayerPaused(address _relayer) external;

    /**
     * @notice Sets the role admin for a given role. An address with role admin can grant or
     * revoke that role for other addresses. Can only be called by address with DEFAULT_ADMIN_ROLE.
     *
     * @param _role bytes32 representation of role being administered.
     * @param _adminRole bytes32 representation of administering role.
     */
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /**
     * @notice Checks whether given address has SMART_CONTRACT role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has SMART_CONTRACT role.
     */
    function isSmartContract(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has DEFAULT_ADMIN_ROLE role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has DEFAULT_ADMIN_ROLE role.
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has RELAYER role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has RELAYER role.
     */
    function isRelayer(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address has RELAYER_ADMIN role.
     *
     * @param _addr Address being checked.
     * @return boolean True if address has RELAYER_ADMIN role.
     */
    function isRelayerAdmin(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given Relayer Name is a registered Relayer.
     *
     * @param _name Name being checked.
     * @return boolean True if _name is a Relayer.
     */
    function isRelayerByName(string calldata _name) external view returns (bool);

    /**
     * @notice Checks whether given address is a registered Relayer.
     *
     * @param _addr Address being checked.
     * @return boolean True if address is a registered Relayer.
     */
    function isRelayerByAddress(address _addr) external view returns (bool);

    /**
     * @notice Checks whether given address is a registered Relayer and not paused.
     *
     * @param _addr Address being checked.
     * @return boolean True if address is a Relayer and not paused.
     */
    function isRelayerAndNotPaused(address _addr) external view returns (bool);

    /**
     * @notice Get relayer address from it's name.
     *
     * @param _name Name of relayer.
     * @return Address of relayer.
     */
    function getRelayerAddressFromName(string calldata _name) external view returns (address);

    /**
     * @notice Get relayer name from it's address.
     *
     * @param _address Adsdress of relayer.
     * @return Name of relayer.
     */
    function getRelayerNameFromAddress(address _address) external view returns (string calldata);

    /**
     * @notice Returns wallet address for ETS Platform.
     *
     * @return ETS Platform address.
     */
    function getPlatformAddress() external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IETS.sol";
import "../interfaces/IETSToken.sol";
import "../interfaces/IETSTarget.sol";
import "./interfaces/IETSRelayerV1.sol";
import { UintArrayUtils } from "../libraries/UintArrayUtils.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ETSRelayerV1
 * @author Ethereum Tag Service <[email protected]>
 * @notice Sample implementation of IETSRelayer
 */
contract ETSRelayerV1 is IETSRelayerV1, ERC165, Ownable, Pausable {
    using UintArrayUtils for uint256[];

    /// @dev Address and interface for ETS Core.
    IETS public ets;

    /// @dev Address and interface for ETS Token
    IETSToken public etsToken;

    /// @dev Address and interface for ETS Target.
    IETSTarget public etsTarget;

    // Public constants
    string public constant NAME = "ETS Relayer V1";
    bytes4 public constant IID_IETSRelayer = type(IETSRelayer).interfaceId;

    // Public variables

    /// @notice Address that built this smart contract.
    address payable public creator;

    /// @dev Public name for Relayer instance.
    string public relayerName;

    constructor(
        string memory _relayerName,
        IETS _ets,
        IETSToken _etsToken,
        IETSTarget _etsTarget,
        address payable _creator,
        address payable _owner
    ) {
        relayerName = _relayerName;
        ets = _ets;
        etsToken = _etsToken;
        etsTarget = _etsTarget;
        creator = _creator;
        transferOwnership(_owner);
    }

    // ============ OWNER INTERFACE ============

    /// @inheritdoc IETSRelayer
    function pause() public onlyOwner {
        _pause();
        emit RelayerPauseToggledByOwner(address(this));
    }

    /// @inheritdoc IETSRelayer
    function unpause() public onlyOwner {
        _unpause();
        emit RelayerPauseToggledByOwner(address(this));
    }

    /// @inheritdoc IETSRelayer
    function changeOwner(address _newOwner) public whenPaused {
        transferOwnership(_newOwner);
        emit RelayerOwnerChanged(address(this));
    }

    // ============ PUBLIC INTERFACE ============

    /// @inheritdoc IETSRelayerV1
    function applyTags(IETS.TaggingRecordRawInput[] calldata _rawInput) public payable whenNotPaused {
        uint256 taggingFee = ets.taggingFee();
        for (uint256 i; i < _rawInput.length; ++i) {
            _applyTags(_rawInput[i], payable(msg.sender), taggingFee);
        }
    }

    /// @inheritdoc IETSRelayerV1
    function replaceTags(IETS.TaggingRecordRawInput[] calldata _rawInput) public payable whenNotPaused {
        uint256 taggingFee = ets.taggingFee();
        for (uint256 i; i < _rawInput.length; ++i) {
            _replaceTags(_rawInput[i], payable(msg.sender), taggingFee);
        }
    }

    /// @inheritdoc IETSRelayerV1
    function removeTags(IETS.TaggingRecordRawInput[] calldata _rawInput) public payable whenNotPaused {
        for (uint256 i; i < _rawInput.length; ++i) {
            _removeTags(_rawInput[i], payable(msg.sender));
        }
    }

    /// @inheritdoc IETSRelayerV1
    function getOrCreateTagIds(
        string[] calldata _tags
    ) public payable whenNotPaused returns (uint256[] memory _tagIds) {
        // First let's derive tagIds for the tagStrings.
        uint256[] memory tagIds = new uint256[](_tags.length);
        for (uint256 i; i < _tags.length; ++i) {
            // for new CTAGs msg.sender is logged as "creator" and this contract is "relayer"
            tagIds[i] = ets.getOrCreateTagId(_tags[i], payable(msg.sender));
        }
        return tagIds;
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IETSRelayer) returns (bool) {
        return interfaceId == IID_IETSRelayer || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IETSRelayer
    function isPausedByOwner() public view virtual returns (bool) {
        return paused();
    }

    /// @inheritdoc IETSRelayer
    function getOwner() public view virtual returns (address payable) {
        return payable(owner());
    }

    /// @inheritdoc IETSRelayer
    function getRelayerName() public view returns (string memory) {
        return relayerName;
    }

    /// @inheritdoc IETSRelayer
    function getCreator() public view returns (address payable) {
        return creator;
    }

    /// @inheritdoc IETSRelayerV1
    function computeTaggingFee(
        IETS.TaggingRecordRawInput calldata _rawInput,
        IETS.TaggingAction _action
    ) public view returns (uint256 fee, uint256 tagCount) {
        return ets.computeTaggingFeeFromRawInput(_rawInput, address(this), msg.sender, _action);
    }

    // ============ INTERNAL FUNCTIONS ============

    function _applyTags(
        IETS.TaggingRecordRawInput calldata _rawInput,
        address payable _tagger,
        uint256 _taggingFee
    ) internal {
        uint256 valueToSendForTagging = 0;
        if (_taggingFee > 0) {
            // This is either a new tagging record or an existing record that's being appended to.
            // Either way, we need to assess the tagging fees.
            uint256 actualTagCount = 0;
            (valueToSendForTagging, actualTagCount) = ets.computeTaggingFeeFromRawInput(
                _rawInput,
                address(this),
                _tagger,
                IETS.TaggingAction.APPEND
            );
            require(address(this).balance >= valueToSendForTagging, "Not enough funds to complete tagging");
        }

        // Call the core applyTagsWithRawInput() function to record new or append to exsiting tagging record.
        ets.applyTagsWithRawInput{ value: valueToSendForTagging }(_rawInput, _tagger);
    }

    function _replaceTags(
        IETS.TaggingRecordRawInput calldata _rawInput,
        address payable _tagger,
        uint256 _taggingFee
    ) internal {
        uint256 valueToSendForTagging = 0;
        if (_taggingFee > 0) {
            // This is either a new tagging record or an existing record that's being appended to.
            // Either way, we need to assess the tagging fees.
            uint256 actualTagCount = 0;
            (valueToSendForTagging, actualTagCount) = ets.computeTaggingFeeFromRawInput(
                _rawInput,
                address(this),
                _tagger,
                IETS.TaggingAction.REPLACE
            );
            require(address(this).balance >= valueToSendForTagging, "Not enough funds to complete tagging");
        }

        // Finally, call the core replaceTags() function to update the tagging record.
        ets.replaceTagsWithRawInput{ value: valueToSendForTagging }(_rawInput, _tagger);
    }

    function _removeTags(IETS.TaggingRecordRawInput calldata _rawInput, address payable _tagger) internal {
        ets.removeTagsWithRawInput(_rawInput, _tagger);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title IETSToken
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETSToken.sol core contract that governs the creation & management
 * of Ethereum Tag Service composable tags (CTAGs).
 *
 * CTAGs are ERC-721 non-fungible tokens that store a single tag string and origin attribution data including
 * a "Relayer" address and a "Creator" address. The tag string must conform to a few simple validation rules.
 *
 * CTAGs are identified in ETS by their Id (tagId) which is an unsigned integer computed from the lowercased
 * tag "display" string. Given this, only one CTAG exists for a tag string regardless of its case. For
 * example, #Punks, #punks and #PUNKS all resolve to the same CTAG.
 *
 * CTAG Ids are combined with Target Ids (see ETSTarget.sol) by ETS core (ETS.sol) to form "Tagging Records".
 *
 * CTAGs may only be generated by Relayer contracts (see examples/ETSRelayer.sol) via ETS core (ETS.sol)
 */
interface IETSToken is IERC721Upgradeable {
    /**
     * @notice Data structure for CTAG Token.
     *
     * Only premium and reserved flags are editable.
     *
     * @param relayer Address of IETSTargetTagger implementation that created CTAG.
     * @param creator Address interacting with relayer to initiate CTAG creation.
     * @param display Display version of CTAG string.
     * @param premium ETS governed boolean flag to identify a CTAG as premium/higher value.
     * @param reserved ETS governed boolean flag to restrict a CTAG from release to auction.
     */
    struct Tag {
        address relayer;
        address creator;
        string display;
        bool premium;
        bool reserved;
    }

    // Events

    /**
     * @dev emitted when the maximum character length of CTAG display string is set.
     *
     * @param maxStringLength maximum character length of string.
     */
    event TagMaxStringLengthSet(uint256 maxStringLength);

    /**
     * @dev emitted when the minimum character length of CTAG display string is set.
     *
     * @param minStringLength minimum character length of string.
     */
    event TagMinStringLengthSet(uint256 minStringLength);

    /**
     * @dev emitted when the ownership term length of a CTAG is set.
     *
     * @param termLength Ownership term length in days.
     */
    event OwnershipTermLengthSet(uint256 termLength);

    /**
     * @dev emitted when the ETS core contract is set.
     *
     * @param ets ets core contract address.
     */
    event ETSCoreSet(address ets);

    /**
     * @dev emitted when the ETS Access Controls is set.
     *
     * @param etsAccessControls contract address access controls is set to.
     */
    event AccessControlsSet(address etsAccessControls);

    /**
     * @dev emitted when a tag string is flagged/unflagged as premium prior to minting.
     *
     * @param tag tag string being flagged.
     * @param isPremium boolean true for premium/false not premium.
     */
    event PremiumTagPreSet(string tag, bool isPremium);

    /**
     * @dev emitted when a CTAG is flagged/unflagged as premium subsequent to minting.
     *
     * @param tagId Id of CTAG token.
     * @param isPremium boolean true for premium/false not premium.
     */
    event PremiumFlagSet(uint256 tagId, bool isPremium);

    /**
     * @dev emitted when a CTAG is flagged/unflagged as reserved subsequent to minting.
     *
     * @param tagId Id of CTAG token.
     * @param isReserved boolean true for reserved/false for not reserved.
     */
    event ReservedFlagSet(uint256 tagId, bool isReserved);

    /**
     * @dev emitted when CTAG token is renewed.
     *
     * @param tokenId Id of CTAG token.
     * @param caller address of renewer.
     */
    event TagRenewed(uint256 indexed tokenId, address indexed caller);

    /**
     * @dev emitted when CTAG token is recycled back to ETS.
     *
     * @param tokenId Id of CTAG token.
     * @param caller address of recycler.
     */
    event TagRecycled(uint256 indexed tokenId, address indexed caller);

    // ============ OWNER INTERFACE ============

    /**
     * @notice admin function to set maximum character length of CTAG display string.
     *
     * @param _tagMaxStringLength maximum character length of string.
     */
    function setTagMaxStringLength(uint256 _tagMaxStringLength) external;

    /**
     * @notice Admin function to set minimum  character length of CTAG display string.
     *
     * @param _tagMinStringLength minimum character length of string.
     */
    function setTagMinStringLength(uint256 _tagMinStringLength) external;

    /**
     * @notice Admin function to set the ownership term length of a CTAG is set.
     *
     * @param _ownershipTermLength Ownership term length in days.
     */
    function setOwnershipTermLength(uint256 _ownershipTermLength) external;

    /**
     * @notice Admin function to flag/unflag tag string(s) as premium prior to minting.
     *
     * @param _tags Array of tag strings.
     * @param _isPremium Boolean true for premium, false for not premium.
     */
    function preSetPremiumTags(string[] calldata _tags, bool _isPremium) external;

    /**
     * @notice Admin function to flag/unflag CTAG(s) as premium.
     *
     * @param _tokenIds Array of CTAG Ids.
     * @param _isPremium Boolean true for premium, false for not premium.
     */
    function setPremiumFlag(uint256[] calldata _tokenIds, bool _isPremium) external;

    /**
     * @notice Admin function to flag/unflag CTAG(s) as reserved.
     *
     * Tags flagged as reserved cannot be auctioned.
     *
     * @param _tokenIds Array of CTAG Ids.
     * @param _reserved Boolean true for reserved, false for not reserved.
     */
    function setReservedFlag(uint256[] calldata _tokenIds, bool _reserved) external;

    // ============ PUBLIC INTERFACE ============

    /**
     * @notice Get CTAG token Id from tag string.
     *
     * Combo function that accepts a tag string and returns it's CTAG token Id if it exists,
     * or creates a new CTAG and returns corresponding Id.
     *
     * Only ETS Core can call this function.
     *
     * @param _tag Tag string.
     * @param _relayer Address of Relayer contract calling ETS Core.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function getOrCreateTagId(
        string calldata _tag,
        address payable _relayer,
        address payable _creator
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Create CTAG token from tag string.
     *
     * Reverts if tag exists or is invalid.
     *
     * Only ETS Core can call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function createTag(
        string calldata _tag,
        address payable _relayer,
        address payable _creator
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Renews ownership term of a CTAG.
     *
     * A "CTAG ownership term" is utilized to prevent CTAGs from being abandoned or inaccessable
     * due to lost private keys.
     *
     * Any wallet address may renew the term of a CTAG for an owner. When renewed, the term
     * is extended from the current block timestamp plus the ownershipTermLength public variable.
     *
     * @param _tokenId Id of CTAG token.
     */
    function renewTag(uint256 _tokenId) external;

    /**
     * @notice Recycles a CTAG back to ETS.
     *
     * When ownership term of a CTAG has expired, any wallet or contract may call this function
     * to recycle the tag back to ETS. Once recycled, a tag may be auctioned again.
     *
     * @param _tokenId Id of CTAG token.
     */
    function recycleTag(uint256 _tokenId) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Function to deterministically compute & return a CTAG token Id.
     *
     * Every CTAG token and it's associated data struct is mapped to by it's token Id. This Id is computed
     * from the "display" tag string lowercased, hashed and cast as an unsigned integer.
     *
     * Note: Function does not verify if CTAG record exists.
     *
     * @param _tag Tag string.
     * @return Id of potential CTAG token id.
     */
    function computeTagId(string memory _tag) external pure returns (uint256);

    /**
     * @notice Check that a CTAG token exists for a given tag string.
     *
     * @param _tag Tag string.
     * @return true if CTAG token exists; false if not.
     */
    function tagExistsByString(string calldata _tag) external view returns (bool);

    /**
     * @notice Check that CTAG token exists for a given computed token Id.
     *
     * @param _tokenId Token Id uint computed from tag string via computeTargetId().
     * @return true if CTAG token exists; false if not.
     */
    function tagExistsById(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Retrieve a CTAG record for a given tag string.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tag Tag string.
     * @return CTAG record as Tag struct.
     */
    function getTagByString(string calldata _tag) external view returns (Tag memory);

    /**
     * @notice Retrieve a CTAG record for a given token Id.
     *
     * Note: returns a struct with empty members when no CTAG exists.
     *
     * @param _tokenId CTAG token Id.
     * @return CTAG record as Tag struct.
     */
    function getTagById(uint256 _tokenId) external view returns (Tag memory);

    /**
     * @notice Retrieve wallet address for ETS Platform.
     *
     * @return wallet address for ETS Platform.
     */
    function getPlatformAddress() external view returns (address payable);

    /**
     * @notice Retrieve Creator address for a CTAG token.
     *
     * @param _tokenId CTAG token Id.
     * @return _creator Creator address of the CTAG.
     */
    function getCreatorAddress(uint256 _tokenId) external view returns (address);

    /**
     * @notice Retrieve last renewal block timestamp for a CTAG.
     *
     * @param _tokenId CTAG token Id.
     * @return Block timestamp.
     */
    function getLastRenewed(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Retrieve CTAG ownership term length global setting.
     *
     * @return Term length in days.
     */
    function getOwnershipTermLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IETS
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the interface for the ETS.sol core contract that records ETS TaggingRecords to the blockchain.
 */
interface IETS {
    /**
     * @notice Data structure for raw client input data.
     *
     * @param targetURI Unique resource identifier string, eg. "https://google.com"
     * @param tagStrings Array of hashtag strings, eg. ["#Love, "#Blue"]
     * @param recordType Arbitrary identifier for type of tagging record, eg. "Bookmark"
     */
    struct TaggingRecordRawInput {
        string targetURI;
        string[] tagStrings;
        string recordType;
    }

    /**
     * @notice Data structure for an Ethereum Tag Service "tagging record".
     *
     * The TaggingRecord is the fundamental data structure of ETS and reflects "who tagged what, where and why".
     *
     * Every Tagging record has a unique Id computed from the hashed composite of targetId, recordType, tagger and
     * relayer addresses cast as a uint256. see computeTaggingRecordId()
     *
     * Given this design, a tagger who tags the same URI with the same tags and recordType via two different relayers
     * would produce two TaggingRecords in ETS.
     *
     * @param tagIds Ids of CTAG token(s).
     * @param targetId Id of target being tagged.
     * @param recordType Arbitrary identifier for type of tagging record.
     * @param relayer Address of Relayer contract that wrote tagging record.
     * @param tagger Address of wallet that initiated tagging record via relayer.
     */
    struct TaggingRecord {
        uint256[] tagIds;
        uint256 targetId;
        string recordType;
        address relayer;
        address tagger;
    }

    /**
     * @dev Action types available for tags in a tagging record.
     *
     * 0 - APPEND Add tags to a tagging record.
     * 1 - REPLACE Replace (overwrite) tags in a tagging record.
     * 2 - REMOVE Remove tags in a tagging record.
     */
    enum TaggingAction {
        APPEND,
        REPLACE,
        REMOVE
    }

    /**
     * @dev emitted when the ETS Access Controls is set.
     *
     * @param newAccessControls contract address access controls is set to.
     */
    event AccessControlsSet(address newAccessControls);

    /**
     * @dev emitted when ETS tagging fee is set.
     *
     * @param newTaggingFee new tagging fee.
     */
    event TaggingFeeSet(uint256 newTaggingFee);

    /**
     * @dev emitted when participant distribution percentages are set.
     *
     * @param platformPercentage percentage of tagging fee allocated to ETS.
     * @param relayerPercentage percentage of tagging fee allocated to relayer of record for CTAG being used in tagging record.
     */
    event PercentagesSet(uint256 platformPercentage, uint256 relayerPercentage);

    /**
     * @dev emitted when a new tagging record is recorded within ETS.
     *
     * @param taggingRecordId Unique identifier of tagging record.
     */
    event TaggingRecordCreated(uint256 taggingRecordId);

    /**
     * @dev emitted when a tagging record is updated.
     *
     * @param taggingRecordId tagging record being updated.
     * @param action Type of update applied as TaggingAction enum.
     */
    event TaggingRecordUpdated(uint256 taggingRecordId, TaggingAction action);

    /**
     * @dev emitted when ETS participant draws down funds accrued to their contract or wallet.
     *
     * @param who contract or wallet address being drawn down.
     * @param amount amount being drawn down.
     */
    event FundsWithdrawn(address indexed who, uint256 amount);

    // ============ PUBLIC INTERFACE ============

    /**
     * @notice Create a new tagging record.
     *
     * Requirements:
     *
     *   - Caller must be relayer contract.
     *   - CTAG(s) and TargetId must exist.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address calling Relayer contract to create tagging record.
     */
    function createTaggingRecord(
        uint256[] memory _tagIds,
        uint256 _targetId,
        string calldata _recordType,
        address _tagger
    ) external payable;

    /**
     * @notice Get or create CTAG token from tag string.
     *
     * Combo function that accepts a tag string and returns corresponding CTAG token Id if it exists,
     * or if it doesn't exist, creates a new CTAG and then returns corresponding Id.
     *
     * Only ETS Relayer contracts may call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function getOrCreateTagId(
        string calldata _tag,
        address payable _creator
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Create CTAG token from tag string.
     *
     * Reverts if tag exists or is invalid.
     *
     * Only ETS Relayer contracts may call this function.
     *
     * @param _tag Tag string.
     * @param _creator Address credited with creating CTAG.
     * @return tokenId Id of CTAG token.
     */
    function createTag(string calldata _tag, address payable _creator) external payable returns (uint256 tokenId);

    /**
     * @notice Apply one or more tags to a targetURI using tagging record raw client input data.
     *
     * Like it's sister function applyTagsWithCompositeKey, records new ETS Tagging Record or appends tags to an
     * existing record if found to already exist. This function differs in that it creates new ETS target records
     * and CTAG tokens for novel targetURIs and hastag strings respectively. This function can only be called by
     * Relayer contracts.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Relayer to tag a targetURI.
     */
    function applyTagsWithRawInput(TaggingRecordRawInput calldata _rawInput, address payable _tagger) external payable;

    /**
     * @notice Apply one or more tags to a targetId using using tagging record composite key.
     *
     * Records new ETS Tagging Record to the blockchain or appends tags if Tagging Record already exists. CTAGs and
     * targetId are created if they don't exist. Caller must be Relayer contract.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Relayer to create tagging record.
     */
    function applyTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable;

    /**
     * @notice Replace entire tag set in tagging record using raw data for record lookup.
     *
     * If supplied tag strings don't have CTAGs, new ones are minted.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Relayer to tag a targetURI.
     */
    function replaceTagsWithRawInput(
        TaggingRecordRawInput calldata _rawInput,
        address payable _tagger
    ) external payable;

    /**
     * @notice Replace entire tag set in tagging record using composite key for record lookup.
     *
     * This function overwrites the tags in a tagging record with the supplied tags, only
     * charging for the new tags in the replacement set.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Relayer to create tagging record.
     */
    function replaceTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable;

    /**
     * @notice Remove one or more tags from a tagging record using raw data for record lookup.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _tagger Address that calls Relayer to tag a targetURI.
     */
    function removeTagsWithRawInput(TaggingRecordRawInput calldata _rawInput, address _tagger) external;

    /**
     * @notice Remove one or more tags from a tagging record using composite key for record lookup.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _targetId targetId of the URI being tagged. See ETSTarget.sol
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _tagger Address of that calls Relayer to create tagging record.
     */
    function removeTagsWithCompositeKey(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external;

    /**
     * @notice Append one or more tags to a tagging record.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function appendTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external payable;

    /**
     * @notice Replaces tags in tagging record.
     *
     * This function overwrites the tags in a tagging record with the supplied tags, only
     * charging for the new tags in the replacement set.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function replaceTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external payable;

    /**
     * @notice Remove one or more tags from a tagging record.
     *
     * @param _taggingRecordId tagging record being updated.
     * @param _tagIds Array of CTAG token Ids.
     */
    function removeTags(uint256 _taggingRecordId, uint256[] calldata _tagIds) external;

    /**
     * @notice Function for withdrawing funds from an accrual account. Can be called by the account owner
     * or on behalf of the account. Does nothing when there is nothing due to the account.
     *
     * @param _account Address of account being drawn down and which will receive the funds.
     */
    function drawDown(address payable _account) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Compute a taggingRecordId from raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     *
     * @return taggingRecordId Unique identifier for a tagging record.
     */
    function computeTaggingRecordIdFromRawInput(
        TaggingRecordRawInput calldata _rawInput,
        address _relayer,
        address _tagger
    ) external view returns (uint256 taggingRecordId);

    /**
     * @notice Compute & return a taggingRecordId.
     *
     * Every TaggingRecord in ETS is mapped to by it's taggingRecordId. This Id is a composite key
     * composed of targetId, recordType, relayer contract address and tagger address hashed and cast as a uint256.
     *
     * @param _targetId Id of target being tagged (see ETSTarget.sol).
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     *
     * @return taggingRecordId Unique identifier for a tagging record.
     */
    function computeTaggingRecordIdFromCompositeKey(
        uint256 _targetId,
        string memory _recordType,
        address _relayer,
        address _tagger
    ) external pure returns (uint256 taggingRecordId);

    /**
     * @notice Compute tagging fee for raw input and desired action.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFeeFromRawInput(
        TaggingRecordRawInput memory _rawInput,
        address _relayer,
        address _tagger,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Compute tagging fee for CTAGs, tagging record composite key and desired action.
     *
     * @param _tagIds Array of CTAG token Ids.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFeeFromCompositeKey(
        uint256[] memory _tagIds,
        uint256 _targetId,
        string calldata _recordType,
        address _relayer,
        address _tagger,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Compute tagging fee for CTAGs, tagging record id and desired action.
     *
     * If the global, service wide tagging fee is set (see ETS.taggingFee() & ETS.setTaggingFee()) ETS charges a per tag for all
     * new tags applied to a tagging record. This applies to both new tagging records and modified tagging records.
     *
     * Computing the tagging fee involves checking to see if a tagging record exists and if so, given the desired action
     * (append or replace) determining the number of new tags being added and multiplying by the ETS per tag fee.
     *
     * @param _taggingRecordId Id of tagging record.
     * @param _tagIds Array of CTAG token Ids.
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFee(
        uint256 _taggingRecordId,
        uint256[] memory _tagIds,
        TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);

    /**
     * @notice Retrieve a tagging record from it's raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return relayer Address of tagging record Relayer contract.
     * @return tagger Address interacting with Relayer to tag content ("Tagger").
     */
    function getTaggingRecordFromRawInput(
        TaggingRecordRawInput memory _rawInput,
        address _relayer,
        address _tagger
    )
        external
        view
        returns (uint256[] memory tagIds, uint256 targetId, string memory recordType, address relayer, address tagger);

    /**
     * @notice Retrieve a tagging record from composite key parts.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _relayer Address of Relayer contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via relayer.
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return relayer Address of tagging record Relayer contract.
     * @return tagger Address interacting with Relayer to tag content ("Tagger").
     */
    function getTaggingRecordFromCompositeKey(
        uint256 _targetId,
        string memory _recordType,
        address _relayer,
        address _tagger
    )
        external
        view
        returns (uint256[] memory tagIds, uint256 targetId, string memory recordType, address relayer, address tagger);

    /**
     * @notice Retrieve a tagging record from Id.
     *
     * @param _id taggingRecordId.
     *
     * @return tagIds CTAG token ids.
     * @return targetId TargetId that was tagged.
     * @return recordType Type of tagging record.
     * @return relayer Address of tagging record Relayer contract.
     * @return tagger Address interacting with Relayer to tag content ("Tagger").
     */
    function getTaggingRecordFromId(
        uint256 _id
    )
        external
        view
        returns (uint256[] memory tagIds, uint256 targetId, string memory recordType, address relayer, address tagger);

    /**
     * @notice Check that a tagging record exists for given raw input.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _relayer Address of tagging record Relayer contract.
     * @param _tagger Address interacting with Relayer to tag content ("Tagger").
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExistsByRawInput(
        TaggingRecordRawInput memory _rawInput,
        address _relayer,
        address _tagger
    ) external view returns (bool);

    /**
     * @notice Check that a tagging record exists by it's componsite key parts.
     *
     * @param _targetId Id of target being tagged.
     * @param _recordType Arbitrary identifier for type of tagging record.
     * @param _relayer Address of Relayer contract that wrote tagging record.
     * @param _tagger Address of wallet that initiated tagging record via relayer.
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExistsByCompositeKey(
        uint256 _targetId,
        string memory _recordType,
        address _relayer,
        address _tagger
    ) external view returns (bool);

    /**
     * @notice Check that a tagging record exsits by it's Id.
     *
     * @param _taggingRecordId taggingRecordId.
     *
     * @return boolean; true for exists, false for not.
     */
    function taggingRecordExists(uint256 _taggingRecordId) external view returns (bool);

    /**
     * @notice Function to check how much MATIC has been accrued by an address factoring in amount paid out.
     *
     * @param _account Address of the account being queried.
     * @return _due Amount of WEI in MATIC due to account.
     */
    function totalDue(address _account) external view returns (uint256 _due);

    /**
     * @notice Function to retrieve the ETS platform tagging fee.
     *
     * @return tagging fee.
     */
    function taggingFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title IETSTarget
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice This is the standard interface for the core ETSTarget.sol contract. It includes both public
 * and administration functions.
 *
 * In ETS, a "Target" is our data structure, stored onchain, that references/points to a URI. Target records
 * are identified in ETS by their Id (targetId) which is a unsigned integer computed from the URI string.
 * Target Ids are combined with CTAG Ids by ETS core (ETS.sol) to form "Tagging Records".
 *
 * For context, from Wikipedia, URI is short for Uniform Resource Identifier and is a unique sequence of
 * characters that identifies a logical or physical resource used by web technologies. URIs may be used to
 * identify anything, including real-world objects, such as people and places, concepts, or information
 * resources such as web pages and books.
 *
 * For our purposes, as much as possible, we are restricting our interpretation of URIs to the more technical
 * parameters defined by the IETF in [RFC3986](https://www.rfc-editor.org/rfc/rfc3986). For newer protocols, such
 * as blockchains, For newer protocols, such as blockchains we will lean on newer emerging URI standards such
 * as the [Blink](https://w3c-ccg.github.io/blockchain-links) and [BIP-122](https://github.com/bitcoin/bips/blob/master/bip-0122.mediawiki)
 *
 * One the thing to keep in mind with URIs & ETS Targets is that differently shaped URIs can sometimes point to the same
 * resource. The effect of that is that different Target IDs in ETS can similarly point to the same resource.
 */
interface IETSTarget {
    /**
     * @notice Data structure for an ETS Target.
     *
     * @param targetURI Unique resource identifier Target points to
     * @param createdBy Address of IETSTargetTagger implementation that created Target
     * @param enriched block timestamp when Target was last enriched. Defaults to 0
     * @param httpStatus https status of last response from ETSEnrichTarget API eg. "404", "200". defaults to 0
     * @param ipfsHash ipfsHash of additional metadata for Target collected by ETSEnrichTarget API
     */
    struct Target {
        string targetURI;
        address createdBy;
        uint256 enriched;
        uint256 httpStatus;
        string ipfsHash;
    }

    /**
     * @dev emitted when the ETSAccessControls is set.
     *
     * @param etsAccessControls contract address ETSAccessControls is set to.
     */
    event AccessControlsSet(address etsAccessControls);

    /**
     * @dev emitted when the ETSEnrichTarget API address is set.
     *
     * @param etsEnrichTarget contract address ETSEnrichTarget is set to.
     */
    event EnrichTargetSet(address etsEnrichTarget);

    /**
     * @dev emitted when a new Target is created.
     *
     * @param targetId Unique Id of new Target.
     */
    event TargetCreated(uint256 targetId);

    /**
     * @dev emitted when an existing Target is updated.
     *
     * @param targetId Id of Target being updated.
     */
    event TargetUpdated(uint256 targetId);

    /**
     * @notice Sets ETSEnrichTarget contract address so that Target metadata enrichment
     * functions can be called from ETSTarget.
     *
     * @param _etsEnrichTarget Address of ETSEnrichTarget contract.
     */
    function setEnrichTarget(address _etsEnrichTarget) external;

    /**
     * @notice Get ETS targetId from URI.
     *
     * Combo function that given a URI string will return it's ETS targetId if it exists,
     * or create a new Target record and return corresponding targetId.
     *
     * @param _targetURI URI passed in as string
     * @return Id of ETS Target record
     */
    function getOrCreateTargetId(string memory _targetURI) external returns (uint256);

    /**
     * @notice Create a Target record and return it's targetId.
     *
     * @param _targetURI URI passed in as string
     * @return targetId Id of ETS Target record
     */
    function createTarget(string memory _targetURI) external returns (uint256 targetId);

    /**
     * @notice Update a Target record.
     *
     * @param _targetId Id of Target being updated.
     * @param _targetURI Unique resource identifier Target points to.
     * @param _enriched block timestamp when Target was last enriched
     * @param _httpStatus https status of last response from ETSEnrichTarget API eg. "404", "200". defaults to 0
     * @param _ipfsHash ipfsHash of additional metadata for Target collected by ETSEnrichTarget API

     * @return success true when Target is successfully updated.
     */
    function updateTarget(
        uint256 _targetId,
        string calldata _targetURI,
        uint256 _enriched,
        uint256 _httpStatus,
        string calldata _ipfsHash
    ) external returns (bool success);

    /**
     * @notice Function to deterministically compute & return a targetId.
     *
     * Every Target in ETS is mapped to by it's targetId. This Id is computed from
     * the target URI sting hashed and cast as a uint256.
     *
     * Note: Function does not verify if Target record exists.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return targetId Id of the potential Target record.
     */
    function computeTargetId(string memory _targetURI) external view returns (uint256 targetId);

    /**
     * @notice Check that a Target record exists for a given URI string.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return true if Target record exists; false if not.
     */
    function targetExistsByURI(string memory _targetURI) external view returns (bool);

    /**
     * @notice Check that a Target record exists for a given computed targetId.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return true if Target record exists; false if not.
     */
    function targetExistsById(uint256 _targetId) external view returns (bool);

    /**
     * @notice Retrieve a Target record for a given URI string.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetURI Unique resource identifier Target record points to.
     * @return Target record.
     */
    function getTargetByURI(string memory _targetURI) external view returns (Target memory);

    /**
     * @notice Retrieve a Target record for a computed targetId.
     *
     * Note: returns a struct with empty members when no Target exists.
     *
     * @param _targetId targetId uint computed from URI via computeTargetId().
     * @return Target record.
     */
    function getTargetById(uint256 _targetId) external view returns (Target memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Adapted from Cryptofin labs Array Utilities
// https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

library UintArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(uint256[] memory A, uint256 a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(uint256[] memory A, uint256 a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Computes the difference of two arrays. Assumes there are no duplicates.
     * @param A The first array
     * @param B The second array
     * @return A - B; an array of values in A not found in B.
     */
    function difference(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
        // First count the new length because can't push for in-memory arrays
        for (uint256 i = 0; i < length; i++) {
            uint256 e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        uint256[] memory newItems = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newItems[j] = A[i];
                j++;
            }
        }
        return newItems;
    }

    /**
     * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
     * @param A The first array
     * @param B The second array
     * @return The intersection of the two arrays
     */
    function intersect(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        uint256[] memory newArray = new uint256[](newLength);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newArray[j] = A[i];
                j++;
            }
        }
        return newArray;
    }

    /**
     * Returns the combination of two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        uint256[] memory newArray = new uint256[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newArray[i] = A[i];
        }
        for (uint256 i = 0; i < bLength; i++) {
            newArray[aLength + i] = B[i];
        }
        return newArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IETSRelayer.sol";
import "../../interfaces/IETS.sol";

/**
 * @title IETSRelayerV1
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice Interface for the IETSRelayerV1 contract.
 */
interface IETSRelayerV1 is IETSRelayer {
    /**
     * @notice Apply one or more tags to a targetURI using tagging record raw client input data.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     */
    function applyTags(IETS.TaggingRecordRawInput[] calldata _rawInput) external payable;

    /**
     * @notice Replace entire tag set in tagging record using raw data for record lookup.
     *
     * If supplied tag strings don't have CTAGs, new ones are minted.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     */
    function replaceTags(IETS.TaggingRecordRawInput[] calldata _rawInput) external payable;

    /**
     * @notice Remove one or more tags from a tagging record using raw data for record lookup.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     */
    function removeTags(IETS.TaggingRecordRawInput[] calldata _rawInput) external payable;

    /**
     * @notice Get or create CTAG tokens from tag strings.
     *
     * Combo function that accepts a tag strings and returns corresponding CTAG token Id if it exists,
     * or if it doesn't exist, creates a new CTAG and then returns corresponding Id.
     *
     * Only ETS Publisher contracts may call this function.
     *
     * @param _tags Array of tag strings.
     * @return _tagIds Array of Id of CTAG Ids.
     */
    function getOrCreateTagIds(string[] calldata _tags) external payable returns (uint256[] memory _tagIds);

    /**
     * @notice Compute tagging fee for raw input and desired action.
     *
     * @param _rawInput Raw client input data formed as TaggingRecordRawInput struct.
     * @param _action Integer representing action to be performed according to enum TaggingAction.
     *
     * @return fee Calculated tagging fee in ETH/Matic
     * @return tagCount Number of new tags being added to tagging record.
     */
    function computeTaggingFee(
        IETS.TaggingRecordRawInput calldata _rawInput,
        IETS.TaggingAction _action
    ) external view returns (uint256 fee, uint256 tagCount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title IETSRelayer
 * @author Ethereum Tag Service <[email protected]>
 *
 * @notice Minimum interface required for ETS Relayer smart contracts. Contracts implementing this
 * interface will need to import OpenZeppelin ERC165, Ownable and Pausable contracts.
 * See https://github.com/ethereum-tag-service/ets/blob/stage/packages/contracts/contracts/examples/ETSRelayer.sol
 * for a sample implementation.
 */
interface IETSRelayer {
    /**
     * @dev Emitted when an IETSRelayer contract is paused/unpaused.
     *
     * @param relayerAddress Address of relayer contract.
     */
    event RelayerPauseToggledByOwner(address relayerAddress);

    /**
     * @dev Emitted when an IETSRelayer contract has changed owners.
     *
     * @param relayerAddress Address of relayer contract.
     */
    event RelayerOwnerChanged(address relayerAddress);

    // ============ OWNER INTERFACE ============

    /**
     * @notice Pause this relayer contract.
     * @dev This function can only be called by the owner when the contract is unpaused.
     */
    function pause() external;

    /**
     * @notice Unpause this relayer contract.
     * @dev This function can only be called by the owner when the contract is paused.
     */
    function unpause() external;

    /**
     * @notice Transfer this contract to a new owner.
     *
     * @dev This function can only be called by the owner when the contract is paused.
     *
     * @param newOwner Address of the new contract owner.
     */
    function changeOwner(address newOwner) external;

    // ============ PUBLIC VIEW FUNCTIONS ============

    /**
     * @notice Broadcast support for IETSRelayer interface to external contracts.
     *
     * @dev ETSCore will only add relayer contracts that implement IETSRelayer interface.
     * Your implementation should broadcast that it implements IETSRelayer interface.
     *
     * @return boolean: true if this contract implements the interface defined by
     * `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Check whether this contract has been pasued by the owner.
     *
     * @dev Pause functionality should be provided by OpenZeppelin Pausable utility.
     * @return boolean: true for paused; false for not paused.
     */
    function isPausedByOwner() external view returns (bool);

    /**
     * @notice Returns address of an IETSRelayer contract owner.
     *
     * @return address of contract owner.
     */
    function getOwner() external view returns (address payable);

    /**
     * @notice Returns human readable name for this IETSRelayer contract.
     *
     * @return name of the Relayer contract as a string.
     */
    function getRelayerName() external view returns (string memory);

    /**
     * @notice Returns address of an IETSRelayer contract creator.
     *
     * @return address of the creator of the Relayer contract.
     */
    function getCreator() external view returns (address payable);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}