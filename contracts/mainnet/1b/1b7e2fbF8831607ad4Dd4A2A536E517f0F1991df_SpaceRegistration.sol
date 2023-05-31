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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISpaceRegistration {

    struct SpaceParam{
        string name;
        string logo;
    }

    function spaceParam(uint id) view external returns(SpaceParam memory);

    function checkMerkle(uint id, bytes32 root, bytes32 leaf, bytes32[] calldata _merkleProof) external view returns (bool);

    function verifySignature(uint id, bytes32 message, bytes calldata signature) view external returns(bool);

    function isAdmin(uint id, address addr) view external returns(bool);

    function isCreator(uint id, address addr) view external returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
import "./ISpaceRegistration.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceRegistration is ISpaceRegistration, Ownable {
    event Registered(uint256 indexed spaceId, string slug);
    event Approved(uint256 indexed spaceId, bytes32 merkleRoot, string slug);
    event Unapproved(uint256 indexed spaceId, bytes32 merkleRoot, string slug);

    modifier onlyAdmin(uint256 spaceId) {
        require(
            spaces[spaceId].creator == msg.sender ||
                spaces[spaceId].adminIndices[msg.sender] > 0 ||
                owner() == msg.sender,
            "auth failed"
        );
        _;
    }

    modifier onlyCreator(uint256 spaceId) {
        require(
            spaces[spaceId].creator == msg.sender ||
                spaces[spaceId].creator == msg.sender,
            "auth failed"
        );
        _;
    }

    struct MerkleRootState {
        // 1: valid; 2: invalid
        uint128 state;
        uint128 timestamp;
    }

    struct Space {
        address creator;
        string slug;
        mapping(address => uint256) adminIndices;
        address[] adminArray;
        string name;
        string logo;
        mapping(bytes32 => MerkleRootState) roots;
    }

    Space[] private spaces;
    mapping(string => uint) slugMap;

    constructor() public {
        /**
         * Start with index of 1
         */
        spaces.push();
    }

    function create(
        string memory _slug,
        string memory _name,
        string memory _logo,
        address[] memory adminArray
    ) public {
        require(slugMap[_slug] == 0, "duplicate");
        Space storage newSpace = spaces.push();
        newSpace.creator = msg.sender;
        newSpace.name = _name;
        newSpace.logo = _logo;
        newSpace.adminArray.push(msg.sender);
        newSpace.slug = _slug;
        slugMap[_slug] = spaces.length - 1;
        for (uint i = 0; i < adminArray.length; i++) {
            addAdmin(spaces.length - 1, adminArray[i]);
        }

        emit Registered(spaces.length - 1, _slug);
    }

    function addAdmin(uint256 id, address admin) public onlyCreator(id) {
        require(
            spaces[id].adminIndices[msg.sender] == 0 || admin == msg.sender,
            "duplication"
        );

        spaces[id].adminArray.push(admin);
        spaces[id].adminIndices[admin] = spaces[id].adminArray.length - 1;
    }

    function removeAdmin(uint256 id, address admin) public onlyCreator(id) {
        require(spaces[id].adminIndices[msg.sender] != 0, "invalid address");

        spaces[id].adminArray[spaces[id].adminIndices[admin]] = address(0);
        spaces[id].adminIndices[admin] = 0;
    }

    function transferSpaceOwnership(
        uint256 id,
        address newOwner
    ) public onlyCreator(id) {
        require(newOwner != address(0), "invalid address");
        if (spaces[id].adminIndices[newOwner] != 0) {
            spaces[id].adminArray[spaces[id].adminIndices[newOwner]] = address(
                0
            );
            spaces[id].adminIndices[newOwner] = 0;
        }
        spaces[id].creator = spaces[id].adminArray[0] = newOwner;
    }

    function getAdminArray(uint256 id) public view returns (address[] memory) {
        return spaces[id].adminArray;
    }

    function updateSpaceParam(
        uint256 id,
        string memory _name,
        string memory _logo
    ) public onlyAdmin(id) {
        spaces[id].name = _name;
        spaces[id].logo = _logo;
    }

    function approveMerkleRoot(uint256 id, bytes32 root) public onlyAdmin(id) {
        require(spaces[id].roots[root].state != 1, "duplicate");
        MerkleRootState memory state = MerkleRootState(
            1,
            uint128(block.timestamp)
        );
        spaces[id].roots[root] = state;
        emit Approved(id, root, spaces[id].slug);
    }

    function unapproveMerkleRoot(
        uint256 id,
        bytes32 root
    ) public onlyAdmin(id) {
        require(spaces[id].roots[root].state == 1, "invalid merkle");
        spaces[id].roots[root].state = 2;
        emit Unapproved(id, root, spaces[id].slug);
    }

    function spaceParam(
        uint256 id
    ) public view override returns (SpaceParam memory) {
        require(spaces[id].creator != address(0), "invalid id");
        return SpaceParam(spaces[id].name, spaces[id].logo);
    }

    function spaceIdBySlug(string memory slug) public view returns (uint) {
        return slugMap[slug];
    }

    function isAdmin(
        uint256 id,
        address addr
    ) public view override returns (bool) {
        return
            spaces[id].creator == addr ||
            spaces[id].adminIndices[addr] > 0 ||
            owner() == addr;
    }

    function isCreator(
        uint256 id,
        address addr
    ) public view override returns (bool) {
        return spaces[id].creator == addr;
    }

    function verifySignature(
        uint256 id,
        bytes32 message,
        bytes calldata signature
    ) public view override returns (bool) {
        bytes32 _ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        address addr = ecrecover(_ethSignedMessageHash, v, r, s);
        return isAdmin(id, addr);
    }

    function checkMerkle(
        uint256 id,
        bytes32 root,
        bytes32 leaf,
        bytes32[] calldata _merkleProof
    ) public view override returns (bool) {
        return
            spaces[id].roots[root].state == 1 &&
            MerkleProof.verify(_merkleProof, root, leaf);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}