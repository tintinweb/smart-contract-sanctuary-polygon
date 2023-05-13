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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface INftree is IERC721EnumerableUpgradeable, IAccessControlUpgradeable {

    // Foundation Trees related to comercial NFTrees
    struct FoundationTrees {
        address staking;
        address ecoEmpire;
        address backup;
    }

    // Struct of a batch of trees with all the attributes
    struct Batch {
        uint256 no;
        uint256 firstIndex;
        uint256 lastIndex;
        uint256 initialSupply;
        uint256 plantTime;
        bool isCo2Absorption;
        bool isEcoEmpires;
        bool isStaking;
        bool isGcsCompliant;
        string location;
        string baseURI;
        string baseExtension;
        FoundationTrees fTrees; // Foundtion trees of this batch
    }

    function getBatchDetails() external view returns (Batch memory);

    function initialize(Batch memory, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ITrees is IERC721EnumerableUpgradeable {
    struct Batch {
      uint256 no;
      uint256 firstIndex;
      uint256 lastIndex;
      uint256 maxSupply;
      uint256 plantTime;
      bool isCo2Absorption;
      bool isGcsCompliant;
      string location;
      string baseURI;
      string baseExtension;
    }
    
  function initialize(Batch calldata _batch, address admin, address nftree) external;
  
  function safeMint(address to, uint256 tokenId) external;
  
  function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './Interfaces/INftree.sol';
import './Interfaces/ITrees.sol';

contract NftreeFactory is Ownable {

    struct BatchTrees {
        INftree nftree;
        ITrees staking;
        ITrees ecoEmpire;
        ITrees backup;
    }

    // Mapping from batch no. to clone address
    mapping (uint256 => BatchTrees) public treesBatch;

    // Batch trees implementation address;
    address public implementationNftree;
    address public implementationStaking;
    address public implementationEcoEmpire;
    address public implementationBackup;

    // Total batch supply of this factory
    uint256 internal _batchSupply;

    /**
     * @dev Constructor function that sets the implementation addresses for Nftree, Staking, EcoEmpire, and Backup.
     * @param _implementationNftree The address of the Nftree implementation.
     * @param _implementationStaking The address of the Staking implementation.
     * @param _implementationEcoEmpire The address of the EcoEmpire implementation.
     * @param _implementationBackup The address of the Backup implementation.
     * Requirements:
     * - All input addresses must be non-zero.
     */
    constructor(address _implementationNftree, address _implementationStaking, address _implementationEcoEmpire, address _implementationBackup) {
        _setImplementation(_implementationNftree, _implementationStaking, _implementationEcoEmpire, _implementationBackup);
    }

    /**
     * @dev Internal function that sets the implementation addresses for Nftree, Staking, EcoEmpire, and Backup.
     * @param _implementationNftree The address of the Nftree implementation.
     * @param _implementationStaking The address of the Staking implementation.
     * @param _implementationEcoEmpire The address of the EcoEmpire implementation.
     * @param _implementationBackup The address of the Backup implementation.
     * Requirements:
     * - All input addresses must be non-zero.
     */
    function _setImplementation(address _implementationNftree, address _implementationStaking, address _implementationEcoEmpire, address _implementationBackup) internal {
        implementationNftree = _implementationNftree;
        implementationStaking = _implementationStaking;
        implementationEcoEmpire = _implementationEcoEmpire;
        implementationBackup = _implementationBackup;
    }

    /**
     * @dev Function that sets the implementation addresses for Nftree, Staking, EcoEmpire, and Backup. Only the contract owner can call this function.
     * @param _implementationNftree The address of the Nftree implementation.
     * @param _implementationStaking The address of the Staking implementation.
     * @param _implementationEcoEmpire The address of the EcoEmpire implementation.
     * @param _implementationBackup The address of the Backup implementation.
     * Requirements:
     * - All input addresses must be non-zero.
     * - The function can only be called by the contract owner.
     */
    function setImplementation(address _implementationNftree, address _implementationStaking, address _implementationEcoEmpire, address _implementationBackup) public onlyOwner {
        _setImplementation(_implementationNftree, _implementationStaking, _implementationEcoEmpire, _implementationBackup);
    }

    /**
     * @dev Function that returns the batch supply value.
     * @return The batch supply value.
     */
    function batchSupply() public view returns (uint256) {
        return _batchSupply;
    }

    /**
     * @dev Virtual function that returns the initial batch token supply.
     * @return The initial batch token supply value.
     */
    function initialBatchTokenSupply() public view virtual returns (uint256) {
        return 0;
    }


    //******** Clone functionality **********//

    /**
     * @dev Creates a new tree batch by cloning the `implementationNftree`, `implementationStaking`,
     * `implementationEcoEmpire`, and `implementationBackup` contracts using the Clones library.
     * The new tree objects are then added to the `treesBatch` mapping, which maps the batch ID to
     * the corresponding `nftree`, `staking`, `ecoEmpire`, and `backup` contracts.
     * 
     * Requirements:
     * - Caller must be the contract owner.
     */
    function _cloneTrees() internal onlyOwner {

        // Since the clone create a proxy, the constructor is redundant and you have to use the initialize function
        // Creating a new trees objects
        INftree nftree = INftree(Clones.clone(implementationNftree));
        ITrees staking = ITrees(Clones.clone(implementationStaking));
        ITrees ecoEmpire = ITrees(Clones.clone(implementationEcoEmpire));
        ITrees backup = ITrees(Clones.clone(implementationBackup));

        // Adding the nftree to our mapping of nftree addresses
        treesBatch[_batchSupply].nftree = nftree;
        treesBatch[_batchSupply].staking = staking;
        treesBatch[_batchSupply].ecoEmpire = ecoEmpire;
        treesBatch[_batchSupply].backup = backup;
    }

    /**
     * @dev Adds a new batch of trees to the `treesBatch` mapping.
     * Initializes the `nftree`, `staking`, `ecoEmpire`, and `backup` contracts with the `newBatch`
     * struct and the contract owner. Also increments the `_batchSupply`.
     * 
     * @param totalSupply The total supply of NFTs in the new batch.
     * @param plantTime The time at which the trees in the new batch were planted.
     * @param isCo2Absorption A boolean indicating whether the trees in the new batch absorb CO2.
     * @param isEcoEmpires A boolean indicating whether the trees in the new batch are part of the EcoEmpires program.
     * @param isStaking A boolean indicating whether the trees in the new batch are stakable.
     * @param isGcsCompliant A boolean indicating whether the trees in the new batch are GCS compliant.
     * @param location A string indicating the location of the trees in the new batch.
     * @param baseURI The base URI for the new batch of NFTs.
     * @param baseExtension The base file extension for the new batch of NFTs.
     * 
     * Requirements:
     * - `totalSupply` cannot be 0.
     * - Caller must be the contract owner.
     */
    function addTreeBatch(uint256 totalSupply, uint256 plantTime, bool isCo2Absorption, bool isEcoEmpires, bool isStaking, bool isGcsCompliant, string memory location, string memory baseURI, string memory baseExtension) public onlyOwner {
        require(totalSupply != 0, "NFT supply in a batch cannot be 0.");
        require(plantTime != 0, "Plant time in a batch cannot be 0.");

        // Incrementing batch supply
        _batchSupply++;

        // Initializing trees
        _cloneTrees();
        INftree.Batch memory newBatch = INftree.Batch(_batchSupply, initialBatchTokenSupply(), totalSupply - 1, totalSupply, plantTime, isCo2Absorption, isEcoEmpires, isStaking, isGcsCompliant, location, baseURI, baseExtension, 
        INftree.FoundationTrees(address(treesBatch[_batchSupply].staking), address(treesBatch[_batchSupply].ecoEmpire), address(treesBatch[_batchSupply].backup)));
        
        treesBatch[_batchSupply].nftree.initialize(newBatch, owner());
        treesBatch[_batchSupply].staking.initialize(ITrees.Batch(_batchSupply, newBatch.lastIndex + 1 , newBatch.lastIndex + totalSupply, totalSupply, plantTime, isCo2Absorption, isGcsCompliant, location, baseURI, baseExtension), owner(), address(treesBatch[_batchSupply].nftree));
        treesBatch[_batchSupply].ecoEmpire.initialize(ITrees.Batch(_batchSupply, newBatch.lastIndex * 2 + 1 , newBatch.lastIndex * 2 + totalSupply, totalSupply, plantTime, isCo2Absorption, isGcsCompliant, location, baseURI, baseExtension), owner(), address(treesBatch[_batchSupply].nftree));
        treesBatch[_batchSupply].backup.initialize(ITrees.Batch(_batchSupply, newBatch.lastIndex * 3 + 1 , newBatch.lastIndex * 3 + totalSupply, totalSupply, plantTime, isCo2Absorption, isGcsCompliant, location, baseURI, baseExtension), owner(), address(treesBatch[_batchSupply].nftree));
    }

    /**
     * @dev Returns an array of all NFTree batch clones.
     * @return nftreebatches An array of BatchTrees.
     */
    function getNftreeClones() public view returns (BatchTrees[] memory) {
        BatchTrees[] memory nftreebatches = new BatchTrees[](_batchSupply);
        for(uint256 i = 0; i < _batchSupply; i++) {
            nftreebatches[i] = treesBatch[i+1];
        }

        return nftreebatches;
    }

    /**
     * @dev Returns a specific NFTree batch clone with the given batch number.
     * @param batchNo The batch number to search for.
     * @return nftreeBatch The BatchTrees object representing the NFTree batch.
     * Requirements:
     * - The batch number should be greater than 0 and less than or equal to the batch supply.
     */
    function getClonesOfBatch(uint256 batchNo) public view returns (BatchTrees memory nftreeBatch) {
        require(batchNo <= _batchSupply && batchNo != 0, "Invalid batch supply.");
        nftreeBatch = treesBatch[batchNo];
    }
}