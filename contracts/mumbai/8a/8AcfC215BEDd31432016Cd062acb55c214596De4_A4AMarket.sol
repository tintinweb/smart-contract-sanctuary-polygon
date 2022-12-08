// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.1;

import "./IERC721_A4A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract A4AMarket is Ownable, IERC721Receiver {

    address private a4A_NFT_address;
    IERC721_A4A a4A_items;
    address payable private _a4A_wallet;
    uint256 public _itemsForSale;

    mapping(uint256 => uint256) private _listedITemsPrice;
    mapping(uint256 => address) private _listedITemsOwner;
    mapping(uint256 => bool) private _notFirstSale;

    event ItemListed(uint256 tokenId, address seller, uint256 price, address author, uint256 itemsForSale);
    event ItemDelisted(uint256 tokenId, address seller, uint256 price, address author, uint256 itemsForSale);

    event ItemSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event ItemSoldOffchain(uint256 tokenId, address buyer, address seller, uint256 price, address author, uint256 authorFee);
    event ItemPriceUpdated(uint256 itemID, address owner, address sender, uint256 itemPrice, address author);

    modifier onlyOwnerOrA4A(uint256 itemID) {
        require( _listedITemsOwner[itemID] == _msgSender() || owner() == _msgSender(), "Sender is not authorized." );
        _;
    }

    constructor(address _a4A_NFT_address) {
        _a4A_wallet = payable(_msgSender());
        a4A_NFT_address = _a4A_NFT_address;
        a4A_items = IERC721_A4A(a4A_NFT_address);
    }


    function listItem(uint256 itemID, uint256 price) external {
        require( a4A_items.ownerOf(itemID) == _msgSender(), "Only owner can list items for sale.");
        //Save NFT price & owner
        _listedITemsPrice[itemID] = price;
        _listedITemsOwner[itemID] = a4A_items.ownerOf(itemID);

        a4A_items.safeTransferFrom(_msgSender(), address(this), itemID);

        _itemsForSale++;

        emit ItemListed(itemID, _msgSender(), _listedITemsPrice[itemID], a4A_items.author(itemID), _itemsForSale);
    }

    function listAnyItem(uint256 itemID, uint256 price) external onlyOwner {
        //Save NFT price & owner
        _listedITemsPrice[itemID] = price;
        address itemOwner = a4A_items.ownerOf(itemID);
        _listedITemsOwner[itemID] = itemOwner;

        a4A_items.safeTransferFrom(itemOwner, address(this), itemID);

        _itemsForSale++;

        emit ItemListed(itemID, itemOwner, _listedITemsPrice[itemID], a4A_items.author(itemID), _itemsForSale);
    }

    function delistItem(uint256 itemID) external onlyOwnerOrA4A(itemID) {

        a4A_items.safeTransferFrom(address(this), _listedITemsOwner[itemID], itemID);
        _removeSaleData(itemID);

        emit ItemDelisted(itemID, _listedITemsOwner[itemID], _listedITemsPrice[itemID], a4A_items.author(itemID), _itemsForSale);
    }

    function buyItem(uint256 itemID) external payable {
        require(_listedITemsPrice[itemID] > 0 && _listedITemsOwner[itemID] != address(0), "Item is not for sale (price = 0).");

        //Check payment
        uint256 _itemPrice = _listedITemsPrice[itemID];
        require(msg.value == _itemPrice, "Price and paid amount do not match.");

        address seller = _listedITemsOwner[itemID];
        require(seller != address(0), "Seller cannot be address 0.");

        //////////////////////////////////

        //Fees
        uint256 _firstSaleFee1; // Fee for beneficiary 1 [First sale]
        uint256 _nextSalesFee1; // Fee for beneficiary 1 (Next sales
        uint256 _firstSaleFee2; // Fee for beneficiary 2 [First sale}
        uint256 _nextSalesFee2; // Fee for beneficiary 2 (Nsext sales)
        uint256 sellerAmt = _itemPrice;

        //Calculate author fee
        uint256 authorFee = a4A_items.authorFee(itemID);

        if (authorFee > 0){
            uint256 authorAmt = (authorFee * _itemPrice) / 100;
            (bool sentAuthortFee, ) = payable( a4A_items.author(itemID)).call{value: authorAmt}("");
            require(sentAuthortFee, "Failed to send BNB fee to the Author.");
            sellerAmt -= authorAmt;
        }


        if(_notFirstSale[itemID]){ //Not firs sale (next sale...)

          uint256 _nextA4aFee = a4A_items.nextA4aFee(itemID);
          if (_nextA4aFee > 0){
              uint256 fee = (_nextA4aFee * _itemPrice) / 100;
              (bool sentFee, ) = _a4A_wallet.call{value: fee}("");
              require(sentFee, "Failed to send fee to A4A.");
              sellerAmt -= fee;
          }

          _nextSalesFee1 = a4A_items.nextSalesFee1(itemID);
          if (_nextSalesFee1 > 0){
              address _receiver1 = a4A_items.saleReceiver1(itemID);
              uint256 fee1 = (_nextSalesFee1 * _itemPrice) / 100;
              (bool sentFee1, ) = _receiver1.call{value: fee1}("");
              require(sentFee1, "Failed to send fee to the fee receiver 1.");
              sellerAmt -= fee1;
          }

          _nextSalesFee2 = a4A_items.nextSalesFee2(itemID);
          if (_nextSalesFee2 > 0){
              address _receiver2 = a4A_items.saleReceiver2(itemID);
              uint256 fee2 = (_nextSalesFee2 * _itemPrice) / 100;
              (bool sentFee2, ) = _receiver2.call{value: fee2}("");
              require(sentFee2, "Failed to send fee to the fee receiver 2.");
              sellerAmt -= fee2;
          }

        }
        else {  //The firs sale

          uint256 _firstA4aFee = a4A_items.firstA4aFee(itemID);
          if (_firstA4aFee > 0){
              uint256 fee = (_firstA4aFee * _itemPrice) / 100;
              (bool sentFee, ) = _a4A_wallet.call{value: fee}("");
              require(sentFee, "Failed to send fee to A4A.");
              sellerAmt -= fee;
          }

          _firstSaleFee1 = a4A_items.firstSaleFee1(itemID);
          if (_firstSaleFee1 > 0){
              address _receiver1 = a4A_items.saleReceiver1(itemID);
              uint256 ffee1 = (_firstSaleFee1 * _itemPrice) / 100;
              (bool sentMarketFee, ) = _receiver1.call{value: ffee1}("");
              require(sentMarketFee, "Failed to send fee to the fee receiver 1.");
              sellerAmt -= ffee1;

          }

          _firstSaleFee2 = a4A_items.firstSaleFee2(itemID);
          if (_firstSaleFee2 > 0){
              address _receiver2 = a4A_items.saleReceiver2(itemID);
              uint256 ffee2 = (_firstSaleFee2 * _itemPrice) / 100;
              (bool sentMarketFee, ) = _receiver2.call{value: ffee2}("");
              require(sentMarketFee, "Failed to send fee to the fee receiver 2.");
              sellerAmt -= ffee2;
          }

          _notFirstSale[itemID] = true;

        }

        //Send seller's amount, after fees
        (bool sentValue, ) = seller.call{value: sellerAmt}("");
        require(sentValue, "Failed to send the amount to the seller.");

        //Transfer NFT to the buyer
        a4A_items.safeTransferFrom(address(this), _msgSender(), itemID);

        //check New owner
        require(a4A_items.ownerOf(itemID) == _msgSender(), "New owner not assigned.");

        emit ItemSold(itemID, a4A_items.ownerOf(itemID), seller, _itemPrice);
        _removeSaleData(itemID);

    }

    function takeItemForBuyer(uint256 itemID, address receiver) external payable onlyOwner {
        require(_listedITemsPrice[itemID] > 0 && _listedITemsOwner[itemID] != address(0), "Item is not for sale (price = 0).");

        address seller = _listedITemsOwner[itemID];
        uint256 _itemPrice = _listedITemsPrice[itemID];

        //Transfer NFT to the buyer
        a4A_items.safeTransferFrom(address(this), receiver, itemID);
        //check New owner
        require(a4A_items.ownerOf(itemID) == receiver, "New owner not assigned.");

        _removeSaleData(itemID);

        emit ItemSoldOffchain(itemID, a4A_items.ownerOf(itemID), seller, _itemPrice, a4A_items.author(itemID), a4A_items.authorFee(itemID));

    }

    function updateItemPrice(uint256 itemID, uint256 newPrice) external onlyOwnerOrA4A(itemID) {
        _listedITemsPrice[itemID] = newPrice;

        emit ItemPriceUpdated(itemID, a4A_items.ownerOf(itemID), _msgSender(), newPrice, a4A_items.author(itemID));

    }

    function _removeSaleData(uint256 itemID) internal {
        _listedITemsPrice[itemID] = 0;
        _listedITemsOwner[itemID] = address(0);
        _itemsForSale--;
    }

    function itemsForSale() external view returns(uint256){
        return _itemsForSale;
    }

    function isItemForSale(uint256 itemID) external view returns(bool){
        return (_listedITemsPrice[itemID] > 0 ||  _listedITemsOwner[itemID] == address(0));
    }

    function ownerOfItem(uint256 itemID) external view returns(address){
        return _listedITemsOwner[itemID];
    }

    function itemPrice(uint256 itemID) external view returns(uint256){
        return _listedITemsPrice[itemID];
    }

    function setA4AWallet(address payable wallet) external onlyOwner {
        _a4A_wallet = wallet;
    }

