//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Semaphore interface.
/// @dev Interface of a Semaphore contract.
interface ISemaphore {
    error Semaphore__CallerIsNotTheGroupAdmin();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__MerkleTreeRootIsExpired();
    error Semaphore__MerkleTreeRootIsNotPartOfTheGroup();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    struct Verifier {
        address contractAddress;
        uint256 merkleTreeDepth;
    }

    /// It defines all the group parameters, in addition to those in the Merkle tree.
    struct Group {
        address admin;
        uint256 merkleRootDuration;
        mapping(uint256 => uint256) merkleRootCreationDates;
        mapping(uint256 => bool) nullifierHashes;
    }

    /// @dev Emitted when an admin is assigned to a group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param externalNullifier: External nullifier.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    event ProofVerified(
        uint256 indexed groupId,
        uint256 merkleTreeRoot,
        uint256 externalNullifier,
        uint256 nullifierHash,
        bytes32 signal
    );

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        uint256 merkleTreeRoot,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        uint256 groupId,
        uint256 depth,
        uint256 zeroValue,
        address admin
    ) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    /// @param admin: Admin of the group.
    /// @param merkleTreeRootDuration: Time before the validity of a root expires.
    function createGroup(
        uint256 groupId,
        uint256 depth,
        uint256 zeroValue,
        address admin,
        uint256 merkleTreeRootDuration
    ) external;

    /// @dev Updates the group admin.
    /// @param groupId: Id of the group.
    /// @param newAdmin: New admin of the group.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;

    /// @dev Adds a new member to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external;

    /// @dev Adds new members to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitments: New identity commitments.
    function addMembers(uint256 groupId, uint256[] calldata identityCommitments) external;

    /// @dev Updates an identity commitment of an existing group. A proof of membership is
    /// needed to check if the node to be updated is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Removes a member from an existing group. A proof of membership is
    /// needed to check if the node to be removed is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Identity commitment to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/LibAppStorage.sol";
import {ByteHasher} from "../ByteHasher.sol";

