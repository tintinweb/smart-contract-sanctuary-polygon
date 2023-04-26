// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity ^0.8.9;
//NOTE: contract requires optimizer

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC1155Royalty.sol";
import "./IERC721Royalty.sol";
import "./IMarketManagement.sol";

/// @title Escrow smart contract for NFT MArketplace Deployment
/// @author Monkhub Innovations
/// @notice This smart contract facilitates exchange of NFTs and ETH
/// @dev

contract Escrow is ERC1155Holder, ERC721Holder, ReentrancyGuard {
    uint256 public minPrice; //minimum bid amount for an order 0.01 ether
    IMarketManagement market;
    address private owner;
    //uint256 public orderCtr;
    //orderID to orders
    mapping(string => Order) public orders;
    //orderID to orderType
    // mapping(string => orderType) TypeMapping;
    //orderID to token type
    mapping(string => nftType) public tokenType;
    uint256 bidIncrementPercent; // 1500 for 15%
    uint256 bidIncrementAmt;

    constructor(
        IMarketManagement _fm,
        uint256 _minimumBid,
        uint256 minBidIncrementPercent,
        uint256 minBidIncrement,
        uint256 _minSalePrice,
        address _owner
    ) {
        require(minBidIncrementPercent <= 10000);
        market = _fm;
        //orderCtr = 0;
        owner = _owner;
        minPrice = _minimumBid; //Minimum possible bid for listing
        bidIncrementPercent = minBidIncrementPercent; // 500 for 5 %
        bidIncrementAmt = minBidIncrement;
        minSalePrice = _minSalePrice;
    }

    enum Stage {
        NOT_LISTED,
        LISTED,
        PARTIALLY_SOLD,
        orders_CLOSED
    }
    enum orderType {
        None,
        auction,
        sale
    }
    enum nftType {
        None,
        ERC721,
        ERC1155
    }
    struct Order {
        Stage stage;
        address payable seller;
        uint256 tokenID;
        address contractAddr;
        orderType ordertype;
        uint256 highestBid;
        address highestBidder;
        uint256 minBid; //Can work as sale price
        uint256 amountListed;
        uint256 timeLimit; //0 for sales
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function");
        _;
    }

    event BidPlaced(
        address indexed _seller,
        address indexed _bidder,
        string orderId,
        uint256 _tokenId,
        uint256 price,
        uint256 expTime
    );
    event TokenSold(
        address indexed _seller,
        address indexed _buyer,
        string orderId,
        uint256 _tokenIdPurchased
    );
    // event TokenListedAuction(
    //     address indexed _seller,
    //     address indexed _contract,
    //     uint256 _tokenIdListed,
    //     string orderId,
    //     uint256 _price,
    //     uint256 exptime
    //);
    event AuctionCancelled(
        address indexed _seller,
        uint256 indexed _tokenID,
        string orderId
    );

    event EarningsCreditedMarket(
        address indexed _fundManager,
        uint256 indexed _amtCredited
    );

    function changeOwnerAddress(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeMinAuctionPrice(uint256 _new) public onlyOwner {
        minPrice = _new;
    }

    function changeBidIncAmt(uint256 _amt) public onlyOwner {
        bidIncrementAmt = _amt;
    }

    function changeBidIncPercent(uint256 _per) public onlyOwner {
        bidIncrementPercent = _per;
    }

    // function listForAuction(
    //     address _contract,
    //     uint256 _tokenId,
    //     uint256 _minBid, //minimum initial bid
    //     uint256 _dayLimit,
    //     uint256 _reservePrice,
    //     nftType tktype,
    //     uint256 orderId
    // ) public {
    //     require(_contract != address(0), "Null contract address provided");
    //     IERC1155Royalty token;
    //     IERC721Royalty token721;
    //     if (tktype == nftType.ERC1155) token = IERC1155Royalty(_contract);
    //     else token721 = IERC721Royalty(_contract);
    //     require(
    //         _minBid <= _reservePrice,
    //         "Minimum initial bid cannot be greater than reserve price"
    //     );
    //     require(
    //         orders[orderId].stage == Stage.NOT_LISTED,
    //         "Order id invalid"
    //     );
    //     require(
    //         _minBid >= minPrice,
    //         "Min Initial Bid Price should be set more than minimum bid limit"
    //     );
    //     if (!market.isMarketplace())
    //         require(
    //             market.isShopCreator(msg.sender),
    //             "Lister not a registered shop creator"
    //         );
    //     if (tktype == nftType.ERC1155) {
    //         require(
    //             token.isApprovedForAll(msg.sender, address(this)) == true,
    //             "Escrow not approved"
    //         );
    //         require(
    //             token.balanceOf(msg.sender, _tokenId) >= 1,
    //             "Not enough tokens in your wallet"
    //         );
    //         TypeMapping[orderId] = orderType.auction;
    //         tokenType[orderId] = tktype;
    //         orders[orderId] = Order(
    //             Stage.LISTED,
    //             orderId,
    //             payable(msg.sender),
    //             _tokenId,
    //             _contract,
    //             0,
    //             address(0),
    //             _minBid,
    //             block.timestamp + _dayLimit * (1 days),
    //             _reservePrice,
    //             1
    //         );
    //         //token.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    //     } else if (tktype == nftType.ERC721) {
    //         require(
    //             token721.isApprovedForAll(msg.sender, address(this)) == true,
    //             "Escrow not approved"
    //         );
    //         require(
    //             token721.balanceOf(msg.sender) >= 1,
    //             "Not enough tokens in your wallet"
    //         );
    //         TypeMapping[orderId] = orderType.auction;
    //         tokenType[orderId] = tktype;
    //         orders[orderId] = Order(
    //             Stage.LISTED,
    //             orderId,
    //             payable(msg.sender),
    //             _tokenId,
    //             _contract,
    //             0,
    //             address(0),
    //             _minBid,
    //             block.timestamp + _dayLimit * (1 days),
    //             _reservePrice,
    //             1
    //         );
    //         //token721.safeTransferFrom(msg.sender, address(this), _tokenId, "");
    //     } else revert("Invalid contract type");

    //     emit TokenListedAuction(
    //         msg.sender,
    //         _contract,
    //         _tokenId,
    //         orderId,
    //         _minBid,
    //         orders[orderId].timeLimit
    //     );
    // }

    function unlistAuction(
        string memory orderID,
        address contractAddr,
        uint256 tokenId,
        nftType tktype,
        address payable seller,
        uint256 minBid,
        uint256 timeLimit,
        bytes memory signature
    ) public {
        require(msg.sender == seller, "Only seller can access this function");
        require(
            verify(
                msg.sender,
                orderID,
                1,
                contractAddr,
                tokenId,
                minBid,
                orderType.auction,
                signature
            ),
            "Signature not verified"
        );
        require(
            orders[orderID].ordertype == orderType.auction,
            "Order ID-Type mismatch"
        );
        require(
            orders[orderID].stage != Stage.orders_CLOSED,
            "order already closed"
        );
        orders[orderID].stage = Stage.orders_CLOSED;
        if (orders[orderID].highestBid != 0) {
            (bool sent, ) = payable(orders[orderID].highestBidder).call{
                value: orders[orderID].highestBid
            }("");
            require(sent, "bid refund failed");
        }
        emit AuctionCancelled(
            orders[orderID].seller,
            orders[orderID].tokenID,
            orderID
        );
    }

    function placeBid(
        string memory orderID,
        address contractAddr,
        uint256 tokenId,
        nftType tktype,
        address payable seller,
        uint256 minBid,
        uint256 timeLimit,
        bytes memory signature
    ) public payable nonReentrant {
        // require(
        //     TypeMapping[orderID] == orderType.auction,
        //     "Order ID-Type mismatch"
        // );
        require(
            orders[orderID].stage != Stage.orders_CLOSED,
            "Order is closed"
        );
        require(
            verify(
                seller,
                orderID,
                1,
                contractAddr,
                tokenId,
                minBid,
                orderType.auction,
                signature
            ),
            "Signature not verified"
        );
        if (orders[orderID].stage == Stage.NOT_LISTED) {
            orders[orderID] = Order(
                Stage.LISTED,
                seller,
                tokenId,
                contractAddr,
                orderType.auction,
                0,
                address(0),
                minBid,
                1,
                timeLimit
            );
            tokenType[orderID] = tktype;
        }
        require(
            msg.sender != orders[orderID].seller,
            "Sellers can't buy their own token"
        );
        require(
            msg.value > orders[orderID].highestBid &&
                msg.value >= orders[orderID].minBid,
            "Insufficient bid"
        );
        require(
            block.timestamp < orders[orderID].timeLimit,
            "Time expired for auction"
        );
        if (orders[orderID].highestBid == 0) {
            require(
                msg.value >= orders[orderID].minBid,
                "Lower than minimum bid"
            );
            orders[orderID].highestBid = msg.value;
            orders[orderID].highestBidder = msg.sender;
            if (
                block.timestamp >= (orders[orderID].timeLimit - 600) &&
                block.timestamp < orders[orderID].timeLimit
            ) orders[orderID].timeLimit = orders[orderID].timeLimit + 600;

            emit BidPlaced(
                orders[orderID].seller,
                orders[orderID].highestBidder,
                orderID,
                orders[orderID].tokenID,
                orders[orderID].highestBid,
                timeLimit
            );
        } else {
            uint256 bidIncrement = msg.value - orders[orderID].highestBid;
            uint256 percent = (orders[orderID].highestBid *
                bidIncrementPercent) / 10000;
            if (percent > bidIncrementAmt)
                //Checking suitable increment for next bid
                require(
                    bidIncrement >= percent,
                    "Consecutive bid's increment not sufficient"
                );
            else
                require(
                    bidIncrement >= bidIncrementAmt,
                    "Consecutive bid's increment not sufficient"
                );

            uint256 refundBid = orders[orderID].highestBid;
            address to = orders[orderID].highestBidder;
            orders[orderID].highestBid = msg.value;
            orders[orderID].highestBidder = msg.sender;

            if (
                block.timestamp >= (orders[orderID].timeLimit - 600) &&
                block.timestamp < orders[orderID].timeLimit
            ) orders[orderID].timeLimit = orders[orderID].timeLimit + 600;

            emit BidPlaced(
                orders[orderID].seller,
                orders[orderID].highestBidder,
                orderID,
                orders[orderID].tokenID,
                orders[orderID].highestBid,
                timeLimit
            );
            (bool sent, ) = payable(to).call{value: refundBid}(""); //relinquish previous bid
            require(sent, "bid refund failed");
        }
    }

    function confirmSale(string memory orderID) public {
        require(orders[orderID].stage == Stage.LISTED, "Order is closed or has no bid");
        require(
            orders[orderID].ordertype == orderType.auction,
            "Order ID-Type mismatch"
        );
        require(
            msg.sender == orders[orderID].seller,
            "Only seller can confirm sale"
        );
        uint256 cost = orders[orderID].highestBid;
        orders[orderID].stage = Stage.orders_CLOSED;
        uint256 marketCommission = (cost * market.earningCommission()) / 10000;
        address minter;
        uint256 royaltyAmount;
        IERC1155Royalty token;
        IERC721Royalty token721;

        if (tokenType[orderID] == nftType.ERC1155) {
            token = IERC1155Royalty(orders[orderID].contractAddr);
            try token.royaltyInfo(orders[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }
            token.safeTransferFrom(
                orders[orderID].seller,
                orders[orderID].highestBidder,
                orders[orderID].tokenID,
                1,
                ""
            );
        } else {
            token721 = IERC721Royalty(orders[orderID].contractAddr);
            try token721.royaltyInfo(orders[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }
            token721.safeTransferFrom(
                orders[orderID].seller,
                orders[orderID].highestBidder,
                orders[orderID].tokenID,
                ""
            );
        }
        if (orders[orderID].seller != minter)
            if (royaltyAmount != 0) payable(minter).transfer(royaltyAmount);
            else royaltyAmount = 0;
        (bool sent, ) = payable(address(market)).call{value: marketCommission}(
            ""
        );
        require(sent, "Commission not credited to market owner");
        emit EarningsCreditedMarket(address(market), marketCommission);
        orders[orderID].seller.transfer(
            cost - (marketCommission + royaltyAmount)
        );
        emit TokenSold(
            orders[orderID].seller,
            orders[orderID].highestBidder,
            orderID,
            orders[orderID].tokenID
        );
    }

    /////////////////////////////////////////////FOR DIRECT SALE ///////////////////////////////////////////////////////////////////////////////////////////////////

    //Min. price of any token
    uint256 public minSalePrice;

    // event TokenListed(
    //     address indexed _seller,
    //     address indexed _contract,
    //     uint256 _tokenIdListed,
    //     uint256 _orderid,
    //     uint256 _amountListed,
    //     uint256 _pricePerPiece
    // );
    event TokenUnlisted(
        address indexed _seller,
        address indexed _contract,
        uint256 _tokenIdUnlisted,
        string _orderid
    );
    event TokenPurchased(
        address indexed _seller,
        address indexed _buyer,
        address indexed _contract,
        string _orderID,
        uint256 _tokenIdPurchased,
        uint256 _amountBought,
        uint256 _cost,
        uint256 _totalListed
    );

    function unlistSale(
        string memory orderID,
        uint256 buyAmount,
        address contractAddr,
        uint256 tokenId,
        nftType tktype,
        address payable seller,
        uint256 listedPrice,
        uint256 listedAmount,
        bytes memory signature
    ) public {
        require(
            orders[orderID].stage != Stage.orders_CLOSED,
            "Order is already closed"
        );
        require(msg.sender == seller, "Only seller can unlist sale");
        require(
            verify(
                msg.sender,
                orderID,
                listedAmount,
                contractAddr,
                tokenId,
                listedPrice,
                orderType.sale,
                signature
            ),
            "Signature not verified"
        );
        orders[orderID].stage = Stage.orders_CLOSED;
        emit TokenUnlisted(
            msg.sender,
            orders[orderID].contractAddr,
            orders[orderID].tokenID,
            orderID
        );
    }

    //For direct buy of tokens
    function fulfillSale(
        string memory orderID,
        uint256 buyAmount,
        address contractAddr,
        uint256 tokenId,
        nftType tktype,
        address payable seller,
        uint256 listedPrice,
        uint256 listedAmount,
        bytes memory signature
    ) public payable {
        require(
            verify(
                seller,
                orderID,
                listedAmount,
                contractAddr,
                tokenId,
                listedPrice,
                orderType.sale,
                signature
            ),
            "Signature not verified"
        );
        if (orders[orderID].stage == Stage.NOT_LISTED) {
            orders[orderID] = Order(
                Stage.PARTIALLY_SOLD,
                seller,
                tokenId,
                contractAddr,
                orderType.sale,
                0,
                address(0),
                listedPrice,
                listedAmount,
                0
            );
            tokenType[orderID] = tktype;
        }
        require(
            (buyAmount > 0) && buyAmount <= orders[orderID].amountListed,
            "Invalid buy amount provided"
        );
        require(
            orders[orderID].stage != Stage.orders_CLOSED,
            "Order is closed"
        );

        require(msg.sender != seller, "Sellers can't buy their own token");

        uint256 cost = (orders[orderID].minBid) * (buyAmount);
        require(msg.value == listedPrice * buyAmount, "Insufficient funds");
        uint256 marketCommission = (cost * market.earningCommission()) / 10000;
        address minter;
        uint256 royaltyAmount;

        if (tokenType[orderID] == nftType.ERC1155) {
            IERC1155Royalty token = IERC1155Royalty(contractAddr);
            require(
                token.isApprovedForAll(seller, address(this)) == true,
                "Escrow not approved"
            );
            try token.royaltyInfo(orders[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }

            token.safeTransferFrom(
                orders[orderID].seller,
                msg.sender,
                orders[orderID].tokenID,
                buyAmount,
                ""
            );
        } else {
            IERC721Royalty token = IERC721Royalty(contractAddr);
            require(
                token.isApprovedForAll(seller, address(this)) == true,
                "Escrow not approved"
            );
            try token.royaltyInfo(orders[orderID].tokenID, cost) returns (
                address x,
                uint256 y
            ) {
                minter = x;
                royaltyAmount = y;
            } catch {
                minter = address(0);
                royaltyAmount = 0;
            }
            token.safeTransferFrom(
                orders[orderID].seller,
                msg.sender,
                orders[orderID].tokenID,
                ""
            );
        }
        orders[orderID].amountListed = orders[orderID].amountListed - buyAmount;
        if (orders[orderID].amountListed == 0)
            orders[orderID].stage = Stage.orders_CLOSED;
        if (orders[orderID].seller != minter)
            if (royaltyAmount != 0) payable(minter).transfer(royaltyAmount);
            else royaltyAmount = 0;
        (bool sent, ) = payable(address(market)).call{value: marketCommission}(
            ""
        );
        require(sent, "Commission not credited to market owner");
        emit EarningsCreditedMarket(address(market), marketCommission);
        (sent, ) = orders[orderID].seller.call{
            value: cost - (marketCommission + royaltyAmount)
        }("");
        require(sent, "Earnings not credited to seller");

        emit TokenPurchased(
            orders[orderID].seller,
            msg.sender,
            address(orders[orderID].contractAddr),
            orderID,
            orders[orderID].tokenID,
            buyAmount,
            cost,
            listedAmount
        );
    }

    function getMessageHash(
        string memory orderID,
        uint256 listedAmount,
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        orderType ordertype
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    orderID,
                    listedAmount,
                    contractAddr,
                    tokenId,
                    price,
                    ordertype
                )
            );
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        string memory orderID,
        uint256 listedAmount,
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        orderType ordertype,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            orderID,
            listedAmount,
            contractAddr,
            tokenId,
            price,
            ordertype
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Royalty is IERC1155,IERC2981 {
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Royalty is IERC721,IERC2981 {
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMarketManagement {
    function earningCommission() external view returns(uint256);
    function isMarketplace() external view returns(bool);
    function isShopCreator(address) external view returns (bool);
}