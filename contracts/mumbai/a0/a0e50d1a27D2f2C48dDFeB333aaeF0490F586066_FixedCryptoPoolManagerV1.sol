// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IBasePoolManagerV1.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BasePoolManagerV1 is IBasePoolManagerV1, Ownable {
    address public override collateralToken;
    uint16 public override tradeFeeRate; // 1 means 1/10000
    uint8 public override tradeFactor;
    mapping(bytes32 => address) public override getPool;
    mapping(address => bool) public override isBuilder;

    modifier onlyBuilder() {
        require(isBuilder[msg.sender], "only builder");
        _;
    }

    constructor(
        address collateralToken_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_
    ) {
        collateralToken = collateralToken_;
        tradeFeeRate = tradeFeeRate_;
        tradeFactor = tradeFactor_;
    }

    function updateCollateralToken(
        address newToken
    ) external override onlyOwner {
        require(newToken != address(0), "zero address");
        collateralToken = newToken;
    }

    function updateTradeFeeRate(uint16 newFeeRate) external override onlyOwner {
        require(newFeeRate < 10000, "over 10000");
        tradeFeeRate = newFeeRate;
    }

    function updateTradeFactor(uint8 newFactor) external override onlyOwner {
        tradeFactor = newFactor;
    }

    function setBuilder(
        address builder,
        bool state
    ) external override onlyOwner {
        require(builder != address(0), "zero address");
        isBuilder[builder] = state;
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "over balance"
        );
        TransferHelper.safeTransfer(token, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BasePoolManagerV1.sol";
import "./FixedCryptoPoolV1.sol";
import "./interfaces/IFixedCryptoPoolManagerV1.sol";
import "./libraries/TransferHelper.sol";

contract FixedCryptoPoolManagerV1 is IFixedCryptoPoolManagerV1, BasePoolManagerV1 {
    address public override keeper;
    
    modifier onlyKeeper() {
        require(msg.sender == keeper, "only keeper");
        _;
    }

    constructor(
        address keeper_,
        address collateralToken_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_
    ) BasePoolManagerV1(collateralToken_, tradeFeeRate_, tradeFactor_) {
        keeper = keeper_;
    }

    function updateKeeper(address newKeeper) external override onlyOwner {
        require(newKeeper != address(0), "zero address");
        keeper = newKeeper;
    }

    function removeLiquidity(bytes32 poolId) external override onlyBuilder {
        require(getPool[poolId] != address(0), "pool not found");
        IFixedCryptoPoolV1 pool = IFixedCryptoPoolV1(getPool[poolId]);
        pool.removeLiquidity(address(this));
    }

    function createFixedCryptoPool(
        address priceOracle,
        uint256 initReserve,
        uint256 tradeStartTime,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string memory tag
    ) external onlyBuilder returns (address pool) {
        require(
            IERC20(collateralToken).balanceOf(address(this)) >= initReserve,
            "over balance"
        );
        bytes32 poolId = keccak256(
            abi.encode(
                priceOracle,
                initReserve,
                roundGap,
                tradeDuration,
                priceDuration
            )
        );
        pool = address(
            new FixedCryptoPoolV1(
                collateralToken,
                priceOracle,
                initReserve,
                tradeStartTime,
                roundGap,
                tradeDuration,
                priceDuration,
                totalRounds,
                tradeFeeRate,
                tradeFactor
            )
        );
        getPool[poolId] = pool;
        emit FixedCryptoPoolCreated(
            poolId,
            pool,
            priceOracle,
            initReserve,
            roundGap,
            tradeDuration,
            priceDuration,
            totalRounds,
            tag
        );

        TransferHelper.safeTransfer(collateralToken, pool, initReserve);
        FixedCryptoPoolV1(pool).addLiquidity();
    }

    function setStartPrice(bytes32 poolId) external override onlyKeeper {
        require(getPool[poolId] != address(0), "pool not found");
        IFixedCryptoPoolV1 pool = IFixedCryptoPoolV1(getPool[poolId]);
        pool.setStartPrice();
    }

    function endCurrentRound(bytes32 poolId) external override onlyKeeper {
        require(getPool[poolId] != address(0), "pool not found");
        IFixedCryptoPoolV1 pool = IFixedCryptoPoolV1(getPool[poolId]);
        TransferHelper.safeTransfer(
            collateralToken,
            address(pool),
            pool.initReserve()
        );
        pool.endCurrentRound();
    }

    function updateLeftRounds(bytes32 poolId, uint32 newLfetRound) external override onlyBuilder {
        require(getPool[poolId] != address(0), "pool not found");
        IFixedCryptoPoolV1 pool = IFixedCryptoPoolV1(getPool[poolId]);
        pool.updateLeftRounds(newLfetRound);
    }

    function restartNextRound(
        bytes32 poolId,
        uint256 tradeStartTime
    ) external override onlyBuilder {
        require(getPool[poolId] != address(0), "pool not found");
        IFixedCryptoPoolV1 pool = IFixedCryptoPoolV1(getPool[poolId]);
        TransferHelper.safeTransfer(
            collateralToken,
            address(pool),
            pool.initReserve()
        );
        pool.restartNextRound(tradeStartTime);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IFixedCryptoPoolV1.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FixedCryptoPoolV1 is IFixedCryptoPoolV1, ERC1155Supply {
    using FullMath for uint256;

    address public immutable override poolManager;
    address public immutable override collateralToken;
    address public immutable override priceOracle;

    uint256 public immutable override initReserve;
    uint32 public immutable override roundGap;
    uint32 public immutable override tradeDuration;
    uint32 public immutable override priceDuration;
    uint16 public immutable override tradeFeeRate;
    uint8 public immutable override tradeFactor;

    uint32 public override leftRounds;
    uint256 public override currentRound;
    uint256 public override totalClaimable;
    uint256 public override collateralReserve;

    mapping(uint256 => RoundData) public override getRoundData;

    uint256 private reserveLong;
    uint256 private reserveShort;

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, "only pool manager");
        _;
    }

    modifier onlyNotStopped() {
        require(leftRounds > 0, "stopped");
        _;
    }

    constructor(
        address collateralToken_,
        address priceOracle_,
        uint256 initReserve_,
        uint256 tradeStartTime,
        uint32 roundGap_,
        uint32 tradeDuration_,
        uint32 priceDuration_,
        uint32 totalRounds_,
        uint16 tradeFeeRate_,
        uint8 tradeFactor_
    ) ERC1155("") {
        poolManager = msg.sender;
        collateralToken = collateralToken_;
        priceOracle = priceOracle_;
        initReserve = initReserve_;
        leftRounds = totalRounds_;
        roundGap = roundGap_;
        tradeDuration = tradeDuration_;
        priceDuration = priceDuration_;
        tradeFeeRate = tradeFeeRate_;
        tradeFactor = tradeFactor_;
        getRoundData[0].tradeStartTime = tradeStartTime;
        getRoundData[0].tradeEndTime = tradeStartTime + tradeDuration;
        getRoundData[0].roundEndTime = getRoundData[0].tradeEndTime + priceDuration;
    }

    function getReserves() external view override returns (uint256[] memory) {
        uint256[] memory result = new uint256[](2);
        result[0] = reserveLong;
        result[1] = reserveShort;
        return result;
    }

    function updateLeftRounds(uint32 newLeftRounds) external override onlyPoolManager {
        require(newLeftRounds > 0, "zero");
        emit LeftRoundsUpdated(leftRounds, newLeftRounds);
        leftRounds = newLeftRounds;
    }

    function addLiquidity() external override onlyNotStopped {
        require(reserveLong == 0 && reserveShort == 0, "already add liquidity");
        uint256 collateralBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );
        uint256 amount = collateralBalance - collateralReserve;
        require(amount >= initReserve, "amount not equal initReserve");
        reserveLong = initReserve;
        reserveShort = initReserve;
        collateralReserve = collateralBalance;
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = reserveLong;
        reserves[1] = reserveShort;
        emit AddLiquidity(amount, reserves);
    }

    function removeLiquidity(address to) external override onlyPoolManager returns (uint256 amount) {
        require(leftRounds == 0, "only stopped");
        uint256 balance = IERC20(collateralToken).balanceOf(address(this));
        require(balance >= totalClaimable, "not enough balance");
        amount = balance - totalClaimable;
        TransferHelper.safeTransfer(collateralToken, to, amount);
        emit RemoveLiquidity(to, amount);
    }

    function buy(
        address to,
        uint8 option
    ) external override onlyNotStopped returns (uint256 shares) {
        require(to != address(0), "to is address zero");
        require(option <= 1, "wrong option");
        bool isLong = option == 0 ? true : false;
        uint256 collateralBalance = IERC20(collateralToken).balanceOf(
            address(this)
        );
        uint256 amount = collateralBalance - collateralReserve;
        require(amount > 0, "zero amount");
        RoundData memory roundData = getRoundData[currentRound];
        require(
            roundData.tradeStartTime >= block.timestamp &&
                roundData.tradeEndTime <= block.timestamp,
            "not trade time"
        );
        require(reserveLong > 0 && reserveShort > 0, "no liquidity");

        uint256 amountWithoutFee = amount -
            (amount * uint256(tradeFeeRate)) /
            10000;
        uint256 newReserveLong;
        uint256 newReserveShort;
        uint256 tokenId;
        if (isLong) {
            tokenId = currentRound * 2;
            newReserveShort = amountWithoutFee * tradeFactor + reserveShort;
            newReserveLong = reserveLong.mulDiv(reserveShort, newReserveShort);
            shares = amountWithoutFee.mulDiv(
                newReserveLong + newReserveShort,
                newReserveShort
            );
        } else {
            tokenId = currentRound * 2 + 1;
            newReserveLong = amountWithoutFee * tradeFactor + reserveLong;
            newReserveShort = reserveLong.mulDiv(reserveShort, newReserveLong);
            shares = amountWithoutFee.mulDiv(
                newReserveLong + newReserveShort,
                newReserveLong
            );
        }
        _mint(to, tokenId, shares, "");
        reserveLong = newReserveLong;
        reserveShort = newReserveShort;
        collateralReserve = collateralBalance;
        emit Buy(msg.sender, to, option, amount, shares, currentRound);
    }

    function sell(
        address to,
        uint8 option
    ) external override onlyNotStopped returns (uint256 amount) {
        require(to != address(0), "to is address zero");
        require(option <= 1, "wrong option");
        bool isLong = option == 0 ? true : false;
        RoundData memory roundData = getRoundData[currentRound];
        require(
            roundData.tradeStartTime >= block.timestamp &&
                roundData.tradeEndTime <= block.timestamp,
            "not trade time"
        );

        uint256 tokenId = isLong ? currentRound * 2 : currentRound * 2 + 1;
        uint256 shares = balanceOf(address(this), tokenId);
        uint256 newReserveLong;
        uint256 newReserveShort;
        if (isLong) {
            newReserveLong = reserveLong + shares;
            newReserveShort = reserveLong.mulDiv(reserveShort, newReserveLong);
            amount = shares.mulDiv(
                newReserveLong + newReserveShort,
                newReserveShort
            );
        } else {
            newReserveShort = reserveShort + shares;
            newReserveLong = reserveLong.mulDiv(reserveShort, newReserveShort);
            amount = shares.mulDiv(
                newReserveLong + newReserveShort,
                newReserveLong
            );
        }
        _burn(address(this), tokenId, shares);
        reserveLong = newReserveLong;
        reserveShort = newReserveShort;
        TransferHelper.safeTransfer(collateralToken, to, amount);
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit Sell(msg.sender, to, option, amount, shares, currentRound);
    }


    function claim(address to) external override returns (uint256 amount) {
        uint256[] memory rounds = new uint256[](currentRound);
        for (uint256 i = 0; i < currentRound; i++) {
            rounds[i] = i;
        }
        return claim(to, rounds);
    }

    function claim(
        address to,
        uint256[] memory rounds
    ) public override returns (uint256 amount) {
        require(to != address(0), "to is address zero");
        RoundData memory data;
        uint256 round;
        uint256 shares;
        for (uint256 i = 0; i < rounds.length; i++) {
            require(rounds[i] < currentRound, "over current round");
            round = rounds[i];
            data = getRoundData[round];
            if (data.oracleRoundIdOfEndPrice > data.oracleRoundIdOfStartPrice) {
                if (data.startPrice < data.endPrice) {
                    shares = balanceOf(address(this), round * 2);
                    if (shares > 0) _burn(address(this), round * 2, shares);
                } else if (data.startPrice > data.endPrice) {
                    shares = balanceOf(address(this), round * 2 + 1);
                    if (shares > 0) _burn(address(this), round * 2 + 1, shares);
                } else {}
                amount += shares;
            }
        }
        require(totalClaimable >= amount, "not enough to be claim");
        totalClaimable -= amount;
        TransferHelper.safeTransfer(collateralToken, to, amount);
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit Claim(msg.sender, to, amount, rounds);
    }

    function setStartPrice() external override onlyNotStopped {
        RoundData memory roundData = getRoundData[currentRound];
        require(roundData.startPrice == 0, "already set");
        require(
            roundData.tradeEndTime < block.timestamp,
            "not over trade end time"
        );
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceOracle);
        (
            uint80 nextRoundID,
            int256 nextPrice,
            ,
            uint256 nextUpdatedAt,

        ) = aggregator.latestRoundData();
        (
            uint80 preRoundID,
            int256 prePrice,
            ,
            uint256 preUpdatedAt,

        ) = aggregator.getRoundData(nextRoundID - 1);

        while (roundData.tradeEndTime < preUpdatedAt) {
            nextRoundID = preRoundID;
            nextPrice = prePrice;
            nextUpdatedAt = preUpdatedAt;
            (preRoundID, prePrice, , preUpdatedAt, ) = aggregator.getRoundData(
                preRoundID - 1
            );
        }

        if (
            roundData.tradeEndTime >= preUpdatedAt &&
            roundData.tradeEndTime < nextUpdatedAt
        ) {
            roundData.startPrice = prePrice;
            roundData.oracleRoundIdOfStartPrice = preRoundID;
        } else {
            roundData.startPrice = nextPrice;
            roundData.oracleRoundIdOfStartPrice = nextRoundID;
        }
        getRoundData[currentRound] = roundData;
        emit StartPriceSet(
            msg.sender,
            currentRound,
            roundData.startPrice,
            roundData.oracleRoundIdOfStartPrice
        );
    }

    function endCurrentRound() external override onlyNotStopped onlyPoolManager {
        // set endPrice
        RoundData memory roundData = getRoundData[currentRound];
        require(
            roundData.roundEndTime <= block.timestamp,
            "not over round end time"
        );
        require(roundData.endPrice == 0, "already set endPrice");
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceOracle);
        (
            uint80 nextRoundID,
            int256 nextPrice,
            ,
            uint256 nextUpdatedAt,

        ) = aggregator.latestRoundData();
        (
            uint80 preRoundID,
            int256 prePrice,
            ,
            uint256 preUpdatedAt,

        ) = aggregator.getRoundData(nextRoundID - 1);

        while (roundData.roundEndTime < preUpdatedAt) {
            nextRoundID = preRoundID;
            nextPrice = prePrice;
            nextUpdatedAt = preUpdatedAt;
            (preRoundID, prePrice, , preUpdatedAt, ) = aggregator.getRoundData(
                preRoundID - 1
            );
        }

        if (
            roundData.roundEndTime >= preUpdatedAt &&
            roundData.roundEndTime < nextUpdatedAt
        ) {
            roundData.endPrice = prePrice;
            roundData.oracleRoundIdOfEndPrice = preRoundID;
        } else {
            roundData.endPrice = nextPrice;
            roundData.oracleRoundIdOfEndPrice = nextRoundID;
        }
        getRoundData[currentRound] = roundData;
        emit EndPriceSet(
            msg.sender,
            currentRound,
            roundData.endPrice,
            roundData.oracleRoundIdOfEndPrice
        );

        // add win shares to totalClaimable
        if (roundData.startPrice < roundData.endPrice) {
            totalClaimable += totalSupply(currentRound * 2);
        } else if (roundData.startPrice > roundData.endPrice) {
            totalClaimable += totalSupply(currentRound * 2 + 1);
        }

        reserveLong = 0;
        reserveShort = 0;
        leftRounds--;
        if (leftRounds > 0) {
            _startNewRound(roundData.roundEndTime + roundGap);
        }
    }

    function restartNextRound(
        uint256 tradeStartTime
    ) external override onlyNotStopped onlyPoolManager {
        _startNewRound(tradeStartTime);
    }

    function getClaimable(
        address user,
        uint256[] memory rounds
    )
        external
        view
        override
        returns (uint256[] memory tokenIds, uint256[] memory amounts)
    {
        tokenIds = new uint256[](rounds.length);
        amounts = new uint256[](rounds.length);
        RoundData memory data;
        uint256 round;
        for (uint256 i = 0; i < rounds.length; i++) {
            require(rounds[i] < currentRound, "over current round");
            round = rounds[i];
            data = getRoundData[round];
            if (data.oracleRoundIdOfEndPrice > data.oracleRoundIdOfStartPrice) {
                if (data.startPrice < data.endPrice) {
                    tokenIds[i] = round * 2;
                    amounts[i] = balanceOf(user, round * 2);
                } else if (data.startPrice > data.endPrice) {
                    tokenIds[i] = round * 2 + 1;
                    amounts[i] = balanceOf(user, round * 2 + 1);
                } else {}
            }
        }
    }

    function _startNewRound(uint256 tradeStartTime) internal {
        currentRound++;
        uint256 tradeEndTime = tradeStartTime + tradeDuration;
        uint256 roundEndTime = tradeEndTime + priceDuration;
        getRoundData[currentRound].tradeStartTime = tradeStartTime;
        getRoundData[currentRound].tradeEndTime = tradeEndTime;
        getRoundData[currentRound].roundEndTime = roundEndTime;

        uint256 collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        require(
            collateralBalance - totalClaimable >= initReserve,
            "not enough balance"
        );
        TransferHelper.safeTransfer(
            collateralToken,
            poolManager,
            collateralBalance - totalClaimable - initReserve
        );
        reserveLong = initReserve;
        reserveShort = initReserve;
        collateralReserve = IERC20(collateralToken).balanceOf(address(this));
        emit NewRoundStarted(
            currentRound,
            tradeStartTime,
            tradeEndTime,
            roundEndTime
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBasePoolManagerV1 {
    function collateralToken() external view returns (address);
    function tradeFeeRate() external view returns (uint16);
    function tradeFactor() external view returns (uint8);
    function getPool(bytes32 poolId) external view returns (address);
    function isBuilder(address) external view returns (bool);

    function updateCollateralToken(address newToken) external;
    function updateTradeFeeRate(uint16 newFeeRate) external;
    function updateTradeFactor(uint8 newFactor) external;
    function setBuilder(address builder, bool state) external;
    function withdraw(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBasePoolV1 {
    event AddLiquidity(uint256 amount, uint256[] reserves);
    event RemoveLiquidity(address indexed to, uint256 amount);
    event Buy(address indexed sender, address indexed to, uint8 indexed option, uint256 amount, uint256 shares, uint256 round);
    event Sell(address indexed sender, address indexed to, uint8 indexed option, uint256 amount, uint256 shares, uint256 round);
    event Claim(address indexed sender, address indexed to, uint256 amount,  uint256[] rounds);

    function poolManager() external view returns (address);
    function collateralToken() external view returns (address);
    function tradeFeeRate() external view returns (uint16); // 1 means 1/10000
    function tradeFactor() external view returns (uint8);
    function getReserves() external view returns (uint256[] memory);
    function collateralReserve() external view returns (uint256);

    function addLiquidity() external;
    function removeLiquidity(address to) external returns (uint256 amount);
    function buy(address to, uint8 option) external returns (uint256 shares);
    function sell(address to, uint8 option) external returns (uint256 amount);
    function claim(address to) external returns (uint256 amount);
    function claim(address to, uint256[] memory rounds) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IBasePoolManagerV1.sol";

interface IFixedCryptoPoolManagerV1 is IBasePoolManagerV1 {
    event FixedCryptoPoolCreated(
        bytes32 poolId,
        address pool,
        address priceOracle,
        uint256 initReserve,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string tag
    );

    function keeper() external view returns (address);
    function updateKeeper(address newKeeper) external;
    function removeLiquidity(bytes32 poolId) external;
    function createFixedCryptoPool(
        address priceOracle,
        uint256 initReserve,
        uint256 tradeStartTime,
        uint32 roundGap,
        uint32 tradeDuration,
        uint32 priceDuration,
        uint32 totalRounds,
        string memory tag
    ) external returns (address pool);
    function setStartPrice(bytes32 poolId) external;
    function endCurrentRound(bytes32 poolId) external;
    function updateLeftRounds(bytes32 poolId, uint32 newLfetRound) external;
    function restartNextRound(bytes32 poolId, uint256 tradeStartTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IBasePoolV1.sol";

interface IFixedCryptoPoolV1 is IBasePoolV1 {
    event StartPriceSet(address sender, uint256 round, int256 startPrice, uint80 oracleRoundIdOfStartPrice);
    event EndPriceSet(address sender, uint256 round, int256 endPrice, uint80 oracleRoundIdOfEndPrice);
    event NewRoundStarted(uint256 round, uint256 tradeStartTime, uint256 tradeEndTime, uint256 roundEndTime);
    event LeftRoundsUpdated(uint32 oldLeftRounds, uint32 newLeftRounds);

    struct RoundData {
        uint256 tradeStartTime;
        uint256 tradeEndTime;
        uint256 roundEndTime;
        int256 startPrice;
        int256 endPrice;
        uint80 oracleRoundIdOfStartPrice;
        uint80 oracleRoundIdOfEndPrice;
    }

    function priceOracle() external view returns (address);
    function roundGap() external view returns (uint32);
    function tradeDuration() external view returns (uint32);
    function priceDuration() external view returns (uint32);
    function leftRounds() external view returns (uint32);
    function currentRound() external view returns (uint256);
    function totalClaimable() external view returns (uint256);
    function initReserve() external view returns (uint256);
    function getRoundData(uint256 round) external view returns (
        uint256 tradeStartTime,
        uint256 tradeEndTime,
        uint256 roundEndTime,
        int256 startPrice,
        int256 endPrice,
        uint80 oracleRoundIdOfStartPrice,
        uint80 oracleRoundIdOfEndPrice
    ); 
    function getClaimable(
        address user, 
        uint256[] memory rounds
    ) external view returns (uint256[] memory tokenIds, uint256[] memory amounts);

    function updateLeftRounds(uint32 newLeftRounds) external;
    function setStartPrice() external;
    function endCurrentRound() external;
    function restartNextRound(uint256 tradeStartTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}