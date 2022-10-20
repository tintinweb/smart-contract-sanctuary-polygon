// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Relational} from "./Relational.sol";
import {Log} from "./Log.sol";
import {Tag} from "./Tag.sol";

contract Manager is Ownable {
    Log log;
    Tag tag;

    constructor(address logAddr, address tagAddr) {
        log = Log(logAddr);
        tag = Tag(tagAddr);
    }

    // create log with tags (new and existing)
    function createLogWithTags(
        string memory _logData,
        string[] memory _newTags,
        uint256[] memory _existingTags
    ) public {
        Relational.Relationship[]
            memory relationships = _createTagsGetRelationships(
                _newTags,
                _existingTags
            );

        // create log
        log.create(_logData, relationships); // TODO: shouldnt duplicate tags
    }

    function addTagsToLog(
        uint256 logID,
        string[] memory _newTags,
        uint256[] memory _existingTags
    ) public {
        Relational.Relationship[]
            memory relationships = _createTagsGetRelationships(
                _newTags,
                _existingTags
            );

        for (uint256 i = 0; i < relationships.length; i++) {
            Relational(relationships[i].addr).addBiDirectionalRelationship(
                logID,
                relationships[i]
            );
        }

        // update log with tags (new and existing)
        // tag.addTagsToLog(_existingTags, logId);
    }

    function _createTagsGetRelationships(
        string[] memory _newTags,
        uint256[] memory _existingTags
    ) internal returns (Relational.Relationship[] memory relationships) {
        // create the new tags
        uint256[] memory newTagIds = createTags(_newTags);

        // create relationships for the new tags
        relationships = new Relational.Relationship[](
            _newTags.length + _existingTags.length
        );

        for (uint256 i = 0; i < _newTags.length; i++) {
            relationships[i] = Relational.Relationship({
                addr: address(tag),
                id: newTagIds[i]
            });
        }

        // create relationships for the existing tags
        for (
            uint256 i = _newTags.length;
            i < _newTags.length + _existingTags.length;
            i++
        ) {
            relationships[i + _newTags.length] = Relational.Relationship({
                addr: address(tag),
                id: _existingTags[i]
            });
        }

        return relationships;
    }

    function createTags(string[] memory _newTags)
        public
        returns (uint256[] memory ids)
    {
        ids = new uint256[](_newTags.length);
        Relational.Relationship[]
            memory relationships = new Relational.Relationship[](0);
        for (uint256 i = 0; i < _newTags.length; i++) {
            ids[i] = tag.create(_newTags[i], relationships);
        }

        return ids;
    }

    function multiCall(address[] calldata targets, bytes[] calldata data)
        public
        view
        returns (bytes[] memory)
    {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint256 i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(
                data[i]
            );
            require(success, "call failed");
            results[i] = result;
        }

        return results;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Relational {
    // TODO review naming: could be "Link"
    struct Relationship {
        address addr;
        uint256 id;
        // maybe need to add author in here too
    }

    event RelationshipAdded(uint256 id, Relationship relationship);

    // Option 1: call the other contract and emit events in both
    // Collection is of B (1,2,3)
    // Collection calls add relationships on id's 1,2,3 with the relationship (addr(collection), id(collection_id))
    // CreateCollection()

    // Option 2: emit events in just the contract which was called

    function addBiDirectionalRelationship(uint256 targetId, Relationship memory)
        external;

    function addUniDirectionalRelationship(
        uint256 targetId,
        Relationship memory
    ) external;

    // function removeRelationship(Relationship memory) external;

    // function create(uint256 id, bytes data);
    // function update(uint256 id, bytes data);
    // function delete(uint256 id);
    // function read(uint256 id) returns (bytes data);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Log is Relational {
    struct LogContents {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        uint256 modifiedTimestamp;
        string data;
        Relationship[] relationships;
    }

    event LogCreated(uint256 id, LogContents data);
    event LogEdited(uint256 id, string data);
    event LogRemoved(uint256 id);

    mapping(uint256 => LogContents) public logs;
    uint256 public logCount;

    function create(string memory data, Relationship[] memory relationships)
        public
        returns (uint256 id)
    {
        // fetch id
        id = logCount;

        // get storage slot for new tag
        LogContents storage log = logs[id];

        // set the new data for the tag
        log.id = id;
        log.author = msg.sender;
        log.createdTimestamp = block.timestamp;
        log.modifiedTimestamp = block.timestamp;
        log.data = data;

        // add relationships to the tag
        for (uint256 i = 0; i < relationships.length; i++) {
            addBiDirectionalRelationship(id, relationships[i]);
        }

        emit LogCreated(log.id, log);

        logCount++;

        return id;
    }

    // TODO need to add errors, and probably add relationships too.

    function edit(uint256 id, string memory data) public {
        LogContents storage log = logs[id];

        log.modifiedTimestamp = block.timestamp;
        log.data = data;

        emit LogEdited(id, data);
    }

    function remove(uint256 id) public {
        delete logs[id];
        emit LogRemoved(id);
    }

    function addBiDirectionalRelationship(
        uint256 id,
        Relationship memory relationship
    ) public {
        Relationship memory thisLog = Relationship({
            addr: address(this),
            id: id
        });

        Relational(relationship.addr).addUniDirectionalRelationship(
            relationship.id,
            thisLog
        );
        addUniDirectionalRelationship(id, relationship);
    }

    function addUniDirectionalRelationship(
        uint256 id,
        Relationship memory relationship
    ) public {
        LogContents storage log = logs[id];
        log.relationships.push(relationship);
        emit RelationshipAdded(id, relationship);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Tag is Relational {
    struct TagContents {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        string name;
        Relationship[] relationships;
    }

    mapping(uint256 => TagContents) public tags;
    uint256 public tagCount;

    event TagCreated(uint256 id, TagContents tag);

    function create(string memory name, Relationship[] memory relationships)
        public
        returns (uint256 id)
    {
        // fetch id
        id = tagCount;

        // get storage slot for new tag
        TagContents storage tag = tags[id];

        // set the new data for the tag
        tag.id = id;
        tag.author = msg.sender;
        tag.createdTimestamp = block.timestamp;
        tag.name = name;

        // add relationships to the tag
        for (uint256 i = 0; i < relationships.length; i++) {
            addBiDirectionalRelationship(tagCount, relationships[i]);
        }

        emit TagCreated(tagCount, tag);
        tagCount++;

        return id;
    }

    function addBiDirectionalRelationship(
        uint256 tagID,
        Relationship memory relationship
    ) public {
        Relationship memory thisTag = Relationship({
            addr: address(this),
            id: tagID
        });

        Relational(relationship.addr).addUniDirectionalRelationship(
            relationship.id,
            thisTag
        );
        addUniDirectionalRelationship(tagID, relationship);
    }

    function addUniDirectionalRelationship(
        uint256 tagID,
        Relationship memory relationship
    ) public {
        TagContents storage tag = tags[tagID];
        tag.relationships.push(relationship);
        emit RelationshipAdded(tagID, relationship);
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