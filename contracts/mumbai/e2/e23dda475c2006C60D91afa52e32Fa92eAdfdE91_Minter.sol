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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @dev Must change the interface name.
interface ITarget {

    // functions of target contract

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    function buy(uint256 tokenId) external payable;

    function buyBundle(uint256[] memory tokenIdList) external payable;

    function updateSaleStatus(bool _isOnSale) external;

    function updateBaseURI(string calldata newBaseURI) external;

    function mintForPromotion(address to, uint256 amount) external;

    function withdrawETH() external;

    function transferOwnership(address newOwner) external;

    // functions for ERC721

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ITarget.sol";

/// @dev must change the name of revert messages
/// @dev Change contract name
contract Minter is Ownable, IERC721Receiver, ReentrancyGuard {

    ITarget public deployedNFT; /// @dev DeployedNFTMock はテスト用の NFT コントラクト。後ほどインターフェースに差し替える
    address public cushionAddress; /// @dev 本番用ではハードコードing, 0xCB8bD8...    
    address public agentAddress; /// @dev Pie

    uint256 public constant HOLDER_PRICE = 0.03 ether; /// @dev これは全体での価格であることに注意する    
    uint256 public constant ALLOWLIST_PRICE = 0.05 ether; /// @dev これは全体での価格であることに注意する    
    uint256 public constant PUBLIC_PRICE = 0.07 ether; /// @dev これは全体での価格であることに注意する    
    uint256 public constant PRICE = 0.01 ether; /// @dev 0xF16a5B6... のPRICE()を書く
    uint256 public constant OWNER_MINT_LIMIT = 20;
    
    bool public isHolderSaleActive;
    bool public isAllowlistSaleActive;
    bool public isPublicSaleActive;

    bytes32 public holderMerkleRoot;
    bytes32 public allowlistMerkleRoot;

    /// @dev holderAddress => minted token amount
    mapping (address => uint256) public holderMinted;

    /// @dev tokenId => seed
    mapping (uint256 => bytes32) private tokenIdToSeed;

    /// @dev 2023年7月11日
    /// @dev eventを準備する
    enum Artist { Okazz, Raf, Ykxotkx }

    event Minted(uint256 indexed _tokenId, Artist indexed _artist, bytes32 indexed _seed);

    constructor(
        address _cushionAddress,
        address _targetAddress
    ) {
        deployedNFT = ITarget(_targetAddress);
        cushionAddress = _cushionAddress;
    }

    function publicMint(
        uint256[] memory _tokenIdList
    ) external payable nonReentrant {
        require(isPublicSaleActive, "TestNFT: Public sale is not active");
        require(msg.value == PUBLIC_PRICE * _tokenIdList.length, "TestNFT: Incorrect payment amount");

        _generateSeed(msg.sender, _tokenIdList);
        _overrideBuyBundle(msg.sender, _tokenIdList);
    }

    function publicMintByAgent(
        uint256[] memory _tokenIdList,
        address _recipient
    ) external payable onlyAgent nonReentrant {
        require(isPublicSaleActive, "TestNFT: Public sale is not active");
        require(msg.value == PUBLIC_PRICE, "TestNFT: Incorrect payment amount");

        _generateSeed(_recipient, _tokenIdList);
        _overrideBuyBundle(_recipient, _tokenIdList);
    }

    /// @dev 複数を買うときの関数をつくる
    /// @dev merklerootも個数を配慮する、ミントしたい個数を選べるようにする
    function allowlistMint(
        bytes32[] calldata _merkleProof,
        uint256[] memory _tokenIdList
    ) external payable nonReentrant {
        require(isAllowlistSaleActive, "TestNFT: Allowlist sale is not active");
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot,  keccak256(abi.encodePacked(msg.sender))), "TestNFT: Invalid Merkle Proof");
        require(msg.value == ALLOWLIST_PRICE * _tokenIdList.length, "TestNFT: Incorrect payment amount");

