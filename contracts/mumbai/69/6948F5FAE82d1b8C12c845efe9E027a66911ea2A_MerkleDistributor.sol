/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title Interface for a sweepable airdrop contract based on merkle tree
 *
 * The airdrop has an expiration time. Once this expiration time
 * is reached the contract owner can sweep all unclaimed funds.
 * As long as the contract has funds, claiming will continue to
 * work after expiration time.
 *
 * @author Michael Bauer <[email protected]>
 */
interface IMerkleDistributor {
    /**
     * Returns the address of the token distributed by this contract.
     */
    function token() external view returns (address);

    /**
     * Returns the expiration time of the airdrop as unix timestamp
     * (Seconds since unix epoch)
     */
    function expireTimestamp() external view returns (uint256);

    /**
     * Returns the merkle root of the merkle tree containing
     * account balances available to claim.
     */
    function merkleRoot() external view returns (bytes32);

    /**
     * @notice Claim and transfer tokens
     *
     * Verifies the provided proof and params
     * and transfers 'amount' of tokens to 'account'.
     *
     * @param account Address of claim
     * @param amount Amount of claim
     * @param proof Merkle proof for (account, amount)
     *
     * Emits a {Claimed} event on success.
     */
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external;

    /**
     * @notice Sweep any unclaimed funds
     *
     * Transfers the full tokenbalance from the distributor contract to `target` address.
     *
     * @param target Address that should receive the unclaimed funds
     */
    function sweep(address target) external;

    /**
     * @notice Sweep any unclaimed funds to owner address
     *
     * Transfers the full tokenbalance from the distributor contract to owner of contract.
     */
    function sweepToOwner() external;

    /**
     * @dev Emitted when an airdrop is claimed for an `account`.
     * in the merkle tree, `value` is the amount of tokens claimed and transferred.
     */
    event Claimed(address indexed account, uint256 amount);
}

// https://github.com/Uniswap/merkle-distributor
contract MerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable expireTimestamp;

    mapping(address => bool) public hasClaimed;

    /**
     * @dev sets values for associated token (ERC20), merkleRoot and expiration time
     *
     * @param token_ Contract address of the ERC20 token that is being dropped
     * @param merkleRoot_ Root of the token distribution merkle tree
     * @param expireTimestamp_ Timestamp when sweeping gets enabled (seconds since unix epoch)
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 expireTimestamp_
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        expireTimestamp = expireTimestamp_;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!hasClaimed[account], 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed.
        hasClaimed[account] = true;

        // Transfer token
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Failed token transfer');

        emit Claimed(account, amount);
    }

    /**
     * @dev Sweep any unclaimed funds to arbitrary destination. Can only be called by owner.
     */
    function sweep(address target) external onlyOwner {
        require(block.timestamp >= expireTimestamp, 'MerkleDistributor: Drop not expired');
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(target, balance);
    }

    /**
     * @dev Sweep any unclaimed funds to contract owner. Can be called by anyone.
     */
    function sweepToOwner() external {
        require(block.timestamp >= expireTimestamp, 'MerkleDistributor: Drop not expired');
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }
}