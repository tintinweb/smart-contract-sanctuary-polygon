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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IBoleroERC721.sol";

interface IBoleroABI {
    function management() external view returns (address);

    function rewards() external view returns (address);
}

interface IBoleroNFT {
    struct Royalties {
        uint256 boleroFeesPrimary;
        uint256 boleroFeesSecondary;
        uint256 artistRoyalties;
    }

    struct Collection {
        address artist;
        address payment;
        address privateSaleToken;
        string collectionName;
        uint256 collectionId;
        uint256 cap;
        uint256 privateSaleThreshold;
        Royalties royalties;
        bool isWithPaymentSplitter;
    }

    function royaltiesForBolero() external view returns (uint256);

    function royaltiesForArtist() external view returns (uint256);

    function artistPayment(uint256 _tokenID) external view returns (address);

    function getRoyalties(uint256 _tokenID) external view returns (uint256);

    function setSecondaryMarketStatus(uint256 _tokenID) external;

    function getIsSecondaryMarket(uint256 _tokenID) external view returns (bool);

    function canSwap(address _userAddress, uint256 _tokenID)
        external
        view
        returns (bool);
    
    /**
	 * @dev Returns if the token is locked (non-transferrable) or not.
	 */
	function isLocked(uint256 _id) external view returns(bool);

	/**
	 * @dev Locks a token, preventing it from being transferrable
	 */
	function lockId(uint256 _id) external;

	/**
	 * @dev Unlocks a token.
	 */
	function unlockId(uint256 _id) external;

    function autoLockId(uint256 _id) external; 
    
    function getCollectionForToken(uint256 _tokenID) external returns (Collection memory);
}

contract Controller {
    address public bolero = address(0); //Management address
    address public rewards = address(0); //address used to send the rewards

    IBoleroABI public boleroContract;

    bool public isEmergencyPause = false;

    modifier onlyBolero() {
        require(
            address(msg.sender) == IBoleroABI(bolero).management(),
            "!authorized"
        );
        _;
    }

    modifier notEmergency() {
        require(isEmergencyPause == false, "emergency pause");
        _;
    }

    function getManagement() public view returns (address) {
        return IBoleroABI(bolero).management();
    }
}

