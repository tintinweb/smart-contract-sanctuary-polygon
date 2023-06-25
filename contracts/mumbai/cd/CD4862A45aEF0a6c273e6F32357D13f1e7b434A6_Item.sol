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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Empire of Sight item contract
 * @dev Extends ERC-1155 basic standard multi-token implementation with various features for the highest safety
 * and the best gaming experience.
 * @notice Play https://empireofsight.com
 * @author leeevi
 */
contract Item is ERC1155, Ownable, ReentrancyGuard {
    // Solidity's arithmetic operations with added overflow checks
    using SafeMath for uint256;

    // All the attributes of an item
    struct ItemInfo {
        uint256 minted;
        uint256 totalSupply;
        uint256 priceUsd; // (USD value in Wei)
        bool paused;
    }

    // Pack contains multiple types of items for batch transactions
    struct PackInfo {
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256 priceUsd; // (USD value in Wei)
        bool paused;
    }

    // ERC-20 token and its price oracle
    struct ERC20TokenInfo {
        IERC20 tokenContract;
        AggregatorV3Interface priceOracle;
        bool paused;
    }

    // Item types (IDs)
    uint256[] public itemTypes;

    // Cost of Mayne Transmuting items
    uint256 public transmuteFee;

    // Sum of received transmuting fees counts from the last withdrawal
    uint256 public transmuteFeeSum;

    // Limit of the ERC-20 token withdrawal amount in one transaction
    uint256 internal _ERC20WithdrawalLimit = 5;

    // Pause for everything
    bool public pausedAll;

    // Pause for Mayne Transmuting
    bool public pausedMayneTransmute;

    // Pause for burning
    bool public pausedBurn;

    // Items (item ID => {item minted, item total supply, item price, item pause})
    mapping(uint256 => ItemInfo) public items;

    // Pack for a batch transaction (pack ID => {item IDs, item amounts, pack price, pack pause})
    mapping(uint256 => PackInfo) public packs;

    // ERC-20 tokens for payment (token ID => {token contract, price oracle, token pause})
    mapping(uint256 => ERC20TokenInfo) public ERC20Tokens;

    // Chainlink Data Feed of blockchain's native currency
    AggregatorV3Interface internal _priceOracle;

    // Minted item(s)
    event Minted(
        address player,
        uint256 id,
        uint256 amount,
        bool isTransmuting
    );

    // Batch minted items
    event MintedBatch(address player, uint256[] id, uint256[] amount);

    // Batch minted pack(s)
    event MintedPack(address player, uint256 packId, uint256 amount);

    // Transmuted item(s)
    event Transmuted(address player, uint256 id, uint256 amount, uint256 slot);

    // Burnt item(s)
    event Burnt(address player, uint256 id, uint256 amount);

    // Burnt items in a batch transaction
    event BurntBatch(address player, uint256[] id, uint256[] amount);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR ////////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    /**
     * @dev Initializes the native currency's price oracle, transmute-variables, and pause-variables.
     * Adds and initializes the first five item types.
     */
    constructor()
        ERC1155("https://empireofsight.com/metadata/items/{id}.json")
    {
        _priceOracle = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );

        transmuteFee = 0;
        transmuteFeeSum = 0;

        pausedAll = false;
        pausedMayneTransmute = false;
        pausedBurn = false;

        for (uint256 i = 0; i < 5; i++) {
            itemTypes.push(i);
            items[i].minted = 0;
            items[i].totalSupply = 10000;
            if (i < 2)
                items[i].priceUsd = 5990000000000000000; // $5.99 in Wei
            else if (i == 2 || i == 4)
                items[i].priceUsd = 3990000000000000000; // $3.99 in Wei
            else if (i == 3) items[i].priceUsd = 4990000000000000000; // $4.99 in Wei
            items[i].paused = false;
        }
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS /////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    /**
     * @dev Returns with the length of `itemTypes`.
     */
    function getLengthItemTypes() external view returns (uint256) {
        return itemTypes.length;
    }

    /**
     * @dev Returns the latest price of the native currency.
     *
     * Requirements:
     *
     * - `price` must be greater than zero.
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = _priceOracle.latestRoundData();
        require(price > 0, "price not available");

        return uint256(price);
    }

    /**
     * @dev Returns with the latest price of `tokenId` type ERC-20 token.
     *
     * Requirements:
     *
     * - `ERC20Tokens[tokenId].tokenContract` must be initialized.
     * - `price` must be greater than zero.
     */
    function getLatestTokenPrice(
        uint256 tokenId
    ) public view returns (uint256) {
        require(
            ERC20Tokens[tokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );

        AggregatorV3Interface priceOracle = ERC20Tokens[tokenId].priceOracle;
        (, int256 price, , , ) = priceOracle.latestRoundData();
        require(price > 0, "price not available");

        return uint256(price);
    }

    /**
     * @dev Returns with the price of the `id` type and `amount` items multiplied
     * native currency price that reflects the latest USD price.
     *
     * Requirements:
     *
     * - `id` must be less than the length of `itemTypes`.
     * - `amount` must be greater than zero.
     */
    function getItemsNativePrice(
        uint256 id,
        uint256 amount
    ) public view returns (uint256) {
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");

        return
            items[id].priceUsd.div(getLatestPrice()).mul(10 ** 8).mul(amount);
    }

    /**
     * @dev Returns with the price of `packId` type and `amount` packs multiplied
     * native currency price that reflects the latest USD price.
     *
     * Requirements:
     *
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `amount` must be greater than zero.
     */
    function getPacksNativePrice(
        uint256 packId,
        uint256 amount
    ) public view returns (uint256) {
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");
        require(amount > 0, "amount can't be zero");

        return
            packs[packId].priceUsd.div(getLatestPrice()).mul(10 ** 8).mul(
                amount
            );
    }

    /**
     * @dev Returns with the price of the `id` type and `amount` items multiplied
     * `tokenId` type ERC-20 token's currency price that reflects the latest USD price.
     *
     * Requirements:
     *
     * - `id` must be less than the length of `itemTypes`.
     * - `amount` must be greater than zero.
     * - `ERC20Tokens[tokenId].tokenContract` must be initialized.
     */
    function getItemsTokenPrice(
        uint256 id,
        uint256 amount,
        uint256 tokenId
    ) public view returns (uint256) {
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            ERC20Tokens[tokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );

        return
            items[id]
                .priceUsd
                .div(uint256(getLatestTokenPrice(tokenId)))
                .mul(10 ** 8)
                .mul(amount);
    }

    /**
     * @dev Returns with the price of `packId` type and `amount` packs multiplied
     * `tokenId` type ERC-20 token's currency price that reflects the latest USD price.
     *
     * Requirements:
     *
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `amount` must be greater than zero.
     * - `ERC20Tokens[tokenId].tokenContract` must be initialized.
     */
    function getPacksTokenPrice(
        uint256 packId,
        uint256 amount,
        uint256 tokenId
    ) public view returns (uint256) {
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            ERC20Tokens[tokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );

        return
            packs[packId]
                .priceUsd
                .div(uint256(getLatestTokenPrice(tokenId)))
                .mul(10 ** 8)
                .mul(amount);
    }

    //-------------------------------------------------------------------------
    // SET FUNCTIONS //////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    /**
     * @dev Sets the `newuri` string as the new URI of all items.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Disables or enables minting of a specific `id` type item.
     *
     * Requirements:
     *
     * - `id` must be less than the length of `itemTypes`.
     * - `msg.sender` must be the owner.
     */
    function setPause(uint256 id, bool paused_) external onlyOwner {
        require(id < itemTypes.length, "item doesn't exist");

        items[id].paused = paused_;
    }

    /**
     * @dev Disables or enables minting of a specific `packId` type pack.
     *
     * Requirements:
     *
     * - `packs[packId].itemIds.length` must be greater than 0.
     * - `msg.sender` must be the owner.
     */
    function setPausePack(uint256 packId, bool paused_) external onlyOwner {
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");

        packs[packId].paused = paused_;
    }

    /**
     * @dev Disables or enables a specific `tokenId` type ERC-20 token as payment method of minting.
     *
     * Requirements:
     *
     * - `ERC20Tokens[tokenId].tokenContract` must be initialized.
     * - `msg.sender` must be the owner.
     */
    function setPauseERC20(uint256 tokenId, bool paused_) external onlyOwner {
        require(
            ERC20Tokens[tokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );

        ERC20Tokens[tokenId].paused = paused_;
    }

    /**
     * @dev Disables or enables Mayne Transmuting.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function setPauseMayneTransmute() external onlyOwner {
        pausedMayneTransmute = !pausedMayneTransmute;
    }

    /**
     * @dev Disables or enables burning.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function setPauseBurn() external onlyOwner {
        pausedBurn = !pausedBurn;
    }

    /**
     * @dev Disables or enables minting for all items and packs.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function setPauseAll() external onlyOwner {
        pausedAll = !pausedAll;
    }

    /**
     * @dev Sets `priceUsd` as the price of the `id` type item.
     *
     * @notice `priceUsd` must be in Wei!
     *
     * Requirements:
     *
     * - `id` must be less than `itemTypes.length`.
     * - `msg.sender` must be the owner.
     */
    function setItemPriceUsd(uint256 id, uint256 priceUsd) external onlyOwner {
        require(id < itemTypes.length, "item doesn't exist");

        items[id].priceUsd = priceUsd;
    }

    /**
     * @dev Sets `priceUsd` as the price of the `packId` type pack.
     *
     * @notice `priceUsd` must be in Wei!
     *
     * Requirements:
     *
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `msg.sender` must be the owner.
     */
    function setPackPriceUsd(
        uint256 packId,
        uint256 priceUsd
    ) external onlyOwner {
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");

        packs[packId].priceUsd = priceUsd;
    }

    /**
     * @dev Sets a `packId` type pack that has `priceUsd` price and
     * contains `ids` types of items in `amounts` amounts.
     *
     * @notice `priceUsd` must be in Wei!
     *
     * Requirements:
     *
     * - `ids` length must be less than the length of `itemTypes`.
     * - `ids` length must be equal to the length of `amounts`.
     * - `msg.sender` must be the owner.
     */
    function setPack(
        uint256 packId,
        uint256 priceUsd,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            ids.length <= itemTypes.length,
            "ids contains an item that doesn't exist"
        );
        require(
            ids.length == amounts.length,
            "ids and amounts must have same length"
        );

        packs[packId].priceUsd = priceUsd;
        packs[packId].itemIds = ids;
        packs[packId].itemAmounts = amounts;
        packs[packId].paused = false;
    }

    /**
     * @dev Sets `fee` as the fee of Mayne Transmuting.
     *
     * @notice `fee` must be in Wei!
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function setTransmuteFee(uint256 fee) external onlyOwner {
        transmuteFee = fee;
    }

    /**
     * @dev Sets `totalSupply_` as the total supply of the `id` type item.
     *
     * Requirements:
     *
     * - `id` must be less than `itemTypes.length`.
     * - `msg.sender` must be the owner.
     */
    function setItemsTotalSupply(
        uint256 id,
        uint256 totalSupply_
    ) external onlyOwner {
        require(id < itemTypes.length, "item doesn't exist");

        items[id].totalSupply = totalSupply_;
    }

    /**
     * @dev Sets a `tokenId` type ERC-20 token with its `erc20TokenAddress` address and
     * `priceOracleAddress` price oracle address.
     *
     * Requirements:
     *
     * - `erc20TokenAddress` cannot be null address.
     * - `priceOracleAddress` cannot be null address.
     * - `msg.sender` must be the owner.
     */
    function setERC20Token(
        uint256 tokenId,
        address ERC20TokenAddress,
        address priceOracleAddress
    ) external onlyOwner {
        require(
            ERC20TokenAddress != address(0),
            "token address can't be null address"
        );
        require(
            priceOracleAddress != address(0),
            "price oracle address can't be null address"
        );

        IERC20 tokenContract = IERC20(ERC20TokenAddress);
        AggregatorV3Interface priceOracle = AggregatorV3Interface(
            priceOracleAddress
        );
        ERC20Tokens[tokenId] = ERC20TokenInfo(
            tokenContract,
            priceOracle,
            false
        );
    }

    /**
     * @dev Sets `priceOracleAddress` as the address of the native currency's USD price oracle.
     *
     * Requirements:
     *
     * - `priceOracleAddress` cannot be a null address.
     * - `msg.sender` must be the owner.
     */
    function setNativePriceOracle(
        address priceOracleAddress
    ) external onlyOwner {
        require(
            priceOracleAddress != address(0),
            "price oracle address can't be null address"
        );

        _priceOracle = AggregatorV3Interface(priceOracleAddress);
    }

    /**
     * @dev Sets `priceOracleAddress` as the address of `tokenId` type ERC-20 token's USD price oracle.
     *
     * Requirements:
     *
     * - ` ERC20Tokens[tokenId].tokenContract` must be initialized.
     * - `priceOracleAddress` cannot be a null address.
     * - `msg.sender` must be the owner.
     */
    function setERC20PriceOracle(
        uint256 tokenId,
        address priceOracleAddress
    ) external onlyOwner {
        require(
            ERC20Tokens[tokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );
        require(
            priceOracleAddress != address(0),
            "price oracle address can't be null address"
        );

        ERC20Tokens[tokenId].priceOracle = AggregatorV3Interface(
            priceOracleAddress
        );
    }

    //-------------------------------------------------------------------------
    // PLAYER FUNCTIONS ///////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    /**
     * @dev Mints `amount` ERC-1155 tokens of token type `id`.
     *
     * Emits a {Minted} event.
     *
     * Requirements:
     *
     * - `pausedAll` must be false.
     * - `items[id].paused` must be false.
     * - `id` must be less than the length of `itemTypes`
     * - `amount` must be greater than zero.
     * - `msg.value` must be at least the same as the price of the token.
     * - sum of `items[id].minted` and `amount` must be less than or equal to `items[id].totalSupply`.
     * - `msg.sender` cannot be the null address.
     */
    function mint(uint256 id, uint256 amount) external payable nonReentrant {
        require(pausedAll == false, "minting is paused for all items");
        require(items[id].paused == false, "minting is paused for this item");
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            msg.value >= getItemsNativePrice(id, amount),
            "sent value not enough"
        );
        require(
            items[id].minted + amount <= items[id].totalSupply,
            "amount exceeds total supply"
        );
        require(msg.sender != address(0), "sender can't be null address");

        _mint(msg.sender, id, amount, "");
        items[id].minted += amount;

        emit Minted(msg.sender, id, amount, false);
    }

    /**
     * @dev Mints `amount` ERC-1155 tokens of token type `id`.
     * Transfers `value` ERC-20 tokens of token type `ERC20TokenId` from `msg.sender` to `address(this)`.
     *
     * Emits a {Minted} event.
     *
     * Requirements:
     *
     * - `pausedAll` must be false.
     * - `items[id].paused` must be false.
     * - `ERC20Tokens[id].paused` must be false.
     * - `id` must be less than the length of `itemTypes`
     * - `amount` must be greater than zero.
     * - sum of `items[id].minted` and `amount` must be less than or equal to `items[id].totalSupply`.
     * - `ERC20Tokens[ERC20TokenId].tokenContract` must be initialized.
     * - `value` must be at least the same as the price of the token.
     * - `msg.sender` cannot be the null address.
     */
    function mintWithERC20(
        uint256 id,
        uint256 amount,
        uint256 ERC20TokenId,
        uint256 value
    ) external nonReentrant {
        require(pausedAll == false, "minting is paused for all items");
        require(items[id].paused == false, "minting is paused for this item");
        require(
            ERC20Tokens[id].paused == false,
            "paying is paused for this ERC-20 token"
        );
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            items[id].minted + amount <= items[id].totalSupply,
            "amount exceeds total supply"
        );
        require(
            ERC20Tokens[ERC20TokenId].tokenContract != IERC20(address(0)),
            "token not set"
        );
        require(
            value >= getItemsTokenPrice(id, amount, ERC20TokenId),
            "sent value not enough"
        );
        require(msg.sender != address(0), "sender can't be null address");

        IERC20 tokenContract = ERC20Tokens[ERC20TokenId].tokenContract;
        tokenContract.transferFrom(msg.sender, address(this), value);

        _mint(msg.sender, id, amount, "");
        items[id].minted += amount;

        emit Minted(msg.sender, id, amount, false);
    }

    /**
     * @dev Mints `amount` pack(s) of pack type `packId`.
     *
     * Emits a {MintedPack} event.
     *
     * Requirements:
     *
     * - `pausedAll` must be false.
     * - `packs[packId].paused` must be false.
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `amount` must be greater than zero.
     * - `msg.value` must be at least the same as the price of the token.
     * - `id` must be less than the length of `itemTypes`
     * - for all the elements of `packs[packId].itemIds` the sum of
     * `items[packs[packId].itemIds[i]].minted` and packs[packId].itemAmounts[i]
     * multiplied by `amount` must be less than or equal to `items[packs[packId].itemIds[i]].totalSupply`.
     * - `msg.sender` cannot be the null address.
     */
    function mintPack(
        uint256 packId,
        uint256 amount
    ) external payable nonReentrant {
        require(
            pausedAll == false,
            "minting is paused for all items and packs"
        );
        require(
            packs[packId].paused == false,
            "minting is paused for this pack"
        );
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            msg.value >= getPacksNativePrice(packId, amount),
            "sent value not enough"
        );
        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            require(
                items[packs[packId].itemIds[i]].minted +
                    packs[packId].itemAmounts[i].mul(amount) <=
                    items[packs[packId].itemIds[i]].totalSupply,
                "amount exceeds total supply"
            );
        require(msg.sender != address(0), "sender can't be null address");

        for (uint256 i = 0; i < amount; ++i)
            _mintBatch(
                msg.sender,
                packs[packId].itemIds,
                packs[packId].itemAmounts,
                ""
            );

        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            items[packs[packId].itemIds[i]].minted += packs[packId]
                .itemAmounts[i]
                .mul(amount);

        emit MintedPack(msg.sender, packId, amount);
    }

    /**
     * @dev Mints `amount` pack(s) of pack type `packId`.
     * Transfers `value` ERC-20 tokens of token type `ERC20TokenId` from `msg.sender` to `address(this)`.
     *
     * Emits a {MintedPack} event.
     *
     * Requirements:
     *
     * - `pausedAll` must be false.
     * - `packs[packId].paused` must be false.
     * - `ERC20Tokens[id].paused` must be false.
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `amount` must be greater than zero.
     * - `value` must be at least the same as the price of the token.
     * - `id` must be less than the length of `itemTypes`
     * - for all the elements of `packs[packId].itemIds` the sum of
     * `items[packs[packId].itemIds[i]].minted` and packs[packId].itemAmounts[i]
     * multiplied by `amount` must be less than or equal to `items[packs[packId].itemIds[i]].totalSupply`.
     * - `msg.sender` cannot be the null address.
     */
    function mintPackWithERC20(
        uint256 packId,
        uint256 amount,
        uint256 ERC20TokenId,
        uint256 value
    ) external payable nonReentrant {
        require(
            pausedAll == false,
            "minting is paused for all items and packs"
        );
        require(
            packs[packId].paused == false,
            "minting is paused for this pack"
        );
        require(
            ERC20Tokens[ERC20TokenId].paused == false,
            "paying is paused for this ERC-20 token"
        );
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");
        require(amount > 0, "amount must be at least 1");
        require(
            value >= getPacksTokenPrice(packId, amount, ERC20TokenId),
            "sent value is not enough"
        );
        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            require(
                items[packs[packId].itemIds[i]].minted +
                    packs[packId].itemAmounts[i].mul(amount) <=
                    items[packs[packId].itemIds[i]].totalSupply,
                "amount exceeds total supply"
            );
        require(msg.sender != address(0), "sender can't be null address");

        IERC20 tokenContract = ERC20Tokens[ERC20TokenId].tokenContract;
        tokenContract.transferFrom(msg.sender, address(this), value);

        for (uint256 i = 0; i < amount; ++i)
            _mintBatch(
                msg.sender,
                packs[packId].itemIds,
                packs[packId].itemAmounts,
                ""
            );

        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            items[packs[packId].itemIds[i]].minted += packs[packId]
                .itemAmounts[i]
                .mul(amount);

        emit MintedPack(msg.sender, packId, amount);
    }

    /**
     * @dev Receives `amount` multiplied by the `transmuteFee` value of the native currency and emits an event.
     *
     * @notice `slot` parameter has an off-chain-related purpose.
     *
     * Emits a {Transmuted} event.
     *
     * Requirements:
     *
     * - `pausedMayneTransmute` must be false.
     * - `id` must be less than the length of `itemTypes`
     * - `amount` must be greater than zero.
     * - `msg.value` must be greater than or equal to `transmuteFee` multiplied by `amount`.
     * - sum of `items[id].minted` and `amount` must be less than or equal to `items[id].totalSupply`.
     * - `msg.sender` cannot be the null address.
     */
    function mayneTransmute(
        uint256 id,
        uint256 amount,
        uint256 slot
    ) external payable nonReentrant {
        require(pausedMayneTransmute == false, "Mayne Transmuting paused");
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(msg.value >= transmuteFee.mul(amount), "sent value not enough");
        require(msg.sender != address(0), "sender can't be null address");
        require(
            items[id].minted + amount <= items[id].totalSupply,
            "amount exceeds total supply"
        );

        transmuteFeeSum += transmuteFee.mul(amount);

        emit Transmuted(msg.sender, id, amount, slot);
    }

    /**
     * @dev Burns `amount` ERC-1155 tokens of token type `id`.
     *
     * Emits a {Burnt} event.
     *
     * Requirements:
     *
     * - `pausedBurn` must be false.
     * - `id` must be less than the length of `itemTypes`
     * - `balanceOf(msg.sender, id)` must be greater than or equal to `amount`.
     * - `amount` must be greater than zero.
     */
    function burn(uint256 id, uint256 amount) external nonReentrant {
        require(pausedBurn == false, "burning paused");
        require(id < itemTypes.length, "item doesn't exist");
        require(
            balanceOf(msg.sender, id) >= amount,
            "not enough items to burn"
        );
        require(amount > 0, "amount can't be zero");

        _burn(msg.sender, id, amount);
        items[id].minted -= amount;

        emit Burnt(msg.sender, id, amount);
    }

    /**
     * @dev Burns array of `amounts` ERC-1155 tokens of multiple token types array of `ids`.
     *
     * Emits a {BurntBatch} event.
     *
     * Requirements:
     *
     * - `pausedBurn` must be false.
     * - `ids` length must be less than or equal to the length of `itemTypes`
     * - `ids` length must be equal to the length of `amounts`
     * - for all the elements of `ids` and `amounts`,
     * `balanceOf(msg.sender, ids[i])` must be greater than or equal to `amounts[i]`.
     * - for all the elements of `amounts`, `amounts[i]` must be greater than zero.
     */
    function burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external nonReentrant {
        require(pausedBurn == false, "burning paused");
        require(
            ids.length <= itemTypes.length,
            "ids contains an item that doesn't exist"
        );
        require(
            ids.length == amounts.length,
            "ids and amounts must have same length"
        );
        for (uint256 i = 0; i < amounts.length; ++i)
            require(
                balanceOf(msg.sender, ids[i]) >= amounts[i],
                "account doesn't have enough items to burn"
            );
        for (uint256 i = 0; i < amounts.length; ++i)
            require(amounts[i] > 0, "amount can't be zero");

        _burnBatch(msg.sender, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i)
            items[ids[i]].minted -= amounts[i];

        emit BurntBatch(msg.sender, ids, amounts);
    }

    //-------------------------------------------------------------------------
    // ADMIN FUNCTIONS ////////////////////////////////////////////////////////
    //-------------------------------------------------------------------------

    /**
     * @dev Creates a new type of item with `totalSupply_` total supply and `priceUsd` USD price in Wei.
     * ID has the value of `itemTypes.length` before pushing the new item type element.
     *
     * @notice `priceUsd` must be in Wei!
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     */
    function addItem(
        uint256 totalSupply_,
        uint256 priceUsd
    ) external onlyOwner {
        uint256 id = itemTypes.length;
        itemTypes.push(id);
        items[id].minted = 0;
        items[id].totalSupply = totalSupply_;
        items[id].priceUsd = priceUsd;
        items[id].paused = false;
    }

    /**
     * @dev Mints `amount` ERC-1155 tokens of token type `id` to `player`.
     * @notice isTransmuting defines if the reason for minting is coming from an ongoing Mayne Transmute process.
     *
     * Emits a {Minted} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     * - `id` must be less than the length of `itemTypes`
     * - `amount` must be greater than zero.
     * - sum of `items[id].minted` and `amount` must be less than or equal to `items[id].totalSupply`.
     * - `player` cannot be the null address.
     */
    function mintAdmin(
        uint256 id,
        uint256 amount,
        address player,
        bool isTransmuting
    ) external onlyOwner {
        require(id < itemTypes.length, "item doesn't exist");
        require(amount > 0, "amount can't be zero");
        require(
            items[id].minted + amount <= items[id].totalSupply,
            "amount exceeds total supply"
        );
        require(player != address(0), "player can't be null address");

        _mint(player, id, amount, "");
        items[id].minted += amount;

        emit Minted(player, id, amount, isTransmuting);
    }

    /**
     * @dev Mints array of `amounts` ERC-1155 tokens of multiple token types array of `ids` to `player`.
     *
     * Emits a {MintedBatch} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     * - `ids` length must be less than or equal to the length of `itemTypes`
     * - `ids` length must be equal to the length of `amounts`
     * - for all the elements of `ids` and `amounts`, the sum of `items[ids[i]].minted` and `amounts[i]`
     * must be less than or equal to `items[ids[i]].totalSupply`.
     * - for all the elements of `amounts`, `amounts[i]` must be greater than zero.
     * - `player` cannot be the null address.
     */
    function mintBatchAdmin(
        uint256[] memory ids,
        uint256[] memory amounts,
        address player
    ) external onlyOwner {
        require(
            ids.length <= itemTypes.length,
            "ids contains an item that doesn't exist"
        );
        require(
            ids.length == amounts.length,
            "ids and amounts must have same length"
        );
        for (uint256 i = 0; i < ids.length; ++i)
            require(
                items[ids[i]].minted + amounts[i] <= items[ids[i]].totalSupply,
                "amount exceeds the total supply"
            );
        for (uint256 i = 0; i < amounts.length; ++i)
            require(amounts[i] > 0, "amount can't be zero");
        require(player != address(0), "player can't be null address");

        _mintBatch(player, ids, amounts, "");
        for (uint256 i = 0; i < ids.length; ++i)
            items[ids[i]].minted += amounts[i];

        emit MintedBatch(player, ids, amounts);
    }

    /**
     * @dev Mints `amount` pack(s) of pack type `packId` to `player`.
     *
     * Emits a {MintedPack} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     * - `packs[packId].itemIds.length` must be greater than zero.
     * - `amount` must be greater than zero.
     * - for all the elements of `packs[packId].itemIds` the sum of
     * `items[packs[packId].itemIds[i]].minted` and packs[packId].itemAmounts[i]
     * multiplied by `amount` must be less than or equal to `items[packs[packId].itemIds[i]].totalSupply`.
     * - `msg.sender` cannot be the null address.
     */
    function mintPackAdmin(
        uint256 packId,
        uint256 amount,
        address player
    ) external onlyOwner {
        require(packs[packId].itemIds.length > 0, "pack doesn't exist");
        require(amount > 0, "amount can't be zero");
        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            require(
                items[packs[packId].itemIds[i]].minted +
                    packs[packId].itemAmounts[i].mul(amount) <=
                    items[packs[packId].itemIds[i]].totalSupply,
                "amount exceeds total supply"
            );
        require(player != address(0), "sender can't be null address");

        for (uint256 i = 0; i < amount; ++i)
            _mintBatch(
                player,
                packs[packId].itemIds,
                packs[packId].itemAmounts,
                ""
            );

        for (uint256 i = 0; i < packs[packId].itemIds.length; ++i)
            items[packs[packId].itemIds[i]].minted += packs[packId]
                .itemAmounts[i]
                .mul(amount);

        emit MintedPack(player, packId, amount);
    }

    /**
     * @dev Withdraws all the balance of the contract to the hard-coded addresses.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     * - `address(this).balance` must be greater than zero
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "balance can't be zero");

        (bool founderOne, ) = payable(
            0xfE38200d6206fcf177c8C2A25300FeeC3E3803F3
        ).call{value: address(this).balance.mul(4).div(10)}("");
        require(founderOne);

        (bool founderTwo, ) = payable(
            0x4ee757CfEBA27580BA587f8AE81f5BA63Bdd021d
        ).call{value: address(this).balance.mul(4).div(10)}("");

        require(founderTwo);
        (bool dev, ) = payable(0x72a2547dcd6D114bA605Ad5C18756FD7aEAc467D).call{
            value: address(this).balance.mul(2).div(10)
        }("");
        require(dev);

        transmuteFeeSum = 0;
    }

    /**
     * @dev Withdraws {_ERC20WithdrawalLimit} ERC-20 token balances of token types `tokenIds`
     * from `address(this)` to the hard-coded addresses.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner.
     * - `tokenIds` length must be less than or equal to `_ERC20WithdrawalLimit`
     * - for all the elements of `tokenIds`, `ERC20Tokens[i].tokenContract` must be initialized
     * and `ERC20Tokens[tokenIds[i]].tokenContract.balanceOf(address(this))` must be greater than zero
     * - `address(this).balance` must be greater than zero
     */
    function withdrawERC20(
        uint256[] memory tokenIds
    ) external onlyOwner nonReentrant {
        require(
            tokenIds.length <= _ERC20WithdrawalLimit,
            "you can't withdraw more than five token types"
        );
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(
                ERC20Tokens[i].tokenContract != IERC20(address(0)),
                "token not set"
            );
            require(
                ERC20Tokens[tokenIds[i]].tokenContract.balanceOf(
                    address(this)
                ) > 0,
                "balance can't be zero"
            );

            ERC20Tokens[i].tokenContract.transferFrom(
                address(this),
                0xfE38200d6206fcf177c8C2A25300FeeC3E3803F3,
                ERC20Tokens[tokenIds[i]]
                    .tokenContract
                    .balanceOf(address(this))
                    .mul(4)
                    .div(10)
            );

            ERC20Tokens[i].tokenContract.transferFrom(
                address(this),
                0x4ee757CfEBA27580BA587f8AE81f5BA63Bdd021d,
                ERC20Tokens[tokenIds[i]]
                    .tokenContract
                    .balanceOf(address(this))
                    .mul(4)
                    .div(10)
            );

            ERC20Tokens[i].tokenContract.transferFrom(
                address(this),
                0x72a2547dcd6D114bA605Ad5C18756FD7aEAc467D,
                ERC20Tokens[tokenIds[i]]
                    .tokenContract
                    .balanceOf(address(this))
                    .mul(2)
                    .div(10)
            );
        }
    }
}