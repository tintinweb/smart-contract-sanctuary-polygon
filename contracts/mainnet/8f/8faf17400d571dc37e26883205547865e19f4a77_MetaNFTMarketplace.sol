// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// NFTMarketplace 合约继承了 Ownable 和 ReentrancyGuard
contract MetaNFTMarketplace is Ownable, ReentrancyGuard {
    // 定义一个拍卖结构体，包含所有拍卖的详细信息
    struct Auction {
        uint256 id;  // 拍卖ID
        address tokenAddress;  // ERC721合约地址
        address payable seller;  // 卖家地址
        uint256 tokenId;  // ERC721代币ID
        uint256 startPrice;  // 起拍价格
        uint256 endBlock;  // 结束拍卖的区块号
        uint256 bidExtensionBlock;  // 拍卖延长的区块数
        uint256 feePercentage;  // 手续费百分比
        bool active;  // 拍卖是否进行中
        address highestBidder;  // 当前最高出价者
        uint256 highestBid;  // 当前最高出价
    }

    // 定义一个公共的拍卖数组，用于存储所有的拍卖
    Auction[] public auctions;

    // 用于生成下一个拍卖的ID
    uint256 private _nextAuctionId = 0;

    // 定义一系列事件，当拍卖的状态发生改变时会被触发
    event AuctionCreated(uint256 id, address tokenAddress, address seller, uint256 tokenId, uint256 startPrice, uint256 endBlock, uint256 bidExtensionBlock, uint256 feePercentage);
    event NewBid(uint256 id, address bidder, uint256 bid);
    event AuctionEnded(uint256 id, address winner, uint256 winningBid);
    event AuctionCancelled(uint256 id);

    // 批量创建拍卖
    function createAuctions(
        address tokenAddress,  // ERC721合约地址
        uint256[] calldata tokenIds,  // 要拍卖的NFT的tokenIds数组
        uint256 startPrice,
        uint256 endBlock,
        uint256 bidExtensionBlock,
        uint256 feePercentage
    ) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            createAuction(tokenAddress, tokenIds[i], startPrice, endBlock, bidExtensionBlock, feePercentage);
        }
    }

    // 创建一个新的拍卖
    function createAuction(
        address tokenAddress,  // ERC721 合约地址
        uint256 tokenId,  // 要拍卖的 NFT 的 tokenId
        uint256 startPrice,  // 拍卖的起始价格
        uint256 endBlock,  // 拍卖的结束区块号
        uint256 bidExtensionBlock,  // 延长拍卖的区块数量
        uint256 feePercentage  // 手续费的百分比
    ) public {
        // 验证调用者是否拥有这个 NFT
        require(IERC721(tokenAddress).ownerOf(tokenId) == msg.sender, "Not the owner");
        // 批准本合约管理此 NFT
        IERC721(tokenAddress).approve(address(this), tokenId);
        // 创建新的拍卖并添加到拍卖数组中
        auctions.push(Auction({
            id: _nextAuctionId,
            tokenAddress: tokenAddress,
            seller: payable(msg.sender),
            tokenId: tokenId,
            startPrice: startPrice,
            endBlock: endBlock,
            bidExtensionBlock: bidExtensionBlock,
            feePercentage: feePercentage,
            active: true,
            highestBidder: address(0),
            highestBid: 0
        }));

        emit AuctionCreated(_nextAuctionId, tokenAddress, msg.sender, tokenId, startPrice, endBlock, bidExtensionBlock, feePercentage);

        _nextAuctionId++;
    }

    // 出价
    function placeBid(uint256 id) external payable nonReentrant {
        Auction storage auction = auctions[id];
        require(auction.active, "Auction not active");
        require(block.number <= auction.endBlock, "Auction ended");
        require(msg.value >= auction.startPrice, "Bid lower than start price");
        require(msg.value > auction.highestBid, "Bid lower than highest bid");

        // 退回之前的最高出价
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        // 如果在拍卖快结束时出现新的出价，自动延长拍卖时间
        if (block.number >= auction.endBlock - auction.bidExtensionBlock) {
            auction.endBlock += auction.bidExtensionBlock;
        }

        emit NewBid(id, msg.sender, msg.value);
    }

    // 结束拍卖，只有合约的拥有者或者管理员才能结束拍卖
    function endAuction(uint256 id) external nonReentrant onlyOwner {
        Auction storage auction = auctions[id];
        require(block.number > auction.endBlock, "Auction not yet ended");
        require(auction.active, "Auction not active");

        if (auction.highestBid >= auction.startPrice) {
            uint256 fee = (auction.highestBid * auction.feePercentage) / 100;
            uint256 sellerProceeds = auction.highestBid - fee;

            auction.seller.transfer(sellerProceeds);
            IERC721(auction.tokenAddress).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            emit AuctionEnded(id, auction.highestBidder, auction.highestBid);
        } else {
            IERC721(auction.tokenAddress).safeTransferFrom(auction.seller, auction.seller, auction.tokenId);
            emit AuctionEnded(id, address(0), 0);
        }

        auction.active = false;
    }

    // 取消拍卖，只有合约的拥有者或者管理员才能取消拍卖
    function cancelAuction(uint256 id) external nonReentrant onlyOwner {
        Auction storage auction = auctions[id];
        require(auction.active, "Auction not active");

        // 退回所有出价
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // 退回 NFT 给卖家
        IERC721(auction.tokenAddress).safeTransferFrom(auction.seller, auction.seller, auction.tokenId);

        auction.active = false;

        emit AuctionCancelled(id);
    }

    // 合约拥有者可以调用此函数取走合约中的手续费
    function withdrawFees() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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