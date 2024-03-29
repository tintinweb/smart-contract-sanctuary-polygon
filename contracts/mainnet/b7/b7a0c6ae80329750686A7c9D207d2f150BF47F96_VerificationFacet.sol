// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IDAO
/// @author Aragon Association - 2022-2023
/// @notice The interface required for DAOs within the Aragon App DAO framework.
interface IDAO {
    /// @notice The action struct to be consumed by the DAO's `execute` function resulting in an external call.
    /// @param to The address to call.
    /// @param value The native token value to be sent with the call.
    /// @param data The bytes-encoded function selector and calldata for the call.
    struct Action {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the contract.
    /// @param _who The address of a EOA or contract to give the permissions.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionCondition` registered.
    /// @return Returns true if the address has permission, false if not.
    function hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) external view returns (bool);

    /// @notice Updates the DAO metadata (e.g., an IPFS hash).
    /// @param _metadata The IPFS hash of the new metadata object.
    function setMetadata(bytes calldata _metadata) external;

    /// @notice Emitted when the DAO metadata is updated.
    /// @param metadata The IPFS hash of the new metadata object.
    event MetadataSet(bytes metadata);

    /// @notice Executes a list of actions. If a zero allow-failure map is provided, a failing action reverts the entire excution. If a non-zero allow-failure map is provided, allowed actions can fail without the entire call being reverted.
    /// @param _callId The ID of the call. The definition of the value of `callId` is up to the calling contract and can be used, e.g., as a nonce.
    /// @param _actions The array of actions.
    /// @param _allowFailureMap A bitmap allowing execution to succeed, even if individual actions might revert. If the bit at index `i` is 1, the execution succeeds even if the `i`th action reverts. A failure map value of 0 requires every action to not revert.
    /// @return The array of results obtained from the executed actions in `bytes`.
    /// @return The resulting failure map containing the actions have actually failed.
    function execute(
        bytes32 _callId,
        Action[] memory _actions,
        uint256 _allowFailureMap
    ) external returns (bytes[] memory, uint256);

    /// @notice Emitted when a proposal is executed.
    /// @param actor The address of the caller.
    /// @param callId The ID of the call.
    /// @param actions The array of actions executed.
    /// @param failureMap The failure map encoding which actions have failed.
    /// @param execResults The array with the results of the executed actions.
    /// @dev The value of `callId` is defined by the component/contract calling the execute function. A `Plugin` implementation can use it, for example, as a nonce.
    event Executed(
        address indexed actor,
        bytes32 callId,
        Action[] actions,
        uint256 failureMap,
        bytes[] execResults
    );

    /// @notice Emitted when a standard callback is registered.
    /// @param interfaceId The ID of the interface.
    /// @param callbackSelector The selector of the callback function.
    /// @param magicNumber The magic number to be registered for the callback function selector.
    event StandardCallbackRegistered(
        bytes4 interfaceId,
        bytes4 callbackSelector,
        bytes4 magicNumber
    );

    /// @notice Deposits (native) tokens to the DAO contract with a reference string.
    /// @param _token The address of the token or address(0) in case of the native token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _reference The reference describing the deposit reason.
    function deposit(address _token, uint256 _amount, string calldata _reference) external payable;

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );

    /// @notice Emitted when a native token deposit has been made to the DAO.
    /// @dev This event is intended to be emitted in the `receive` function and is therefore bound by the gas limitations for `send`/`transfer` calls introduced by [ERC-2929](https://eips.ethereum.org/EIPS/eip-2929).
    /// @param sender The address of the sender.
    /// @param amount The amount of native tokens deposited.
    event NativeTokenDeposited(address sender, uint256 amount);

    /// @notice Setter for the trusted forwarder verifying the meta transaction.
    /// @param _trustedForwarder The trusted forwarder address.
    function setTrustedForwarder(address _trustedForwarder) external;

    /// @notice Getter for the trusted forwarder verifying the meta transaction.
    /// @return The trusted forwarder address.
    function getTrustedForwarder() external view returns (address);

    /// @notice Emitted when a new TrustedForwarder is set on the DAO.
    /// @param forwarder the new forwarder address.
    event TrustedForwarderSet(address forwarder);

    /// @notice Setter for the [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    /// @param _signatureValidator The address of the signature validator.
    function setSignatureValidator(address _signatureValidator) external;

    /// @notice Emitted when the signature validator address is updated.
    /// @param signatureValidator The address of the signature validator.
    event SignatureValidatorSet(address signatureValidator);

    /// @notice Checks whether a signature is valid for the provided hash by forwarding the call to the set [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    /// @param _hash The hash of the data to be signed.
    /// @param _signature The signature byte array associated with `_hash`.
    /// @return Returns the `bytes4` magic value `0x1626ba7e` if the signature is valid.
    function isValidSignature(bytes32 _hash, bytes memory _signature) external returns (bytes4);

    /// @notice Registers an ERC standard having a callback by registering its [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID and callback function signature.
    /// @param _interfaceId The ID of the interface.
    /// @param _callbackSelector The selector of the callback function.
    /// @param _magicNumber The magic number to be registered for the function signature.
    function registerStandardCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSelector,
        bytes4 _magicNumber
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {IDAO} from "../../dao/IDAO.sol";
import {_auth} from "../../utils/auth.sol";

