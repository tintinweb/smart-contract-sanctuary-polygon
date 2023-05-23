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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./interfaces/IERC1155Drop.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

contract ERC1155Drop is IERC1155Drop, Ownable, IERC165, IERC1155Receiver {

    /**
     * @dev Data holder for individual drops
     * @param arrayIndex Links back to the index if this drop's tokenId in the _tokenIds array.
     *        This is required to efficiently remove a specific drop again, otherwise we would need to perform a linear search in `_tokenIds`
     * @param price This drop's price in Wei per token
     * @param maxClaimable The maximum amount of tokens if this id that can be purchased
     * @param currentClaimed Track the amount that has already been purchased
     * @param startTime The unix timestamp in seconds after which this drop becomes active
     * @param endTime The unix timestamp in seconds after which this drop closes and no longer allows purchases
     */
    struct DropData {
        uint256 arrayIndex;
        uint256 price;
        uint256 maxClaimable;
        uint256 currentClaimed;
        uint256 startTime;
        uint256 endTime;
    }

    uint256[] _tokenIds;
    mapping(uint256 => DropData)  private _drops;
    // this doesn't need to know the precise implementation, only that it's an ERC1155 contract with the metadata extension
    IERC1155MetadataURI private token;

    constructor(address _token){
        token = IERC1155MetadataURI(_token);
        require(token.supportsInterface(type(IERC1155MetadataURI).interfaceId), "token does not implement metadata interface");
    }

    /**
     * @dev Action to purchase tokens
     * @param recipient The address to transfer tokens to
     * @param tokenIds The token IDs to purchase
     * @param amounts The amounts of each token ID to purchase
     */
    function purchase(address recipient, uint256[] calldata tokenIds, uint256[] calldata amounts) override external payable {
        require(tokenIds.length == amounts.length, "Invalid array sizes");
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalPrice += _purchase(recipient, tokenIds[i], amounts[i]);
        }
        require(totalPrice == msg.value, "payment did not match total price of purchases");
        emit TokensPurchased(recipient, tokenIds, amounts);
    }

    /**
     * @dev Process a single item of a batch purchase.
     * It is important to first modify the drop's `currentClaimed` value before minting the actual token,
     * otherwise we would be prone to reentry attacks, allowing to mint more tokens than intended
     * This method also calculates and returns the price of this purchase. This could be done one level up in the hierarchy, but that would mean multiple storage reads
     * or a more complicated function interface
     * @param recipient The address that should receive the tokens, does not have to be the address paying for this
     * @param tokenId The ERC1155 token id being purchased
     * @param amount The amount of tokens being purchased. The price must be multiplied by this amount
     * @return totalPrice The MATIC amount in Wei that purchasing this token `amount` times cost. i.e. the price multiplied by the amount
     *
     */
    function _purchase(address recipient, uint256 tokenId, uint256 amount) private returns (uint256 totalPrice){
        require(amount > 0, "Can not buy amount of 0");
        DropData storage drop = _getDropData(tokenId);
        require(drop.maxClaimable > 0, "Drop does not exist");
        uint256 remaining = drop.maxClaimable - drop.currentClaimed;
        require(amount <= remaining, "Claim limit reached");
        //TODO validate start and end date
        drop.currentClaimed += amount;
        token.safeTransferFrom(address(this), recipient, tokenId, amount, "");
        return drop.price * amount;
    }

    /**
     * @dev Read metadata about the drops
     * @return An array containing data about all drops currently configured
     */
    function dropData() external view override returns (DropDataView[] memory){
        DropDataView[] memory data = new DropDataView[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            DropData storage entry = _drops[tokenId];
            data[i] = DropDataView(
                tokenId,
                entry.price,
                entry.maxClaimable,
                entry.currentClaimed,
                entry.startTime,
                entry.endTime,
                token.uri(tokenId)
            );
        }
        return data;
    }

    /**
     * @dev Get the address of the ERC1155 contract being dropped, all token ids are scoped to that contract.
     * @return The address of the token contract
     */
    function getToken() external view override returns (address){
        return address(token);
    }

    /**
     * @dev Implementation of `IERC1155Receiver` interface. This is required to fund this contract with tokens.
     *      We only need the `from` param, all others are ignored, but we need to keep the type declaration to be compatible with the interface definition.
     * @param from The address from which we received the tokens. We require this to be 0x0 in order to only accept tokens directly minted to this contract
     */
    function onERC1155Received(
        address /*operator*/,
        address from,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external view returns (bytes4){
        require(msg.sender == address(token), "Only accepting tokens from this drop");
        require(from == address(0), "Only accepting fresh mints");
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Implementation of `IERC1155Receiver` interface. This is required to fund this contract with tokens.
     *      We only need the `from` param, all others are ignored, but we need to keep the type declaration to be compatible with the interface definition.
     * @param from The address from which we received the tokens. We require this to be 0x0 in order to only accept tokens directly minted to this contract
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address from,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external view returns (bytes4){
        require(msg.sender == address(token), "Only accepting tokens from this drop");
        require(from == address(0), "Only accepting fresh mints");
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool){
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function addDrop(uint256 tokenId, uint256 price, uint256 maxClaimable, uint256 startTime, uint256 endTime) external onlyOwner {
        require(_drops[tokenId].maxClaimable == 0, "drop for this tokenId already exists");
        require(maxClaimable > 0, "Can not set maxClaimable to 0");
        require(endTime > startTime, "end time is before start");
        require(token.balanceOf(address(this), tokenId) >= maxClaimable, "Drop does not hold enough tokens of this id. Please first supply a sufficient amount");
        uint256 index = _tokenIds.length;
        _tokenIds.push(tokenId);
        _drops[tokenId] = DropData(
            index,
            price,
            maxClaimable,
            0,
            startTime,
            endTime
        );
    }

    function updateEndTime(uint256 tokenId, uint256 endTime) external onlyOwner {
        DropData storage drop = _getDropData(tokenId);
        require(endTime >= drop.startTime, "End must be after start");
        drop.endTime = endTime;
    }

    function updatePrice(uint256 tokenId, uint256 price) external onlyOwner {
        DropData storage drop = _getDropData(tokenId);
        require(price > 0, "Can not set price to 0");
        drop.price = price;
    }

    function updateStartTime(uint256 tokenId, uint256 startTime) external onlyOwner {
        DropData storage drop = _getDropData(tokenId);
        require(startTime <= drop.startTime, "Start must be before end");
        drop.startTime = startTime;
    }

    function updateMaxClaimable(uint256 tokenId, uint256 claimableAmount) external onlyOwner {
        DropData storage drop = _getDropData(tokenId);
        require(claimableAmount > 0, "Can not set maxClaimable to 0");
        require(claimableAmount >= drop.currentClaimed, "can not set maximum amount below already claimed amount");
        //if we are increasing the amount, first check our balance to ensure the contract is sufficiently funded
        if (claimableAmount > drop.maxClaimable) {
            uint256 newRemaining = claimableAmount - drop.currentClaimed;
            require(token.balanceOf(address(this), tokenId) >= newRemaining, "Drop does not hold enough tokens of this id. Please first supply a sufficient amount");
        }
        drop.maxClaimable = claimableAmount;
    }

    function removeDrop(uint256 tokenId) external onlyOwner{
        //TODO Look up the tokenId in _drops, use arrayIndex to remove the tokenId from _tokenIds and then delete the element from _drops
    }

    function _getDropData(uint256 tokenId) private view returns (DropData storage){
        DropData storage data = _drops[tokenId];
        require(data.maxClaimable > 0, "No drop exists for this token id");
        return data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IERC1155Drop {

    /**
     * @dev Data structure to contain information about a single purchaseable token
     * @param tokenId The token's ERC1155 token id
     * @param price the price per unit denominated in Wei, so a price of 1 Matic would be 10^18
     * @param maxClaimable The maximum amount of tokens allow to be purchased
     * @param currentClaim The amount of tokens that have already been purchased
     * @param startTime A unix timestamp in seconds after which the token can be purchased
     * @param endTime A unix timestamp in seconds after which the drop closes and is no longer purchasable
     * @param metaDataUri The metadata for this token type according to https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions .
     *        If the uri contains the "{id}" placeholder, it must be replaced with the tokenId formatted as hex (without 0x prefix) and padded with leading 0s to be 64 chars
     *        e.g. metadata uri = https://example.com/{id}.json ; tokenId = 42 -> https://example.com/000000000000000000000000000000000000000000000000000000000000002A.json
     */
    struct DropDataView {
        uint256 tokenId;
        uint256 price;
        uint256 maxClaimable;
        uint256 currentClaimed;
        uint256 startTime;
        uint256 endTime;
        string metaDataUri;
    }

    /**
     * @dev Emitted whenever a new purchase is made. Parameters correspond directly to those passed to `purchase`
     */
    event TokensPurchased(address indexed recipient, uint256[] tokenIds, uint256[] amounts);

    /**
     * @dev Action to purchase tokens
     * @param recipient The address to transfer tokens to
     * @param tokenIds The token IDs to purchase
     * @param amounts The amounts of each token ID to purchase
     */
    function purchase(address recipient, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;

    /**
     * @dev Read metadata about the drops
     * @return An array containing data about all drops currently configured
     */
    function dropData() external view returns (DropDataView[] memory);

    /**
     * @dev Get the address of the ERC1155 contract being dropped, all token ids are scoped to that contract.
     * @return The address of the token contract
     */
    function getToken() external view returns (address);
}