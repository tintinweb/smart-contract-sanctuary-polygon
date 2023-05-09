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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IMarketplaceBaseInternal} from "./IMarketplaceBaseInternal.sol";
import {IMarketplaceBaseOwnable} from "./IMarketplaceBaseOwnable.sol";
import {MarketplaceBaseStorage} from "../storage/MarketplaceBaseStorage.sol";

/**
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IMarketplaceBase is IMarketplaceBaseInternal {
    function fee() external view returns (uint104);

    function mintFee() external view returns (uint104);

    function decimals() external view returns (uint8);

    function feeReceipient() external view returns (address);

    function getPayableTokens(
        address token
    ) external view returns (MarketplaceBaseStorage.TokenFeed memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IMarketplaceBaseInternal {
    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address seller,
        address indexed buyer
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMarketplaceBaseOwnable {
    event FeeUpdate(uint104 newFee);
    event MintFeeUpdate(uint104 newMintFee);
    event DecimalsUpdate(uint8 newDecimals);
    event FeeReceipientUpdate(address newAddress);
    event PaymentOptionAdded(address token, address feed, uint8 decimals);
    event PaymentOptionRemoved(address token);

    function setFee(uint104 newFee) external;

    function setMintFee(uint104 newMintFee) external;

    function setDecimals(uint8 newDecimals) external;

    function setFeeReceipient(address newAddress) external;

    function addPayableToken(
        address token,
        address feed,
        uint8 decimals
    ) external;

    function removeTokenFeed(address token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IMarketplaceBase} from "./interfaces/IMarketplaceBase.sol";
import {MarketplaceBaseInternal} from "./MarketplaceBaseInternal.sol";
import {MarketplaceBaseStorage} from "./storage/MarketplaceBaseStorage.sol";

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract MarketplaceBase is MarketplaceBaseInternal, IMarketplaceBase {
    function fee() external view returns (uint104) {
        return _fee();
    }

    function mintFee() external view returns (uint104) {
        return _mintFee();
    }

    function decimals() external view returns (uint8) {
        return _decimals();
    }

    function feeReceipient() external view returns (address) {
        return _feeReceipient();
    }

    function getPayableTokens(
        address token
    ) external view returns (MarketplaceBaseStorage.TokenFeed memory) {
        return _getPayableToken(token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../metatx/ERC2771ContextInternal.sol";

import "./MarketplaceBase.sol";

/**
 * @title Base ERC721A contract with meta-transactions support (via ERC2771).
 */