        _generateSeed(msg.sender, _tokenIdList);
        _overrideBuyBundle(msg.sender, _tokenIdList);
    }

    /// @param _recipient recipient address of this token
    function allowlistMintByAgent(
        bytes32[] calldata _merkleProof,
        uint256[] memory _tokenIdList,
        address _recipient
    ) external payable onlyAgent nonReentrant {
        require(isAllowlistSaleActive, "TestNFT: Allowlist sale is not active");
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot,  keccak256(abi.encodePacked(_recipient))), "TestNFT: Invalid Merkle Proof");
        require(msg.value == ALLOWLIST_PRICE * _tokenIdList.length, "TestNFT: Incorrect payment amount");

        _generateSeed(_recipient, _tokenIdList);
        _overrideBuyBundle(_recipient, _tokenIdList);
    }

    function holderMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256[] memory _tokenIdList
    ) external payable nonReentrant {
        require(isHolderSaleActive, "TestNFT: Holder sale is not active");
        require(holderMinted[msg.sender] + _tokenIdList.length <= _quantity, "TestNFT: Exceeds the number of mints allowed");
        require(MerkleProof.verify(_merkleProof, holderMerkleRoot,  keccak256(abi.encodePacked(msg.sender, _quantity))), "TestNFT: Invalid Merkle Proof");
        require(msg.value == HOLDER_PRICE * _tokenIdList.length, "TestNFT: Incorrect payment amount");
        
        _generateSeed(msg.sender, _tokenIdList);
        _overrideBuyBundle(msg.sender, _tokenIdList);
        holderMinted[msg.sender] += _tokenIdList.length;
    }

    function holderMintByAgent(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256[] memory _tokenIdList,
        address _recipient
    ) external payable onlyAgent nonReentrant {
        require(isHolderSaleActive, "TestNFT: Holder sale is not active");
        require(holderMinted[_recipient] + _tokenIdList.length <= _quantity, "TestNFT: Exceeds the number of mints allowed");
        require(MerkleProof.verify(_merkleProof, holderMerkleRoot,  keccak256(abi.encodePacked(msg.sender, _quantity))), "TestNFT: Invalid Merkle Proof");
        require(msg.value == HOLDER_PRICE * _tokenIdList.length, "TestNFT: Incorrect payment amount");
        
        _generateSeed(_recipient, _tokenIdList);
        _overrideBuyBundle(_recipient, _tokenIdList);
        holderMinted[_recipient] += _tokenIdList.length;
    }

    /// @dev 残り110枚がミントできる
    function ownerMintByMintForPromotion(address _to, uint256 _quantity) external onlyOwner {
        /// @dev overrideMintForPromotion function of DeployedNFTMock
        deployedNFT.mintForPromotion(_to, _quantity);
    }

    function ownerMintByBuyBundle(address _to, uint256[] memory _tokenIdList) external onlyOwner {
        _overrideBuyBundle(_to, _tokenIdList);
    }

    modifier onlyAgent() {
        require(msg.sender == agentAddress, "TestNFT: Invalid agent address");
        _;
    }

    function _changeSaleState(bool _state) internal {
        deployedNFT.updateSaleStatus(_state);
    }

    /// @dev override buy function of DeployedNFTMock
    function _overrideBuy(address _to, uint256 tokenId) internal {
        _changeSaleState(true);
        /// @dev valueはDeployedNFTMockのPRICE()を参照する
        /// @dev それぞれのコントラクトにETHが送金される
        deployedNFT.buy{value: PRICE}(tokenId);
        _changeSaleState(false);

        _transfer(_to, tokenId);
    }

    function _overrideBuyBundle(address _to, uint256[] memory _tokenIdList) internal {
        _changeSaleState(true);
        deployedNFT.buyBundle{value: PRICE * _tokenIdList.length}(_tokenIdList);
        _changeSaleState(false);

        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            _transfer(_to, _tokenIdList[i]);
            emit Minted(_tokenIdList[i], getArtistFor3rdSale(_tokenIdList[i]), tokenIdToSeed[_tokenIdList[i]]);
        }
    }

    function _transfer(address _to, uint256 tokenId) internal {
        /// @dev 署名付きトランザクションでの実行を想定しているため、その前にcushionAddressで、address(this)をapproveForAllする必要がある（like OpenSeaの署名）
        deployedNFT.safeTransferFrom(address(this), cushionAddress, tokenId);        
        deployedNFT.safeTransferFrom(cushionAddress, _to, tokenId);        
    }

    function _generateSeed(address _addr, uint256[] memory _tokenIdList) internal {
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            /// @dev 本番ではblockhash等を使う
            tokenIdToSeed[_tokenIdList[i]] = keccak256(abi.encodePacked(_tokenIdList[i], block.number, blockhash(block.number - 1), _addr));
            /// @dev 本番では消す
            // tokenIdToSeed[_tokenIdList[i]] = keccak256(abi.encodePacked(_tokenIdList[i], _addr));
        }
    }

    /// @dev EOAのみに限定する
    function overrideTransferOwnership(address _to) public onlyOwner {
        require(!Address.isContract(_to), "TestNFT: Cannot transfer ownership to a contract");
        deployedNFT.transferOwnership(_to);
    }

    function setIsHolderSaleActive(bool _state) external onlyOwner {
        require(holderMerkleRoot != bytes32(0), "TestNFT: MerkleRoot is not set");
        isHolderSaleActive = _state;
    }

    function setIsAllowlistSaleActive(bool _state) external onlyOwner {
        require(allowlistMerkleRoot != bytes32(0), "TestNFT: MerkleRoot is not set");
        isAllowlistSaleActive = _state;
    }

    function setIsPublicSaleActive(bool _state) external onlyOwner {
        isPublicSaleActive = _state;
    }

    /// @dev 入力を間違えないようにする
    function setMerkleRoot(
        bytes32 _holderMerkleRoot,
        bytes32 _allowlistMerkleRoot
    ) external onlyOwner {
        holderMerkleRoot = _holderMerkleRoot;
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        deployedNFT.updateBaseURI(_newBaseURI);
    }

    function setAgentAddress(address _agentAddress) external onlyOwner {
        agentAddress = _agentAddress;
    }
    
    function getSeed(uint256 tokenId) external view returns (bytes32) {
        return tokenIdToSeed[tokenId];
    }

    /// @dev 本番 public => internal
    function getArtistFor3rdSale(uint256 tokenId) public pure returns (Artist) {        
        if (tokenId <= 2888) {
            return Artist.Okazz;
        } else if (tokenId <= 5801) {
            return Artist.Raf;
        } else {
            return Artist.Ykxotkx;
        }
    }
    
    function withdraw(address payable _receiptAddress) external onlyOwner {
        require(_receiptAddress != address(0), "TestNFT: Invalid receipt address");

        _receiptAddress.transfer(address(this).balance);        
        deployedNFT.withdrawETH();
    }

    /// @dev ERC721Receiver は 必要
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}

}