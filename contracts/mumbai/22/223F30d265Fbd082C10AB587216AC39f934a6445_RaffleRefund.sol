/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

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

interface IRaffleTicket {
    function burnFrom(address to, uint256 amount) external returns (bool);
}

interface IVault {
    function transferFromVault(address to, uint256 amountInWei)
        external
        returns (bool);
}

contract RaffleRefund {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event RefundMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    /// @notice Thrown if address has already claimed
    error RefundAlreadyClaimed();

    event RaffleRefunded(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    mapping(address => bool) private _owner;
    bool private _paused;

    address public RAFFLE_TICKET_ADDRESS;
    address public VAULT;
    uint256 public RAFFLE_TICKET_PRICE;

    bytes32 public RefundMerkleRoot;

    /// @notice Mapping of addresses who have claimed tokens
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    uint256[] private claimedWord;

    constructor(
        address[] memory owner,
        address raffleaddr,
        address vaultaddr,
        uint256 price_per_raffleticket_in_wei
    ) {
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _paused = true;
        RAFFLE_TICKET_ADDRESS = raffleaddr;
        VAULT = vaultaddr;
        RAFFLE_TICKET_PRICE = price_per_raffleticket_in_wei;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), "RaffleRefund: caller is not the owner");
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
        require(!paused(), "RaffleRefund#Pausable: paused");
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
        require(paused(), "RaffleRefund#Pausable: not paused");
        _;
    }

    function pause() external onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

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

    function setRefundMerkleRoot(bytes32 root) external onlyOwner {
        require(paused(), "RaffleRefund#setRefundMerkleRoot: not paused (root can be changed only whenPaused)");
        for (uint256 i = 0; i < claimedWord.length; i++) {
            delete claimedBitMap[claimedWord[i]];
        }
        delete claimedWord;
        emit RefundMerkleRootUpdated(RefundMerkleRoot, root);
        RefundMerkleRoot = root;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWordValue = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWordValue & mask == mask;
    }

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

    function claimRaffleRefund(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused returns (bool) {
        require(
            !isContract(_msgSender()),
            "RaffleRefund#claimRaffleRefund: no contract allowed"
        );
        require(
            !isClaimed(index),
            "RaffleRefund#claimRaffleRefund: Refund Already Claimed"
        );
        bytes32 leafnode = keccak256(
            abi.encodePacked(index, _msgSender(), amount)
        );
        require(
            MerkleProof.verify(merkleProof, RefundMerkleRoot, leafnode),
            "RaffleRefund#claimRaffleRefund: Invalid proof."
        );
        _setClaimed(index);
        require(
            IRaffleTicket(RAFFLE_TICKET_ADDRESS).burnFrom(_msgSender(), amount),
            "RaffleRefund#claimRaffleRefund: Burning Raffle Ticket Failed"
        );
        require(
            IVault(VAULT).transferFromVault(
                _msgSender(),
                amount * RAFFLE_TICKET_PRICE
            ),
            "RaffleRefund#claimRaffleRefund: Payment from Vault Failed"
        );

        emit RaffleRefunded(index, _msgSender(), amount);

        return true;
    }
}