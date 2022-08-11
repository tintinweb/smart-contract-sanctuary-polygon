// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseModifiers} from "./abstract/BaseModifiers.sol";
import {Errors} from "./libraries/Errors.sol";
import {ICollectionManager} from "./interfaces/ICollectionManager.sol";
import {ICollectionBase} from "./interfaces/ICollectionBase.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CollectionManager
/// @notice This contract acts as a factory for creating and managing collections.
contract CollectionManager is ICollectionManager, Ownable, BaseModifiers {
    /// @notice Admin role for managing Collections
    /// @dev Initially the Rubix Admin wallets
    address public admin;

    /// @notice Address of the Collection implementation to be used for deploying clones
    ICollectionBase public collectionImpl;

    /// @notice Mapping of Collections to creation data
    /// @dev Collection address => Creation data struct
    mapping(address => CreationData) public collectionCreationData;

    /// @param _admin The initial admin address
    /// @param _collectionImpl The address of the Collection implementation for clone deployments
    constructor(address _admin, address _collectionImpl)
        nonZeroAddress(_admin)
        nonZeroAddress(_collectionImpl)
    {
        admin = _admin;
        collectionImpl = ICollectionBase(_collectionImpl);
    }

    /// @notice Creates a new Collection, deploying a clone proxy from the stored singleton implementation
    function createCollection(bytes calldata _vars)
        external
        onlyExpectedCaller(admin)
        returns (address newCol)
    {
        newCol = Clones.clone(address(collectionImpl));

        collectionCreationData[newCol] = CreationData(
            address(collectionImpl),
            msg.sender
        );

        ICollectionBase(newCol).initialize(_vars);

        emit CollectionCreated(newCol, address(collectionImpl), msg.sender);
    }

    // TODO: importCollection() ?

    /* ---------------------------------- View ---------------------------------- */

    /* --------------------------------- Setters -------------------------------- */
    function setCollectionImplementation(address _collectionImpl)
        external
        onlyOwner
        returns (bool success)
    {
        collectionImpl = ICollectionBase(_collectionImpl);
        emit SetCollectionImplementation(_collectionImpl);

        success = true;
    }

    function setAdmin(address _admin)
        external
        onlyOwner
        returns (bool success)
    {
        admin = _admin;
        emit SetAdmin(admin);

        success = true;
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
        // address admin; TODO? Useful for tracking who imports a new collection as well
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

    /// @notice Emitted when the implementation address is updated.
    /// @param newImplementation The new implementation address.
    event SetCollectionImplementation(address indexed newImplementation);

    /// @notice Emitted when the admin address is updated.
    /// @param newAdmin The new admin address.
    event SetAdmin(address indexed newAdmin);

    /* -------------------------------- Functions ------------------------------- */
    // TODO: Doc here and @inheritdoc in the implementing contracts
    function createCollection(bytes memory vars)
        external
        returns (address newCol);

    function setCollectionImplementation(address collectionImpl)
        external
        returns (bool);

    function setAdmin(address admin) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICollectionBase {
    /* -------------------------------- Functions ------------------------------- */
    /// @notice The initializer for the collection.
    /// Each Collection takes its own defined fields.
    /// @param vars the ABI-encoded sequence of bytes from which to the decode the initialization parameters.
    function initialize(bytes calldata vars) external;

    /* ---------------------------------- View ---------------------------------- */
    /// @notice Returns the owner of the collection.
    /// The owner is the address with permissions to change the collection's mutable fields.
    function owner() external view returns (address);

    /// @notice Returns the name of the collection.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the collection.
    function symbol() external view returns (string memory);

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