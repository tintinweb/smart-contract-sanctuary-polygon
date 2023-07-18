/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: Market.sol


pragma solidity ^0.8.0;





interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Market is Ownable, ReentrancyGuard {
    uint256 public firstWhiteListTokenPrice = 2; //0.02 * 100 USD
    uint256 public presaleTokenPrice = 3; //0.03 * 100 USD
    uint256 public normalSaleTokenPrice = 4; //0.04 * 100 USD
    uint256 public usdt_usdc_value = 100; // 1.00 USD
    uint256 public maxTokenForWhiteListUser = 1250 * 1e18;
    uint256 public maxTokenLimitOfPresale = 18000000 * 1e18;
    uint256 public minDollarAmountForMatic = 1e20; //5e20; $1
    uint256 public minDollarAmountForUsdtUsdc = 1e8; //5e8; $1
    uint256 public tokenSoldInPresale;
    address private paymentReceiver;
    bytes32 public merkleRoot =
        0xc86d368b9ab2cdb70cf357e5a368a1feb663e7b06eb4fcfa9b6c4996e312e8d6;
    // uint256 public currentTokenPrice;
    bool isWhiteListStart;
    bool isPresaleStart;
    bool isWhiteListSaleStarted;
    bool isWhiteListCompleted;
    AggregatorV3Interface internal dataFeed;
    IERC20 snora;

    mapping(address => uint256) public totalWhiteListInvestorToken;
    mapping(address => uint256) public totalUserToken;

    event WhitelistSaleStart(uint256 tokenAmoun, uint256 timeDuration);
    event PreSaleStart(uint256 tokenAmount, uint256 timeDuration);
    event PaymentReceiverSet(address owner, address _receiver);
    event Buy(
        address tokenAddress,
        address user,
        uint256 amountPaid,
        uint256 amountReceived,
        uint256 price,
        uint256 time
    );

    constructor(IERC20 snoraTokenAddress) Ownable() {
        dataFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        snora = IERC20(snoraTokenAddress);
    }

    function startStopWhitelistSale(bool action)
        public
        onlyOwner
        returns (bool)
    {
        require(
            paymentReceiver != address(0),
            "Market : Payment receiver not set"
        );
        require(!isWhiteListCompleted, "Market : WhiteList sale ended");
        if (action) {
            require(!isWhiteListStart, "Market : Already started");
            isWhiteListStart = action;
            isWhiteListSaleStarted = true;
            return true;
        }
        require(isWhiteListStart, "Market : Already closed");
        isWhiteListStart = action;
        isWhiteListCompleted = true;
        return true;
    }

    function changeWhiteListPrice(uint256 price)
        public
        onlyOwner
        returns (bool)
    {
        require(price > 0, "Market : Invalid price");
        firstWhiteListTokenPrice = price;
        return true;
    }

    function startPreSale() public onlyOwner returns (bool) {
        require(isWhiteListSaleStarted, "Market : WhiteList sale not started");
        require(!isWhiteListStart, "Market : WhiteList sale is running");
        require(!isPresaleStart, "Market : Already started");
        isPresaleStart = true;
        return true;
    }

    function changepreSaleprice(uint256 price) public onlyOwner returns (bool) {
        require(price > 0, "Market : Invalid price");
        presaleTokenPrice = price;
        return true;
    }

    function stopPresale() public onlyOwner returns (bool) {
        require(isPresaleStart, "Market : Presale not started");
        isPresaleStart = false;
        return true;
    }

    function buyToken(
        address tokenAddress,
        bytes32[] calldata merkleProof,
        uint256 quantity,
        bool isMatic
    ) public payable nonReentrant returns (bool) {
        require(
            isMatic == true || isMatic == false,
            "Market : Invalid isMatic"
        );
        uint256 totalDollarAmount;
        uint256 totalReceivedToken;
        uint256 tokenRemaining;

        if (isWhiteListStart) {
            require(merkleProof.length > 0, "Market : Invalid params");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(merkleProof, merkleRoot, leaf),
                "Market : You are not a whitelist user"
            );
            if (isMatic) {
                require(
                    tokenAddress == address(0) && quantity == 0,
                    "Market : Invalid params passed"
                );
                uint256 maticPrice = getMaticToUsd();
                require(
                    msg.value * maticPrice >= minDollarAmountForMatic,
                    "Market : Buy atleast of $1 amount"
                );
                require(
                    maxTokenLimitOfPresale >= tokenSoldInPresale + quantity,
                    "Market : All token sold"
                );
                totalDollarAmount = msg.value * maticPrice;
                totalReceivedToken =
                    totalDollarAmount /
                    firstWhiteListTokenPrice;

                tokenRemaining =
                    maxTokenForWhiteListUser -
                    totalWhiteListInvestorToken[msg.sender];
                require(
                    totalReceivedToken <= tokenRemaining,
                    "Market : Limit exceeds"
                );
                buyTokenThroughMatic(totalReceivedToken);
                totalWhiteListInvestorToken[msg.sender] += totalReceivedToken;
                totalUserToken[msg.sender] += totalReceivedToken;
                tokenSoldInPresale += totalReceivedToken;
                emit Buy(
                    tokenAddress,
                    msg.sender,
                    msg.value,
                    totalReceivedToken,
                    firstWhiteListTokenPrice,
                    block.timestamp
                );
                return true;
            } else {
                require(
                    tokenAddress != address(0) &&
                        tokenAddress.code.length > 0 &&
                        quantity > 0,
                    "Market : Invalid params passed"
                );
                require(
                    maxTokenLimitOfPresale >= tokenSoldInPresale + quantity,
                    "Market : All token sold"
                );
                totalDollarAmount = quantity * usdt_usdc_value;
                require(
                    totalDollarAmount >= minDollarAmountForUsdtUsdc,
                    "Market : Buy atleast of $1 amount"
                );
                totalReceivedToken =
                    (totalDollarAmount / firstWhiteListTokenPrice) *
                    1e12;
                tokenRemaining =
                    maxTokenForWhiteListUser -
                    totalWhiteListInvestorToken[msg.sender];
                require(
                    totalReceivedToken <= tokenRemaining,
                    "Market : Limit exceeds"
                );
                transferToken(tokenAddress, quantity, totalReceivedToken);
                totalWhiteListInvestorToken[msg.sender] += totalReceivedToken;
                totalUserToken[msg.sender] += totalReceivedToken;
                tokenSoldInPresale += totalReceivedToken;
                emit Buy(
                    tokenAddress,
                    msg.sender,
                    quantity,
                    totalReceivedToken,
                    firstWhiteListTokenPrice,
                    block.timestamp
                );
                return true;
            }
        } else if (isPresaleStart) {
            if (isMatic) {
                require(
                    tokenAddress == address(0) && quantity == 0,
                    "Market : Invalid params passed"
                );
                uint256 maticPrice = getMaticToUsd();
                require(
                    msg.value * maticPrice >= minDollarAmountForMatic,
                    "Market : Buy atleast of $1 amount"
                );
                require(
                    maxTokenLimitOfPresale >= tokenSoldInPresale + quantity,
                    "Market : All token sold"
                );

                totalDollarAmount = msg.value * maticPrice;
                totalReceivedToken = totalDollarAmount / presaleTokenPrice;

                buyTokenThroughMatic(totalReceivedToken);

                totalUserToken[msg.sender] += totalReceivedToken;
                tokenSoldInPresale += totalReceivedToken;
                emit Buy(
                    tokenAddress,
                    msg.sender,
                    msg.value,
                    totalReceivedToken,
                    presaleTokenPrice,
                    block.timestamp
                );
                return true;
            } else {
                require(
                    tokenAddress != address(0) &&
                        tokenAddress.code.length > 0 &&
                        quantity > 0,
                    "Market : Invalid params passed"
                );
                totalDollarAmount = quantity * usdt_usdc_value;
                require(
                    totalDollarAmount >= minDollarAmountForUsdtUsdc,
                    "Market : Buy atleast of $1 amount"
                );
                totalReceivedToken =
                    (totalDollarAmount / presaleTokenPrice) *
                    1e12;

                require(
                    maxTokenLimitOfPresale >=
                        tokenSoldInPresale + totalReceivedToken,
                    "Market : All token sold"
                );

                transferToken(tokenAddress, quantity, totalReceivedToken);

                totalUserToken[msg.sender] += totalReceivedToken;
                tokenSoldInPresale += totalReceivedToken;
                emit Buy(
                    tokenAddress,
                    msg.sender,
                    quantity,
                    totalReceivedToken,
                    presaleTokenPrice,
                    block.timestamp
                );
                return true;
            }
        } else {
            revert("No active sale");
        }
    }

    function buyTokenThroughMatic(uint256 totalReceivedToken)
        internal
        returns (bool)
    {
        require(
            snora.transferFrom(owner(), msg.sender, totalReceivedToken),
            "Market : ERC20 transfer"
        );
        payable(paymentReceiver).transfer(msg.value);
        totalUserToken[msg.sender] += totalReceivedToken;
        return true;
    }

    function setPaymentReceiver(address _receiver)
        public
        onlyOwner
        returns (bool)
    {
        require(_receiver != address(0), "Market : Null address");
        paymentReceiver = _receiver;
        emit PaymentReceiverSet(owner(), _receiver);
        return true;
    }

    function withdrawToken(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Market : unsufficient amount");
        require(
            snora.balanceOf(address(this)) >= amount,
            "Market : Unsufficient balance"
        );
        require(snora.transfer(owner(), amount));
        return true;
    }

    function transferToken(
        address tokenAddress,
        uint256 payableAmount,
        uint256 receivedAmount
    ) internal {
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                paymentReceiver,
                payableAmount //1e12
            ) && snora.transferFrom(owner(), msg.sender, receivedAmount),
            "Market : ERC20 Error"
        );
    }

    function transferToken(address receiver, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(isPresaleStart, "Market : Presale is not started");
        require(
            maxTokenLimitOfPresale >= tokenSoldInPresale + amount,
            "Market : All token sold"
        );
        require(
            snora.transferFrom(owner(), receiver, amount),
            "Market : ERC20"
        );
        tokenSoldInPresale += amount;
        return true;
    }

    function getPresaleTokenRemaining() public view returns (uint256) {
        return maxTokenLimitOfPresale - tokenSoldInPresale;
    }

    function getSaleAndPrice()
        public
        view
        returns (
            bool whiteList,
            uint256 WhiteListprice,
            bool preSale,
            uint256 preSalePrice
        )
    {
        return (
            isWhiteListStart,
            firstWhiteListTokenPrice,
            isPresaleStart,
            presaleTokenPrice
        );
    }

    function getCurrentPaymentReceiver() public view returns (address) {
        return paymentReceiver;
    }

    function getMaticToUsd() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return uint256(answer / 10**6);
    }
}