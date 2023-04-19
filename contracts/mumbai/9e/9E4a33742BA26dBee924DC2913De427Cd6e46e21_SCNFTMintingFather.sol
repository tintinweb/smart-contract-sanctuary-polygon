// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/*
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.13;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.13;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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

pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";

interface INft {
    function mint(address to, uint256 qty) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMinting is Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    // treasuryAddr
    address public treasuryAddr;
    // NFT SC collection
    INft public immutable nft;
    // Price Feed
    AggregatorV3Interface public priceFeed;
    // Info of each phase.
    struct PhaseInfo {
        uint256 priceInUSDPerNFT;
        uint256 priceInUSDPerNFTWithoutWhiteList;
        uint256 maxTotalSales;
        uint256 maxSalesPerWallet;
        bool whiteListRequired;
        bool phasePriceInUSD;
        uint256 priceInWeiPerNFT;
        uint256 priceInWeiPerNFTWithoutWhiteList;
        uint256 timeStampStart;
        uint256 timeStampEnd;
    }
    // Phases Info
    PhaseInfo[] public phasesInfo;
    // Total Sales
    uint256 public totalSales = 0;
    // Max Total Sales
    uint256 public totalMaxSales;
    // Phases Total Sales
    mapping(uint256 => uint256) public phasesTotalSales;
    // Phases Wallet Sales
    mapping(uint256 => mapping(address => uint256)) public phasesWalletSales;
    // AllowList
    mapping(uint256 => bytes32) public allowlistMerkleRoot;
    // AllowedToBuyWithCreditCard
    mapping(address => bool) public allowedToBuyWithCreditCard;

    event AddPhase(uint256 indexed _priceInUSDPerNFT, uint256 indexed _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList, uint256 _timeStampStart, uint256 _timeStampEnd);
    event EditPhase(uint8 indexed _phaseId, uint256 indexed _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList, uint256 _timeStampStart, uint256 _timeStampEnd);
    event ChangeCurrentPhase(uint8 indexed _phaseId);
    event ChangePriceFeedAddress(address indexed _priceFeedAddress);
    event Buy(uint256 indexed quantity, address indexed to);
    event BuyWithCreditCard(uint256 indexed quantity, address indexed to);
    event SetAllowlistMerkleRoot(uint8 _phase, bytes32 indexed _allowlistMerkleRoot);
    event SetTreasury(address indexed _treasuryAddr);
    event WithdrawMoney();
    event SetAddressToBuyWithCreditCardAllowed(address indexed _account, bool indexed _canBuy);

    modifier onlyAllowListed(uint8 _phase, bytes32[] calldata _merkleProof, address _to) {
        PhaseInfo storage phase = phasesInfo[_phase];

        if (phase.whiteListRequired) {
            require(_to == msg.sender, "In this phase it is mandatory that you can only mint to your own wallet");
            bool passMerkle = checkMerkleProof(_phase, _merkleProof, _to);
            require(passMerkle, "Not allowListed");
        }
        _;
    }

    modifier onlyBuyWithCreditCardAllowedUsers() {
        require(allowedToBuyWithCreditCard[msg.sender], "You can't buy with credit card ;)");
        _;
    }

    constructor(
        INft _nft,
        address _priceFeedAddress
    ) {
        require(address(_nft) != address(0));
        require(_priceFeedAddress != address(0));

        nft = _nft;
        treasuryAddr = address(this);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function phasesInfoLength() public view returns (uint256) {
        return phasesInfo.length;
    }

    function isPhaseActive(uint8 _phaseId) public view returns (bool) {
        return (
            block.timestamp >= phasesInfo[_phaseId].timeStampStart
            &&
            block.timestamp <= phasesInfo[_phaseId].timeStampEnd
        );
    }

    function checkMerkleProof(uint8 _phase, bytes32[] calldata _merkleProof, address _to) public view virtual returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        return MerkleProof.verify(_merkleProof, allowlistMerkleRoot[_phase], leaf);
    }

    function changePriceFeedAddress(address _priceFeedAddress) external onlyOwner {
        require(_priceFeedAddress != address(0));
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        emit ChangePriceFeedAddress(_priceFeedAddress);
    }

    function setTotalMaxSales(uint256 _totalMaxSales) external onlyOwner {
        totalMaxSales = _totalMaxSales;
    }

