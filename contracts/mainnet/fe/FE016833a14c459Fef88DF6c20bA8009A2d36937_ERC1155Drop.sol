// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC1155Drop.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "../openzeppelin-contracts/contracts/utils/Address.sol";

contract ERC1155Drop is IERC1155Drop, Ownable, IERC165, IERC1155Receiver {

    /**
     * @dev Data holder for individual drops
     * @param arrayIndex Links back to the index if this drop's tokenId in the _tokenIds array.
     *        This is required to efficiently remove a specific drop again, otherwise we would need to perform a linear search in `_tokenIds`
     * @param price This drop's price in Wei per token
     * @param maxClaimable The maximum amount of tokens of this id that can be purchased
     * @param currentClaimed Tracks the amount that has already been purchased
     * @param startTime The unix timestamp in seconds after which this drop becomes active
     * @param endTime The unix timestamp in seconds after which this drop closes and no longer allows purchases. Alternatively we use 0 as special value to mark an open-ended sale
     */
    struct DropData {
        uint256 arrayIndex;
        uint256 price;
        uint256 maxClaimable;
        uint256 currentClaimed;
        uint64 startTime;
        uint64 endTime;
    }

    /**
     * @dev Contains all token ids currently set up in this drop. This helps enumerating them for frontend display
     *      This must be synchronized with the related _drops mapping
     */
    uint256[] private _tokenIds;

    /**
     * @dev Contains drop configurations, i.e. price, amount, time bounds for each drop uniquely identified by the token id
     *      This must be synchronized with the related _tokenIds array
     */
    mapping(uint256 => DropData)  private _drops;

    /**
     * @dev The ERC1155 token contract containing all tokens being dropped, this is used to eventually transfer tokens upon purchase and to retrieve metadata
     *      We don't need to know the precise implementation, only that it's an ERC1155 contract with the metadata extension
     */
    IERC1155MetadataURI private token;

    /**
     * @dev The address eventually receiving all payments made to purchase tokens in this drop. This can be a simple address but will most likely be a PaymentSplitter
     *      to securely share revenue between all involved parties
     */
    address payable private paymentReceiver;

    /**
     * @dev Constructor; validates the initial setup of the token contract and payment receiver. Neither of these can be changed  later on
     * @param _token The address of the ERC1155 token being dropped
     * @param _paymentReceiver The address/contract eventually receiving all MATIC that was received from purchases.
     */
    constructor(address _token, address payable _paymentReceiver) {
        require(_paymentReceiver != address(0x0), "payment receiver can not be 0x0");
        token = IERC1155MetadataURI(_token);
        require(token.supportsInterface(type(IERC1155MetadataURI).interfaceId), "token does not implement metadata interface");
        paymentReceiver = _paymentReceiver;
    }

    /**
     * @dev Function to call when purchasing tokens. A MATIC value must be attached to the transaction.
     *      It is validated that this value matches the exact overall price determined by the token ids and amounts specified, i.e. it is not acceptable to overpay and expect "change"
     * @param recipient The address to transfer tokens to
     * @param tokenIds The token IDs to purchase
     * @param amounts The amounts of each token ID to purchase
     */
    function purchase(address recipient, uint256[] calldata tokenIds, uint256[] calldata amounts) override external payable {
        require(tokenIds.length == amounts.length, "Invalid array sizes");
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 amount = amounts[i];
            DropData storage drop = _getDropData(tokenIds[i]);
            processPurchase(drop, amount);
            totalPrice += amount * drop.price;
        }
        require(totalPrice == msg.value, "payment did not match total price of purchases");
        token.safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");
        emit TokensPurchased(recipient, msg.sender, tokenIds, amounts);
    }

    /**
     * @dev Process a single item of a batch purchase.
     *      This method validates the purchase, i.e. time bounds and max amount and updates the drop config to reflect the new `currentClaimed` amount
     * @param drop The drop configuration for the token being purchased
     * @param amount The amount of tokens being purchased
     */
    function processPurchase(DropData storage drop, uint256 amount) private {
        require(amount > 0, "Can not buy amount of 0");
        require(drop.maxClaimable > 0, "Drop does not exist");
        uint256 remaining = drop.maxClaimable - drop.currentClaimed;
        require(amount <= remaining, "Claim limit reached");
        require(block.timestamp >= drop.startTime, "Drop has not started yet");
        require(drop.endTime == 0 || block.timestamp < drop.endTime, "Drop has finished");
        drop.currentClaimed += amount;
    }

    /**
     * @dev Read metadata about the drops
     * @return An array containing data about all drops currently configured
     */
    function dropData() external view override returns (DropDataView[] memory) {
        DropDataView[] memory data = new DropDataView[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            data[i] = dropData(tokenId);
        }
        return data;
    }

    /**
     * @dev Read metadata about a single drop.  Reverts if no drop for the specified token id exists
     * @param tokenId The id of the drop to query
     * @return Metadata about the drop.
     */
    function dropData(uint256 tokenId) public view returns (DropDataView memory) {
        DropData memory entry = _getDropData(tokenId);
        return DropDataView(
            tokenId,
            entry.price,
            entry.maxClaimable,
            entry.currentClaimed,
            entry.startTime,
            entry.endTime,
            token.uri(tokenId)
        );
    }

    /**
     * @dev Get the address of the ERC1155 contract being dropped, all token ids are scoped to that contract.
     * @return The address of the token contract
     */
    function getToken() external view override returns (address) {
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
    ) external view returns (bytes4) {
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
    ) external view returns (bytes4) {
        require(msg.sender == address(token), "Only accepting tokens from this drop");
        require(from == address(0), "Only accepting fresh mints");
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Required to fully implement the IERC1155Receiver interface, see onERC1155Received and onERC1155BatchReceived
     * @param interfaceId The ERC165 interface id being checked
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
    * @dev Sets up a new tokenId to be dropped. This validates that the drop contract is sufficiently funded.
    *      That means before setting up a drop, the token contract must mint the appropriate amount of tokens to the drop
    * @param tokenId The tokenId in the token contract, this will be used when transferring tokens upon purchase
    * @param price The system token (MATIC for polygon) price in Wei per unit of this token. Must be > 0
    * @param maxClaimable The maximum amount of tokens that can be purchased by users. This methods validates that the drops balance for the tokenIds is at least that amount
    * @param startTime A unix timestamp in seconds after which the drop becomes enabled
    * @param endTime A unix timestamp in seconds after which the drop becomes disabled again. Alternatively 0 can be used to denote an open ended drop
    */
    function createDrop(uint256 tokenId, uint256 price, uint256 maxClaimable, uint64 startTime, uint64 endTime) external onlyOwner {
        require(_drops[tokenId].maxClaimable == 0, "drop for this tokenId already exists");
        require(price > 0, "Can not set price to 0");
        require(maxClaimable > 0, "Can not set maxClaimable to 0");
        require(endTime == 0 || startTime <= endTime, "end time is before start");
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
    /**
    * @dev Update the configuration for an existing drop. Does the same validation steps as `createDrop`. Requires the drop, identified by the tokenId, to exist.
    * @param tokenId The tokenId in the token contract. This also serves as unique key to identify this drop configuration
    * @param price The system token (MATIC for polygon) price in Wei per unit of this token. Must be > 0
    * @param maxClaimable The maximum amount of tokens that can be purchased by users. This methods validates that the drops balance for the tokenIds is at least that amount
    * @param startTime A unix timestamp in seconds after which the drop becomes enabled
    * @param endTime A unix timestamp in seconds after which the drop becomes disabled again. Alternatively 0 can be used to denote an open ended drop
    */
    function updateDrop(uint256 tokenId, uint256 price, uint256 maxClaimable, uint64 startTime, uint64 endTime) external onlyOwner {
        DropData storage drop = _getDropData(tokenId);
        require(price > 0, "Can not set price to 0");
        require(endTime == 0 || startTime <= endTime, "end time is before start");
        require(maxClaimable > 0, "Can not set maxClaimable to 0");
        // if we are increasing the maxClaimable amount, check again that we have enough tokens left to cover for the new amount
        if (maxClaimable > drop.maxClaimable) {
            uint256 newRemaining = maxClaimable - drop.currentClaimed;
            require(token.balanceOf(address(this), tokenId) >= newRemaining, "Insufficient balance to cover for drop, mint additional tokens");
        }
        drop.price = price;
        drop.maxClaimable = maxClaimable;
        drop.startTime = startTime;
        drop.endTime = endTime;
    }

    /**
     * @dev Completely removes a drop, it will no longer be visible
     * @param tokenId The token id of the drop that should be removed
     */
    function removeDrop(uint256 tokenId) external onlyOwner {
        DropData storage data = _getDropData(tokenId);
        uint256 indexToRemove = data.arrayIndex;
        //removing an element that is not the last one. To avoid leaving gaps, reorder the array to move the last element to the gap
        if (indexToRemove != _tokenIds.length - 1) {
            uint256 lastTokenId = _tokenIds[_tokenIds.length - 1];
            DropData storage lastElement = _getDropData(lastTokenId);
            _tokenIds[indexToRemove] = lastTokenId;
            lastElement.arrayIndex = indexToRemove;
        }
        //unfortunately we can't use the storage pointer here
        delete _drops[tokenId];
        _tokenIds.pop();
    }

    /**
     * @dev Get a drop configuration by its id and validate that it exists (by asserting that maxClaiming > 0; this is ensured during setup and modification of a drop config)
     * @param tokenId The id for which the configuration should be obtained
     */
    function _getDropData(uint256 tokenId) private view returns (DropData storage) {
        DropData storage data = _drops[tokenId];
        require(data.maxClaimable > 0, "No drop exists for this token id");
        return data;
    }

    /**
     * @dev Claim payments in MATIC/ETH and send them to the dedicated payment receiver set up during deployment.
     *      Since the receiver is predetermined, it's fine to make this public. This also ensures that all parties receiving revenue shares
     *      can claim their share and don't have to rely on the owner eventually calling this function.
    */
    function claimPayments() external {
        uint256 sysTokenBalance = address(this).balance;
        Address.sendValue(paymentReceiver, sysTokenBalance);
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
     * @param recipient The address that received the purchased tokens
     * @param payer The address that paid for this purchase, might be different from the recipient in case of CC purchases
     * @param tokenIds The token ids that have been purchases in a batch
     * @param amounts The amount of each token id in `tokenIds` that has been purchased, matched by array index
     */
    event TokensPurchased(address recipient, address payer, uint256[] tokenIds, uint256[] amounts);

    /**
     * @dev Emitted whenever a new drop has been created (i.e. for a new token id)
     * @param tokenId The (token)id of the newly created drop
     */
    event DropCreated(uint256 indexed tokenId);
    /**
     * @dev Emitted whenever an existing drop has been modified
     * @param tokenId The (token)id of the modified drop
     */
    event DropModified(uint256 indexed tokenId);

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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