contract BoleroNFTSwap is Controller {
    using Counters for Counters.Counter;
    struct Offer {
        address from; // NFT SELLER
        address fromPayment; // PAYMENT ADDRESS
        address to; // NFT BUYER
        address nftAddress; //ADDRESS OF THE NFT CONTRACT
        address wantAddress; //ADDRESS OF THE ERC20 CONTRACT
        uint256 nftTokenID; //TOKEN ID OF THE NFT TO EXCHANGE
        uint256 wantAmount; //AMOUNT OF THE ERC20 TO EXCHANGE
        bytes32 status; // Open, Executed, Cancelled
    }
    struct Bid {
        address from; // NFT SELLER
        address fromPayment; // PAYMENT ADDRESS
        address to; // Current best offer
        address nftAddress; //ADDRESS OF THE NFT CONTRACT
        address wantAddress; //ADDRESS OF THE ERC20 CONTRACT
        uint256 nftTokenID; //TOKEN ID OF THE NFT TO EXCHANGE
        uint256 startOffer; //STARTING PRICE FOR THIS AUCTION
        uint256 bestOffer; //BEST OFFER OF THE NFT TO EXCHANGE, OR INITIAL PRICE
        uint256 startTime; //TIMESTAMP OF THE START OF THE AUCTION
        uint256 endTime; //TIMESTAMP OF THE END OF THE AUCTION
        bytes32 status; // Open, Executed, Cancelled
    }
    struct BidMemory {
        address from; //Bider
        uint256 offer; //Amount of bid
        bytes32 status; // Open, Executed, Cancelled
    }
    struct LastSale {
        uint8 saleType; //0 = none, 1 = buy, 2 = sell, 3 = bid
        uint256 id; //id of the sale
        uint256 timestamp; //when executed
        uint256 amount; //amount of want token in exchange
        address buyer; //buyer of the sale
        address wantToken; //address of the want token
    }

    struct PaymentConfiguration {
        bool isSecondaryMarket;
        uint256 royaltiesForBolero;
        uint256 royaltiesForArtist;
        uint256 amountForBolero;
        uint256 amountForArtist;
        uint256 amountForSeller;
        address artistPayment;
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    mapping(uint256 => Offer) public sellOffers;
    mapping(uint256 => Offer) public buyOffers;
    mapping(uint256 => Bid) public bids;
    mapping(address => mapping(uint256 => uint256[])) public sellOffersEnum;
    mapping(address => mapping(uint256 => uint256[])) public buyOffersEnum;
    mapping(address => mapping(uint256 => uint256[])) public bidsEnum;
    mapping(address => mapping(uint256 => BidMemory[])) public bidsValues;
    mapping(address => mapping(uint256 => LastSale)) public lastSale;
    Counters.Counter private sellCounter;
    Counters.Counter private buyCounter;
    Counters.Counter private bidCounter;

    event CreateSellOffer(
        uint256 indexed sellCounter,
        address from,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 wantAmount,
        string status
    );
    event CancelSellOffer(
        uint256 indexed sellCounter,
        address from,
        address indexed nftAddress,
        uint256 indexed nftTokenID,
        string status
    );
    event ExecuteSellOffer(
        uint256 indexed sellCounter,
        address from,
        address to,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 wantAmount,
        string status
    );
    event CreateBuyOffer(
        uint256 indexed buyCounter,
        address from,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 wantAmount,
        string status
    );
    event CancelBuyOffer(
        uint256 indexed buyCounter,
        address from,
        address indexed nftAddress,
        uint256 indexed nftTokenID,
        string status
    );
    event ExecuteBuyOffer(
        uint256 indexed buyCounter,
        address from,
        address to,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 wantAmount,
        string status
    );
    event OpenBid(
        uint256 indexed bidCounter,
        address from,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 startOffer,
        uint256 startTime,
        uint256 endTime,
        string status
    );
    event PerformBid(
        uint256 indexed bidCounter,
        address from,
        address to,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 startOffer
    );
    event CancelBid(
        uint256 indexed bidCounter,
        address from,
        address indexed nftAddress,
        uint256 indexed nftTokenID,
        string status
    );
    event CancelBidOffer(
        uint256 indexed bidOfferCounter,
        address from,
        address indexed nftAddress,
        uint256 indexed nftTokenID,
        string status
    );
    event ExecuteBid(
        uint256 indexed bidCounter,
        address from,
        address to,
        address indexed nftAddress,
        address wantAddress,
        uint256 indexed nftTokenID,
        uint256 wantAmount,
        string status
    );

    modifier isUnlockOrIsPrimary(address _nftAddress, uint256 _nftTokenID) {
        require(
            IBoleroNFT(_nftAddress).getIsSecondaryMarket(_nftTokenID) && 
            IBoleroNFT(_nftAddress).isLocked(_nftTokenID) || 
            !IBoleroNFT(_nftAddress).getIsSecondaryMarket(_nftTokenID),
            "isLocked"
        );
        _;
    }

    constructor(address _management, address _rewards) {
        rewards = _rewards;
        bolero = _management;
    }

    /*************************************************************************************
     **	@notice Open a new sell offer. A sell offer can occurs when a user has
     **			a NFT and want to sell it. To a specific price.
     **			The sell order will be added on chain and available for anyone
     **			to buy it.
     **
     **	@dev The NFT is locked in the contract until the trade is executed or cancelled.
     **       The trade will fail if the NFT is not approved.
     **
     **	@param _nftAddress address of the Bolero NFT contract to sell
     **	@param _wantAddress address of the ERC20 contract the user wants in countervalue
     **	@param _payment address to use to receive the payment
     **	@param _nftTokenID ID of the NFT to sell
     **	@param _wantAmount amount of the ERC20 the user wants.
     *************************************************************************************/
    function openSellOffer(
        address _nftAddress,
        address _wantAddress,
        address _payment,
        uint256 _nftTokenID,
        uint256 _wantAmount
    ) public {
        sellCounter.increment();
        uint256 _sellCounter = sellCounter.current();
        IERC721(_nftAddress).transferFrom(
            msg.sender,
            address(this),
            _nftTokenID
        );
        sellOffersEnum[_nftAddress][_nftTokenID].push(_sellCounter);
        sellOffers[_sellCounter] = Offer({
            from: msg.sender,
            fromPayment: _payment,
            to: address(0),
            nftAddress: _nftAddress,
            nftTokenID: _nftTokenID,
            wantAddress: _wantAddress,
            wantAmount: _wantAmount,
            status: "Open"
        });
        emit CreateSellOffer(
            _sellCounter,
            msg.sender,
            _nftAddress,
            _wantAddress,
            _nftTokenID,
            _wantAmount,
            "Open"
        );
    }

    function openSellOffer(
        address _nftAddress,
        address _wantAddress,
        address _owner,
        address _payment,
        uint256 _nftTokenID,
        uint256 _wantAmount
    ) public {
        sellCounter.increment();
        uint256 _sellCounter = sellCounter.current();
        IERC721(_nftAddress).transferFrom(
            msg.sender,
            address(this),
            _nftTokenID
        );
        sellOffersEnum[_nftAddress][_nftTokenID].push(_sellCounter);
        sellOffers[_sellCounter] = Offer({
            from: _owner,
            fromPayment: _payment,
            to: address(0),
            nftAddress: _nftAddress,
            nftTokenID: _nftTokenID,
            wantAddress: _wantAddress,
            wantAmount: _wantAmount,
            status: "Open"
        });
        emit CreateSellOffer(
            _sellCounter,
            _owner,
            _nftAddress,
            _wantAddress,
            _nftTokenID,
            _wantAmount,
            "Open"
        );
    }

    /*************************************************************************************
     **	@notice Cancel one of my existing trades. Only by the owner of the trade. Only
     **			if the trade is not executed.
     **
     **	@dev The NFT will be returned to the user and the trade set as Cancelled.
     **
     **	@param _sellCounter ID of the trade to cancel
     *************************************************************************************/
    function cancelSellOffer(uint256 _sellCounter) public {
        Offer memory offer = sellOffers[_sellCounter];
        require(msg.sender == offer.from, "!not seller");
        require(offer.status == "Open", "!open");
        sellOffers[_sellCounter].status = "Cancelled";

        IERC721(offer.nftAddress).transferFrom(
            address(this),
            offer.from,
            offer.nftTokenID
        );
        emit CancelSellOffer(
            _sellCounter,
            msg.sender,
            offer.nftAddress,
            offer.nftTokenID,
            "Cancelled"
        );
    }

    function configurePayementOption(address _nftAddress, uint256 _tokenID, uint256 wantAmount) internal returns(PaymentConfiguration memory){
        PaymentConfiguration memory payement;
        payement.isSecondaryMarket = IBoleroNFT(_nftAddress).getIsSecondaryMarket(_tokenID);
        payement.royaltiesForBolero = payement.isSecondaryMarket ? IBoleroNFT(_nftAddress).getCollectionForToken(_tokenID).royalties.boleroFeesSecondary : IBoleroNFT(_nftAddress).getCollectionForToken(_tokenID).royalties.boleroFeesPrimary;
        payement.royaltiesForArtist = IBoleroNFT(_nftAddress).getRoyalties(_tokenID);
        payement.amountForBolero = (wantAmount * payement.royaltiesForBolero) / 10000;
        payement.amountForArtist = (wantAmount * payement.royaltiesForArtist) / 10000;
        payement.amountForSeller = payement.isSecondaryMarket? wantAmount - (payement.amountForBolero + payement.amountForArtist) : wantAmount - payement.amountForBolero;

        //Retrieve the address of the artist and the address of BoleroRewards to increment
        //their treasures.
        payement.artistPayment = IBoleroNFT(_nftAddress).artistPayment(_tokenID);
        return payement;
    }

    /*************************************************************************************
     **	@notice Execute a trade. Can be called by anyone but the seller. The trade should
     **			be in the Open state.
     **			Some royalties will be paid to the artist and Bolero based on the values
     **			set in the NFT Contract. Theses fees will be substracted from the amount
     **			of ERC20 the seller will get and put in a treasury, ready to be claimed.
     **
     **	@param _sellCounter ID of the trade to cancel
     *************************************************************************************/
    function executeMetaSellOffer(uint256 _sellCounter, address recipient)
        public
        notEmergency
    {
        Offer memory offer = sellOffers[_sellCounter];
        require(offer.status == "Open", "!open");
        require(offer.from != msg.sender, "!msg.sender");
        require(
            IBoleroNFT(offer.nftAddress).canSwap(msg.sender, offer.nftTokenID),
            "!whitelist"
        );

        sellOffers[_sellCounter].to = recipient;
        sellOffers[_sellCounter].status = "Executed";

        //Compute the royalties for Bolero and the artist, and get the final amount
        //for the seller.
         
        PaymentConfiguration memory config = configurePayementOption(offer.nftAddress,offer.nftTokenID, offer.wantAmount);

        //Transfering the offer to this contract
        require(
            IERC20(offer.wantAddress).transferFrom(
                msg.sender,
                address(this),
                offer.wantAmount
            )
        );

        //Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
        require(IERC20(offer.wantAddress).transfer(rewards, config.amountForBolero));

        if(config.isSecondaryMarket){
            require(
                IERC20(offer.wantAddress).transfer(config.artistPayment, config.amountForArtist)
            );
        }
        require(
            IERC20(offer.wantAddress).transfer(offer.from, config.amountForSeller)
        );

        //Send the nft to the buyer
        IERC721(offer.nftAddress).transferFrom(
            address(this),
            recipient,
            offer.nftTokenID
        );

        if(!config.isSecondaryMarket) IBoleroNFT(offer.nftAddress).autoLockId(offer.nftTokenID);
        IBoleroNFT(offer.nftAddress).setSecondaryMarketStatus(offer.nftTokenID);
        lastSale[offer.nftAddress][offer.nftTokenID] = LastSale(
            2,
            _sellCounter,
            block.timestamp,
            offer.wantAmount,
            recipient,
            offer.wantAddress
        );

        emit ExecuteSellOffer(
            _sellCounter,
            offer.from,
            recipient,
            offer.nftAddress,
            offer.wantAddress,
            offer.nftTokenID,
            offer.wantAmount,
            "Executed"
        );
    }

    /*************************************************************************************
     **	@notice Execute a trade. Can be called by anyone but the seller. The trade should
     **			be in the Open state.
     **			Some royalties will be paid to the artist and Bolero based on the values
     **			set in the NFT Contract. Theses fees will be substracted from the amount
     **			of ERC20 the seller will get and put in a treasury, ready to be claimed.
     **
     **	@param _sellCounter ID of the trade to cancel
     *************************************************************************************/
    function executeSellOffer(uint256 _sellCounter) public notEmergency {
        Offer memory offer = sellOffers[_sellCounter];
        require(offer.status == "Open", "!open");
        require(offer.from != msg.sender, "!msg.sender");
        require(
            IBoleroNFT(offer.nftAddress).canSwap(msg.sender, offer.nftTokenID),
            "!whitelist"
        );

        sellOffers[_sellCounter].to = msg.sender;
        sellOffers[_sellCounter].status = "Executed";

        //Compute the royalties for Bolero and the artist, and get the final amount
        //for the seller.
        PaymentConfiguration memory config = configurePayementOption(offer.nftAddress,offer.nftTokenID, offer.wantAmount);
        //Transfering the offer to this contract
        require(
            IERC20(offer.wantAddress).transferFrom(
                msg.sender,
                address(this),
                offer.wantAmount
            )
        );

        //Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
        require(IERC20(offer.wantAddress).transfer(rewards, config.amountForBolero));
        if(config.isSecondaryMarket){
            require(
                IERC20(offer.wantAddress).transfer(config.artistPayment, config.amountForArtist)
            );
        }
        require(
            IERC20(offer.wantAddress).transfer(
                offer.fromPayment,
                config.amountForSeller
            )
        );

        //Send the nft to the buyer
        IERC721(offer.nftAddress).transferFrom(
            address(this),
            msg.sender,
            offer.nftTokenID
        );

        if(!config.isSecondaryMarket) IBoleroNFT(offer.nftAddress).autoLockId(offer.nftTokenID);
        IBoleroNFT(offer.nftAddress).setSecondaryMarketStatus(offer.nftTokenID);
        lastSale[offer.nftAddress][offer.nftTokenID] = LastSale(
            2,
            _sellCounter,
            block.timestamp,
            offer.wantAmount,
            msg.sender,
            offer.wantAddress
        );

        emit ExecuteSellOffer(
            _sellCounter,
            offer.from,
            msg.sender,
            offer.nftAddress,
            offer.wantAddress,
            offer.nftTokenID,
            offer.wantAmount,
            "Executed"
        );
    }

    /*************************************************************************************
     **	@notice Open a new buy offer. A buy offer can occurs when a user wants to buy an
     **			NFT to a specific price, even if there is no sell order currently
     **			available.
     **			The buy order will be added on chain and available the NFT owner to sell.
     **
     **	@dev The payout is locked in the contract until the trade is executed or
     **		 cancelled. The trade will fail if the tokens are not approved.
     **
     **	@param _nftAddress address of the Bolero NFT contract to sell
     **	@param _wantAddress address of the ERC20 contract the user wants in countervalue
     **	@param _nftTokenID ID of the NFT to sell
     **	@param _wantAmount amount of the ERC20 the user wants.
     *************************************************************************************/
    function openBuyOffer(
        address _nftAddress,
        address _wantAddress,
        uint256 _nftTokenID,
        uint256 _wantAmount
    ) public {
        require(
            IERC20(_wantAddress).balanceOf(msg.sender) >= _wantAmount,
            "!balance"
        );
        require(
            IERC20(_wantAddress).allowance(msg.sender, address(this)) >=
                _wantAmount,
            "!balance"
        );
        require(
            IBoleroNFT(_nftAddress).canSwap(msg.sender, _nftTokenID),
            "!whitelist"
        );

        buyCounter.increment();
        uint256 _buyCounter = buyCounter.current();
        buyOffersEnum[_nftAddress][_nftTokenID].push(_buyCounter);
        buyOffers[_buyCounter] = Offer({
            from: msg.sender,
            fromPayment: msg.sender,
            to: address(0),
            nftAddress: _nftAddress,
            nftTokenID: _nftTokenID,
            wantAddress: _wantAddress,
            wantAmount: _wantAmount,
            status: "Open"
        });
        emit CreateBuyOffer(
            _buyCounter,
            msg.sender,
            _nftAddress,
            _wantAddress,
            _nftTokenID,
            _wantAmount,
            "Open"
        );
    }

    /*************************************************************************************
     **	@notice Cancel one of my existing trades. Only by the owner of the trade. Only
     **			if the trade is not executed.
     **
     **	@dev The wantAmount will be returned to the user and the trade set as Cancelled.
     **
     **	@param _buyCounter ID of the trade to cancel
     *************************************************************************************/
    function cancelBuyOffer(uint256 _buyCounter) public {
        Offer memory offer = buyOffers[_buyCounter];
        require(msg.sender == offer.from, "!authorized");
        require(offer.status == "Open", "!open");
        buyOffers[_buyCounter].status = "Cancelled";
        emit CancelBuyOffer(
            _buyCounter,
            msg.sender,
            offer.nftAddress,
            offer.nftTokenID,
            "Cancelled"
        );
    }

    /*************************************************************************************
     **	@notice Execute a trade. The trade should be in the Open state.
     **			Some royalties will be paid to the artist and Bolero based on the values
     **			set in the NFT Contract. Theses fees will be substracted from the amount
     **			of ERC20 the seller will get and put in a treasury, ready to be claimed.
     **
     **	@param _buyCounter ID of the trade to cancel
     *************************************************************************************/
    function executeBuyOffer(uint256 _buyCounter, address _receiver)
        public
        notEmergency
    {
        Offer memory offer = buyOffers[_buyCounter];
        require(offer.status == "Open", "!open");
        require(offer.from != msg.sender, "!msg.sender");

        buyOffers[_buyCounter].to = msg.sender;
        buyOffers[_buyCounter].status = "Executed";

        //Compute the royalties for Bolero and the artist, and get the final amount
        //for the seller.
 
        PaymentConfiguration memory config = configurePayementOption(offer.nftAddress,offer.nftTokenID, offer.wantAmount);
        //Transfering the offer to this contract
        require(
            IERC20(offer.wantAddress).transferFrom(
                offer.from,
                address(this),
                offer.wantAmount
            )
        );

        //Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
        require(IERC20(offer.wantAddress).transfer(rewards, config.amountForBolero));
        if(config.isSecondaryMarket){
            require(
                IERC20(offer.wantAddress).transfer(config.artistPayment, config.amountForArtist)
            );
        }
        require(IERC20(offer.wantAddress).transfer(_receiver, config.amountForSeller));

        //Send the nft to the buyer
        IERC721(offer.nftAddress).transferFrom(
            msg.sender,
            offer.from,
            offer.nftTokenID
        );
       
        if(!IBoleroNFT(offer.nftAddress).getIsSecondaryMarket(offer.nftTokenID) ) IBoleroNFT(offer.nftAddress).autoLockId(offer.nftTokenID);
        IBoleroNFT(offer.nftAddress).setSecondaryMarketStatus(offer.nftTokenID);

        lastSale[offer.nftAddress][offer.nftTokenID] = LastSale(
            1,
            _buyCounter,
            block.timestamp,
            offer.wantAmount,
            offer.from,
            offer.wantAddress
        );

        emit ExecuteBuyOffer(
            _buyCounter,
            offer.from,
            msg.sender,
            offer.nftAddress,
            offer.wantAddress,
            offer.nftTokenID,
            offer.wantAmount,
            "Executed"
        );
    }

    /*************************************************************************************
     **	@notice Create a new auction. An auction can occurs when a user wants to sell an
     **			NFT to a non specific price and let buyers bid on it.
     **
     **	@dev The NFT is locked in the contract until the trade is executed or cancelled.
     **       The trade will fail if the NFT is not approved.
     **
     **	@param _nftAddress address of the Bolero NFT contract to sell
     **	@param _wantAddress address of the ERC20 contract the user wants in countervalue
     **	@param _nftTokenID ID of the NFT to sell
     **	@param _startOffer start price for this bid
     *************************************************************************************/

    function openBid(
        address _nftAddress,
        address _wantAddress,
        address _fromPayment,
        uint256 _nftTokenID,
        uint256 _startOffer,
        uint256[2] memory _startEndTime
    ) public isUnlockOrIsPrimary(_nftAddress, _nftTokenID) {
        require(
            _startEndTime[0] >= block.timestamp || _startEndTime[0] == 0,
            "!timestamp"
        );
        require(_startEndTime[1] > _startEndTime[0], "!endTime");
        bidCounter.increment();
        uint256 _bidCounter = bidCounter.current();
        IERC721(_nftAddress).transferFrom(
            msg.sender,
            address(this),
            _nftTokenID
        );
        bidsEnum[_nftAddress][_nftTokenID].push(_bidCounter);
        bidsValues[_nftAddress][_nftTokenID].push(
            BidMemory(address(0), _startOffer, "Open")
        );
        bids[_bidCounter] = Bid({
            from: msg.sender,
            fromPayment: _fromPayment,
            to: address(0),
            nftAddress: _nftAddress,
            nftTokenID: _nftTokenID,
            wantAddress: _wantAddress,
            startOffer: _startOffer,
            bestOffer: _startOffer,
            startTime: _startEndTime[0],
            endTime: _startEndTime[1],
            status: "Open"
        });
        emit OpenBid(
            _bidCounter,
            msg.sender,
            _nftAddress,
            _wantAddress,
            _nftTokenID,
            _startOffer,
            _startEndTime[0],
            _startEndTime[1],
            "Open"
        );
    }

    function openBid(
        address _nftAddress,
        address _wantAddress,
        address _owner,
        address _fromPayment,
        uint256 _nftTokenID,
        uint256 _startOffer,
        uint256[2] memory _startEndTime
    ) public returns (uint256) {
        require(
            _startEndTime[0] >= block.timestamp || _startEndTime[0] == 0,
            "!timestamp"
        );
        require(_startEndTime[1] > _startEndTime[0], "!endTime");
        bidCounter.increment();
        uint256 _bidCounter = bidCounter.current();
        IERC721(_nftAddress).transferFrom(
            msg.sender,
            address(this),
            _nftTokenID
        );
        bidsEnum[_nftAddress][_nftTokenID].push(_bidCounter);
        bidsValues[_nftAddress][_nftTokenID].push(
            BidMemory(address(0), _startOffer, "Open")
        );
        bids[_bidCounter] = Bid({
            from: _owner,
            fromPayment: _fromPayment,
            to: address(0),
            nftAddress: _nftAddress,
            nftTokenID: _nftTokenID,
            wantAddress: _wantAddress,
            startOffer: _startOffer,
            bestOffer: _startOffer,
            startTime: _startEndTime[0],
            endTime: _startEndTime[1],
            status: "Open"
        });
        emit OpenBid(
            _bidCounter,
            _owner,
            _nftAddress,
            _wantAddress,
            _nftTokenID,
            _startOffer,
            _startEndTime[0],
            _startEndTime[1],
            "Open"
        );
        return _nftTokenID;
    }

    /*************************************************************************************
     **	@notice Add a new bid to an existing auction.
     **
     **	@dev This function will check if the bidder has enough ERC20 to pay the bid, and
     **			if the ERC20 are approved by the contract. It will also check if the
     **			auction is still open, and if the bid is higher than the current best.
     **			No funds are transfered, only the approval is checked.
     **
     **	@param _bidCounter ID of the auction to bid on
     **	@param _offer amount to bid
     *************************************************************************************/
    function performBid(uint256 _bidCounter, uint256 _offer) public {
        Bid memory bid = bids[_bidCounter];
        require(bid.status == "Open", "!open");
        require(
            block.timestamp >= bid.startTime || bid.startTime == 0,
            "!timestamp"
        );
        require(block.timestamp < bid.endTime, "!endTime");
        require(bid.from != msg.sender, "!msg.sender");
        require(bid.bestOffer < _offer, "!offer");
        require(
            IERC20(bid.wantAddress).balanceOf(msg.sender) >= _offer,
            "!balance"
        );
        require(
            IERC20(bid.wantAddress).allowance(msg.sender, address(this)) >=
                _offer,
            "!balance"
        );
        require(
            IBoleroNFT(bid.nftAddress).canSwap(msg.sender, bid.nftTokenID),
            "!whitelist"
        );

        bids[_bidCounter].to = msg.sender;
        bids[_bidCounter].bestOffer = _offer;
        bidsValues[bid.nftAddress][bid.nftTokenID].push(
            BidMemory(msg.sender, _offer, "Open")
        );
        emit PerformBid(
            _bidCounter,
            bid.from,
            msg.sender,
            bid.nftAddress,
            bid.wantAddress,
            bid.nftTokenID,
            _offer
        );
    }

    /*************************************************************************************
     **	@notice Cancel an auction.
     **
     **	@dev This function will check if the auction is still open, and if the caller is
     **	     the owner of the auction. The NFT is transfered back to the owner.
     **
     **	@param _bidCounter ID of the auction to bid on
     *************************************************************************************/
    function cancelBid(uint256 _bidCounter) public {
        Bid memory bid = bids[_bidCounter];
        require(bid.status == "Open", "!open");
        require(bid.from == msg.sender, "!authorized");
        bids[_bidCounter].status = "Cancelled";
        IERC721(bid.nftAddress).transferFrom(
            address(this),
            bid.from,
            bid.nftTokenID
        );

        emit CancelBid(
            _bidCounter,
            bid.from,
            bid.nftAddress,
            bid.nftTokenID,
            "Cancelled"
        );
    }

    /*************************************************************************************
     **	@notice Cancel an user bid
     **
     **	@param _bidCounter ID of the auction to cancel
     **	@param _bidIndex ID of the bid Offer to cancel
     *************************************************************************************/
    function cancelBidOffer(uint256 _bidCounter, uint256 _bidIndex) public {
        Bid memory bid = bids[_bidCounter];
        require(bid.status == "Open", "!open");

        BidMemory memory bidToCancel = bidsValues[bid.nftAddress][
            bid.nftTokenID
        ][_bidIndex];
        require(bidToCancel.status == "Open", "!open");
        require(bidToCancel.from == msg.sender, "!authorized");
        bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex]
            .status = "Cancelled";

        emit CancelBidOffer(
            _bidIndex,
            bidToCancel.from,
            bid.nftAddress,
            bid.nftTokenID,
            "Cancelled"
        );
    }

    /*************************************************************************************
     **	@notice Allow the owner of the NFT to accept the highest bid.
     **
     **	@dev This function will check if the bid is not executed yet and will try to take
     **		 the ERC20 from the bidder to execute the paiement. This will fail is the
     **		 bidder no longer has enough funds.
     **
     **	@param _bidCounter ID of the auction to bid on
     **	@param _bidIndex ID of the bid Offer to accept
     *************************************************************************************/
    function acceptBid(uint256 _bidCounter, uint256 _bidIndex) public {
        Bid memory bid = bids[_bidCounter];
        require(bid.status == "Open", "!open");
        require(bid.from == msg.sender, "!authorized");

        BidMemory memory bidToAccept = bidsValues[bid.nftAddress][
            bid.nftTokenID
        ][_bidIndex];
        require(bidToAccept.status == "Open", "!open");
        require(bidToAccept.from != address(0), "!address0");
        require(bidToAccept.offer != 0, "!offer");

        bids[_bidCounter].status = "Executed";
        bidsValues[bid.nftAddress][bid.nftTokenID][_bidIndex]
            .status = "Executed";

        //Compute the royalties for Bolero and the artist, and get the final amount
        //for the seller.
        PaymentConfiguration memory config = configurePayementOption(bid.nftAddress, bid.nftTokenID, bidToAccept.offer);

        //Transfering the bid to this contract
        require(
            IERC20(bid.wantAddress).transferFrom(
                bidToAccept.from,
                address(this),
                bidToAccept.offer
            )
        );

        //Send the fees to Bolero and the Artist paiement contract. Sending the paiement to the seller
        require(IERC20(bid.wantAddress).transfer(rewards, config.amountForBolero));
        if(config.isSecondaryMarket){
            require(
                IERC20(bid.wantAddress).transfer(config.artistPayment, config.amountForArtist)
            );
        }
        require(
            IERC20(bid.wantAddress).transfer(bid.fromPayment, config.amountForSeller)
        );

        lastSale[bid.nftAddress][bid.nftTokenID] = LastSale(
            3,
            _bidCounter,
            block.timestamp,
            bidToAccept.offer,
            bidToAccept.from,
            bid.wantAddress
        );

        //Send the nft to the buyer
        IERC721(bid.nftAddress).transferFrom(
            address(this),
            bidToAccept.from,
            bid.nftTokenID
        );
        
        if(!config.isSecondaryMarket) IBoleroNFT(bid.nftAddress).autoLockId(bid.nftTokenID);
        IBoleroNFT(bid.nftAddress).setSecondaryMarketStatus(bid.nftTokenID);
        emit ExecuteBid(
            _bidCounter,
            bid.from,
            bidToAccept.from,
            bid.nftAddress,
            bid.wantAddress,
            bid.nftTokenID,
            bidToAccept.offer,
            "Executed"
        );
    }

    /*******************************************************************************
     **	@notice
     **		Allow bolero to send tokens to a list of recipients
     **	@param recipients: List of addresses to receive the tokens
     **	@param nftAddress: nft address contract 
     ** @param tokenIds: Tokens list to send
     *******************************************************************************/
    function grantTokens(address[] memory recipients, address nftAddress, uint256[] memory tokenIds)
        external
        onlyBolero
    {
        for (uint256 i = 0; i < recipients.length; i++){
            IERC721(nftAddress).transferFrom(address(this),recipients[i],tokenIds[i]);
                 sellOffers[(sellOffersEnum[nftAddress][tokenIds[i]]).length].to = recipients[i];
                 sellOffers[(sellOffersEnum[nftAddress][tokenIds[i]]).length].status = "Executed";
            if(!IBoleroNFT(nftAddress).getIsSecondaryMarket(tokenIds[i])) {

                IBoleroNFT(nftAddress).autoLockId(tokenIds[i]);
                IBoleroNFT(nftAddress).setSecondaryMarketStatus(tokenIds[i]);

                }
            }
    }



    function countBids(address _nftAddress, uint256 _nftTokenID)
        public
        view
        returns (uint256)
    {
        return (bidsEnum[_nftAddress][_nftTokenID]).length;
    }

    function countSellOffers(address _nftAddress, uint256 _nftTokenID)
        public
        view
        returns (uint256)
    {
        return (sellOffersEnum[_nftAddress][_nftTokenID]).length;
    }

    function countBuyOffers(address _nftAddress, uint256 _nftTokenID)
        public
        view
        returns (uint256)
    {
        return (buyOffersEnum[_nftAddress][_nftTokenID]).length;
    }

    function countOffersForBid(uint256 _bidCounter)
        public
        view
        returns (uint256)
    {
        Bid memory bid = bids[_bidCounter];
        return (bidsValues[bid.nftAddress][bid.nftTokenID]).length;
    }

    function getLastBid(address _nftAddress, uint256 _nftTokenID)
        public
        view
        returns (Bid memory)
    {
        uint256 numberOfBids = (bidsEnum[_nftAddress][_nftTokenID]).length;
        uint256 lastBidEnum = bidsEnum[_nftAddress][_nftTokenID][
            numberOfBids - 1
        ];
        return bids[lastBidEnum];
    }

    function getLastSell(address _nftAddress, uint256 _nftTokenID)
        public
        view
        returns (Offer memory)
    {
        uint256 numberOfSells = (sellOffersEnum[_nftAddress][_nftTokenID])
            .length;
        uint256 lastSellEnum = sellOffersEnum[_nftAddress][_nftTokenID][
            numberOfSells - 1
        ];
        return sellOffers[lastSellEnum];
    }

    function setRewards(address _newRewards) public onlyBolero {
        rewards = _newRewards;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBoleroERC721 {

	/**
	 * @dev Returns if the token is locked (non-transferrable) or not.
	 */
	function isLocked(uint256 _id) external view returns(bool);

	/**
	 * @dev Locks a token, preventing it from being transferrable
	 */
	function lockId(uint256 _id) external;

	/**
	 * @dev Unlocks a token.
	 */
	function unlockId(uint256 _id) external;

}