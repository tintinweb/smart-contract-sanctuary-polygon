// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.12;

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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

interface INFT1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IRaffleTicket {
    function burnFrom(address to, uint256 amount) external returns (bool);
}

contract NFTDistributor {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted after a ClaimMerkleRoot has been Updated.
     */
    event ClaimMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    /**
     * @dev Emitted after a successful NFT claim
     * 
     * @param account recipient of claim
     * @param tokenIds of NFT claimed
     * @param amounts of NFT claimed
     */
    event NFTClaimed(
        uint256 indexed index,
        address indexed account,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /**
     * @dev  Thrown if address has already claimed
     */
    error NFTAlreadyClaimed();

    mapping(address => bool) private _owner;
    bool private _paused;

    address public RAFFLE_TICKET_ADDRESS;
    address public NFT_ADDRESS;
    bytes32 public ClaimMerkleRoot;

    /**
     * @dev Mapping of addresses who have claimed tokens
     * This is a packed array of booleans.
     */
    mapping(uint256 => uint256) private claimedBitMap;

    uint256[] private claimedWord;

    constructor(
        address[] memory owner,
        address nftaddr,
        address raffleaddr
    ) {
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _paused = true;
        NFT_ADDRESS = nftaddr;
        RAFFLE_TICKET_ADDRESS = raffleaddr;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws error if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            isOwner(_msgSender()),
            "NFTDistributor: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "NFTDistributor#Pausable: paused");
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
        require(paused(), "NFTDistributor#Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
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
    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Returns true if `account` is the contract address.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev updates claim MerkleRoot and resets `claimedWord`
     *
     * Requirements:
     *
     * - The caller must be owner.
     */
    function setClaimMerkleRoot(bytes32 root) external onlyOwner {
        require(paused(), "NFTDistributor#setClaimMerkleRoot: not paused (root can be changed only whenPaused)");
        for (uint256 i = 0; i < claimedWord.length; i++) {
            delete claimedBitMap[claimedWord[i]];
        }
        delete claimedWord;
        emit ClaimMerkleRootUpdated(ClaimMerkleRoot, root);
        ClaimMerkleRoot = root;
    }

    /**
     * @dev Returns true if `index` has been already claimed
     */
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWordValue = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWordValue & mask == mask;
    }

    /**
     * @dev registers `index` that has claimed
     */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        if (claimedBitMap[claimedWordIndex] == 0) {
            claimedWord.push(claimedWordIndex);
        }
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @dev User can claim `amounts` NFT of token type `tokenIds` 
     * if they provide valid `merkleProof` and `rafflecount` to burn
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function claimNFT(
        uint256 index,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 rafflecount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused returns (bool) {
        require(
            !isContract(_msgSender()),
            "NFTDistributor#claimNFT: no contract allowed"
        );
        require(
            !isClaimed(index),
            "NFTDistributor#claimNFT: NFT Already Claimed"
        );

        // Construct the leafnode and Verify the merkle proof.
        bytes32 leafnode = keccak256(
            abi.encodePacked(
                index,
                _msgSender(),
                tokenIds,
                amounts,
                rafflecount
            )
        );
        require(
            MerkleProof.verify(merkleProof, ClaimMerkleRoot, leafnode),
            "NFTDistributor#claimNFT: Invalid proof."
        );

        // Mark `index` claimed and  burn the Raffle token.
        _setClaimed(index);
        require(
            IRaffleTicket(RAFFLE_TICKET_ADDRESS).burnFrom(
                _msgSender(),
                rafflecount
            ),
            "NFTDistributor#claimNFT: Burning Raffle Ticket Failed"
        );

        // sends the nft to `msg.sender`
       INFT1155(NFT_ADDRESS).mintBatch(_msgSender(), tokenIds, amounts, "");

        emit NFTClaimed(index, _msgSender(), tokenIds, amounts);

        return true;
    }
}