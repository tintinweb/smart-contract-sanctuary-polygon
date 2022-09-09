/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StreamDrop {
    event Claim(address indexed to, uint256 amount);
    event ClaimForOtherAddress(
        address indexed claimant,
        address indexed newAddress,
        uint256 amount
    );

    /* ========== STATE VARIABLES ========== */

    struct Stream {
        uint64 id;
        address owner;
        uint256 balance;
        uint256 initialBalance;
        uint64 endTime;
        uint64 startTime;
    }

    Stream[] public allStreams;

    // Which stream each address owns
    mapping(address => Stream) public streamForAddress;

    bytes32 public immutable merkleRoot =
        0x615e966478b9487e2dcdd8611c865143d026d16e77f745439e16268e2b06a47f;

    // Location of Halo token contract
    address public immutable tokenAddress =
        0x04c6fC407cB56C3A101661e82F86CF23B8134D02;

    // Which addresses have claimed their streams
    mapping(address => bool) public hasClaimed;

    uint256 public claimedBalance = 0;

    uint64 public numStreams;

    uint64 public streamLength = 5 * 52 weeks;

    bool public incentivizedStreamsInitialized = false;
    bool public treasuryStreamInitialized = false;

    /* ========== FUNCTIONS ========== */

    function getLeaf(address to, uint256 amount) public pure returns (bytes32) {
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        return leaf;
    }

    function verifyProof(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // This function can be called by anyone to start a stream with verified proof
    function claimStream(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        // Throw if address has already has a stream
        require(
            streamForAddress[to].id == 0,
            'Address has already has a stream'
        );

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, 'Address and amount not proved to be in tree');

        // Set address to claimed
        hasClaimed[to] = true;

        startStream(to, amount);

        // Emit claim event
        emit Claim(to, amount);
    }

    // This function can be called by anyone who has a stream that they have
    // not yet claimed to claim their stream to a different address. For instance,
    // to change from hardware wallet to hot wallet.
    function claimStreamForOtherAddress(
        address newAddress,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        // Throw if address has already claimed tokens
        require(!hasClaimed[msg.sender], 'Address has already claimed stream');

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, 'Address and amount not proved to be in tree');

        // Set address to claimed
        hasClaimed[msg.sender] = true;

        startStream(newAddress, amount);

        // Emit claim event
        emit ClaimForOtherAddress(msg.sender, newAddress, amount);
    }

    // Internal function to start a stream
    // tokens come from the balance of this contract
    function startStream(address owner, uint256 amount) internal {
        IERC20 Token = IERC20(tokenAddress);
        require(
            Token.balanceOf(address(this)) >= amount,
            'The contract does not have enough tokens'
        );

        claimedBalance += amount;

        Stream memory stream;
        stream.id = numStreams;
        stream.owner = owner;
        stream.balance = amount;
        stream.initialBalance = amount;
        stream.startTime = uint64(block.timestamp);
        stream.endTime = stream.startTime + streamLength;

        allStreams.push(stream);
        streamForAddress[owner] = stream;
        numStreams++;
    }

    // Function that starts streams for each of the incentivized battle mountains
    // Can be called only once and only by angelbattles.eth
    function startIncentivizedStreams(
        address _battleMountainAddress,
        address _battleArenaAddress,
        address _lightAngelAddress,
        address _darkAngelAddress,
        address _freeCardAddress,
        address _l2CardsAddress
    ) public {
        // angelbattles.eth
        require(
            msg.sender == 0x20886Ba6fD8731ed974ba00108F043fC9006e1f8,
            'Only angelbattles.eth'
        );
        require(incentivizedStreamsInitialized == false);
        incentivizedStreamsInitialized = true;

        // 10 million tokens represents 1% of the total Halo supply
        uint256 onePercent = 10000000000000000000000000;
        startStream(_battleMountainAddress, 7 * onePercent);
        startStream(_battleArenaAddress, 7 * onePercent);
        startStream(_lightAngelAddress, 3 * onePercent);
        startStream(_darkAngelAddress, 3 * onePercent);
        startStream(_freeCardAddress, onePercent);
        startStream(_l2CardsAddress, onePercent);
    }

    function startTreasuryStream(address _treasuryAddress) public {
        // angelbattles.eth
        require(
            msg.sender == 0x20886Ba6fD8731ed974ba00108F043fC9006e1f8,
            'Only angelbattles.eth'
        );
        require(treasuryStreamInitialized == false);
        treasuryStreamInitialized = true;

        // 52% of tokens get streamed to the treasury over 10 years
        uint256 amount = 520000000000000000000000000;

        IERC20 Token = IERC20(tokenAddress);
        require(
            Token.balanceOf(address(this)) >= amount,
            'The contract does not have enough tokens'
        );

        claimedBalance += amount;

        Stream memory stream;
        stream.id = numStreams;
        stream.owner = _treasuryAddress;
        stream.balance = amount;
        stream.initialBalance = amount;
        stream.startTime = uint64(block.timestamp);
        stream.endTime = stream.startTime + (2 * streamLength);

        allStreams.push(stream);
        streamForAddress[_treasuryAddress] = stream;
        numStreams++;
    }

    function getClaimAmount(address _address)
        public
        view
        returns (uint256 amount)
    {
        uint64 elapsedTime = (uint64(block.timestamp) -
            streamForAddress[_address].startTime);
        // Initial balance must be at least on the order of stream length.
        uint256 totalOwed = (streamForAddress[_address].initialBalance *
            elapsedTime) / streamLength;

        amount =
            totalOwed +
            streamForAddress[_address].balance -
            streamForAddress[_address].initialBalance;

        return amount;
    }

    // Function that claims the appropraite amount of tokens
    function claimTokens(address _to) public {
        IERC20 Token = IERC20(tokenAddress);

        uint256 amount = getClaimAmount(_to);

        require(
            Token.balanceOf(address(this)) >= amount,
            'This contract does not have enough balance'
        );

        // Decrement the balance
        streamForAddress[_to].balance -= amount;

        // Transfer the amount.
        Token.transfer(_to, amount);
    }
}