/*
    function setA4Afee(uint256 fee) external onlyOwner {
        _marketFee = fee;
    }
*/

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IRoyalties {

    function author(uint256 tokenID) external view returns(address);
    function authorFee(uint256 tokenID) external view returns(uint256);

    function firstA4aFee(uint256 tokenId) external view returns(uint256);
    function setFirstA4aFee(uint256 tokenId, uint256 fee) external;

    function nextA4aFee(uint256 tokenId) external view returns(uint256);
    function setNextA4aFee(uint256 tokenId, uint256 fee) external;

    function firstSaleFee1(uint256 tokenId) external view returns(uint256);
    function setFirstSaleFee1(uint256 tokenId, uint256 fee) external;

    function nextSalesFee1(uint256 tokenId) external view returns(uint256);
    function setNextSalesFee1(uint256 tokenId, uint256 fee) external;

    function saleReceiver1(uint256 tokenId) external view returns(address);
    function setSaleReceiver1(uint256 tokenId, uint256 fee) external;

    function firstSaleFee2(uint256 tokenId) external view returns(uint256);
    function setFirstSaleFee2(uint256 tokenId, uint256 fee) external;

    function nextSalesFee2(uint256 tokenId) external view returns(uint256);
    function setNextSalesFee2(uint256 tokenId, uint256 fee) external;

    function saleReceiver2(uint256 tokenId) external view returns(address);
    function setSaleReceiver2(uint256 tokenId, uint256 fee) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IRoyalties.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721_A4A is IERC165, IRoyalties {
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