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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRaffleDrawV3 {
    enum Tier {
        Common,
        Rare,
        Epic
    }

    enum DrawStatus {
        ACTIVE,
        COMPLETED,
        INACTIVE
    }

    struct Draw {
        uint40 endDate;
        uint24 totalEntries;
        uint24 currentEntries;
        uint24 maxEntriesPerWallet;
        uint24 numberOfPrizes;
        uint24 numberOfPlayers;
        DrawStatus status;
        Tier tier;
        string name;
        string description;
        string imageUrl;
    }

    struct DrawMetadata {
        // index start from 1
        mapping(uint256 => address) indexToPlayer;
        // number of bought entries of each player
        mapping(address => uint256) boughtEntries;
    }

    struct DrawPlayerStatus {
        bool canBuyEntries;
        uint256 availableEntries;
    }

    struct DrawWinner {
        uint256[] drawEntries;
        mapping(uint256 => bool) entryMapping;
    }

    event RaffleDrawAdded(
        uint256 indexed id,
        DrawStatus indexed status,
        Tier indexed tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes,
        string name
    );

    event RaffleDrawUpdated(
        uint256 indexed id,
        Tier indexed tier,
        uint40 endDate,
        uint24 totalEntries,
        uint24 maxEntriesPerWallet,
        uint24 numberOfPrizes
    );

    event RaffleDrawDescUpdated(uint256 indexed id, string name, string description, string imageUrl);

    event RaffleDrawStatusUpdated(uint256 indexed id, DrawStatus status);

    event RaffleDrawEntriesBought(uint256 indexed id, address player, uint256 boughtEntries);

    event RaffleDrawEntriesAssigned(uint256 indexed id, address[] players, uint256[] assignedEntries);

    event RaffleDrawWinnerPicked(uint256 indexed id, address[] winners);

    /**
     * buy entries in a Raffle Draw with Luck tokens
     * Common Raffles: Gold tokens = 4 entries, Silver token = 2 entries, Bronze token = 1 entry.
     * Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
     * Epic Raffles: Gold token = 1 entry.
     */
    function buyEntries(
        uint256 _id,
        uint256[] calldata _luckyTokenIds,
        uint256[] calldata _numberOfTokens
    ) external;

    /** admin only - START **/

    /**
     * pick winners - manager only
     */
    function pickWinners(uint256 _id) external;

    /**
     * add new raffle draw
     */
    function addRaffleDraw(
        Tier _tier,
        uint40 _endDate,
        uint24 _totalEntries,
        uint24 _maxEntriesPerWallet,
        uint24 _numberOfPrizes,
        string calldata _name
    ) external;

    /**
     * update raffle draw end date
     */
    function updateRaffleDraw(
        uint256 _id,
        Tier _tier,
        uint40 _endDate,
        uint24 _totalEntries,
        uint24 _maxEntriesPerWallet,
        uint24 _numberOfPrizes
    ) external;

    /**
     * update raffle draw description
     */
    function updateRaffleDrawDesc(
        uint256 _id,
        string calldata _name,
        string calldata _description,
        string calldata _imageUrl
    ) external;

    /**
     * set raffle draw status
     */
    function activateRaffleDraw(uint256 _id, bool _isActive) external;

    /**
     * assign entries directly
     */
    function assignEntries(uint256 _id, address[] calldata _players, uint256[] calldata _entries) external;

    /** admin only - END **/

    /** owner only - START **/

    /**
     * set external contract addresses
     */
    function setExternalContractAddresses(address _luckyTokenAddr) external;

    /**
     * set admin
     */
    function setAdmin(address _addr, bool _isAdmin) external;

    /** owner only - END **/

    /**
     * find draws
     */
    function findRaffleDraws(uint256[] calldata _ids) external view returns (Draw[] memory draws);

    /**
     * get draw status for a player
     */
    function getDrawPlayerStatus(
        address _player,
        uint256[] calldata _ids
    ) external view returns (DrawPlayerStatus[] memory _statuses);

    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function calculateNumberOfEntries(
        Tier _tier,
        uint256[] calldata _luckyTokenIds,
        uint256[] calldata _numberOfTokens
    ) external pure returns (uint256 _numberOfEntries);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin-4.8/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin-4.8/contracts/access/Ownable.sol";

import "../ERC1155/IChibiLuckyToken.sol";
import "./IRaffleDrawV3.sol";

error Unauthorized();
error InvalidRaffleId();
error InvalidLuckyToken();
error NotEnoughLuckyToken();
error InvalidStatus();
error TooLateToBuyEntries();
error ExceedMaximumAvailableEntries();
error ExceedMaximumAvailableEntriesForAWallet();
error ArrayLengthNotMatch();
error NotAbleToPickWinnerYet();
error RaffleAlreadyCompleted();
error RaffleEntriesHaveAlreadyBeenBought();
error InvalidEntries();

contract RaffleDrawV3 is Ownable, IRaffleDrawV3 {
    /** --------------------STORAGE VARIABLES-------------------- */
    /**
     * raffle draws
     */
    mapping(uint256 => Draw) public raffleDraws;
    /**
     * the total number of raffle draws
     */
    uint256 public totalRaffleDraws;
    /**
     * external contracts
     */
    ERC1155Burnable public luckyTokenContract;
    /**
     * draw metadata
     */
    mapping(uint256 => DrawMetadata) private drawMetadata;
    /**
     * number of existing raffle draws
     */
    uint256 public numberOfExistingRaffleDraws;
    /**
     * admins
     */
    mapping(address => bool) public admins;

    /** --------------------STORAGE VARIABLES-------------------- */

    constructor(uint256 _numberOfExistingRaffleDraws) {
        numberOfExistingRaffleDraws = _numberOfExistingRaffleDraws;
        totalRaffleDraws = _numberOfExistingRaffleDraws;
    }

    /** --------------------MODIFIERS-------------------- */

    /**
     * Throws exception if not a admin
     */
    modifier onlyAdmin() {
        if (!admins[_msgSender()]) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * Throws exception if invalid raffle draw id
     */
    modifier onlyValidRaffle(uint256 _id) {
        if (_id >= totalRaffleDraws) {
            revert InvalidRaffleId();
        }
        _;
    }

    /** --------------------MODIFIERS-------------------- */

    /** --------------------EXTERNAL FUNCTIONS-------------------- */
    /**
     * see {IRaffleDraw-buyEntries}
     */
    function buyEntries(
        uint256 _id,
        uint256[] calldata _luckyTokenIds,
        uint256[] calldata _numberOfTokens
    ) external override onlyValidRaffle(_id) {
        // CHECK
        if (_luckyTokenIds.length == 0){
            revert InvalidLuckyToken();
        }
        if (_luckyTokenIds.length != _numberOfTokens.length){
            revert ArrayLengthNotMatch();
        }
        Draw memory draw = raffleDraws[_id];
        if (draw.status != DrawStatus.ACTIVE){
            revert InvalidStatus();
        }
        if (draw.endDate < block.timestamp){
            revert TooLateToBuyEntries();
        }

        uint24 newEntries = uint24(_calculateNumberOfEntries(draw.tier, _luckyTokenIds, _numberOfTokens));
        if ((drawMetadata[_id].boughtEntries[msg.sender] + newEntries) > draw.maxEntriesPerWallet){
            revert ExceedMaximumAvailableEntriesForAWallet();
        }
        if ((draw.currentEntries + newEntries) > draw.totalEntries){
            revert ExceedMaximumAvailableEntries();
        }

        for (uint256 i = 0; i < _luckyTokenIds.length; i++) {
            if (_numberOfTokens[i] == 0){
                revert InvalidLuckyToken();
            }
            if (_numberOfTokens[i] > luckyTokenContract.balanceOf(msg.sender, _luckyTokenIds[i])){
                revert NotEnoughLuckyToken();
            }
        }

        // EFFECTS
        // burn Lucky tokens before buying entries
        luckyTokenContract.burnBatch(msg.sender, _luckyTokenIds, _numberOfTokens);

        // ACTIONS
        // update currentEntries;
        raffleDraws[_id].currentEntries += newEntries;
        // update unique players
        uint24 currentPlayers = raffleDraws[_id].numberOfPlayers;
        uint256 currentBoughtEntries = drawMetadata[_id].boughtEntries[msg.sender];
        if (currentBoughtEntries == 0) {
            // add a new unique player
            drawMetadata[_id].indexToPlayer[currentPlayers] = msg.sender;
            currentPlayers += 1;
            raffleDraws[_id].numberOfPlayers = currentPlayers;
        }
        // update bought entries
        drawMetadata[_id].boughtEntries[msg.sender] = currentBoughtEntries + newEntries;

        emit RaffleDrawEntriesBought(_id, msg.sender, newEntries);
    }

    /** admin only - START **/

    /**
     * see {IRaffleDraw-pickWinners}
     */
    function pickWinners(uint256 _id) external override onlyAdmin onlyValidRaffle(_id) {
        Draw memory draw = raffleDraws[_id];
        if (draw.status != DrawStatus.ACTIVE){
            revert InvalidStatus();
        }
        if (draw.endDate >= block.timestamp){
            revert NotAbleToPickWinnerYet();
        }

        address[] memory winners;
        if (draw.numberOfPlayers <= draw.numberOfPrizes) {
            // all are winners
            winners = new address[](draw.numberOfPlayers);
            for (uint256 i = 0; i < draw.numberOfPlayers; i++) {
                winners[i] = drawMetadata[_id].indexToPlayer[i];
            }
        } else {
            winners = new address[](draw.numberOfPrizes);
            uint256 remainedTotalEntries;
            uint256 remainedPlayers = draw.numberOfPlayers;
            address[] memory players = new address[](draw.numberOfPlayers);
            uint256[] memory boughtEntries = new uint256[](draw.numberOfPlayers);

            for (uint256 i = 0; i < draw.numberOfPlayers; i++) {
                players[i] = drawMetadata[_id].indexToPlayer[i];
                boughtEntries[i] = drawMetadata[_id].boughtEntries[players[i]];
                remainedTotalEntries += boughtEntries[i];
            }

            for (uint256 i = 0; i < draw.numberOfPrizes; i++) {
                // get a random entry
                uint256 randomEntry = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.number,
                            i == 0 ? address(0) : winners[i - 1], // previous winner
                            i
                        )
                    )
                ) % remainedTotalEntries;
                // find matching player
                uint256 checkedEntries = 0;
                for (uint256 j = 0; j < remainedPlayers; j++) {
                    checkedEntries += boughtEntries[j];
                    if (randomEntry < checkedEntries) {
                        // pick winner
                        winners[i] = players[j];
                        remainedTotalEntries -= boughtEntries[j];
                        if (j < remainedPlayers - 1) {
                            //switch last remained player to the current position
                            players[j] = players[remainedPlayers - 1];
                            boughtEntries[j] = boughtEntries[remainedPlayers - 1];
                        }
                        break;
                    }
                }

                // decrease remained players
                remainedPlayers -= 1;
            }
        }

        emit RaffleDrawWinnerPicked(_id, winners);

        raffleDraws[_id].status = DrawStatus.COMPLETED;
        emit RaffleDrawStatusUpdated(_id, DrawStatus.COMPLETED);
    }

    /**
     * see {IRaffleDraw-addRaffleDraw}
     */
    function addRaffleDraw(
        Tier _tier,
        uint40 _endDate,
        uint24 _totalEntries,
        uint24 _maxEntriesPerWallet,
        uint24 _numberOfPrizes,
        string calldata _name
    ) external override onlyAdmin {
        uint256 id = totalRaffleDraws;
        raffleDraws[id] = Draw({
            tier: _tier,
            status: DrawStatus.INACTIVE,
            endDate: _endDate,
            totalEntries: _totalEntries,
            maxEntriesPerWallet: _maxEntriesPerWallet,
            numberOfPrizes: _numberOfPrizes,
            numberOfPlayers: 0,
            name: _name,
            description: "",
            imageUrl: "",
            currentEntries: 0
        });
        ++totalRaffleDraws;

        emit RaffleDrawAdded(
            id,
            DrawStatus.INACTIVE,
            _tier,
            _endDate,
            _totalEntries,
            _maxEntriesPerWallet,
            _numberOfPrizes,
            _name
        );
    }

    /**
     * see {IRaffleDraw-updateRaffleDraw}
     */
    function updateRaffleDraw(
        uint256 _id,
        Tier _tier,
        uint40 _endDate,
        uint24 _totalEntries,
        uint24 _maxEntriesPerWallet,
        uint24 _numberOfPrizes
    ) external override onlyAdmin onlyValidRaffle(_id) {
        if (raffleDraws[_id].status != DrawStatus.INACTIVE){
            revert InvalidStatus();
        }

        raffleDraws[_id].tier = _tier;
        raffleDraws[_id].endDate = _endDate;
        raffleDraws[_id].totalEntries = _totalEntries;
        raffleDraws[_id].maxEntriesPerWallet = _maxEntriesPerWallet;
        raffleDraws[_id].numberOfPrizes = _numberOfPrizes;

        emit RaffleDrawUpdated(_id, _tier, _endDate, _totalEntries, _maxEntriesPerWallet, _numberOfPrizes);
    }

    /**
     * see {IRaffleDraw-updateRaffleDrawDesc}
     */
    function updateRaffleDrawDesc(
        uint256 _id,
        string calldata _name,
        string calldata _description,
        string calldata _imageUrl
    ) external override onlyAdmin onlyValidRaffle(_id) {
        raffleDraws[_id].name = _name;
        raffleDraws[_id].description = _description;
        raffleDraws[_id].imageUrl = _imageUrl;

        emit RaffleDrawDescUpdated(_id, _name, _description, _imageUrl);
    }

    /**
     * see {IRaffleDraw-activateRaffleDraw}
     */
    function activateRaffleDraw(uint256 _id, bool _isActive) external override onlyAdmin onlyValidRaffle(_id) {
        if (raffleDraws[_id].status == DrawStatus.COMPLETED) {
            revert RaffleAlreadyCompleted();
        }
        if (raffleDraws[_id].status == DrawStatus.INACTIVE && _isActive) {
            raffleDraws[_id].status = DrawStatus.ACTIVE;
            emit RaffleDrawStatusUpdated(_id, DrawStatus.ACTIVE);
        } else if (raffleDraws[_id].status == DrawStatus.ACTIVE && !_isActive) {
            if (raffleDraws[_id].currentEntries != 0) {
                revert RaffleEntriesHaveAlreadyBeenBought();
            }
            raffleDraws[_id].status = DrawStatus.INACTIVE;
            emit RaffleDrawStatusUpdated(_id, DrawStatus.INACTIVE);
        }
    }

    /**
     * assign entries directly
     */
    function assignEntries(
        uint256 _id,
        address[] calldata _players,
        uint256[] calldata _entries
    ) external override onlyAdmin {
        // CHECK
        if (_id >= totalRaffleDraws) {
            revert InvalidRaffleId();
        }
        Draw memory draw = raffleDraws[_id];
        if (draw.status != DrawStatus.ACTIVE){
            revert InvalidStatus();
        }
        if (draw.endDate < block.timestamp){
            revert TooLateToBuyEntries();
        }


        uint256 numberOfAddresses = _players.length;
        uint256 totalNewEntries;
        for (uint256 i; i < numberOfAddresses; i++) {
            address currentPlayer = _players[i];
            uint256 entriesForCurrentPlayer = _entries[i];
            if (entriesForCurrentPlayer == 0){
                revert InvalidEntries();
            }
            if ((drawMetadata[_id].boughtEntries[currentPlayer] + entriesForCurrentPlayer) >
                    draw.maxEntriesPerWallet){
                revert ExceedMaximumAvailableEntriesForAWallet();
            }
            totalNewEntries += entriesForCurrentPlayer;
        }
        if ((draw.currentEntries + totalNewEntries) > draw.totalEntries){
            revert ExceedMaximumAvailableEntries();
        }

        // EFFECTS & ACTIONS
        raffleDraws[_id].currentEntries += uint24(totalNewEntries);
        // update unique players
        uint24 currentPlayers = raffleDraws[_id].numberOfPlayers;
        for (uint256 i; i < numberOfAddresses; i++) {
            address currentPlayer = _players[i];
            uint256 entriesForCurrentPlayer = _entries[i];
            uint256 currentBoughtEntries = drawMetadata[_id].boughtEntries[currentPlayer];
            if (currentBoughtEntries == 0) {
                // add a new unique player
                drawMetadata[_id].indexToPlayer[currentPlayers] = currentPlayer;
                currentPlayers += 1;
                raffleDraws[_id].numberOfPlayers = currentPlayers;
            }
            // update bought entries
            drawMetadata[_id].boughtEntries[currentPlayer] = currentBoughtEntries + entriesForCurrentPlayer;
        }
        emit RaffleDrawEntriesAssigned(_id, _players, _entries);
    }

    /** admin only - END **/

    /** owner only - START **/

    /**
     * see {IRaffleDraw-setExternalContractAddresses}
     */
    function setExternalContractAddresses(address _luckyTokenAddr) external override onlyOwner {
        luckyTokenContract = ERC1155Burnable(_luckyTokenAddr);
    }

    /**
     * see {IRaffleDraw-setAdmin}
     */
    function setAdmin(address _addr, bool _isAdmin) external override onlyOwner {
        admins[_addr] = _isAdmin;
    }

    /** owner only - END **/

    /**
     * see {IRaffleDraw-findRaffleDraws}
     */
    function findRaffleDraws(uint256[] calldata _ids) external view override returns (Draw[] memory draws) {
        draws = new Draw[](_ids.length);
        for (uint256 i = 0; i < draws.length; i++) {
            draws[i] = raffleDraws[_ids[i]];
        }
    }

    /**
     * see {IRaffleDraw-getDrawPlayerStatus}
     */
    function getDrawPlayerStatus(
        address _player,
        uint256[] calldata _ids
    ) external view override returns (DrawPlayerStatus[] memory statuses) {
        statuses = new DrawPlayerStatus[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            Draw memory draw = raffleDraws[_ids[i]];
            if (draw.status == DrawStatus.ACTIVE && draw.endDate >= block.timestamp) {
                uint256 walletAvailableEntries = draw.maxEntriesPerWallet -
                    drawMetadata[_ids[i]].boughtEntries[_player];
                uint256 drawAvailableEntries = draw.totalEntries - draw.currentEntries;
                bool canBuyEntries = walletAvailableEntries > 0 && drawAvailableEntries > 0;
                uint256 availableEntries = walletAvailableEntries;
                if (availableEntries > drawAvailableEntries) {
                    availableEntries = drawAvailableEntries;
                }
                statuses[i] = DrawPlayerStatus({canBuyEntries: canBuyEntries, availableEntries: availableEntries});
            }
        }
    }

    /**
     * see {IRaffleDraw-calculateNumberOfEntries}
     */
    function calculateNumberOfEntries(
        Tier _tier,
        uint256[] calldata _luckyTokenIds,
        uint256[] calldata _numberOfTokens
    ) external pure override returns (uint256 numberOfEntries) {
        numberOfEntries = _calculateNumberOfEntries(_tier, _luckyTokenIds, _numberOfTokens);
    }

    /** --------------------EXTERNAL FUNCTIONS-------------------- */

    /** --------------------PRIVATE FUNCTIONS-------------------- */
    /**
     * calculate number of entries can be bought using luck tokens (based on tier)
     */
    function _calculateNumberOfEntries(
        Tier _tier,
        uint256[] calldata _luckyTokenIds,
        uint256[] calldata _numberOfTokens
    ) private pure returns (uint256 numberOfEntries) {
        for (uint256 i = 0; i < _luckyTokenIds.length; i++) {
            if (_tier == Tier.Common) {
                // Common Raffles: Gold(1) tokens = 4 entries, Silver(2) token = 2 entries, Bronze(3) token = 1 entry.
                if (_luckyTokenIds[i] < 1 || _luckyTokenIds[i] > 3){
                    revert InvalidLuckyToken();
                }
                if (_luckyTokenIds[i] == 1) {
                    numberOfEntries += 4 * _numberOfTokens[i];
                } else if (_luckyTokenIds[i] == 2) {
                    numberOfEntries += 2 * _numberOfTokens[i];
                } else {
                    numberOfEntries += _numberOfTokens[i];
                }
            } else if (_tier == Tier.Rare) {
                // Rare Raffles: Gold token = 2 entries, Silver token = 1 entry.
                if (_luckyTokenIds[i] < 1 || _luckyTokenIds[i] > 2){
                    revert InvalidLuckyToken();
                }
                if (_luckyTokenIds[i] == 1) {
                    numberOfEntries += 2 * _numberOfTokens[i];
                } else {
                    numberOfEntries += _numberOfTokens[i];
                }
            } else {
                // Epic Raffles: Gold token = 1 entry.
                if (_luckyTokenIds[i] != 1){
                    revert InvalidLuckyToken();
                }
                numberOfEntries += _numberOfTokens[i];
            }
        }
    }
    /** --------------------PRIVATE FUNCTIONS-------------------- */
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

