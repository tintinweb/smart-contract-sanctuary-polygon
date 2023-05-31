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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC1155 token with automatic token ID handling
 * @notice Token ID is automatically incremented when minting a new one
 */
abstract contract ERC1155AutoId is
    ERC1155
{
    using Counters for Counters.Counter;

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    // Current token ID
    Counters.Counter private _nextTokenId;

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     */
    constructor() {
        _nextTokenId.increment();
    }

    //=============================================================//
    //                      PUBLIC FUNCTIONS                       //
    //=============================================================//

    /**
     * Get total token supply
     * @return Total token supply
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Mint `amount_` tokens to `to_`
     * @param to_     Receiver address
     * @param amount_ Token amount
     * @param data_   Data if the receiver is a contract
     */
    function _mintTo(
        address to_,
        uint256 amount_,
        bytes memory data_
    ) internal virtual {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _mint(to_, currentTokenId, amount_, data_);
    }

    /**
     * Mint `amounts_` of different tokens to `to_`
     * @param to_      Receiver address
     * @param amounts_ Token amounts
     * @param data_    Data if the receiver is a contract
     */
    function _mintBatchTo(
        address to_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual {
        // Build IDs array
        uint256[] memory ids = new uint[](amounts_.length);
        for (uint256 i = 0; i < amounts_.length; i++) {
            ids[i] = _nextTokenId.current();
            _nextTokenId.increment();
        }

        _mintBatch(to_, ids, amounts_, data_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IERC4906.sol";


 /**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC1155 token that stores and handles a single URI
 * @notice Both token URI and contract URI can be set. URIs can be freezed to prevent future modifications
 * @dev    It replaces the _uri variable used in openzeppelin contract, by handling the URIs like in ERC721
 */
abstract contract ERC1155MultipleURIStorage is
    ERC1155,
    IERC4906
{
    using Strings for uint256;

    //=============================================================//
    //                          CONSTANTS                          //
    //=============================================================//

    /// Default name for contract metadata
    string constant private CONTRACT_DEFAULT_METADATA = "contract";

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Flag to freeze URI
    bool public uriFreezed;
    /// Base URI
    string public baseURI;
    /// Contract URI
    string public contractURI;
    /// Mapping from token ID to specific token URI
    mapping(uint256 => string) private _tokenURIs;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if URI is empty
     */
    error UriEmptyError();

    /**
     * Error raised if URI is freezed
     */
    error UriFreezedError();

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when URI is freezed
     */
    event UriFreezed(
        string baseURI,
        string contractURI
    );

    /**
     * Event emitted when URI is changed
     */
    event UriChanged(
        string oldURI,
        string newURI
    );

    /**
     * Event emitted when a token URI is changed
     */
    event TokenUriChanged(
        uint256 tokenId,
        string oldURI,
        string newURI
    );

    //=============================================================//
    //                           MODIFIERS                         //
    //=============================================================//

    /**
     * Modifier to make a function callable only if the URI `uri_` is not empty.
     * Require URI `uri_` to be not empty.
     * @param uri_ URI
     */
    modifier notEmptyURI(
        string memory uri_
    ) {
        if (bytes(uri_).length == 0) {
            revert UriEmptyError();
        }
        _;
    }

    /**
     * Modifier to make a function callable only when the URI is not freezed.
     * Require URI to be not freezed.
     */
    modifier whenUnfreezedUri() {
        if (uriFreezed) {
            revert UriFreezedError();
        }
        _;
    }

    //=============================================================//
    //                          CONSTRUCTOR                        //
    //=============================================================//

    /**
     * Constructor
     * @param baseURI_ Base URI
     */
    constructor(
        string memory baseURI_
    ) {
        uriFreezed = false;
        _setBaseURI(baseURI_);
        _setContractURI(string(abi.encodePacked(baseURI_, CONTRACT_DEFAULT_METADATA)));
    }

    //=============================================================//
    //                      INTERNAL FUNCTIONS                     //
    //=============================================================//

    /**
     * Freeze URI
     */
    function _freezeURI() internal whenUnfreezedUri {
        uriFreezed = true;

        emit UriFreezed(baseURI, contractURI);
    }

    /**
     * Set base URI to `baseURI_`
     * @param baseURI_ Base URI
     */
    function _setBaseURI(
        string memory baseURI_
    ) internal whenUnfreezedUri {
        string memory old_uri = baseURI;
        baseURI = baseURI_;

        emit UriChanged(old_uri, baseURI);

        _updateEntireCollectionMetadata();
    }

    /**
     * Set contract URI to `contractURI_`
     * @param contractURI_ Contract URI
     */
    function _setContractURI(
        string memory contractURI_
    ) internal whenUnfreezedUri {
        string memory old_uri = contractURI;
        contractURI = contractURI_;

        emit UriChanged(old_uri, contractURI);
    }

    /**
     * Set URI of token ID `tokenId_` to `URI_`
     * @param tokenId_ Token ID
     * @param URI_     URI
     */
    function _setTokenURI(
        uint256 tokenId_,
        string memory URI_
    ) internal whenUnfreezedUri {
        string memory old_uri = _tokenURIs[tokenId_];
        _tokenURIs[tokenId_] = URI_;

        emit TokenUriChanged(tokenId_, old_uri, URI_);

        _updateSingleTokenMetadata(tokenId_);
    }

    /**
     * Update metadata of token `tokenId_`
     * @param tokenId_ Token ID
     */
    function _updateSingleTokenMetadata(
        uint256 tokenId_
    ) internal {
        emit MetadataUpdate(tokenId_);
    }

    /**
     * Update metadata of the entire collection
     */
    function _updateEntireCollectionMetadata() internal {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    //=============================================================//
    //                     OVERRIDDEN FUNCTIONS                    //
    //=============================================================//

    /**
     * See {ERC1155-uri}
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId_];
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId_.toString())) : "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


 /**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC1155 token with the possibility to pause transfers in a selective way
 * @notice Transfers can be paused for all but some addresses or only for some addresses
 */
abstract contract ERC1155SelectivePausable is
    ERC1155,
    Pausable
{
    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Mapping from wallet address to the unpaused status
    /// If true, the wallet can transfer tokens when paused
    mapping(address => bool) public unpausedWallets;
    /// Mapping from wallet address to the paused status
    /// If true, the wallet cannot transfer tokens
    mapping(address => bool) public pausedWallets;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if a transfer is made by a paused wallet
     */
    error TransferByPausedWalletError();

    /**
     * Error raised if a transfer is made while paused
     */
    error TransferWhilePausedError();

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when a paused wallet status is changed
     */
    event PausedWalletStatusChanged(
        address walletAddress,
        bool status
    );

    /**
     * Event emitted when an unpaused wallet status is changed
     */
    event UnpausedWalletStatusChanged(
        address walletAddress,
        bool status
    );

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Set the status of paused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet cannot transfer tokens, false otherwise
     */
    function _setPausedWallet(
        address wallet_,
        bool status_
    ) internal {
        pausedWallets[wallet_] = status_;

        emit PausedWalletStatusChanged(wallet_, status_);
    }

    /**
     * Set the status of unpaused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet can transfer tokens when paused, false otherwise
     */
    function _setUnpausedWallet(
        address wallet_,
        bool status_
    ) internal {
        unpausedWallets[wallet_] = status_;

        emit UnpausedWalletStatusChanged(wallet_, status_);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC1155-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {
        super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);


        // Do not check address zero (in case of burning)
        if (to_ == address(0)) {
            return;
        }

        // Revert if paused wallet
        if (pausedWallets[from_]) {
            revert TransferByPausedWalletError();
        }

        // Revert if transfer while paused and wallet is not paused
        if (!unpausedWallets[from_] && paused()) {
            revert TransferWhilePausedError();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC1155 token with the possibility to limit the maximum number of token owned by each wallet
 */
abstract contract ERC1155WalletCapped is
    ERC1155
{
    //=============================================================//
    //                         STRUCTURES                          //
    //=============================================================//

    /// Data for wallet maximum number of tokens
    struct WalletMaxTokens {
        uint256 maxTokens;
        bool isSet;
    }

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Mapping from wallet address to the maximum number of ownable tokens for a specified token ID
    mapping(address => mapping(uint256 => WalletMaxTokens)) public walletsMaxTokens;
    /// Default maximum number of tokens if address is not in the mapping
    mapping(uint256 => WalletMaxTokens) public defaultWalletMaxTokens;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if default wallet maximum number of tokens is reached
     */
    error DefaultWalletMaxTokensReachedError(
        uint256 maxValue
    );

    /**
     * Error raised if specific wallet maximum number of tokens is reached
     */
    error WalletMaxTokensReachedError(
        uint256 maxValue
    );

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when default maximum number of tokens is changed
     */
    event DefaultMaxTokensChanged(
        uint256 tokenId,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * Event emitted when maximum number of tokens for a wallet is changed
     */
    event WalletMaxTokensChanged(
        address walletAddress,
        uint256 tokenId,
        uint256 oldValue,
        uint256 newValue
    );

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Set the maximum number of token `tokenId_` for the wallet `wallet_` to `maxTokens_`
     * @param wallet_    Wallet address
     * @param tokenId_   Token ID
     * @param maxTokens_ Maximum number of tokens
     */
    function _setWalletMaxTokens(
        address wallet_,
        uint256 tokenId_,
        uint256 maxTokens_
    ) internal {
        uint256 old_value = walletsMaxTokens[wallet_][tokenId_].maxTokens;

        WalletMaxTokens storage wallet_max_tokens = walletsMaxTokens[wallet_][tokenId_];
        wallet_max_tokens.isSet = true;
        wallet_max_tokens.maxTokens = maxTokens_;

        emit WalletMaxTokensChanged(wallet_, tokenId_, old_value, maxTokens_);
    }

    /**
     * Set the default wallet maximum number of token `tokenId_` to `maxTokens_`
     * @param tokenId_   Token ID
     * @param maxTokens_ Maximum number of tokens
     */
    function _setDefaultWalletMaxTokens(
        uint256 tokenId_,
        uint256 maxTokens_
    ) internal {
        uint256 old_value = defaultWalletMaxTokens[tokenId_].maxTokens;

        WalletMaxTokens storage wallet_max_tokens = defaultWalletMaxTokens[tokenId_];
        wallet_max_tokens.isSet = true;
        wallet_max_tokens.maxTokens = maxTokens_;

        emit DefaultMaxTokensChanged(tokenId_, old_value, maxTokens_);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC1155-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {
        super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);

        // Do not check address zero (in case of burning)
        if (to_ == address(0)) {
            return;
        }

        for (uint256 i = 0; i < ids_.length; i++) {
            uint256 id = ids_[i];
            uint256 new_balance = balanceOf(to_, id) + amounts_[i];

            WalletMaxTokens storage wallet_max_tokens = walletsMaxTokens[to_][id];
            if (wallet_max_tokens.isSet && new_balance > wallet_max_tokens.maxTokens) {
                revert WalletMaxTokensReachedError(wallet_max_tokens.maxTokens);
            } else if (defaultWalletMaxTokens[id].isSet && new_balance > defaultWalletMaxTokens[id].maxTokens) {
                revert DefaultWalletMaxTokensReachedError(defaultWalletMaxTokens[id].maxTokens);
            }
            // If defaultWalletMaxTokens is not set, it'll mean infinite tokens
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  IERC4906 interface for ERC1155
 * @dev    Added since not present in last openzeppelin release
 */
interface IERC4906 is
    IERC165,
    IERC1155
{
    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * This event emits when the metadata of a token is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFT.
     */
    event MetadataUpdate(
        uint256 tokenId
    );

    /**
     * This event emits when the metadata of a range of tokens is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFTs.
     */
    event BatchMetadataUpdate(
        uint256 fromTokenId,
        uint256 toTokenId
    );
}

// SPDX-License-Identifier: MIT

//
// Strategic Club (https://strategicclub.io/)
//
//                                    ..:^^~!!777????????777!!~^^:..
//                               .:^!!7????????????????????????????7!!^:.
//                           :^!7????????????????????????????????????????7!^:
//                       .^!7????????????????????????????????????????????????7!^.
//                    .^!????????????????????????????????????????????????????????!^.
//                  :!??????????????????????????????????????????????????????????????!:
//               .^7??????????????????????????????????????????????????????????????????7^.
//             .~7??????????????????????????????????????????????????????????????????????7~.
//            ^7????????????????7~!???????77???7777777????????????????????????????????????7^
//          :7?????????????????!:::~7???7^::~7^:::::::^^^^~!7???????????????????????????????7:
//         ~???????????????????7:::::^^~~::::^^:::::::::::::^~7???????????????????????????????~
//       .!?????????????????????7::::::::::::::::::::::::::::::^!??????????????????????????????!.
//      :7?????????????????????!^::::::::::::::::::::::::::::::::^!?????????????????????????????7:
//     :??????????????????????~:::::::::::::::::::^^::::::::::::^5^^7?????????????????????????????:
//    :??????????????????????~:::::::::::::::::::JG::::::..::..:~#5.:!?????????????????????????????:
//   .7??????????????????????~:::~~::::::::::::::[email protected]?~^~7??YPPJJP&B7:::~????????????????????????????7.
//   !?????????????????????7~::::::::::::::::::::~5##&@@@@@@@@@@B^:::::~????????????????????????????!
//  :????????????????????7~:::::::::::::::::::::::^[email protected]@@@@@@@@@5^:::::::7????????????????????????????:
//  !???????????????????~:::::::::::::::::::::::::[email protected]@@@@@@@@@@@&?:::::::~????????????????????????????!
// :????????????????????!::::::::::::::::::::::::.~G#&@@@@@@@@@@@5::::::^?????????????????????????????:
// ~?????????????????????7~^:::::::^^^^:::::::^~?5B&@@@@@@@@@@@@@@Y::::::?????????????????????????????~
// 7????????????????????????7777777G&&##BBBBBB#&@@@@@@@@@@@@@@@@@@#^:::::7????????????????????????????7
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^::::^??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::~??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~::::7??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5::::^??????????????????????????????7
// ~????????????????????????????G&@@@#BPPGB&@@@@@@@@@@@@@@@@@@@@@Y:::::7??????????????????????????????~
// :[email protected]@@BY^:::::[email protected]@@#P#@@@@@@@@@#&@@@J.::::~???????????????????????????????:
//  [email protected]@P7?!:::::~&@G^[email protected]@&YYPPY7:[email protected]@B:::::^???????????????????????????????!
//  :[email protected]@&?777^.:::[email protected]@Y::[email protected]@[email protected]#^:::^7???????????????????????????????:
//   [email protected]@@PY5PGPGBB#@@@&&@@@&#[email protected]@@Y~^^7???????????????????????????????!
//   [email protected]@@@@@@&&##BGGPP555YYY5555555P5PPGGPGGPP5YJJ????????????????????????7.
//    :????????????????J5G#&&#GPYJ?7!~~^^:::::::::::::::::::::::::^^^~~!77???77????????????????????:
//     :????????????YPGG5J7!^^:::::^^^^^~~~~~~~~~~~~~!!~~~~~~~~~~~~^^^^^^::::^^^^~!!7?????????????:
//      :7???????7?J?7~^^~~~!!777777????????????????????????????????????77777!!!~~~^^~~!77??????7:
//       .!?????7!!!77???????????????????????????????????????????????????????????????777!!7????!.
//         ~??????????????????????????????????????????????????????????????????????????????????~
//          :7??????????????????????????????????????????????????????????????????????????????7:
//            ^7??????????????????????????????????????????????????????????????????????????7^
//             .~7??????????????????????????????????????????????????????????????????????7~.
//               .^7??????????????????????????????????????????????????????????????????7^.
//                  :!??????????????????????????????????????????????????????????????!:
//                    .^!????????????????????????????????????????????????????????!^.
//                       .^!7????????????????????????????????????????????????7!^.
//                           :^!7????????????????????????????????????????7!^:
//                               .:^!!7????????????????????????????7!!^:.
//                                    ..:^^~!!777????????777!!~^^:..
//

pragma solidity ^0.8.19;

//=============================================================//
//                            IMPORTS                          //
//=============================================================//
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155AutoId.sol";
import "./ERC1155SelectivePausable.sol";
import "./ERC1155MultipleURIStorage.sol";
import "./ERC1155WalletCapped.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  Ticket NFT for Strategic Club group
 * @notice NFT expiration date will be specified in NFT metadata traits
 */
contract StrategicClubTicketNFT is
    ERC1155AutoId,
    ERC1155WalletCapped,
    ERC1155SelectivePausable,
    ERC1155MultipleURIStorage,
    Ownable
{
    //=============================================================//
    //                           CONSTANTS                         //
    //=============================================================//

    // NFT name
    string constant private NFT_NAME = "Strategic Club Ticket NFT";
    // NFT symbol
    string constant private NFT_SYMBOL = "SCTK";

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if minting zero tokens
     */
    error ZeroTokensMintError();

    //=============================================================//
    //                             EVENTS                          //
    //=============================================================//

    // Event emitted when a single token is minted
    event SingleTokenMinted(
        address toAddress,
        uint256 tokenId,
        uint256 amount
    );

    // Event emitted when multiple tokens are minted
    event MultipleTokensMinted(
        address toAddress,
        uint256 startTokenId,
        uint256 tokenNum,
        uint256[] amounts
    );

    /**
     * Event emitted when a single token is burned
     */
    event SingleTokenBurned(
        address fromAddress,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * Event emitted when a multiple tokens are burned
     */
    event MultipleTokensBurned(
        address fromAddress,
        uint256[] tokenIds,
        uint256[] amounts
    );

    //=============================================================//
    //                          CONSTRUCTOR                        //
    //=============================================================//

    /**
     * Constructor
     * @param baseURI_ Base URI
     */
    constructor(
        string memory baseURI_
    )
        ERC1155("")
        ERC1155MultipleURIStorage(baseURI_)
    {
        name = NFT_NAME;
        symbol = NFT_SYMBOL;
    }

    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    //
    // Mint/Burn
    //

    /**
     * Mint `amount_` tokens to `to_`
     * @param to_     Receiver address
     * @param amount_ Token amount
     */
    function mintTo(
        address to_,
        uint256 amount_
    ) public onlyOwner {
        mintTo(to_, amount_, "");
    }

    /**
     * Mint `amount_` tokens to `to_`
     * @param to_     Receiver address
     * @param amount_ Token amount
     * @param data_   Data if the receiver is a contract
     */
    function mintTo(
        address to_,
        uint256 amount_,
        bytes memory data_
    ) public onlyOwner {
        if (amount_ == 0) {
            revert ZeroTokensMintError();
        }

        _mintTo(to_, amount_, data_);

        emit SingleTokenMinted(to_, totalSupply(), amount_);
    }

    /**
     * Mint `amounts_` of different tokens to `to_`
     * @param to_      Receiver address
     * @param amounts_ Amount for each token
     */
    function mintBatchTo(
        address to_,
        uint256[] memory amounts_
    ) public onlyOwner {
        mintBatchTo(to_, amounts_, "");
    }

    /**
     * Mint `amounts_` of different tokens to `to_`
     * @param to_      Receiver address
     * @param amounts_ Amount for each token
     * @param data_    Data if the receiver is a contract
     */
    function mintBatchTo(
        address to_,
        uint256[] memory amounts_,
        bytes memory data_
    ) public onlyOwner {
        uint256 tokens_num = amounts_.length;
        for (uint256 i = 0; i < tokens_num; i++) {
            if (amounts_[i] == 0) {
                revert ZeroTokensMintError();
            }
        }

        _mintBatchTo(to_, amounts_, data_);

        emit MultipleTokensMinted(to_, totalSupply() - tokens_num + 1, tokens_num, amounts_);
    }
/*
    function airdrop(
        address[] calldata receivers_
    ) public onlyOwner {
        uint256 tokens_num = receivers_.length;

        _mintTo(owner(), tokens_num, "");

        for (uint256 i = 0; i < tokens_num; i++) {
            safeTransferFrom
        }
    }
*/
    /**
     * Burn `amount_` tokens of token `id_` from `from_`
     * @param from_   Target address
     * @param id_     Token ID
     * @param amount_ Token amount
     */
    function burn(
        address from_,
        uint256 id_,
        uint256 amount_
    ) public onlyOwner {
        _burn(from_, id_, amount_);

        emit SingleTokenBurned(from_, id_, amount_);
    }

    /**
     * Burn `amounts_` tokens of token `ids_` from `from_`
     * @param from_    Target address
     * @param ids_     Token IDs
     * @param amounts_ Token amounts
     */
    function burnBatch(
        address from_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) public onlyOwner {
        _burnBatch(from_, ids_, amounts_);

        emit MultipleTokensBurned(from_, ids_, amounts_);
    }

    //
    // URIs management
    //

    /**
     * Set base URI to `baseUri_`
     * @param baseUri_ URI
     */
    function setBaseURI(
        string memory baseUri_
    ) public onlyOwner notEmptyURI(baseUri_) {
        _setBaseURI(baseUri_);
        _updateEntireCollectionMetadata();
    }

    /**
     * Set contract URI to `contractURI_`
     * @param contractURI_ Contract URI
     */
    function setContractURI(
        string memory contractURI_
    ) public onlyOwner notEmptyURI(contractURI_) {
        _setContractURI(contractURI_);
    }

    /**
     * Set URI of token ID `tokenId_` to `URI_`
     * @param tokenId_ Token ID
     * @param URI_     URI
     */
    function setTokenURI(
        uint256 tokenId_,
        string memory URI_
    ) public onlyOwner {
        _setTokenURI(tokenId_, URI_);
    }

    /**
     * Freeze URI
     */
    function freezeURI() public onlyOwner {
        _freezeURI();
    }

    //
    // Maximum tokens per wallet management
    //

    /**
     * Set the maximum number of token `tokenId_` for the wallet `wallet_` to `maxTokens_`
     * @param wallet_    Wallet address
     * @param tokenId_   Token ID
     * @param maxTokens_ Maximum number of tokens
     */
    function setWalletMaxTokens(
        address wallet_,
        uint256 tokenId_,
        uint256 maxTokens_
    ) public onlyOwner {
        _setWalletMaxTokens(wallet_, tokenId_, maxTokens_);
    }

    /**
     * Set the default wallet maximum number of token `tokenId_` to `maxTokens_`
     * @param tokenId_   Token ID
     * @param maxTokens_ Maximum number of tokens
     */
    function setDefaultWalletMaxTokens(
        uint256 tokenId_,
        uint256 maxTokens_
    ) public onlyOwner {
        _setDefaultWalletMaxTokens(tokenId_, maxTokens_);
    }

    //
    // Pause management
    //

    /**
     * Set the status of paused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet cannot transfer tokens, false otherwise
     */
    function setPausedWallet(
        address wallet_,
        bool status_
    ) public onlyOwner {
        _setPausedWallet(wallet_, status_);
    }

    /**
     * Set the status of unpaused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet can transfer tokens when paused, false otherwise
     */
    function setUnpausedWallet(
        address wallet_,
        bool status_
    ) public onlyOwner {
        _setUnpausedWallet(wallet_, status_);
    }

    /**
     * Pause token transfers
     */
    function pauseTransfers() public onlyOwner {
        _pause();
    }

    /**
     * Unpause token transfers
     */
    function unpauseTransfers() public onlyOwner {
        _unpause();
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC1155-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override(ERC1155WalletCapped, ERC1155SelectivePausable, ERC1155) {
        super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);
    }

    /**
     * See {ERC1155-uri}
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override(ERC1155MultipleURIStorage, ERC1155) returns (string memory) {
        return super.uri(tokenId_);
    }
}