    function addPhase(uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList, uint256 _timeStampStart, uint256 _timeStampEnd) external onlyOwner {
        phasesInfo.push(PhaseInfo({
            priceInUSDPerNFT: _priceInUSDPerNFT,
            priceInUSDPerNFTWithoutWhiteList: _priceInUSDPerNFTWithoutWhiteList,
            maxTotalSales: _maxTotalSales,
            maxSalesPerWallet: _maxSalesPerWallet,
            whiteListRequired: _whiteListRequired,
            phasePriceInUSD: _phasePriceInUSD,
            priceInWeiPerNFT: _priceInWeiPerNFT,
            priceInWeiPerNFTWithoutWhiteList: _priceInWeiPerNFTWithoutWhiteList,
            timeStampStart: _timeStampStart,
            timeStampEnd: _timeStampEnd
        }));

        emit AddPhase(_priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList, _timeStampStart, _timeStampEnd);
    }

    function editPhase(uint8 _phaseId, uint256 _priceInUSDPerNFT, uint256 _priceInUSDPerNFTWithoutWhiteList, uint256 _maxTotalSales, uint256 _maxSalesPerWallet, bool _whiteListRequired, bool _phasePriceInUSD, uint256 _priceInWeiPerNFT, uint256 _priceInWeiPerNFTWithoutWhiteList, uint256 _timeStampStart, uint256 _timeStampEnd) external onlyOwner {
        require(_phaseId < phasesInfoLength(), "you cannot edit a phase that does not exist");
        require(phasesInfo[_phaseId].priceInUSDPerNFT >= _priceInUSDPerNFT, "NFT:priceInUSDPerNFT: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInUSDPerNFTWithoutWhiteList >= _priceInUSDPerNFTWithoutWhiteList, "NFT:priceInUSDPerNFTWithoutWhiteList: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInWeiPerNFT >= _priceInWeiPerNFT, "NFT:priceInWeiPerNFT: the price must be equal to or below the previous price");
        require(phasesInfo[_phaseId].priceInWeiPerNFTWithoutWhiteList >= _priceInWeiPerNFTWithoutWhiteList, "NFT:priceInWeiPerNFTWithoutWhiteList: the price must be equal to or below the previous price");

        phasesInfo[_phaseId].priceInUSDPerNFT = _priceInUSDPerNFT;
        phasesInfo[_phaseId].priceInUSDPerNFTWithoutWhiteList = _priceInUSDPerNFTWithoutWhiteList;
        phasesInfo[_phaseId].maxTotalSales = _maxTotalSales;
        phasesInfo[_phaseId].maxSalesPerWallet = _maxSalesPerWallet;
        phasesInfo[_phaseId].whiteListRequired = _whiteListRequired;
        phasesInfo[_phaseId].phasePriceInUSD = _phasePriceInUSD;
        phasesInfo[_phaseId].priceInWeiPerNFT = _priceInWeiPerNFT;
        phasesInfo[_phaseId].priceInWeiPerNFTWithoutWhiteList = _priceInWeiPerNFTWithoutWhiteList;
        phasesInfo[_phaseId].timeStampStart = _timeStampStart;
        phasesInfo[_phaseId].timeStampEnd = _timeStampEnd;

        emit EditPhase(_phaseId, _priceInUSDPerNFT, _priceInUSDPerNFTWithoutWhiteList, _maxTotalSales, _maxSalesPerWallet, _whiteListRequired, _phasePriceInUSD, _priceInWeiPerNFT, _priceInWeiPerNFTWithoutWhiteList, _timeStampStart, _timeStampEnd);
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,

        ) = priceFeed.latestRoundData();

