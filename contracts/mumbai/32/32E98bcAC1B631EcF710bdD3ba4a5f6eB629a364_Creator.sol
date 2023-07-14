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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC7254 standard as defined in the EIP.
 */
interface IERC7254 {

    struct UserInformation {
        uint256 inReward;
        uint256 outReward;
        uint256 withdraw;
    }

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
     * @dev Emitted when the add reward  of a `contributor` is set by
     * a call to {approve}.
     */
    event UpdateReward(address indexed contributor, uint256 value);

    /**
     * @dev Emitted when `value` tokens reward to
     * `caller`.
     *
     * Note that `value` may be zero.
     */
    event GetReward(address indexed owner, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns user information by `account`.
     */
    function informationOf(address account) external view  returns (UserInformation memory);

    /**
     * @dev Returns token reward.
     */
    function tokenReward() external view returns (address);


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

    /**
     * @dev Add `amount` tokens .
     *
     * Returns a rewardPerShare.
     *
     * Emits a {UpdateReward} event.
     */
    function updateReward(uint256 amount) external returns(uint256);

    /**
     * @dev Returns the amount of reward by `account`.
     */
    function viewReward(address account) external returns (uint256);

    /**
     * @dev Moves reward to caller.
     *
     * Returns a amount value of reward.
     *
     * Emits a {GetReward} event.
     */
    function getReward() external returns(uint256);
}

interface IReferral {
    function getSponsor(address user) external view returns(address);
    function getRef(address user) external view returns(address[] memory);
    function getFee() external view returns(uint);
    function getCharity() external view returns(address);
    function getReceiver(address user) external view returns(address);
}

interface IRouter {

    function getReferral() external view returns (address);