interface IChibiLuckyToken {
    /**
     * free mint, each wallet can only mint one token
     */
    function freeMint() external;

    /**
     * mint tokens with $SHIN
     */
    function mintWithShin(uint256 numberOfTokens) external;

    /**
     * mint tokens with Seals. Each seal can only be used once.
     */
    function mintWithSeals(uint256[] calldata sealTokenIds) external;

    /**
     * mint tokens with Chibi Legends. Each Legend can only be used once.
     */
    function mintWithChibiLegends(uint256[] calldata legendTokenIds) external;

    /**
     * check if can use Seals to mint
     */
    function canUseSeals(uint16[] calldata sealTokenIds) external view returns (bool[] memory statuses);

    /**
     * check if can use Chibi Legends to mint
     */
    function canUseChibiLegends(uint16[] calldata legendTokenIds) external view returns (bool[] memory statuses);

    /**
     * mint - only minter
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * mint batch - only minter
     */
    function mintBatch(
        address[] calldata addresses,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * set base token URI & extension - only contract owner
     */
    function setURI(string memory newUri, string memory newExtension) external;

    /**
     * set external contract addresses (Shin) - only contract owner
     */
    function setExternalContractAddresses(address shinAddr, address chibiLegendAddr, address sealAddr) external;

    /*
     * enable/disable mint - only contract owner
     */
    function enableMint(bool shouldEnableMintWithShin) external;

    /*
     * enable/disable free mint - only contract owner
     */
    function enableFreeMint(bool shouldFreeMintEnabled, uint256 newTotalFreeMint) external;

    /*
     * enable/disable mint with Seals - only contract owner
     */
    function enableMintWithSeals(bool shouldEnableMintWithSeals) external;

    /*
     * enable/disable mint with Legends - only contract owner
     */
    function enableMintWithLegends(bool shouldEnableMintWithLegends) external;

    /*
     * set mint cost ($SHIN) - only contract owner
     */
    function setMintCost(uint256 newCost) external;

    /**
     * set Chibi Legend - Lucky Token mapping
     */
    function setChibiLegendLuckyTokenMapping(
        uint256[] calldata chibiLegendTokenIds,
        uint256[] calldata luckyTokenIds
    ) external;

    /**
     * set Seal - Lucky Token mapping
     */
    function setSealLuckyTokenMapping(uint256[] calldata sealTokenIds, uint256[] calldata luckyTokenIds) external;
}