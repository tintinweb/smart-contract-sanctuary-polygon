/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
// SPDX-License-Identifier: Unlicensed
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// File contracts/interfaces/IERC721Creators.sol

pragma solidity ^0.8.0;

interface IERC721Creators is IERC721 {
    /**
     * @dev Returns the creators of the token
     */
    function getTokenCreators(uint256 _tokenId) external view returns (address[] memory);
}


// File contracts/Marketplace.sol

pragma solidity ^0.8.1;



contract Marketplace is ReentrancyGuard, IERC721Receiver {

    uint256 private itemIds;
    uint256 public constant CREATORS_PERCENTAGE = 20;

    struct Item {
        uint256 itemId;
        IERC721Creators nftContract;
        uint256 tokenId;
        address payable seller;
        bool listed;
        bool sold;
        uint256 amount;
    }

    mapping(uint256 => Item) private itemsMapping;
    mapping(address => uint256) private creatorsFees;

    event Sell(uint256 itemId, address nftContract, uint256 tokenId, address buyer, uint256 amount);
    event List(uint256 itemId, address nftContract, uint256 tokenId, address seller, uint256 amount);
    event Unlist(uint256 itemId, address nftContract, uint256 tokenId, address seller);
    event FeesCollected(address creator, uint256 amount);

    function buy(uint256 _itemId) external payable nonReentrant {
        require(_isExistingItem(_itemId), "Invalid item ID");
        Item storage item = itemsMapping[_itemId];
        require(msg.value == item.amount, "Send the exact amount of the listing");
        require(item.sold == false, "Item is sold");
        require(item.listed == true, "Item is no longer listed");
        
        item.sold = true;
        IERC721Creators nftContract = item.nftContract;
        address [] memory creators = nftContract.getTokenCreators(item.tokenId);
    
        uint256 creatorsAmount = _saveCreatorsFees(creators, item.amount);
        uint256 sellerAmount = item.amount - creatorsAmount;

        assert(sellerAmount > 0 && sellerAmount <= item.amount);
        item.seller.transfer(sellerAmount);
        nftContract.safeTransferFrom(address(this), msg.sender, item.tokenId);

        emit Sell(item.itemId, address(item.nftContract), item.tokenId, msg.sender, item.amount);
    }

    function listToken(IERC721Creators _nftContract, uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_price > 0, "Price for sell should be greater than 0");
        require(_nftContract.ownerOf(_tokenId) == msg.sender, "Sender is not owner of the NFT");
        require(_nftContract.getApproved(_tokenId) == address(this), "Approval not given");
        
        itemIds++;
        uint256 itemId = itemIds;
        Item memory newItem = Item(itemId, _nftContract, _tokenId, payable(msg.sender), true, false, _price);
        itemsMapping[itemId] = newItem;

        _nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit List(itemId, address(_nftContract), _tokenId, msg.sender, _price);
    }

    function unlistToken(uint256 _itemId) external nonReentrant {
        require(_isExistingItem(_itemId), "Item does not exist");
        Item storage item = itemsMapping[_itemId];
        require(item.seller == msg.sender, "Only the seller can unlist the token");
        require(item.sold == false, "Item is sold");
        require(item.listed == true, "Item is unlisted");

        item.listed = false;

        item.nftContract.safeTransferFrom(address(this), item.seller, item.tokenId);

        emit Unlist(item.itemId, address(item.nftContract), item.tokenId, item.seller);
    }

    function collectFees() external nonReentrant {
        require(creatorsFees[msg.sender] > 0, "No fees to collect");
        uint256 amount = creatorsFees[msg.sender];

        creatorsFees[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit FeesCollected(msg.sender, amount);
    }
    
    function pendingFees() external view returns (uint256){
        return creatorsFees[msg.sender];
    }

    function getItem(uint256 _itemId) external view returns (Item memory) {
        return itemsMapping[_itemId];
    }

    function listedItems() external view returns (Item[] memory){
        uint256 toBeReturned = 0;

        for(uint256 i=1; i<= itemIds; i++){
            Item memory item = itemsMapping[i];
            if(item.listed == true && item.sold == false){
                toBeReturned++;
            }
        }

        Item[] memory items = new Item[](toBeReturned);
        uint256 index = 0;

        for(uint256 i=1; i<= itemIds; i++){
            Item memory item = itemsMapping[i];
            if(item.listed == true && item.sold == false){
                items[index] = item;
                index++;
            }
        }

        return items;
    }

    function userListedItems(address _user) external view returns (Item[] memory){
        uint256 toBeReturned = 0;

        for(uint256 i=1; i<= itemIds; i++){
            Item memory item = itemsMapping[i];
            if(item.seller == _user){
                toBeReturned++;
            }
        } 

        Item[] memory items = new Item[](toBeReturned);
        uint256 index = 0;

        for(uint256 i=1; i<= itemIds; i++){
            Item memory item = itemsMapping[i];
            if(item.seller == _user){
                items[index] = item;
                index++;
            }
        }

        return items;       
    }

    function _isExistingItem(uint256 _itemId) internal view returns (bool) {
        return _itemId > 0 && itemsMapping[_itemId].itemId != 0;
    }

    function _getCreatorsAmount(uint256 _amount) internal pure returns(uint256) {
        return (_amount * CREATORS_PERCENTAGE) / 100;
    }

    function _saveCreatorsFees(address[] memory _creators, uint256 _itemAmount) internal returns (uint256){
        if(_creators.length == 0){
            return 0;
        }

        uint256 creatorsAmount = _getCreatorsAmount(_itemAmount);
        uint256 individualAmount = creatorsAmount / _creators.length;
        uint256 remainder = creatorsAmount % _creators.length;
        assert( individualAmount > 0 && individualAmount * _creators.length + remainder == creatorsAmount);

        for(uint256 i=0; i < _creators.length; i++){
            creatorsFees[_creators[i]] += individualAmount;
        }

        return creatorsAmount;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4){
        return this.onERC721Received.selector;
    }
}