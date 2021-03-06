// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract.
 */
interface IERC1155{
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
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
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}



// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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

    // constructor () {
    //     _status = _NOT_ENTERED;
    // }

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


// For future use to allow buyers to receive a discount depending on staking or other rules.
interface IDiscountManager {
    function getDiscount(address buyer) external view returns (uint256 discount);
}

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



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    // constructor (){
    //     // Derived contracts need only register support for their own interfaces,
    //     // we register support for ERC165 itself here
    //     _registerInterface(_INTERFACE_ID_ERC165);
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * _Available since v3.1._
 */
abstract contract NFTReceiver is ERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual returns (bytes4){
        return this.onERC721Received.selector;
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract NFTMarket is ReentrancyGuard,NFTReceiver,Initializable  {
    
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
    _;
    }
    
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; // Id for each individual item
    Counters.Counter private _itemsSold; // Number of items sold
    Counters.Counter private _itemsCancelled; // Number of items sold


    Counters.Counter private _offerIds; // Tracking offers

    address public owner; // The owner of the NFTMarket contract 
    address public discountManager; // a contract that can be callled to discover if there is a discount on the transaction fee.

    uint256 public saleFeePercentage; // Percentage fee paid to team for each sale
    uint256 public volumeTraded; // Total amount traded
    uint256 public totalSellerFee; // Total fee from sellers
    uint8 public sellerFee; // 10: 1%, 100: 10% 

    function initialize() public initializer {
        owner = msg.sender;
        discountManager = address(0x0);
        saleFeePercentage = 5;
        volumeTraded = 0;
        totalSellerFee = 0;
        sellerFee = 0;
    }


    struct MarketOffer {
        uint256 offerId;
        address payable bidder;
        uint256 offerAmount;
        uint256 offerTime;
        uint256 tokenAmount;
        bool cancelled;
        bool accepted;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        address payable seller;
        address payable buyer;
        string category;
        uint8 kind; // 0:fixed price sale ,1: enable auction
        bool hasAmount; // true: erc1155, false: erc721
        IERC20 currency;
        uint256 price;
        bool isSold;
        bool cancelled;
        uint256 soldAmount;
    }

    struct MarketAuctionItem {
        uint256 flashPrice;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(uint256 => MarketAuctionItem) public idToMarketAuctionItem;
    mapping(address => mapping(uint256 => uint256[])) public contractToTokenToItemId;

    mapping(uint256 => MarketOffer[]) private idToMarketOffers;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );
    
     event MarketSaleCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        string category,
        uint256 price
    );

    event ItemOfferCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        address owner,
        address bidder,
        uint256 bidAmount
    );

    // offers
    function makeOffer(uint256 itemId, uint256 tokenAmount, uint256 offerPrice) public payable nonReentrant{
        require(itemId > 0 && itemId<=_itemIds.current(), "Invalid item id.");
        require(idToMarketItem[itemId].isSold==false && idToMarketItem[itemId].cancelled==false , "This item is not for sale.");
        require(idToMarketItem[itemId].seller!=msg.sender , "Can't bid on your own item.");
        require(tokenAmount >0 && tokenAmount <= idToMarketItem[itemId].amount , "Invalid amount.");
        IERC20 _currency = idToMarketItem[itemId].currency;
        require(address(_currency) == address(0) || msg.value>0, "Can't offer nothing.");
        uint256 _offerPrice = msg.value;
        if (address(_currency) != address(0)) {
            _currency.transferFrom(msg.sender, address(this), offerPrice);
            _offerPrice = offerPrice;
        }
        uint256 offerIndex = idToMarketOffers[itemId].length;
        if (idToMarketItem[itemId].kind == 1) {
            require(idToMarketAuctionItem[itemId].endTime == 0 || block.timestamp < idToMarketAuctionItem[itemId].endTime, "Auction was over.");
            uint256 _lastPrice = idToMarketItem[itemId].price;
            for(uint i = offerIndex - 1; i >=0 ; i--) {
                if (!idToMarketOffers[itemId][i].cancelled) {
                    _lastPrice = idToMarketOffers[itemId][i].offerAmount;
                    break;
                }
            }
            require(_offerPrice > _lastPrice, "Can't offer nothing.");
        }
        idToMarketOffers[itemId].push(MarketOffer(offerIndex,payable(msg.sender),_offerPrice,block.timestamp,tokenAmount,false, false));
        if (_offerPrice >= idToMarketAuctionItem[itemId].flashPrice) {
            _acceptOffer(itemId, offerIndex);
        }
    }
        
    function acceptOffer(uint256 itemId, uint256 offerIndex) public nonReentrant{
        require(address(idToMarketItem[itemId].seller) == address(msg.sender), "You are not the seller.");
        _acceptOffer(itemId, offerIndex);
    }

    function _acceptOffer(uint256 itemId, uint256 offerIndex) internal {
        require(offerIndex<=idToMarketOffers[itemId].length, "Invalid offer index");
        require(idToMarketItem[itemId].isSold==false && idToMarketItem[itemId].cancelled==false , "This item is not for sale.");
        require(idToMarketOffers[itemId][offerIndex].accepted==false && idToMarketOffers[itemId][offerIndex].cancelled==false, "Already accepted or cancelled.");
        
        uint256 price = idToMarketOffers[itemId][offerIndex].offerAmount;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address bidder = payable(idToMarketOffers[itemId][offerIndex].bidder);
        address seller = idToMarketItem[itemId].seller;

        //add total volumeTraded
        volumeTraded = volumeTraded + price;
        
        uint256 fees = SafeMath.div(price,100).mul(saleFeePercentage);

        idToMarketOffers[itemId][offerIndex].accepted = true;

        if (discountManager!=address(0x0)){
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager).getDiscount(seller);
            fees = fees.div(100).mul(feeDiscountPercent);
        }
        
        uint256 saleAmount = price.sub(fees);

        if (address(idToMarketItem[itemId].currency) == address(0))
            payable(seller).transfer(saleAmount);
        else
            idToMarketItem[itemId].currency.transfer(idToMarketItem[itemId].seller, saleAmount);
        
        uint256 amount = idToMarketItem[itemId].amount;
        if(idToMarketItem[itemId].hasAmount)
            IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this),  bidder, tokenId, amount, "");
        else
            IERC721(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this),  bidder, tokenId);
        
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].soldAmount = amount;
        idToMarketItem[itemId].buyer = payable(bidder);
        cancelOffers(itemId);
        _itemsSold.increment();

        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i = 0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }
        string memory category = idToMarketItem[itemId].category;
        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].nftContract,
            tokenId,
            seller,
            bidder,
            category,
            price
        );
        
        //create new marketitem
        uint _preAmount = idToMarketItem[itemId].amount;
        uint _prePrice = idToMarketItem[itemId].price;
        if(amount < _preAmount)
        {
            uint256 newAmount = _preAmount.sub(amount);
            uint256 newPrice = _prePrice.div(_preAmount).mul(newAmount);
            cloneMarketItem(itemId, newAmount, newPrice);
        }
    }

    function cloneMarketItem(uint256 itemId, uint256 newAmount, uint256 newPrice) internal {        
        address nftContract = idToMarketItem[itemId].nftContract;
        address seller = idToMarketItem[itemId].seller;
        uint8 kind = idToMarketItem[itemId].kind;
        bool hasAmount = idToMarketItem[itemId].hasAmount;
        string memory category = idToMarketItem[itemId].category;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();

        IERC20 currency = idToMarketItem[itemId].currency;
        uint256 _newPrice = newPrice;
        idToMarketItem[newItemId] = MarketItem(
            newItemId,
            nftContract,
            tokenId,
            newAmount,
            payable(seller),
            payable(address(0)), // No owner for the item
            category,
            kind,
            hasAmount,
            currency,
            _newPrice,
            false,
            false,
            0
        );
        idToMarketAuctionItem[newItemId] = MarketAuctionItem(
            0,
            0,
            0
        );
        contractToTokenToItemId[idToMarketItem[itemId].nftContract][tokenId].push(newItemId);
        emit MarketItemCreated(
            newItemId,
            nftContract,
            tokenId,
            seller
        );
    }
    
    function cancelOffer(uint256 itemId, uint256 offerIndex) public nonReentrant{
        require(idToMarketOffers[itemId][offerIndex].bidder==msg.sender && idToMarketOffers[itemId][offerIndex].cancelled==false , "Wrong bidder or offer is already cancelled");
        require(idToMarketOffers[itemId][offerIndex].accepted==false, "Already accepted.");

        IERC20 currency = idToMarketItem[itemId].currency;   
        address bidder = idToMarketOffers[itemId][offerIndex].bidder;

        idToMarketOffers[itemId][offerIndex].cancelled = true;        
        if (address(currency) == address(0))
            payable(bidder).transfer(idToMarketOffers[itemId][offerIndex].offerAmount);
        else
            currency.transfer(bidder, idToMarketOffers[itemId][offerIndex].offerAmount);

        //TODO emit
    }

    function getMarketOffers(uint256 itemId) public view returns (MarketOffer[] memory) {
        
        uint256 openOfferCount = 0;
        uint256 currentIndex = 0;
        MarketOffer[] memory marketOffers = idToMarketOffers[itemId];

        for (uint256 i = 0; i < marketOffers.length; i++) {
            if (marketOffers[i].accepted==false && marketOffers[i].cancelled==false){
                openOfferCount++;
            }
        }
          
        MarketOffer[] memory openOffers =  new MarketOffer[](openOfferCount);
        
        for (uint256 i = 0; i < marketOffers.length; i++) {
            if (marketOffers[i].accepted==false && marketOffers[i].cancelled==false){
                MarketOffer memory currentItem = marketOffers[i];
                openOffers[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        
        return openOffers;
    }


    // returns the total number of items sold
    function getItemsSold() public view returns(uint256){
        return _itemsSold.current();
    }
    
    // returns the current number of listed items
    function numberOfItemsListed() public view returns(uint256){
        uint256 unsoldItemCount = _itemIds.current() - (_itemsSold.current()+_itemsCancelled.current());
        return unsoldItemCount;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint8 kind,
        bool hasAmount,
        IERC20 currency,
        uint256 price,
        uint256 flashPrice,
        uint256 startTime,
        uint256 endTime,
        string calldata category
    ) public payable nonReentrant {
        require(price > 0, "No item for free here");
        if (sellerFee > 0) {
            if (address(currency) == address(0)) {
                require(msg.value >= price.mul(sellerFee).div(1000), "You have to pay seller fee");
            } else {
                currency.transferFrom(msg.sender, address(this), price.mul(sellerFee).div(1000));
            }
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            amount,
            payable(msg.sender),
            payable(address(0)), // No owner for the item
            category,
            kind,
            hasAmount,
            currency,
            price,
            false,
            false,
            0
        );        
        idToMarketAuctionItem[itemId] = MarketAuctionItem(
            flashPrice,
            startTime,
            endTime
        );
        if(hasAmount)
            IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        else
            IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        contractToTokenToItemId[nftContract][tokenId].push(itemId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender
        );
    }
    
    // cancels a market item that's for sale
    function cancelMarketItem(uint256 itemId) public {
        require(itemId <=_itemIds.current());
        require(idToMarketItem[itemId].seller==msg.sender);
        require(idToMarketItem[itemId].cancelled==false && idToMarketItem[itemId].isSold==false);
        require(IERC1155(idToMarketItem[itemId].nftContract).balanceOf(address(this), idToMarketItem[itemId].tokenId) > 0); // should never fail
        idToMarketItem[itemId].cancelled=true;
        cancelOffers(itemId);
         _itemsCancelled.increment();
        if(idToMarketItem[itemId].hasAmount)
            IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId, idToMarketItem[itemId].amount, "");
        else
            IERC721(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId);
        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i =0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }

        //TODO emit
    }

    function cancelOffers(uint256 itemId) internal {
        require(idToMarketItem[itemId].isSold || idToMarketItem[itemId].cancelled, "Can't cancel offers.");
        IERC20 currency = idToMarketItem[itemId].currency;
        uint256 offerLength = idToMarketOffers[itemId].length;
        for(uint i = 0; i < offerLength; i++) {
            MarketOffer memory offer = idToMarketOffers[itemId][i];
            if (offer.accepted == false && offer.cancelled == false) {
                address bidder = idToMarketOffers[itemId][i].bidder;
                idToMarketOffers[itemId][i].cancelled = true;
                if (address(currency) == address(0))
                    payable(bidder).transfer(idToMarketOffers[itemId][i].offerAmount);
                else
                    currency.transfer(bidder, idToMarketOffers[itemId][i].offerAmount);
            }
        }
    }

    function createMarketSale(uint256 itemId, uint256 amount)
        public
        payable
        nonReentrant
    {
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(amount > 0 && amount <= idToMarketItem[itemId].amount, "Invalid amount");
        uint256 price = idToMarketItem[itemId].price.div(idToMarketItem[itemId].amount).mul(amount);
        require(
            msg.value >= price,
            "Please make the price to be same as listing price"
        );
        require(idToMarketItem[itemId].isSold==false, "This item is already sold.");
        require(idToMarketItem[itemId].cancelled==false, "This item is not for sale.");
        require(idToMarketItem[itemId].seller!=msg.sender , "Cannot buy your own item.");
        
        //add total volumeTraded
        volumeTraded = volumeTraded + price;

        // take fees and transfer the balance to the seller (TODO)
        uint256 fees = SafeMath.div(price,100).mul(saleFeePercentage);

        if (discountManager!=address(0x0)){
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager).getDiscount(msg.sender);
            fees = fees.div(100).mul(feeDiscountPercent);
        }
        
        uint256 saleAmount = price.sub(fees);
        idToMarketItem[itemId].seller.transfer(saleAmount);
        if(idToMarketItem[itemId].hasAmount)
            IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        else
            IERC721(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].soldAmount = amount;
        idToMarketItem[itemId].buyer = payable(msg.sender);
        _itemsSold.increment();
        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i =0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }

        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].nftContract,
            tokenId,
            idToMarketItem[itemId].seller,
            msg.sender,
            idToMarketItem[itemId].category,
            price
        );
        
        //create new marketitem
        if(amount < idToMarketItem[itemId].amount)
        {
            uint256 newAmount = idToMarketItem[itemId].amount.sub(amount);
            uint256 newPrice = idToMarketItem[itemId].price.sub(price);
            cloneMarketItem(itemId, newAmount, newPrice);
        }
    }

    // returns all of the current items for sale
    // 
    function getMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - (_itemsSold.current()+_itemsCancelled.current());
        uint256 currentIndex = 0;

        MarketItem[] memory marketItems = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].buyer == address(0) && idToMarketItem[i + 1].cancelled==false && idToMarketItem[i + 1].isSold==false) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // returns the purchased items for this user
    function fetchPurchasedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].buyer == msg.sender && idToMarketItem[i + 1].cancelled == false && idToMarketItem[i + 1].isSold == true) {
                itemCount += 1;
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].buyer == msg.sender && idToMarketItem[i + 1].cancelled == false && idToMarketItem[i + 1].isSold == true) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }


    // returns all items created by this user regardless of status (forsale, sold, cancelled)
    function fetchCreateNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender && idToMarketItem[i + 1].cancelled == false && idToMarketItem[i + 1].isSold == true) {
                itemCount += 1; // No dynamic length. Predefined length has to be made
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender && idToMarketItem[i + 1].cancelled == false && idToMarketItem[i + 1].isSold == true) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // Get items by category
    // This could be used with different collections
    function getItemsByCategory(string calldata category)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                itemCount += 1;
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    function getAveragePrice(address nftContract, uint256 tokenId) external view returns(uint256){
        uint256[] storage marketItems = contractToTokenToItemId[nftContract][tokenId];
        uint256 price;
        for(uint i = 0; i < marketItems.length; i++)
        {
            price = price.add(idToMarketItem[marketItems[i]].price);
        }
        return price.div(marketItems.length);
    }
    
    // administration functions
    function setSalePercentageFee(uint256 _amount) public onlyOwner{
        require(_amount<=5, "5% maximum fee allowed.");
        saleFeePercentage = _amount;
    }
    
    function setOwner(address _owner) public onlyOwner{
        require(_owner!=address(0x0), "0x0 address not permitted");
        owner = payable(_owner);
    }
    
    function setDiscountManager(address _discountManager) public onlyOwner{
        require(_discountManager!=address(0x0), "0x0 address not permitted");
        discountManager = _discountManager;
    }
    
    function getItemIDsForToken(address token, uint256 tokenID) external view returns (uint256[] memory){
        return contractToTokenToItemId[token][tokenID];
    }

    function setSellerFee(uint8 _fee) external onlyOwner {
        sellerFee = _fee;
    }

    function withDraw(IERC20 token) external onlyOwner {
        if(address(token) == address(0))
            token.transfer(owner, token.balanceOf(address(this)));
        else
            payable(owner).transfer(payable(address(this)).balance);
    }
}


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


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}