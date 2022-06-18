// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IMoaCultivation.sol";
import "./IMoaMarketplace.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract MoaMarketplace is IMoaMarketplace, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsRevoke;
    
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(address => mapping(uint256 => uint256)) private getItemIdFromAddress;


    modifier isMarketItemSeller(
        address nftAddress,
        uint256 itemId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address _itemSeller = idToMarketItem[itemId].seller;
        address _owner = nft.ownerOf(idToMarketItem[itemId].tokenId);

        require(_itemSeller == spender);
        require(_owner == spender);
        _; 
    }

    //Prevent donate item being duplicate in the donateItem list
    modifier isUnqiueMarketItem(address _nftAddress, uint256 _tokenId) {
        uint256 _itemId = getItemIdFromAddress[_nftAddress][_tokenId];
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        require((_marketItem.itemId == 0) || (_marketItem.itemId != 0 && _marketItem.sold != false)  || (_marketItem.itemId != 0 && _marketItem.revoke != false), "already exists");
        _;
    }

    function createMarketItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) public override isUnqiueMarketItem(_nftContract, _tokenId) payable nonReentrant {
        require(_price > 0, "Price must be greater than 0");
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Sender does not own the NFT"); 
        require(IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)) == true, "Marketplace not the operator of the tokenId");

        _itemIds.increment();
        uint256 _itemId = _itemIds.current();

        idToMarketItem[_itemId] = MarketItem({
            itemId: _itemId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: payable(msg.sender),
            owner: payable(address(0)),
            price: _price,
            sold: false,
            revoke: false
        });

        getItemIdFromAddress[_nftContract][_tokenId] = _itemId;

        emit MarketItemCreated(
            _itemId,
            _nftContract,
            _tokenId,
            msg.sender,
            address(0),
            _price,
            false,
            false
        );
    }

    function createMarketSale(
        uint256 itemId
        ) public override payable nonReentrant {

            require(_exists(itemId) == true);
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            address nftContract = idToMarketItem[itemId].nftContract;
            address seller = idToMarketItem[itemId].seller;
            bool sold = idToMarketItem[itemId].sold;

            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This Sale has alredy finnished");

            // Transfer the receviced eth to seller
            idToMarketItem[itemId].seller.transfer(msg.value);

            // Transfer the MoA ownership to sender
            IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);

            // Update the owner
            idToMarketItem[itemId].owner = payable(msg.sender);

            // Increase the itemSold counter
            _itemsSold.increment();

            // Update the MarketItem to sold true
            idToMarketItem[itemId].sold = true;

            emit MarketItemSold(
                itemId,
                msg.sender
            );
    }

    function revokeMarketItem(
        address _nftContract,
        uint256 _itemId
    ) public
      override
      isMarketItemSeller(_nftContract, _itemId, msg.sender) 
      nonReentrant 
    {
        require(_exists(_itemId) == true);
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        // only on-sale item can be de-listing
        require(_marketItem.sold == false);
        
        // Effect
        _marketItem.revoke = true;
        _itemsRevoke.increment();

        // Event
        emit MarketItemRevoke(_itemId);
    }

    function updateMarketItem(
        address _nftContract,
        uint256 _itemId,
        uint256 _price
    ) public
      override 
      isMarketItemSeller(_nftContract, _itemId, msg.sender) 
      nonReentrant
    {
        require(_exists(_itemId) == true);
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        // Only on-sale item can be update
        // Check the item is listing on sale
        require(_marketItem.sold == false && _marketItem.revoke == false);
        require(_price > 0, "Price must be greater than 0");

        // Effect
        _marketItem.price = _price;

        // Event
        emit MarketItemUpdate(_itemId, _price);
    }
        
    function fetchSaleMarketItems() public override view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint onsaleItemCount = _itemIds.current() - _itemsSold.current() - _itemsRevoke.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](onsaleItemCount);
        for (uint i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (idToMarketItem[i + 1].sold == false && idToMarketItem[i + 1].revoke == false) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchSoldMarketItems() public override view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint soldItemCount = _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](soldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            // Check the market item is sold
            if (idToMarketItem[i + 1].sold == true && idToMarketItem[i + 1].owner != address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchRevokeMarketItems() public override view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint revokeItemCount = _itemsRevoke.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](revokeItemCount);
        for (uint i = 0; i < itemCount; i++) {
            // Check the market item is revoked
            if (idToMarketItem[i + 1].revoke == true && idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getMarketItemByTokenId(
        address _nftContract,
        uint256 _tokenId
    ) public view override  returns (uint256) {
        return getItemIdFromAddress[_nftContract][_tokenId];
    }

    function balanceOf(
        address _address
    ) public view override returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            // Check the market item is revoked
            if (idToMarketItem[i + 1].seller == _address) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function ownerOf(
        uint256 _itemId
    ) public view override returns (address) {
        require(_exists(_itemId));
        return idToMarketItem[_itemId].owner;
    }

    function sellerOf(
        uint256 _itemId
    ) public view override returns (address) {
        require(_exists(_itemId));
        return idToMarketItem[_itemId].seller;
    }

    function _exists(uint256 _itemId) internal view virtual returns (bool) {
        return idToMarketItem[_itemId].seller != address(0);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IMoaMarketplace {
    /// @dev event 
    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool revoke
    );

    event MarketItemSold(uint indexed itemId, address owner);
    
    event MarketItemRevoke(uint indexed itemId); 

    event MarketItemUpdate(uint indexed itemId, uint256 updated); 

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool revoke;
    }

    /// @dev create a market item for sale
    /// the NFT will be approved the marketplace as operator to call transfer
    /// emit MarketItemCreated event 
    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) external payable;

    /// @dev sale a market item to buyer
    /// the marketplace will collect payment and transfer the market item to buyer
    /// emit MarketItemSold event
    function createMarketSale(uint256 itemId) external payable;

    /// @dev revoke a market item
    /// remove the market item from markerItemIds
    /// remove the approval of the tokenId
    function revokeMarketItem(address nftContract, uint256 tokenId) external;

    function updateMarketItem(address _nftContract,uint256 _itemId, uint256 _price) external;

    /// @dev Fetch on-sale market items
    function fetchSaleMarketItems() external view returns (MarketItem[] memory);

    /// @dev Fetch Sold market items
    function fetchSoldMarketItems() external view returns (MarketItem[] memory);

    ///@dev Fetch Revoke market items 
    function fetchRevokeMarketItems() external view returns (MarketItem[] memory);

    /// @dev Find itemId by tokenId and NFT address
    function getMarketItemByTokenId(address _nftContract, uint256 _tokenId) external view returns (uint256);

    /// @dev get balance of target address
    function balanceOf(address _address) external view returns (MarketItem[] memory);

    /// @dev get owner address of target item ID
    function ownerOf(uint256 itemId) external view returns (address);

    /// @dev get seller address of target item ID
    function sellerOf(uint256 itemId) external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IMoaCultivation {
    event Cultivation(address indexed  owner, uint256 indexed  matronId, uint256 indexed  sireId);
    event CompleteCultivation(address indexed owner, uint256 indexed babyId, uint256 indexed babyGenes);
    event AutoBirth(uint256 indexed matronId, uint256 indexed cooldownEndTime); 

    /// @dev update the autoBirthFee
    function setAutoBirthFee(uint256 _autoBirthFee) external;

    function setGeneScienceAddress(address _address) external;

    /// @dev start a Cultivation process between 2 MoA.
    ///  always AutoBirth now
    function startCultivation(uint256 _matronId, uint256 _sireId)
        external
        payable returns (uint64);

    /// @dev end a Cultivation process and a new MoA is born!
    function completeCultivation(uint256 _matronId) external returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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