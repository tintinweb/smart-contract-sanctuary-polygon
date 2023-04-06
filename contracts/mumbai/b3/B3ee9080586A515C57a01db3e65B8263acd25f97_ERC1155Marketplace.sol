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

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC1155} from "../interfaces/IERC1155.sol";
import {IERC1155Marketplace} from "../interfaces/IERC1155Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing1155, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibErrors.sol";

/**
 * @title ERC1155Marketplace contract
 *
 * @dev EIP-2535 Facet implementation of the multi-token marketplace.
 * See https://eips.ethereum.org/EIPS/eip-2535
 */
contract ERC1155Marketplace is IERC1155Marketplace, Modifiers {
    using LibNFTUtils for address;

    /**
     * @inheritdoc IERC1155Marketplace
     *
     * @dev Function call reverts if an NFT is not approved for the marketplace
     * @dev Previous existing listing would be overwritten with new `quantity` and `price` parameters
     */
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external validValue(quantity) validValue(price) {
        _requireSufficientBalance(msg.sender, nftContract, tokenId, quantity);

        // check item is approved for the marketplace
        _requireIsApprovedForAll(msg.sender, address(this), nftContract);

        Listing1155 memory listing = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        // check item is not listed
        if (listing.price > 0 && listing.quantity == quantity) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        AppStorage.layout().listings1155[nftContract][tokenId] = Listing1155(
            msg.sender,
            price,
            quantity
        );

        emit ERC1155ItemListed(
            msg.sender,
            nftContract,
            tokenId,
            quantity,
            price
        );
    }

    /**
     * @inheritdoc IERC1155Marketplace
     *
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to revert
     * @notice msg.value must be greater or equal to the total price of the `quantity` items
     */
    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable validValue(quantity) {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing1155 memory item = sl.listings1155[nftContract][tokenId];

        // _requireIsListed(listedItem.price);
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
        if (quantity > item.quantity || item.quantity == 0) {
            revert NFTMarket__InsufficientQuantity();
        }

        uint256 totalPrice = item.price * quantity;

        if (msg.value < totalPrice) {
            revert NFTMarket__PriceNotMet(msg.value, totalPrice);
        }

        unchecked {
            uint256 remainingQuantity = item.quantity - quantity;

            if (remainingQuantity == 0) {
                delete sl.listings1155[nftContract][tokenId];
            } else {
                sl
                .listings1155[nftContract][tokenId]
                    .quantity = remainingQuantity;
            }
        }

        // calculate Royalty
        bytes memory royaltyData = nftContract.callRoyalty(tokenId, msg.value);

        if (royaltyData.length != 0) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
                royaltyData,
                (address, uint256)
            );

            if (/* royaltyReceiver != address(0) && */ royaltyAmount != 0) {
                // set royalty fee to collection owner
                unchecked {
                    sl.profits[royaltyReceiver] += royaltyAmount;
                }
            }

            // check royalty amount manipulation
            uint256 sellerTotal = msg.value - royaltyAmount;
            unchecked {
                sl.profits[item.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                sl.profits[item.seller] += msg.value;
            }
        }

        // Trasfer NFTs to buyer
        bytes memory resultData = (item.seller).sendNFTs(
            msg.sender,
            nftContract,
            tokenId,
            quantity
        );

        emit ERC1155ItemBought(
            item.seller,
            msg.sender,
            nftContract,
            tokenId,
            quantity,
            msg.value,
            resultData
        );
    }

    /**
     * @inheritdoc IERC1155Marketplace
     */
    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        Listing1155 memory listedItem = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        _requireIsOwner(msg.sender, listedItem.seller);

        // _requireIsListed(listedItem.price);

        AppStorage.layout().listings1155[nftContract][tokenId].price = newPrice;

        emit ERC1155ItemUpdated(msg.sender, nftContract, tokenId, newPrice);
    }

    /**
     * @inheritdoc IERC1155Marketplace
     */
    function cancelERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external {
        Listing1155 memory listedItem = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        _requireIsOwner(msg.sender, listedItem.seller);

        // _requireIsListed(listedItem.price);

        delete (AppStorage.layout().listings1155[nftContract][tokenId]);

        emit ERC1155ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function _requireSufficientBalance(
        address account,
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) private view {
        if (IERC1155(nftContract).balanceOf(account, tokenId) < quantity) {
            revert NFTMarket__InsufficientBalance();
        }
    }

    function _requireIsApprovedForAll(
        address account,
        address operator,
        address nftContract
    ) private view {
        if (IERC1155(nftContract).isApprovedForAll(account, operator) != true) {
            revert NFTMarket__NotApproved();
        }
    }

    function _requireIsOwner(address account, address seller) private pure {
        if (account != seller) {
            revert NFTMarket__NotOwner();
        }
    }

    /* 
    function _requireIsListed(Listing1155 memory item) private pure {
        if (item.price == 0 || item.seller == address(0)) {
            revert NFTMarket__ItemNotListed(); 
        }
    } 
    */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ERC1155Marketplace interface
 */
interface IERC1155Marketplace {
    /**
     * @notice Emitted when an ERC1155 items(`nftContract`, `tokenId`, `quantity`)
     * owned by `seller` are listed to the marketplace with `price`.
     *
     * Emitted when `price` updates
     */
    event ERC1155ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC1155 items(`nftContract`, `tokenId`, `quantity`)
     * are bought by `buyer` with `price`.
     *
     * Returns result data `returnData` when transfers NFT.
     */
    event ERC1155ItemBought(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        bytes returnData
    );

    /**
     * @notice Emitted when an ERC1155 items (`nftContract`, `tokenId`, `quantity`)
     * owned by `seller` are delisted from the marketplace.
     */
    event ERC1155ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId
    );

    event ERC1155ItemUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 newPrice
    );

    /**
     * @notice Method for listing ERC1155 NFT
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param quantity Quantity of tokens to list
     * @param price Selling price sale price for each item
     *
     * Emits an {ERC1155ItemListed} event.
     */
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external;

    /**
     * @notice Method for buying ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param quantity Quantity of tokens to buy
     *
     * Emits an {ERC1155ItemBought} event.
     */
    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    /**
     * @notice Method for updating ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item to update
     *
     * Emits an {ERC1155ItemListed} event.
     */
    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    /**
     * @notice Method for cancelling ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     *
     * Emits an {ERC1155ItemDelisted} event.
     */
    function cancelERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// ERC721 Listing type
