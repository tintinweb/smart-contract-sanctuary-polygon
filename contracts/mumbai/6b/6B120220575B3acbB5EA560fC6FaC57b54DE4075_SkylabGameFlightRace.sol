// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract ComputeHashPathDataVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            8975200139137680326537315640903298764240966659913302774219199787784839890746,
            18918103695192043224561275999785871250349745983763714554452227384706535599218
        );

        vk.beta2 = Pairing.G2Point(
            [10507076799693754277342299610883221342455370125701534989585604406444248460586,
             11138084488718045907097424010827096951539532146970121877800163102538937365126],
            [10358410162609335113119458381526034341309899576968486459646063181991922201864,
             529324185255923006029450586357433426066092575823694765129234273017526751567]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [16239796213936581576278405918138688158754501547987497628457986817672976688785,
             19847114241177350705322977681643079266915986431948633301190855842568654600255],
            [6182531180118821590100097188713346172522167901656153466854091949998522789614,
             5654957927447453679428706234169482756365433435444604475329826095054831813976]
        );
        vk.IC = new Pairing.G1Point[](102);
        
        vk.IC[0] = Pairing.G1Point( 
            12421031618647416173901446564540373459425654768044845392332733094869690777316,
            4994799953116800428085613926331878426045453585653577789287881430384845666882
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            12918612768012093927034284719417865043439902186527081080670464765278821596878,
            1601751884378993411993465881044758328625174361200172728021353511901784781180
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            343756855093656447339076608940290175193715412024730380519175051143695633778,
            6418604295214979666847591546533297518147135543612407764827373260850221223658
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            18990723711466980005007362716344434192631578340016546811429137863706590194738,
            857135315530324082359223898561395171798834965676917954503773184067870335223
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            11765941808152909009669288096136367556544931996679586883822765717589395010772,
            12610901019673886500903168970847642305711654506516755862424271291738024928463
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            8239074086542334646383930056412106857123307149840100962089329623603621101963,
            12058642277408947472997061970363038137083224555787005238510026689268316404093
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            19428826431841459875197182553657985587967401789535630823337424371598489487252,
            18852909596976739963743043889762951790518852233118207625414491985065600946992
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            13746382123297300635608905612484995472509732768851560851648852303422840124986,
            21560151806907442519251597668809396608168907963404854734839127711065407379665
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            13179524277829670783034431492411530223004157725304468853090661765592571482485,
            3910275391208575883609768292750669655471261458737045779302390811702882635946
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            791694119842041048165459360520548841082415295736858523360974534170173509215,
            19399516078386754893805181928132849638111188489665495936359174117506607835498
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            5475305757553554106463165980118913822135933480903414383688079699110727922303,
            10042448407224364470535506166809990059242596790092790481487046116448457170388
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            11283027622879481229828794720381203985974427415837999577664195086263673293351,
            5300362470480825700739754090523140873619985717200344997435921676216376520902
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            492503751079145025402648729259720369056552442900564939508648463562322164568,
            4785928325067960050631602890573339324779536829045260799786485350008286565684
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            4625184895667647714107644160867264448422302751373178926409359061599709987882,
            17356343928508288573715313844837945476426969716260218306056794718689539722638
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            473922138243363043139503664574060006446492392284612395438624895087485861996,
            17119723732083449532121587941731961068378944157820053208104433510134156424859
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            18838921791495680610609204133566817990049355554868840596114834429895169290430,
            2281991732816775534436782113975164733927004394812761552718292989984116134143
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            8296431119880794018267513442665940166153643153234128234976465054319623305540,
            10443444251385646033987201006841545689824038521364120433025749697091414004159
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            13678339343022371073348913443564893089050962708900597720682248132435256315709,
            20302027244630334879777083718357920373747827838879987361117590831936858806866
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            5360731056669647956907523579093350788617684923030510561841150506442755909050,
            5714268740486009770429349447396084834630195621163763280988538846555817171264
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            2669204895346037400979268679663787906560839188732944252058856379698232369918,
            10496297025490987102209100904407240971373223821752389968584127371540656920615
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            18329097475289100177180671965889769071826842279132456114068456945778830220987,
            745066720212065310388355727708966172943754045073943701499769562390554169417
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            6883803630692928834611607916391504528950965047827664943995460727288860554389,
            3500500105718038874803524058552139885541428764578360899884819414258266961548
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            12715143197292373316853007303458490528609903340373809853629699131625348849299,
            10919827647521500856137532072096087671774487313067709944115671901939795379385
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            8633198308987063133351311979471787437318271336703224798331455386719333615073,
            2870327022950688736556388954490079398911688628915583167131967654004582542305
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            16485105447451554539692679463626394804422841674643142706522693544875340799585,
            21518923510035706198106410045936392075867676614466974059525786774361022384394
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            3731708738646006054963356421108242612826964923660894527383471536757798451356,
            6395104772914889578871841297927596520420758661333149846711335253303154128148
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            8368369237783879952027412519199051558078171044995647853779803426450374079201,
            2750024737512633147135163077672454779878278353600698683753457477467158651234
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            20780469531022975598499715008562892451112218129957966565423897743051897018011,
            10426821188720422951391002007116287292909927694458390883053143649989794820686
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            3754051914092194774607153706963142836729655116163495348856600350740847502847,
            13036522120754758019482487614383426756643167435250799808679569575916135971468
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            631186398492363636477573753534024643356405617072925583093388649672473364487,
            11968505941194836712604170502148183417982287612876913205356608157825861878651
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            3038460873822227003022860629419396391845081963499741661859206003872686542775,
            16529228901549073026405751469157097063237041557126603425190620026376317367920
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            11827300356817142718013664777563233191122098077059971206208021860882846584780,
            10685377535655624499462763484155528014436736624266090847591424108590092896427
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            17924850836981367871334392284032913426566895044331403123165720276944514630506,
            4228613432623071089520033848833336034393679887505170071671490510844698722747
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            6095082789795503189528318414043190059444927071044278311379020449299393696581,
            2521918404490041713635529774256757802556760281023048167138492691057442398474
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            8526894959690417683028957421041979021344319433213031149006615050770336568530,
            18968227051768385790089157210415640275944133246417440825386508439905521861688
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            14500378308631932405771180464908934367333079839846577367412307270518065956337,
            3051240653722834935782159120441162675652312542898004774803238178827994489853
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            11874224329985658458311466655490088446952579668994446968610962981847169581837,
            20649897607393206813221071667265639407572757189432896419335374113164813456652
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            9756495851978047864046712486821576377076148684335092878297651440009316663957,
            13919497198401460057444793099190120090144709228431875309011397308187119433942
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            1343753489244064605714321982033250281565120533027615086555785463722684415032,
            2728481269677252394226305094764646508355741212142268309084185590245037494775
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            18709457774495581749686748009826239196568613008894023341183741311432204482227,
            18752169545973260349801456389778770342765747257942140674727181018545910064828
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            15272535621198861070131340227402537714604195653520900129139358373770469834395,
            21557887547731126752274893004585964697389715033619911211036077636074615351685
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            14658406239709689126162620874939919595765791848614662986290922972817346407922,
            17112548301787440992286107606855328766870410148293081322880670375939011127066
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            8112063981193484978858790877994574204806427728693449484478942788760841572401,
            14354986175221701106677073519670525457143730635078300630454043308084228607368
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            20394700222238694879181161936655819356977419794128947261697753299413836279226,
            20396210306594165204790248543797745500413699628663183880157796061630441818553
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            10631182532164492436920248005166270001525803716777857885664067163071710799416,
            17583816743748550885714630979705268644374721313981910480781951500106221312475
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            7796805038454622153764588292608962299381426660522368854062232980643166153846,
            12413388439434647278657436837605556515092066228515859700877042284577765971388
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            21718411791423614806763933238850442075236101464546100152496688418723340568515,
            2967258255735277165837805025226992761768602451886217553590524257279057181370
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            21757660563445281234534953407244161828576905413515038346948070843405958432683,
            21845416818764178026154398982252615599060758133622330133493305720234395839682
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            400203704724402125896077616217835789365952048176536831487492622605882165956,
            16750991068755130369133616972504504003428317237761326230338460226266817953155
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            6117105008807847572131382496154642744223695108719798722245575420273926548398,
            1058796605757107261112661022365157197274919015835220471652188647421435378596
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            6428611510178423046522650263191524570705170129823855970926981163811793697962,
            12447303059634282708578982310061084849831593155114577644018252797550308266133
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            19407519926040573591991717135704946167831844261593839087243599759486418080979,
            4768567128058759953700678999216386425982049810568010891896608594624217616290
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            14330620759105389730918673286810731905613296145404846869599649774692197335550,
            17966842458280449002687364318606937824785383653549315377709786812870459532975
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            10703711296789114487152958609440440805106070852582912953297089050624978985940,
            6962140607033667349760231120015166889142411025248668171321415490016816518442
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            4940835694161724634190051119073432868763633816124940258980540115688668927938,
            2945082592931975667888969100521606478743967640281590394987873295431997426461
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            14324370402690090990401784157637001444941267713307772573711767887373220838335,
            7726509789038186752656682937518116625125055756396036746132699396423571438566
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            9687810202614673624942491519180091412766099617137887348909286596981112850070,
            12949281592024570664447814866297337468287517778075950397532370514494690098429
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            15374068776550295240751074794089628334704194930559019668312372318223715414572,
            12220211117412873663661340514175452648069108814586183532764687913590536601724
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            6769511203127530983846720346102644604659454978176947760412132276594250474915,
            2578970529108455761878910792330016311053242145746024605998563750421022290479
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            14004274222550464287224249057761576194974800600298186789922294563987021905177,
            8921729223788218608547746335410739551829744314458034391686820547294883773825
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            20220188425994110579029181776055182555760792468773716842650430970526926643187,
            2186785715690588837719188433191929799629667630521475127091004401432892800657
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            20172401006518468264069730572332830568844616559523387620667833212474464019514,
            10833901835788697998573559452973431206089901645856473793083709972996173641299
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            3286383184107796082224048816934001097746249978891443666719670210052848329398,
            17845079906779099317989571895617947061978808327046632460828865487146034206027
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            9769100037424057467660756839357765026062406120326442888149709807436616864307,
            18873316792172502108528273609062011739978702753243494856671061987440750954663
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            8135800151071209420520010390981512291424743508128929260861369636984361740683,
            21862127486892607685438018221513832402572891337604477907650955095551521139927
        );                                      
        
        vk.IC[65] = Pairing.G1Point( 
            8092751574834344954098818937480983045425857678866871135433096556376913167522,
            17918692984570485292442994621612973541778792650376847184043068944291196667350
        );                                      
        
        vk.IC[66] = Pairing.G1Point( 
            17446549964317166565200789811916753971181023330946700656374103871866067989513,
            13982714637248389236373225415620343357154850934987936646586027589356223187199
        );                                      
        
        vk.IC[67] = Pairing.G1Point( 
            255952445423735690885715962918950859104053280031814736786780678284722292347,
            18760986046060712160822708952242472313517085855987701774796929211558749695721
        );                                      
        
        vk.IC[68] = Pairing.G1Point( 
            21018130188195585446368661012937357336443526704737603666287149000854123170833,
            3202196583751872752853615786048188733373423622954788358226236724084121763678
        );                                      
        
        vk.IC[69] = Pairing.G1Point( 
            19457267893763077683406705619307672676172827075263127723491264404651870636011,
            1164482389907700789619795386171889055935511914296890390986249242078904266077
        );                                      
        
        vk.IC[70] = Pairing.G1Point( 
            21517928681549509562191974709509508773645951031465503930933132525072866309679,
            18255489786803649364149628320533759417826327167190180256315663647631775047227
        );                                      
        
        vk.IC[71] = Pairing.G1Point( 
            6950820074905543294059566818647010169121479268941001991816190334639196973405,
            15185947777790745395175301271336707438622036053871396303943063338839075839916
        );                                      
        
        vk.IC[72] = Pairing.G1Point( 
            7271554091526269959637188356880129320228961414070114468151351817121075516853,
            11010386964830246972606646275974167215333981902191667470525125497801097187519
        );                                      
        
        vk.IC[73] = Pairing.G1Point( 
            7754641539899415940478709828654464259021312545835172261169918210062613226630,
            8488941510925111730699077597603489784421193925101340210664638946226125087473
        );                                      
        
        vk.IC[74] = Pairing.G1Point( 
            10491812237390441061924494196219670364447753728138950315878104516479853359685,
            10918956884610474114957080986383507761723002301059347293694384205605643513248
        );                                      
        
        vk.IC[75] = Pairing.G1Point( 
            8125570718457336373733763441501918030139220427644838752380301648437831262659,
            4224907337611051517315384418802300050856648702138410632350425270117126905902
        );                                      
        
        vk.IC[76] = Pairing.G1Point( 
            10209123816961451792208646854634813067281457627846073036139283286892174841960,
            3694452786683241209178986647340712131155390318268937112555812463044733738891
        );                                      
        
        vk.IC[77] = Pairing.G1Point( 
            13903891221749397616122168945815557245764640548094512735129337180132393137107,
            5965481599150666968469696973889775838208819596619950662509301873404648044166
        );                                      
        
        vk.IC[78] = Pairing.G1Point( 
            3826983163658588234731008018660323344829167218506043574553373656017186428760,
            21543538649759633850463397377146779803144168555910944179762277194794106192180
        );                                      
        
        vk.IC[79] = Pairing.G1Point( 
            10002263975081496655541936683663889106332141903010288490155575937514403232803,
            18848313907032890883767846205780657696008786543001071021681075871409165670353
        );                                      
        
        vk.IC[80] = Pairing.G1Point( 
            15001806022679623892982343095208980454221635962571458607940631019391998772628,
            15578120282428824490566499216659073443445325481926684639256039508593954049833
        );                                      
        
        vk.IC[81] = Pairing.G1Point( 
            2209335672569870843205707262494552613378185002865168486470950014530344359190,
            9913770270111388606233528313318329755692498084320429956312534548647703582945
        );                                      
        
        vk.IC[82] = Pairing.G1Point( 
            17291460706805477205827783605257311819759009608661942070554086540521022286330,
            10751471050262610580501517306980466146405347621120660882898046623051382739921
        );                                      
        
        vk.IC[83] = Pairing.G1Point( 
            13289192160985029552663955929045469166277240690721607529449458569072816445255,
            12259238517085581143064728486457005116263916311944044414137180311597935623363
        );                                      
        
        vk.IC[84] = Pairing.G1Point( 
            1592691847390195395005289997893788771468192103724717236266156856088459289000,
            3126802691599201532602069819319676562550281625372565175753400518057235693656
        );                                      
        
        vk.IC[85] = Pairing.G1Point( 
            735135443491828395996108495615194879193721581556720627221441562028841708301,
            18254477793665952697827037314634956931060931229242992664425997480943732613553
        );                                      
        
        vk.IC[86] = Pairing.G1Point( 
            9242115661072705623648734481411182414435910213243762316733173195057520465442,
            927072760387387503555849148158078601623466704859557232958326442122288858975
        );                                      
        
        vk.IC[87] = Pairing.G1Point( 
            14646056149031854086542526377727240881212144054407593374243914855374187767963,
            12266348506664616841386636578246077132505805959594146818505631557265938988647
        );                                      
        
        vk.IC[88] = Pairing.G1Point( 
            6396947530776650621477423520872419772982104259669452150077826579839156076121,
            11502074903892296042115772020000414018151060173842165079298881449297869111093
        );                                      
        
        vk.IC[89] = Pairing.G1Point( 
            10946458993881688986927910849481816324454831526049095539176357327854971977618,
            5692818236250065107490913399811852971385472931605448960212600323056773937804
        );                                      
        
        vk.IC[90] = Pairing.G1Point( 
            5777442726397972906681258157409862284692232787027336502064129262833253540409,
            12533488525293962978676494933040117446619736710995709081080469674702977790482
        );                                      
        
        vk.IC[91] = Pairing.G1Point( 
            5253658426948807364571717351072864573097112295745981584649406240362624378918,
            16811126459496552866567782559121469319150754895919957692371210903337575653834
        );                                      
        
        vk.IC[92] = Pairing.G1Point( 
            9602753227541606409911146775967175075625339391448087840066817828641587636765,
            9992882341621694715683807221842979278421697535144085289594997444399549116168
        );                                      
        
        vk.IC[93] = Pairing.G1Point( 
            1402568322771326539085966935087005624058494724115881159780851211976864740087,
            475793255298171503728520410214522450122388987052008115259161370363899104447
        );                                      
        
        vk.IC[94] = Pairing.G1Point( 
            15520244790226117846707091428618536020270792822939864015212827184472691195573,
            6084708761749386809985953238814961793337317156208941708886742143232564812445
        );                                      
        
        vk.IC[95] = Pairing.G1Point( 
            5228694409995254722369882121605748123939696500105732381189014387420165260170,
            16952920147313636751804325201522565744101824197551177951684097769956356271712
        );                                      
        
        vk.IC[96] = Pairing.G1Point( 
            10668433651157538865191748155076735007768484178924302838807969926910616240251,
            17144590972545034388458235202739540750102764818675045257313430939106746975751
        );                                      
        
        vk.IC[97] = Pairing.G1Point( 
            4011091409147594665360535878092673147928271216285510111814690599135897646191,
            17469434003490378296288505629224604970046655324385307335636439388441543092770
        );                                      
        
        vk.IC[98] = Pairing.G1Point( 
            9404339739165816773340307993266662769269221628192961178507054986822178091525,
            14974248693367524032521771630573501588254271542779502382006360348071875912055
        );                                      
        
        vk.IC[99] = Pairing.G1Point( 
            17907477305132533964571060626210295793245498381532345054587580964822814250710,
            3848316766381221894581011575558460489976597468540610173016827298779408501383
        );                                      
        
        vk.IC[100] = Pairing.G1Point( 
            2876152813496217087804330597545291376553798873490855245373258212041487041797,
            13305189393049483303052417781507503995004491886129167867898581795055152838916
        );                                      
        
        vk.IC[101] = Pairing.G1Point( 
            11246966281387345597806396035626423475469237820576907343787118407989912004004,
            16693969610457620338447472354729408304700012063027235442839447127296083817625
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[101] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract GameboardTraverseVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            8975200139137680326537315640903298764240966659913302774219199787784839890746,
            18918103695192043224561275999785871250349745983763714554452227384706535599218
        );

        vk.beta2 = Pairing.G2Point(
            [10507076799693754277342299610883221342455370125701534989585604406444248460586,
             11138084488718045907097424010827096951539532146970121877800163102538937365126],
            [10358410162609335113119458381526034341309899576968486459646063181991922201864,
             529324185255923006029450586357433426066092575823694765129234273017526751567]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [4001442839954725037333447853850733333968664356417358726144597182449279756239,
             1152897790532049476428963388846431023699282708442179981587673374807243405509],
            [15632162860459092247780976129726608502493342528467255812552543424909532651200,
             21239214062766621779583427443828174760012915414507190215633714781170477937961]
        );
        vk.IC = new Pairing.G1Point[](10);
        
        vk.IC[0] = Pairing.G1Point( 
            14702718669818258186558787893559554106556832223627451999490734729070591951233,
            19185936270873705290996910751004555464656661540423279480211774870888608935019
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            15267871107830201566720118951786556787243539874755528104513422695077765065056,
            7392026876992116243216879681715505259964198573563230004697750682634346072165
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            1261535165445045290525269306654686349967344117589029148039716412867042718518,
            4280729361825389995664575382271474586152571875137144413474527532758930946913
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            21410500895705976957882494308896588584139276490964148097986862841859326475974,
            10002709132894916159462417590769599647739553407232168164892604325087876780210
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            2910494161146637852917949819179857420667896790023634074903389872279597859872,
            9285121275192308133905658467217922042447533122595814624296889742437926129340
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20979801119113377312688342837965922938805932862870900230428645247694114167575,
            9331466549161716887575569119896041445154368043235341413789234239850667839191
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            5814885928825527826325966887904770630221486604101422450960820271018268766539,
            706598455170362276305815614787240518528407121410883771508861773776315952732
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            711974435473551101226226596303522352778317796502828525339081631496503347728,
            11980987925751339017383453330166050777065721420442312098148363307724864290098
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            11302420174618502113058050337252448235115693160297307052891224870337000716052,
            1956946648582046833788549538415024610465999335003677393498937419467482091841
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            11053393529941319217815414466010448743470959625622478519133724234006545865141,
            9787414792396418197179746129907136120049979262948141500242242480422051753841
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[9] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MapHashes {

	uint[300] private hashes_low;
	uint[300] private hashes_mid;
	uint[100] private hashes_high;

	constructor() {	
		hashes_low[0] = 3753290604638666365629493345667492887360387304355990211724271473447884148794;
		hashes_low[1] = 15011519063584535071494262518037266494433360043082782558351133088518307419151;
		hashes_low[2] = 7714727977557247982396391355777119148295034796730416117011181333254288639514;
		hashes_low[3] = 15206250624448000772597285428373903624843271717034486763325494148480213137700;
		hashes_low[4] = 12381318998910310345580426604168871544024341003785079436806002375239595371325;
		hashes_low[5] = 12849015442450860926086374222919761491713956664568637795420468423165823099194;
		hashes_low[6] = 16333218925438193092824506846359591376194793739955154835047479049150810674491;
		hashes_low[7] = 12788889653343121626819784225498313067245536709230670631686925995840290511213;
		hashes_low[8] = 15501403044539906665697424087897857148294612507792285658416947090586796730277;
		hashes_low[9] = 3729747152292447268163600335290188867678488445027300049642896977644823348007;
		hashes_low[10] = 15687034843080273030524149840540202397661187588600314326827112527502957831312;
		hashes_low[11] = 20669256476061161996799132601039592579010840554668445888023960767947210061152;
		hashes_low[12] = 11560315816620203393265363486470336907160277818896689804293029388270027223793;
		hashes_low[13] = 1593298911726363534916096032368796407309759716003450824653197027545619121521;
		hashes_low[14] = 1200766011277165064300136459759378813227763514840649949493409636580735566531;
		hashes_low[15] = 11282616529489245873875246171247601218216819237693711408690618786712064210625;
		hashes_low[16] = 8876305642591072856455890575193131088106416435592257921591234048467540112670;
		hashes_low[17] = 13823787553341301905560046197623439299430300684159982167967398098413833512052;
		hashes_low[18] = 6042311207445316683479555274762801236334441877838505046229016097296561852647;
		hashes_low[19] = 21600038265773212651337877324972405300134521785865147561282525987935349814734;
		hashes_low[20] = 15676919684811436321949453651263585956284311264234582123610434107970479563144;
		hashes_low[21] = 13179695885633948540214780150814688726882880916227222088444965215043505835762;
		hashes_low[22] = 16492312883845526845961796604171903372982836591142976467887965462257340538763;
		hashes_low[23] = 16797169319732745035071069618768025023376377003300948995687896867685507739917;
		hashes_low[24] = 10629436817111029613185120671912386200005476125514147113845470223102283939877;
		hashes_low[25] = 13256817602160313814886489943463434149036283139235055028138810801758353967078;
		hashes_low[26] = 19259594954942806706527082563937364728633410387942165185981013093496363034585;
		hashes_low[27] = 19186292311005786497441895717823997722736621991279629224659101920602738628914;
		hashes_low[28] = 1651221564778243835913652612380819672300552984101016515863657314762408978377;
		hashes_low[29] = 16665516900599186161719478959468094447930387750849141659875298682856117391850;
		hashes_low[30] = 9804176866863405456285906799916733553979002823999921782546967869694005192157;
		hashes_low[31] = 20394034410493349019351461165285538955581490247060176344467369850385206711348;
		hashes_low[32] = 6690707647084151316253263865415390143343700558488932648967341750594699898164;
		hashes_low[33] = 16283397479025355574752549993362350959251567903431511552334027590081820091096;
		hashes_low[34] = 13684108091543804585262319781915421576447324763271841449435830767391648720856;
		hashes_low[35] = 12982255836863654075496093465461530523088829896783409133875538203123770608917;
		hashes_low[36] = 10155614952255384063279173454483395450145964513408943530880317199425419736878;
		hashes_low[37] = 15270833406073306099869483055601864617906301390216424271799106367774668764121;
		hashes_low[38] = 2255279796762388059963185486181690160335014034571730674387739566535926049169;
		hashes_low[39] = 9503478546319104277766008194054165335515962741861358827463809267409241889148;
		hashes_low[40] = 19688123491080356720916488362058486768644603068632433251599915508718126334287;
		hashes_low[41] = 871088358257397021182951668760960902211254974916249731043606406869553655426;
		hashes_low[42] = 14024084256791835578203601823913648656055414992322004578795801472792486374009;
		hashes_low[43] = 7839857115776406720535818654398754684453305364719813606809255709771712670670;
		hashes_low[44] = 9984253181190220366971914454205067425902127151452354854086556632975538352073;
		hashes_low[45] = 2281718706767611397105739407993816112491085218991143451646746471851915967209;
		hashes_low[46] = 3111736914156890961550407065011884555309847384140872545147974495108085059672;
		hashes_low[47] = 7298671632896507870038923874702500790269623613787560154460291920831994470879;
		hashes_low[48] = 16905370805845576503415895731704837261834515222694273722879108060296404024849;
		hashes_low[49] = 4648441990879248752237432321782519418873942593983092029079162014258105405339;
		hashes_low[50] = 1146463846118604433960434337745006935894306804410894072734094683019752187447;
		hashes_low[51] = 4019003364360427786977352714128910157007319229115833893373190828924223302805;
		hashes_low[52] = 3122793392986042160770327747524362123789947896169483253871972790407430479211;
		hashes_low[53] = 16428380934948640605702611444881423436479235344169261699998317003435999244779;
		hashes_low[54] = 3211510183412014073006778184582564289342417058479192587056219965435641664783;
		hashes_low[55] = 10600275684009647645616819959106458260407831707537064095016502178006992162131;
		hashes_low[56] = 13119863494618097224543364031978382996626084128553519539177641109118222359279;
		hashes_low[57] = 13340762894897087434633271645817312316463295737536890575157259586270288860374;
		hashes_low[58] = 13194126854910650963399252521410460631537913631914829358074770330670599573300;
		hashes_low[59] = 21221341192348250139950849970823922781466415107513317014542277274546193991519;
		hashes_low[60] = 162801767487173069237304269169208521505947425859057339046343519243639825659;
		hashes_low[61] = 8583387436958163836452259924988770627432812176816616926876502674252911556564;
		hashes_low[62] = 21728479138237271502816619658236598598547107320266653595580000668962941594574;
		hashes_low[63] = 19281217296250414837924800001917794663591645725647000118766116497932971782965;
		hashes_low[64] = 7569939920284276480525891234821124850576091969069794256612865894617936345447;
		hashes_low[65] = 2854209955313596413385054528761421924882455703570426322663486917626604805323;
		hashes_low[66] = 14158477288091494934073633383421964140498698641717916349716772910430500004866;
		hashes_low[67] = 17364277832670764372205178420132167004080915659241028631266566079759361029056;
		hashes_low[68] = 21547100965255766327619139696261089530744255385121894520933939311156877046592;
		hashes_low[69] = 3768187922503045396043001303634365334243054690934550562330826025897459820310;
		hashes_low[70] = 2136429189168792310739251224690856779631615072810139598825389201030689753437;
		hashes_low[71] = 11636483733528304747543428826731453290705266233490055921828609922691726748137;
		hashes_low[72] = 2675731777900719572962556306333920091237256731398102079875579926107648286887;
		hashes_low[73] = 12820363734673605253912850120172122582426947660350624741605433616882416034341;
		hashes_low[74] = 8385199218006817878029390046251967165255767208443062240795174536227599323254;
		hashes_low[75] = 20973668591223969616740166135147828410273949680669413486276129562296922427317;
		hashes_low[76] = 17117150729879719470950892441086897880034023662688580378745165627709978515272;
		hashes_low[77] = 6835675508344910570752304432859472464224253023888365851033231333700610632672;
		hashes_low[78] = 679517419407723735675474735105210387917136520403562392150719703343175997250;
		hashes_low[79] = 15120738481925603786649939237683023301495851914199111842966421168466747596759;
		hashes_low[80] = 14292881921616422176607684321217799687318338533781002850603970867196999591312;
		hashes_low[81] = 3053226209008192450056798728081342509123331526706626312589219925767402474363;
		hashes_low[82] = 4627137736156586779935887413714806809415131602940079026809590165235827985867;
		hashes_low[83] = 7374787846125656186785690262806576639593879680805681959257279608266031710811;
		hashes_low[84] = 6519556838595717823129090513827528017522609253240335459984371135550167983074;
		hashes_low[85] = 9937284725214163195559378838662817204161338269852081148605443265691881534981;
		hashes_low[86] = 12584755864655767595400547126992689398963182359349429030683079615897018751334;
		hashes_low[87] = 5706723920225549354402829240878931624116904261336976732314536774222888284930;
		hashes_low[88] = 7094707128342308388375859859925106369109253464097366908787194831264859561902;
		hashes_low[89] = 5721079245778009062212137794803304579317429664142943832242217266660832601768;
		hashes_low[90] = 6436312774463931697700448883870901614866047539230445562756182221536597082752;
		hashes_low[91] = 315594812787070519505358580616524702608704031955858897967585504733682418881;
		hashes_low[92] = 16178927757753051027987532707124696582242925721735920279664488937841017534027;
		hashes_low[93] = 16650445763417015713778576651257420851941310315458972889939574867258383644779;
		hashes_low[94] = 14004335459730712750452965644095352874738010182913708012536822214339228964107;
		hashes_low[95] = 12158117998992517712720167264053752586555790072332439783248430534054558008578;
		hashes_low[96] = 12551629524695348930422063351396169374121157940663852188071100247661900976542;
		hashes_low[97] = 4667016065714386482878752434661201035263292174734353971047414850926869287670;
		hashes_low[98] = 17958115272795192805164002214799055805895109625685238401702694176423156202735;
		hashes_low[99] = 3695157539261758097935906323209466598705541934135225776544806151543853787633;
		hashes_low[100] = 10138926714665906117876284856351629443951679324119506858350825416117503678204;
		hashes_low[101] = 4296686771394721937647559819434183844662595452192939258079041799421856990007;
		hashes_low[102] = 20550244110031737966389956765124811238462603066305873469320037099130009391771;
		hashes_low[103] = 12939914055411492462982785163366195364251960164778510268862113150722245324536;
		hashes_low[104] = 9716437406377618030945463071446654178157704135539992785329430332219803677781;
		hashes_low[105] = 12946123813362933681653165116871117726317068728270606746606052580286382746262;
		hashes_low[106] = 2494966974702315094683459876921635292850685163170086147209595205733486735574;
		hashes_low[107] = 21147682309904845325699145350285892381060094165733163764457457776755428974586;
		hashes_low[108] = 4888916271571650772009525142167640065796527212526248508971814189919380619811;
		hashes_low[109] = 3396502038166346451534678640828614419355221529827605954017799815674636015562;
		hashes_low[110] = 17542289036000902923598250633404007402761484616954101654416974221739485680136;
		hashes_low[111] = 2540275286546196659963453479327862152009869222408971770331575505266353623066;
		hashes_low[112] = 13682034032598817811166039504029719089781230899235824152025049633547715757230;
		hashes_low[113] = 4999819727847606879920548693087743142073084712992452352592852246536823763920;
		hashes_low[114] = 3944650649037711438859126472083699986964557771274204149186088138598786018632;
		hashes_low[115] = 11652248233716369019091567661749526608544006295699815887078033081736911902589;
		hashes_low[116] = 10313795173443798057057344787291410344502678977409164873274488995281974566008;
		hashes_low[117] = 2422064836276159309988610378572960842487997167086770515814155096329681310851;
		hashes_low[118] = 17027838282670887490680764750461513862628315370259952557148723279104752101987;
		hashes_low[119] = 13728222244198977509471891506474441122668245733127630723719861893666373937756;
		hashes_low[120] = 15216634086881579289188977494262657024984389305371229907613000375183693861141;
		hashes_low[121] = 15803075700402501103389726096780809924837925779056703018774240529201037424040;
		hashes_low[122] = 4468393906488620421127062287394112290758247646647836379821040279542319652528;
		hashes_low[123] = 14019853963457893300811486326129801104323662827125508173306152527998854674651;
		hashes_low[124] = 5378714336533318825864836595359650182986501256594383916635434049524443666076;
		hashes_low[125] = 11908954852095265392502263017785825074671496028105308150617987141027348422453;
		hashes_low[126] = 17073666033495507443574829526948341216453071616256404116780671228096574861903;
		hashes_low[127] = 98730783164073389241516654483970632465103116769917319751481263069434210131;
		hashes_low[128] = 10876469665330165536572798720953970744262017344470829456953695137003814171067;
		hashes_low[129] = 8103216804733250448181052533927894608524588039661871130995724608344229038413;
		hashes_low[130] = 13241871688375970205848724737458701465637568440509206917861332787229819407379;
		hashes_low[131] = 7850932964679862238815273157046569386110205143272453645617188065420911825813;
		hashes_low[132] = 2409600169947607035989719047745160798732919967475824449537465499639792890304;
		hashes_low[133] = 19451360095803409583527983481867461677666227366357677169811719920284584840300;
		hashes_low[134] = 14373224546753407254604555888987909594554504133673427772175318723603128155143;
		hashes_low[135] = 8850657026809384564742219571785479580621052770965398501243644939895600648051;
		hashes_low[136] = 9266839194215065624505032869580182507675594103809885168771419069784291113251;
		hashes_low[137] = 12145282321878903256679332850956684764718493198553245080615580249633227551560;
		hashes_low[138] = 1627061901800469412312424711551262113354293420254941412494257809046033809488;
		hashes_low[139] = 14766357465287873841455723900959600240799675146950559314055904051363554477970;
		hashes_low[140] = 11949965991881540777276462862136563988730661022670216882285902307716743234805;
		hashes_low[141] = 639121504918019910257565779387869505248377780231692072532842753350189391082;
		hashes_low[142] = 7378695076882770242257464837144430396261389254342341538013646617056229903946;
		hashes_low[143] = 19239440707346476069645869288038552135750971695209926254199196281186270914894;
		hashes_low[144] = 12951559292643096128881429366874133828466574542588744431390459695404606817864;
		hashes_low[145] = 20544665666659952336839332301686901263936181281035109801969450710959471330003;
		hashes_low[146] = 21406659666485790561191677331874390879091959799527659197858479120858673381983;
		hashes_low[147] = 11246480656488841084624381450681390829042063556751153086697975487065505361606;
		hashes_low[148] = 8846977962034996406245856364568046420541536740216520783681053944740504277957;
		hashes_low[149] = 11747150273631041589523784450351897703286834686283673995442121294686880027006;
		hashes_low[150] = 12583662972242326445428423253833040385583434762949553825387724527549952411636;
		hashes_low[151] = 7423980150043283306182499284191631664481572938175009210660673963345047102013;
		hashes_low[152] = 18780464517693658092915603197766899906223427309338714001620895248075051265203;
		hashes_low[153] = 4379039709536550292840282676835594699282080819808036191471676964917334724248;
		hashes_low[154] = 14876564249455641776712199626113309947411510557355168178372292389574864795297;
		hashes_low[155] = 18845418648084622740616741526716180721818677386428489470340885605441997127287;
		hashes_low[156] = 4649942480897830092118510773413978756276302497047185281666217441157815317019;
		hashes_low[157] = 11453595889939481170443348301945644334635585742197538608067346116859984067190;
		hashes_low[158] = 3772963324096207547267636192152341197338485251017817555187426085296018329580;
		hashes_low[159] = 1799784083989331543841699733269774368575465070084952719553531613652402790024;
		hashes_low[160] = 528372807772140027660439964375891714720885801021285690396832980139941847700;
		hashes_low[161] = 8385633420310640448350561365512382665776011226343925165579599266219442138584;
		hashes_low[162] = 13197240918701456046767218559636535400456201314194881423756222507831746603353;
		hashes_low[163] = 14381200317325035361424711038507599886038202595455527830270082749084286763048;
		hashes_low[164] = 18397696076558289402590819351226373560210902535075621426949099411623176856706;
		hashes_low[165] = 11540040928369781387554757881582360758764627286584277118129928891786197505275;
		hashes_low[166] = 16280360791620506599329900069674094683534114732846260159689906153365386856896;
		hashes_low[167] = 18685918061027063260357715067586758068212239992769617377524818805225265248399;
		hashes_low[168] = 17473963017098481379386701506462151699943844808052214399002770567475223106208;
		hashes_low[169] = 10209109066575261062620355308336051462390200466296257143724525388873547894765;
		hashes_low[170] = 17704257201110439204078162459104606413310295454305069815495855088609804710478;
		hashes_low[171] = 3364570894770187590991075491877964060179704580014905168145713699035725710102;
		hashes_low[172] = 6094162358136320339087673804294605409778383280985039840797519447243706623080;
		hashes_low[173] = 3911928058745834141639667471541092520001163034355895569488130913541011578664;
		hashes_low[174] = 2710346585382833861626075043934172370483028338187399732351899262490726893894;
		hashes_low[175] = 18142024607148511063769198366966793895024022023829562070064575572262023842162;
		hashes_low[176] = 4915619935842559071298817795235268430849294950657353623065987413902086352132;
		hashes_low[177] = 19203826495462526980818512489472763865181401587803466772761585305214898082741;
		hashes_low[178] = 4615937215204632742521366971828655440739985287738044427376387051203885234492;
		hashes_low[179] = 2165366897662095024353158332318110930126213631572954972904708987071133186635;
		hashes_low[180] = 18530195900317849355648661523494892917154808952449551772071952593255302916771;
		hashes_low[181] = 15067136106756625848674363097123845470391367205454119973573605510472742214841;
		hashes_low[182] = 759019810625248561843167768374822353786925603788749243179931352053304555624;
		hashes_low[183] = 15353438559765301699087179131676693256214212265659998558333687724099597721167;
		hashes_low[184] = 4004110582299836614688786665338201184392359977899809139266577716145969874005;
		hashes_low[185] = 4230638457071976448906972883215127523782579611295501027594703654762874895;
		hashes_low[186] = 9773636806203383425133650528159161414714693542977640309080127811802484308069;
		hashes_low[187] = 9160748440932846781100898163664266740353845080670689060855589109266009151006;
		hashes_low[188] = 11095267967871478274626559315600287715483892683205332208688359799475440043382;
		hashes_low[189] = 14678961205603095453284630122870475274730697339160899320550977498976494747706;
		hashes_low[190] = 8237539557213177179576288431487330277703177679554099240924350491882977117709;
		hashes_low[191] = 5517413689030889077699640316839378441774308102394449023799911499708059472240;
		hashes_low[192] = 13017871827241792584247493675976121030765436898292249206370419824604766314792;
		hashes_low[193] = 9472166208800384454131540076053404805912359909418072553277785979149115689372;
		hashes_low[194] = 15303995102881834527741376374949738489389338836351762465822084959789937445591;
		hashes_low[195] = 11405521025005340183534595156132371925642741225141707661382411277114173405144;
		hashes_low[196] = 20211573725685514995944367404289547642199195103173691322148121824313917608816;
		hashes_low[197] = 19071013560966987353141730164363717552750965034198897942257131498055301774956;
		hashes_low[198] = 1725178214967419659763783882326745573178267509012993579361607079039047990180;
		hashes_low[199] = 20105983337039017604734447218162316968823481677324524816259089973019360684688;
		hashes_low[200] = 7687984355209516886149613057752140899786749512763634968007140300480959873324;
		hashes_low[201] = 21687435699549560988663092317274683755304252261409285961542691106742348467697;
		hashes_low[202] = 14054437143526609791846302155805891772714712189608079984858605746036921169599;
		hashes_low[203] = 13744577518465989532459266399655661825084234369026406096443014665451326864265;
		hashes_low[204] = 4424227749738535067051728396791308155732406676113661444017911568558413056752;
		hashes_low[205] = 17560682440961733806087785457145900918917856857312222513736353030849051807476;
		hashes_low[206] = 13850212719706644164607489052690998351681210136148432391731768280289969212483;
		hashes_low[207] = 1951032158336189017414898410435188315619209171735093607282748872263382452294;
		hashes_low[208] = 20686649703068055214558690797400047527348937312836166793979305126687706435470;
		hashes_low[209] = 18090962506770463378893543600746542378877518382751419881239657711052195469349;
		hashes_low[210] = 7264336008408340129344332309372864955004462812142149669380203192452828138389;
		hashes_low[211] = 9456274739288207973965051466454274323136977670800230199344881812341923128863;
		hashes_low[212] = 6397448193043814911687067645985348332591897696169001112701814019729306802983;
		hashes_low[213] = 11986779685592564706499503399826165007134991142327192408638911621323348078149;
		hashes_low[214] = 15137906878206664226849081878024498092020149571867910273587118570059826040020;
		hashes_low[215] = 16913742832761318391612034046392017266544066755527315570465367794091657273390;
		hashes_low[216] = 21099242977826820536230953638795733080412243602216937067267007406584971304582;
		hashes_low[217] = 19256941855288802419550054731520830584576996109031931668494410863038024952191;
		hashes_low[218] = 19663054436560277679805408608266651997603153746630104152816257434511991232326;
		hashes_low[219] = 19883554844994527531977016001621750441677070694239681697805974579782551347306;
		hashes_low[220] = 1723679751935984929739534628158941184356245127243966360668033232649725016528;
		hashes_low[221] = 3092491347232106918884519074677544080932068252868181740451102371737412278788;
		hashes_low[222] = 7824911346798803980342886114758523024386146195211800103560403676572486632423;
		hashes_low[223] = 21852688202806990614270378687587684913271136424069693890504729621719145503337;
		hashes_low[224] = 17247295402115421935421001202110783550365703016567300297984234194995815607819;
		hashes_low[225] = 2900046901647481205148148447828944188117256559640083102987415727418061036805;
		hashes_low[226] = 4173592298240289862957362960566149232450706721832839765387605248742731227166;
		hashes_low[227] = 1598346776267148993693938621557632936951852517162676278632676897701212050136;
		hashes_low[228] = 16482851302003266744844495974157852414898995311754875218189884579369686897235;
		hashes_low[229] = 2726678788855102184964954456738849823652869239451337407055512280947430507492;
		hashes_low[230] = 2748960507173557215466322932597383390096633246065522962094815728657037123120;
		hashes_low[231] = 2123575949543352406859417903111989984322187023922943533573570952167873146659;
		hashes_low[232] = 8532452427983136191163893700210167276384548459188234448464800376338814899751;
		hashes_low[233] = 2827824613333203742764921648597348016473813276496280943023476299156125915559;
		hashes_low[234] = 1877752162222906928184010671024490017995088139922852035753564002963122321382;
		hashes_low[235] = 20827259389941651119846030931569356237405995045488697865557813013771424299487;
		hashes_low[236] = 19630686698281387165093082308513212686483458758242795566785958051591257683043;
		hashes_low[237] = 9320081832114939469976213024373324709724807348124286432481547042069505515089;
		hashes_low[238] = 10008629147676065881801660520558695720158972357344771571395817650790738352486;
		hashes_low[239] = 1394700253499374437186205256129128526935000007399859117857804337378645158834;
		hashes_low[240] = 2994617012946515039219918800455306205063656577016382805328690058729812307182;
		hashes_low[241] = 9241490221864262228861336130177305523874633712623425236521101490499778287753;
		hashes_low[242] = 13221686830981307726778261277008986754315705185456831742417312913377440005679;
		hashes_low[243] = 21021432186308965562461877768584757837263809773516673489686820263520212444156;
		hashes_low[244] = 8727235801562290241634701767635919638200984719858197207359462125290878772985;
		hashes_low[245] = 5816712686004891276601253914872109321590501268994661217705766431272916309420;
		hashes_low[246] = 19202266191166854246356927357239983833538535375179478726530246616192919934928;
		hashes_low[247] = 5510254835517058036104230771140441112093063886592871567100183198092669974905;
		hashes_low[248] = 21074353141950692061379226125319886624107733914113644896484398759232959146481;
		hashes_low[249] = 1130680727423442963227969178295782627217572415019238289098573429638368298172;
		hashes_low[250] = 17991963556794323512343000855211314562651413869472199916989325606610113918399;
		hashes_low[251] = 15529676153600038254074018278921279631266300842237927680047061252147222432913;
		hashes_low[252] = 15355117107064910783062347289950320824744336357875063554871810295168956198543;
		hashes_low[253] = 1728179236874579429433615696442822868058099390329488003852854622931380570613;
		hashes_low[254] = 12933637331504114360003735553350022973767900482992184334612045329774745537823;
		hashes_low[255] = 15426677665632167055895491128603125386778783199533639259592048611645992907201;
		hashes_low[256] = 7152522304311322346703666395243268363842520249670582450831510411854591244821;
		hashes_low[257] = 11350584881307822838205990350489447522766809006839621235657749595603011812229;
		hashes_low[258] = 2084232961141940219640913428826882276822484258123508453857712115210026913740;
		hashes_low[259] = 3709446194729331138557131572256593193139989907970911479636652620643584078254;
		hashes_low[260] = 2402913755930397439189431720315840961234720247280930856240840867110041717973;
		hashes_low[261] = 12281580655921251428216284629354600864491809483127442014133316208103833963650;
		hashes_low[262] = 8328111081812622022913391750731071587460206557272013200942869190981788401072;
		hashes_low[263] = 4682574840030595709238590707176779368287417883921571858807764071263102612325;
		hashes_low[264] = 17776704785997612438772104969532981010247068275386001688041763622251756474569;
		hashes_low[265] = 13119054916070809671248386234952060314346382734253560816932536534626645201969;
		hashes_low[266] = 12502360298688737881436789563273801842866746946363477681270651034472341952351;
		hashes_low[267] = 6938590449197036349877319358215390361796310834293756208145867938295858156391;
		hashes_low[268] = 4395294868571144386744700229340004126265196809311347117760193661569703790251;
		hashes_low[269] = 17809113072252636913992633224319442522834841874323910513862528681464374981518;
		hashes_low[270] = 5040830031354726050244884009714845437122597127960307063676817163569638054072;
		hashes_low[271] = 8888379218205133725439162221499790564261009358291991953667254649059257283987;
		hashes_low[272] = 5278476035489879812992145817765198474461520394149563702776894368181589006932;
		hashes_low[273] = 20846476092627269978817526950304382732292777055260550279171656925336826253470;
		hashes_low[274] = 16060417168973235002920817611782599289698211350711878487595046969100888937952;
		hashes_low[275] = 21582417918277352033925700239273096049631546485721192882631308962237793057991;
		hashes_low[276] = 21690943546517610960736342910894752742916323977257053019743604916474455241932;
		hashes_low[277] = 1702930548666826453502919718310108834296800974792801232136929063862058726721;
		hashes_low[278] = 15156462132507887329725648625398612653505384477747505965035187135530660174639;
		hashes_low[279] = 18875352993798009758907661347731377429650818792819087237588500526613676745632;
		hashes_low[280] = 2121824687362720587029454076142789951025734796933613986557382867320953127397;
		hashes_low[281] = 3996093555442361984559341608884651774136911459637997818895292415129807416141;
		hashes_low[282] = 5418842716258197301374135144592668740843561839490605060012343471076489423468;
		hashes_low[283] = 16708451908280019341903534665652595365730234730585943548617506862562860075697;
		hashes_low[284] = 19686865761447792491975650542710716791857219023214385398397555938687682245852;
		hashes_low[285] = 15104847472720540940764899943980359073598027131762498611282484120443030938152;
		hashes_low[286] = 18492791287486809822282890631994156206285160240806730680229376786099252937225;
		hashes_low[287] = 1864736366548954516280773106058631490499256279726401410323650584629018880172;
		hashes_low[288] = 21740038010175136057160080254263505727709109622366851141157761719193838091900;
		hashes_low[289] = 5070785664344380706833702704790778336711460774057099987313572372219862571327;
		hashes_low[290] = 6836998534724281959648432981585813535473973634708031441226361819005376068699;
		hashes_low[291] = 20093652989184965657712743771935979584562708527434153500321306033376237700463;
		hashes_low[292] = 5309662531065515423021298760728133768629198003971362723008754638675919217223;
		hashes_low[293] = 2250629657258088868340000424949954170386565936887619319940144104857244521420;
		hashes_low[294] = 8800136381618131338502848053059809945251576742314537481241448977274194035897;
		hashes_low[295] = 20707691817206067932782574660394153605136152068770639524886728165711741927564;
		hashes_low[296] = 7909979173467776250529227805546099527748573156742104916713028611170640422697;
		hashes_low[297] = 7677518386408010858440641613406378766503542073782177430133095567438442089695;
		hashes_low[298] = 20185118214325008420227525008252029430261286077268850132902021465616826494210;
		hashes_low[299] = 13134210315596246669053643209251529237010782203713527977972390453628029283564;
		hashes_mid[0] = 15536450028183028438592250091047282617497971059028057278406989608986156546575;
		hashes_mid[1] = 6032582213238031112669168693353543211042463302240981908953446688878953326040;
		hashes_mid[2] = 6167214670962914610214666898201637485017831414691686399408828381662236461075;
		hashes_mid[3] = 17428290972445565716051037689928997296937430214530089917890077981937961368849;
		hashes_mid[4] = 3871166653640528808180181698355621776038363801044727245773497882591279013370;
		hashes_mid[5] = 20881122058021287242234323267630288935098054146466459512313283712354460536929;
		hashes_mid[6] = 7746576030239963066576625968803644405511433940952154541878091396656417749237;
		hashes_mid[7] = 16504849247047319987847524955561616898015004934005955553280680233587043978657;
		hashes_mid[8] = 8133100397177345955501424110703176217453871648047495091421699201954014832442;
		hashes_mid[9] = 9955781825516688576171665266804677924585968286494739647800692205479688383219;
		hashes_mid[10] = 8162295650440028404939388874033620979703039838456893422573479613579629112089;
		hashes_mid[11] = 15530423943658443981172304938947570004468868227586544338875863214733913523407;
		hashes_mid[12] = 1546942488676294671147083509312583219064931400554704853054943580686518963257;
		hashes_mid[13] = 12253470935440852123645101276945488297366216082089808521250083859914789680664;
		hashes_mid[14] = 12891652169631409041755679325153238808986066927705638878591327698354678668151;
		hashes_mid[15] = 8115189774321812989820076632190198526653467319271132224391536660846665536533;
		hashes_mid[16] = 9148095109539598166396304443307082199979853476713311151217135247202604312757;
		hashes_mid[17] = 15913519853409412667513613524610682447367983711146111994267686216715426265309;
		hashes_mid[18] = 10204123168953822133857618497472544902270858870655830402027330323897388102682;
		hashes_mid[19] = 12063506071425534842856282933207424934742457051430333079605827820495153576225;
		hashes_mid[20] = 379379040087451525689034679029569041477305795702771177182713557655193282485;
		hashes_mid[21] = 2316677292750384123520327324699312815968196456052326632874447638087027497331;
		hashes_mid[22] = 1568007553108205810552661085745262314526861130949660455976381821326155043562;
		hashes_mid[23] = 17275027031652058015440829264476655358102338678375120447583117172541733681459;
		hashes_mid[24] = 4370850825027781111591399697257110770507490453793813214638152048409187447807;
		hashes_mid[25] = 13591224586587833505103111661648130217259961508752188263694607757862158768894;
		hashes_mid[26] = 1925548799647181420462890342864520780453234984191107709336239035400534258512;
		hashes_mid[27] = 17447464835174086312182623653139943241352489376767797079206341340157313147133;
		hashes_mid[28] = 6528195161477806412405021143736616335430181467311695391380871923700094574714;
		hashes_mid[29] = 2027048840969747583407685351638600581276483064056887875450552297549524612553;
		hashes_mid[30] = 6780825075911775283846296603057249356161565835223135335305241273498781078173;
		hashes_mid[31] = 10397848759846799069022752714672573560007538679680176802436026239956534584675;
		hashes_mid[32] = 10768051817261429205155766210930068617851778514699277279379552210997851372334;
		hashes_mid[33] = 13186700763882099722650503126728860929073722953908787846735762695368348335339;
		hashes_mid[34] = 12623458276580285907293148379132016662296569054292586284709336163211566208187;
		hashes_mid[35] = 9374713501455603257445394386847466909058645035628082899264388171847410857150;
		hashes_mid[36] = 699560306572793513529427878661455342118156248255309988011004154006861975913;
		hashes_mid[37] = 1112308625770679688153215800361387565704833648595880424565664784820492995159;
		hashes_mid[38] = 4728077773028747989645337801777623218782369702866536328871699292882176232306;
		hashes_mid[39] = 15949411744805680265204380936584613157972392782523986619350706041205550854257;
		hashes_mid[40] = 16079897798883233549625062236065657679534466020504859715914360391123420300191;
		hashes_mid[41] = 21623779243762460354646792920362156573347200039956242150712251191053764699377;
		hashes_mid[42] = 161955911208863570985444625046358482422136222349872973561178047454261398415;
		hashes_mid[43] = 19250987946589931938554404949385039755481588048173030873208278623732220019325;
		hashes_mid[44] = 5907663674209890287454885868214780383934358712199940941929677707774724451757;
		hashes_mid[45] = 20296961274843679557927227296798743288426768417026433973195324870449419963086;
		hashes_mid[46] = 8293565571800423868720563943143995344489896123600762423745606042879846765869;
		hashes_mid[47] = 5142796922407348016564667878378485112863775891630539072581123972550614750503;
		hashes_mid[48] = 12706136486349408110773664886657226088276941445508045300716672509172062454180;
		hashes_mid[49] = 2923304044147905495397147740967137369689011796930861200399183431092252440805;
		hashes_mid[50] = 6869494177275342240469756251932749647802557865574944708454270644772759712224;
		hashes_mid[51] = 21072390911592650396636671599789960041185920378416134357978529008782783559221;
		hashes_mid[52] = 13695848853288770472762179111077752729078044917770890804805447607201892265169;
		hashes_mid[53] = 13791437692284260730558502457420167992128376210218998590157254417466827694591;
		hashes_mid[54] = 404217761581778921605881986016363515413536264991707759463141751601266272625;
		hashes_mid[55] = 14835734426342437263211687549325061804163050168613953473809937906283797961216;
		hashes_mid[56] = 4456756525570892567715958448940116209943135908840256666452428388859983536403;
		hashes_mid[57] = 20700561151091608930614922120050559657442539982191671247221792625142325698746;
		hashes_mid[58] = 15357834872774509714348808666885919177513511399321801894874008972232468559398;
		hashes_mid[59] = 20633983048754215948559908260568293818458332714352460717573241085464052657606;
		hashes_mid[60] = 8456012871850668786259332325759483915735011583675156229123663580460168045142;
		hashes_mid[61] = 18232833147066566850674103328046128959713993170870498772352353402063291619160;
		hashes_mid[62] = 14670058797859894258542011459329071561876363946821691427390373379970214561789;
		hashes_mid[63] = 10640848324820845283477582478882168546153789867730499928189529295089080501436;
		hashes_mid[64] = 16516213042073513885579017984355904198257331439291664166788597083029858887454;
		hashes_mid[65] = 9125074724332723683207924489401625256557879430486187707396307311906390391092;
		hashes_mid[66] = 19965103171949654678614822440701085036856781853279683563507927637286082952928;
		hashes_mid[67] = 12463078851807871192355718682017021113220935175349076451717816723122986179310;
		hashes_mid[68] = 20373913849217142005501481073885397714501385678994301556381110908584514935259;
		hashes_mid[69] = 1912430685582514394671221728514608387401680871630113959872547565179740745877;
		hashes_mid[70] = 7539069833952034798079612561413364624835480319335778796656418844978858064805;
		hashes_mid[71] = 11363514647045031833723325494582414609817226745826114165133664142982036587230;
		hashes_mid[72] = 9791113270128428398570755801527206847462322737790004201045711811936216392996;
		hashes_mid[73] = 2720357739971504041951667509928332319910754984002120255887020982377740095657;
		hashes_mid[74] = 11215212151182005818318359916198699674570869627546752323721432107135460826662;
		hashes_mid[75] = 10475826701831104128885285544751273031173251100050557235349214708536633546997;
		hashes_mid[76] = 18074060734577829835498647334646124606239224419923040717262505091034983741127;
		hashes_mid[77] = 4851809382451575442812016154620378819503687074259691873782212764115015420552;
		hashes_mid[78] = 953604284670711759282474822995017055700209033558645190010259404215839132799;
		hashes_mid[79] = 9001484446651443434590404063992325489543638809139418367711401878877829551972;
		hashes_mid[80] = 16080389302123649600379164504206318833530828023696718807472317385000668279755;
		hashes_mid[81] = 1991121785868002482176741778921780614769296803408682906645805129914936511963;
		hashes_mid[82] = 14365477707352337536822821625336645485069123121064864408662803901399713488370;
		hashes_mid[83] = 12782723500044543521852295509036400355179437301495716171707703731389869205647;
		hashes_mid[84] = 7350987660108500305891352231728646739635246797041386486844112545112976319818;
		hashes_mid[85] = 18433696629968649674034890080377665033099012054282002821375964220880168347187;
		hashes_mid[86] = 17720970022148110407224351723122370727676009250342563943114277010555713521574;
		hashes_mid[87] = 18335335419622803404352860451211608108158584734039866400733947739385561722498;
		hashes_mid[88] = 14862405846472572142229643092027505658931032317488001315306574328639546388733;
		hashes_mid[89] = 2157553987980866010080708727450635193322301513502203882132737104920304937316;
		hashes_mid[90] = 9427113027636534576760059528818374299408693252852219933111945419248566480484;
		hashes_mid[91] = 4800288854345150181208590360788647435277933192317369711346797530163222104493;
		hashes_mid[92] = 18332560177499684350234460892654388336200358053822931325115040993794477587351;
		hashes_mid[93] = 3629837471475470227722144733282521692174662300065858831825413657644087786264;
		hashes_mid[94] = 2919459350138108142657699680642371703649175464769115521223338685192469805320;
		hashes_mid[95] = 10231951512867924951289703178880382399916504024138738962485326456351384655304;
		hashes_mid[96] = 21762417581047168955831221071513320915370669879587472683358835839443517439247;
		hashes_mid[97] = 11761958841900994870079728759217899512087686462930003731785278481468500019781;
		hashes_mid[98] = 384894116364169998816990106808413742665761813214221910822504713916095308292;
		hashes_mid[99] = 11832231505524273091903514009783186690842029624952842979961055208167392432810;
		hashes_mid[100] = 6480766938236255083447718425131262819542778926816876138004012383997599424192;
		hashes_mid[101] = 19502145998390597221656467160593623886243172451383827491744183317658848883024;
		hashes_mid[102] = 12835313609406813812080770826131276417945576993717331732246691319111695497313;
		hashes_mid[103] = 15838805355062085537004071859371472050055763170956579464830623808121861797717;
		hashes_mid[104] = 20342121719210048185136832498041989011398236881800379837468600512517656590552;
		hashes_mid[105] = 14544764480046950403481080263042404818866428022388133144424831419832606504513;
		hashes_mid[106] = 9686344867297641526317226423491984561233292954333377020605830788252276403295;
		hashes_mid[107] = 11276642746635215785405350438369170172645735497781059039535161933662498630972;
		hashes_mid[108] = 11343670766681824810345448817186760649891727773853385892791598247703186536781;
		hashes_mid[109] = 14136130020697503423456101340858549172948317645114575767714397736612317757916;
		hashes_mid[110] = 19569453717684414262056991497718252812480129239317187336849377832948871980799;
		hashes_mid[111] = 15742899361034206697277604014156384995650242995871502635423270702763566414577;
		hashes_mid[112] = 829811056939444303061276285320793953156674416726837127726766791613823639749;
		hashes_mid[113] = 6037502914022124821074215247854184626439817863358290005504045250243033755487;
		hashes_mid[114] = 3356178457968009189584482871589684868868711532999467602645089352399829157421;
		hashes_mid[115] = 17583813563161251412460333227673736333839450891199064690527569817592262050706;
		hashes_mid[116] = 15500352124938237175386561933985900215435328442038662603294812268939319440710;
		hashes_mid[117] = 9485961677461419631282705078590918224207961192730269521312411835512408334810;
		hashes_mid[118] = 5555531525640209457697283739369319769374670833108650343030164645479276157949;
		hashes_mid[119] = 13940745877949551609938948637540323557504037811411089767384960927495719080365;
		hashes_mid[120] = 4488979492666557384967589354779450310692115822762770520670337362666715398867;
		hashes_mid[121] = 21156927164142433643084995090080200735401600124509907871410644584743435571488;
		hashes_mid[122] = 13280577078198971024500651097725918214468475610672757524993702481837260423300;
		hashes_mid[123] = 105845829622084417920054085759765427932916621362340342718613570891487599737;
		hashes_mid[124] = 18980913568476830844828778653567268369791391344031421616683672715156335176165;
		hashes_mid[125] = 2945863017166378883999283091319721518744196136999524502793154771220772983474;
		hashes_mid[126] = 7501033071730449017068064675245712774004038884331643733404755704476201834166;
		hashes_mid[127] = 10304709638221949440787905778991514256844471717097370206639036640921802342026;
		hashes_mid[128] = 19328233631528972388264180381385598168838761156762074852618807111740624031470;
		hashes_mid[129] = 18572034326481063784669294482303354476835048402860626885692368035755485852198;
		hashes_mid[130] = 10237152174846858614480375248560112220800870398803238674620130982022448254822;
		hashes_mid[131] = 6291818009621156750773639177132741857893745947158576200020495766998302406919;
		hashes_mid[132] = 2171524323461338666393347745872209549718591330281640121155355681602826628126;
		hashes_mid[133] = 15058788191560526123424771682735307118185924789499162941857904128195598203175;
		hashes_mid[134] = 3029125385134815144713446246981350286735519702375864509841703042143058130514;
		hashes_mid[135] = 19873821989536391609207934143247011147355366862031516225329174503966854390333;
		hashes_mid[136] = 17746371970237814809794548120741256163985589485192363967595627388943792757752;
		hashes_mid[137] = 10632922918291017965996548726634602352479227765747876754111325442710299453358;
		hashes_mid[138] = 1361887958970442434087812432789994022422044527439224625584563754069130986823;
		hashes_mid[139] = 6447783370145032762680094066973181793358486669285035549711159157335094466457;
		hashes_mid[140] = 20327274568657003100068216081605370668249113157011213773108000737709609627823;
		hashes_mid[141] = 11143321153068007154326248887444491938170737365497881300484905638404599560216;
		hashes_mid[142] = 15513976308603587624865012170497026867548719811582807961765929235967071090040;
		hashes_mid[143] = 8420369184561205842044714541607247905828720356732543707681185423488229235595;
		hashes_mid[144] = 12463972018451383343174294504221685411518147576800426303634441706074893409703;
		hashes_mid[145] = 2741626543937368159118809566099471729165701305970890543192349652489916293855;
		hashes_mid[146] = 21132606735542678753084055700025782489334162083444555072910247975212278476053;
		hashes_mid[147] = 9283985349576502419878038873904548557161112885275241803860482135029886173513;
		hashes_mid[148] = 8057256091199811441840199955046513085164494362502854037883988101962099983889;
		hashes_mid[149] = 9037871821857287369428560207036577868425898090931858721956603425243284585112;
		hashes_mid[150] = 16982474275192600679772967686462752811892686770438648764419125590988564951503;
		hashes_mid[151] = 15536659733761499895011543607436450812077147220301946907210030909681267231413;
		hashes_mid[152] = 18078995337229764953030161848440005518819218617226533845765099030408912131954;
		hashes_mid[153] = 10446132147338820647358581998533283321236233300181017097463553274410034907778;
		hashes_mid[154] = 6510199671462709035602883756754457066565199195681280763152708805790736418160;
		hashes_mid[155] = 15081514024101892161835796528758514685810758240333858708996842487931943764183;
		hashes_mid[156] = 9645481315537514061419891081441117622758824079213340841641768246146711338064;
		hashes_mid[157] = 5040197824394323359613929210580981701232845946879397455864033363104040379487;
		hashes_mid[158] = 9392467620925091240136450524351324151660156734299004695663546632379890703296;
		hashes_mid[159] = 19552881521657792955404349374858845977058275843079576039514889433697983074496;
		hashes_mid[160] = 16271744976709950107072106915773871868930059743738039135179510886764419114883;
		hashes_mid[161] = 848101330991040774459672543513305435042631365394919423197554949544138265724;
		hashes_mid[162] = 4306694517028984048741289766504756119107799905280924847368433086667866617468;
		hashes_mid[163] = 3210523743372646157102184372267956773573167524038794108664215420399184497446;
		hashes_mid[164] = 7877812505632536567486481862288365845664612939759334427030207709584205814989;
		hashes_mid[165] = 4509134819340629551023891650739091935663162749148500095160536059574298793036;
		hashes_mid[166] = 7745176825211720515526171883896749763328626617277625867535651146061899598496;
		hashes_mid[167] = 19149763752409055777223535274219230281114142012751503981111750484719100332028;
		hashes_mid[168] = 14353789345575259190437018601726667739573857277174137005232693538897392839303;
		hashes_mid[169] = 6632819842420427144230222888709772572337327283898220394622180543862030092449;
		hashes_mid[170] = 13687966465456170143243112917636411222197116299294887753998145415315882784312;
		hashes_mid[171] = 11164343909198957915707997373519194787882268460753044617768227926554938515496;
		hashes_mid[172] = 3636819463963274814281474294024930561031266612136712700150314950409934242552;
		hashes_mid[173] = 9844289345487081241858338906982977312780246483436671207358296962161092863110;
		hashes_mid[174] = 5158923767067535394774898760656100528746841391198354484523574242869150856392;
		hashes_mid[175] = 17832205213952122181593563692109044792183764335149406462526326427113390831588;
		hashes_mid[176] = 11506820586452166942599592068309718522336020852597740650808028542814985053907;
		hashes_mid[177] = 12270640409120638430936407812693533564406341187459447572455620798950768240266;
		hashes_mid[178] = 4147866055926570327036900659312978467351543576084313300972530220826581807973;
		hashes_mid[179] = 11657811031401452558506235183118788235805265291191003488356086904049793273527;
		hashes_mid[180] = 19164617482629745175964381436138382592258767844788566999750795392390790802657;
		hashes_mid[181] = 14452446890605571402782347656913219634413477849724138999890593854844851909421;
		hashes_mid[182] = 10780072700031185064722018249804548462640928408078590736405403301075850682836;
		hashes_mid[183] = 17091392201197405455087908398497048706576645902631707991245990535371468611481;
		hashes_mid[184] = 11683957365047087272844643301343018272947163156251313259471270570714234723811;
		hashes_mid[185] = 19003939322650261248469445937439275948900166878402994028231772129092574725054;
		hashes_mid[186] = 15077623826961443071677700885978613497072381700946960185954786209018861767910;
		hashes_mid[187] = 10346529958935382951024463566799173479157529987541125185744795681300700883445;
		hashes_mid[188] = 14947138305602617309105824144962210741647639564215605902843882235191044077022;
		hashes_mid[189] = 19426938839511217673480651933735922142311018063650348365899032336247863781214;
		hashes_mid[190] = 10966010436032147854957806975424522903956905581385593426266603433054997183455;
		hashes_mid[191] = 8254134007893897511328213737519119192885145393218260324518422854985555542970;
		hashes_mid[192] = 10737822551807614862793951299158632002845357744824711902304867783496754269559;
		hashes_mid[193] = 5693885467773185449215419477044587605537211708442917492514875185710721377437;
		hashes_mid[194] = 7199993747338775871632996805495551148087141523796363174996016673245695255066;
		hashes_mid[195] = 16992078403519318643138811078085710977144006752661287385234876166441901875709;
		hashes_mid[196] = 11127490280108393180926820370482912769457089458815842506730012361640489392276;
		hashes_mid[197] = 14931824269339841251664654742435899800280338011046282058437592434197362700534;
		hashes_mid[198] = 20891781167901281988013047417825516884331547858434844818367736948775861825532;
		hashes_mid[199] = 3811139884026484938885066453298991967801524231562896808038139669579090619153;
		hashes_mid[200] = 5456996594259542952588766497741114437713380909765165470281228357852014822695;
		hashes_mid[201] = 10481162464584081242158495941415590472984326838497592809765110945959168659986;
		hashes_mid[202] = 14576985124990801922964165670428577578488837706105952647087030212257346318211;
		hashes_mid[203] = 9559271790378368508108220239783784613273752903790123127323049811608995414251;
		hashes_mid[204] = 18679527760414933625919654823439151597164345446669608553375619239229069247632;
		hashes_mid[205] = 10262372358101731861167117442495119476398470209774017644227093003050689054475;
		hashes_mid[206] = 8804825363669428904034716866006644424740206917279716887637262757821641721059;
		hashes_mid[207] = 539407433159690193209230611616437551604753114337759247808799070622149719209;
		hashes_mid[208] = 19358603437864198187298614582194762834649902306245749754498879118437050062997;
		hashes_mid[209] = 3572407846736686975413695022498007621217028021926816799671244144329040808410;
		hashes_mid[210] = 6253139450629438438802505534779959974106665816176797560424212592495431005107;
		hashes_mid[211] = 7356683303826848743427150926150005531588170156676518745037716732463518523198;
		hashes_mid[212] = 14510225518514630163810241299856221779873370143629204403076324535179373600851;
		hashes_mid[213] = 635065063287083947885094974153304988589443654365729167165003430083704961330;
		hashes_mid[214] = 11947971251933780610293272888694866198967474476309484140688606053081226323075;
		hashes_mid[215] = 17673595899564405224426007318430394388194179778737591501705884454607636471487;
		hashes_mid[216] = 15700136240403542758637038810224288186862632956082314122003793725821480620631;
		hashes_mid[217] = 13191080551015115561027753639048731375076135729701527346603479010959903027911;
		hashes_mid[218] = 20056327844813484159732399972425852945599577108950200070197286792774016543249;
		hashes_mid[219] = 2633613812909952896829683462618819184743799369836924176915239750498301536288;
		hashes_mid[220] = 1909712558675546385357069346278292935725851181629737163094072148953427776731;
		hashes_mid[221] = 5787522535240196710475980387931238957989652886122665841287804192703117653194;
		hashes_mid[222] = 3739013219472173856750900173254314033647011185285286697229492236505622117410;
		hashes_mid[223] = 20898343914094234614786506943468493757702333393153977758554621132521598866386;
		hashes_mid[224] = 15380248800796646845503118724690887822095246049353392489437386259427404225677;
		hashes_mid[225] = 11811549758461959582065947485454314758290278146521809271828974838975027229964;
		hashes_mid[226] = 2017080855447123065114144440479597254833549025409630692776046898493732112233;
		hashes_mid[227] = 21836799625526169479504701493314626023971355728334560912581636343422336784439;
		hashes_mid[228] = 20421052339983332651727216518298646438260838676469566917090360833559968868264;
		hashes_mid[229] = 4623774740564221878915749673156137304505523210740181772052408142450528525041;
		hashes_mid[230] = 20367507315373269941411050566811647005375832680103232077915236923004311305264;
		hashes_mid[231] = 10268046609903991177844761749161651335325324102951130392256329526865515375930;
		hashes_mid[232] = 14228495059288987490449624559180098283132048879141988692773990736477623793283;
		hashes_mid[233] = 13736992179764993597025713512802986915076155135521721001934689117990977489932;
		hashes_mid[234] = 2063680852873316751734690648167324157051673204515057615331471722569423114179;
		hashes_mid[235] = 20702487494000405298755742745943414651535471745081996118424758228736731318088;
		hashes_mid[236] = 11337016666233256038679365524004332986624431926104839590008832185464973259874;
		hashes_mid[237] = 20097878246395263103194970470145913073669478398258192709216290685417428137627;
		hashes_mid[238] = 10855804966273377415190779151910414011576640314243882146979844123772595019421;
		hashes_mid[239] = 4269753796800838275798023680639591726336472846209642155159010409991397278666;
		hashes_mid[240] = 20637017982742956048638892419565010164722534282812945232487980876382925522026;
		hashes_mid[241] = 19903731508998152758944432584561654534026061924035489777165490491299803880869;
		hashes_mid[242] = 11031228673733753818465944480640297219435726805031274456871819376371892752670;
		hashes_mid[243] = 4574782659660226733449943693762633567767457331711304273145316284053443571757;
		hashes_mid[244] = 582164032983260371583307008690238578875118487227340407600650845893088312258;
		hashes_mid[245] = 5738537375293778118490544858859532093256077981528233228828883910368475654730;
		hashes_mid[246] = 463714210513171637694221626580348666582255839297338041585119297185837587062;
		hashes_mid[247] = 21626258895993370655146499784453274806861959251020145987049672440672062715088;
		hashes_mid[248] = 12163983982862456107619947168796936616902063022888835360868261008899444124608;
		hashes_mid[249] = 1724261502385985400150376130828440301704641878811166013402251425395708325582;
		hashes_mid[250] = 2853697965334659034727284161461579044586342959326093090919984545631344406447;
		hashes_mid[251] = 4076153901089655769005939749214166399600718341921129486212931629336661916094;
		hashes_mid[252] = 1014274414594646197206703252550972360675805162797043893185729123563962803199;
		hashes_mid[253] = 6130423865306088458001587258846996802565249074476128092444426808563265678237;
		hashes_mid[254] = 16143228803715795041148052464462905911647024083367101839896088842191210079915;
		hashes_mid[255] = 17306853649934783426081040745996006536310298908335383003620941382185165310598;
		hashes_mid[256] = 19790785393865964610808443712634706222119087099257884994491309391235963249626;
		hashes_mid[257] = 17356930266110873680514485828557789749512283243762920968978198187321316896040;
		hashes_mid[258] = 868002862590709348247163323830481403718821742983896232721039477105265112179;
		hashes_mid[259] = 21108520013326015523949534084458223312362070135549569453490055592004161202663;
		hashes_mid[260] = 21684035514207610574133509824229290199337612999202453826176632874796088558161;
		hashes_mid[261] = 19519741627037723593736621588834151148666869688226342977240225494971016011473;
		hashes_mid[262] = 21358812087366005239236709284716065891275990730332946760302526107928638054343;
		hashes_mid[263] = 18763408709739414198087693241855721623108164349784221100941825832875161539103;
		hashes_mid[264] = 5970443858927271823823439452510920018268393195471310691612090990595415795047;
		hashes_mid[265] = 6699305739373114430524624645684093124575149632825390017663106405615010137527;
		hashes_mid[266] = 17967910977141684715305370650434399154627186672225813068165297408247936488756;
		hashes_mid[267] = 8346962806529796422477214918860960163771779916382520926005300271695692706486;
		hashes_mid[268] = 17022201432980185737091123969140392424397631202470573757646844674263519987446;
		hashes_mid[269] = 13141636195789252497734142062886762101455654182942757342954233601005251064686;
		hashes_mid[270] = 4605286262479512035679548782496499204069782268067934441322776608026515755679;
		hashes_mid[271] = 5232554989340843292930171450897375548150705733910620606598766801590539499474;
		hashes_mid[272] = 4319660227226724634521769627328479231130233355383482721932689329068494282795;
		hashes_mid[273] = 16257178033408464173708197655884427086825175518789164694391596353962581541122;
		hashes_mid[274] = 6056919611660949729177758411429231540218521676497946895964386230292476801162;
		hashes_mid[275] = 21764649180818913478186234519001785241149677936148192128012490459209862078059;
		hashes_mid[276] = 20382533036677872901205503787666350377705138266606229529736870279408238941551;
		hashes_mid[277] = 5381932589094137832024646326256691932847445377054981869886496447407063345159;
		hashes_mid[278] = 14436469833952136131682145106930350326960068780134891259852214748833102110700;
		hashes_mid[279] = 16631376577567709387634898868473572435544740618311245828847980287119622980948;
		hashes_mid[280] = 6222168355228192032007353003129190563511479431114144047373222111251917504626;
		hashes_mid[281] = 21828971688412604827858526117842483855187236950083455772623898664692578205236;
		hashes_mid[282] = 20951128032908643060972086209698936094876428583300152152175121784259133827547;
		hashes_mid[283] = 993572446230440663595442105230682068500351638332242136182958116891397437078;
		hashes_mid[284] = 8051473335482428556291484624733059878623633083152255600086351894437174674139;
		hashes_mid[285] = 17883672466719477035580664123230654659698662498620098856510272939295814635546;
		hashes_mid[286] = 96476345517506331146731048780510599301344104574409143889806489528416167989;
		hashes_mid[287] = 3685801988635679310245560840098962647442316122305621230830592581813972256615;
		hashes_mid[288] = 20195272808804605168103393833254567790734457865655791330026737544155457149132;
		hashes_mid[289] = 3400223189510362909231982161852544843702868084005446674316497668812141918170;
		hashes_mid[290] = 3222585603736168547382208209143991600030496398542596555452666202609623167954;
		hashes_mid[291] = 2823495320295799436461606975457178265645938993727362209019379759544252850499;
		hashes_mid[292] = 14001740731455216877580491529677857642020378590026680461456369331297346359412;
		hashes_mid[293] = 6099173275317580993730032001570648858080770790502170920471202110671930774743;
		hashes_mid[294] = 19636639133067913744551312308316274981302749668112510852772696006170348961964;
		hashes_mid[295] = 9984386361542135262886799140917086920643424293471296946319461699114431368969;
		hashes_mid[296] = 11492591441994996631539791255492512031692691660041487389286776418316308962753;
		hashes_mid[297] = 16865975096710160093834483257841078681667453426360075718076293175169854544622;
		hashes_mid[298] = 13262096178435963203567794808151596935018188546927282955478302665404353132487;
		hashes_mid[299] = 5907128386564263371949439699339144613818283536708485025055934813708322843872;
		hashes_high[0] = 7506611958118467120063685841708178043027647410686873487367106426605305980227;
		hashes_high[1] = 16947304753458386669801624905617534535659704753661476320074925530579946448163;
		hashes_high[2] = 21246790196956583595625940915359992699034676104073876872582617873605020011501;
		hashes_high[3] = 3799344467194005514401776580398013857896771327316267575421021270683071530672;
		hashes_high[4] = 4537754269840029650511468783954612505065568980153496044095328870191458696753;
		hashes_high[5] = 4693532850633107034680842679203524877878072350009118771265656203711212870068;
		hashes_high[6] = 10075100054481296399222970740871630365580827217097643157853472649844333291889;
		hashes_high[7] = 7044616885336333536094718819468908833135239301133846669854519055555800701272;
		hashes_high[8] = 15168093793291115229716570131322796870997814257096141398981179279403729053172;
		hashes_high[9] = 9300220670180395909280068636419981540457231425063953799584604346149485663666;
		hashes_high[10] = 7534592588549892660629084068769553218478254296887906379009609100068200892179;
		hashes_high[11] = 8600879842104652875881466339801644396023795983403566105415168336171184018315;
		hashes_high[12] = 15255967692447769365546264224565777435502311300656363605324959226311877218059;
		hashes_high[13] = 2804576038309687478795378419388122648935889810879811032636211383458860818807;
		hashes_high[14] = 10994478782622101440580500494197764844356754374634552929279869293034711385829;
		hashes_high[15] = 969339718179267594853948415469915285200855482621884472345779350922292096222;
		hashes_high[16] = 21637417032377170733232887070275234381234280546227149534720772727220864844258;
		hashes_high[17] = 15196373294094658118266881936131512714516994817277085893321861430139343692742;
		hashes_high[18] = 11581340787344035946558685614768163050040763026650300815830442376276594100842;
		hashes_high[19] = 5037059383107080029385834210831682236491271095368119569429147248288027139521;
		hashes_high[20] = 19402777497301007360939614219270079754593671873422258257037302120760979746514;
		hashes_high[21] = 5385725707167903796067402795461179842331486439851354092682254625669753941790;
		hashes_high[22] = 11870354620406924627612488748540901170177409962034802626956559013947572596089;
		hashes_high[23] = 16864345105506673877493669250930545829558703958382641352533421395722769227365;
		hashes_high[24] = 3502510670038658893548320500435659055962343408081063095980529963019334842562;
		hashes_high[25] = 18309704122179348253758351316583651215097064127002401651935358759084097009478;
		hashes_high[26] = 4448302339722210410323540227450351022925851503441253151381633808989971365378;
		hashes_high[27] = 11642676375414496415780177074344341759126003187490262523680165574095537146776;
		hashes_high[28] = 17316161804650179859261752285510963563841139784338115621442203255068115449178;
		hashes_high[29] = 20609514794786975276918484665366646048287770685313947356114986954964356400365;
		hashes_high[30] = 21741685555357005532153171290186233784759836948180944281468547716938719905555;
		hashes_high[31] = 15460487563430405076035170356145085331971852913889376301793429702174686101811;
		hashes_high[32] = 15934948957077855431084603443558741644986867021071061527829938774002128819897;
		hashes_high[33] = 5349665521329312023668626745702546661390561885527511891575164105508747021812;
		hashes_high[34] = 21374255217900489810458404092499174900136559304764399140164057758638418010333;
		hashes_high[35] = 13408567878537515568959151663337011675261457948658880251934836201020242797362;
		hashes_high[36] = 5297585846046526277060162583631449204839196869300294565887585400100650160480;
		hashes_high[37] = 4092445297226655409165907200318101678096530616159521311871088760962216766071;
		hashes_high[38] = 2224132752609396430246849208980958526608219943810104915437408930156150685716;
		hashes_high[39] = 2627717323662774349670781502542586277203385884054303779455785218106227798087;
		hashes_high[40] = 5352995273928788242979913300235271016907218782177244425814830635522108148226;
		hashes_high[41] = 8076840855220598335911920065733700312470810287910504352355881806418336820038;
		hashes_high[42] = 5230813499040514314255210207408338305602195547226125022601650022506403084656;
		hashes_high[43] = 16420972426303527270546860565281238009011026452917490955207029967261603502303;
		hashes_high[44] = 16446697071171715350850181964226835218991071688934204224482264538821604796708;
		hashes_high[45] = 4626289151805548658803702817524894084806333554513459748308084290766071365714;
		hashes_high[46] = 3753080514248200214625379106565304094709001224508424141347301008021512992223;
		hashes_high[47] = 14226464216678006840371365847774925288089630214359161127676148811279163081074;
		hashes_high[48] = 18708112611180798825406600035018277767977912097205193550280571626366724072249;
		hashes_high[49] = 3333851306071294446544820959480888631362539264377246729071314260858973329767;
		hashes_high[50] = 15918212616220820807638154649556455709104328721627617911945360146417410355539;
		hashes_high[51] = 6026626433914608869547807779585795749829500654497716183318505032521089259289;
		hashes_high[52] = 18860832827272196565243903946176065113161525549874508380249524168750156175997;
		hashes_high[53] = 1173363579120995113191265821285074120696148037730973417010278971545832338281;
		hashes_high[54] = 14485945752973362898401269759503367919665956751441861890433937581601784548922;
		hashes_high[55] = 21663519272497199531878900486190443017083360701820224427076919028395860871876;
		hashes_high[56] = 13201823744762313234374896218528801115488533710720459204352105879244695646191;
		hashes_high[57] = 14380404601893043087866667363783668002911922101982736503926778192091188743973;
		hashes_high[58] = 15106848552993202482865603329998205332914258033671078705990228923901521248325;
		hashes_high[59] = 20216903660116280187746846359711479808939131857251666176357340141526762201599;
		hashes_high[60] = 13111726060184860818026351268399548333323139021803456505686673556155387440200;
		hashes_high[61] = 10610981820787603168681753803491633942278011107399370177974582555946300336779;
		hashes_high[62] = 19019363093865642486766049190476340519162140938891598751659152640218921569868;
		hashes_high[63] = 9001747809844571871098390545487620531271415249863633934279747876802824041641;
		hashes_high[64] = 17377752780749008152719651107998739771351728811453760466441825101569233761270;
		hashes_high[65] = 6607132451024209386110512328223725199542601271564973528824648885767486133664;
		hashes_high[66] = 17998056140765350838879301855711143294733447135254095286836265982565107193698;
		hashes_high[67] = 20305836380916617731263631178185298279831053367796353245251528294628703937569;
		hashes_high[68] = 12412769603621670984391087552411461659126026459116117114574292721530184707452;
		hashes_high[69] = 948300568639391122141944459550303215812425467304789903268150206116859905829;
		hashes_high[70] = 2756641332712849818514464413701593798615158092722851611726380983068640797270;
		hashes_high[71] = 14487309554788739140338720219205864764029548875551870949008917388248511612245;
		hashes_high[72] = 10189225942296955088741544906440636365085880028813913227469097161891153690517;
		hashes_high[73] = 10116520200280009174648411017070705569891510279406510609190133691795689082371;
		hashes_high[74] = 11821895785294286351713541391942332500604160729521766229008988879580802069764;
		hashes_high[75] = 13414063608766488091127590241131700164107150246346915915980176565297757336465;
		hashes_high[76] = 7666650371746426855744976826210459995297997748063462068592555678575092373980;
		hashes_high[77] = 553236371000010607163466537760646703924872412791860491090311255068273654291;
		hashes_high[78] = 20126396047418457010449386426942723433661289339453300864128259586269457740570;
		hashes_high[79] = 13807678544931436347256913818532918876009649541249886019119838297162349243209;
		hashes_high[80] = 2920518101775986425853352177389043003657874407816429817164171134751733254947;
		hashes_high[81] = 4395697665633371750230838305654857263613299403948313005892688359456593368984;
		hashes_high[82] = 6210332388152861797296647183283171254102081464359006826532212157948102468127;
		hashes_high[83] = 6700907221070575726418263265432516562267502948762285800973352162731537288159;
		hashes_high[84] = 3974403616786143424837052972030199643505082127309487553819351338517891890641;
		hashes_high[85] = 20895225171014755641131392723011388507010983623557732026971926609812066418262;
		hashes_high[86] = 14830971245515975674738311057058641914498607248173258815034051397179244681374;
		hashes_high[87] = 14217166647119555757087725306327288194687925502956704933652244095332507655798;
		hashes_high[88] = 547306983969389587595995553981332343156250916965862592379631214007745649977;
		hashes_high[89] = 3656155244271892799963064573726879601834507173197171782726629853956772802162;
		hashes_high[90] = 14781358464052224800886738932215274250092250645928962024111235447653862234860;
		hashes_high[91] = 15571455909505245738420259714337464683152067275414831239219967015661576588710;
		hashes_high[92] = 21716627923492260554178596464018062648287236992026715240805153641751760501568;
		hashes_high[93] = 18429479145275256145040134824776204456757934083728899195807223426928145283767;
		hashes_high[94] = 14590896707984386678407661518193510796211004829846739723167955516314536488312;
		hashes_high[95] = 5364846444483935991819887639155787178688286892628055230442348393360968864165;
		hashes_high[96] = 9801622906774738403384239914839094674761724577558153039348209006591762016507;
		hashes_high[97] = 15431878162193705014848255398295325695049573682949436842449218146856708553948;
		hashes_high[98] = 20385915059841553350063953555311644679628149074969022444688004876281610915975;
		hashes_high[99] = 11236761174796376103584872853089573894584730345383658669546459654139545949581;
	}


	function getMapID(uint level, uint source) external view returns (uint) {
		if (level <= 7) {
			return source % hashes_low.length;
		} else if (level <= 12) {
			return source % hashes_mid.length;
		} else {
			return source % hashes_high.length;
		}
	}

	function verifyMap(uint map_id, uint level, uint hash) external view returns (bool) {
		if (level <= 7) {
			return hashes_low[map_id] == hash;
		} else if (level <= 12) {
			return hashes_mid[map_id] == hash;
		} else {
			return hashes_high[map_id] == hash;
		}
	}

	function verifyMapC1(uint level, uint c1) external pure returns (bool) {
		if (level <= 7) {
			return c1 == 2;
		} else if (level <= 12) {
			return c1 == 6;
		} else {
			return c1 == 17;
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

/*
Functions here are stubs for the solidity compiler to generate the right interface.
The deployed library is generated bytecode from the circomlib toolchain
*/

library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(bytes32[2] memory input) public pure returns (bytes32) {}
}

library PoseidonT4 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(bytes32[3] memory input) public pure returns (bytes32) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { SkylabMetadata } from "./SkylabMetadata.sol";
import { SkylabResources } from "./SkylabResources.sol";

contract SkylabBase is ERC721Enumerable, Ownable {
    using Strings for uint;

    // per token data
    mapping(uint => uint) public _aviationLevels;
    mapping(uint => bool) public _aviationHasWinCounter;
    mapping(uint => bool) public _aviationTradeLock;
    mapping(uint => uint) public _aviationPilotIds;
    mapping(uint => address) public _aviationPilotAddresses;

    uint internal _nextTokenID = 1;
    string internal _metadataBaseURI;
    mapping(address => mapping(uint => uint)) internal _pilotToToken;

    // addresses
    SkylabResources internal _skylabResources;
    SkylabMetadata internal _skylabMetadata;
    mapping(address => bool) internal _gameAddresses;
    mapping(address => string) internal _pilotAddressesToNames;
    mapping(address => string) internal _pilotAddressesToUrls;

    modifier onlyGameAddresses() {
        require(_gameAddresses[_msgSender()], "SkylabBase: msg.sender is not a valid game address");
        _;
    }

    constructor(string memory baseURI, string memory name, string memory symbol) ERC721(name, symbol) {
        _metadataBaseURI = baseURI;
    }

    // ====================
    // Mint 
    // ====================

    // function publicMint(address memory to) external {
    //     _safeMint(to, __nextTokenID);
    //     _aviationLevels[__nextTokenID] = 1;
    //     __nextTokenID++;
    // }


    // function addPilot(uint tokenId, uint pilotId, address pilotAddress) external {
    //     address pilotOwner = ERC721(pilotAddress).ownerOf(pilotId);
    //     require(_msgSender() == pilotOwner || ERC721(pilotAddress).isApprovedForAll(pilotOwner, _msgSender()) || ERC721(pilotAddress).getApproved(pilotId) == _msgSender(), "SkylabBase: pilot not owned by msg sender");
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    //     require(_pilotAddressesToNames[pilotAddress] != "", "SkylabBase: unregistered pilotAddress");
    //     require(_pilotToToken[pilotAddress][pilotId] == 0, "SkylabBase: pilot already added");
    //     _aviationPilotIds[tokenId] = pilotId;
    //     _aviationPilotAddresses[tokenId] = pilotAddress;
    //     _pilotToToken[pilotAddress][pilotId] = tokenId;
    // }

    // ====================
    // Aviation level 
    // ====================

    function aviationGainCounter(uint tokenId) external onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        if (!_aviationHasWinCounter[tokenId]) {
            _aviationHasWinCounter[tokenId] = true;
        } 
        else {
            _aviationHasWinCounter[tokenId] = false;
            _aviationLevels[tokenId] += 1;
        }
    }

    function aviationLevelDown(uint tokenId, uint levelDelta) external onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        if (_aviationLevels[tokenId] > levelDelta) {
            _aviationLevels[tokenId] -= levelDelta;
        } else {
            _aviationLevels[tokenId] = 0;
            burnAviation(tokenId);
        }
    }

    function burnAviation(uint tokenId) private {
        _burn(tokenId);
        _pilotToToken[_aviationPilotAddresses[tokenId]][_aviationPilotIds[tokenId]] = 0;
    }

    // ====================
    // MISC
    // ====================
    function requestResourcesForGame(address from,
        address game,
        uint256[] memory ids,
        uint256[] memory amounts) external onlyGameAddresses {
        _skylabResources.burn(from, ids, amounts);
        _skylabResources.mintBatch(game, ids, amounts, "");
    }

    function refundResourcesFromGame(address game,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts) external onlyGameAddresses {
        _skylabResources.burn(game, ids, amounts);
        _skylabResources.mintBatch(to, ids, amounts, "");
    }

    function aviationLock(uint tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(!_aviationTradeLock[tokenId], "SkylabBase: aviation locked");
        _aviationTradeLock[tokenId] = true;
    }

    function aviationUnlock(uint tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(_aviationTradeLock[tokenId], "SkylabBase: aviation not locked");
        _aviationTradeLock[tokenId] = false;
    }

    function isAviationLocked(uint tokenId) external view virtual onlyGameAddresses returns (bool) {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        return _aviationTradeLock[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) override internal virtual {
        require(!_aviationTradeLock[tokenId], "SkylabBase: token is locked");
        super._transfer(from, to, tokenId);
    } 

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }


    // // ====================
    // // Factory Mechanism
    // // ====================

    // // Stake a Factory so that it's ready to generate fuel and become prone to attack
    // function stakeFactory(uint tokenId) external _isApprovedOrOwner {

    // }

    // function unstakeFactory(uint tokenId) external _isApprovedOrOwner {

    // }

    // // If the factory has been staked for more than 7 days, claim fuel as rewards
    // function generateFuel(uint tokenId) external _isApprovedOrOwner {

    // }

    // // Defend a factory with certain amount of shields
    // function shieldFactory(uint tokenId, uint shieldCount) external _isApprovedOrOwner {

    // }

    // // Attack a random factory
    // function attackFactory(uint bombCount) external _isApprovedOrOwner {

    // }

    // =======================
    // Admin Utility
    // =======================
    function registerMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataBaseURI = metadataURI;
    }

    function registerResourcesAddress(address resourcesAddress) external onlyOwner {
        _skylabResources = SkylabResources(resourcesAddress);
    }

    function registerMetadataAddress(address metadataAddress) external onlyOwner {
        _skylabMetadata = SkylabMetadata(metadataAddress);
    }

    function registerGameAddress(address gameAddress, bool enable) external onlyOwner {
        _gameAddresses[gameAddress] = enable;
    }
    
    function registerPilotAddress(address pilotAddress, string memory pilotCollectionName, string memory baseUrl) external onlyOwner {
        _pilotAddressesToNames[pilotAddress] = pilotCollectionName;
        _pilotAddressesToUrls[pilotAddress] = baseUrl;
    }

    // // Set the number of shields generated when an Aviation of a specified level dies in a collision
    // function setShieldYield(uint level) external onlyOwner {

    // }

    // // Set the level of an Aviation for allowlist mint purpose
    // function setAviationLevel(uint tokenId) external onlyOwner {

    // }

    // // Air drop bombs for all owners of Aviation of a specified level
    // function airdropBombs(uint level, uint bombCount) external onlyOwner {

    // }

    // // Mint L1s for all owners of Aviation of a specified level
    // function airdropL1s(uint level, uint l1Counts) external onlyOwner {

    // }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        
        string memory tokenLevelString = _aviationLevels[tokenId].toString();
        if (_aviationHasWinCounter[tokenId]) {
            tokenLevelString = string(abi.encodePacked(tokenLevelString, ".5"));
        }
        string memory pilotString = "None";
        string memory baseUrl = _metadataBaseURI;
        address pilotAddress = _aviationPilotAddresses[tokenId];
        if (pilotAddress != address(0)) {
            pilotString = 
                string(abi.encodePacked(_pilotAddressesToNames[pilotAddress], " #", _aviationPilotIds[tokenId].toString()));
            baseUrl = string(abi.encodePacked(_pilotAddressesToUrls[pilotAddress], _aviationPilotIds[tokenId].toString(), "/"));
        }

        return _skylabMetadata.generateTokenMetadataa(
            tokenId.toString(), 
            string(abi.encodePacked(baseUrl, tokenLevelString, ".png")),
            tokenLevelString,
            pilotString
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { SkylabBase } from "./SkylabBase.sol";


contract SkylabGameBase is Ownable, ERC1155Holder {
    using Strings for uint;

    SkylabBase internal _skylabBase;

    // token id => address
    mapping(uint256 => address) private _gameApprovals;


    constructor(address skylabBaseAddress) {
        _skylabBase = SkylabBase(skylabBaseAddress);
    }

    // =====================
    // Approval
    // =====================
    function isApprovedForGame(uint tokenId) public view returns (bool) {
    	return _skylabBase.isApprovedOrOwner(msg.sender, tokenId) || _gameApprovals[tokenId] == msg.sender;
    }

    function approveForGame(address to, uint tokenId) external {
    	require(isApprovedForGame(tokenId), "SkylabGameBase: caller is not token owner or approved");
    	_gameApprovals[tokenId] = to;
    }

    function unapproveForGame(uint tokenId) external {
    	require(isApprovedForGame(tokenId), "SkylabGameBase: caller is not token owner or approved");
    	delete _gameApprovals[tokenId];
    }

    // =====================
    // Utils
    // ===================== 
    function registerSkylabBase(address skylabBaseAddress) external onlyOwner {
        _skylabBase = SkylabBase(skylabBaseAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PoseidonT3, PoseidonT4 } from "./poseidon.sol";
import { GameboardTraverseVerifier } from "./GameboardTraverseVerifier.sol";
import { ComputeHashPathDataVerifier } from "./ComputeHashPathDataVerifier.sol";
import { MapHashes } from "./MapHashes.sol";
import { SkylabGameBase } from "./SkylabGameBase.sol";


contract SkylabGameFlightRace is SkylabGameBase {
    struct GameTank {
        uint fuel;
        uint battery;
    }

    struct CommittedHash {
        bool first;
        uint seed_hash;
        uint time_hash;
        uint path_hash;
        uint used_resources_hash;
    }

    struct RevealedOpponentData {
        uint final_time;
        uint[101] path;
        uint[101] used_resources;
    }

    GameboardTraverseVerifier private _gameboardTraverseVerifier;
    ComputeHashPathDataVerifier private _computeHashPathDataVerifier;
    MapHashes private _mapHashes;

    // ====================
    // Gameplay data
    // ====================
    mapping(uint => uint) private matchingQueues;
    mapping(uint => uint) public gameState;
    mapping(uint => GameTank) public gameTank;

    // Static values
    uint constant searchOpponentTimeout = 300;
    uint constant getMapTimeout = 900;
    uint constant commitTimeout = 300;

    /*
    *   State 1: queueing or found opponent; Next: getMap within timeout
    */
    // id => id
    mapping(uint => uint) public matchedAviationIDs;
    // id => timeout
    mapping(uint => uint) public timeout;

    /*
    *   State 2: map found; Next: commit data within timeout
    */
    // id => id
    mapping(uint => uint) public mapId;

    /*
    *   State 3: data committed; Next: reveal data within timeout
    */
    // id => CommittedHash
    mapping(uint => CommittedHash) public committedHash;

    /*
    *   State 4: data revealed or winner determined; Next: set winner/loser state and clean up
    */
    // id => final time
    mapping(uint => RevealedOpponentData) internal revealedOpponentData;

    /*
    *   State 5: winner state
    *   State 6: loser state
    *   State 7: escape state
    */ 


    constructor(address skylabBaseAddress, address gameboardTraverseVerifierAddress, address computeHashPathDataVerifierAddress, address mapHashesAddress) SkylabGameBase(skylabBaseAddress) {
        _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
        _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
        _mapHashes = MapHashes(mapHashesAddress);
    }


    function loadFuelBatteryToGameTank(uint tokenId, uint fuel, uint battery) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "SkylabGameFlightRace: incorrect gameState");

        // PLAYTEST DISABLE uint tokenLevel = _skylabBase._aviationLevels(tokenId);
        // PLAYTEST DISABLE uint totalResourceCap = 50 * 2 ** (tokenLevel - 1);
        // PLAYTEST DISABLE require(gameTank[tokenId].fuel + fuel + gameTank[tokenId].battery + battery <= totalResourceCap, "SkylabGameFlightRace: resources exceeds resource cap");

        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint[] memory resourceAmounts = new uint[](2);
        resourceAmounts[0] = fuel;
        resourceAmounts[1] = battery;
        _skylabBase.requestResourcesForGame(_skylabBase.ownerOf(tokenId), address(this), ids, resourceAmounts);
        gameTank[tokenId].fuel += fuel;
        gameTank[tokenId].battery += battery;
    }

    // ====================
    // Aviation Collision
    // ====================

    function searchOpponent(uint tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "SkylabGameFlightRace: incorrect gameState");
        require(!_skylabBase.isAviationLocked(tokenId), "SkylabGameFlightRace: token is locked");

        _skylabBase.aviationLock(tokenId);

        uint currentQueue = matchingQueues[_skylabBase._aviationLevels(tokenId)];

        if (currentQueue == 0) {
            matchingQueues[_skylabBase._aviationLevels(tokenId)] = tokenId;
        }
        else {
            require(_skylabBase.ownerOf(tokenId) != _skylabBase.ownerOf(currentQueue), "SkylabGameFlightRace: no in-fight");
            matchedAviationIDs[tokenId] = currentQueue;
            matchedAviationIDs[currentQueue] = tokenId;
            timeout[tokenId] = block.timestamp + searchOpponentTimeout;
            timeout[currentQueue] = block.timestamp + searchOpponentTimeout;
            matchingQueues[_skylabBase._aviationLevels(tokenId)] = 0;
        }
        gameState[tokenId] = 1;
    }

    function getMap(uint tokenId) external returns (uint) {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");

        uint mapIdGenerated;
        if (mapId[matchedAviationIDs[tokenId]] != 0) {
            mapIdGenerated = mapId[matchedAviationIDs[tokenId]];
        }
        else if (tokenId < matchedAviationIDs[tokenId]) {
            mapIdGenerated = _mapHashes.getMapID(_skylabBase._aviationLevels(tokenId), uint(PoseidonT4.poseidon([bytes32(block.timestamp), bytes32(tokenId), bytes32(matchedAviationIDs[tokenId])])));
        } else {
            mapIdGenerated = _mapHashes.getMapID(_skylabBase._aviationLevels(tokenId), uint(PoseidonT4.poseidon([bytes32(block.timestamp), bytes32(matchedAviationIDs[tokenId]), bytes32(tokenId)])));
        }
        timeout[tokenId] = block.timestamp + getMapTimeout;
        mapId[tokenId] = mapIdGenerated;
        gameState[tokenId] = 2;
        return mapIdGenerated;
    }

    function commitPath(uint tokenId, 
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[9] memory input) external  {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        // seed_hash, map_hash, start_fuel_confirm, start_battery_confirm, final_time_hash, path_hash, used_resources_hash, level_scaler, c1
        require(gameState[tokenId] == 2, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(_gameboardTraverseVerifier.verifyProof(a, b, c, input), "SkylabGameFlightRace: incorrect proof");
        require(_mapHashes.verifyMap(mapId[tokenId], _skylabBase._aviationLevels(tokenId), input[1]), "SkylabGameFlightRace: map hash verification failed");
        require(gameTank[tokenId].fuel == input[2], "SkylabGameFlightRace: incorrect starting fuel");
        require(gameTank[tokenId].battery == input[3], "SkylabGameFlightRace: incorrect starting battery");
        require(2 ** (_skylabBase._aviationLevels(tokenId) - 1) == input[7], "SkylabGameFlightRace: incorrect level scaler");
        require(_mapHashes.verifyMapC1(_skylabBase._aviationLevels(tokenId), input[8]), "SkylabGameFlightRace: incorrect c1");

        // verify
        committedHash[tokenId] = CommittedHash(gameState[matchedAviationIDs[tokenId]] != 3, input[0], input[4], input[5], input[6]);
        gameState[tokenId] = 3;
        // temporarily reset timeout
        timeout[tokenId] = 0;


        if (gameState[matchedAviationIDs[tokenId]] == 3) {
            timeout[tokenId] = block.timestamp + commitTimeout;
            timeout[matchedAviationIDs[tokenId]] = block.timestamp + commitTimeout;
        }
    }

    function revealPath(uint tokenId, uint seed, uint time, 
            uint[2] memory pathA,
            uint[2][2] memory pathB,
            uint[2] memory pathC,
            uint[101] memory pathInput,
            uint[2] memory usedResourcesA,
            uint[2][2] memory usedResourcesB,
            uint[2] memory usedResourcesC,
            uint[101] memory usedResourcesInput) external  {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 3, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(gameState[matchedAviationIDs[tokenId]] >= 3, "SkylabGameFlightRace: incorrect opponent gameState");
        require(committedHash[tokenId].seed_hash == poseidon(seed, seed), "SkylabGameFlightRace: incorrect seed hash");
        require(committedHash[tokenId].time_hash == poseidon(time, seed), "SkylabGameFlightRace: incorrect time hash");
        require(committedHash[tokenId].path_hash == pathInput[0], "SkylabGameFlightRace: incorrect path hash");
        require(committedHash[tokenId].used_resources_hash == usedResourcesInput[0], "SkylabGameFlightRace: incorrect used resources hash");
        require(_computeHashPathDataVerifier.verifyProof(pathA, pathB, pathC, pathInput), "SkylabGameFlightRace: incorrect path proof");
        require(_computeHashPathDataVerifier.verifyProof(usedResourcesA, usedResourcesB, usedResourcesC, usedResourcesInput), "SkylabGameFlightRace: incorrect used resources hash");

        revealedOpponentData[matchedAviationIDs[tokenId]] = RevealedOpponentData(time, pathInput, usedResourcesInput);
        gameState[tokenId] = 4;
        // temporarily reset timeout
        timeout[tokenId] = 0;

        if (gameState[matchedAviationIDs[tokenId]] == 4) {
            if (time < revealedOpponentData[tokenId].final_time) {
                win(tokenId);
                lose(matchedAviationIDs[tokenId]);
            } else if (time == revealedOpponentData[tokenId].final_time && committedHash[tokenId].first) {
                win(tokenId);
                lose(matchedAviationIDs[tokenId]);
            }
            else {
                win(matchedAviationIDs[tokenId]);
                lose(tokenId);
            }
        }
    }

    function postGameCleanUp(uint tokenId) external  {
        require(isApprovedForGame(tokenId) || _skylabBase.ownerOf(tokenId) == address(0), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 5 || gameState[tokenId] == 6 || gameState[tokenId] == 7, "SkylabGameFlightRace: incorrect gameState");

        reset(tokenId, gameState[tokenId] == 5 || gameState[tokenId] == 6);
    }

    function claimTimeoutPenalty(uint tokenId) external  {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] > 0, "SkylabGameFlightRace: incorrect gameState");
        require(gameState[tokenId] < 5, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(timeout[matchedAviationIDs[tokenId]] > 0, "SkylabGameFlightRace: timeout isn't defined");
        require(block.timestamp > timeout[matchedAviationIDs[tokenId]], "SkylabGameFlightRace: timeout didn't pass yet");

        win(tokenId);
        lose(matchedAviationIDs[tokenId]);
    }
    
    function withdrawFromQueue(uint tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] == 0, "SkylabGameFlightRace: already has matched opponent");

        matchingQueues[_skylabBase._aviationLevels(tokenId)] = 0;
        
        reset(tokenId, false);
    }

    function retreat(uint tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1 || gameState[tokenId] == 2, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");

        escape(tokenId);
        win(matchedAviationIDs[tokenId]);
    }

    function reset(uint tokenId, bool clearTank) public {
        _skylabBase.aviationUnlock(tokenId);
        matchedAviationIDs[tokenId] = 0;
        timeout[tokenId] = 0;
        mapId[tokenId] = 0;
        delete committedHash[tokenId];
        delete revealedOpponentData[tokenId];
        if (!clearTank) {
            uint[] memory ids = new uint[](2);
            ids[0] = 0;
            ids[1] = 1;
            uint[] memory resourceAmounts = new uint[](2);
            resourceAmounts[0] = gameTank[tokenId].fuel;
            resourceAmounts[1] = gameTank[tokenId].battery;
            _skylabBase.refundResourcesFromGame(address(this), _skylabBase.ownerOf(tokenId), ids, resourceAmounts);
        }
        delete gameTank[tokenId];

        if (gameState[tokenId] == 5) {
            if (_skylabBase._aviationLevels(tokenId) == 1) {
                _skylabBase.aviationGainCounter(tokenId);
            }
            _skylabBase.aviationGainCounter(tokenId);
        } else if (gameState[tokenId] == 6 || gameState[tokenId] == 7) {
            _skylabBase.aviationLevelDown(tokenId, 1);
        }
        gameState[tokenId] = 0;
    }


    function poseidon(uint input_0, uint input_1) private pure returns (uint) {
        return uint(PoseidonT3.poseidon([bytes32(input_0), bytes32(input_1)]));
    }

    function win(uint tokenId) private {
        gameState[tokenId] = 5;
    }

    function lose(uint tokenId) private {
        gameState[tokenId] = 6;
    }

    function escape(uint tokenId) private {
        gameState[tokenId] = 7;
    }

    // Utils
    function getOpponentFinalTime(uint tokenId) external view returns (uint) {
        return revealedOpponentData[tokenId].final_time;
    }

    function getOpponentPath(uint tokenId) external view returns (uint[101] memory) {
        return revealedOpponentData[tokenId].path;
    }

    function getOpponentUsedResources(uint tokenId) external view returns (uint[101] memory) {
        return revealedOpponentData[tokenId].used_resources;
    }

    // Admin
    function refreshAddresses(address gameboardTraverseVerifierAddress, address computeHashPathDataVerifierAddress, address mapHashesAddress) external onlyOwner {
        _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
        _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
        _mapHashes = MapHashes(mapHashesAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Base64 } from "./Base64.sol";

contract SkylabMetadata {
    function generateTokenMetadataa(string memory tokenId, string memory imageUrl, string memory tokenLevelString, string memory pilotString) external pure returns (string memory) {
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#', tokenId, '",',
                        '"image": "', imageUrl, '",',
                        '"attributes": [',
                            '{',
                                '"trait_type": "Level",',
                                '"value": ', tokenLevelString, 
                            '},',
                            '{',
                                '"trait_type": "Pilot",',
                                '"value": "', pilotString, '"',
                            '}',
                        ']'
                    '}'
                    )
                )
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Design decision: no player interaction with this contract
contract SkylabResources is ERC1155, Ownable {
    address private  _sky;

    modifier onlySky() {
        require(msg.sender == _sky, "SkylabResources: msg.sender is not Sky");
        _;
    }

    constructor(address skylabBaseAddress) ERC1155("") {
        _sky = skylabBaseAddress;
    }

    function setSky(address sky) external onlyOwner {
        _sky = sky;
    }

    // Can only be minted by SkylabBase contract
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlySky {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlySky {
        _mintBatch(to, ids, amounts, data);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) override public virtual {
        
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) override public virtual {
        
    }

    function playTestNuke(address player, uint256[] memory ids) external onlySky {
        for (uint256 i = 0; i < ids.length; i++) {
            ERC1155._burn(player, ids[i], balanceOf(player, ids[i]));
        }
    }
 
    function burn(address from, uint256[] memory ids, uint256[] memory amounts) external onlySky {
        ERC1155._burnBatch(from, ids, amounts);
    }
}