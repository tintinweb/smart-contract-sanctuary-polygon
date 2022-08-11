// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseModifiers} from "./abstract/BaseModifiers.sol";
import {Errors} from "./libraries/Errors.sol";
import {ICollectionManager} from "./interfaces/ICollectionManager.sol";
import {ICollectionBase} from "./interfaces/ICollectionBase.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @title CollectionManager
/// @notice This contract acts as a factory for creating and managing collections.
contract CollectionManager is ICollectionManager, Ownable, BaseModifiers {
    /// @notice Mapping of collection implementations that are approved for creation.
    /// @dev Keccak of Group-Version-Kind(GVK) string -> Address of the collection implementation.
    /// ex. keccak256("collection.rubix.io/v1:SCollectionV1") => 0xABC123ABC123ABC123ABC123ABC123ABC1
    mapping(bytes32 => address) public approvedImpl;

    /// @notice Mapping of Collections to creation data
    /// @dev Collection address => Creation data struct
    mapping(address => CreationData) public collectionCreationData;

    constructor() {}

    /// @inheritdoc ICollectionManager
    function createCollection(bytes32 _gvk, bytes calldata _vars)
        external
        returns (address newCol)
    {
        address impl = approvedImpl[_gvk];

        if (impl == address(0)) {
            revert Errors.NotApproved();
        }

        newCol = Clones.clone(impl);

        collectionCreationData[newCol] = CreationData(impl, msg.sender);

        ICollectionBase(newCol).initialize(_vars);

        emit CollectionCreated(newCol, impl, msg.sender);
    }

    // TODO: importCollection() ?

    /* ---------------------------------- View ---------------------------------- */

    /* --------------------------------- Setters -------------------------------- */
    function setApprovedImpl(bytes32 _gvk, address _impl)
        external
        onlyOwner
        nonZeroAddress(_impl)
    {
        if (
            !ERC165Checker.supportsInterface(
                _impl,
                type(ICollectionBase).interfaceId
            )
        ) revert Errors.InvalidImplementation();

        approvedImpl[_gvk] = _impl;

        emit SetApprovedImpl(_gvk, _impl);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Errors} from "../libraries/Errors.sol";

/// @title BaseModifiers
/// @notice Base contract that defines commonly used modifiers for other contracts
/// to inherit.
abstract contract BaseModifiers {
    /* -------------------------------- Modifiers ------------------------------- */
    modifier nonZeroAddress(address addr) {
        if (addr == address(0)) revert Errors.ZeroAddress();
        _;
    }

    modifier nonZeroValue(uint256 value) {
        if (value == 0) revert Errors.ZeroValue();
        _;
    }

    modifier onlyExpectedCaller(address expected) {
        if (msg.sender != expected)
            revert Errors.UnexpectedCaller(msg.sender, expected);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Errors
/// @notice A Custom Error library for global use in the contracts.
library Errors {
    /* --------------------------- Base Global Errors --------------------------- */
    /// @notice Emitted when the submitted address is the zero address
    error ZeroAddress();

    /// @notice Emitted when the submitted value is zero.
    error ZeroValue();

    /// @notice Emitted when the submitted value is zero or less
    /// @dev Technically uint can't be negative, so it wouldn't make
    /// sense for this error to happen when [value] is an uint.
    /// Hence I'm defining it as an int256 instead.
    error ZeroOrNegativeValue(int256 value);

    /// @notice Emitted when the caller is not the expected address
    error UnexpectedCaller(address caller, address expected);

    /// @notice Emitted when the caller does not have the required permissions
    error UnauthorizedCaller(address caller);

    /* ---------------------------- Signature Errors ---------------------------- */

    /// @notice Emitted when the signature's deadline has expired.
    error SignatureExpired();

    /// @notice Emitted when the signature failed to verify.
    error SignatureInvalid();

    error SignatureInvalidS();
    error SignatureInvalidV();

    /* ------------------------ Collection Manager Errors ----------------------- */

    /// @notice Emitted when the submitted address is not an approved implementation.
    error NotApproved();

    /// @notice Emitted when the submitted address is not a valid collection implementation.
    error InvalidImplementation();

    /* ---------------------------- Collection Errors --------------------------- */

    // TODO

    /// @notice Emitted when the collection is not mintable and a mint was attempted.
    error NotMintable();

    /// @notice Emitted when the amount paid is different than the mint price.
    error InvalidAmountPaid(uint256 expected);

    /// @notice Emitted when the amount of tokens minted would exceed the maximum for the wallet.
    error MaxPerWalletExceeded();

    /// @notice Emitted when the amount of tokens minted would exceed the maximum supply.
    error MaxSupplyExceeded();

    /* ------------------------------ Module Errors ----------------------------- */

    // TODO
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICollectionManager {
    /// @notice Stores data about the a collection's creation
    /// @param implementation The address of the collection's singleton (implementation).
    /// @param creator Thea address that created the collection.
    struct CreationData {
        address implementation;
        address creator;
        // TODO: Anything else or should we leave this for off-chain?
    }

    /* --------------------------------- Events --------------------------------- */

    /// @notice Emitted when a collection is created.
    /// TODO: Or imported?
    /// @param collection The address of the collection.
    /// @param implementation The address of the collection's implementation.
    /// @param creator The address that created the collection.
    event CollectionCreated(
        address indexed collection,
        address indexed implementation,
        address indexed creator
    );

    /// @notice Emitted when the approval of a collection implementation is set.
    /// @param gvk The address of the collection implementation.
    /// @param implementation Whether the collection implementation is approved.
    event SetApprovedImpl(bytes32 indexed gvk, address indexed implementation);

    /* -------------------------------- Functions ------------------------------- */
    /// @notice Creates a collection clone proxy from the current `collectionImpl` singleton
    /// and initializes it with the given parameters.
    /// @param gvk Group-Version-Kind(GVK) string of the singleton implementation to be cloned and initialized.
    /// @param vars ABI-encoded parameters corresponding to the current `collectionImpl`'s initialization parameters.
    function createCollection(bytes32 gvk, bytes memory vars)
        external
        returns (address newCol);

    function setApprovedImpl(bytes32 gvk, address impl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICollectionBase {
    /// @notice Stores metadata about the collection.
    /// @param version The version of the collection contract.
    /// @param interfaceId The EIP165 InterfaceID of the collection contract.
    /// @param name The name of the collection.
    /// @param symbol The symbol of the collection.
    struct Metadata {
        uint256 version;
        bytes4 interfaceId;
        string name;
        string symbol;
    }

    /* -------------------------------- Functions ------------------------------- */
    /// @notice The initializer for the collection.
    /// Each Collection takes its own defined fields.
    /// @param vars the ABI-encoded sequence of bytes from which to the decode the initialization parameters.
    function initialize(bytes calldata vars) external;

    /* ---------------------------------- View ---------------------------------- */
    function getMetadata() external view returns (Metadata memory);

    // TODO Do we need this in here?
    /// @notice Returns the URI for `tokenId` token from the collection.
    // function tokenURI(uint256 tokenId) external view returns (string memory);

    // TODO Should the spec be here as well? We would not be able to define a Struct for it then as a return type (unless its always the same)
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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