/// @title DaoAuthorizable
/// @author Aragon Association - 2022-2023
/// @notice An abstract contract providing a meta-transaction compatible modifier for non-upgradeable contracts instantiated via the `new` keyword to authorize function calls through an associated DAO.
abstract contract DaoAuthorizable is Context {
    /// @notice The associated DAO managing the permissions of inheriting contracts.
    IDAO private immutable dao_;

    /// @notice Constructs the contract by setting the associated DAO.
    /// @param _dao The associated DAO address.
    constructor(IDAO _dao) {
        dao_ = _dao;
    }

    /// @notice Returns the DAO contract.
    /// @return The DAO contract.
    function dao() public view returns (IDAO) {
        return dao_;
    }

    /// @notice A modifier to make functions on inheriting contracts authorized. Permissions to call the function are checked through the associated DAO's permission manager.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(bytes32 _permissionId) {
        _auth(dao_, address(this), _msgSender(), _permissionId, _msgData());
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/// @title IPlugin
/// @author Aragon Association - 2022-2023
/// @notice An interface defining the traits of a plugin.
interface IPlugin {
    enum PluginType {
        UUPS,
        Cloneable,
        Constructable
    }

    /// @notice returns the plugin's type
    function pluginType() external view returns (PluginType);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {IDAO} from "../../dao/IDAO.sol";

/// @title IProposal
/// @author Aragon Association - 2022-2023
/// @notice An interface to be implemented by DAO plugins that define membership.
interface IMembership {
    /// @notice Emitted when members are added to the DAO plugin.
    /// @param members The list of new members being added.
    event MembersAdded(address[] members);

    /// @notice Emitted when members are removed from the DAO plugin.
    /// @param members The list of existing members being removed.
    event MembersRemoved(address[] members);

    /// @notice Emitted to announce the membership being defined by a contract.
    /// @param definingContract The contract defining the membership.
    event MembershipContractAnnounced(address indexed definingContract);

    /// @notice Checks if an account is a member of the DAO.
    /// @param _account The address of the account to be checked.
    /// @return Whether the account is a member or not.
    /// @dev This function must be implemented in the plugin contract that introduces the members to the DAO.
    function isMember(address _account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {IDAO} from "../dao/IDAO.sol";
import {DaoAuthorizable} from "./dao-authorizable/DaoAuthorizable.sol";
import {IPlugin} from "./IPlugin.sol";

/// @title Plugin
/// @author Aragon Association - 2022-2023
/// @notice An abstract, non-upgradeable contract to inherit from when creating a plugin being deployed via the `new` keyword.
abstract contract Plugin is IPlugin, ERC165, DaoAuthorizable {
    /// @notice Constructs the plugin by storing the associated DAO.
    /// @param _dao The DAO contract.
    constructor(IDAO _dao) DaoAuthorizable(_dao) {}

    /// @inheritdoc IPlugin
    function pluginType() public pure override returns (PluginType) {
        return PluginType.Constructable;
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPlugin).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {IDAO} from "../dao/IDAO.sol";

/// @notice Thrown if a call is unauthorized in the associated DAO.
/// @param dao The associated DAO.
/// @param where The context in which the authorization reverted.
/// @param who The address (EOA or contract) missing the permission.
/// @param permissionId The permission identifier.
error DaoUnauthorized(address dao, address where, address who, bytes32 permissionId);

/// @notice A free function checking if a caller is granted permissions on a target contract via a permission identifier that redirects the approval to a `PermissionCondition` if this was specified in the setup.
/// @param _where The address of the target contract for which `who` recieves permission.
/// @param _who The address (EOA or contract) owning the permission.
/// @param _permissionId The permission identifier.
/// @param _data The optional data passed to the `PermissionCondition` registered.
function _auth(
    IDAO _dao,
    address _where,
    address _who,
    bytes32 _permissionId,
    bytes calldata _data
) view {
    if (!_dao.hasPermission(_where, _who, _permissionId, _data))
        revert DaoUnauthorized({
            dao: address(_dao),
            where: _where,
            who: _who,
            permissionId: _permissionId
        });
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
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/mudgen/diamond-2-hardhat/blob/main/contracts/interfaces/IDiamondCut.sol
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove, AddWithInit, RemoveWithDeinit}
    // Add=0, Replace=1, Remove=2, AddWithInit=3, RemoveWithDeinit=4

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
        bytes initCalldata;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(
        FacetCut[] calldata _diamondCut
    ) external;

    event DiamondCut(FacetCut[] _diamondCut);
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import { IMembership } from "@aragon/osx/core/plugin/membership/IMembership.sol";

/**
 * @title IDAOReferenceFacet
 * @author Utrecht University
 * @notice This interface is an extension upon Aragons IMembership.
 * It allows to query is a wallet was a member at a certain timestamp.
 * It allows to get a list of all wallets that were a member at some point.
 */
interface IMembershipExtended is IMembership {
    /// @inheritdoc IMembership
    function isMember(address _account) external view override returns (bool);

    /// Returns whether an account was a member at a given timestamp
    function isMemberAt(address _account, uint256 _blockNumber) external view returns (bool);

    /// Returns all accounts that were a member at some point
    /// @dev Can be used to loop over all members, loop over this array with filter isMember
    function getMembers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */


pragma solidity ^0.8.0;

/**
 * @title IMembershipWhitelisting
 * @author Utrecht University
 * @notice This interface allows a wallet to be whitelisted, bypassing the usual verification requirements.
 */
interface IMembershipWhitelisting {
    /// @notice Whitelist an address.
    /// @param _address The address to whitelist.
    /// @dev Whitelist verification never expires.
    function whitelist(address _address) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import { IMembershipExtended, IMembership } from "./IMembershipExtended.sol";

/**
 * @title ITieredMembershipStructure
 * @author Utrecht University
 * @notice This interface extends IMembershipExtended, distinguishing members into tiers.
 */
abstract contract ITieredMembershipStructure is IMembershipExtended {
    /// @inheritdoc IMembershipExtended
    function isMember(address _account) external view virtual override returns (bool) {
        return _isMemberAt(_account, block.number);
    }

    /// @inheritdoc IMembershipExtended
    function isMemberAt(address _account, uint256 _blockNumber) external view override returns (bool) {
        return _isMemberAt(_account, _blockNumber);
    }

    /// @dev This internal copy is needed to be able to call the function from inside the contract
    /// This function is used by the isMember function given the latest block timestamp
    function _isMemberAt(address _account, uint256 _blockNumber) internal view virtual returns (bool) {
        return getTierAt(_account, _blockNumber) > 0;
    }

    /// @inheritdoc IMembershipExtended
    function getMembers() external view virtual override returns (address[] memory);

    /// @notice Returns the tier score for an accout at a given timestamp
    function getTierAt(address _account, uint256 _blockNumber) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
 * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
 * © Copyright Utrecht University (Department of Information and Computing Sciences)
 */

pragma solidity ^0.8.0;

import { LibDiamond } from  "../libraries/LibDiamond.sol";

/**
 * @title IFacet
 * @author Utrecht University
 * @notice This interface is the base of all facets.
 * @dev Alwasys inherit this interface of all facets you create and use it to (un)register interfaces.
 */
abstract contract IFacet {
    // Should be called by inheritors too, thats why public
    function init(bytes memory _initParams) public virtual {}

    function deinit() public virtual {}

    function registerInterface(bytes4 _interfaceId) internal virtual {
        LibDiamond.diamondStorage().supportedInterfaces[_interfaceId] = true;
    }

    function unregisterInterface(bytes4 _interfaceId) internal virtual {
        LibDiamond.diamondStorage().supportedInterfaces[_interfaceId] = false;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "LibDiamond: Facet method can only be called by itself");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */


pragma solidity ^0.8.0;

import { SignVerification } from "../../other/verification/SignVerification.sol";

/**
 * @title IVerificationFacet
 * @author Utrecht University
 * @notice This interface defines verification stamps that wallets can have.
 */
interface IVerificationFacet {
    /// @notice Returns all stamps of an account.
    /// @param _address The address to get stamps from.
    /// @return stamps The stamps of the account.
    function getStamps(address _address) external view returns (SignVerification.Stamp[] memory);

    /// @notice Returns stamps of an account at a given block number
    /// @param _address The address to get stamps from
    /// @param _blockNumber The block number to get stamps at
    /// @return stamps The stamps of the account.
    function getStampsAt(address _address, uint _blockNumber) external view returns (SignVerification.Stamp[] memory);

    /// @notice Returns the current verification contract address
    /// @return address of the verification contract
    function getVerificationContractAddress() external view returns (address);

    /// @notice Updates the verification contract address
    /// @param _verificationContractAddress The new verification contract address
    function setVerificationContractAddress(address _verificationContractAddress) external;

    /// @notice Returns the current verification contract address
    function getTierMapping(string calldata _providerId) external view returns (uint256);

    /// @notice Updates a "tier" score for a given provider. This can be used to either score new providers or update
    /// scores of already scored providers
    /// @dev This maps a providerId to a uint256 tier
    function setTierMapping(string calldata _providerId, uint256 _tier) external;

    /// @notice Returns the amount of days that a stamp is valid for (latest value)
    /// @dev This function interacts with the verification contract to get the day threshold
    function getVerifyThreshold() external view returns (uint);

    /// @notice Updates the amount of days that a stamp is valid for
    /// @dev This function interacts with the verification contract to update the day threshold
    /// @param _verifyThreshold The new amount of days that a stamp is valid for
    function setVerifyThreshold(uint _verifyThreshold) external;

    /// @notice Returns the amount of days that a stamp is valid for
    /// @dev This function interacts with the verification contract to get the reverification threshold
    function getReverifyThreshold() external view returns (uint);

    /// @notice Updates the amount of days that a stamp is valid for
    /// @dev This function interacts with the verification contract to update the reverification threshold
    /// @param _reverifyThreshold The new amount of days that a stamp is valid for
    function setReverifyThreshold(uint _reverifyThreshold) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

import {IDAO} from "@aragon/osx/core/plugin/Plugin.sol";
import {LibVerificationStorage} from "../../libraries/storage/LibVerificationStorage.sol";
import { ITieredMembershipStructure, IMembershipExtended, IMembership } from "../../facets/governance/structure/membership/ITieredMembershipStructure.sol";
import { IMembershipWhitelisting } from "../../facets/governance/structure/membership/IMembershipWhitelisting.sol";
import { AuthConsumer } from "../../utils/AuthConsumer.sol";
import { IVerificationFacet, SignVerification } from "./IVerificationFacet.sol";
import { IFacet } from "../IFacet.sol";

/**
 * @title VerificationFacet
 * @author Utrecht University
 * @notice Implementation of ITieredMembershipStructure, IMembershipWhitelisting and IVerificationFacet.
 */
contract VerificationFacet is ITieredMembershipStructure, IMembershipWhitelisting, IVerificationFacet, AuthConsumer, IFacet {
    // Permission used by the updateTierMapping function
    bytes32 public constant UPDATE_TIER_MAPPING_PERMISSION_ID = keccak256("UPDATE_TIER_MAPPING_PERMISSION");
    // Permission used by the whitelist function
    bytes32 public constant WHITELIST_MEMBER_PERMISSION_ID = keccak256("WHITELIST_MEMBER_PERMISSION");
    // Permission used to update the verification contract address
    bytes32 public constant UPDATE_VERIFICATION_CONTRACT_PERMISSION_ID = keccak256("UPDATE_VERIFICATION_CONTRACT_PERMISSION");
    // Permission used to update the verification day threshold
    bytes32 public constant UPDATE_VERIFY_DAY_THRESHOLD_PERMISSION_ID = keccak256("UPDATE_VERIFY_DAY_THRESHOLD_PERMISSION");
    // Permission used to update the reverification day threshold
    bytes32 public constant UPDATE_REVERIFICATION_THRESHOLD_PERMISSION_ID = keccak256("UPDATE_REVERIFICATION_THRESHOLD_PERMISSION");

    struct VerificationFacetInitParams {
        address verificationContractAddress;
        string[] providers;
        uint256[] rewards;
    }

    /// @inheritdoc IFacet
    function init(bytes memory _initParams) public virtual override {
        VerificationFacetInitParams memory _params = abi.decode(_initParams, (VerificationFacetInitParams));
        __VerificationFacet_init(_params);
    }

    function __VerificationFacet_init(VerificationFacetInitParams memory _params) public virtual {
        LibVerificationStorage.Storage storage s = LibVerificationStorage.getStorage();

        s.verificationContractAddress = _params.verificationContractAddress;
        require(_params.providers.length == _params.rewards.length, "Providers and rewards array length does not match");
        for (uint i; i < _params.providers.length;) {
            s.tierMapping[_params.providers[i]] = _params.rewards[i];

            unchecked {
                i++;
            }
        }

        registerInterface(type(IMembership).interfaceId);
        registerInterface(type(IMembershipExtended).interfaceId);
        registerInterface(type(ITieredMembershipStructure).interfaceId);
        registerInterface(type(IMembershipWhitelisting).interfaceId);
        registerInterface(type(IVerificationFacet).interfaceId);
        
        emit MembershipContractAnnounced(address(this));
    }
    
    /// @inheritdoc IFacet
    function deinit() public virtual override {
        unregisterInterface(type(IMembership).interfaceId);
        unregisterInterface(type(IMembershipExtended).interfaceId);
        unregisterInterface(type(ITieredMembershipStructure).interfaceId);
        unregisterInterface(type(IMembershipWhitelisting).interfaceId);
        unregisterInterface(type(IVerificationFacet).interfaceId);
        super.deinit();
    }

    /// @notice Whitelist a given account
    /// @inheritdoc IMembershipWhitelisting
    function whitelist(address _address) external virtual override auth(WHITELIST_MEMBER_PERMISSION_ID) {
        LibVerificationStorage.getStorage().whitelistBlockNumbers[_address] = block.number;
    }

    /// @notice Returns the given address as a string
    /// Source: https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    /// @notice Returns the ascii character related to a byte
    /// @dev Helper function for toAsciiString
    /// Source: https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    /// @inheritdoc IVerificationFacet
    function getStampsAt(
        address _address,
        uint _blockNumber
    ) public view virtual override returns (SignVerification.Stamp[] memory) {
        LibVerificationStorage.Storage storage ds = LibVerificationStorage.getStorage();
        SignVerification verificationContract = SignVerification(ds.verificationContractAddress);
        SignVerification.Stamp[] memory stamps = verificationContract.getStampsAt(
            _address,
            _blockNumber
        );

        // Check if this account was whitelisted and add a "whitelist" stamp if applicable
        uint whitelistBlockNumber = ds.whitelistBlockNumbers[_address];
        if (whitelistBlockNumber == 0) {
            return stamps;
        } else {
            SignVerification.Stamp[] memory stamps2 = new SignVerification.Stamp[](
                stamps.length + 1
            );

            uint[] memory verifiedAt = new uint[](1);
            verifiedAt[0] = whitelistBlockNumber;

            SignVerification.Stamp memory stamp = SignVerification.Stamp(
                "whitelist",
                toAsciiString(_address),
                verifiedAt
            );

            stamps2[0] = stamp;

            for (uint i = 0; i < stamps.length; i++) {
                stamps2[i + 1] = stamps[i];
            }

            return stamps2;
        }
    }

    /// @inheritdoc IVerificationFacet
    function getStamps(address _address) external view override returns (SignVerification.Stamp[] memory) {
        LibVerificationStorage.Storage storage ds = LibVerificationStorage.getStorage();
        SignVerification verificationContract = SignVerification(ds.verificationContractAddress);
        SignVerification.Stamp[] memory stamps = verificationContract.getStamps(_address);

        // Check if this account was whitelisted and add a "whitelist" stamp if applicable
        uint whitelistBlockNumber = ds.whitelistBlockNumbers[_address];
        if (whitelistBlockNumber == 0) {
            return stamps;
        } else {
            SignVerification.Stamp[] memory stamps2 = new SignVerification.Stamp[](
                stamps.length + 1
            );

            uint[] memory verifiedAt = new uint[](1);
            verifiedAt[0] = whitelistBlockNumber;

            SignVerification.Stamp memory stamp = SignVerification.Stamp(
                "whitelist",
                toAsciiString(_address),
                verifiedAt
            );

            stamps2[0] = stamp;

            for (uint i = 0; i < stamps.length; i++) {
                stamps2[i + 1] = stamps[i];
            }

            return stamps2;
        }
    }

    /// @inheritdoc ITieredMembershipStructure
    function getMembers() external view virtual override returns (address[] memory members) {
        LibVerificationStorage.Storage storage ds = LibVerificationStorage.getStorage();
        SignVerification verificationContract = SignVerification(ds.verificationContractAddress);
        return verificationContract.getAllMembers();
    }

    /// @inheritdoc ITieredMembershipStructure
    /// @notice Returns the highest tier included in the stamps of a given account
    function getTierAt(address _account, uint256 _blockNumber) public view virtual override returns (uint256) {
        SignVerification.Stamp[] memory stampsAt = getStampsAt(_account, _blockNumber);

        LibVerificationStorage.Storage storage ds = LibVerificationStorage.getStorage();
        mapping (string => uint256) storage tierMapping = ds.tierMapping;

        uint256 tier = 0;

        // Set highest tier score in stamps
        for (uint8 i = 0; i < stampsAt.length; i++) {
            uint256 currentTier = tierMapping[stampsAt[i].providerId];
            if (currentTier > tier)
                tier = currentTier;
        }

        return tier;
    }

    /// @inheritdoc IVerificationFacet
    function getTierMapping(string calldata _providerId) external view virtual override returns (uint256) {
        return LibVerificationStorage.getStorage().tierMapping[_providerId];
    }

    /// @inheritdoc IVerificationFacet
    function setTierMapping(string calldata _providerId, uint256 _tier) external virtual override auth(UPDATE_TIER_MAPPING_PERMISSION_ID) {
        LibVerificationStorage.getStorage().tierMapping[_providerId] = _tier;
    }

    /// @inheritdoc IVerificationFacet
    function getVerificationContractAddress() external view virtual override returns (address) {
        return LibVerificationStorage.getStorage().verificationContractAddress;
    }

    /// @inheritdoc IVerificationFacet
    function setVerificationContractAddress(address _verificationContractAddress) external virtual override auth(UPDATE_VERIFICATION_CONTRACT_PERMISSION_ID) {
        LibVerificationStorage.getStorage().verificationContractAddress = _verificationContractAddress; 
    }

    /// @inheritdoc IVerificationFacet
    function getVerifyThreshold() external view returns (uint) {
        SignVerification verificationContract = SignVerification(LibVerificationStorage.getStorage().verificationContractAddress);
        return verificationContract.getVerifyThreshold();
    }

    /// @inheritdoc IVerificationFacet
    function setVerifyThreshold(uint _verifyThreshold) external auth(UPDATE_VERIFY_DAY_THRESHOLD_PERMISSION_ID) {
        SignVerification verificationContract = SignVerification(LibVerificationStorage.getStorage().verificationContractAddress);
        verificationContract.setVerifyThreshold(_verifyThreshold);
    }

    /// @inheritdoc IVerificationFacet
    function getReverifyThreshold() external view returns (uint) {
        SignVerification verificationContract = SignVerification(LibVerificationStorage.getStorage().verificationContractAddress);
        return verificationContract.getReverifyThreshold();
    }

    /// @inheritdoc IVerificationFacet
    function setReverifyThreshold(uint _reverifyThreshold) external auth(UPDATE_REVERIFICATION_THRESHOLD_PERMISSION_ID) {
        SignVerification verificationContract = SignVerification(LibVerificationStorage.getStorage().verificationContractAddress);
        verificationContract.setReverifyThreshold(_reverifyThreshold);
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */
 // This contract is based on https://github.com/mudgen/diamond-2-hardhat/blob/main/contracts/libraries/LibDiamond.sol

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../additional-contracts/IDiamondCut.sol";
import { IFacet } from "../facets/IFacet.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex]
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        IDiamondCut.FacetCut memory _facetCut
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_facetCut.functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");

        if (_facetCut.action == IDiamondCut.FacetCutAction.AddWithInit || _facetCut.action == IDiamondCut.FacetCutAction.RemoveWithDeinit) {
            // Call IFacet (de)init function on diamond cut add/remove action
            (bool success, bytes memory error) = _facetCut.facetAddress.delegatecall(_facetCut.initCalldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up error
                    /// @solidity memory-safe-assembly
                    assembly {
                        let returndata_size := mload(error)
                        revert(add(32, error), returndata_size)
                    }
                } else {
                    revert InitializationFunctionReverted(_facetCut.facetAddress, _facetCut.initCalldata);
                }
            }
        }

        if (_facetCut.action == IDiamondCut.FacetCutAction.Add || _facetCut.action == IDiamondCut.FacetCutAction.AddWithInit) {
            enforceHasContractCode(_facetCut.facetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_facetCut.facetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_facetCut.action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_facetCut.facetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _facetCut.facetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_facetCut.facetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_facetCut.action == IDiamondCut.FacetCutAction.Remove || _facetCut.action == IDiamondCut.FacetCutAction.RemoveWithDeinit) {
            require(_facetCut.facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");

            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _facetCut.functionSelectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _facetCut.functionSelectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8" 
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

library LibVerificationStorage {
    bytes32 constant VERIFICATION_STORAGE_POSITION =
        keccak256("verification.diamond.storage.position");

    struct Storage {
        /// @notice mapping from whitelisted address to timestamp of whitelisting
        mapping(address => uint) whitelistBlockNumbers;
        /// @notice mapping from providerId to tier score
        mapping(string => uint256) tierMapping;
        address verificationContractAddress;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = VERIFICATION_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
 * © Copyright Utrecht University (Department of Information and Computing Sciences)
 */

pragma solidity ^0.8.0;

import {GenericSignatureHelper} from "../../utils/GenericSignatureHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SignVerification
 * @author Utrecht University
 * @notice This contracat requires a signer to provide proof of verification with a certain offchain service (example: GitHub) and assigns the respecitve stamp to the address.
 */
contract SignVerification is GenericSignatureHelper, Ownable {
    // Map from user to their stamps
    mapping(address => Stamp[]) internal stamps;
    // Map from userhash to address to make sure the userhash isn't already used by another address
    mapping(string => address) internal stampHashMap;
    // Map to show if an address has ever been verified
    mapping(address => bool) internal isMember;
    address[] allMembers;

    /// @notice The thresholdHistory array stores the history of the verifyThreshold variable. This is needed because we might want to check if some stamps were valid in the past.
    Threshold[] thresholdHistory;

    /// @notice The reverifyThreshold determines how long a user has to wait before they can re-verify their address, in days
    uint reverifyThreshold;

    /// @notice The signer is the address that can sign proofs of verification
    address _signer;

    /// @notice A stamp defines proof of verification for a user on a specific platform at a specific date
    struct Stamp {
        string providerId; // Unique id for the provider (github, proofofhumanity, etc.)
        string userHash; // Hash of some unique user data of the provider (username, email, etc.)
        uint[] verifiedAt; // Block number at which the user has verified
    }

    /// @notice A threshold defines the number of days for which a stamp is valid
    struct Threshold {
        uint blockNumber; // Block number at which the threshold was set
        uint threshold; // Number of blocks for which a stamp is valid
    }

    /// @notice Initializes the owner of the contract
    constructor(uint _threshold, uint _reverifyThreshold, address signer_) {
        thresholdHistory.push(Threshold(block.number, _threshold));
        reverifyThreshold = _reverifyThreshold;
        _signer = signer_;
    }

    /// @notice This function can only be called by the owner, and it verifies an address. It's not possible to re-verify an address before half the verifyThreshold has passed.
    /// @dev Verifies an address
    /// @param _toVerify The address to verify
    /// @param _userHash The hash of the user's unique data on the provider (username, email, etc.)
    /// @param _timestamp The block number at which the proof was generated
    /// @param _providerId Unique id for the provider (github, proofofhumanity, etc.)
    /// @param _proofSignature The proof signed by the server
    function verifyAddress(
        address _toVerify,
        string calldata _userHash,
        uint _timestamp,
        string calldata _providerId,
        bytes calldata _proofSignature
    ) external {
        require(
            stampHashMap[_userHash] == address(0) ||
                stampHashMap[_userHash] == _toVerify,
            "ID already affiliated with another address"
        );

        require(_toVerify != address(0), "Address cannot be 0x0");
        require(
            block.timestamp < _timestamp + 1 hours,
            "Proof expired, try verifying again"
        );

        require(
            verify(_signer, keccak256(abi.encodePacked(_toVerify, _userHash, _timestamp, _providerId)), _proofSignature),
            "Proof is not valid"
        );

        // Check if there is existing stamp with providerId
        bool found; // = false;
        uint foundIndex; // = 0;

        for (uint i; i < stamps[_toVerify].length; ) {
            if (
                keccak256(abi.encodePacked(stamps[_toVerify][i].providerId)) ==
                keccak256(abi.encodePacked(_providerId))
            ) {
                found = true;
                foundIndex = i;
                break;
            }

            unchecked {
                i++;
            }
        }

        if (!found) {
            // Check if this is the first time this user has verified so we can add them to the allMembers list
            if (!isMember[_toVerify]) {
                isMember[_toVerify] = true;
                allMembers.push(_toVerify);
            }

            // Create new stamp if user does not already have a stamp for this providerId
            stamps[_toVerify].push(
                createStamp(_providerId, _userHash, block.number)
            );

            // This only needs to happens once (namely the first time an account verifies)
            stampHashMap[_userHash] = _toVerify;
        } else {
            // If user already has a stamp for this providerId
            // Check how long it has been since the last verification
            uint[] storage verifiedAt = stamps[_toVerify][foundIndex]
                .verifiedAt;
            uint blocksSinceLastVerification = block.number -
                verifiedAt[verifiedAt.length - 1];

            // If it has been more than reverifyThreshold days, update the stamp
            if (blocksSinceLastVerification > reverifyThreshold) {
                // Overwrite the userHash (in case the user changed their username or used another account to reverify)
                stamps[_toVerify][foundIndex].userHash = _userHash;
                verifiedAt.push(block.number);
            } else {
                revert(
                    "Address already verified; cannot re-verify yet, wait at least half the verifyThreshold"
                );
            }
        }
    }

    /// @notice Unverifies a provider from the sender
    /// @param _providerId Unique id for the provider (github, proofofhumanity, etc.) to be removed
    function unverify(string calldata _providerId) external {
        // Assume all is good in the world
        Stamp[] storage stampsAt = stamps[msg.sender];

        // Look up the corresponding stamp for the provider
        for (uint i; i < stampsAt.length; ) {
            if (stringsAreEqual(stampsAt[i].providerId, _providerId)) {
                // Remove the mapping from userhash to address
                stampHashMap[stampsAt[i].userHash] = address(0);

                // Remove stamp from stamps array (we don't care about order so we can just swap and pop)
                stampsAt[i] = stampsAt[stampsAt.length - 1];
                stampsAt.pop();
                return;
            }

            unchecked {
                i++;
            }
        }

        revert(
            "Could not find this provider among your stamps; are you sure you're verified with this provider?"
        );
    }

    /// @dev Solidity doesn't support string comparison, so we use keccak256 to compare strings
    function stringsAreEqual(
        string memory str1,
        string memory str2
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    /// @notice Creates a stamp for a user
    /// @param _providerId Unique id for the provider (github, proofofhumanity, etc.)
    /// @param _userHash Unique user hash on the platform of the stamp (GH, PoH, etc.)
    /// @param _blockNumber Block number at which the proof was submitted
    /// @return Stamp Returns the created stamp
    function createStamp(
        string memory _providerId,
        string memory _userHash,
        uint _blockNumber
    ) internal returns (Stamp memory) {
        uint[] memory verifiedAt = new uint[](1);
        verifiedAt[0] = _blockNumber;
        Stamp memory stamp = Stamp(_providerId, _userHash, verifiedAt);
        stampHashMap[_userHash] = msg.sender;
        return stamp;
    }

    /// @notice This function returns the stamps of an address
    /// @param _toCheck The address to check
    /// @return An array of stamps
    function getStamps(
        address _toCheck
    ) external view returns (Stamp[] memory) {
        return stamps[_toCheck];
    }

    /// @notice Returns the *valid* stamps of an address at a specific block number
    /// @param _toCheck The address to check
    /// @param _blockNumber The block number to check
    function getStampsAt(
        address _toCheck,
        uint _blockNumber
    ) external view returns (Stamp[] memory) {
        Stamp[] memory stampsAt = new Stamp[](stamps[_toCheck].length);
        uint count; // = 0;

        // Loop through all the user's stamps
        for (uint i; i < stamps[_toCheck].length; ) {
            // Get the list of all verification block numbers
            uint[] storage verifiedAt = stamps[_toCheck][i].verifiedAt;

            // Get the threshold at _blockNumber
            uint currentBlockNumberIndex = thresholdHistory.length - 1;
            while (
                currentBlockNumberIndex > 0 &&
                thresholdHistory[currentBlockNumberIndex].blockNumber > _blockNumber
            ) {
                currentBlockNumberIndex--;
            }

            uint verifyThreshold = thresholdHistory[currentBlockNumberIndex]
                .threshold;

            // Reverse for loop, because more recent dates are at the end of the array
            for (uint j = verifiedAt.length; j > 0; j--) {
                // If the stamp is valid at _blockNumber, add it to the stampsAt array
                if (
                    verifiedAt[j - 1] + verifyThreshold >
                    _blockNumber &&
                    verifiedAt[j - 1] < _blockNumber
                ) {
                    stampsAt[count] = stamps[_toCheck][i];
                    count++;
                    break;
                } else if (
                    verifiedAt[j - 1] + verifyThreshold <
                    _blockNumber
                ) {
                    break;
                }
            }

            unchecked {
                i++;
            }
        }

        Stamp[] memory stampsAtTrimmed = new Stamp[](count);

        for (uint i = 0; i < count; i++) {
            stampsAtTrimmed[i] = stampsAt[i];
        }

        return stampsAtTrimmed;
    }

    function getAllMembers() external view returns (address[] memory) {
        return allMembers;
    }

    /// @notice Returns whether or not the caller is or was a member at any time
    /// @dev Loop through the array of all members and return true if the caller is found
    /// @return bool Whether or not the caller is or was a member at any time
    function isOrWasMember(address _toCheck) external view returns (bool) {
        return isMember[_toCheck];
    }

    /// @notice Returns latest verifyThreshold
    function getVerifyThreshold() external view returns (uint) {
        return thresholdHistory[thresholdHistory.length - 1].threshold;
    }

    /// @notice This function can only be called by the owner to set the verifyThreshold
    /// @dev Sets the verifyThreshold
    /// @param _blocks The number of blocks to set the verifyThreshold to
    function setVerifyThreshold(uint _blocks) external onlyOwner {
        Threshold memory lastThreshold = thresholdHistory[
            thresholdHistory.length - 1
        ];
        require(
            lastThreshold.threshold != _blocks,
            "Threshold already set to this value"
        );

        thresholdHistory.push(Threshold(block.number, _blocks));
    }

    /// @notice Returns the reverifyThreshold
    function getReverifyThreshold() external view returns (uint) {
        return reverifyThreshold;
    }

    /// @notice This function can only be called by the owner to set the reverifyThreshold
    /// @dev Sets the reverifyThreshold
    /// @param _days The number of days to set the reverifyThreshold to
    function setReverifyThreshold(uint _days) external onlyOwner {
        reverifyThreshold = _days;
    }

    /// @notice Returns the full threshold history
    /// @return An array of Threshold structs
    function getThresholdHistory() external view returns (Threshold[] memory) {
        return thresholdHistory;
    }

    /// @notice Sets the signer address
    /// @param signer_ new signer address
    function setSigner(address signer_) external onlyOwner {
        _signer = signer_;
    }

    /// @notice Returns the signer address
    /// @return Signer address
    function getSigner() external view returns (address) {
        return _signer;
    }

}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  *
  * This source code is licensed under the MIT license found in the
  * LICENSE file in the root directory of this source tree.
  */
 
pragma solidity ^0.8.0;

/**
 * @title IAuthProvider
 * @author Utrecht University
 * @notice This interface defines a AuthProvider, to allow for easy swapping of auth function across all facets.
 */
interface IAuthProvider {
    function auth(bytes32 _permissionId, address _account) external view;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  *
  * This source code is licensed under the MIT license found in the
  * LICENSE file in the root directory of this source tree.
  */
 
pragma solidity ^0.8.0;

import { IAuthProvider } from "./auth-providers/IAuthProvider.sol";

/**
 * @title AuthConsumer
 * @author Utrecht University
 * @notice This contract converts the IAuthProvider interface (currently cut into the Diamond) auth function to a modifier.
 */
abstract contract AuthConsumer {
    /// @notice A modifier to make functions on inheriting contracts authorized. Permissions to call the function are checked through the associated DAO's permission manager.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(bytes32 _permissionId) {
        if (msg.sender != address(this)) {
            // This call should revert if the call is not allowed
            IAuthProvider(address(this)).auth(_permissionId, msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

// Modified source from: https://solidity-by-example.org/signature/

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

/// @title Set of (helper) functions for signature verification
contract GenericSignatureHelper {
    /// @notice Signs the messageHash with a standard prefix
    /// @param _messageHash The hash of the packed message (messageHash) to be signed
    /// @return bytes32 Returns the signed messageHash
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /// @notice Verify a signature
    /// @dev Generate the signed messageHash from the parameters to verify the signature against
    /// @param _signer The signer of the signature (the owner of the contract)
    /// @param _messageHash The hash of the packed message (messageHash) to be signed
    /// @param _signature The signature of the proof signed by the signer
    /// @return bool Returns the result of the verification, where true indicates success and false indicates failure
    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    /// @notice Recover the signer from the signed messageHash and the signature
    /// @dev This uses ecrecover
    /// @param _ethSignedMessageHash The signed messageHash created from the parameters
    /// @param _signature The signature of the proof signed by the signer
    /// @return address Returns the recovered address
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Splits the signature into r, s, and v
    /// @dev This is necessary for the ecrecover function
    /// @param sig The signature
    /// @return r Returns the first 32 bytes of the signature
    /// @return s Returns the second 32 bytes of the signature
    /// @return v Returns the last byte of the signature
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}