contract PostCommentFacet is Modifiers {
    using ByteHasher for bytes;
    event NewItem(ItemKind itemType, uint256 groupId, uint256 id, uint256 parentId, bytes32 contentCID, uint256 note);
    event UpdateItem(ItemKind itemType, uint256 itemId, bytes32 newCID, uint256 newNote);
    event VoteItem(VoteKind voteType, ItemKind itemType, uint256 itemId, uint256 upvote, uint256 downvote);

    function getPostIdList(uint256 groupId) external view returns (uint256[] memory) {
        require(groupId >= 0 && groupId < s.groupCount, "Invalid groupId");
        if (s.groups[groupId].removed) {
            uint256[] memory posts;
            return posts;
        } else {
            return s.groups[groupId].posts;   
        }
    }

    function getCommentIdList(uint256 postId) external view returns (uint256[] memory) {
        require(postId >= 0 && postId < s.itemCount, "Invalid postId");
        require(s.items[postId].removed == false, "post removed");

        if (s.items[postId].removed) {
            uint256[] memory childIds;
            return childIds;
        } else {
            return s.items[postId].childIds;
        }
    }

    function itemCount() external view returns (uint256) {
        return s.itemCount;
    }

    function itemAt(uint256 index) external view returns (Item memory) {
        require(index >= 0 && index < s.itemCount, "Invalid itemId");
        return s.items[index];
    }

    function addPost(
        uint256 groupId,
        bytes32 contentCID,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 note,
        uint256[8] calldata proof
    ) external {
        require(groupId >= 0 && groupId < s.groupCount, "Invalid groupId");
        require(s.groups[groupId].removed == false, "Removed group");

        uint256 externalNullifierHash = abi.encodePacked(contentCID).hashToField();
        s.semaphore.verifyProof(groupId, merkleTreeRoot, contentCID, nullifierHash, externalNullifierHash, proof);

        uint256[] memory childIds;
        s.items[s.itemCount] = Item(ItemKind.POST, s.itemCount, 0, groupId, block.number, childIds, 0, 0, note, contentCID, false);
        s.groups[groupId].posts.push(s.itemCount);

        emit NewItem(ItemKind.POST, groupId, s.items[s.itemCount].id, 0, contentCID, note);

        unchecked {
            s.itemCount += 1;
        }
    }

    function addComment(
        uint256 groupId,
        uint256 parentId,
        bytes32 contentCID,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 note,
        uint256[8] calldata proof
    ) external {
        require(groupId >= 0 && groupId < s.groupCount, "Invalid groupId");
        require(s.groups[groupId].removed == false, "Removed group");
        require(parentId >= 0 && parentId < s.itemCount, "Invalid parentId");
        require(s.items[parentId].removed == false, "parent item removed");

        uint256 externalNullifierHash = abi.encodePacked(contentCID).hashToField();
        s.semaphore.verifyProof(groupId, merkleTreeRoot, contentCID, nullifierHash, externalNullifierHash, proof);

        uint256[] memory childIds;
        s.items[s.itemCount] = Item(ItemKind.COMMENT, s.itemCount, parentId, groupId, block.number, childIds, 0, 0, note, contentCID, false);
        s.items[parentId].childIds.push(s.items[s.itemCount].id);

        emit NewItem(ItemKind.COMMENT, groupId, s.items[s.itemCount].id, parentId, contentCID, note);
        unchecked {
            s.itemCount += 1;
        }
    }

    function editItem(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c, 
        uint256 itemId,
        bytes32 newCID,
        uint256 newNote
    ) external {
        require(itemId >= 0 && itemId < s.itemCount, "Invalid itemId");
        uint256 oldCID = abi.encodePacked(s.items[itemId].contentCID).hashToField();
        require(s.verifier.verifyProof(
            _a,
            _b,
            _c,
            [
                oldCID, 
                s.items[itemId].note
            ]
        ), "Invalid Proof");
        s.items[itemId].contentCID = newCID;
        s.items[itemId].note = newNote;
        emit UpdateItem(s.items[itemId].kind, itemId, newCID, newNote);
    }

    function vote(
        uint256 groupId,
        uint256 itemId, //id of post or comment
        VoteKind voteType, //0: up, 1: down
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        require(groupId >= 0 && groupId < s.groupCount, "Invalid groupId");
        require(s.groups[groupId].removed == false, "Removed group");
        require(itemId >= 0 && itemId < s.itemCount, "Invalid itemId");
        require(s.items[itemId].removed == false, "Removed Item");
        require(voteType == VoteKind.UP || voteType == VoteKind.DOWN, "Invalid voteType");

        uint256 signal = abi.encodePacked(itemId, "vote").hashToField();
        s.semaphore.verifyProof(groupId, merkleTreeRoot, bytes32(signal), nullifierHash, signal, proof);

        unchecked {
            if(voteType == VoteKind.UP)
                s.items[itemId].upvote = s.items[itemId].upvote + 1;
            else 
                s.items[itemId].downvote = s.items[itemId].downvote + 1;
        }

        emit VoteItem(voteType, s.items[itemId].kind, itemId, s.items[itemId].upvote, s.items[itemId].downvote);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    ) external view returns (bool r);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {IVerifier} from "../interfaces/IVerifier.sol";

enum ItemKind {
    POST,
    COMMENT
}

enum VoteKind {
    UP,
    DOWN
}

struct Requirement {
    address tokenAddress;
    uint256 minAmount;
}

struct Group {
    string name;
    Requirement[] requirements;
    uint256 id;
    uint256 creatorIdentityCommitment;
    uint256 userCount;
    uint256 chainId;
    uint256[] posts;
    bool removed;
    mapping(uint256 => bytes32) users;
}

struct Item {
    /// @notice what kind of item (post or comment)
    ItemKind kind;

    /// @notice Unique item id, assigned at creation time.
    uint256 id;

    /// @notice Id of parent item. Posts have parentId == 0.
    uint256 parentId;

    uint256 groupId;
    /// @notice block number when item was submitted
    uint256 createdAtBlock;

    uint256[] childIds;
    uint256 upvote;
    uint256 downvote;
    uint256 note;
    bytes32 contentCID;
    bool removed;
}

struct AppStorage {
    uint256 adminCount;
    uint256 moderatorCount;
    address[] admins;
    address[] moderators;
    mapping(address => address[]) removeAdminApprovals;

    IVerifier verifier;
    ISemaphore semaphore;

    /// @dev counter for issuing group ids
    uint256 groupCount;

    /// @dev counter for issuing item ids
    uint256 itemCount;
    
    /// @dev maps group id to Group
    mapping(uint256 => Group) groups;

    /// @dev maps item id to Group
    mapping(uint256 => Item) items;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyAdmin() {
        bool _isAdmin = false;
        for (uint256 i = 0; i < s.admins.length; ++i) {
            if(s.admins[i] == msg.sender) {
                _isAdmin = true;
            }
        }
        require(_isAdmin == true, "caller is not admin");
        _;
    }

    modifier onlyModerator() {
        bool _isModerator = false;
        for (uint256 i = 0; i < s.admins.length; ++i) {
            if(s.admins[i] == msg.sender) {
                _isModerator = true;
                break;
            }
        }

        if(!_isModerator) {
            for (uint256 i = 0; i < s.moderators.length; ++i) {
                if(s.moderators[i] == msg.sender) {
                    _isModerator = true;
                    break;
                }
            }
        }
        require(_isModerator == true, "caller is not moderator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
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

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}