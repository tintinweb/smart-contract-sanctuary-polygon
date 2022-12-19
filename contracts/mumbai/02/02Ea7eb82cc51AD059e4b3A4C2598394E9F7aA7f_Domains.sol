// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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

//SPDX-License-Identifier: MIT
//Signity is a name service platform created for EVM chains by Ebuka, lead contributor at Payrave.
//Forking without asking our permission kind of sucks, since we'll give the permission anyway. Send a request to [email protected] and get a reply in under an hour.

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "../libraries/StringUtils.sol";
import {Base64} from "../libraries/Base64.sol";

pragma solidity ^0.8.7;

contract Domains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld; //our top-level domain, ie .payrave

    string svgPartOne =
        '<svg width="270" height="270" viewBox="0 0 270 270" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="270" height="270" fill="url(#paint0_linear_2145_335)"/><path d="M25.7954 24.6448C27.2098 23.146 28.0027 21.1159 28 19.0003C27.9985 18.8698 27.9483 18.745 27.8603 18.6533C27.7723 18.5615 27.6536 18.51 27.5299 18.51C27.4062 18.51 27.2875 18.5615 27.1994 18.6533C27.1114 18.745 27.0613 18.8698 27.0598 19.0003C27.0618 20.8543 26.3665 22.6334 25.1268 23.9466C24.525 24.5988 23.8056 25.1172 23.0109 25.4712C22.2162 25.8251 21.3624 26.0075 20.4999 26.0075C19.6374 26.0075 18.7836 25.8251 17.989 25.4712C17.1943 25.1172 16.4748 24.5988 15.873 23.9466C14.635 22.6321 13.9401 20.8537 13.9401 19C13.9401 17.1463 14.635 15.368 15.873 14.0534C16.4713 13.4062 17.1854 12.8908 17.9738 12.5371C18.7622 12.1834 19.6093 11.9985 20.466 11.993C20.6489 11.999 20.8223 12.0802 20.9493 12.2194C21.0763 12.3585 21.1467 12.5444 21.1456 12.7376C21.1446 12.9308 21.0721 13.1159 20.9436 13.2534C20.8151 13.391 20.6408 13.4701 20.4578 13.4739C20.4409 13.4739 20.4239 13.4749 20.4071 13.4768C19.1038 13.5211 17.8672 14.0956 16.9558 15.0801C15.9933 16.1029 15.4532 17.486 15.4532 18.9276C15.4532 20.3693 15.9933 21.7524 16.9558 22.7752C17.426 23.2836 17.9878 23.6876 18.6081 23.9635C19.2284 24.2393 19.8948 24.3814 20.5679 24.3814C21.2409 24.3814 21.9073 24.2393 22.5276 23.9635C23.1479 23.6876 23.7097 23.2836 24.1799 22.7752C25.1438 21.7534 25.6842 20.3696 25.6823 18.9276C25.6843 18.7005 25.6436 18.4751 25.5627 18.2647C25.4817 18.0543 25.362 17.8628 25.2105 17.7015C25.059 17.5401 24.8788 17.412 24.6802 17.3246C24.4816 17.2372 24.2686 17.1922 24.0534 17.1922C23.8382 17.1922 23.6251 17.2372 23.4265 17.3246C23.2279 17.412 23.0477 17.5401 22.8962 17.7015C22.7447 17.8628 22.6251 18.0543 22.5441 18.2647C22.4631 18.4751 22.4224 18.7005 22.4244 18.9276C22.4244 18.9421 22.4253 18.9557 22.4264 18.9696C22.4253 18.9835 22.4244 18.9974 22.4244 19.0116C22.4275 19.4076 22.3191 19.7956 22.1128 20.1265C21.9067 20.4573 21.612 20.716 21.2663 20.8699C20.9206 21.0236 20.5394 21.0655 20.1711 20.9903C19.8028 20.915 19.464 20.726 19.1976 20.4471C18.9312 20.1682 18.7494 19.8121 18.675 19.4239C18.6007 19.0357 18.6373 18.633 18.7802 18.2669C18.923 17.9006 19.1657 17.5875 19.4774 17.3671C19.7891 17.1468 20.1558 17.0291 20.5309 17.0291C20.5932 17.0299 20.6549 17.0177 20.7126 16.9931C20.7703 16.9685 20.8228 16.9321 20.867 16.8859C20.9113 16.8398 20.9465 16.7848 20.9704 16.7242C20.9944 16.6636 21.0068 16.5985 21.0068 16.5329C21.0068 16.4672 20.9944 16.4022 20.9704 16.3416C20.9465 16.2809 20.9113 16.226 20.867 16.1798C20.8228 16.1337 20.7703 16.0972 20.7126 16.0726C20.6549 16.0481 20.5932 16.0358 20.5309 16.0366C19.9742 16.0399 19.4308 16.2171 18.9694 16.546C18.508 16.8749 18.1492 17.3407 17.9383 17.8846C17.7274 18.4285 17.6738 19.0262 17.7843 19.6022C17.8948 20.1782 18.1645 20.7068 18.5593 21.1212C18.954 21.5356 19.4562 21.8173 20.0025 21.9308C20.5488 22.0442 21.1147 21.9843 21.6288 21.7587C22.1428 21.533 22.5821 21.1517 22.8911 20.6628C23.2001 20.1739 23.3649 19.5993 23.3649 19.0116C23.3649 18.9971 23.364 18.9835 23.3629 18.9696C23.364 18.9557 23.3649 18.9418 23.3649 18.9276C23.3631 18.8309 23.3795 18.7348 23.4134 18.6449C23.4471 18.555 23.4976 18.4731 23.5617 18.4041C23.6258 18.335 23.7024 18.2801 23.7868 18.2427C23.8713 18.2052 23.9621 18.1859 24.0536 18.1859C24.1452 18.1859 24.236 18.2052 24.3205 18.2427C24.4049 18.2801 24.4815 18.335 24.5456 18.4041C24.6097 18.4731 24.6602 18.555 24.6939 18.6449C24.7278 18.7348 24.7442 18.8309 24.7424 18.9276C24.7436 20.1082 24.3009 21.241 23.5115 22.0772C23.1287 22.4924 22.6711 22.8222 22.1655 23.0475C21.66 23.2728 21.1168 23.3888 20.568 23.3888C20.0193 23.3888 19.4761 23.2728 18.9705 23.0475C18.465 22.8222 18.0073 22.4924 17.6246 22.0772C16.8362 21.2403 16.3937 20.1079 16.3937 18.9276C16.3937 17.7473 16.8362 16.615 17.6246 15.778C18.0076 15.3634 18.4653 15.0338 18.9707 14.8086C19.4761 14.5834 20.0191 14.467 20.5677 14.4664C20.6099 14.4663 20.6519 14.4601 20.6926 14.4481C21.0928 14.3833 21.4562 14.1648 21.7132 13.8346C21.9702 13.5043 22.1026 13.0855 22.085 12.6585C22.0675 12.2315 21.9011 11.8263 21.618 11.5208C21.3348 11.2153 20.9548 11.0309 20.5508 11.003C20.534 11.001 20.5169 11 20.4999 11C20.4905 11 20.4811 11 20.4716 11C20.4669 11 20.4624 11 20.4579 11C20.4533 11 20.4487 11.0006 20.4442 11.0007C19.4668 11.0088 18.5007 11.2211 17.6014 11.6252C16.7021 12.0294 15.8876 12.6175 15.2046 13.3555C13.7925 14.8559 13 16.885 13 19C13 21.115 13.7925 23.1441 15.2046 24.6445C15.8939 25.39 16.7174 25.9826 17.6269 26.387C18.5363 26.7916 19.5132 27 20.5001 27C21.4869 27 22.4638 26.7916 23.3733 26.387C24.2827 25.9826 25.1063 25.39 25.7955 24.6445L25.7954 24.6448Z" fill="white"/><path d="M33.12 17.52C33.2933 17.78 33.5133 17.9733 33.78 18.1C34.0533 18.22 34.3333 18.28 34.62 18.28C34.78 18.28 34.9433 18.2567 35.11 18.21C35.2767 18.1567 35.4267 18.08 35.56 17.98C35.7 17.88 35.8133 17.7567 35.9 17.61C35.9867 17.4633 36.03 17.2933 36.03 17.1C36.03 16.8267 35.9433 16.62 35.77 16.48C35.5967 16.3333 35.38 16.2133 35.12 16.12C34.8667 16.02 34.5867 15.9267 34.28 15.84C33.98 15.7467 33.7 15.62 33.44 15.46C33.1867 15.3 32.9733 15.0867 32.8 14.82C32.6267 14.5467 32.54 14.18 32.54 13.72C32.54 13.5133 32.5833 13.2933 32.67 13.06C32.7633 12.8267 32.9067 12.6133 33.1 12.42C33.2933 12.2267 33.54 12.0667 33.84 11.94C34.1467 11.8067 34.5133 11.74 34.94 11.74C35.3267 11.74 35.6967 11.7933 36.05 11.9C36.4033 12.0067 36.7133 12.2233 36.98 12.55L36.2 13.26C36.08 13.0733 35.91 12.9233 35.69 12.81C35.47 12.6967 35.22 12.64 34.94 12.64C34.6733 12.64 34.45 12.6767 34.27 12.75C34.0967 12.8167 33.9567 12.9067 33.85 13.02C33.7433 13.1267 33.6667 13.2433 33.62 13.37C33.58 13.4967 33.56 13.6133 33.56 13.72C33.56 14.02 33.6467 14.25 33.82 14.41C33.9933 14.57 34.2067 14.7 34.46 14.8C34.72 14.9 35 14.99 35.3 15.07C35.6067 15.15 35.8867 15.2633 36.14 15.41C36.4 15.55 36.6167 15.7433 36.79 15.99C36.9633 16.23 37.05 16.5633 37.05 16.99C37.05 17.33 36.9833 17.6367 36.85 17.91C36.7233 18.1833 36.55 18.4133 36.33 18.6C36.11 18.7867 35.85 18.93 35.55 19.03C35.25 19.13 34.93 19.18 34.59 19.18C34.1367 19.18 33.7067 19.1 33.3 18.94C32.8933 18.78 32.57 18.5333 32.33 18.2L33.12 17.52ZM38.3066 14.26H39.2066V19H38.3066V14.26ZM38.0966 12.56C38.0966 12.38 38.16 12.2267 38.2866 12.1C38.42 11.9667 38.5766 11.9 38.7566 11.9C38.9366 11.9 39.09 11.9667 39.2166 12.1C39.35 12.2267 39.4166 12.38 39.4166 12.56C39.4166 12.74 39.35 12.8967 39.2166 13.03C39.09 13.1567 38.9366 13.22 38.7566 13.22C38.5766 13.22 38.42 13.1567 38.2866 13.03C38.16 12.8967 38.0966 12.74 38.0966 12.56ZM45.389 18.96C45.389 19.32 45.3257 19.6467 45.199 19.94C45.079 20.24 44.9057 20.4967 44.679 20.71C44.4523 20.93 44.179 21.1 43.859 21.22C43.539 21.34 43.1857 21.4 42.799 21.4C42.3457 21.4 41.929 21.3367 41.549 21.21C41.1757 21.0833 40.819 20.8633 40.479 20.55L41.089 19.79C41.3223 20.0433 41.5757 20.2333 41.849 20.36C42.1223 20.4933 42.4323 20.56 42.779 20.56C43.1123 20.56 43.389 20.51 43.609 20.41C43.829 20.3167 44.0023 20.1933 44.129 20.04C44.2623 19.8867 44.3557 19.71 44.409 19.51C44.4623 19.3167 44.489 19.12 44.489 18.92V18.22H44.459C44.2857 18.5067 44.049 18.72 43.749 18.86C43.4557 18.9933 43.1457 19.06 42.819 19.06C42.4723 19.06 42.149 19 41.849 18.88C41.5557 18.7533 41.3023 18.5833 41.089 18.37C40.8757 18.15 40.709 17.8933 40.589 17.6C40.469 17.3 40.409 16.9767 40.409 16.63C40.409 16.2833 40.4657 15.96 40.579 15.66C40.6923 15.3533 40.8523 15.0867 41.059 14.86C41.2723 14.6333 41.5257 14.4567 41.819 14.33C42.119 14.2033 42.4523 14.14 42.819 14.14C43.139 14.14 43.449 14.21 43.749 14.35C44.0557 14.49 44.2957 14.6867 44.469 14.94H44.489V14.26H45.389V18.96ZM42.929 14.98C42.689 14.98 42.4723 15.0233 42.279 15.11C42.0857 15.19 41.9223 15.3033 41.789 15.45C41.6557 15.59 41.5523 15.7633 41.479 15.97C41.4057 16.17 41.369 16.39 41.369 16.63C41.369 17.11 41.509 17.4967 41.789 17.79C42.069 18.0767 42.449 18.22 42.929 18.22C43.409 18.22 43.789 18.0767 44.069 17.79C44.349 17.4967 44.489 17.11 44.489 16.63C44.489 16.39 44.4523 16.17 44.379 15.97C44.3057 15.7633 44.2023 15.59 44.069 15.45C43.9357 15.3033 43.7723 15.19 43.579 15.11C43.3857 15.0233 43.169 14.98 42.929 14.98ZM46.7523 14.26H47.6523V14.99H47.6723C47.7856 14.7367 47.9823 14.5333 48.2623 14.38C48.5423 14.22 48.8656 14.14 49.2323 14.14C49.4589 14.14 49.6756 14.1767 49.8823 14.25C50.0956 14.3167 50.2789 14.4233 50.4323 14.57C50.5923 14.7167 50.7189 14.9067 50.8123 15.14C50.9056 15.3667 50.9523 15.6367 50.9523 15.95V19H50.0523V16.2C50.0523 15.98 50.0223 15.7933 49.9623 15.64C49.9023 15.48 49.8223 15.3533 49.7223 15.26C49.6223 15.16 49.5056 15.09 49.3723 15.05C49.2456 15.0033 49.1123 14.98 48.9723 14.98C48.7856 14.98 48.6123 15.01 48.4523 15.07C48.2923 15.13 48.1523 15.2267 48.0323 15.36C47.9123 15.4867 47.8189 15.65 47.7523 15.85C47.6856 16.05 47.6523 16.2867 47.6523 16.56V19H46.7523V14.26ZM52.3789 14.26H53.2789V19H52.3789V14.26ZM52.1689 12.56C52.1689 12.38 52.2322 12.2267 52.3589 12.1C52.4922 11.9667 52.6489 11.9 52.8289 11.9C53.0089 11.9 53.1622 11.9667 53.2889 12.1C53.4222 12.2267 53.4889 12.38 53.4889 12.56C53.4889 12.74 53.4222 12.8967 53.2889 13.03C53.1622 13.1567 53.0089 13.22 52.8289 13.22C52.6489 13.22 52.4922 13.1567 52.3589 13.03C52.2322 12.8967 52.1689 12.74 52.1689 12.56ZM57.2513 15.04H55.9613V17.19C55.9613 17.3233 55.9646 17.4567 55.9713 17.59C55.9779 17.7167 56.0013 17.8333 56.0413 17.94C56.0879 18.04 56.1546 18.1233 56.2413 18.19C56.3346 18.25 56.4679 18.28 56.6413 18.28C56.7479 18.28 56.8579 18.27 56.9712 18.25C57.0846 18.23 57.1879 18.1933 57.2813 18.14V18.96C57.1746 19.02 57.0346 19.06 56.8613 19.08C56.6946 19.1067 56.5646 19.12 56.4713 19.12C56.1246 19.12 55.8546 19.0733 55.6613 18.98C55.4746 18.88 55.3346 18.7533 55.2413 18.6C55.1546 18.4467 55.1013 18.2767 55.0813 18.09C55.0679 17.8967 55.0613 17.7033 55.0613 17.51V15.04H54.0212V14.26H55.0613V12.93H55.9613V14.26H57.2513V15.04ZM57.8424 14.26H58.8824L60.2924 17.96H60.3124L61.6524 14.26H62.6224L60.3724 20.02C60.2924 20.2267 60.2091 20.4133 60.1224 20.58C60.0358 20.7533 59.9324 20.9 59.8124 21.02C59.6924 21.14 59.5458 21.2333 59.3724 21.3C59.2058 21.3667 58.9991 21.4 58.7524 21.4C58.6191 21.4 58.4824 21.39 58.3424 21.37C58.2091 21.3567 58.0791 21.3233 57.9524 21.27L58.0624 20.45C58.2424 20.5233 58.4224 20.56 58.6024 20.56C58.7424 20.56 58.8591 20.54 58.9524 20.5C59.0524 20.4667 59.1358 20.4133 59.2024 20.34C59.2758 20.2733 59.3358 20.1933 59.3824 20.1C59.4291 20.0067 59.4758 19.9 59.5224 19.78L59.8124 19.03L57.8424 14.26Z" fill="white"/><path d="M32.34 22.22H32.79V23.97H32.8C32.88 23.8467 32.995 23.75 33.145 23.68C33.295 23.6067 33.455 23.57 33.625 23.57C33.8083 23.57 33.9733 23.6017 34.12 23.665C34.27 23.7283 34.3967 23.8167 34.5 23.93C34.6067 24.04 34.6883 24.1717 34.745 24.325C34.8017 24.475 34.83 24.6383 34.83 24.815C34.83 24.9917 34.8017 25.155 34.745 25.305C34.6883 25.455 34.6067 25.5867 34.5 25.7C34.3967 25.8133 34.27 25.9017 34.12 25.965C33.9733 26.0283 33.8083 26.06 33.625 26.06C33.465 26.06 33.3083 26.025 33.155 25.955C33.005 25.885 32.8867 25.7867 32.8 25.66H32.79V26H32.34V22.22ZM33.57 25.64C33.69 25.64 33.7983 25.62 33.895 25.58C33.9917 25.5367 34.0733 25.48 34.14 25.41C34.2067 25.3367 34.2583 25.25 34.295 25.15C34.3317 25.0467 34.35 24.935 34.35 24.815C34.35 24.695 34.3317 24.585 34.295 24.485C34.2583 24.3817 34.2067 24.295 34.14 24.225C34.0733 24.1517 33.9917 24.095 33.895 24.055C33.7983 24.0117 33.69 23.99 33.57 23.99C33.45 23.99 33.3417 24.0117 33.245 24.055C33.1483 24.095 33.0667 24.1517 33 24.225C32.9333 24.295 32.8817 24.3817 32.845 24.485C32.8083 24.585 32.79 24.695 32.79 24.815C32.79 24.935 32.8083 25.0467 32.845 25.15C32.8817 25.25 32.9333 25.3367 33 25.41C33.0667 25.48 33.1483 25.5367 33.245 25.58C33.3417 25.62 33.45 25.64 33.57 25.64ZM35.1116 23.63H35.6316L36.3366 25.48H36.3466L37.0166 23.63H37.5016L36.3766 26.51C36.3366 26.6133 36.295 26.7067 36.2516 26.79C36.2083 26.8767 36.1566 26.95 36.0966 27.01C36.0366 27.07 35.9633 27.1167 35.8766 27.15C35.7933 27.1833 35.69 27.2 35.5666 27.2C35.5 27.2 35.4316 27.195 35.3616 27.185C35.295 27.1783 35.23 27.1617 35.1666 27.135L35.2216 26.725C35.3116 26.7617 35.4016 26.78 35.4916 26.78C35.5616 26.78 35.62 26.77 35.6666 26.75C35.7166 26.7333 35.7583 26.7067 35.7916 26.67C35.8283 26.6367 35.8583 26.5967 35.8816 26.55C35.905 26.5033 35.9283 26.45 35.9516 26.39L36.0966 26.015L35.1116 23.63ZM39.4032 22.46H40.6482C40.8749 22.46 41.0616 22.4917 41.2082 22.555C41.3549 22.615 41.4699 22.6933 41.5532 22.79C41.6399 22.8833 41.6999 22.99 41.7332 23.11C41.7666 23.2267 41.7832 23.34 41.7832 23.45C41.7832 23.56 41.7666 23.675 41.7332 23.795C41.6999 23.9117 41.6399 24.0183 41.5532 24.115C41.4699 24.2083 41.3549 24.2867 41.2082 24.35C41.0616 24.41 40.8749 24.44 40.6482 24.44H39.8832V26H39.4032V22.46ZM39.8832 24.02H40.5132C40.6066 24.02 40.6982 24.0133 40.7882 24C40.8816 23.9833 40.9632 23.955 41.0332 23.915C41.1066 23.875 41.1649 23.8183 41.2082 23.745C41.2516 23.6683 41.2732 23.57 41.2732 23.45C41.2732 23.33 41.2516 23.2333 41.2082 23.16C41.1649 23.0833 41.1066 23.025 41.0332 22.985C40.9632 22.945 40.8816 22.9183 40.7882 22.905C40.6982 22.8883 40.6066 22.88 40.5132 22.88H39.8832V24.02ZM42.2621 23.92C42.3888 23.8033 42.5354 23.7167 42.7021 23.66C42.8688 23.6 43.0354 23.57 43.2021 23.57C43.3754 23.57 43.5238 23.5917 43.6471 23.635C43.7738 23.6783 43.8771 23.7367 43.9571 23.81C44.0371 23.8833 44.0954 23.9683 44.1321 24.065C44.1721 24.1583 44.1921 24.2567 44.1921 24.36V25.57C44.1921 25.6533 44.1938 25.73 44.1971 25.8C44.2004 25.87 44.2054 25.9367 44.2121 26H43.8121C43.8021 25.88 43.7971 25.76 43.7971 25.64H43.7871C43.6871 25.7933 43.5688 25.9017 43.4321 25.965C43.2954 26.0283 43.1371 26.06 42.9571 26.06C42.8471 26.06 42.7421 26.045 42.6421 26.015C42.5421 25.985 42.4538 25.94 42.3771 25.88C42.3038 25.82 42.2454 25.7467 42.2021 25.66C42.1588 25.57 42.1371 25.4667 42.1371 25.35C42.1371 25.1967 42.1704 25.0683 42.2371 24.965C42.3071 24.8617 42.4004 24.7783 42.5171 24.715C42.6371 24.6483 42.7754 24.6017 42.9321 24.575C43.0921 24.545 43.2621 24.53 43.4421 24.53H43.7721V24.43C43.7721 24.37 43.7604 24.31 43.7371 24.25C43.7138 24.19 43.6788 24.1367 43.6321 24.09C43.5854 24.04 43.5271 24.0017 43.4571 23.975C43.3871 23.945 43.3038 23.93 43.2071 23.93C43.1204 23.93 43.0438 23.9383 42.9771 23.955C42.9138 23.9717 42.8554 23.9933 42.8021 24.02C42.7488 24.0433 42.7004 24.0717 42.6571 24.105C42.6138 24.1383 42.5721 24.17 42.5321 24.2L42.2621 23.92ZM43.5321 24.86C43.4254 24.86 43.3154 24.8667 43.2021 24.88C43.0921 24.89 42.9904 24.9117 42.8971 24.945C42.8071 24.9783 42.7321 25.025 42.6721 25.085C42.6154 25.145 42.5871 25.2217 42.5871 25.315C42.5871 25.4517 42.6321 25.55 42.7221 25.61C42.8154 25.67 42.9404 25.7 43.0971 25.7C43.2204 25.7 43.3254 25.68 43.4121 25.64C43.4988 25.5967 43.5688 25.5417 43.6221 25.475C43.6754 25.4083 43.7138 25.335 43.7371 25.255C43.7604 25.1717 43.7721 25.09 43.7721 25.01V24.86H43.5321ZM44.5599 23.63H45.0799L45.7849 25.48H45.7949L46.4649 23.63H46.9499L45.8249 26.51C45.7849 26.6133 45.7432 26.7067 45.6999 26.79C45.6565 26.8767 45.6049 26.95 45.5449 27.01C45.4849 27.07 45.4115 27.1167 45.3249 27.15C45.2415 27.1833 45.1382 27.2 45.0149 27.2C44.9482 27.2 44.8799 27.195 44.8099 27.185C44.7432 27.1783 44.6782 27.1617 44.6149 27.135L44.6699 26.725C44.7599 26.7617 44.8499 26.78 44.9399 26.78C45.0099 26.78 45.0682 26.77 45.1149 26.75C45.1649 26.7333 45.2065 26.7067 45.2399 26.67C45.2765 26.6367 45.3065 26.5967 45.3299 26.55C45.3532 26.5033 45.3765 26.45 45.3999 26.39L45.5449 26.015L44.5599 23.63ZM47.3449 23.63H47.7949V23.995H47.8049C47.8349 23.9317 47.8749 23.875 47.9249 23.825C47.9749 23.7717 48.0299 23.7267 48.0899 23.69C48.1532 23.6533 48.2215 23.625 48.2949 23.605C48.3682 23.5817 48.4415 23.57 48.5149 23.57C48.5882 23.57 48.6549 23.58 48.7149 23.6L48.6949 24.085C48.6582 24.075 48.6215 24.0667 48.5849 24.06C48.5482 24.0533 48.5115 24.05 48.4749 24.05C48.2549 24.05 48.0865 24.1117 47.9699 24.235C47.8532 24.3583 47.7949 24.55 47.7949 24.81V26H47.3449V23.63ZM49.2055 23.92C49.3321 23.8033 49.4788 23.7167 49.6455 23.66C49.8121 23.6 49.9788 23.57 50.1455 23.57C50.3188 23.57 50.4671 23.5917 50.5905 23.635C50.7171 23.6783 50.8205 23.7367 50.9005 23.81C50.9805 23.8833 51.0388 23.9683 51.0755 24.065C51.1155 24.1583 51.1355 24.2567 51.1355 24.36V25.57C51.1355 25.6533 51.1371 25.73 51.1405 25.8C51.1438 25.87 51.1488 25.9367 51.1555 26H50.7555C50.7455 25.88 50.7405 25.76 50.7405 25.64H50.7305C50.6305 25.7933 50.5121 25.9017 50.3755 25.965C50.2388 26.0283 50.0805 26.06 49.9005 26.06C49.7905 26.06 49.6855 26.045 49.5855 26.015C49.4855 25.985 49.3971 25.94 49.3205 25.88C49.2471 25.82 49.1888 25.7467 49.1455 25.66C49.1021 25.57 49.0805 25.4667 49.0805 25.35C49.0805 25.1967 49.1138 25.0683 49.1805 24.965C49.2505 24.8617 49.3438 24.7783 49.4605 24.715C49.5805 24.6483 49.7188 24.6017 49.8755 24.575C50.0355 24.545 50.2055 24.53 50.3855 24.53H50.7155V24.43C50.7155 24.37 50.7038 24.31 50.6805 24.25C50.6571 24.19 50.6221 24.1367 50.5755 24.09C50.5288 24.04 50.4705 24.0017 50.4005 23.975C50.3305 23.945 50.2471 23.93 50.1505 23.93C50.0638 23.93 49.9871 23.9383 49.9205 23.955C49.8571 23.9717 49.7988 23.9933 49.7455 24.02C49.6921 24.0433 49.6438 24.0717 49.6005 24.105C49.5571 24.1383 49.5155 24.17 49.4755 24.2L49.2055 23.92ZM50.4755 24.86C50.3688 24.86 50.2588 24.8667 50.1455 24.88C50.0355 24.89 49.9338 24.9117 49.8405 24.945C49.7505 24.9783 49.6755 25.025 49.6155 25.085C49.5588 25.145 49.5305 25.2217 49.5305 25.315C49.5305 25.4517 49.5755 25.55 49.6655 25.61C49.7588 25.67 49.8838 25.7 50.0405 25.7C50.1638 25.7 50.2688 25.68 50.3555 25.64C50.4421 25.5967 50.5121 25.5417 50.5655 25.475C50.6188 25.4083 50.6571 25.335 50.6805 25.255C50.7038 25.1717 50.7155 25.09 50.7155 25.01V24.86H50.4755ZM51.5032 23.63H52.0232L52.7332 25.445L53.4132 23.63H53.8932L52.9632 26H52.4682L51.5032 23.63ZM54.6282 24.98C54.6282 25.0833 54.6499 25.1783 54.6932 25.265C54.7399 25.3483 54.7999 25.42 54.8732 25.48C54.9466 25.54 55.0316 25.5867 55.1282 25.62C55.2249 25.6533 55.3249 25.67 55.4282 25.67C55.5682 25.67 55.6899 25.6383 55.7932 25.575C55.8966 25.5083 55.9916 25.4217 56.0782 25.315L56.4182 25.575C56.1682 25.8983 55.8182 26.06 55.3682 26.06C55.1816 26.06 55.0116 26.0283 54.8582 25.965C54.7082 25.9017 54.5799 25.815 54.4732 25.705C54.3699 25.5917 54.2899 25.46 54.2332 25.31C54.1766 25.1567 54.1482 24.9917 54.1482 24.815C54.1482 24.6383 54.1782 24.475 54.2382 24.325C54.3016 24.1717 54.3866 24.04 54.4932 23.93C54.6032 23.8167 54.7332 23.7283 54.8832 23.665C55.0332 23.6017 55.1966 23.57 55.3732 23.57C55.5832 23.57 55.7599 23.6067 55.9032 23.68C56.0499 23.7533 56.1699 23.85 56.2632 23.97C56.3566 24.0867 56.4232 24.22 56.4632 24.37C56.5066 24.5167 56.5282 24.6667 56.5282 24.82V24.98H54.6282ZM56.0482 24.62C56.0449 24.52 56.0282 24.4283 55.9982 24.345C55.9716 24.2617 55.9299 24.19 55.8732 24.13C55.8166 24.0667 55.7449 24.0183 55.6582 23.985C55.5749 23.9483 55.4766 23.93 55.3632 23.93C55.2532 23.93 55.1516 23.9517 55.0582 23.995C54.9682 24.035 54.8916 24.0883 54.8282 24.155C54.7649 24.2217 54.7149 24.2967 54.6782 24.38C54.6449 24.46 54.6282 24.54 54.6282 24.62H56.0482Z" fill="white"/><defs><linearGradient id="paint0_linear_2145_335" x1="135" y1="0" x2="135" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#CEAAF9"/><stop offset="1" stop-color="#80C7E9"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = "</text></svg>";

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint => string) public names;

    address payable public owner;

    constructor(string memory _tld)
        payable
        ERC721("Signity Name Service", "SNS")
    {
        owner = payable(msg.sender);
        tld = _tld;
    }

    function price(string calldata name) public pure returns (uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 0.5MATIC (Change this)
        } else if (len == 4) {
            return 3 * 10**17; // 0.3 MATIC
        } else {
            return 1 * 10**17;
        }
    }

    function register(string calldata name) public payable {
        require(domains[name] == address(0));

        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough Matic paid");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Signity Name Service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;
        names[newRecordId] = name;

        _tokenIds.increment();
    }

    function getAllNames() public view returns (string[] memory) {
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
        }

        return allNames;
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        require(domains[name] == msg.sender);
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}