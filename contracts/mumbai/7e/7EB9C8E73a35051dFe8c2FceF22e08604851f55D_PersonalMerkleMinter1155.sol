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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './TimedSale1155.sol';

interface ICoolERC1155 {
  function mint(address to, uint256 tokenId, uint256 amount) external;
}

/// @title BaseMinter
/// @notice This contract is used to mint tokens, with ownable, pausing, withdrawal and pricing.
contract BaseMinter1155 is Ownable, Pausable, TimedSale1155 {
  address public _tokenAddress;
  ICoolERC1155 public _tokenContract;

  struct TokenDetails {
    bool forSale;
    uint256 pricePerToken;
  }

  address public _withdrawalAddress;
  mapping(uint256 => TokenDetails) public _tokenDetails;

  event TokenContractSet(address tokenAddress);
  event WithdrawalAddressSet(address withdrawalAddress);
  event TokenDetailsUpdated(uint256 tokenId, bool forSale, uint256 pricePerToken);

  error NotForSale(uint256 tokenId);
  error IncorrectFundsSent(uint256 expected, uint256 sent);
  error InsufficientFundsForWithdrawal(uint256 amount, uint256 balance);
  error WithdrawalAddressNotSet();

  constructor(address tokenAddress, address withdrawalAddress) {
    _tokenAddress = tokenAddress;
    _tokenContract = ICoolERC1155(tokenAddress);

    _withdrawalAddress = withdrawalAddress;

    _pause();
  }

  /// @notice Pauses the contract - stopping minting via the public mint function
  /// @dev Only the owner can call this function
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract - allowing minting via the public mint function
  /// @dev Only the owner can call this function
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Withdraws a specific amount of mint funds to the withdrawal address
  /// @dev Only the owner can call this function
  /// @param amount The amount to withdraw
  function withdraw(uint256 amount) external onlyOwner {
    _withdraw(amount);
  }

  /// @notice Withdraws all mint funds to the withdrawal address
  /// @dev Only the owner can call this function
  function withdrawAll() external onlyOwner {
    _withdraw(address(this).balance);
  }

  /// @notice Sets the token contract address
  /// @dev Only the owner can call this function
  /// @param tokenAddress The address of the token contract
  function setTokenContract(address tokenAddress) external onlyOwner {
    _tokenAddress = tokenAddress;
    _tokenContract = ICoolERC1155(tokenAddress);

    emit TokenContractSet(tokenAddress);
  }

  /// @notice Returns the price per token for a given token ID
  /// @param tokenId The token ID to get the price for
  function getPricePerToken(uint256 tokenId) external view returns (uint256) {
    return _tokenDetails[tokenId].pricePerToken;
  }

  /// @notice Returns whether a token is for sale
  /// @param tokenId The token ID to get the for sale status for
  function isSaleActive(uint256 tokenId) public view override returns (bool) {
    if (!_tokenDetails[tokenId].forSale) return false;

    return super.isSaleActive(tokenId);
  }

  /// @notice Sets both the sale status and price per token for a given token ID
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the details for
  /// @param forSale Whether the token is for sale
  /// @param pricePerToken The price per token
  function setTokenDetails(
    uint256 tokenId,
    bool forSale,
    uint256 pricePerToken
  ) external onlyOwner {
    _tokenDetails[tokenId] = TokenDetails(forSale, pricePerToken);

    emit TokenDetailsUpdated(tokenId, forSale, pricePerToken);
  }

  /// @notice Sets the price per token
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the price for
  /// @param pricePerToken The price per token
  function setPricePerToken(uint256 tokenId, uint256 pricePerToken) external onlyOwner {
    TokenDetails storage tokenDetails = _tokenDetails[tokenId];
    tokenDetails.pricePerToken = pricePerToken;

    emit TokenDetailsUpdated(tokenId, tokenDetails.forSale, tokenDetails.pricePerToken);
  }

  /// @notice Sets the sale status
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the sale status for
  /// @param forSale Whether the token is for sale
  function setSaleStatus(uint256 tokenId, bool forSale) external onlyOwner {
    TokenDetails storage tokenDetails = _tokenDetails[tokenId];
    tokenDetails.forSale = forSale;

    emit TokenDetailsUpdated(tokenId, tokenDetails.forSale, tokenDetails.pricePerToken);
  }

  /// @notice Sets the withdrawal address
  /// @dev Only the owner can call this function
  /// @param withdrawalAddress The address to withdraw to
  function setWithdrawalAddress(address withdrawalAddress) external onlyOwner {
    _withdrawalAddress = withdrawalAddress;

    emit WithdrawalAddressSet(withdrawalAddress);
  }

  /// @notice Backend function to check if an address can mint tokens
  /// @dev Only the system address can call this function
  ///      Other checks are still required for an individual mint (check max per tx and wallet)
  ///      This implementation checks if the sale is paused
  /// @param tokenId The token id to check
  /// @return result True if the address can mint tokens
  ///         reason The reason why the address can't mint tokens
  function canUserBeMintedTo(
    address,
    uint256 tokenId
  ) public view virtual returns (bool result, string memory reason) {
    if (!_tokenDetails[tokenId].forSale) return (false, 'Token is not for sale');
    if (paused()) return (false, 'Sale is paused');
    if (!isSaleActive(tokenId)) return (false, 'Token sale is not active');

    return (true, '');
  }

  /// @notice mint function which checks the payment amount and calls the internal mint function
  /// @param to The address to mint to
  /// @param tokenId The token id to mint
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 tokenId, uint256 amount) public payable virtual {
    TokenDetails memory tokenDetails = _tokenDetails[tokenId];
    if (!tokenDetails.forSale) {
      revert NotForSale(tokenId);
    }
    uint256 totalCost = amount * tokenDetails.pricePerToken;
    if (msg.value != totalCost) {
      revert IncorrectFundsSent(totalCost, msg.value);
    }

    _mint(to, tokenId, amount);
  }

  /// @notice Internal mint function which calls the token contract to mint tokens
  /// @dev Only when the contract is unpaused
  /// @param to The address to mint to
  /// @param tokenId The token id to mint
  /// @param amount The amount of tokens to mint
  function _mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) internal virtual whenNotPaused onlyDuringSale(tokenId) {
    _tokenContract.mint(to, tokenId, amount);
  }

  /// @notice Internal function to withdraw funds to the withdrawal address
  /// @dev Checks that the withdrawal address is set and that there are enough funds
  /// @param amount The amount to withdraw
  function _withdraw(uint256 amount) internal virtual {
    if (_withdrawalAddress == address(0)) {
      revert WithdrawalAddressNotSet();
    }
    if (amount > address(this).balance) {
      revert InsufficientFundsForWithdrawal(amount, address(this).balance);
    }

    payable(_withdrawalAddress).transfer(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './LimitedMinter1155.sol';

/// @title CappedMinter
/// @notice This contract is used to mint tokens with a cap.
/// @dev This contract inherits from LimitedMinter. A cap of 0 means no cap.
contract CappedMinter1155 is LimitedMinter1155 {
  struct MintingCap {
    uint256 maxSupply;
    uint256 minted;
  }

  /// @notice Maps the tokenId to the max amount of tokens that can be minted, and the amount minted so far
  mapping(uint256 => MintingCap) public _mintingCaps;

  event MaxMintAmountSet(uint256 tokenId, uint256 maxMintAmount);

  error MintAmountExceedsMax(uint256 amount, uint256 remaining);

  constructor(
    address tokenContract,
    address withdrawalAddress
  ) LimitedMinter1155(tokenContract, withdrawalAddress) {}

  /// @notice Sets the max amount of tokens that can be minted
  /// @dev Only the owner can call this function
  /// @param maxMintAmount The max amount of tokens that can be minted
  function setMaxMintAmount(uint256 tokenId, uint256 maxMintAmount) external virtual onlyOwner {
    _mintingCaps[tokenId].maxSupply = maxMintAmount;

    emit MaxMintAmountSet(tokenId, maxMintAmount);
  }

  /// @notice Backend function to check if an address can mint tokens
  /// @dev Only the system address can call this function
  ///      Other checks are still required for an individual mint (check max per tx and wallet)
  ///      This implementation checks if the tokens are sold out
  /// @param user The address to check
  /// @param tokenId The tokenId to check
  /// @return result True if the address can mint tokens
  ///         reason The reason why the address can't mint tokens
  function canUserBeMintedTo(
    address user,
    uint256 tokenId
  ) public view virtual override returns (bool result, string memory reason) {
    MintingCap memory mintingCap = _mintingCaps[tokenId];
    if (mintingCap.maxSupply > 0 && mintingCap.minted >= mintingCap.maxSupply)
      return (false, 'Sold out');

    return super.canUserBeMintedTo(user, tokenId);
  }

  /// @notice Mints tokens to an address
  /// @dev This includes the max mint amount check
  /// @param to The address to mint tokens to
  /// @param tokenId The tokenId to mint
  /// @param amount The amount of tokens to mint
  function _mint(address to, uint256 tokenId, uint256 amount) internal virtual override {
    MintingCap storage mintingCap = _mintingCaps[tokenId];
    if (mintingCap.maxSupply > 0 && mintingCap.minted + amount > mintingCap.maxSupply) {
      revert MintAmountExceedsMax(amount, mintingCap.maxSupply - mintingCap.minted);
    }

    mintingCap.minted += amount;

    super._mint(to, tokenId, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './BaseMinter1155.sol';

/// @title LimitedMinter
/// @notice This contract is used to mint tokens with a limit per transaction and per wallet
/// @dev This contract inherits from BaseMinter
///      Per tx and wallet limits can be disabled by setting them to 0
contract LimitedMinter1155 is BaseMinter1155 {
  struct PurchaseLimits {
    uint256 maxPerTx;
    uint256 maxPerWallet;
  }

  /// @notice The max per mints per transaction and per wallet, for each tokenId
  mapping(uint256 => PurchaseLimits) public _purchaseLimits;

  /// @notice maps user => tokenId => amount
  mapping(address => mapping(uint256 => uint256)) public _mintedPerWallet;

  event MaxPerTxSet(uint256 tokenId, uint256 maxPerTx);
  event MaxPerWalletSet(uint256 tokenId, uint256 maxPerWallet);

  error MaxPerTxExceeded(uint256 maxPerTx, uint256 amount);
  error MaxPerWalletExceeded(uint256 maxPerWallet, uint256 amount);

  constructor(
    address tokenContract,
    address withdrawalAddress
  ) BaseMinter1155(tokenContract, withdrawalAddress) {}

  /// @notice Sets the max mints per transaction
  /// @dev Only the owner can call this function
  /// @param tokenId The tokenId to set the limit for
  /// @param maxPerTx The max per transaction
  function setMaxPerTx(uint256 tokenId, uint256 maxPerTx) external onlyOwner {
    _purchaseLimits[tokenId].maxPerTx = maxPerTx;

    emit MaxPerTxSet(tokenId, maxPerTx);
  }

  /// @notice Sets the max mints per wallet
  /// @dev Only the owner can call this function
  /// @param tokenId The tokenId to set the limit for
  /// @param maxPerWallet The max mints per wallet
  function setMaxPerWallet(uint256 tokenId, uint256 maxPerWallet) external onlyOwner {
    _purchaseLimits[tokenId].maxPerWallet = maxPerWallet;

    emit MaxPerWalletSet(tokenId, maxPerWallet);
  }

  /// @notice Sets the max mints per transaction and per wallet
  /// @dev Only the owner can call this function
  /// @param tokenId The tokenId to set the limit for
  /// @param maxPerTx The max per transaction
  /// @param maxPerWallet The max mints per wallet
  function setPurchaseLimits(
    uint256 tokenId,
    uint256 maxPerTx,
    uint256 maxPerWallet
  ) external onlyOwner {
    _purchaseLimits[tokenId] = PurchaseLimits(maxPerTx, maxPerWallet);

    emit MaxPerTxSet(tokenId, maxPerTx);
    emit MaxPerWalletSet(tokenId, maxPerWallet);
  }

  /// @notice Backend function to check if an address can mint tokens
  /// @dev Only the system address can call this function
  ///      Other checks are still required for an individual mint (check max per tx and wallet)
  ///      This implementation checks if the user has already minted their max amount
  /// @param user The address to check
  /// @param tokenId The tokenId to check
  /// @return result True if the address can mint tokens
  ///         reason The reason why the address can't mint tokens
  function canUserBeMintedTo(
    address user,
    uint256 tokenId
  ) public view virtual override returns (bool result, string memory reason) {
    PurchaseLimits memory limits = _purchaseLimits[tokenId];
    if (limits.maxPerWallet > 0 && _mintedPerWallet[user][tokenId] >= limits.maxPerWallet)
      return (false, 'Max per wallet exceeded');

    return super.canUserBeMintedTo(user, tokenId);
  }

  /// @notice Mints amount of tokens to the user
  /// @dev enforces max per tx and wallet
  /// @param to The address to mint tokens to
  /// @param tokenId The tokenId to mint
  /// @param amount The amount of tokens to mint
  function _mint(address to, uint256 tokenId, uint256 amount) internal virtual override {
    PurchaseLimits memory limits = _purchaseLimits[tokenId];
    if (limits.maxPerTx > 0 && amount > limits.maxPerTx) {
      revert MaxPerTxExceeded(limits.maxPerTx, amount);
    }

    uint256 mintedPerWallet = _mintedPerWallet[to][tokenId];
    if (limits.maxPerWallet > 0 && mintedPerWallet + amount > limits.maxPerWallet) {
      revert MaxPerWalletExceeded(limits.maxPerWallet, amount);
    }

    _mintedPerWallet[to][tokenId] = mintedPerWallet + amount;

    super._mint(to, tokenId, amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '../CappedMinter1155.sol';

/// @title PersonalMerkleMinter1155
/// @author Adam | Grampa_Bacon
/// @notice This contract allows for minting of tokens only by users on the merkle tree allowlist,
///         and only to themselves.
contract PersonalMerkleMinter1155 is CappedMinter1155 {
  struct MerkleData {
    bytes32 merkleRoot;
    bool allowlistEnabled;
  }

  mapping(uint256 => MerkleData) public _allowlistData;

  event MerkleRootSet(uint256 tokenId, bytes32 merkleRoot);
  event AllowlistEnabled(uint256 tokenId, bool allowlistEnabled);

  error AllowlistActive(bool active);
  error CanOnlyMintToSelf(address to, address msgSender);
  error NotAllowlisted(uint256 tokenId);
  error NullMerkleRoot();

  constructor(
    address tokenContract,
    address withdrawalAddress
  ) CappedMinter1155(tokenContract, withdrawalAddress) {}

  function allowlistMint(
    uint256 tokenId,
    uint256 amount,
    bytes32[] calldata proof
  ) external payable virtual {
    MerkleData memory data = _allowlistData[tokenId];
    if (!data.allowlistEnabled || data.merkleRoot == bytes32(0)) {
      revert AllowlistActive(false);
    }

    // Verify the merkle proof.
    if (!isValidMerkleProof(msg.sender, tokenId, proof)) {
      revert NotAllowlisted(tokenId);
    }

    super.mint(msg.sender, tokenId, amount);
  }

  /// @notice Mints amount of tokens to the sender
  /// @dev This exists to override the mint function in LimitedMinter
  /// @param tokenId The tokenId to mint
  /// @param amount The amount of tokens to mint
  function mint(uint256 tokenId, uint256 amount) external payable {
    mint(msg.sender, tokenId, amount);
  }

  /// @notice Mints amount of tokens to the to address, reverts if the to address is not the sender
  /// @dev This exists to override the mint function in LimitedMinter
  /// @param to The address to mint tokens to (must be the sender)
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 tokenId, uint256 amount) public payable virtual override {
    if (_allowlistData[tokenId].allowlistEnabled) {
      revert AllowlistActive(true);
    }

    super.mint(to, tokenId, amount);
  }

  /// @notice Mints tokens to an address
  /// @dev This includes the max mint amount check
  /// @param to The address to mint tokens to
  /// @param tokenId The tokenId to mint
  /// @param amount The amount of tokens to mint
  function _mint(address to, uint256 tokenId, uint256 amount) internal override {
    if (to != msg.sender) {
      revert CanOnlyMintToSelf(to, msg.sender);
    }

    super._mint(to, tokenId, amount);
  }

  /// @notice Sets the merkle root
  /// @dev Only the owner can call this function
  /// @param merkleRoot The new merkle root
  function setMerkleRoot(uint256 tokenId, bytes32 merkleRoot) external virtual onlyOwner {
    MerkleData memory data = _allowlistData[tokenId];
    if (data.allowlistEnabled && merkleRoot == bytes32(0)) {
      revert AllowlistActive(true);
    }

    _allowlistData[tokenId] = MerkleData(merkleRoot, true);

    emit MerkleRootSet(tokenId, merkleRoot);
  }

  /// @notice Sets the allowlist status
  /// @dev Only the owner can call this function
  /// @param allowlistEnabled The new allowlist status
  function setAllowlistEnabled(uint256 tokenId, bool allowlistEnabled) external virtual onlyOwner {
    MerkleData memory data = _allowlistData[tokenId];
    if (data.merkleRoot == bytes32(0) && allowlistEnabled) {
      revert NullMerkleRoot();
    }

    _allowlistData[tokenId].allowlistEnabled = allowlistEnabled;

    emit AllowlistEnabled(tokenId, allowlistEnabled);
  }

  /// @notice Checks if a given address is on the merkle tree allowlist
  /// @dev Merkle trees can be generated using https://github.com/OpenZeppelin/merkle-tree
  /// @param account The address to check
  /// @param merkleProof The merkle proof to check
  function isValidMerkleProof(
    address account,
    uint256 tokenId,
    bytes32[] calldata merkleProof
  ) public view virtual returns (bool) {
    return
      MerkleProof.verify(
        merkleProof,
        _allowlistData[tokenId].merkleRoot,
        keccak256(bytes.concat(keccak256(abi.encode(account, tokenId))))
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

/// @title TimedSale
/// @notice Adds functionality to a minter to allow for a timed sale
/// @dev Functionality is disabled if both the start and end time are 0
contract TimedSale1155 is Ownable {
  struct Sale {
    uint256 startTime;
    uint256 endTime;
  }

  // Maps token ID to sale times
  mapping(uint256 => Sale) public _mintTimes;

  event StartAndEndTimeSet(uint256 tokenId, uint256 startTime, uint256 endTime);

  error SaleNotStarted(uint256 startTime);
  error SaleEnded(uint256 endTime);
  error StartAfterEnd(uint256 startTime, uint256 endTime);

  modifier onlyDuringSale(uint256 tokenId) {
    Sale memory times = _mintTimes[tokenId];

    if (times.startTime > 0 || times.endTime > 0) {
      if (block.timestamp < times.startTime) {
        revert SaleNotStarted(times.startTime);
      }
      if (block.timestamp > times.endTime) {
        revert SaleEnded(times.endTime);
      }
    }
    _;
  }

  /// @notice Sets the start time for the sale
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the start time for
  /// @param startTime The start time for the sale
  function setStartTime(uint256 tokenId, uint256 startTime) external {
    setStartAndEndTime(tokenId, startTime, _mintTimes[tokenId].endTime);
  }

  /// @notice Sets the end time for the sale
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the end time for
  /// @param endTime The end time for the sale
  function setEndTime(uint256 tokenId, uint256 endTime) external {
    setStartAndEndTime(tokenId, _mintTimes[tokenId].startTime, endTime);
  }

  /// @notice Sets the start and end time for the sale
  /// @dev Only the owner can call this function
  /// @param tokenId The token ID to set the sale times for
  /// @param startTime The start time for the sale
  /// @param endTime The end time for the sale
  function setStartAndEndTime(
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime
  ) public onlyOwner {
    if (startTime > endTime) {
      revert StartAfterEnd(startTime, endTime);
    }

    _mintTimes[tokenId] = Sale(startTime, endTime);

    emit StartAndEndTimeSet(tokenId, startTime, endTime);
  }

  /// @notice Returns the remaining time (in seconds) for the sale
  /// @param tokenId The token ID to get the remaining time for
  function saleTimeRemaining(uint256 tokenId) external view returns (uint256) {
    if (isSaleActive(tokenId)) {
      return _mintTimes[tokenId].endTime - block.timestamp;
    }
    return 0;
  }

  /// @notice Returns whether the sale has started
  /// @param tokenId The token ID to check
  function isSaleStarted(uint256 tokenId) public view returns (bool) {
    return block.timestamp >= _mintTimes[tokenId].startTime;
  }

  /// @notice Returns whether the sale has ended
  /// @param tokenId The token ID to check
  function isSaleEnded(uint256 tokenId) public view returns (bool) {
    uint256 endTime = _mintTimes[tokenId].endTime;
    if (endTime == 0) {
      return false;
    }
    return block.timestamp >= endTime;
  }

  /// @notice Returns whether the sale is currently active
  /// @param tokenId The token ID to check
  function isSaleActive(uint256 tokenId) public view virtual returns (bool) {
    return isSaleStarted(tokenId) && !isSaleEnded(tokenId);
  }
}