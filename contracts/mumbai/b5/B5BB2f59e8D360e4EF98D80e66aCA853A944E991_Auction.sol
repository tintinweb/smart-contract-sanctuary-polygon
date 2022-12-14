// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Auction is Ownable, ReentrancyGuard {
    IERC721 public nftCollection;

    uint256[] percentages;

    enum Status{Active, Inactive}

    struct AuctionDetails {
        uint256 startingPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 minBidPercentage;
        address highestBidder;
        uint256 highestBidderPrice;
        Bidder[] bidders;
        uint256 maxExtensionPeriod; // 1 week in epoch = 604,800
        Status status;
    }

    struct Bidder {
        address bidder;
        uint256 placedAt;
        uint256 amountOffered;
        bool isCancelled;
    }
    struct Winner {
        address winerBid;
        uint256 highAmountBid;
    }

    mapping(uint256 => AuctionDetails) auctions; // token id => auction
    event AuctionStarted(uint256 tokenId, uint256 price, uint256 startTime, uint256 endTime, uint256 percentage);
    event BidPlaced(uint256 tokenId, address seller, address buyer, uint256 amount);
    event AuctionEnded(uint256 tokenId, address seller, address highestBidder, uint256 amount);
    event BidCancelled(uint256 tokenId, address seller, address buyer);
    // event CalculationDetails(uint256 previousBid, uint256 _amountOffered, uint256 diff, uint256 mult, uint256 result);

    modifier isTokenOwner(uint256 _tokenId) {
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "You don't have the authority to cancel the sale of this token!");
        _;
    }

    modifier isMinBid(uint256 _tokenId, uint256 _amountOffered) {
        uint256 minBid = currentMinBid(_tokenId, _amountOffered);
        
        require(minBid >= auctions[_tokenId].minBidPercentage, "Your offer is less than the minimum bid.");
        _;
    }

    function currentMinBid(uint256 _tokenId, uint256 _amountOffered) public view returns (uint256) {
        uint256 totalCount = auctions[_tokenId].bidders.length;

        // formula: percentage increase = (increase / original number) x 100
        if(totalCount > 0) {
            uint256 previousBid = auctions[_tokenId].bidders[totalCount - 1].amountOffered;

            require(_amountOffered > previousBid, "Your offer should be more than the previous offer.");

            uint256 diff = _amountOffered - previousBid;
            uint256 mult = diff * 10000;
            uint256 result = mult / previousBid;

            // emit CalculationDetails(previousBid, _amountOffered, diff, mult, result);

            return result;
        } else {
            require(_amountOffered > auctions[_tokenId].startingPrice, "Your offer should be more than the previous offer.");
            uint256 diff = _amountOffered - auctions[_tokenId].startingPrice;
            uint256 mult = diff * 10000;
            uint256 result = mult / auctions[_tokenId].startingPrice;

            // emit CalculationDetails(auctions[_tokenId].startingPrice, _amountOffered, mult, diff, result);

            return result;
        }
    }

    /**
        @dev initializes the token contract
    */
    function initialize(address _nftAddress, uint256[] memory _percentages) public onlyOwner {
        nftCollection = IERC721(_nftAddress);
        percentages = _percentages;
    }

    /**
        @dev allows seller to start receiving offers on their token
    */
    function startAuction(uint256 _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime, uint256 _percentageIndex) external isTokenOwner(_tokenId) {
        require(_percentageIndex >= 0 && _percentageIndex < percentages.length, "Please choose percentages within the range offered");
        require(auctions[_tokenId].status == Status.Active, "The auction is inactive."); 
        
        auctions[_tokenId].startingPrice = _price;
        auctions[_tokenId].startTime = _startTime;
        auctions[_tokenId].endTime = _endTime;
        auctions[_tokenId].minBidPercentage = percentages[_percentageIndex];
        auctions[_tokenId].maxExtensionPeriod = 604800;
        emit AuctionStarted(_tokenId, _price, _startTime, _endTime, auctions[_tokenId].minBidPercentage);
    }

    /**
        @dev allows buyer to place a bid on a token
        @notice this requires the approval of token spending
    */
    function placeBid(uint256 _tokenId) payable external isMinBid(_tokenId, msg.value) {
        require(auctions[_tokenId].status == Status.Active, "The auction is inactive.");
        require(block.timestamp <= auctions[_tokenId].endTime, "The auction is over.");
        require(msg.value > auctions[_tokenId].highestBidderPrice, "value must be greater than the highest bidder.");
        // reject payments of 0 Eth/Polygon
        require(msg.value != 0, "payment rejected.");
        uint256 timeLeft = auctions[_tokenId].endTime - block.timestamp;

        if(timeLeft == 600 && auctions[_tokenId].maxExtensionPeriod > 0) {
            auctions[_tokenId].maxExtensionPeriod -= 600; 
            auctions[_tokenId].endTime += 600;
        }

        auctions[_tokenId].highestBidder = msg.sender;

        Bidder memory bidderInfo;

        bidderInfo.bidder = msg.sender; 
        bidderInfo.placedAt = block.timestamp;
        bidderInfo.amountOffered = msg.value;

        auctions[_tokenId].bidders.push(bidderInfo);

        emit BidPlaced(_tokenId, nftCollection.ownerOf(_tokenId), msg.sender, msg.value);
    }

    /**
        @dev allows seller to end the auction
    */
    function endAuction(uint256 _tokenId) public isTokenOwner(_tokenId) {
        require(auctions[_tokenId].status == Status.Active, "The auction is inactive.");
        require(block.timestamp >= auctions[_tokenId].endTime, "The auction is still running.");

        auctions[_tokenId].status = Status.Inactive;

        address highestBidder = auctions[_tokenId].highestBidder;
        uint256 totalCount = auctions[_tokenId].bidders.length;
        uint256 amount;

        for(uint256 i = 0; i < totalCount; i++) {
            if(!auctions[_tokenId].bidders[i].isCancelled) {
                if(auctions[_tokenId].bidders[i].bidder == highestBidder) {
                    amount = auctions[_tokenId].bidders[i].amountOffered;

                    (bool success, ) = payable(nftCollection.ownerOf(_tokenId)).call{value: amount}("");

                    require(success, "Transfer failed.");

                    nftCollection.transferFrom(msg.sender, auctions[_tokenId].highestBidder, _tokenId);

                } else {
                    uint256 offer = auctions[_tokenId].bidders[i].amountOffered;
                    address bidder = auctions[_tokenId].bidders[i].bidder;

                    (bool success, ) = payable(bidder).call{value: offer}("");

                    require(success, "Transfer failed.");
                }
            }
        }

        emit AuctionEnded(_tokenId, nftCollection.ownerOf(_tokenId), auctions[_tokenId].highestBidder, amount);
    }


    function cancelBid(uint256 _tokenId) external {
        if(auctions[_tokenId].highestBidder == msg.sender && auctions[_tokenId].maxExtensionPeriod > 0) {
            auctions[_tokenId].maxExtensionPeriod -= 600; 
            auctions[_tokenId].endTime += 600;
        }

        uint256 totalCount = auctions[_tokenId].bidders.length;
        uint256 amount;

        for(uint256 i = 0; i < totalCount; i++) {
            if(auctions[_tokenId].bidders[i].bidder == msg.sender) {
                amount = auctions[_tokenId].bidders[i].amountOffered;
                auctions[_tokenId].bidders[i].isCancelled = true;
            }
        }

        (bool success, ) = msg.sender.call{value: amount}("");

        require(success, "Transfer failed.");

        emit BidCancelled(_tokenId, nftCollection.ownerOf(_tokenId), msg.sender);
    }

    function fetchBiddings(uint256 _tokenId) external view returns (Bidder[] memory) {
        uint256 totalCount = auctions[_tokenId].bidders.length;
        Bidder[] memory bidders = new Bidder[](totalCount);

        for(uint256 i = 0; i < totalCount; i++) {
            bidders[i] = auctions[_tokenId].bidders[i];
        }

        return bidders;
    }

    function fetchAuction(uint256 _tokenId) public view returns (AuctionDetails memory) {
        return auctions[_tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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