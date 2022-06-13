/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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


// File @openzeppelin/contracts/security/[email protected]

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


// File contracts/MetaFiMarketPlace.sol

pragma solidity 0.8.4;
// Direct sale from seller to buyer.
// Seller fix the price and sale end date
// Buyer pays the price, gets the NFT during sale period

contract NFTMarket is ReentrancyGuard {

    struct DirectSale {
        uint256 tokenId;
        address payable seller;
        uint256 startTime;
        uint256 endTime;
        address payable buyer;
        uint256 salePrice;
    }
    // Mapping
    // Handles Price of each NFT
    mapping(uint256 => uint128) public NFTPrice;
    // Hamdles sale data in struct
    mapping(address => mapping(uint256 => DirectSale)) public tokenIdToSale;    

    // Event
    // Records Sale call
    event DirectSaleCreated(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 reservePrice
    );

    // Records buy call
    event DirectSaleFinalized(
        address indexed buyer,
        uint256 indexed tokenId
    );

    modifier onlyValidConfig(uint256 reservePrice) {
        require(
            reservePrice > 0,
            "NFTSale: Reserve price must be at least 1 wei"
        );
        _;
    }

    /**

     * @notice Creates an Sale for the given NFT.
     * The NFT is held in escrow until the Sale is finalized or canceled.
     */

    constructor(){

    }
    
    receive()
       external
       payable    
    {
        
    }

    function createDirectSale(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 startDate,
        uint256 endDate
    ) public onlyValidConfig(reservePrice) nonReentrant {

        require(tokenIdToSale[nftContract][tokenId].endTime == 0, "NFTSale : Token already in sale");

        tokenIdToSale[nftContract][tokenId] = DirectSale(
            tokenId,
            payable(msg.sender),
            startDate,
            endDate, // endTime is when sale ends
            payable(address(0)), // Buyer is only known when the buyer buys the NFT
            reservePrice
        );
        
        IERC721(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit DirectSaleCreated(
                msg.sender,
                tokenId,
                reservePrice
        );

    }
     /**
     * @notice Before the countdown has expired for an sale, anyone can settle the Sale.
     * This will send the NFT to the Buyer.
     */

    function finalizeDirectSale(
        address nftContract,
        uint256 tokenId
    ) public payable nonReentrant {

        DirectSale storage sale = tokenIdToSale[nftContract][tokenId];

        require(
            sale.startTime <= block.timestamp &&
                sale.endTime >= block.timestamp,
            "NFTSale: Sale not live"
        );

        require(sale.salePrice > 0, "NFTSale: Not a valid sale");
        // ends the sale
        sale.endTime = 0;

        // (bool success, ) = msg.sender.call{value: sale.salePrice, gas: 20000}("");
        // require(success, "NFTSale : Sale amount transfer failed with low gas limit");
        require(msg.value >= sale.salePrice, "Insufficient funds");

        
        //pay for token owner
        (bool success, ) = payable(sale.seller).call{
                // value: msg.value,
                value: sale.salePrice,
                gas: 300000
        }("");
        // if it failed, update their credit balance so they can pull it later
        require(success, "Pay seller failed");

        //transfer NFT to buyer
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        resetTokenIdToSale(nftContract, tokenId);

        emit DirectSaleFinalized(
                msg.sender,
                tokenId
        );
    }

    function resetTokenIdToSale(
        address nftContract,
        uint256 tokenId
    )
    public{
        tokenIdToSale[nftContract][tokenId].seller = payable(address(0));
        tokenIdToSale[nftContract][tokenId].startTime = 0;
        tokenIdToSale[nftContract][tokenId].endTime = 0;
        tokenIdToSale[nftContract][tokenId].buyer = payable(address(0));
        tokenIdToSale[nftContract][tokenId].salePrice = 0;
    }

    function getTokenprice(uint256 tokenId, address nftContract) public view returns(uint256) {
        return tokenIdToSale[nftContract][tokenId].salePrice;
    }
}