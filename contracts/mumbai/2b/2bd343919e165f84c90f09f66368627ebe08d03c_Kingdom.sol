/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// SPDX-License-Identifier: MIT
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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

interface IWarrior {
    // struct to store each token's traits
    struct AvtHtr {
        bool isMerry;
        //2
        uint8 brutalityLevel;
        //3
        uint8 hench_num;
        //4
        uint8 hair;
        //5
        uint8 face;
        //6
        uint8 mask;
        //7
        uint8 weapon;
        //8
        uint8 hat;
        //9
        uint8 top;
        //10
        uint8 pants;
        //11
        uint8 accesorie;
        //12
        uint8 bling;
        //13
        uint8 alphaIndex;
    }

    function getPaidTokens() external view returns (uint256);
    function getMaxTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (AvtHtr memory);
}

 
interface IKingdom {
  function addManyToKingdomAndPack(address account, uint16[] memory tokenIds) external;
  function randomWarriorOwner(uint256 seed) external view returns (address);
}

 
interface IGroat {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function addController(address controller) external;
  function removeController(address controller) external;
}

 
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8);
}

contract Warrior is IWarrior, ERC721Enumerable, Ownable, Pausable {
    // uint256 public constant MAX_PER_MINT = 10;
    // mint price 1.5AVAX
    uint256 public MINT_PRICE = 100000000;
    address public MINT_PAY_TOKEN_ADDRESS ;

    //whitelist price  1.25 avax
    uint256 public WL_PRICE = 50000000;
    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;
    uint16 public Henchmen_minted;
    uint16 public Merrymen_minted;
    // Pre mint
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    // payment wallets
    address payable AdminWallet;
    address payable Multisig;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => AvtHtr) public tokenTraits;

    // WhiteList
    mapping(address => bool) public WhiteList;

    mapping(address => uint256) public whiteListMintCounts;
    mapping(uint256 => uint256) public scoreToDiscount;
    mapping(address => uint256) public userToReward;
    uint256 public totalReward = 0;
    // reference to the Kingdom for choosing random warrior thieves
    IKingdom public kingdom;
    // reference to $GROAT for burning on mint
    IGroat public groat;
    // reference to Traits
    ITraits public traits;

    event DiscountDiceRolled(address owner, uint256[] scores , uint256 refund_amount);
    event BeforeMint(address owner, address this_address);
    event NormalMint(string msg);
    event PreMint(string msg);

    /**
     * instantiates contract and rarity tables
     */

    constructor(
        address _groat,
        address _traits,
        address _mint_pay_token_address,
        uint256 _maxTokens,
        uint256 _paidTokens,
        address _withdraw
    ) ERC721("RobbinTheHood", "RobbinTheHoodGAME") {
        Multisig = payable(_withdraw);
        groat = IGroat(_groat);
        traits = ITraits(_traits);
        MINT_PAY_TOKEN_ADDRESS = _mint_pay_token_address;
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _paidTokens;
    }

    function setMintPayTokenAddress(address _address) external onlyOwner{
        MINT_PAY_TOKEN_ADDRESS = _address;
    }
    function setScoreToDiscount(uint256[] memory _discounts) external onlyOwner {
        for (uint256 i = 0; i < _discounts.length; i++) {
            scoreToDiscount[i+1] = _discounts[i];
        }
    }
    function setAdmin(address _admin) external onlyOwner {
        AdminWallet = payable(_admin);
    }

    function setWithdrawWallet(address _withdraw) external onlyOwner {
        Multisig = payable(_withdraw);
    }
    function setTraits(address _traits) external onlyOwner {
        traits = ITraits(_traits);
    }
    function setMintPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }


    function setWLMintPrice(uint256 _price) external onlyOwner {
        WL_PRICE = _price;
    }
    /** EXTERNAL */
    function setTimeforPremint(uint256 _startTimestamp, uint256 _endTimestamp)
        external
        onlyOwner
    {
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    modifier onlyWhileOpen() {
        require(
            block.timestamp >= startTimestamp && block.timestamp <= endTimestamp
        );
        _;
    }

    modifier onlyWhileClose() {
        require(block.timestamp > endTimestamp);
        _;
    }

    function isOpened() public view returns (bool) {
        return
            block.timestamp >= startTimestamp &&
            block.timestamp <= endTimestamp;
    }

    function isClosed() public view returns (bool) {
        return block.timestamp > endTimestamp;
    }

    function setWhitelist(address[] memory _whitelist) external onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            WhiteList[_whitelist[i]] = true;
        }
    }

    function levelupBrutality(uint256 tokenId) external returns (bool) {
        require(_msgSender() == address(kingdom), "No permission");
        tokenTraits[tokenId].brutalityLevel++;
        return true;
    }

    function approveMultiple(address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            approve(to, tokenIds[i]);
        }
    }

    /*
     * mint a token - 90% Adventurers, 10% warriors
     * The first 20% are free to claim, the remaining cost $GROAT
     */
    function mint(uint256 amount, bool stake) external whenNotPaused {
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0, "Invalid mint amount");        
        if (isOpened()) {
            IERC20(MINT_PAY_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount * WL_PRICE);
            _premint(amount, stake);            
        } else if (isClosed()) {
            IERC20(MINT_PAY_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount * MINT_PRICE);
            _normal_mint(amount, stake);            
        }
    }

    // after white list period
    function _normal_mint(uint256 amount, bool stake) private onlyWhileClose {
        //MAYBE WHITELISTED CAN MINT 1.25
        require(tx.origin == _msgSender(), "Only EOA");
        if (minted < PAID_TOKENS) {
            require(
                minted + amount <= PAID_TOKENS,
                "All tokens on-sale already sold"
            );

            // require(
            //     amount * MINT_PRICE <= msg.value || _msgSender() == AdminWallet,
            //     "Invalid payment amount"
            // );
            
            //IERC20(MINT_PAY_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount * MINT_PRICE);
        } else {
            require(
                msg.value == 0,
                "Do not send MATIC, minting is with GROAT now"
            );
        }
        core_mint(amount, stake);
    }

    // during white list period
    function _premint(uint256 amount, bool stake) private onlyWhileOpen {
        require(tx.origin == _msgSender(), "Only EOA");
        require(WhiteList[_msgSender()], "You are not whitelisted");
        require(
            whiteListMintCounts[_msgSender()] + amount <= 5,
            "White list can only mint 5"
        );
        require(
            minted + amount <= PAID_TOKENS,
            "All tokens on-sale already sold"
        );

        // require(
        //     amount * WL_PRICE <= msg.value || _msgSender() == AdminWallet,
        //     "Invalid payment amount"
        // );
        // send msg.sender's usdc 100 to this address's usdc  balance

        //IERC20(MINT_PAY_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount * WL_PRICE);

        whiteListMintCounts[_msgSender()] += amount;
        core_mint(amount, stake);
    }

    function core_mint(uint256 amount, bool stake) private {
        uint256 totalGroatCost = 0;
        uint16[] memory tokenIds = stake
            ? new uint16[](amount)
            : new uint16[](0);
        uint256 seed;
        uint256[] memory scores = new uint256[](amount);
        uint256 discount_amount=0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 diceScore = (random(i+1) % 11) + 2;
            scores[i] = diceScore;
            discount_amount = discount_amount + scoreToDiscount[diceScore];
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            if (!stake || recipient != _msgSender()) {
                _safeMint(recipient, minted);
            } else {
                _safeMint(address(kingdom), minted);
                tokenIds[i] = minted;
            }
            if (tokenTraits[minted].isMerry) {
                Merrymen_minted += 1;
            } else {
                Henchmen_minted += 1;
            }
            totalGroatCost += mintCost(minted); // 0 if we are before 10.000
        }

        //we may want to do that first but w/o reentrancy
        if (totalGroatCost > 0) groat.burn(_msgSender(), totalGroatCost);
        if (stake) kingdom.addManyToKingdomAndPack(_msgSender(), tokenIds);
        userToReward[msg.sender] += discount_amount;
        totalReward += discount_amount;
        emit DiscountDiceRolled(msg.sender, scores, discount_amount);
    }

    /**
     * the first 20% are paid in AVAX
     * the next 20% are 20000 $GROAT
     * the next 40% are 40000 $GROAT
     * the final 20% are 80000 $GROAT
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= (MAX_TOKENS * 4) / 6) return 20000 ether;
        if (tokenId <= (MAX_TOKENS * 5) / 6) return 40000 ether;
        return 80000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Kingdom's approval so that users don't have to waste gas approving
        if (_msgSender() != address(kingdom))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 tokenId, uint256 seed)
        internal
        returns (AvtHtr memory t)
    {
        t = selectTraits(seed);
        tokenTraits[tokenId] = t;

        return t;
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        return traits.selectTrait(seed, traitType);
    }

    /**
     * the first 20% (AVAX purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked adventurer
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the adventurer thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        //if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0)
            return _msgSender(); // top 10 bits haven't been used
        // address thief = kingdom.randomWarriorOwner(seed >> 144); // 144 bits reserved for trait selection
        // if (thief == address(0x0)) return _msgSender();
        // return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param _seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 _seed)
        internal
        view
        returns (AvtHtr memory t)
    {
        uint256 seed = _seed;
        t.isMerry = (seed & 0xFFFF) % 10 == 0;

        if (t.isMerry) {
            if ((seed & 0xFFFF) % 100 > 60) {
                t.alphaIndex = 1;
            } else if ((seed & 0xFFFF) % 100 > 30) {
                t.alphaIndex = 2;
            } else if ((seed & 0xFFFF) % 100 > 0||(seed & 0xFFFF) % 100 == 0) {
                t.alphaIndex = 3;
            }
        } else {
            t.brutalityLevel = 0;
        }

        if (0 < (seed & 0xFFFF) % 10 && (seed & 0xFFFF) % 10 < 4) {
            t.hench_num = 1;
        } else if (3 < (seed & 0xFFFF) % 10 && (seed & 0xFFFF) % 10 < 7) {
            t.hench_num = 2;
        } else if (6 < (seed & 0xFFFF) % 10 && (seed & 0xFFFF) % 10 < 10) {
            t.hench_num = 3;
        }

        if (t.isMerry) {
            seed >>= 16;
            t.hair = selectTrait(uint16(seed & 0xFFFF), 0);
            seed >>= 16;
            t.top = selectTrait(uint16(seed & 0xFFFF), 1);
            seed >>= 16;
            t.mask = selectTrait(uint16(seed & 0xFFFF), 2);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 3);
        } else if (t.hench_num == 1) {
            seed >>= 16;
            t.hat = selectTrait(uint16(seed & 0xFFFF), 4);
            seed >>= 16;
            t.top = selectTrait(uint16(seed & 0xFFFF), 5);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 6);
            seed >>= 16;
            t.accesorie = selectTrait(uint16(seed & 0xFFFF), 7);
            seed >>= 16;
            t.bling = selectTrait(uint16(seed & 0xFFFF), 8);
        } else if (t.hench_num == 2) {
            seed >>= 16;
            t.hair = selectTrait(uint16(seed & 0xFFFF), 9);
            seed >>= 16;
            t.face = selectTrait(uint16(seed & 0xFFFF), 10);
            seed >>= 16;
            t.top = selectTrait(uint16(seed & 0xFFFF), 11);
            seed >>= 16;
            t.pants = selectTrait(uint16(seed & 0xFFFF), 12);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 13);
        } else if (t.hench_num == 3) {
            seed >>= 16;
            t.hair = selectTrait(uint16(seed & 0xFFFF), 14);
            seed >>= 16;
            t.face = selectTrait(uint16(seed & 0xFFFF), 15);
            seed >>= 16;
            t.top = selectTrait(uint16(seed & 0xFFFF), 16);
            seed >>= 16;
            t.pants = selectTrait(uint16(seed & 0xFFFF), 17);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 18);
        }
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */

    // need to use seed contract
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /** READ */

    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (AvtHtr memory)
    {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    function getMaxTokens() external view override returns (uint256) {
        return MAX_TOKENS;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random adventurers thieves
     * @param _kingdom the address of the Kingdom
     */
    function setKingdom(address _kingdom) external onlyOwner {
        kingdom = IKingdom(_kingdom);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserReward(address user) public view returns (uint256){
        return userToReward[user];
    }

    function withdrawMoneyTo(address payable _to) public onlyOwner {
        _to.call{value: getBalance()-totalReward, gas: 100000}("");
    }

    function withdrawReward() external{
        uint256 this_usdc_balance = IERC20(MINT_PAY_TOKEN_ADDRESS).balanceOf(address(this));
        require(
            userToReward[msg.sender]>0 && this_usdc_balance >= userToReward[msg.sender],
            "You don't have reward balance."
        );
        IERC20(MINT_PAY_TOKEN_ADDRESS).transfer(msg.sender, userToReward[msg.sender]);
        totalReward -= userToReward[msg.sender];
        userToReward[msg.sender] = 0;
    }
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance-totalReward);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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


contract GROAT is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  constructor() ERC20("GROAT", "GROAT") { }

  /*
   * mints $GROAT to a recipient
   * @param to the recipient of the $GROAT
   * @param amount the amount of $GROAT to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /*
   * burns $GROAT from a holder
   * @param from the holder of the $GROAT
   * @param amount the amount of $GROAT to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /*
   * enables an address to mint / burn
   * @param controller the address to enable
   */
   function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }
  /*
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
   function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}


contract BLING is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  constructor() ERC20("BLING", "BLING") { }

  /*
   * mints $BLING to a recipient
   * @param to the recipient of the $BLING
   * @param amount the amount of $BLING to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /*
   * burns $BLING from a holder
   * @param from the holder of the $BLING
   * @param amount the amount of $BLING to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /*
   * enables an address to mint / burn
   * @param controller the address to enable
   */
   function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }
  /*
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
   function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}


contract Kingdom is Ownable, IERC721Receiver, Pausable {  
    // struct to store a stake's token, owner, and earning values
    
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint256 minTime;
        uint256 addReward;
        uint80 levelTime;
    }

    struct Contracts{
        Warrior warrior;
        GROAT groat;
        BLING bling;
    }

    Contracts public contracts;

    struct BrutRelated {
        mapping(uint8 => uint256) brutToEarnPerDay;
        mapping(uint8 => uint256) brutToUnstakingFee;
        mapping(uint8 => uint256) brutToRequiredBling;
        mapping(uint8 => uint256) brutToTimeLimit;
    }

    BrutRelated brutRelated;

    struct TokenData {
        uint256 id;
        IWarrior.AvtHtr traits;
        string tokenURI;
        Stake stakeInfo;
        uint256 owed;
        bool isGuarding;
    }

    uint8 public MAX_ALPHA = 8;
    uint256 public GROAT_CLAIM_TAX_PERCENTAGE = 20; 
    uint256 public MAXIMUM_GLOBAL_GROAT;

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event DiceRolled(address owner, uint256 tokenId, uint256 score);
    event HenchmanClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event MerrymanClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event BuyBlingSuccess(address owner, uint256 amount);
    event BrutalityLevelupSuccess(address owner, uint256 tokenId);

    // maps tokenId to stake
    mapping(uint256 => Stake) public kingdom;
    //dice score to time limit hours
    mapping(uint256 => uint256) public scoreToTimelimit;

    //dice score to additional percentage
    mapping(uint256 => uint256) public scoreToAddReward;

    // maps alpha to all merrymen stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Merryman in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no merrymen are staked
    uint256 public unaccountedRewards = 0;
    // amount of $GROAT due for each alpha point staked
    uint256 public groatPerAlpha = 0;

    // amount of $GROAT earned so far
    uint256 public totalGroatEarned;
    // number of Henchman staked in the kingdom
    uint256 public totalHenchmenStaked;
    // the last time $GROAT was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $GROAT
    bool public rescueEnabled = false;

    /*
     * @param _warrior reference to the Warrior NFT contract
     * @param _groat reference to the $GROAT token
     */
    constructor(
        address _warrior,
        address _groat,
        address _bling
    ) {
        contracts.warrior = Warrior(_warrior);
        contracts.groat = GROAT(_groat);
        contracts.bling = BLING(_bling);

        MAXIMUM_GLOBAL_GROAT = 2500000000 ether;

        scoreToTimelimit[1] = 8;
        scoreToTimelimit[2] = 16;
        scoreToTimelimit[3] = 24;
        scoreToTimelimit[4] = 32;
        scoreToTimelimit[5] = 40;
        scoreToTimelimit[6] = 48;

        scoreToAddReward[1] = 8;
        scoreToAddReward[2] = 16;
        scoreToAddReward[3] = 24;
        scoreToAddReward[4] = 32;
        scoreToAddReward[5] = 40;
        scoreToAddReward[6] = 48;

        brutRelated.brutToEarnPerDay[0] = 10000 ether;
        brutRelated.brutToEarnPerDay[1] = 11000  ether;
        brutRelated.brutToEarnPerDay[2] = 13000 ether;
        brutRelated.brutToEarnPerDay[3] = 16000 ether;
        brutRelated.brutToEarnPerDay[4] = 20000 ether;
        brutRelated.brutToEarnPerDay[5] = 25000 ether;
        brutRelated.brutToEarnPerDay[6] = 31000 ether;
        brutRelated.brutToEarnPerDay[7] = 38000 ether;
        brutRelated.brutToEarnPerDay[8] = 46000 ether;
        brutRelated.brutToEarnPerDay[9] = 55000 ether;
        brutRelated.brutToEarnPerDay[10] = 65000 ether;  

        brutRelated.brutToUnstakingFee[0] = 10000 ether;
        brutRelated.brutToUnstakingFee[1] = 11000 ether;
        brutRelated.brutToUnstakingFee[2] = 13000 ether;
        brutRelated.brutToUnstakingFee[3] = 16000 ether;
        brutRelated.brutToUnstakingFee[4] = 20000 ether;
        brutRelated.brutToUnstakingFee[5] = 25000 ether;
        brutRelated.brutToUnstakingFee[6] = 31000 ether;
        brutRelated.brutToUnstakingFee[7] = 38000 ether;
        brutRelated.brutToUnstakingFee[8] = 46000 ether;
        brutRelated.brutToUnstakingFee[9] = 55000 ether;
        brutRelated.brutToUnstakingFee[10] = 65000 ether;

        brutRelated.brutToRequiredBling[0] = 0 ether;
        brutRelated.brutToRequiredBling[1] = 150 ether;
        brutRelated.brutToRequiredBling[2] = 350 ether;
        brutRelated.brutToRequiredBling[3] = 500 ether;
        brutRelated.brutToRequiredBling[4] = 650 ether;
        brutRelated.brutToRequiredBling[5] = 850 ether;
        brutRelated.brutToRequiredBling[6] = 1000 ether;
        brutRelated.brutToRequiredBling[7] = 1150 ether;
        brutRelated.brutToRequiredBling[8] = 1350 ether;
        brutRelated.brutToRequiredBling[9] = 1500 ether;
        brutRelated.brutToRequiredBling[10] = 1650 ether; 

        brutRelated.brutToTimeLimit[0] = 0;
        brutRelated.brutToTimeLimit[1] = 1;
        brutRelated.brutToTimeLimit[2] = 1;
        brutRelated.brutToTimeLimit[3] = 1;
        brutRelated.brutToTimeLimit[4] = 1;
        brutRelated.brutToTimeLimit[5] = 1;
        brutRelated.brutToTimeLimit[6] = 2;
        brutRelated.brutToTimeLimit[7] = 2;
        brutRelated.brutToTimeLimit[8] = 2;
        brutRelated.brutToTimeLimit[9] = 2;
        brutRelated.brutToTimeLimit[10] = 2;  
    }

    function setMerrymenTax(uint256 _amount) external onlyOwner{
        GROAT_CLAIM_TAX_PERCENTAGE = _amount;
    }

    function setBrutToEarnPerDay(uint256[] memory _earns) external onlyOwner {
        for (uint8 i = 0; i < _earns.length; i++) {
            brutRelated.brutToEarnPerDay[i] = _earns[i]*1 ether;
        }
    }

    function setBrutToUnstakingFee(uint256[] memory _amount) external onlyOwner {
        for (uint8 i = 0; i < _amount.length; i++) {
            brutRelated.brutToUnstakingFee[i] = _amount[i]*1 ether;
        }
    }

    function setBrutToRequiredBling(uint256[] memory _amount) external onlyOwner {
        for (uint8 i = 0; i < _amount.length; i++) {
            brutRelated.brutToRequiredBling[i] = _amount[i]*1 ether;
        }
    }

    function setBrutToTimeLimit(uint256[] memory _amount) external onlyOwner {
        for (uint8 i = 0; i < _amount.length; i++) {
            brutRelated.brutToTimeLimit[i] = _amount[i];
        }
    }

    function setScoreToTimeLimit(uint256[] memory _amount) external onlyOwner {
        for (uint8 i = 0; i < _amount.length; i++) {
            scoreToTimelimit[i] = _amount[i];
        }
    }

    function setWarrior(address _address)
        external
        onlyOwner
    {
        contracts.warrior = Warrior(_address);
    }

    function setGroat(address _address)
        external
        onlyOwner
    {
        contracts.groat = GROAT(_address);
    }

    function setBling(address _address)
        external
        onlyOwner
    {
        contracts.bling = BLING(_address);
    }

    function setMAXIMUM_GLOBAL_GROAT(uint256 _MAXIMUM_GLOBAL_GROAT)
        external
        onlyOwner
    {
        MAXIMUM_GLOBAL_GROAT = _MAXIMUM_GLOBAL_GROAT;
    }

    function buyBling(uint256 _amount) external {
        require(
            contracts.groat.balanceOf(_msgSender()) > _amount * 12,
            "NOT ENOUGH GROAT"
        );
        contracts.groat.burn(_msgSender(), _amount * 12);
        contracts.bling.transfer(_msgSender(), _amount);
        emit BuyBlingSuccess(_msgSender(), _amount);
    }

    function levelupBrutality(uint256 tokenId) external {
        require(
            contracts.warrior.ownerOf(tokenId) == _msgSender(),
            "You are not the owner of this nft token"
        );
        uint256 required_bling = brutRelated.brutToRequiredBling[
            _brutalityLevelForHenchman(tokenId)
        ];
        require(
            contracts.bling.balanceOf(_msgSender()) > required_bling,
            "NOT ENOUGH BLING"
        );
        require(
            block.timestamp - kingdom[tokenId].levelTime >
                brutRelated.brutToTimeLimit[_brutalityLevelForHenchman(tokenId)] * 1 days,
            "There is time limit before each brutality level"
        );
        contracts.warrior.levelupBrutality(tokenId);
        emit BrutalityLevelupSuccess(_msgSender(), tokenId);
    }

    /** STAKING */

    /**
     * adds Henchman and Merrymen to the kingdom and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Henchman and Merrymen to stake
     */

    //  function getStakedTokenData() external view returns (TokenData[] memory tokenData)
    // {

    // }
    function addManyToKingdomAndPack(address account, uint16[] memory tokenIds)
        external
    {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(contracts.warrior),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(contracts.warrior)) {
                // dont do this step if its a mint + stake
                require(
                    contracts.warrior.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                contracts.warrior.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isMerry(tokenIds[i])) _addMerrymanToPack(account, tokenIds[i]);
            else _addHenchmanToKingdom(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Henchman to the kingdom
     * @param account the address of the staker
     * @param tokenId the ID of the Henchman to add to the kingdom
     */
    function _addHenchmanToKingdom(address account, uint256 tokenId)
        internal
        whenNotPaused
    {
        _updateEarnings(tokenId);
        uint256 diceScore = (random(tokenId) % 6) + 1;
        emit DiceRolled(account, tokenId, diceScore);
        kingdom[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            minTime: scoreToTimelimit[diceScore] * 1 hours,
            addReward: scoreToAddReward[diceScore],
            levelTime: uint80(block.timestamp)
        });
        totalHenchmenStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Merryman to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Merryman to add to the Pack
     */
    function _addMerrymanToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForMerryman(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the Merryman in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(groatPerAlpha),
                minTime: 0 * 1 hours,
                addReward: 0,
                levelTime: 0
            })
        ); // Add the Merryman to the Pack
        emit TokenStaked(account, tokenId, groatPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $GROAT earnings and optionally unstake tokens from the kingdom / Pack
     * to unstake a Henchman it will require it has 2 days worth of $GROAT unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromKingdomAndPack(uint16[] memory tokenIds, bool unstake)
        external
        whenNotPaused
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _updateEarnings(tokenIds[i]);
            if (isMerry(tokenIds[i]))
                owed += _claimMerrymanFromPack(tokenIds[i], unstake);
            else owed += _claimHenchmanFromKingdom(tokenIds[i], unstake);
        }

        if (owed == 0) return;
        contracts.groat.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        if (contracts.warrior.getTokenTraits(tokenId).isMerry) {
            uint256 alpha = _alphaForMerryman(tokenId);
            Stake memory stake = pack[alpha][packIndices[tokenId]];
            owed = (alpha) * (groatPerAlpha - stake.value);
        } else {
            Stake memory stake = kingdom[tokenId];
            if (totalGroatEarned < MAXIMUM_GLOBAL_GROAT) {
                owed =
                    ((block.timestamp - stake.value) * brutRelated.brutToEarnPerDay[_brutalityLevelForHenchman(tokenId)]) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $GROAT production stopped already
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * brutRelated.brutToEarnPerDay[_brutalityLevelForHenchman(tokenId)]) /
                    1 days; // stop earning additional $GROAT if it's all been earned
            }
        }
    }

    /**
     * realize $GROAT earnings for a single Henchman and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Merrymen
     * if unstaking, there is a 50% chance all $GROAT is stolen
     * @param tokenId the ID of the Henchman to claim earnings from
     * @param unstake whether or not to unstake the Henchman
     * @return owed - the amount of $GROAT earned
     */
    function _claimHenchmanFromKingdom(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = kingdom[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < stake.minTime),
            "GONNA BE COLD UNTIL MINIMUM STAKE TIME"
        );
        if (totalGroatEarned < MAXIMUM_GLOBAL_GROAT) {
            owed =
                ((block.timestamp - stake.value) *
                    brutRelated.brutToEarnPerDay[_brutalityLevelForHenchman(tokenId)]) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $GROAT production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) *
                    brutRelated.brutToEarnPerDay[_brutalityLevelForHenchman(tokenId)]) /
                1 days; // stop earning additional $GROAT if it's all been earned
        }
        if (unstake) {
            require(
                (owed>= brutRelated.brutToUnstakingFee[_brutalityLevelForHenchman(tokenId)]),
                "Lack of $GROAT for unstaking fee"
            );
            owed -= brutRelated.brutToUnstakingFee[_brutalityLevelForHenchman(tokenId)];

            _payMerrymenTax((owed * GROAT_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked Merrymen
            owed = (owed * (100 - GROAT_CLAIM_TAX_PERCENTAGE)) / 100;

            contracts.warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Henchman
            delete kingdom[tokenId];
            totalHenchmenStaked -= 1;
        } else {
            _payMerrymenTax((owed * GROAT_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked Merrymen
            owed = (owed * (100 - GROAT_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Henchman owner
            kingdom[tokenId].value = uint80(block.timestamp); // reset stake
        }
        emit HenchmanClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $GROAT earnings for a single Merryman and optionally unstake it
     * Merrymen earn $GROAT proportional to their Alpha rank
     * @param tokenId the ID of the Merryman to claim earnings from
     * @param unstake whether or not to unstake the Merryman
     * @return owed - the amount of $GROAT earned
     */
    function _claimMerrymanFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            contracts.warrior.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _alphaForMerryman(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (groatPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            contracts.warrior.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Merryman
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Merryman to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(groatPerAlpha),
                minTime: 0 * 1 hours,
                addReward: 0,
                levelTime: 0
            }); // reset stake
        }
        emit MerrymanClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!isMerry(tokenId)) {
                stake = kingdom[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                contracts.warrior.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Henchman
                delete kingdom[tokenId];
                totalHenchmenStaked -= 1;
                emit HenchmanClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForMerryman(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                contracts.warrior.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Merryman
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Merryman to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                emit MerrymanClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $GROAT to claimable pot for the Pack
     * @param amount $GROAT to add to the pot
     */
    function _payMerrymenTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked Merrymans
            unaccountedRewards += amount; // keep track of $GROAT due to Merrymans
            return;
        }
        // makes sure to include any unaccounted $GROAT
        groatPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $GROAT earnings to ensure it stops once 2.4 billion is eclipsed
     */
    function _updateEarnings(uint256 tokenId) internal {
        if (totalGroatEarned < MAXIMUM_GLOBAL_GROAT) {
            totalGroatEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalHenchmenStaked *
                    brutRelated.brutToEarnPerDay[_brutalityLevelForHenchman(tokenId)]) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /* READ ONLY */

    /*
     * checks if a token is a Henchman
     * @param tokenId the ID of the token to check
     * @return Henchman - whether or not a token is a Henchman
     */
    function isMerry(uint256 tokenId) public view returns (bool) {
        IWarrior.AvtHtr memory temp = contracts.warrior.getTokenTraits(tokenId);
        return temp.isMerry;
    }

    /**
     * gets the alpha score for a Merryman
     * @param tokenId the ID of the Merryman to get the alpha score for
     * @return the alpha score of the Merryman (5-8)
     */
    function _alphaForMerryman(uint256 tokenId) internal view returns (uint8) {
        IWarrior.AvtHtr memory temp = contracts.warrior.getTokenTraits(tokenId);
        return MAX_ALPHA - temp.alphaIndex; // alpha index is 1-3
    }

    function _brutalityLevelForHenchman(uint256 tokenId)
        internal
        view
        returns (uint8)
    {
        //( , uint8 brutalityLevel, , , , , , , , , , , ) = contracts.warrior.tokenTraits(tokenId);
        IWarrior.AvtHtr memory temp = contracts.warrior.getTokenTraits(tokenId);
        return temp.brutalityLevel;
    }

    /*
     * chooses a random Merryman when a newly minted token is stolen
     * @param seed a random value to choose a Merryman from
     * @return the owner of the randomly selected Merryman
     */
    function randomMerrymanOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Merrymen with the same alpha score
        for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Merryman with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to kingdom directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}