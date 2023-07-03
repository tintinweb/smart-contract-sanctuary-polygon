// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4906.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../interfaces/IERC4906.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

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
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StellarToken is IERC20 {
    string public name = "StellarToken";
    string public symbol = "STLLER";
    uint256 public decimals = 18;
    uint256 public override totalSupply = 6900000000 * 10**decimals; // 6.9 billion tokens
    
    uint256 private burnTaxPercent = 3; // Initial burn tax percentage
    uint256 private burnTaxThreshold1 = 690000000 * 10**decimals; // Threshold for 2% burn tax
    uint256 private burnTaxThreshold2 = 69000000 * 10**decimals; // Threshold for 1% sell tax
    
    uint256 private devLockDuration = 365 days;

    //uint256 private stakeLockDuration = 28 days; // Stake lock duration
    uint256 private stakeLockDuration = 5 minutes; //ONLY TEST
    //uint256 private stakeSuperSpecialLockDuration = 21 days; // Stake lock duration
    uint256 private stakeSuperSpecialLockDuration = 3 minutes; //ONLY TEST

    uint256 private stakeRewardPercent = 7; // Stake reward percentage
    uint256 private stakeBurnPercent = 2; // Stake burn percentage
    uint256 private totalStakedAmount;
    
    address private devWallet;
    address private teamWallet;
    address private marketingWallet;
    address private nullAddress;
    address public nftContract; // Address of the contract
    address private uniswapPair;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private lockTimestamps;
    mapping(address => uint256) public nftLevels; // Mapping to track NFT levels
    
    bool private reentrancyGuard; // Reentrancy guard

    uint256 private constant YEAR_SECONDS = 31536000;
    uint256 private constant DAY_SECONDS = 86400;
    uint256 private constant LEAP_YEAR_SECONDS = 31622400;

    bool private stakingEnabled = false;

    // Liquidity Provision
    address private constant router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant factory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address private constant MATIC_TOKEN = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private liquidityPairAddress;
    
    struct Stake {
        uint256 amount;
        uint256 releaseTimestamp;
    }
    
    mapping(address => Stake) private stakes;
    
    event StakeTokens(address indexed staker, uint256 amount, uint256 releaseTimestamp);
    event UnstakeTokens(address indexed staker, uint256 amount);
    event Burn(address indexed _from, uint256 _value);
    event ForceUnstakeBurn(address indexed _from, uint256 _value);
    event RewardAdded(address indexed user, uint256 amount);
    event StakeEnabled();
    event CompoundRewards(address indexed recipient, uint256 amount);
    event TokensReceived(address sender, uint256 amount);
    event PairCreated(address indexed token0, address indexed token1, address pair);
    
    constructor() {
        devWallet = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
        teamWallet = 0xC37F88Bec51c9c18b971FdF8B0dC2D93EE2913d9;
        marketingWallet = 0x8a06B97d744fF433E7576755455c50272286713D;
        nullAddress = address(0);
        
        // Allocate 3% of the total supply to the dev wallet
        uint256 devAllocation = totalSupply * 4 / 100;
        balances[teamWallet] = devAllocation;
        emit Transfer(address(0), teamWallet, devAllocation);
        lockTimestamps[teamWallet] = block.timestamp + devLockDuration;
        
        // Allocate 10% of the total supply to the marketing wallet
        uint256 marketingAllocation = totalSupply * 10 / 100;
        balances[marketingWallet] = marketingAllocation;
        emit Transfer(address(0), marketingWallet, marketingAllocation);
        
        // Allocate remaining tokens to the contract
        uint256 remainingTokens = totalSupply - devAllocation - marketingAllocation;
        balances[address(this)] = remainingTokens;
        emit Transfer(address(0), address(this), remainingTokens);
    }
    
    modifier onlyDev() {
        require(msg.sender == devWallet, "Only the dev wallet can call this function");
        _;
    }

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
        _;
    }
    
    function transfer(address to, uint256 value) external override returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        // Perform the transfer
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowances[from][msg.sender], "Allowance exceeded");
        require(to != address(0), "Invalid recipient");
        
        // Decrease the allowance
        allowances[from][msg.sender] -= value;
        
        // Perform the transfer
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        require(!reentrancyGuard, "Reentrant call detected");
        reentrancyGuard = true;

        if (from == teamWallet && lockTimestamps[teamWallet] + devLockDuration > block.timestamp) {
            require(false, "Team wallet locked");
        }

        // Check if the transfer is for liquidity provision, if yes no tax applied
        bool isLiquidityTransfer = (from == address(this) && to == liquidityPairAddress);

        if (!isLiquidityTransfer) {
            // Perform burn tax calculation and burning
            uint256 burnTax = calculateBurnTax(value);
            balances[nullAddress] += burnTax;
            emit Burn(nullAddress, burnTax);

            // Deduct burnTax from totalSupply
            totalSupply -= burnTax;
            
            balances[from] -= value;
            balances[to] += value - burnTax;
            emit Transfer(from, to, value - burnTax);
        } else {
            // Transfer without tax for liquidity provision
            balances[from] -= value;
            balances[to] += value;
            emit Transfer(from, to, value);
        }

        // Reentrancy guard release
        reentrancyGuard = false;
    }    
    
    function calculateBurnTax(uint256 value) private returns (uint256) {
        // Check if total supply is below burnTaxThreshold1
        // If so, set burnTaxPercent to 2%
        if (totalSupply <= burnTaxThreshold1) {
            burnTaxPercent = 2;
        }
        // Check if total supply is below burnTaxThreshold2
        // If so, set burnTaxPercent to 1%
        else if (totalSupply <= burnTaxThreshold2) {
            burnTaxPercent = 1;
        }
        
        uint256 burnTax = value * burnTaxPercent / 100;
        
        return burnTax;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    function approve(address spender, uint256 value) external override returns (bool) {
        require(spender != address(0), "Invalid spender");
        require(spender != msg.sender, "Cannot approve own address");
        
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveInternal(address spender, uint256 value) internal returns (bool) {
        require(spender != address(0), "Invalid spender");
        require(spender != msg.sender, "Cannot approve own address");
        
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }
    
    function getRemainingDevLockTime() external view returns (uint256, uint256, uint256, uint256) {
        uint256 lockTimestamp = lockTimestamps[teamWallet];
        uint256 unlockTimestamp = lockTimestamp;
        uint256 remainingTime = unlockTimestamp > block.timestamp ? unlockTimestamp - block.timestamp : 0;

        uint256 daysRemaining = remainingTime / 1 days;
        uint256 hoursRemaining = (remainingTime % 1 days) / 1 hours;
        uint256 minutesRemaining = (remainingTime % 1 hours) / 1 minutes;
        uint256 secondsRemaining = (remainingTime % 1 minutes) / 1 seconds;

        return (daysRemaining, hoursRemaining, minutesRemaining, secondsRemaining);
    }

    function enableStaking() external onlyDev {
        require(!stakingEnabled, "Staking is already enabled");
        stakingEnabled = true;
        emit StakeEnabled();
    }
        
    function stakeTokens(uint256 amount) external {
        require(stakingEnabled, "Staking is not enabled");
        require(amount > 0, "Invalid stake amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Calculate the maximum stake amount (1% of circulating supply)
        uint256 maxStakeAmount = (totalSupply * 1) / 100;

        require(amount <= maxStakeAmount, "Stake amount exceeds limit");

        uint256 releaseTimestamp = 0;
        //if user has a very very special nft level 6
        //stake instead of being 28 days becomes 21 days
        if (nftLevels[msg.sender] == 6) {
            releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        // Deduct the tokens from the sender's balance
        balances[msg.sender] -= amount;

        totalStakedAmount += amount;

        // Remove the staked tokens from circulation
        totalSupply -= amount;

        // Stake the tokens
        stakes[msg.sender] = Stake(amount, releaseTimestamp);

        emit Transfer(msg.sender, address(0), amount);
        emit StakeTokens(msg.sender, amount, releaseTimestamp);
    }

    function unstakeRewardsOnly() external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = stake.amount * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
            reward += boostReward;
        }

        // Check if the contract has enough balance to pay rewards
        if (reward > balances[address(this)]) {
            // If contract balance is below the rewards amount, it will mint new tokens in order to pay for it
            // This is the only time tokens might be minted
            uint256 shortage = reward - balances[address(this)];
            totalSupply += shortage;
            balances[address(this)] += shortage;
        }

        // Add the rewards to the sender's balance
        balances[msg.sender] += reward;

        // Reset the release timestamp for the stake
        if (nftLevels[msg.sender] == 6) {
            stake.releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            stake.releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        emit RewardAdded(msg.sender, reward);
    }

    function compoundRewards() external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
            reward += boostReward;
        }

        // Check if the contract has enough balance to pay rewards
        if (reward > balances[address(this)]) {
            // If contract balance is below the rewards amount, it will mint new tokens in order to pay for it
            // This is the only time tokens might be minted
            uint256 shortage = reward - balances[address(this)];
            totalSupply += shortage;
            balances[address(this)] += shortage;
        }

        // Remove the compounded rewards from circulation
        totalSupply -= reward;
        totalStakedAmount += reward;

        // Add the rewards to the sender's stake
        stake.amount += reward;

        // Reset the release timestamp for the stake
        if (nftLevels[msg.sender] == 6) {
            stake.releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            stake.releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        emit CompoundRewards(msg.sender, reward);
        emit Transfer(address(0), address(this), reward);
    }

    function unstakeTokens() external {
        Stake memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;
        uint256 burnAmount = stake.amount * stakeBurnPercent / 100;
        uint256 unstakeAmount = stake.amount;

        // Deduct the burn amount from the rewards
        reward -= burnAmount;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = unstakeAmount * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
            reward += boostReward;
        }

        // Check if the contract has enough balance to pay rewards
        if (reward > balances[address(this)]) {
            // If contract balance is below the rewards amount, it will mint new tokens in order to pay for it
            // This is the only time tokens might be minted
            uint256 shortage = reward - balances[address(this)];
            totalSupply += shortage;
            balances[address(this)] += shortage;
        }

        // Add the staked tokens from circulation
        totalSupply += unstakeAmount;

        // Add the rewards to the sender's balance
        balances[msg.sender] += reward;

        // Transfer the unstaked tokens to the sender
        balances[msg.sender] += unstakeAmount;
        totalStakedAmount -= stake.amount;

        // Burn the tax
        totalSupply -= burnAmount;

        // Reset the stake
        delete stakes[msg.sender];

        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
        emit RewardAdded(msg.sender, reward);
        emit Burn(address(this), burnAmount);
    }

    function forceUnstakeTokens() external {
        Stake memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");

        uint256 unstakeAmount = stake.amount;
        uint256 burnAmount = unstakeAmount * 30 / 100; // 30% burn tax

        // Deduct the burn amount from the staked amount
        unstakeAmount -= burnAmount;

        // Burn the tax
        totalSupply -= burnAmount;

        // Add the staked tokens back to circulation
        totalSupply += unstakeAmount;

        // Transfer the unstaked tokens to the sender
        balances[msg.sender] += unstakeAmount;

        // Reset the stake
        delete stakes[msg.sender];

        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
        emit ForceUnstakeBurn(address(this), burnAmount);
    }

    function getStakedAmountAndTimeRemaining(address account) public view returns (uint256, uint256, uint256, uint256, uint256) {
        Stake memory stake = stakes[account];
        require(stake.amount > 0, "No stakes found");

        uint256 releaseTimestamp = stake.releaseTimestamp;
        uint256 currentTimestamp = block.timestamp;

        uint256 timeRemaining = 0;
        if (currentTimestamp < releaseTimestamp) {
            timeRemaining = releaseTimestamp - currentTimestamp;
        }

        uint256 daysRemaining = timeRemaining / DAY_SECONDS;
        timeRemaining -= daysRemaining * DAY_SECONDS;

        uint256 hoursRemaining = timeRemaining / 3600;
        timeRemaining -= hoursRemaining * 3600;

        uint256 minutesRemaining = timeRemaining / 60;
        uint256 secondsRemaining = timeRemaining - minutesRemaining * 60;

        return (stake.amount, daysRemaining, hoursRemaining, minutesRemaining, secondsRemaining);
    }    

    function setNFTContract(address _nftContract) external onlyDev {
        nftContract = _nftContract;
    }

    function setNFTLevel(address account, uint256 level) external onlyNFTContract {
        // Set the NFT level for a specific address
        require(level >= 0 && level <= 6, "Invalid NFT level");
        nftLevels[account] = level;
    }

    function clearNFTLevel(address account) external onlyNFTContract {
        // Check if the address has an existing NFT level
        require(nftLevels[account] != 0, "No NFT level set for the address");

        // Clear the NFT level for the specified address
        delete nftLevels[account];
    }    

    function burnTokens(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return totalStakedAmount;
    }

    function createPair() external onlyDev {
        require(IUniswapV2Factory(factory).getPair(address(this), MATIC_TOKEN) == address(0), "Pair already created");
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(factory);
        liquidityPairAddress = uniswapFactory.createPair(address(this), MATIC_TOKEN);
    }

    function addLiquidity(uint256 amountStellarToken, uint256 amountMaticDesired) external onlyDev {
        require(amountStellarToken > 0, "Amount of StellarToken must be greater than zero");
        require(amountMaticDesired > 0, "Amount of MATIC must be greater than zero");

        // Check if the pair has already been created
        require(IUniswapV2Factory(factory).getPair(address(this), MATIC_TOKEN) != address(0), "Pair not yet created");

        // Check if the contract has sufficient balance of StellarToken
        require(IERC20(address(this)).balanceOf(address(this)) >= amountStellarToken, "Insufficient StellarToken balance");

        // Check if the contract has sufficient balance of MATIC
        require(IERC20(MATIC_TOKEN).balanceOf(address(this)) >= amountMaticDesired, "Insufficient MATIC balance");

        // Approve the router to spend the tokens
        IERC20(address(this)).approve(router, amountStellarToken);
        IERC20(MATIC_TOKEN).approve(router, amountMaticDesired);

        // Add liquidity
        IUniswapV2Router02(router).addLiquidity(
            address(this),
            MATIC_TOKEN,
            amountStellarToken,
            amountMaticDesired,
            0,
            0,
            liquidityPairAddress,
            block.timestamp
        );
    }

    function removeLiquidity(uint256 liquidity) external onlyDev {
        require(liquidity > 0, "Liquidity amount must be greater than zero");

        // Get the pair address
        address pair = IUniswapV2Factory(factory).getPair(address(this), MATIC_TOKEN);
        require(pair != address(0), "Pair not found");

        // Approve the router to spend LP tokens
        IERC20(pair).approve(router, liquidity);

        // Remove liquidity
        (uint256 amountStellarToken, uint256 amountMatic) = IUniswapV2Router02(router).removeLiquidity(
            address(this),
            MATIC_TOKEN,
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        // Transfer the amount of MATIC to the dev wallet address
        IERC20(MATIC_TOKEN).transfer(devWallet, amountMatic);

        // Transfer the amount of StellarToken back to the contract
        IERC20(address(this)).transferFrom(address(this), address(this), amountStellarToken);
    }

    function getPairLiquidity() external view returns (uint256 reserveStellarToken, uint256 reserveMatic) {
        // Get the pair address
        address pair = IUniswapV2Factory(factory).getPair(address(this), MATIC_TOKEN);
        require(pair != address(0), "Pair not found");

        // Get the reserves of the tokens in the pair
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();

        // Determine the order of the reserves based on the token addresses
        (address token0, ) = sortTokens(address(this), MATIC_TOKEN);

        // Assign the correct reserve values based on the token order
        if (token0 == address(this)) {
            reserveStellarToken = reserve0;
            reserveMatic = reserve1;
        } else {
            reserveStellarToken = reserve1;
            reserveMatic = reserve0;
        }

        return (reserveStellarToken, reserveMatic);
    }

    // Helper function to sort the token addresses in ascending order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getLPTokenBalance() external view returns (uint256) {
        IERC20 lpToken = IERC20(liquidityPairAddress);
        return lpToken.balanceOf(address(this));
    }

    receive() external payable {
        emit TokensReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./StellarToken.sol";

contract StellarTokenNFT is ERC721URIStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    address public owner;
    StellarToken public stellarTokenContract;
    mapping(address => EnumerableSet.UintSet) private ownedTokens;
    mapping(address => uint8) public levelOfAddress;
    mapping(uint256 => uint256) public tokenIdToPrice;
    mapping(uint256 => address) private tokenIndexToAddress;
    EnumerableSet.UintSet private availableTokens;

    uint256 public totalSupply;
    uint256 public nextTokenId;
    uint256 public mintPrice = 0.001 ether;
    uint256 public mintedCount;
    address payable marketingWallet;

    event NFTMinted(address indexed recipient, uint8 level);
    event NFTPriceSet(uint256 tokenId, uint256 price);
    event NFTBought(uint8 tokenId, address indexed buyer, uint256 amount);
    event TokensReceived(address sender, uint256 amount);

    constructor(string memory name, string memory symbol, address payable _marketingWallet) ERC721(name, symbol) {
        mintedCount = 0;
        owner = msg.sender;
        marketingWallet = _marketingWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setStellarTokenContract(address payable _stellarTokenContract) external onlyOwner {
        stellarTokenContract = StellarToken(_stellarTokenContract);
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function mintNFT(uint256 quantity) external payable {
        require(address(stellarTokenContract) != address(0), "StellarToken contract not set");
        require(totalSupply + quantity <= 100001, "Exceeds supply");
        require(msg.value >= mintPrice * quantity, "Insufficient funds");
        address recipient = msg.sender;

        marketingWallet.transfer(mintPrice * quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint8 level = getRandomLevel();
            string memory rarity = getRarity(level);

            uint8 currentLevel = levelOfAddress[recipient];
            if (level > currentLevel) {
                stellarTokenContract.setNFTLevel(recipient, level);
            }

            _safeMint(recipient, nextTokenId);
            ownedTokens[recipient].add(nextTokenId);

            if(level == 1) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(), '', '', '', '');
            }

            if(level == 2) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(), '', '', '');
            }
            if(level == 3) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(), '', '');
            }
            if(level == 4) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(),
                    getRandomMeteorFilename(), '');
            }
            if(level == 5 || level == 6) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(),
                    getRandomMeteorFilename(),
                    getRandomSatelliteFilename());
            }

            levelOfAddress[recipient] = level;
            availableTokens.add(nextTokenId);
            totalSupply++;
            nextTokenId++;
            mintedCount++;

            emit NFTMinted(recipient, level);
        }
    }

    function mintNFTDev(uint256 quantity, uint8 level) external payable onlyOwner {
        require(address(stellarTokenContract) != address(0), "StellarToken contract not set");
        require(totalSupply + quantity <= 100001, "Exceeds supply");
        require(msg.value >= mintPrice * quantity, "Insufficient funds");
        address recipient = msg.sender;

        marketingWallet.transfer(mintPrice * quantity);

        for (uint256 i = 0; i < quantity; i++) {
            string memory rarity = getRarity(level);

            uint8 currentLevel = levelOfAddress[recipient];
            if (level > currentLevel) {
                stellarTokenContract.setNFTLevel(recipient, level);
            }

            _safeMint(recipient, nextTokenId);
            ownedTokens[recipient].add(nextTokenId);

            if(level == 1) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(), '', '', '', '');
            }

            if(level == 2) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(), '', '', '');
            }
            if(level == 3) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(), '', '');
            }
            if(level == 4) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(),
                    getRandomMeteorFilename(), '');
            }
            if(level == 5 || level == 6) {
                tokenIdToMetadata[nextTokenId] = NFTMetadata(
                    level, 
                    rarity, 
                    getRandomBackground(), 
                    getRandomSpaceshipFilename(),
                    getRandomPlanetFilename(),
                    getRandomSmallPlanetFilename(),
                    getRandomMeteorFilename(),
                    getRandomSatelliteFilename());
            }

            levelOfAddress[recipient] = level;
            availableTokens.add(nextTokenId);
            totalSupply++;
            nextTokenId++;
            mintedCount++;

            emit NFTMinted(recipient, level);
        }
    }

    struct NFTMetadata {
        uint8 level;
        string rarity;
        string background_url;
        string spaceship_url;
        string planet_1_url;
        string planet_2_url;
        string meteor_url;
        string satelite_url;
    }

    function setNFTPrice(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Must > zero");

        tokenIdToPrice[tokenId] = price;

        emit NFTPriceSet(tokenId, price);
    }

    function buyNow(uint8 tokenId) external payable {
        require(tokenIdToPrice[tokenId] > 0, "Not for sale");
        require(msg.value >= tokenIdToPrice[tokenId], "Insufficient funds");

        address seller = ownerOf(tokenId);
        uint8 level = levelOfAddress[msg.sender];
        uint8 highestLevel = findHighestLevel(msg.sender);

        if (level > highestLevel) {
            highestLevel = level;
            levelOfAddress[msg.sender] = highestLevel;

            stellarTokenContract.setNFTLevel(msg.sender, highestLevel);
        }

        uint8 highestLevelSeller = findHighestLevel(seller);
        if(highestLevelSeller > 0) {
            stellarTokenContract.setNFTLevel(seller, highestLevelSeller);
        } else {
            stellarTokenContract.clearNFTLevel(seller);
        }

        _transfer(seller, msg.sender, tokenId);
        ownedTokens[seller].remove(tokenId);
        ownedTokens[msg.sender].add(tokenId);
        availableTokens.remove(tokenId);

        payable(seller).transfer(msg.value);

        emit NFTBought(tokenId, msg.sender, msg.value);
    }    

    function findHighestLevel(address addr) internal view returns (uint8) {
        EnumerableSet.UintSet storage tokens = ownedTokens[addr];
        uint8 highestLevel;

        for (uint256 i = 0; i < tokens.length(); i++) {
            uint256 tokenId = tokens.at(i);
            address tokenAddress = ownerOf(tokenId);
            uint8 level = levelOfAddress[tokenAddress];
            if (level > highestLevel) {
                highestLevel = level;
            }
        }

        return highestLevel;
    }

    function getOwnedTokens(address addr) external view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](ownedTokens[addr].length());
        for (uint256 i = 0; i < ownedTokens[addr].length(); i++) {
            tokens[i] = ownedTokens[addr].at(i);
        }
        return tokens;
    }

    function getRandomLevel() internal view returns (uint8) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nextTokenId)));
        uint8 level;

        if (randomNumber % 1000 < 5) {
            level = 6; // 0.5% chance for level 6
        } else if (randomNumber % 1000 < 30) {
            level = 5; // 2.5% chance for level 5
        } else if (randomNumber % 1000 < 80) {
            level = 4; // 5% chance for level 4
        } else if (randomNumber % 1000 < 230) {
            level = 3; // 15% chance for level 3
        } else if (randomNumber % 1000 < 500) {
            level = 2; // 27% chance for level 2
        } else {
            level = 1; // 50% chance for level 1
        }

        return level;
    }

    function getRarity(uint8 level) internal pure returns (string memory) {
        if (level == 6) {
            return "Legendary";
        } else if (level == 5) {
            return "Epic";
        } else if (level == 4) {
            return "Rare";
        } else if (level == 3) {
            return "Uncommon";
        } else if (level == 2) {
            return "Common";
        } else {
            return "Basic";
        }
    }

    mapping(uint256 => NFTMetadata) public tokenIdToMetadata;

    function getRandomBackground() public view returns (string memory) {
        string[8] memory filenames = [
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_01.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_02.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_03.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_04.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_05.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_06.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_07.png" height="400" width="400" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/background/background_08.png" height="400" width="400" />'
        ];
        
        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }

    function getRandomSpaceshipFilename() public view returns (string memory) {
        string[15] memory filenames = [
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_01.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_02.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_03.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_04.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_05.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_06.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_07.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_08.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_09.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_10.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_11.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_12.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_13.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_14.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/spaceships/spaceship_15.png" x="50%" y="50%" width="150" height="150" transform="translate(-75, -75)" />'
        ];

        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }

    function getRandomPlanetFilename() public view returns (string memory) {
        string[8] memory filenames = [
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_01.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_02.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_03.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_04.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_05.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_06.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_07.png" x="280" y="30" width="85" height="85" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_08.png" x="280" y="30" width="85" height="85" />'
        ];

        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }

    function getRandomSmallPlanetFilename() public view returns (string memory) {
        string[8] memory filenames = [
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_05.png" x="10" y="210" width="45" height="45" />',            
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_04.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_02.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_07.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_08.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_03.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_01.png" x="10" y="210" width="45" height="45" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/planets/planet_06.png" x="10" y="210" width="45" height="45" />'
        ];

        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }

    function getRandomMeteorFilename() public view returns (string memory) {
        string[6] memory filenames = [
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_1.png" x="0" y="0" width="60" height="60" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_2.png" x="0" y="0" width="60" height="60" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_3.png" x="0" y="0" width="60" height="60" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_4.png" x="0" y="0" width="60" height="60" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_5.png" x="0" y="0" width="60" height="60" />',
            '<image href="https://stellartokennft.s3.amazonaws.com/meteors/meteor_6.png" x="0" y="0" width="60" height="60" />'
        ];

        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }

    function getRandomSatelliteFilename() public view returns (string memory) {
        string[5] memory filenames = [
            '<g id="seed" transform="translate(320,70)" stroke-width="2" stroke="black" fill="none"><image href="https://stellartokennft.s3.amazonaws.com/satelites/sat_1.png" x="32" width="30" height="30" class="white-glow" /><animateTransform attributeType="xml" attributeName="transform" type="rotate" values="0 0 0; 360 0 0" dur="15s" additive="sum" repeatCount="indefinite" /></g>',
            '<g id="seed" transform="translate(320,70)" stroke-width="2" stroke="black" fill="none"><image href="https://stellartokennft.s3.amazonaws.com/satelites/sat_2.png" x="32" width="30" height="30" class="white-glow" /><animateTransform attributeType="xml" attributeName="transform" type="rotate" values="0 0 0; 360 0 0" dur="15s" additive="sum" repeatCount="indefinite" /></g>',
            '<g id="seed" transform="translate(320,70)" stroke-width="2" stroke="black" fill="none"><image href="https://stellartokennft.s3.amazonaws.com/satelites/sat_3.png" x="32" width="30" height="30" class="white-glow" /><animateTransform attributeType="xml" attributeName="transform" type="rotate" values="0 0 0; 360 0 0" dur="15s" additive="sum" repeatCount="indefinite" /></g>',
            '<g id="seed" transform="translate(320,70)" stroke-width="2" stroke="black" fill="none"><image href="https://stellartokennft.s3.amazonaws.com/satelites/sat_4.png" x="32" width="30" height="30" class="white-glow" /><animateTransform attributeType="xml" attributeName="transform" type="rotate" values="0 0 0; 360 0 0" dur="15s" additive="sum" repeatCount="indefinite" /></g>',
            '<g id="seed" transform="translate(320,70)" stroke-width="2" stroke="black" fill="none"><image href="https://stellartokennft.s3.amazonaws.com/satelites/sat_5.png" x="32" width="30" height="30" class="white-glow" /><animateTransform attributeType="xml" attributeName="transform" type="rotate" values="0 0 0; 360 0 0" dur="15s" additive="sum" repeatCount="indefinite" /></g>'
        ];

        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % filenames.length;
        
        return filenames[randIndex];
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI nonexistent");

        string[10] memory parts;
        uint8 level = tokenIdToMetadata[tokenId].level;
        

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400">';
        parts[1] = "<defs><style>@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P');.base{font-family:'Press Start 2P',Roboto;font-size:15px;fill:#fff;}.small{font-family:'Press Start 2P',Roboto;font-size:10px;fill:#fff;}.flipper{animation:flip 4s cubic-bezier(0.4,0,0.3,1) infinite;transform-origin:center;transform-box:fill-box;filter:drop-shadow(0 5px 5px gold);opacity:0.8;}@keyframes flip{0%{transform:scaleX(1) translateX(0);}20%{transform:scaleX(-1) translateX(0);}80%{transform:scaleX(-1) translateX(0);}100%{transform:scaleX(1) translateX(0);}}.white-glow{filter:drop-shadow(0 0 5px white);}</style></defs>";
        parts[2] = tokenIdToMetadata[tokenId].background_url;
        parts[3] = tokenIdToMetadata[tokenId].spaceship_url;

        parts[4] = '';
        if(level >= 2) {
            parts[4] = tokenIdToMetadata[tokenId].planet_1_url;
        }
        parts[5] = '';
        if(level >= 3) {
            parts[5] = tokenIdToMetadata[tokenId].planet_2_url;
        }
        parts[6] = '';
        if(level >= 4) {
            parts[6] = tokenIdToMetadata[tokenId].meteor_url;
        }
        parts[7] = '';
        if(level >= 5) {
            parts[7] = tokenIdToMetadata[tokenId].satelite_url;
        }
        parts[8] = '';
        if(level == 6) {
            parts[8] = '<image href="https://stellartokennft.s3.amazonaws.com/logo/top_banner.png" x="10" y="340" width="40" height="40" class="flipper" />';
        }
        
        parts[9] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', toString(tokenId), '", "Level": "', toString(tokenIdToMetadata[tokenId].level), '", "Rarity": "', tokenIdToMetadata[tokenId].rarity, '", "image": "data:image/png;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function getMintedCount() external view returns (uint256) {
        return mintedCount;
    }

    receive() external payable {
        // Your implementation code here
        // This function will be called when the contract receives tokens
        
        // Emit the event to log the tokens received
        emit TokensReceived(msg.sender, msg.value); // Assuming the tokens have a 1:1 mapping with Ether value
    }
}