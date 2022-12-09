// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
// import "./Ownable.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
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
     * - `target` must be a contract.78
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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

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


contract ERC721Holder is IERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  )
    public
    override
    virtual
    returns(bytes4)
  {
    return this.onERC721Received.selector;
  }
}


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /*
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// abstract contract Context {
   
// }

contract Ownable  {
    address private _owner;
    uint256 public totalOwners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address[] private ownersArray;
    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        totalOwners++;
    }

     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() virtual {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

  
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        owners[newOwner] = true;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        totalOwners++;
        ownersArray.push(newOwner);
    }

    function findOwnerAddress(address _ownerAddr) internal view returns(uint256 index){
        for(uint i = 0; i < ownersArray.length; i++){
            if(ownersArray[i] == _ownerAddr){
                index = i;
            }
        }
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
        uint256 index = findOwnerAddress(_Owner);
        require(index >= 0, "Invalid index!");
        for (uint i = index; i<ownersArray.length-1; i++){
            ownersArray[i] = ownersArray[i+1];
        }
        ownersArray.pop();
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }

    function getAllOwners() public view returns (address[] memory){
        return ownersArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import './Interfaces.sol';
//import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './Interfaces.sol';
import './Ownable.sol';
import './Whitelisting.sol';
// import 'hardhat/console.sol';


contract TraderTestinggg is Ownable, ERC721, ERC721Holder{ 

    using Strings for uint256;
    Whitelisting whitelisting;
    Ownable ownable;


    uint256 public constant totalSupply = 10000;
    uint256 public totalMinted = 0;                 // Total Minted Supply
    uint256 public publicMinted = 0;                // Public Minted Supply 
    uint256 public giftMinted = 0;                  // Gift Minted Supply
    uint256 public airDropMinted = 0;               // AirDrop Minted Supply
    uint256 public publicMintLimit = 9500;         //  Public mint limit
    uint256 public giftMintLimit = 500;              //  Gift mint limit
    uint256 public giftMintId = 9501;
    uint256 public publicMintId = 1;
    uint256 public mintPrice = 1 * 10 ** 17;        // minting price 0.1 ETH
    uint256 public perTxQuantity = 20;
    uint256 public perWalletQuantity = 20;
    uint256 public whitelistType;
    uint256 public mintedThroughStripe;

    address public custodialWallet;
    address public deployer; 
    address public fundReceiver;

    bool public publicSaleIsActive = false;
    bool public privateSaleIsActive = false; 
    bool public isPaused = false;
    bool public isHalted = false;
    bool public revealed = false; 


    string wrongValuePassed = "You have passed wrong value.";
    string invalidWalletAddress = "Invalid wallet address.";
    string userNotWhitelisted = "User not whitelisted";
    string saleNotStarted = "Sale has not been started yet.";
    string private revealedUri;
    string private notRevealedUri; 

    address[] private giftMintedAddresses;
    address[] private NFTBuyersAddresses;

    event nft_minted(address buyer, uint256 quantity, uint time, uint256[] tokenIDs, mintType);

    enum mintType{
        walletMinted,   //mint through metamask
        stripeMinted,   //mint through stripe
        giftMinted,     //gift minted
        airdropMinted,   //airdrop minted
        ownerMinted     //owner minted
        
    }


    mapping(address => bool) private giftMintedAddressBool;
    mapping(address => bool) private NFTBuyersAddressBool;

    //      UUID    =>       PaymentID=> tokenIDs
    mapping(bytes => mapping(bytes32 => uint256[])) private tokenIDwithUUID;
    mapping(address => uint256) public walletMinted;
    mapping(uint256 => bool) public lockedNFTs;    //for locking NFTs, if the user has revert his payment.
    mapping(bytes => uint256) public UUIDMinted;

    modifier isPause(){
        require(isPaused == false, "Token is Paused.");
        _;
    }

    modifier isHalt(){
        require(isHalted == false, "Token is Halted.");
        _;
    }

    modifier onlyCustodialWallet() {
        require(msg.sender == custodialWallet, "call from unknown address");
        _;
    }

    modifier onlyOwner() override {
        if(address(ownable) != address(0)){
            require(
            ownable.verifyOwner(msg.sender) == true ||
            verifyOwner(msg.sender) == true,
            "Caller is not the Owner."
            );
        } 
        else{
            require(
            verifyOwner(msg.sender) == true,
            "Caller is not the Owner." );
        }
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, 
            "Caller in not deployer"
        );
        _;
    } 


    constructor(address _custodialWallet) ERC721("TraderSpirits", "TRSP"){
        custodialWallet = _custodialWallet;
        deployer = fundReceiver = msg.sender;
    }


    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                       SETTER FUNCTIONS                              //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////


    function setWhitelistContractAddress(address whitelistContractAddress) external onlyDeployer{
        require(whitelistContractAddress != address(0) && whitelistContractAddress != address(this), "Invalid whitelist address.");

        // if(IERC165(whitelistContractAddress).supportsInterface(0x7619beda) == true){
        // whitelisting = Whitelisting(whitelistContractAddress);
        // } else{
        //     revert("Wrong contract Address passed");
        // }


        whitelisting = Whitelisting(whitelistContractAddress);
    }

    function setOwnable(address ownableAddr) external onlyDeployer {
        require(ownableAddr != address(0) && ownableAddr != address(this), "Invalid ownable address.");
        ownable = Ownable(ownableAddr);
    }
    function _setrevealedUri(string memory _revealedUri) external onlyOwner{
        revealedUri = _revealedUri;
    }

    function _setNotRevealURI(string memory _notRevealUri) external onlyOwner{
        notRevealedUri = _notRevealUri;
    }

    function setFundReceiver(address _fundReceiver) external onlyOwner{
        require(_fundReceiver != address(0) && _fundReceiver != address(this), invalidWalletAddress);
        fundReceiver = _fundReceiver;
    }

    function setCustodialWallet(address newCustodialWallet) external onlyOwner{
        require(newCustodialWallet != address(0) && newCustodialWallet != address(this), invalidWalletAddress);
        custodialWallet = newCustodialWallet;
    }

    function reveal() external onlyOwner {
       revealed = !revealed;
    }
  
    function setSaleStatus(uint8 saleType) external onlyOwner {
        require(saleType == 0 || saleType == 1, "Sale type is invalid.");
        // saleType = 0 for private sale
        // saleType = 1 for public sale
        
        if(saleType == 0){
            uint256 identifier = whitelisting.identifier();
           
            require(
                !privateSaleIsActive && 
                address(whitelisting) != address(0) &&
                identifier > 0 && identifier <=3,
                "Transaction invalid"
            );
           
            privateSaleIsActive = true;
            publicSaleIsActive = false;
        }
        else if(saleType == 1){
            require(!publicSaleIsActive, wrongValuePassed);
            publicSaleIsActive = true;
            privateSaleIsActive = false;
        }

    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0 && newPrice != mintPrice, wrongValuePassed);
        mintPrice = newPrice;
    }
    
    function setPauseStatus() external onlyOwner{
        isPaused = !isPaused;
    }

    function setHaltStatus() external onlyOwner{
        isHalted = !isHalted;
    }

    function setPublicMintLimit(uint256 _publicMintLimit) external onlyOwner{
        require(_publicMintLimit > 0, wrongValuePassed);
        publicMintLimit = _publicMintLimit;
    }

    function setGiftMintLimit(uint256 _giftMintLimit) external onlyOwner{
        require(_giftMintLimit > 0 && _giftMintLimit < totalSupply, wrongValuePassed);
        giftMintLimit = _giftMintLimit;
        publicMintLimit = totalSupply - giftMintLimit;
    }

    function setGiftMintId(uint256 _giftMintId) external onlyOwner{
        require(_giftMintId > 0 && _giftMintId + giftMintLimit <= totalSupply, wrongValuePassed);
        giftMintId = _giftMintId;
    }

    function setPerTxQuantity(uint256 _perTxQuantity) external onlyOwner{
        require(_perTxQuantity > 0 && _perTxQuantity != perTxQuantity, wrongValuePassed);
        perTxQuantity = _perTxQuantity;
    }

    function setPerWalletQuantity(uint256 _perWalletQuantity) external onlyOwner{
        require(_perWalletQuantity > 0 && _perWalletQuantity != perWalletQuantity, wrongValuePassed);
        perWalletQuantity  = _perWalletQuantity;
    }


    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                      MINTING FUNCTIONS                              //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////


    function mintByUser(uint256 quantity, bytes32[] memory proof, bytes32 rootHash) external payable isPause isHalt {

        require(privateSaleIsActive == true || publicSaleIsActive == true, saleNotStarted);
        
        address sender = msg.sender;

        if(privateSaleIsActive == true){
            require(address(whitelisting) != address(0), "Whitelisting contract not initialized.");
            uint256 identifier = whitelisting.identifier();
            require(identifier > 0 && identifier <= 3, "Identifier is invalid.");
        
            if(identifier == 1){
                require (whitelisting.VerifyAddressForWhitelisting(sender) == true, 
                    userNotWhitelisted
                );
            }   
            else if (identifier == 2){
                require(whitelisting.statusOfAddress(sender) == true, 
                    userNotWhitelisted
                );
            }
            else if(identifier == 3){
                require(whitelisting.getRootHashesForVerifyUsingContract_status(rootHash) == true, 
                    "Root hash not found."
                );

                bytes32 leaf = keccak256(abi.encodePacked(sender));

                require(MerkleProof.verify(proof,rootHash, leaf), 
                    userNotWhitelisted
                );
            }
        }
  
        else if(publicSaleIsActive == true){
            require(publicSaleIsActive == true, "Public Sale is not Started");
            require(publicMinted + quantity <= publicMintLimit, "Max Limit To Total Sale");
        }
        
        uint256[] memory mintedTokenIDs  = new uint256[](quantity);
    
        require(
            quantity > 0 && quantity <= perTxQuantity &&
            walletMinted[sender] + quantity <= perWalletQuantity &&
            msg.value >= mintPrice * quantity,
            "invalid transaction."
        );

        (bool success,) = payable(fundReceiver).call{value: msg.value}("");

        if(!success) {
            revert("Payment Sending Failed.");
        }
        else{
            uint256 count = quantity;

            while(count > 0) {
                if(!_exists(publicMintId) && (publicMintId < giftMintId || publicMintId >= (giftMintId+giftMintLimit))){
                    _safeMint(sender, publicMintId);
                    mintedTokenIDs[quantity - count] = publicMintId;
                    publicMintId++;
                    count--;
                    // counter++;
                }else{
                    if(_exists(publicMintId)){
                        publicMintId++;
                    }else{
                        publicMintId+=giftMintLimit;
                    }
                }
            }

            totalMinted+=quantity;
            publicMinted+=quantity;

            if(NFTBuyersAddressBool[sender] == false){
                NFTBuyersAddresses.push(sender);
                NFTBuyersAddressBool[sender] = true; 
            }
            walletMinted[sender] += quantity;
        }
        
        emit nft_minted(sender, quantity, block.timestamp, mintedTokenIDs, mintType.walletMinted);
    }
    
     
    function mintByOwner(uint256 quantity) external isHalt onlyOwner {
        require(publicSaleIsActive == true, "Public Sale is not Started");
        require(publicMinted + quantity <= publicMintLimit, "Max Limit To Total Sale");
        uint256 count = quantity; 

        uint256[] memory mintedTokenIDs  = new uint256[](quantity);
        // uint256 counter = 0;  


        while(count > 0) {
            if(!_exists(publicMintId) && (publicMintId < giftMintId || publicMintId >= (giftMintId+giftMintLimit))){
                _safeMint(msg.sender, publicMintId);
                mintedTokenIDs[quantity - count] = publicMintId;
                publicMintId++;
                // counter++;
                count--;
            }else{
                if(_exists(publicMintId)){
                    publicMintId++;
                }else{
                    publicMintId+=giftMintLimit;
                }
            }
        }

        totalMinted += quantity;
        publicMinted += quantity;


        emit nft_minted(msg.sender, quantity, block.timestamp, mintedTokenIDs, mintType.ownerMinted);
    }
    
    function giftMint(address _address, uint256 quantity) external isHalt onlyOwner{
        require((giftMinted + quantity) <= giftMintLimit, wrongValuePassed);
        uint256 count = quantity;

        uint256[] memory mintedTokenIDs  = new uint256[](quantity);
        // uint256 counter = 0; 

        while(count > 0){
            if(!_exists(giftMintId)){
                _safeMint(_address, giftMintId);
                mintedTokenIDs[quantity - count] = giftMintId;
                giftMintId++;
                // counter++;
                count--;
            }else{
                giftMintId++;
            }
        }

        giftMinted += quantity;
        totalMinted += quantity;

        if(giftMintedAddressBool[_address] == false){
            giftMintedAddresses.push(_address);
            giftMintedAddressBool[_address] = true; 
        }

        emit nft_minted(_address, quantity, block.timestamp, mintedTokenIDs, mintType.giftMinted);

    } 

    function airDropToken(address _address, uint256 _tokenID) external isHalt onlyOwner{
        require(_tokenID > 0 && _tokenID <= (publicMintLimit + giftMintLimit), "You have passed wrong value");
        airDropMinted++;
        totalMinted++;
        _safeMint(_address, _tokenID);

        uint256[] memory mintedTokenIDs  = new uint256[](1);
        mintedTokenIDs[0] = _tokenID;

        emit nft_minted(_address, 1, block.timestamp, mintedTokenIDs, mintType.airdropMinted);

    }

    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                          MINT THROUGH STRIPE FUNCTIONS                              //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////



    function mintThroughStripe(bytes memory UUID, bytes32 paymentID, address walletAddress, uint256 quantity) external isHalt isPause onlyCustodialWallet {

        require(privateSaleIsActive == true || publicSaleIsActive == true, saleNotStarted);
        require(
            quantity > 0 && quantity <= perTxQuantity &&
            UUIDMinted[UUID] + quantity <= perWalletQuantity  &&
            UUID.length != 0 && getUUID_Data(UUID, paymentID).length == 0,
            "Invalid Transaction"
        );

        uint256 count =  quantity;

        address receiver;

        if(walletAddress == address(0)){
            receiver = address(this);
        }else{
            receiver = walletAddress;
        }

        // uint256[] memory mintedTokenIDs  = new uint256[](quantity);
        // uint256 counter = 0; 
        
        while(count > 0) {
            if(!_exists(publicMintId) && (publicMintId < giftMintId || publicMintId >= (giftMintId+giftMintLimit))){
                
                _safeMint(receiver, publicMintId);
                // if(receiver != address(this)){
                //     // mintedTokenIDs[counter] = publicMintId;
                //     // counter++;
                // }
                tokenIDwithUUID[UUID][paymentID].push(publicMintId);
                publicMintId++;
                count--;
            }else{
                //publicMintId++;
                if(_exists(publicMintId)){
                        publicMintId++;
                }else{
                    publicMintId+=giftMintLimit;
                }
            }
        }
        totalMinted+=quantity;
        publicMinted+=quantity;
        UUIDMinted[UUID] += quantity;

        if(receiver != address(this)){
            // uint256[] memory mintedTokenIDs = getUUID_Data(UUID, paymentID);
            emit nft_minted(msg.sender, quantity, block.timestamp, getUUID_Data(UUID, paymentID), mintType.stripeMinted);
        }       
    }

    function claimNFT(bytes memory UUID, bytes memory paymentID)public isHalt isPause{
        // require(UUID.length != 0, "UUID can't be null.");
        bytes32[] memory paymentIDsList = abi.decode(paymentID, (bytes32[]));

        uint256 quantity = _getTokenIdsLength(UUID, paymentID);

        uint256[] memory mintedTokenIDs = new uint256[](quantity);
        uint256 counter = 0; 
        address sender = msg.sender;

        uint i;
        
        for (i = 0; i < paymentIDsList.length; i++){
            uint256[] memory totalTokens = getUUID_Data(UUID,paymentIDsList[i]);
            // mintedTokenIDs = new uint256[](totalTokens.length);

            if( totalTokens.length > 0){
            for(uint x = 0; x < totalTokens.length; x++){
                // console.log(totalTokens[x]);
                // ERC721(address(this)).approve(msg.sender, totalTokens[x]);
                ERC721(address(this)).transferFrom(address(this), sender, totalTokens[x]);
                // ERC721(address(this))._transfer(address(this), msg.sender, totalTokens[x]);
                mintedTokenIDs[counter] = totalTokens[x];
                counter++;
            }
            delete tokenIDwithUUID[UUID][paymentIDsList[i]];
            }
        }
    
        emit nft_minted(sender, quantity, block.timestamp, mintedTokenIDs, mintType.stripeMinted);
        
    }

    function updateUUID(bytes memory UUID, bytes memory paymentID, bytes memory newUUID) external onlyCustodialWallet returns(bool){
    
        bool areEqual = UUID.length == newUUID.length && keccak256(UUID) == keccak256(newUUID);

        require( 
            UUID.length !=0 && 
            newUUID.length != 0 &&
            paymentID.length != 0 &&
            !areEqual,
            "Wrong arguments passed."
        );

        bytes32[] memory paymentIDsList = abi.decode(paymentID, (bytes32[]));
        
        for (uint i = 0; i < paymentIDsList.length; i++){
            if(tokenIDwithUUID[UUID][paymentIDsList[i]].length == 0){
               continue;
            } else {
            uint256[] memory data = tokenIDwithUUID[UUID][paymentIDsList[i]]; 
            tokenIDwithUUID[newUUID][paymentIDsList[i]] = data;
            }
        }

        return true;
    } 

    function _getTokenIdsLength(bytes memory UUID, bytes memory paymentID) internal view returns(uint256){
        bytes32[] memory paymentIDsList = abi.decode(paymentID, (bytes32[]));
        
        uint256 totalTokens;

        for (uint256 i = 0; i < paymentIDsList.length; i++){
            totalTokens += getUUID_Data(UUID,paymentIDsList[i]).length;
        }

        return totalTokens;
    }

    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                         LOCK FUNCTIONS                              //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////



    function lockNFTs(bytes memory tokenIDs) external onlyOwner{
        require(tokenIDs.length != 0, "null argument.");
        uint256[] memory tokenIDsList = abi.decode(tokenIDs, (uint256[]));

        for(uint i = 0; i < tokenIDsList.length; i++){
            lockedNFTs[tokenIDsList[i]] = true;
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(lockedNFTs[tokenId] == false, "This NFT is locked.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(lockedNFTs[tokenId] == false, 
        "this NFT can't be transferred."
        );
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
        require(lockedNFTs[tokenId] == false, 
        "this NFT can't be transferred."
        );
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }


    /////////////////////////////////////////////////////////////////////////////////////////    
    //                                                                                     //
    //                                         VIEW FUNCTIONS                              //
    //                                                                                     //
    /////////////////////////////////////////////////////////////////////////////////////////

    //overridden function from Context
    function _msgSender() internal view override(Context, Ownable) virtual returns (address) {
        return msg.sender;
    }

      //overridden function from Context
    function _msgData() internal view override(Context, Ownable) virtual returns (bytes calldata) {
        return msg.data;
    }

    
    function getGiftMintedAddresses() public view returns(address[] memory){
        return giftMintedAddresses;
    }
    
    function getNFTMintedAddresses() public view returns(address[] memory){
        return NFTBuyersAddresses;
    }

      function getUUID_Data(bytes memory UUID, bytes32 paymentId) public view returns(uint256[] memory) {
        return tokenIDwithUUID[UUID][paymentId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // if(revealed == false && tokenId <= publicMintLimit){
            if(revealed == false && (tokenId < giftMintId || tokenId > giftMintId + giftMintLimit)){
          // string memory revealedUri = _revealedUri();
            return bytes(notRevealedUri).length > 0 ? string(abi.encodePacked(notRevealedUri)) : "";
        }
        else{
            return bytes(revealedUri).length > 0 ? string(abi.encodePacked(revealedUri, tokenId.toString(),".json")) : "";
        } 
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool matched) {
            return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";


contract Whitelisting is Ownable{

    //1 is for dontVerify
    //2 is for verify
    //3 is for verifyWithSmartContract
    //will denote the method for whitelisting in smart contract

    Ownable ownable;
    
    uint256 public identifier = 0;  // initially set to 0
    bool public registerUserEnabled = false;

    address public deployer;
    

    mapping (address => bool) public VerifyAddressForWhitelisting;  //for identifier 1
    mapping (address => bool) public verifyAddress;  // for identifier 2

    //bytes32[] rootHashesForVerifyUsingContract; //for verifying with identifier 3
    mapping(bytes32 => bool) rootHashesForVerifyUsingContract;   //for verifying with identifier 3

    modifier moduleAccess(uint256 idType){
        require(identifier == idType, "Invalid identifier");
        _;
    }
   
    modifier onlyOwner() override {

        if(address(ownable) != address(0)){
        require(
        ownable.verifyOwner(msg.sender) == true ||
        verifyOwner(msg.sender) == true,
        "Caller is not the Owner."
        );
        } 
        else{
        require(
        verifyOwner(msg.sender) == true,
        "Caller is not the Owner." );
        }
        _;
    }
    

    modifier onlyDeployer() {
        require(msg.sender == deployer, 
        "Caller in not deployer"
        );
        _;
    } 

    constructor() {
        deployer = msg.sender;
    }

    function setOwnable(address ownable_Address) public onlyDeployer{
        // require(msg.sender == deployer);
        ownable = Ownable(ownable_Address);
    }   

    //onlyOwner
    function setWhitelistType(uint256 identifierType) external onlyOwner{
        require (identifierType > 0 && identifierType <= 3, "wrong parameter passed");
        identifier = identifierType;
    }
    
    // Don't verify module start  - identifier 1
    function registerUser(address addr, uint256 id) external moduleAccess(id){
        require(registerUserEnabled == true, "registerUser is disabled.");
        require(VerifyAddressForWhitelisting[addr] == false, "User is already registered");
        VerifyAddressForWhitelisting[addr] = true;
    }
    
    function setRegisterUserEnabled() external onlyOwner{
        registerUserEnabled = !registerUserEnabled;
    }
    // Don't verify module end 

    

    //Verify module start   - identifier 2
    function addAddresses(bytes memory addresses, uint256 id) external moduleAccess(id) onlyOwner {
        address[] memory walletAddressesList = abi.decode(addresses, (address[]));
    
        for(uint i = 0; i < walletAddressesList.length; i++){

        if(walletAddressesList[i] != address(0)){
        verifyAddress[walletAddressesList[i]] = true;
        }
        }
    }

    function statusOfAddress(address addr) external view returns(bool){
        return verifyAddress[addr];
    }
    //Verify module end


    //VerifyWithSmartContract module start - identifier 3
    function addRootHashForVerifyUsingContract(bytes32 newRootHash, uint256 id) external moduleAccess(id) onlyOwner {
        require(newRootHash[0] != 0,  "Empty bytes passed.");
        require(rootHashesForVerifyUsingContract[newRootHash] == false, "Root Hash is already in the list.");       
        rootHashesForVerifyUsingContract[newRootHash] = true;
    }

    function getRootHashesForVerifyUsingContract_status(bytes32 rootHash) public view returns(bool){
        return rootHashesForVerifyUsingContract[rootHash];
    }
    

}