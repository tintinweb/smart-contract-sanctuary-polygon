// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMoaMarketplace.sol";


contract MoaMarketplace is Context, IMoaMarketplace, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsRevoke;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() {}

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(address => mapping(uint256 => uint256)) private getItemIdFromAddress;

    modifier isMarketItemSeller(
        uint256 itemId,
        address spender
    ) {
        require(idToMarketItem[itemId].seller == spender);
        _; 
    }

    /// @dev Prevent market item being duplicate
    /// @dev TODO: check _msgSender() against seller, we shall not stop new NFT owner to make sale
    modifier isUnqiueMarketItem(address _nftAddress, uint256 _tokenId) {
        uint256 _itemId = getItemIdFromAddress[_nftAddress][_tokenId];
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        require((_marketItem.itemId == 0) || (_marketItem.itemId != 0 && _marketItem.sold != false)  || (_marketItem.itemId != 0 && _marketItem.revoke != false), "already exists");
        _;
    }

    /// Check if NFT contract implemented royalties (ERC2981)
    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function listForSale(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint _salesDays
    ) public override isUnqiueMarketItem(_nftContract, _tokenId) nonReentrant {
        require(_price > 0, "Price must be greater than 0");
        require(_salesDays > 0, "On Sales item at least available for 1 day");
        require(_salesDays <= 60, "On Sales item at most available for 60 days");
        require(IERC721(_nftContract).ownerOf(_tokenId) == _msgSender(), "Not owner"); 
        require(IERC721(_nftContract).isApprovedForAll(_msgSender(), address(this)) == true, "Marketplace not the operator of the tokenId");

        _itemIds.increment();
        uint256 _itemId = _itemIds.current();

        idToMarketItem[_itemId] = MarketItem({
            itemId: _itemId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: payable(_msgSender()),
            owner: payable(address(0)),
            price: _price,
            sold: false,
            revoke: false,
            salesDays: _salesDays,
            salesFinishTime: uint64(block.timestamp + (_salesDays * 1 days))
        });

        getItemIdFromAddress[_nftContract][_tokenId] = _itemId;

        emit MarketItemCreated(
            _itemId,
            _nftContract,
            _tokenId,
            _msgSender(),
            address(0),
            _price,
            false,
            false,
            uint64(_salesDays),
            uint64(block.timestamp + (_salesDays * 1 days))
        );
    }

    /// @dev _msgSender() to buy an item
    function buy(
        uint256 _itemId
    ) public override payable nonReentrant {
        require(_exists(_itemId) == true);
        uint256 price = idToMarketItem[_itemId].price;
        uint256 tokenId = idToMarketItem[_itemId].tokenId;
        address nftContract = idToMarketItem[_itemId].nftContract;
        address seller = idToMarketItem[_itemId].seller;
        uint64 salesFinishTime = idToMarketItem[_itemId].salesFinishTime;
        bool sold = idToMarketItem[_itemId].sold;
        bool revoke = idToMarketItem[_itemId].revoke;
        require(IERC721(nftContract).ownerOf(tokenId) == seller); // the seller still owns the NFT
        require(IERC721(nftContract).isApprovedForAll(_msgSender(), address(this)) == true); // our contract is still an operator

        require(sold != true, "The item is sold");
        require(revoke != true, "Sale cancalled");
        require(salesFinishTime >= block.timestamp, "Sale expired");
        require(msg.value >= price, "Insufficient value");

        // Update the MarketItem record
        idToMarketItem[_itemId].owner = payable(_msgSender());  // Record the (new) owner
        idToMarketItem[_itemId].sold = true; // set the MarketItem to sold = true
        // Increase the itemSold counter
        _itemsSold.increment();

        // Interactions:
        // Check NFT has royalty implemented
        // if implmented, royaltyAmount will be transfered to the receiver
        if (checkRoyalties(nftContract) == true) {
            (address _receiver, uint256 _royaltyAmount) = IERC2981(nftContract).royaltyInfo(tokenId, price);
            require(_royaltyAmount < price); // safe-guard

            if(_royaltyAmount > 0){ // needed to pay royalty
                address payable royaltyReceiver = payable(address(_receiver));
                royaltyReceiver.transfer(_royaltyAmount);
                idToMarketItem[_itemId].seller.transfer(SafeMath.sub(msg.value, _royaltyAmount));

                emit RoyaltyTransfer(_receiver, _royaltyAmount);
            } else {
                // Transfer all receviced value to seller
                idToMarketItem[_itemId].seller.transfer(msg.value);
            }
        } else {
            // Transfer the receviced value to seller
            idToMarketItem[_itemId].seller.transfer(msg.value);
        }

        // Transfer the MoA ownership to sender
        IERC721(nftContract).safeTransferFrom(seller, _msgSender(), tokenId);

        emit MarketItemSold(
            _itemId,
            nftContract,
            tokenId,
            price,
            seller,
            _msgSender()
        );
    }

    function revokeSale(
        uint256 _itemId
    ) public
      override
      isMarketItemSeller(_itemId, _msgSender()) 
      nonReentrant 
    {
        require(_exists(_itemId) == true);
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        // only on-sale item can be de-listing
        require(_marketItem.sold == false);
        
        // Effects
        _marketItem.revoke = true;
        _itemsRevoke.increment();

        // Event
        emit MarketItemRevoke(_itemId, _marketItem.nftContract, _marketItem.tokenId, _msgSender());
    }

    function updateSale(
        uint256 _itemId,
        uint256 _price,
        uint _extraSalesDays
    ) public
      override
      isMarketItemSeller(_itemId, _msgSender())
      nonReentrant
    {
        require(_exists(_itemId) == true);
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        uint256 tokenId = _marketItem.tokenId;
        address nftContract = _marketItem.nftContract;
        // Only on-sale item can be update
        // Check the item is listing on sale
        require(_marketItem.sold == false && _marketItem.revoke == false);
        require(_price > 0, "Price must be greater than 0");
        require(_marketItem.salesDays + _extraSalesDays <= 60, 'At most 60 days.'); // TODO: why not simply replace the salesDays and update salesFinishTime?
        require(IERC721(nftContract).ownerOf(tokenId) == _msgSender()); // the seller still owns the NFT

        // Effect
        _marketItem.price = _price;
        _marketItem.salesDays += _extraSalesDays;
        _marketItem.salesFinishTime += uint64(_extraSalesDays * 1 days); 

        // Event
        emit MarketItemUpdate(_itemId, nftContract, tokenId, _price, _msgSender(), _marketItem.salesDays, _marketItem.salesFinishTime);
    }

    function getItemId(
        address _nftContract,
        uint256 _tokenId
    ) public view override  returns (uint256) {
        return getItemIdFromAddress[_nftContract][_tokenId];
    }

    function getItem(uint256 _itemId)
        public
        view
        override
        returns (MarketItem memory)
    {
        require(_exists(_itemId), "Not exists");
        return idToMarketItem[_itemId];
    }

    function _exists(uint256 _itemId) internal view virtual returns (bool) {
        return idToMarketItem[_itemId].seller != address(0);
    }

    /// @dev withdraw funds from this contract, for whatever reason that it have some balance
    function withdraw(address to, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount);
        payable(to).transfer(amount);
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
        bool revoke,
        uint salesDays,
        uint64 salesFinishTime
    );

    event MarketItemSold(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address owner
    );

    event MarketItemRevoke(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller
    );

    event MarketItemUpdate(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 updatedPrice,
        address seller,
        uint updatedSalesDays,
        uint64 updatedSalesFinishTime
    );

    event RoyaltyTransfer(address indexed receiver, uint256 royaltyFee);

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool revoke;
        uint salesDays;
        uint64 salesFinishTime;
    }

    /// @dev create a market item for sale
    /// @dev the NFT will be approved the marketplace as operator to call transfer
    /// @dev emit MarketItemCreated event
    function listForSale(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint _salesLastDays
    ) external;

    /// @dev sale a market item to buyer
    /// @dev the marketplace will collect payment and transfer the market item to buyer
    /// @dev emit MarketItemSold event
    function buy(uint256 _itemId) external payable;

    /// @dev revoke a market item
    function revokeSale(uint256 _itemId) external;

    function updateSale(
        uint256 _itemId,
        uint256 _price,
        uint _extraSalesDays
    ) external;

    /// @dev Find itemId by tokenId and NFT address
    function getItemId(address _nftContract, uint256 _tokenId)
        external
        view
        returns (uint256);

    /// @dev get sale item details
    function getItem(uint256 _itemId) external view returns (MarketItem memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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