/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*
same as:
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
*/

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
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *	 return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
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
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

	/**
	 * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
	 * Use along with {totalSupply} to enumerate all tokens.
	 */
	function tokenByIndex(uint256 index) external view returns (uint256);
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

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library TreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
	    uint count;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(Tree storage self) internal view returns (bool) {
        return self.root == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (Node memory) {
        require(exists(self, key));
        return Node(self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }
    function getCount(Tree storage self) internal view returns (uint) {
        return self.count;
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);

        self.count++;
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];

        self.count--;
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

struct IDTree{
	TreeLibrary.Tree tree;
}

library IDTreeLib{
	using TreeLibrary for TreeLibrary.Tree;
	
	function root(IDTree storage self) external view returns (uint _key) {
		_key = self.tree.root;
	}
	
	function first(IDTree storage self) external view returns (uint _key) {
		_key = self.tree.first();
	}
	
	function last(IDTree storage self) external view returns (uint _key) {
		_key = self.tree.last();
	}
	
	function next(IDTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.next(key);
	}
	
	function prev(IDTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.prev(key);
	}
	
	function exists(IDTree storage self, uint key) external view returns (bool _exists) {
		_exists = self.tree.exists(key);
	}
	
	function isEmpty(IDTree storage self) external view returns (bool) {
		return self.tree.isEmpty();
	}

	function getCount(IDTree storage self) external view returns (uint) {
		return self.tree.getCount();
	}

	//////////////////////////////////////////

	function insert(IDTree storage self, uint _key) external {
		self.tree.insert(_key);
	}
	
	function remove(IDTree storage self, uint _key) external {
		self.tree.remove(_key);
	}

}

struct NFTSave{
	string uri;
	address creator;
	string title;
	uint hash;
}

struct NFTData{
	uint id;
	string uri;
	address creator;
	string creatorName;
	address owner;
	string ownerName;
	string title;
	uint hash;

	AuctionData auctionData;
}

struct AuctionData{
	bool isActive;
	uint endTime;//拍賣結束時間
	uint directPrice;//直購價
	uint nowPrice;//目前拍賣價
	address bidder;//目前出價人
}

enum LogType{
	StartAuction, StopAuction, Bid, Trade, Send, SendFail
}

struct LogData{
	LogType logType;

	address owner;//fromAddr
	address bidder;//toAddr
	uint tokenID;

	uint endTime;
	uint directPrice;
	uint nowPrice;//bidPrice、sendValue

	uint time;
}

library PoolnftLib{
	using IDTreeLib for IDTree;

	event Log(LogType logType, address indexed owner, address indexed bidder, uint indexed tokenID,
		uint endTime, uint directPrice, uint nowPrice, uint time);

	function startAuctionLog(address owner, uint tokenID, uint endTime, uint directPrice, uint nowPrice) public {
		emit Log(LogType.StartAuction, owner, address(0), tokenID, endTime, directPrice, nowPrice, block.timestamp);
	}

	function stopAuctionLog(address owner, uint tokenID) public {
		emit Log(LogType.StopAuction, owner, address(0), tokenID, 0, 0, 0, block.timestamp);
	}

	function bidLog(address owner, address bidder, uint tokenID, uint nowPrice) public {
		emit Log(LogType.Bid, owner, bidder, tokenID, 0, 0, nowPrice, block.timestamp);
	}

	function tradeLog(address owner, address bidder, uint tokenID, uint nowPrice) public {
		emit Log(LogType.Trade, owner, bidder, tokenID, 0, 0, nowPrice, block.timestamp);
	}

	function sendLog(address toAddr, uint sendValue, bool isFail) public {
		emit Log(isFail ? LogType.SendFail : LogType.Send, address(0), toAddr, 0, 0, 0, sendValue, block.timestamp);
	}

	function tokenData(uint tokenID, NFTSave[] memory nftSaveAr, mapping(address => string) storage addrNameMap,
			mapping(uint => AuctionData) storage auctionMap, Poolnft poolnft) 
			external view returns (NFTData memory data){

		require(poolnft.isToken(tokenID) );

		data.id=tokenID;
		data.uri=nftSaveAr[tokenID].uri;

		data.creator=nftSaveAr[tokenID].creator;
		data.creatorName=addrNameMap[data.creator];

		data.owner=poolnft.ownerOf(tokenID);
		data.ownerName=addrNameMap[data.owner];

		data.title=nftSaveAr[tokenID].title;
		data.hash=nftSaveAr[tokenID].hash;
		
		data.auctionData=auctionMap[tokenID];
	}

	function tokensData(uint[] memory tokenIDAr, NFTSave[] memory nftSaveAr,
			mapping(address => string) storage addrNameMap,
			mapping(uint => AuctionData) storage auctionMap, Poolnft poolnft
			) external view returns (NFTData[] memory dataAr) {
		
		dataAr=new NFTData[](tokenIDAr.length);

		for(uint i=0; i<tokenIDAr.length; i++){

			uint tokenID=tokenIDAr[i];
			if(tokenID==0){
				break;
			}
			
			require(poolnft.isToken(tokenID) );

			dataAr[i].id=tokenID;
			dataAr[i].uri=nftSaveAr[tokenID].uri;

			dataAr[i].creator=nftSaveAr[tokenID].creator;
			dataAr[i].creatorName=addrNameMap[dataAr[i].creator];

			dataAr[i].owner=poolnft.ownerOf(tokenID);
			dataAr[i].ownerName=addrNameMap[dataAr[i].owner];

			dataAr[i].title=nftSaveAr[tokenID].title;
			dataAr[i].hash=nftSaveAr[tokenID].hash;

			dataAr[i].auctionData=auctionMap[tokenID];
		}
	}

	function getOwnData(uint startIdx, uint size, IDTree storage idTree, Poolnft poolnft)
			external view returns (NFTData[] memory dataAr) {

		uint[] memory idAr=new uint[](size);
		
		uint id=idTree.first();
		uint lastID=idTree.last();
		uint i=0;
		while(true){
			if(i>=startIdx){
				idAr[i-startIdx]=id;

				if(i-startIdx == size-1){
					break;
				}
			}
			i++;

			if(id==lastID){
				break;
			}
			id=idTree.next(id);
		}

		return poolnft.tokensData(idAr);
	}

	function sendOrgCoin(address addr, uint value) public {
		if(payable(addr).send(value)==false){
			//遇到特殊合約可能出錯，這裡跳過錯誤，避免被卡住
			sendLog(addr, value, true);
		}
		else{
			sendLog(addr, value, false);
		}
	}

	function getAuctionNFTData(uint startIdx, uint size, IDTree storage idTree, Poolnft poolnft)
			external view returns (NFTData[] memory dataAr) {
		
		uint[] memory idAr=new uint[](size);
		
		uint id=idTree.first();
		uint lastID=idTree.last();
		uint i=0;
		while(true){
			if(i>=startIdx){
				idAr[i-startIdx]=id;

				if(i-startIdx == size-1){
					break;
				}
			}
			i++;

			if(id==lastID){
				break;
			}
			id=idTree.next(id);
		}

		return poolnft.tokensData(idAr);
	}

	function startAuction(uint tokenID, uint endTime, uint directPrice, uint nowPrice,
			mapping(uint => AuctionData) storage auctionMap,
			mapping(address => IDTree) storage userAuctionMap,
			Poolnft poolnft) external {

		require(poolnft.isToken(tokenID) );
		require(!auctionMap[tokenID].isActive && poolnft.ownerOf(tokenID)==msg.sender &&
			directPrice>0 && nowPrice>0 && directPrice>=nowPrice);

		auctionMap[tokenID]=AuctionData(true, endTime, directPrice, nowPrice, address(0) );
		userAuctionMap[msg.sender].insert(tokenID);

		startAuctionLog(msg.sender, tokenID, endTime, directPrice, nowPrice);
	}

	function stopAuction(uint tokenID, mapping(uint => AuctionData) storage auctionMap,
			mapping(address => IDTree) storage userAuctionMap,
			Poolnft poolnft) external {

		require(poolnft.isToken(tokenID) );

		AuctionData storage data=auctionMap[tokenID];

		require(poolnft.ownerOf(tokenID)==msg.sender && data.isActive &&
			(data.bidder==address(0) || data.bidder==msg.sender) );

		if(data.bidder==msg.sender){
			sendOrgCoin(data.bidder, data.nowPrice);

			poolnft.setBidBalance(poolnft.bidBalance()-data.nowPrice);
		}

		data.isActive=false;
		userAuctionMap[msg.sender].remove(tokenID);

		stopAuctionLog(msg.sender, tokenID);
	}

	function bid(uint tokenID, mapping(uint => AuctionData) storage auctionMap,
			mapping(address => IDTree) storage userAuctionMap,
			Poolnft poolnft) external {

		require(poolnft.isToken(tokenID) );

		AuctionData storage data=auctionMap[tokenID];

		require(data.isActive);

		address owner=poolnft.ownerOf(tokenID);

		if(msg.value>=data.directPrice){//時間過了也可以用直購價買
			if(data.bidder!=address(0) ){
				sendOrgCoin(data.bidder, data.nowPrice);
				poolnft.setBidBalance(poolnft.bidBalance()-data.nowPrice);
			}

			sendOrgCoin(owner, msg.value);

			data.isActive=false;
			poolnft.libTransfer(owner, msg.sender, tokenID);

			userAuctionMap[owner].remove(tokenID);

			tradeLog(owner, msg.sender, tokenID, msg.value);
			return;
		}

		require(data.endTime>block.timestamp);

		if(data.bidder==address(0) ){
			require(msg.value>=data.nowPrice);
		}
		else{
			require(msg.value>data.nowPrice);

			sendOrgCoin(data.bidder, data.nowPrice);
			poolnft.setBidBalance(poolnft.bidBalance()-data.nowPrice);
		}

		data.bidder=msg.sender;
		data.nowPrice=msg.value;
		poolnft.setBidBalance(poolnft.bidBalance()+msg.value);

		bidLog(owner, msg.sender, tokenID, msg.value);
	}

	function bidEnd(uint tokenID, mapping(uint => AuctionData) storage auctionMap,
			mapping(address => IDTree) storage userAuctionMap,
			Poolnft poolnft) external {

		require(poolnft.isToken(tokenID) );

		AuctionData storage data=auctionMap[tokenID];
		address owner=poolnft.ownerOf(tokenID);

		require(data.isActive && data.endTime<=block.timestamp);
		require((owner==msg.sender && data.bidder!=address(0) ) || data.bidder==msg.sender);

		sendOrgCoin(owner, data.nowPrice);
		poolnft.setBidBalance(poolnft.bidBalance()-data.nowPrice);

		data.isActive=false;
		poolnft.libTransfer(owner, data.bidder, tokenID);

		userAuctionMap[owner].remove(tokenID);

		tradeLog(owner, data.bidder, tokenID, data.nowPrice);
	}
}

contract Poolnft is ERC721, IERC721Enumerable {
	using IDTreeLib for IDTree;

	address immutable founderAddr;

	NFTSave[] nftSaveAr;
	mapping(address => uint[]) createMap;
	mapping(address => IDTree) ownMap;

	mapping(address => string) addrNameMap;
	mapping(string => address) nameUseMap;
	
 
	constructor() ERC721("Poolnft", "NFT") {
		founderAddr=msg.sender;
		nftSaveAr.push();//塞入一個空資料，讓ID從1開始，因為IDTree不接受0
	}

	function mint(string memory uri, string memory title, uint hash) public {
		require(bytes(uri).length > 0);
		require(bytes(title).length>0 && bytes(title).length <= 60*3);//一個中文字一般3個bytes

		uint id=nftSaveAr.length;
		_mint(msg.sender, id);

		nftSaveAr.push(NFTSave(uri, msg.sender, title, hash) );

		createMap[msg.sender].push(id);
		//ownMap[msg.sender].insert(id);在_safeMint中的_beforeTokenTransfer已做
	}
	
	function testMassMint(string memory uri, string memory title, uint hash, uint count) public {
		require(msg.sender==founderAddr);
		require(bytes(uri).length > 0);
		require(bytes(title).length>0 && bytes(title).length <= 60*3);//一個中文字一般3個bytes

		NFTSave memory save=NFTSave(uri, msg.sender, title, hash);

		for(uint i=0; i<count; i++){

			uint id=nftSaveAr.length;
			_mint(msg.sender, id);

			nftSaveAr.push(save);
			createMap[msg.sender].push(id);
		}
	}
	
	function isToken(uint tokenID) public view returns (bool) {
		return tokenID > 0 && tokenID < nftSaveAr.length;
	}

	function changeURI(uint tokenID, string memory uri) public {
		require(isToken(tokenID) );
		require(nftSaveAr[tokenID].creator==msg.sender || ownerOf(tokenID)==msg.sender);//擁有者或創作者才能改

		nftSaveAr[tokenID].uri=uri;
	}

	function tokenURI(uint tokenID) public view virtual override returns (string memory) {
		require(isToken(tokenID) );

		return nftSaveAr[tokenID].uri;
	}

	function tokenData(uint tokenID) public view returns (NFTData memory data) {
		
		return PoolnftLib.tokenData(tokenID, nftSaveAr, addrNameMap, auctionMap, this);
	}

	function tokensData(uint[] memory tokenIDAr) public view returns (NFTData[] memory dataAr) {
		
		return PoolnftLib.tokensData(tokenIDAr, nftSaveAr, addrNameMap, auctionMap, this);
	}

	function getTokensData(uint startIdx, uint size) public view returns (NFTData[] memory dataAr) {
		
		uint[] memory idAr=new uint[](size);
		
		for(uint i=startIdx; i<nftSaveAr.length && i<startIdx+size; i++){
			idAr[i-startIdx]=i + 1;
		}

		return tokensData(idAr);
	}

	function getCreateCount(address user) public view returns (uint count) {
		return createMap[user].length;
	}

	function getCreateData(address user, uint startIdx, uint size) public view returns (NFTData[] memory dataAr) {
		
		uint[] memory idAr=new uint[](size);
		
		for(uint i=startIdx; i<createMap[user].length && i<startIdx+size; i++){
			idAr[i-startIdx]=createMap[user][i];
		}

		return tokensData(idAr);
	}

	function getOwnCount(address user) public view returns (uint count) {
		return ownMap[user].getCount();
	}

	function getOwnData(address user, uint startIdx, uint size) public view returns (NFTData[] memory dataAr) {

		IDTree storage idTree=ownMap[user];
		if(idTree.isEmpty() ){
			return dataAr;
		}

		return PoolnftLib.getOwnData(startIdx, size, idTree, this);
	}

	//////////////////////////////////////////////////////////
	//IERC721Enumerable
	//////////////////////////////////////////////////////////

	function totalSupply() external view returns (uint){
		return nftSaveAr.length-1;
	}

	function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint){

		IDTree storage idTree=ownMap[owner];
		require(index < idTree.getCount() );

		uint id=idTree.first();
		uint lastID=idTree.last();
		uint i=0;
		while(true){
			if(i==index){
				return id;
			}
			i++;

			if(id==lastID){
				break;
			}
			id=idTree.next(id);
		}

		revert();
	}

	function tokenByIndex(uint index) external view returns (uint){
		uint id=index+1;
		require(isToken(id) );

		return id;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	//////////////////////////////////////////////////////////

	function setName(string memory name) public {
		require(nameUseMap[name]==address(0) );
		require(bytes(name).length>0 && bytes(name).length<60*3);//一個中文字一般3個bytes

		string memory oldName=addrNameMap[msg.sender];
		if(bytes(oldName).length!=0){
			nameUseMap[oldName]=address(0);
		}

		nameUseMap[name]=msg.sender;
		addrNameMap[msg.sender]=name;
	}

	function getName(address addr) public view returns (string memory) {
		return addrNameMap[addr];
	}

	function getNameAddr(string memory name) public view returns (address addr) {
		return nameUseMap[name];
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
		
		require(!auctionMap[tokenId].isActive);//拍賣時不能轉移
		
		super._beforeTokenTransfer(from, to, tokenId);
		
		if(from!=address(0) ){
			ownMap[from].remove(tokenId);
		}
		ownMap[to].insert(tokenId);
	}
	
	//////////////////////////////////////////////////////////

	mapping(uint => AuctionData) auctionMap;
	mapping(address => IDTree) userAuctionMap;
	uint public bidBalance=0;
	bool isLibCall=false;

	event Log(LogType logType, address indexed owner, address indexed bidder, uint indexed tokenID,
		uint endTime, uint directPrice, uint nowPrice, uint time);

	function setBidBalance(uint value) external {
		require(isLibCall);

		bidBalance=value;
	}

	function libTransfer(address fromAddr, address toAddr, uint tokenID) external {
		require(isLibCall);

		_transfer(fromAddr, toAddr, tokenID);
	}

	function getAuctionNFTData(address user, uint startIdx, uint size) public view returns (NFTData[] memory dataAr) {
		
		IDTree storage idTree=userAuctionMap[user];
		if(idTree.isEmpty() ){
			return dataAr;
		}

		return PoolnftLib.getAuctionNFTData(startIdx, size, idTree, this);
	}

	function getAuctionCount(address user) public view returns (uint count) {
		return userAuctionMap[user].getCount();
	}

	function startAuction(uint tokenID, uint endTime, uint directPrice, uint nowPrice) public {

		PoolnftLib.startAuction(tokenID, endTime, directPrice, nowPrice, auctionMap, userAuctionMap, this);
	}

	function stopAuction(uint tokenID) public {

		isLibCall=true;
		PoolnftLib.stopAuction(tokenID, auctionMap, userAuctionMap, this);
		isLibCall=false;
	}

	function bid(uint tokenID) public payable {

		isLibCall=true;
		PoolnftLib.bid(tokenID, auctionMap, userAuctionMap, this);
		isLibCall=false;
	}

	function bidEnd(uint tokenID) public {

		isLibCall=true;
		PoolnftLib.bidEnd(tokenID, auctionMap, userAuctionMap, this);
		isLibCall=false;
	}

	//////////////////////////////////////////////////////////

	function getBalance() public view returns (uint) {
		return address(this).balance;
	}

	function getOtherBalance() public view returns (uint) {
		return address(this).balance-bidBalance;
	}

	function withdrawOther(uint value) public{
		require(msg.sender==founderAddr);
		require(value<=getOtherBalance() );
		
		payable(msg.sender).transfer(value);
	}

}