// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC721Marketplace} from "../interfaces/IERC721Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing721, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibErrors.sol";

/**
 * @title ERC721Marketplace contract
 *
 * @dev EIP-2535 Facet implementation of the ERC721 marketplace.
 * See https://eips.ethereum.org/EIPS/eip-2535
 */
contract ERC721Marketplace is IERC721Marketplace, Modifiers {
    using LibNFTUtils for address;

    /**
     * @inheritdoc IERC721Marketplace
     *
     * @notice Function call reverts if an NFT is not approved for the marketplace
     */
    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        // check the owner of an item
        _requireIsOwner(msg.sender, nftContract, tokenId);

        // check item is approved for the marketplace
        _requireIsApproved(address(this), nftContract, tokenId);

        Listing721 memory item = AppStorage.layout().listings721[nftContract][
            tokenId
        ];

        // check item is not listed
        if (item.price > 0 || item.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        AppStorage.layout().listings721[nftContract][tokenId] = Listing721(
            msg.sender,
            price
        );

        emit ERC721ItemListed(msg.sender, nftContract, tokenId, price);
    }

    /**
     * @inheritdoc IERC721Marketplace
     *
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to revert
     */
    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing721 memory item = sl.listings721[nftContract][tokenId];

        _requireIsListed(item);

        if (msg.value < item.price) {
            revert NFTMarket__PriceNotMet(msg.value, item.price);
        }

        delete sl.listings721[nftContract][tokenId];

        // calculate Royalty
        bytes memory royaltyData = nftContract.callRoyalty(tokenId, msg.value);

        if (royaltyData.length != 0) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
                royaltyData,
                (address, uint256)
            );

            if (/* royaltyReceiver != address(0) && */ royaltyAmount != 0) {
                // Transfer royalty fee to collection owner
                unchecked {
                    sl.profits[royaltyReceiver] += royaltyAmount;
                }
            }

            // checked royalty amount manipulation
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

        // Trasfer NFT from seller
        bytes memory resultData = (item.seller).sendNFT(
            msg.sender,
            nftContract,
            tokenId
        );

        emit ERC721ItemBought(
            item.seller,
            msg.sender,
            nftContract,
            tokenId,
            msg.value,
            resultData
        );
    }

    /**
     * @inheritdoc IERC721Marketplace
     */
    function updateERC721Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        _requireIsOwner(msg.sender, nftContract, tokenId);

        _requireIsListed(AppStorage.layout().listings721[nftContract][tokenId]);

        AppStorage.layout().listings721[nftContract][tokenId].price = newPrice;

        emit ERC721ItemUpdated(msg.sender, nftContract, tokenId, newPrice);
    }

    /**
     * @inheritdoc IERC721Marketplace
     */
    function cancelERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external {
        _requireIsOwner(msg.sender, nftContract, tokenId);

        _requireIsListed(AppStorage.layout().listings721[nftContract][tokenId]);

        delete (AppStorage.layout().listings721[nftContract][tokenId]);

        emit ERC721ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function _requireIsOwner(
        address account,
        address nftContract,
        uint256 tokenId
    ) private view {
        if (IERC721(nftContract).ownerOf(tokenId) != account) {
            revert NFTMarket__NotOwner();
        }
    }

    function _requireIsApproved(
        address target,
        address nftContract,
        uint256 tokenId
    ) private view {
        if (IERC721(nftContract).getApproved(tokenId) != target) {
            revert NFTMarket__NotApproved();
        }
    }

    function _requireIsListed(Listing721 memory item) private pure {
        if (item.price == 0 || item.seller == address(0)) {
            revert NFTMarket__ItemNotListed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ERC721Marketplace interface
 */
interface IERC721Marketplace {
    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is listed to the marketplace with `price`.
     * Emitted when `price` updates
     */
    event ERC721ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) is bought by `buyer` with `price`.
     * Returns result data `returnData` when trasfers NFT.
     */
    event ERC721ItemBought(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        bytes returnData
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is updated with new params.
     */
    event ERC721ItemUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is delisted from the marketplace.
     */
    event ERC721ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId
    );

    /**
     * @notice Method for listing ERC721 NFT
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */
    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    /**
     * @notice Method for buying ERC721 listing
     * @param nftContract Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable;

    /**
     * @notice Method for updating ERC721 listing
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateERC721Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    /**
     * @notice Method for cancelling ERC721 listing
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     */
    function cancelERC721Listing(address nftContract, uint256 tokenId) external;
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