abstract contract MarketplaceBaseERC2771 is
    MarketplaceBase,
    ERC2771ContextInternal
{
    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771ContextInternal)
        returns (address)
    {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771ContextInternal)
        returns (bytes calldata)
    {
        return ERC2771ContextInternal._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import {IMarketplaceBaseInternal} from "./interfaces/IMarketplaceBaseInternal.sol";
import {MarketplaceBaseStorage} from "./storage/MarketplaceBaseStorage.sol";

/**
 * @title Base Marketplace internal functions, excluding optional extensions
 */
abstract contract MarketplaceBaseInternal is Context, IMarketplaceBaseInternal {
    using MarketplaceBaseStorage for MarketplaceBaseStorage.Layout;

    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    modifier isPayableToken(address _payToken) {
        require(
            _payToken != address(0) &&
                _getPayableToken(_payToken).feed != address(0),
            "invalid pay token"
        );
        _;
    }

    function _fee() internal view virtual returns (uint104) {
        return MarketplaceBaseStorage.layout().sokosFee;
    }

    function _mintFee() internal view virtual returns (uint104) {
        return MarketplaceBaseStorage.layout().mintFee;
    }

    function _decimals() internal view virtual returns (uint8) {
        return MarketplaceBaseStorage.layout().sokosDecimals;
    }

    function _feeReceipient() internal view virtual returns (address) {
        return MarketplaceBaseStorage.layout().feeReceipient;
    }

    function _getPayableToken(
        address token
    ) internal view virtual returns (MarketplaceBaseStorage.TokenFeed memory) {
        return MarketplaceBaseStorage.layout().payableToken[token];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library MarketplaceBaseStorage {
    struct TokenFeed {
        address feed;
        uint8 decimals;
    }

    struct Layout {
        uint104 sokosFee;
        uint104 mintFee;
        uint8 sokosDecimals;
        address payable feeReceipient;
        mapping(address => TokenFeed) payableToken;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("SOKOS.contracts.storage.MarketplaceBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/MarketplaceBaseInternal.sol";
import "./interfaces/IAuctionInternal.sol";
import "./interfaces/IAuctionExtension.sol";
import {AuctionInternal} from "./AuctionInternal.sol";
import {AuctionStorage} from "./storage/AuctionStorage.sol";

abstract contract AuctionExtension is IAuctionExtension, AuctionInternal {
    using AuctionStorage for AuctionStorage.Layout;

    function createAuction(
        address nft,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime
    ) public virtual isPayableToken(payToken) isNotAuction(nft, tokenId) {
        _createAuction(
            nft,
            tokenId,
            payToken,
            price,
            minBid,
            startTime,
            endTime
        );
    }

    function cancelAuction(
        address nft,
        uint256 tokenId
    ) public virtual isAuction(nft, tokenId) {
        _cancelAuction(nft, tokenId);
    }

    function bidPlace(
        address nft,
        uint256 tokenId,
        uint256 bidPrice
    ) public virtual isAuction(nft, tokenId) {
        _bidPlace(nft, tokenId, bidPrice);
    }

    function resultAuction(address nft, uint256 tokenId) public virtual {
        _resultAuction(nft, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../access/ownable/OwnableInternal.sol";
import "../../base/MarketplaceBaseInternal.sol";
import {IAuctionInternal} from "./interfaces/IAuctionInternal.sol";
import {ISokosNFT} from "./interfaces/ISokosNFT.sol";
import {AuctionStorage} from "./storage/AuctionStorage.sol";
import {MarketplaceBaseInternal} from "../../base/MarketplaceBaseInternal.sol";

abstract contract AuctionInternal is
    OwnableInternal,
    IAuctionInternal,
    MarketplaceBaseInternal
{
    using AuctionStorage for AuctionStorage.Layout;

    modifier isAuction(address _nft, uint256 _tokenId) {
        AuctionStorage.AuctionNFT memory auction = AuctionStorage
            .layout()
            .auctionNfts[_nft][_tokenId];
        require(
            auction.nft != address(0) && !auction.success,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        AuctionStorage.AuctionNFT memory auction = AuctionStorage
            .layout()
            .auctionNfts[_nft][_tokenId];
        require(
            auction.nft == address(0) || auction.success,
            "auction already created"
        );
        _;
    }

    function _calculateRoyalty(
        uint256 _royalty,
        uint256 _price
    ) internal pure returns (uint256) {
        return (_price * _royalty) / 10000;
    }

    function _calculatePlatformFee(
        uint256 _price
    ) internal view returns (uint256) {
        return (_price * _fee()) / 10000;
    }

    function _createAuction(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) internal virtual {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == _msgSender(), "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        nft.transferFrom(_msgSender(), address(this), _tokenId);
        AuctionStorage.layout().auctionNfts[_nft][_tokenId] = AuctionStorage
            .AuctionNFT({
                nft: _nft,
                tokenId: _tokenId,
                creator: _msgSender(),
                payToken: _payToken,
                initialPrice: _price,
                minBid: _minBid,
                startTime: _startTime,
                endTime: _endTime,
                lastBidder: address(0),
                heighestBid: _price,
                winner: address(0),
                success: false
            });
        emit CreatedAuction(
            _nft,
            _tokenId,
            _payToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            _msgSender()
        );
    }

    function _cancelAuction(address _nft, uint256 _tokenId) internal virtual {
        AuctionStorage.AuctionNFT memory auction = AuctionStorage
            .layout()
            .auctionNfts[_nft][_tokenId];
        require(auction.creator == _msgSender(), "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.lastBidder == address(0), "already have bidder");
        IERC721 nft = IERC721(_nft);

        nft.transferFrom(address(this), _msgSender(), _tokenId);

        delete AuctionStorage.layout().auctionNfts[_nft][_tokenId];
    }

    function _bidPlace(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) internal virtual {
        AuctionStorage.AuctionNFT memory auction = AuctionStorage
            .layout()
            .auctionNfts[_nft][_tokenId];
        require(block.timestamp >= auction.startTime, "auction not start");
        require(block.timestamp <= auction.endTime, "auction ended");
        require(
            _bidPrice >= auction.heighestBid + auction.minBid,
            "less than min bid price"
        );

        // AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        payToken.transferFrom(_msgSender(), address(this), _bidPrice);

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.heighestBid;

            // Transfer back to last bidder
            payToken.transfer(lastBidder, lastBidPrice);
        }

        // Set new heighest bid price
        auction.lastBidder = _msgSender();
        auction.heighestBid = _bidPrice;

        emit PlacedBid(
            _nft,
            _tokenId,
            auction.payToken,
            _bidPrice,
            _msgSender()
        );
    }

    function _resultAuction(address _nft, uint256 _tokenId) internal virtual {
        AuctionStorage.AuctionNFT memory auction = AuctionStorage
            .layout()
            .auctionNfts[_nft][_tokenId];
        require(!auction.success, "already resulted");
        require(
            _msgSender() == _owner() ||
                _msgSender() == auction.creator ||
                _msgSender() == auction.lastBidder,
            "not creator, winner, or owner"
        );
        require(block.timestamp > auction.endTime, "auction not ended");

        // AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        ISokosNFT sokosNft = ISokosNFT(_nft);
        address royaltyRecipient = sokosNft.getRoyaltyRecipient();
        uint256 royaltyFee = sokosNft.getRoyaltyFee();

        uint256 heighestBid = auction.heighestBid;
        uint256 totalPrice = heighestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = _calculateRoyalty(royaltyFee, heighestBid);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = _calculatePlatformFee(heighestBid);
        payToken.transfer(_feeReceipient(), platformFeeTotal);

        // Transfer to auction creator
        payToken.transfer(auction.creator, totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.heighestBid,
            _msgSender()
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that tracks supply and defines a max supply cap.
 */
interface IAuctionExtension {
    function createAuction(
        address nft,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime
    ) external;

    function cancelAuction(address nft, uint256 tokenId) external;

    function bidPlace(address nft, uint256 tokenId, uint256 bidPrice) external;

    function resultAuction(address nft, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IAuctionInternal {
    error ErrMaxSupplyExceeded();
    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );
    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 bidPrice,
        address indexed bidder
    );
    event ResultedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISokosNFT {
    function getRoyaltyFee() external view returns (uint256);

    function getRoyaltyRecipient() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library AuctionStorage {
    struct AuctionNFT {
        address nft;
        uint256 tokenId;
        address creator;
        address payToken;
        uint256 initialPrice;
        uint256 minBid;
        uint256 startTime;
        uint256 endTime;
        address lastBidder;
        uint256 heighestBid;
        address winner;
        bool success;
    }
    struct ListNFT {
        address nft;
        uint256 tokenId;
        address seller;
        address payToken;
        uint256 price;
        bool sold;
    }

    struct OfferNFT {
        address nft;
        uint256 tokenId;
        address offerer;
        address payToken;
        uint256 offerPrice;
        bool accepted;
    }

    struct Layout {
        // nft => tokenId => acution struct
        mapping(address => mapping(uint256 => AuctionNFT)) auctionNfts;
        // nft => tokenId => list struct
        mapping(address => mapping(uint256 => ListNFT)) listNfts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("SOKOS.contracts.storage.auction");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ListStorage} from "../storage/ListStorage.sol";

interface IListExtension {
    function createListing(
        address tokenAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 startTime,
        uint256 endTime
    ) external;

    function listedNFT(
        uint256 listingId
    ) external view returns (ListStorage.Listing memory);

    function listedNFTs() external view returns (ListStorage.Listing[] memory);

    function listingIds() external view returns (uint256[] memory);

    function listedNFTsByIDs(
        uint256[] calldata ids
    ) external view returns (ListStorage.Listing[] memory);

    function listedNFTbyOwner(
        address owner,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (ListStorage.Listing memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IListInternal {
    event ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 time
    );
    event UpdateListing(
        uint256 indexed listingId,
        address indexed tokenAddress,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 time
    );

    event CancelListing(
        address indexed tokenAddress,
        address indexed owner,
        uint256 tokeId,
        uint256 listingId,
        uint256 time
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/MarketplaceBaseInternal.sol";
import "./interfaces/IListInternal.sol";
import "./interfaces/IListExtension.sol";
import {ListInternal} from "./ListInternal.sol";
import {ListStorage} from "./storage/ListStorage.sol";

abstract contract ListExtension is IListExtension, ListInternal {
    using ListStorage for ListStorage.Layout;

    function createListing(
        address tokenAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 priceInUsd,
        uint256 startTime,
        uint256 endTime
    ) external virtual {
        require(
            startTime < endTime && startTime >= block.timestamp,
            "INVALID_TIME"
        );
        _createListing(
            tokenAddress,
            tokenId,
            quantity,
            priceInUsd,
            startTime,
            endTime
        );
    }

    function cancelListing(
        address tokenAddress,
        uint256 tokenId
    )
        external
        virtual
        isListedNFT(tokenAddress, tokenId, _msgSender())
        returns (bool)
    {}

    function listingIds() external view returns (uint256[] memory) {
        return ListStorage.layout().listingIds;
    }

    function listedNFT(
        uint256 listingId
    ) external view returns (ListStorage.Listing memory) {
        return _listedNFT(listingId);
    }

    function listedNFTs() external view returns (ListStorage.Listing[] memory) {
        return _listedNFTs();
    }

    function listedNFTsByIDs(
        uint256[] calldata ids
    ) external view returns (ListStorage.Listing[] memory) {
        return _listedNFTsByIDs(ids);
    }

    function listedNFTbyOwner(
        address owner,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (ListStorage.Listing memory) {
        return _listedNFTbyOwner(owner, tokenAddress, tokenId);
    }

    function nowTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getListingId(
        address owner,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (uint256) {
        return _getListingId(owner, tokenAddress, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IListInternal} from "./interfaces/IListInternal.sol";
import {ListStorage} from "./storage/ListStorage.sol";
import {OwnableInternal} from "../../../access/ownable/OwnableInternal.sol";
import {MarketplaceBaseInternal} from "../../base/MarketplaceBaseInternal.sol";

// import {ISokosNFT} from "./interfaces/ISokosNFT.sol";

// import {MarketplaceBaseInternal} from "../../base/MarketplaceBaseInternal.sol";

abstract contract ListInternal is
    OwnableInternal,
    IListInternal,
    MarketplaceBaseInternal
{
    using ListStorage for ListStorage.Layout;

    modifier isListedNFT(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) {
        uint256 listingId = _getListingId(_owner, _tokenAddress, _tokenId);
        ListStorage.Listing memory listing = _listedNFT(listingId);
        require(!listing.cancelled && !listing.sold, "NOT_LISTED");
        _;
    }

    function _cancelListing(
        address _tokenAddress,
        uint256 _tokenId,
        address _owner
    ) internal returns (bool) {
        ListStorage.Layout storage l = ListStorage.layout();
        uint256 listingId = l.tokenToListingId[_tokenAddress][_tokenId][_owner];
        for (uint i = 0; i < l.listingIds.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(l.listingIds[i])) ==
                keccak256(abi.encodePacked(listingId))
            ) {
                l.listingIds[i] = l.listingIds[l.listingIds.length + 1];
            }
        }
        l.listingIds.pop();
        delete l.listings[listingId];
        delete l.tokenToListingId[_tokenAddress][_tokenId][_owner];
        emit CancelListing(
            _tokenAddress,
            _owner,
            _tokenId,
            listingId,
            block.timestamp
        );
        return true;
    }

    function _createListing(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _priceInUsd,
        uint256 _startTime,
        uint256 _endTime
    ) internal {
        IERC1155 erc1155Token;
        IERC721 erc721Token;
        bool isERC1155;
        if (IERC165(_tokenAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            erc721Token = IERC721(_tokenAddress);
            require(
                erc721Token.ownerOf(_tokenId) == _msgSender(),
                "Not owning item"
            );
            require(
                erc721Token.isApprovedForAll(_msgSender(), address(this)),
                "Not approved for transfer"
            );
        } else if (
            IERC165(_tokenAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            erc1155Token = IERC1155(_tokenAddress);
            require(
                erc1155Token.balanceOf(_msgSender(), _tokenId) >= _quantity,
                "Not enough ERC1155 token"
            );
            require(
                erc1155Token.isApprovedForAll(_msgSender(), address(this)),
                "Not approved for transfer"
            );
            isERC1155 = true;
        } else {
            revert("INVALID_NFT");
        }

        ListStorage.Layout storage l = ListStorage.layout();

        uint256 listingId = l.tokenToListingId[_tokenAddress][_tokenId][
            _msgSender()
        ];

        if (listingId == 0) {
            uint256 listId = l.nextListingId++;

            l.listingIds.push(listId);
            l.tokenToListingId[_tokenAddress][_tokenId][_msgSender()] = listId;
            l.listings[listId] = ListStorage.Listing({
                listingId: listId,
                seller: _msgSender(),
                tokenAddress: _tokenAddress,
                tokenId: _tokenId,
                quantity: _quantity,
                boughtQuantity: 0,
                priceInUsd: _priceInUsd,
                timeCreated: block.timestamp,
                timeLastPurchased: 0,
                sourceListingId: 0,
                startTime: _startTime,
                endTime: _endTime,
                sold: false,
                cancelled: false,
                isERC1155: isERC1155
            });

            emit ListingAdd(
                listId,
                _msgSender(),
                _tokenAddress,
                _tokenId,
                _quantity,
                _priceInUsd,
                block.timestamp
            );
        } else {
            ListStorage.Listing storage listing = l.listings[listingId];
            listing.quantity = _quantity;
            listing.priceInUsd = _priceInUsd;
            listing.startTime = _startTime;
            listing.endTime = _endTime;
            emit UpdateListing(
                listingId,
                _tokenAddress,
                _quantity,
                _priceInUsd,
                block.timestamp
            );
        }
    }

    function _listedNFT(
        uint256 _listingId
    ) internal view returns (ListStorage.Listing memory) {
        ListStorage.Layout storage l = ListStorage.layout();
        return l.listings[_listingId];
    }

    function _getListingId(
        address _owner,
        address _tokenAddress,
        uint256 _tokenId
    ) internal view returns (uint256) {
        ListStorage.Layout storage l = ListStorage.layout();
        return l.tokenToListingId[_tokenAddress][_tokenId][_owner];
    }

    function _listedNFTbyOwner(
        address _owner,
        address _tokenAddress,
        uint256 _okenId
    ) internal view returns (ListStorage.Listing memory) {
        ListStorage.Layout storage l = ListStorage.layout();
        uint256 listingId = l.tokenToListingId[_tokenAddress][_okenId][_owner];
        return l.listings[listingId];
    }

    function _listedNFTs()
        internal
        view
        returns (ListStorage.Listing[] memory)
    {
        ListStorage.Layout storage l = ListStorage.layout();
        uint256 length = l.listingIds.length;
        ListStorage.Listing[] memory nfts = new ListStorage.Listing[](
            l.listingIds.length
        );
        for (uint i = 0; i < length; i++) {
            ListStorage.Listing storage nft = l.listings[l.listingIds[i]];
            nfts[i] = nft;
        }
        return nfts;
    }

    function _listedNFTsByIDs(
        uint256[] calldata ids
    ) internal view returns (ListStorage.Listing[] memory) {
        ListStorage.Listing[] memory nfts = new ListStorage.Listing[](
            ids.length
        );
        ListStorage.Layout storage l = ListStorage.layout();
        for (uint i = 0; i < ids.length; i++) {
            ListStorage.Listing storage nft = l.listings[ids[i]];
            nfts[i] = nft;
        }
        return nfts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ListStorage {
    struct Listing {
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
        uint256 startTime;
        uint256 endTime;
        bool sold;
        bool cancelled;
        bool isERC1155;
    }
    struct Layout {
        uint256 nextListingId;
        mapping(uint256 => Listing) listings;
        mapping(address => mapping(uint256 => mapping(address => uint256))) tokenToListingId;
        uint256[] listingIds;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("sokos.contracts.storage.listing");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/MarketplaceBaseERC2771.sol";
import {AuctionExtension} from "./extensions/auction/AuctionExtension.sol";
import {ListExtension} from "./extensions/List/ListExtension.sol";
import {MarketplaceBaseInternal} from "./base/MarketplaceBaseInternal.sol";

/**
 * @title Marketplace - with meta-transactions
 * @notice Standard EIP-20 with ability to accept meta transactions (mainly transfer and approve methods).
 *
 * @custom:type eip-2535-facet
 * @custom:category Marketplace
 * @custom:provides-interfaces IMarketplace IMarketplaceBase IAuctionExtension IMarketplaceMintableExtension
 */
contract Marketplace is
    MarketplaceBaseERC2771,
    ListExtension,
    AuctionExtension
{
    function _msgSender()
        internal
        view
        virtual
        override(Context, MarketplaceBaseERC2771)
        returns (address)
    {
        return MarketplaceBaseERC2771._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, MarketplaceBaseERC2771)
        returns (bytes calldata)
    {
        return MarketplaceBaseERC2771._msgData();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(MarketplaceBaseInternal) {
        MarketplaceBaseInternal._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./ERC2771ContextStorage.sol";

abstract contract ERC2771ContextInternal is Context {
    function _isTrustedForwarder(address operator) internal view returns (bool) {
        return ERC2771ContextStorage.layout().trustedForwarder == operator;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC2771ContextStorage {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.ERC2771Context");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}