// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT1155 is ERC1155, Ownable {

    constructor() ERC1155("https://gateway.moralisipfs.com/ipfs/QmXrgWF4x4kEioo8NBXuExK8KPYEqZVjysg2VsBmnf37cz"){}
    
    using Strings for uint256;
    
    string public name = "Furniture";
    string public symbol = "FURNI";
    string private baseURI;

    uint256 private _currentTokenId = 0;

    function setURI(string memory _URI) external onlyOwner 
    {
        require(keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked(_URI)), "baseURI is already the value being set.");
        baseURI = _URI;
    }

    // function uri(uint256 tokenId) public view virtual override returns (string memory) {
    //     return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    // }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".png"));
    }
    function mintTo(address to) public {
        uint256 newTokenId = _getNextTokenId();
        _mint(to, newTokenId, 10, "");
        _incrementTokenId();
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    function _incrementTokenId() private {
        _currentTokenId ++;
    }
    

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract TestSwapBox is ReentrancyGuard, Ownable {

    uint256 public _itemCounter;

    struct ERC20Details {
        address tokenAddrs;
        uint96 amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint32 id3;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint32 id1;
        uint16 amount1;
        uint32 id2;
        uint16 amount2;
    }

    struct ERC20Fee {
        address tokenAddress;
        uint96 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint96 feeAmount;
    }

    struct BoxOffer {
        uint32 boxID;
        uint8 active;
    }
    
    // struct GasTest1 {
    //     address to;
    //     uint64 amount;
    // }

    // struct GasTest2 {

    //     address to;
    //     uint256 amount;
    // }

    // struct GasTest3 {
    //     address to;
    //     uint64[] amount;
    // }

    // struct GasTest4 {
    //     address to;
    //     uint256[] amount;
    // }


    // struct GasBoxState1 {
    //     address owner;
    //     uint64 id;
    //     uint8 state;
    //     uint8 whiteListOffer;
    // }

    // struct GasBoxState2 {
    //     address owner;
    //     uint256 id;
    //     uint256 state;
    //     uint256 whiteListOffer;
    // }

    struct SwapBox {
        address owner;
        uint32 id;
        uint32 state;
        uint32 whiteListOffer;
    }

    mapping(uint256 => ERC20Details[1000]) erc20Details;
    mapping(uint256 => ERC721Details[1000]) erc721Details;
    mapping(uint256 => ERC1155Details[1000]) erc1155Details;
    mapping(uint256 => uint256) gasTokenAmount;
    mapping(uint256 => BoxOffer) offers;
    mapping(uint256 => uint256) nftSwapFee;
    mapping(uint256 => ERC20Fee) erc20Fees;
    mapping(uint256 => RoyaltyFee) boxRoyaltyFee;
    mapping(uint256 => uint256) gasTokenFee;
    mapping(uint256 => SwapBox) swapBoxes;

    // GasTest1 private gasTest1;
    // GasTest2 private gasTest2;
    // GasTest3 private gasTest3;
    // GasTest4 private gasTest4;

    // GasBoxState1 private gasBoxState1;
    // GasBoxState2 private gasBoxState2;
    // GasBoxState3 private gasBoxState3;
    

    // function Test1() public {
    //     gasTest1.to = msg.sender;
    //     gasTest1.amount = 100000;
    // }

    // function Test2() public {
    //     gasTest2.to = msg.sender;
    //     gasTest2.amount = 100000;
    // }

    // function Test3() public {
    //     gasBoxState1.owner = msg.sender;
    //     gasBoxState1.id = 1;
    //     gasBoxState1.state = 1;
    //     gasBoxState1.whiteListOffer = 1;
    // }

    // function Test4() public {
    //     gasBoxState2.owner = msg.sender;
    //     gasBoxState2.id = 1;
    //     gasBoxState2.state = 1;
    //     gasBoxState2.whiteListOffer = 1;
    // }

    // function Test5() public {
    //     gasTest3.to = msg.sender;
    //     gasTest3.amount.push(12);
    //     // gasTest3.amount.push(12);
    // }

    // function Test6() public {
    //     gasTest4.to = msg.sender;
    //     gasTest4.amount.push(12);
    //     // gasTest3.amount.push(12);
    // }

    // function Test7() public {
    //     gasBoxState3.owner = msg.sender;
    //     gasBoxState3.id = 1;
    //     gasBoxState3.state = 1;
    //     gasBoxState3.whiteListOffer = 1;
    // }

    function creatBox(
        ERC721Details[] calldata   _erc721Details,
        ERC20Details[] calldata  _erc20Details,
        ERC1155Details[] calldata  _erc1155Details,
        uint256 _gasTokenAmount
    ) public {

        _itemCounter++;
        swapBoxes[_itemCounter].owner = msg.sender;
        swapBoxes[_itemCounter].id = uint32(_itemCounter);
        swapBoxes[_itemCounter].state = 0;
        swapBoxes[_itemCounter].whiteListOffer = 1;
        for(uint256 i ; i < _erc20Details.length; ++i)
            erc20Details[_itemCounter][i] = _erc20Details[i];

        for(uint256 i ; i < _erc721Details.length; ++i)
            erc721Details[_itemCounter][i] = _erc721Details[i];

        for(uint256 i ; i < _erc1155Details.length; ++i)
            erc1155Details[_itemCounter][i] = _erc1155Details[i];
        gasTokenAmount[_itemCounter] = _gasTokenAmount;
    }

    // function deleteBox(
    //     ERC721Details[] calldata   _erc721Details,
    //     ERC20Details[] calldata  _erc20Details,
    //     ERC1155Details[] calldata  _erc1155Details,
    //     uint256 _gasTokenAmount
    // ) public {

    //     _itemCounter++;
    //     swapBoxes[_itemCounter].owner = msg.sender;
    //     swapBoxes[_itemCounter].id = uint32(_itemCounter);
    //     swapBoxes[_itemCounter].state = 0;
    //     swapBoxes[_itemCounter].whiteListOffer = 1;
    //     for(uint256 i ; i < _erc20Details.length; ++i)
    //         erc20Details[_itemCounter].push(_erc20Details[i]);

    //     for(uint256 i ; i < _erc721Details.length; ++i)
    //         erc721Details[_itemCounter].push(_erc721Details[i]);

    //     for(uint256 i ; i < _erc1155Details.length; ++i)
    //         erc1155Details[_itemCounter].push(_erc1155Details[i]);
    //     gasTokenAmount[_itemCounter] = _gasTokenAmount;

    //     delete swapBoxes[_itemCounter];
    //     delete erc20Details[_itemCounter];
    //     delete erc721Details[_itemCounter];
    //     delete erc1155Details[_itemCounter];
    //     delete gasTokenAmount[_itemCounter];
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/INFTSwap.sol";
import "./interface/INFTSwapBoxWhitelist.sol";
import "./interface/INFTSwapBoxFees.sol";
import "./interface/INFTSwapBoxAssets.sol";
import "./interface/INFTSwapBoxHistory.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";
contract NFTSwapBox is
    ReentrancyGuard,
    Ownable,
    INFTSwap,
    ERC1155Holder
{
    mapping(uint256 => SwapBox) public swapBoxes;
    mapping(uint256 => ERC20Details[]) private erc20Details;
    mapping(uint256 => ERC721Details[]) private erc721Details;
    mapping(uint256 => ERC1155Details[]) private erc1155Details;
    mapping(uint256 => uint256) public gasTokenAmount;
    mapping(uint256 => uint256[]) private offers;
    mapping(uint256 => uint256) public nft_gas_SwapFee;
    mapping(uint256 => ERC20Fee[])  private erc20Fees;
    mapping(uint256 => RoyaltyFee[]) private boxRoyaltyFee;

    mapping(uint256 => address[]) public addrWhitelistedToOffer;


    uint256 private _boxesCounter;
    uint256 private _historyCounter;
    /**
        Fees List
        0: Creating a box
        1: Listing a box
        2: Offering a box
        3: Delisting a box
    */

    uint256[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether];

    bool openSwap = true;

    address public NFTSwapBoxWhitelist;
    address public NFTSwapBoxFees;
    address public NFTSwapBoxHistory;
    address public withdrawOwner;

    constructor(
        address whiteList,
        address boxFee,
        address withdraw
    ) {
        NFTSwapBoxWhitelist = whiteList;
        NFTSwapBoxFees = boxFee;
        withdrawOwner =  withdraw;
    }

    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }

    /**
        Controlling WhiteListContract, SwapboxFees, History Address
     */
    function setNFTWhiteListAddress(address nftSwapboxWhiteListAddress) public onlyOwner {
        NFTSwapBoxWhitelist = nftSwapboxWhiteListAddress;
    }

    function setNFTSwapBoxFeesAddress(address nftFeesAddress) public onlyOwner {
        NFTSwapBoxFees = nftFeesAddress;
    }

    function setNFTSwapBoxHistoryAddress(address historyAddress) public onlyOwner {
        NFTSwapBoxHistory = historyAddress;
    }
    

    /**
    SwapBox Contract State
    _new : true(possilbe swapbox)
    _new : false(impossilbe swapbox)
     */
    function setSwapState(bool _new) public onlyOwner {
        openSwap = _new;
    }

    function setWithDrawOwner(address withDrawOwner) public onlyOwner {
        withdrawOwner = withDrawOwner;
    }
    function setSwapFee(uint256 _index, uint64 _value) public onlyOwner {
        swapConstantFees[_index] = _value;
    }
    function getSwapPrices() public view returns (uint256[] memory) {
        return swapConstantFees;
    }

    /**
        All Box IDs that are waiting for offers
    */
    function getWaitingBoxes() public view returns(uint256) {
        
        uint256 waitingBoxCounter;
        for(uint256 i ; i < _boxesCounter ; ++i) {
            if(swapBoxes[i].state == uint32(1))
            {
                ++waitingBoxCounter;
            }
        }
        // uint256[]  memory boxID = new uint256[](waitingBoxCounter);
        // uint256 index;

        // for(uint256 i ; i < _boxesCounter ; ++i) {
        //     if(swapBoxes[i].state == 1) {
        //         ++index;

        //         boxID[index] = i;
        //     }
        // }
        return waitingBoxCounter;
    }

    /**
        Get Assets 
    */

    function getERC20Data(uint256 _boxID) public view returns(ERC20Details[] memory) {
        return erc20Details[_boxID];
    }

    function getERC721Data(uint256 _boxID) public view returns(ERC721Details[] memory) {
        return erc721Details[_boxID];
    }

    function getERC1155Data(uint256 _boxID) public view returns(ERC1155Details[] memory) {
        return erc1155Details[_boxID];
    }

    function getERC20Fee(uint256 _boxID) public view returns(ERC20Fee[] memory) {
        return erc20Fees[_boxID];
    }

    function getRoyaltyFee(uint256 _boxID) public view returns(RoyaltyFee[] memory) {
        return boxRoyaltyFee[_boxID];
    }

    function getOffers(uint256 _boxID) public view returns(uint256[] memory) {
        return offers[_boxID];
    }

    function getBoxAssets(uint256 _boxID) public view returns(ERC721Details[] memory, ERC20Details[] memory, ERC1155Details[] memory, SwapBox memory, uint256) {
        return(erc721Details[_boxID], erc20Details[_boxID], erc1155Details[_boxID], swapBoxes[_boxID], gasTokenAmount[_boxID]);
    }
    /**
        Transferring ERC20Fee
        for creating box, prepaidFees, refund assets to users
     */
    function _transferERC20Fee(
        ERC20Fee[] memory erc20fee,
        address from, 
        address to, 
        bool transferFrom
    ) internal {
        for(uint256 i = 0 ; i < erc20fee.length ; i ++) {
            if(transferFrom == true) {
                require(
                        IERC20(erc20fee[i].tokenAddr).allowance(
                            from,
                            to
                            ) >= erc20fee[i].feeAmount,
                        "not approved to swap contract"
                        );

                    IERC20(erc20fee[i].tokenAddr).transferFrom(
                        from,
                        to,
                        erc20fee[i].feeAmount
                    );
            } else {
                    IERC20(erc20fee[i].tokenAddr).transfer(
                        to,
                        erc20fee[i].feeAmount
                    );
            }
        }
    }
    /**
        Transferring Box Assets including erc721, erc20, erc1155
        for creating box, destroy box
     */
    function _transferAssetsHelper(
        ERC721Details[] memory erc721Detail,
        ERC20Details[]  memory erc20Detail,
        ERC1155Details[] memory erc1155Detail,
        address from,
        address to,
        bool transferFrom
    ) internal {
        for (uint256 i = 0; i < erc721Detail.length; i++) {

            if(erc721Detail[i].id1 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id1
            );

            if(erc721Detail[i].id2 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id2
            );

            if(erc721Detail[i].id3 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id3
            );
        }
        if(transferFrom == true) {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc20Detail[i].amounts
                );
            }
        } else {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transfer(to, erc20Detail[i].amounts);
            }
        }

        for (uint256 i = 0; i < erc1155Detail.length; i++) {
            if(erc1155Detail[i].amount1 == 0) continue;
            if(erc1155Detail[i].amount2 == 0) {
                uint256 [] memory ids = new uint256[](1);
                ids[0] = erc1155Detail[i].id1;
                uint256 [] memory amounts = new uint256[](1);
                amounts[0] = erc1155Detail[i].amount1; 
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            } else {
                uint256 [] memory ids = new uint256[](2);
                ids[0] = erc1155Detail[i].id1;
                ids[1] = erc1155Detail[i].id2;
                uint256 [] memory amounts = new uint256[](2);
                amounts[0] = erc1155Detail[i].amount1;
                amounts[1] = erc1155Detail[i].amount2;
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            }
        }
    }
    /**
    Check OfferState
    if return is true : it is offered
    if return is false : it is not offered
    */
    function _checkOfferState(
        uint256 listBoxID,
        uint256 offerBoxID
    ) internal view returns (bool) {
        for (uint256 i = 0; i < offers[listBoxID].length; i++) {
            if(offers[listBoxID][i] == offerBoxID)
                return true;
        }

        return false;
    }

    function _transferSwapFees(
        uint256 boxID,
        address to,
        bool swapped
    ) internal {
        payable(to).transfer(nft_gas_SwapFee[boxID]);
        _transferERC20Fee(erc20Fees[boxID], address(this), to, false);

        uint256 royaltyFeeLength = boxRoyaltyFee[boxID].length;
        if(!swapped) {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(to).transfer(boxRoyaltyFee[boxID][i].feeAmount);
            }
        } else {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(boxRoyaltyFee[boxID][i].reciever).transfer(boxRoyaltyFee[boxID][i].feeAmount);
            }
        }
        }

    function _checkingBoxAssetsCounter(
        ERC721Details[] memory _erc721Details,
        ERC20Details[] memory _erc20Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenAmount
    ) internal pure returns (uint256) {
        uint256 assetCounter;

        for(uint256 i ; i < _erc721Details.length ; ++i){
            if(_erc721Details[i].id1 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id2 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id3 == 4294967295) continue;
                ++assetCounter;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i){
            if(_erc1155Details[i].amount1 == 0) continue;
                assetCounter += _erc1155Details[i].amount1;
            if(_erc1155Details[i].amount2 == 0) continue;
                assetCounter += _erc1155Details[i].amount2;
        }

        if(_erc20Details.length > 0)
            ++assetCounter;

        if(_gasTokenAmount > 0)
            ++assetCounter;

        return assetCounter;
    }

     //check availabe offerAddress for listing box
    function _checkAvailableOffer(uint256 boxID, address offerAddress) internal view returns(bool) {
        for(uint256 i = 0; i < addrWhitelistedToOffer[boxID].length; i++) {
            if(addrWhitelistedToOffer[boxID][i] == offerAddress)
                return true;
        }
        return false;
    }

    //Delect SwapBoxAssets

    function _deleteAssets(uint256 boxID) internal {
        delete swapBoxes[boxID];
        delete erc20Details[boxID];
        delete erc721Details[boxID];
        delete erc1155Details[boxID];
        delete gasTokenAmount[boxID];
        delete erc20Fees[boxID];
        delete boxRoyaltyFee[boxID];
        delete nft_gas_SwapFee[boxID];
        delete offers[boxID];
        delete addrWhitelistedToOffer[boxID];
    }

    function createBox(
        ERC721Details[] calldata _erc721Details,
        ERC20Details[] calldata _erc20Details,
        ERC1155Details[] calldata _erc1155Details,
        uint256 _gasTokenAmount,
        address[] memory offerAddress,
        uint256 state
    ) public payable isOpenForSwap nonReentrant {

        require(_erc721Details.length + _erc20Details.length + _erc1155Details.length + _gasTokenAmount > 0,"No Assets");
        require(state == 1 || state == 2, "Invalid state");

        uint256 createFees = _checkingBoxAssetsCounter(_erc721Details, _erc20Details, _erc1155Details, _gasTokenAmount) * swapConstantFees[0];

        uint256 swapFees = INFTSwapBoxFees(NFTSwapBoxFees)._checknftgasfee(
            _erc721Details,
            _erc1155Details,
            _gasTokenAmount,
            msg.sender
        );

        RoyaltyFee[] memory royaltyFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkRoyaltyFee(
            _erc721Details,
            _erc1155Details,
            msg.sender
        );

        ERC20Fee[] memory erc20swapFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkerc20Fees(
            _erc20Details,
            msg.sender
        );
        
        uint256 boxroyaltyFees; 
          for (uint256 i = 0; i < royaltyFees.length; i++){
            boxroyaltyFees += royaltyFees[i].feeAmount;
        }

        if(state == 1){
            require(
                msg.value == createFees + _gasTokenAmount + swapConstantFees[1] + swapFees + boxroyaltyFees, "Insufficient Creating Fee"
            );
        } else {
            require(
                msg.value == createFees + _gasTokenAmount + swapConstantFees[2] + swapFees + boxroyaltyFees, "Insufficient Offering Fee"
            );
        }

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._checkAssets(
            _erc721Details,  
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this)
        );

        _transferAssetsHelper(
            _erc721Details,
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this),
            true
        );

        payable(withdrawOwner).transfer(createFees);

        _boxesCounter++;


        SwapBox storage box = swapBoxes[_boxesCounter];
        box.id = uint32(_boxesCounter);
        box.owner = msg.sender;
        box.state = uint32(state);

        for(uint256 i ; i < _erc20Details.length; ++i) 
            erc20Details[_boxesCounter].push(_erc20Details[i]);

        for(uint256 i ; i < _erc721Details.length; ++i)
            erc721Details[_boxesCounter].push(_erc721Details[i]);

        for(uint256 i ; i < _erc1155Details.length; ++i)
            erc1155Details[_boxesCounter].push(_erc1155Details[i]);

        gasTokenAmount[_boxesCounter] = _gasTokenAmount;

        nft_gas_SwapFee[_boxesCounter] = swapFees;
        for(uint256 i ; i < erc20swapFees.length ; ++i)
            erc20Fees[_boxesCounter].push(erc20swapFees[i]);
        for(uint256 i ; i < royaltyFees.length ; ++i)
            boxRoyaltyFee[_boxesCounter].push(royaltyFees[i]);

        if(state == 1)
            payable(withdrawOwner).transfer(swapConstantFees[1]);

        if(offerAddress.length > 0) {
            for(uint256 i ; i < offerAddress.length ; ++i){
                addrWhitelistedToOffer[_boxesCounter][i] = offerAddress[i];
            }
            box.whiteListOffer = 1;
        }

        emit SwapBoxCreated(
            uint32(_boxesCounter),
            uint8(state)
        );
    }

    // Destroy Box. all assets back to owner's wallet
    function withdrawBox(uint256 boxID)
        payable
        public
        isOpenForSwap
        nonReentrant
    {

        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );

        if(swapBoxes[boxID].state == 1) {

            require(msg.value == offers[boxID].length * swapConstantFees[3], "Insufficient Fee for Delisting");

            INFTSwapBoxAssets(address(this))._deleteOfferAddress(boxID);
        }

        _transferAssetsHelper(
            erc721Details[boxID],
            erc20Details[boxID],
            erc1155Details[boxID],
            address(this),
            msg.sender,
            false
        );

        if (gasTokenAmount[boxID] > 0) {
            payable(msg.sender).transfer(gasTokenAmount[boxID]);
        }

        _transferSwapFees(
            boxID,
            msg.sender,
            false
        );
        
        _deleteAssets(boxID);

        emit SwapBoxWithDraw(
            boxID
        );
    }
    /**
        Changine BoxState
        when box sate is 1(waiting_for_offeres), state will  change as state 2(offered)
     */
    function changeBoxState (uint256 boxID) public payable isOpenForSwap nonReentrant {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        
        if(swapBoxes[boxID].state == 1){
            require(swapBoxes[boxID].state != 2,"Not Allowed");
            require(msg.value ==  offers[boxID].length * swapConstantFees[3], "Insufficient Fee for Delisting");

            delete offers[boxID];
            delete addrWhitelistedToOffer[boxID];

            swapBoxes[boxID].state = 2;
        }
        else {
            require(msg.value == swapConstantFees[1], "Insufficient Fee for listing");
            swapBoxes[boxID].state = 1;
        }

        emit SwapBoxStateChanged(
            uint32(boxID),
            uint8(swapBoxes[boxID].state)
        );
    }

    // Link your Box to other's waiting Box. Equal to offer to other Swap Box
    function offerBox(uint256 listBoxID, uint256 offerBoxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].state == 2,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            _checkOfferState(listBoxID, offerBoxID) == false,
            "already linked"
        );
        require(
            swapBoxes[listBoxID].state == 1,
            "not Waiting_for_offer State"
        );
        require(msg.value == swapConstantFees[2], "Insufficient Fee for making an offer");

        if(swapBoxes[listBoxID].whiteListOffer == 1)
            require(_checkAvailableOffer(listBoxID, msg.sender) == true, "Not listed Offer Address");

        payable(withdrawOwner).transfer(swapConstantFees[2]);

        offers[listBoxID].push(offerBoxID);

        emit SwapBoxOffer(uint32(listBoxID), uint32(offerBoxID));
    }



    // Swaping Box. Owners of Each Swapbox should be exchanged
    function swapBox(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
    {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == 1,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].state == 2,
            "Not offered"
        );
        require(
            _checkOfferState(listBoxID, offerBoxID),
            "not exist or active"
        );

        swapBoxes[listBoxID].owner = swapBoxes[offerBoxID].owner;
        swapBoxes[listBoxID].state = 1;

        swapBoxes[offerBoxID].owner = msg.sender;
        swapBoxes[offerBoxID].state = 1;

        _transferSwapFees(
            listBoxID,
            withdrawOwner,
            true);
        _transferSwapFees(
            offerBoxID,
            withdrawOwner,
            true);
        // INFTSwapBoxHistory(NFTSwapBoxHistory).addHistoryUserSwapFees(
        //     _historyCounter,
        //     swapBoxes[listBoxID],
        //     swapBoxes[offerBoxID]);
        

        emit Swaped(
            _historyCounter,
            listBoxID,
            swapBoxes[listBoxID].owner,
            offerBoxID,
            swapBoxes[offerBoxID].owner
        );
        
        
        _deleteAssets(listBoxID);
        _deleteAssets(offerBoxID);

        // _historyCounter++;
    }
    // WithDraw offer from linked offer
    function withDrawOffer(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );

        uint256 offerLength =  offers[listBoxID].length;
        for(uint256 i ; i < offerLength ; ++i) {
            if(offers[listBoxID][i] == offerBoxID)
                delete offers[listBoxID][i];
        }

        emit SwapBoxWithDrawOffer(uint32(listBoxID), uint32(offerBoxID));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwap {

    event SwapBoxCreated(
        uint32 boxID,
        uint8 state
    );

    event SwapBoxStateChanged(
        uint32 boxID,
        uint8 state
    );

    event SwapBoxWithDraw(
        uint256 boxID
    );

    event SwapBoxOffer(
        uint32 listBoxID,
        uint32 OfferBoxID
    );

    event Swaped (
        uint256 historyID,
        uint256 listID,
        address listBoxOwner,
        uint256 offerID,
        address offerBoxOwner
    );

    event SwapBoxWithDrawOffer(
        uint32 listSwapBoxID,
        uint32 offerSwapBoxID
    );

    struct ERC20Details {
        address tokenAddr;
        uint96 amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint32 id3;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint16 amount1;
        uint16 amount2;
    }

    struct ERC20Fee {
        address tokenAddr;
        uint96 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint96 feeAmount;
    }


    struct SwapBox {
        address owner;
        uint32 id;
        uint32 state;
        uint32 whiteListOffer;
    }
    
    struct SwapBoxConfig {
        uint8 usingERC721WhiteList;
        uint8 usingERC1155WhiteList;
        uint8 NFTTokenCount;
        uint8 ERC20TokenCount;
    }

    struct UserTotalSwapFees {
        address owner;
        uint256 nftFees;
        ERC20Fee[] totalERC20Fees;
    }

    struct SwapHistory {
        uint256 id;
        uint256 listId;
        address listOwner;
        uint256 offerId;
        address offerOwner;
        uint256 swapedTime;
    }

    struct Discount {
        address user;
        address nft;
    }

    struct PrePaidFee {
        uint256 nft_gas_SwapFee;
        ERC20Fee[] erc20Fees;
        RoyaltyFee[] royaltyFees;
    }

    enum State {    
        Waiting_for_offers,
        Offered
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxWhitelist is INFTSwap {

    function _checkAssets(
        ERC721Details[] calldata,
        ERC20Details[] calldata,
        ERC1155Details[] calldata,
        address,
        address
    ) external view;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";
interface INFTSwapBoxFees is INFTSwap {

    function _checkerc20Fees(
        ERC20Details[] calldata,
        address
    ) external view returns(ERC20Fee[] memory);

    function _checknftgasfee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        uint256,
        address
    ) external view returns(uint256);

    function _checkRoyaltyFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        address
    ) external view returns(RoyaltyFee[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxAssets is INFTSwap {
    
    function _transferERC20Fee(ERC20Fee[] calldata, address, address, bool) external;
    function _transferAssetsHelper(ERC721Details[] calldata, ERC20Details[] calldata, ERC1155Details[] calldata, address, address, bool) external;
    function _setOfferAdddress(uint256, address[] calldata) external;
    function _checkAvailableOffer(uint256, address) external view returns(bool);
    function _deleteOfferAddress(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxHistory is INFTSwap {
    // function addHistoryUserSwapFees(uint256, SwapBox memory, SwapBox memory) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TestFT is ERC20, ERC20Burnable {
    constructor() ERC20("Test20", "T20") {
        _mint(msg.sender, 100_000_000_000 * 10**18 );
    }

    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// contracts/TestNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TestNFT is ERC721 {
    using Strings for uint256;

    uint256 private _currentTokenId = 0; //tokenId will start from 1
    string public baseURI_ = "";

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId ++;
    }

    /**
     * @dev Set BaseURI 
     */
    function setBaseURI(string memory baseURI) public {
        baseURI_ = baseURI;
    }

    /*
     * Function to Get TokenURI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721METADATA: URI query for non existent token"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                name(),
                                '#',
                                tokenId.toString(),
                                '", "image":"',
                                baseURI_,
                                tokenId.toString(),
                                '.jpg"}'
                            )
                        )
                    )
                )
            );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/INFTSwap.sol";

contract NFTSwapFeeDiscount is AccessControl {

    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;

    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
    }
    mapping(address => uint256) private userDiscount;
    mapping(address => uint256) private nftDiscount;

    function setUserDiscount(address userAddress, uint256 percentage) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(percentage > 100 && percentage <= 10000, "percentage must be between 1 and 100");
        userDiscount[userAddress] = percentage;
    }

    function setNFTDiscount(address nftAddress, uint256 percentage) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(percentage > 100 && percentage <= 10000, "percentage must be between 1 and 100");
        nftDiscount[nftAddress] = percentage;
    }

    function getUserDiscount(address userAddress) external view returns(uint256) {
        return userDiscount[userAddress];
    }

    function getNFTDiscount(address nftAddress) external view returns(uint256) {
        return nftDiscount[nftAddress];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/INFTSwap.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";

contract NFTSwapBoxWhitelist is INFTSwap, AccessControl {

    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;
    SwapBoxConfig private swapConfig;
    address[] public whitelistERC20Tokens;
    address[] public whitelistERC721Tokens;
    address[] public whitelistERC1155Tokens;

    /// @dev Add `root` to the admin role as a member.
    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
        swapConfig.usingERC721WhiteList = 1;
        swapConfig.usingERC1155WhiteList = 1;
        swapConfig.NFTTokenCount = 5;
        swapConfig.ERC20TokenCount = 5;
    }

    /**
        SetSwapConfig(usingERC721WhiteList, usingERC1155WhiteList, NFTTokenCount, ERC20TokenCount)
     */

    function setUsingERC721Whitelist(uint256 usingList) external  onlyRole(ADMIN) {
        swapConfig.usingERC721WhiteList = uint8(usingList);
    }

    function setUsingERC1155Whitelist(uint256 usingList) external  onlyRole(ADMIN) {
        swapConfig.usingERC1155WhiteList = uint8(usingList);
    }

    function setNFTTokenCount(uint256 limitTokenCount) external  onlyRole(ADMIN) {
        swapConfig.NFTTokenCount = uint8(limitTokenCount);
    }

    function setERC20TokenCount(uint256 limitERC20Count) external  onlyRole(ADMIN) {
        swapConfig.ERC20TokenCount = uint8(limitERC20Count);
    }
    /**
    Getting swapConfig((usingERC721WhiteList, usingERC1155WhiteList, NFTTokenCount, ERC20TokenCount))
    */
    function getSwapConfig() external view returns(SwapBoxConfig memory) {
        return swapConfig;
    }
    /**
        check assets for creating swapBox
     */
    function _checkAssets(
        ERC721Details[]  calldata erc721Details,
        ERC20Details[] calldata erc20Details,
        ERC1155Details[] calldata erc1155Details,
        address offer,
        address swapBox
    ) external view {
        require(
            (erc721Details.length + erc1155Details.length) <=
                swapConfig.NFTTokenCount,
            "Too much NFTs selected"
        );

        for (uint256 i = 0; i < erc721Details.length; i++) {
            require(
                validateWhiteListERC721Token(erc721Details[i].tokenAddr),
                "Not Allowed ERC721 Token"
            );

            require(
                erc721Details[i].id1 != 4294967295,
                "Non included ERC721 token"
            );

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id1
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );

            if(erc721Details[i].id2 == 4294967295) continue;

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id2
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );

            if(erc721Details[i].id3 == 4294967295) continue;

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id3
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );
        }

        require(
            erc20Details.length <= swapConfig.ERC20TokenCount,
            "Too much ERC20 tokens selected"
        );

        for (uint256 i = 0; i < erc20Details.length; i++) {
            require(
                validateWhiteListERC20Token(erc20Details[i].tokenAddr),
                "Not Allowed ERC20 Tokens"
            );
            require(
                IERC20(erc20Details[i].tokenAddr).allowance(
                    offer,
                    swapBox
                ) >= erc20Details[i].amounts,
                "ERC20 tokens must be approved to swap contract"
            );
            require(
                IERC20(erc20Details[i].tokenAddr).balanceOf(offer) >=
                    erc20Details[i].amounts,
                "Insufficient ERC20 tokens"
            );
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            require(
                validateWhiteListERC1155Token(erc1155Details[i].tokenAddr),
                "Not Allowed ERC1155 Token"
            );
            
            require(erc1155Details[i].amount1 != 0, "Non included ERC1155 token");

            require(
                IERC1155(erc1155Details[i].tokenAddr).balanceOf(
                    offer,
                    erc1155Details[i].id1
                ) >= erc1155Details[i].amount1,
                "Insufficient ERC1155 Balance"
            );

            require(
                IERC1155(erc1155Details[i].tokenAddr).isApprovedForAll(
                    offer,
                    swapBox
                ),
                "ERC1155 token must be approved to swap contract"
            );

            if(erc1155Details[i].amount2 != 0) {
                require(
                    IERC1155(erc1155Details[i].tokenAddr).balanceOf(
                        offer,
                        erc1155Details[i].id2
                    ) >= erc1155Details[i].amount2,
                    "Insufficient ERC1155 Balance"
                );
            }

        }
    }
    /**
        add tokens to Whitelist
     */

    function whiteListERC20Token(address erc20Token) public {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(
            validateWhiteListERC20Token(erc20Token) == false,
            "Exist Token"
        );
        whitelistERC20Tokens.push(erc20Token);
    }

    function whiteListERC721Token(address erc721Token) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        
        require(
            validateWhiteListERC721Token(erc721Token) == false,
            "Exist Token"
        );
        whitelistERC721Tokens.push(erc721Token);
    }

    function whiteListERC1155Token(address erc1155Token)
        public
    {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(
            validateWhiteListERC1155Token(erc1155Token) == false,
            "Exist Token"
        );
        whitelistERC1155Tokens.push(erc1155Token);
    }
    /**
        Get function for whitelist
     */

    function getERC20WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC20Tokens;
    }

    function getERC721WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC721Tokens;
    }

    function getERC1155WhiteListTokens()
        public
        view
        returns (address[] memory)
    {
        return whitelistERC1155Tokens;
    }

    /**
        RemoveToken from WhiteList
     */
    function removeFromERC20WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(index < whitelistERC20Tokens.length, "Invalid element");
        whitelistERC20Tokens[index] = whitelistERC20Tokens[
            whitelistERC20Tokens.length - 1
        ];
        whitelistERC20Tokens.pop();
    }

    function removeFromERC721WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(index < whitelistERC721Tokens.length, "Invalid element");
        whitelistERC721Tokens[index] = whitelistERC721Tokens[
            whitelistERC721Tokens.length - 1
        ];
        whitelistERC721Tokens.pop();
    }

    function removeFromERC1155WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(index < whitelistERC1155Tokens.length, "Invalid element");
        whitelistERC1155Tokens[index] = whitelistERC1155Tokens[
            whitelistERC1155Tokens.length - 1
        ];
        whitelistERC1155Tokens.pop();
    }

    // Checking whitelist ERC20 Token
    function validateWhiteListERC20Token(address erc20Token)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < whitelistERC20Tokens.length; i++) {
            if (whitelistERC20Tokens[i] == erc20Token) {
                return true;
            }
        }

        return false;
    }

    // Checking whitelist ERC721 Token
    function validateWhiteListERC721Token(address erc721Token)
        public
        view
        returns (bool)
    {
        if (swapConfig.usingERC721WhiteList == 0) return true;

        for (uint256 i = 0; i < whitelistERC721Tokens.length; i++) {
            if (whitelistERC721Tokens[i] == erc721Token) {
                return true;
            }
        }

        return false;
    }

    // Checking whitelist ERC1155 Token
    function validateWhiteListERC1155Token(address erc1155Token)
        public
        view
        returns (bool)
    {
        if (swapConfig.usingERC1155WhiteList == 0) return true;

        for (uint256 i = 0; i < whitelistERC1155Tokens.length; i++) {
            if (whitelistERC1155Tokens[i] == erc1155Token) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/INFTSwap.sol";
import "./interface/INFTSwapFeeDiscount.sol";

contract NFTSwapBoxFees is INFTSwap,AccessControl {
    using SafeMath for uint256;
    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint256 public defaultNFTSwapFee = 0.0001 ether;
    uint256 public defaultTokenSwapPercentage;
    uint256 public defaultGasTokenSwapPercentage;

    mapping(address => uint256) public NFTSwapFee;
    mapping(address => uint256) public ERC20SwapFee;
    mapping(address => RoyaltyFee) public NFTRoyaltyFee;

    address public nftSwapFeeDiscount;

    /// @dev Add `root` to the admin role as a member.
    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
    }

    function setDefaultNFTSwapFee(uint256 fee) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 0, "fee must be greate than 0");
        defaultNFTSwapFee = fee;
    }

    function setDefaultTokenSwapPercentage(uint256 fee) public  {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultTokenSwapPercentage = fee;
    }

    function setDefaultGasTokenSwapPercentage(uint256 fee) public {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultGasTokenSwapPercentage = fee;
    }

    function setNFTSwapFee(address nftAddress, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTSwapFee[nftAddress] = fee;
    }

    function setNFTRoyaltyFee(address nftAddress, uint256 fee, address receiver) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTRoyaltyFee[nftAddress].feeAmount = uint96(fee);
        NFTRoyaltyFee[nftAddress].reciever = receiver;
    }

    function setERC20Fee(address erc20Address, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 100 && fee <= 10000, "fee must be greate than 0");
        ERC20SwapFee[erc20Address] = fee;
    }

    function setNFTSwapDiscountAddress(address addr) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        nftSwapFeeDiscount = addr;
    }

    function getNFTSwapFee(address nftAddress) public view returns(uint256) {
        return NFTSwapFee[nftAddress];
    }

    function getRoyaltyFee(address nftAddress) public view returns(RoyaltyFee memory) {
        return NFTRoyaltyFee[nftAddress];
    }

    function getERC20Fee(address erc20Address) public view returns(uint256) {
        return ERC20SwapFee[erc20Address];
    }

    // function _getNFTLength(
    //     ERC721Details[] memory _erc721Details,
    //     ERC1155Details[] memory _erc1155Details
    // ) internal view returns(uint256) {

    //     uint256 royaltyLength;
    //     for(uint256 i ; i < _erc721Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     for(uint256 i ; i < _erc1155Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     return royaltyLength;
    // }

    function _checkerc20Fees(
        ERC20Details[] memory _erc20Details,
        address boxOwner
    ) external view returns(ERC20Fee[] memory) {
        uint256 erc20fee;
        ERC20Fee [] memory fees = new ERC20Fee[](_erc20Details.length);
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc20Details.length ; ++i) {
            erc20fee = 0;
            if(ERC20SwapFee[_erc20Details[i].tokenAddr] > 0)
                erc20fee = _erc20Details[i].amounts * ERC20SwapFee[_erc20Details[i].tokenAddr];
            else
                erc20fee = _erc20Details[i].amounts * defaultTokenSwapPercentage;
            erc20fee -= erc20fee * userDiscount / 10000;
            fees[i].tokenAddr = _erc20Details[i].tokenAddr;
            fees[i].feeAmount = uint96(erc20fee / 10000);
        }
        return fees;
    }
    
    function _checknftgasfee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenAmount,
        address boxOwner
    ) external view returns(uint256){
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);
        uint256 erc721Fee;
        uint256 erc1155Fee;
        uint256 gasFee;
        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += defaultNFTSwapFee;

            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];    

            if(nftDiscount > userDiscount) {
                erc721Fee -= erc721Fee * nftDiscount / 10000;
            }
            else {  
                erc721Fee -= erc721Fee * userDiscount / 10000;
            }
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount2 != 0)
               erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount2;
            
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount2 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount2;

            if(nftDiscount > userDiscount) {
                erc1155Fee -= erc1155Fee * nftDiscount / 10000;
            }
            else {  
                erc1155Fee -= erc1155Fee * userDiscount / 10000;
            }
        }

        if(_gasTokenAmount > 0)
            gasFee = _gasTokenAmount *  defaultGasTokenSwapPercentage / 10000;
        gasFee -= gasFee * userDiscount / 10000;

        return erc721Fee + erc1155Fee + gasFee;
    }

    function _checkRoyaltyFee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        address boxOwner
    ) external view returns(RoyaltyFee[] memory) {
        RoyaltyFee[] memory royalty = new RoyaltyFee[](_erc721Details.length + _erc1155Details.length);
       
        uint256 nftIndex;
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id1 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id2 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id3 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;

            if(nftDiscount > userDiscount) {
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else {  
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc721Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount1 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount1;   
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount2 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount2;   

            if(nftDiscount > userDiscount){
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else{
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc1155Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        return royalty;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwapFeeDiscount {
    function getUserDiscount(address) external view returns(uint256);
    function getNFTDiscount(address) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./interface/INFTSwap.sol";

// contract NFTSwapBoxHistory is Ownable, INFTSwap {

//     uint256 _swapFeeCounter = 1;
//     uint256 public totalSwapCounter = 0;

//     mapping(uint256 =>UserTotalSwapFees) public totalSwapFees;
//     mapping(uint256 => SwapHistory)  public swapHistory;
//     // UserTotalSwapFees[] totalSwapFees;
//     // SwapHistory [] swapHistory;

//     function _existAddress(address userAddress) internal view returns(bool) {
//         for(uint256 i = 0 ; i < _swapFeeCounter ; i++){
//             if(totalSwapFees[i].owner == userAddress)
//                 return true;
//         }
//         return false;
//     }

//     function _existERC20Fees(ERC20Fee[] memory historyFee, ERC20Fee[] memory addFees ) internal pure returns(bool) {
//         for(uint256 i = 0 ; i < historyFee.length ; i++) {
//             for(uint256 j = 0 ; j < addFees.length ; j++) {
//                 if(historyFee[i].tokenAddr == addFees[j].tokenAddr)
//                     return true;
//             }
//         }
//         return false;
//     }

//     function _addERC20Fees(uint256 index, ERC20Fee[] memory addFees ) internal {
//         for(uint256 i = 0 ; i < totalSwapFees[index].totalERC20Fees.length ; i++) {
//             for(uint256 j = 0 ; j < addFees.length ; j++) {
//                 if(totalSwapFees[index].totalERC20Fees[i].tokenAddr == addFees[j].tokenAddr)
//                     totalSwapFees[index].totalERC20Fees[i].feeAmount += addFees[j].feeAmount;
//             }
//         }
//     }

//     function getUserTotalSwapFees(address userAddress) public view returns(UserTotalSwapFees memory) {

//         require(_existAddress(userAddress) == true, "No History");
//         UserTotalSwapFees memory userFees;
//         for(uint256 i = 0 ; i < _swapFeeCounter ; i++){
//             if(totalSwapFees[i].owner == userAddress) {
//                 userFees.owner = totalSwapFees[i].owner;
//                 userFees.nftFees = totalSwapFees[i].nftFees;
//                 userFees.totalERC20Fees = totalSwapFees[i].totalERC20Fees;
//             }
//         }
//         return userFees;
//     }

//     function getSwapHistoryById(uint256 id) public view returns(SwapHistory memory) {
//         return swapHistory[id];
//     }

//     function addHistoryUserSwapFees(uint256 historyId, SwapBox memory listBox, SwapBox memory offerBox) external {
        
//         for(uint256 i = 0 ; i < _swapFeeCounter; i++) {
//             if(totalSwapFees[i].owner == listBox.owner){

//                 totalSwapFees[i].nftFees = totalSwapFees[i].nftFees + listBox.nftSwapFee + listBox.gasTokenFee;
//                 if(_existERC20Fees(totalSwapFees[i].totalERC20Fees, listBox.erc20Fees) == true)
//                     _addERC20Fees(i, listBox.erc20Fees);
//                 else {
//                     for(uint256 j = 0 ; j < listBox.erc20Fees.length ; j++){
//                         totalSwapFees[i].totalERC20Fees.push(listBox.erc20Fees[j]);
//                     }
//                 }

//             } else if(totalSwapFees[i].owner == offerBox.owner) {
//                  totalSwapFees[i].nftFees = totalSwapFees[i].nftFees + offerBox.nftSwapFee + offerBox.gasTokenFee;
//                  if(_existERC20Fees(totalSwapFees[i].totalERC20Fees, offerBox.erc20Fees) == true)
//                     _addERC20Fees(i, offerBox.erc20Fees);
//                 else {
//                     for(uint256 j = 0 ; j < offerBox.erc20Fees.length ; j++){
//                         totalSwapFees[i].totalERC20Fees.push(offerBox.erc20Fees[j]);
//                     }
//                 }
//             } else {
//                 UserTotalSwapFees storage listBoxswapFees = totalSwapFees[_swapFeeCounter];
//                 listBoxswapFees.owner = listBox.owner;
//                 listBoxswapFees.nftFees = listBox.nftSwapFee + listBox.gasTokenFee;
//                 for(uint256 j = 0 ; j < listBox.erc20Fees.length ; j++) {
//                     listBoxswapFees.totalERC20Fees.push(listBox.erc20Fees[j]);
//                 }

//                 _swapFeeCounter++;
                
//                 UserTotalSwapFees storage offerBoxswapFees = totalSwapFees[_swapFeeCounter];
//                 offerBoxswapFees.owner = offerBox.owner;
//                 offerBoxswapFees.nftFees = offerBox.nftSwapFee + offerBox.gasTokenFee;
//                 for(uint256 j = 0 ; j < offerBox.erc20Fees.length ; j++) {
//                     offerBoxswapFees.totalERC20Fees.push(offerBox.erc20Fees[j]);
//                 }
//                 _swapFeeCounter++;
//             }
//         }
        
//         SwapHistory storage history = swapHistory[historyId];

//         history.id = historyId;
//         history.listId = listBox.id;
//         history.listOwner = listBox.owner;
//         history.offerId = offerBox.id;
//         history.offerOwner =  offerBox.owner;
//         history.swapedTime = block.timestamp;
//         totalSwapCounter++;
//     }
// }