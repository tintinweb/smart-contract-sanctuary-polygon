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
pragma solidity ^0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ContextDocument is Ownable {
    enum DocumentType { SCHEMA, DOCUMENT }

    struct Document {
        uint64 versionId;
        mapping (uint16 => string) major;
        mapping (uint32 => string) minor;
        mapping (uint64 => string) patch;
    }
    mapping (bytes32 => Document) public document;

    // Constructor.
    constructor( address _owner ) {
        transferOwnership(_owner);
    }

    function read(string calldata name) public view
        returns (uint64, string memory, string memory, string memory)
    {
        Document storage doc = document[keccak256(bytes(name))];
        return (readVersion(name, doc.versionId));
    }

    function readVersion( string calldata name, uint64 versionId ) public view
        returns (uint64, string memory, string memory, string memory)
    {
        Document storage doc = document[keccak256(bytes(name))];
        uint16 majorId = uint16(versionId >> 32);
        uint32 minorId = uint32(versionId >> 16);
        return (versionId, doc.major[majorId], doc.minor[minorId], doc.patch[versionId]);
    }

    function pushMajor(
        string memory _name,
        string memory major,
        string memory minor,
        string memory patch
    ) public onlyOwner {
        bytes32 name = keccak256(bytes(_name));
        Document storage doc = document[name];
        // Increment Major and reset minor and patch versions.
        uint16 majorId = uint16(doc.versionId >> 32) + 1;
        doc.major[majorId] = major;
        doc.versionId = (uint64(majorId) << 32) | (uint64(0) << 16) | 0;
        uint32 minorId = uint32(doc.versionId >> 16);
        doc.minor[minorId] = minor;
        doc.patch[doc.versionId] = patch;
    }

    function pushMinor(
        string memory _name,
        string memory minor,
        string memory patch
    ) public onlyOwner {
        bytes32 name = keccak256(bytes(_name));
        Document storage doc = document[name];
        require(document[name].versionId > 0, "Document does not exist");
        // Increment minor and reset patch version.
        uint16 majorId = uint16(doc.versionId >> 32);
        uint32 minorId = uint32(doc.versionId >> 16) + 1;
        uint32 patchId = 0;
        doc.versionId = (uint64(majorId) << 32) | (uint64(minorId) << 16) | patchId;
        doc.minor[minorId] = minor;
        doc.patch[doc.versionId] = patch;
    }

    function pushPatch(
        string memory _name,
        string memory patch
    ) public onlyOwner {
        bytes32 name = keccak256(bytes(_name));
        Document storage doc = document[name];
        require(document[name].versionId > 0, "Document does not exist");
        // Increment patch.
        doc.versionId = doc.versionId + 1;
        doc.patch[doc.versionId] = patch;
    }
}