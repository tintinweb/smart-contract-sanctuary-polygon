/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractFactory} from '../../abstracts/AbstractFactory.sol';
import {CarbonAccessList} from '../../CarbonAccessList.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import {RemoteCarbonToken} from '../remote/RemoteCarbonToken.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon Token Factory Contract
 */
contract RemoteCarbonTokenFactory is AbstractFactory {

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new carbon credit token.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The name of the new token, should be unique within the ecosystem.
     * @param symbol_ - The symbol of the ERC-20 token, should be unique within the ecosystem.
     * @param details_ - Token details to define the fungibillity characteristics of this token.
     * @param accessList_ - The permission list of this token.
     * @param operator_ - The account that will be granted operator privileges.
     * @param treasury_ - The address of the carbon treasury.
     * @param station_ - The terminal station to manage this token.
     * @return The address of the newly created token.
     */
    function createToken(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_,
        address operator_,
        address payable treasury_,
        RemoteCarbonStation station_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        bytes memory initializer = abi.encodeWithSelector(
            RemoteCarbonToken(address(0)).initialize.selector,
            name_, symbol_, details_, accessList_, operator_, treasury_, station_
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {BeaconProxy} from '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

/**
 * @author Flowcarbon LLC
 * @title Factory Base-Contract
 */
abstract contract AbstractFactory is
        AccessControlUpgradeable,
        UUPSUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted after the implementation contract has been swapped.
     * @param blueprint - The address of the new implementation contract.
     */
    event BlueprintAdded(address indexed blueprint);

    /**
     * @notice Emitted after a new token has been created by this factory.
     * @param instance - The address of the freshly deployed contract.
     */
    event InstanceCreated(address indexed instance);

    // ================
    // Public Constants
    // ================

    /**
     * @notice Operator role for access control.
     * @dev Operators take care of day-to-day operations in the protocol.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    // =================
    // Public Properties
    // =================

    /** @dev Discoverable blueprints that can be deployed by this factory. */
    mapping (uint => address) public blueprints;

    // ===================
    // Private Prooperties
    // ===================

    /** @dev Discoverable blueprints that can be deployed by this factory. */
    EnumerableSetUpgradeable.UintSet private _blueprintIds;

    /** @dev Discoverable contracts that have been deployed by this factory. */
    EnumerableSetUpgradeable.AddressSet private _instances;

    /** @dev Discoverable contracts that have been deployed by this factory. */
    mapping (address => uint) private _instanceIds;

    // ========================
    // Initialization Functions
    // ========================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @notice The number of contracts deployed by this factory. */
    function blueprintIdCount() public view returns (uint256) {
        return _blueprintIds.length();
    }

    /**
     * @notice Get the blueprint ID at the given index.
     * @param index_ - Index into the set.
     */
    function blueprintIdAt(uint index_) public view returns (uint) {
        return _blueprintIds.at(index_);
    }

    /**
     * @notice Get the blueprint at the given index.
     * @param index_ - Index into the set.
     */
    function blueprintAt(uint index_) public view returns (address) {
        return blueprints[_blueprintIds.at(index_)];
    }

    /**
     * @notice Get the blueprint used to create the given instance.
     * @param instance_ - The instance address.
     */
    function blueprintIdOf(address instance_) public view returns (uint) {
        return _instanceIds[instance_];
    }

    /**
     * @notice Get the blueprint with the given ID.
     * @dev id_ - The ID of the blueprint.
     */
    function blueprintById(uint id_) public view returns (address) {
        return blueprints[id_];
    }

    /** @notice The number of contracts deployed by this factory. */
    function instanceCount() external view returns (uint256) {
        return _instances.length();
    }

    /**
     * @notice Check if a contract as been released by this factory.
     * @param address_ - The address of the contract.
     * @return Whether this contract has been deployed by this factory.
     */
    function hasInstanceAt(address address_) external view returns (bool) {
        return _instances.contains(address_);
    }

    /**
     * @notice The contract instance deployed at a specific index.
     * @dev The ordering may change upon adding/removing instances.
     * @param index_ - The index into the set.
     */
    function instanceAt(uint256 index_) external view returns (address) {
        return _instances.at(index_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Add a blueprint to the set of deployable contracts.
     * @param blueprintId_ - The ID of blueprint.
     * @param blueprint_ - The contract to be used from now on.
     */
    function addBlueprint(uint blueprintId_, address blueprint_) public onlyRole(OPERATOR_ROLE) returns (bool) {
        require(blueprintId_ != 0,
            'AbstractFactory: blueprint id can not be 0');
        bool result = _blueprintIds.add(blueprintId_);
        blueprints[blueprintId_] = blueprint_;
        emit BlueprintAdded(blueprint_);
        return result;
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), 'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE, 'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /**
     * @dev Create a new contract instance.
     * @param blueprintId_ - The id of the blueprint/beacon to use.
     * @param initializer_ - Initialization calldata.
     * @return The address of the created beacon-proxy.
     */
    function _createBeaconProxy(uint blueprintId_, bytes memory initializer_) internal returns (address) {
        require(blueprintById(blueprintId_) != address(0),
            'AbstractFactory: invalid blueprint');

        address instance = address(new BeaconProxy(blueprintById(blueprintId_), initializer_));
        _instances.add(instance);
        _instanceIds[instance] = blueprintId_;
        emit InstanceCreated(instance);
        return instance;
    }

    /** See UUPSUpgradeable. */
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(OPERATOR_ROLE) {}
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Access-List Contract
 */
contract CarbonAccessList is AccessControlUpgradeable, UUPSUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when an operator changes the access-list.
     * @param account - The account for which permissions have changed.
     * @param hasAccess - Flag indicating whether access was granted or revoked.
     * @param isGlobal - Flag indicating whether the permission is local or multi-chain enabled.
     */
    event AccessChanged(address indexed account, bool hasAccess, bool isGlobal);

    // ================
    // Public Constants
    // ================

    /** @notice Operator role for access control. */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    // =================
    // Public Properties
    // =================

    /** @dev The protocol-internal name given to the access-list. */
    string public name;

    /** @notice The factory that produced this contract. */
    address public factory;

    // ==================
    // Private Properties
    // ==================

    /** @dev Set of globally privileged addresses. */
    EnumerableSetUpgradeable.AddressSet private _globalAddresses;

    /** @dev Set of locally privileged addresses. */
    EnumerableSetUpgradeable.AddressSet private _localAddresses;

    mapping (uint256 => EnumerableSetUpgradeable.AddressSet) private _remoteAddresses;

    // ========================
    // Initialization Functions
    // ========================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev Initialize proxy pattern. */
    function initialize(string memory name_, address operator_, address factory_) external initializer {
        require(bytes(name_).length > 0,
            'CarbonAccessList: name is required');
        require(operator_ != address(0),
            'CarbonAccessList: operator is required');
        require(factory_ != address(0),
            'CarbonAccessList: factory is required');
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, factory_);
        name = name_;
        factory = factory_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @dev Check if the given address has global access. */
    function hasGlobalAccess(address account_) external view virtual returns (bool) {
        return _globalAddresses.contains(account_);
    }

    /** @dev Get the global address at the given index. */
    function globalAddressAt(uint256 index_) external view virtual returns (address) {
        return _globalAddresses.at(index_);
    }

    /** @dev Get the total number of global addresses. */
    function globalAddressCount() external view virtual returns (uint256) {
        return _globalAddresses.length();
    }

    /** @dev Get the full set of addresses with global access. */
    function globalAddresses() external view virtual returns (address[] memory) {
        return _globalAddresses.values();
    }

    /** @dev Check if the given address has local access. */
    function hasLocalAccess(address account_) external view virtual returns (bool) {
        return _localAddresses.contains(account_);
    }

    /** @dev Get the total number of local addresses. */
    function localAddressCount() external view virtual returns (uint256) {
        return _localAddresses.length();
    }

    /** @dev Get the local address at the given index. */
    function localAddressAt(uint256 index_) external view virtual returns (address) {
        return _localAddresses.at(index_);
    }

    /** @dev Get the full set of addresses with local access. */
    function localAddresses() external view virtual returns (address[] memory) {
        return _localAddresses.values();
    }

    /** @dev Check if the given address has either local or global access. */
    function hasAccess(address account_) external view virtual returns (bool) {
        return _globalAddresses.contains(account_) || _localAddresses.contains(account_);
    }

    /** @dev Check if the given address has remote access on the given destination. */
    function hasRemoteAccess(uint chainId_, address account_) external view virtual returns (bool) {
        EnumerableSetUpgradeable.AddressSet storage addresses = _remoteAddresses[chainId_];
        return addresses.contains(account_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Set the global access status of the given address. */
    function setGlobalAccess(address account_, bool hasAccess_) public virtual onlyRole(OPERATOR_ROLE) {
        require(account_ != address(0),
            'CarbonAccessList: account is required');
        require(!hasAccess_ || (hasAccess_ && account_.code.length == 0),
            'CarbonAccessList: attempt to add smart-contract to global address set');

        bool changed;
        if (hasAccess_) {
            changed = _globalAddresses.add(account_);
        } else {
            changed = _globalAddresses.remove(account_);
        }
        if (changed) {
            emit AccessChanged(account_, hasAccess_, true);
        }
    }

    /** @dev Set global access status in batch. */
    function setGlobalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) external virtual onlyRole(OPERATOR_ROLE) {
        require(accounts_.length == permissions_.length, 'accounts and permissions must have the same length');
        for (uint256 i=0; i < accounts_.length; i++) {
            setGlobalAccess(accounts_[i], permissions_[i]);
        }
    }

    /** @dev Set the local access status of the given address. */
    function setLocalAccess(address account_, bool hasAccess_) public virtual onlyRole(OPERATOR_ROLE) {
        require(account_ != address(0),
            'CarbonAccessList: account is required');

        bool changed;
        if (hasAccess_) {
            changed = _localAddresses.add(account_);
        } else {
            changed = _localAddresses.remove(account_);
        }
        if (changed) {
            emit AccessChanged(account_, hasAccess_, false);
        }
    }

    /** @dev Set local access status in batch. */
    function setLocalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) external virtual onlyRole(OPERATOR_ROLE) {
        require(accounts_.length == permissions_.length,
            'CarbonAccessList: accounts and permissions must have the same length');

        for (uint256 i=0; i < accounts_.length; i++) {
            setLocalAccess(accounts_[i], permissions_[i]);
        }
    }

    /** @dev Set the remote access status of the address for the given destination. */
    function setRemoteAccess(uint chainId_, address account_, bool hasAccess_) public virtual onlyRole(OPERATOR_ROLE) {
        require(account_ != address(0),
            'CarbonAccessList: account is required');

        EnumerableSetUpgradeable.AddressSet storage addresses = _remoteAddresses[chainId_];
        bool changed;
        if (hasAccess_) {
            changed = addresses.add(account_);
        } else {
            changed = addresses.remove(account_);
        }
        if (changed) {
            emit AccessChanged(account_, hasAccess_, true);
        }
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev See UUPSUpgradeable. */
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(OPERATOR_ROLE) {}
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractBaseCarbonToken} from './abstracts/AbstractBaseCarbonToken.sol';
import {CarbonBundleTokenFactory} from './CarbonBundleTokenFactory.sol';
import {CarbonAccessList} from './CarbonAccessList.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Token Contract
 */
contract CarbonToken is AbstractBaseCarbonToken {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when the access-list is renounced.
     * @param accessList - The address of the renounced access-list.
     */
    event AccessListRenounced(address indexed accessList);

    /**
     * @notice Emitted when access-list changes.
     * @param oldList - The address of the old access-list.
     * @param newList - The address of the new access-list.
     */
    event AccessListChanged(address indexed oldList, address indexed newList);

    /**
     * @notice Emitted when new tokens have been minted.
     * @dev The account can be found in the Transfer event and is thus omitted here.
     * @param amount - The amount of tokens that have been minted.
     * @param checksum - The checksum associated with the backing registry entry.
     */
    event Mint(uint256 amount, bytes32 checksum);

    // =================
    // Member Structures
    // =================

    /** @notice The details of a token determine its fungibility. */
    struct TokenDetails {
        // The registry holding the backing carbon credits (e.g. VERRA).
        string registry;
        // The standard used during certification (e.g. VERIFIED_CARBON_STANDARD).
        string standard;
        // The credit type of the token (e.g. AGRICULTURE_FORESTRY_AND_OTHER_LAND_USE).
        string creditType;
        // The year in which the carbon was sequestered.
        uint16 vintage;
    }

    // =================
    // Public Properties
    // =================

    /** @notice The access-list associated with the token. */
    CarbonAccessList public accessList;

    /** @notice The bundle token factory associated with the token. */
    CarbonBundleTokenFactory public bundleFactory;

    /** @notice Number of tokens that have been moved off the blockchain. */
    uint256 public movedOffChain;

    // ==================
    // Private Properties
    // ==================

    /** @notice Token details/metadata. */
    CarbonToken.TokenDetails private _details;

    /** @notice Mapping of registry event checksums to the number of tokens minted. */
    mapping (bytes32 => uint256) private _mintedAmounts;

    /** @notice Mapping of registry event checksums to the number of tokens offsettet. */
    mapping (bytes32 => uint256) private _offsetAmounts;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_,
        address operator_,
        address payable treasury_,
        address bundleFactory_
    ) external initializer {
        require(details_.vintage >= 2000,
            'CarbonToken: vintage out of bounds');
        require(details_.vintage < 2100,
            'CarbonToken: vintage out of bounds');
        require(bytes(details_.registry).length > 0,
            'CarbonToken: registry is required');
        require(bytes(details_.standard).length > 0,
            'CarbonToken: standard is required');
        require(bytes(details_.creditType).length > 0,
            'CarbonToken: credit type is required');
        require(address(bundleFactory_) != address(0),
            'CarbonToken: bundle factory is required');

        AbstractBaseCarbonToken.initialize(name_, symbol_, operator_, treasury_);
        _details = details_;
        accessList = accessList_;
        bundleFactory = CarbonBundleTokenFactory(bundleFactory_);
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @notice The registry holding the underlying credits (e.g. VERRA or GOLDSTANDARD). */
    function registry() external view virtual returns (string memory) {
        return _details.registry;
    }

    /** @notice The standard of this token (e.g. VERIFIED_CARBON_STANDARD). */
    function standard() external view virtual returns (string memory) {
        return _details.standard;
    }

    /** @notice The creditType of this token (e.g. WETLAND_RESTORATION or REFORESTATION). */
    function creditType() external view virtual returns (string memory) {
        return _details.creditType;
    }

    /** @notice The guaranteed vintage of this token - newer is always better :-). */
    function vintage() external view virtual returns (uint16) {
        return _details.vintage;
    }

    /**
     * @notice Get the amount of tokens minted with the given checksum.
     * @param checksum_ - The checksum associated with a minting event.
     * @return The amount minted with the associated checksum.
     */
    function getMintedAmountByChecksum(bytes32 checksum_) external view virtual returns (uint256) {
        return _mintedAmounts[checksum_];
    }

    /**
     * @notice Get the amount of tokens offsetted with the given checksum.
     * @param checksum_ - The checksum of the associated registry event.
     * @return The amount of tokens that have been offsetted with this checksum.
     */
    function getOffsetByChecksum(bytes32 checksum_) external view virtual returns (uint256) {
        return _offsetAmounts[checksum_];
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Mints new tokens in association with a registry event checksum.
     * @param account_ - The account that will receive the new tokens.
     * @param amount_ - The amount of tokens to be minted.
     * @param checksum_ - The checksum of the associated registry event.
     */
    function mint(address account_, uint256 amount_, bytes32 checksum_) external virtual onlyRole(TOKENIZER_ROLE) returns (bool) {
        require(checksum_ != 0,
            'CarbonToken: checksum is required');
        require(_mintedAmounts[checksum_] == 0,
            'CarbonToken: checksum already used');

        _mint(account_, amount_);
        _mintedAmounts[checksum_] = amount_;
        emit Mint(amount_, checksum_);
        return true;
    }

    /**
     * @notice Burn tokens and perform the required bookeeping.
     * @param amount_ - The amount of tokens to burn.
     */
    function burn(uint256 amount_) public virtual {
        require(hasRole(TOKENIZER_ROLE, _msgSender()) || bundleFactory.hasInstanceAt(_msgSender()),
            'CarbonToken: sender is not allowed to burn');
        _burn(_msgSender(), amount_);
        if (hasRole(TOKENIZER_ROLE, _msgSender())) {
            movedOffChain += amount_;
        }
    }

    /**
     * @notice Once the actual carbon offsets are retired, the offsetting process can be finalized on-chain.
     *         Operators provide a checksum for the audit-trail.
     * @param amount_ - The number of token to finalize offsetting.
     * @param checksum_ - The checksum associated with the registry offset event.
     */
    function finalizeOffset(uint256 amount_, bytes32 checksum_) external virtual onlyRole(TOKENIZER_ROLE) returns (bool) {
        require(checksum_ != 0,
            'CarbonToken: checksum is required');
        require(_offsetAmounts[checksum_] == 0,
            'CarbonToken: checksum already used');
        require(amount_ <= incompleteOffsetBalance,
            'CarbonToken: amount exceeds incomplete offset balance');

        _offsetAmounts[checksum_] = amount_;
        incompleteOffsetBalance -= amount_;
        offsetBalance += amount_;

        // Yay, real-world carbon was removed from the atmosphere <3
        emit OffsetFinalized(amount_, checksum_);
        return true;
    }

    /**
     * @notice Set the access-list.
     * @param accessList_ - The access-list to use.
     */
    function setAccessList(CarbonAccessList accessList_) external virtual onlyRole(OPERATOR_ROLE) {
        require(address(accessList) != address(0),
            'CarbonToken: invalid attempt at changing the access-list');
        require(address(accessList_) != address(0),
            'CarbonToken: invalid attempt at renouncing the access-list');
        address oldAccessListAddress = address(accessList);
        accessList = accessList_;
        emit AccessListChanged(oldAccessListAddress, address(accessList_));
    }

    /**
     * @notice Renounce the access-list, making this token accessible to everyone
     *         NOTE: This operation is *irreversible* and will leave the token permanently non-permissioned!
     */
    function renounceAccessList() external virtual onlyRole(OPERATOR_ROLE) {
        accessList = CarbonAccessList(address(0));
        emit AccessListRenounced(address(this));
    }

    // ==================
    // Internal Functions
    // ==================

    /**
     * @notice Override ERC20.transfer to respect access-lists.
     * @param from_ - The senders address.
     * @param to_ - The recipients address.
     * @param amount_ - The amount of tokens to send.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(accessList) != address(0)) {
            require(accessList.hasAccess(from_),
                'CarbonToken: the sender is not allowed to transfer this token');
            require(accessList.hasAccess(to_),
                'CarbonToken: the recipient is not allowed to receive this token');
        }
        return super._transfer(from_, to_, amount_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {CarbonAccessList} from '../../CarbonAccessList.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import {AbstractRemoteBaseCarbonToken} from '../abstracts/AbstractRemoteBaseCarbonToken.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon Token Contract
 */
contract RemoteCarbonToken is AbstractRemoteBaseCarbonToken {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when a token renounces its access-list.
     * @param accessList - The address of the renounced access-list.
     */
    event AccessListRenounced(address indexed accessList);

    /**
     * @notice Emitted when the access-list changes.
     * @param oldList - The address of the old access-list.
     * @param newList - The address of the new access-list.
     */
    event AccessListChanged(address indexed oldList, address indexed newList);

    /**
     * @notice Emitted when new tokens have been minted.
     * @dev The account can be found in the Transfer event and is thus omitted here.
     * @param amount - The amount of tokens that have been minted.
     * @param checksum - The checksum associated with the backing registry entry.
     */
    event Mint(uint256 amount, bytes32 checksum);

    /**
     * @notice Emitted when offsets are processed.
     * @param account - The account credited with the offsets.
     * @param amount - The amount of tokens that have been offsetted.
     */
    event RemoteOffsetIncreased(address indexed account, uint256 amount);

    // ===================
    // Private Properties
    // ===================

    /** @notice The access-list associated with this token. */
    CarbonAccessList public accessList;

    /** @notice Token metadata. */
    CarbonToken.TokenDetails private _details;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_,
        address operator_,
        address payable treasury_,
        RemoteCarbonStation station_
    ) external initializer {
        AbstractRemoteBaseCarbonToken.initialize(name_, symbol_, operator_, treasury_, station_);
        _details = details_;
        accessList = accessList_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @notice The registry holding the underlying credits (e.g. VERRA). */
    function registry() external view virtual returns (string memory) {
      return _details.registry;
    }

    /** @notice The standard of this token (e.g. VERIFIED_CARBON_STANDARD). */
    function standard() external view virtual returns (string memory) {
        return _details.standard;
    }

    /** @notice The credit type of this token (e.g. AGRICULTURE_FORESTRY_AND_OTHER_LAND_USE). */
    function creditType() external view virtual returns (string memory) {
        return _details.creditType;
    }

    /** @notice The guaranteed vintage of this token - newer is always better :-) */
    function vintage() external view virtual returns (uint16) {
        return _details.vintage;
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Set the access-list.
     * @dev Since this may only be invoked by contracts, there is no dedicated renounce function.
     * @param accessList_ - The access-list to use.
     */
    function setAccessList(CarbonAccessList accessList_) external virtual onlyRole(OPERATOR_ROLE) {
        address oldList = address(accessList);
        address newList = address(accessList_);

        if (oldList == newList) {
            return;
        } else if (newList != address(0)) {
            accessList = accessList_;
            emit AccessListChanged(oldList, newList);
        } else {
            accessList = CarbonAccessList(address(0));
            emit AccessListRenounced(oldList);
        }
    }

    /**
     * @notice Increase the local offset balance.
     * @param account_ - The account that is credited with the offset.
     * @param amount_ - The amount of tokens that have been offset.
     */
    function increaseOffset(address account_, uint256 amount_) external virtual onlyRole(TOKENIZER_ROLE) {
        // We mint to the terminal station to simplify bookkeeping
        _mint(_msgSender(), amount_);
        _offset(account_, amount_);

        // The balance is already processed to the central network
        incompleteOffsetBalance -= amount_;
        emit RemoteOffsetIncreased(account_, amount_);
    }

    // ==================
    // Internal Functions
    // ==================

    /**
     * @notice Override ERC20.transfer to respect access-lists.
     * @param from_ - The senders address.
     * @param to_ - The recipients address.
     * @param amount_ - The amount of tokens to send.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(accessList) != address(0)) {
            require(accessList.hasAccess(from_),
                'RemoteCarbonToken: the sender is not allowed to transfer this token');
            require(accessList.hasAccess(to_),
                'RemoteCarbonToken: the recipient is not allowed to receive this token');
        }
        return super._transfer(from_, to_, amount_);
    }

    /** @dev See parent. */
    function _processOffsets(uint256 amount_) internal virtual override {
        station.processOffsets{value: msg.value}(this, amount_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {ERC1967Proxy} from '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import {CarbonToken} from '../CarbonToken.sol';
import {CarbonAccessList} from '../CarbonAccessList.sol';
import {CarbonAccessListFactory} from '../CarbonAccessListFactory.sol';
import {AbstractCarbonStation} from './abstracts/AbstractCarbonStation.sol';
import {AbstractRemoteBaseCarbonToken} from './abstracts/AbstractRemoteBaseCarbonToken.sol';
import {RemoteCarbonBundleTokenFactory} from './remote/RemoteCarbonBundleTokenFactory.sol';
import {RemoteCarbonBundleToken} from './remote/RemoteCarbonBundleToken.sol';
import {RemoteCarbonToken} from './remote/RemoteCarbonToken.sol';
import {RemoteCarbonTokenFactory} from './remote/RemoteCarbonTokenFactory.sol';
import {RemoteCarbonSender} from './remote/RemoteCarbonSender.sol';
import {RemoteCarbonReceiver} from './remote/RemoteCarbonReceiver.sol';
import {CentralCarbonReceiver} from './central/CentralCarbonReceiver.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon Station Contract
 */
contract RemoteCarbonStation is AbstractCarbonStation {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when bundle offsets are forwarded to the central chain for processing.
     * @param bundle - The bundle that has been offsettet.
     * @param amount - The amount that has been offsettet.
     */
    event BundleOffsetsProcessed(address indexed bundle, uint256 amount);

    /**
     * @notice Emitted when token offsets are forwarded to the central chain for processing.
     * @param token - The token that has been offsettet.
     * @param amount - The amount that has been offsettet.
     */
    event OffsetsProcessed(address indexed token, uint256 amount);

    // =========
    // Modifiers
    // =========

    /** @dev Allows access only to token contracts. */
    modifier onlyTokens() {
        require(
            tokenFactory.hasInstanceAt(_msgSender()) || bundleFactory.hasInstanceAt(_msgSender()),
            'RemoteCarbonStation: caller is not known to protocol'
        );
        _;
    }

    // =================
    // Public Properties
    // =================

    /** @notice Chain ID of the central network. */
    uint256 public centralChainId;

    /** @notice Operator account passed to newly created instances. */
    address public operator;

    /** @notice Factory for remote GCO2 tokens. */
    RemoteCarbonTokenFactory public tokenFactory;

    /** @notice Factory for remote bundle tokens. */
    RemoteCarbonBundleTokenFactory public bundleFactory;

    /** @notice Access-list factory. */
    CarbonAccessListFactory public accessListFactory;

    /** @notice Map of local bundle addresses to central bundle addresses. */
    mapping (address => address) public localToCentralBundles;

    /** @notice Map of central bundle addresses to local bundle addresses. */
    mapping (address => address) public centralToLocalBundles;

    /** @notice Map of local GCO2 addresses to central GCO2 addresses. */
    mapping (address => address) public localToCentralTokens;

    /** @notice Map of central GCO2 addresses to local GCO2 addresses. */
    mapping (address => address) public centralToLocalTokens;

    /** @notice Map of local access-list addresses to central access-list addresses. */
    mapping (address => address) public localToCentralAccessLists;

    /** @notice Map of central access-list addresses to local access-list addresses. */
    mapping (address => address) public centralToLocalAccessLists;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        uint256 chainId_,
        uint256 centralChainId_,
        RemoteCarbonTokenFactory tokenFactory_,
        RemoteCarbonBundleTokenFactory bundleFactory_,
        CarbonAccessListFactory accessListFactory_,
        address operator_,
        address payable treasury_
    ) public initializer {
        require(centralChainId_ != 0,
            'RemoteCarbonStation: central chain id is required');
        require(address(tokenFactory_) != address(0),
            'RemoteCarbonStation: token factory is required');
        require(address(bundleFactory_) != address(0),
            'RemoteCarbonStation: bundle factory is required');
        require(address(accessListFactory_) != address(0),
            'RemoteCarbonStation: access-list factory is required');

        AbstractCarbonStation.initialize(
            chainId_,
            operator_,
            treasury_
        );

        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
        centralChainId = centralChainId_;
        operator = operator_;

        ERC1967Proxy tokenFactoryProxy = new ERC1967Proxy(
            address(tokenFactory_),
            abi.encodeWithSelector(
                RemoteCarbonTokenFactory(address(0)).initialize.selector,
                address(this)
            )
        );
        tokenFactory = RemoteCarbonTokenFactory(address(tokenFactoryProxy));
        tokenFactory.grantRole(tokenFactory.DEFAULT_ADMIN_ROLE(), operator_);
        tokenFactory.grantRole(tokenFactory.OPERATOR_ROLE(), operator_);

        ERC1967Proxy bundleFactoryProxy = new ERC1967Proxy(
            address(bundleFactory_),
            abi.encodeWithSelector(
                RemoteCarbonBundleTokenFactory(address(0)).initialize.selector,
                address(this)
            )
        );
        bundleFactory = RemoteCarbonBundleTokenFactory(address(bundleFactoryProxy));
        bundleFactory.grantRole(bundleFactory.DEFAULT_ADMIN_ROLE(), operator_);
        bundleFactory.grantRole(bundleFactory.OPERATOR_ROLE(), operator_);

        ERC1967Proxy accessListFactoryProxy = new ERC1967Proxy(
            address(accessListFactory_),
            abi.encodeWithSelector(
                CarbonAccessListFactory(address(0)).initialize.selector,
                address(this)
            )
        );
        accessListFactory = CarbonAccessListFactory(address(accessListFactoryProxy));
        accessListFactory.grantRole(accessListFactory.DEFAULT_ADMIN_ROLE(), operator_);
        accessListFactory.grantRole(accessListFactory.OPERATOR_ROLE(), operator_);
    }

    // ================
    // Public Functions
    // ================

    /**
     * @notice Reverts if the given bundle address is not known to the protocol.
     * @param bundle_ - The address of the bundle.
     */
    function getBundle(address bundle_) external view returns (RemoteCarbonBundleToken) {
        require(bundleFactory.hasInstanceAt(bundle_),
            'RemoteCarbonStation: bundle not registered');
        return RemoteCarbonBundleToken(bundle_);
    }

    /**
     * @notice Reverts if the given token address is not known to the protocol.
     * @param token_ - The address of the token.
     */
    function getToken(address token_) external view returns (RemoteCarbonToken) {
        require(tokenFactory.hasInstanceAt(token_),
            'RemoteCarbonStation: token not registered');
        return RemoteCarbonToken(token_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Set the initial operator for remote instances. */
    function setOperator(address operator_) external onlyRole(OPERATOR_ROLE) {
        require(operator_ != address(0),
            'RemoteCarbonStation: operator is required');
        operator = operator_;
    }

    // ==================
    // Protocol Functions
    // ==================

    /** @dev Wrapper for access-control. */
    function createToken(
        uint blueprintId_,
        address token_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_
    ) external onlyRole(TRANSMITTER_ROLE) returns (RemoteCarbonToken){
        RemoteCarbonToken token = RemoteCarbonToken(tokenFactory.createToken(
            blueprintId_,
            name_,
            symbol_,
            details_,
            accessList_,
            operator,
            treasury,
            this
        ));
        localToCentralTokens[address(token)] = token_;
        centralToLocalTokens[token_] = address(token);
        return token;
    }

    /** @dev Wrapper for access-control. */
    function mint(
        AbstractRemoteBaseCarbonToken token_,
        address account_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.mint(account_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function burn(
        AbstractRemoteBaseCarbonToken token_,
        address account_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.burn(account_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function setAccessList(
        RemoteCarbonToken token_,
        CarbonAccessList accessList
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.setAccessList(accessList);
    }

    /** @dev Wrapper for access-control. */
    function increaseOffset(
        RemoteCarbonToken token_,
        address beneficiary_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.increaseOffset(beneficiary_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function updateVintage(
        RemoteCarbonBundleToken rBundle,
        uint16 vintage_
    ) external onlyRole(TRANSMITTER_ROLE) {
        rBundle.updateVintage(vintage_);
    }

    /** @dev Wrapper for access-control. */
    function createBundle(
        uint blueprintId_,
        address bundle_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_
    ) external onlyRole(TRANSMITTER_ROLE) returns (RemoteCarbonBundleToken) {
        RemoteCarbonBundleToken rBundle = RemoteCarbonBundleToken(bundleFactory.createBundle(
            blueprintId_,
            name_,
            symbol_,
            vintage_,
            operator,
            treasury,
            this
        ));
        localToCentralBundles[address(rBundle)] = bundle_;
        centralToLocalBundles[bundle_] = address(rBundle);
        return rBundle;
    }

    /** @dev Wrapper for access-control. */
    function registerTokenForBundle(
        RemoteCarbonBundleToken bundle_,
        RemoteCarbonToken token_,
        bool isAdded_,
        bool isPaused_
    ) external onlyRole(TRANSMITTER_ROLE) {
        bundle_.setPausedForBundle(token_, isPaused_);
        if (isAdded_) {
            bundle_.addToken(token_);
        } else {
            bundle_.removeToken(token_);
        }
    }

    /** @dev Wrapper for access-control. */
    function createAccessList(
        uint blueprintId_,
        address accessList_,
        string memory name_
    ) external onlyRole(TRANSMITTER_ROLE) returns (CarbonAccessList) {
        CarbonAccessList accessList = CarbonAccessList(accessListFactory.createAccessList(
            blueprintId_, name_, address(this)
        ));
        accessList.grantRole(accessList.DEFAULT_ADMIN_ROLE(), operator);
        accessList.grantRole(accessList.OPERATOR_ROLE(), operator);

        localToCentralAccessLists[address(accessList)] = accessList_;
        centralToLocalAccessLists[accessList_] = address(accessList);

        accessList.setLocalAccess(address(this), true);
        accessList.setLocalAccess(sender, true);
        return accessList;
    }

    /** @dev Wrapper for access-control. */
    function setGlobalAccess(
        CarbonAccessList accessList_,
        address account_,
        bool hasAccess_
    ) external onlyRole(TRANSMITTER_ROLE) {
        accessList_.setGlobalAccess(account_, hasAccess_);
    }

    /** @dev Wrapper for access-control. */
    function processBundleOffsets(
        RemoteCarbonBundleToken bundle_,
        uint256 amount_
    ) external onlyTokens payable {
        _send(
            centralChainId,
            abi.encodeWithSelector(
              CentralCarbonReceiver.handleProcessOffsets.selector,
              _getMessageTrace(msg.sender, msg.data),
              localToCentralBundles[address(bundle_)],
              amount_
            )
        );

        emit BundleOffsetsProcessed(address(bundle_), amount_);
    }

    /** @dev Send GCO2 offsets to the main chain for processing. */
    function processOffsets(
        RemoteCarbonToken token_,
        uint256 amount_
    ) external onlyTokens payable {
        _send(
            centralChainId,
            abi.encodeWithSelector(
              CentralCarbonReceiver.handleProcessOffsets.selector,
              _getMessageTrace(msg.sender, msg.data),
              localToCentralTokens[address(token_)],
              amount_
            )
        );

        emit BundleOffsetsProcessed(address(token_), amount_);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev For tracing blocks accross chains. */
    function _getMessageTrace(address sender_, bytes memory data_) private view returns (bytes32) {
        return sha256(abi.encodePacked(block.number, chainId, sender_, data_));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
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
interface IERC1822Proxiable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
library StorageSlot {
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

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {IBaseCarbonToken} from '../interfaces/IBaseCarbonToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Token Base-Contract
 */
abstract contract AbstractBaseCarbonToken is
        IBaseCarbonToken,
        AccessControlUpgradeable,
        ERC20Upgradeable,
        UUPSUpgradeable {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when someone offsets carbon tokens.
     * @param account - The account credited with offsetting.
     * @param amount - The amount of carbon that was offset.
     */
    event Offset(address indexed account, uint256 amount);

    /**
     * @notice This event is emitted when bridge operators have retired the underlying carbon credits.
     * @param amount - The amount of tokens offset.
     * @param checksum - The checksum associated with the offset event.
     */
    event OffsetFinalized(uint256 amount, bytes32 checksum);

    /**
     * @notice Emitted when the treasury has changed.
     * @param treasury - The new treasury address.
     */
    event TreasuryChanged(address indexed treasury);

    // ================
    // Public Constants
    // ================

    /** @dev Operators take care of day-to-day operations in the protocol. */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    /** @dev Tokenizers are allowed to mint and burn carbon tokens. */
    bytes32 public constant TOKENIZER_ROLE = keccak256('TOKENIZER_ROLE');

    // =================
    // Member Structures
    // =================

    /** @notice The time and amount of a specific offsetting event. */
    struct OffsetEntry {
        uint time;
        uint amount;
    }

    // =================
    // Public Properties
    // =================

    /** @notice Number of tokens that have been offset off-chain and on-chain. */
    uint256 public offsetBalance;

    /** @notice The address of our treasury contract. */
    address payable public treasury;

    /** @notice Number of tokens offset by the protocol that have not been finalized off-chain. */
    uint256 public incompleteOffsetBalance;

    // ==================
    // Private Properties
    // ==================

    /** @dev Mapping of user to offsets to make them discoverable. */
    mapping (address => OffsetEntry[]) private _offsetEntries;

    /** @notice Mapping of user addresses to the amount of tokens offsetted. */
    mapping (address => uint256) internal _offsetBalances;

    // ========================
    // Initialization Functions
    // ========================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        address operator_,
        address payable treasury_
    ) internal onlyInitializing {
        require(bytes(name_).length != 0,
            'AbstractBaseCarbonToken: name is required');
        require(bytes(symbol_).length != 0,
            'AbstractBaseCarbonToken: symbol is required');
        require(operator_ != address(0),
            'AbstractBaseCarbonToken: operator is required');
        require(treasury_ != address(0),
            'AbstractBaseCarbonToken: treasury is required');
        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
        _grantRole(TOKENIZER_ROLE, operator_);
        treasury = treasury_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @dev See ICarbonToken. */
    function offsetCountOf(address address_) external view returns (uint256) {
        return _offsetEntries[address_].length;
    }

    /** @dev See ICarbonToken. */
    function offsetAmountAt(address address_, uint256 index_) external view returns(uint256) {
        return _offsetEntries[address_][index_].amount;
    }

    /** @dev See ICarbonToken. */
    function offsetTimeAt(address address_, uint256 index_) external view returns(uint256) {
        return _offsetEntries[address_][index_].time;
    }

    /** @dev See ICarbonToken. */
    function offsetBalanceOf(address account_) external view returns (uint256) {
        return _offsetBalances[account_];
    }

    // ================
    // Public Functions
    // ================

    /** @dev See ICarbonToken. */
    function offsetOnBehalfOf(address account_, uint256 amount_) external {
        _offset(account_, amount_);
    }

    /** @dev See ICarbonToken. */
    function offset(uint256 amount_) external {
        _offset(_msgSender(), amount_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Set the treasury. */
    function setTreasury(address payable treasury_) external onlyRole(OPERATOR_ROLE) {
        require(treasury_ != address(0),
            'AbstractBaseCarbonToken: treasury is required');
        treasury = treasury_;
        emit TreasuryChanged(treasury_);
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), 'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE, 'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev See UUPSUpgradeable. */
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(OPERATOR_ROLE) {}

    /** @dev Common functionality of the two offset functions. */
    function _offset(address account_, uint256 amount_) internal {
        _burn(_msgSender(), amount_);
        _offsetBalances[account_] += amount_;
        incompleteOffsetBalance += amount_;
        _offsetEntries[account_].push(OffsetEntry(block.timestamp, amount_));

        // Thank you for offsetting with us :)
        emit Offset(account_, amount_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractFactory} from './abstracts/AbstractFactory.sol';
import {CarbonFeeMaster} from './CarbonFeeMaster.sol';
import {CarbonBundleToken} from './CarbonBundleToken.sol';
import {CarbonToken} from './CarbonToken.sol';
import {CarbonTokenFactory} from './CarbonTokenFactory.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Bundle-Token Factory Contract
 */
contract CarbonBundleTokenFactory is AbstractFactory {

    // =================
    // Public Properties
    // =================

    /** @notice The associated token factory. */
    CarbonTokenFactory public tokenFactory;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        require(operator_ != address(0),
            'CarbonAccessListFactory: operator is required');
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new bundle.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The name of the bundle, should be unique within the ecosystem.
     * @param symbol_ - The symbol of the ERC-20, should be unique within the ecosystem.
     * @param vintage_ - The minimum vintage requirement of the bundle.
     * @param tokens_ - Initial set of tokens in the bundle.
     * @param feePoints_ - The fee in basis points taken on unbundling.
     * @param operator_ - The account that is granted operator privileges.
     * @param treasury_ - The addres of the carbon treasury.
     * @return The address of the newly created bundle instance.
     */
    function createBundle(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        uint256 feePoints_,
        address operator_,
        address payable treasury_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        require(address(tokenFactory) != address(0),
            'CarbonBundleTokenFactory: token factory not set');
        bytes memory initializer = abi.encodeWithSelector(
            CarbonBundleToken(address(0)).initialize.selector,
            name_, symbol_, vintage_, tokens_, feePoints_, operator_, address(this), treasury_, tokenFactory
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }

    /**
     * @notice Set the token factory which is passed to bundle instances.
     * @param tokenFactory_ - The token factory instance passed to new bundles.
     */
    function setTokenFactory(CarbonTokenFactory tokenFactory_) external onlyRole(OPERATOR_ROLE) {
        require(address(tokenFactory_) != address(0),
            'CarbonBundleTokenFactory: token factory is required');
        tokenFactory = tokenFactory_;
    }

    /**
     * @notice Set the fee-master for a bundle controlled by this factory.
     * @dev The conductor uses this to set the initial fee-master for new bundles.
     * @param bundle_ - The bundle on which to levy fees.
     * @param feeMaster_ - The fee-master contract.
     */
    function setFeeMaster(CarbonBundleToken bundle_, CarbonFeeMaster feeMaster_) external onlyRole(OPERATOR_ROLE) {
        require(address(bundle_) != address(0),
            'CarbonBundleTokenFactory: bundle is required');
        require(address(feeMaster_) != address(0),
            'CarbonBundleTokenFactory: fee-master is required');
        bundle_.setFeeMaster(feeMaster_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/**
 * @author Flowcarbon LLC
 * @title Base Carbon Token Interface
 */
interface IBaseCarbonToken is IERC20Upgradeable {

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice Return the balance of carbon tokens that have been offsetted by the given address.
     * @param account_ - The account for which to check the number of tokens that were offsetted.
     * @return The number of tokens offsetted by the given account.
     */
    function offsetBalanceOf(address account_) external view returns (uint256);

    /**
     * @notice Returns the number of offsets made by the given address.
     * @dev This is allows discovery of all offsets made by a user.
     * @param address_ - Address of the user that offsetted the tokens.
     */
    function offsetCountOf(address address_) external view returns(uint256);

    /**
     * @notice Returns amount of offsetted tokens for the given address and index.
     * @param address_ - Address of the user who did the offsets.
     * @param index_ - Index into the list.
     */
    function offsetAmountAt(address address_, uint256 index_) external view returns(uint256);

    /**
     * @notice Returns the timestamp of an offset for the given address and index.
     * @param address_ - Address of the user who did the offsets.
     * @param index_ - Index into the list.
     */
    function offsetTimeAt(address address_, uint256 index_) external view returns(uint256);

    // ================
    // Public Functions
    // ================

    /**
     * @notice Offset on behalf of the sender.
     * @dev This will only offset tokens sent by msg.sender, increases tokens awaiting finalization.
     * @param amount_ - The number of tokens to be offset.
     */
    function offset(uint256 amount_) external;

    /**
     * @notice Offsets on behalf of the given address.
     * @dev This will offset tokens on behalf of account, increases tokens awaiting finalization.
     * @param account_ - The address of the account to offset on behalf of.
     * @param amount_ - The number of tokens to be offsetted.
     */
    function offsetOnBehalfOf(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {CarbonTreasury} from './CarbonTreasury.sol';
import {CarbonAccessListFactory} from './CarbonAccessListFactory.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon fee-master Contract
 */
contract CarbonFeeMaster is UUPSUpgradeable, AccessControlUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when the fee settings are updated.
     * @param subject - The address subject to fees.
     * @param feePoints - The updated fee in basis points.
     */
    event FeeChanged(address indexed subject, uint256 feePoints);

    // ================
    // Public Constants
    // ================

    /** @notice Hard limit on fees in basis points (50%). */
    uint256 public constant MAX_FEE_POINTS = 5000;

    /**
     * @notice Operator role for access control.
     * @dev Operators take care of day-to-day operations in the protocol.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    // =================
    // Public Properties
    // =================

    /**
     * @notice The default fee in basis points.
     * @dev 10000bp = 100%.
     */
    uint256 public feePoints;

    // ==================
    // Private Properties
    // ==================

    /** @notice The subjects of this fee-master. */
    mapping(address => uint256) private _feePointsBySubject;

    /** @dev Internal set of carbon credit tokens that have overridden fee divisors. */
    EnumerableSetUpgradeable.AddressSet private _subjects;

    // ========================
    // Initialization Functions
    // ========================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev Initialize proxy pattern. */
    function initialize(uint256 feePoints_, address operator_) external initializer {
        require(feePoints_ <= MAX_FEE_POINTS,
            'CarbonFeeMaster: fee too high');
        require(operator_ != address(0),
            'CarbonFeeMaster: operator is required');
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
        feePoints = feePoints_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice The fee points levied on a subject.
     * @dev Falls back to `feePoints`.
     * @return The fee in basis points.
     */
    function getFeePoints(address subject_) external view virtual returns (uint256) {
        if (hasSubject(subject_)) {
            return _feePointsBySubject[subject_];
        }
        return feePoints;
    }

    /**
     * @notice Checks if the given address is a subject of this fee-master.
     * @param subject_ - The address to check.
     * @return True if the address is a subject of this fee-master.
     */
    function hasSubject(address subject_) public view virtual returns (bool) {
        return _subjects.contains(address(subject_));
    }

    /**
     * @notice Number of subjects configured fee settings.
     * @return The number of subjects.
     */
    function subjectCount() external view virtual returns (uint256) {
        return _subjects.length();
    }

    /**
     * @notice Get the subject at the given index.
     * @dev The ordering may change when adding/removing subjects.
     * @param index_ - Index into the set of subjects.
     * @return The address of the subject at the index.
     */
    function subjectAt(uint256 index_) external view virtual returns (address) {
        return _subjects.at(index_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Set the fee for the given subject.
     * @param subject_ - The address of the subject.
     * @param fee_ - The fee in basis points.
     */
    function setFee(address subject_, uint256 fee_) public virtual onlyRole(OPERATOR_ROLE) {
        require(fee_ <= feePoints,
            'CarbonFeeMaster: fee override exceeds base fee');
        require(_feePointsBySubject[subject_] != fee_,
            'CarbonFeeMaster: fee divisor must change');

        _subjects.add(address(subject_));
        _feePointsBySubject[subject_] = fee_;
        emit FeeChanged(subject_, fee_);
    }

    /**
     * @notice Batch apply fees to subjects.
     * @param subjects_ - Array of subject addresses.
     * @param fees_ - Array of fees.
     */
    function setFeesInBatch(address[] memory subjects_,  uint256[] memory fees_) external virtual onlyRole(OPERATOR_ROLE) {
        require(subjects_.length == fees_.length,
            'CarbonFeeMaster: tokens and fee divisors must have the same length');
        for (uint256 i=0; i < subjects_.length; i++) {
            setFee(subjects_[i], fees_[i]);
        }
    }

    /**
     * @notice Removes a fee divisor for a token.
     * @param subject_ - The token for which we remove the fee divisor.
     */
    function removeFee(address subject_) public virtual onlyRole(OPERATOR_ROLE) {
        require(hasSubject(subject_),
            'CarbonFeeMaster: no fee divisor configured for subject');

        _subjects.remove(subject_);
        _feePointsBySubject[subject_] = 0;
        emit FeeChanged(subject_, feePoints);
    }

    /**
     * @notice Batch remove fees from subjects.
     * @param subjects_ - Array of subject addresses.
     */
    function removeFeesInBatch(address[] memory subjects_) external virtual onlyRole(OPERATOR_ROLE) {
        for (uint256 i=0; i < subjects_.length; i++) {
            removeFee(subjects_[i]);
        }
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev See UUPSUpgradeable. */
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(OPERATOR_ROLE) {}
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {AbstractBaseCarbonToken} from './abstracts/AbstractBaseCarbonToken.sol';
import {CarbonToken} from './CarbonToken.sol';
import {CarbonFeeMaster} from './CarbonFeeMaster.sol';
import {CarbonTokenFactory} from './CarbonTokenFactory.sol';
import {CarbonAccessList} from './CarbonAccessList.sol';
import {CarbonAccessListFactory} from './CarbonAccessListFactory.sol';
import {CarbonIntegrity} from './libraries/CarbonIntegrity.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Bundle Token Contract
 */
contract CarbonBundleToken is AbstractBaseCarbonToken {

    using SafeERC20Upgradeable for CarbonToken;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice The token address and amount of an offset event.
     * @dev The struct is stored for each checksum.
     */
    struct TokenAmount {
        address _token;
        uint256 _amount;
    }

    /**
     * @notice Emitted when tokens are bundled.
     * @param account - The sender address.
     * @param token - The address of the token that was bundled.
     * @param amount - The amount of tokens that have been added to the bundle.
     */
    event Bundle(address indexed account, address indexed token, uint256 amount);

    /**
     * @notice Emitted when tokens are unbundled.
     * @param account - The token recipient.
     * @param token - The address of the token that was unbundled.
     * @param amountIn - The amount of bundle tokens going into the call.
     * @param amountOut - The amount of GCO2 received after fees.
     */
    event Unbundle(address indexed account, address indexed token, uint256 amountIn, uint256 amountOut);

    /**
     * @notice Emitted when a token is added to the bundle.
     * @param token - The address of the token that has been added to the bundle.
     */
    event TokenAdded(address indexed token);

    /**
     * @notice Emitted when a token is removed from the bundle.
     * @param token - The address of the token that has been removed from the bundle.
     */
    event TokenRemoved(address indexed token);

    /**
     * @notice Emitted when a token is paused or resumed for bundling.
     * @param token - The token paused for bundling.
     * @param paused - Whether the token was paused (true) or resumed (false).
     */
    event TokenPaused(address indexed token, bool paused);

    /**
     * @notice Emitted when the minimum vintage requirement changes.
     * @param vintage - The updated minimum vintage.
     */
    event VintageIncremented(uint16 vintage);

    /**
     * @notice Emitted when tokens are reserved for finalization.
     * @param token - The token that has been reserved.
     * @param amount - The reserved amount.
     */
    event ReservedForFinalization(address indexed token, uint256 amount);

    /**
     * @notice Emitted the fee-master has been changed.
     * @param feeMaster - The address of the new fee-master.
     */
    event FeeMasterChanged(address indexed feeMaster);

    // ================
    // Public Constants
    // ================

    /** @notice The minimum supported token vintage. */
    uint16 public constant MIN_VINTAGE_YEAR = 2000;

    /** @notice The maximum supported token vintage. */
    uint16 public constant MAX_VINTAGE_YEAR = 2100;

    /** @notice Limit on vintage increments. */
    uint8 public constant MAX_VINTAGE_INCREMENT = 10;

    /** @notice Hard limit on fees in basis points (50%). */
    uint256 public constant MAX_FEE_POINTS = 5000;

    // =================
    // Public Properties
    // =================

    /** @notice The fee-master controls the payment of fees for unbundling. */
    CarbonFeeMaster public feeMaster;

    /** @notice The token factory for carbon tokens. */
    CarbonTokenFactory public tokenFactory;

    /** @notice The minimum vintage requirement of the bundle. */
    uint16 public vintage;

    /**
     * @notice Bookkeping of the token amounts in this bundle.
     * @dev This might differ from the ERC20.balanceOf if someone sends tokens to the contract.
     */
    mapping (CarbonToken => uint256) public amountInBundle;

    /** @notice Mapping of token amounts that have been reserved for offsetting. */
    mapping (CarbonToken => uint256) public amountReserved;

    /** @notice Total amount of reserved tokens. */
    uint256 public amountReservedInBundle;

    /**
     * @notice The guaranteed maximum fee taken when unbundling tokens.
     * @dev Always lower than MAX_FEE_POINTS.
     */
    uint256 public maxFeePoints;

    // ==================
    // Private Properties
    // ==================

    /** @notice The carbon tokens contained in the bundle. */
    EnumerableSetUpgradeable.AddressSet private _tokensInBundle;

    /** @notice Set of tokens that have been paused for bundling. */
    EnumerableSetUpgradeable.AddressSet private _tokensPausedForBundle;

    /** @notice Keeps track of offset checksums, amounts and tokens. */
    mapping (bytes32 => TokenAmount) private _offsetAmounts;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        uint256 maxFeePoints_,
        address operator_,
        address factory_,
        address payable treasury_,
        address tokenFactory_
    ) external initializer {
        require(vintage_ >= MIN_VINTAGE_YEAR,
            'CarbonBundleToken: vintage out of bounds');
        require(vintage_ <= MAX_VINTAGE_YEAR,
            'CarbonBundleToken: vintage out of bounds');
        require(maxFeePoints_ <= MAX_FEE_POINTS,
            'CarbonBundleToken: unbundle fee too high');
        require(address(factory_) != address(0),
            'CarbonBundleToken: factory is required');
        require(address(tokenFactory_) != address(0),
            'CarbonBundleToken: token factory is required');

        AbstractBaseCarbonToken.initialize(name_, symbol_, operator_, treasury_);
        _grantRole(OPERATOR_ROLE, factory_);

        maxFeePoints = maxFeePoints_;
        vintage = vintage_;
        tokenFactory = CarbonTokenFactory(tokenFactory_);

        for (uint256 i = 0; i < tokens_.length; i++) {
            _addToken(tokens_[i]);
        }
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice Checks if the given token is part of the bundle.
     * @param token_ - The address of the token to check.
     */
    function hasToken(CarbonToken token_) public view virtual returns (bool) {
        return _tokensInBundle.contains(address(token_));
    }

    /** @notice Returns the total number of tokens in the bundle. */
    function tokenCount() public view virtual returns (uint256) {
        return _tokensInBundle.length();
    }

    /**
     * @notice Get the token at the given index.
     * @dev The ordering may change when adding/removing token.
     * @param index_ - Index into the set of tokens.
     */
    function tokenAt(uint256 index_) public view virtual returns (CarbonToken) {
        return CarbonToken(_tokensInBundle.at(index_));
    }

    /**
     * @notice Check if a token is paused for bundling.
     * @param token_ - The address of the token to check.
     * @return Whether or not the token is paused.
     */
    function isPausedForBundle(CarbonToken token_) public view virtual returns (bool) {
        return _tokensPausedForBundle.contains(address(token_));
    }

    /**
     * @notice Return the balance of tokens offsetted with the given address and checksum.
     * @param checksum_ - The checksum of the associated registry offset.
     * @return The number of tokens that have been offsetted with this checksum.
     */
    function getOffsetByChecksum(bytes32 checksum_) external view virtual returns (uint256) {
        return _offsetAmounts[checksum_]._amount;
    }

    /**
     * @notice Return the address of the token associated with the given offset checksum.
     * @param checksum_ - The checksum of the associated registry offset.
     * @return The address of the carbon token that has been retired with this checksum.
     */
    function getTokenByChecksum(bytes32 checksum_) external view virtual returns (address) {
        return _offsetAmounts[checksum_]._token;
    }

    /**
     * @notice Get the effective fee points for unbundling a token.
     * @param token_ - The token subject to fees.
     */
    function getFeePoints(CarbonToken token_) public view virtual returns (uint256) {
        if (address(feeMaster) != address(0)) {
            uint256 feePoints = feeMaster.getFeePoints(address(token_));
            return feePoints < maxFeePoints ? feePoints : maxFeePoints;
        } else {
            return maxFeePoints;
        }
    }

    // ================
    // Public Functions
    // ================

    /**
     * @notice Deposits a token into the bundle.
     * @dev Requires approval.
     * @param token_ - The token to deposit into bundle.
     * @param amount_ - The amount of tokens to deposit.
     */
    function bundle(CarbonToken token_, uint256 amount_) external virtual returns (bool) {
        CarbonIntegrity.requireCanBundleToken(this, token_, amount_);

        _mint(_msgSender(), amount_);
        amountInBundle[token_] += amount_;

        _requestAccessIfRequired(token_);
        token_.safeTransferFrom(_msgSender(), address(this), amount_);

        emit Bundle(_msgSender(), address(token_), amount_);
        return true;
    }

    /**
     * @notice Withdraw tokens from the bundle.
     *         NOTE: This operation is subject to fees.
     * @param token_ - The token to withdraw from the bundle.
     * @param amount_ - The amount of tokens to withdraw.
     * @return The amount of tokens withdrawn after fees.
     */
    function unbundle(CarbonToken token_, uint256 amount_) external virtual returns (uint256) {
        CarbonIntegrity.requireCanUnbundleToken(this, token_, amount_);

        uint256 feePoints = getFeePoints(token_);
        _burn(_msgSender(), amount_);

        uint256 feeAmount = amount_ * feePoints / 10000;
        uint256 amountToUnbundle = amount_ - feeAmount;
        if (feeAmount > 0) {
            token_.safeTransfer(treasury, feeAmount);
        }
        amountInBundle[token_] -= amount_;
        token_.safeTransfer(_msgSender(), amountToUnbundle);

        emit Unbundle(_msgSender(), address(token_), amount_, amountToUnbundle);
        return amountToUnbundle;
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Withdraws tokens that have been mistakenly sent to the contract to the treasury.
     * @param token_ - The address of the token.
     * @return The amount withdrawn to the treasury.
     */
    function withdrawOrphanedToken(CarbonToken token_) public virtual returns (uint256) {
        uint256 orphanedAmount = token_.balanceOf(address(this)) - amountInBundle[token_];
        if (orphanedAmount > 0) {
            token_.safeTransfer(treasury, orphanedAmount);
        }
        return orphanedAmount;
    }

    /**
     * @notice Adds a token to the bundle.
               The token details must be compatible with the bundle.
     * @param token_ - The address of the token to be added to the bundle.
     */
    function addToken(CarbonToken token_) external virtual onlyRole(OPERATOR_ROLE) {
        _addToken(token_);
    }

    /**
     * @notice Removes a token from the bundle.
     * @param token_ - The address of the token to be removed from the bundle.
     */
    function removeToken(CarbonToken token_) external virtual onlyRole(OPERATOR_ROLE) {
        CarbonIntegrity.requireHasToken(this, token_);

        withdrawOrphanedToken(token_);
        require(token_.balanceOf(address(this)) == 0,
            'CarbonBundleToken: token has remaining balance');

        address token = address(token_);
        _tokensInBundle.remove(token);
        emit TokenRemoved(token);
    }

    /**
     * @notice Increase the minimum vintage requirement of the bundle.
     * @dev In case of vintage mismatch: existing tokens can no longer be bundled, new tokens require the new vintage.
     * @param years_ - Number of years to increment the vintage. Must be less than, or equal to MAX_VINTAGE_INCREMENT.
     */
    function incrementVintage(uint16 years_) external virtual onlyRole(OPERATOR_ROLE) returns (uint16) {
        require(years_ <= MAX_VINTAGE_INCREMENT,
            'CarbonBundleToken: vintage increment is too large');
        require(vintage + years_ <= MAX_VINTAGE_YEAR,
            'CarbonBundleToken: vintage too high');

        vintage += years_;
        emit VintageIncremented(vintage);
        return vintage;
    }

    /**
     * @notice Pauses or resumes bundling of the given token.
     * @param token_ - The token to pause or resume.
     * @param isPaused_ - Flag indicating whether to pause or resume.
     * @return True if the contract state changed, otherwise false.
     */
    function setPausedForBundle(CarbonToken token_, bool isPaused_) external virtual onlyRole(OPERATOR_ROLE) returns(bool) {
        CarbonIntegrity.requireHasToken(this, token_);
        bool hasChanged;
        if (isPaused_) {
            hasChanged = _tokensPausedForBundle.add(address(token_));
        } else {
            hasChanged = _tokensPausedForBundle.remove(address(token_));
        }
        if (hasChanged) {
            emit TokenPaused(address(token_), isPaused_);
        }
        return hasChanged;
    }

    /**
     * @notice Set the fee-master for the bundle.
     * @param feeMaster_ - The fee-master contract.
     */
    function setFeeMaster(CarbonFeeMaster feeMaster_) external virtual onlyRole(OPERATOR_ROLE) {
        feeMaster = feeMaster_;
        emit FeeMasterChanged(address(feeMaster_));
    }

    /**
     * @notice Reserves a specific amount of tokens for finalization of offsets.
     * @dev This function must be called before completing the off-chain retirement process to avoid race-conditions.
     * @param token_ - The token to reserve.
     * @param amount_ - The amount of tokens to reserve.
     */
    function reserveForFinalization(CarbonToken token_, uint256 amount_) external virtual onlyRole(OPERATOR_ROLE) {
        CarbonIntegrity.requireHasToken(this, token_);

        amountReservedInBundle -= amountReserved[token_];
        amountReserved[token_] = amount_;
        amountReservedInBundle += amount_;

        require(incompleteOffsetBalance >= amountReservedInBundle,
            'CarbonBundleToken: cannot reserve more than what is currently pending');

        emit ReservedForFinalization(address(token_), amount_);
    }

    /**
     * @notice Operators finalize the offsetting process once the off-chain credits have been retired.
     * @param token_ - The address of the token that has been offsetted.
     * @param amount_ - The amount of tokens that have been offsetted.
     * @param checksum_ - The checksum associated with the registry offset.
     */
    function finalizeOffset(
        CarbonToken token_,
        uint256 amount_,
        bytes32 checksum_
    ) external virtual onlyRole(OPERATOR_ROLE) returns (bool) {
        CarbonIntegrity.requireCanFinalizeOffset(this, token_, amount_, checksum_);

        incompleteOffsetBalance -= amount_;
        _offsetAmounts[checksum_] = TokenAmount(address(token_), amount_);
        offsetBalance += amount_;
        amountInBundle[token_] -= amount_;
        token_.burn(amount_);
        amountReservedInBundle -= amount_;
        amountReserved[token_] -= amount_;

        emit OffsetFinalized(amount_, checksum_);
        return true;
    }

    // ==================
    // Internal Functions
    // ==================

    /**
     * @dev Private function to call addToken for use in the initializer.
     */
    function _addToken(CarbonToken token_) private {
        require(!hasToken(token_),
            'CarbonIntegrity: token already added to bundle');
        require(tokenFactory.hasInstanceAt(address(token_)),
            'CarbonIntegrity: unknown token');
        require(token_.vintage() >= vintage,
            'CarbonIntegrity: vintage mismatch');

        if (tokenCount() > 0) {
            require(address(token_.bundleFactory()) ==  address(tokenAt(0).bundleFactory()),
                'CarbonIntegrity: all tokens must have the same bundle factory');
        }

        _tokensInBundle.add(address(token_));
        emit TokenAdded(address(token_));
    }

    /**
     * @dev Allows the bundle to request access to a token.
     *      Requires TRUSTEE_ROLE on the access-list factory.
     */
    function _requestAccessIfRequired(CarbonToken token_) internal virtual {
        if (address(token_.accessList()) != address(0)) {
            CarbonAccessList accessList = token_.accessList();
            if (!accessList.hasAccess(address(this))) {
                CarbonAccessListFactory accessListFactory = CarbonAccessListFactory(accessList.factory());
                accessListFactory.requestAccess(accessList);
            }
        }
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractFactory} from './abstracts/AbstractFactory.sol';
import {CarbonToken} from './CarbonToken.sol';
import {CarbonAccessList} from './CarbonAccessList.sol';
import {CarbonBundleTokenFactory} from './CarbonBundleTokenFactory.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Token Factory Contract
 */
contract CarbonTokenFactory is AbstractFactory {

    // =================
    // Public Properties
    // =================

    /** @notice The associated bundle factory. */
    CarbonBundleTokenFactory public bundleFactory;

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        require(operator_ != address(0),
            'CarbonAccessListFactory: operator is required');
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new carbon credit token.
     * @param blueprintId_ - The ID of the blueprint to be instantiated.
     * @param name_ - The name of the ERC-20 token, should be unique within the ecosystem.
     * @param symbol_ - The symbol of the ERC-20 token, should be unique within the ecosystem.
     * @param details_ - Token details to capture the fungibility characteristics of this token.
     * @param accessList_ - The access-list of the token.
     * @param operator_ - The account that is granted operator privileges.
     * @param treasury_ - The address of the carbon treasury.
     * @return The address of the newly created token
     */
    function createToken(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_,
        address operator_,
        address payable treasury_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        require(address(bundleFactory) != address(0),
            'CarbonTokenFactory: bundle factory is not set');
        bytes memory initializer = abi.encodeWithSelector(
            CarbonToken(address(0)).initialize.selector,
            name_, symbol_, details_, accessList_, operator_, treasury_, bundleFactory
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }

    /**
     * @notice Set the bundle token factory to be passed to token instances.
     * @param bundleFactory_ - The bundle factory instance passed to new tokens.
     */
    function setBundleFactory(CarbonBundleTokenFactory bundleFactory_) external onlyRole(OPERATOR_ROLE) {
        require(address(bundleFactory_) != address(0),
            'CarbonBundleTokenFactory: bundle factory is required');
        bundleFactory = bundleFactory_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Treasury Contract
 */
contract CarbonTreasury is AccessControl {

    using SafeERC20 for IERC20;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when native tokens are sent to this account.
     * @param account - The sender.
     * @param amount - The amount received.
     */
    event Received(address indexed account, uint amount);

    // ================
    // Public Constants
    // ================

    /**
     * @notice Treasurer role for access control.
     * @dev Treasurers are allowed to withdraw from the treasury.
     */
    bytes32 public constant TREASURER_ROLE = keccak256('TREASURER_ROLE');

    // ========================
    // Initialization Functions
    // ========================

    constructor(address treasurer_) {
        require(treasurer_ != address(0),
            'CarbonTreasury: treasurer is required');
        _grantRole(DEFAULT_ADMIN_ROLE, treasurer_);
        _grantRole(TREASURER_ROLE, treasurer_);
    }

    /** @dev Make the treasury payable. */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Treasurers are allowed to withdraw from the treasury with this function.
     * @param token_ - The ERC-20 token to withdraw.
     * @param amount_ - The amount to withdraw.
     */
    function withdraw(IERC20 token_, uint256 amount_) external onlyRole(TREASURER_ROLE) {
        token_.safeTransfer(msg.sender, amount_);
    }

    /**
     * @notice Treasurers are allowed to withdraw native tokens from the treasury with this function.
     * @param amount_ - The amount to withdraw.
     */
    function withdrawEth(uint256 amount_) external onlyRole(TREASURER_ROLE) {
        (bool success, bytes memory returnData) = msg.sender.call{value: amount_}('');
        require(success, string(returnData));
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {AbstractFactory} from './abstracts/AbstractFactory.sol';
import {CarbonAccessList} from './CarbonAccessList.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon access-list Factory Contract
 */
contract CarbonAccessListFactory is AbstractFactory {

    // ================
    // Public Constants
    // ================

    /**
     * @notice Trustee role for access control.
     * @dev A trustee can request access to lists via the factory.
     */
    bytes32 public constant TRUSTEE_ROLE = keccak256('TRUSTEE_ROLE');

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        require(operator_ != address(0),
            'CarbonAccessListFactory: operator is required');
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new carbon access-list.
     * @param blueprintId_ - The ID of the blueprint to be instantiated.
     * @param name_ - The name given to the newly deployed list.
     * @param operator_ - The address to which ownership of the deployed contract will be transferred.
     * @return The address of the newly created list.
     */
    function createAccessList(
        uint blueprintId_,
        string memory name_,
        address operator_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        bytes memory initializer = abi.encodeWithSelector(
            CarbonAccessList(address(0)).initialize.selector,
            name_, operator_, address(this)
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }

    // ==================
    // Protocol Functions
    // ==================

    /** @dev Factory operators can appoint brokers, who can request access to tokens. */
    function appointTrustee(address account_) external onlyRole(OPERATOR_ROLE) {
        _grantRole(TRUSTEE_ROLE, account_);
    }

    /** @dev Allows the rakeback factory to give access to GCO2 tokens. */
    function requestAccess(CarbonAccessList accessList_) external onlyRole(TRUSTEE_ROLE) {
        accessList_.setLocalAccess(_msgSender(), true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {CarbonBundleTokenFactory} from '../CarbonBundleTokenFactory.sol';
import {CarbonToken} from '../CarbonToken.sol';
import {CarbonBundleToken} from '../CarbonBundleToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Integrity Library
 */
library CarbonIntegrity {

    // ================
    // Public Functions
    // ================

    /** @dev Reverts if a bundle does not contain a token. */
    function requireHasToken(CarbonBundleToken bundle_, CarbonToken token_) public view {
        require(bundle_.hasToken(token_),
            'CarbonIntegrity: token is not part of bundle');
    }

    /** @dev Reverts if the tokens vintage is incompatible with the bundle. */
    function requireVintageNotOutdated(CarbonBundleToken bundle_, CarbonToken token_) public view {
        require(token_.vintage() >= bundle_.vintage(),
            'CarbonIntegrity: token outdated');
    }

    /** @dev Reverts if the token and amount cannot be bundled. */
    function requireCanBundleToken(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        requireVintageNotOutdated(bundle_, token_);
        require(amount_ != 0,
            'CarbonIntegrity: amount may not be zero');
        require(!bundle_.isPausedForBundle(token_),
            'CarbonIntegrity: token is paused for bundling');
    }

    /** @dev Reverts if the token and amount cannot be unbundled. */
    function requireCanUnbundleToken(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        require(token_.balanceOf(address(bundle_)) - bundle_.amountReserved(token_) >= amount_,
            'CarbonIntegrity: amount exceeds the token balance');
        require(amount_ != 0,
            'CarbonIntegrity: amount may not be zero');
        uint256 feePoints = bundle_.getFeePoints(token_);
        require(feePoints == 0 || amount_ * feePoints >= 10000,
            'CarbonIntegrity: amount too low for fees');
    }

    /** @dev Reverts if the amount and checksum cannot be finalized for the given bundle and token. */
    function requireCanFinalizeOffset(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_, bytes32 checksum_) external view {
        requireHasToken(bundle_, token_);
        require(checksum_ != 0,
            'CarbonIntegrity: checksum is required');
        require(bundle_.getOffsetByChecksum(checksum_) == 0,
            'CarbonIntegrity: checksum already used');
        require(amount_ <= bundle_.incompleteOffsetBalance(),
            'CarbonIntegrity: amount exceeds incomplete offset balance');
        require(token_.balanceOf(address(bundle_)) >= amount_,
            'CarbonIntegrity: amount exceeds the token balance');
        require(bundle_.amountReserved(token_) >= amount_,
            'CarbonIntegrity: reserve too low');
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';
import {AbstractBaseCarbonToken} from '../../abstracts/AbstractBaseCarbonToken.sol';

/*
 * @author Flowcarbon LLC
 * @title Remote Carbon Token Base-Contract
 */
abstract contract AbstractRemoteBaseCarbonToken is AbstractBaseCarbonToken {

    // =================
    // Public Properties
    // =================

    /** @notice The station associated with this remote token. */
    RemoteCarbonStation public station;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        address operator_,
        address payable treasury_,
        RemoteCarbonStation station_
    ) internal onlyInitializing {
        AbstractBaseCarbonToken.initialize(name_, symbol_, operator_, treasury_);
        station = station_;
        _grantRole(OPERATOR_ROLE, operator_);
        _grantRole(TOKENIZER_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, address(station_));
        _grantRole(TOKENIZER_ROLE, address(station_));
    }

    // ================
    // Public Functions
    // ================

    /**
     * @notice Send all pending offsets to our central network.
     *         NOTE: Operators run this frequently, but anyone is free to do so!
     */
    function processIncompleteOffsets() external payable  {
        uint256 amount = incompleteOffsetBalance;
        offsetBalance += amount;
        incompleteOffsetBalance = 0;
        _processOffsets(amount);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Mint new remote tokens. Internal usage only - neither users nor operators have access.
     * @param account_ - The address of the recipient.
     * @param amount_ - The amount of tokens to mint to the recipient.
     */
    function mint(address account_, uint256 amount_) external onlyRole(TOKENIZER_ROLE) {
        _mint(account_, amount_);
    }

    /**
     * @notice Burn remote tokens. Internal usage only - neither users nor operators have access.
     * @param account_ - The address of the arsonist.
     * @param amount_ - The amount to tokens to burn from the arsonists wallet.
     */
    function burn(address account_, uint256 amount_) external onlyRole(TOKENIZER_ROLE) {
        _burn(account_, amount_);
    }

    // ==================
    // Internal Functions
    // ==================

    /**
     * @dev The actual processing implementation to the terminal station.
     * @param amount_ - The amount processed.
     */
    function _processOffsets(uint256 amount_) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {IRouteReceiver} from '../interfaces/IRouteReceiver.sol';
import {IRoute} from '../interfaces/IRoute.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Station Base-Contract
 */
abstract contract AbstractCarbonStation is
        IRouteReceiver,
        AccessControlUpgradeable,
        UUPSUpgradeable,
        PausableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when native tokens are sent to this account.
     * @param account - The sender.
     * @param amount - The amount received.
     */
    event Received(address indexed account, uint amount);

    /**
     * @notice Emitted when a remote route is registered.
     * @param destination - The remote chain ID.
     * @param routeAdapter - Address of the route adapter.
     * @param remoteRouteAdapter - The registered route contract.
     */
    event RemoteRouteRegistered(uint256 destination, address indexed routeAdapter, address indexed remoteRouteAdapter);

    /**
     * @notice Emitted when a new route is configured for a chain.
     * @param destination - The remote chain ID.
     * @param routeAdapter - Address of the route adapter.
     * @param identifier - Hashed identifier of the route adapter.
     */
    event RouteRegistered(uint256 destination, address indexed routeAdapter, bytes32 identifier);

    /**
     * @notice Treasury changed.
     * @param treasury - New treasury address.
     */
    event TreasuryChanged(address indexed treasury);

    /**
     * @notice Emitted when the sending transit endpoint has been updated.
     * @param sender - New sender address.
     */
    event SenderChanged(address indexed sender);

    /**
     * @notice Emitted when the receiving transit endpoint has been updated.
     * @param receiver - New receiver address.
     */
    event ReceiverChanged(address indexed receiver);

    // ================
    // Public Constants
    // ================

    /**
     * @notice Operator role for access control.
     * @dev Operators take care of day-to-day operations in the protocol.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    /**
     * @notice Transmitter role for access control.
     * @dev Transmitters are involved in cross-chain message delivery.
     */
    bytes32 public constant TRANSMITTER_ROLE = keccak256('TRANSMITTER_ROLE');

    // =================
    // Public Properties
    // =================

    /** @notice The chainId of the network this station is deployed on. */
    uint public chainId;

    /** @notice Mapping of chain IDs to remote bridge addresses. */
    mapping(uint256 => address) public remoteRoutes;

    /** @notice Mapping of chain IDs to local bridge interfaces. */
    mapping(uint256 => IRoute) public routes;

    /** @notice The sender contract used by the station. */
    address public sender;

    /** @notice The receiver contract used by the station. */
    address public receiver;

    /** @notice The carbon treasury address. */
    address payable public treasury;

    // ==================
    // Private Properties
    // ==================

    /** @dev Set of chain IDs supported by the local bridge adapters. */
    EnumerableSetUpgradeable.UintSet private _supportedRoutes;

    // ========================
    // Initialization Functions
    // ========================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev Initialize proxy pattern. */
    function initialize(
        uint chainId_,
        address operator_,
        address payable treasury_
    ) public onlyInitializing {
        require(chainId_ != 0,
            'AbstractCarbonStation: chain id is required');
        require(operator_ != address(0),
            'AbstractCarbonStation: operator is required');
        require(treasury_ != address(0),
            'AbstractCarbonStation: treasury is required');
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
        chainId = chainId_;
        treasury = treasury_;
    }

    /** @dev Make the station payable. */
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice Checks if there exists a registered route for a given destination.
     * @return True if we have support, else false.
     */
    function hasRoute(uint256 destination_) public view returns (bool) {
        return _supportedRoutes.contains(destination_);
    }

    /**
     * @notice Returns the local route adapter for the given destination.
     * @dev Reverts if no route exists.
     * @param destination_ - The target chain.
     * @return The route address for the given destination.
     */
    function getRoute(uint256 destination_) public view returns (IRoute) {
        require(hasRoute(destination_),
            'AbstractCarbonStation: no route registered for destination');
        return routes[destination_];
    }

    /** @return The number of routes/destination supported. */
    function routeCount() external view returns (uint256) {
        return _supportedRoutes.length();
    }

    /**
     * @notice The local route adapter at the given index.
     * @dev Ordering may change upon adding/removing.
     * @param index_ - The index into the set.
     * @return The bridge at the given index.
     */
    function routeAt(uint256 index_) external view returns (IRoute) {
        return routes[_supportedRoutes.at(index_)];
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Set a new treasury address.
     * @param treasury_ - Address of the new treasury.
     */
    function setTreasury(address payable treasury_) external onlyRole(OPERATOR_ROLE) {
        require(treasury_ != address(0),
            'AbstractCarbonStation: treasury is required');
        treasury = treasury_;
        emit TreasuryChanged(treasury_);
    }

    /*
     * @notice Configure a new sender endpoint.
     * @param sender_ - Address of the sender.
     */
    function setSender(address sender_) external onlyRole(OPERATOR_ROLE) {
        require(sender_ != address(0),
            "AbstractCarbonStation: sender is required");
        require(sender_ != sender,
            "AbstractCarbonStation: sender must change");
        _revokeRole(TRANSMITTER_ROLE, sender);
        _grantRole(TRANSMITTER_ROLE, sender_);
        sender = sender_;
        emit SenderChanged(sender_);
    }

    /**
     * @notice Configure a new receiver endpoint.
     * @param receiver_ - Address of the receiver.
     */
    function setReceiver(address receiver_) external onlyRole(OPERATOR_ROLE) {
        require(receiver_ != address(0),
            "AbstractCarbonStation: receiver is required");
        require(receiver_ != receiver,
            "AbstractCarbonStation: receiver must change");
        _revokeRole(TRANSMITTER_ROLE, receiver);
        _grantRole(TRANSMITTER_ROLE, receiver_);
        receiver = receiver_;
        emit ReceiverChanged(receiver_);
    }

    /**
     * @notice Add or remove a route adapter.
     * @param destination_ - The target destination chain.
     * @param route_ - The bridge adapter to use, address(0) disables the destination.
     */
    function registerRoute(uint256 destination_, IRoute route_) external onlyRole(OPERATOR_ROLE) {
        routes[destination_] = route_;
        if (address(route_) == address(0)) {
            _supportedRoutes.remove(destination_);
            // NOTE: zero address indicates removal
            emit RouteRegistered(destination_, address(route_), bytes32(uint256(uint160(0))));
        } else {
            _supportedRoutes.add(destination_);
            emit RouteRegistered(destination_, address(route_), route_.getIdentifier());
        }
    }

    /**
     * @notice Registers a remote route for use with this station.
     * @param destination_ - The remote chain ID.
     * @param contract_ - The address of the contract to trust as a remote sender.
     */
    function registerRemoteRoute(uint256 destination_, address contract_) external onlyRole(OPERATOR_ROLE) {
        getRoute(destination_).registerRemoteRoute(destination_, contract_);
        remoteRoutes[destination_] = contract_;
        emit RemoteRouteRegistered(destination_, address(routes[destination_]), contract_);
    }

    /** @notice Send *all* ETH held by this contract to the treasury. */
    function sendEthToTreasury() external onlyRole(OPERATOR_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, bytes memory returnData) = treasury.call{value: balance}('');
        require(success, string(returnData));
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    /** @dev See PausableUpgradeable. */
    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /** @dev See PausableUpgradeable. */
    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    // ==================
    // Protocol Functions
    // ==================

    /** @dev See IRouteReceiver. */
    function handleSendMessage(uint256 source_, bytes memory payload_) external whenNotPaused {
        require(address(receiver) != address(0),
            'AbstractCarbonStation: receiver is not initialized');
        require(address(getRoute(source_)) == _msgSender(),
            'AbstractCarbonStation: invalid source');

        (bool success, bytes memory returnData) = address(receiver).call(payload_);
        require(success, string(returnData));
    }

    /** @dev Send a message to a remote chain - only allowed for trusted endpoints. */
    function send(uint256 destination_, bytes memory payload_) external payable onlyRole(TRANSMITTER_ROLE) {
        _send(destination_, payload_);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev See UUPSUpgradeable. */
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(OPERATOR_ROLE) {}

    /**
     * @param destination_ - The remote chain.
     * @param payload_ - The raw mesage payload.
     */
    function _send(uint256 destination_, bytes memory payload_) internal whenNotPaused {
        require(address(sender) != address(0),
            'AbstractCarbonStation: sender is not initialized');
        getRoute(destination_).sendMessage{value: msg.value}(destination_, payload_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractFactory} from '../../abstracts/AbstractFactory.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';
import {RemoteCarbonBundleToken} from './RemoteCarbonBundleToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon-Bundle Token Factory Contract
 */
contract RemoteCarbonBundleTokenFactory is AbstractFactory {

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new carbon credit bundle token.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The name of the new token, should be unique within the ecosystem.
     * @param symbol_ - The token symbol of the ERC-20, should be unique within the ecosystem.
     * @param vintage_ - The minimum vintage of this bundle.
     * @param operator_ - The account to be granted operator privileges.
     * @param treasury_ - The address of the carbon treasury.
     * @param station_ - The terminal station that manages the token.
     * @return The address of the newly created token.
     */
    function createBundle(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        address operator_,
        address payable treasury_,
        RemoteCarbonStation station_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        bytes memory initializer = abi.encodeWithSelector(
            RemoteCarbonBundleToken(address(0)).initialize.selector,
            name_, symbol_, vintage_, operator_, treasury_, station_
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {AbstractRemoteBaseCarbonToken} from '../abstracts/AbstractRemoteBaseCarbonToken.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';
import {RemoteCarbonToken} from './RemoteCarbonToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon-Bundle Token Contract
 */
contract RemoteCarbonBundleToken is AbstractRemoteBaseCarbonToken {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when a token is added to the bundle.
     * @param token - The token address.
     */
    event TokenAdded(address indexed token);

    /**
     * @notice Emitted when a token is removed from the bundle.
     * @param token - The token address.
     */
    event TokenRemoved(address indexed token);

    /**
     * @notice Emitted when a token is paused or resumed for bundling.
     * @param token - The token paused for bundling.
     * @param paused - Whether the token was paused (true) or resumed (false).
     */
    event TokenPaused(address indexed token, bool paused);

    /**
     * @notice Emitted when the minimum vintage requirements change.
     * @param vintage - The new vintage after the update.
     */
    event VintageIncremented(uint16 vintage);

    // =================
    // Public Properties
    // =================

    /** @notice The lower bound of carbon vintages in the bundle. */
    uint16 public vintage;

    // ==================
    // Private Properties
    // ==================

    /** @notice The set of tokens in the bundle. */
    EnumerableSetUpgradeable.AddressSet private _tokensInBundle;

    /** @notice The set of tokens that are paused for depositing to the bundle. */
    EnumerableSetUpgradeable.AddressSet private _tokensPausedForBundle;

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        address operator_,
        address payable treasury_,
        RemoteCarbonStation station_
    ) external initializer {
        AbstractRemoteBaseCarbonToken.initialize(name_, symbol_, operator_, treasury_, station_);
        vintage = vintage_;
        station = station_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice Checks if a token is part of the bundle.
     * @param token_ - A carbon credit token.
     */
    function hasToken(RemoteCarbonToken token_) external view virtual returns (bool) {
        return _tokensInBundle.contains(address(token_));
    }

    /** @notice Return the number of tokens in the bundle. */
    function tokenCount() external view virtual returns (uint256) {
        return _tokensInBundle.length();
    }

    /**
     * @notice Get the address of the token at the given index.
     * @dev Ordering may change upon adding/removing tokens.
     * @param index_ - Index into the token set.
     */
    function tokenAt(uint256 index_) external view virtual returns (address) {
        return _tokensInBundle.at(index_);
    }

    /**
     * @notice Check if a token is paused for bundling.
     * @param token_ - The token address.
     * @return Whether the token is paused or not.
     */
    function isPausedForBundle(RemoteCarbonToken token_) public view virtual returns (bool) {
        return _tokensPausedForBundle.contains(address(token_));
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Add a token to the bundle.
     * @param token_ - The address of the carbon token to be added.
     * @return True if token was added, false if it was already part of the bundle.
     */
    function addToken(RemoteCarbonToken token_) external virtual onlyRole(OPERATOR_ROLE) returns (bool) {
        bool isAdded = _tokensInBundle.add(address(token_));
        if (isAdded) {
            emit TokenAdded(address(token_));
        }
        return isAdded;
    }

    /**
     * @notice Removes a token from the bundle.
     * @param token_ - The carbon credit token to remove.
     */
    function removeToken(RemoteCarbonToken token_) external virtual onlyRole(OPERATOR_ROLE) {
        address tokenAddress = address(token_);
        bool isRemoved = _tokensInBundle.remove(tokenAddress);
        if (isRemoved) {
            emit TokenRemoved(tokenAddress);
        }
    }

    /**
     * @notice Updates the vintage to the given value.
     * @dev The vintage can only be increased, never decreased.
     * @param vintage_ - The new vintage (e.g. 2020).
     */
    function updateVintage(uint16 vintage_) external virtual onlyRole(OPERATOR_ROLE) {
        if (vintage < vintage_) {
            vintage = vintage_;
            emit VintageIncremented(vintage);
        }
    }

    /**
     * @notice Pause or resume bundling of the given carbon token.
     * @param token_ - The token to pause or resume.
     * @return True if the action changed the contract state, else false.
     */
    function setPausedForBundle(RemoteCarbonToken token_, bool pause_) external virtual onlyRole(OPERATOR_ROLE) returns(bool) {
        bool changed;
        if (pause_) {
            changed = _tokensPausedForBundle.add(address(token_));
        } else {
            changed = _tokensPausedForBundle.remove(address(token_));
        }
        if (changed) {
            emit TokenPaused(address(token_), pause_);
        }
        return changed;
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev See parent. */
    function _processOffsets(uint256 amount_) internal virtual override {
        station.processBundleOffsets{value: msg.value}(this, amount_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {ICarbonSender} from '../interfaces/ICarbonSender.sol';
import {ICarbonReceiver} from '../interfaces/ICarbonReceiver.sol';
import {IBaseCarbonToken} from '../../interfaces/IBaseCarbonToken.sol';
import {CentralCarbonReceiver} from '../central/CentralCarbonReceiver.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';
import {RemoteCarbonBundleToken} from './RemoteCarbonBundleToken.sol';
import {RemoteCarbonToken} from './RemoteCarbonToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon Sender Contract
 */
contract RemoteCarbonSender is ICarbonSender {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when tokens are put into a bundle.
     * @param trace - Trace for tracking events across chains.
     * @param account - The token sender.
     * @param amount - The amount of tokens to bundle.
     * @param token - The address of the vanilla underlying.
     */
    event Bundle(
        bytes32 trace,
        address indexed account,
        address indexed bundle,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Emitted when tokens are taken from a bundle.
     * @param trace - Trace for tracking events across chains.
     * @param account - The token recipient.
     * @param amount - The amount of unbundled tokens.
     * @param token - The address of the vanilla underlying.
     */
    event Unbundle(
        bytes32 trace,
        address indexed account,
        address indexed bundle,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Emitted when a bundle swap is excuted.
     * @param trace - Trace for tracking events across chains.
     * @param sourceBundle - The source bundle.
     * @param targetBundle - The target bundle.
     * @param token - The token to swap from source to target.
     * @param amount - The amount of tokens to swap.
     */
    event SwapBundle(
        bytes32 trace,
        address account,
        address indexed sourceBundle,
        address indexed targetBundle,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Emitted on offset specific on behalf of and offset specific (which is just a special case of the on behalf of).
     * @param trace - Trace for tracking events across chains.
     * @param bundle - The bundle from which to offset.
     * @param token - The token to offset.
     * @param account - Address of the account that is granted the offset.
     * @param amount - The amount of tokens offsetted.
     */
    event OffsetSpecificOnBehalfOf(
        bytes32 trace,
        address account,
        address indexed beneficiary,
        address indexed bundle,
        address indexed token,
        uint256 amount
    );

    // =================
    // Public Properties
    // =================

    /** @notice The local station that connects us to the cross-chain network. */
    RemoteCarbonStation public station;

    // ========================
    // Initialization Functions
    // ========================

    constructor(RemoteCarbonStation station_) {
        require(address(station_) != address(0),
            'RemoteCarbonSender: station is required');
        station = station_;
    }

    // ================
    // Public Functions
    // ================

    /** @dev See ICarbonSender - tokens are burned here. */
    function sendToken(
        uint256 destination_,
        address token_,
        address recipient_,
        uint256 amount_
    ) public payable {
        require(amount_ != 0,
            'RemoteCarbonSender: amount must be greater than 0');
        RemoteCarbonToken rToken = station.getToken(token_);
        if (address(rToken.accessList()) != address(0)) {
            require(rToken.accessList().hasAccess(msg.sender),
                'RemoteCarbonSender: the sender is not allowed to send this token');
            require(rToken.accessList().hasGlobalAccess(recipient_) || rToken.accessList().hasRemoteAccess(destination_, recipient_),
                'RemoteCarbonSender: the recipient is not allowed to receive this token');
        }

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(rToken, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                ICarbonReceiver.handleSendToken.selector,
                trace,
                station.localToCentralTokens(token_),
                recipient_,
                amount_
            )
        );

        emit SendToken(
            trace,
            destination_,
            msg.sender,
            recipient_,
            address(rToken),
            amount_
        );
    }

    /** @dev See ICarbonSender - bundles are burned here. */
    function sendBundle(
        uint256 destination_,
        address bundle_,
        address recipient_,
        uint256 amount_
    ) external payable {
        require(amount_ != 0,
            'RemoteCarbonSender: amount must be greater than 0');
        RemoteCarbonBundleToken rBundle = station.getBundle(bundle_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(rBundle, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              ICarbonReceiver.handleSendBundle.selector,
              trace,
              station.localToCentralBundles(bundle_),
              recipient_,
              amount_
            )
        );

        emit SendBundle(
            trace,
            destination_,
            msg.sender,
            recipient_,
            bundle_,
            amount_
        );
    }

    /**
     * @notice Swaps source bundle for the target via the given token for the given amount.
     * @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur.
     * @param sourceBundle_ - The source bundle.
     * @param targetBundle_ - The target bundle.
     * @param token_ - The token to swap from source to target.
     * @param amount_ - The amount of tokens to swap.
     */
    function swapBundle(
        address sourceBundle_,
        address targetBundle_,
        address token_,
        uint256 amount_
    ) external payable {
        // NOTE: redundant calls because of stack limit.
        require(station.getBundle(sourceBundle_).hasToken(station.getToken(token_)),
            'RemoteCarbonSender: token must be compatible with source');
        require(station.getBundle(targetBundle_).hasToken(station.getToken(token_)),
            'RemoteCarbonSender: token must be compatible with target');
        require(!station.getBundle(targetBundle_).isPausedForBundle(station.getToken(token_)),
            'RemoteCarbonSender: token is paused for bundling');

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(station.getBundle(sourceBundle_), msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleSwapBundle.selector,
                trace,
                station.chainId(),
                station.localToCentralBundles(sourceBundle_),
                station.localToCentralBundles(targetBundle_),
                station.localToCentralTokens(token_),
                msg.sender,
                amount_
            )
        );

        emit SwapBundle(
            trace,
            msg.sender,
            sourceBundle_,
            targetBundle_,
            token_,
            amount_
        );
    }

    /**
     * @notice Offsets a specific token from a bundle on behalf of a user.
     * @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur.
     * @param bundle_ - The bundle from which to offset.
     * @param token_ - The token to offset.
     * @param beneficiary_ - The address to be credited with the offset.
     * @param amount_ - The amount of tokens to offset.
     */
    function offsetSpecificOnBehalfOf(
        address bundle_,
        address token_,
        address beneficiary_,
        uint256 amount_
    ) public payable {
        RemoteCarbonBundleToken rBundle = station.getBundle(bundle_);
        RemoteCarbonToken rToken = station.getToken(token_);
        require(rBundle.hasToken(rToken),
            'RemoteCarbonSender: token must be compatible with bundle');

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(rBundle, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleOffsetSpecificOnBehalfOf.selector,
                trace,
                station.chainId(),
                station.localToCentralBundles(bundle_),
                station.localToCentralTokens(token_),
                msg.sender,
                beneficiary_,
                amount_
            )
        );

        emit OffsetSpecificOnBehalfOf(
            trace,
            msg.sender,
            beneficiary_,
            bundle_,
            token_,
            amount_
        );
    }

    /**
     * @notice Offset on behalf of the sender.
     * @dev See offsetSpecificOnBehalfOf, this is just a special case convenience function.
     * @param bundle_ - The bundle from which to offset.
     * @param token_ - The specific token to offset, must be part of the bundle.
     * @param amount_ - The amount of tokens to offset.
     */
    function offsetSpecific(
        address bundle_,
        address token_,
        uint256 amount_
    ) external payable {
        offsetSpecificOnBehalfOf(bundle_, token_, msg.sender, amount_);
    }

    /**
     * @notice Offset tokens on behalf of the sender.
     * @param token_ - The token or bundle to offset.
     * @param amount_ - The amount to offset.
     */
    function offset(
        address token_,
        uint256 amount_
    ) external payable {
        IBaseCarbonToken token = IBaseCarbonToken(token_);
        token.transferFrom(msg.sender, address(this), amount_);
        token.offsetOnBehalfOf(msg.sender, amount_);
    }

    /**
     * @notice Offset tokens on behalf of the given user.
     * @param token_ - The token or bundle to offset.
     * @param beneficiary_ - The account to be credited with the offset.
     * @param amount_ - The amount to offset.
     */
    function offsetOnBehalfOf(
        address token_,
        address beneficiary_,
        uint256 amount_
    ) external payable {
        IBaseCarbonToken token = IBaseCarbonToken(token_);
        token.transferFrom(msg.sender, address(this), amount_);
        token.offsetOnBehalfOf(beneficiary_, amount_);
    }

    /**
     * @notice Inject GCO2 tokens into a bundle.
     * @dev Tokens are sent back on failure, a small fee to cover the tx in terms of the bundle may occur.
     * @param bundle_ - The bundle token to receive.
     * @param token_ - The GCO2 token to bundle.
     * @param amount_ - The amount of tokens.
     */
    function bundle(
        address bundle_,
        address token_,
        uint256 amount_
    ) external payable {
        RemoteCarbonBundleToken rBundle = station.getBundle(bundle_);
        RemoteCarbonToken rToken = station.getToken(token_);
        require(rBundle.hasToken(rToken),
            'RemoteCarbonSender: token must be compatible with bundle');
        require(!rBundle.isPausedForBundle(rToken),
            'RemoteCarbonSender: token is paused for bundling');

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(rToken, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleBundle.selector,
                trace,
                station.chainId(),
                station.localToCentralBundles(bundle_),
                station.localToCentralTokens(token_),
                msg.sender,
                amount_
            )
        );

        emit Bundle(
            trace,
            msg.sender,
            bundle_,
            token_,
            amount_
        );
    }

    /**
     * @notice Takes GCO2s tokens out of a bundle.
     * @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur.
     * @param bundle_ - The bundle token to input.
     * @param token_ - The GCO2 token to receive, must be part of the bundle.
     * @param amount_ - The amount of tokens.
     */
    function unbundle(
        address bundle_,
        address token_,
        uint256 amount_
    ) external payable {
        RemoteCarbonBundleToken rBundle = station.getBundle(bundle_);
        RemoteCarbonToken rToken = station.getToken(token_);
        require(rBundle.hasToken(rToken),
            'RemoteCarbonSender: token must be compatible with bundle');

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        station.burn(rBundle, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleUnbundle.selector,
                trace,
                station.chainId(),
                station.localToCentralBundles(bundle_),
                station.localToCentralTokens(token_),
                msg.sender,
                amount_
            )
        );

        emit Unbundle(
            trace,
            msg.sender,
            bundle_,
            token_,
            amount_
        );
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev For tracing blocks across blockchains. */
    function _getMessageTrace(address sender_, bytes memory data_) private view returns (bytes32) {
        return sha256(abi.encodePacked(block.number, station.chainId(), sender_, data_));
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import {CarbonAccessList} from '../../CarbonAccessList.sol';
import {ICarbonReceiver} from '../interfaces/ICarbonReceiver.sol';
import {RemoteCarbonStation} from '../RemoteCarbonStation.sol';
import {RemoteCarbonToken} from './RemoteCarbonToken.sol';
import {RemoteCarbonBundleToken} from './RemoteCarbonBundleToken.sol';
import {AbstractRemoteBaseCarbonToken} from '../abstracts/AbstractRemoteBaseCarbonToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Remote Carbon Receiver Contract
 */
contract RemoteCarbonReceiver is
        ICarbonReceiver,
        AccessControl {

    // ================
    // Public Constants
    // ================

    /**
     * @notice Transmitter role for access control.
     * @dev Transmitters are involved in cross-chain message delivery.
     */
    bytes32 public constant TRANSMITTER_ROLE = keccak256('TRANSMITTER_ROLE');

    // =================
    // Public Properties
    // =================

    /** @notice The local station that connects us to the cross-chain network. */
    RemoteCarbonStation public station;

    // ========================
    // Initialization Functions
    // ========================

    constructor(RemoteCarbonStation station_) {
        require(address(station_) != address(0),
            'RemoteCarbonReceiver: station is required');
        _grantRole(TRANSMITTER_ROLE, address(station_));
        station = station_;
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @dev Message handler for `CentralCarbonSender.syncToken`.
     * @param trace_ - Trace for tracking messages across chains.
     * @param blueprintId_ - The ID of the blueprint on the central chain.
     * @param token_ - The address on the central chain.
     * @param name_ - The name of the token.
     * @param symbol_ - The symbol of the token.
     * @param details_ - The details of the token.
     * @param accessList_ - The access-list of the token on the central chain.
     */
    function handleSyncToken(
        bytes32 trace_,
        uint blueprintId_,
        address token_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        address accessList_
    ) external onlyRole(TRANSMITTER_ROLE) {
        RemoteCarbonToken rToken;
        CarbonAccessList rAccessList = accessList_ == address(0)
            ? CarbonAccessList(address(0))
            : CarbonAccessList(station.centralToLocalAccessLists(accessList_));

        if (station.centralToLocalTokens(token_) == address(0)) {
            rToken = station.createToken(blueprintId_, token_, name_, symbol_, details_, rAccessList);
        } else {
            rToken = RemoteCarbonToken(station.centralToLocalTokens(token_));
            station.setAccessList(rToken, rAccessList);
        }
        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Message handler for `syncBundle`.
     * @param trace_ - Trace for tracking messages across chains.
     * @param blueprintId_ - The ID of the blueprint on the central chain.
     * @param bundle_ - The bundle on the central chain.
     * @param name_ - Tame of the bundle.
     * @param symbol_ - The symbol of the bundle.
     * @param vintage_ - Minimum vintage requirements of this bundle.
     */
    function handleSyncBundle(
         bytes32 trace_,
         uint blueprintId_,
         address bundle_,
         string memory name_,
         string memory symbol_,
         uint16 vintage_
    ) external onlyRole(TRANSMITTER_ROLE) {
        RemoteCarbonBundleToken _bundle;
        if (station.centralToLocalBundles(bundle_) == address(0)) {
            _bundle = station.createBundle(blueprintId_, bundle_, name_, symbol_, vintage_);
        } else {
            _bundle = RemoteCarbonBundleToken(station.centralToLocalBundles(bundle_));
            station.updateVintage(_bundle, vintage_);
        }
        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Message handler for `syncAccessList`.
     * @param trace_ - Trace for tracking messages across chains.
     * @param blueprintId_ - The ID of the blueprint on the central chain.
     * @param accessList_ - The address of the access-list on the central chain.
     * @param name_ - The name of the access-list.
     */
    function handleSyncAccessList(
        bytes32 trace_,
        uint blueprintId_,
        address accessList_,
        string memory name_
    ) external onlyRole(TRANSMITTER_ROLE) {
        // NOTE: Guaranteed by the central sender to be only synced once
        station.createAccessList(blueprintId_, accessList_, name_);

        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Update a access-list - it is guaranteed by the main chain to exist.
     * @param trace_ - Trace for tracking messages across chains.
     * @param accessList_ - The address of this access-list on the main chain.
     * @param account_ - The address of the account to add or remove.
     * @param hasAccess_ - Flag if access is granted or removed.
     */
    function handleRegisterAccess(
        bytes32 trace_,
        address accessList_,
        address account_,
        bool hasAccess_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.setGlobalAccess(
            CarbonAccessList(station.centralToLocalAccessLists(accessList_)),
            account_,
            hasAccess_
        );
        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Update a token - it is guaranteed by the main chain to exist.
     * @param trace_ - Trace for tracking messages across chains.
     * @param bundle_ - The address of bundle that should add/remove the token.
     * @param token_ - The address of the token.
     * @param isAdded_ - Flag if added or removed.
     * @param isPaused_ - Flag if token is paused.
     */
    function handleRegisterTokenForBundle(
        bytes32 trace_,
        address bundle_,
        address token_,
        bool isAdded_,
        bool isPaused_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.registerTokenForBundle(
            RemoteCarbonBundleToken(station.centralToLocalBundles(bundle_)),
            RemoteCarbonToken(station.centralToLocalTokens(token_)),
            isAdded_,
            isPaused_
        );

        emit MessageStatus(trace_, true);
    }

    /** @dev See ICarbonReceiver. */
    function handleSendToken(
        bytes32 trace_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.mint(
            AbstractRemoteBaseCarbonToken(station.centralToLocalTokens(token_)),
            recipient_,
            amount_
        );
        emit MessageStatus(trace_, true);
    }

    /** @dev See ICarbonReceiver. */
    function handleSendBundle(
        bytes32 trace_,
        address bundle_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.mint(
            AbstractRemoteBaseCarbonToken(station.centralToLocalBundles(bundle_)),
            recipient_,
            amount_
        );

        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Handles offsetting a specific token by increasing the offset for that token.
     * @param trace_ - Trace for tracking messages across chains.
     * @param token_ - The address of the token on the central chain.
     * @param beneficiary_ - The receiver of the token.
     * @param amount_ - The amount of the token.
     */
    function handleOffsetSpecificOnBehalfOfCallback(
        bytes32 trace_,
        address token_,
        address beneficiary_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.increaseOffset(
            RemoteCarbonToken(station.centralToLocalTokens(token_)),
            beneficiary_,
            amount_
        );
        emit MessageStatus(trace_, true);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IBaseCarbonToken} from '../../interfaces/IBaseCarbonToken.sol';
import {CarbonBundleToken} from '../../CarbonBundleToken.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import {RemoteCarbonReceiver} from '../remote/RemoteCarbonReceiver.sol';
import {ICarbonReceiver} from '../interfaces/ICarbonReceiver.sol';
import {CentralCarbonStation} from '../CentralCarbonStation.sol';

/**
 * @title Central Carbon Receiver Contract
 * @author Flowcarbon LLC
 */
contract CentralCarbonReceiver is
        ICarbonReceiver,
        AccessControl {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when we send a response to an OffsetSpecificOnBehalfOf message.
     * @param trace - The message trace.
     * @param success - The message success status.
     * @param account - The account that pays for the offset.
     * @param beneficiary - The account that benefits from the offset.
     * @param bundle - The bundle from which to offset.
     * @param token - The token to offset from the bundle.
     * @param amount - The amount of tokens to offset.
     */
    event OffsetSpecificOnBehalfOf(
        bytes32 trace,
        bool success,
        address account,
        address indexed beneficiary,
        address indexed bundle,
        address indexed token,
        uint256 amount
    );

    // ================
    // Public Constants
    // ================

    /**
     * @notice Transmitter role for access control.
     * @dev Transmitters are involved in cross-chain message delivery.
     */
    bytes32 public constant TRANSMITTER_ROLE = keccak256('TRANSMITTER_ROLE');

    // =================
    // Public Properties
    // =================

    /** @notice The central station that connects us to the cross-chain network. */
    CentralCarbonStation station;

    // ========================
    // Initialization Functions
    // ========================

    constructor(CentralCarbonStation station_) {
        require(address(station_) != address(0),
            'CentralCarbonReceiver: station is required');
        _grantRole(TRANSMITTER_ROLE, address(station_));
        station = station_;
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Protocol Functions
    // ==================

    /** @dev See IHandlerInterface. */
    function handleSendToken(
        bytes32 trace_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.transfer(IBaseCarbonToken(token_), recipient_, amount_);
        emit MessageStatus(trace_, true);
    }

    /** @dev See IHandlerInterface. */
    function handleSendBundle(
        bytes32 trace_,
        address bundle_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.transfer(IBaseCarbonToken(bundle_), recipient_, amount_);
        emit MessageStatus(trace_, true);
    }

    /** @dev Finalize received offsets from the treasury. */
    function handleProcessOffsets(
        bytes32 trace_,
        address token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        station.offset(IBaseCarbonToken(token_), amount_);
        emit MessageStatus(trace_, true);
    }

    /**
     * @dev Completes the bundling of tokens across chains.
     *      Sends back the bundle tokens or GCO2 on failure.
     */
    function handleBundle(
        bytes32 trace_,
        uint256 source_,
        address bundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        CarbonBundleToken bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);

        try station.bundle(bundle, token, amount_) {
            // Pay the fees in terms of bundle.
            uint256 amountAfterFees = station.deductPostageFee(source_, bundle, bundle, amount_, true);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    source_,
                    abi.encodeWithSelector(
                        RemoteCarbonReceiver.handleSendBundle.selector,
                        trace_,
                        bundle_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
            emit MessageStatus(trace_, true);
        } catch {
            // This is an edge-case when we removed the token on the main chain but it has not
            // been synced yet and someone tries to bundle.
            // We send back the tokens and take a postage fee in terms of the GCO2 token.
            uint256 amountAfterFees = station.deductPostageFee(source_, bundle, token, amount_, false);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    source_,
                    abi.encodeWithSelector(
                        RemoteCarbonReceiver.handleSendToken.selector,
                        trace_,
                        token_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
            emit MessageStatus(trace_, false);
        }
    }

    /**
     * @dev Completes the unbundling of tokens accross chains.
     *      Sends back the GCO2 tokens on success or bundle tokens on failure.
     */
    function handleUnbundle(
        bytes32 trace_,
        uint256 source_,
        address bundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        CarbonBundleToken bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);

        uint256 fee = station.feeMaster().getPostageFee(source_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(source_, bundle, bundle, amount_, false);
            // The provided amount is too low - do nothing.
            emit MessageStatus(trace_, false);
            return;
        }

        try station.unbundle(bundle, token, amount_ - fee) returns (uint256 amountUnbundled) {
            station.deductPostageFee(source_, bundle, bundle, amount_, true);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleSendToken.selector,
                    trace_,
                    token_,
                    recipient_,
                    amountUnbundled
                )
            );
            emit MessageStatus(trace_, true);
        } catch {
            uint256 amountAfterFees = station.deductPostageFee(source_, bundle, bundle, amount_, false);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleSendBundle.selector,
                    trace_,
                    bundle_,
                    recipient_,
                    amountAfterFees
                )
            );
            emit MessageStatus(trace_, false);
        }
    }

    /**
     * @dev Completes a bundle swap accross chains.
     *      Sends back the destination tokens on success or source tokens on failure.
     */
    function _handleSwapBundle(
        bytes32 trace_,
        uint256 source_,
        CarbonBundleToken sourceBundle_,
        CarbonBundleToken targetBundle_,
        CarbonToken token_,
        address recipient_,
        uint256 amount_,
        uint256 fee_
    ) internal returns (bool) {
        bool success = false;
        if (fee_ >= amount_) {
            station.deductPostageFee(source_, sourceBundle_, sourceBundle_, amount_, false);
            // The provided amount is too low - do nothing.
            return success;
        }

        try station.swapBundle(sourceBundle_, targetBundle_, token_, amount_ - fee_) returns (uint256 amountSwapped) {
            station.deductPostageFee(source_, sourceBundle_, sourceBundle_, amount_, true);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleSendBundle.selector,
                    trace_,
                    targetBundle_,
                    recipient_,
                    amountSwapped
                )
            );
            success = true;
        } catch {
            uint256 amountAfterFees = station.deductPostageFee(source_, sourceBundle_, sourceBundle_, amount_, false);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleSendBundle.selector,
                    trace_,
                    sourceBundle_,
                    recipient_,
                    amountAfterFees
                )
            );
        }
        return success;
    }

    /**
     * @dev Completes a bundle swap accross chains.
     *      Sends back the destination tokens on success or source tokens on failure.
     */
    function handleSwapBundle(
        bytes32 trace_,
        uint256 source_,
        address sourceBundle_,
        address targetBundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        CarbonBundleToken sourceBundle = station.conductor().getBundle(sourceBundle_);
        CarbonBundleToken targetBundle = station.conductor().getBundle(targetBundle_);
        CarbonToken token = station.conductor().getToken(token_);

        uint256 fee = station.feeMaster().getPostageFee(source_, sourceBundle, amount_, true);
        bool success = _handleSwapBundle(
            trace_,
            source_,
            sourceBundle,
            targetBundle,
            token,
            recipient_,
            amount_,
            fee
        );
        emit MessageStatus(trace_, success);
    }

    /**
     * @dev Completes offsetting a specific GCO2 token on behalf of a user.
     *      Send back the offsets on success or bundle tokens on failure.
     */
    function handleOffsetSpecificOnBehalfOf(
        bytes32 trace_,
        uint256 source_,
        address bundle_,
        address token_,
        address account_,
        address beneficiary_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        CarbonBundleToken bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);

        uint256 fee = station.feeMaster().getPostageFee(source_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(source_, bundle, bundle, amount_, false);
            // The provided amount is too low - do nothing.
            emit MessageStatus(trace_, false);
            return;
        }

        try station.offsetSpecific(bundle, token, amount_ - fee) returns (uint256 amountOffsetted) {
            station.deductPostageFee(source_, bundle, bundle, amount_, true);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleOffsetSpecificOnBehalfOfCallback.selector,
                    trace_,
                    token_,
                    beneficiary_,
                    amountOffsetted
                )
            );
            emit MessageStatus(trace_, true);
        } catch {
            uint256 amountAfterFees = station.deductPostageFee(source_, bundle, bundle, amount_, false);
            station.sendCallback(
                source_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleSendBundle.selector,
                    trace_,
                    bundle_,
                    account_,
                    amountAfterFees
                )
            );
            emit MessageStatus(trace_, false);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Route Receiver Interface
 */
interface IRouteReceiver {

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @notice Interface hook for inbound messages.
     * @param source_ - The chain ID from which this message was sent.
     * @param payload_ - The raw payload.
     */
    function handleSendMessage(uint256 source_, bytes memory payload_) external;
}

/** SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Route Interface
 */
interface IRoute {

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @dev The identifier format is ROUTE_NAME_v1.0.0.
     * @return Keccak256 encoded identifier.
     */
    function getIdentifier() external pure returns (bytes32);

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Send a message to the remote chain.
     * @param destination_ - The chain id to which we want to send the message.
     * @param payload_ - The raw payload to send.
     */
    function sendMessage(uint256 destination_, bytes memory payload_) payable external;

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @notice Connect a contract on the terminal chain to this chain.
     * @dev The target contract needs to be an IRouteReceiver.
     * @param destination_ - The chain id with the respective route endpoint contract.
     * @param contract_ - The address on the terminal chain.
     */
    function registerRemoteRoute(uint256 destination_, address contract_) external;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Carbon Sender Interface
 */
interface ICarbonSender {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when you send GCO2 tokens to a user on another blockchain.
     * @param destination - The target chain.
     * @param token - The address of the token on source chain.
     * @param sender - The sending address on origin chain.
     * @param recipient - The receiving address on target chain.
     * @param amount - The amount sent.
     */
    event SendToken(bytes32 trace, uint256 destination, address indexed sender, address indexed recipient, address indexed token,  uint256 amount);

    /**
     * @notice Emitted when you send bundle to a user on another blockchain.
     * @param destination - The target chain.
     * @param bundle - The address of the bundle on the source chain.
     * @param sender - The sending address on the source chain.
     * @param recipient - The receiving address on target chain.
     * @param amount - The amount sent.
     */
    event SendBundle(bytes32 trace, uint256 destination, address indexed sender, address indexed recipient, address indexed bundle, uint256 amount);

    // ================
    // Public Functions
    // ================

    /**
     * @notice Send GCO2 tokens to someone on a remote blockchain.
     * @param destination_ - The destination chain ID.
     * @param token_ - The address of the token to send.
     * @param recipient_ - The address of the recipient on the remote chain.
     * @param amount_ - The amount of tokens to be sent.
     */
    function sendToken(uint256 destination_, address token_, address recipient_, uint256 amount_) external payable;

    /**
     * @notice Send bundle tokens to someone on a remote blockchain.
     * @param destination_ - The destination chain ID.
     * @param bundle_ - The address of the token to send.
     * @param recipient_ - The address of the recipient on the remote chain.
     * @param amount_ - The amount of tokens to be sent.
     */
    function sendBundle(uint256 destination_, address bundle_, address recipient_, uint256 amount_) external payable;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Carbon Receiver Interface
 */
interface ICarbonReceiver {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted to give status update for cross-chain messages.
     * @param trace - Trace value of the original message.
     * @param status - Success flag.
     */
    event MessageStatus(bytes32 trace, bool status);

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @notice Handler for inbound GCO2 tokens.
     * @dev Edge case: this fails if the token is not synced, sync and retry in that case.
     * @param trace_ - Trace value of the original message.
     * @param sourceToken_ - The address of the token on the central network.
     * @param recipient_ - The receiver of the token.
     * @param amount_ - The amount of the token.
     */
    function handleSendToken(bytes32 trace_, address sourceToken_, address recipient_, uint256 amount_) external;

    /**
     * @notice Handler for inbound bundle tokens.
     * @dev Edge case: this fails if the token is not synced, sync and retry in that case.
     * @param trace_ - Trace value of the original message.
     * @param sourceBundle_ - The address of the token on the main chain.
     * @param recipient_ - The receiver of the token.
     * @param amount_ - The amount of the token.
     */
    function handleSendBundle(bytes32 trace_, address sourceBundle_, address recipient_, uint256 amount_) external;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import {IBaseCarbonToken} from '../interfaces/IBaseCarbonToken.sol';
import {CarbonToken} from '../CarbonToken.sol';
import {CarbonBundleToken} from '../CarbonBundleToken.sol';
import {CarbonConductor} from '../CarbonConductor.sol';
import {AbstractCarbonStation} from './abstracts/AbstractCarbonStation.sol';
import {CentralPostageFeeMaster} from './central/CentralPostageFeeMaster.sol';
import {CentralCarbonSender} from './central/CentralCarbonSender.sol';
import {CentralCarbonReceiver} from './central/CentralCarbonReceiver.sol';

/**
 * @author Flowcarbon LLC
 * @title Central Carbon Station Contract
 */
contract CentralCarbonStation is AbstractCarbonStation {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using SafeERC20Upgradeable for IBaseCarbonToken;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when a callback-type message is sent to a remote chain.
     * @dev Gives us a hint on when to refill the central station.
     * @param destination - The chain ID of the destination network.
     */
    event CallbackSent(uint256 destination);

    // =================
    // Public Properties
    // =================

    /** @notice The conductor hosts the factories and provides vital protocol functionality. */
    CarbonConductor public conductor;

    /** @notice The postage fee-master imposes a small fee on some transactions to prevent griefing. */
    CentralPostageFeeMaster public feeMaster;

    // ==================
    // Private Properties
    // ==================

    /** @dev Mapping to keep track of which access-lists have already been synced to remote chains. */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedAccessLists;

    /** @dev Mapping to keep track of which tokens have already been synced to remote chains. */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedTokens;

    /** @dev Mapping to keep track of which bundle token have already been synced to remote chains. */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedBundles;

    // ========================
    // Initialization Functions
    // ========================

    /** @notice Initialize proxy pattern. */
    function initialize(
        uint chainId_,
        CarbonConductor conductor_,
        CentralPostageFeeMaster feeMaster_,
        address operator_
    ) public initializer {
        require(address(conductor_) != address(0),
            'CentralCarbonStation: conductor is required');
        require(address(feeMaster_) != address(0),
            'CentralCarbonStation: postage fee-master is required');

        AbstractCarbonStation.initialize(
            chainId_,
            operator_,
            address(conductor_) == address(0) ? payable(0) : payable(conductor_.treasury())
        );
        conductor = conductor_;
        feeMaster = feeMaster_;
    }

    // ================
    // Public Functions
    // ================

    /**
     * @dev Reverts if the given access-list is not synced to the destination.
     * @param destination_ - The destination chain ID.
     * @param accessList_ - The address of the central access-list.
     */
    function requireAccessListSynced(uint256 destination_, address accessList_) external view {
        if (accessList_ != address(0)) {
            require(_syncedAccessLists[destination_].contains(accessList_),
                'CentralCarbonStation: access-list not synced');
        }
    }

    /**
     * @dev Revertes if the given access-list is already synced to the destination.
     * @param destination_ - The destination chain ID.
     * @param accessList_ - The address of the central access-list.
     */
    function requireAccessListNotSynced(uint256 destination_, address accessList_) external view {
        require(!_syncedAccessLists[destination_].contains(accessList_),
            'CentralCarbonStation: access-list already synced');
    }

    /**
     * @dev Reverts if the given token is not synced to the destination.
     * @param destination_ - The destination chain ID.
     * @param token_ - The address of the central token.
     */
    function requireTokenSynced(uint256 destination_, address token_) external view {
        require(_syncedTokens[destination_].contains(token_),
            'CentralCarbonStation: token not synced');
    }

    /**
     * @dev Reverts if the given bundle is not synced to the destination.
     * @param destination_ - The destination chain ID.
     * @param bundle_ - The address of the central bundle.
     */
    function requireBundleSynced(uint256 destination_, address bundle_) external view {
        require(_syncedBundles[destination_].contains(bundle_),
            'CentralCarbonStation: bundle not synced');
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Operators can swap the conductor contract. */
    function setConductor(CarbonConductor conductor_) external onlyRole(OPERATOR_ROLE) {
        require(address(conductor_) != address(0),
            'CentralCarbonStation: conductor is required');
        conductor = conductor_;
    }

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @dev Deduct the postage fee and send it to the treasury.
     * @param destination_ - The destination chain of the message - needed to calculate the fee.
     * @param bundle_ - The bundle for which the fee is levied.
     * @param feeToken_ - The token in terms of which the fee is paid - can be the bundle or an underlying GCO2.
     * @param amount_ - The amount in terms of the feeToken.
     * @param isSuccessPath_ - On success the fee might be waived, if amount exceeds the configured threshold.
     * @return The amount after fees.
     */
    function deductPostageFee(
        uint256 destination_,
        CarbonBundleToken bundle_,
        IBaseCarbonToken feeToken_,
        uint256 amount_,
        bool isSuccessPath_
    ) external onlyRole(TRANSMITTER_ROLE) returns (uint256) {
        uint256 fee = feeMaster.getPostageFee(destination_, bundle_, amount_, isSuccessPath_);
        if (amount_ <= fee) {
            feeToken_.safeTransfer(address(conductor.treasury()), amount_);
            return 0;
        }
        if (fee > 0) {
            feeToken_.safeTransfer(address(conductor.treasury()), fee);
        }
        return amount_ - fee;
    }

    /** @dev Runs after a token has been synced. */
    function onSyncToken(
        uint256 destination_,
        address token_
    ) external onlyRole(TRANSMITTER_ROLE) returns (bool) {
        return _syncedTokens[destination_].add(token_);
    }

    /** @dev Runs after a bundle has been synced. */
    function onSyncBundle(
        uint256 destination_,
        address bundle_
    ) external onlyRole(TRANSMITTER_ROLE) returns (bool) {
        conductor.getBundle(bundle_).approve(address(conductor), type(uint256).max);
        return _syncedBundles[destination_].add(bundle_);
    }

    /** @dev Runs after an access-list has been synced. */
    function onSyncAccessList(
        uint256 destination_,
        address accessList_
    ) external onlyRole(TRANSMITTER_ROLE) returns (bool) {
        return _syncedAccessLists[destination_].add(accessList_);
    }

    /** @dev Wrapper for access-control. */
    function transfer(
        IBaseCarbonToken token_,
        address recipient_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.safeTransfer(recipient_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function bundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function unbundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) returns (uint256){
        bundle_.approve(address(bundle_), amount_);
        return bundle_.unbundle(token_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function swapBundle(
        CarbonBundleToken sourceBundle_,
        CarbonBundleToken targetBundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) returns (uint256) {
        return conductor.swapBundle(sourceBundle_, targetBundle_, token_, amount_);
    }

    /** @dev Wrapper for access-control. */
    function offset(
        IBaseCarbonToken token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) {
        token_.offset(amount_);
    }

    /** @dev Wrapper for access-control. */
    function offsetSpecific(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyRole(TRANSMITTER_ROLE) returns (uint256) {
        return conductor.offsetSpecific(bundle_, token_, amount_);
    }

    /**
     * @dev Send a callback message to the source chain - postage fees apply.
     * @param destination_ - The chain ID from where the message originated.
     * @param payload_ - The message payload.
     */
    function sendCallback(uint256 destination_, bytes memory payload_) external onlyRole(TRANSMITTER_ROLE) {
        getRoute(destination_).sendMessage{
            value: feeMaster.getNativeFee(destination_)
        }(destination_, payload_);

        emit CallbackSent(destination_);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {CarbonBundleTokenFactory, CarbonBundleToken} from './CarbonBundleTokenFactory.sol';
import {CarbonTokenFactory, CarbonToken} from './CarbonTokenFactory.sol';
import {CarbonFeeMasterFactory, CarbonFeeMaster} from './CarbonFeeMasterFactory.sol';
import {CarbonAccessListFactory, CarbonAccessList} from './CarbonAccessListFactory.sol';
import {CarbonTreasury} from './CarbonTreasury.sol';

/**
 * @title Carbon Bundle Conductor Contract
 * @author Flowcarbon LLC
 */
contract CarbonConductor is AccessControl {

    using SafeERC20Upgradeable for CarbonBundleToken;

    using SafeERC20Upgradeable for CarbonToken;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when tokens are swapped betweens bundles.
     * @param account - The account that initiated the swap.
     * @param sourceBundle - The source bundle address.
     * @param targetBundle - The target bundle address.
     * @param token - The address of the token that was swapped.
     * @param amountIn - The amount swapped in terms of source bundle.
     * @param amountOut - The amount received after fees in terms of target bundle.
     */
    event SwapBundle(
        address account,
        address indexed sourceBundle,
        address indexed targetBundle,
        address indexed token,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @notice Emitted when a specific token from a bundle has been offsetted.
     * @param account - The account that is credited with the offset.
     * @param bundle - The bundle address.
     * @param token - The address of the token that has been offsetted.
     * @param amountIn - The amount to offset in terms of source bundle.
     * @param amountOffsetted - The amount offsetted after fees in terms of the token.
     */
    event OffsetSpecific(
        address indexed account,
        address indexed bundle,
        address indexed token,
        uint256 amountIn,
        uint256 amountOffsetted
    );

    // ================
    // Public Constants
    // ================

    /** @dev Operators take care of day-to-day operations in the protocol. */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    /** @dev Tokenizers are privileged external accounts that can mint and burn tokens in our protocol. */
    bytes32 public constant TOKENIZER_ROLE = keccak256('TOKENIZER_ROLE');

    // =================
    // Public Properties
    // =================

    /** @notice The carbon treasury contract. */
    CarbonTreasury public treasury;

    /** @notice The conductor operates the access-list factory. */
    CarbonAccessListFactory public accessListFactory;

    /** @notice The conductor operates the token factory. */
    CarbonTokenFactory public tokenFactory;

    /** @notice The conductor operates the bundle factory. */
    CarbonBundleTokenFactory public bundleFactory;

    /** @notice The conductor operates the the fee-master factory. */
    CarbonFeeMasterFactory public feeMasterFactory;

    /**
     * @notice Mapping of external batch identifiers to their checksums.
     * @dev We store these to simplify auditing.
     */
    mapping (bytes32 => string) public checksumRegistry;

    // ========================
    // Initialization Functions
    // ========================

    constructor (
        CarbonTreasury treasury_,
        CarbonAccessListFactory accessListFactory_,
        CarbonTokenFactory tokenFactory_,
        CarbonBundleTokenFactory bundleFactory_,
        CarbonFeeMasterFactory feeMasterFactory_,
        address operator_
    ) {
        require(address(treasury_) != address(0),
            'CarbonConductor: treasury is required');
        require(address(accessListFactory_) != address(0),
            'CarbonConductor: access-list factory is required');
        require(address(tokenFactory_) != address(0),
            'CarbonConductor: token factory is required');
        require(address(bundleFactory_) != address(0),
            'CarbonConductor: bundle factory is required');
        require(address(feeMasterFactory_) != address(0),
            'CarbonConductor: fee-master factory is required');
        require(operator_ != address(0),
            'CarbonConductor: operator is required');
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);

        treasury = treasury_;
        accessListFactory = accessListFactory_;
        tokenFactory = tokenFactory_;
        bundleFactory = bundleFactory_;
        feeMasterFactory = feeMasterFactory_;
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @notice Reverts if the given bundle address is not part of our protocol.
     * @param bundle_ - The address to check.
     * @return The bundle token.
     */
    function getBundle(address bundle_) public view returns (CarbonBundleToken) {
        require(bundleFactory.hasInstanceAt(bundle_),
            'CarbonConductor: unknown bundle');
        return CarbonBundleToken(bundle_);
    }

    /**
     * @notice Reverts if the given access-list address is not part of our protocol.
     * @param accessList_ - The address to check.
     * @return The access-list.
     */
    function getAccessList(address accessList_) external view returns (CarbonAccessList) {
        require(accessListFactory.hasInstanceAt(accessList_),
            'CarbonConductor: unknown access-list');
        return CarbonAccessList(accessList_);
    }

    /**
     * @notice Reverts if the given token address is not part of our protocol.
     * @param token_ - The address to check.
     * @return The GCO2 token.
     */
    function getToken(address token_) public view returns (CarbonToken) {
        require(tokenFactory.hasInstanceAt(token_),
            'CarbonConductor: unknown token');
        return CarbonToken(token_);
    }

    /**
     * @notice Get the fee-master at the given address, making sure it is part of our deployment.
     * @param feeMaster_ - The address of the fee-master.
     * @return The fee-master contract.
     */
    function getFeeMaster(address feeMaster_) public view returns (CarbonFeeMaster) {
        require(feeMasterFactory.hasInstanceAt(feeMaster_),
            'CarbonConductor: unknown fee-master');
        return CarbonFeeMaster(feeMaster_);
    }

    // ================
    // Public Functions
    // ================

    /**
     * @notice Swap the given GCO2 token between bundles.
     * @param sourceBundle_ - The source bundle of the swap.
     * @param targetBundle_ - The target bundle of the swap.
     * @param token_ - The token to swap.
     * @param amount_ - The amount of tokens to swap.
     * @return The amount of target bundle tokens received after fees.
     */
    function swapBundle(
        CarbonBundleToken sourceBundle_,
        CarbonBundleToken targetBundle_,
        CarbonToken token_,
        uint256 amount_
    ) external returns (uint256) {
        uint amountOut = _bundleAndTransfer(
            targetBundle_,
            token_,
            _transferFromAndUnbundle(sourceBundle_, token_, amount_)
        );

        emit SwapBundle(
            _msgSender(),
            address(sourceBundle_),
            address(targetBundle_),
            address(token_),
            amount_,
            amountOut
        );
        return amountOut;
    }

    /**
     * @notice Offsets a specific GCO2 token on behalf of the given address.
     * @param token_ - The GCO2 token to offset.
     * @param beneficiary_ - The address to be credited with the offset.
     * @param amount_ - The amount of tokens to offset.
     * @return The amount of tokens offsetted after fees.
     */
    function offsetSpecificOnBehalfOf(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        address beneficiary_,
        uint256 amount_
    ) public returns (uint256) {
        uint256 amountUnbundled = _transferFromAndUnbundle(bundle_, token_, amount_);
        token_.offsetOnBehalfOf(
            beneficiary_,
            amountUnbundled
        );

        emit OffsetSpecific(
            beneficiary_,
            address(bundle_),
            address(token_),
            amount_,
            amountUnbundled
        );
        return amountUnbundled;
    }

    /**
     * @notice Offset a specific GCO2 token from the bundle.
     * @param token_ - The GCO2 token to offset.
     * @param amount_ - The amount of tokens to offset.
     * @return The amount tokens offsetted after fees.
     */
    function offsetSpecific(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external returns (uint256) {
        return offsetSpecificOnBehalfOf(bundle_, token_, msg.sender, amount_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Create a new carbon token.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The token name.
     * @param symbol_ - The token symbol.
     * @param details_ - The token details structure.
     * @param accessList_ - Associated access-list.
     * @param operator_ - Account that is given operator privileges.
     * @return The created token.
     */
    function createToken(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        CarbonAccessList accessList_,
        address operator_
    ) external onlyRole(OPERATOR_ROLE) returns (CarbonToken) {
        return CarbonToken(tokenFactory.createToken(
            blueprintId_, name_, symbol_, details_, accessList_, operator_, payable(treasury)
        ));
    }

    /**
     * @notice Create a new access-list.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The access-list name.
     * @param operator_ - Account that is given operator privileges.
     * @return The created access-list.
     */
    function createAccessList(
        uint blueprintId_,
        string memory name_,
        address operator_
    ) external onlyRole(OPERATOR_ROLE) returns (CarbonAccessList) {
        return CarbonAccessList(accessListFactory.createAccessList(
            blueprintId_, name_, operator_
        ));
    }

    /**
     * @notice Create a new bundle.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param name_ - The bundle name.
     * @param symbol_ - The bundle symbol.
     * @param vintage_ - The minimum bundle vintage.
     * @param tokens_ - The tokens that are in the bundle.
     * @param maxFeePoints_ - The maximum unbundle fee in basis points.
     * @param operator_ - Account that is given operator privileges.
     * @return The created bundle.
     */
    function createBundle(
        uint blueprintId_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        uint256 maxFeePoints_,
        address operator_
    ) public onlyRole(OPERATOR_ROLE) returns (CarbonBundleToken) {
        CarbonBundleToken _bundle = CarbonBundleToken(bundleFactory.createBundle(
            blueprintId_, name_, symbol_, vintage_, tokens_, maxFeePoints_, operator_, payable(treasury)
        ));
        accessListFactory.appointTrustee(address(_bundle));
        return _bundle;
    }

    /**
     * @notice Create a new fee-master.
     * @param blueprintId_ - The ID of the blueprint to instantiate.
     * @param maxFee_ - The guaranteed maximum fee taken for unbundling.
     * @param operator_ - Account that is given operator privileges.
     * @return The created fee-master.
     */
    function createFeeMaster(
        uint blueprintId_,
        uint256 maxFee_,
        address operator_
    ) public onlyRole(OPERATOR_ROLE) returns (CarbonFeeMaster) {
        return CarbonFeeMaster(feeMasterFactory.createFeeMaster(
            blueprintId_, maxFee_, operator_
        ));
    }

    /**
     * @notice Creates a new fee-master and link it to a bundle.
     * @param feeMasterBlueprintId_ - The ID of the fee-master blueprint to use.
     * @param bundle_ - The bundle for which to create a new fee-master.
     * @param operator_ - The account that is given operator privileges.
     */
    function createFeeMasterForBundle(
        uint feeMasterBlueprintId_,
        CarbonBundleToken bundle_,
        address operator_
    ) public onlyRole(OPERATOR_ROLE) {
        CarbonFeeMaster feeMaster = createFeeMaster(
            feeMasterBlueprintId_, bundle_.maxFeePoints(), operator_
        );
        bundleFactory.setFeeMaster(bundle_, feeMaster);
    }

    /**
     * @notice Create a new bundle with an associated fee-master contract.
     * @param bundleBlueprintId_ - The ID of the bundle blueprint to use.
     * @param feeMasterBlueprintId_ - The ID of the fee-master blueprint to use.
     * @param name_ - The bundle name.
     * @param symbol_ - The bundle symbol.
     * @param vintage_ - The minimum bundle vintage.
     * @param tokens_ - The tokens that are in the bundle.
     * @param maxFeePoints_ - The maximum unbundle fee in basis points.
     * @param operator_ - Account that is given operator privileges.
     */
    function createBundleAndFeeMaster(
        uint bundleBlueprintId_,
        uint feeMasterBlueprintId_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        uint256 maxFeePoints_,
        address operator_
    ) external onlyRole(OPERATOR_ROLE) {
        CarbonBundleToken _bundle = createBundle(
            bundleBlueprintId_, name_, symbol_, vintage_, tokens_, maxFeePoints_, operator_
        );
        createFeeMasterForBundle(feeMasterBlueprintId_, _bundle, operator_);
    }

    /**
     * @notice Mint tokens from external sources to our protocol.
     * @param token_ - Token to mint.
     * @param account_ - The receiver of the freshly minted tokens.
     * @param amount_ - The amount of tokens to mint.
     * @param identifier_ - Audit-trail identifier.
     */
    function mintTokenWithExternalOrigin(
        CarbonToken token_,
        address account_,
        uint256 amount_,
        string memory identifier_
    ) public onlyRole(TOKENIZER_ROLE) {
        token_ = getToken(address(token_));
        bytes32 checksum = keccak256(abi.encodePacked(identifier_));
        checksumRegistry[checksum] = identifier_;
        token_.mint(account_, amount_, checksum);
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev Pulls in the tokens from the sender and unbundles it to the specified token.  */
    function _transferFromAndUnbundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) internal returns (uint256) {
        bundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        return bundle_.unbundle(token_, amount_);
    }

    /** @dev Takes GCO2 and sends back bundle tokens.  */
    function _bundleAndTransfer(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) internal returns (uint256) {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
        bundle_.safeTransfer(_msgSender(), amount_);
        return amount_;
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {CarbonBundleToken} from '../../CarbonBundleToken.sol';

/**
 * @author Flowcarbon LLC
 * @title Central Postage fee-master Contract
 */
contract CentralPostageFeeMaster is AccessControl {

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when the postage fee is changed.
     * @param destination - Fee set for a specific destination.
     * @param bundle - Address of the bundle token.
     * @param amount - Amount in terms of the bundle token.
     * @param refundTreshold - Threshold after which we take the fee.
     */
    event PostageFeeChanged(
        uint256 destination,
        address indexed bundle,
        uint256 amount,
        uint256 refundTreshold
    );

    /**
     * @notice Emitted when the postage fee is changed.
     * @param destination - Fee set for a specific destination.
     * @param amount - Amount in terms of the native token.
     */
    event NativeFeeChanged(
        uint256 destination,
        uint256 amount
    );

    // =================
    // Member Structures
    // =================

    /** @notice Postage fee settings structure. */
    struct PostageFeeConfig {
        // The bundle for which to take fees.
        CarbonBundleToken bundle;
        // Amount in terms of the bundle token.
        uint256 amount;
        // If the transaction amount exceeds this threshold, we waive the fee on success.
        uint256 refundThreshold;
    }

    // ================
    // Public Constants
    // ================

    /**
     * @notice Operator role for access control.
     * @dev Operators take care of day-to-day operations in the protocol.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    // ==================
    // Private Properties
    // ==================

    /** @notice Mapping of destination chain ID to postage fees. */
    mapping(uint256 => PostageFeeConfig[]) private _postageFees;

    /** @notice Mapping of destination chain ID to native fees. */
    mapping(uint256 => uint256) private _nativeFees;

    // ========================
    // Initialization Functions
    // ========================

    constructor() {
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @dev Defaults to 0.
     * @return The fee in terms of the native currency.
     */
    function getNativeFee(uint256 destination_) external view returns (uint256) {
        return _nativeFees[destination_];
    }

    /**
     * @param destination_ - The chain for which one is interested in the fees.
     * @param bundle_ - The bundle for which one is interested in the fees.
     * @param amount_ - The amount that is subject to fees.
     * @param onSuccess_ - Which path is this fee collected on? If successful, we might reimburse the fee :-)
     * @return The fee for a bundle and destination.
     */
    function getPostageFee(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amount_,
        bool onSuccess_
    ) external view returns (uint256) {
        uint256 index = _getConfigIndexOf(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            PostageFeeConfig memory feeConfig = _postageFees[destination_][index];
            if (onSuccess_ && amount_ >= feeConfig.refundThreshold) {
                return 0;
            }
            return _postageFees[destination_][index].amount;
        }
        // Free as a bird!
        return 0;
    }

    /**
     * @dev Successfull messages handling amounts larger than a configured threshold may have their fees reimbursed.
     * @return The threshold above which no fee is taken.
     */
    function getRefundThreshold(
        uint256 destination_,
        CarbonBundleToken bundle_
    ) external view returns (uint256) {
        uint256 index = _getConfigIndexOf(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            return _postageFees[destination_][index].refundThreshold;
        }
        revert('CentralPostageFeeMaster: missing refund threshold');
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Set the native fees for a destination. */
    function setNativeFee(uint256 destination_, uint256 amount_) external onlyRole(OPERATOR_ROLE) {
        _setNativeFee(destination_, amount_);
    }

    /** @dev Batch update fees. */
    function setNativeFeesInBatch(uint256[] memory destinations_, uint256[] memory amountsNative_) external onlyRole(OPERATOR_ROLE) {
        require(destinations_.length == amountsNative_.length,
            'CentralPostageFeeMaster: input length mismatch');

        for (uint256 i=0; i < destinations_.length; ++i) {
            _setNativeFee(destinations_[i], amountsNative_[i]);
        }
    }

    /** @dev Update the fee settings for a given bundle at a given a destination. */
    function setPostageFee(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amount_,
        uint256 refundThreshold_
    ) external onlyRole(OPERATOR_ROLE) {
        _setPostageFee(destination_, bundle_, amount_, refundThreshold_);
    }

    /** @notice Batch update fees. */
    function setPostageFeesInBatch(
        uint256[] memory destinations_,
        CarbonBundleToken[] memory bundles_,
        uint256[] memory amounts_,
        uint256[] memory refundThresholds_
    ) external onlyRole(OPERATOR_ROLE) {
        require(destinations_.length == bundles_.length,
            'CentralPostageFeeMaster: input length mismatch');
        require(destinations_.length == amounts_.length,
            'CentralPostageFeeMaster: input length mismatch');
        require(destinations_.length == refundThresholds_.length,
            'CentralPostageFeeMaster: input length mismatch');

        for (uint256 i=0; i < destinations_.length; ++i) {
            _setPostageFee(destinations_[i], bundles_[i], amounts_[i], refundThresholds_[i]);
        }
    }

    /** @dev See AccessControlUpgradeable. */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(),
            'AccessControl: can only renounce roles for self');
        require(role != DEFAULT_ADMIN_ROLE,
            'AccessControl: invalid attempt to renounce admin role');
        _revokeRole(role, account);
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev Set the native fees for a destination. */
    function _setNativeFee(uint256 destination_, uint256 amount_) internal {
        _nativeFees[destination_] = amount_;
    }

    /** @dev Update the fee structure for a given bundle at a given a destination. */
    function _setPostageFee(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amount_,
        uint256 refundThreshold_
    ) internal {
        uint256 index = _getConfigIndexOf(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            _postageFees[destination_][index] = PostageFeeConfig(
                bundle_,
                amount_,
                refundThreshold_
            );
        } else {
            _postageFees[destination_].push(PostageFeeConfig(
                    bundle_,
                    amount_,
                    refundThreshold_
                ));
        }
        emit PostageFeeChanged(
            destination_,
            address(bundle_),
            amount_,
            refundThreshold_
        );
    }

    /** @return The index of a postage fee or total number of entries if not found. */
    function _getConfigIndexOf(
        uint256 destination_,
        CarbonBundleToken bundle_
    ) internal view returns (uint256) {
        for (uint256 i=0; i < _postageFees[destination_].length; i++) {
            if (_postageFees[destination_][i].bundle == bundle_) {
                return i;
            }
        }
        return _postageFees[destination_].length;
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {AbstractBaseCarbonToken} from '../../abstracts/AbstractBaseCarbonToken.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import {CarbonBundleToken} from '../../CarbonBundleToken.sol';
import {CarbonAccessList} from '../../CarbonAccessList.sol';
import {RemoteCarbonReceiver} from '../remote/RemoteCarbonReceiver.sol';
import {ICarbonSender} from '../interfaces/ICarbonSender.sol';
import {ICarbonReceiver} from '../interfaces/ICarbonReceiver.sol';
import {CentralCarbonStation} from '../CentralCarbonStation.sol';

/**
 * @author Flowcarbon LLC
 * @title Central Carbon Sender Contract
 */
contract CentralCarbonSender is ICarbonSender {

    using SafeERC20Upgradeable for CarbonToken;

    using SafeERC20Upgradeable for CarbonBundleToken;

    // ==============
    // Emitted Events
    // ==============

    /**
     * @notice Emitted when a token is synced.
     * @param trace - Message id for tracking the tx.
     * @param destination - The target chain of the sync.
     * @param token - The address of the synced token.
     */
    event SyncToken(bytes32 trace, uint256 destination, address indexed token);

    /**
     * @notice Emitted when a bundle token is synced the tx.
     * @param trace - Message id for tracking the tx.
     * @param destination - The target chain of the sync.
     * @param bundle - The address of the synced bundle.
     */
    event SyncBundle(bytes32 trace, uint256 destination, address indexed bundle);

    /**
     * @notice Emitted when a access-list is synced.
     * @param trace - Message id for tracking the tx.
     * @param destination - The target chain of the sync.
     * @param accessList - The address of the synced access-list.
     */
    event SyncAccessList(bytes32 trace, uint256 destination, address indexed accessList);

    /**
     * @notice Emitted when a access is registered.
     * @param trace - Message id for tracking the tx.
     * @param destination - The target chain of the sync.
     * @param accessList - The address of the synced access-list.
     * @param account - Which account was registered.
     * @param hasAccess - Indicates if the access was granted or revoked.
     */
    event RegisterAccess(bytes32 trace, uint256 destination, address indexed accessList, address indexed account, bool hasAccess);

    /**
     * @notice Emitted when a token is registered.
     * @param trace - Message id for tracking the transaction across chains.
     * @param destination - The target chain of the sync.
     * @param token - The token being registered.
     * @param bundle - The bundle for which the token is registered/deregistered.
     * @param isAdded - True for adding, false for removal.
     * @param isPaused - True if paused, false if not.
     */
    event RegisterToken(bytes32 trace, uint256 destination, address indexed token, address indexed bundle, bool isAdded, bool isPaused);

    // =================
    // Public Properties
    // =================

    /** @notice The central station that connects us to cross-chain network. */
    CentralCarbonStation public station;

    // ========================
    // Initialization Functions
    // ========================

    constructor(CentralCarbonStation station_) {
        require(address(station_) != address(0),
            'CentralCarbonSender: station is required');
        station = station_;
    }

    // ================
    // Public Functions
    // ================

    /**
     * @notice Send tokens to an address on the destination chain.
     * @param destination_ - The target chain.
     * @param token_ - The token to send.
     * @param recipient_ - The recipient on the remote chain.
     * @param amount_ - The amount of tokens to be sent.
     * @dev Requires approval.
     */
    function sendToken(
        uint256 destination_,
        address token_,
        address recipient_,
        uint256 amount_
    ) public payable {
        station.requireTokenSynced(destination_, token_);
        CarbonToken token = station.conductor().getToken(token_);
        if (address(token.accessList()) != address(0)) {
            require(token.accessList().hasAccess(msg.sender),
                'CentralCarbonSender: the sender is not allowed to send this token');
            require(token.accessList().hasGlobalAccess(recipient_) || token.accessList().hasRemoteAccess(destination_, recipient_),
                'CentralCarbonSender: the recipient is not allowed to receive this token');
        }

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        token.safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                ICarbonReceiver.handleSendToken.selector,
                trace,
                token_,
                recipient_,
                amount_
            )
        );

        emit SendToken(trace, destination_, msg.sender, recipient_, token_, amount_);
    }

    /**
     * @notice Send bundle tokens to an address on the destination chain.
     * @param destination_ - The target chain.
     * @param bundle_ - The token to send.
     * @param recipient_ - The recipient on the remote chain.
     * @param amount_ - The amount of tokens to be sent.
     * @dev Requires approval.
     */
    function sendBundle(
        uint256 destination_,
        address bundle_,
        address recipient_,
        uint256 amount_
    ) public payable {
        station.requireBundleSynced(destination_, bundle_);
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        _bundle.safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSendBundle.selector,
                trace,
                bundle_,
                recipient_,
                amount_
            )
        );

        emit SendBundle(trace, destination_, msg.sender, recipient_, bundle_, amount_);
    }

    /**
     * @notice Place tokens into a bundle via cross-chain messaging.
     * @param bundle_ - The bundle to receive.
     * @param token_ - The token to bundle.
     * @param amount_ - The amount of tokens to bundle.
     * @dev Requires approval.
     */
    function bundle(
        address bundle_,
        address token_,
        uint256 amount_
    ) external {
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);
        token.transferFrom(msg.sender, address(this), amount_);
        token.approve(bundle_, amount_);
        _bundle.bundle(token, amount_);
        _bundle.transfer(msg.sender, amount_);
    }

    /**
     * @notice Remove tokens from a bundle via cross-chain messaging.
     * @param bundle_ - The bundle from which to remove the tokens.
     * @param token_ - The token to unbundle.
     * @param amount_ - The amount of tokens to unbundle.
     * @dev Requires approval.
     */
    function unbundle(
        address bundle_,
        address token_,
        uint256 amount_
    ) external {
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);
        _bundle.transferFrom(msg.sender, address(this), amount_);
        _bundle.approve(bundle_, amount_);
        uint256 amountUnbundled = _bundle.unbundle(token, amount_);
        token.transfer(msg.sender, amountUnbundled);
    }

    /**
     * @notice Swap tokens between bundles via cross-chain messaging.
     * @param sourceBundle_ - The bundle from which to remove the tokens.
     * @param targetBundle_ - The bundle to receive.
     * @param token_ - The token to swap.
     * @param amount_ - The amount of tokens to swap.
     * @dev Requires approval.
     */
    function swapBundle(
        address sourceBundle_,
        address targetBundle_,
        address token_,
        uint256 amount_
    ) external {
        CarbonBundleToken sourceBundle = station.conductor().getBundle(sourceBundle_);
        CarbonBundleToken targetBundle = station.conductor().getBundle(targetBundle_);
        CarbonToken token = station.conductor().getToken(token_);
        sourceBundle.transferFrom(msg.sender, address(this), amount_);
        sourceBundle.approve(address(station.conductor()), amount_);
        uint256 amountSwapped = station.conductor().swapBundle(sourceBundle, targetBundle, token, amount_);
        targetBundle.transfer(msg.sender, amountSwapped);
    }

    /**
     * @notice Offset tokens via cross-chain messaging.
     * @param token_ - The token to offset.
     * @param amount_ - The amount of tokens to offset.
     * @dev Requires approval.
     */
    function offset(
        address token_,
        uint256 amount_
    ) external {
        require(
            station.conductor().tokenFactory().hasInstanceAt(token_) || station.conductor().bundleFactory().hasInstanceAt(token_),
            'CentralCarbonSender: unknown token'
        );
        AbstractBaseCarbonToken token = AbstractBaseCarbonToken(token_);
        token.transferFrom(msg.sender, address(this), amount_);
        token.offsetOnBehalfOf(msg.sender, amount_);
    }

    /**
     * @notice Offset tokens on behalf of the given user via cross-chain messaging.
     * @param token_ - The token to offset.
     * @param beneficiary_ - The account to be credited with the offset.
     * @param amount_ - The amount of tokens to offset.
     * @dev Requires approval.
     */
    function offsetOnBehalfOf(
        address token_,
        address beneficiary_,
        uint256 amount_
    ) external {
        require(
            station.conductor().tokenFactory().hasInstanceAt(token_) || station.conductor().bundleFactory().hasInstanceAt(token_),
            'CentralCarbonSender: unknown token'
        );
        AbstractBaseCarbonToken token = AbstractBaseCarbonToken(token_);
        token.transferFrom(msg.sender, address(this), amount_);
        token.offsetOnBehalfOf(beneficiary_, amount_);
    }

    /**
     * @notice Offset a specific token from a bundle via cross-chain messaging.
     * @param bundle_ - The bundle containing the token to offset.
     * @param token_ - The token to offset.
     * @param amount_ - The amount of tokens to offset.
     * @dev Requires approval.
     */
    function offsetSpecific(
        address bundle_,
        address token_,
        uint256 amount_
    ) external {
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);
        _bundle.transferFrom(msg.sender, address(this), amount_);
        _bundle.approve(address(station.conductor()), amount_);
        station.conductor().offsetSpecificOnBehalfOf(_bundle, token, msg.sender, amount_);
    }

    /**
     * @notice Offset a specific token from a bundle on behalf of the given user via cross-chain messaging.
     * @param bundle_ - The bundle containing the token to offset.
     * @param token_ - The token to offset.
     * @param beneficiary_ - The account to be credited with the offset.
     * @param amount_ - The amount of tokens to offset.
     * @dev Requires approval.
     */
    function offsetSpecificOnBehalfOf(
        address bundle_,
        address token_,
        address beneficiary_,
        uint256 amount_
    ) external {
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = station.conductor().getToken(token_);
        _bundle.transferFrom(msg.sender, address(this), amount_);
        _bundle.approve(address(station.conductor()), amount_);
        station.conductor().offsetSpecificOnBehalfOf(_bundle, token, beneficiary_, amount_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Syncs a token to the terminal chain, giving it the full interface on the terminal chain.
     * @dev Syncs initially, subsequent calls update the access-list or do nothing but costing you fees.
     * @param destination_ - The terminal chain.
     * @param token_ - The address of the central token to sync.
     * @return True if the token is added for the first time, else false (on update).
     */
    function syncToken(
        uint256 destination_,
        address token_
    ) external payable returns (bool) {
        CarbonToken token = station.conductor().getToken(token_);
        CarbonAccessList accessList = token.accessList();
        station.requireAccessListSynced(destination_, address(accessList));

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        uint blueprintId = station.conductor().tokenFactory().blueprintIdOf(token_);
        CarbonToken.TokenDetails memory details = CarbonToken.TokenDetails(
            token.registry(),
            token.standard(),
            token.creditType(),
            token.vintage()
        );
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSyncToken.selector,
                trace, blueprintId, token_, ERC20Upgradeable(token_).name(), ERC20Upgradeable(token_).symbol(), details, accessList
            )
        );

        emit SyncToken(trace, destination_, token_);
        return station.onSyncToken(destination_, token_);
    }

    /**
     * @notice Syncs a bundle to the destination chain, allowing access to all functionality on a remote network.
     * @dev After syncing once, subsequent calls will update the vintage.
     * @param destination_ - The terminal chain.
     * @param bundle_ - The address of the central bundle to sync.
     * @return True if a new bundle was created, otherwise false.
     */
    function syncBundle(
        uint256 destination_,
        address bundle_
    ) external payable returns (bool) {
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        uint blueprintId = station.conductor().bundleFactory().blueprintIdOf(bundle_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSyncBundle.selector,
                trace, blueprintId, bundle_, ERC20Upgradeable(bundle_).name(), ERC20Upgradeable(bundle_).symbol(), _bundle.vintage()
            )
        );

        emit SyncBundle(trace, destination_, bundle_);
        return station.onSyncBundle(destination_, bundle_);
    }

    /**
     * @notice Sync an access-list over to the destination chain.
     * @param destination_ - The terminal chain.
     * @param accessList_ - The address of the central access-list to sync.
     * @return A flag if this action had an effect.
     */
    function syncAccessList(
        uint256 destination_,
        address accessList_
    ) external payable returns (bool) {
        station.requireAccessListNotSynced(destination_, accessList_);
        CarbonAccessList accessList = station.conductor().getAccessList(accessList_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        uint blueprintId = station.conductor().accessListFactory().blueprintIdOf(accessList_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSyncAccessList.selector,
                trace, blueprintId, accessList_, accessList.name()
            )
        );

        emit SyncAccessList(trace, destination_, accessList_);
        return station.onSyncAccessList(destination_, accessList_);
    }

    /**
     * @notice Registers access state to the destination chain.
     * @param destination_ - The terminal chain id.
     * @param accessList_ - Address of the access-list to register an account for.
     * @param account_ - The account to sync.
     * @return Flag that indicates if the access was added.
     */
    function registerAccess(
        uint256 destination_,
        address accessList_,
        address account_
    ) external payable returns (bool) {
        station.requireAccessListSynced(destination_, accessList_);
        CarbonAccessList accessList = station.conductor().getAccessList(accessList_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        bool hasAccess = accessList.hasGlobalAccess(account_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleRegisterAccess.selector,
                trace, accessList_, account_, hasAccess
            )
        );

        emit RegisterAccess(trace, destination_, accessList_, account_, hasAccess);
        return hasAccess;
    }

    /**
     * @notice Registers a token for a bundle.
     * @param destination_ - The target chain.
     * @param bundle_ - The bundle for which the token is registered.
     * @param token_ - The bundled token.
     * @return Flag indicating if the token was added or removed.
     */
    function registerTokenForBundle(
        uint256 destination_,
        address bundle_,
        address token_
    ) external payable returns (bool) {
        station.requireTokenSynced(destination_, token_);
        station.requireBundleSynced(destination_, bundle_);
        CarbonBundleToken _bundle = station.conductor().getBundle(bundle_);
        CarbonToken token = CarbonToken(token_);

        bytes32 trace = _getMessageTrace(msg.sender, msg.data);
        bool isAdded = _bundle.hasToken(token);
        bool isPaused = _bundle.isPausedForBundle(CarbonToken(token));
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleRegisterTokenForBundle.selector,
                trace, bundle_, token_, isAdded, isPaused
            )
        );
        emit RegisterToken(trace, destination_, token_, bundle_, isAdded, isPaused);
        return isAdded;
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev For tracing blocks accross chains. */
    function _getMessageTrace(address sender_, bytes memory data_) private view returns (bytes32) {
        return sha256(abi.encodePacked(block.number, station.chainId(), sender_, data_));
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractFactory} from './abstracts/AbstractFactory.sol';
import {CarbonFeeMaster} from './CarbonFeeMaster.sol';

/**
 * @author Flowcarbon LLC
 * @title Carbon Fee-Master Factory Contract
 */
contract CarbonFeeMasterFactory is AbstractFactory {

    // ========================
    // Initialization Functions
    // ========================

    /** @dev Initialize proxy pattern. */
    function initialize(address operator_) external initializer {
        require(operator_ != address(0),
            'CarbonAccessListFactory: operator is required');
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, operator_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Deploy a new fee-master.
     * @param feePoints_ - The maximum fee in basis points.
     * @param operator_ - The account that is granted operator privileges.
     * @return The address of the newly created fee-master.
     */
    function createFeeMaster(
        uint blueprintId_,
        uint256 feePoints_,
        address operator_
    ) external onlyRole(OPERATOR_ROLE) returns (address) {
        bytes memory initializer = abi.encodeWithSelector(
            CarbonFeeMaster(address(0)).initialize.selector,
            feePoints_, operator_
        );
        return _createBeaconProxy(blueprintId_, initializer);
    }
}