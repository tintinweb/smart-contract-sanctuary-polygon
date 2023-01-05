// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
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
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
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
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "evm-gateway-contract/contracts/IGateway.sol";
import "evm-gateway-contract/contracts/Utils.sol";

/// @title CrossTalkUtils
/// @author Router Protocol
/// @notice This contract can be used to abstract the complexities while using the
/// Router CrossTalk framework.
library CrossTalkUtils {
  /// @notice Fuction to get whether the calls were executed on the destination chain.
  /// @param execFlags Array of boolean flags which indicate the execution status of calls on dest chain.
  /// @return boolean value indicating whether the calls were successfully executed on destination chain.
  function getTxStatusForAtomicCall(
    bool[] calldata execFlags
  ) internal pure returns (bool) {
    return execFlags[execFlags.length - 1] == true;
  }

  /// @notice Fuction to get the index of call out of an array of calls that failed on the destination chain.
  /// @param execFlags Array of boolean flags which indicate the execution status of calls on dest chain.
  /// @return index of call that failed
  function getTheIndexOfCallFailure(
    bool[] calldata execFlags
  ) internal pure returns (uint8) {
    require(getTxStatusForAtomicCall(execFlags), "No calls failed");

    for (uint8 i = 0; i < execFlags.length; i++) {
      if (execFlags[i] == false) {
        return i;
      }
    }

    return 0;
  }

  /// @notice Function to convert address to bytes
  /// @param addr address to be converted
  /// @return b bytes pertaining to address addr
  function toBytes(address addr) internal pure returns (bytes memory b) {
    assembly {
      let m := mload(0x40)
      addr := and(addr, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(
        add(m, 20),
        xor(0x140000000000000000000000000000000000000000, addr)
      )
      mstore(0x40, add(m, 52))
      b := m
    }
  }

  /// @notice Function to convert bytes to address
  /// @param _bytes bytes to be converted
  /// @return addr address pertaining to the bytes
  function toAddress(bytes memory _bytes) internal pure returns (address addr) {
    bytes20 srcTokenAddress;
    assembly {
      srcTokenAddress := mload(add(_bytes, 0x20))
    }
    addr = address(srcTokenAddress);
  }

  /// @notice Function to send a single request without acknowledgement to the destination chain.
  /// @dev You will be able to send a single request to a single contract on the destination chain and
  /// you don't need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddress Contract address (in bytes format) of the contract which will be
  /// called on the destination chain which will handle the payload.
  /// @param payload abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function singleRequestWithoutAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    Utils.DestinationChainParams memory destChainParams,
    bytes memory destinationContractAddress,
    bytes memory payload
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    bytes[] memory addresses = new bytes[](1);
    addresses[0] = destinationContractAddress;
    bytes[] memory payloads = new bytes[](1);
    payloads[0] = payload;

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        false,
        Utils.AckType.NO_ACK,
        Utils.AckGasParams(0, 0),
        destChainParams,
        Utils.ContractCalls(payloads, addresses)
      );
  }

  /// @notice Function to send a single request with acknowledgement to the destination chain.
  /// @dev You will be able to send a single request to a single contract on the destination chain and
  /// you need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
  /// @param ackGasParams This includes the gas limit required for the execution of handler function for
  /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddress Contract address (in bytes format) of the contract which will be
  /// called on the destination chain which will handle the payload.
  /// @param payload abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function singleRequestWithAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    Utils.AckType ackType,
    Utils.AckGasParams memory ackGasParams,
    Utils.DestinationChainParams memory destChainParams,
    bytes memory destinationContractAddress,
    bytes memory payload
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    bytes[] memory addresses = new bytes[](1);
    addresses[0] = destinationContractAddress;
    bytes[] memory payloads = new bytes[](1);
    payloads[0] = payload;

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        false,
        ackType,
        ackGasParams,
        destChainParams,
        Utils.ContractCalls(payloads, addresses)
      );
  }

  /// @notice Function to send multiple requests without acknowledgement to multiple contracts on the
  /// destination chain.
  /// @dev You will be able to send multiple requests to multiple contracts on the destination chain and
  /// you don't need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
  /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
  /// fail, others will not be affected.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddresses Array of contract addresses (in bytes format) of the contracts
  /// which will be called on the destination chain which will handle the respective payloads.
  /// @param payloads Array of abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function multipleRequestsWithoutAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    bool isAtomicCalls,
    Utils.DestinationChainParams memory destChainParams,
    bytes[] memory destinationContractAddresses,
    bytes[] memory payloads
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        isAtomicCalls,
        Utils.AckType.NO_ACK,
        Utils.AckGasParams(0, 0),
        destChainParams,
        Utils.ContractCalls(payloads, destinationContractAddresses)
      );
  }

  /// @notice Function to send multiple requests with acknowledgement to multiple contracts on the
  /// destination chain.
  /// @dev You will be able to send multiple requests to multiple contracts on the destination chain and
  /// you need the acknowledgement back on the source chain.
  /// @param gatewayContract address of the gateway contract.
  /// @param expiryTimestamp timestamp when the call expires. If this time passes by, the call will fail
  /// on the destination chain. If you don't want to add an expiry timestamp, set it to zero.
  /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
  /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
  /// fail, others will not be affected.
  /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
  /// @param ackGasParams This includes the gas limit required for the execution of handler function for
  /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
  /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
  /// required to execute handler function on the destination chain and the gas price of destination chain.
  /// @param destinationContractAddresses Array of contract addresses (in bytes format) of the contracts
  /// which will be called on the destination chain which will handle the respective payloads.
  /// @param payloads Array of abi encoded data that you want to send to the destination chain.
  /// @return Returns the nonce from the gateway contract.
  function multipleRequestsWithAcknowledgement(
    address gatewayContract,
    uint64 expiryTimestamp,
    bool isAtomicCalls,
    Utils.AckType ackType,
    Utils.AckGasParams memory ackGasParams,
    Utils.DestinationChainParams memory destChainParams,
    bytes[] memory destinationContractAddresses,
    bytes[] memory payloads
  ) internal returns (uint64) {
    if (expiryTimestamp == 0) {
      expiryTimestamp = type(uint64).max;
    }

    return
      IGateway(gatewayContract).requestToDest(
        expiryTimestamp,
        isAtomicCalls,
        ackType,
        ackGasParams,
        destChainParams,
        Utils.ContractCalls(payloads, destinationContractAddresses)
      );
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "evm-gateway-contract/contracts/ICrossTalkApplication.sol";
import "evm-gateway-contract/contracts/Utils.sol";
import "./CrossTalkUtils.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract XERC1155 is ERC1155, ICrossTalkApplication {
  address public admin;
  address public gatewayContract;
  uint64 public destGasLimit;
  // chain type + chain id => address of our contract in bytes
  mapping(uint64 => mapping(string => bytes)) public ourContractOnChains;

  struct TransferParams {
    uint256[] nftIds;
    uint256[] nftAmounts;
    bytes nftData;
    bytes recipient;
  }

  constructor(
    string memory _uri,
    address payable gatewayAddress,
    uint64 _destGasLimit
  ) ERC1155(_uri) {
    gatewayContract = gatewayAddress;
    destGasLimit = _destGasLimit;
    admin = msg.sender;

    _mint(msg.sender, 1, 10, "");
  }

  function setContractOnChain(
    uint64 chainType,
    string memory chainId,
    address contractAddress
  ) external {
    require(msg.sender == admin, "only admin");
    ourContractOnChains[chainType][chainId] = toBytes(contractAddress);
  }

  function transferCrossChain(
    uint64 chainType,
    string memory chainId,
    uint64 expiryDurationInSeconds,
    uint64 destGasPrice,
    TransferParams memory transferParams
  ) public payable {
    // burning the NFTs from the address of the user calling this function
    _burnBatch(msg.sender, transferParams.nftIds, transferParams.nftAmounts);

    bytes memory payload = abi.encode(transferParams);
    uint64 expiryTimestamp = uint64(block.timestamp) + expiryDurationInSeconds;
    Utils.DestinationChainParams memory destChainParams = Utils
      .DestinationChainParams(destGasLimit, destGasPrice, chainType, chainId);

    CrossTalkUtils.singleRequestWithoutAcknowledgement(
      gatewayContract,
      expiryTimestamp,
      destChainParams,
      ourContractOnChains[chainType][chainId], // destination contract address
      payload
    );
  }

  function handleRequestFromSource(
    bytes memory srcContractAddress,
    bytes memory payload,
    string memory srcChainId,
    uint64 srcChainType
  ) external override returns (bytes memory) {
    require(msg.sender == gatewayContract);
    require(
      keccak256(srcContractAddress) ==
        keccak256(ourContractOnChains[srcChainType][srcChainId])
    );

    TransferParams memory transferParams = abi.decode(
      payload,
      (TransferParams)
    );
    _mintBatch(
      // converting the address of recipient from bytes to address
      CrossTalkUtils.toAddress(transferParams.recipient),
      transferParams.nftIds,
      transferParams.nftAmounts,
      transferParams.nftData
    );

    return abi.encode(srcChainId, srcChainType);
  }

  function handleCrossTalkAck(
    uint64, //eventIdentifier,
    bool[] memory, //execFlags,
    bytes[] memory //execData
  ) external view override {}

  function toBytes(address a) public pure returns (bytes memory b) {
    assembly {
      let m := mload(0x40)
      a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
      mstore(0x40, add(m, 52))
      b := m
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev CrossTalk flow Interface.
 */
interface ICrossTalkApplication {
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external returns (bytes memory);

    function handleCrossTalkAck(uint64 eventIdentifier, bool[] memory execFlags, bytes[] memory execData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    function requestToRouter(bytes memory payload, string memory routerBridgeContract) external;

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory);

    function requestToDest(
        uint64 expTimestamp,
        bool isAtomicCalls,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint64 valsetNonce;
    }

    // This is being used purely to avoid stack too deep errors
    struct RouterRequestPayload {
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        uint256 relayerFee;
        uint256 outgoingTxFee;
        bool isAtomic;
        uint64 expTimestamp;
        // The user contract address
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct SourceChainParams {
        uint64 crossTalkNonce;
        uint64 expTimestamp;
        bool isAtomicCalls;
        uint64 chainType;
        string chainId;
    }
    struct SourceParams {
        bytes caller;
        uint64 chainType;
        string chainId;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        SourceParams sourceParams;
        ContractCalls contractCalls;
    }

    struct CrossTalkAckPayload {
        uint64 crossTalkNonce;
        uint64 eventIdentifier;
        uint64 destChainType;
        string destChainId;
        bytes srcContractAddress;
        bool[] execFlags;
        bytes[] execData;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint64 newNonce, uint64 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2863311530;
}