    function launchpadAddLiquidity(
        address token, 
        address nft, 
        uint256 id,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin,
        address to, 
        uint deadline
    ) external returns(address);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferFromNFT(address nft, address from, address to, uint256 id, uint value, bytes memory dataNFT) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
        (bool success, bytes memory data) = nft.call(abi.encodeWithSelector(0xf242432a, from, to, id, value, dataNFT));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_NFT_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
    
}

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC7254/IERC7254.sol";
import "../library/TransferHelper.sol";
import "../library/SafeMath.sol";
import "./LaunchPad.sol";

contract Creator is ERC1155, Ownable, ERC1155Supply {
    using SafeMath for uint;
    string private _name;
    string private _symbol;
    address public WETH;
    address public receiver;
    address public demask;
    uint public feeLockDemask;
    address public referral;
    address public router;
    struct vote_mint {
        address creator;
        address receiver;
        uint id;
        uint startTime;
        uint endTime;
        uint totalMint;
        uint totalVote;
        uint currentSupply;
        bool statusUnlock;
        bool statusMint;
    }
    struct vote_uri {
        address creator;
        uint id;
        uint startTime;
        uint endTime;
        string uri;
        uint totalVote;
        uint currentSupply;
        bool statusUnlock;
        bool statusUri;
    }
    mapping(address => mapping(uint => mapping(uint => mapping(uint => uint)))) public uservote; // user -> option -> id -> count
    mapping(uint => uint) public countVoteMint; // tokenId -> count
    mapping(uint => mapping(uint => vote_mint)) public votemint; // id -> count 
    mapping(uint => uint) public countVoteUri; // tokenid -> count
    mapping(uint => mapping(uint => vote_uri)) public voteuri;
    mapping(uint256 => string) private _uri;
    mapping(address => uint256[]) private ownerMint;
    mapping(uint256 => bool) public isMint;
    mapping(address => bool) public isLaunchPad;

    constructor(address _WETH, address _receiver, address _demask, uint _feeLockDemask, address _referral) ERC1155(""){
        _name = 'DeMask Creator';
        _symbol = 'DRC';
        WETH = _WETH;
        receiver = _receiver;
        demask = _demask;
        feeLockDemask = _feeLockDemask;
        referral = _referral;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    modifier IsMint(uint256 id) {
        require(!isMint[id], "Creator: exist id");
        _;
        isMint[id] = true;
    }
    modifier IsNotMint(uint256 id) {
        require(isMint[id], "Creator: id not exist");
        _;
    }
    modifier VerifyTime(uint startTime, uint endTime) {
        require(endTime > block.timestamp && endTime > startTime);
        _;
    }
    
    event LaunchpadSubmit(
        address creator,
        uint id,
        uint initial,
        uint totalSell,
        uint percentLock,
        uint price,
        uint priceListing,
        address tokenPayment,
        uint startTime,
        uint endTime,
        uint durationLock,
        uint maxbuy,
        bool refundType,
        bool whiteList,
        string url,
        bytes data,
        uint timeStamp
    );

    event Launchpad(
        address to,
        address token,
        uint id,
        uint bill,
        uint amount,
        uint timeStamp
    );

    event VoteMintSubmit (
        address creator,
        uint id,
        uint startTime,
        uint endTime,
        uint totalMint,
        uint currentSupply,
        uint count,
        uint timeStamp
    );
    event VoteUriSubmit (
        address creator,
        uint id,
        string uri,
        uint startTime,
        uint endTime,
        uint currentSupply,
        uint count,
        uint timeStamp
    );

    //true : lock, false: unlock
    event UserVote (
        address voter,
        uint option,
        uint id,
        uint count,
        uint amount,
        bool status,  
        uint timeStamp
    );

    event MintWithVote (
        address from,
        address receiver,
        uint totalMint,
        uint timeStamp
    );
    event ChangeUriWithVote (
        address from,
        string uri,
        uint timeStamp
    );

    // event URI(string _value, uint256 _id);

    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function claimReward() external onlyOwner(){
        uint256 reward = IERC7254(demask).getReward();
        address tokenReward = IERC7254(demask).tokenReward();
        TransferHelper.safeTransfer(tokenReward, msg.sender, reward);
    }

    function addRouter(address _router) external onlyOwner(){
        require(_router != address(0));
        router = _router;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return _uri[_id];
    }

    function getList(address _owner) public view returns (uint256[] memory){
        return ownerMint[_owner];
    }

    function existLaunchPad(address _launchpad) public view returns (bool){
        return isLaunchPad[_launchpad];
    }

    function _setURI(uint256 _id, string memory _url) internal virtual{
        _uri[_id] = _url;
        emit URI(_url, _id);
    }
    function mint(address account, uint id, uint amount, bytes memory data, string memory _url) external IsMint(id){       
        require(amount > 0);
        _mint(account, id, amount, data);
        ownerMint[account].push(id);
        _setURI(id, _url);
    }

    function launchpad_submit(LaunchPad.launchpad_data memory launchpad_information , string memory _url, bytes memory data) external IsMint(launchpad_information.id) VerifyTime(launchpad_information.startTime, launchpad_information.endTime){
        require(launchpad_information.price > 0 && launchpad_information.priceListing > 0 , "PRICE_WRONG");
        require(launchpad_information.maxbuy >= launchpad_information.price);
        require(launchpad_information.percentReferral + launchpad_information.percentLock <= 1000000, "Exceed Percent");
        require(router != address(0), "Waiting Add Router");
        uint maxNFTLock = launchpad_information.price * launchpad_information.totalSell * launchpad_information.percentLock / ( launchpad_information.priceListing * 1000000);  // 1% -> 10000
        LaunchPad launchPad = new LaunchPad(launchpad_information, maxNFTLock, address(this), referral, WETH, router);
        uint totalSupply_id = launchpad_information.initial + maxNFTLock +  launchpad_information.totalSell;
        _setURI(launchpad_information.id, _url);
        _mint(address(launchPad), launchpad_information.id, totalSupply_id, data);
        isLaunchPad[address(launchPad)] = true;
        emit LaunchpadSubmit(
            msg.sender, 
            launchpad_information.id, 
            launchpad_information.initial, 
            launchpad_information.totalSell, 
            launchpad_information.percentLock, 
            launchpad_information.price, 
            launchpad_information.priceListing, 
            launchpad_information.tokenPayment, 
            launchpad_information.startTime,
            launchpad_information.endTime,
            launchpad_information.durationLock, 
            launchpad_information.maxbuy,
            launchpad_information.refundType,
            launchpad_information.whiteList,
            _url,
            data, 
            block.timestamp);
    }

    function unlock(uint option, uint id, uint count) external {
        require(option == 1 || option == 2);
        if(option == 1){
            address creator = votemint[id][count].creator;
            uint endTime  = votemint[id][count].endTime;
            bool status = votemint[id][count].statusUnlock;
            require(creator != address(0) && block.timestamp > endTime && status == false);
            votemint[id][count].statusUnlock = true;
            _unlockDemask(creator);
        }
        if(option == 2){
            address creator = voteuri[id][count].creator;
            uint endTime = voteuri[id][count].endTime;
            bool status = voteuri[id][count].statusUnlock;
            require(creator != address(0) && block.timestamp > endTime && status == false);
            votemint[id][count].statusUnlock = true;
            _unlockDemask(creator);
        }
    }
    
    function submit_vote_mint_token(address _receiver, uint id, uint startVote, uint endVote, uint totalMint) external IsNotMint(id) VerifyTime(startVote, endVote){
        _lockDemask();
        require(totalMint > 0);
        require(_receiver != address(0));
        uint count = countVoteMint[id];
        votemint[id][count + 1] = vote_mint(msg.sender, _receiver, id, startVote, endVote, totalMint, 0, totalSupply(id), false, false);
        countVoteMint[id] +=1;
        emit VoteMintSubmit(msg.sender, id, startVote, endVote, totalMint, totalSupply(id), (count+1), block.timestamp);
    }

    function vote_mint_token(uint _count, uint _id, uint amount) external {
        require(block.timestamp > votemint[_id][_count].startTime && block.timestamp <= votemint[_id][_count].endTime);
        require(!votemint[_id][_count].statusMint);
        require(amount > 0);
        _lock(_id, amount);
        uservote[msg.sender][1][_id][_count] += amount;
        votemint[_id][_count].totalVote += amount;
        emit UserVote(msg.sender, 1, _id, _count, amount, true, block.timestamp);
    }
    function unlock_vote(uint option, uint _count, uint _id) external {
        require(option == 1 || option == 2);
        require(uservote[msg.sender][option][_id][_count] > 0);
        uint amount = uservote[msg.sender][option][_id][_count];
        uservote[msg.sender][option][_id][_count] = 0;
        if(option == 1){
            votemint[_id][_count].totalVote -= amount;
        } 
        else if(option == 2){
            voteuri[_id][_count].totalVote -= amount;
        }
        _unlock(_id, amount);
        emit UserVote(msg.sender, option, _id, _count, amount, false, block.timestamp);
    }
    function mint_with_vote(uint _count, uint id) external {
        require(!votemint[id][_count].statusMint);
        require(2*votemint[id][_count].totalVote > votemint[id][_count].currentSupply && votemint[id][_count].totalVote > 0);
        votemint[id][_count].statusMint = true;
        _mint(votemint[id][_count].receiver, id, votemint[id][_count].totalMint, '0x');
        emit MintWithVote(msg.sender, votemint[id][_count].receiver, votemint[id][_count].totalMint, block.timestamp);
    }

    function submit_vote_change_uri(uint id, uint startVote, uint endVote, string memory uri_) external IsNotMint(id) VerifyTime(startVote, endVote){
        _lockDemask();  
        uint count = countVoteUri[id];
        voteuri[id][count+1] = vote_uri(msg.sender, id, startVote, endVote, uri_, 0, totalSupply(id), false, false);
        countVoteUri[id] += 1;
        emit VoteUriSubmit (msg.sender, id, uri_, startVote, endVote, totalSupply(id), (count+1), block.timestamp);
    }
    function vote_uri_token(uint _count, uint _id, uint amount) external {
        require(voteuri[_id][_count].startTime < block.timestamp && block.timestamp <= voteuri[_id][_count].endTime);
        require(!voteuri[_id][_count].statusUri); 
        require(amount > 0);
        _lock(_id, amount);
        uservote[msg.sender][2][_id][_count] += amount;
        voteuri[_id][_count].totalVote += amount;
        emit UserVote(msg.sender, 2, _id, _count, amount, true, block.timestamp);
    }

    function change_uri_with_vote(uint _count, uint id) external {
        require(!voteuri[id][_count].statusUri);
        require(2*voteuri[id][_count].totalVote > voteuri[id][_count].currentSupply && votemint[id][_count].totalVote > 0);
        voteuri[id][_count].statusUri = true;
        _setURI(id, voteuri[id][_count].uri);
        emit ChangeUriWithVote(msg.sender, voteuri[id][_count].uri, block.timestamp);
    }

    function burn(uint _id, uint _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function _lockDemask() internal {
        TransferHelper.safeTransferFrom(demask, msg.sender, address(this), feeLockDemask);
    }
    function _unlockDemask(address creator) internal {
        TransferHelper.safeTransfer(demask, creator, feeLockDemask);
    }

    function _lock(uint id, uint amount) internal {
        _burn(msg.sender, id, amount);
    }
    function _unlock(uint id, uint amount) internal {
        _mint(msg.sender, id, amount, '0x');
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// Receive token
// add liquidity and transfer reward 
// unlock liquidity 
pragma solidity ^0.8.9;
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interface/IReferral.sol";
import "../interface/IWETH.sol";
// import "../interface/ICreator.sol";
import "../ERC7254/IERC7254.sol";
import "../library/TransferHelper.sol";
import "../interface/IRouter.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface ICreator {
    function burn(uint _id, uint _amount) external;
}
contract LaunchPad is ERC1155Holder {
    struct launchpad_data {
        address creator;
        uint id;
        uint initial;
        uint totalSell;
        uint percentLock;
        uint price;
        uint priceListing;
        address tokenPayment;
        uint startTime;
        uint endTime;
        uint durationLock;
        uint maxbuy;
        bool refundType;
        bool whiteList;
        uint percentReferral;
    }

    launchpad_data public LaunchPadInfo;
    uint public totalSoldout;
    uint public totalTokenReceive;
    uint public totalRewardReferral;
    address referral;
    address WETH;
    address dml;
    address NFT;
    address router;
    uint maxNFTLock;
    bool isListed = false;
    mapping(address => bool) public admin;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public balanceOf;
    constructor(launchpad_data memory launchpad_information, uint _maxNFTLock, address _nft, address _referral, address _weth, address _router) {
        // refund type: true: burn, false: refund
        // whitelist: true: enable, false: disable
        //  1% -> 10000
        LaunchPadInfo = launchpad_information;
        referral = _referral;
        WETH = _weth;
        NFT = _nft;
        maxNFTLock = _maxNFTLock;
        router = _router;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyCreator(){
         require(msg.sender == LaunchPadInfo.creator, "Only Creator");
        _;
    }  

    modifier onlyAdmin(){
        require(admin[msg.sender] || msg.sender == LaunchPadInfo.creator, "Only Admin or Creator");
        _;
    }

    modifier verifyAmount(uint _amount){
        require(totalSoldout + _amount <= LaunchPadInfo.totalSell, "Exceed amount");
        _;
    }
    modifier verifyWhiteList(){
        if(LaunchPadInfo.whiteList){
            require(isWhitelisted[msg.sender], "No whitelist");
        }
        _;
    }

    modifier verifyTimeClaimDml(){
        uint timeClaim = LaunchPadInfo.endTime + LaunchPadInfo.durationLock;
        require(timeClaim <= block.timestamp, "Waiting time");
        _;
    }

    modifier verifyTimeClaim(){
        require(block.timestamp > LaunchPadInfo.endTime, "Waiting end");
        _;
    }

    modifier verifyTimeBuy(){
        require(block.timestamp > LaunchPadInfo.startTime && block.timestamp <= LaunchPadInfo.endTime, "Sold out");
        _;
    }

    event Admin(
        address admin,
        bool status,
        uint blockTime
    );

    event WhiteList(
        address user,
        bool status,
        uint blockTime
    );

    event Buy(
        address user,
        uint amount,
        uint totalSold,
        uint blockTime
    );

    event Claim(
        address user,
        uint amount,
        uint blockTime
    );

    event Listing(
        address dml,
        uint totalTokenAddLiquidity,
        uint totalNFTAddLiquidity,
        uint totalBurn,
        uint totalNFTReceive,
        uint totalTokenReceive,
        uint blockTime
    );

     function addAdmin(address[] memory _admin, bool[] memory _status) external onlyCreator() {
        for(uint i =0; i < _admin.length; i++){
            admin[_admin[i]] = _status[i];
            emit Admin(_admin[i], _status[i], block.timestamp);
        }
    }

    function addWhieList(address[] memory _address, bool[] memory _status) external onlyAdmin(){
        require(LaunchPadInfo.whiteList, "WhiteList is disable");
        require(_address.length == _status.length, "Input Wrong");
        for(uint i = 0; i < _address.length; i++){
            isWhitelisted[_address[i]] = _status[i];
            emit WhiteList(_address[i], _status[i], block.timestamp);
        }
    }

    function buy(uint _amount) external verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        uint amount = LaunchPadInfo.price * _amount;
        TransferHelper.safeTransferFrom(LaunchPadInfo.tokenPayment, msg.sender, address(this), amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        totalTokenReceive += amount;
        _tranferToReferral(amount);
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function buyETH(uint _amount) external payable verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        require(LaunchPadInfo.tokenPayment == WETH);
        uint amount = LaunchPadInfo.price * _amount;
        require(amount >= msg.value, "Amount is low");
        IWETH(WETH).deposit{value: msg.value}();
        if (msg.value > amount) TransferHelper.safeTransferETH(msg.sender, msg.value - amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        totalTokenReceive += amount;
        _tranferToReferral(amount);
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function claim() external verifyTimeClaim(){
        require(isListed, "Wait Listing");
        require(balanceOf[msg.sender] > 0, "Balance = 0");
        uint amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        TransferHelper.safeTransferFromNFT(NFT, address(this), msg.sender, LaunchPadInfo.id, amount, bytes(''));
        emit Claim(msg.sender, amount, block.timestamp);
    }

    function listing() external verifyTimeClaim(){
        // transfer money and initial token to creator
        uint refund = LaunchPadInfo.totalSell - totalSoldout;
        uint totalBurn = LaunchPadInfo.refundType ? refund : 0;
        uint totalRefund = refund - totalBurn;
        uint totalNFTReceive = LaunchPadInfo.initial + totalRefund;
        uint tokenAddLiquidity = totalTokenReceive * LaunchPadInfo.percentLock / 1000000;
        uint NFTAddLiquidity = tokenAddLiquidity / LaunchPadInfo.priceListing;
        uint totalNFTAddLiquidity = maxNFTLock > NFTAddLiquidity ? NFTAddLiquidity : maxNFTLock;
        uint remaining = maxNFTLock - totalNFTAddLiquidity;
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, router, tokenAddLiquidity);
        TransferHelper.safeTransferFromNFT(NFT, address(this) , router, LaunchPadInfo.id, totalNFTAddLiquidity, bytes(''));
        dml = IRouter(router).launchpadAddLiquidity(LaunchPadInfo.tokenPayment, NFT, LaunchPadInfo.id, tokenAddLiquidity, totalNFTAddLiquidity, 0, address(this), block.timestamp + 20*60);
        // if((totalBurn + remaining) > 0){
        //     ICreator(NFT).burn(LaunchPadInfo.id, (totalBurn + remaining));
        // }
        // if(totalNFTReceive > 0){
        //     TransferHelper.safeTransferFromNFT(NFT, address(this), LaunchPadInfo.creator, LaunchPadInfo.id, totalNFTReceive, bytes(''));
        // }
        // if((totalTokenReceive - tokenAddLiquidity - totalRewardReferral) > 0){
        //     TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, LaunchPadInfo.creator, (totalTokenReceive - tokenAddLiquidity - totalRewardReferral));
        // }
        isListed = true;
        emit Listing(dml, tokenAddLiquidity, totalNFTAddLiquidity, (totalBurn + remaining), totalNFTReceive, (totalTokenReceive - tokenAddLiquidity), block.timestamp);
    }

    function claimDml() external onlyCreator() verifyTimeClaimDml(){
        uint256 balance = IERC7254(dml).balanceOf(address(this));
        TransferHelper.safeTransfer(dml, msg.sender, balance);
        uint256 reward = IERC7254(dml).getReward();
        address tokenReward = IERC7254(dml).tokenReward();
        TransferHelper.safeTransfer(tokenReward, msg.sender, reward);
    }

    function claimReward() external onlyCreator(){
        uint256 reward = IERC7254(dml).getReward();
        address tokenReward = IERC7254(dml).tokenReward();
        TransferHelper.safeTransfer(tokenReward, msg.sender, reward);
    }

    function _tranferToReferral(uint _amount) internal {
        uint amountFee = _amount * LaunchPadInfo.percentReferral / 1000000;
        totalRewardReferral += amountFee;
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, IReferral(referral).getReceiver(msg.sender), amountFee);
    }

}