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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

library ReleaseQueueLib {
    uint256 constant MAX_INT = 2 ** 256 - 1;

    struct ReleaseQueueItem {
        uint256 tokenId;
        address contractAddress;
        address tokenOwner;
        uint256 releaseTimestamp;
    }

    struct ReleaseQueue {
        mapping(uint256 => ReleaseQueueItem) q;
        uint256 front;
        uint256 back;
    }

    // Assuming qItem.releaseTimestamp > rQueue.q[rQueue.back].releaseTimestamp
    function push(
        ReleaseQueue storage rQueue,
        ReleaseQueueItem memory qItem
    ) internal {
        if (isFull(rQueue)) {
            revert("Queue is full");
        }

        rQueue.q[rQueue.back] = qItem;

        if (rQueue.back == MAX_INT) {
            rQueue.back = 0;
        } else {
            rQueue.back++;
        }
    }

    // Assuming block.timestamp >= rQueue.q[rQueue.front].releaseTimestamp
    function pop(
        ReleaseQueue storage rQueue
    ) internal returns (ReleaseQueueItem memory qItem) {
        if (isEmpty(rQueue)) {
            revert("Queue is empty");
        }

        qItem = rQueue.q[rQueue.front];
        delete rQueue.q[rQueue.front];

        if (rQueue.front == MAX_INT) {
            rQueue.front = 0;
        } else {
            rQueue.front++;
        }
    }

    function isReadyForRelease(
        ReleaseQueue storage rQueue
    ) internal view returns (bool) {
        return
            !isEmpty(rQueue) &&
            block.timestamp >= rQueue.q[rQueue.front].releaseTimestamp;
    }

    function isEmpty(ReleaseQueue storage rQueue) internal view returns (bool) {
        return rQueue.back == rQueue.front;
    }

    function isFull(ReleaseQueue storage rQueue) internal view returns (bool) {
        return
            (rQueue.back == MAX_INT && rQueue.front == 0) ||
            (rQueue.front != 0 && rQueue.back == rQueue.front - 1);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

import "./ReleaseQueueLib.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, IERC721Receiver, ReentrancyGuard {
    using ReleaseQueueLib for ReleaseQueueLib.ReleaseQueue;
    // Interface for the ERC721 contract
    mapping(address => IERC721) nftContracts;

    // Structure to store staked NFT information
    struct StakedNFT {
        uint256 tokenId;
        address contractAddress;
        uint256 stakedAt;
        address owner;
    }

    struct StakeArgs {
        uint256 tokenId;
        address contractAddress;
    }

    // Mapping to store staked NFTs using token ID as the key
    mapping(bytes32 => StakedNFT) stakedNfts;

    // Maximum number of tokens that can be staked in a single transaction
    uint8 public MAX_STAKE_PER_TXN = 10;
    uint8 public MAX_RELEASE_PER_TXN = 50;
    uint256 public COOLING_OFF_PERIOD = 1209600; // 14 Days in seconds

    ReleaseQueueLib.ReleaseQueue[] releaseQueue;

    // Event emitted when an NFT is staked
    event NFTStaked(
        uint256 tokenId,
        address contractAddress,
        uint256 stakedAt,
        address owner
    );

    // Event emitted when an NFT is unstaked
    event NFTUnstaked(
        uint256 tokenId,
        address contractAddress,
        uint256 unstakedAt,
        address owner
    );

    // Event emitted when an NFT is released to owner
    event NFTReleased(
        uint256 tokenId,
        address contractAddress,
        uint256 releasedAt,
        address owner
    );

    // Event emitted when cooling-off period is changes
    event CoolingOffPeriodChanged(uint256 cop);
    event MaxReleasePerTransactionChanged(uint8 maxRelease);
    event MaxStakePerTransactionChanged(uint8 maxStake);

    error NFTAlreadyStaked();
    error NotTokenOwner();
    error ToManyNFTsToStake();
    error ToManyNFTsToUnstake();
    error ContractNotRegistered();

    // Constructor function that sets the address of the NFT contract
    constructor() {
        releaseQueue.push();
    }

    // Sets the address of the NFT contract
    function addNFTContract(address _nftContractAddress) external onlyOwner {
        nftContracts[_nftContractAddress] = IERC721(_nftContractAddress);
    }

    /*
     * @dev Stakes multiple NFTs to the contract.
     * @param tokenIds An array of token IDs to be staked.
     * Requirements:
     * - The maximum stake limit per transaction is enforced.
     * - Each NFT must not be already staked.
     * - The caller must be the owner of the NFT.
     * - NFTs are transferred from the caller to this contract.
     * - Staking information is stored in the `stakedNfts` mapping.
     * Emits a {NFTStaked} event for each staked NFT.
     */
    function stake(StakeArgs[] calldata args) external nonReentrant {
        uint256 len = args.length;

        if (len > MAX_STAKE_PER_TXN) {
            revert ToManyNFTsToStake();
        }

        for (uint256 i = 0; i < len; i++) {
            bytes32 nftMapId = getNFTMapId(
                args[i].tokenId,
                args[i].contractAddress
            );

            if (address(nftContracts[args[i].contractAddress]) == address(0)) {
                revert ContractNotRegistered();
            }

            if (stakedNfts[nftMapId].owner != address(0)) {
                revert NFTAlreadyStaked();
            }

            if (
                nftContracts[args[i].contractAddress].ownerOf(
                    args[i].tokenId
                ) != _msgSender()
            ) {
                revert NotTokenOwner();
            }

            nftContracts[args[i].contractAddress].safeTransferFrom(
                _msgSender(),
                address(this),
                args[i].tokenId,
                "0x00"
            );

            StakedNFT memory stakedNft = StakedNFT(
                args[i].tokenId,
                args[i].contractAddress,
                block.timestamp,
                _msgSender()
            );
            stakedNfts[nftMapId] = stakedNft;

            emit NFTStaked(
                stakedNft.tokenId,
                stakedNft.contractAddress,
                stakedNft.stakedAt,
                stakedNft.owner
            );
        }
    }

    /*
     * @dev Unstakes multiple NFTs from the contract.
     * @param tokenIds An array of token IDs to be unstaked.
     * Requirements:
     * - The maximum unstake limit per transaction is enforced.
     * - Each NFT must be staked by the caller.
     * - NFTs are queued to be transffered to owner after cooling off period is over.
     * - Staking information is removed from the `stakedNfts` mapping.
     * Emits a {NFTUnstaked} event for each unstaked NFT.
     */
    function unstake(StakeArgs[] calldata args) external nonReentrant {
        uint256 len = args.length;

        if (len > MAX_STAKE_PER_TXN) {
            revert ToManyNFTsToUnstake();
        }

        for (uint256 i = 0; i < len; i++) {
            bytes32 nftMapId = getNFTMapId(
                args[i].tokenId,
                args[i].contractAddress
            );

            if (address(nftContracts[args[i].contractAddress]) == address(0)) {
                revert ContractNotRegistered();
            }

            if (stakedNfts[nftMapId].owner != _msgSender()) {
                revert NotTokenOwner();
            }

            ReleaseQueueLib.ReleaseQueueItem memory qItem = ReleaseQueueLib
                .ReleaseQueueItem(
                    args[i].tokenId,
                    args[i].contractAddress,
                    _msgSender(),
                    block.timestamp + COOLING_OFF_PERIOD
                );
            releaseQueue[releaseQueue.length - 1].push(qItem);
            delete stakedNfts[nftMapId];

            emit NFTUnstaked(
                args[i].tokenId,
                args[i].contractAddress,
                block.timestamp,
                _msgSender()
            );
        }
    }

    function releaseToOwner() external nonReentrant {
        uint8 totalReleased = 0;
        for (uint i = 0; i < releaseQueue.length; i++) {
            while (
                releaseQueue[i].isReadyForRelease() &&
                totalReleased <= MAX_RELEASE_PER_TXN
            ) {
                ReleaseQueueLib.ReleaseQueueItem memory qItem = releaseQueue[i]
                    .pop();

                nftContracts[qItem.contractAddress].safeTransferFrom(
                    address(this),
                    qItem.tokenOwner,
                    qItem.tokenId,
                    "0x00"
                );

                emit NFTReleased(
                    qItem.tokenId,
                    qItem.contractAddress,
                    block.timestamp,
                    qItem.tokenOwner
                );
                totalReleased++;
            }
        }
    }

    function setCoolingOffPeriod(uint256 copInSeconds) external onlyOwner {
        COOLING_OFF_PERIOD = copInSeconds;
        releaseQueue.push();
        emit CoolingOffPeriodChanged(copInSeconds);
    }

    function setMaxStakePerTransaction(uint8 maxStakeLimit) external onlyOwner {
        MAX_STAKE_PER_TXN = maxStakeLimit;
        emit MaxStakePerTransactionChanged(maxStakeLimit);
    }

    function setMaxReleasePerTransaction(
        uint8 maxReleasePerTxn
    ) external onlyOwner {
        MAX_RELEASE_PER_TXN = maxReleasePerTxn;
        emit MaxReleasePerTransactionChanged(maxReleasePerTxn);
    }

    function isReadyForRelease() public view returns (bool) {
        for (uint i = 0; i < releaseQueue.length; i++) {
            if (releaseQueue[i].isReadyForRelease()) {
                return true;
            }
        }
        return false;
    }

    // Function required by the ERC721Receiver interface
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getNFTMapId(
        uint256 tokenId,
        address contractAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress, tokenId));
    }
}