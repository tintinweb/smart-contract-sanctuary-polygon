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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract Auctions{
    
    using EnumerableSet for EnumerableSet.UintSet;

    event AuctionCreated(uint auctionId);
    event AuctionDeleted(Auction auction);

    struct Auction{
        address owner;
        uint minBid;
        uint maxBid;
        address lastBidder;
        uint endDate;
    }

    uint public _auctionId;
    
    mapping(uint => Auction) public _auctionDetails;

    function createAuction(Auction calldata auction) internal returns(uint){
        isValidAuction(auction);

        _auctionId++;
        _auctionDetails[_auctionId] = auction;

        emit AuctionCreated(_auctionId);
        return _auctionId;
    }

    function updateAuction(uint auctionId, Auction calldata updatedAuction) public {
        checkAuctionExists(auctionId);
        isValidAuctionOwner(auctionId);
        isValidAuction(updatedAuction);

        cancelPreviousBid(auctionId);
        _auctionDetails[auctionId] = updatedAuction;
    }

    function deleteAuction(uint auctionId) internal {
        Auction memory auction = _auctionDetails[auctionId];

        checkAuctionExists(auctionId);
        isValidAuctionOwner(auctionId);

        cancelPreviousBid(auctionId);
        delete _auctionDetails[auctionId];
        
        emit AuctionDeleted(auction);
    }

    function makeBid(uint auctionId) public payable{
        uint currentTimestamp = block.timestamp;

        checkAuctionExists(auctionId);
        isValidBid(auctionId);
        require(currentTimestamp < _auctionDetails[auctionId].endDate, "Auctions: Auction end date expired");
        require((msg.sender).code.length == 0, "Auction: Bidder should be a EOA");

        cancelPreviousBid(auctionId);
        _auctionDetails[auctionId].maxBid = msg.value;
        _auctionDetails[auctionId].lastBidder = msg.sender;

    }

    function endAuction(uint auctionId) internal{
        Auction memory auction = _auctionDetails[auctionId];

        checkAuctionExists(auctionId);
        isValidAuctionOwner(auctionId);

        // payable(auction.owner).transfer(auction.maxBid);
        delete _auctionDetails[auctionId];

        emit AuctionDeleted(auction);
    }

    function cancelPreviousBid(uint auctionId) private{
        if (_auctionDetails[auctionId].lastBidder != address(0)){
            payable(_auctionDetails[auctionId].lastBidder).transfer(_auctionDetails[auctionId].maxBid);
            _auctionDetails[auctionId].lastBidder = address(0);
            _auctionDetails[auctionId].maxBid = 0;
        }
    }

    function isValidBid(uint auctionId) private view{
        if (_auctionDetails[auctionId].lastBidder == address(0)){
            require(msg.value > _auctionDetails[auctionId].minBid, "Auctions: Bid should be > minimum bid");
        }
        else{
            require(msg.value > _auctionDetails[auctionId].maxBid, "Auctions: Bid should be > maximum bid");
        }
    }

    function isValidAuction(Auction calldata auction) private view{
        uint currentTimestamp = block.timestamp;

        if (auction.owner == address(0) || msg.sender != auction.owner || auction.minBid == 0 || auction.maxBid != 0 || auction.lastBidder != address(0) || auction.endDate <= currentTimestamp){
            revert("Auctions: Invalid auction details");
        }

        //
        
    }

    function checkAuctionExists(uint auctionId) private view{
        require(_auctionDetails[auctionId].minBid != 0, "Auctions: Auction don't exists");
    }

    function isValidAuctionOwner(uint auctionId) private view{
        require(msg.sender == _auctionDetails[auctionId].owner, "Auctions: Not an owner of auction");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./TicketsERC1155.sol";
import "./Renting.sol";


enum PromoCodeType{ fixedDiscount, percentageDiscount, free }

struct Event{
    uint startDate;
    uint endDate;
    uint servicePercentage;
    uint royaltyPercentage;
    bool isPaused;
}

struct TicketType{
    uint maxAmount;
    uint price;
    string uri;
    uint[] validDates;
    uint soldAmount;
}

struct PromoCode{
    uint[] eventIds;
    uint endDate;
    PromoCodeType promoCodeType;
    uint maxUseAmount;
    uint amountUsed;
    // depends on promocode type
    uint amount;
    uint maxCap; //optional
    uint ticketTypeId; // in case of free discount for an event
}

contract Main is Ownable, Pausable{
    event EventCreated(uint indexed eventId, uint[] ticketIds);
    event TicketTypesCreated(uint indexed eventId, uint[] ticketIds);
    event PromoCodesCreated(uint[] promoCodeIds);
    
    event TicketTypeDeleted(TicketType ticketType);
    event PromoCodeDeleted(PromoCode promocode);

    uint public _eventId;
    uint public _ticketTypeId;
    uint public _promoCodeId;

    using EnumerableSet for EnumerableSet.UintSet;

//  ---------------------------------- Events Details ----------------------------------

//  mapping(eventId => eventDetails)
    mapping(uint => Event) public _eventDetails;

//  ---------------------------------- Ticket Type ----------------------------------

//  mapping(eventId => ticketTypeIds)
    mapping(uint => EnumerableSet.UintSet) _eventTicketTypes;
//  mapping(ticketTypeId => ticketTypeDetails)
    mapping(uint => TicketType) public _ticketTypeDetails;

//  ---------------------------------- Promo Code ----------------------------------

//  mapping(promoCodeId => promoCodeDetails)
    mapping(uint => PromoCode) public _promoCodeDetails;
//  mapping(eventId => associated promoCodes[])
    mapping(uint => EnumerableSet.UintSet) _promoCodeDiscountOnEvent;


    TicketsERC1155 public _ticketsERC1155Contract;
    Renting public _rentingContract;

    constructor(address ticketsERC1155Contract){
        require(ticketsERC1155Contract == address(0) || ticketsERC1155Contract.code.length > 0, "Main: Invalid contract address");

        _ticketsERC1155Contract = TicketsERC1155(ticketsERC1155Contract);

        require(_ticketsERC1155Contract.owner() == owner(), "Main: Both Tickets and Main contract have different owners");
    }

    function setTicketContract(address ticketContractAddress) public whenNotPaused onlyOwner{
        require(ticketContractAddress.code.length > 0, "Main: Invalid contract address");
        _ticketsERC1155Contract = TicketsERC1155(ticketContractAddress);

        require(msg.sender == _ticketsERC1155Contract.owner(), "Main: Ticket1155 and Main contract have different owners");
    }

    function setRentingContract(address rentingContractAddress) public whenNotPaused onlyOwner{
        require(rentingContractAddress.code.length > 0, "Main: Invalid contract address");
        _rentingContract = Renting(rentingContractAddress);

        require(msg.sender == owner(), "Renting: Main and Renting contract have different owners");
    }

    function createEvent(Event calldata eventDetails, TicketType[] calldata ticketTypes)public whenNotPaused onlyOwner{
        isValidEvent(eventDetails);
        isValidTicketType(eventDetails, ticketTypes);

        _eventId++;
        _eventDetails[_eventId] = eventDetails;

        uint[] memory ticketTypeIds = createTicketTypes(_eventId, ticketTypes);

        emit EventCreated(_eventId, ticketTypeIds);
    }

    function updateEvent(uint eventId, Event calldata updatedEventDetails) public whenNotPaused onlyOwner{
        checkEventExists(eventId);
        isValidEvent(updatedEventDetails);

        _eventDetails[_eventId] = updatedEventDetails;
    }

    function deleteEvent(uint eventId) public whenNotPaused whenNotPaused onlyOwner {
        checkEventExists(eventId);

        delete _eventDetails[eventId];
        delete _eventTicketTypes[eventId];
        delete _promoCodeDiscountOnEvent[eventId];
    }

    function createPromoCodes(PromoCode[] calldata promoCodes) public whenNotPaused onlyOwner{
        
        uint promoCodesLength = promoCodes.length;
        uint[] memory promoCodeIds = new uint[](promoCodesLength);

        require(promoCodesLength > 0, "Main: No promocode given");
        
        for (uint i; i < promoCodesLength; i++){
            isValidPromoCode(promoCodes[i]);

            _promoCodeId++;
            _promoCodeDetails[_promoCodeId] = promoCodes[i];
            promoCodeIds[i] = _promoCodeId;

            associatePromoCodeWithEvents(promoCodes[i]);
        }

        emit PromoCodesCreated(promoCodeIds);
    }

    function updatePromoCode(uint promoCodeId, PromoCode calldata updatedPromoCode) public whenNotPaused onlyOwner {
        checkPromoCodeExists(promoCodeId);
        isValidPromoCode(updatedPromoCode);
        require(updatedPromoCode.maxUseAmount >= _promoCodeDetails[promoCodeId].amountUsed, "Main: Max no of uses in updated promocode should be >= exisiting promocode used amount");

        removePromoCodeFromEvents(promoCodeId);
        uint usedAmount = _promoCodeDetails[promoCodeId].amountUsed;
       _promoCodeDetails[promoCodeId] = updatedPromoCode;
       _promoCodeDetails[promoCodeId].amountUsed = usedAmount;
       associatePromoCodeWithEvents(_promoCodeDetails[promoCodeId]);
    }

    function deletePromocode(uint promoCodeId) public whenNotPaused onlyOwner{
        checkPromoCodeExists(promoCodeId);

        PromoCode memory promoCode = _promoCodeDetails[promoCodeId];
        
        removePromoCodeFromEvents(promoCodeId);
        delete _promoCodeDetails[promoCodeId];
        
        emit PromoCodeDeleted(promoCode);
    }

    function buyTicketInCrypto(uint eventId, uint ticketTypeId, uint amountToBuy, uint promoCodeId) whenNotPaused public payable{
        uint currentTimestamp = block.timestamp;
        
        checkEventExists(eventId);
        checkEventNotPaused(eventId);
        checkTicketTypeExists(ticketTypeId);
        checkEventHasTicketTypeId(eventId, ticketTypeId);
        
        require(amountToBuy > 0, "Main: Amount to buy is 0");
        require(currentTimestamp <= _eventDetails[eventId].endDate, "Main: Event end date passed");
        require(_ticketTypeDetails[ticketTypeId].soldAmount + amountToBuy <= _ticketTypeDetails[ticketTypeId].maxAmount, "Main: Don't have enough available tickets");

        if (promoCodeId != 0){
            checkPromoCodeExists(promoCodeId);
            checkEventHasPromoCode(eventId, promoCodeId);
            isValidDiscountAmouont(_ticketTypeDetails[ticketTypeId], _promoCodeDetails[promoCodeId]);
            require(currentTimestamp <= _promoCodeDetails[promoCodeId].endDate, "Main: Promocode end date passed");
        }

        uint serviceFee = _promoCodeDetails[promoCodeId].promoCodeType == PromoCodeType.free ? 0 : findValueFromPercentage(_eventDetails[eventId].servicePercentage, _ticketTypeDetails[ticketTypeId].price) * amountToBuy;     
        uint actualPrice = _ticketTypeDetails[ticketTypeId].price * amountToBuy;
        uint discountedPrice = getTicketDiscountedPrice(_ticketTypeDetails[ticketTypeId], _promoCodeDetails[promoCodeId], amountToBuy);

        require(msg.value == (promoCodeId == 0 ? actualPrice + serviceFee : discountedPrice + serviceFee), "Main: Insufficient amount sent");

        _promoCodeDetails[promoCodeId].amountUsed += 1;
        _ticketTypeDetails[ticketTypeId].soldAmount += amountToBuy;
        _ticketsERC1155Contract.mint(msg.sender, ticketTypeId, amountToBuy, "");
    }

    function getReqTicketPrice(uint eventId, uint ticketTypeId, uint promoCodeId, uint amountToBuy) public view returns (uint, uint){
        isValidDiscountAmouont(_ticketTypeDetails[ticketTypeId], _promoCodeDetails[promoCodeId]);
        uint serviceFee = _promoCodeDetails[promoCodeId].promoCodeType == PromoCodeType.free ? 0 : findValueFromPercentage(_eventDetails[eventId].servicePercentage, _ticketTypeDetails[ticketTypeId].price);     
        uint actualPrice = _ticketTypeDetails[ticketTypeId].price;
        uint discountedPrice = getTicketDiscountedPrice(_ticketTypeDetails[ticketTypeId], _promoCodeDetails[promoCodeId], 1);

        return promoCodeId == 0 ? (actualPrice * amountToBuy, serviceFee * amountToBuy) : (discountedPrice * amountToBuy, serviceFee * amountToBuy);
    }

    function buyTicketInFiat(address buyer, uint eventId, uint ticketTypeId, uint amountToBuy) whenNotPaused public onlyOwner{
        uint currentTimestamp = block.timestamp;
        
        checkEventExists(eventId);
        checkEventNotPaused(eventId);
        checkTicketTypeExists(ticketTypeId);
        checkEventHasTicketTypeId(eventId, ticketTypeId);
        
        require(amountToBuy > 0, "Main: Amount to buy is 0");
        require(currentTimestamp <= _eventDetails[eventId].endDate, "Main: Event end date passed");
        require(_ticketTypeDetails[ticketTypeId].soldAmount + amountToBuy <= _ticketTypeDetails[ticketTypeId].maxAmount, "Main: Don't have enough available tickets");

        _ticketTypeDetails[ticketTypeId].soldAmount += amountToBuy;
        _ticketsERC1155Contract.mint(buyer, ticketTypeId, amountToBuy, "");
    }

    function getTicketDiscountedPrice(TicketType memory ticketTypeDetails, PromoCode memory promoCodeDetails, uint amountToBuy) private pure returns(uint){
        if (promoCodeDetails.promoCodeType == PromoCodeType.fixedDiscount){
            return (ticketTypeDetails.price - promoCodeDetails.amount) * amountToBuy;
        }
        else if(promoCodeDetails.promoCodeType == PromoCodeType.percentageDiscount){
            uint discountOnSingleTicket = findValueFromPercentage(promoCodeDetails.amount, ticketTypeDetails.price);
            uint actualPrice = ticketTypeDetails.price * amountToBuy;
        
            return (actualPrice - ((discountOnSingleTicket < promoCodeDetails.maxCap) ? (discountOnSingleTicket * amountToBuy) : (promoCodeDetails.maxCap * amountToBuy)));
        }
        else{ //promoCodeDetails.promoCodeType == PromoCodeType.free
            return 0;
        }
    }

    function updateTicketType(uint eventId, uint ticketTypeId, TicketType memory updatedTicketType) public whenNotPaused onlyOwner {
        checkEventExists(eventId);
        checkEventNotPaused(eventId);
        checkTicketTypeExists(ticketTypeId);
        checkEventHasTicketTypeId(eventId, ticketTypeId);
        require(updatedTicketType.maxAmount >= _ticketTypeDetails[ticketTypeId].soldAmount, "Main: Max copies in updated ticket type should be >= exisiting ticket sold amount");

        TicketType[] memory ticketTypes = new TicketType[](1);
        ticketTypes[0] = updatedTicketType;

        isValidTicketType(_eventDetails[eventId], ticketTypes);

        updatedTicketType.soldAmount = _ticketTypeDetails[ticketTypeId].soldAmount;
        _ticketTypeDetails[ticketTypeId] = updatedTicketType;
    }

    function addTicketTypes(uint eventId, TicketType[] calldata ticketTypes) public whenNotPaused onlyOwner{
        checkEventExists(eventId);
        checkEventNotPaused(eventId);
        isValidTicketType(_eventDetails[eventId], ticketTypes);

        uint[] memory ticketTypeIds = createTicketTypes(eventId, ticketTypes);

        emit TicketTypesCreated(eventId, ticketTypeIds);
    }

    function deleteTicketType(uint eventId, uint ticketTypeId) public whenNotPaused onlyOwner{
        checkEventExists(eventId);
        checkEventNotPaused(eventId);
        checkTicketTypeExists(ticketTypeId);
        checkEventHasTicketTypeId(eventId, ticketTypeId);

        TicketType memory ticketType = _ticketTypeDetails[ticketTypeId];
        
        _eventTicketTypes[eventId].remove(ticketTypeId);
        
        delete _ticketTypeDetails[ticketTypeId];
        
        emit TicketTypeDeleted(ticketType);
    }

    function updateEventStatus(uint eventId, bool status) public whenNotPaused onlyOwner{
        checkEventExists(eventId);
        _eventDetails[eventId].isPaused = status;
    }

    // function scanTicket(address user, uint eventId, uint ticketTypeId) public view returns(bool){
    //     require(user != address(0), "Main: Invalid user address");
    //     checkEventExists(eventId);
    //     checkEventNotPaused(eventId);
    //     checkTicketTypeExists(ticketTypeId);
    //     checkEventHasTicketTypeId(eventId, ticketTypeId);

    //     checkTicketValidity(ticketTypeId);

    //     //date validation
    //     if (_ticketsERC1155Contract.balanceOf(user, ticketTypeId) > 0 || _rentingContract._borrowedBalance(ticketTypeId, user) > 0){
    //         return true;
    //     }

    //     return false;
    // }

    // function checkTicketValidity(uint ticketTypeId) private view{
    //     uint currentTimestamp = block.timestamp;
    //     uint validDatesLength = _ticketTypeDetails[ticketTypeId].validDates.length;
    //     bool flag;

    //     for (uint i; i < validDatesLength; i++){
    //         if (currentTimestamp <= (_ticketTypeDetails[ticketTypeId].validDates[i] + 86400)){
    //             revert("2nd expression");
    //         }
    //         if (currentTimestamp >= _ticketTypeDetails[ticketTypeId].validDates[i] && currentTimestamp <= _ticketTypeDetails[ticketTypeId].validDates[i] + 86400){
    //             flag = true;
    //             break;
    //         }
    //     }

    //     require(flag, "Main: Ticket date validity fails");
    // }

    function withdrawAmount(uint amount) public onlyOwner{
        require(amount > 0, "Main: amount is 0");
        require(amount <= address(this).balance, "Main: Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function checkEventExistsWithTicketTypes(uint[] calldata eventIds, uint[][] calldata ticketTypeIds) public view{
        require(eventIds.length > 0, "Main: Got empty events array");
        
        for (uint i; i < eventIds.length; i++){
            checkEventExists(eventIds[i]);
            require(ticketTypeIds[i].length > 0, "Main: Got event with empty ticket type array passed");

            for (uint j; j < ticketTypeIds[i].length; j++){
                checkTicketTypeExists(ticketTypeIds[i][j]);
                checkEventHasTicketTypeId(eventIds[i], ticketTypeIds[i][j]);
            }
        }
    }

    function createTicketTypes(uint eventId, TicketType[] calldata ticketTypes) private returns(uint[] memory){
        uint ticketTypeLength = ticketTypes.length;
        uint[] memory ticketTypeIds = new uint[](ticketTypeLength);

        for (uint i; i < ticketTypeLength; i++){
            _ticketTypeId++;
            _ticketTypeDetails[_ticketTypeId] = ticketTypes[i];
            _eventTicketTypes[eventId].add(_ticketTypeId);

            ticketTypeIds[i] = _ticketTypeId;
        }

        return ticketTypeIds;
    }

    function isValidEvent(Event calldata eventDetails) private view {
        uint currentTimestamp = block.timestamp;
        // eventDetails.startDate < currentTimestamp || 
        if (eventDetails.endDate < currentTimestamp || eventDetails.startDate >= eventDetails.endDate){
            revert("Main: Invalid event details");
        }
    }

    function isValidTicketType(Event memory eventDetails, TicketType[] memory ticketTypes) private pure {
        uint ticketTypeLength = ticketTypes.length;
        
        require(ticketTypes.length > 0, "Main: Empty ticketType array");

        for(uint i; i < ticketTypeLength; i++){
            
            uint validDatesLength = ticketTypes[i].validDates.length;
            
            if (ticketTypes[i].maxAmount == 0 || ticketTypes[i].price == 0 || ticketTypes[i].soldAmount > 0 || compareString(ticketTypes[i].uri, "") || validDatesLength == 0){
                revert("Main: Got invalid ticket type");
            }
            else{
                for (uint j; j < validDatesLength; j++){
                    if (ticketTypes[i].validDates[j] < eventDetails.startDate || ticketTypes[i].validDates[j] > eventDetails.endDate){
                        revert("Main: Got invalid ticket valid date");
                    }
                }
            }
        }

    }

    function isValidPromoCode(PromoCode calldata promoCode) private view {
        uint currentTimestamp = block.timestamp;

        if (promoCode.endDate < currentTimestamp || promoCode.maxUseAmount == 0 || promoCode.amountUsed > 0 ){
            revert("Main: Got invalid promocode");
        }
        
        if (promoCode.promoCodeType == PromoCodeType.fixedDiscount || promoCode.promoCodeType == PromoCodeType.percentageDiscount){
            require(promoCode.promoCodeType != PromoCodeType.percentageDiscount ? true : promoCode.maxCap > 0, "Main: Max cap is 0");
            isValidPromoCodeType(promoCode);
        }
        else if (promoCode.promoCodeType == PromoCodeType.free){
            require(promoCode.eventIds.length == 1, "Main: Muliple events given for free discounts");

            checkEventExists(promoCode.eventIds[0]);
            checkTicketTypeExists(promoCode.ticketTypeId);
        }
        else{
            revert("Main: PromoCodeType enum not selected");
        }
    }

    function isValidDiscountAmouont(TicketType memory ticketType, PromoCode memory promoCode) private pure{
        if (promoCode.promoCodeType == PromoCodeType.percentageDiscount){
            require(promoCode.maxCap < ticketType.price, "Main: Max cap is >= ticket type price");
        }
        else if (promoCode.promoCodeType == PromoCodeType.fixedDiscount){
            require(promoCode.amount < ticketType.price, "Main: Discount amount is >= ticket type price");
        }
        
    }

    function isValidPromoCodeType(PromoCode calldata promoCode) private view{
        
        require(promoCode.eventIds.length > 0, "Main: No event given");
        require(promoCode.amount > 0, "Main: Discount amount is 0");

        for (uint i; i < promoCode.eventIds.length; i++){
            checkEventExists(promoCode.eventIds[i]);
            
            uint eventId = promoCode.eventIds[i];
            
            require(_eventTicketTypes[eventId].values().length > 0, "Main: Event don't have ticket types");

            // for(uint j; j < ticketTypeIds.length; j++){
            //     if (countMaxCapAsActualValue){
            //         require(promoCode.maxCap < _ticketTypeDetails[ticketTypeIds[j]].price, "Main: Max cap is >= event's ticket type price");
            //     }
            //     else {
            //         require(promoCode.amount < _ticketTypeDetails[ticketTypeIds[j]].price, "Main: Discount amount is >= event's ticket type price");
            //     }
            // }

        }
    }

    function removePromoCodeFromEvents(uint promoCodeId) private{
        uint eventIdsLength = _promoCodeDetails[promoCodeId].eventIds.length;
        uint[] memory eventIds = new uint[](eventIdsLength);
        eventIds = _promoCodeDetails[promoCodeId].eventIds;

        for(uint i; i < eventIdsLength; i++){
            _promoCodeDiscountOnEvent[eventIds[i]].remove(promoCodeId);
        }
    }

    function associatePromoCodeWithEvents(PromoCode memory promoCode) private{
        for(uint i; i < promoCode.eventIds.length; i++){
            _promoCodeDiscountOnEvent[promoCode.eventIds[i]].add(_promoCodeId);
        }
    }

    function getEventDetails(uint eventId) public view returns(Event memory){
        return _eventDetails[eventId];
    }

    function getPromoCodesOnEvent(uint eventId) public view returns(uint[] memory){
        return _promoCodeDiscountOnEvent[eventId].values();
    }

    function getPromoCodeEventIds(uint promoCodeId) public view returns(uint[] memory){
        return _promoCodeDetails[promoCodeId].eventIds;
    }

    function getEventTicketTypes(uint eventId) public view returns(uint[] memory){
        return _eventTicketTypes[eventId].values();
    }

    function findValueFromPercentage(uint percentage, uint totalAmount) public pure returns(uint){
        return (percentage * totalAmount) / 100;
    }

    function compareString(string memory str1, string memory str2) private pure returns(bool){
        return keccak256(bytes(str1)) == keccak256(bytes(str2));
    }

    function checkEventExists(uint eventId) private view{
        require(_eventDetails[eventId].startDate != 0, "Main: Event dont exists");
    }

    function checkEventNotPaused(uint eventId) private view {
        require(!_eventDetails[eventId].isPaused, "Main: Event is paused");
    }

    function checkPromoCodeExists(uint promoCodeId) private view{
        require(_promoCodeDetails[promoCodeId].endDate != 0, "Main: Promocode dont exists");
    }

    function checkTicketTypeExists(uint ticketTypeId) private view{
        require(_ticketTypeDetails[ticketTypeId].price != 0, "Main: Ticket type dont exists");
    }

    function checkEventHasPromoCode(uint eventId, uint promoCodeId) private view{
        require(_promoCodeDiscountOnEvent[eventId].contains(promoCodeId), "Main: Event dont contains promocode");
    }

    function checkEventHasTicketTypeId(uint eventId, uint ticketTypeId) private view{
        require(_eventTicketTypes[eventId].contains(ticketTypeId), "Main: Event don't have given ticket type id");
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Main.sol";
import "./Auctions.sol";
import "./TicketsERC1155.sol";


contract Renting is Ownable, ERC1155Receiver, Auctions, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    enum RentingType {fixedPrice, auction}

    event RentingPkgCreatedWithFixedPrice(uint eventPkgId);
    event RentingPkgCreatedWithAuction(uint eventPkgId, uint auctionId);
    
    event RentingPkgDeleted(EventPkg pkg);

    struct EventPkg{
        address lender;
        uint eventId;
        uint[] ticketTypeIds;
        uint[] copies;
        uint price;
        uint startDate;
        uint endDate;
        address borrower;
        RentingType rentingType;
    }


    Main public _mainContract;
    TicketsERC1155 public _ticketsERC1155Contract;
    uint public _eventPkgId;


    // mapping(tokenId => lender => amount)
    mapping(uint => mapping(address => uint)) public _lockedCopies;
    // mapping(tokenId => lender => amount)
    mapping(uint => mapping(address => uint)) public _frozenBalance;

    mapping(uint => EventPkg) public _eventPkgDetails;

// -------------------------- Marked as rent --------------------------

//  mapping(lender => (tokenId => recIDs[]))
    mapping(address => EnumerableSet.UintSet) _lenderMarkedPkgIds;

// -------------------------- Actually on rent --------------------------

//  mapping(user => array containing record ids of borrowed tokens)
    mapping(address => EnumerableSet.UintSet) _userBorrowedpkgIds;

//  mapping(user => array containing record ids of borrowed tokens)
    mapping(uint => mapping(address => uint)) public _borrowedBalance;

//  mapping(lender => (tokenId => recIDs[]))
    mapping(address => EnumerableSet.UintSet) _lenderOnRentPkgIds;

// -------------------------- Auction --------------------------

    //mapping(pkgId => auctionId)
    mapping(uint => uint) public _rentingPkgWithAuction;


    constructor(address mainContractAddress, address ticketsERC1155Contract){    
        require(mainContractAddress.code.length > 0, "Renting: Invalid main contract address");
        require(ticketsERC1155Contract.code.length > 0, "Renting: Invalid ticket1155 contract address");
        
        _mainContract = Main(mainContractAddress);
        _ticketsERC1155Contract = TicketsERC1155(ticketsERC1155Contract);

        require(msg.sender == _mainContract.owner(), "Renting: Main and Renting contract have different owners");
        require(msg.sender == _ticketsERC1155Contract.owner(), "Renting: Tickets and Renting contract have different owners");
    }

    modifier onlyAllowed(address caller){
        require(caller == address(_mainContract) || caller == owner(), "Renting: Caller is not authorized");
        _;
    }

    modifier isValidMainContract(){
        require(address(_mainContract) != address(0), "Renting: Main contract is null");
        _;
    }

    function setMainContract(address mainContractAddress) public onlyOwner whenNotPaused{
        require(mainContractAddress.code.length > 0, "Renting: Invalid contract address");
        _mainContract = Main(mainContractAddress);

        require(msg.sender == _mainContract.owner(), "Renting: Main and Renting contract have different owners");
    }

    function setTicketContract(address ticketContractAddress) public onlyOwner whenNotPaused{
        require(ticketContractAddress.code.length > 0, "Renting: Invalid contract address");
        _ticketsERC1155Contract = TicketsERC1155(ticketContractAddress);

        require(msg.sender == _ticketsERC1155Contract.owner(), "Renting: Ticket1155 and Renting contract have different owners");
    }

    function markForRentWithFixedPrice(EventPkg calldata pkg) public whenNotPaused{
        isValidEventPkg(pkg);
        isEligibleForPkgCreation(pkg);
        require(pkg.rentingType == RentingType.fixedPrice, "Renting: Renting type should be fixed-price");

        addNewEventPkgDetails(pkg);

        emit RentingPkgCreatedWithFixedPrice(_eventPkgId);
    }

    function markForRentWithAuction(EventPkg calldata pkg, Auction calldata auction) public whenNotPaused{
        isValidEventPkg(pkg);
        isEligibleForPkgCreation(pkg);

        require(pkg.lender == auction.owner, "Renting: Different owners in package and auction details");
        require(pkg.rentingType == RentingType.auction, "Renting: Renting type should be auction");

        uint auctionId = createAuction(auction);

        addNewEventPkgDetails(pkg);
        _rentingPkgWithAuction[_eventPkgId] = auctionId;
        
        emit RentingPkgCreatedWithAuction(_eventPkgId, auctionId);
    }

    function updateEventPkg(uint eventPkgId, EventPkg calldata updatedPkg) public whenNotPaused{
        checkEventPkgExists(eventPkgId);
        isValidPkgOwner(eventPkgId);
        checkPkgIsNotBorrowed(eventPkgId);
        isValidEventPkg(updatedPkg);

        require(_eventPkgDetails[eventPkgId].rentingType == updatedPkg.rentingType, "Renting: Renting type cannot be updated");
        
        unlockUserCopies(_eventPkgDetails[eventPkgId]);
        isEligibleForPkgCreation(updatedPkg);
        lockUserCopies(updatedPkg);
        
        _eventPkgDetails[eventPkgId] = updatedPkg;
    }

    function deleteEventPkg(uint eventPkgId) public whenNotPaused{
        checkEventPkgExists(eventPkgId);
        isValidPkgOwner(eventPkgId);
        checkPkgIsNotBorrowed(eventPkgId);
        
        if(_eventPkgDetails[eventPkgId].rentingType == RentingType.auction){
            deleteAuction(_rentingPkgWithAuction[eventPkgId]);
            _rentingPkgWithAuction[eventPkgId] = 0;
        }

        unlockUserCopies(_eventPkgDetails[eventPkgId]);
            
        EventPkg memory pkg = _eventPkgDetails[eventPkgId];
        _lenderMarkedPkgIds[pkg.lender].remove(eventPkgId);

        delete _eventPkgDetails[eventPkgId];
        emit RentingPkgDeleted(pkg);
    }

    function borrowPkgWithFixedPrice(uint eventPkgId) public whenNotPaused payable{
        checkEventPkgExists(eventPkgId);
        require(msg.sender != _eventPkgDetails[eventPkgId].lender, "Renting: Cannot borrow your own package");
        require(block.timestamp <= _eventPkgDetails[eventPkgId].endDate, "Renting: Package end date passed");
        checkPkgIsNotBorrowed(eventPkgId);
        checkUserBalance(_eventPkgDetails[eventPkgId].lender, _eventPkgDetails[eventPkgId].ticketTypeIds, _eventPkgDetails[eventPkgId].copies);
        
        EventPkg memory pkg = _eventPkgDetails[eventPkgId];
        Event memory eventDetails = _mainContract.getEventDetails(pkg.eventId);

        uint serviceFee = findValueFromPercentage(eventDetails.servicePercentage, pkg.price);
        uint royaltyFee = findValueFromPercentage(eventDetails.royaltyPercentage, pkg.price);

        require(msg.value == serviceFee + royaltyFee + pkg.price, "Renting: Insufficient amount to buy package");
        
        _ticketsERC1155Contract.transferTokens(
            pkg.lender, 
            address(this),
            pkg.ticketTypeIds,
            pkg.copies
        );

        _eventPkgDetails[eventPkgId].borrower = msg.sender;
        
        _lenderMarkedPkgIds[pkg.lender].remove(eventPkgId);
        _lenderOnRentPkgIds[pkg.lender].add(eventPkgId);

        _userBorrowedpkgIds[msg.sender].add(eventPkgId);
        increaseBorrowedBalance(pkg, msg.sender);

        freezeBalance(pkg);

        payable(_eventPkgDetails[eventPkgId].lender).transfer(pkg.price);
        
    }

    function endAuctionForRentingPkg(uint eventPkgId) public whenNotPaused{
        checkEventPkgExists(eventPkgId);
        isValidPkgOwner(eventPkgId);
        checkUserBalance(_eventPkgDetails[eventPkgId].lender, _eventPkgDetails[eventPkgId].ticketTypeIds, _eventPkgDetails[eventPkgId].copies);
        require(_eventPkgDetails[eventPkgId].rentingType == RentingType.auction, "Renting: Package is not on auction");

        EventPkg memory pkg = _eventPkgDetails[eventPkgId];
        Event memory eventDetails = _mainContract.getEventDetails(pkg.eventId);
        Auction memory auction = _auctionDetails[_rentingPkgWithAuction[eventPkgId]];

        require(auction.lastBidder != address(0), "Renting: Can't end auction having no bid");

        uint serviceFee = findValueFromPercentage(eventDetails.servicePercentage, auction.maxBid);
        uint royaltyFee = findValueFromPercentage(eventDetails.royaltyPercentage, auction.maxBid);

        _ticketsERC1155Contract.transferTokens(
            pkg.lender, 
            address(this),
            pkg.ticketTypeIds,
            pkg.copies
        );

        _eventPkgDetails[eventPkgId].borrower = auction.lastBidder;

        _lenderMarkedPkgIds[pkg.lender].remove(eventPkgId);
        _lenderOnRentPkgIds[pkg.lender].add(eventPkgId);

        _userBorrowedpkgIds[auction.lastBidder].add(eventPkgId);

        freezeBalance(pkg);

        payable(_eventPkgDetails[eventPkgId].lender).transfer(auction.maxBid - (serviceFee + royaltyFee));

        endAuction(_rentingPkgWithAuction[eventPkgId]);     
    }

    function redeemPkg(uint eventPkgId) public whenNotPaused{
        EventPkg memory pkg = _eventPkgDetails[eventPkgId];

        checkEventPkgExists(eventPkgId);
        isValidPkgOwner(eventPkgId);
        require(pkg.borrower != address(0), "Renting: Package is not borrowed yet");
        require(block.timestamp >= pkg.endDate, "Renting: Package is not expired yet");

        _userBorrowedpkgIds[pkg.borrower].remove(eventPkgId);
        decreaseBorrowedBalance(pkg);

        _lenderOnRentPkgIds[pkg.lender].remove(eventPkgId);

        unFreezeBalance(_eventPkgDetails[eventPkgId]);
        unlockUserCopies(_eventPkgDetails[eventPkgId]);

        _ticketsERC1155Contract.transferTokens(
            address(this),
            pkg.lender, 
            pkg.ticketTypeIds,
            pkg.copies
        );
        
        delete _eventPkgDetails[eventPkgId];
        emit RentingPkgDeleted(pkg); 
    }

    function removeFromRent(uint eventPkgId) public whenNotPaused{
        EventPkg memory pkg = _eventPkgDetails[eventPkgId];

        checkEventPkgExists(eventPkgId);
        isValidPkgOwner(eventPkgId);
        checkPkgIsNotBorrowed(eventPkgId);

        unlockUserCopies(_eventPkgDetails[eventPkgId]);
        _lenderMarkedPkgIds[pkg.lender].remove(eventPkgId);
        
        delete _eventPkgDetails[eventPkgId];
        emit RentingPkgDeleted(pkg); 
    }

    function withdrawAmount(uint amount) public onlyOwner{
        require(amount > 0, "Main: amount is 0");
        require(amount <= address(this).balance, "Main: Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function getLenderMarkedPkgIds(address lender) public view returns(uint[] memory){
        return _lenderMarkedPkgIds[lender].values();
    }

    function getLenderOnRentPkgIds(address lender) public view returns(uint[] memory){
        return _lenderOnRentPkgIds[lender].values();
    }

    function getBorrowedPkgIds(address borrower) public view returns(uint[] memory){
        return _userBorrowedpkgIds[borrower].values();
    }
 
    function isEligibleForPkgCreation(EventPkg calldata pkg) private view {
        
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            
            uint lockedCopies = _lockedCopies[pkg.ticketTypeIds[i]][pkg.lender];
            uint frozenBalance = _frozenBalance[pkg.ticketTypeIds[i]][pkg.lender];

            require(pkg.copies[i] > 0, "Renting: Got invalid number of copies");

            if (_frozenBalance[pkg.ticketTypeIds[i]][pkg.lender] == 0){
                require(_ticketsERC1155Contract.balanceOf(pkg.lender, pkg.ticketTypeIds[i]) >= (lockedCopies + pkg.copies[i]), "Renting: Not eligible for creating package (release locked tokens)");
            }
            else{
                require(frozenBalance <= lockedCopies, "Renting: Assertion occured (frozen > locked)");

                require(_ticketsERC1155Contract.balanceOf(pkg.lender, pkg.ticketTypeIds[i]) >= (lockedCopies - frozenBalance) + pkg.copies[i], "Renting: Not eligible for creating package (release frozen tokens)");
            }
            
        }

    }

    function addNewEventPkgDetails(EventPkg calldata pkg) private{
        _eventPkgId++;
        _eventPkgDetails[_eventPkgId] = pkg;
        _lenderMarkedPkgIds[pkg.lender].add(_eventPkgId);
        lockUserCopies(pkg);
    }

    function lockUserCopies(EventPkg calldata pkg) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _lockedCopies[pkg.ticketTypeIds[i]][pkg.lender] += pkg.copies[i];
        }
    }

    function freezeBalance(EventPkg memory pkg) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _frozenBalance[pkg.ticketTypeIds[i]][pkg.lender] += pkg.copies[i];
        }
    }

    function increaseBorrowedBalance(EventPkg memory pkg, address borrower) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _borrowedBalance[pkg.ticketTypeIds[i]][borrower] += pkg.copies[i];
        }
    }

    function decreaseBorrowedBalance(EventPkg memory pkg) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _borrowedBalance[pkg.ticketTypeIds[i]][pkg.borrower] -= pkg.copies[i];
        }
    }

    function unlockUserCopies(EventPkg memory pkg) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _lockedCopies[pkg.ticketTypeIds[i]][pkg.lender] -= pkg.copies[i];
        }
    }

    function unFreezeBalance(EventPkg memory pkg) private{
        for (uint i; i < pkg.ticketTypeIds.length; i++){
            _frozenBalance[pkg.ticketTypeIds[i]][pkg.lender] -= pkg.copies[i];
        }
    }

    function findValueFromPercentage(uint percentage, uint totalAmount) public pure returns(uint){
        return (percentage * totalAmount) / 100;
    }

    function isValidEventPkg(EventPkg calldata pkg) private view{
        uint currentTimestamp = block.timestamp;

        if (pkg.lender == address(0) || pkg.lender != msg.sender || pkg.price == 0 || pkg.ticketTypeIds.length == 0 || pkg.copies.length == 0 || pkg.borrower != address(0) || pkg.startDate >= pkg.endDate || pkg.endDate <= currentTimestamp){
            revert("Renting: Got invalid event package");
        }

        checkTicketTypeAndCopiesArrayLength(pkg);
        // require(pkg.copies.length == pkg.ticketTypeIds.length, "Renting: Ticket type ids and copies arrays have different length");

        uint[] memory eventIds = new uint[](1);
        uint[][] memory  ticketTypeIds = new uint[][](1);
        
        eventIds[0] = pkg.eventId;
        ticketTypeIds[0] = pkg.ticketTypeIds;

        _mainContract.checkEventExistsWithTicketTypes(eventIds, ticketTypeIds);

        // checkUserBalance(pkg.lender, pkg.ticketTypeIds, pkg.copies);
    }

    function isValidPkgOwner(uint eventPkgId) private view {
        require(msg.sender == _eventPkgDetails[eventPkgId].lender, "Renting: Not an owner of package");
    }

    function checkUserBalance(address user, uint[] memory ticketTypeIds, uint[] memory copies) private view{

        for (uint i; i < ticketTypeIds.length; i++){
            require(copies[i] > 0, "Renting: Got invalid number of copies");
            require(_ticketsERC1155Contract.balanceOf(user, ticketTypeIds[i]) >= copies[i], "Renting: Seller has insufficient token balance");
        }
    }

    function checkEventPkgExists(uint eventPkgId) private view{
        require(_eventPkgDetails[eventPkgId].lender != address(0), "Renting: Event package dont exists");
    }

    function checkTicketTypeAndCopiesArrayLength(EventPkg calldata pkg) private pure{
        require(pkg.copies.length == pkg.ticketTypeIds.length, "Renting: Ticket type ids and copies arrays have different length");
    }

    function checkPkgIsNotBorrowed(uint eventPkgId)private view{
        require(_eventPkgDetails[eventPkgId].borrower == address(0), "Renting: Package already borrowed");
    }

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC1155, ERC1155Receiver)
    //     returns (bool)
    // {
    //     return
    //         interfaceId == type(IERC5006).interfaceId ||
    //         ERC1155.supportsInterface(interfaceId) ||
    //         ERC1155Receiver.supportsInterface(interfaceId);
    // }

    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract TicketsERC1155 is ERC1155, Ownable, Pausable, ERC1155Burnable {
    address public _adminContract;
    address public _resellingContract;
    address public _rentingContract;

    constructor(string memory baseURI) ERC1155(baseURI) {    

    }

    modifier onlyAllowed(address caller){
        require(caller == _resellingContract || caller == _rentingContract || caller == _adminContract || caller == owner(), "TicketsERC1155: Caller is not authorized");
        _;
    }

    modifier isValidAdminContract(){
        require(_adminContract != address(0), "TicketsERC1155: Admin contract address is null");
        _;
    }

    modifier isValidResellingContract(){
        require(_resellingContract != address(0), "TicketsERC1155: Admin contract address is null");
        _;
    }

    function setAdminContract(address adminContract) public onlyOwner{
        isValidContractAddress(adminContract);
        _adminContract = adminContract;
    }

    function setResellingContract(address resellingContract) public onlyOwner{
        isValidContractAddress(resellingContract);
        _resellingContract = resellingContract;
    }

    function setRentingContract(address rentingContract) public onlyOwner{
        isValidContractAddress(rentingContract);
        _rentingContract = rentingContract;
    }

    function setURI(string memory newuri) public onlyAllowed(msg.sender) {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyAllowed(msg.sender) isValidAdminContract
    {
        require(account != address(0), "TicketsERC1155: Account address is null");
        
        _mint(account, id, amount, data);

        givePermission(account);
    }

    function transferTokens(address from, address to, uint256[] memory ids, uint256[] memory amounts) public onlyAllowed(msg.sender) isValidAdminContract{
        givePermission(to);
        _safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function givePermission(address account) private{
        if (_adminContract != address(0) && !isApprovedForAll(account, _adminContract)){
            updateApproval(account, _adminContract, true);
        }
        if (_resellingContract != address(0) && !isApprovedForAll(account, _resellingContract)){
            updateApproval(account, _resellingContract, true);
        }
        if (_rentingContract != address(0) && !isApprovedForAll(account, _rentingContract)){
            updateApproval(account, _rentingContract, true);
        }
    }

    function isValidContractAddress(address contractAddr) private view{
        require(contractAddr.code.length > 0, "TicketsERC1155: Invalid contract address");
    }

    function updateApproval(address owner, address operator, bool appproved) public onlyAllowed(msg.sender){
       require(owner != address(0), "TicketsERC1155: Owner address is null");
       require(operator != address(0), "TicketsERC1155: Operator address is null");

       _setApprovalForAll(owner, operator, appproved);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyAllowed(msg.sender) isValidAdminContract
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}