// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.16;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "../library/Address.sol";
import "../utils/Context.sol";
import "../utils/ERC165.sol";

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
        require(account != address(0), "ERC1155: address zero");
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
        require(accounts.length == ids.length, "ERC1155: arrays length mismatch");

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
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: not owner or approved");
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
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: not owner or approved");
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
        require(to != address(0), "ERC1155: transfer to address 0");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance");
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
        require(ids.length == amounts.length, "ERC1155: arrays length mismatch");
        require(to != address(0), "ERC1155: transfer to address 0");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance");
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
        require(to != address(0), "ERC1155: mint to address 0");

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
        require(to != address(0), "ERC1155: mint to address 0");
        require(ids.length == amounts.length, "ERC1155: arrays length mismatch");

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
        require(from != address(0), "ERC1155: burn from address 0");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: amount exceeds balance");
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
        require(from != address(0), "ERC1155: burn from address 0");
        require(ids.length == amounts.length, "ERC1155: arrays length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: amount exceeds balance");
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
        require(owner != operator, "ERC1155: approval for self");
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
                    revert("ERC1155: ERC1155Receiver reject");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: non-ERC1155Receiver");
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
                    revert("ERC1155: ERC1155Receiver reject");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: non-ERC1155Receiver");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity 0.8.16;

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

pragma solidity 0.8.16;

import "./IERC1155Receiver.sol";
import "../utils/ERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity 0.8.16;

import "../utils/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity 0.8.16;

import "./IERC1155.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity 0.8.16;

import "../utils/IERC165.sol";

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
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
                if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity 0.8.16;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.16;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "../library/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: invalid allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit failed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: operation failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import {SkinsNFT} from "./SkinsNFT.sol";
import {IERC20} from "./ERC20/IERC20.sol";
import {SafeERC20} from "./ERC20/SafeERC20.sol";
import {ERC1155Holder} from "./ERC1155/ERC1155Holder.sol";
import {Ownable} from "./security/Ownable.sol";
import {ReentrancyGuard} from "./security/ReentrancyGuard.sol";
import {Pausable} from "./security/Pausable.sol";
import {DSMath} from "./utils/DSMath.sol";

/**
 * @title Gamify Staking Contract - SuperUltra.io
 * @author @Pedrojok01
 */
