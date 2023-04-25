// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PublicBuildingLib.sol";
import "./ExperienceTCBuilderLib.sol";

library ExperienceBuilderLib {
    string public constant EXPERIENCE_BUILDER_TYPE = "MVREstate:PublicBuildingExpBuilder";

    struct MVREstateExperienceBuilder {
        uint256 tokenId;
        address owner;
        address[] creators;
        address[] eventManagers;
        string vrestateType;
        uint256 pubBuildingID;
        uint256 mainExpTCBuilderId;
        string ipfsURL;
    }

    event NewMVREstateExperienceBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed eventManagers,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 mainExpTCBuilderId,
        string ipfsURL
    );

    event UpdatedMVREstateExperienceBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed eventManagers,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 mainExpTCBuilderId,
        string ipfsURL
    );

    error BadOwnerAddress();
    error BadCreatorsAddresses();
    error BadPublicBuildingID();
    error BadIpfsURL();
    error InvalidExpBuilder();
    error ExpBuilderDoNotExist();
    error NotAuthToCreateExpBuilder();

    function isValid(
        MVREstateExperienceBuilder memory newExperience,
        mapping(uint256 => PublicBuildingLib.MVREstatePublicBuilding) storage publicBuildings
    ) public view returns (bool) {
        if (newExperience.owner == address(0)) {
            revert BadOwnerAddress();
        }

        if (newExperience.creators.length == 0) {
            revert BadCreatorsAddresses();
        }

        // Looping in Solidity cost lot of gas, see if not too expensive here.
        for (uint i = 0; i < newExperience.creators.length; i++) {
            if (newExperience.creators[i] == address(0)) {
                revert BadCreatorsAddresses();
            }
        }

        // Est-ce qu'on est sur qu'on veut pas que l'ID soit après, dans le cas où le public building est reconstruit et mint après par exemple mais garde la même expérience ?
        if (newExperience.pubBuildingID >= newExperience.tokenId) {
            revert BadPublicBuildingID();
        }

        if (bytes(newExperience.ipfsURL).length == 0) {
            revert BadIpfsURL();
        }

        // Check la validité de l'url ipfs autre que length != 0?

        PublicBuildingLib.MVREstatePublicBuilding memory pubBuilding = publicBuildings[newExperience.pubBuildingID];

        if (pubBuilding.owner == address(0)) {
            revert PublicBuildingLib.PublicBuildingDoNotExist();
        }

        bool isAuthorizedToCreateExpBuilder = pubBuilding.owner == newExperience.owner;

        if (!isAuthorizedToCreateExpBuilder) {
            if (pubBuilding.expCreators.length != 0) {
                for (uint256 i = 0; i < pubBuilding.expCreators.length; i++) {
                    // On check si y'a pas l'address de l'owner dans les expCreators. Si c'est le cas on alloue l'authorisation à tout le monde.
                    // Faire des mappings "isAuth" sur les différentes vérifs coute moins de gas ou pas ?
                    if (
                        pubBuilding.expCreators[i] == newExperience.owner ||
                        pubBuilding.expCreators[i] == pubBuilding.owner
                    ) {
                        isAuthorizedToCreateExpBuilder = true;
                        break;
                    }
                }
            }
        }

        if (!isAuthorizedToCreateExpBuilder) {
            revert NotAuthToCreateExpBuilder();
        }

        return true;
    }

    function checkUpdateMVRESExperienceBuilder(
        MVREstateExperienceBuilder memory updatedExperience,
        mapping(uint256 => PublicBuildingLib.MVREstatePublicBuilding) storage publicBuildings,
        mapping(uint256 => MVREstateExperienceBuilder) storage experienceBuilders,
        mapping(uint256 => ExperienceTCBuilderLib.MVREstateExperienceTCBuilder) storage experienceTCBuilders
    ) public returns (bool) {
        ExperienceBuilderLib.MVREstateExperienceBuilder memory previousExperience = experienceBuilders[
            updatedExperience.tokenId
        ];

        if (previousExperience.owner == address(0)) {
            revert ExpBuilderDoNotExist();
        }

        if (previousExperience.owner != msg.sender) {
            revert NotAuthToCreateExpBuilder();
        }

        if (previousExperience.owner != updatedExperience.owner) {
            revert InvalidExpBuilder();
        }

        if (keccak256(bytes(updatedExperience.vrestateType)) != keccak256(bytes(EXPERIENCE_BUILDER_TYPE))) {
            revert InvalidExpBuilder();
        }

        // This library has access to publicBuildings mapping ?
        PublicBuildingLib.MVREstatePublicBuilding memory pubBuilding = publicBuildings[updatedExperience.pubBuildingID];

        if (pubBuilding.owner == address(0)) {
            revert PublicBuildingLib.PublicBuildingDoNotExist();
        }

        // We check authorization to mint (are modifiers or openzeppelin roles better for that ?)
        bool isAuthorizedToCreateExpBuilder = pubBuilding.owner == updatedExperience.owner;

        if (!isAuthorizedToCreateExpBuilder) {
            if (pubBuilding.expCreators.length != 0) {
                for (uint256 i = 0; i < pubBuilding.expCreators.length; i++) {
                    if (
                        pubBuilding.expCreators[i] == updatedExperience.owner ||
                        pubBuilding.expCreators[i] == pubBuilding.owner
                    ) {
                        isAuthorizedToCreateExpBuilder = true;
                        break;
                    }
                }
            }
        }

        if (!isAuthorizedToCreateExpBuilder) {
            revert NotAuthToCreateExpBuilder();
        }

        if (previousExperience.mainExpTCBuilderId != updatedExperience.mainExpTCBuilderId) {
            if (experienceTCBuilders[updatedExperience.mainExpTCBuilderId].owner != address(0)) {
                experienceTCBuilders[previousExperience.mainExpTCBuilderId].isMain = false;

                experienceTCBuilders[updatedExperience.mainExpTCBuilderId].isMain = true;
            } else {
                revert ExperienceTCBuilderLib.ExpTCBuilderDoNotExist();
            }
        }

        // Laisser l'owner pouvoir modifier tous les champs et les métadonnées comme ça ? Pas de prbl s'il change bcp son Experience NFT ? Quels prbl sur les ExpTCBuilder ?

        if (!isValid(updatedExperience, publicBuildings)) {
            revert InvalidExpBuilder();
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PublicBuildingLib.sol";
import "./ExperienceBuilderLib.sol";

library ExperienceTCBuilderLib {
    string public constant EXPERIENCE_TC_BUILDER_TYPE = "MVREstate:PublicBuildingTCExpBuilder";

    struct MVREstateExperienceTCBuilder {
        uint256 tokenId;
        address owner;
        address[] creators;
        string vrestateType;
        uint256 pubBuildingID;
        uint256 expBuilderID;
        bool isMain;
        string ipfsURL;
    }

    event NewMVREstateExperienceTCBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 indexed expBuilderID,
        bool isMain,
        string ipfsURL
    );

    event UpdatedMVREstateExperienceTCBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 indexed expBuilderID,
        bool isMain,
        string ipfsURL
    );

    error BadOwnerAddress();
    error BadCreatorsAddresses();
    error BadPublicBuildingID();
    error BadExpBuilderID();
    error BadIpfsURL();
    error InvalidExpTCBuilder();
    error ExpTCBuilderDoNotExist();
    error NotAuthToCreateExpTCBuilder();

    function isValid(
        MVREstateExperienceTCBuilder memory newExpTCBuilder,
        mapping(uint256 => PublicBuildingLib.MVREstatePublicBuilding) storage publicBuildings,
        mapping(uint256 => ExperienceBuilderLib.MVREstateExperienceBuilder) storage experienceBuilders
    ) public view returns (bool) {
        if (newExpTCBuilder.owner == address(0)) {
            revert BadOwnerAddress();
        }

        if (newExpTCBuilder.creators.length == 0) {
            revert BadCreatorsAddresses();
        }

        // Looping in Solidity cost lot of gas, see if not too expensive here.
        for (uint i = 0; i < newExpTCBuilder.creators.length; i++) {
            if (newExpTCBuilder.creators[i] == address(0)) {
                revert BadCreatorsAddresses();
            }
        }

        // Est-ce qu'on est sur qu'on veut pas que l'ID soit après, dans le cas où le public building est reconstruit et mint après par exemple mais garde la même TC expérience ?
        if (newExpTCBuilder.pubBuildingID >= newExpTCBuilder.tokenId) {
            revert BadPublicBuildingID();
        }

        // Est-ce qu'on est sur qu'on veut pas que l'ID soit après, dans le cas où l'experience builder est reconstruit et mint après par exemple mais garde la même TC expérience ?
        if (newExpTCBuilder.expBuilderID >= newExpTCBuilder.tokenId) {
            revert BadPublicBuildingID();
        }

        if (bytes(newExpTCBuilder.ipfsURL).length == 0) {
            revert BadIpfsURL();
        }

        // Check la validité de l'url ipfs autre que length != 0?

        PublicBuildingLib.MVREstatePublicBuilding memory pubBuilding = publicBuildings[newExpTCBuilder.pubBuildingID];

        ExperienceBuilderLib.MVREstateExperienceBuilder memory expBuilder = experienceBuilders[
            newExpTCBuilder.expBuilderID
        ];

        if (pubBuilding.owner == address(0)) {
            revert PublicBuildingLib.PublicBuildingDoNotExist();
        }

        if (expBuilder.owner == address(0)) {
            revert ExperienceBuilderLib.ExpBuilderDoNotExist();
        }

        if (expBuilder.pubBuildingID != pubBuilding.tokenId) {
            revert PublicBuildingLib.InvalidPublicBuilding();
        }

        bool isAuthorizedToCreateExpTCBuilder = expBuilder.owner == newExpTCBuilder.owner;

        if (!isAuthorizedToCreateExpTCBuilder) {
            if (expBuilder.eventManagers.length != 0) {
                for (uint256 i = 0; i < expBuilder.eventManagers.length; i++) {
                    if (
                        expBuilder.eventManagers[i] == newExpTCBuilder.owner ||
                        expBuilder.eventManagers[i] == expBuilder.owner
                    ) {
                        isAuthorizedToCreateExpTCBuilder = true;
                        break;
                    }
                }
            }
        }

        if (!isAuthorizedToCreateExpTCBuilder) {
            revert NotAuthToCreateExpTCBuilder();
        }

        return true;
    }

    function checkUpdateMVRESExperienceTCBuilder(
        MVREstateExperienceTCBuilder memory updatedExpTCBuilder,
        mapping(uint256 => PublicBuildingLib.MVREstatePublicBuilding) storage publicBuildings,
        mapping(uint256 => ExperienceBuilderLib.MVREstateExperienceBuilder) storage experienceBuilders,
        mapping(uint256 => MVREstateExperienceTCBuilder) storage experienceTCBuilders
    ) public returns (bool) {
        MVREstateExperienceTCBuilder memory previousExpTCBuilder = experienceTCBuilders[updatedExpTCBuilder.tokenId];

        if (previousExpTCBuilder.owner == address(0)) {
            revert ExpTCBuilderDoNotExist();
        }

        if (previousExpTCBuilder.owner != msg.sender) {
            revert NotAuthToCreateExpTCBuilder();
        }

        if (previousExpTCBuilder.owner != updatedExpTCBuilder.owner) {
            revert InvalidExpTCBuilder();
        }

        if (keccak256(bytes(updatedExpTCBuilder.vrestateType)) != keccak256(bytes(EXPERIENCE_TC_BUILDER_TYPE))) {
            revert InvalidExpTCBuilder();
        }

        PublicBuildingLib.MVREstatePublicBuilding memory pubBuilding = publicBuildings[
            updatedExpTCBuilder.pubBuildingID
        ];

        ExperienceBuilderLib.MVREstateExperienceBuilder memory expBuilder = experienceBuilders[
            updatedExpTCBuilder.expBuilderID
        ];

        if (pubBuilding.owner == address(0)) {
            revert PublicBuildingLib.PublicBuildingDoNotExist();
        }

        if (expBuilder.owner == address(0)) {
            revert ExperienceBuilderLib.ExpBuilderDoNotExist();
        }

        if (expBuilder.pubBuildingID != pubBuilding.tokenId) {
            revert InvalidExpTCBuilder();
        }

        // We check authorization to mint (are modifiers or openzeppelin roles better for that ? Maybe not for the if "any")
        bool isAuthorizedToCreateExpTCBuilder = expBuilder.owner == updatedExpTCBuilder.owner;

        if (!isAuthorizedToCreateExpTCBuilder) {
            if (expBuilder.eventManagers.length != 0) {
                for (uint256 i = 0; i < expBuilder.eventManagers.length; i++) {
                    // On check si y'a pas l'address de l'owner dans les eventmanager. Si c'est le cas on alloue l'authorisation à tout le monde.
                    if (
                        expBuilder.eventManagers[i] == updatedExpTCBuilder.owner ||
                        expBuilder.eventManagers[i] == expBuilder.owner
                    ) {
                        isAuthorizedToCreateExpTCBuilder = true;
                        break;
                    }
                }
            }
        }

        if (!isAuthorizedToCreateExpTCBuilder) {
            revert NotAuthToCreateExpTCBuilder();
        }

        if (updatedExpTCBuilder.isMain) {
            if (expBuilder.owner == updatedExpTCBuilder.owner) {
                if (
                    experienceTCBuilders[experienceBuilders[updatedExpTCBuilder.expBuilderID].mainExpTCBuilderId]
                        .tokenId != updatedExpTCBuilder.tokenId
                ) {
                    experienceTCBuilders[experienceBuilders[updatedExpTCBuilder.expBuilderID].mainExpTCBuilderId]
                        .isMain = false;
                    experienceBuilders[updatedExpTCBuilder.expBuilderID].mainExpTCBuilderId = updatedExpTCBuilder
                        .tokenId;
                }
            } else {
                revert NotAuthToCreateExpTCBuilder();
            }
        }

        if (!isValid(updatedExpTCBuilder, publicBuildings, experienceBuilders)) {
            revert InvalidExpTCBuilder();
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PublicBuildingLib {
    string public constant PUBLIC_BUILDING_TYPE = "MVREstate:PublicBuilding";

    struct MVREstatePublicBuilding {
        uint256 tokenId;
        address owner;
        address[] creators;
        address[] expCreators;
        string vrestateType;
        string ipfsURL;
        // Do we add the 3D Map URL on chain here or in IPFS ?
    }

    event NewMVRESPublicBuildingEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed expCreators,
        string vrestateType,
        string ipfsURL
    );

    event UpdatedMVRESPublicBuildingEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed expCreators,
        string vrestateType,
        string ipfsURL
    );

    error BadOwnerAddress();
    error BadCreatorsAddresses();
    error BadIpfsURL();
    error InvalidPublicBuilding();
    error PublicBuildingDoNotExist();

    function isValid(MVREstatePublicBuilding memory building) public pure returns (bool) {
        if (building.owner == address(0)) {
            revert BadOwnerAddress();
        }

        if (building.creators.length == 0) {
            revert BadCreatorsAddresses();
        }

        // Looping in Solidity cost lot of gas, see if not too expensive here.
        for (uint i = 0; i < building.creators.length; i++) {
            if (building.creators[i] == address(0)) {
                revert BadCreatorsAddresses();
            }
        }

        if (bytes(building.ipfsURL).length == 0) {
            revert BadIpfsURL();
        }

        return true;
    }

    function checkUpdateMVRESPublicBuilding(
        MVREstatePublicBuilding memory updatedBuilding,
        mapping(uint256 => MVREstatePublicBuilding) storage publicBuildings
    ) public view returns (bool) {
        MVREstatePublicBuilding memory previousBuilding = publicBuildings[updatedBuilding.tokenId];

        if (previousBuilding.owner == address(0)) {
            revert PublicBuildingDoNotExist();
        }

        if (previousBuilding.owner != msg.sender) {
            revert InvalidPublicBuilding();
        }

        if (previousBuilding.owner != updatedBuilding.owner) {
            revert InvalidPublicBuilding();
        }

        if (keccak256(bytes(updatedBuilding.vrestateType)) != keccak256(bytes(PUBLIC_BUILDING_TYPE))) {
            revert InvalidPublicBuilding();
        }

        if (!isValid(updatedBuilding)) {
            revert InvalidPublicBuilding();
        }

        return true;
    }

    // tx.gasprice (uint): gas price of the transaction : See if we can choose more or less verif according to the gasprice
    // (Maybe security issues when passing false arguments during high gasprice for less verif ?)
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PublicBuildingLib.sol";
import "./ExperienceBuilderLib.sol";
import "./ExperienceTCBuilderLib.sol";

contract VREstate is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => PublicBuildingLib.MVREstatePublicBuilding) public publicBuildings;

    mapping(uint256 => ExperienceBuilderLib.MVREstateExperienceBuilder) public experienceBuilders;

    mapping(uint256 => ExperienceTCBuilderLib.MVREstateExperienceTCBuilder) public experienceTCBuilders;

    event NewMVRESPublicBuildingEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed expCreators,
        string vrestateType,
        string ipfsURL
    );

    event UpdatedMVRESPublicBuildingEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed expCreators,
        string vrestateType,
        string ipfsURL
    );

    event NewMVREstateExperienceBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed eventManagers,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 mainExpTCBuilderId,
        string ipfsURL
    );

    event UpdatedMVREstateExperienceBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        address[] indexed eventManagers,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 mainExpTCBuilderId,
        string ipfsURL
    );

    event NewMVREstateExperienceTCBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 indexed expBuilderID,
        bool isMain,
        string ipfsURL
    );

    event UpdatedMVREstateExperienceTCBuilderEvent(
        uint256 tokenId,
        address indexed owner,
        address[] indexed creators,
        string vrestateType,
        uint256 pubBuildingID,
        uint256 indexed expBuilderID,
        bool isMain,
        string ipfsURL
    );

    constructor() ERC721("VREstate", "VRE") {}

    /*
    event Test(string success);

    function TestFunc(string memory _string) public {
        emit Test(_string);
    }*/

    // Gérer le tokenURI pour IPFS

    function NewMVRESPublicBuilding(
        address[] memory _creators,
        address[] memory _expCreators,
        string memory _ipfsURL
    ) public {
        // Laisser la fonction de mint ouverte à n'importe qui ?
        uint256 tokenId = _tokenIds.current();

        PublicBuildingLib.MVREstatePublicBuilding memory newBuilding = PublicBuildingLib.MVREstatePublicBuilding(
            tokenId,
            msg.sender,
            _creators,
            _expCreators,
            PublicBuildingLib.PUBLIC_BUILDING_TYPE,
            _ipfsURL
        );

        if (!PublicBuildingLib.isValid(newBuilding)) {
            revert PublicBuildingLib.InvalidPublicBuilding();
        }

        // Check la validité de l'url ipfs autre que length != 0 ?

        // What if someone copy/paste 3D map & datas and create a new identical Public Building ? Is that really a prbl for us ?

        _safeMint(msg.sender, tokenId);

        publicBuildings[tokenId] = newBuilding;

        _tokenIds.increment();

        emit PublicBuildingLib.NewMVRESPublicBuildingEvent(
            tokenId,
            msg.sender,
            _creators,
            _expCreators,
            PublicBuildingLib.PUBLIC_BUILDING_TYPE,
            _ipfsURL
        );
    }

    function updateMVRESPublicBuilding(PublicBuildingLib.MVREstatePublicBuilding memory updatedBuilding) public {
        if (!PublicBuildingLib.checkUpdateMVRESPublicBuilding(updatedBuilding, publicBuildings)) {
            revert PublicBuildingLib.InvalidPublicBuilding();
        }

        publicBuildings[updatedBuilding.tokenId] = updatedBuilding;

        emit PublicBuildingLib.UpdatedMVRESPublicBuildingEvent(
            updatedBuilding.tokenId,
            updatedBuilding.owner,
            updatedBuilding.creators,
            updatedBuilding.expCreators,
            updatedBuilding.vrestateType,
            updatedBuilding.ipfsURL
        );
    }

    function GetMVRESPublicBuildingByID(
        uint256 _tokenId
    ) public view returns (PublicBuildingLib.MVREstatePublicBuilding memory) {
        return publicBuildings[_tokenId];
    }

    function NewMVRESPublicBuildingExpBuilder(
        address[] memory _creators,
        address[] memory _eventManagers,
        uint256 _pubBuildingID,
        uint256 _mainExpTCBuilderId,
        string memory _ipfsURL
    ) public {
        // Laisser la fonction de mint ouverte à n'importe qui ?

        // Dans le Subgraph rajouter aux Owners/Creators etc le building associé à cet évènement et pareil pour les autres, bien voir toutes les intéractions.
        uint256 tokenId = _tokenIds.current();

        ExperienceBuilderLib.MVREstateExperienceBuilder memory newExperience = ExperienceBuilderLib
            .MVREstateExperienceBuilder(
                tokenId,
                msg.sender,
                _creators,
                _eventManagers,
                ExperienceBuilderLib.EXPERIENCE_BUILDER_TYPE,
                _pubBuildingID,
                _mainExpTCBuilderId,
                _ipfsURL
            );

        if (!ExperienceBuilderLib.isValid(newExperience, publicBuildings)) {
            revert ExperienceBuilderLib.InvalidExpBuilder();
        }

        _safeMint(msg.sender, tokenId);

        experienceBuilders[tokenId] = newExperience;

        _tokenIds.increment();

        emit ExperienceBuilderLib.NewMVREstateExperienceBuilderEvent(
            tokenId,
            msg.sender,
            _creators,
            _eventManagers,
            ExperienceBuilderLib.EXPERIENCE_BUILDER_TYPE,
            _pubBuildingID,
            _mainExpTCBuilderId,
            _ipfsURL
        );
    }

    function updateMVRESPublicBuildingExpBuilder(
        ExperienceBuilderLib.MVREstateExperienceBuilder memory updatedExperience
    ) public {
        if (
            !ExperienceBuilderLib.checkUpdateMVRESExperienceBuilder(
                updatedExperience,
                publicBuildings,
                experienceBuilders,
                experienceTCBuilders
            )
        ) {
            revert ExperienceBuilderLib.InvalidExpBuilder();
        }

        experienceBuilders[updatedExperience.tokenId] = updatedExperience;

        emit ExperienceBuilderLib.UpdatedMVREstateExperienceBuilderEvent(
            updatedExperience.tokenId,
            updatedExperience.owner,
            updatedExperience.creators,
            updatedExperience.eventManagers,
            updatedExperience.vrestateType,
            updatedExperience.pubBuildingID,
            updatedExperience.mainExpTCBuilderId,
            updatedExperience.ipfsURL
        );
    }

    function GetMVRESPublicBuildingExpBuilderByID(
        uint256 _tokenId
    ) public view returns (ExperienceBuilderLib.MVREstateExperienceBuilder memory) {
        return experienceBuilders[_tokenId];
    }

    function NewMVRESPublicBuildingExpTCBuilder(
        address[] memory _creators,
        uint256 _pubBuildingID,
        uint256 _expBuilderID,
        bool _isMain,
        string memory _ipfsURL
    ) public {
        // Laisser la fonction de mint ouverte à n'importe qui ?
        uint256 tokenId = _tokenIds.current();

        ExperienceTCBuilderLib.MVREstateExperienceTCBuilder memory newExpTCBuilder = ExperienceTCBuilderLib
            .MVREstateExperienceTCBuilder(
                tokenId,
                msg.sender,
                _creators,
                ExperienceTCBuilderLib.EXPERIENCE_TC_BUILDER_TYPE,
                _pubBuildingID,
                _expBuilderID,
                _isMain,
                _ipfsURL
            );

        if (!ExperienceTCBuilderLib.isValid(newExpTCBuilder, publicBuildings, experienceBuilders)) {
            revert ExperienceTCBuilderLib.InvalidExpTCBuilder();
        }

        _safeMint(msg.sender, tokenId);

        ExperienceBuilderLib.MVREstateExperienceBuilder memory expBuilder = experienceBuilders[
            newExpTCBuilder.expBuilderID
        ];

        if (expBuilder.owner == newExpTCBuilder.owner && _isMain) {
            experienceTCBuilders[expBuilder.mainExpTCBuilderId].isMain = false;
            expBuilder.mainExpTCBuilderId = tokenId;
        } else {
            newExpTCBuilder.isMain = false;
        }

        experienceTCBuilders[tokenId] = newExpTCBuilder;

        _tokenIds.increment();

        emit ExperienceTCBuilderLib.NewMVREstateExperienceTCBuilderEvent(
            tokenId,
            msg.sender,
            _creators,
            ExperienceTCBuilderLib.EXPERIENCE_TC_BUILDER_TYPE,
            _pubBuildingID,
            _expBuilderID,
            newExpTCBuilder.isMain,
            _ipfsURL
        );
    }

    function updateMVRESPublicBuildingExpTCBuilder(
        ExperienceTCBuilderLib.MVREstateExperienceTCBuilder memory updatedExpTCBuilder
    ) public {
        if (
            !ExperienceTCBuilderLib.checkUpdateMVRESExperienceTCBuilder(
                updatedExpTCBuilder,
                publicBuildings,
                experienceBuilders,
                experienceTCBuilders
            )
        ) {
            revert ExperienceTCBuilderLib.InvalidExpTCBuilder();
        }

        experienceTCBuilders[updatedExpTCBuilder.tokenId] = updatedExpTCBuilder;

        emit ExperienceTCBuilderLib.UpdatedMVREstateExperienceTCBuilderEvent(
            updatedExpTCBuilder.tokenId,
            updatedExpTCBuilder.owner,
            updatedExpTCBuilder.creators,
            updatedExpTCBuilder.vrestateType,
            updatedExpTCBuilder.pubBuildingID,
            updatedExpTCBuilder.expBuilderID,
            updatedExpTCBuilder.isMain,
            updatedExpTCBuilder.ipfsURL
        );
    }

    function GetMVRESPublicBuildingExpTCBuilderByID(
        uint256 _tokenId
    ) public view returns (ExperienceTCBuilderLib.MVREstateExperienceTCBuilder memory) {
        return experienceTCBuilders[_tokenId];
    }
}