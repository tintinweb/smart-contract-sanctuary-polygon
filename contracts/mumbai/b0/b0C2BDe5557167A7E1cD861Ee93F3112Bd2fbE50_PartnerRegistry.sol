// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../access/OperatorAccessControlUpgradeable.sol";

contract PartnerRegistry is OperatorAccessControlUpgradeable {
    address[] public partners;
    mapping(address => uint) partnerIdxPlusOne;

    event PartnerRegistryChanged(address partner, bool isAdded);

    struct Event {
        address partner;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPerFlexer;
        uint256 another1TokenRewardPool;
        bool isPoapAssigned;
        bool isCancelled;
    }

    string public EventBaseUri;
    Event[] public events;
    mapping(address => uint256) clerkToEventIdPlusOne;
    mapping(uint256 => mapping(address => bool)) allowedCollectionsByEventId;
    mapping(uint256 => uint256) public allowedCollectionsCounterByEventId;

    event EventCreated(address indexed partner, uint256 index, uint256 startTime, uint256 endTime, uint256 rewardPerFlexer, uint256 another1TokenRewardPool, bool isPoapAssigned);
    event EventModified(address indexed partner, uint256 index, uint256 startTime, uint256 endTime, uint256 rewardPerFlexer, uint256 another1TokenRewardPool, bool isPoapAssigned);
    event ClerkAddedToEvent(uint256 indexed eventId, address clerk);
    event ClerkRemovedFromEvent(uint256 indexed eventId, address clerk);
    event AllowedCollectionsAdded(uint256 indexed eventId, address[] collectionAddresses);
    event AllowedCollectionsRemoved(uint256 indexed eventId, address[] collectionAddresses);
    event EventCancellation(uint256 indexed eventId, bool isCancelled);

    function __PartnerRegistry_initialize(string memory _eventBaseUri)
        public
        initializer
        onlyInitializing
    {
        __OperatorAccessControl_init(_msgSender());
        __PartnerRegistry_initialize_unchained(_eventBaseUri);
    }

    function __PartnerRegistry_initialize_unchained(string memory _eventBaseUri) public onlyInitializing {
        setEventBaseUri(_eventBaseUri);
    }

    modifier onlyPartner(address _partner) {
        require(isPartner(_partner), "PartnerRegistry::onlyPartner: address is not a partner");
        _;
    }

    modifier onlyEventOwner(uint256 eventId) {
        require(events[eventId].partner == msg.sender, "PartnerRegistry::onlyEventOwner: sender is not Event owner");
        _;
    }

    function addPartner(address _partner) external onlyOperator {
        require(
            _partner != address(0),
            "PartnerRegistry::addPartner: added address can't be zero"
        );
        require(
            !isPartner(_partner),
            "PartnerRegistry::addPartner: partner already registered"
        );
        partners.push(_partner);
        partnerIdxPlusOne[_partner] = partners.length;

        emit PartnerRegistryChanged(_partner, true);
    }

    function removePartner(address _partner) external onlyOperator onlyPartner(_partner) {
        uint removedPartnerIdx = partnerIdxPlusOne[_partner] - 1;
        address lastPartner = partners[partners.length - 1];
        partners[removedPartnerIdx] = lastPartner;
        partnerIdxPlusOne[lastPartner] = removedPartnerIdx + 1;
        partnerIdxPlusOne[_partner] = 0;
        partners.pop();

        emit PartnerRegistryChanged(_partner, false);
    }

    function isPartner(address _addr) public view returns (bool) {
        return partnerIdxPlusOne[_addr] > 0;
    }

    function numPartners() external view returns (uint) {
        return partners.length;
    }

    function setEventBaseUri(string memory _eventBaseUri) public onlyOwner {
        require(bytes(_eventBaseUri).length > 0, "PartnerRegistry::setEventBaseUri EventBaseUri cannot be empty string");
        EventBaseUri = _eventBaseUri;
    }

    function createEvent(uint256 startTime, uint256 endTime, uint256 rewardPerFlexer, uint256 another1TokenRewardPool, bool isPoapAssigned) public onlyPartner(msg.sender) {
        require(endTime > startTime, "PartnerRegistry::createEvent: endTime cannot be before startTime");
        require(rewardPerFlexer > 0, "PartnerRegistry::createEvent: rewardPerFlexer must be greater than zero");
        require(another1TokenRewardPool >= rewardPerFlexer, "PartnerRegistry::createEvent: another1TokenRewardPool must be greater than rewardPerFlexer");

        events.push(Event(msg.sender, startTime, endTime, rewardPerFlexer, another1TokenRewardPool, isPoapAssigned, false));
        emit EventCreated(msg.sender, events.length - 1, startTime, endTime, rewardPerFlexer, another1TokenRewardPool, isPoapAssigned);
    }

    function modifyEvent(uint256 eventId, uint256 startTime, uint256 endTime, uint256 rewardPerFlexer, uint256 another1TokenRewardPool, bool isPoapAssigned) public onlyEventOwner(eventId) {
        require(endTime > startTime, "PartnerRegistry::modifyEvent: endTime cannot be before startTime");
        require(rewardPerFlexer > 0, "PartnerRegistry::modifyEvent: rewardPerFlexer must be greater than zero");
        require(another1TokenRewardPool >= rewardPerFlexer, "PartnerRegistry::modifyEvent: another1TokenRewardPool must be greater than rewardPerFlexer");

        events[eventId].startTime = startTime;
        events[eventId].endTime = endTime;
        events[eventId].rewardPerFlexer = rewardPerFlexer;
        events[eventId].another1TokenRewardPool = another1TokenRewardPool;
        events[eventId].isPoapAssigned = isPoapAssigned;
        emit EventModified(msg.sender, eventId, startTime, endTime, rewardPerFlexer, another1TokenRewardPool, isPoapAssigned);
    }

    function _addClerkToEvent(uint256 eventId, address _clerk) private {
        require(_clerk != address(0), "PartnerRegistry::addClerkToEvent: Clerk address can't be zero");
        if(isClerk(_clerk)) {
            _removeClerkFromEvent(_clerk);
        }

        clerkToEventIdPlusOne[_clerk] = eventId + 1;
        emit ClerkAddedToEvent(eventId, _clerk);
    }

    function addClerksToEvent(uint256 eventId, address[] memory _clerks) public onlyEventOwner(eventId) {
        for(uint256 i = 0; i < _clerks.length; ++i) {
            _addClerkToEvent(eventId, _clerks[i]);
        }
    }

    function _removeClerkFromEvent(address _clerk) private onlyEventOwner(getClerkEventId(_clerk)) {
        uint256 eventId = getClerkEventId(_clerk);

        delete clerkToEventIdPlusOne[_clerk];
        emit ClerkRemovedFromEvent(eventId, _clerk);
    }

    function removeClerksFromEvent(address[] memory _clerks) public {
        for(uint256 i = 0; i < _clerks.length; ++i) {
            _removeClerkFromEvent(_clerks[i]);
        }
    }

    function addAllowedCollections(uint256 eventId, address[] memory colectionAddresses) public onlyEventOwner(eventId) {
        for(uint256 i = 0; i < colectionAddresses.length; ++i) {
            if(!allowedCollectionsByEventId[eventId][colectionAddresses[i]]) {
                allowedCollectionsCounterByEventId[eventId]++;
            }
            allowedCollectionsByEventId[eventId][colectionAddresses[i]] = true;
        }
        emit AllowedCollectionsAdded(eventId, colectionAddresses);
    }

    function removeAllowedCollections(uint256 eventId, address[] memory colectionAddresses) public onlyEventOwner(eventId) {
        for(uint256 i = 0; i < colectionAddresses.length; ++i) {
            if(allowedCollectionsByEventId[eventId][colectionAddresses[i]]) {
                allowedCollectionsCounterByEventId[eventId]--;
            }
            allowedCollectionsByEventId[eventId][colectionAddresses[i]] = false;
        }
        emit AllowedCollectionsRemoved(eventId, colectionAddresses);
    }

    function setEventCancellation(uint256 eventId, bool isCancelled) public onlyEventOwner(eventId) {
        events[eventId].isCancelled = isCancelled;
        emit EventCancellation(eventId, isCancelled);
    }

    // Public getters

    function getEventsCount() public view returns(uint256) {
        return events.length;
    }

    function isClerk(address _clerk) public view returns(bool) {
        return clerkToEventIdPlusOne[_clerk] != 0;
    }

    function getClerkEventId(address _clerk) public view returns(uint256) {
        require(isClerk(_clerk), "PartnerRegistry::getClerkEventId: Clerk is not assigned to any Event");
        return clerkToEventIdPlusOne[_clerk] - 1;
    }

    function partnerOfClerk(address _clerk) public view returns(address) {
        return events[getClerkEventId(_clerk)].partner;
    }

    function getRewardPerFlexer(uint256 eventId) public view returns(uint256) {
        return events[eventId].rewardPerFlexer;
    }

    function getTokenPool(uint256 eventId) public view returns(uint256) {
        return events[eventId].another1TokenRewardPool;
    }

    function getStartAndEndTime(uint256 eventId) public view returns(uint256, uint256) {
        return (
            events[eventId].startTime,
            events[eventId].endTime
        );
    }

    function isPoapAssignedToEvent(uint256 eventId) public view returns(bool) {
        return events[eventId].isPoapAssigned;
    }

    function isCollectionAllowed(uint256 eventId, address collection) public view returns(bool) {
        if(allowedCollectionsCounterByEventId[eventId] == 0) {
            return true;
        }
        return allowedCollectionsByEventId[eventId][collection];
    }

    function isEventCancelled(uint256 eventId) public view returns(bool) {
        return events[eventId].isCancelled;
    }
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (access/OperatorAccessControlUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title OperatorAccessControlUpgradeable contract
 *
 * @dev Contract module which provides operator access control mechanisms, where
 * there is a list of accounts (operators) that can be granted exclusive access to
 * specific priviliged functions.
 *
 * By default, the first operator account will be the one that deploys the contract.
 * This can later be changed by ussing the methods {addOperator}, {removeOperator} or
 * {addOperators}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to the functions with restricted access to
 * the operators.
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
abstract contract OperatorAccessControlUpgradeable is OwnableUpgradeable {

    // Mapping from operator address to status (true/false)
    mapping(address => bool) private operators;
    
    /**
     * @dev Emitted when `operators` values are changed.
     */
    event OperatorAccessChanged(address indexed operator, bool indexed status);

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorAccessControl::onlyOperator: caller is not a operator.");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the owner and first operator.
     */
    function __OperatorAccessControl_init(address _owner) internal onlyInitializing {
        __Ownable_init();
        __OperatorAccessControl_init_unchained(_owner);
    }

    function __OperatorAccessControl_init_unchained(address _owner) internal onlyInitializing {
        _transferOwnership(_owner);
        _addOperator(_owner);
    }

    /**
     * @dev Adds `_operator` to the list of allowed operators.
     */
    function addOperator(address _operator) public onlyOwner {
        _addOperator(_operator);
    }

    /**
     * @dev Adds `_operator` to the list of allowed operators.
     * Internal function without access restriction.
     */
    function _addOperator(address _operator) internal virtual {
        operators[_operator] = true;
        emit OperatorAccessChanged(_operator, true);
    }

    /**
     * @dev Adds `_operators` to the list of allowed 'operators'.
     */
    function addOperators(address[] memory _operators) external onlyOwner {
        for (uint i = 0; i < _operators.length; i++) {
            address operator = _operators[i];
            operators[operator] = true;
            emit OperatorAccessChanged(operator, true);
        }
    }

    /**
     * @dev Revokes `_operator` from the list of allowed 'operators'.
     */
    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
        emit OperatorAccessChanged(_operator, false);
    }

    /**
     * @dev Returns `true` if `_account` has been granted to operators.
     */
    function isOperator(address _account) public view returns (bool) {
        return operators[_account];
    }

    // gap for future versions
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
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
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
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

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
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
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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