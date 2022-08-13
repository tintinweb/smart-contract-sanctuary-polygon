/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

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


// File contracts/Market.sol

// License-Identifier: MIT
pragma solidity ^0.8.4;
/// @title Market
/// @author Alberto Lalanda
/// @notice NFT marketplace NFT to buy/sell NumbersNFT with the NumbersToken
/// @notice The marketplace can be deployed with another NFT and token contracts
contract Market is IERC721Receiver, Ownable {
    address public immutable NUM_NFT;
    address public immutable NUM_TOKEN;

    struct Listing {
        uint256 activeIndexes; // uint128(activeListingIndex),uint128(userActiveListingIndex)
        uint256 tokenId;
        uint256 price;
        address owner;
    }

    mapping(uint256 => Listing) public listings;

    uint256[] public listingsArray; // list of listingIDs tokens being sold
    mapping(address => uint256[]) public userListings; // list of listingIDs which are active and belong to the user

    /*///////////////////////////////////////////////////////////////
                       MARKET MANAGEMENT SETTINGS
    //////////////////////////////////////////////////////////////*/
    uint256 public marketFeePercent;
    bool public isMarketOpen;
    bool public emergencyDelisting;

    /*///////////////////////////////////////////////////////////////
                        MARKET GLOBAL STATISTICS
    //////////////////////////////////////////////////////////////*/
    uint256 public totalVolume;
    uint256 public totalSales;
    uint256 public highestSalePrice;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event AddListingEv(uint256 indexed tokenId, uint256 price, address seller);
    event UpdateListingEv(uint256 tokenId, uint256 price);
    event CancelListingEv(uint256 tokenId);
    event FulfillListingEv(uint256 tokenId, address buyer);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error Percentage0to100();
    error ClosedMarket();
    error InvalidListing();
    error InactiveListing();
    error InvalidOwner();
    error NoActiveListings();
    error WrongIndex();
    error OnlyEmergency();
    error ZeroAddress();
    error NoFundsToWithdraw();

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address nft_address,
        uint256 market_fee,
        address token_address
    ) {
        if (nft_address == address(0x0)) revert ZeroAddress();
        if (token_address == address(0x0)) revert ZeroAddress();

        if (market_fee > 100) {
            revert Percentage0to100();
        }

        NUM_TOKEN = token_address;
        NUM_NFT = nft_address;

        marketFeePercent = market_fee;
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function openMarket() external onlyOwner {
        if (emergencyDelisting) {
            emergencyDelisting = false;
        }
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        if (newMarketFee > 100) {
            revert Percentage0to100();
        }

        marketFeePercent = newMarketFee;
    }

    // If something goes wrong, we can close the market and enable emergencyDelisting
    //    After that, anyone can delist active listings
    function emergencyDelist(uint256[] calldata listingIDs) external {
        if (!(emergencyDelisting && !isMarketOpen)) revert OnlyEmergency();

        uint256 len = listingIDs.length;
        for (uint256 i; i < len; ++i) {
            uint256 id = listingIDs[i];
            Listing memory listing = listings[id];
            removeListing(listing.activeIndexes >> (8 * 16));
            removeUserListing(
                listing.owner,
                uint256(uint128(listing.activeIndexes))
            );

            //listings[id].active = false;
            IERC721(NUM_NFT).transferFrom(
                address(this),
                listing.owner,
                listing.tokenId
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAWALS
    //////////////////////////////////////////////////////////////*/
    function withdrawNUM() external onlyOwner {
        uint256 balance = IERC20(NUM_TOKEN).balanceOf(address(this));
        if (balance <= 0) {
            revert NoFundsToWithdraw();
        }
        bool sent = IERC20(NUM_TOKEN).transfer(msg.sender, balance);
        require(sent, "Token transfer failed");
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS READ OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function totalListings() public view returns (uint256) {
        return listingsArray.length;
    }

    function getListing(uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[tokenId];
    }

    function getAllListings() external view returns (Listing[] memory listing) {
        return getListings(0, listingsArray.length);
    }

    function getListings(uint256 from, uint256 length)
        public
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 listingsLength = listingsArray.length;
            if (from + length > listingsLength) {
                length = listingsLength - from;
            }

            Listing[] memory _listings = new Listing[](length);
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[listingsArray[from + i]];
            }
            return _listings;
        }
    }

    function getMyListingsCount() external view returns (uint256) {
        return userListings[msg.sender].length;
    }

    function getAllMyListings()
        external
        view
        returns (Listing[] memory listing)
    {
        return getMyListings(0, userListings[msg.sender].length);
    }

    function getMyListings(uint256 from, uint256 length)
        public
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 myListingsLength = userListings[msg.sender].length;

            if (from + length > myListingsLength) {
                length = myListingsLength - from;
            }

            Listing[] memory myListings = new Listing[](length);
            for (uint256 i; i < length; ++i) {
                myListings[i] = listings[userListings[msg.sender][i + from]];
            }
            return myListings;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LISTINGS STORAGE MANIPULATION
    //////////////////////////////////////////////////////////////*/

    /// Moves the last element to the one to be removed
    function removeListing(uint256 index) internal {
        uint256 numActive = listingsArray.length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = listingsArray[numActive - 1];

            listingsArray[index] = listingID;

            listings[listingID].activeIndexes =
                uint256(index << (8 * 16)) |
                uint128(listings[listingID].activeIndexes);
        }
        listingsArray.pop();
    }

    /// Moves the last element to the one to be removed
    function removeUserListing(address user, uint256 index) internal {
        uint256 numActive = userListings[user].length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = userListings[user][numActive - 1];

            userListings[user][index] = listingID;

            listings[listingID].activeIndexes =
                (listings[listingID].activeIndexes &
                    (type(uint256).max << (8 * 16))) |
                uint128(index);
        }
        userListings[user].pop();
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function addListing(uint256 _tokenId, uint256 _price) external {
        if (!isMarketOpen) revert ClosedMarket();

        uint256[] storage _senderActiveListings = userListings[msg.sender];

        listings[_tokenId] = Listing(
            (listingsArray.length << (8 * 16)) |
                uint128(_senderActiveListings.length),
            _tokenId,
            _price,
            msg.sender
        );

        _senderActiveListings.push(_tokenId);
        listingsArray.push(_tokenId);

        emit AddListingEv(_tokenId, _price, msg.sender);
        IERC721(NUM_NFT).transferFrom(msg.sender, address(this), _tokenId);
    }

    function updateListing(uint256 tokenId, uint256 price) external {
        if (!isMarketOpen) revert ClosedMarket();

        Listing storage listing = listings[tokenId];
        if (listing.owner == address(0)) revert InvalidListing();
        if (listing.owner != msg.sender) revert InvalidOwner();

        listing.price = price;
        emit UpdateListingEv(tokenId, price);
    }

    function cancelListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];

        if (listing.owner == address(0)) revert InvalidListing();
        if (listing.owner != msg.sender) revert InvalidOwner();

        removeListing(listing.activeIndexes >> (8 * 16));
        removeUserListing(msg.sender, uint256(uint128(listing.activeIndexes)));

        delete listings[tokenId];

        emit CancelListingEv(tokenId);

        IERC721(NUM_NFT).transferFrom(
            address(this),
            listing.owner,
            listing.tokenId
        );
    }

    function fulfillListing(uint256 tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();

        Listing memory listing = listings[tokenId];
        if (listing.owner == address(0)) revert InvalidListing();

        delete listings[tokenId];

        if (msg.sender == listing.owner) revert InvalidOwner();

        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(NUM_NFT)
            .royaltyInfo(listing.tokenId, listing.price);

        // Update active listings
        removeListing(listing.activeIndexes >> (8 * 16));
        removeUserListing(
            listing.owner,
            uint256(uint128(listing.activeIndexes))
        );

        // Update global stats
        unchecked {
            totalVolume += listing.price;
            totalSales += 1;
        }

        if (listing.price > highestSalePrice) {
            highestSalePrice = listing.price;
        }

        uint256 marketFee = (listing.price * marketFeePercent) / 100;

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            listing.owner,
            listing.price - royaltyAmount - marketFee
        );

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            royaltyReceiver,
            royaltyAmount
        );

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            address(this),
            marketFee
        );

        emit FulfillListingEv(tokenId, msg.sender);

        IERC721(NUM_NFT).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function onERC721Received(
        address, //_operator,
        address, //_from,
        uint256, //_id,
        bytes calldata //_data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}