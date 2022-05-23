// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC721.sol";

contract A4AAuction is Ownable, IERC721Receiver {
    //using SafeMath for uint256;

    address private a4A_NFT_address = 0xf0DFE1C98b0c8aC0c1f4D0fFb20D06cb8DA588B1;//0x86693F3853A12c0E14Aa4DF2bFA1612528B10835;
    address private _a4A_wallet;

    IERC721 a4A_items = IERC721(a4A_NFT_address);

    mapping(uint256 => address) private _listedItemsOwner;
    mapping(uint256 => uint256) private _auctionsEndDate;
    mapping(uint256 => uint256) private _listedItemsMinPrice;
    mapping(uint256 => uint256) private _listedItemsMaxPrice;
    mapping(uint256 => uint256) private _auctionsCreationDate;

    mapping(uint256 => address) private _maxBidderByItemID;
    //mapping(uint256 => address) private _maxBidderbyAuction;

    //mapping(uint256 => uint256) private _auctionByItemID; //NFT ID --> Auction ID
    //mapping(uint256 => uint256) private _itemByAuctionID; //Auction ID --> NFT ID


    uint256 public _auctionFee;
    uint256 public _itemsForAuction;

    //using Counters for Counters.Counter;
    //Counters.Counter private _auctionIds;


    event NewAuction(uint256 tokenId, address seller, uint256 price, uint256 endDate);
    event CancelAuction(uint256 tokenId);
    event ExtendAuction(uint256 tokenId, uint256 newEndDate);

    event NewBid(uint256 tokenId, address bidder, uint256 price);
    event ItemSold(uint256 tokenId, address buyer, address seller, uint256 price);


    constructor() {
        _auctionFee = 5;
        _a4A_wallet = payable(_msgSender());
    }


    function listItemForAuction(uint256 itemID, uint256 minPrice, uint256 endDate) external {
        require(a4A_items.ownerOf(itemID) == _msgSender(), "Auction can only be open by the owner.");

        //Save NFT price & owner
        _auctionsEndDate[itemID] = endDate;
        _listedItemsMinPrice[itemID] = minPrice;
        _listedItemsOwner[itemID] = a4A_items.ownerOf(itemID);
        _auctionsCreationDate[itemID] = block.timestamp;

        //Create Auction ID
        /*
        _auctionIds.increment();
        uint256 newAuctionId = _auctionIds.current();
        _itemByAuctionID[newAuctionId] = itemID;
        _auctionByItemID[itemID] = newAuctionId;
        */

        //Transfer NFT to contract (requires previous approve)
        a4A_items.safeTransferFrom(_msgSender(), address(this), itemID);

        _itemsForAuction++;

        emit NewAuction(itemID, _msgSender(), minPrice, endDate);
    }

    function cancelAuction(uint256 itemID) external {
        require(_listedItemsOwner[itemID] == _msgSender());
        require(block.timestamp < _auctionsEndDate[itemID]);

        if (_maxBidderByItemID[itemID] != address(0)){
            (bool sentFee, ) = _maxBidderByItemID[itemID].call{value: _listedItemsMaxPrice[itemID]}("");
            require(sentFee, "Failed to send money back to previous highest bidder.");
        }

        //Transfer NFT back to owner
        a4A_items.safeTransferFrom(address(this), _listedItemsOwner[itemID], itemID);

        _removeAuctionData(itemID);
        _itemsForAuction--;

        emit CancelAuction(itemID);

    }

    function extendAuction(uint256 itemID, uint256 newEndDate) external {
        require(_listedItemsOwner[itemID] == _msgSender());
        require(block.timestamp < _auctionsEndDate[itemID]);
        require(block.timestamp < newEndDate);
         _auctionsEndDate[itemID] = newEndDate;

         emit ExtendAuction(itemID, newEndDate);
    }

    function bidForItem(uint256 itemID) external payable {
        require(block.timestamp < _auctionsEndDate[itemID]);
        require(msg.value > _listedItemsMaxPrice[itemID]);

        (bool sentFee, ) = _maxBidderByItemID[itemID].call{value: _listedItemsMaxPrice[itemID]}("");
        require(sentFee, "Failed to send money back to previous highest bidder.");

        _listedItemsMaxPrice[itemID] = msg.value;
        _maxBidderByItemID[itemID] = _msgSender();

        emit NewBid(itemID, _msgSender(), msg.value);
    }

    //_maxBidderbyAuction[auctionId]
    function claimAuctionResult(uint256 itemID) external onlyOwner {
        require(block.timestamp > _auctionsEndDate[itemID], "Auction is still active.");

        if(_maxBidderByItemID[itemID] == address(0) || _listedItemsMaxPrice[itemID] < _listedItemsMinPrice[itemID]){
            a4A_items.safeTransferFrom(address(this), _listedItemsOwner[itemID], itemID);
        }
        else {

            //Check payment
            uint256 _itemPrice = _listedItemsMaxPrice[itemID];

            address seller = payable(_listedItemsOwner[itemID]);
            require(seller != address(0), "Seller cannot be address 0.");

            //Calculate market fee
            uint256 marketAmt = _auctionFee * _itemPrice / 100;
            (bool sentFee, ) = _a4A_wallet.call{value: marketAmt}("");
            require(sentFee, "Failed to send BNB fee to the team.");

            //Calculate author fee
            uint256 authorAmt = a4A_items.authorFee(itemID) * _itemPrice / 100;
            (bool sentAuthortFee, ) = payable( a4A_items.author(itemID)).call{value: authorAmt}("");
            require(sentAuthortFee, "Failed to send BNB fee to the Author.");

            //Calculate seller's amount
            uint256 sellerAmt = _itemPrice - marketAmt - authorAmt;
            (bool sentValue, ) = seller.call{value: sellerAmt}("");
            require(sentValue, "Failed to send BNB to the item owner.");

            //Transfer NFT to the buyer
            a4A_items.safeTransferFrom(address(this), _maxBidderByItemID[itemID], itemID);

            _listedItemsOwner[itemID] = address(0);
            _listedItemsMaxPrice[itemID] = 0;

            //check New owner & Not for sale
            require(a4A_items.ownerOf(itemID) == _maxBidderByItemID[itemID], "New owner not assigned.");
            require(_listedItemsMaxPrice[itemID] == 0, "Price not set to 0 after sell.");
            //require(msg.sender == _maxBidder[itemID], "Only new owner can claim the item.");

            _removeAuctionData(itemID);
            _itemsForAuction--;

        }

        emit ItemSold(itemID, a4A_items.ownerOf(itemID), _listedItemsOwner[itemID], _listedItemsMaxPrice[itemID] );
    }

    function _removeAuctionData(uint256 itemID) internal onlyOwner {
        _listedItemsOwner[itemID] = address(0);
        _auctionsEndDate[itemID] = 0;
        _listedItemsMinPrice[itemID] = 0;
        _listedItemsMaxPrice[itemID] = 0;
        _auctionsCreationDate[itemID] = 0;
        //_auctionByItemID[itemID] = 0; //NFT ID --> Auction ID
        _maxBidderByItemID[itemID] = address(0);
        //_maxBidderbyAuction[itemID] = address(0);
        //_itemByAuctionID[_auctionByItemID[itemID]] = 0; //Auction ID --> NFT ID

    }

    function setA4AWallet(address payable wallet) external onlyOwner {
        _a4A_wallet = wallet;
    }

    function setA4Afee(uint256 fee) external onlyOwner {
        _auctionFee = fee;
    }


    function listedItemsOwner(uint256 itemId) external view returns(address) {
        return _listedItemsOwner[itemId];
    }

    function listedItemsMinPrice(uint256 itemId) external view returns(uint256) {
        return _listedItemsMinPrice[itemId];
    }

    function listedItemsMaxPrice(uint256 itemId) external view returns(uint256) {
        return _listedItemsMaxPrice[itemId];
    }

    function auctionsEndDate(uint256 itemId) external view returns(uint256) {
        return _auctionsEndDate[itemId];
    }

    function auctionsCreationDate(uint256 itemId) external view returns(uint256) {
        return _auctionsCreationDate[itemId];
    }

    function lastBid(uint256 itemId) external view returns(address, uint256) {
        return (_maxBidderByItemID[itemId], _listedItemsMaxPrice[itemId]);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

/*
    function getAuctionIDbyItem(uint256 itemId) public view returns(uint256) {

        return _auctionByItemID[itemId];
    }

    function getItemIDbyAuction(uint256 auctionId) external view returns(uint256) {
        return _itemByAuctionID[auctionId];
    }

    function lastBidbyAuction(uint256 auctionId) external view returns(address){
        return _maxBidderbyAuction[auctionId];
    }
*/

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

    /**
     * @dev Returns the author of `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function author(uint256 tokenID) external view returns(address);

    /**
     * @dev Returns the author fee of `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function authorFee(uint256 tokenID) external view returns(uint256);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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