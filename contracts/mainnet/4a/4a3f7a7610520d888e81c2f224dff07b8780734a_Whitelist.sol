// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solbase/auth/Owned.sol";
import "./libraries/MerkleVerifier.sol";

contract Whitelist is Owned {
    mapping(address => bool) public isWhitelisted;

    bytes32 public merkleRoot;

    event Whitelisted(address indexed account, bool whitelisted);

    error InvalidProof();
    error MisMatchArrayLength();

    constructor(address owner) Owned(owner) {}

    function verify(bytes32[] memory proof, address user, uint256 index) public view returns (bool) {
        return MerkleVerifier.verify(proof, merkleRoot, keccak256(abi.encodePacked(user)), index);
    }

    function whitelistAddress(bytes32[] memory proof, address user, uint256 index) external {
        if (!verify(proof, user, index)) revert InvalidProof();
        isWhitelisted[user] = true;
        emit Whitelisted(user, true);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setDirectWhitelist(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
        emit Whitelisted(account, whitelisted);
    }

    function setDirectWhitelistBatch(address[] calldata accounts, bool[] calldata whitelisted) external onlyOwner {
        if (accounts.length != whitelisted.length) revert MisMatchArrayLength();
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = whitelisted[i];
            emit Whitelisted(accounts[i], whitelisted[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MerkleVerifier {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index) internal pure returns (bool) {
        bytes32 node = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }

            index = index / 2;
        }

        return node == root;
    }
}