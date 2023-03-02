// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {AppStorage, ERC1155Listing, Modifiers, TokenFeed, Bid} from "../libraries/LibAppStorage.sol";
import {LibMeta} from "../libraries/LibMeta.sol";
import {LibMarketplace} from "../libraries/LibMarketplace.sol";
import {LibUtils} from "../libraries/LibUtils.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {LibChainlink} from "../libraries/LibChainlink.sol";

contract MarketplaceFacet is Modifiers {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    event RoyaltiesPaid(
        address tokenAddress,
        uint256 tokenId,
        uint256 royaltyAmount
    );
    event PaymentOptionAdded(address _paytoken);
    event PaymentOptionRemoved(address _paytoken);
    event ChangedListingFee(uint256 listingFeeInWei);
    event ERC1155ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 time
    );
    event ERC1155ExecutedListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address erc1155TokenAddress,
        uint256 erc1155TypeId,
        uint256 _quantity,
        uint256 priceInUsd,
        uint256 time
    );
    event ERC1155ExecutedToRecipient(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed recipient
    );
    event UpdateERC1155Listing(
        uint256 indexed listingId,
        address indexed tokenAddress,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 time
    );

    event BidCreated(
        address indexed bidder,
        address indexed tokenAddress,
        uint256 tokenId,
        address payToken,
        uint256 bid,
        uint256 expiresAt
    );

    /// @notice To Get sokos listing fee
    /// @return NFTs listing fee in uint256
    function getListingFee() external view returns (uint256) {
        return s.listingFeeInWei;
    }

    /// @notice To Get Eth value in USD
    /// @param _eth Eth amount in wei
    /// @return Eth value in USD
    function getEthRate(uint256 _eth) public view returns (uint256) {
        uint256 ethPrice = LibChainlink.getPrice(s.ethPriceFeed);
        uint256 ethInUsd = (ethPrice * _eth) / 1e18;
        return ethInUsd;
    }

    /// @notice To Get ERC20 token value in USD
    /// @param _feed chainlink price feed address
    /// @param _cost Number of tokens
    /// @return Token value in USD
    function getTokenRate(address _feed, uint256 _cost)
        public
        view
        returns (uint256)
    {
        require(_feed != address(0), "Invalid feed address");
        uint256 tokenPrice = LibChainlink.getPrice(_feed);
        uint256 priceInUSD = (tokenPrice * _cost) / 1e18;
        return priceInUSD;
    }

    /// @notice To Get ERC20's price feed address
    /// @param _token ERC20 token address
    /// @return tokenFeed struct of ERC20 token's price feed address and decimal
    function getTokenFeed(address _token)
        external
        view
        returns (TokenFeed memory)
    {
        return s.tokenToFeed[_token];
    }

    /// @notice To Get ERC20's price feed address
    /// @return address for eth price feed
    function getEthFeed() external view returns (address) {
        return s.ethPriceFeed;
    }

    function getERC1155ListingId(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) external view returns (uint256) {
        return s.erc1155TokenToListingId[_tokenAddress][_tokenId][_owner];
    }

    function getERC1155Listing(uint256 _listingId)
        external
        view
        returns (ERC1155Listing memory listing_)
    {
        listing_ = s.erc1155Listings[_listingId];
    }

    function getListedIds()
        external
        view
        returns (uint256[] memory listingIds_)
    {
        listingIds_ = s.listingIds;
    }

    /// @notice Method for listing NFT
    /// @param _tokenAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity The amount of NFTs to be listed
    /// @param _priceInUsd The cost price of the NFT
    function createERC1155Listing(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _priceInUsd
    ) external {
        address seller = LibMeta.msgSender();
        IERC1155 erc1155Token = IERC1155(_tokenAddress);

        require(
            erc1155Token.balanceOf(seller, _tokenId) >= _quantity,
            "ERC1155Marketplace: Not enough ERC1155 token"
        );
        require(
            erc1155Token.isApprovedForAll(seller, address(this)),
            "ERC1155Marketplace: Not approved for transfer"
        );

        uint256 listingId = s.erc1155TokenToListingId[_tokenAddress][_tokenId][
            seller
        ];
        if (listingId == 0) {
            uint256 listId = s.nextListingId++;

            s.listingIds.push(listId);
            s.erc1155TokenToListingId[_tokenAddress][_tokenId][seller] = listId;
            s.erc1155Listings[listId] = ERC1155Listing({
                listingId: listId,
                seller: seller,
                tokenAddress: _tokenAddress,
                tokenId: _tokenId,
                quantity: _quantity,
                boughtQuantity: 0,
                priceInUsd: _priceInUsd,
                timeCreated: block.timestamp,
                timeLastPurchased: 0,
                sourceListingId: 0,
                sold: false,
                cancelled: false
            });

            emit ERC1155ListingAdd(
                listId,
                seller,
                _tokenAddress,
                _tokenId,
                _quantity,
                _priceInUsd,
                block.timestamp
            );
        } else {
            ERC1155Listing storage listing = s.erc1155Listings[listingId];
            listing.quantity = _quantity;
            listing.priceInUsd = _priceInUsd;
            emit UpdateERC1155Listing(
                listingId,
                _tokenAddress,
                _quantity,
                _priceInUsd,
                block.timestamp
            );
        }
    }

    ///@notice Allow an ERC1155 owner to cancel his NFT listing through the listingID
    ///@param _listingId The identifier of the listing to be cancelled
    function cancelERC1155Listing(uint256 _listingId) external {
        LibMarketplace.cancelERC1155Listing(_listingId, LibMeta.msgSender());
    }

    ///@notice Allow an ERC1155 owner to cancel his NFT listings through the listingIDs
    ///@param _listingIds An array containing the identifiers of the listings to be cancelled
    function cancelERC1155Listings(uint256[] calldata _listingIds)
        external
        onlyOwner
    {
        for (uint256 i; i < _listingIds.length; i++) {
            uint256 listingId = _listingIds[i];

            ERC1155Listing storage listing = s.erc1155Listings[listingId];
            if (listing.cancelled == true || listing.sold == true) {
                return;
            }
            listing.cancelled = true;
            emit LibMarketplace.ERC1155ListingCancelled(
                listingId,
                block.number
            );
            LibMarketplace.removeERC1155ListingItem(listingId);
        }
    }

    ///@notice Update the ERC1155 listing of an address
    ///@param _tokenAddress Contract address of the ERC1155 token
    ///@param _tokenId Identifier of the ERC1155 token
    ///@param _owner Owner of the ERC1155 token
    function updateERC1155Listing(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) external {
        LibMarketplace.updateERC1155Listing(_tokenAddress, _tokenId, _owner);
    }

    ///@notice Update the ERC1155 listings of an address
    ///@param _tokenAddress Contract address of the ERC1155 token
    ///@param _tokenIds An array containing the identifiers of the ERC1155 tokens to update
    ///@param _owner Owner of the ERC1155 tokens
    function updateBatchERC1155Listing(
        address _tokenAddress,
        uint256[] calldata _tokenIds,
        address _owner
    ) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            LibMarketplace.updateERC1155Listing(
                _tokenAddress,
                _tokenIds[i],
                _owner
            );
        }
    }

    function getBid(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns (Bid memory bid_)
    {
        Bid storage bid = s.bids[_tokenAddress][_tokenId];
        require(
            bid.offerer != address(0),
            "ERC1155Marketplace: bid does not exist"
        );
        bid_ = bid;
    }

    function safePlaceBid(
        uint256 _listingId,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _priceInUsd,
        address _payToken,
        uint256 _expiresAt
    ) external {
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        require(
            listing.quantity == 1 && !listing.sold,
            "ERC1155Marketplace: bidding for allowed"
        );
        require(
            _priceInUsd > listing.priceInUsd,
            "ERC1155Marketplace: bid should be greater than reserve price"
        );

        Bid storage bid = s.bids[_tokenAddress][_tokenId];

        TokenFeed storage tokenFeed = s.tokenToFeed[_payToken];

        require(
            tokenFeed.feed != address(0),
            "ERC1155Marketplace: ERC20 not acceptable"
        );

        uint256 actualCost = listing.priceInUsd;
        uint256 highestBid = bid.price;

        address bidder = LibMeta.msgSender();

        if (bid.offerer != address(0)) {
            if (bid.expiresAt >= block.timestamp) {
                require(
                    _priceInUsd > highestBid,
                    "ERC1155Marketplace: bid price should be higher than last bid"
                );
            }
            require(
                bid.offerer != bidder,
                "ERC1155Marketplace: Can't bid unless someone else has bid"
            );
            LibMarketplace.cancelBid(_tokenAddress, _tokenId, bid);
        }
        IERC20 token = IERC20(_payToken);

        require(
            getTokenRate(
                tokenFeed.feed,
                token.allowance(bidder, address(this))
            ) >= _priceInUsd,
            "ERC1155Marketplace: tokens spend approved not enough"
        );

        token.transferFrom(bidder, address(this), _priceInUsd);

        s.bids[_tokenAddress][_tokenId] = Bid(
            bidder,
            _payToken,
            listing.quantity,
            _priceInUsd,
            _expiresAt,
            _priceInUsd
        );
        emit BidCreated(
            bidder,
            _tokenAddress,
            _tokenId,
            _payToken,
            _priceInUsd,
            _expiresAt
        );
    }

    ///@notice Allow a buyer to execcute an open listing i.e buy the NFT on behalf of the recipient. Also checks to ensure the item details match the listing.
    ///@dev Will throw if the NFT has been sold or if the listing has been cancelled already
    ///@param _listingId The identifier of the listing to execute
    ///@param _tokenAddress The token contract address
    ///@param _tokenId the erc1155 token id
    ///@param _quantity The amount of ERC1155 NFTs execute/buy
    ///@param _payToken The ERC20 token address
    ///@param _recipient the recipient of the item
    function executeERC1155ListingWithERC20(
        uint256 _listingId,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        address _recipient
    ) external {
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        require(
            listing.timeCreated != 0,
            "ERC1155Marketplace: listing not found"
        );
        require(
            listing.sold == false,
            "ERC1155Marketplace: listing is sold out"
        );
        require(
            listing.cancelled == false,
            "ERC1155Marketplace: listing is cancelled"
        );

        require(
            listing.tokenAddress == _tokenAddress,
            "ERC1155Marketplace: Incorrect token address"
        );
        require(
            listing.tokenId == _tokenId,
            "ERC1155Marketplace: Incorrect token id"
        );
        require(_quantity > 0, "ERC1155Marketplace: _quantity can't be zero");
        require(
            _quantity <= listing.quantity,
            "ERC1155Marketplace: quantity is greater than listing"
        );
        address buyer = LibMeta.msgSender();
        address seller = listing.seller;

        require(seller != buyer, "ERC1155Marketplace: buyer can't be seller");

        TokenFeed memory tokenFeed = s.tokenToFeed[_payToken];

        require(
            tokenFeed.feed != address(0),
            "ERC1155Marketplace: ERC20 not acceptable"
        );
        uint256 costInWei = getTokenRate(
            tokenFeed.feed,
            _quantity *
                (listing.priceInUsd *
                    (10**(tokenFeed.decimals - s.sokosDecimals)))
        );
        //  10 USD
        require(
            IERC20(_payToken).balanceOf(buyer) >= costInWei,
            string(
                abi.encodePacked(
                    "ERC1155Markrtplace: not enough ",
                    LibUtils.toAsciiString(_payToken)
                )
            )
        );
        require(
            IERC20(_payToken).allowance(buyer, address(this)) >= costInWei,
            "ERC1155Marketplace: tokens spend approved not enough"
        );

        uint256 fee = s.sokosFee;
        uint256 netCost = costInWei - fee;

        if (IERC2981(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC2981)) {
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(
                _tokenAddress
            ).royaltyInfo(_tokenId, costInWei);
            require(royaltiesReceiver != address(0), "Address Zero");
            if (royaltiesAmount > 0) {
                LibERC20.transferFrom(
                    _payToken,
                    buyer,
                    royaltiesReceiver,
                    royaltiesAmount
                );
                costInWei -= royaltiesAmount;
                emit RoyaltiesPaid(_tokenAddress, _tokenId, royaltiesAmount);
            }
        }

        LibERC20.transferFrom(_payToken, buyer, s.feeReceipient, fee);
        LibERC20.transferFrom(_payToken, buyer, seller, netCost);

        listing.quantity -= _quantity;
        listing.boughtQuantity += _quantity;
        listing.timeLastPurchased = block.timestamp;

        if (listing.quantity == 0) {
            listing.sold = true;
            LibMarketplace.removeERC1155ListingItem(_listingId);
        }

        IERC1155(listing.tokenAddress).safeTransferFrom(
            seller,
            _recipient,
            listing.tokenId,
            _quantity,
            new bytes(0)
        );

        emit ERC1155ExecutedListing(
            _listingId,
            seller,
            _recipient,
            listing.tokenAddress,
            listing.tokenId,
            _quantity,
            listing.priceInUsd,
            block.timestamp
        );

        //Only emit if buyer is not recipient
        if (buyer != _recipient) {
            emit ERC1155ExecutedToRecipient(_listingId, buyer, _recipient);
        }
    }

    ///@notice Allow a buyer to execcute an open listing i.e buy the NFT on behalf of the recipient. Also checks to ensure the item details match the listing.
    ///@dev Will throw if the NFT has been sold or if the listing has been cancelled already
    ///@param _listingId The identifier of the listing to execute
    ///@param _tokenAddress The token contract address
    ///@param _tokenId the erc1155 token id
    ///@param _quantity The amount of ERC1155 NFTs execute/buy
    ///@param _priceInUsd the cost price of the ERC1155 NFTs individually
    ///@param _recipient the recipient of the item
    function executeERC1155ListingWithEth(
        uint256 _listingId,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _priceInUsd,
        address _recipient
    ) external {
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        require(
            listing.timeCreated != 0,
            "ERC1155Marketplace: listing not found"
        );
        require(
            listing.sold == false,
            "ERC1155Marketplace: listing is sold out"
        );
        require(
            listing.cancelled == false,
            "ERC1155Marketplace: listing is cancelled"
        );
        require(
            _priceInUsd == listing.priceInUsd,
            "ERC1155Marketplace: wrong price or price changed"
        );
        require(
            listing.tokenAddress == _tokenAddress,
            "ERC1155Marketplace: Incorrect token address"
        );
        require(
            listing.tokenId == _tokenId,
            "ERC1155Marketplace: Incorrect token id"
        );
        require(_quantity > 0, "ERC1155Marketplace: _quantity can't be zero");
        require(
            _quantity <= listing.quantity,
            "ERC1155Marketplace: quantity is greater than listing"
        );
        address buyer = LibMeta.msgSender();
        address seller = listing.seller;
        require(seller != buyer, "ERC1155Marketplace: buyer can't be seller");

        // uint256 cost = _quantity * _priceInUsd;

        // {
        //     if (IERC2981(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC2981)) {
        //         (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(_tokenAddress).royaltyInfo(_tokenId, cost);
        //         if (royaltiesAmount > 0) {
        //             LibERC20.transferFrom(_payToken, buyer, royaltiesReceiver, royaltiesAmount);
        //             cost -= royaltiesAmount;
        //             emit RoyaltiesPaid(_tokenAddress, _tokenId, royaltiesAmount);
        //         }
        //         uint256 netCost = cost - s.sokosFee;

        //         LibERC20.transferFrom(_payToken, buyer, s.feeReceipient, s.sokosFee);

        //         LibERC20.transferFrom(_payToken, buyer, seller, netCost);
        //     }

        //     listing.quantity -= _quantity;
        //     listing.boughtQuantity += _quantity;
        //     listing.timeLastPurchased = block.timestamp;
        //     if (listing.quantity == 0) {
        //         listing.sold = true;
        //         LibMarketplace.removeERC1155ListingItem(_listingId);
        //     }
        // }
        IERC1155(listing.tokenAddress).safeTransferFrom(
            seller,
            _recipient,
            listing.tokenId,
            _quantity,
            new bytes(0)
        );

        emit ERC1155ExecutedListing(
            _listingId,
            seller,
            _recipient,
            listing.tokenAddress,
            listing.tokenId,
            _quantity,
            listing.priceInUsd,
            block.timestamp
        );

        //Only emit if buyer is not recipient
        if (buyer != _recipient) {
            emit ERC1155ExecutedToRecipient(_listingId, buyer, _recipient);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISokosRegistry {
    function sokosMaticPriceFeed() external view returns (address);

    function sokosPriceFeed() external view returns (address);

    function isSokosNFT(address _nft) external view returns (bool);

    function createCollection(
        string memory _name,
        string memory _symbol,
        bool _isPublic
    ) external returns (address);

    function marketplace() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISokosRegistry} from "../interfaces/ISokosRegistry.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

/// @notice Structure for listed items
struct Listing {
    uint256 quantity;
    uint256 price;
    uint256 startingTime;
    uint256 expiresAt;
    bool isERC1155;
}

/// @notice Structure for Bid offer
struct Offer {
    address offerer;
    IERC20 payToken;
    uint256 quantity;
    uint256 price;
    uint256 expiresAt;
    uint256 paidTokens;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address tokenAddress;
    uint256 tokenId;
    uint256 quantity;
    uint256 boughtQuantity;
    uint256 priceInUsd;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}

struct Bid {
    address offerer;
    address payToken;
    uint256 quantity;
    uint256 price;
    uint256 expiresAt;
    uint256 paidAmount;
}

struct TokenFeed {
    address feed;
    uint8 decimals;
}

struct AppStorage {
    ///////////////////////////////////////////
    /// @notice Root
    ///////////////////////////////////////////
    mapping(address => bool) itemManagers;
    ///////////////////////////////////////////
    /// @notice MetaTx
    ///////////////////////////////////////////
    mapping(address => uint256) metaNonces;
    bytes32 domainSeparator;
    ///////////////////////////////////////////
    /// @notice Marketplace
    ///////////////////////////////////////////
    uint16 sokosFee;
    uint8 sokosDecimals;
    uint256 mintFee;
    address payable feeReceipient;
    address ethPriceFeed;
    mapping(address => TokenFeed) tokenToFeed;
    mapping(address => mapping(uint256 => Bid)) bids;
    uint256 listingFeeInWei;
    uint256 nextListingId;
    mapping(uint256 => ERC1155Listing) erc1155Listings;
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc1155TokenToListingId;
    uint256[] listingIds;
}

library LibAppStorage {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyItemManager() {
        address sender = LibMeta.msgSender();
        require(s.itemManagers[sender] == true, "LibAppStorage: only an ItemManager can call this function");
        _;
    }
    modifier onlyOwnerOrItemManager() {
        address sender = LibMeta.msgSender();
        require(
            sender == LibDiamond.contractOwner() || s.itemManagers[sender] == true,
            "LibAppStorage: only an Owner or ItemManager can call this function"
        );
        _;
    }

    function getSokosDecimals() public view returns (uint8) {
        return s.sokosDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

library LibChainlink {
    function getPrice(address _priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(_priceFeed)
            .latestRoundData();
        return
            uint256(answer) *
            (10**(18 - AggregatorV3Interface(_priceFeed).decimals()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
        );
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(
                    abi.decode(_result, (bool)),
                    "LibERC20: transfer or transferFrom returned false"
                );
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibAppStorage, AppStorage, ERC1155Listing, Modifiers, TokenFeed, Bid} from "./LibAppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";

library LibMarketplace {
    event PaymentOptionAdded(address _paytoken);
    event PaymentOptionRemoved(address _paytoken);
    event ERC1155ListingCancelled(uint256 indexed listingId, uint256 time);
    event ERC1155ListingRemoved(uint256 indexed listingId, uint256 time);
    event UpdateERC1155Listing(
        uint256 indexed listingId,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 time
    );
    event BidCancelled(
        address indexed bidder,
        address indexed tokenAddress,
        uint256 tokenId
    );

    function setTokenFeed(
        address _token,
        address _feed,
        uint8 _decimals
    ) internal {
        AppStorage storage s = LibAppStorage.getStorage();

        s.tokenToFeed[_token] = TokenFeed({feed: _feed, decimals: _decimals});
        emit PaymentOptionAdded(_token);
    }

    function removeTokenFeed(address _token) internal {
        AppStorage storage s = LibAppStorage.getStorage();

        delete s.tokenToFeed[_token];
        emit PaymentOptionRemoved(_token);
    }

    function cancelERC1155Listing(uint256 _listingId, address _owner) internal {
        AppStorage storage s = LibAppStorage.getStorage();
        ERC1155Listing storage listing = s.erc1155Listings[_listingId];
        if (listing.cancelled == true || listing.sold == true) {
            return;
        }
        require(listing.seller == _owner, "Marketplace: owner not seller");
        listing.cancelled = true;
        emit ERC1155ListingCancelled(_listingId, block.timestamp);
        removeERC1155ListingItem(_listingId);
    }

    function removeERC1155ListingItem(uint256 _listingId) internal {
        AppStorage storage s = LibAppStorage.getStorage();
        delete s.erc1155Listings[_listingId];
        for (uint256 i; i < s.listingIds.length; i++) {
            uint256 listing = s.listingIds[i];
            if (listing == _listingId) {
                s.listingIds[i] = s.listingIds[s.listingIds.length - 1];
                s.listingIds.pop();
            }
        }
        emit ERC1155ListingRemoved(_listingId, block.timestamp);
    }

    function updateERC1155Listing(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) internal {
        AppStorage storage s = LibAppStorage.getStorage();
        uint256 listingId = s.erc1155TokenToListingId[_tokenAddress][_tokenId][
            _owner
        ];
        if (listingId == 0) {
            return;
        }
        ERC1155Listing storage listing = s.erc1155Listings[listingId];
        if (
            listing.timeCreated == 0 ||
            listing.cancelled == true ||
            listing.sold == true
        ) {
            return;
        }
        uint256 quantity = listing.quantity;
        if (quantity > 0) {
            quantity = IERC1155(listing.tokenAddress).balanceOf(
                listing.seller,
                listing.tokenId
            );
            if (quantity < listing.quantity) {
                listing.quantity = quantity;
                emit UpdateERC1155Listing(
                    listingId,
                    quantity,
                    listing.priceInUsd,
                    block.timestamp
                );
            }
        }
        if (quantity == 0) {
            cancelERC1155Listing(listingId, listing.seller);
        }
    }

    function cancelBid(
        address _tokenAddress,
        uint256 _tokenId,
        Bid storage bid
    ) internal {
        AppStorage storage s = LibAppStorage.getStorage();
        IERC20(bid.payToken).transfer(bid.offerer, bid.paidAmount);
        emit BidCancelled(bid.offerer, _tokenAddress, _tokenId);
        delete s.bids[_tokenAddress][_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"
            )
        );

    function domainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32 domainSeparator_)
    {
        domainSeparator_ = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibUtils {
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}