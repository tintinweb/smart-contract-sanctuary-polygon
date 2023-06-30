// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// debug tools
// import {Test, console2, StdStyle, StdCheats} from "forge-std/Test.sol";
//OpenZeppelin's NFT Standard Contracts. We will extend functions from this in our implementation

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol"; // this could be something where we can hand owner to a contract not an address
// Interface
import {INFTMarketplace} from "./interfaces/INFTMarketplace.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarketplace is INFTMarketplace, Ownable, ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    // Keeps track of the number of items sold on the marketplace

    Counters.Counter private _itemsSold;
    // feePercentage is the fee that the marketplace takes from each sale
    uint256 public feePercentage = 5;
    // feeRecipient is the address that receives the fee
    address payable public feeRecipient;

    // nativeCurrency is the currency that the marketplace accepts
    string public nativeCurrency;

    //The structure to store info about a listed token
    struct Listing {
        uint256 tokenId;
        address contractAddress;
        address payable seller;
        uint256 price;
        bool currentlyListed;
        string tokenURI;
    }

    mapping(uint256 => Listing) public listings; // could be private aggregator or 2rd party could pull this data and display it in their own platform. urchases) would still have to go through your smart contract. A third-party site could potentially become a popular place to browse listings, but it wouldn't be able to circumvent the marketplace contract when it comes to actual transactions. This means the contract (and by extension, the original application) would still receive any fees or commissions it's programmed to collect.

    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "Fee Recipient cannot be the zero address");
        feeRecipient = payable(_feeRecipient);
        // feeRecipient = payable(owner()); // Using the owner() function provided by Ownable
    }

    // set the fee recipient
    function setFeeRecipient(address newFeeRecipient) public onlyOwner {
        require(newFeeRecipient != address(0), "Fee Recipient cannot be the zero address");
        feeRecipient = payable(newFeeRecipient);
        emit FeeRecipientChanged(newFeeRecipient);
    }

    // ownership transfer function (should this be in a separate contract?)
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        // Our additional logic here...
    }

    // listing function
    function listToken(address nftContractAddress, uint256 tokenId, uint256 price) external {
        IERC721Metadata nftContract = IERC721Metadata(nftContractAddress); // using the interface is more gas efficient and adheres to best practices of using the least authority neccessary.
        // ERC721 nftContract = ERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "You must own the token to list it for sale");
        require(price > 0, "Make sure the price isn't negative");

        string memory tokenURI = nftContract.tokenURI(tokenId); // Get the token URI

        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(
            tokenId,
            nftContractAddress, // Save the contract address
            payable(msg.sender),
            price,
            true,
            tokenURI
        );
        emit TokenListed(tokenId, msg.sender, price, true);
    }

    function buyToken(address nftContractAddress, uint256 tokenId) external payable nonReentrant {
        // Get the listing from storage.
        Listing storage listing = listings[tokenId];

        // Require that the token is currently listed.
        require(listing.currentlyListed, "The token is not currently listed");

        // Require that the correct amount was sent.
        require(msg.value >= listing.price, "The sent amount is less than the listing price");

        // Create an instance of the NFT contract.
        IERC721 nftContract = IERC721(nftContractAddress);

        // Ensure that the contract owns the token.
        require(nftContract.ownerOf(tokenId) == address(this), "The contract does not own this token");

        // Calculate the marketplace fee
        uint256 marketplaceFee = (listing.price * feePercentage) / 100;

        // Transfer the token to the buyer.
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

        // Transfer the payment to the seller and marketplace (if there's a fee).
        listing.seller.transfer(listing.price - marketplaceFee);
        feeRecipient.transfer(marketplaceFee);

        // Update the listing to indicate it's no longer listed
        listing.currentlyListed = false;

        // Emit the event for successful purchase. The application parses this message and updates the end user
        // msg.sender is the buyer of the token
        //list.seller
        emit TokenSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    function removeListing(uint256 tokenId) external {
        /* lets a seller remove their listing if the NFT hasn't been sold yet. */
        // Get the listing from storage.
        Listing storage listing = listings[tokenId];
        // Require that the token is currently listed
        require(listing.currentlyListed, "The token is not currently listed");
        // Require that the sender is the seller of the token
        require(listing.seller == msg.sender, "You are not the seller of this token");
        // Unlist the token
        listing.currentlyListed = false;
        // Transfer the token back to the seller
        IERC721 nftContract = IERC721(listing.contractAddress);
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

        // remove from listing mapping | *gas optimization and data cleanliness
        // for now wouldnt remove it from the mapping for the sake of data integrity
        // delete listings[tokenId]; // if we do it here then we have to do in buyToken() as well but this is all considering off chain data aggregation and display and data availability

        // emit event
        emit TokenDelisted(tokenId, msg.sender);
    }

    function changeListingPrice(uint256 tokenId, uint256 newPrice) public {
        /* allows the seller to change the listing price of their NFT. */
        // Get the listing from storage.
        Listing storage listing = listings[tokenId];
        // Require that the token is currently listed
        require(listing.currentlyListed, "The token is not currently listed");
        // Require that the sender is the seller of the token
        require(listing.seller == msg.sender, "You are not the seller of this token");
        // Store the old price
        uint256 oldPrice = listing.price;
        // Change the listing price
        listing.price = newPrice;
        // Emit the event
        emit TokenPriceChanged(tokenId, msg.sender, oldPrice, newPrice);
    }

    function getTokenDetails(uint256 tokenId)
        public
        view
        returns (address seller, string memory tokenURI, uint256 price)
    {
        /* This function returns details about a specific token that's listed for sale, given its tokenId.  */
        Listing memory item = listings[tokenId];
        // Return the seller, tokenURI, and price of the token
        return (item.seller, item.tokenURI, item.price);
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes memory /* data */
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
pragma solidity 0.8.20;

interface INFTMarketplace {
    // Events
    event TokenListed(uint256 indexed tokenId, address indexed seller, uint256 price, bool currentlyListed); //bool could be redundant but needed?
    event TokenSold(uint256 indexed tokenId, address indexed seller, address buyer, uint256 price);
    event TokenDelisted(uint256 indexed tokenId, address indexed seller);
    event TokenPriceChanged(uint256 indexed tokenId, address indexed seller, uint256 oldPrice, uint256 newPrice);
    event FeeRecipientChanged(address newFeeRecipient);

    // Functions

    function listToken(address nftContractAddress, uint256 tokenId, uint256 price) external;
    function removeListing(uint256 tokenId) external;
    function buyToken(address nftContractAddress, uint256 tokenId) external payable;
    function changeListingPrice(uint256 tokenId, uint256 newPrice) external;
    function getTokenDetails(uint256 tokenId)
        external
        view
        returns (address seller, string memory tokenURI, uint256 price);
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