        return (
            price
        );
    }

    function setAllowlistMerkleRoot(uint8 _phase, bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot[_phase] = _allowlistMerkleRoot;
        emit SetAllowlistMerkleRoot(_phase, _allowlistMerkleRoot);
    }

    function setAddressToBuyWithCreditCardAllowed(address _account, bool _canBuy) external onlyOwner {
        allowedToBuyWithCreditCard[_account] = _canBuy;
        emit SetAddressToBuyWithCreditCardAllowed(_account, _canBuy);
    }

    function setTreasury(address _treasuryAddr) external onlyOwner {
        treasuryAddr = _treasuryAddr;
        emit SetTreasury(_treasuryAddr);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        emit WithdrawMoney();
    }

    function transferGuardedNfts(uint256[] memory tokensId, address[] memory addresses) external onlyOwner
    {
        require(
            addresses.length == tokensId.length,
            "addresses does not match tokensId length"
        );

        for (uint256 i = 0; i < addresses.length; ++i) {
            nft.transferFrom(address(this), addresses[i], tokensId[i]);
        }
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverERC721TransferFrom(address nftAddress, address to, uint256 tokenId) external virtual onlyOwner {
        IERC721(nftAddress).transferFrom(address(this), to, tokenId);
    }

    function buyWithCreditCard(uint8 _phase, uint256 _quantity, address _to) external onlyBuyWithCreditCardAllowedUsers nonReentrant whenNotPaused {
        require(isPhaseActive(_phase), "this phase is not active");

        PhaseInfo storage phase = phasesInfo[_phase];

        require(totalMaxSales <= totalSales + _quantity, "is not possible buy more NFTs");
        require(phase.maxTotalSales >= phasesTotalSales[_phase] + _quantity, "this phase does not allow this purchase");

        phasesTotalSales[_phase] = phasesTotalSales[_phase] + _quantity;

        nft.mint(_to, _quantity);
        totalMaxSales = totalMaxSales + _quantity;

        emit BuyWithCreditCard(_quantity, _to);
    }

    function buy(uint8 _phase, uint256 _quantity, address _to, bytes32[] calldata _merkleProof) external payable nonReentrant onlyAllowListed(_phase, _merkleProof, _to) whenNotPaused {
        uint256 totalPrice;
        uint256 priceInUSD;
        uint256 priceInWei;

        require(isPhaseActive(_phase), "this phase is not active");
        require(totalMaxSales <= totalSales + _quantity, "is not possible buy more NFTs");
        require(phasesInfo[_phase].maxTotalSales >= phasesTotalSales[_phase] + _quantity, "this phase does not allow this purchase");
        require(phasesInfo[_phase].maxSalesPerWallet >= phasesWalletSales[_phase][_to] + _quantity, "you can not buy as many NFTs in this phase");

        if (checkMerkleProof(_phase, _merkleProof, _to)) {
            priceInUSD = phasesInfo[_phase].priceInUSDPerNFT;
            priceInWei = phasesInfo[_phase].priceInWeiPerNFT;
        } else {
            priceInUSD = phasesInfo[_phase].priceInUSDPerNFTWithoutWhiteList;
            priceInWei = phasesInfo[_phase].priceInWeiPerNFTWithoutWhiteList;
        }

        if (phasesInfo[_phase].phasePriceInUSD) {
            uint256 totalPriceInUSD = priceInUSD * _quantity * 1e8 * 1e18;

            (
            int ethPrice
            ) = getLatestPrice();

            uint256 ethPrice256 = uint256(ethPrice);
            totalPrice = (totalPriceInUSD * 1e24) / (ethPrice256 * 1e24);
        } else {
            totalPrice = priceInWei * _quantity;
        }

        phasesTotalSales[_phase] = phasesTotalSales[_phase] + _quantity;
        phasesWalletSales[_phase][_to] = phasesWalletSales[_phase][_to] + _quantity;

        refundIfOver(totalPrice);
        (bool success, ) = treasuryAddr.call{value: address(this).balance}("");
        require(success);
        nft.mint(_to, _quantity);
        totalMaxSales = totalMaxSales + _quantity;

        emit Buy(_quantity, _to);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            require(success);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.13;

import "./Context.sol";

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

pragma solidity ^0.8.13;

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./NFTMinting.sol";

contract SCNFTMintingFather is Ownable {
    mapping(address => bool) public allowedToCreate;
    address[] public addressSettedAllowed;

    struct SmartContractsCreateds {
        address smartContractAddress;
        address adminCreator;
        string projectName;
    }

    SmartContractsCreateds[] public smartContracts;

    event SetAddressToCreate(address indexed _account, bool indexed _canCreate);
    event ContractNFTMintingCreated(address creator, address nftMintingAddress);

    modifier onlyAllowedToCreate() {
        require(allowedToCreate[msg.sender], "You can't create ;)");
        _;
    }

    constructor(

    ) {
        setAddressToCreate(_msgSender(), true);
    }

    function setAddressToCreate(address _account, bool _canCreate) public onlyOwner {
        allowedToCreate[_account] = _canCreate;
        addressSettedAllowed.push(_account);
        emit SetAddressToCreate(_account, _canCreate);
    }

    function createNFTMintingSC(
        INft _nft,
        address _priceFeedAddress,
        string memory projectName
    )
    external onlyAllowedToCreate
    returns (address)
    {
        NFTMinting nftMinting = new NFTMinting(
            _nft,
            _priceFeedAddress
        );

        nftMinting.transferOwnership(_msgSender());
        emit ContractNFTMintingCreated(_msgSender(), address(nftMinting));

        smartContracts.push(SmartContractsCreateds({
            smartContractAddress: address(nftMinting),
            adminCreator: _msgSender(),
            projectName: projectName
        }));

        return address(nftMinting);
    }

    function smartContractsLength() external view returns (uint256) {
        return smartContracts.length;
    }

    function addressSettedAllowedLength() external view returns (uint256) {
        return addressSettedAllowed.length;
    }
}