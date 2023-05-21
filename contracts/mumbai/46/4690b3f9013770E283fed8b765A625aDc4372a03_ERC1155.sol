/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    error NotOwner(); // 0x30cd7471

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

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

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

contract ERC1155 is Ownable, IERC165, IERC1155, IERC1155MetadataURI, IERC2981 {
    struct Collection {
        bool exist;
        address minter;
        address royaltyRecipient;
        uint256 royalty;
        string _uri;
        uint256[] _items;
    }
    struct Item {
        bool exist;
        uint256 collection;
        string _uri;
        uint256 supply;
    }

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => Item) private _items;

    string private constant _name = "ERC1155";
    string private constant _symbol = "ERC1155";

    uint256 private collectionsLength;
    uint256 private itemsLength;

    error LengthMismatch();
    error NotTokenOwnerOrApproved();
    error InsufficientBalance();
    error SelfApproval();
    error ERC1155ReceiverRejected();
    error NotERC1155Receiver();
    error CollectionNotExist();
    error ItemNotExist();
    error NotMinter();

    event MintBatch(
        address indexed to,
        uint256[] itemsIds,
        uint256[] amounts,
        bytes data
    );
    event CreateCollection(uint256 indexed id);
    event UpdateCollection(uint256 indexed id);
    event CreateItem(uint256 indexed id);
    event UpdateItem(uint256 indexed id);

    constructor() payable {}

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256) {
        Collection storage _collection = _collections[
            _items[_tokenId].collection
        ];
        return (
            _collection.royaltyRecipient,
            (_salePrice * _collection.royalty) / 10000
        );
    }

    function lengths()
        external
        view
        returns (uint256 collections, uint256 items)
    {
        return (collectionsLength, itemsLength);
    }

    function collection(uint256 id) external view returns (Collection memory) {
        return _collections[id];
    }

    function item(uint256 id) external view returns (Item memory) {
        return _items[id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function uri(uint256 id) external view override returns (string memory) {
        if (!_items[id].exist) revert ItemNotExist();
        return _items[id]._uri;
    }

    function balanceOf(
        address account,
        uint256 id
    ) external view override returns (uint256) {
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view override returns (uint256[] memory) {
        if (accounts.length != ids.length) revert LengthMismatch();
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; ++i) {
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external override {
        if (from != msg.sender && !_operatorApprovals[from][msg.sender])
            revert NotTokenOwnerOrApproved();

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override {
        if (from != msg.sender && !_operatorApprovals[from][msg.sender])
            revert NotTokenOwnerOrApproved();

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (amount > _balances[id][from]) revert InsufficientBalance();
        unchecked {
            _balances[id][from] -= amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i; i < ids.length; ++i) {
            if (amounts[i] > _balances[ids[i]][from])
                revert InsufficientBalance();
            unchecked {
                _balances[ids[i]][from] -= amounts[i];
            }
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        if (owner == operator) revert SelfApproval();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155ReceiverRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert NotERC1155Receiver();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155ReceiverRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert NotERC1155Receiver();
            }
        }
    }

    function createCollection(
        address minter,
        address royaltyRecipient,
        uint256 royalty,
        string calldata _uri
    ) external onlyOwner {
        _collections[collectionsLength] = Collection(
            true,
            minter,
            royaltyRecipient,
            royalty,
            _uri,
            new uint256[](0)
        );
        emit CreateCollection(collectionsLength);
        collectionsLength++;
    }

    function updateCollection(
        uint256 id,
        address newMinter,
        address newRoyaltyRecipient,
        uint256 newRoyalty,
        string calldata newUri
    ) external onlyOwner {
        if (!_collections[id].exist) revert CollectionNotExist();
        _collections[id] = Collection(
            true,
            newMinter,
            newRoyaltyRecipient,
            newRoyalty,
            newUri,
            _collections[id]._items
        );
        emit UpdateCollection(id);
    }

    function createItem(
        uint256 collectionId,
        string calldata _uri
    ) external onlyOwner {
        _items[itemsLength] = Item(true, collectionId, _uri, 0);
        _collections[collectionId]._items.push(itemsLength);
        emit URI(_uri, itemsLength);
        emit CreateItem(itemsLength);
        itemsLength++;
    }

    function updateItem(uint256 id, string calldata _uri) external onlyOwner {
        if (!_items[id].exist) revert ItemNotExist();
        _items[id] = Item(true, _items[id].collection, _uri, _items[id].supply);
        emit URI(_uri, id);
        emit UpdateItem(id);
    }

    function mintBatch(
        address to,
        uint256[] calldata itemsIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        if (itemsIds.length != amounts.length) revert LengthMismatch();

        for (uint256 i; i < itemsIds.length; i++) {
            if (!_items[itemsIds[i]].exist) revert ItemNotExist();

            if (
                _collections[_items[itemsIds[i]].collection].minter !=
                msg.sender
            ) revert NotMinter();

            _items[itemsIds[i]].supply += amounts[i];
            _balances[itemsIds[i]][to] += amounts[i];
        }

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            to,
            itemsIds,
            amounts,
            data
        );

        emit TransferBatch(msg.sender, address(0), to, itemsIds, amounts);
        emit MintBatch(to, itemsIds, amounts, data);
    }
}