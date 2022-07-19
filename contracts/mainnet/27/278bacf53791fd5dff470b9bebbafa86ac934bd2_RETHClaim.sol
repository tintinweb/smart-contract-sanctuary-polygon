/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

//SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol


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

// File: AirdropClaim.sol


pragma solidity ^0.8.4;



interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
/* 
 0x446576656c6f7065642062792053442d4d414c494e47410000000000000000
 Contract for airdrop token claim
 */

contract RETHClaim is Ownable {
    bool internal locked;
    IERC20 public token;
    bytes32 public root;

    struct UserData {
        address wallet;
        uint256 amt;
        bool claimed;
    }

    mapping(address=>bool) public claimed;
    mapping(address=>uint256) public amountClaimed;
    mapping(address=>UserData) public userData;
    mapping(bytes32=>bool) public leafUsed;

    event doneClaim(address wallet, uint256 amount);
    constructor(IERC20 add) {
        token = add;
    }


    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }


    function feedData(address wallet_, uint256 amt_) public onlyOwner {
        userData[wallet_] = UserData(
            wallet_,
            amt_,
            false
        );
    }


    function claim() nonReentrancy external nonReentrancy {
        require(userData[msg.sender].claimed == false, "Already Claimed");
        userData[msg.sender].claimed = true;
        uint256 useramt = userData[msg.sender].amt;
        token.transfer(msg.sender, useramt);
        amountClaimed[msg.sender]+= useramt;
        emit doneClaim(msg.sender, useramt);
    }

    function claimDrop(uint256 amt, bytes32[] memory proof) external nonReentrancy {
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked([keccak256(abi.encodePacked(msg.sender)), bytes32(amt)]))));
        require(leafUsed[leaf] == false, "Already claimed");
        require(isValid(proof, leaf), "Not a part of Allowlist");
        leafUsed[leaf] = true;
        claimed[msg.sender] = true;
        token.transfer(msg.sender, amt);
        amountClaimed[msg.sender]+=amt;
        emit doneClaim(msg.sender, amt);
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }
    function userAmt(address add_) public view returns (uint256) {
        uint256 udata_ = userData[add_].amt;
        return udata_;
    }

    function  userStatus(address add_) public view returns (bool) {
        bool udata_ = userData[add_].claimed;
        return udata_;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
    function isValidA(bytes32[] memory proof, uint256 amt, address add_) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked([keccak256(abi.encodePacked(add_)), bytes32(amt)]))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdraw(IERC20 address_, uint256 amt_) external onlyOwner {
        address_.transfer(owner(), amt_);
    }

}