contract GamifyStaking is ERC1155Holder, Ownable, ReentrancyGuard, Pausable, DSMath {
    using SafeERC20 for IERC20;

    /* Storage:
     ***********/

    IERC20 private token;
    SkinsNFT private skinsNft;
    address private admin; // Backend address (yield payment + API)

    struct Vault {
        uint8 apr;
        uint8 boost;
        uint256 timelock;
        uint256 totalAmountLock;
    }

    Vault[5] public vaults;

    /// @notice Struct used to store rewards info (skin NFT ids & staked amount needed);
    struct VaultRewards {
        uint8[4] rewardsIds;
    }
    VaultRewards[4] private vaultRewards; // Store all VaultRewards per _timelock

    uint256[4] private tiers = [250, 750, type(uint256).max, type(uint256).max];

    /// @notice Struct used to represent each stake;
    struct Stake {
        address user;
        bool isBoost;
        uint8 timelock;
        uint256 amount;
        uint256 since;
        uint256 unlockTime;
        uint256 claimable;
    }

    /// @notice Struct that holds all stakes per address (user)
    struct Stakeholder {
        address user;
        Stake[5] address_stakes;
    }

    /// @notice Store all Stakes performed on the Contract per index, the index can be found using the stakes mapping
    Stakeholder[] private stakeholders;

    /// @notice keep track of the INDEX for the stakers in the stakes array
    mapping(address => uint256) private stakes;

    /// @notice Struct used to easily fetch summary info for a user
    struct StakingSummary {
        uint256 total_amount;
        Stake[5] stakes;
    }

    /**
     * @notice Define the token that will be used for staking, and push once to stakeholders for index to work properly
     * @param _token the token that will be used for staking
     */
    constructor(IERC20 _token, SkinsNFT _skinsNft) {
        _initializeVaults();
        token = _token;
        skinsNft = _skinsNft;
        admin = msg.sender;
        stakeholders.push();
    }

    /***********************************************************************************
                                    STAKE FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow a user to stake his tokens
     * @param _amount Amount of tokens that the user wish to stake
     * @param _timelock Duration of staking (in months) chosen by user: 0 | 1 | 3 | 6 | 12 (determines the APR)
     */
    function stake(uint256 _amount, uint8 _timelock, bool _boost) external nonReentrant whenNotPaused {
        require(_isValidLock(_timelock), "Staking: invalid lock");
        require(_amount <= token.balanceOf(_msgSender()), "Cannot stake more than you own");
        require(_amount <= token.allowance(_msgSender(), address(this)), "Staking: not allowed");
        require(_amount > 0, "Staking: Can't stake 0");

        if (_timelock == 12) {
            require(isSuperVaultUnlocked(_msgSender()), "Staking: super vault locked");
        }

        token.safeTransferFrom(msg.sender, address(this), _amount); // Transfer tokens to staking contract
        _stake(_amount, _timelock, _boost); // Handle the new stake
    }

    function _stake(uint256 _amount, uint8 _timelock, bool _boost) private {
        uint256 index = stakes[msg.sender];
        // Check if new user:
        if (index == 0) {
            index = _addStakeholder(msg.sender);
        } else {
            // Check if stake exist for the selected vault:
            require(
                stakeholders[index].address_stakes[_getIndexFromTimelock(_timelock)].amount == 0,
                "Staking: Stake already ongoing"
            );
        }

        _addAmountToVault(_amount, _timelock);
        uint256 since = block.timestamp;
        uint256 unlockTime = since + _getLockPeriod(_timelock);

        // Check the NFT booster and transfer it to the contract:
        if (_boost) {
            uint256 initialBalance = skinsNft.balanceOf(address(this), 0);
            _activateBooster();
            require(skinsNft.balanceOf(address(this), 0) == initialBalance + 1, "Staking: booster error");
        } else _boost = false;

        stakeholders[index].address_stakes[_getIndexFromTimelock(_timelock)] = Stake(
            msg.sender,
            _boost,
            _timelock,
            _amount,
            since,
            unlockTime,
            index
        );

        if (_timelock != 0 && _amount >= _convertAmount(tiers[0])) {
            _mintRewardsIfEligible(_msgSender(), _timelock, _amount);
        }

        emit Staked(msg.sender, _boost, _timelock, _amount, index, since, unlockTime);
    }

    /**
     * @notice Add the selected amount to the selected vault;
     * @param _amount Amount to be added;
     * @param _timelock Vault to add the amount in (0 | 1 | 3 | 6 | 12);
     */
    function _addAmountToVault(uint256 _amount, uint8 _timelock) private {
        uint8 vaultIndex = _getIndexFromTimelock(_timelock);
        vaults[vaultIndex].totalAmountLock += _amount;
    }

    /**
     * @notice Allow to activate an extra APR if eligible;
     */
    function _activateBooster() private {
        require(skinsNft.balanceOf(_msgSender(), 0) > 0, "Staking: no booster found");
        require(skinsNft.isApprovedForAll(_msgSender(), address(this)), "Staking: Not authorized");
        skinsNft.safeTransferFrom(_msgSender(), address(this), 0, 1, "");
    }

    event Staked(
        address indexed user,
        bool isBoost,
        uint8 timelock,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 unlockTime
    );

    /***********************************************************************************
                                    WITHDRAW FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow a staker to withdraw his stakes from his holder's account
     * @param _timelock Used to select the corresponding vault: 0 | 1 | 3 | 6 | 12 (months);
     */
    function withdrawStake(uint8 _timelock) external nonReentrant whenNotPaused {
        uint256 userIndex = stakes[msg.sender];
        Stake memory current_stake = stakeholders[userIndex].address_stakes[_getIndexFromTimelock(_timelock)];

        uint256 amount = current_stake.amount;
        uint256 reward = _withdrawStake(_timelock);
        // Return staked tokens/booster to user
        token.safeTransfer(msg.sender, amount);
        if (current_stake.isBoost) {
            skinsNft.safeTransferFrom(address(this), _msgSender(), 0, 1, "");
        }

        // Pay earned reward to user
        token.safeTransferFrom(admin, msg.sender, reward);
        emit Withdrawn(msg.sender, _timelock, amount, reward);
    }

    /**
     * @notice Empty a stake if the lock duration is over;
     * @return reward Amount to transfer back to the acount (amount staked + reward);
     */
    function _withdrawStake(uint8 _timelock) private returns (uint256 reward) {
        uint8 vaultIndex = _getIndexFromTimelock(_timelock);
        uint256 userIndex = stakes[msg.sender];

        Stake memory current_stake = stakeholders[userIndex].address_stakes[vaultIndex];
        uint256 _amount = current_stake.amount;
        require(block.timestamp > current_stake.unlockTime, "Staking: under lock");

        reward = _calculateStakeReward(current_stake);

        current_stake.amount = 0;
        delete stakeholders[userIndex].address_stakes[vaultIndex];
        _withdrawAmountFromVault(_amount, current_stake.timelock);

        return reward;
    }

    /**
     * @notice Remove the selected amount from the selected vault;
     * @param _amount Amount to be removed;
     * @param _timelock Vault to remove the amount from (0 | 1 | 3 | 6 | 12);
     */
    function _withdrawAmountFromVault(uint256 _amount, uint8 _timelock) private {
        uint8 vaultIndex = _getIndexFromTimelock(_timelock);
        vaults[vaultIndex].totalAmountLock -= _amount;
    }

    event Withdrawn(address indexed user, uint8 indexed timelock, uint256 amount, uint256 reward);

    /***********************************************************************************
                                    VIEW FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow to check if a account has stakes and to return the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) external view returns (StakingSummary memory) {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Iterate through all stakes and grab the amount of each stake
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = _calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount += summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    /**
     * @notice Allow to to quickly fetch the total amount of tokens staked on the contract;
     */
    function getTotalStaked() external view returns (uint256) {
        uint256 totalStaked = 0;

        for (uint256 i = 0; i < vaults.length; i++) {
            totalStaked += vaults[i].totalAmountLock;
        }

        return totalStaked;
    }

    /***********************************************************************************
                                    RESTRICTED FUNCTIONS
    ************************************************************************************/

    function setToken(IERC20 _newToken) external onlyOwner {
        IERC20 oldToken = token;
        token = _newToken;
        emit NewTokenSet(oldToken, _newToken);
    }

    event NewTokenSet(IERC20 indexed oldToken, IERC20 indexed newToken);

    function setSkinsNft(SkinsNFT _newSkinsNft) external onlyOwner {
        SkinsNFT oldSkinsNft = skinsNft;
        skinsNft = _newSkinsNft;
        emit NewSkinsNFTSet(oldSkinsNft, _newSkinsNft);
    }

    event NewSkinsNFTSet(SkinsNFT indexed oldSkinsNft, SkinsNFT indexed newSkinsNft);

    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Staking: zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit NewAdminSet(oldAdmin, _newAdmin);
    }

    event NewAdminSet(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @notice The following functions allow to change the APR per lock duration;
     * @param _newApr Percent interest per year. Will be divided by 10,000,000 to get the %/day;
     * @param _timelock Indicate the lock duration: 0 | 1 | 3 | 6 | 12 (months);
     */
    function setAPR(uint8 _newApr, uint8 _timelock) external onlyOwner {
        vaults[_getIndexFromTimelock(_timelock)].apr = _newApr;
        emit NewAprSet(_newApr, _timelock);
    }

    event NewAprSet(uint8 _newApr, uint8 _timelock);

    /**
     * @notice Allow to set/add a staking tier;
     * @param _tier Used to select the tier to edit (index of "tiers" array (0,1,2,3));
     * @param _value Indicate the value to attribute to the selected tier;
     */
    function setTierAmount(uint8 _tier, uint256 _value) external onlyOwner {
        tiers[_tier] = _value;
        emit NewTierAmountSet(_tier, _value);
    }

    event NewTierAmountSet(uint8 _tier, uint256 _value);

    /**
     * @notice Allow to set/add a staking tier;
     * @param _vault Used to select the vault to edit (0 = 1 month | 1 = 3 months | 2 = 6 months | 3 = 12 months);
     * @param _tier Used to select the tier to edit (index of "tiers" array (0,1,2,3));
     * @param _id Indicate the id of the Skin NFT to be rewarded;
     */
    function setTierReward(uint8 _vault, uint8 _tier, uint8 _id) external onlyOwner {
        vaultRewards[_vault].rewardsIds[_tier] = _id;
        emit NewTierRewardSet(_vault, _tier, _id);
    }

    event NewTierRewardSet(uint8 indexed vault, uint8 tier, uint8 id);

    /**
     * @notice Allow to pause staking/withawal in case of emergency;
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allow to unpause staking/withawal if paused;
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /***********************************************************************************
                                    PRIVATE FUNCTIONS
    ************************************************************************************/

    function _initializeVaults() private {
        vaults[0] = Vault({boost: 1, timelock: 0, apr: 2, totalAmountLock: 0});
        vaults[1] = Vault({boost: 2, timelock: 30 days, apr: 3, totalAmountLock: 0});
        vaults[2] = Vault({boost: 3, timelock: 90 days, apr: 4, totalAmountLock: 0});
        vaults[3] = Vault({boost: 4, timelock: 180 days, apr: 5, totalAmountLock: 0});
        vaults[4] = Vault({boost: 5, timelock: 360 days, apr: 6, totalAmountLock: 0});

        vaultRewards[0] = VaultRewards({rewardsIds: [uint8(1), 3, 4, 6]});
        vaultRewards[1] = VaultRewards({rewardsIds: [2, 0, 5, 0]});
        vaultRewards[2] = VaultRewards({
            rewardsIds: [type(uint8).max, type(uint8).max, type(uint8).max, type(uint8).max]
        });
        vaultRewards[3] = VaultRewards({
            rewardsIds: [type(uint8).max, type(uint8).max, type(uint8).max, type(uint8).max]
        });
    }

    /**
     * @notice Add a stakeholder to the "stakeholders" array if new user;
     * @return userIndex The user index in the "stakeholders" array;
     */
    function _addStakeholder(address staker) private returns (uint256 userIndex) {
        stakeholders.push();
        userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice Mint a Skin NFT to the recipient if eligible;
     * @param _recipient Staker address who will receive the Skin NFT if eligible;
     * @param _timelock Lock duration: 0 | 1 | 3 | 6 | 12 (months);
     * @param _amount Amount staked, used to select the reward tier;
     */
    function _mintRewardsIfEligible(address _recipient, uint8 _timelock, uint256 _amount) private {
        uint8 tier = _getTierForAmount(_amount); // from 0 to 3

        for (int8 i = int8(tier); i >= 0; i--) {
            VaultRewards memory rewards = vaultRewards[uint8(i)]; // uint8[4] NFT ids per tier
            uint8 index = _getVaultRewardsIndexFromTimelock(_timelock);
            uint8 nftId = rewards.rewardsIds[index];

            if (!skinsNft.getSkinMintStatusForId(_recipient, nftId)) {
                skinsNft.mint(nftId, _recipient, 1);
                break;
            }
        }
    }

    /**
     * @notice Calculate how much a user should be rewarded for his stakes;
     * @return reward Amount won based on: vault APR, NFT boost (if any), number of days, amount staked;
     */
    function _calculateStakeReward(Stake memory _current_stake) private view returns (uint256 reward) {
        uint256 apr = 0;
        uint8 vaultIndex = _getIndexFromTimelock(_current_stake.timelock);

        if (_current_stake.isBoost) {
            apr = _getAprFromPercent(vaults[vaultIndex].apr + vaults[vaultIndex].boost);
        } else {
            apr = _getAprFromPercent(vaults[vaultIndex].apr);
        }

        // Calculation: numbers of days * amount staked * APR
        reward = wmul((((block.timestamp - _current_stake.since) / 1 days) * _current_stake.amount), apr);
        return reward;
    }

    /***********************************************************************************
                                    UTILS FUNCTIONS
    ************************************************************************************/

    function _isValidLock(uint8 _timelock) private pure returns (bool) {
        if (_timelock == 0 || _timelock == 1 || _timelock == 3 || _timelock == 6 || _timelock == 12) return true;
        else return false;
    }

    function _getLockPeriod(uint8 _timelock) private view returns (uint256) {
        return vaults[_getIndexFromTimelock(_timelock)].timelock;
    }

    /**
     * @notice Return the tier index used to determine a potential Skin NFT rewards;
     */
    function _getTierForAmount(uint256 _amount) private view returns (uint8) {
        if (_amount >= _convertAmount(tiers[0]) && _amount < _convertAmount(tiers[1])) return 0;
        else if (_amount >= _convertAmount(tiers[1]) && _amount < _convertAmount(tiers[2])) return 1;
        else if (_amount >= _convertAmount(tiers[2]) && _amount < _convertAmount(tiers[3])) return 2;
        else if (_amount >= _convertAmount(tiers[3])) return 3;
        else revert("invalid amount");
    }

    /**
     * @notice Return the vault index to get the stake corresponding the the selected vault (_timelock);
     */
    function _getIndexFromTimelock(uint8 _timelock) private pure returns (uint8) {
        if (_timelock == 0 || _timelock == 1) return _timelock;
        else if (_timelock == 3) return 2;
        else if (_timelock == 6) return 3;
        else if (_timelock == 12) return 4;
        else revert("Staking: invalid lock");
    }

    function _getAprFromPercent(uint16 _percent) private pure returns (uint256) {
        return wdiv(_percent * 274, 1e7); // eg: 5% APR == 0.0001370/day
    }

    function _convertAmount(uint256 _amount) private pure returns (uint256) {
        if (_amount != type(uint256).max) return _amount * 10 ** 18;
        else return _amount;
    }

    /**
     * @notice Return the tier index to get the Skin NFT rewards corresponding the the selected vault (_timelock);
     */
    function _getVaultRewardsIndexFromTimelock(uint8 _timelock) private pure returns (uint8) {
        if (_timelock == 1) return 0;
        else if (_timelock == 3) return 1;
        else if (_timelock == 6) return 2;
        else if (_timelock == 12) return 3;
        else revert("Staking: invalid lock");
    }

    function isSuperVaultUnlocked(address _staker) private view returns (bool isUnlocked) {
        isUnlocked = false;

        for (uint256 i = 1; i < 6; i++) {
            if (skinsNft.balanceOf(_staker, i) == 0) return isUnlocked;
        }

        isUnlocked = true;
        return isUnlocked;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity 0.8.16;

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
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * eslint-disable-next-line max-len
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
        require(address(this).balance >= value, "Address: insufficient balance");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.16;

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
        require(owner() == _msgSender(), "Ownable: caller isn't owner");
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
        require(newOwner != address(0), "Ownable: new owner = address 0");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity 0.8.16;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.16;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import {ERC1155} from "./ERC1155/ERC1155.sol";
import {Ownable} from "./security/Ownable.sol";
import {ReentrancyGuard} from "./security/ReentrancyGuard.sol";
import {Pausable} from "./security/Pausable.sol";

/** 
@title NFT ERC1155 contract to be used with the SuperUltra Casual Gaming Platform
@author @Pedrojok01
*/

contract SkinsNFT is ERC1155, Ownable, ReentrancyGuard, Pausable {
    /* Storage:
     ************/
    address private gamifyStaking = address(0x000000000000000000000000000000000000dEaD);

    struct Skin {
        uint8 id;
        uint128 amount;
        bytes32 name;
        mapping(address => bool) minted;
    }

    Skin[] public skins;

    mapping(uint8 => bytes32) internal getName; // get name from id
    mapping(bytes32 => uint8) internal getId; // get id from name

    constructor() ERC1155("ipfs://Qmd6sxmAvamKGc2UyvhiKho6qmVeJp1zaWbar9mfeDNCGv/metadata/{id}.json") {
        // Automatically set the NFT Booster at index 0
        _initialize();
    }

    /* View functions:
     *******************/

    function getSkinNameFromId(uint8 _id) external view returns (bytes32) {
        return getName[_id];
    }

    function getSkinIdFromName(bytes32 _name) external view returns (uint8) {
        // @ToDo Take a string or bytes32 as args????
        return getId[_name];
    }

    function getSkinAmount(uint8 _id) external view returns (uint128) {
        return skins[_id].amount;
    }

    function getNumberOfSkins() external view returns (uint256) {
        return skins.length;
    }

    function getSkinMintStatusForId(address _recipient, uint8 _id) external view returns (bool) {
        return skins[_id].minted[_recipient];
    }

    /* Restricted functions:
     ************************/

    function addNewSkin(uint8 _id, bytes32 _name) external onlyOwner {
        require(_id == skins.length, "SkinsNFT: id invalid");
        require(getId[_name] == 0, "SkinsNFT: name already exist");
        _addNewSkin(_id, _name);
    }

    function batchAddNewSkin(uint8[] calldata _id, bytes32[] calldata _name) external onlyOwner {
        require(_id.length == _name.length, "SkinsNFT: array mismatched");
        uint256 length = _id.length;

        for (uint256 i = 0; i < length; i++) {
            _addNewSkin(_id[i], _name[i]);
        }
    }

    /**
    @dev Limited mint, only the owner can mint the level 2 and above NFTs;
    @param id Allow to choose the kind of NFT to be minted;
    @param recipient Address which will receive the limited NFTs;
    @param amount Amount of NFTs to be minted to the recipient;
    */
    function mint(uint256 id, address recipient, uint128 amount) external nonReentrant whenNotPaused {
        require(_msgSender() == owner() || _msgSender() == gamifyStaking, "SkinsNFT: not authorised");
        require(_isValidSkin(id), "SkinsNFT: wrong parameter");

        skins[id].amount += amount;
        if (_msgSender() == gamifyStaking) {
            skins[id].minted[recipient] = true;
        }
        _mint(recipient, id, amount, "");
    }

    // @ToDo batchMint onlyOwner

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
        emit NewURISet(newuri);
    }

    event NewURISet(string newuri);

    function setStakingAddress(address _newStakingAddress) external onlyOwner {
        require(_newStakingAddress != address(0), "SkinsNFT: address 0");
        gamifyStaking = _newStakingAddress;
    }

    /* Private functions:
     **********************/

    function _initialize() private {
        skins.push();
        skins[0].id = 0;
        skins[0].amount = 0;
        skins[0].name = stringToBytes32("Booster");

        getName[0] = stringToBytes32("Booster");
        getId[stringToBytes32("Booster")] = 0;
    }

    function _isValidSkin(uint256 _id) private view returns (bool) {
        if (_id <= skins.length) {
            return true;
        } else {
            return false;
        }
    }

    function _addNewSkin(uint8 _id, bytes32 _name) private {
        skins.push();
        skins[_id].id = _id;
        skins[_id].amount = 0;
        skins[_id].name = _name;

        getName[_id] = _name;
        getId[_name] = _id;

        emit NewSkinAdded(_id, _name);
    }

    event NewSkinAdded(uint8 id, bytes32 name);

    /* Utils:
     **********/

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.16;

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

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.16;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 private constant WAD = 10 ** 18;
    uint256 private constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.16;

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

pragma solidity 0.8.16;

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