struct Listing721 {
    address seller;
    uint256 price;
}

// ERC1155 Listing type
struct Listing1155 {
    address seller;
    uint256 price; // price per token
    uint256 quantity;
}

library AppStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("NFTMarketApp.contracts.storage.AppStorage");

    struct StorageLayout {
        // Mapping from NFT contract address from token ID to Listing
        mapping(address nftContract => mapping(uint256 tokenId => Listing721)) listings721;
        // Mapping from NFT contract address from token ID to Listing
        mapping(address nftContract => mapping(uint256 tokenId => Listing1155)) listings1155;
        // Mapping seller address to amount earned
        mapping(address account => uint256 balance) profits;
    }

    function layout() internal pure returns (StorageLayout storage sl) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            sl.slot := slot
        }
    }
}

abstract contract Modifiers {
    // Custom error for invalid input
    error NFTMarket__ZeroValue();

    // Modifiers
    modifier validValue(uint256 value) {
        if (value == 0) {
            revert NFTMarket__ZeroValue();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// common ERC721 & ERC1155 errors
error NFTMarket__ItemAlreadyListed();
error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
error NFTMarket__NotOwner();
error NFTMarket__NotApproved();
error NFTMarket__ItemNotListed();

// ERC1155 errors
error NFTMarket__InsufficientBalance();
error NFTMarket__InsufficientQuantity();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Custom error for failed NFT transfer
error NFTMarket__NFTTransferFailed(bytes data);

library LibNFTUtils {
    function sendNFT(
        address from,
        address to,
        address nftContract,
        uint256 tokenId
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                from,
                to,
                tokenId
            )
        );

        return verifyCallResult(nftContract, success, returnData);
    }

    function sendNFTs(
        address from,
        address to,
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                from,
                to,
                tokenId,
                quantity,
                ""
            )
        );

        return verifyCallResult(nftContract, success, returnData);
    }

    function callRoyalty(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.staticcall(
            abi.encodeWithSignature(
                "royaltyInfo(uint256,uint256)",
                tokenId,
                price
            )
        );

        if (!success || returnData.length == 0) return "";

        return returnData;
    }

    function isContract(address account) private view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function verifyCallResult(
        address account,
        bool success,
        bytes memory returndata
    ) private view returns (bytes memory) {
        if (!success) {
            revert NFTMarket__NFTTransferFailed(returndata);
        }
        if (returndata.length == 0 && !isContract(account)) {
            // only check isContract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            revert NFTMarket__NFTTransferFailed(returndata);
        }
        return returndata;
    }
}