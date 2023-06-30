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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SignumEtnaSNFT2023 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
 /***********************************************************************************************************************************
  **                                                                                                                               **
  ** SIGNUM ETNA 2023 COLLECTIONS AVAILABLE AT: https://gateway.pinata.cloud/ipfs/QmTNhGLKSecGFepGL7z3q1wA8p3UhNZ3fXQ2wZjt6jxMJF/  **
  **                                                                                                                               **
  **                   ************************************************************************************                        **
  **                   *                      ***   IDENTITY CARD OF THE WINE   ***                       *                        **
  **                   *                                                                                  *                        **
  **                   *  Date of harvesting: October 6, 2015                                             *                        **
  **                   *  Fermentation and maceration: October 6, 2015                                    *                        **
  **                   *  The end of maceration and racking: October 21, 2015                             *                        **
  **                   *  The end of malolactic fermentation: November 10, 2015                           *                        **
  **                   *  The beginning of aging in Tonneaux: January 10, 2016                            *                        **
  **                   *  The bottling: August 8, 2019 (N° 2436 L.719)                                    *                        **
  **                   *  Certification Etna DOC Riserva n. 388/2023 for Bott. N. 2436: February 9, 2023  *                        **
  **                   ************************************************************************************                        **
  **                                                                                                                               **
  ************************************************************************************************************************************/   
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address private _contractOwner;
    uint private constant _TOTAL = 2436;
    uint private constant _SERVICES_DISABLED = 0;
    uint private constant _SERVICES_ENABLED = 1;
    uint private constant _STATUS_KO = 1;
    uint private constant _STATUS_OK = 0;    
    struct Bottle {        
        uint256 tokenId;
        uint startDate;        
        uint status;
        uint services;        
        address [] ownerHistory;
    }
    Bottle[_TOTAL] private _collection;    

    modifier onlyContractOwner() {
        require(msg.sender == _contractOwner, "Operation not allowed, caller is not the contract owner");
        _;
    }
    
    modifier before(uint idBottle, string memory verificationCode) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        require(_verifyCode(idBottle, verificationCode), "Verification Code is not valid");
        _;
    }
    
    modifier beforeRegister(uint idBottle, string memory verificationCode) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        require(_verifyCode(idBottle, verificationCode), "Verification Code is not valid");
        require(_collection[idBottle-1].status == _STATUS_OK, "Operation not allowed, status KO");
        require(_collection[idBottle-1].services == _SERVICES_DISABLED, "Operation not allowed, services already active");
        _;
    }

    modifier beforeUpdateTokenUri(uint idBottle, string memory verificationCode) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        require(_verifyCode(idBottle, verificationCode), "Verification Code is not valid");
        require(_collection[idBottle-1].status == _STATUS_OK, "Operation not allowed, status KO");
        require(_collection[idBottle-1].services == _SERVICES_ENABLED, "Operation not allowed, services disabled");
        _;
    }

    constructor() ERC721("Signum Etna S-NFT 2023", "SESNFT2023") {_contractOwner = msg.sender;}

    function registerBottle(address to, string memory uri, uint idBottle, string memory verificationCode) public onlyContractOwner beforeRegister(idBottle, verificationCode) {        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _collection[idBottle-1].tokenId = tokenId;
        _collection[idBottle-1].startDate = block.timestamp;        
        _collection[idBottle-1].services = _SERVICES_ENABLED;
        _collection[idBottle-1].ownerHistory.push(to);
    }

    function updateTokenUriBottle(string memory uri, uint idBottle, string memory verificationCode) public onlyContractOwner beforeUpdateTokenUri(idBottle, verificationCode) {                
        _setTokenURI( _collection[idBottle-1].tokenId, uri);
    }
    
    function disableServicesBottle(uint idBottle, string memory verificationCode) public onlyContractOwner before(idBottle, verificationCode) {        
        _collection[idBottle-1].services = _SERVICES_DISABLED;        
    }

    function enableServicesBottle(uint idBottle, string memory verificationCode) public onlyContractOwner before(idBottle, verificationCode) {
        _collection[idBottle-1].services = _SERVICES_ENABLED;
    }
    
    function destroyBottle(uint idBottle, string memory verificationCode) public onlyContractOwner before(idBottle, verificationCode) {
        _collection[idBottle-1].status = _STATUS_KO;
        _collection[idBottle-1].services = _SERVICES_DISABLED;
    }

    function restoreBottle(uint idBottle, string memory verificationCode) public onlyContractOwner before(idBottle, verificationCode) {
        _collection[idBottle-1].status = _STATUS_OK;
    }

    function updateOwnerHistory(uint idBottle, string memory verificationCode, address owner) public onlyContractOwner before(idBottle, verificationCode) {        
        _collection[idBottle-1].ownerHistory.push(owner);
    }

    function getStatusOf(uint idBottle) public view onlyContractOwner returns (uint) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        /* 0 --> OK, 1 --> KO*/
        return _collection[idBottle-1].status;
    }

    function getServiceOf(uint idBottle) public view onlyContractOwner returns (uint) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        /* 0 --> DISABLED, 1 --> ENABLED*/
        return _collection[idBottle-1].services;
    }

    function getOwnerHistory(uint idBottle) public view onlyContractOwner returns (address[] memory) {        
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        return _collection[idBottle-1].ownerHistory;
    }

    function getTokenIdOf(uint idBottle) public view onlyContractOwner returns (uint) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        require(_collection[idBottle-1].services == _SERVICES_ENABLED, "Operation not allowed, services disabled");
        return _collection[idBottle-1].tokenId;
    }

    function getBottleOfTokenId(uint tokenId) public view onlyContractOwner returns (int) {
        for (uint i=0; i<_TOTAL; i++) {
            if (_collection[i].services ==_SERVICES_ENABLED && tokenId == _collection[i].tokenId) {
                return int(i+1);
            }
        }
        return -1;
    }

    function getStartDateOf(uint idBottle) public view onlyContractOwner returns (uint) {
        require(idBottle > 0 && idBottle <= _TOTAL, "ID is not part of collection");
        require(_collection[idBottle-1].services == _SERVICES_ENABLED, "Operation not allowed, services disabled");
        return _collection[idBottle-1].startDate;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)        
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)        
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)        
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // END The following functions are overrides required by Solidity.   

    function _verifyCode(uint idBottle, string memory verificationCode) private pure returns (bool) {
        if (idBottle >= 1 && idBottle<=200)
            return SignumEtna2023Collection_1_200.verifyBottleCode(idBottle-1, verificationCode);
        if (idBottle >= 201 && idBottle<=400)
            return SignumEtna2023Collection_201_400.verifyBottleCode(idBottle-200-1, verificationCode);
        if (idBottle >= 401 && idBottle<=600)
            return SignumEtna2023Collection_401_600.verifyBottleCode(idBottle-400-1, verificationCode);
        if (idBottle >= 601 && idBottle<=800)
            return SignumEtna2023Collection_601_800.verifyBottleCode(idBottle-600-1, verificationCode);
        if (idBottle >= 801 && idBottle<=1000)
            return SignumEtna2023Collection_801_1000.verifyBottleCode(idBottle-800-1, verificationCode);
        if (idBottle >= 1001 && idBottle<=1200)
            return SignumEtna2023Collection_1001_1200.verifyBottleCode(idBottle-1000-1, verificationCode);
        if (idBottle >= 1201 && idBottle<=1400)
            return SignumEtna2023Collection_1201_1400.verifyBottleCode(idBottle-1200-1, verificationCode);
        if (idBottle >= 1401 && idBottle<=1600)
            return SignumEtna2023Collection_1401_1600.verifyBottleCode(idBottle-1400-1, verificationCode);
        if (idBottle >= 1601 && idBottle<=1800)
            return SignumEtna2023Collection_1601_1800.verifyBottleCode(idBottle-1600-1, verificationCode);
        if (idBottle >= 1801 && idBottle<=2000)
            return SignumEtna2023Collection_1801_2000.verifyBottleCode(idBottle-1800-1, verificationCode);
        if (idBottle >= 2001 && idBottle<=2200)
            return SignumEtna2023Collection_2001_2200.verifyBottleCode(idBottle-2000-1, verificationCode);
        if (idBottle >= 2201 && idBottle<=2400)
            return SignumEtna2023Collection_2201_2400.verifyBottleCode(idBottle-2200-1, verificationCode);
        if (idBottle >= 2401 && idBottle<=2436)
            return SignumEtna2023Collection_2401_2436.verifyBottleCode(idBottle-2400-1, verificationCode);
        return false;
    }
}

library Utils {
    function compare(string memory str1, string memory str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}

library SignumEtna2023Collection_1_200 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"d29a11e5d720162dce145c1e2f6347bef96cc9a71e912691c3e746cc7f9adb8f",
"872b52f7b715d50167a0b56fea6b0b3344f9e300d08603798c82965d7c1dc633",
"9365d6fbb19d92cc81eab45b4ae1a70341c9edefe26d880af402fa378f003c08",
"99c7fab27397a1cbda85adc580002dee3df12cfd0154955fd051b5dba44b600e",
"fb54eb7c4aa10e9a7f736d4c6f1aac0dba54b70c9c3d647d30699a13d5ec0fcc",
"b0a45655ed101d03d12008521ff8e706919762cdc2a380c3c8e424b23cf2844b",
"ea4b82396e87143164426dbdad05a5504459b7fbdfbe6f4ffa9158789dc80247",
"adc5125bbfb2d5989a78b61d3c772a88ac5b252797f9bfa977e05c3366a2166e",
"6f1fdad9013006d572892ae700eeaaaa7ab99b22523d311f9b0bc1181c7003df",
"1143d31ee0aaeff35177738d3d58ba808c100d52b3120646c1ccff321106c48c",
"34fec1a3b8971417a701465485eae6fa8b7c0acd11a11a562cbc90ee5c97c753",
"93d7f6f9ea24a95760c1539a518bb86db74a68c82f3fc216af490f01357422e2",
"ef6184d982c5b9bd1005e37373c89839b61925590709e9cade9490e7bec4df6c",
"b156e06a9405df00475678ca19ddf4151e459a8fd272ee6c0353eb812d611dd6",
"478df1b841789464ef00e55ec06f67a1f380793aff7d12f6a6c3b059bf968921",
"7d566eca3b55da3ed88dbf86928b07cde0805f3feed2da0037e0f8a521292adc",
"64811b078047f166a751e858efb3f4d7f64507430828bfad9b9e01f4cfa45381",
"7c6e75126160c7511bfbebf6c8e5e9c26b1496afb1d2ea1cd35edfb29a8e442a",
"72e4a88d3d2dd28de8515c84b19080eb11c532bf94e2265012cc10289a66b9d3",
"ce47470cc6b2dd855bfa2f4f7f4c85070291a94a6d22717df832aed20355dba5",
"792e18a2dd0cccb7ccb5186e10680452ba16fb2f910d91805917da090c70caf7",
"893cfefc5e8da9dfc4f1ea1f920c9a75484d3eeee37ead9b22f492da3f06c70b",
"f2dc3482f037df3bd29814bcfddcdd7df1bb3460c00537e77fec029ba99eaa31",
"aad06996554ffdddf7ba16271a3302e9f7963fe64e2d782c57c25fd81fda8b2e",
"e95871a6831863c74a91a7eb4df3124aff5a27ca505f84de8be64d9cd2682818",
"1fbc1fc835245a20cfcb316dc66a583f3e71df8175c4534243b48b0e7277ac1a",
"4cec009d826ad2b1560e32f0dea36a048744d0a72798708ec3dd78f3fda1cb16",
"137e73d605fc5e92a96f8145367980a99bdd1337d3dfb3d1c1b993802b525011",
"7c5661e42b5f634656715c2cc5f7bc28be1c897c23ce5cb8e72e5a82bcb9cf59",
"c355000fd729a71eddcbf07da2a0c212a2f0717e8f30c40268a4f182b80a0adf",
"8046581d506756914e139f99d5f15bd8d157c6f750a043df2282f011cf8d13cf",
"dda74bf06281c9a1124666b54bd8739c453929ea93c6d239449301fe235b0fc2",
"d2417affd995fe1d297d145929c40747d6f0cbe913d8035e4028c342d886d219",
"b2db010d0cc204c392a6c8438be68811fcb1478949fa8ba0c94a8cb3522041ed",
"ebe0e223eb8bd3ea35e97bbdbf64587a95e463878d6cc0c3f5882300f9329abb",
"d402f06eb3b1ebda5632c466dfa90c7680abdfe25db75db5a93c4fa7ac341bca",
"2fedbef8633aa9099496d3c4f5cae2e582bf0a6586d5dbde297bd3253177f82f",
"1b2fa553847aeaf482b648a2a4849674f24325168aeb3605ade50ae507cda286",
"ff45e19e1588bdff2497bdbe20957f74e5494dc78f936c2f995d1fb6b6683ca0",
"c239c216f8ec27c7453850ec9bd64254b616221b13537374b6c2bf80018e8929",
"4208c990748a9051dc4f3dd9b2b061a6d323f4bde3e8e15bbdc10862204ab9d5",
"ef33b1d227096dad934c5b7561236a118898401711b886e6f78ce6c316bbb053",
"f3193d70938f00528e9a4c57521affb2b3dc5b93ebf98ca4bad8e373ca6f4c82",
"5df4db09bf6aae197fba0d1bc44041ab1840f13a27cb98609634c7bea66d3d1a",
"229cdfe1f769b920bc05c6a56ebc94268fa292a2201c361ee33be45451f569c1",
"a21a35b70809a69d5beb8748767f461447babb68e8ab6c9ebc0e7d610fdb52b6",
"431e0a0ec46183bebde1baaa7608dd4abd128ab3602d2c8ab2a06044b7731b73",
"a1b452841b093d4d3cb3fd1007f8c4dead1f704cd41cf3e86e339837e891038b",
"0d41d3bb8a57ee52133d20d7b314e6933f1b3c9d2d905d3c03ca713f44e49f18",
"c382192b30010d4a4cc490d565b8eabc07f9446cfa9a848bf5b818cd1055af3c",
"6044d732224adf523d457b4c4fab6ed508cc1b6cff450da691b5e32a1a6a90ba",
"ed4cd1f71f35f3a2bec20a4897c4cd2ee554040e6db9d875a1b333185bd781c0",
"a6d93ae2f61fda76a52280e5fd606c38098b539743a04f37b98ac1e43beadfe9",
"3c9d9be300146f564f8fcb4e310d4aa237cef87f332036ebc6386fa1677743cb",
"1839ddfa9f7f77a63e01826e296224dca8d1e0880e3a5a1eb1370c4f1b65433c",
"c22887978e10612b1540d43fc721c3ccf9cf6d73483d2bd096a9ce0add18e9e8",
"2429dd870f45f4866647914c5e7366331f963a14fb33bd55660e40581e017e68",
"6fb679881e0b9bcc90e2bc92870d9fdbf7b4ae5801d7d4e1240ad3fbe31a2fb6",
"852618d2e8a4637ea24bfbc98efd9980c0482a1e92f2e21768e526ee2a84ad1e",
"090064c45a06b0ffef801bf086573fd298a717f86cb198dfe6e229f4802b8093",
"22a98df84c1801cd99b06f63b22324bc0d738c876ba6663bf49b1d6d7ec1ce37",
"fddf0128730f39ee648174713330d6a046ce1e9483b3af16b7f561be4413b4f7",
"ea22ab04d45012fe26385da6cc15a5d1a8f79a0b3b9f0563ff5318a63f5030f6",
"c6959be08a0e193ec2d54d51ce1fbf9fa2404f641bace0c04c362ae97d1365d0",
"7fbc49a8e8559c8ab283b3fccb63b0a3811fc05ab786fdf0bcc3aba4c14582f8",
"ad51f9d6115a4ba56438b76f4be72797d8be62232a8e784aa01e2cbfa7e448c3",
"c0c2f47ea36ebbd6c6494ded8421f3c46e43ff4fc80bb6f406ca5094efb498cf",
"f7d36d5bf38e32ff80b47448b132b690b9396f4adebd94ee96025571c6baf2d9",
"8e1fc95e947eebabe46f39f1ae76d9282d2c61ff7d3a99a66f3cd6860f60453c",
"436886946207cb2e6da50d6d6cfec915e34f76116f1e23cb01555cc2a68dcc2a",
"1c0622f66db76a2be51fcb0599c40dccb450f16f4b4a6703fde0d4be2eecfc84",
"2966c237ce1350eba8b1b4bb63571bd523339c90632f63abe154ab56ece11334",
"814e4117c985355f88657246db5ea66ca63ad5fd590a30b4cdbc32c95f5583d1",
"36e1bc4bf914dc9d4ea2b70ad3de542222edf59118318797ebda5d4925359e1f",
"d11332a3e88d8ec1206f0954c5fe57fc43867840b6d347a3104fdc88749ee010",
"2fca04a234425a68895ec420e904494ce07b31b19458daaa03b19d2dbb74c8d0",
"1b0d5009c7d76b45e55beec1a28d862a8ec0293fe97433104349784e992c2924",
"16b1ccbd668d0265e54a03f5000ebc67d02fb7c6451edbc4c2a62251885c6a01",
"23d7915a0d12514250843646671ccde022df3cf8abe9eaeb3cbe090393e37da6",
"02ea9442ab24c94c9373d5347072c061f1fd5abda9d9e915519252dd3c4dcd51",
"ca6b6e56e09f830b46b879933e6f1373c003e8eaa0f74013ae19b3eb046133d0",
"527c55cf4bbea018972b0714691a290708996cc58c65578e314c3c201cf74ab7",
"b04edf8431fb11515623b2ac71a58e83d65533ef4376d5cc55b5c04e5ec7e2a2",
"9a1eee2f2569d51a06ce029d57a3c691f04ba6a9903ef4c2be6584e4f69c1a31",
"da7285502fc7bdb1d9cf739f54297c79d317c88734990ccb5da914cedaafbb67",
"4a3bd80ac0302e71d8559756cdf3c5ee6c4847d69aab4191018a9fb59c3b827d",
"938e73af54666e5fa2f6b021ec87b88083ed5831f5115b8c40ccaaa7dbdafe0d",
"3f68a91ec55e3d192b05e93c1d5eb6a00564a2ac052a61dbcea221b2ae86999a",
"a8108b286b51121cdb1b7bcbf52b640c25ee74588d39a281ad875936defa771c",
"cbb96ff8c30985abc6b15f22527f8483ea5c14d035d7978f2006b5fbeebd178b",
"8dca5c2f25b73a79669d943bc06f1fc21a891fb5fd8161b6a37f97e91dd9eba8",
"864c01777e1288d95fe7859f8da98538a15b477a8b560555ef7df6a543876112",
"3b9fa3943fc208013280578a4b78c16b91e49ed54f274f872af82a3b7e59a629",
"b809425cbf5e4ade6627e27421fffc80819898e1c04ad2ca1834bc162a2e38b8",
"abbc58c28fbc2c89057c407588a29f21529fe88cd7664221f0cc79b9df8885ff",
"d85e38f8e38bc646a6a5448126836b1cc091b5713af6db7e40dfe2035213f73f",
"c28b18a7667fb6d655d53fff9c4d87c9d326eae26026d23ae27239519c1e37a1",
"bb50a7c5d66dc055763234b84c81ebbca88f26cfcc7ff7126a10ccd65bee2aee",
"a41d42ca59c8d0ea102a1c637c46d20f1258f1f2a0195218eef2a13b1f1cbe2d",
"8ea80054a1a97a91713af5d14a7b5af6c897ea6072d39273eda88ed19fc32e46",
"9661570aa87a1f8780584ace9c58f2c54322b8a152ff38e9b791826c4bed7383",
"8022a30436c59d5b409b05e76fc9d7c92e8ca3cd9a5ea3a63d8db5f8090349c4",
"1da76ae43729989c7bf12f96353e35dd672f7db190c35354282e8c14ba20cd36",
"424c1a6b5dae874d1f15023170a4924d5ee3235f1902b5840fdd1af64793f222",
"132292544f7232f5aa13dcdd26d7fae0d1bcd71f0035daaa78466ead1b980038",
"ca0ddd07026213a719476f7ad561b2ce9d0101f575b707d106bff8a8397894e9",
"609df257586b99a347e7ae0d5efa532ddd157cf557278375eb41123e89746354",
"a15460c4ba8b6aafe3379446e7221f315056bab8923799fcaa284ee8d98b0a60",
"7369f5d95cd351e52ec46603a9e4c961116859bdcccdb622561a4e4ece4931af",
"dc6114b93169be3e9749da03a9bd7b881facef0cd8bfa105cd51843da69db50c",
"e78981298ea851fa6d3083ffc34b4a1237466a96304a00fd66bc4f4854c99528",
"5dfdd9457541602a9a709751cc8954cac0fd6001201303db9dd2ebf226978b3d",
"f38b2288480771f307979972e5fd7a62921f5503039c22a8560a5673251e6feb",
"ba3f526ad88dd13ff72834de5d1e61aa11eade00d7064a0036df69f1471afffc",
"7c2ad4fed0cff8adef3a549a64a1c837c55a5f2c114d8ad76a61e08309117854",
"ca2eff7a3a23e26adf0f5ee184a000e4cf93125d5637653b3fd204a287f5664d",
"7d2027c78ba80c427d6b80e5c3781e70eff1b129f2e9dbeb0579e34481228999",
"c2cce3d306db8e7e757e5be1856884c46667b203c67a98728319e3ef8f33f3ad",
"1870e47c0128570d86334af858ea84cc631db033e38ea04a8b6d693fcdc20fe4",
"df35a027a8cc21db6b59d68688aedefde200cdb6a42d678d501c89fed405d4a7",
"cd8782f9501243eabf863febd6144ab865045993621798025d49fd90bdd5b408",
"c5672035c0db879a9e600c42a400d54cc2e8db87fd85a91210881ae97b403f9a",
"0becf480732640c1777507a51e60b76c6a64bd45141ac0e6044dcf3152f5e204",
"e6c3774c24ffc45a64e7abc50a93a3eb0b4016bb68c40a861c43a1fdc79e4cc8",
"34aca7b327015bc073c85e5981cff8e47a22b76d4f17aa03cc8e611c852bdea2",
"dcb0fc3e6ff0f055427e73980e87cdd85847053fb2dba3d87bb95f68293ab9c4",
"5ec98684070bc91261279c9e7de1cba907ddc40437e802c6e8a42a21ba01686b",
"ce59b27fcb379c2e0e7f4f8bdea792f854d67bdb492839122e731ce91940ab6d",
"eda6a41084fdf0c2a5cad57a84054b8ffa5149159b21b6df761ec7cd18de9950",
"7b77a78932606ac5535806e389a708bc931dae40c03df13fd218217311ae4991",
"4fd5b12783dff95ac839c57ba33175caa93a7feed653ad9e0c48125bd3874b1c",
"ff289b0dd13ceb83fe2a108df59386c77dce63b38c48f52f4ef43abfc26f260f",
"64d06fb66a8068f40fef2ac62948ff5c7472d6f16a9a034936e3a022556c2004",
"5ff6cff7a46d0db3908163b6bb7d7f7375f15b14153a41d59f960b0565d53f93",
"0fca3f3148ca19c293b623ca1958c7582929a380174b8eb1deda87abc6515601",
"60a19439a259eb9958fec356cb16024caa1c00275631680d938014d600068447",
"a0bfda64614064c99dd6ceabc4714fc787fda0c9e6df3db9f44bcc3b3aa68ae8",
"c4c0e1560219d4caf4a830fa54c0e18f65d83c8ce3361cc5e9a5af35908fffbb",
"351cdc457a56796dbc20802e7f5ae3fc82e5d5ab355cc49dd21f144f5e377afa",
"8682ff682a7a07e376e30b7eaae94aa3e872502d9e320bea1deac9a37dba8cc5",
"e5c4dabbda4a2a4e01ad8ba8c08e49536e0d7d9a04856f0dba7e64f40f471f63",
"d51566dd01542c76525924f4799182c30dda675d7d350948c7a33152c7b0f5b4",
"f804f8836451d8b82a79c05301a983f7d671c99f245b959bc84d36b350cd1717",
"7d500b47fed07069bcbf8f74ae2a6123ee0b58a932fc0ad8dd65689cd24bf01b",
"feca9927998a1218674557f2144716ea8984fbbc31b525de72df276946c8f0b6",
"9410c42d3a963cc1079f1aa024a2eba3965155a5f9dc2f69ebfab776fd437717",
"47f9d960cd95079f47338b33b28f6a089396a7cb3361d3741db5d07adb0e95a9",
"cfcb6107b803bd29ae9b5ee1219e5beeb97657ab0cc8cc6793a0a5a6c098fc2a",
"977f8fbb330ab39202f70dcceb16291ea1144bab908104f3276ca10c1aaaa29b",
"9735797e780154ad047bc962fa9e44ae9306f12936cc959557866fea2a68e1c9",
"eb096744ea149e745fc646b921c6a3f148ed1b0beae3b1abac63fc4b85e4c134",
"b410f04c45f983ffb1a2517bb0f80ecea04567ef5ebcd38616c985635a312e51",
"568f72093d5c759f249852528719624446d61dccf6b25a6310853fc962c37d92",
"6a31a42279f4d055fed925177ea51f46630809973a7b3ccf0e9f23caf78eb605",
"fca2013991a1065e82db720acc3a6d8b8dcf5230a054f2491f220176b2524b04",
"c20eb4bade410fc9cc1c4578e6dd9ef60adb7eb944a485d3f39857b95da1e002",
"17d776971b4a05f43a1f354357b628ea63a346d1e43b3f1c4f43c597e498bbf0",
"691391136f9806f63186af34b84a56e26403e3c06c6cfc8caaa3863954ff3b72",
"a6427880da06044f309e0644ea2e03266f8aecec57aab1871abd2e9911b3038d",
"4ee7849dc331aa3ffa6da1758a3f4303214678806719241d1fd443f25c222bf5",
"c5c3da6b1336fb036e09dd335e23231fa4733277c569458b44ba6324eaf0b21b",
"d61e5727c8361aea00fa2098527187079f734c452788975dc5799c6fc0fc23ae",
"8d07c0559081a6a389dccf1c52d4f8dd1f9aa9389199aba91647ac0cdc30f51a",
"f6731c65758acc2988d0d695b04b050d743db4c3be45dc9ce3c3c5f1be1f8b0b",
"4e8d8a7fd9156d4a17f1b852c25aaf480b843c2246c7bcf4bda54d917c380d75",
"38185ff261eef16220d07464ab0a9396fa87203d86a16599ba58a8022bb466c2",
"10f19d11410b5d257728288336b4b340811bab54c829c50a21c4376a1835c3b7",
"76d7c011135b0c739482d843c53b0fc0ad7a79d94bc06d042b2defbdb1940758",
"860cd181e8982465bebf3242399c2e30abf1a29c22204ebe9b8a691ce99ae09c",
"552e38017d76ab48c092735326fe0f68b1535fe287bb5d52fa0ffa3d02a900a3",
"6f0c58e25c6819e48d59a32e33e9c68c3a3560498bae476c229c0416c7722357",
"1e81cb3be0cfbf8f2f4ed755176c3ad2e8fda2c74e5272d3b6e5ba1bf2f427d6",
"b866cad91ccc6bab649a7b33fcf8c4244be38dd0f5b94547ee0f6aecb1f972d2",
"baeb5a794889caa28cb41df22a958b0de08dccb6c5a4b6e82ec6598413da1feb",
"bef9c1bc5bffc50232613f7c4d7343e29dec6a86708bb2019129ebda0a62668e",
"200afa56890996668c63af9399a4f4c41f92a2ee14757fd8f9fd493f919097cb",
"547610fd35f91f3ebdea808be60b14572549aece41469f68ca4692832411d172",
"8bd43fceefa8b87ca8f881718850aa7afef28d93fd330b9de0a3122b3071d017",
"83acce7c62e218fd366291d5dc23d879a1fdeb46bb67b362b7446e57b443d539",
"441d53f6a436bfe742a6328bfe45420a05460c37a6a4943bff180074088efb6b",
"fc309557823cb9183fa88050cdcb64efde8f71dff5036d30e2d83e7dcf08d346",
"5f73b63058e06e0c0566e1326c9481feb1a7f42648bd4e1c5de6d26c57433beb",
"0c3497ff3ec2e157066d41bf2a0f69dc07ab8d0fac625346b640c295fc4cbee9",
"45cdb5d869a9b2311597b57161aa544ef402951a627eac725dc5077d48ea93e4",
"3ac1d90aae3fbe42df89ce77270f505ffc4d0180189d10bba5b59b134d5118e8",
"f1ca347fe38c3fe19369d22b93bffdebbbbedcd0a9e2166113ad68f7a163db03",
"c65d799331f428bb2a2821f672dcdb9faa68d0ea5b8701f490aa3158a7547715",
"8985b375101dc4eff1aadf08661e110a70526f29ab7042adc5f7318bc6cb7967",
"6b29cacdfb37d0d3f8944603a1751cc1758db3af1494ddd41483f2911bbf3d6e",
"68e8c327e4b6eceabb6a55aee85ec35d39a5220dbd6b96192c0fdb95b68abcba",
"b0f34541265c2e15b00c6f7ed03d7932e934f08e8fe641566d093614c30f19a8",
"0aa09013a730cd6d42741073f82e76a7e6e29bdd38befeb2a52e447d79ff1033",
"7137ed305d73ff9f5b8aec9b53a526299ee4d56fa7271ab88102df1f0ede015f",
"58402a9b1115d6e407c296fe27dfa0e016c0f5df18d0fb65f1e5a6efe0639cd2",
"e10d8cff74a877a3c721d895de5a3b2080e2823088367ed400006ee1953b49ee",
"48489dac9ff17a5ee0ce417665313271f6a5baca6b130bb780ebb67a56784643",
"1aa399525cbdf3662bd004ea4ef3b6dd5ed279509a59cdd98e1e6972a37a23c7",
"3f7a62b5e04d868629da313dfeb593e77007996313b16a71f0466415832b867c",
"5c8f83de2426a7a3cfb1169aac70e57714af16ee87b1e1e804a9dabb6175b4bf",
"42dda1f0963af8ae65aa8761ee6bd4dcc85ee1a235cc8711b0468337e810376f"            
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }
}

library SignumEtna2023Collection_201_400 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"ed199d8ab1838e1b6cead30404953cb50b76adeb50b87a64132176ca88be6b49",
"47f0dca8fb548d89aa9abb85dbb59f2342d7287f0fd66a722891a97e7915de17",
"d67d3d3c586495b6f844f5f719fba60ea009d83538d596c26fc51a6024705df1",
"6d8514bf6e97640c6243360c783f06ecaf05630a62e7e936c974e51fada92af4",
"c97ad07f970d41e4f710d70835ce54f5483cc17a45c1624753491122366291e3",
"e48cc6e7c32d7e8bcc54974cde0555906538cd7a170be6ec23ad1eee80e8ddfe",
"1b723046b513389da40a4c83c66fefc2b179d046911ed0c97ce722c3713f81aa",
"acd15ac3ae0c6ebc7325c3b1860347cd7ebeaea417b04a419d6112b52537c9aa",
"bfc94686bb22af8dc897132d7f16626833094f73486310effbca31fc372bd34d",
"76dae17cfb12c12aa81d4803984a9838efb44323572cda1f7e6c15721756778a",
"f32c85172d44ce8341d36e2afb18fbf207513e90cdd57211866db136ee4d840f",
"70aeeb6fc4b1d52afe6c9cb9bc3c20232f7fdb3164665402db067701f10666be",
"2c6db72a3c473a6e0003106a10cc59fdf5fccb8f594e9df5036db315fdbbea50",
"0e08fefca51477f6b758f36a6113b038c2d2eb90408a8c611cf612969cbc788c",
"ebb464746d86f33c9fca04ddecc822bea25c96a2da35a9f1a91bf60153be48c5",
"0a449b8e0be994e42490c30e4f7f8b72fd235ce002262ac2a023fcc9b0cbd50b",
"554c34dad358b423560166c1abc8e18fab7f94a39288c7e71589f36f3330fa00",
"4468382bf74fec0763b4b3cdf2741b73e41562cf1e2a45cc682f908b470eb153",
"5173f1844aa27b41e439bcf08f6f832f61180cb636d0dfcbabe8d9ca395fc09b",
"3e8f11fcf9628139794ff2aec8c7b03eeba5d7b1bd425105d0c928c786007b65",
"12d059f7421d0b4c36d0cb1b3f485ec36106c81a97674e91df07fc3ef65c42b5",
"a126cd80d44a9ac5e7b58fcfd85197d7d8053c39e76addfe97ec1879fed1c100",
"466a32ef9a6fa6b965b710634f8d264ae33cca6c63b6e69398b589463c1c2fd8",
"d1204d72d33cca342c884cead79a5342b37d70299b8ad84adf61848745716857",
"a84a7a44ef46f19aa82291d7dd1dd257b43bfc55bff679a25310a5efdf991171",
"18db5360d0684effe497c2e267c6d5b4970eb494dcaeaa6a302574ea1ed9a993",
"4229ca18ac8424f349e2b3fa4c8d6d2f34e0945fc9b9b2cb2b730a69f764ffb3",
"25f638984f73d43034edc62067e17797341a6a5db6b5adef332fb8e46c2b7ff5",
"b42279639446e679c16fff225f9f9c7ab673694676c7f9cf083b0d9a604a1963",
"86b3d1569d2755f5c02b6ed1f60dfffc658a55b2e3dc7c1b650d075932ebde69",
"0c6e7e9baf3f89edef3b8df7f0e637d1a4cec05547483ce776265335ea570e31",
"8203894292cf00657de805d1d2d594b30253a0521c048c06adec07fa656ad764",
"0f0e3b05892ad6d04ba95931c92d3e204bec009487c1735d508eef0bccac0460",
"ad804539da513a5fe97c8b26fc00b85d7a121ca2032eae73965762891115a009",
"993cae4be321b46cf54d74bdb53e544afbdff5fb4a6f760d40c84b2a415b7ea4",
"6eda8378ea556861d621e10de7ce1d1e029c155cba37d40e54243d9bb0d5e846",
"2030473012d9601b0156778d802a457aecc917c74b430855dee82af1a51db5c2",
"45bba4e54965144dd1a937be9378e8531b18c6b5dca79a5c8bd5d6195f302e5b",
"e729676d6f9db541dd52f15714b18bc236b668b96120d8eb0dbfe560976ffee3",
"4a6402d52c0fc89765e4ac72db0e416d2f5891a17ca6feb0786c3a08064b1be8",
"95169c4578c3663899c5475ff1a3182cd546e8fc7566e01c348443abaccb5265",
"d04f493cb5d346a1b5550ee8b40e096181f26aff865f5f29972ac2b80e3cfdde",
"a2b8b7a7ea2d1bfe0e9fc99d13eaaebf676ea40536006d7abea1a6330d5d6c0d",
"512184428f335fe0991993a7078c43cdf4a3de0d42e30422379934cadb502a5d",
"bbc52162d5112ff61ad87ef679cb3b013f6953844e15ef7ea6349f98eb87167c",
"6a684be01ebc1ac0f2799604b528147a2c4eee03e4e86546e7b58b9051eed3e1",
"bd04d8fd96fee89fb2112fb3c225d6b6ad9778c8322206b8d33194b2929fb84b",
"c38de193e26544163322a3501733d98754c457acde76dd2f349b1f08f907ca0c",
"8415d94efce6786c23ec761d7c22c3f371d46be1f68df07dc99f5ae6abfa3901",
"18dfa9ae9196a50ee3809a5f8137b95d769d08e71a9a3080282fb0a8787ca692",
"e7df994ca1d181295d50978b29f80712482fcbff4ecae2272a9cd487cdaa439b",
"c95b3cae80d779d8bf192616d6d80ec820aa09c94bf9107ef3f07b6701100628",
"909f39fe83432e3c7ad3c40d0bfb8e78a7955ff9cadd230b4ecff179b6159f78",
"e1d0ccf70703828845a704728f5c0de42236aba6d702b1355143b0b5677cc5ce",
"b0827ebbb4eadb09fca6aae67b26d3cd3ccf3389d319a7533cfe4fe124a6ec9d",
"ae0152683d43da72aecb33c2fb58a51d4b278cb61497893862119d45d347af87",
"2290f2fd5d6c8e6856003de4d808923ce3b80b788755e04b84a8f388610cf480",
"5288ec49698d853da1d0b0e26763326baec43dc612a57e98976282545a540a13",
"e6d5fff1dbcd1c8f1e699bf78caf39a61b01f0a5505492fb18d9f180a3090423",
"61aea88b4efc8c4a53798009b5328cb8d3f3bd439a4e1061eb1c2d43112521de",
"f188d1b06df6b8b5e56471079cb0c121564ec2a84e0ad1e5c4f8c02226a94021",
"1441047185871ee1342eae1ac16425a2c30007440aed448735aa1308edc9e590",
"288cfa73a97cc9b5ad2c3a3b3da7adb31acfdb82deef407787579651144386d2",
"1bfdbbb5c223c7beb781245e1605a7987f50890934069bb28cb87f13bad7eeee",
"f63f8dc2c29f7379b0a0761d39099fee4a1fbf91472af565f9f813df167d8801",
"1d62c728c1ef3d73fc201008d4535130ec305e3cb3b8dc15a926d2641befa9f6",
"947a1d8d6095b915842d42a656a961d1b8476aacffdd11b2959e00c31ffee8e9",
"a9d728db1113a3a25447d79a8d8a9a8c05b5fd725a038d7703070fc35769212d",
"5a440a4f8281887a444a4ae2aaa5d86cd7bac1f7754f32cba78ab640775b1307",
"32533d2a249c86b4b481f2808d9b4e793f7cfb0f61651240c039dc15afd85ae2",
"7089afbece05c3b534cfb2ab8a009cbd47d37b1ac864cf0975d3d62d9ec5b1ad",
"1497ae998bbc6cb1ceffd1648cd84929eca0f304a9707235c096a363786e1c5e",
"de64b939120b05261b141863ed80f45d3fd1dcb3542cf4bac1fccc7c0d72a68b",
"caf8614a649c247c38ef34fdb3f564f1b149c00af9d5c17c757340bc86116abc",
"e1ed339893512189ee231e54ca3f9e143e1e27152e1fdd713506151f07330df1",
"3a91175831faeda5fe8169f489984bbd78a9cfc040a5fb852117e508aa1300fb",
"83d79ca785428ccfcdb90d79195b909d02ed372748fd5364c38ac255ea0686a6",
"08d5899098cf071b7c9db62491fdbdffa35d29f588b90f24823cb061567743b0",
"b31c989e1603427ad6ad7bbfb5eafff2c5eb0d3b509f6398bb9e7949a3839c82",
"0d0c16d919b526852744f908a4e8c24163f168ddf347c36e6797649deab74c27",
"47160f9e0b03d09ed0f6b78a5690f713a8072da51423065a9ec99a4e392ab7af",
"075be6e70053f42a5a9f06751057ef3799a9cbcea5fef72dcd7e0f0893da04fc",
"3762d48f5ccd562f7d3e253c430334b01d8da3cb0625bdce4049314144b1a9c3",
"1eb60490a2a69ab79b80b0dd29e58b3a58e82f15ddf5679a47a8c6358b68895d",
"cbbc262f7ae5b1489ec94a96ceb3a52099d0d16f7a211cac4b9cf06f0d59e557",
"8ab885c2a3dba6f7f2494f97672ba61f8fa3330cb2a5576d99b1b61b3459ce42",
"bb03337fd0f6cf1f47035118a02ae479e65b308e76fb782a0a216acb2d232204",
"ce76f3e15af649d8e2f1c40f05c8e1e3cebd311313d66d465edb0e6885b5af67",
"214a01682ed453a637177e134526f9637bbad9d0c05af17750578b9d4ed21aad",
"b05360c72436a0bd9650934f021c406a619c7a2a82dcc189f797a8cd3eb3ee18",
"a97c050063c1937fd5855511898422435dfba5fb3f34e22727755bb44d307444",
"6bdd7078e1d6b0b791ebfd7445cca9a0067337498593b505740ea622f334b2cf",
"4ecd9970279731ebe07b9d1caf52736e69707c393eef53611eedafb6a2b4fe0b",
"cec63f61d08fc753a731105c50edb81623c48ddd5ff7a77b1015a13a76ca54a9",
"95dfd8e9871517c6667fce58a188170e03641e4a8a7b0f85a8f0c88ad8242c9b",
"2a9ec9b333dcd63fd250099d5b7d2c7d5869097540951234712e6b19c7818b9c",
"0522717a6fccb30ee6cfd71f3a0781eb2eab8b7f4c75a5fe459bfc858190049c",
"561a43ab552665d71f4a0a55bbf4372794cb3a6f553a1c3080896dd06ff45a66",
"63986b9b9b99f65c3fd74d3e0b4e26ddce2961201a2c8727d02973c62a50d93e",
"d8dc1669d744f968f3dad08c17279cf8df4c01fae5697f3189898e2b2d85142a",
"9d0557cb217524fa4d2c471ff1f83b9494e48868ee3621bb429f8e3f5c879557",
"9e7ed4875871fd08f2c1ed1c840b2f6c5d17a63a31657e39d064d452437da30e",
"dfd9c390a8bd4a51b410f6d1a7d0e2b84832e5dabc726b75da8a09d036438684",
"95ba7d0005511d1a725856d5de8a982d682f9369d1b0168f39d7470c3b1c6e13",
"32c5c036c10c6462d049b113ccdccd1a7c51370007165b6d909fcfb634485648",
"13dc64bdf8bbfcfb5ebaa2a78a14f937cf1faad57c655b3e87159de9e8a8ad13",
"8fe24bab0117d1db9823357ebcf471df9ae76209266618b6a5a3b65030cf8bb3",
"e58ccd73ec2aa0056d5312ab27701099aa62edda6d713e15430a66d1b399983c",
"8039ea47edab37f8ca4d6ad4eb80c328f3e05441323ce856173d88b3b6ed17df",
"51de142d698176bad64a1eea97bbd358c8cfd44dc2ded25179af05c38e7e99b4",
"619c78093567d47748923e89aef084ce0141ae20be59315c82d5f844f2a23dee",
"dae7912db687f9ed8e5ffc66ffd62ed98ba197cc89aae17b8dac877dc03f6637",
"baad2f82245be52890c496f0e29f4a6cd289dc204c13c78d79b2a3300726a1b3",
"95842fc005031b9a15692ac838a39b3f55d8e2653f883882c6bb61184d1432bd",
"5cddd1676c9ac587f0094514905bd6def97841d72f09e7946d37d799e95a668b",
"9e06aefaca9cafb346297e6706144093f6dd1861c3bc1f05639968189e63cc15",
"28ae86403ccb00d7b57f58aa2b6cafc53d920379919cdc5a701d709dae71bc7d",
"3899242d33da8748eafae6a331539a76b0bb7e8f01c9d0c185bb494f1eda6aa2",
"2dbaa825e8cef4f8e23f6fe08a7f9e8c87591eb3d4ffbffea690c5533e51477f",
"856d95677faba361b2986bb94e5c858571f5448b37775b461f280667c73b6616",
"8957e3a434f1a637fbfd5154138e75d26e6f82784e8de7ce3bf5b95dd68566a7",
"28be78ed60d79158e0afe8581b0c8dfea7da3aa722fefa7098e5e3f027c1f99e",
"f4e2b599cc3d119ce63f2f5bd2b5a1f419e2e812bf6a1ba71485762ac6400a2b",
"819ad276344919e3d8c30294b85c836f4047a71732048c8be66bb8e01771d0af",
"afcbc10d41b954fe66305851b43cb5e60f2882c68d099acdcdc4ae6c2f34357c",
"e81c8747384c6adbeccb0b6a987619005410c49a57a3dd7d61f4d922229c3c05",
"885ec861004b436299abca9d6694b9b5e8aac7b258aaf620d98af42c0d9b1129",
"44d626e5b51d1a51482deecee3e12d06d84d06b2ef2dc01541b9cb3d3b471569",
"6455515c74456a00583be837258db6793677ace2c357953c06e8d0cd78ee8f00",
"53768ac48acce46a1a270d4976b5fbc0fb7fba2e412bd6c206382d424a382f4e",
"ab4a42637f05fff94a391cf05f1a059d459a83422702d1014796f2efa8c796d2",
"d549cf53249a01503f3f4de5c8d3fa569c0b58207b66598762f3231e32e8954f",
"af16971266c0fb81a0fedb47afa869cff2cbfc960956d3ac2aa7fd81e52e8a0c",
"f05016c0d337bb127d240f327cc4380ba987628d5d42a6441d1d320275517f2f",
"2677de4872cbf1084c799c8725c29925b66f73dc7919aae508d5fac9a4df1568",
"7bacb21b1d00141d73d10b22938c364278ca8cbbbafc3b354c499a04a4133842",
"dbac02341b37d3a76576e4d4d48e26b3895538ed08f3d08b9fa9170f93a5810d",
"6d03a9039dcfe0121933a6ec7e37bcae901c0babf9e49ab5571656d92915f354",
"d011c3b152727f0d997ffc9b071f00359a472cee943bb3ad793465d675045b91",
"b6763420ca49f16556fc1b590d23953787d8c132acb72e1d5b38d27e18ceabb4",
"30313dd08fe7fe68936fc280ecdd41376868d1d394024a402b4aa953a94797e6",
"250f033e4385afb5c87f9f17869768e3678d27b89ff9a974b2a8ac6b7df48a23",
"1c654c9477da486e6955321c3ea71c14f73660c415bd73a1d414b6b11a0529c1",
"14582c5827850ace39f0e75ec0051188bcb2a9ea1517b72ad0aabe43240030fb",
"c90ae6d7456cdafa7e24c053efcd9ee7a3d3ccf5c6bd1f5b309ef0e7827c529c",
"0a521bfa28e1c549f33d7ae44486e99d2554e7c1db98cbd24a29e904359438e2",
"a42ed3d38fa24acc91aa5ada8f736090cad21d1a6c5d2ed112e2c42628e8c2fb",
"655208b75b0b4dea472f6a79992877861ead3b1b7778ff4bfe5b74a437f72868",
"a78105c311be5118a4fe57781a00779f88c2cad772be60de8a3f4cbfca9fb010",
"ac25553c7e09eea8ed323ac07f2d52ecea98387317bd05d72725ecd80d9d1cd3",
"aa07da5d16d7482d350c8b7a581edc30e931f0d71a46341a084506b567f71cda",
"a96533c1516766575e4f573f9a9097eda3eedacf758f949d4e57ade511293d32",
"037de812b5b623f27fdff6d50b4f8102d8ad9fa5d3ff4342b17fae53aa746103",
"9836542646307c9170283bbbd2345aef157783ee863b13869f7e6d300363b690",
"06132934e51da6ba7292b04d531b2e0d59c7d238e9460b40608cb36bead39929",
"230d51b19e62fa7f3d803b56d1055524790097ef8da47cf5cca62167b01611d4",
"f28456f1f91ac63b8f05451879ecfff77d397b74f2f46a3d052947ec5bce17d5",
"d2ca93fdc0aa5e48f06ec3f1e1ddeec9435828c9b583e18bad0dca601c74e3e7",
"3e0457f4b1f61de1d073dab4039dd6bb40d7e29783996d8a3086ba6a346967cd",
"ccb1b67bd89e5c1ce28e9c1f8fe80e1296f8b467def62fa1d2e5f834296acb79",
"46767e1c9b49a4363ca3b5a7376a8bb0347834be3881034f3d901adae6034d30",
"6dfd94dd3b4751861aa8954000382babc41733a6300b50edc6f651594579a75d",
"81db34d98a1aea75cfe899adb6a72f0f01636f35030a470977daf0f9e64b9afc",
"89c9f754c46201e8f711a0f373a08497a3fa09525a2fb3cf08efa6c7600c020b",
"256acc6bdbe9f75d93313c76bf9423f7dd49fd246088915991b7cfe6bddc2675",
"2f04a8157f45b9a5551733d7797c25c03bf89875b6acc7db16996091fc23b496",
"fbae1842496280072e6861cc895807f641056882c0de333ea4a877d09b06f6f7",
"69caf5bedfc407e199acfa04fa77c5662351ff784b52733c64cec268b8cca24a",
"f6c2341ae528b2608f837299f638797e88721d429949cbe21b592b470af60b8d",
"45dbca7187829efd5c4ec2d84c5a6bf8d67d33eece9562b589f7abd1decf59d0",
"0e5045c80e3f1fdc355b3bc551d655d28bd2b74c809042cb7539603c676560ec",
"ea12d73f7dd02b9465e4a6080149c0f7cd36254f083cf4200c3c1fde2cf2102d",
"a75b130100f0f578a3d5af446501bb3d9f137d70b90ed11d19e6e381a6b26c4d",
"a6416fc65627a78bf7abebdc39590331c21ac973f570a58ee6ec1c8e740f6d29",
"eee741e520c30c667c66167fad3f5928aefe71389030513b12af09f6386eacb4",
"a26f244d1b605873b2aa4362be6f3ec29784e04ca10f9ae9c1eba00c12bc0198",
"6ba5c03b19b84adea243436f999042515e23dc5308583914f5e1d6dabf8d8a59",
"eb4fbf0e25b08c16c29ea3ccfd3e7a3af720fe37a787aad6b098f4fa636a6f34",
"216665b4f11cb44ab0e85ce94f3007bf9d2aed69506d922302c1a7a825801e77",
"463e3c8ddd041bd21141ebe876ba46e85cff77a3248c8e1b4b443bf46bbfc0b8",
"77712f6439f9c3fdf312c7f4111d784ac5e6d9f145e066ba43e6f615eb267b88",
"1c908ebf814cc312962b32eff85fb42f23e367cf4f567d833eacd927be0a480e",
"836143a95fb9b25cb7edc942ee054db74ce2da172ca1cdac2a9167556c6ccd7a",
"bbf6f21483fccb9f1085edc5ba5715809bda9de2025d73f5df097f95367fe2ac",
"a77a0f046c13e86986121967ddcbd6e896d4b41e5e08d2743881c89980ba3256",
"bea903fca14fecb1c3bc008abbbc429d39c96462fcd036514a32523c867628c5",
"ba43d04a5c803ca098454b7205115154be45b40885f49a3882f830a69af167bf",
"5453ced07dad045356032bdc6122b1720b5ed5646c8215b0d7f70d0dd777cea1",
"1213c1ed15668fb212bf300f2dfb20e7cbe6081650a6e78052a1fcd15985b820",
"b0986acf702ea3e8b1c883aefc2fb2146e173138bac7b892f07d3debb36f95d7",
"68691675aa44d85403900c582dc502820a0b997ac6dcb650a25d784cb3112d15",
"eb4ab51a0db54e55067e25b280a28f4e3fca15faf0cb2637ce510a58e4464aa2",
"be4028e664d48d3165f40d40067549bf9113939156dd9843bbf75c33c81f5723",
"3132c4322c4d2ec42b2e5ce918bf6bc0ff123f7720e97bb925a6aec159be219e",
"78028c164d008dce322c4cdb1169bf1bd100b27c1d6233f9625ef467db5df520",
"ff926e833725aef44aae3bbb1d165baa1d1088342589b4853a288e531d70da6c",
"941c5cfaae36a610a150aeb8c1d077bba07ceabc8925fb75deba43843ef22f87",
"338becbde62e2c0e71c1126d3bbb388bad8a426190d3e6c0c52a3857b98453ea",
"0cdc7b4ebaee7f8c8cd3db1f47370ccdadf9fc68909ac280268fece9c2f41290",
"6618dca4b2018092783f2e770122692c2f473a1f7e21faa4fd138ec5df4088b7"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_401_600 {   
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"c89f34101ed02c513dd253ee50ac95043617d565485aa2a743601290452f9612",
"a44a6ebe2ea1cfe92150f5490897c9ecc5fae34d1a8d2a76593a6f61228fc0b4",
"db42bf24c681d24cbd29a3e5078c51fa5e22a887b456aeddafd3ee66cc45caa0",
"2109a0e831e642e67f7c60b45343a5a0ed68310b229e78d8aedf099b875f709a",
"3eb4e5799de374d792ee3acffd20f2911d10cd67800d9595c50559a7c35bbfa3",
"5329d3a5aa345b31e4655e0c9505ca8a406a2bed6793fb56ea0555ec46b24117",
"07ee617c6c5e220ed9de2386bf196745c8a602b897a76d9dabb1821a449c4dfb",
"d171d900dbd3d65e880a344a7fb6f1b649de922913a8bb4949e8d43b32c5273d",
"bc641b4c96ecb4f6ab6eb36d78684fc454e549698e246d7e11b629ba231fef93",
"7dbbda5dbd7f4588f064782a1189c2752d9dd6d8273d55e8f4bdc3dea18b034e",
"6f9711310a95f8fb30ee68ca8f5cc6acd23740abf8a297ce353f63956d2d89a2",
"e7113f2d3a3f668125fd3fd54459b90b3380e4ca31e4cfe4eb05bd5010dbe8b9",
"b5007915101611bf782e1463f459a5cf3838c17b57ca78e5a535e55441182212",
"9e6aae8303d35e705c35de7edcd2a3a6c7ef68d8f0336ef084153d964800115b",
"608400e2ff88b7ae7c19a657d53228e321f0a947158aff05175d8e786cd1d8b7",
"26a3ebea9566b78beb424685c326f67825f1529e6e13314f28b5b37e7992e2d9",
"bb05c5682d8dcb44e0bd6e3d01c077e8cca8acbf21a72e4170918f55ad9d7564",
"792443e816e10deaf4160cb0953f8e09842d0db9bbc99908f9b5646067cebc27",
"c8833337cfe28486bd606a2a6357b7bf5cea9f6851abe14c271333d3916890fc",
"797e87191e97203815edd5e71efa4158412b590e84e5dcf13709c3a3321520c9",
"c5a8a6f1ab6b8f8652f9f0aecac6fc16e2a851caf8866acf084858521fb6a31f",
"b202eb9c6416171bfa233434f2274b896e02dcc7636b8338757e0f082ef949e0",
"55f55f18eb85ceae955afc760b678a4df57e44e183ece1b9c5dcfb12eae75a3a",
"150997e4ce4ebfdeb64e277019c53f6b1d1e446fe1b902957f9d2d06193b016e",
"9c266107588eed74730966d5737af3b28024bdd93b697698da6a2f6313f58c62",
"f73caeeee117af4ec3a2b0df072eff83e10faf0cb8f13d14b1dd30a1b969eb18",
"ba3d6ead9895c2e4037a27554ed3741c3813e32bef3a8353ee4f993ec4f098ef",
"257507ff95a6d8f918c863b6caa43d8b3a4cb0e6941c30726979597084e5a77a",
"5e57ac04aef3407b024f8a1530f4a2ded2b06af3e6d72e875ed1172c04c88a27",
"fe82e4edfa4f3dde9b37ecf463795d0e811680ec5f8dfffb4b841f8b1c56b723",
"8becd483145beba34ad8c8c7530dbd3794ea654e77fad7e09eed1938edf75224",
"599b7e8a2866caf190e331d44c3bee054073eeec96fa4f7d8ea1d6384228dec8",
"8a2a95452c0fdce5e674caac621222f1d05f81c87b7506754f395ae96ea1e5d6",
"4af50d7cea6649d6ee1c7804fa77964dbeb25aacdb3335bd9c5760e07b3dd346",
"14f6febf7a106780face01ca2f33f9379b87204c095781a85a28816d97952096",
"37f9188c41742d26645927e7eab7db36395cea10b9b8ee6c0ebf6f12c547542c",
"35d4bcf05b0f0ccdf420e5ecfcd4c24c54ac6a971783a50e9c1364da40704c3f",
"4149afdf72f5328e41bf2693f09fac80c08f7b985abbb8d260bc21284bcdbdf9",
"817326bfa13e0beb75040a5634514f5e3b206006709e23810ab0d6b24738db7e",
"b85d43e0e5f5faa8393ef6183634ee5d3ca2e5f4a90a0eb5fdd0d9c9dce3e1be",
"ed16c9038570063c30410158a9c6882a3843ee760a9486c346e57be0efc72697",
"5d984243e1d67917f84e3f8e73ee24b4c1bdf234d88027466dc2ce1fc47c2a02",
"8b7c8e4b59b5b189e152109428e4b5b387234694ddb85c781ce9209d9c6224cb",
"eaaad0dba1c192fa3fd691dc6723f712476cafa9b25ca3f2524b2db9daa0747e",
"5cfe417ef270aa90e98b50f946b69d2a3fc8c7180577f541c586ded0535e7f57",
"d2a68f81b4a9d3b0ea62cb448d675d6a53527c7bdd8db8317daed74e7baf0f60",
"3f43727b79031190c4358bffe32295c2ff39279ac7389f346d3fedd9eea94210",
"f4d172e05f87f1ae029f0a56f0eb4d7054365fe3d60bc9f3c0578855dd41730e",
"3523fadf0d72c4a28eaa65728a7baff06802c06d178e9125cfe02b3828595fcf",
"7f8acf41da58b4897ab44fcb4de7ccfaa75e312f176c9b911a3092ab558b4b45",
"e7f8874597c8502c2ea7cbbe19bb472ab100893a3bc1f417751cc77fa4a6367c",
"59093ff44cdce9471ff7e3595ebb88a63e7d0378fabac9623b13e12de59b2303",
"882b0d1f667dd3d190e5444406d9cc12739389b0c28a1361d69a293d73718a95",
"9ffc6f46028d8eab06af74333c431a169e987e3c59c1b9c7f92e6136fd86bb44",
"f5a664cb90d0fe80a5b965547d323fb6ca81e516877aec218707eae340e419ed",
"815b9567fd390c79efd86bfc30c2257863137ef3564c7b579d3deb341339511d",
"c44cdc5aa226b34a13be0e08106d7d727767cdaa785a6bab49cca1046f431b36",
"b79028e77851955a48cdb87ef8149cecfa419eba2dd03568e7cfe74efb5a4244",
"9c7df6152574dadbc67703b7d814aeb9cfcbc039f0a9c1cfa630a02ce766efd9",
"925523e4364dbfbd4864077936ce36c47a03ed85e00d7b2ee41f4c8dc8eedef4",
"6dc6c17954908c4785cb1de502ea998eb204078101e69b41099bba471d5128c2",
"8c5b0018ff5aff3a5da25f63d5c9e8062867263424c01c49429b839e8e043e50",
"ca4f8f07c70abba6b82f6bff259a0bb397b9f2768be07c3b12b64e827d960a67",
"5f4327b16f7965962f757e328a4bdbe98adda80499e5d2f1e4d93dd999ee733c",
"059b8050c72a55d7c3799499731b4a4f69e7ac1d928e7f48418ceadd929ce5d7",
"a1326a0276db6f434d5b268be7d9ca8dd538a19dc5659a9e1b0758093739a639",
"05ddb38e15a9a2e4e12db33a3550ec94ffb3064a3dbcd55d02dbcd4581c16589",
"4bb54b8ae6acf8f58b42fbbf4d43aafe83c73efd8484b139fb019154fb32d987",
"cee60f0f0d4b2fce75a6fefac6c2bae0b09081b8a28cf2c5d901690796e46f73",
"a774e3677e0eaf5de49cfdfe3b3a6b042a09e9d67e4b41601d7d77bb51b46f6f",
"68f5d966a51f5a85ffd0f531fca926ef97cdf0d82bba8bc3104eb2e0c33528c4",
"91d52569e2e01b40f3057f7451ff56e1d47a6d6c022bc9bc2ec57332f1d4ab5a",
"438cf5dd6f088a1d818bdd247e22b7d0e008e958b8ed6be8544eeed4777fa654",
"d3c987a45c027726615236c4265c13faeb8659a359db2d418f58d05a964d5502",
"a8789fa5c5f4ddc9e0ce97e7520f47d3d11ecedf9be6f2fad536c0c3054c8bf3",
"ede1c14c2d9d80f03c6863815db7c776bd3dac43b803bf11ba591d94968025da",
"d93abf7549fdd445b6b37b806e38974417899e8bc28d83051f322cd5e0c417c7",
"f75664897628832fc5db7eedd7d60ad372abc184b7f9af43bc9d27c22ca40e92",
"6e486dd0b1d9f221027ddd620366506caa283296ac9747c50dd930ad1b3bb90c",
"eaffb60653c333059326edd5e412413e5b8ef39eb7807e467f2f445f19e3369f",
"5bde0621e4b543950d224ef105a5652dd509c58cad3db098f9f3fda0830ab6a8",
"b102b91a8f8fe7472cafc44c62d282d51d0ab4c928da81c702157a941c47ab2a",
"3420719b3343312e8ae471c42014a6c4e94e30353f472b9bbf3c06d7ac1c21fc",
"954ce6c8ad8496ce84a3b077e5b9608a2a98305861ee7489f7b5c6c9a8b67f4e",
"0bee1e25a2365c1b127a622a7243a88c3a21fd9619f65505a00ed22361577717",
"e3526780d6ffdeb38821ea452c988ad87c09d7c15fc8e9a0fde4c56c1a7e0459",
"535f2fe83b600a9ef992fc8a979c6d84560c0ebedd6a7fb459e46d3a51b31e63",
"d7fa394ec78145b4c901df48dcb2c745d7edd5329795a446953ec97cf7e767b4",
"2f93b5ec9739d7c1bc3eef2be9b92551ac7ebac0bfb093944b42ab42fc576f42",
"222a0056d148dfad4437a04afd7b4c5c71ea8b98c651d543ffe2a44262a28f93",
"869f5d8397c0b4898b24aa84872d1e6c282d02158fb635c598d46534c6f58f71",
"1e22bd0ab7450914476be4f02491af34b01af89d3e71981a77110d88197240e1",
"126ae539347df053c96f0f2921c970626e1727d0838cfb6fe47b4c1407fc1854",
"1581216775ebda0cef1d1425dcb3899c7adf20df3247db28d6bbcf2c18308d69",
"36fb1e6568ca395e83f28dbdd26d10a059c9b6345deeb36276babee0a596823d",
"f6642199a08ca205b908ae63d862ad33900b91485c0df4684460a8a89a02c7cc",
"69b92e918fa8fe7772764161ddbf3d3dee27ea6877963bd42b2a826d85130f19",
"8637abc908b1c1cee606af5081a1a79e18b6080948efe9ac4d91d695b69a2a70",
"e903d4d4223bf18f7a2bc77b06ed776c08e79d981da9dff2aa05d6c00c7ba25c",
"6b1f724d7b493fc8d5d0cdd6089b80d72a267b45004c9ef5fa4a11df389d9793",
"082ec963d1cbacbd79be92009947c777bea9e913526514eb3f718e40ce1a26d2",
"a94a74f0b7553b322628d34db987ce4c390e02f07ae1d13daf57d9b53b2ed805",
"a2e87ed6e2fe81470a93637658557685c7dc6696840f42946fe95b55e9286c9e",
"6e3b4e00d021a31448baf60923c7c057e86ea11196602539757b8ae61b46f4ad",
"f1261575f5e9cdba701321926a0bd0903dac4d9a0977f22b3ee9a241c05b99d1",
"e2b633b5f946b076d9805a26f98933a0d75847f547999c83a734927f82d2dd61",
"828919bf34d0c81b257c08f566111fafa73d28883885789a91af768138a10c2d",
"9df9d88aa7233c4d0c7352118c751bb90e425b49a79215868f478b4ad83e07a3",
"74936a14d6eecc668c310091d3f998aafc2065f946a7ede6e50f13c486b71b26",
"8b0f260efc17b3866e24d0020bccaabf835f62099661e0e46d1cc9f311fb5633",
"3d230e1994abff269c2df5fa5eef9acfdac66a638f397965ac72132c488a7d23",
"51f2dcd27bbc608376dba81392b99943b26d19c8805ae76714f60b8489f6701a",
"b4ad402cfab91631775e268df4642a88796b7290d4f0715a8842f0b227581949",
"e2cc0d910e10bc9b15d8316e6cf7ff07df53830223a3b94883ad67da4f0ce380",
"219783c6116e44e3a93311ef698f4b77d166a6a43039face74153fb0721ba277",
"48c6d39b78b112b62d0d64562c097459c82f9841f1f3ef61517c7562e169fe60",
"833fb1821760741b70fccf5a32da447a8939bfaa20b1fae5121d29f5fdb816e7",
"2ca2a872487b536558c0cb6ef35c225e0a6c80b43f202d9cab2a165f01b43077",
"07d2c992384692987a2b6b878cee12327093cfe9d2c2be85aba81e389faf8c28",
"ee18c2839db41227ca5fbcc2f0ccabe1f40d8bb3a749347b87069f9542383cb9",
"2a1d0ce3ba2ee161c054bef9a7fbf5beecb4bbd64e7cb578796644cb9aca544d",
"bb49f2e9a5797e2f4992d872d2ecf5f77b659b864a0e9b10f7e56f1842e10db5",
"8064d8d5997132e1165a1b282c7e13545e1f2e3fd54132e36e21dd5df214d6b1",
"d937f790f4bdbd94bab6bff969281566a9a9b8eed7c9c4bd4ef56ea9dd963634",
"4f403d266d109a3caa1ecef73a99a3c12cb175a4dce495f59d3c6bb8b663f18c",
"7c98adcc21ec257c819da4eed965b7c1aff08b910ec53d191d0aa1200407b954",
"e9be2d59f0f80252956cef0cd34b2cffc17ed2e6fdc12a64b91ca0fa534d2008",
"fbcf1efcfaf8176a55510a6738ceabee6085f3ce7444601dff0b4a3831b352e9",
"9f9d967d0459542a4ca3ea1c316599e2a38180d4720f0c5e6315072050e99c9d",
"6a9244e740a26c6b8b24ed83ed0e312469dc229ba5c3264d71ec9471567e9cb7",
"d41f0991683fd5f093c2a9be36954ad031812e30c94e83c305c56adf734d4611",
"f9a127f59909def37841d2fec4106eea9ed46df63593842f88c867e11988ba09",
"14b294513c5307a24b90eeff0f5a2d5fb3421c7248c54443e9273bf18e59e59a",
"aed075c36b9b6019084513980ff3ebef8443d0b9cc1ab4c42cab7fa0994e069b",
"f2757f9715e64c66d439d81cdef7c0513a3add4e3331df57d1212fa5e5685ff0",
"345ceaf38f76e232faf9bda342033d4ac0755a6a9a918590159c69ea30520267",
"3942c2fc7b37eb278b9c7d1a37b959d0a54d61d5baf267534e54e2d467c8b36c",
"229844c8f337fbfc5199122130a96e536aa72dc81061ba9688222232ded0a3a0",
"93213162c8b18bbf35689b95055673483ffdf910e03bf22a99b96a01130a7661",
"a84e3adfbcc889b6bebcadecce38df954b4c3d2da83707a68e694f7014ec2187",
"58168c836eaa7d19e6b53d4edce3f3c13f7f59f595524175b34cda9b458a50bd",
"e20f5b66985ef063137aeaa5f908f3385f37b3b4072bc27da0d095584cc97585",
"09b5ee812cb5c0e3cd2b81b61354f0eb446ff95e11859282795d0e8241ab2dde",
"371ea14219b850703b5ea8ffe79ee7edafbc00d53b6893e6e55e589094195e77",
"501b854ba8f47662ad439b2b320a6855d57ef8b9a1c5a30719aac5b14f6e8fc6",
"b3416e4d21afeb37e9f6bc19b37b9221ec81c0f5224f4214650e06eb9cd8f613",
"b007a260b623aa74ffbf3c5e87564a8c6191781cd4bc49f7f689321baa138cab",
"df33d50432b71ca2347d98fab08d47ef4d6a6d0628a2260d05880f3a076c92cd",
"a9795305c0f28380486533b2d367d93e858f068c452e5c09847e9f987d6aa1ec",
"28f784981b76b8e673a29141991f19afc1e3535c424a690cb3a50fa4989ee400",
"d57075f0336b61ecf7b0b0ecaa683a5725cfe150a9cbd11d0c74e0fec4c9046f",
"c21a7bfe7156fee07f85a995fe2c57db97eb0694723f17dbf281780d20c3f9b7",
"337613b76aacfba647827aa63a189e1742fb37a4434634604d667473e21a50de",
"d1f362accadd55da8afde091a0dabdef67344351329a27e233ef328e47bf33f5",
"dead636504a8340a2e77e6cc320a71610c86187feaf88c3fe0c8f85595e40f24",
"3918ee01568cb4a0bde0623267f98fd076dbc56583956221a898d03a9500368f",
"3ffd99776757111ec6a0f72e752604d666a5b323137b7dc9a2a36da36d925d6f",
"7517a0a8e11b48642d3833f8458fe1da4576947097d2111b0a016822d78ba722",
"f24e6be892240d2d6f7edf1f140b2cc7ccf266539df4ae6064969e1419f2c5d4",
"7e9175e5ff6f252923cac94ce791beaeac61271cd6ecf6a96a828792a1786c91",
"6544de65afbfa1ccbd349307cff3879bc7771174c9eec768e3ee65910e228cb5",
"d62e22b0570cabffc8e5ed7a31f36f84d72a9b9f4b50ec5ca2187e05d2d4475a",
"d7edaaafba6af1f1414eb47d5ce5e8c76511f9cb5b05f2bf3327b739785bffcb",
"5f378e5c12b17dee78d8f9a1f46061174ac0d7b103d3983347b706f249f73136",
"987011b729de6adf162fbf185405344dd548170e334fe9658a46ec9479157cc5",
"b7d7adc1ef1a756be2f65fa833f6aaca66fb8c18c2f6c7b7f5ffd4daf2d1024f",
"27e9ae146adad1e70d77fa87e2cd397b44b2f4a73eca01c775287e8172520f96",
"b001fd65b63531b34106f137d160cc75432c51c987ef834978d70a2561fa57e6",
"f4a14e4fb402d9b6c1c8780e1b7dc1798ecd0263552c4f4ef4fab5933e70612d",
"aef4c42d4d5f5c50b18001b767c744f4c8f3f81f56ed49631a500d224c8f48c2",
"00d092f1e8c7f1263c7ddfdf4a8f92517134e2dece178ce726d16f3b65f2c000",
"4df685de056e8ee991fdb31c5094f3b657c015be484fdc824d8cc77823280c2c",
"81ef6391464810383e60ba4c24257d5d084472f5494959d153e5267ac7b1e105",
"294c3aea27093dc46f97f49524616f4886ad824d8f284c821cac2447b370a22e",
"e82bb6c46489816dccab6539de269f91c1fdf88ea1726fa98db5b95c6ff6b68e",
"5d3b0b39b4c7d0fd0e80f899577abe9272ad0c18cc82ada53f9a8587762aaf01",
"72a54b4e53265996f1b02aa0e503c2aef9f3151ea59eb54f718d741fab4fa79a",
"729fc20016f45aff09fa2b87e9da2606462420e42c01f232876596920045b38d",
"9ac6991c91d4dd9b2953df5001604c19cdaf4aef82576f4386de3d5d36d7f1fb",
"c421cc1668e8943dada58666f8dd7b649874849e28ba319a5d6d31d265b261f4",
"1ae69109e01823f14a05acfc6dc0a26e107e6813dcca0a4afb64ae34da1f8d14",
"c66c17aedba9ce7c3dc03c350c5a7960351f42a8c67120d67b769422adc54279",
"54be1a31c6c0ccb6d253fff10006a08a984009b0326b6ed5bce9a29e3ef97948",
"72d4a0e2488222997aa4a47c28bb237a052e06308419632ad43f680da62db4a6",
"4085c18631df262c4c82765a70921c78b0f2bdcd4634937c64a4870ab696caa8",
"aad079cf02f9483ad2199d013fb96bbf551b5c9e51dc014ffa87a20a7ec881ca",
"ffbf6768d3c6e369121b2a50f043217a7d0b93d2276e312aa012995e40e6000c",
"ebb1174166d45d2b272c2e7f1bbf5edb763ca087e469435bfcbe849ab0bf6132",
"17540aa6cefa8f990141d855683a5fd748633b8f69b0e3b51e27b0f578bc462b",
"06c1802c7f296253d205686caf33af8e2fb863fed6b7fda361fc4f79d6c6c7d8",
"e2a3b9088d1144e3bb283ecb05a0015680d10bfdb8790e80f4b243d776f3b116",
"ac8af0ab57018b809f24a0deab0978e88ebe0205f6d0235bd824ddf0c2467231",
"ec28131fb6aaf6d4c7d73f96661e631f563ed206c83f2ab809ff18bed6c99a9b",
"8ec26dff994af8476e0d23bc6654b0e4d2cf113093ec341b85596abe8c2d4922",
"6869aab2f2bb9128faf3d3ef62cd6210d8b783501c80ab9ae81d71cd4c22e0a5",
"37b3cb7366f1e68fe79ec6dad7921d601224da9dcd4f631f28a8a0f010e08528",
"d13262dc80bd884d09ada1d58131acf3345570bf6ef06b7ea6b0c3495758b4ed",
"610dc660b8f1452c97624e2db8f3a1488df62773b9115dcfcd61657bf6a6b439",
"7155ed6a52c238963c428b8b9a27799d70b1d2b8331de2ed84bb45abac2a53d7",
"5c845e089b89af933b984844395f91f1bd6c824a4c8b7645bb144222d3c6e40c" 
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_601_800 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"73d449a97915ab0e3e7f1a6b41a8fb0a43a88cb608a8d999d499f59acaf1ed6b",
"450255f7f874d2363263b8e6049f24887aaa24236057ea8000df8d64078883bc",
"6ad2cc4e57ee5f6ed6df9e6da356de8c8cdabc9246e119b1d6aee9a48390021d",
"6cfcea25773e2860d7d31f34d032482e60aa133e368f34ffa538c6f291746241",
"41ae3c00f88dc7e1f7988e92c888459dec22217f3a1b6217bbbe914303f57524",
"52b63622878f146ded897eafb3296e5867759034a82fa2ab42fd92ea24acd2e9",
"c6fe48dbead8b0d5ec8ee80eb1e67ba3cc6ec1c5cc650169e23d7a549247f30c",
"c36eeb240cbf1e78e594c94affda02d61006fb68b9eac9563f8242f3068232d9",
"11945617c0a56523fbb1cd8535d081feffa7e4e9155fe6e433b1866bd882b392",
"510c8928bd7f3c0c6cd587392953eab26ca4ab13d8e2860c1faf55225eccc180",
"7e1c8b0275d1567c4625b04573692d9d94b8571380e63ad1912454bca94bc8cb",
"71fa1237751947b556b8ee17ad7691eee5b2400215a53d84d2fcc65706745c7e",
"544ea81d3b1330d8b98f7d2cd2a1ab75905e9608fa5d3ad33b01a10740823e23",
"4bd59cd5e647f8fd465b53c48e6eaf79180707f2a8b9b15ce5cdf9d6a91d5d73",
"3eff636535bbcf58b52ae823594b562f51000f7a1ab6aca7fe27c8d779668dcb",
"f8f034c3db8ed9c7f764111af8fe8023b0db3c1da2a8d273f843284d60b9e2a1",
"7c0a51f7e88d8a6652590f8bdad97471566879392b680abe15bf79fce22c292d",
"3604063f40e14ea2ddf4d00287a1cb289461af1a43db64b8881ce3b8354201db",
"ed9d8b699538df02bc9cdff823a800ad0eb5f53818ccf954f3d01c5b6a0aac9a",
"95f28399cece84a12e7a1979723d2a96603b864cc060e91f6f7d4b6c4292657a",
"2ee2e203075df373341935ed42e1abe4b94b96b7b69b511b2c8f9b70ff0aae47",
"48807972e0d262e53c548e80e0b9986b95e7b5982562ae4f23a8fb8f3c70eb6e",
"5bea649de9ff2ba7c790be56dd63239199d3513a472ac9860b7d46115f0a7288",
"931343830d9f701baadbbd8c03236506e9601688303098587998db9cb7dcd551",
"c3e89aee34c4d72d4319d29090913b76269a607a3360155ab0ea1cfe44c03184",
"59ec245aabac6bceb1ef62e69c155618e4eaf534e904dd4a632ccb16796f2b0f",
"cff6f5e0749c192957891b44b9c30d2d5284a89c52bbcd7252edaabbd795b381",
"090bf83466ecceaf2d8b3bc21ab64d8a57d8a371591e67a9a65fa6e0f834635c",
"099758dbff308495bb8c96ba67f8faec6d18476684252a3efe1ba46169fc08d8",
"4628e1c67606b6dfb8d08aa2ca6a6cd393b0a0a55dfd2b2b1c0c1ba58f4b8ff4",
"5d4bdbecfa6c03a21e77261fd4461a04d6894c6e8888c6040eb4c7e0aaa3c8c7",
"f88b79d9b7b950d9459e961e6380eaaeff33ba5d3ec8af8b2a5e462d74ff67cd",
"a0ac546140fd2f2b47b3e31a13a3528f2eea4c7823bbd798eb5a43be93b66f0a",
"eb5f8ec901837f98c0e23799d6e4359ec94718c4268e8ae90d3ee3a1b6178c71",
"c13540e954e026323af0d350057058eaaf5e7ac0dd77e9ff25984f44238fe24b",
"b55e2f013f8b78faf61cf8082e5450efe143080f039fb56b7d3065a6ac9bbc91",
"97315179d679546dd041b536e8bda33c8f08e7eff6b2ae077827d228022dff8a",
"437e2a58327621644760b8b76ea31ef9a59a6f524ac63cc18856f7916a6ac77c",
"d66228e4f153a5400e992e3942ff37f12ff8fa58c18813cacf1695e1003676b8",
"cc2d938a96ee874c8fb9107951abfc1fb30a96d769f6b67a3138f667a2d161ca",
"fd3cd82e4de33fba11bacb6c27d6e564f980dc47909628bc4b09de63ba0d666f",
"626f802a5d009050a033db35c22cca488dad10f352fd2c29a3b90917f91a7c94",
"780447af77715e1bbc495674f0bc2c5db286ef88a3cba88a426d8b03bfa850b5",
"4bb43ea6c16ae710dd98ffddacd916c27a7dabf2c67d8e6147b3431fe6fb5063",
"b6132e5133ce31b0c9bc16bb1323a0b7370ed4d31d3d108ab0ca015327cf8389",
"23e70f86b3b91e8295aa0ed87117387dc69aa5306b1326d8f280e052a83dffc7",
"97e65b27ed7bd577e6ca420eedf38e9f28971df46c7f9ea1004f99abf3e8fd27",
"f8ef3fdde363bc74eda7610f29357a28edfd17fc987fc7185a6dadf29513e693",
"f0234a1e6cee825b4104accc43fdeb942a074e2bb4050a558ac1d575277426aa",
"cf279a6c997938a562a435c74a33f09244ccd4372ba0b29b544776c3c8ecfe27",
"51ba617634733b58efff016d79805ca3f40c4b7c8d8e37aadb53560503cea0d3",
"dd275468ac2efff483eec0239bf4e8d418c238f61dc6034466c0ac600fa057cc",
"1a052d11eea9686670b0cb7d4c70013fc980550b554825b91cafc76f0305fbff",
"35e0536fe8de5f5f8dc74100c6d5b680d4b316af4bf70c12e7ea2f0d394e3ea8",
"c1fde40b7211186656d541dd031ba2202b9b91ad99eb0d2861635f54307d6e35",
"71ad039d1da5d3c95f2b4bfc11e78a1c8ef49a44b2b57cbe8d713612d347b5f8",
"e6f03b74fdcb7848f5316b63b72a04e1827efaf17bce4a3ba5b240023a7b5787",
"221084ac22bb183806359e5df1b639eff7d4c3027addcbde1998fd9c959c3a7f",
"747c7ab67e1b00fd0a10f6330afc795277c1acdd599314776ab01c00e50f53ec",
"6e1ed30211128ce6ae67c51ac0356ed88173fdabf6eb1266b4ab62c5bb035730",
"f323300233a920990edb58878399a1374107deae82cf478b858d8bb666ecac2f",
"ba21e5d7d39f65976386d52f454259cfc1a6aeb9a19a70c9b8f72ef82d474d70",
"beb07d1dcd73ffca87673aba1844092af71305c7919861c8b9a2d36f72e42f2c",
"98cdb3447f85d8e865b904525d1ac6ec71315c673c80b36e36bacaaf031e1427",
"e15aaaf7c04d571f56f91c7b2f2cc9a5b646f1e8cdb407658cdb332f1faae879",
"ec2d1b6de1bc3fc906655d9b5073288c6720a00c270fc25a70809763d3158839",
"17225d447b9373ea9c935b9330832324b80a20b02b9d3d1bec00c8632b1882ab",
"b89702b6afd2b923546f5961fc98bd75948563ff3bf9f17fcf055943f5b4153a",
"6637c73aaccfdedcb5a114bf0e32a15137c612cd27f2d0bdad46dc61a312373e",
"67774314349f61b4a78f790a091e532a99a1e27c9c54f23da6f665948cd6ebec",
"398fe46e33910332d8566904541b0faf3b283ecd36d8333a44583c30ec99d596",
"49d3e6bf9bebe880daf4a87d0ccb87e938fda28893b640d4153e15da1c810bf7",
"7e9540a34bfdd4e5bf0dcdd43a4849978f5d77f27760f1b338d1f14d5bd68ed3",
"20d737a2b6934c703325e728deb517334f55087532e38d0ea3ac4fd236391c08",
"34e1b49354d2f9d13bb6dbb56c221079916b98bbe3231e59f3a971190bb8e2d0",
"f79b5848532fc2cc22bc04561351e7b364ea8261008eed9621227f57d0c58252",
"ee494c4688419c076b5c0fb1fbf49b0e7078826a78d0e875ddc7b37f4c833fdb",
"bfb5959db0b77e7a3ffe4051788f20b8ce679c5b1a15ab0f8d4036426ba8145e",
"a22e1a6d3b0a36644fda873abe7717cdc285bb9123f3f02f5299bf3c35fe4086",
"735fd7f84acca66891b0dcde21c7192a09c34a09427d48b4b429b4af3203bac6",
"4dc815e23be473b6275eba5a540d82c7915d68fa8e44015867424dce8c307138",
"75cd70d7ec812c69676a4ded396ee556ac4153025e965f8135fbf204379667ff",
"5f3c5484e68f925ef90b8bb5cb5f26f938c9a5ee164212c1c899d49077d37f06",
"1a3a1187a39c7a1b0710c2d0bfb44584464c73c223c0b688c31284dff4c2b7d0",
"316a0caa244f4b0fea3b9e65cbddab043570bcd4b5c7e2896cc193c22c8d7f99",
"1ac72b4a150dfdecb71a07cbe9e80f7746ed89f85b6ae8629d0ca78db4a5781e",
"9b0abfbe01e0e113a456fee8ae954935c477e0cf0aff9b29876ebe86672845e1",
"5ef07a564b3213870441ad6fb9d5eddbf4fffe1c1a1fe730af519f07aebcec9d",
"e9a2be223d60804f4a5dfeaf0415f0f17c7bcf64d876eaef1fd9bf9a2de02dbb",
"1ff2ed014cd4c45db539c6dd59bbcee6ff6cc6e9078ce8042621a3b25ab0d871",
"a5e0484a546a7132fda018c862da2face5d5d1c2d3c869f677dfa67b9379d0e3",
"cc60e6eb348d068580fd7d7c01dbdbdb65a1439695e7eebf588e0fe37707dcc7",
"1b738cd3a5a72616c273f184d23ff54414531a85ad3637397edc2023ce9f55a6",
"27b5d906ed95e3082789cc6de91b4d78c2bfc56c590ff882a29d4805e2a2ba90",
"a8d09fe2138c621ca3eb811f73e8d65bf8135c94d5289eb5b415bac4b78c0a75",
"113f50a46e1a4578b8baf701a579e9c0eeb7a08a91bae42c231cb93b467d13ec",
"e6cf8fed5ca5f2f9d404043fc3f28eec8f414c32ad1fc3811f4a0ec41a8eeef4",
"b5ecd60dbafce36bebf2b075470d8b2dde4b547f4e133eb067d67a5bd9f22fc4",
"c5c1359b896c9ad48baae1b03419b677d860ad1b7c1eb32013a0e9915d226a08",
"9508942ffa8bc2008bf0a034e4f446e52174ded67a6d29886e184fedb5e65da8",
"a11651f76efd850135c4ce54b47b43ff0f38c8832d405c87893c90338c052c12",
"cc4739fb1dee155c5190be66c7f4d4c14f88d93d6aeac0f8ade0adc3381125c8",
"263c02605bd9ffce895708176fca4d1047a2a561d87a4f80f1541f41ce33d812",
"9b20363d34a43344ef53ba0c489bced96fce8c9e9128ae8a280ef6f0bef1842d",
"21c385c9f1606df63d3052ff6bd7ef1c5692c83c42410e7eaa984456eb95566c",
"d0b28173426e56918552f8928741bf3379bbab573527c0da52a3f6c2b580619b",
"99927f5297aa95959523d15d027ac96dd9b28cce595233cd546e793d439fab97",
"4980dbe15ee717aa18bcc9060891520b022b870680056c72b1831e41c466bd12",
"d004da6971ce77204b93f744f0b0f79caa156e45dad3e478fa0884640aa51183",
"b403634702c161e65b1f239cc107f09d6beb73efeae8d401c518a47cdba2d0cd",
"990cb777a371acf86216f1fc2824ef3fae797877b5af26a5a166482ff900192c",
"ed0cbbe7dea496639c64967554cf2471263c193e727153fe660af9de6d6abf69",
"cff29198e08a06252f5d772a86691b8db2ad07ce9579f65c7f5f8ce453a6506d",
"34eb9d1375536cb07bb4c88d251d465bd9c2e3b104ab0dabbbe1f5da5a0fe081",
"dbce5c28cc3b291e0a998cac37953255b1d4d8e47105d580a5b20710729ba960",
"2eac1e34129fb870011cfbb6418f2c8a4e619a3a1f8d9ebabd06f5886da86d11",
"61398d1352e9bfe372c7cc6a1ed56404db94b71c7e831795aec5d17997971dd4",
"c2426d4108955be94dd57dd12dba1cdf725f48b62bb0e4605d7ce28a1c191ee6",
"3bce119ed5c7fbad812805d27486bded51b6204d2ef85ebaaed610f64069e601",
"c0d341fc9b9e630b947573aebe5f3667abc85c794d2d91d859963f617fd2a970",
"1706c2451a66ee83692594c7bccf1d3447f4bf165cf7eff6f35cb804c828b717",
"a03ed6d26e09f9c55afb5db1a688be8b1e9d772559ab03e4c2e51c286a265274",
"0de59fb3f9536af7c6aa9cdf299ce9526cd98ab6ec2a9b202c59f84d59bb94ed",
"fe1fcdc1ece5ca1dbe83e9cf1ba4dece358b377cf1536c376e02ceb57feed28f",
"e0b6e8540091eb89d0c4f34b192a6b413bbd67bf965793c64ca0ef6ce21eb60e",
"242efa98d7f1e02fc681060f7016bd912ede7142b616d2dc3bb669617b6eab65",
"993a1a85ac4e504b621953062e8107d82533ea9514056580c3725314cb9b25ea",
"040b9b3942f8bb6802ac4e05fe4262d3c970fdfdc2efaf0f35621f19a3e4b08e",
"29bec84e3f99ab56164b60e73cb0ba6b6369b8a26e55dbcaf193570f048ffa09",
"2f239fdc8779b17da55e3c245ddf74603dc193f2a54a04cab8013e36d5d6b64a",
"f428052cf00972b368206f964b2ce1a9d9625cafc670e7b26aaf72ef18b869f9",
"d8eb54823d077abe5a8c1dcb40bffe9835b117c19abde807d378a76442b994f5",
"f99f869d80985708f499d05dbe78bfa9458303987f33cfea88671cc9f4a6edf8",
"b7c0a3477b7816a5fec37b114e04a33bf1cd78310a57827cf71c04ed2553a861",
"24ce9f8a588f18e496f2e5c37b0fcbcc242fe98b6302143b40cddb1405f20f50",
"99ce07c5022f143b4becca9b91ae290ce69c762519afa418006428e6fdf7c420",
"ef9cde0ed449d9138fb4ea7e6e0546d4e67bb253ec69f2bef6bf98a170625aa2",
"d466e730fd2cdb4d61c8edc8efc2aa26dfd78633f896d4503f3e215068db7dee",
"083ddca4f3c4a23715668ea4c0e024c7d95ce3bc4456e1a1a940dee1455e0be7",
"419e9ba34e369e4a7f170dbc1db885426ee93fbbeb193a515a0da1578f7e4f7f",
"0352fff046df5df41b6b4728af25ea86cb418cea2e9d5d127b1184b886708597",
"904fc3b2433f7edf6c2fce71c60c03f11a372d8dd709b30f41036f05937d26e8",
"95510a662a0f0ba35212223fecfb8b548fe18f054fcdc7f5621e22661ce6124f",
"be4e6daa4223c348cc648dadafec48f1f1c49648c1223aa9ea4d6254227efe1d",
"0974b4617a285f4ead07670ad80d114eb7c5063c1f6d91eba07c46826fc49de0",
"ad1a161c6c416a9e1a4e2b135f0ed8fc5886827d876951b6ce2746aced32cf21",
"044ce4b1d4e59ae52c9a9bf41a27087b975532c9fb497cbef90d875ef2e61a98",
"29d2f522855f74d1f63fca8f23dc095520c802b607ddf2cda3355c01bcd027df",
"262a0f9decdfed0b513d58adf44ada54a945c694297ba42d7c07de21049e8ac2",
"0dcde1eb86f43c2b8031911488c276089642f7d0336f4b55c4327d5256f4b80c",
"d09325e7f42e2d6077e9c4605d0fe5f84c52afd99d38485d59a476ce386d9595",
"9c8be33b534359a1830a5ca75d25f34255aa5f59781f8aac1e123eb550da5a68",
"1fe36619a539462e92ad123e2098f1d31ff83b89c0a136a7a64f6753c62ac849",
"50b83ea3c65e0e0c0ce75b4d40e81e2ab9b7160da46387e819a226df14a34c8c",
"9c07396fecf2b9ad878f0ed70a9056852c57277e0f61f59ec66c110da1989450",
"b2abc81f40ff44d242fe69586c86a01cea8f22c5aa34a0043feef3c6eee23fd2",
"7510f2456f390bbc1913fb92c423577c250b10878d40107542698f469368f794",
"161bd67873311070726206bbb7fabd14387d415ea9415a04f1e29a422886b352",
"b2bc7b8a7bd4724d6f474fd91607946624d58aba0c2d1e6dfb3d57d39b858843",
"f194cf9481a543ecd8a3eacc3db348499d33c759797ad588bda551f191fb9d95",
"e81445e3ee61aeca526479969a6a484180ae4c2b7f86cacd56aa7bf62af76800",
"ecc3c0c8b72f2bea0fe0713a77ed30a43be579dd79fa232e0088074e848d3902",
"ec0a660cd546f9718498108ca3ab31222bf7403925f8c43ec7c9c669c48a70b6",
"ff802605de926d56a4cd68ec5a3940e03160184267e683c39302d8df56597360",
"c1833a13329f8bcb978676c6fe7d1a77caf14142c523e7bdbcc7e7c696b98b83",
"cc3556249af82e0ee0f22f0700ffb07e9807393216276e9cb68726e4028c909c",
"fa0630e838145fb9e007e1f0cb836d1001a16dda9ebf49b1cb33c870bbc25e0f",
"95d605db92ef8ae62f5208e20e8bea6a9907db84d9cde25c21a490c9e0217378",
"2b14fddce7c729a29a2cf47381dbc8f69463a5bb687f5383d706b44281a91216",
"d48079263a1f6770fec82f68601277d24ea4263e121f2c9d87018546de4a6cfa",
"71f799966f573e9e9d2fca9144369d79aa8248244204b2c908a528910823946c",
"7e3b76b7b9359ea355d2c85a6606a13df528bb111dbacd713727ef6f3a5e999a",
"7712bf915c66977539865a36b68dd7568a5c36988e96c9694dceadd99127dfca",
"9cb9f72e86231b58c4811b2239c56f75f8a9610a52699d454e5656649339a182",
"7bed6ad0b94790c3e9045bcad11f9f41e47109b358291e4518d28adf06198c90",
"57b42f2924546cbe3c067c1c59364c6d84cc9665b53de7ae51516312bdb5307b",
"aa962afd3fba2d1ea3a23a1d7445e849d4eb83d3d930ec1a39af489ac549bf4a",
"ad1790494cb03aff0d5fb7170f363a7d0cdce14877dd48520d29fc0d617052a6",
"941604028cac5e5c0ca05dffe18e32738d26fa3ef278c11e789e256ebb8df329",
"c78f8cc5cbb8ac9d9085bee219d43fb48ffc54d724c36f8b2c535cac413de1c0",
"9abeeab6330948b0f6bed16864b8b9a777f5f71dec653ee8556bed072bf26fd3",
"9d1b341377913430bcbf8e29456dc700cf13499164e0ac35c5fddc0b2213b201",
"fe048584bd2363c048c233a27554de1afdca084e6ae2b88686eff438c19f1e69",
"f6721599b94a00474fe3009cb6293784c958ac242e07799f90b57efe053c33cf",
"f05364aa81b6af81c28829881cedb4cfa83513be5def48b3a7ab4c865c429663",
"8eb3be9b34a329a9c38bd90f13fa576e9cbfd85a1003aee60c8201a408642fb6",
"1a2e66ef0d084eeb2fcc979e9481d6ebfbbd3808135d6007ae023ad86d2a4f0f",
"d6310cfff54e480e15eae0bae333b279ab6c18b1439c4b8d1fe6e27e6a81a175",
"8f4fa3c2aae7ff0d0b644509c9db7aef51d14aa4421760dee429f270f8927f01",
"913ebb6723a04287d441cbf5837f4fb3bc60c9108e6626a07f97bd2b2e30b46b",
"a7bd31288b900da973fcb036a370c4de8e0a50e7ea32af7b284ae3fb368feef2",
"a98742b146aa1b4fcd7efaa47bdc39444082d9c8051c625148f02bc5d03c63b9",
"088939abf2201f097a492922b1e50e1442d8d2f4d1be1efa9e5bea684bd1a7b7",
"716ca58431ff5484529aa11e7eb6aaba83159fbd4e307d6f9e1c2047f9974537",
"ee8f771ee37a203d68e33cfbb035505a4d2cdaef4a49b4621a7202cc2958fe61",
"0e13a842af40f1fad571707842ae16b901ecb45ac31f9be95af7f2cf8d14f8cb",
"1219ea50cad5d868f309e678f78832543ecf4d2e55beb8835c9a20a5f5c83bb5",
"6b4e40e65ba7074edafe1948c1816590d74a525a7f31be40a52be65eca75049a",
"52ba71e7dd6392b1e9dca9d99ae061531e09f870b5bcfb26cef2d28aeee38078",
"296f5345bfbf3b2e7c1553d6babdc1d04829acbd99a7f296ec017c46bd2d55e9" 
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_801_1000 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"1d48d2bc3aaf27e0d5de9609031b24f391284013319877b20025a31369be2432",
"947ae5a64017fd2e7317eb47740f1b87e96696a12f08c65ecae9f5670017c2fe",
"d346d2c4eab7b354b72a9332733227ff2a640238f4d3e3b8bf2087f64cf50219",
"552b44497f186dd317c092bcee8b5b24b1fe327f23c49a6146c24db09cd2daa3",
"df41516e7a046d7c94b9a59f0d9328479ad12ae8e60cc72e75e81bd371105114",
"742af194d07929f024e288bd56098f801c4a228df41937b3c05c88bea4fa2b41",
"2591b793e7a036fb580838ce0cf02377dd98b9c770cf14400f9523deddeff0f8",
"714660d443a6d55d69174f12a8a3c6c0972b6720470c9cc7c0479abb891e6d38",
"aa383ddf16f9c89cea3c504c60d6b71f11c204cc124f8aa6004f156b4242cf11",
"a1dbfe1dde93b87982127321e9c6983dfb9f7d947e891ff3de45cef9346e77e0",
"13aeb416e7ca0f35e83ca890173404be0f75ebe8fbf779a084cf3a4b37a471de",
"6fabaabeec5866d9809f3006aa994571b0d991e8444a6c0b6730303e028544d4",
"cba33f74a4531a41b1e72a2da99e4cc5ece1b5e1877c9228cc26a7689774141d",
"f0990e2f8c677ad3bcb58fbf707ba5ceabc2ea04b6776c0979589525966a2a0c",
"59165a34f2c1a9988b2193281c7bfb5a09cf2db219223da68b8d093e0b320e42",
"5d93cecd1dea4b500bd3bb6d27df579ebd355ed12c2f6003c5c79c58df585e18",
"b52ef2a3dd96dee9e607ecc9fd77739f12ca8dceeed243e6cdd733439f3b0949",
"f4149dfe1a7d095e1f76c5d4a7bb6c30d2f5f8d6b1d1be7baba1c3207d1a9c07",
"64b3e6a23cad9dec19e004254722e135e3e72d94d4d122fd4e518e96aecdfde6",
"f51be6012af8e6c8216ed1fdf4c04ab9ab01d4ea410ebd69e3957a334b510423",
"c1ed03ec57249ff6220a036a67a206fea534edbd25758d3768290a028e476beb",
"524273a640b30a07713f9e8687ddabc66ab6564377409d386f5e8ee8ccd61890",
"a87b8ce8622d830ef6784cf6844afccb32ea3ad048c7e0695bd0392690a53dfc",
"1235b9b611920bbf3686472648e85f5beacc98782512f6122cb23040ce995535",
"39d0e42c0e35004ac2bae8e53da762e499c56a82eb7efec0c09ec1883fb0e599",
"91d0481195aa36da32cbf4ed892e64c4122291b8679877dffadc69ec91a7195d",
"a09e26ec611d0f5c990abf4f802075a5fabff273ba5d5e36062da34c81ab5c48",
"f1831d0dc05c5738553fafad1faebfeaeed30e5c0c4d4a24cefb6c98ee0ffb2e",
"09d3bd4138cc124077a5285bbf1f8ec09aa7720e69e9d07bba27b2eb859ca4a4",
"91650aaff2916b2d178f7fabf0f558f75b69db6fdbf3c82050a6b9b09665569c",
"764131874d60db1aa3d13493aed5ce6fc141844d432b35000aed1f59c004ee51",
"9a6ec786be7bccd806a92d92b3bfb22e3937e766889b8218d7b03a215bc451fc",
"9b4e5c74a18719a27c9f50cfe99cf040dff8e67681ceee91e8a316b0e1addc39",
"f834d308a251a9e688391471ab7ad3abcdc7b0431364cfc421860d0a3b590391",
"1a92817d5599f9e9e4b7ef06e844ad35b652d6b2ca417307ee59109047ad99f7",
"7116dee49e53135539909c5f0b256e5acb521cbba4cb91539bea338c0d8ca275",
"e85d5c8aba59b09a086400aa1a2ecbece7c1f469fb251cf18be1f90fe472f6f2",
"efed766edc0cd5b2fedbc28ed5b6fa2420c4b8f77211cda87e0ab12a7fb4c1b9",
"7691b833b798207337e0d7e010a8bc97e17a70f5406a808121265b3aef1a6228",
"25cc1ebd470fa9e14dc6313e7f257386ecaf205cc4f91db563b747ecaab13825",
"7342037747726a884a0780f310f4d7a2855821b832253b1d028d3c521432f87b",
"c20f8f97a36f28d8daa0ba00ff5d2f32765b7b2b89b06c4c9af92017bf0c9896",
"93028d130a1b116b2c4df0805856e0534d8b1c06efd37e0a69fed2b8ee68a8e8",
"53851e09407f5fffbe0ff1c2c80a551749c8c21aa1775f65092e188266374bf2",
"bb400575bdef5871ab9ac0bbb46cfc95ce556340b901756fd9f931bab09d477d",
"53da2141278e8ca2f1ceb16e53016d27268b2bcd4f90a7bafef82176bf9be70f",
"26f3a4501abe7a1ca79aea98b7f312f9c9c32b0bc4f99d0fe902ec35bf20b264",
"dee02e9802c73fbf6d6163bcbb769caee6f086906af445e15aced2d90217c317",
"6ab43df7b185b306aca322db649e560ba44e1a62814b871284fe5f37dd5f51f8",
"876771e0f95b0e52a9d91e93de34497b26401941a25c25abf9158098bc581e64",
"0426412c251e66408abdd73cf03534b4f8b4dcc3078f7243242525f3178d26e0",
"6f7e3e0d8dce200b5a84629aa01c024b16e4acf12cad582b3d37c66d75e5f0b4",
"708ea56621af6f6931aec73abd0bbb5a8111bec483104247fbef609172cfc444",
"3043901943f60d6e052c11d16bf43e0b32a4e7acff56d31a4b66b66f4e83ccc5",
"34c5c8053170861c008a08e361df4562d17ca6c5fe08f1e94d4fb91f684a2dc2",
"d650061671670a170effb64674dc5f57e319beb538e237e751a008a977d74f1f",
"13970164826f68fd1fb57ae827803c643559431a97c32bcb7caf1786fb03d9cf",
"ef6b5e4c96f5355a7c06d072787d57c30e8bd1aba814991f31b71befb6ce6db5",
"7cadf5d7cb2169733c5b4bde2c0ff3cd659879001df527c29e8551c41e52a6a2",
"705d46bf3c002df014d637a35f88b2276afdca4061155f44d20d25f6eae4f12a",
"e8a80a8d2a8691c4b4104b1620b82609d5aedf84f0544ebf6fc335199d2ed07a",
"36a726eeea31a699153bcdd7da835d4a203c079e1ea3afa829cde4071ed61131",
"31edb2b2adf311b515ddcf718d4f52483c2950c0e11251c47bba1662f481e229",
"c46df319767fa774cc44b5efbda214af95f54884071907c53f7e4b2c1160919e",
"cfc0de54793b77660fc00656dfaed14af60fe4328a0eb075d4223d0f66740a29",
"51e4389518501e7c0a288ac231d81726122a98b937a047c290ed6f9a8bd7f716",
"28be61da162ffd00755bd73399f5fc74a7b4915a173e954e177649cb2cb32d9f",
"f074f711a631ea8428e638cee90d47e0e2eaf2b7ebeeeb674a23e6366e2fa73e",
"b34587af93e553354cff2eef7edf8a412f7338854e35acbdbb17272c0ba0ce45",
"f21dbf56e4856fdb6303b406a24309a937b48003212153ab5bf772e8125e636b",
"d7fdeba79f117655dad8cbcc6a1bbfa11cd8025001ff4ab043e2f9e832667ccf",
"17be2656b789aef28a8aa03e6de1ce9ce5ab6aaa143f1b055e5ee4267e4dc59e",
"63ea202594245bb9b99bf8a833ae6383fb3b9954d514af3c4e6fc91dfe8d9d42",
"b025946dbd4a4c41af8db7f055f42326f352d4c4c2a43b94b3f4f8cdafaa6c48",
"dade91c5c10e051bb8ca86921743219d1b94bbe8e211c94131177d3b443d0bdc",
"b5e6cb411b267c36ad286b7acd1dc736a34e6e3427fdc223823c43b6200c9857",
"3fd074aaf9fa93d826920d849f882a2cc718f94a070cd04a214caeb410ed59f7",
"6143fe8f80826d8b30bda49b5d0bb159e1a6893450a0ca6804a82a4fa4646735",
"59b82d3f0ad10241ab015741796df19f9b5074e4f02e287db8bf67b96ab50a0d",
"91db4b16cf4072bfd50a7ac1b89b18bbbd4fcab1652424e8ae368ebb0d441092",
"b90b4abebfbddf56c2071ea3c79d70475eff6d163d57d05e4b6ccdabda3faa41",
"7f55a754f7f06f93c719566260516243ec5555829123199edb77abfca75468ea",
"5371068e598624172e6b3e10fadaa284896584b92e0e7e19fb65998822dd343a",
"0f965be58c1aa363f896608dc466708bb924dbecd8d10d37c74e1909957bb67b",
"9170cf1ff0e464ea757aed454365035afe00d68d48bff4e1ec98aab3ee74d4e4",
"1ff499794e4aa87aeaa1249451eee9771bd8d38c0f87ec70d741ba0c6b7308ab",
"9b5aa58b11c65f367a1ae8d766a25a3e80ad44f5d940aea7cf302ba42bea8f85",
"8b46d74f446c4301ea77e3ec9ab554c51cc7b93f3da580be669d3d1c7e53a623",
"990d8f157193aec8512009f80862b01090464fc2b790821d6c279eb3d6822c66",
"b471ea543179dcac53fb13fb3862709f1d2255927992741ea69b231b3796360f",
"bf9e54191a93705534e80038b3cd64bc02c58d2502135eba56ee183edf2e0f81",
"f8857c40e848b49f3ac1468229a6d14c6c61f96e5852bb06a9bf15089d148838",
"ed7d94d022b8fe2b6b23e5f78aeb9ea298c44c5dbe6552bdddc7def22943f764",
"94f20807c234e5859641628eabddb667c52cad04fc56468e3b7f471567a9ca41",
"9b0c3b19d37d05bd47d57f44d97cffb88844544f4bdcbf85cb045214154dba14",
"9e563bbe8d163793dc8199b20da6db99f24b441197b8c323e429496e1c09aeeb",
"d10410d97de2fb84fbf9b3148b30b9173ed1968aff4560d8f0ef148c7846d80f",
"da976fe7b26a0b403a71ecaebf0fd22cf15d0034f0e43b34b035c5c672aacb1e",
"679359834d5b4fc386de54ea58f08b4b21632dc13285b3fe4a6c56b200dcd86e",
"d493deb7a2d161107eb7de662361ff8b39c45cc1f427fd5ac9d54fbfb6744e05",
"13a0608f997493624c46b4cebdff230ef55e866876470d329631982518b67fbe",
"5f7182a2420fd7846f8bab1ff9d99ceea46e9f3b254aa8c4792b8aa93cbc062e",
"19c1ce966df09b2b2f187b1f6545db397f5bd44a7d586bcb4f715030d7ef9973",
"d53a6166876e49eb9ac654d54c1e1c68129605b7ca76171148d640a420f30f1d",
"9883856a7f68a6cfd00b1d448570eef5a13087eb3133fd15491e08ff623503e4",
"ddcbebd56206f9526edf4d098235994ba6b0add93e57bf0d65d06855a4434c7a",
"e2af475e4013e6104a3f22318ff803d7eae529da23abf32392cbae955b202611",
"00a9e95e6661a28672fb15c49b557e48943910d9771815a1c3b6d77f48f788ed",
"6ee72e662c0bef53471b96ffff2595f182906170480a050b7bc3990d692e912c",
"a33af566e966b0d2f0f52c1dbb6cfe1a11594de6f5f5894498361a05107a351e",
"f3db9dab277e2deceff9aff052f745ad7253181529159ed0bbba073ead2799a3",
"8b107d8f7b61a77306fea237a7dce3815af96f712936389b8d7995bb6409c141",
"62267862e0703fd62f8a1f0bbf9d8570abdce5e7dedd37118250f4600519e7d8",
"21b76c51b520a1029517b5da20fb293e43f20909e5dafcca160ec7157ce231e7",
"da125a5d221c843f66fff61edf433a73fed3064b59bb66e512f99fa96c0a9015",
"ed5b0bdfaf4c451d3fd5bcf887a5f4357f97f2f996a253e29a269b9ce663303e",
"8f43cc8ef95236055dea5b65e41e6a88d4ff1f4f516d7183127af691139f6e02",
"74635e341e9f28ad00f6ced5c8fe0015b9a1045f8129b5b3f193a037ca9c4f84",
"df8ae3acc4508ac807a271e68e38a49d84e1fc29696a33116e139c71c5fadeca",
"81da56ae8bbc467bcbcf848477a165cfb6f6bfd008828f13d21bace4c8acc3a5",
"b1a868b5ddca11bbd412a6a2c47d4d0f69515cffc1a77b7b0b4080e52f2b89c3",
"fbec2826dba0ff3c3dbf75b3c7d8a67adc0ec56cd61282c4ad2a6773e19969b6",
"19f3794dc5a7204c4523fcf72d7ae07f1c5409ff756b4748caa3c0e8a444365f",
"3176ba13c20df2ab8feee707cf96f93c8a19803012ae7c8a348f5c4aa3fc85ed",
"beeaade15e5a0f436c1b62a409aefebf9f7757dd2ad510e089a7dc02fcd208bf",
"c0067c296eed4556f89376a00f1a5cc5bf760c70dd1f98822960558031c863d9",
"bb2d68e0ecb8edd814902f695ecbc6a6d71e500ce89f2374635b063526d3fdd3",
"1607c08165693566a58ced580c6cffcf1b00ce3133e60a197043d7ed042f74f9",
"b0c112c138611922fafc9f9d3db65cacccff8a082fa0c49fdac710fac8993f1c",
"ef8b32d0457238f9c799996ec7c0d95ab7f81cace766bc414ccadaa43a91415b",
"4ec1db3e2a090032c2c267bcd5c391948eb23a0cd3f71167e9caecbe0ba3d2ba",
"036475d6bbb8db2f5ac2a0c48338f37f9a3ed09545bf39ea3ff00cda2380b895",
"ad8f3a66f5c72432aba68c7b8b90942ca9f7478e92dabd39793ff4ed8cd0d961",
"74e051d051210b51d9c9df7423c413a9b9a74f360d5055c55f49c3a7e4bff90a",
"aec2eedca36dada6bd3796b28fad74df33b1c346f47be8e6226a85791d74c604",
"7f0c79e3063a49f5fcc4093525dc258209c1fcc4a03128e73dd2764ef029b2db",
"01b02b722af47aec4e883ee0b689d58d0a93b49c6f8c4b4ffd002b351a216971",
"58156d2cc9f42e608555b40d273f6e4c41d9a386f3d72bd94ff583efb73c876a",
"80a92674bde7dde25f91db4823544e119f89f1ffa58e035e49fc1f4cd14605aa",
"1b9cfcf8b4a72f6a8a9809872635f146a71005a3423bf8e9fe666abe7ae01186",
"63098abf3c42df4cb9c1fd38c2433adbf6254b7fec75a3b9e2f3421a58b2432d",
"67435d180d423dd24d7ee3a62de0fd494a066ff5c330771b3a03e2c1903260ed",
"a81c7c91d2f09dc558fb28bfebeec4eb50f7fe9f618926b15ecdc41ffb55a28c",
"8f7870bc32b91900c20fea8f2ffb5bc7381ca75b54cff43447117d36c6636f4b",
"6d5e60260f7c8349203dca7686d5b301405e96393f1ee3acbd45d2462556c3db",
"071bce46cce41cde9431d23d98ff23f0c7957f6fc34ee11010d99bdc000b8415",
"6a71ec77476fa75c04854e848e021da5a2dd1385edad6364d3738c37f6f37470",
"0f0d34271ba90f6afd0447bcdc5598735dac18def9310abbd3d9b267aff2d910",
"a4d403004bf4321bde7fa64e3975c6bfc1ce881fd22a91385837d7594c9cebf0",
"6330c68aae9f7560017e50d45d746ee92d9471b86f493cf292a7e15c331f5b0e",
"3c85451ada9a45bfe097b0daa4144d3cceb1223b688d4fea4a504e266d42fca6",
"964c21c010e0b0945afa5f5977b7126e730096c89f410aea5b204a44dd26e8d4",
"297f9f6abbe9fae2d470f9df982a31c1470cbe429f6414987bf56e81d6c09d18",
"357dfb54f66be2cdf6eb196a35a271f9ee7c997e5d2a16100bd37f28699b73ef",
"f48f5c510cbb942f3d1bab7462a97c894d2105a406486d5ee41207999d76de46",
"8f11a97299b84c9c55d8cdbc8677896c9848c1f0fb2d8924723215647376f393",
"db2ce7b5febb7d42c93f64fe54899914e835e4c9638b61bde5b9de6d4f40b2e3",
"4a3b3856cd9baa2f30814e44d5c2366d116915397d6fea2b0dc2e4e8a15e3411",
"0e197228ce6d6f4f98c110291d3c0fc47ad66c5d0c0f5dddeaa46de661819569",
"dfb7bf151d6e0e1a7551c499e19aab44d78e16b28b0d10e404dcfbb231441635",
"51e125b04f4eee485cd19f3ecf51a625b54e026dde68e5ae2b7c2ab6c952d744",
"7271e0435ce5ae9810094999ac3176c2769c6c4c3219f9c77269df3f7ade35c7",
"e2ac5aef2dc93c0c24d1f7795ed1e97f25b3c91c9efe4f4e3e74ba9a3c044a7d",
"c9501b22234e6c9fccd60bed4dc0b33a4b51b0a16534c87b492bcd8ee2568683",
"42ba8375cf53801100ce44b23b874aeec448486d500806ded416ce5abfc2e4a2",
"ed6eea6a76547b644fc9dfb33a01f7552422150426e878de7fd65fc8d278a3d6",
"3525c32f26a23f4a86a1698c5ef54f63da2683a77afe1180cd24e112f633ef69",
"80e0574b0fee3bb2c728528330626257129048a47ce81327421ba617f242ae09",
"ecc5d8e9f4c8a10555fc78fcab6901a40d82089a6c3d900274fd60d553740318",
"04cbe2d9e790036799a03c44c050075bdfc4f6cb68611194ef091306142487b3",
"380e035142a096effe5e167ee9d4091b8611042c8b54266bf3f6164ed326a2cf",
"b7cd550d4fb536ea8cc5fa921caf7891f472708d51e63daeaffa00d1b14d2f36",
"54f3094c62309567763d048fbc1f58bc6e713bb9b6b42b2049ed4fa3ab53b376",
"b94a50dbbadea3b81f3de93d61e24f008acb0431e12af1ecf84fd1052afab52f",
"24858e80655e13b394e3eb0f8f91ab41b5877414c1a8e41bdb81530b002b8c8d",
"c487d060a755a5184d087baef95482044177f114a41956ad6e3127cbdfa4327d",
"f31f7988e8af96fd6921a07403d60b330c7f80e86fe5f47a7b7ba9f986317f24",
"e284f372a5fe5f876b6401f7f77b1e1ca5a8ae3e251c479fa31f04cfbd9c5c52",
"7bba1cd0d6a1055413d51bb2e6ceac3cfe5621648382f2f5850278393047f940",
"2a6e4762e7b06c47efdd2eda8e73ddaf52910ed2b67347cbeceb27686ea2f065",
"13ee953e1ba4b52a6a67a6883c03e786d100c8063535570a801d8d8c17261a26",
"f73db7163a39941a5fdbf561f7a736f6af6acd743c4bb0e09ca4e889c7b10871",
"8c34baa306062971bcfe27d32c9ccdddbf105435357d8d2847a8ff94e012cb6e",
"be8d566fe52a532785529ed7e64183049b42faf189202d0967be771e1af94ade",
"2395c6e9b1e0c43ce631e83ca3753db37aa70c0967472a79d99961c0f4268cda",
"cdef9213e857d00c597a60ce3a9af03ca689fb9277ccce2b01cf160268cfd76d",
"0bc5ec932b2148df86e6a5f9ad31487334164765e0e4ae1608839b6a55a0517b",
"70e45fdf740c3b6b56b8529504e14d7c5dea69b72923da3f721d948080943858",
"9aa7fba264755a49cc340fd446a81138494a9175ba5e6ff279aa45e2579ba382",
"0a4c9cbc28e079bed1b07975da5fc135656801021d06a094c741e7ad0421da16",
"5bebcff1c6360b20d903cdd070d39e8cc4a21a453814e4c860b6b750d5d4e846",
"6e68d645cf50522e969bbc4a949bd2831a0caeae69c3148e0ca408ce406a75c6",
"61bbc787cd405df544088fe2e7f718128cf88ffa11d6d7cbff7e7c82c31dc4af",
"758c809dd0dff09bede79b0d0a84150eac3b346ad1fb00448ebe456c3927381b",
"a43bacb5a1aa04b7ad7a1edd07e0e3fbeb613181bfdcc83c72876767d71f8f44",
"5b8f40e19954e672ce689f1b39cb0db2af3d804215eb02426a35085906c04172",
"2019852ec721f773003947bdaf807a23cb94e587d08ec4ebaa8e3613fe645659",
"6816b9fb850a8f26f39a56079612f76d0d9dd99066af38a194143506463dd344",
"f5ae1927fd46504f1393391a12bb4abf81b3df508a3d5c87ba4fef8f05e6cfad",
"5ee481d81164e4b07129133884759c096b3f1a1b832578bf90ed80608150699d"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_1001_1200 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"3165e25ec4bef4a516ac862be23e99a0b6dcb909c4a3898088e01889a9b5d776",
"b94aa01ca49c19da85bb96dec21637d8d4260bf8441263c979f565512499d7f7",
"874b32a008e7cada9a3764a224ba68b0a358b78c3e27bbf838510eb401219082",
"f0cf843ab541eb1447717099b3fb5b7687b80a6b3e34409e3716d91906b5c17a",
"a3c91c7825b6018a751def0255fe41e972c9219d03d7f84789458cf4801fb034",
"736b98d264d8e508f130ec7abe92baf4dfbdb4df9f5e123f2f805c965d494239",
"8ba091675ad0ad2b187d7910d73974713cf7cd25c20a5b4cff44415a128af708",
"407ce765d5d6153133a707afef0698f6584d833024015f6037f6ebd622a60547",
"eeda584fb71fd1b999527588576e7008cf0d41bed5955a7f86cea4e55bec2cea",
"a0de2c0b0fec956a04425acf8898e166ca21ef914c5fc48670a9aefc74af9bf4",
"296cc336e5e1b1545d6700bea5beeec7c373bb4455e24d4044f00755e75592b7",
"56b582d11e79905c0f0bd581cc5e1c860336ca7b5c701a53624f4588fa48f203",
"c1f8103a97b52d5c2d7697fa0f2ff3b5bbe58fd5524412ec335583ee509772e7",
"555945f2fb38ad6c3439bb7500cb39763c5560313d315aa14a4fe02275c0a587",
"3b0687c27380f0d8939d38ae5344591140ab9b6573dcc25604188ddf85c96d1c",
"707b6b232a254c4c2be4cd581d9aaca9d1abb71f4a35e38fdb8f4aa885fba560",
"4815fecbf6f7f57033a18089c28d2ffc773d61a51ae4da78ce22f4a1edb909c8",
"97f90f69ee53b67fef59e062fd8164cf55d910683f7036713820e2ada89b262e",
"76aef33786c31361ee418f2ae0bc35b80ad2325cf6829a4eedbddf9c3c4719f4",
"5b4a6b97b59d5aeed4e75dfd5962d02cc2510a33bcdbf9658ff5abf2058cd828",
"0d8b324798d19c23a10da7a3e8b1814d28d114e06c74e922fb9cb78af2880c98",
"cd788ab4b0c56c358c2b68319ac5ed58702666f3353623c3d2ded491593ab2d7",
"7c82811bec0ea2d775a962d569fb471040cffece35553fa9d5ee9105a85ef06f",
"60febfc36ee5306b88cdc5f8d2f75de668fc25ea35696841b2a2e1d3f6fbc28f",
"d445401bc9c9b664d7f4d7032f8b40dbba72e1ffb78967e53f42e0fbf3146783",
"1bdfeeee2f368e3f6c987ed6d135166d25fdf1afa3ffc2d36416bd81497b4b96",
"c56510dbecf6a6eb24e9c0ba64ee6df95dff94d7bffae3366395d2e1df74a418",
"b62e6fe0a4a64ab83fb7d9d8be5786cc6409ace9215c5221059b406e72ea380a",
"a8874667a09d1734a0e31185052130aee913fdfa92a54f425df1e738d052f5ed",
"f6849fa5911728344cb30858ac37e19742a9b63161d3697247dd6d093841ea28",
"fd61ad0cd836c8ee86705a4272cf9d19cc8ac7f2257ff144327845f2534822a5",
"492d79781b0169754d0dbc88b7813c24d40ec021882392cacc1a3421eeec471b",
"f7e6c4dc339e6841eeb0070fd3680c6b65b3a6f3f13039719befe4fc690ea5d9",
"4b78e78e094f27ab8b21f356c8ef9652c31d489d787c81a2fb48a464f73f30fe",
"b33a21d2527c5820e15dfc23e4db61ad4ae3ad0591e222226994e6f9ea7764eb",
"43485c02b57f988915ae7a72e01435fe6c0e90d0f87575581f2e94a062445811",
"f8620fb23c5165b5c15fe7c1a4d8f93210f3f2a026faff9b1cf4a4e2ce04dde0",
"5c22716b82a727f717b632399b08c5b14737c8aaeaea61f6245dc06efa5088e7",
"4ccaeccf01439d6b33af05709f1385fd2aeb7a083caef3035342a182c63582eb",
"1019e85a5c8f811412cd31b4e90ae5715c38b9b682bfadbe0f47f746b1a8d383",
"19b74f0f97ada1c0189aa814011c147b187857a1ef12e427240818bc5c0e6cd2",
"49e1ba6aa1f65a42c8f9a0a220fc6fd02e8bf4fc0ea2263db8cd504487791181",
"7cfd69743285bc563d6e8ce26ceaddf8831e3b04dcfff5ada80370d0bb8cea76",
"090c861ffd89ad7b6e1d81ab733e942686112809d2d76e33338472ebd799102d",
"b1a98d2ccb74b732b44591f27326119589281500079706c48d9feff6cae0af0d",
"04b5efbd6bc385b5ff41d288b777b122f998b45d44207bf36d95ae28ae9c3b8f",
"ec21132b1edc6a0f40c0edb057998ffb251f79acbc461583d38597a6d1851d5e",
"6365bafde538b13802b3ca37977760aac8d493afc6c1a4db4561c9e7a9a38208",
"8772fec5e4ca40bc0b3783c9c5631f6a1c0d88bb37e648f7378258138f1fd9f8",
"c691521b5191525cc3d9350247aa4f478577be694a1b1611ad8ce7a626dc322d",
"17901bf9b349a2eaf2eb26986167fe47c7fc7007e58bd2a5b5527648ebd0ce5e",
"f65c069f182e7c6d93c522f869a01a1b4a2b8d280c7bfb32c09a342446f9e517",
"43d41841407de19e7acd8898f601274c9f7056d8a613cd685bab0808bc4fbb9c",
"304d19c2aba290cc08f8a6e141a2582cd8c721f944389ff361b1c11f27bb9751",
"8adabf6a2a805716271a16c2942eaf124fbc7ccb4ec01b93af5ab291d485661e",
"1699f9a17665672d18d2d1283781e69d2030ec60594f169168d553572aa999b4",
"cd687787e48f9b4f3e85f4159a4f6bf98b2f8773c49c107c1aff1558752d79b3",
"98c1c8a9a14a2c0af307bc0133838816dd75eed6629ef1166422eaceaf595674",
"a4ef50df6508525f226f2804b08119f8276f5681b73ec2c296e5ff057f379532",
"06142eccd4ad8f37d9d3abf3d6ea05f3c506c62588d4cfc376fa4dc9a91cbe1e",
"50d3e0020de84f1569afbc0b928d1cc4f549f1ccec1fb401add52f44274bfb74",
"06d1056c6aecac233d54634669c198273a6232e6f1af7fd1bfb51835db24efa8",
"900084deed8c67a2f979bb0a6c65144da3448173b16fa4c047a8a42b3ff5d566",
"bb80b789f61120c7905e07a1303ffbf1f701e1bd6736a2d168d3e15f61a92518",
"0e1dda06ae6534a29ab3c2f1aceaa1a96a657ed8b818d4cf39b3b4082c446dad",
"f0348c25f1e81d17956efd71c2869782d4096fd9979f3c2250f0a63e189b2248",
"5bbe15e17a9a05481ac8af3901070e9806713aef2d87984d42a63d9f00010791",
"c502c59c9c4b5adc8a15f6b291e119d973e40b92e25369eeff6feed45901db81",
"024444afca2fed3d91391b79a7823f2ad64e793493f775b3f089337893b11b43",
"470784862991a7c2f62f638e0da32c03d1621855789ce3ebdcfeae332f4005a6",
"967ea4c7103b8219e66115526cb5613a7f56678ef55fb39daa6c7c66c8f7dfb5",
"14ac469d04a67d92d0d002b300c707f9e6d08f4e35f853ec721f8597b3385730",
"1c91717a583e64b99903f6aa3875151f488a1f2c48ddde104830ea1d47e3a1c9",
"eec228221cf358405c10d0bd0b1e654e9cdf219771a407b3b781233c7dd8d171",
"1711ccd6045c097b9f3c9864ca41421c2678c2834e45376900a57e0650d062da",
"933e0bafcb9564613bf9c6958a3076e8f7217a69f28bab21c6b1b56d9a729cfb",
"8894c85148ed8fb521abf59fcdb02605e12e0e04504f3e410c346b074caae2ba",
"0cbb97c60a91898a7ddf9ca6726f7f8bd59ec258cdcef3baeda95b2e97d653e4",
"7efb69f212a00d59cd29c2c2ab20f4c037a177e7764739b7429e145c2eb9e0a4",
"8c539f4ee23d61cb0dff53848dd616d53f8bf113696fde139a30ef6b4796434f",
"441179069d3d1d3266ba448d829e8fd69c4ff5167c84de92ee789147ff905d56",
"6f09d7a9cbf115df27966cf0ba962a4bb2bae755f75eec6e8211dadf78ed8252",
"4af484276dc39ceb2c5ff26f87eb53bd136f4378e3bd4b899b226ca3af89e64e",
"2a5deb7b024fd6872b210505638d74181160d58c25c0ca5da081d55229948143",
"1cd9c30388c52e5096a71d325d8a1c7b3fd0390bc8dd3f828ec1b5a8fc0fd7a3",
"1a230789e1c0ce8fe353207fddccad74c1d730810a20c5b91009d99d8bd69878",
"1c298be575db39e8c8a3fab5b2fca75ea17f76ba0713d59c562cba4a0b71ea54",
"a50af08362d72c35164a54384b67dbad46aefa30165e0aad6d9bea50cf298eaf",
"94cc452d7512bd7cc1cdef7498e25e0af35104e45d7c6b5b80fa4acb71c47d71",
"eace33a76f737823bad70a2ccae34b64b81aeaf8d1ceabed0f784573a3afcff7",
"b9eb8f12a28b1d7a82980479ce79ff792642d4812b3faea4b786516a3556cc51",
"8fa00fe32181bbb94c6eed3b79fd207175ee950ed22ddcc2863262dc963eb679",
"4181cf9e4ee566c4ba5cbcd87a043f239782b65e04885d4db9a585fbf91c377a",
"990bdefeb2a25be11a7bbed5ecb72b716fd7c0c7bd04eb89ec940146c3504bb7",
"8feec5ec521219bb72e58c03c85c73193ec663d00c664217d2990833e141c90a",
"549e7fe05e76bee7706068da798de7bf015ded4b900ccdbb050c1e50c9bfcdea",
"9f3de8b066093658c89365e3883cff7d97981a6adbe5ab6f1eb90e53f20638d1",
"61b4e512cead37228b0324502e4a09c1ad7c7cba23020bc0922de9f01d18fac1",
"26d90ed2c2d6a092dd83fc0a5b20f5b36a575fecd8191e723cddc0dd9aa50040",
"605d497b5ea78b8cff973ad6041b04679904825f391c4980130487ac357dbdd5",
"92a89fbf3035a10e1c1eef43fd7bc1f9f03e12444306e6f03e0d1d05ed9f3d94",
"0760b27e0fcb19c25823491a53eab3d58eb7519083076aef66238e29e0235262",
"e42b519336d0e51bcd5d4401180ecea28395be9a5dc03afdfb405366a0467eb0",
"2cf5146423435f0777f6bb20ff07fcd803e31b95ebe9fb0c97f4efad7b673825",
"c3db55ce2e15e725f492bf4d025ec0e7789becd0436edb855731f3e20e2bb376",
"9b1d15a4a962d28e4c2578bcd0ddb267387bfb07aab50e355350360d7a2d4f9c",
"74f18df1d011f8f49806ae024dd597579511172020db1177e8084bbb55526672",
"20cf36d966549cde57933cdde506d35771933f83df776c3b8a07aee6e34085bf",
"521e2ed1453e5f0668e297112071387d86d6e328980033915d878c3d3a634812",
"277f8107c3de1ae668564262d22e4f716fcce0c838d55dd779a55e404f700138",
"964337079ccbdf50500684eb9c689c248d9989f441a0c497a971c145e7acaa67",
"d141400d8c39557c45f559a84b5db8a21f0264a290804d7ae67f7b3562c3bcb0",
"f5ccba8e8d770f358b669868fd48898ff31ced21fac8fbe9e4247981f1944e3e",
"1aa0b0cc0b9a68664a539b846a52a4a2b77087096d4df6b344fda45a2bc3b2f3",
"5c7e3308b17e37385a87b9d52713bed2d9c5a003b812ced70fb768249eeb9328",
"8c610e254db9f66d2a681ff2884555224b86a69a8152e6a06653d5accfcd29d2",
"7a0e1a56dfc19d2406bee00b51812be8d0b41f643c6ef9ae830d437a236826b4",
"b724d3074a9055b4f8674a90b4cd60f22b7c2bdc42216b7bd5250d9386322480",
"071eb0f17c94c0da903427c8ea7b42fea6e2be981ea9dcbfa6cc137780eda27f",
"b70d63757401b1b374ad18ed5ac1cd3528ad6874cdcf26ba85069f5872dbbb01",
"b88dca7d0516d78649dc48b5217aef58fcf5fc50099aa7e82d073b214dd4aecd",
"da8a0e14c8f28dac7db2ad89d42f7ad9363851b7294be0ec0e0842a9c7e515b4",
"1f3147207fe94bea635a17b28db570d311fefd88e75fe2c3b91ac8147c8c0448",
"cd72d1fa55018e4fd7dabe70c3b8b4c3f2f822538074444ca7c7414efead0580",
"6ee5b47588bdfc81779fc6337c55448bc5023ca8fc10ebd8bdfe1c64922dbcad",
"3d9f23f95273bbcfe2773c271cbe734c02e1ba6467d119cec7905aca28da2d2e",
"6df36c03e66bfa25214e51dcd4307b95e32a14eeb7787f4d7bc550fc539028f3",
"13daa04114399cf182cdac020977017dc4af2efa57639d96c6c1b21bba3103c1",
"4b6633a16c5e305602627062c0801cb6e5a57133438a92268eb99af31d62fea9",
"d73431a4c6f36d850e5dbadb992f10d37235d6083559acde444357add29a6212",
"eb92bad54980c9c2c5f5bf8cf50c3d12d2bc4b297f1d6815ef5fa7985614fe82",
"b569008a35c1893489d062561d1dde2132babb9c7ef7c3f305045ca467174d59",
"26f8aca40ef6cc251d15ae28c9c6934c156604a42d4feebcc98909a93046db51",
"0dec409406fb10be19947fede0fe2f6d544c80fcfaba7b4802ca7d311492443e",
"4a8f1de4184af280e31f79a348ff0d46ab86d52ba1feb03bf58273a0c2e84f7f",
"cfba066b4ae90decb7f9a01f3b3bb1e62b6ec9373e4cddb876534eaf0ed2843f",
"14a9c6455948e8a5edbd5d3be9d3f9b0646f849730a6d0e6aea60dcc66cb4a16",
"27da7799382b6d70e9efcb7cde2b364ba2e77cb699fbd979b52321443710ff12",
"f05054d2f5e6b55f1b35dd779683e88a4895f4c9b1e7b6e5c41815689416be5a",
"e6a77a11e5aee82bb4d0f100dbb02c43b52d87f2b4cce99910ff3296f4754e44",
"f5eb84f87415ecffd1ec042fa5da712f8ec546e28874a4e238385689b858e309",
"dabe5c135eb6e1afd68becdbb7b8e195d118271b1f846db6d52ad5beccd0c65a",
"3e11071f87d1e09dfc9643b33414b0bb37d326e1d5ce48b9b3934a9b65dcae61",
"3d4c80de1c3ee29a3ab42016018366561034d1dea10976c495786795463c4639",
"702ee93cdff1b1bace31e2e183b80edf55475f5a65e74538d74f08a836be89c9",
"a1a384028d2ea7b4f88aa9802d0ac79b5abcdd496e319a13e3d7845c44a6c2e7",
"3a193456096fc08488255f46cd88831e63f0eaadab5cde9b6c023738fc63f6bd",
"635fd9e95187a59a17461db5256d92407e8bfdab2b1e690e184c745f4a7714c4",
"9127f72fd8ff6104640f264c5ae6011649c41cdca20689df7f37f64c8d7d69cf",
"1043618d9aeba2f98795ed43035967d8c6ff9f062fa751913cbd9065d17f40d8",
"75ad64a203057774817e2ed3bb793d78417837afe9fddf1dc6e2fd6abeb4878f",
"6f8d0ecbbd30bbb2ccf1655f4665215237a1350798b6ba65c8feb4ab26d8d659",
"dfb703561ca114c8cc466178dfc36ec7886dd1242a9e0d564ad842d58df04a80",
"ab475a2832619949e88c74f2e2c59301da7ada6be432d7d6560462d5ea5dc718",
"6fcff8e8660d0b3ae21fecdb49e532de1e84f0685948251d6ddd7860658df721",
"a8a5e39900f219dbe7c2fb7642e4bfa82fe391b1314319ab478837bd2cbe84c7",
"02e14a331f37b0ff55823ce3568688d747cb5eed54ddd0b15af8442d86249919",
"88e1262a6c3068be09c2b17b28c28eb6f4040a1eac48afbe666c2812b5646767",
"7ffdfae5efd26e84a2f47e5bd2024fcf820f5c1c97aaaf67be2541a232cd2dab",
"4af7941600a1d45be5fa7811ec6c11a1cbd26e57692954e3ce3fe67cd89cf3e6",
"73a231c801463c37f1382b62684773e4ee7727cda6dd53d5115a939d84f1e720",
"a25779568ee0bd4b33ef9f881cdf2d8ddc883f1236854ba66eca5ef02309a9e2",
"9fdb1e595f8ab16a0624192d08891f2e2a9193901dc8069b682f3a5422a1d80d",
"152985d8e1ddee77a9985a15d8ba093bb9e8ea6345ae68224947d5615cfd5418",
"108ecfee118fe1e42248ab009383ff354336fb8cf5f655e88aedfc714ea027d5",
"c2da42b299d857296a44fb9b8086f065238d0c724e3a74a4098bd8a9f0e48d57",
"e0c0f334234e35899c33a2c811f3c3cb5b92c1ea424febcaa85d411c3681bd8c",
"759c1b568f4fb0ba2f687a8146b8355b8a2f0a160d69af73a84556726e53bdbc",
"8c9e73c03448678f8af24bbed15ac851833370f12e847eafb24f5f632976f539",
"b3ad83ac3e3bc79e4435f12e6668ad41a46ab9e3ef8dce72d14c4369f23a18c5",
"f4ae5b3b44aa0eab206945fad7db9cc7eb007300760876b792ba7f63941c1918",
"824bb1e3c037c93b93b07a704f881937c15603f365401f5aee1d46317d6fee6a",
"bcb29c75576d668056ee8f8b5708c0a41691ed8a7bf6ac8ba55e2a532ef17f7c",
"f7b0e7d0c54beabf9c3c58a77e871fcd5eba1fa34a4286a3bc574240c482d86b",
"4b597840b04bbe84f856007cfd037b7d4ae2532cc7aee8da31c3cc1ae413003a",
"3b1bec71545ca5b91859f4e8102a82e3950e6c98a7276c28265daade9592b56a",
"f36607ff859b2c30fe64ec2c4b1b7b8a94a9e9059064f1d2328a6426bdff7df9",
"2306b6cd51be1447271a5699a1a7d4e269bfcec754944e4755bb8f19055f71c2",
"5fc4acdc3d9be779e7ac2d99129855ba7c8ce57a6441cd4a97466e8f79f2e131",
"6bcfcd3f0bea57d99b82b4f869a1de0c2c78b1bf7307659e9ca3fe384162dae8",
"2d0dbe3701fe3e59d186fe343a89a6dd9f4f0dded8e3071ac9ee7fbd040f626c",
"bb9a85a0138e0b340666e72f37ae8d0ed62007c6c06f0a718cd3431c571b77a9",
"a41ad5712ffdd87a2b001241c3606f3d27ed4e761022b1fe02d180d9d358b37a",
"e610f9007afc67f49b662c6d0fe597531c0c4f4fe40e2cd8832ba6550d324376",
"dd27951e00a2e96b908241e9df3849c275c7525e94402f9d17c362737fd12ede",
"0dffb7a46d4b4aefda2fb549643aba01f63606026fb9ecc78885f99eb455e351",
"355df7b50e64ba3aa7c7f61925f205ab9fd8cb89eebd5c1875852a2211b58d48",
"eacd61dc4408e72b99e91ee384c68830fe3f4bac443f6cc5e5cc4ff731ef195d",
"e6ffbf18a288830815f099645609f97a8ee0d21c1232f116a94f478cd0d2b213",
"64c43366e8d13de618f5adb5ee580dbc07fd26ac4a7bf980fc51bebc7897f1a9",
"67eac19e3e1739377a1587201e3a1301fe76eb59a30f1ae824618a03003c97d5",
"c813c2ed0a9fa7d96e1fcae552cb3952d60a72e9e2475a63c0e08e9b9be34d41",
"0e02e3919850bd65461fe2b5c37e1a27c2c86fce10de876360670641fb558a50",
"ece463fc9ae7cdb3d8553362676fdc3e351121c63adf9996b741908b3c787673",
"2b0c0bebac72fe24044c07c1bee75535a33302f669196d69a0aef39e636bfe30",
"486fd7ed8890d6a03e376d388d220606db295b14feadb2bc8703434b0cc4da94",
"cc4250475962d86d7d6fbdef0749164b22f5b3bbb707c7ed61d774b231d028f0",
"1a79c52da852b6517e38d6477a31af15e038b7e31da5214e5d1490c9e5c8fc39",
"61fa8304d65be75a7de205403d767ae196c0e13b2d9c0a61f3f806428d20b11d",
"6453dcf99c862dec8ace90b62c248d4aa36030329acd964ce09dda1177353d00"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_1201_1400 {   
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"154fe883392815e0fb0677f481d17133093958a672d9db9402d10ac1408112f5",
"4b30e88617b744b37a920f06fd7ad53eb4e1135840a03c8b962d910294fe856d",
"a0545ea455a4be8df9f1bd0acac3311bc057c82883586602575f23176972513e",
"1ed281bfaf61b1bc1f8b784fbb7466096a401cceb6a36d54985593adf4d8de20",
"9b91cfd8aaf0c150987a6cd99f6a974c34335ed5e0389efe9c14fbad5a405be6",
"9ba153aef2a5a073e42499d755c95166b936d74d96260dbb40e0c86e7365dddd",
"cd673b9500da2c9eceee515a3bc28bea97b0aa6abb53d86d8bb940d6d28655ae",
"005b7fb92b3f639e9d6a00b9140fb14a075863694fb419206e1bcf981f64c7b0",
"4d780439e6e8cac1e9c27e4eb7398d7864a8a5732c5cad4cb9fa4e2a3277e3ac",
"99b5e45c000aaad8c5b852f8bb083da922c660ef9033d7eb08472a4a7c62fdfd",
"ddd061446e3937104996920e499d2a835cc08c8ae5ca837b828a73fe07969e64",
"fd5cbabad0f11a2799bbaac9984c9645cd85b44a3c410d428c1316feb3bd9bd7",
"c31dc20be972a39420470596c17d5da6591688c53d74725839bd3a3871c207b5",
"0aa71b8660a1e075171c2317c5ae26d692260efa711db524ece91fbb64881128",
"09bb78d37745c4e0fe0b2758f11949c77298ddb3a9da202e9bb3913d4239f2cf",
"032581260a1b7bb726050445ed5033f03a6b79208b1d18f62f0ac2fcbf4b7715",
"9e210942560888274f00ac7b5f9aba8f47efd42f8adfa0c0344c1dc75c05b9a2",
"ab24aec7aad35b075bdd534cb26a2c50d0bad8885b0de86111df646336665b63",
"c5e0cf81428a5045a98367235f3817a2f8f15fd90fcad6fc09e56183e6438da9",
"0e12770f53f18b5707250c542892335f3ff66b79f8f60e2f893aedae33f674e6",
"44a1e6617365fd8b45f9dda5bbc0993ea023404b86f3f82b848a58cc6e06580e",
"124041a78fc2a372beeda63187cdfe2dd8da661c337b972cf0015ab138c1523c",
"40287f677c50818d715210824ce01bd857d2e4a9432d22b0911c3b91da56ea48",
"2206bdba73f1c2050e441aa2da52b7f2d88e1f93bd7bd241b29959042e6897ff",
"722ff5a2704e21743781c2accb8424f7716438eb372406caeae93829904f72cd",
"b6577d7ffcd11b522c52145e40360321bddc1ea3cd8787b7235d7edb142378ac",
"7bc1aad7ecd0be526ba362cf14f1dfa39ad01db7af58bc27d604fab2d45582be",
"7e546f906f63a31960c3af7f8db90ba3e0816dacdb733956fef576124ca21916",
"751d963ef7fcb44c49f8e1d63edc19c2742ebaf786e2715cbb60ee96142acd7c",
"6b875b8f56f8217c8886c1f74c7067a81bbccfca895ae901653622416be85a74",
"75ddd522ef6148f8b1caaddbebab8985076dabcfa650946435c87dd67f020e80",
"77112db77b61974a96ab0560f0ad57b9a9fae60e2e4cc75968f382def8b84af8",
"f8ab7f69dda3fa6c38338e071c9def05572f8afc88658951eb7dfa1d49e1fa61",
"fcb7147b729f98f00b74df1015d80aaddeb315f18ec837ee921c295f62df29bf",
"3c4b50f68b6b3b85041c2c37ae5a642a7a013c260c552fb336e5ccf3e1c32add",
"2b767c912b4abf40b64eb8aa4c4675f7841d01e267937faba1da7c60ee8771fc",
"c38f4b999a280231047cf9d5ba81b56e65db797ae907a1ebb4f0c0db3f196512",
"9c6261f7580e12d803c297255216afe7bd98f4c6fea1a2868405c1c13ea94017",
"634b050125fddd093ba4962e2167ab1a793554fd1c7728a7d929f5566acc4028",
"2dcca7391a04e08e43307de7c1f406732710fb0e2a70d1e87158c6f40bea4398",
"178240d7693e7356ed5f45a5f654d44678f3e26e3a8ed46c77bc12986aec4d36",
"8606a2036873cd942f3d2daf48237973a9ae12bd0639800d5e067482d560f046",
"b3976d2ec481538f45a1383456f9a8765cf31765f59ced59f492b16ca246412b",
"97f5761649173c910dfa4cfb8f21da6d6990059bb2011ac3aced525fdb8f5c1c",
"e0fbcf06b3f636c3fd028ecc1964c02276c2e83ff6e999e98d341f8040970168",
"29a58a6d9f57ac6ddb6edcd9145ea9637129c1d27fc718167add8e21e0dc5312",
"1ca25e73f696906d425c570c954d9733c13a3ec360f36600046489cffe802242",
"a6938b2909a70c2f16c560a9aeb69bfeb73000bb0d995fad2af8dc5aa48ca352",
"c38a37002693ccc340a819f31e65198038f9bbd594f6bd4d3080f984fa36dbe6",
"b22e797b454df8aaf8891da8da73186fb8c0c4600945925e38fa256e12d094c1",
"1de41fc02b070ebd113967f5dad8c3acd0e24a3159e0f0f08fd2cf46f31eed2a",
"ff4d80c74aebe3cc1095a70d35eb4f7055c51fe802f168ddf7fd14b121e88e43",
"bdc761faf981b19bc24a63e153985bedb4bb09725a2813c96cc33e41785526fd",
"0fb813efd5e767a7f3544ba7b52f19397ce97db5a1fabcfedaae3c9861f9774c",
"57eba1be6b68794902c0ff61b0c0017d0afcbd3db72a31d9df0a9e4232b61e8e",
"e845676c791c08080feaea1f7fe17e458159617dba44c615033ca5dced7b09fd",
"41a677556462d36f1c5a24fe979a22ea7016959eaf1be3ddcc12558a967eb622",
"da3b8b1c219f101631cbb68b47756601b49f9cda05e187de8be1228f21f9e353",
"512ea4c24b4951787903277fda569397be805af432cf0c5d69b342406aa7442b",
"c43760e7073cf0ce3f0c80e2ed1e1d262fa000cab8726d1e2ceaa44c5e193d62",
"0b6b55a628027125f1df9eaab89b3d49cf47cafdf6dbf25441aa1cd3a19f8b25",
"5b68659a409f2ac257b0b1786df77e32745adfed3b2e3b8993fc7d03bf5a06f2",
"8e1d467f0b09cbbf9f9931112ee84f7a90a2eede381fb86bfa6149384f56bc13",
"200d06a46f8187e3a16efe373bd52b74cca248a7b75a77d9c8dbd2786b17f8ee",
"a72b96b4dec8645c0bebbeb0fa562edbb4ea3ef61609b90d135d7118bdd13b54",
"8638a6c62d803637a5bc0363b816be006d0379d51fe158e84b052eae4feb8e9f",
"cec1fbf0a836ec25ca8a56e8b954836d76c81f04fb867eeb6cd4f263b18bfac9",
"6e9ab5a99bc633194128089a473ebac449a7c194506d22e507f2bdaec7c26d88",
"0cb8c69c3d5342b7f82bad96fd145e81f84d25f0cb1e7945e5d0acf4558bd60c",
"71eb5e070788857cf23a420a9f37d999cd3c05b52c3d8f7b166403250ca7256b",
"a0c63c4de3765fcd9877b11caa6e9e935ad7c5dd84a6a3601808ee1f6ede21bf",
"1d8a0183559cbb52f41b37c8a4a92139292511c7236652aca908558549a6a6fe",
"c7c68597e46f2b777c7d03d3f45005b42131d05fb807ba3d0a75321b93a62376",
"2deff47dc2f63d681e46f4acb4b0f59b1ec57750d2468aaf508a929e5f2d0d36",
"e48803f4257dae0840a938a1062ce1b0bf363e03d40a8d2ce5600884082fae63",
"e36c63d21f672d772d40b097c6be997b8bafcd0d2ada6a2f84fa7fd2057fb2c3",
"e5888028fcffe2fd8f607ff54d9af656348bf8a3bad658ba0f070b4b65294c5d",
"e1a1216211414e2ee9762dcab8a767a94d4cd498d3768508d11d352f054e1d9b",
"c1d7181923aa51b57aa231e0469c92c97c75cc938ccc353f7a82a09189228204",
"b010794c5616e4cfc5148f5541a99e652013caec91c4c30ec85f56bbeea4a99c",
"c59444364b7051e90eaad732bedba06f13fd85273a9d0d98b7c11d913badba87",
"c6f2923f2ff180fcc12a60107ddcae5d0ba19a65792136ad1d290f87c9121ed0",
"c23f6db9668901a4ea86bbc573471f5ec46df9ba47c99fa9428f9f539a3ae093",
"eb54acd995e3b75967821bd10d10077e55f538f4b8fa085a61ebe8309ae350a9",
"cb8cc51b4045754c25ffbec66ff9820fc01c4f44e0bba251f3aab3074c858d17",
"0d9e68cdcf4a70baf36a4acca49821517930a46d2ba6307c9f2a7250a2bdf768",
"1cf2e8ef00fae89cfdd1cbaecd624c0caec7f93642abae80f530f479db24a039",
"a78aaf9a3688120a4aaea4cfa4fb4af6b07695d53d9de85697f55bde2551f88a",
"3dcec394e9fad2391bd19f8262da0252a741a91bceb7fffa2749741e1975c3ad",
"6518d6657906c117b191011c3d86b9979f17c6ed224976e2dd1d3252db164995",
"9c984272063ff5efbc261911e8dcb8b67a9b62f4fe00f3681d087bed72eb5d52",
"b7def8745bd89b27b3e486f095a5aba44623485acaa6dae0d0b194da7451c43d",
"df5765061e99a9e34af46a6bd1f1fe6714d12ff94a9c21444dedfded52263b61",
"e95321cd803d314eaaf2687804062748e6ec76f3d706e0728ac5a7031b152e9f",
"c229fef3c4b467e934d335f567ccacf7369fd246fd740bbca8f57b708df68a0d",
"6ef56b5752fd2d07c764adb6163fda093447405c024c970c8a8d0b8743004430",
"92dbb99c3eb27d1052088e2ea46a804965083abd7b414d8c7492841601d672d3",
"12b89e03829e36b75a31a9c5ceb0df86c8fa63a22912f0c82fd91357f896fe4a",
"62cf0654ca6f3680ce719a2b339b674ca22d1582f579739eb517a9681945f1d9",
"afc83af92b5e3c81988a4bb6fd05c38abeb9376c9d28a00a05f0ed2e5d62d2b0",
"2ef1452f74753173a2710496d35200c06c37627dab1ec53dea1ff918c717b058",
"51e3a7492567dec7786b039ad44df9776801cd0f629851cfb8cc9eabce0b784e",
"af19acc158d4997750acc7807b7f3ccbd62db2324bb539d2627c189eeec73172",
"3c27d0b51af281d26da4f8eab6f8e8a7c585996bf836de4e19dac44994b16028",
"e2741342c1fbc2fda1f7eefa63f0317a382f59cdc431cb67043a32600f8b77be",
"b673ad477e8bbd891c811a517a88fc24612ff554b5e28dad1709d00d8e47512d",
"df0a16d6eaf6351bdac98b0b313b1c3906ae87141d0da706295afc5a6f373797",
"b5d27fcd9734d332e2952b387f54b0b29d1e6730f2dfa6e04cd57f93c1b002d6",
"b2d7e99cb38f5b2d9643bf27ced4370400f46785755d162a56be548a7ecce744",
"1a8497e946fb8d181a23c675f6aac3e862aedd6f920e91edfd6c4cdfff210bac",
"840a3a8c35046c94ab6c8a94df11ee1b79b6ca9e896e7be8739f44ae22f6a19d",
"665a9a26ffe619eedc84d0b34dce68ad1e0686d0e243baf5f8725a4a061d69b6",
"8015c46cba66b2f4ee3d5db9743b477c1786443bde62f59a9eb19e9de99af0cf",
"3c1219bf110b49d20d7a9be78c868c46b3b236696b89fe437f90723725a37cc0",
"69aa781f6f72b45818b6f35367a11a58566d047c5fc07f9e38b3eb041dc9c7ce",
"f5142bcc418fe8b4277aeca2469a18996502ff4107f6f1d110767f3d04642636",
"941c784ddeb5d1d37a0438185a739cfb313dcd9aff218a14e6f047bc2d26b562",
"d34dfc1a40c5566e540cc3924bab9edd135868fe19f35cd2e8c0a5f40d287ffd",
"e4fe89aacada2cb1ec08559fc81e71452d1952e1bb8db41f02bf703c65ad24fb",
"f7bc3199b62a38e4ff9a2a27db0f07ca13df965e2a64ef3dbddbc17701be11b3",
"397600a1da30f413d4848e5a9ea5a61762cca3ee00922e6ea561917dd53002e6",
"e0bbd43ee8b5c42ba74fcd7d40b25170a2fba8a67cad9c9a4dba49716304922a",
"b3d3be62389ec028a2f682747cac00c190f09f299bf50179f62e43170f908cda",
"3025a9878fb7eab968854253b63e2dd51403e428fe9d065deb1c151e65330c85",
"ac7ea6b95f273b0380185f35720cbc615c76c8385b156a295d63653fb32c409f",
"d224037e59a28a107a8a015be5f68cf74a2ce855f29bf599c00527c7e07487b9",
"7c1ecb91d747df0d24f0289890037975448718f9a255be0cf424f2d4eb59fd63",
"3e5b86d984334c3c7502543cef8f5a72d0cf98e590d6f289571be9cc7c683135",
"5d5340ddf7b902b521b891289f9522902bedbc52b0d6c5610ed6d52fe34697cd",
"6cc01e66d16198923d0ad740bfe3b5ac70ae3cae29864acb9a87f1c6182b56cf",
"b36064aada156f5167bff0ffc769673292e8e9e26b5e52ec6b396f37f068c8c2",
"98078b2fb07f46ee4ea5ee848a6af93a9d40116c0c1603e36886b3a24318ca8a",
"dd941a7d4945a55258e9e0da851c99c65bd469274d26831576e9da486aa6cfdb",
"f87dcc6a3d7892af89b5a3f831df4afb366e5adbbf5bbb3112f5fcd918db046f",
"a28fc77998e233e4fd3f4979a6870b659ea6fa2e12faa38417de5d489f8e6a49",
"56de560016ea3334474335cf81840bacb47d791e9743d6ed6e550cb326fd1a98",
"2bdc5221ea853b04d83385c5a492b2438532ace3be019f7438754dcb93c5beb9",
"b2c773a5bcccf9f131c7bbcd611bf415a380420628ba92c31eca51a35837f772",
"caf73963214128a09473c738bf333fe6b864b5a3d3a886a0cbd347e173880991",
"c48865d4ab4a4a21591425af1401916d9bc134dc933b21eda2dd9606610d8696",
"c0a939b694fbaf621c3fb67653b80fc01e66a60b46456c4c17308fa87f33c572",
"fa4c0e49c9a945b3ca8d5a81971924a29719a340dff10f00a59698b67427399e",
"7914ade161eab0ecc22c74dc09b45e968032f7604c03e2cf22b52cee839dd2e6",
"3724cc71169490a6575fd0bee22b491c536aeee3c76201bdf5d229fa2193022a",
"c89be8c69c8b267c994f131952ab9251c4c8979a2a343ed3e7f618e474e12150",
"1e1e3ac3c815e1d30cd490507e422b871f29cc03a7f813bf8138a62047f1a233",
"99163fe2a851e5f4a1ed756ddfdbf05e925cc9243540cda8448b59246b06531f",
"88d85bb51d3242f94f37d75e6d2d8f6e1e5cb280ce55d67abebeb17c9959f2dc",
"dc3f63eae561b9f86a284425d906d0c8508825436bac16d97416195b744e3f5a",
"25b5a735130e869f0bf646d2d14324a85902c2b61d60fc00fb89faa7bf2ed857",
"01c637ada2081bcd9f523b4b7d6c8ca942cfb7465f5a2095066084f18630e53c",
"53540fccfe8b10bef1334fa9f8f114f9a504eee0c9dd1ba7a07930d32a11afa7",
"9bf3fe47254c59974f9009772aacc4ccc387878f0eb6f22bc80d693c69466cf1",
"31fdd7eb5aed1d3c425fba9dffa30d36f5dfcc26dccb9f07b1e419b96d2dbdc8",
"ac6f5910464d7040951aba92ac2bf4fcb75f83df426c38839339238ab4ec8961",
"5a471dbaec0387cf5d376b5c2093181d1f3a24ee3dc8a5d199ec17465c1875d3",
"b2a49693e1811c2c985ce9bf533427ebdd838f70eee5e7572601de390345cf5a",
"4cb6f1e7c2caa72fa11ea02e9c00cf919ccd708723f0fce826feec61520938b5",
"a543ad37868a866e2d1823710e6c03c17cf543ab3baf841c80ac6d924a471aa5",
"5f96b43043aa9aee4d0eb90c1b975cd3fd47b6146f9973901a487b660ac83156",
"6dbd6172a77e413c3e705a66c2a8623113a8253966d679db510c3ccb924d376a",
"0739460e33514d4ed082aeed4989048dee414ee454e60922c07c252ef457ce39",
"01bc45f36a62e4be18cd4d2475eed330ff2b765d2fec9547fcc95e7a6a8f8006",
"9cfc5abb7d7f8012e4e9ec9fccaec238f129e4745da6ab2fdb156ff500e728bc",
"cbbd8f800a18957eb2fa847474a1e20b1aec76d8dc4e43673a906db6a8177fa2",
"ba44660d91c5ae3af97f7b4e92e67d6798ecccb8be6abe8426be7ca58c5e0c5a",
"2336fcac05257f9888602c00c697a0ebaf63e9c1ccf3a67eb6d1cf7b1eb113bd",
"39bfdabcd9c65c96ba8c5e75f9aba713c8726c0d8d4fe99c8a4cd7a1b3630f84",
"6e5bee33ba0ea4606c132528274216f7508006834e8ae8eb89b2248e9f0854b9",
"0fca0fd96d59da568f2833a6b79062c4f373ba218ecfca40a62fa4315c56d8cc",
"8498049f1a52f6a3242904399f0d30dd951b1fec8cbcaafc0dd700fa89940236",
"23c198ce547cce651496858e950dc591a211aa5a4dcb439cac8ca771b1ea98d6",
"addb17ef1370cdc13e3f6a3a0a532b472cd235cd961ceb467d0dff25ec235d5a",
"1029d93cd7c7315397a0ddd57a2aab495b387347a7525750d138fd7492cee445",
"e4ded1d15a6b043933cf8a00579b6aac02a1a0852dd1c0b28214e6ee9356c721",
"ecfe9eb7fcca9e21bee6d6fcc3d7292d558a9d8ae7bcc62dd814ae2c035869c3",
"fcfbeec1dae92e7e95d9d160fcb9a6cd7b090939844439bc36a96bdbf16962fc",
"1cbb25910436a32db385d61f41555a58adaa795bb08f087d0a5672998bbe1a01",
"09632a36b1884c4c571d1484d211c660ccb3869c4b3c035e50911e3ac5bdd8d8",
"41a22e1ddac420c94c8508a17903d62adef5fd94e74e43349745cee7482bebc9",
"3ad01bd2185592b15b41f34d46a8518329f7405efed6d93395ffc538c2f63427",
"014bdaab56c2ddbbe368f57dd9700f6f80a9777919dd09430d2d4057af2dc1ec",
"3aac07169f2ddaf5b68be84e12eb220a0f42e7ed01c110948307a46de9c0c209",
"a9139bcfd0121d52df679720a58a2dd02a93f433baf10b5ba968c0af8f27224d",
"db5835d58c09237d4eb6e93e41a80f2c37d031afba90294cb23105ac48d46fb1",
"e9f271a5738910bd011c15b3ad3cafea078d7ffe2d8bf596f4c5a6170b39a6b4",
"6ae0bea0d0e236b7462734b992085f172827fce001a4d69d9834bad9c2881885",
"5f00b81a43552d89007a2ec4b0bb7c326209f31ddd57b0e078c03f2661005f59",
"3ec29855d6544ddb129642ff3adfe5bee491666b7feb4836d0c4cff8d096916d",
"be8e1f04cfa8ff8a6b6f877ab68ad5b2434ac2dfbf3df78009d4adc7b346078d",
"7832559b0c49d608f10756812edd266584509f3cbfed963b3fce7a7415970d38",
"0d1f7c9a1317f6cb04539e7b7f7371d32a8612342ed901999c453aa1037eb815",
"e69919d8cf521b6ee42ecbd60d41c9d198a9aafbef8fe0a2626f0481b0ab4e61",
"59a5c342b61163f8b9fc29731159f84e65b0181ff90041024aa332ee320de281",
"6c2960c0b4afef5be26652bcb1858b5df86eead56730206ea563d49e8c0ac893",
"4f69abde386427db8df22acabe1eeb368f251f996ff63cbce4ddd4219f8ff6d8",
"f36a78132a7b690ec098fe08f13350520162919f8833f3f0f25348ab8332cee0",
"915d10f3f954a0f562bc77ece57312a1a23aabf1bbab033c13ad7dafcb56a39e",
"c1cab754b567e7bff0d9274dcb2c0967c43b58ea42ac3a1dddd5da56eda1b058",
"69cb05daabd123c1be283a635ae1f19d2b7a60c38c3a017c1c8462fbf7246f89"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_1401_1600 { 
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"93df6cd4fbf9933b0587408082dcbd27811b8a6de059f794b54ae3b1f80c5752",
"ed34b87e2ac4dd3418b13fed6939d7c02c4a937dffbd6657a2743bd6bae35b86",
"8cc64a19d363d63b93452ee9e1a800145fdc564f307df9dbb86e1cf7da4388b4",
"a394cd04f53c3d78d2bd6177dd6a724536146c25c149485a6ce5d9172f14b773",
"af43a1936be8912edd5f840b387ac6c2602d4678bc36ba55af7ea357494fecb4",
"eb7274cd2645b32b2e584667ee1769b63300f8dc2af1427659ad0f6b61f72e68",
"dcac9d82eab6fff076f9660513e343c434919b1f50bce37711b27dd010a945d8",
"dec84c27c519dd6496b9cdb868b3fcaf8670ecdd328f74ca2b912afbe6e0462d",
"80555f5353f0a79e9e0ccfbb1c10e632c2eb1ebde94e683415c06e64bca07b11",
"e2d0e45d2a6eaf4868b580ab8ad7d23095273ec449e155c2ce1be62bb988d6ef",
"c40f4e67a1a9552024d00b11f22833c907fbc9dd25cc7248823baa3f6a9c4d25",
"61c801f510ca3421ae21737df5d9805a818252a82ce24c20b539298024416c89",
"7a0dc229b584a023fd0d4eb1cde29a2a00fb906105c757260c3d1c26735a1e43",
"f2902834bc228af05b43b5cd92e77f53f8c53117e98e702a8f8a6926502d0be6",
"d1bc66cc67c731915258cd6c71a311525f6a4135815b266d1de273c6e89753e4",
"238a7886bdfa0bf72fcaaad5d70c4f6868775effee01593b36a7fda377d29607",
"ba85e8df7dfb5d6563ca8f83e1ee032d9117c86927b5e8e1819ebc28bf47765e",
"8c12de80c6e90f8c8a06998cc38f9af5116893a94866623534ed8d30b8d6c66e",
"9fdf702fb57e043864d0365ddc2d493ccdfe5c2accfbf814933753e842b7eb38",
"59a3d00e528f634a0d7d1e0705b340fd574d05c443a6fdd1d6c7fb3cb7f5fb14",
"289496d249be3bec90b2e1a25f226d73df6d5240123267dd1a7bd6c8b4f98d9e",
"df96b7936313e165fd2d6257eab2135fcb69e8a58072698e78d50817a4db2805",
"fa498ad6134a904659f49891d5167913bad5baf4afea4c6fc7a71151e4a2b46f",
"21a34bb169ca1c574f58d9ed910e08101130d0bccecc5679d98258ca12c66ad4",
"f488107486bb9a9970549d607dc0cc3c2cb3d99df6668b7fd784d76f7ed41e14",
"54d500c9cd1546725f05b9e9e9295ea1091acffb3a064c81bd7e702b8d1d7a6b",
"6f585ff7f9e72fa9b7c9bf317af8f4ad9ca9b8d826d300eabdbe3509a9cf2e19",
"7ecc4b6d2c787e3cdd056a6595a81a975fa809c54eeafd705a35eaae4cbd3afb",
"63934901fd9a6786c0b372015890d6e592aa41118b9ea6762b2aa3510496128d",
"624c68cdad641b93fe56309a0499a8c37de96f403d35214d06b30e32ec3185e1",
"778b5a94a83f4f3597e32b5ee21ce73ab5611a8a92ff68326a2d40fcf2d4b300",
"1a65e42ea93751d8f16561b574ef9514f607b729477a7e717d02f6f8ae9bdbf7",
"02eb56ecc660036112ab69cd70938e2214023986ff768794dc4d232682662193",
"2c25d05a59ac31457a813c28e0659bfa381d811d542157e10518116b0532e3c4",
"8bcdf1b3b250a2258e8d109bac82eab46c9c9138c0d7fda4ef607fd46069bc0e",
"a1885f00765e3da9a136a492daa8b61bf5fddcc057797931d45a94ff2f20a16d",
"b11b25522a112fbfe0f1edfa7008be6e954134e45124ddc91224e156e3e9cdac",
"87b23c255f5532beb73f76e26c282453c4ee0fbd7878cb2b8e80c5735346b4fe",
"b801dff830e4adde3151019c21aa80b27814b87445757c88c93a08c987482512",
"d34b05d7251981421c3e98873bb6c4c18f9343ed89f9bb75a3bbc322a9ccfa07",
"3702c00387b39c8ccdc56b1f9023ccb0f022db15a4d4a5224c8616219cdd1d99",
"a16c6588f4cb76f7c138d89dee8dd5756cf57f46d2e84a86343d2c17d26423aa",
"0d32edc89744a10ff230062341cb2abf35799b69b062761c4b331d13808110e1",
"f6422cd6e23f99cdf34d1c257f03ad66b8789aaeb98de815c1c27c1c924f3f0f",
"27b5568c7012c1f467ff763afdc81113f59753f70723f72ab1c032a993f97524",
"2a66cc47ceca97f54e7a006016c1a0aac43d94311303a82a0684e0c8e9cd6a1e",
"c0533974d2001e287ac5ad376d02ce542f1da94668e4ff45ec4e52602b5a272a",
"df932fdf87915dd1f156003020dbcbcb5a3555bd4512a9e5ad2e39fc874e29bf",
"5b39469d5e7cee0229190353e14620bec1394b977e032b778fe00f7fc29b91a3",
"2882bc52ef51eaee6fee1fcfdb790b1ab2cc9b5195ff22b7bcf874f0f3174ecb",
"99acb65503cab66c0025b9d6d92714e640479dcd091f89dcfbdfb9de4cbbfff6",
"d5c6a9b60ef3ddf654c0921591521c300f7deb8f31ca1c8773eff169a92b401d",
"8138a1617233bbc6de349e5bc6fa0642b04bec32a261297849a7004d4dee94dd",
"bc4a5f2b80a5849fdc8048245132a25532abc86d9bbe7b7a5e94a553ccf12f40",
"e78e2387578744c43027f2688d5f888b3bf6b7577e54ae45fbf3e7664eadccaa",
"04cde6c43ebdf7123c27a8bec4eaff11217e5df701a5df76717d6496177c94d6",
"7baa9565da9df100347477583ea5bed212a163a64ed33555f79942f54b7385bd",
"91379b606c939773923557840328d25b11e01d359dbf1fd67bef7683f7b89430",
"ad4c10e686b67419f506f723aa43910e25a9f04bea485446b8edcf58436990bb",
"91cbb89907a32c8310eac24e34653e058138f44f920fdc52a9c21a6ca1e62e3f",
"6278bde089a12a8595ca40d29aef529b8d18a7832162dc7f52f238cd2a17b18e",
"a8911ec99f219dadeeaa7aebae0eda01143ca67fd525d8f0bf246686904589f1",
"3ac1e532f7eb15aa93088b818ab994b2ffaed673a7ccd5b09ab70eb97a33e409",
"4e757a1e46a7e520b1fdb1e28f95a36f4ca75c25be17f5583ea2a70195fa754c",
"97f2f6c69eaa11a42bc66be8e4560326431dd8a314bdadd23c9423bbd05b19ba",
"dd0688f4cd918733a8b6853a8991c4a5f13131c80d0750d283f907494d8c93dd",
"e836385c7c001efb61d1bd797d96f41b8b7b1f4bc3af60061e57f186efb3a3a7",
"e4f60320ca00778c9c4badde95b2e67088e032b4ae307cf9934d39c78ce8f5f5",
"effb08ec2ab14ac1914baa89c6c157554563af555ac802a24f701b9d160bcaaa",
"da7999860c79bca9e05f8a3d14adc7739a902c008f2e7af27002a9a750b7c57d",
"52cf743fe81f6dd292bf30d7903cab5ca04d839707f05e16c99051c7e934f8f9",
"94dec5e2dbbbc15b1249e15aa960c10b639c951b3e88e1daefe3f47eb28275f7",
"a85803523af989c838d21b6acff228365b45a1d2bca7d1addda9f69c031f26e8",
"4f87a49af9dc134159e7b2659d4e665ab6cf495c98b4099411a33c528ba07381",
"8eec9b27eb5d0972ba08487078f222be2cdfb09a57084ac0e2a0cb8dd988ab93",
"c43771e41e36cfcea51bacce2dec63118dacacaff090eaf3afa816a9331ab639",
"9fac23edcccc507ef9968e56218842e3feb0c887d4f24bd0069acc9c4a6692bd",
"4429ccbd3a6926c29c3fc117514e8200d3dd2c05579c23e6e9bc301c3649dd8d",
"8aaf35b47fce1582503c14e2bf4e9384b07c1b46fb8fe9fe755b140748ba1712",
"e965dc39841e4c64c4b79e7d69471f99643e403f55e16f150fc29cca3c584ed2",
"d30d2e19427f82c0afb2d7a05427adff0e53869b8abf95a5344678566384214a",
"d8f680d993766d59b8d55c1b04cc2ace33f4e99a92163f5d61a95edf4e79c629",
"779dba98a3817963620ec99598a89617aad9a0641da6455238ae1da2194e6b11",
"90c03c614322bfa468a2dea6722573889296a901af1ca2676df3241068c2e187",
"43037cb3a96e267a600ca5a3136aaeb5d90f9386a254ded8ff6252f451ae7ce2",
"267bd883f9162f96f86a93b5777f86a1dbc055778e0b7884df5e09c098e50881",
"f41c35ce1bac4a7e73b26a9638cb344e1e301b9f0e1fe0b2c2129873fac019fe",
"e1515f6c7b842e4489745f235f81a1e8180c9d4e63944b0b730ae6bd434ef9e4",
"5f1a8d1caae1d635715bdf2370d4f580e91a74d894610b3342bb9b214ff5aaf3",
"a8ffec781154820fd6162d54f2cfb8560eae57d6e3711c307e47c9b1cf668a6a",
"1410edd3bc183e495810c634f6b11cb616046e19bbdf9af7464e33fc282c7259",
"0154d49d66670b085019dfc6b61532749ef8dffe4259d214d95a2c05baeccc32",
"60dff60f6ad2d4ecdc8a4f55ca7b718fda7ffd9ef5d1bda06db785518067d35d",
"b56521a5036279111c182d7c3024bc30cc752501a7594c1d6f894c8cdd8c9aea",
"18373b410809a845ee443075864761d7092d6271522d012ceb0457114127ca7d",
"8651563ce9c13f9508450e6ffa93e176accbe0b20943f3d60f74bb5e79a518cb",
"5f13bc4cb55c369aef690861812b16617596ccb5a6ad4a298ed00969d1743137",
"21f9128bef339308db834659a869e6057b3dd3dd94f7fd93284c813f3efbbdfb",
"b604350a45d96ccfe7c83f860451142d143f588b01ae330d1812a6247ebefdec",
"02591526d2b29a3051001780d717f0ef8d5a273ebd87d9af38e9c7ab1cb3ea71",
"b636145b426ae4c2881a332ec136856e5ae0e958557deb437c53888fa7bdfbe6",
"e4656030eb6d5b2b9d4f6c5280b37f2c516280f251e4a428edfab354a52d8056",
"468f5a2610e730ae65012880e7ebe08862026eefe8db0f8e5fc22246ebf328c0",
"fa1a5a30644ae68a77614794eaa966a98e5b85d5f20f5b4b47e0d113a86f3229",
"72321ba0e2b7fd365bd870aa874ef3c207d8bff586005f0e41786710f812d61b",
"484d119a25c4db7f1c3915060c7a55ffc8bfabd074075e95a4a29435ce2b2d5d",
"c46ecfb1239c89970d4fc5e39e1a081ed7b01399f2bd63bb9fea0586f60b21d4",
"f3e787834081284d86607319f49c0466b9deb0449c5d597065f3bf5dd0306cd8",
"0f354439b02ba126acd84e2d0156bf08e726b65f3dd1860af0da521f2289be01",
"714477868a4b7613be0c99ecd0aa0527a2c31eaceff7abbcbda8f6505eb6643d",
"17af5ff1a894812117cbe80a638795904f967835ebe336366f9d3aeba7987188",
"a97b5214ba84423a9b82e58afee91e2ab4ee35c24ae7bf0d35a8a7bfeb2a7058",
"5db8a453c7d23d694972f52855acd6ec8d9b77f97244a26df59a90bb30d26162",
"2e6d02b5e2a9d3143a79576b0f2f14fafa3584b956e56b20d99b996f50fec1dd",
"3d6064c32c6edbd7d5ae35f0427f23d717649f4e5512f514236fc17585de8533",
"a67572a5bbed2055d74708f06ce95482b535ca68ee0839a55e64ceb3c8be26bc",
"6ad3b72126f32e797d519ae7895f1fbed570e5a47d1637ae6f9114416c6dc60b",
"6919e7718d622fcf42cced9f4ae5b10b849bb5ce7f31f5ab924d1f679dac1ec3",
"b5e36d4571315feba7911392a1ec372e313b1efa93c16321e2bec97936dbdc34",
"e3dab9ed1f4a945aba45329323eeee085aa685f899a4ef4ebc91fb508d43d4ba",
"570b7d8b72694969a8505d6050a437e556dd502cfa713340850c7062899a7c3c",
"2c86641992d7583d3fc7917447aa2ab2a8c8eaf68fce675ac6de178afa9c9e16",
"cbd9f57133138b6c16c94d9d6e77a228e866d3950ea2f7ea5952b2f131b68ebc",
"f8de530714b9e3303e2ae8cfdf4c6fdb5fcdde98367f30f91f6e05e2ad3bc931",
"03b2d9079f5f78177ba58341741a714e09c0b60c24d40485c871c9c9e9f82166",
"cef294f09c5bbe8932b12d52f6ada98b25038850f7c3218056d19e76bbef71d1",
"009caf8adb49fdb4c1b4ed011ac2df6420afb1882fac04774224eab2aaeece92",
"6c844fab96323c6372495715c2efe4be73655717fba3ceaa97622b2a1e910646",
"8d785b617277967bb72dd65e0713fe3370230a61b6e9fd00e0ff80d1cbc389f8",
"eb5be95dce9fad94235e82a806f04d6938849437add6609443f3e1fcfd8f7204",
"787a5cc78b87d4da16291596e9d21803c18147e1d0ddabfd9f6c91e112b49125",
"98314ee1fe4697bcccb1cd43d4ec57f4f6e37d8feff89acb3a302be533c5269c",
"178979a43f38062dcd98160adbc6c14a949fe5715cbc422d22cda7b006afe10d",
"1433173b6c670042c4bb68b54a4d76b0988dd1bae7f50a5c5ba8180126b46fdf",
"9ae9760d8cf21c10e3a8fead8b2bbe917da176d200219deca563ede7d74f3a1f",
"85352a13f65ab7f9d87103443fa324393ef63b98fa03487a5e4182ef9b61eec8",
"6c0d6ac647423c4502494b79cabe9bd0e35d7c0c9a2482e09023621fd6287dc2",
"f9274c8436cfbd31a2e14d503b5ff3491544fc05ba6d8806d27267ae301692ed",
"921822437c78b7414c9883a5d298e5ef8024543a6a169c1b5c24ac506e10dbe4",
"437689877f9b90c4e317ef1a16ab5bc0b7d7958d11b7a30cd62d42840bcdff0e",
"8c9d7129db5d27d472eb78507b8288dabcb341717eec20c9cd6e12ebf32d0e81",
"13328a2bf205808cb43bab266ffea9a238b0d948696441aae488af1af15bddb6",
"fdd5311b8b600c5c38cb3eb52d4ade3fd27c6b759057e3f3ae194423734a6258",
"30851c3897bc24c9cad6e916890ee18c990cb82a1cf2f7e6d24ee8346efb3f45",
"ddff83d94ec562d43b185b70890bbbbbdd17fa1d37fe216202003348dbbeab5f",
"8aecd36eb1363f571ee6576947cbe41aca9439a9fd395a0c416a9aab1710ccbf",
"7b4bf53e7a2c77bfe1bc29861668bb29e71f5475700868818faa52e19f5386b6",
"8bbb39f69944246dc95eb8a29228ede66ce28e82f3c601a8960a6b69d31c29d1",
"9b99ebba61147a8ae0d1c5ec09098217b68ac47ef92e9acbcba5d0583862923b",
"c2a2565c5e995e905bbd68fea4a2ae9b4f67dbf1a34b9c9803ac63a037b6eb37",
"7c6570f634daa05183ea32428d8c1c940cc6e01a02a080d86f5f8aef0e75ad47",
"9668048be702b9136e7298896a78356e78a9db033ad40fb311994cb7afd40d8d",
"74ada27982601caf84c10757b0035be50fbf2417cc4312f18462bd9d22e35d60",
"023966201def54166062b9c94c5ab8e335dd088ce253e23f5971eb7cf39a267b",
"87efa0c410c5bf239c5306d20b1856f54540a7b43612f1ff40e733d0a8791995",
"76b3948a63553e2d24114c1b6e538bdef0ef6dcdf98b81f26e68696ea8576525",
"50a1ec96a646e8c7989313da3b9dba53b1cbacb3fae662135bc83edb9d76c245",
"6472825f5ca807f906d5627164d8e7b06e2d4635172576643eea43e0e9101cdc",
"0e30388a439e706f5b5c35a5d55b30dd675c09fe6645568a9cb76cdb4ea48bae",
"1f7f7d34b2fea82ecfe3b063a835ad01d722d9f675af23142a2a2c980e421f0a",
"08451f1fbe5cab6750daa8f0f9ff75d90a414f4ab3073150c305edbf7d1d81ca",
"aafd1578e3d2dc8f36026d5d0c21bf0654d47ce3f305568dfb142bee22272daa",
"c4facf6d457fadb1d9db8c90cdb53827a1b8c77c030d9040a4031eb23c208e18",
"4ed9ec140180f9151650f599f6139325113611f1b586b6f5addf70e8236be154",
"a7ef9d5103750909052c7111337bb54706ef4fe19faa471e5e2253e740271db8",
"59165aacfebe8cc77edf1566b48e46fcc5edc733151664208bc4d880e9bb7827",
"b9933864765d58dc2363f903e5a22a0088551d1bde33102203a1259c4df10d7e",
"d30e54941432c026791abd7dc473313cde37e4354e9f790eab951c5f120e4a0f",
"247ec1166a0e529fb139161962c80c05cd2c540412920cca90c62f5f04713863",
"aefd09471a9a6d3f73043211aaac94fda77dc422d7c4378f3013bb3b74288ca6",
"a0b9c1f283320b8ff44898cfa27048e99d05d9a792427f89bcc0d09e78863f30",
"1a234c883064d3c5dd30f6edda4cc30dc2740c87b4d8de4f917a3c2294c9f544",
"e86811faf258422f150d9732008485097d4e3219b5721cd65412c47d087f871c",
"712ce2a9c1e6770583daae06876315681243dbf6e8c797c12e40d5542756d9a4",
"9cb9fa69513c6dc53e8ad6ec5bfa6d9eb2802d7eaa0de358602548776d6a295c",
"e235637794fbdf54bdcd5c5a89830dbb34b260a8bca831a1c2464743ba3528da",
"dd49a1d481de2a718f5d06526566ab401a44883679f1a0fc66681e561224649a",
"960d68acb7a2a9e4a2643924e270ce7f60ffafd94e1d88e5b4083ff8f16dadbd",
"488c2458a6101201152cc85680e2fbe3bf0dd3d7ca238a1fec4e3870408a8ec8",
"d52b8c948e4f01fa2c31823e513bb8de23be4a0386e991febac30730849827cb",
"aa65294d5ec74f2f1fd8dc59ddc710e15d36ec4058db65fdb2f14be40bedfbd7",
"1a27ed82b61afa08442b98fad16ceba217ce9bf5c3257b85f02dc71075f5acb1",
"115bcd72eb6df3dad0f31419b8d6b0f5e6e8245d79dffd88f58159794544a60b",
"246ce5bd762e12fd37d971bd74d029a207ea32d04169034d563dfef958c3ae24",
"74f6679be6fc2864d60db1d7cf16456b8010cfe5c6ffede585d497db516d08c3",
"c4613c462411a86a832123d9756e1ae0b98854d61ec2ade7d44bcead2fa7b610",
"90183ec67bf0038e96cbae80789b33416739e44493f4773f51be933c6f6daa0c",
"30f3d465213a4c93f6fa7555b95c69bfd463f5c5efcaf9531892d18f13e37f85",
"6a7d1e183be540df4fe8d0f5e7c5d7bfa57846c262c27b87d5e05158968224fe",
"2ba4412aadad7f66dc2d3087aa538b81385f36052d12a3410dd651043bd7053f",
"d70f1069515b456e73b6e438a156e8fe13ed2d7017a508d71a87a2b1857c1adf",
"ee0de08cc5f5bf983fccaab33f7889f88635dc72b642214dfab6523d3b598987",
"52ba754f748c3e3338dadff524246c696743ad2087c809686c956f1c2110a2c7",
"c480609cf17d05559beb73046687ba26a8461590fbc8fdf59e6345d7795e6fa3",
"ca3ee202b2fd67a8db9ea32c19a3785390db34e967604be3df3b0d0f44c6d48c",
"1e794d0d27b69ea262e807a90fe3720a3772c1868c46a548cb9156ebd0e2d272",
"c7e0a91e8ca1f43d90e00f86586e28af55973339a2360b0eda861f6e49eb2ef6",
"b0a71f159e4f22525d2e87349242cd2f92b048af972b63806db2953f3b359194",
"047bf659779adfbd647da5cd5bf7fbc9c64096b4ae237b53f874637fcba3609a",
"96a539c9aa17b63ef6e59e55a7726ed03bede6f35000eb53e635ab87ff02b039"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_1601_1800 {   
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"0d22a1469f57987bacaf798ba2a88e912545a58d467116bffdb6f05ff3f29e76",
"9cd80c4299d7aa778f6efef6495d5b500c9bb33c47672ed0c82932213cb46c4b",
"550e94779a928e84eb5515b25f9ef8df240c1ccaacf83c0568b1c14d34d92e8a",
"1ffda2fc927dbb620c15490cea8e2ffd225a5b9e0919c28551fc09d4358836e2",
"73a050e8a2b1adb18287aa05a5f51c79bfb12d28d8f71ca37eb42c8482394771",
"e5e8ce9524c0aefeb4383d2c37f4156ca967fedc4524c8dafc529970e9df8525",
"08d7b1276d5b4bf90fc0e6b5303ad6b64e4529369151bfb12ef94c9632d579a4",
"3e9f25e6d26edf5424218d6b917e37b1434560d63b433d4ebf5a8c92c93b5269",
"7b2ca4831c28f2c4b6bc43b14cdd1edb6fb709f20734bac8ad5aac15ca2e0249",
"aeab816603e28f80023e9e32cabafd4958ba772dc093aef911bc048acf3c0bc4",
"6f610967fbd17f1d6d610ff908616a96240b5f2c84c36850fcaa29b8a8bdc965",
"c9518a74d04fc9b2faf57cdc6c7a61dc343167655a227bc46a99448d23f4510a",
"de772445b90ec69d95eed9c46cda26179692e63fc9568609de6ca71335720031",
"fdfc1b6d1f89439003fecc9dbb4e1234fe3ceb9455701e6f9f44dca7972786cc",
"6569859914b55af5584dd534732862813999c69079cf2dbd59f2e1c7ed8a3f8a",
"a78413658e95cab573cab2f63cfa06a6509eadefc2be13ed5424f6948365e0c7",
"aa3e6e47ae41bce01b8c0a497a73fb7680dad45aa48536d97e87785303393937",
"e040b0a3f983ac554d7e1f9e1fc3adba936b124dcb5d29311da3d9413c5dbca3",
"eda957ea2b47ccf1bb70d99c056eb4c79f84f19f19a712692b61c50710eb25fe",
"4235f0592f4218d1fd6c128c653e8ef5662da8d63d38904189d1716d57920286",
"fbf2a0c7c9d3c0572548af632b93d7a9afc1ed3d8a1671fde71ccde822d9d3ee",
"b968621d053c7605dd9186709a135519a4ee1716fe3ec0151e68e116262c1d5b",
"8c5ad07b4b8a0e2ed625a922bd24eef9384c3dfa210d27467a5fa20cd9d81820",
"e8218deb4628fc3f9bf3ecf7eda4868517a4996a3c1d7e92642229f9d55c47ea",
"93d0c6939494d5157a67f786a23b17294f0e829a0e00e9138ae9dd6aa0fa047b",
"fb5e3c087206dcdec278445312fac7ff8986e39114901c9111bc80198353ba6b",
"a629cd055cdfdc0d8cc19ce593899359dd4ae809a6828b9aa43d39f33837c90b",
"a66036f77ce9eefdf4a9c873b4c44757f1195f7c029c9c87fccf1252dfe90389",
"5f1c7a09807d031c253fb8ce0ecb342cf3e0a1cadf7c54d7ebc3298c2735e80b",
"07c2eea524c2595f81ed054f5cc8dca841ddc0aab79b660c47672851ec55670d",
"44cde79b3b2742a051c85e6a63e74b311cb7be44041417436ce4f5206abefe0a",
"b8ae2eaf3034501f1f0fe877723683458f5c3729508422692b5adaaf6e4e04a9",
"1079b7672634960097707940e7827b1e2ba776b6dc5df72d44f6d7fc91a0877a",
"870c03b6745b0bffe7f41d0c2c692eea3d299304a8103ad149e4e49c0df9c471",
"9d3eec02dcc0d4f3af5639439bcf0806ba20fee9e820f22abf4b9622d6ab66dd",
"6844fac1d5f860c74ff731aad37ba37b89c15fb4c57f912ff1bf32c225dc10ac",
"0c62ac0f236f4cccae70d82d72e89e78ca00202785652eeba24882c8daf0661d",
"76919c7e69c890e16ad6d42ed6712b86d4f3106110ec252e72c7a8d446adf4a3",
"c5d564faf9d942b27e923130fde73a84e19fbaeb08fb088f6e299298019a5e1d",
"e8b5e300d9f759cd54cd95666bd0e647996c6f1f2037da433d38814489a6b8be",
"03717020f88e440cd73a42a08db4cae3188d492e52109eed28e6890c7e97d118",
"ea794eda1698351179cf5a5a800d8160fa79bd9a93ae73ae5a1141ab9f5696fb",
"8e689df7ec031ba37108a737e0ae145aa531b2894f7ffee3b7b894898a37b2c1",
"49ce34626ae715998e1b82c3dc5171d7f29d15d6306bf9d6c448abae21e5cda2",
"de43013e4e4c88dc64ffbff760e1d589db28e48a0e0248bfb75680c7c355852b",
"65a95fa67484258de0bde154434181eede1112ab75b330360b78f47fd125079d",
"77ad7e3a1a318c485333de292dce9bcfe136ec6f8f74dc96c1b6929012882200",
"540db9b75d8271a26d7c2cc5c8dccd2621b8739d6c2bfa111607cf913d91324e",
"ac94e7fca5667374f8213e15201774546627fb14a9d178d8eed02dfc3b9c4dda",
"88270b1c5010d02c645dbdd3cc7bc47e02c93157796324e897154d25b9074e8b",
"c68d7f9f316301bae456991cdefee331987bf42e45de9c44089ee8525f6ef685",
"1aac3427cd8c9a61d71eae4072aaeada56ae953d7238c76fce0ef6d4a0d8b91e",
"ec9f18055636d6049685be2766a4c523dcb066b232c02a38143e557e0a09918c",
"6bb1ae09f5b7402ec79cfc773b6cf09cbc40149ba7aa326d075408abe88f9445",
"1bdde131a397476052e2542dcbc51aec819ae6595193aef0c59b097319ec8f39",
"4795100f0d6f647d13c7fc1bddf2ef0c8950def6c2fc36f54f912d0dc499d9c6",
"bd8fd42c05e8f0ee61ed9266e0ea59750a5a7c85038a974a6ca5c64d56415b5a",
"18da8be30777263532d4419037f212e8194b53cc46cd19ffb3f686b3ab731439",
"add2193d8ca58e1592422fa3151b77a171fa24e0196fbe2e89ec87531d07e9fe",
"b18485c56099575bc079353a6bb78138f03f0efbed51f5fbb7df4ee2d140ab9e",
"a470d30bf648840c3f9f8dfc53b527e1a3ff3d69a1afffb510029454fa2e6c9a",
"46bc47cc4fa3c4940f612ba9721e2481fb337809b5f96c0a6f2625d1bc6bdb46",
"6eb66456d6bf8ebfa8634f02bbcae74a2d86d6e1cf015ca942f07e0dccb935a1",
"45ace5a52e8075763468d9cfa1c6960329a4c7ab7033edf488f39120a54ccb4a",
"812a9428406b346005464c76abe69b1db0014cfbf0cc038e03bc49f010dda0e6",
"c25801476764d5876a33b28f7e9a34371fcffd43b1ed3a229922c6b3dea30c2e",
"c23898210006eb22d052debc3c91b588d85f66e3a3dbfec23c704f663c31e449",
"a809ec56572084c54c18200388bcb5c4d033fec4625a9f6a7d971ca300a8fff8",
"8cca6ff7b320f6b4c3424f90e2d703adcef94de249e610aa61bc3d928e7bf702",
"c7e1ec7b8ad10c66b65282d1bbcf31a2a7b35b525492eb8a3e9624e1550a45ae",
"d7dfa00364fe08abdabdcf234a1e9adf6a4cfd72bafac869cae9a7e277eeaa46",
"af45c2207490806679059b5ee090a017e027922721e5066643085f4ae708f4f3",
"8856473a8abaeaefe3caef16f9028477e7e7567495c34f39c5994b1b45c560ec",
"e16751cceafe54c2f6ceceec7fbf91d1b3bb1bc07e3a797c648e3f9b7a42514a",
"46648c7215af23e77caa74e979c3b94dfca9ad2f37b5ea8690613a72eace2ab0",
"0623da3cf8bf7ae5c5d4cd1612b3ef1d710cb8c9cd52c31cb788a42ddeba05c4",
"574cbd5389d73637c5bf107cef3572dbd0a9073868565a94a82ce208ba79f0cb",
"0a291eeb8223faf29d449d737b9f1f8160ebdca5ee2a0ef0151ac0034454905d",
"28390c1fbf77fd774233957d1e899b323ddb220183d3ba967d47f9852ff8eb83",
"3f6bd32a3fa90606f774c19bf83d3f0afb8e62b6a9ec444e1fe9be323119f1bd",
"44bb7e1132d0b7ebb640261c38d5221adc2dc5d62c5c9b1a73e31a7eb463fad4",
"d07885f9aa93bd424770a1e2a86c541d8444a63f0125fd3c8ccd1c9b6eaa471c",
"58306e37f7f7858494982b11df599fcb528e81dc1b4eb0b510e107552e54b747",
"b2c391ec3f870fc8061d19c5b07ac6f52fe3a34d1d07c5f6ad05f92d5cac1a7e",
"31a4f6046aaa050ddfb7dc5b8684c1794674d889f3b3d7e52ac036a944afa350",
"fb87ba317297e04f101dab2f4e1559d74f5ce55644d9c2aceb423728cc71ce85",
"89dbdfbca2ee0633280c077be5b78c0b3db5208f3e3ba25c83219c487735df36",
"019b8d42a336b3f3c389418a3974d6312fd71ce793f4fd49bdb8bcf22f7a70f1",
"92989aff4daef8bf33b0d8e33659c61733ce62bf02b292d650db280849b86363",
"4ca8687384f9f08f8095baf48049cabd993b6a4ccfbe883c6d611b83e9fa99e1",
"af537d402d1e09e8d491d9bfa66eb570533437398cc4bdd292b749bba96bf23e",
"81192954e5751c31dc9494f73844c081f1e7e260333b9451ae735d824d34860f",
"52c1b147b63edf49341ee43c783b5f7155ca7f1db8d61f4ace853cc93b152754",
"763ab14adaa265969cb067f5693ec0812711674f194e73d0ef8d0f790f381a8d",
"33cbca1286611bc5fd91aceb5ee6cbf1796b55844cc78a913be452c3e2225083",
"78b31b3ee54ecad929e43cfaf85e0e0002f389a0288895832a0d208578bacb9a",
"0933d1e6aa5fa0d6d9d47734ee3ff9e5cd347cf949501d707273d47eb610cc4c",
"43588f703009120eba72199813cc9626d1cf91a5298186c6d0571a9d37f98feb",
"4f7fccb3eacba37712c3cad68e0e20d370efadc1323aa99262f829868c92497c",
"903acfe5505693aba7729a5b3a9dcf255a70c3c993553b6f9a564b8191afaea4",
"7a67f14e7d04bafa027e20d35e44ddeca47f563cdcff325a2a5ec58ff75b7600",
"126fca804da3fe87938e68163ff61ac1f5a7b5f2a5e1ffd83ff420d45360de7f",
"ae53b91c36971a90760d79200687ec2ce86fb1365a5ae9fbba5611b025a5fd58",
"16e29d80008cbb4d39e62fa880c1369b33a6a0f8b778c73cd043d8fab4b3b18e",
"f83f89218d38dc3743999297267d7a95354d97d1744b41006e41c2621c80392c",
"a4d434bde6fff7cb6d70682931ca90ae22733efb893918dc05a2081b479dcf24",
"a7f29c9a397f048b4aefb050e3e327878366c48594050f820168742cb752fdc2",
"250932d781d2bd8af1cac72f1b4feef4ce1ade548645c8461c2b9a62e1495a16",
"42a1ef981d3f9afefb950b9ace91b643ce81b5047ce4abccb15c6293f1f0dffe",
"8e0bf176de179bcbcb527a9836209b6e23bad71cb2414a87f6603070a475aa67",
"30ff14085d03e94e13a20ace0f192955829ea3a6150b201128d2eba10ad5d840",
"6b98b88af9a468c1f8562b7ad66eac49b26d9c17541f78a51917410e59539875",
"f7be155c1b03eaed34f9c588a449341e2ec9ec8b956a920f76f4c1b5f22dcd6b",
"bd5f1e9fbcb6c21f92e8b0d1fb9b65aff01f8f4a0675f12e72e7442697164fe4",
"54097131968df8b081379163f8d21eb645dbf60d82408727b7ae508443c35411",
"6336115a4ee287471165aa96ea1cda6110bfcb89fcc74d1828c030c42d727d21",
"f0cf5a199836fd3c15e4caf7cfc33a975bfe07e89bc93b364a6ddca64aa5cf64",
"af5d27f8b2b5e534e356926dbf9ffce02e4ecc16bbd04b7cebfaf82b5588e9b7",
"b719fdad8b62d8eea98d7b0d817c250fc9c7975c3107dad5229713d4d9b411f9",
"c289605aefbb686a00b36df80c4b6697cdc28e4528f05cde1f6e10930e12cac2",
"e34492b355a4c7f4aea9c4f8c79478eb1f44b92a7c8b81172d39abf3f82153e9",
"a849fc76de231aee07c059ca7a8d5d9fde9236eb66e86cec3b5fb1d24bc4da27",
"bed186f386e192d3faf20e4d9f8c208236f5d0d4811090406f23ffd6a90be05c",
"d54e1bad29fdd36cd9decdd496a42617c0ca08c151b8cf698f2efb5e401c4761",
"bf426888e50bdc5ed45ac83326ff1aa982fbbb02bffb18933639e4131e71a5e2",
"13e2197be21100e7e61f554438be02ac4217620f2c8b8610215a04c0659dc73f",
"5df463b7782021628b3d5374734eb491a09afeaac84132d6b2a0fa630a917628",
"af67a912936920719c726b6f2d481baf3e07259e0332be33d234c29ff4fe436b",
"dfabfb5810adfcaf5f20c9f4816aedacc97db5fc61d83f56364f7d6f35e0c780",
"8d536e5b0472bf3fc139e2ed54cbe5cd18633eef25ade036d347b1b13c630ffb",
"468336e054be9d5415339677c11da469c4ea7f575cf3fc7a931e0064bfd14f0f",
"9b654dd7829efddbecc5d3ddcbdb5157e92cc7f1fa92e5bac3e2576dceda76f0",
"f5f3d13ce9ac5cd57c2ef5c92c38cd5a2aa64a89c2a076d604b26a5b839f5c13",
"a22388e1569cab9c4fef88ed5559b7fb1a626202b2c11fe14bdebb05bcbb1fc9",
"55a2c5ad143c1f395629af5af0d11af884663bb86559b82ccf95efb7a8736570",
"ad2f7f6e03f34a1291b959f729df452efb22929929eb3df2ea778f8a7a06d02d",
"e4fb0e5aa219622a8aafa4fe97ae542558b40dfccd51818fa9bebae2f954bce0",
"5d146f771e524cce59aff8fa0e9e4620df1ddd4f1d3e764ad361f46d113ea1de",
"288988bca47363e0fa4dfd4767b64b90c107cf5218f795e11f2f65dc3cd6d15c",
"0d36093f4f6bd51513e7c6f777d35cdbd9b360dcd1af4dbd5a8f96e687e9f9ec",
"c5413305e5be6c98971cac88cb428284640d1e7ce3907db80443a083539d7740",
"4e7ffb0df9b2ca8c3c1a57998aa4879bea196d99df0ef718f29b3351969f28a4",
"e46c6adcb9b5a205b9caf7b6c04e675a2fac48ae9f71e9b41a0cfa76ff882e03",
"28f5f869913e9b16ac30b283452ab712fa3bca1033331aa39c487a226f6b8a67",
"dcc77f311e041d367918b6b97372006ace9e1c0f605aaa253f42e0b7ab7b6482",
"a8128d9560a1ecfcee387287560c261b48ffdd92f118976d044b0f9662cca9be",
"342bbfa50e772e5a4563e6552ae508506c93f529d16eefca5919bc1a0364d218",
"2ccffc06b368a2645ba20107d86486951e0eb6cc9e87647f1fd6606d913ac385",
"7e3efe895e3d243bc8b2957eb1f1d18e7a22265079691cf62278c263ee89116f",
"8241430a7b14f06e661d308884d9483baf40a988459ce932722ba0a2de4a8a60",
"377b9af88d0279532208f32750dcaa945b98087b6573c0a9dc28d8e3d8ea8c20",
"6fc4bd3cd66de41ff8927d76c2d573a9e86dded60810dd8cebdca69db1cde165",
"e4e0ff5eac8ea4c0548b36fab2b8d374f2af9837d81fd43fd1c3091786b26212",
"d8dc87e02ff8abf8e0659cf988f343208189a83bf15c66c7fff0ee116da9e7c9",
"a1049d597f8376b325e843be3955d785523f9104e54cf8aa42d1025513fd06dd",
"56ff181dd30ffcc1f5e156b65d37a59d7fcc56efdbd5ce78b4f88d9b294a8102",
"fb1d80e14b39cf77f5d7e8e1e4bb8cdfdefc3770b6477c23e9a03e646930fa72",
"217a71695f0ae3fbb8aa31ce91a1d769d8bf46b34f8ef818a118b32eb1d6a7ec",
"daa21f503e59149ddd49f13e88ae220ca892eb8671a1f36382c710bb6bc30b97",
"574a18da22b64b4f8509e943c0a5fec2476f1cc98bbc7394648ff8e12b14b957",
"181db322c746345268ab14263212303b434b771f27ca3e4a479c983a1b19a35a",
"6278b4289feaec2167fb0002fe7c1ffc609aa6a2efc6d788c6efa42ff5299a6b",
"0f1ae140cc8c96ad1d09144753421bfe2becf17ed22e7c50d1474d93591b027f",
"f084d37740480a093cbc3172ebf3690e6b5d125d97f6b3137ed551df7b307a4c",
"30cdab80e04c8f537fb7151e2821ca71b6595bfb0923232ba4e55f493e4a4e4c",
"30bca488e65c9896dd137d2f9d534df4c2cb695cdb825e91e14e98f0d5827cd7",
"66002a3cbed0b591d2f45db0977bf9a7c30d2d170ca8a07ed9ad3b0d77f75390",
"ec4bb111a8fd440b0c13e258a26b3d1bd3e087494d4797d416dd545b01c82713",
"b6f498a3ba0b1fcbda6eeac26327cb50eaa25cfd9a6679475b7b72899b4ce50f",
"2f36c28efdb7a0cd7be2192e2092dd4256023a0a26bd6c59bbf3684c540c07dd",
"dbb80f3440108df58fa73a0623fa7d8d79a52fbe07df125fdeff23a81ea44485",
"197f491e9fc7937a33ad4186e2389654c9ab9793c5083afaa69462a09e08ca6c",
"caa7f8ba2f5af9e1e0b4f462240d333521deb054777a495364f1fff1684f58f5",
"cd4ad910be17d36697d72d2de73b6b9b9fc6028497f248e92863a25a99277391",
"383ecf812438beb450ef5cff05735b928c24213a93a9cf133d08de364552a010",
"7b1ee612684b89cdc65982eed55c241aab377543f5543663e8d8d6e593cdb47b",
"c9b99febc47d480aead844c0055a67c54b1bd2e3167294bf291ae63277d72c09",
"6ac9cc7d8b2b7bef5c9869c95ec7333808d1aad981848826a925d228ee0d04b3",
"b4f4becbb6b643831136348be14350bbd72a44611182d0bee1901b58ff542051",
"f052b62d0b7b7ac67823261937652c9f50654dcf66f6acf06b4d860d56fad8f0",
"03ce3cac31be4945cebf91a625d69bdd0458a6bca4d4eb77a368ab5fceba5fbc",
"84912c2ed7686c2ddca15bdaa3076874d6079f1324e7e7142bf112a4af799f0c",
"1bd1dc01b5d3ef39f4c2d73633e159fe16a4c444ac89e597d407c088969166af",
"7755956fc6717c83925cfd0da4c1f32b0dc50a3d532d40c5eb044777b2792404",
"b2a8dac1cf2748f9b6d0db097883626dbcbc98d1ad519ea5f1285f54e5a4162b",
"0dcf501b52d00219ef728c0ab2862ea1cb09dcac6bd377435a6674f803e9d406",
"e8dc9262281cdc2173d3959cf377a5555110e077d170d00ed5f7d76410b5fb97",
"3391c9848263cd5c2673b0730b1248bb99d23c62bddb450e655e419a9d14b2e8",
"cbc6a81679634f2b8dc56a1368dcabdcf888073aa72d0ffdb03debdc5c96fb15",
"152ac4f1ffe6d7e9f587e75113c8eb6e99c7b5bd313d946e0f6f1dff8cdcf8ff",
"3d144010f765dd8b62fe93d7c1b62d91560afed1eaf0355efbdc95ac0d4f57ac",
"669e18c9c9e1e5d32e00c6b1f4bad121beccd6c93f1ac119f07ff7e4c2f5f0e3",
"ac1cf4d32b4cd54f957684c1bfeb2d4656b667d93b8c38895421dd172399a9d4",
"79a09cc8aa62c393c507e95861270f26a2691034b03abc3ad3490752ac0fd388",
"04981735078826341cbab0c514d30f4986291436d66f993703ff5f10c2689553",
"c950f55c784f910a31a0b42678868e2a85aaa3cd85d1534e0b7b38e7d67b78c3",
"a073796f08720d11bcb355ee57bf4ccd1ddb58eaeb078d615922519a2e0c39ee",
"3b9f8c688c1c9c72507248c0dcd53f229a9e100612009e7457506ec2618953b0",
"282d32f973d2074059521f48a687bca702f6553deafd1f385b9ca104b7193cae",
"20dabb5b0a19a1b16d9a23508823058804d0dae23e62ec28d15abf1e46f914b9"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_1801_2000 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"96944f13a3e376c23a9b8838a4f88605cabda8da81b9726fac6620dc3c410d6d",
"4ea0a2896b04378f425e6a4a01c6dd70efca5fe2662791b8e8b31160dd245037",
"4067e5404322feeabc388c4bc2cb56ce3e3b372dd9bb212d51fe5db537944f75",
"0ab78c19c7752e4b81f215611ed6e7273ca7ba5282ff4580c22bcc4911bb752e",
"7b03eb388aa284899248b9af8cc3e8b092fa1286a29b874e4eefa12ac1a33749",
"d2e7e735e74f3caa1761ae4241a3a75df513e14a91cc04fc8b9579df3a57d9ed",
"702c00a4809be55b65272f7c92e240cd14e92892f17a3ab3c792cd3e2b295a25",
"36616359c5a185349f490f43aae8acf97189fc911a1e17301eca9961d2ca2da2",
"59c6c75007307ae09d3f9b88619b69365e319be76fc8346e8593694c5261dcc6",
"0a5fbb474ff81d605bcae0dcf4619f1e59ff84ee0043966d416f4aa40965a079",
"5cb41664eda424bb7f64507ad56bfa868f8abe1aa8927a4c85fc9c5c18f2f296",
"8bf8dec171dc6ce2f1c20ada222ead7d510429e830cbb183413914af6f5a1582",
"571fcfca9bfcffbe760e204dc537092f0d00a84b5ad136546cc236e19a0b3be8",
"c441f57fdbca032df26a2edb326f7997720fe1047fb8aea04731ccc0b6bb199a",
"4cbe14f9f4d265a224f2eb8aaa2defe2a991e0b522059f1d26fc328941f3ced8",
"18bf1a2e91befedb4b2bb1de3e9a279e590f5e6ead9c0f1496d9f7ac37bcbad0",
"e41430e3ed50c96bed605f0351eaa0737186cd68bd2a4c8e2cecfac7ba6975b5",
"215e79c7f69d6d46cce2f431aef333b6fb35829bdd99157b18a70575bd11f9b9",
"b0af856650525f309a890564c85811b8a2a189b0e7ea14c62b79d47765a51891",
"4de1f238124bc7bae8d9248f5dbf3f5c018e6db2921a3736e8a62eaa93148c71",
"842a1260f154cc7fb71da440dd51abfb1e7f1a4c123145cb371e61b6dec14dca",
"ec59c0ae598f2c58d078a12fc20eb577a10235592266363e989f2cf691661616",
"421bea0fd13867847caedc224b507cf32010fac81c420d590f7ed0eac5de7f50",
"93c98123458e27b39469977e9e31ec02cdedbd965cdbdc25c100abb9e813cb67",
"afd06d425eee7bfced848d19bb0dbd44a342349c91c0f34cf1978d4d2fd6f99d",
"4a22e72fb12aa0c2ca058c93cd2fd979c75dabe2cb51f85292ff4be32be0a041",
"f780896b2297de1cb25cb8021985140427ece379ad480e4bc6000487e7f33d64",
"e2d02cec07886ee3a69602e8eb70b4257c586cd717c12a0ec112b60bcf4b132a",
"fd22dfd1c936d0c33f2030e32147769e53e3d47c24c584f01bc2ccbcc8214599",
"f12afe5299640e26647a94afb66824d1196cb8e827d1bb36d661a8d09e5a5a8b",
"592cc5f5dc3db783758f52e79115ed9d88f7c6b4e326297702fabd27d6d031d0",
"0f9d27c463a9fb1c8f95615b7ff161dd2ae3a3717ea859baa544b947251ef6ac",
"e7ed7a6b967698dffe84025220f82e509898407bf2af4f84370f939a10575ce5",
"de0412f45a1011c7a2e39cc0392cf34088b4a4404bc20ae6c86fc56a64426f88",
"b60df9860fd84efe64b5c0a08feeaf131869db808f0d59443968a25e95e61094",
"dfe93405ee0364ab7148a09dab4a2c0a7a12d3d0edf26e9a1e1995a1a5cd222a",
"08bb0ac8f661b945c455f0e6ac05bc8284947099e6b19c9ebe3306c317f22325",
"d3ad617e3b3ab4284254ad09ff6d7ea54a360875ad5d23511b2855fcf94abd2c",
"4db15f70cbd6f0c759ad96d3ea40596ba0b5cc281723ff47825cc3839119e680",
"a23bd487652a7477082319e0abc44050ac941da5586cff5368059508aa40eaf7",
"7ff6f4bd8661318ed37cac6b42240b919be341d3ad5359e8644eb1c59747f06b",
"7817eaf014a852fcd9fc603460b3ba1c06cbdd0b9b9fbe61f24558707a90c3a9",
"e04952be9c301b411a52d3b1c122b9b8c0c6331aa796fc03f10afb4941cc6048",
"b5478f54a741d73496ac39dad22fe29fecec5e2dc484b36a711c29be02fd9119",
"fec95a009704afe0ee86b0db725d0e99204367fc88adddc35fc122a9a7a1fe6f",
"f5f2ef1f3ba45d6fcf84facf1544bac893988a7dd12c7117640088dc4f4635e9",
"d5895765c74f26aae79128be434df7ed08941477e5ab8a9d2e2bf5739ece33a8",
"a85b7b19cdc9c7718544152eb27959e1ac8230cc2764ab6193b83ad12f4c110e",
"c7a7fc1bd0ab1609d4f3e21d93c28f5e0a0d56df49dccede377c82c91e14b711",
"953dfb3d08b0344d0b9912eb1520ca19504acf696703ecc3d0a1db26a69ecb27",
"6d80e0d2ecc0ba61f74bbf51064aff90a9e9bf67264a81f141f494f2e34d9753",
"272c410e9e5a3107f3444ed5c91c902c8f34f292bff137461097c86545595681",
"f51a71a228fd0eda13465b98d0b6eeb69760632c56b00889500382f5820ea3aa",
"5fc6a0bb34eafe4e282a207cb9d8f7c2482addc9195017377d1563170f8eecf6",
"2527a32ce236d096b3776412fb41948e438150a8c8587482ee2703a7fc2f0e16",
"08ed13e7ba130f205b924416c9a49e22b433b7e60e4ba5a8631a02cf2953cb7d",
"40254d61c138601a129cea839b7678b7efec74710c3fe0431e1a3338a16e86b7",
"00e6689112f230da01a4f7ec5bf6ce0c96dc3aa4ffc1d7eb3c620aaccce7da81",
"3492dfd94dbf4fa71976a1dd8dcad1569c4d41b916759377d4151815beeee3d0",
"d079a95b79bc6ce87948464bd56099a1bec0238ed08dbab8da2f5f1674c45c3b",
"c754f3c4469e38d8483315f676c7b4fad3c0aa9e5fc960d33fb0f6fa7126d1cc",
"8fa5ded9275041de61e53e1929ab704ce5cec4602a353b8dea754324f7379e60",
"9d3915e288eb2e5969d8fdcd2e7c5dc2d2caa21cbf8420d1dc177a96078af2eb",
"3b979ac96a90be70fc6bcdd71bbc4d020aa0206d96b863e55dad1fd503913e5b",
"648f6e6f915ac2bffaa7d61de186ebefa8bb962ee2a1d4ec7c4500f1363550fe",
"4f3f214a1b98ab5fb7545ccd43f4dd9ab5c33a469bd66e9791a64571dffef41a",
"766239d887acfadee78f02f47253a831dc50844d2e8f3d635bd1ffecdc83e398",
"eafa7d52e0c9314d8f8c67a85d61a6a89d8a7820d99635dfb10c383d0b9aeab6",
"608ce8645b9af5f006773a7e946773ab19e64e9d8241cde098ff449a8bf86bef",
"e995db2d086668e75da44ca80eaef1178df9ef84975b537a55cb2abb0b2acc9f",
"2334865cfeb19695e266cfb205632cc362a3128419d51febf864dc58a0fc26e5",
"272558d0f5bbb75ddcc4d322ef98b86326ec167a006cc3d23fdb5347f42f6347",
"dc3a5cdbe4eaafa522030176a751bce51f3cad167c64253cef44f34512cc3ca5",
"244cb4a4191670811e03cb61aa7c1f5371a50ebb220aade4d8cd2f5ab4f1dca0",
"e4506c53b58256d751b0932f848e92fb3a0c5ede1280fe66076896da16010e09",
"a5af71afc79df281fd3429aa8e79f76520dcf34e967910535f39dbc7b2aefc61",
"680428fddd7214a9eb1097f45dc613476268a359e63647015c43515392ce7e04",
"a0757e8622b454c44b6f50f4a004bae32ba1d1464eab74e487326367f5ec2c83",
"9c69c848dc72728f66e1167b70c36645f29c3ef6ab18991e4024ee18b6c521bb",
"be2dbf94a1882602158015983ba40ceb7450e09ac624151e2d3d368ecf6e77c9",
"9487f04ca7395cdf3bef555b538d2b3ba5858e283857a565aa50ef711722ebe5",
"7b3ad6f3fb2ed686fed9a10fa20d48a2c3885102ecc3d6bd37278fefa6fa2435",
"edd63deaf4f22415a496c4f3e4bc7af50fbfc817c7d5c7bd415bfbc36791c302",
"e978ba4835d35b4181a92b5107f04ed58d0058df9cc0117f0211c979d973094f",
"ea949595ffe7ce2389fa6bc3d9f75041c22740e65306e13f68b68acd2e1dcc74",
"f5c413ac59ec2d41a81b06d589af79fbe63750c17c215ce982067f366a563922",
"236437e7e1c5dc3c15b40596bea7f64924cf9d89f1f2f13a56a8741a5c1c11b6",
"11df94c1d31f73559609d77270003027e344150482ec55c225e6106cacc74d29",
"398fdb2a8b110495788645411d54fac35e7a266d6a3bdfaf4ae2d91ea83a7b4e",
"fa7c5be91c4b08ba19a5daccf492eca78e24a494c59c04708a42da144e4500fc",
"080001b427e52df0ac505fa67f7ccf357992a6f3b6c5245de411e05268964c45",
"b6a551057d751a1cb407ad803317e62a3f40a765261ba4862ca68b8849418f17",
"2a116fa37a0448e256d25bfed7e1a6eb2ea278cebacd9cb07662c63c85716fde",
"d4b9f1d8aa9ee9bdfc406119a236d1938f2436b5eaae680b0555c9ad4c73618e",
"548dd9adafd606ad27524cd0d0f5016d91f8e8c8cbc826dcc5d747a15f2cf786",
"7b3ed71c050f4eb2caf23ea59660d7857b54cf8ca13f1a13d656373ef47843c3",
"8f04f142a54e5666022910ee192a0c76c1aac9271081310f976f0238d64296fd",
"a93c172352dc201bf6742d63fc02a5fd8428bd0c2ce0bc6b6fae2ca045879ae5",
"2fe7233e21e10e7bbb724d4636b2dc2b06afc07984d4575ffa794ba0606bec54",
"b25dc0cea9627ab44899492b4489cf03cc0a38001e939c6f100dad2fd8abe1db",
"2c848f45d9139efceabd1dea336da7e582fece1279528f52bd460c490987f87a",
"ee2d35804ca15f9f44d459272352a048e6c402498b4ca64ee16b530f591ee56e",
"2f6dd04ef9f981f9257690861e445ed3bb9546b28b0cd71c36724c3b3f322d67",
"7642dcbe12996841b0002c2d89d7936759a6cf628731d52c7889f885f608b8d4",
"cac82d5dcb1d28e8efabccdb3eeace340b40da0b8fd2d774ffc6c2ae7867e0bd",
"d2ea9f4988fbf92b66aa22606a75447333ccc60dc26dbaaae7fb5be6e08b52d7",
"316432faa4351906073293ee8366017cf542b304fbe24bf381b6286f3b72a368",
"2331020666a47bc457197426b19072f147f88c018cb4649d48d48cd73be7aba0",
"4790b1828b1cccd06920928ec35927c632620a4692319646e26f30a8bd6cec86",
"7d7e084415e44203f1b95d3ecb25ffc0314693aaab845d57ccd3227f98a32e1b",
"0c78a7cddf088fee666212d75f8c21a345edd05455db7259ed64d7193afb0b91",
"c4705ac8531b7ac5eb0343e82e8ecf42a0ff05b34ebb7d9993b9feece0f9b2ea",
"9a1c58b7d999db071e1cde37c7ed023a1dc2057888606bf0156875da6db2fe2f",
"4577463ec340e81f794147db906b9e88831ea9daaea0ecdf595eca5cf89b2a98",
"98864924390209d23ce6af3df54e52a63ffc07291b38d6fe29981a3299651d27",
"e6c4aa345d522e759e96a321007f6ef791adf55f3f06513d7ba5d9147429a09a",
"27b6db973e2d77cc2ab96827ff72fb1cf5de6536d2619aec21e0355ee170c0c0",
"eadc32d2b97b50c195db706c74130dd170085d3ec3bfed2cbc7695605b237a07",
"bd3e0b62581d4fae5d1925c12c947e34370759a99f3f17e1ef6bbd4de41b3b4d",
"ff1e9bc5f789c276838601f16295916da337f6d8ff8cdffefafca2f79021be73",
"9a9cd594f87e70fb14204d960e65463e02b93fc4831d3ca344f93247e44a33e8",
"13d69439ff644231f78cbfb501ca09e69b4d5d4600ed17d84da24f3ef698c906",
"1f83bd20b8d69016b8ed296ab298e861e5ce7224f4f4f0e46ae544a3a1424e3f",
"cdf483942d2f60592ad20129219cfd667e78bbb33c462f8296615fbf3e7a3edf",
"5d545d70916431290d74d5a506862b9b142fd13d0846ee63dc76bd8f1be9e1e3",
"7419a434c86dd051098d786258346503721385a5d7c4b49ed58f4fbbc412458e",
"2df6a700042cdb0fbe27b3a47e21aa812472ef8c8a393fcf64c39c6b9184dd70",
"3ed706fb666fe1ca38d6bae5709fb392bf248d6dec6e43fb898088527fc21b2a",
"131c4b2682b014cfddc28b137f4ff367b9fb0511dbb7727657f67fbf791221b2",
"e00c7bd790adcaf63f7c8b5d4e1fd03082ceeddacf1e3d32a0c463043dfd1f40",
"4f863052518e2d80b9d352ec5e6c3a65f07ee324bbec56715fe8033ec18f510d",
"70f09ef9d6b8ca4f08c8254df93b7b342e252dfcf44dc2789c7610e0bcbc90fb",
"77de74df370a5cc3dce25853ed88daef127b89b24da6fd1db1040e70434c6ff1",
"ba27b788a16334a81bb09e8606021283c5a4ab6461483a575c348abcd12a36bd",
"39ad0c5a7c343689c42b5cb398fe9adeac73095eac822115875fe8166201b421",
"622a8190c1d6e64c7635bbf1e053e006321298f1ac90ca66f4624dc4cf9ee31b",
"4e593bcae552f35fb436e72ce34768b6416113c56f9dae748cb282e3f211a5e3",
"e768f19d7a5d845e557b7c798c8a740c2bf40ef163a53f2d84d983f129b90b48",
"233503fbcd512e30413e5bbd7c6ef93d07ef0b9dab20c98d34495c1737fb6113",
"d8f9642cfe7106cc9270639a9e1397376060c0601c401b6a06202c0d0448bb61",
"7f2950a458b7042bddba1b58af483981e87e14d3ff144cff2a4c4f59d9728bd9",
"5a731d07d4aecb17e5b119c4075b45e2efed6bb10a84d75402963bcc758dc9f0",
"52639e0a5a3c72d043b99e95c561205cfa7e79e6c9a0927101b08406207b0261",
"acd7021eff68279eba9788c165d3bebee95815cf50338a25a2215ae2ab32e001",
"1d359e8b6360bea7e3cf6b2e165d109ec786c58c208890869c466f90e3f73a41",
"776c0b4166b15fa3899b75280b1da7d6ae7576d4319617ee6af16a5ac2178e18",
"469b8ae8860f76f0a8dba9ce9401ba1d54cfbdf1581f1d7e1805019e16c3b19b",
"3b58ed0d458897c3b6b8a50bacf8afc99381c9e2270673a048d0e5e1850d7de2",
"23c1cc212362a627e316af1e7d6a0f7b0926d2a454d214e688d966b770646e68",
"e2a0138f3614514f1385dd9747cc6bc2a249461836c6ecd444e4c945651d15f3",
"6bc0a0a2376aa40f7da4a4138f914fd8a14f8028dc3912c43060f339668e6368",
"6138eb0bdc31513380125f0018a38b9bab90528f8dd686898526ffad639ce5ac",
"e0559266764d7ac93d1c1041d03e0b593d1fbb1441783d42d72ea793843ff4a5",
"582fadcfdb39514bbd22580a5c225ee841730da5a9b930e891e38081b6d998e2",
"87cd0eca9ec32eb5553498baeafa4d7f6fc8d591223fd1ad9a76706014538eba",
"ad40262ed31c28703031166afc96de4b4a718e081c35569d3d390e01be0064cd",
"af05e7d21731c69b00459dbe2169accd444878dc85b9b7e316faf99248ee8567",
"afb2c6b2389ff316d567205e3b5cc8e7f55d419c4406ddb9f5c185bca83cf7d6",
"ecc59380b7dd5772ce76f68b490f128b5077810802017b56ca1120f0b6f97f99",
"ee7c7d490212d05f0901b5ecffe84fa6778e8f64eb8f9033867885eb4f8473a4",
"602a52101785263e842b458cc1a40af79f10467cc49581a2809f1d6a08c76cbc",
"8e8d7d8dddf92b5bc30daf36764ef8304a26c415a6da4ef76f15dbdff2d70fd5",
"2c16d2e3b58db9ea345c6c75d7b3b0c4c26988f20bcc68e2682901576f19b668",
"af44ff88cdd0dcc4c194cffa6204bf98fbed38fd19859e27ab6c7b03a1d65062",
"8facf14a8f88fb08e600305092ffa03dddfe83bad49b7d4a02382bdc78390df0",
"ac9a46d22ef7ac1826b35271f4be28209f6fdde61c74669aa780a7f12a2c3d8c",
"870c5670626e07df84f5bf5504072b1eac54b9cac4d6cb1030eaadaa2101ef4c",
"f7656c0fa72bc48cf53d74de01da1b7fa2b315b999d97334ee433a025cd37e10",
"4637f6047bdd54b9cbda0aa26fde2854894cd7bcf333f65a431d5e7b751da18f",
"133ce894acdb41d8ef92cbc56e69150c43f197487556e8e90ad75b3d17b5c12a",
"84f8061438335f4d4da7bbc10895588a573869c4fee0f32789b0eabf100fff66",
"e33bd8b462baf4e0a4b7454e48b0b3fd09105b26b7b5a27fbe48175e68e19f5f",
"b5419eeb17c1c28a2cf7467f745776e3e6be707e4377753882f3dc937180f7e6",
"fa800d09f6c984f1ff48d1ed1ef74a20f5868954fba275b626e06a707b84a377",
"af2aa5c539bf0351eb3a4efb787db42ec30fec6c9080f86fd965f0c37de7cb4f",
"bbab2ac10b7c2facc4e0eaf2f755a379e345c51b8dc28e5de949ea3b0b505e6c",
"b5033bca647dbac0ace2b494948d7d49f0e51082456c7e5a055a8cc88d2048f4",
"b3069fa57ec7821a49e05b6f638150bdbbd0706273fe5977e8792d83ef0ba28a",
"c211da629be7a0fd33a57e487a3cb328b95c4b7717f19452d1f7c675fcb8eb6f",
"adce24c68a7a4c0a646dc329e4a0c9aef66e045be7065c1b40ae42bee704d907",
"f475584d71f905ec8df6877edf2c2dce814b88f3c273daec2c1720d7a31a09fd",
"12121e4b5756700fccc7549f1cc230eaecfa409a6bb39dca38c71b3c8b3c1a66",
"0b2caa92c6c06fbfc666bd9acd7dd6aad31dd1c8c33b00347486d9a1a65152d0",
"76fb023b4c9c03f879a46a783cce9a4da554e5fb18dc3fc818a3b28d3d00633c",
"1a04db8271634aa3af47d9350fb550cd5761c151a6943bf286e1bb945a9d2f9e",
"90f424885635ec035c2b03f9515a1623a6f40f27ac60d1027ed9119de652d844",
"eac63d3fe7da5aef1fc80fc8b59c237fe0bbb8658d484c37989d1f21ac3e1b51",
"0971dc3220fbbd116d358fed4be323bcf772b20d1a08b70c74294fbbe45cc64b",
"b89f12d43021a206abade93c336fe4076aaf3aa0843f25e95c946284854e3a90",
"3dbccbc315dae190b23a11efb38f29d042b4a3a143e90f7e57d04829c7b72b99",
"ec4fe1e823a3a5a43432e6f6b5eb48384fa94e6df7ff29a57fcf3170769db8a4",
"f140b7f41c94842597103c7e894c05ab9768bb6dff2a1f3e3be01f2876d84774",
"eb6c375910d514cde69163b5931fe7f901403199b666ccbc7f7a39172bc8fcd9",
"011df61ca36a4bd26b108dcd5031b4c73c0c4b5009497020a437890eb564a15c",
"8bd76525da45e17a000429aee4dbbfda50ae426dfc78223b488528b66857f609",
"daf3b9e8d1900456bcf805bfd1c24bd89c1ec9640aab0eb4cc8e5375ce69f7fb",
"cafd936d4323f0d9af035dd70f96950575a7e651df7ce580ceb5446be79a78e6",
"fbf5f1a0d2a2bfb0460c18cd9ac2aa1f81f6bd1b7c9691e71f7279e49a66a59a",
"733335bec9a011a19467ffe42eefec74cb292df4908ba75a45fd5c3d90c20c20",
"ff58b8aed22cc4a08280f353ec19ab740c6064a63a359d45183edc220175e115"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_2001_2200 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"9f922b2df4280d47d1096e50ac3b807f67fba346b4ed1949267c46ad1ade1cef",
"42005d89ca8b61a5dcd857d62ecc135b854e924fe70c8dcea5f6957dc2a93d58",
"87289b82e0a0a20c8c69c4f951704b67a8e4679faf18363ece7fbb62ae62e49f",
"601407750093fc450e5856834e2d0bd3b01a3cebf20476984fa8ed82d636ceb5",
"5b5c9395fbdee55a3973bb1b2947650ab9d436ebc0238b0481528e4f003df9e2",
"836f68e5995197567491f726cdbc95478ece339fc2a1bc005efade00a2a85ad0",
"c9ca1412da5a170baf4872a76cc1bdd74024ad8ed10deacf1c05dae2a2923738",
"e3e3d0548303e437af6c0811ac06c6306ef7fb30a651bd5d699996d94326cf8d",
"c03e4dfde65a98519387d8ade5858b9b8ddd34f68f857409a922af120d5dc245",
"933f1467dec5cfb2c08dbced911b5db1616bd28e48cb276111f5a1eba5f34567",
"d44346f6784a2d000e3df40051b7ac405c63326929d9889b3173001d47fe2a8d",
"4f13f8afff58fd130540cd775d066b257d40d2538d80cadc82da3148e08da66b",
"2568488ae33fe2c3ed5808e473407598d111cc7753c1c22725bb07df2490fa0c",
"f13178a6c4fdf29c52dd0dc65f502b21aa93211cbf58a4cc91ae2396f7d5d8a0",
"2447e0c966b12141a300f213dcef7c2f34ecd5691572cb57b9fa05983e2e2a93",
"50fcaad9a42e4cc540a8643ac599c9a2c6f40a47599718fd8ae4a54f33068ceb",
"796dcf46c8e835d4f4b9982cb674d59e712df5d637cdffc7dcbd0f64ac2347f0",
"49e05891942df4bc5738a5606026ab9985bb21de5129b7e5a70d684f6274b720",
"fe5c735ee24c3b0d17c22ee4620d2d86e98c70e985119ad5b68fd8934cff65fd",
"2ef29ce2308a27c4cd674c37a1ed6ba5152dda342fbca27ea826dcc1823ca1f5",
"988c4ffbf9f509e9d6ef5af70a37998ec0274a1e903222198a7628ab9930d5ea",
"3a0d5aa84c8c0746adf69d04d27e096c857b551dd6b0d38204f5da66fb4c68dd",
"d0398d6fb439f01b0d34081a61d49d3593b903516db7d23bef574b03a490d07c",
"29cdf9149009b03955a3e6d265a22552c46834b6023dde591a45177cffc7e841",
"92ab4f75ee3c2e82e9865f024ee9fda9d4231cd12f98385c701ca92cd0174b05",
"81c8c833ceb40f6d65b68e21ff64bb45a978260457d9cc88503c3bf63633e465",
"03c8cb5f6f0b784ca55ecc762be99e29dc2405ee20a6597a124393df0a357220",
"12b6b37546dac371412e6ca2a7032d8b8b84f4b8d156b34ebcf3717b0d1407a7",
"6a3a9d1a8590e47a79b5d50133e66a46286de331650db7b1d7c970401076f821",
"f838bc427ce4747f5a7ca361f156adb7e7ad7c1332a2fb6a987ec7971a7f89e4",
"9d37e1fb84f0c4c193010e90e0527abcb4c98254df7050446384f0167be2ef2c",
"d2f8bd755aa018a5083de4a8a178997eeb2548929d28356057169fde556cd189",
"d7a9091f3b0afc104301aef5d9379957979ad1e201ba96d85d3ed3fc78a5ea92",
"d5117430ca306d34111f58dbed1dc7ed969618238979225af1d98c2fa63d3de5",
"5394e09313e8963b2849e21b4a8cb48469792047c21dd31fcd02238393d61070",
"9fd08f549f70858bae89c75b3ae73c33bf639574552e2ba190484dd1876c066a",
"102e6c769d020f3406fff228797912775c93e63c5cf2f89b4e4b8a8ac2f62640",
"77efb461fc03030ee7297918cbe31749a33e9e0b7278b82b10faff6fd7ab20e2",
"c839b29501a0da1e76dece425d5f1b4cd22b2e4e30ceceaf4d5f6050ee4f61ab",
"d774619e090e280332038db9a61a50d0ae4fb344d61f75bffb4a57e9ff3dd7d4",
"292d140bebe36182f35fbe5877f397f303149e6307b22c15b24554c57fdf87f6",
"758b5fa7588b942085fb695d5beab5523c72fb9f9d417a6d217b3884ca8dd9d3",
"895ea3a89bb4422d485bc148327ba2748a7bd97e642e7e2af56ccf262e70e950",
"e66932d0a562049b4f1bd0935968a830e323f9445b25f2a40de797aae1256c3a",
"f10baf4d700a266cd9509375a21eb45008e0a986b95c7a7a682cc71cc9d7ace0",
"9dbcada9dacebbfc4f6e97ad7e63b1a98a192412b8f5bd161ace63c553fcda5e",
"808ee0f09662c059e143679618f4d4091510215ab573755e7ab3a75aa9eddc93",
"1f76c9000450510d0765df42227c16f93fc9bc7a7a5036581ed1b5502628f31c",
"e1202c0f1ed61529fdf0b37e460621876603884c1255a868bdeceed55f553d0f",
"2478ece507b1d262da847b54153c852c2610bca0cad818306e42d26254f81625",
"7e6e0b501ebc38d1a8fe3273ff0bf42f77d2d3e757522c9a6cac335c71c55814",
"4ac6a90ed338508b73e906afa8138d08dc13779fc0ad1e1755dc77d12e8e401a",
"1cffae1d2bc4865f8be4cf87ca35736bae971d5c16701073222b24b145fe006b",
"73295753fc6c9ac6a19fbea9536b61702f788e3f76366e81a39dbbc1b7ebac66",
"e041a7a57a8765efec2a6545dfeffa3bc4a311bba05d097f34f6ef3fc26edec6",
"c75f8544b268ad94b9643268eb479cd94b770637e9b73075174a8a4dc629e00e",
"857b87e840979b5d891d4aec3f96c38ae202d075e53c6d1a0138c6a7e7f197c4",
"9176a907bc841a036435729584cba6ed8fd636a84a2a27aab79d252f44738738",
"0e6bff6470fad82d47650bc1f2878e89e141378613dca007d6bd4d33299171ab",
"0e0b045d8e60af74c8200534a33ffc737f8fd0470b0666b78580001494967a1d",
"ebb88af5523806d142e8b455c9769bc29d2a38f32212575d4897eafad6e08e35",
"3c924c5a3338157b0a30fd7d1f4af6f0bc5049bf3d718925000c1facb29d6499",
"3e2395200b6b7887548841b5fdead824a6e42864db7b44898306067478b8957c",
"059abd3657a4ea1f81d45d512a9627e992e73d790d6bfea556b4e350610ff4b0",
"cd0cc44957a0d1d81fea37f95618e829b68cba4fe7a1b9495725579746891ff4",
"598e366854e6eb33c852e9e924354d513a7576c99c31d37a7ee04cafeb7a7280",
"7bf46ac0e5ba10234c13bceacddcb6df25a837302bd588ad8f52600a8a88bc54",
"63748fe195d2f111afd2421fa5209b480e2489be5276cda7c1c087d9bc8600c2",
"006a6af87b77157f69d2c3d3a290a4a74c732c526992d73c8cdb0c392441a95f",
"dba6a9a6ae797bf0e3b3ed6a2bfe00b0aff25a92ece8c64cbf62787c38a7a8dc",
"ad660cce6cc5e7ad6b9c91f7bcf6248291c6a1398e7c2554b505744a33bf9a9f",
"308832dad86a285db81b9dd72b686829ee39e81120f9f3e01e87b6326b0cfbf1",
"caa12bf573c94c302188f161a80fb90586e58310674a762703db579afbb5fc2b",
"c6156a3fc1aeedced4c340ffadc84f4eb4e5f7be6fe00d4b99f56434483d777a",
"c87dbae12a52c960135e943f168969b5f329b447ded4b0b0646f593ac30346a8",
"66e609d39c5223bc3a56347bfd496fb4e105042dbbde7629b8e516f6695b853c",
"44d33b25419f72a3c04229c5aa24b83aaa09ba0b2f3c8cb5cfccb33db3444018",
"28919a859a5990d7d1592180acecb6b6952ac57851d7b80a46c68b47259a7636",
"dfaae2f4dd49c291e298a96e6b2ba1daf7260f400755ec77c7cf099058d03702",
"3fa2cd994e9e0e073c261f8013b2b0371991b0d41cb27f57094e58e951a05610",
"28b8ed76c03be6a230388a80ae189f7e0adb1d07fa89bf71a6035557e2b97a2c",
"48c24f591e1d02f8dac950eba0f3298cef80a2eff7fa2e972e241c53f97c6552",
"3dc2081934fc1266c221bc5efb8e1b76c5f30e9ad6592fc5ee1f90bc5f22d499",
"aad98c602cc43c1a6c062ad133ef6f176c4d5fd3896671c40f9bec4706e7d498",
"7ab59f83f8c16a6aae505b978d50767fe25babfae83572c7e3d16d0bf9eb7197",
"148e3ba60e5fc52077c26bcd351dcd00aa44451a1cbdc11c8246632345c6a038",
"50d680bd8a5f31851f591f973d6b84e86ed3e4fbf43704d2815315e9582b35c8",
"2ca588a12afea18d67c2cc0093f21c48b9f78c6aa019ea4411cb7fdac80818a4",
"c6a6007f359c97f67f6e0037916cb4794da135835c7220ae0c172608d141af1e",
"ec496891c6228467724e909434f24c57369ce41b8dea1a33ecd9f1b7d6e28858",
"c4959ca865813f0ed41808059d72a77cb109fbfa628fa95913b959472f078a9e",
"b9ec594fab556dc41e9113e9b057dc57c2e2e14026602096f77652fc22a868eb",
"8ce45f5c18fa53f8a62ec22c9e2083a63e1fa6f5c02eedccb2e9cf8b0f11243b",
"4a18a9a158cdcd4741c614299c4c5b7cc584095d262b5a8e2c548f80fee360d0",
"0b82161d227273b26808e36b3b145dba719fd2e6bacdda3bd70544d08356fe1b",
"4d6038faf93889590fade0d1f6e8d75a4e97059f5caa8ca94a8453aec2bbf852",
"cdf11a8d2ab61ca1b55c7b4d9a73234b2f71b4293747a1c51467bd11c0434f8f",
"a9c03834d3750cd1d336fe20c5f99032d4df6bf3d3d91f743f23912cd3ade76d",
"b582262ab27bf497239e698ff0d2f9b5195b23bae3eb1bec5de29c4e969533de",
"5fe4072798e45bf3bb86ccf2af3cb90e3a00ee5f9dc3830deeed39b6a13ad705",
"5a2cd78c1349f25a8083d33bdc29a87bf2a4780e3050d6766c6e9bb167e48e73",
"c891eedb023f652f52a0cb0766993e16fb5cca65c2af424da49dae1d28fdc740",
"11ea43db8fdba9a49a9e0b43c6bf8a2e97bfa38885cf2de50ca1c3259846c77f",
"a823704b87cad4c1b82b8d2016953a934d83de50ca992422f51de467ef5f3437",
"c142265861fff050fed9df49879a40cf9f7abfa514ba40540203450c104980eb",
"b26d790cb4409d9d3202b4bc6c541e03ffb70549bc9c938579365fb21e1d0b9f",
"df87a423bd1e9894424f9ff93aa366cfca504a41d76f102627afdebf5c5a4c37",
"bfb5ac76e6fc99406d44ca9bdb308b345f8eb99d65ec615f281b1b19b3b049ee",
"4582d74bf5c8b5050bab150a68ef2e5166da60fc9988b2f1fa069e9b80043d48",
"d4e861dd70ce4dff2e3d2ac79a557b6a70eeec296f795c7efbb6a9723b21e4ae",
"1882b460e53a316d5e9ce0e9033d5f28327cec14f2366f77545c6320d731ad4f",
"01df638286c95724519d6591579b219f6a2614caa1dc61aaf073a471c79c62ae",
"c31b5ff9b5be540a5f3c45bc06d9664c4fe47bb597984b1f15ab1dd67f08d2f4",
"d9a34dd7f220031c8c5edc9cf188d695490b9848c7cc787aad24396ddbee40c8",
"73ef72d08f457cff3c6b24bb93037d42444eb410c1c944309b15f52f42ca40f7",
"a75b28eaed721035ff6111a532610dfcd7242a792b38a28e6c3bc90abdcf0ffd",
"dbc8ab4b7a59444fdf243829299a451a89f09f3e5d7a9cd65b456d8b5dfe0a36",
"2c988614d44777a227fe4ebcafade3f22bf61a34c90ea791b8403061c0c9da27",
"ea2c239fa51bbf92021f5888dde43d3ca50e889f10a76b833d6c65b612a30afe",
"c330bac682abee7c29a34ac70f6ba573898ecffd7371a43acdc15ebc807e79f4",
"47662bceccdc4b138b073d145f91243f593bd1f2d3753c8833e161048e743ec7",
"14b875864751cb0f0fbe6845440bd3c385b58b9a600935a133a62926d7b77e2a",
"d3e4fe42185a95d01230d4045cbb0b39f0662a5845321a5e74167ef7679fc00e",
"99ed103feadb498de0c809e3a8286c6bd0cc04b3cc892a04f5e63685688566ad",
"48bcac6a0d7e96993f39a2f7b475103b4539422b5913a110cff0074602ee748b",
"6ab9c13cd0a52fda98e3d850c7c0deafb6aec5a1ef93a1705686a9094ef4ebc6",
"ce23c7c36e616e9731150d7db57685a0afcc44fd6ed7a58fc3eeec42ba59a058",
"91c18ebd21028e7a78055a330a1d1ad5ee6f86fcbdb25e7479095152350063dd",
"2cf50a5e58cede394db804b0232bf07fe89ee2982a9c5375e522e8f1f7ae1fa0",
"31f9af2a640bf5b5a0b98c0f67f322807da90fa974bf55d86f9ab25399ffd2be",
"80a33cc79be51ac1909808a4abfa7d300d6a92c53ace7bf7272e33136ef51583",
"74eceb8363350a1b6fdf0f044a905eeeb47ed43c46bc1407aed8720846c3c9f4",
"65daddf9768cfd7c42bcc6847a088f732ce8272059448c5d1c81f7d35c734585",
"ba46d9ca5c51901307782d158a4126bc8b501ad455b57e7d779682e023ace08a",
"3a355120d6a8281555eb12bcd852ceed7d4dbd98fde2c195258f5bac8be5615d",
"c242f3e4679fe5b5bc00486c388227d99bdcf19749ae538485243c0a3a8cae53",
"205f1521f3d6c2222f6421563e7161f4e9a9febe1dbdf4714d1981c39e4bdfd2",
"6faf9d93ca1dfcbb9b7b7d2048263a5a1d7ad6b08fd125010b6bedeb5fb0124e",
"8c36399345c804e4adabe73a6c7c2a75da61d256e071b9e91b64c21d4244ab53",
"d058303858d92750573808a97d0418fb86e9da9fff8df33da129df3d3673216f",
"a34c8885a2297bfc4b731b1928b7538dc822c50b5242c80f0df1d0ca4227c124",
"8340c5a408970aa371f6c8972a3da74d4ddea98bf008bb84d5421a3242dcb09c",
"66e47f9789790c28e363e4daf4a538848b85c9d8e308d5f8927b6018ef37504b",
"bd4eeaac8edb402beb9793536f5a5abe1a40866de9aa138e0a345ee57b572c8e",
"62fae6042ecd3dbc3303f3f0a1359700f972aee93157f22880bc1d8972f76759",
"0dc113e804e003a928fdeacdded30231e7d974559004d6a42e55f26dc8fc2314",
"4c341a6407632f3adb813874a985ac625a453e6c1d76e2c29516cab278153ce9",
"ecbd638ea4bca621010b86e0ad9a50afdf5be58e4032c695a7c8b747847b2105",
"189a63828ba65a16a063c897028a176ea0c345cd8f4c3ff27fdb6d5da1fb4274",
"d7f17bec54ad56e5943f2de06b482aa3b7239d71474bd4fb981d2b73d8dfbaf3",
"d79c897d6d225629106acb340ff08e3de010aeef23fce6eec18ff95a3fcf1e6a",
"d5c3b5fc1b3b102abe47891f3d3b14fdec8c5004e3204324e2477bd88d840157",
"f3efa11842e4a61a2ae79f2bfbc0e493cbb0bbffb14daccbd3efe5641eb92fbd",
"e42fe49a23547173b9ab2153cfbda12429b19606ff560d975bb1a5820acc3327",
"a1da08010928177a0f75050fb9fcdc43da4abfe271223738d849df59e74e9afa",
"e1bbd328ac39fdbca97490de37d26bb7a1c936cf6626001cb2590a34ea4c32be",
"3a79afdb042ffbf9c85629a5fe0b8a112e3adc7e189c974c22bc829a312a04da",
"1c1b0c29efa283c6e7510bad13e5411634d23d030ab66852406002daf0cb5885",
"dc75fb57979314a00a719ad573c88d49aef0d4d20dfd192c0451d053fd14270f",
"ed8d069f2f53e47b14e578ae0bf46630f0060b94e372f7b955e8228449b9d3a1",
"b4fb4485e312ad8f56d546a820b1d7645f695397473e6bc7a0e28bc9186302a3",
"3a4b490d3a4f92e68000d7f3394a00d5383b2ffbf471093d85ece47c399208b5",
"fe13fadda6834874fbd7fab9059e32e0cf42d2ab6546f272f5f886d7554d2f07",
"498b475ef8c1a8ce5b9ed3bd599db402980f0a8a1b0e7791fa0d2d83b137fb45",
"d59eb5bbee708aa585524b8474ea653927359eaf681c6f42ff71e589e22f7ad4",
"e2528e5cac3e99e5f8ff1f1cff642c04b113daf4b0a791f5aa03e14123eba4aa",
"bcde95b45e7815a93945b7ada394f8e6429b7afcaa6ddbd347988f92e379432f",
"8f3d407e5bd16e4cb251bf417cddc52ac72b5ab9181f48803b5288aa90fea834",
"63e6c88cd587a850f9c8b0c436202f04d3c27af949deaee67703d7d8b0309f54",
"16a8a52265125ace07be9e5b1384c1784347d7738f47c16e64308c1db97556ad",
"cc91d39252bf38cbec05d5cdfd8dcebc25322963a1782209efd0d1a28fdb3f87",
"2c25301c1f69fa78de937b455c70dd8f62c452c6cc17e2c555eb0f81f42b5d9d",
"d938091ab1ec6b8b4dcc3921b08ec95ec5864aa199881d0828e543e290bd9207",
"a22d7f1114699ea25123f61cd48d41c41224090312ac8d89d1865aed9dea8734",
"04da0d65cc48beee02099c94de049c74720f983319e557d9b5d98251e066dc4b",
"b204febc1b76b1541b3f938766d2dc818dade688ac987c09c00b0d36e88d0cef",
"cb70e3942fd5b7b9a1819b764cdcab47441678e1fd2c1fe19b1cc3441bdeaca8",
"c32d1f2ec86c4e398d0162f07b8592de95b903f0f2ea81455c1453468923fbe0",
"0a2329ed686117da20998f4393cb83f48115d7e7c223f4901a854db41d8da120",
"a48847d99365bc8821a0c8f5a5b90c57645b678608c3fa4c9932d677949688b1",
"13f28e9ea6e6d9878f9fc484954ef1303d37916d987ed290965916171804a4b8",
"8263f13144f24d8205763ba4d894e3afe2ceebf3f6e0e144942d791e295be8d5",
"d2409b5d15c4910fd4164be2aabc3160ea50f42c3c69943178691b1147bf1a4f",
"d3959f3e0c2c11e64326b990dc6195b90a8e7fbcb0574f93225db26ee8c0a1b6",
"b3d44c65171b5a7405f2c5896b23c03d834ad27ca2e5a4bfe45b5a462e1688b3",
"032dd5812fe64cbc63252a009b8e8d342789f4d8145ae0990eb96152003d0e68",
"8eaf3948197e718d6e3bf6b8ea34129e6045acc61df904cb7ceba8d1617992fb",
"987cba8c4967ac09b1cd728478edb0829b68b3429ee70218f0736b432ac8a77b",
"e47b0827b26a8a6f261a1b41d978570207611b1382b50add3ce3aa818e808c49",
"8b649cb58610be826f3d8ac9f32103946a9237e3b323062b4c1eb5ce4ed3afab",
"44ff1ee0df5fab60de172f84b9929f90fdfbda833c935c44642d1ab0d2513165",
"d5ed40f80fa062062c0df5af9347465e4ce9a6c8b3411991ef8b3ac9c5f015c3",
"ff5696ba76e830314504b483e463ff8da2617ff490f95c834c1e7c1a3fe1d359",
"c2892f8df813ae7208796a249c0bfbb917034750d3fca27edb45f83f98dc6b3d",
"be0725fedd884aa4ea33e06786398ee0771c3453d36fd0f49f3a1023c2ee629e",
"cfe1cf7a17aba32076c5d87edef0227ba91e2ac925c816d36ddde1b036cfd8cf",
"32d72b2e77fcbc0cc6ea75f6b3b2fc9881229c332fb883f4a3916236f0d217cb",
"a89abd08aef7f377edf9e6e17bd5d41b1080fb9ee36ee2b681f9d8666a0c6503",
"70243030e6be29d0891aa165fbdbe8b519815a1da704786b6a32ad0e0c9bed7b",
"7e3818bd6404e7b26c4be10d77c50b67717826086182d34d680cf1030cd2414b"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_2201_2400 {    
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[200] memory _originalCollection = [
"2dbdc744a32608c31ecc80ced21f7eb1daa1fc97049a00b18d8220f4b55cfcdb",
"89234d02492f58896d624b5cab534ef2909674c0d8d54d12ff3fa65e64b8a378",
"9a58279e7261dd753435d225ef3079ba864599045b0033d71873329de9de7672",
"f8f734bafaa3d8ae9d6ad900bbeed45e3afeee5a29d4d6a143e798a4222993ae",
"c26d527697b2c75f3d449836948af57c01e65b0c8707330294dfb31f825bc209",
"9203e9f865106399e2ca3e7d1e1262d0b9ca1a0b39f2539d854e801896339d0c",
"3e5008f01a33c9fdcbd726a5026b868221fc1764bba135237392f87f8dcee59c",
"e9c20add4ccc3e731015fc654d56531ba62127d37f2dec58d32c2c4b78574a12",
"105f8a0d46d8a66fb5a5839de69b52dfab4814f77bdf9704b743178fc996ab27",
"3a658fdaab9ad5eef5a60cb21831ff2f21e392272bfad571a31193cc85f2ab84",
"bac65d43d6b3a4dc3fb9841def21b28c6c25c54babac12129ee3f0bfbbada4e8",
"977f0aa3254217b4f6a2e1d91f86e4603f57e222517607f73acf1603d105dc38",
"e2612234f3d9a85e281fdd728387ddd82c1293bf70b5b93853c15e6c415283a6",
"c20927d4abf3a900dd28e8948c44f0d1172116f586fa2e2c15c764f14b7f7d65",
"18dc25962381387f87c56fe5cac572767bac8716c3b71c916f3a7eec0041bd39",
"5062c352f701f78f7cc8d959dcc201e7549730491271eb369b7d7bde2c25a99d",
"242a2666b03c90bacbb6fbc0d538d42c55cd6964396be3e6fb53b665190a162a",
"239d11863bf5556e10be8a60cb2c2a6ca633c136a506b704278758de9ed7a8a1",
"31d5d64730289faa85405c1d1d653b007908a02b2c5ceef3f06d009115837215",
"00c143bd4b8f756b5c335c27eac6763a6553ee77c1248756452d44f1589f93a4",
"d3fd911e97562d31e3459af503c5ab1253e1081ad8147f11db965ab2a5510643",
"f243d4466a628f49aa8c0f98e4ddcd864321f4ad74d6514deac8434abb9b868f",
"472c6d308d77d34ec517a653c2dbcc13d3f820244bb74eb2974d401445c31fe4",
"641d39c0acfdd1483c218165c8e7852625fa395523fc473a9130f40a7e21ac65",
"5f0e380c70d844560e8303c3f35e34641c235d6c35de4c6693b98f555c1f786c",
"5cefaeca50595f6a35b7680b0fda2760d5bbf192193740c627e86985f5f74646",
"4c8b4b7b0ffc9ccae1ae671dfbdbcb2e153533729bfee36fd4c522672fbe9f43",
"7384e597b5a67b3674a074407a651a1fb8093385012dce16ed1ddda64d3b25c9",
"19b6e3ed4d02ec6df2e07a5bdc9ef9e89e8ea52d2476b00f0a83c2bdc047c80e",
"41524f3ef39e88563d0d11a9467f717e735e60f8af3e36c1573d27bc19b10bd9",
"14873e5f2b980e89141bcab8d3e747bd564fd8ea4156048aad1bd6fe971fe53b",
"6974131fdde05a8441f2a8dad96d1d174bab6dc06a6643495089f6838c9de456",
"a6ccbb36ba1afa8d43105ad582496518b837849657e4e33f7c48332ba3aab4e1",
"5697e7cf4de713f59df237a87e1b8f29feda812b7cb13d96a38d96118ae019c9",
"4e16217aa333434054c0694a402e3cc8ffe1e0a5b589a9c8e9cc9eafe080a029",
"ee1670fb211eff33e8b97e862ebc1ba2fcee61b00bf33d99ac2c3004e210ed0a",
"84d311c6d4767c3ffb84178355e3abbc2eccf7c083ba130aca0aa08b62595ce6",
"1e7e656c17e363a2818d162ad5fa662c7f806b03fdb7ac99dd9bc5472fd22463",
"8eccb709c51ee76a04434921d5cbde12142f95ca81b0f504350b1ad5f354ecad",
"476350bd3b5e81a4b28ee81c9f0a6790d5c22937fc40ab07afba33127875001a",
"2f34bf7e3b881b9ffe4f7bcf47bc96d8c2bc5d61b23817d3e623354003ecbb8a",
"b73cef5f770da07254b0481ff188c10bf567aac5f516b3f8c49dbc4088075761",
"6e949eeaee679e0c5b5e0008c33e8c57d9cd8103e43556e24d878561b6b0ca36",
"3e3abfc13f3f4bb038d97e1d7474dc5eafe772267dd782382d20bc0cbe4415cc",
"c0f3ce7a91940fa76af27655f69900f2e6adb42c370124e1e5d636c880480bee",
"a1c703b401022937e6671b753454dda6c29570decb540a90efffa3d7a94e2c16",
"e7e4cfe19980831003a023eba82a4d68ccfec1e6cdda3a343cbce50c8bd5f55e",
"e560ebe9ebfa92d0dfa6196cfc4c5165a8b4cf1a9768ed25094bdb833d180b5b",
"4c827f95ba98c22f5d3c8d18eed065331df59ac634eadf27c4ed5476d4c17c70",
"0e2e649d7a6d31094c4144c41820b46b4e4dad2bc260e1f37c6f447ea5015892",
"755fe0db5baecb6b21edba3fffc80691f287ece27367b92b23703b7b818bb141",
"25990a47ce80fb86b3af86c9e0a63de3eb8e1203a2d1a7c0c6762069b34db4ac",
"a860adfd530ef42dbde9d6cb192862385d29d247d407388782e26b49a2648f2c",
"3f9c59c493fba37a9acef856c97f3c3ac75edb701faf646604c316813063a18d",
"3dfc1f3dcc832fbd1e185df2e64f0309c10113b0bfff0cf715a700863a8134d4",
"60c1b948122354e9c5774a6933eae1272e29f4ce9f0e1fa8ab5d31c73d59c301",
"542f2fb168ef0597304a6fddd2e1078fa0379d3b85e3e10fe4f9d424e3737c14",
"a3f4298ad0b2e0c5f380600c4aea042fb1917b590a5992de37636dd2132db769",
"c45efc7889a814f2e453ef54dfcdef0d26fa7e9e6a8af60d24cf34f1b562898a",
"608ddd99a6b7e3836736b66b2107db7862e8f289420680649f137d4fd470f3d7",
"232911c7c274d0ead0b089e97ceb8f9c5cf9b8bf2c1b7944fe57c5391afd9ffb",
"0c2850c355b86520f0a248dc6e62cb2396028aa1de0b5cb22f5487c8bf7f6734",
"35b93b00a15feef33d33d9aa2bb8de576c9bc1850be7e4b4182e08fdc7cece41",
"548f2413db9c2c7b2d01e4814643f069388c9fa5b1bd1f6336d80b39aecbd86d",
"4942978a0118da0303da78829bd1d0c5b1f56934add74df3e2e9639196f6da53",
"9328bb89084cf8acbd7842a1e709f29cd2c83b813c1bf51bbfe26e26021c6087",
"b59eb0bca078eaa1acb05671f6b4378742b9d029510ec34d61c4e7eb26388cd3",
"14ca04ca589f69488a8326a80992df33d78ee60ca687ee35624248086f95d227",
"6f734e85833bec0495622758509c235d0838a0ec904d1303c52ec0f3d63bdb6b",
"e53cb499bc9782e1eca7e1771755afbdc248826a3899fd3842d305c6c61385d5",
"075d309777cb347c8578c0ffc5be7d9c7d76796f967c0ff2ad60244c4bcbce90",
"d62144894e1dcb61f2aaeec40094478b9c798448452e6393ace375ebc6e324a1",
"5f26ba7f5a03c58774edaa973a59c8db26f3c6e8ad72df2efad529a94164940f",
"a9167cda2a967848569bd7cc499e888f7d4af188d281d694e70c75d6b924ffde",
"a0b608da64d444a5342b30db0e62d653ba9fa954fe1b78fb272fcd12b7551451",
"e39dd2cdba90377f48379b930f16b5afee556d046db26c0eee298419649f3ce5",
"4c2f5debc9e1d59979036c22169cb52e54209ac71728f2b031a2dc0127ea77da",
"3b347f6d42d9f9192bfcf357179c90c6f852897918e3c563cf0e1996a29dd81a",
"c8f31befcb1caa23e87293336a4a89a07cf5409b0715e49b781fc92fbd293093",
"5e525b8105e47caff955e496adaa216d4f2f5e71a5052d8e33943bc0832c7cb6",
"abc3352b681bf3eeaf8e8ddd33ab324f6f2260c4978329eedeca0a60e47c5c8f",
"3fe6a239cb58be006f0ad49730c5975e21fe8c9ec0e73ee03ca590df796a2776",
"0c900e3fef831c76e61f3f8910e5018c2f3e806bebacb4bae5a82afd03b4cd15",
"e215f688019750b590fef73b11a20a1eba19db0042d8d641af60e0d4f0b30d55",
"07ceb09b6b60505c753f48682dac8f9f6c0955ef4d3429b690cfd8b3a532f1db",
"82a6b0aca6f9974901757dfb9a617798a12e5c1efef09f4d6e7013b7992717e7",
"cd98fd6cc9c63d13f615a32bd6206dea80012fffaba5ed4c6adbd15ed566e0ff",
"694483bea6f25c2d10212c9be4feeb5c3a5eabe08ae72e71b6572daf63cb524c",
"47496e0814a5a48bb35c0aaf0b14388b29e99bb8982f565df1cf490327a529fd",
"ca6cc45090ab32e3963fc212b45649dab87b90dab62e0ea5d8b058c14e6dc3e4",
"6e6e738cd638a07b117fc67a7db7ffcab1d410a548e7c73be7ca4a898b116add",
"fe7694f0ff77ea085e26210973404a9f8741c7e8133252b9571fa5e6a45d01b7",
"32e4beee452e17ad460b44a4f707851c339c05001dc97628c7183f273f5d896b",
"dd5b0d0cc08ff42dc67313a5896970f8b2d533712ba3dc66c13e94b1d09c2bd3",
"8812b856bbb7459ee0e9f15a10e5945d3f3466721e498f0d878735e30c11bc51",
"36472bd8f450b9b205d1b25f1046c9d594a3d4124b6094b1f845789702486f11",
"91dbacb0f96aca0505febd4f6a5786bfe13a381d47b5118ef7514bfb9a59141c",
"71919067a2907fdae522cf5e2ed423a347b04b8669d20c2236202aa25646382d",
"c5a08f6e1c6edce6c8fde3010be4af11012e6a8b58130c6a6ad32f319734b5a1",
"baf3a93269926e8e3723989d7e4a7310c1310a5d621aa7a04b9cb647622d48dd",
"028c0b7448d802eb21abe12a97fd874c8628900ea9824bdd59f73d61be8eb80a",
"372a9926de2c98625daf652213d4331406dbcdc84beb4aa6f1ec2a4b1ce3ca01",
"9a011d813d861831b57cd85153d48cfa03884dffb19a382b82f6bbce0b192105",
"82c59fde49cc5e302e1d4a7beeb1d77ed58029c14ab2032e50eee34a382ce573",
"a9a0912f1a534a539c0a8a1476bdda1a5f9eb54b44d011b3355ff0f36193dada",
"1dbcc53d2a8009e44a6735075384acd136026b664a990a5ef98cd6db1b03aa4e",
"6ae10e25575db1cb52ece9cf3a1222f0b60b4a1ca153393c452a62295b0ff767",
"bb3a268f1d1dc7fec7e1b7c69dc5dd4aa78ec09fcb408b4efd097e8cfbe3044d",
"9b7ac5bb6107e0e47b77cd16c05be4901fdfc65cd4a2be552326a608e4dbcc8a",
"6062b79ed163e3cca9a4e6a5204f19b1d750c1300c4f4d6f70a6ccd766981f6e",
"b2eb198c5a6171dff4de38368c649e56f3a8eeae93e604661b64c16178c51a4c",
"73ecfceecf008a56b135db873da662e0f92123d2026ee41001dd2f8f00de73b0",
"8c321fbb0463ecfe58e50813bd6fb7e02830e116ae69edea0a4dafe7c997054f",
"c203b76709360fddcf89658c9ca2e064ba2b0d00d966511fb2e3209b664ec7bf",
"5eaedfb3f934b8c1439c3850f9978ff85fd0219bef4c2d9ce34fcc19ec943d89",
"09d5a2a882ebc6033c23e90d82608ffa3d74a58fd0446b612a98f6d52585760f",
"09c38316a873b2e350e25a74fec2472f74448ad3c4ef5715e4d6bf74c521f53e",
"22e73e091ff87722cf501ef5ad309ffdda0eeb29af778ab20cc8c083d3f539de",
"fde5d91396534f4a6ae91bc197f43d91533f4d76515bbbeac11d761ff1bbb984",
"83fa818f49d0c5c0fca2c33556ea587dc50ecc813ac1fbddb4f87af0edbbfb30",
"ae2c1a81ed74397029d4484d6878ac63436d5126c43b62656b763a5079980379",
"9aa2ed9eddb4d740c5297d8f0497a82051923292225c1ced077213186e6db0c1",
"a3badcfb4aba0b46727fc0ac90f619a6624c87c2833c48adac6a026fc5cc889b",
"daffb409cf94847ca7583038dd0b41a0d2ba716281756c80b547bb6f7634f7ff",
"8775c72109ce6c351ae25479157385e1b0ec953d39da099d4859f8ee0c7dfe9c",
"b7ac03e443dded94c81bab08068a5ff3b604a7b8e95d7a72083fd26d28435bbf",
"f9e56c7359d95977e35b76379cb7ade097ce2a01befa9f5f9caf180803b8d53a",
"1fb6e37999a437216b951b623aff256407103c36e6bad8eff27476208c8197b7",
"247047dd7a9f987edb9a896c0cc132933e0d3288068e68e5c3c3b8ac3b8d6d54",
"a8a31035df9389cfb37bd8f058d66ef60582a37af9190315453a113ffa4bc080",
"e26050574eea6c2ba804efbb5fe4b642e9454a10d8189d6148b60509d4803705",
"0eaee9c28d0c3c31be37169d232160f487a9429422c2fe031e932f8aaaf34473",
"39689d0322c1bf120df94838812fb864b0d9d0ef7f30014351fac07df1de8148",
"ac478460ea9e5477d4eb79aa86aa1759494ef3c1e87c52a9bb34f068e6190294",
"3b90f9fca60343b6f7d22a49a42047f229e683812cfdeebf657465ba89746d36",
"3e4ed627d783200acfbb5ab2e594a8a0b1d244055d48f7dce35fd6fa93f48f6b",
"34687dec9d715c20f32258e36795c92bbae6c59a95d406810f6ca1e06f16ed8d",
"6478dc331294ead3f3ecdd8066f11755f9e96a3d001086b96fa650996c0189c9",
"dcb765596d6cfd897c9aaccf23cf8e9f96659db99ba52e3dd83d0dbda1401e50",
"bfe1fc12e51b9366b32bf14dbb40df06bcfc0732050e87d2f582ca825061a3eb",
"8baded7e337dfa7eca5b9f5609976113b01a374c765ebb297ec809ca254429af",
"02594343f6c52282c65863fd08fec8ac35173cf5491f8263dbd4aecad03c00e6",
"754cdc2bde340d0a72c537f3045a30e6f105716d0e989ad48eb87c5a75e5e9e0",
"fa8896d05ad2a545c11982704c31a0ffe6e5a6c0ef271f9d5df186c08debdeef",
"af3243511df82d70a20860b76394ff5a6effd9200a431ad595b9745e42bd2a14",
"51831f99d0b82702f99f4b6bcb163b7537e78e13de2c91654fa0c13011148fdc",
"c8bb98341147c3a4da9f28ef96b997bd602670ec9c2f7988472a5376c2abe093",
"8c3ca979a1576e456c9bf79f8f0adc39ce57ec91bce735b8f2f5c28d2981d30b",
"9610845fc2a467839b0a11e3fa9fdc76c899dd713f415aa56d4794271b269dfe",
"13a77b33e9f0dd84fb9fe9c60b51620fc5aab5e0571c488f3312e94aa49a6457",
"3cb99a911c55b5180f0899280be3e88ece5a58e7ba387a251accfc5c9b92abe6",
"772db600dda7e5c14fbe72644a6787451c5344b9b70bac992c7e1d64f9f48049",
"8d9701c806f0cea4f9489f6357bc2acd7bf5e989fd87b7fecdba855038e559bf",
"fe666649890bdeba080b0edc466080221bf8c17af810e63eb2560f5481060873",
"56655d3ce40102bc1554ead9fd822257b512b1711d3fc68d8b0b739e01701208",
"308f31ae00668eb1583e42d3cb9458468850ea2849175f97fec89698429442d3",
"32bd028ec25f59e2dcb94b1296d92253a67bb801c0f32f7cc629ecdc68f08894",
"7344be7a5d029fc299f942fadd825d93c2ac52da293d1e9839954e2bb0386d6c",
"ff77cffa228a3bef7d22a5b060ecf6248562c8aa7ad082880bf05a137540a7d0",
"606b77613ed6e77331862716650d1e9d480c630ec1c2c352ee0829b9473293dd",
"f54e931ddf23899fd97fc78913f3a290127c4003166b6a529d5b8ed1f6fc8eb4",
"88f9dfa204fc0cb4dd82fce15bd80dfb8bc8dd48810e2701dfe78eaf3473f32a",
"26b04f69fbd89746dd4b7f95b42cbbaff593b831d745898565585f30916df467",
"1d8f2bf6891b216d68cfc85b8dec07bdc19749aa39cf18885fc51db90058fdf6",
"069471e009eefd19c8b80c823801ac2e1edbb7dd382491098e3501078a436efb",
"d90afd4f7c201d7071bbe2182365750021bf15e92f5d310693f6dcb4e095f261",
"2af7ab6b92b0e431653422786d289db29f203d43c47404c9bdf35882d0b6eb07",
"31e73e16d39bba7b517665a49621ce115cdeb0270465a8029f92931a6e3a0fd7",
"029b42e175978a1df6ff1f75976bacef8cd30b248118c2f24f28d357f3740dc6",
"b2bf368ccb371690e31a5362cc716e8d8d7f8e466b61efabbfe22e6a3131a71f",
"8a03c652b7d343d0608c2a8d59d7f275493d1a7f344adb4d1e1af965f6a8d788",
"3a9b2129f132afd8294d4e799f4cbd5543862e2abeaf23e0506d09c0ccb81295",
"929bffba12ec263e106a01446494fd437027ff9d3e0c7b90d5d780615ac5ea43",
"bae8478afa9b7f79664a12fbfd9cc74e7f5c6611b8e0591e28c4ed359991c7fb",
"2132cd49073c2e8d7a92647f216bdf43d720983593da7443f58e695921a86b8d",
"8d1376855b87870162fadff9c43e32500b92e3a23c6936bdc31c50cd16813b6d",
"c721530bafbe8e0727da1d43e95923602a0a6d0388747feb4d94f2c5e70193c7",
"aa927e262b2bf8af764c3bc2405aee915dd1925a46d386109f0f4bd044f24322",
"7e751d0b012b20526a8abd1d5cd8fbbc09e223ad218173470dc60b6cddcb2179",
"e758e847728b080075541626385caf92b6c013226be79d019ca1127bfe738770",
"e000b8d04769c6aa14512417aaa434bc8d0d02a64a01b660e7320861bd87421a",
"b97e35dee4565914905ac64bc843700a4654b2671eb57c82c9d77b755df24dac",
"71f69d83d254ab53e3284b62205b08619be047b6fd73ee4cb4f3433df125db74",
"7fdcd4c892b2b2b93d3068e82d0d050f7e8673085cc28748fc7764f05996422a",
"ef57c9ad3a7a95a7d3aeb7b956c8ac4dd6047ab711872027b23a9074843df767",
"7a0627ffcacbf0cee2768cc2d6db13391e2cbd84ac6b9769f86b23b314328c02",
"713e264981c00bb281d5cf4bc8f3519f7d0b966b095882017e99ba364be7179b",
"1eabd20f1e7c8bf56efd28e5fe5f6a1cbbc1b312067e6b52467b1641ea627ff4",
"72873c46038ce34c094ff53983620780add638413c61b35c4f797a9ea0f71c52",
"5caf2d3b507094d4cae29da70c0484968ddda62db5c15a31a176960bce8c41a3",
"10d1cf596707de2932cf5152b723c399ad2f613d40f4cbc2493507c618f7f7f2",
"dc3f501cd661470fbd4906adbcf150ea0e8db7811221abf2534f9445d5dcfc8d",
"1086f48d0a73d625b5214fcbe641ca3c859b61a5e22395c8459eae13470c3da5",
"6e46297ee4f44018006334a6a16f0f1240a58554e6186184f9c362d82e7c579b",
"5ec6873318440f335a94337ec85727a6595d1ad047659ba7750f28d629cc7168",
"185f90a47137c8c4df4581e42406f8d21d9bf0621c910f92d59b4b5d7dc3a584",
"98f996de87b32d8665c126fe1e29b94c8bc91ae83f3683d27dc726054d32e96a",
"709f4686e0d7e74e6acd940df7e969739f9d93936d71e5a73d03b3cc71edafcf",
"245961d0208efce24bd290477fe4f44f6b6917e7d87da3fa81a7cbdefdf0ed91",
"607b8a1022c2ea2d18840bafa8364ee21041321ac920436c2a19de56e0fd5605"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}

library SignumEtna2023Collection_2401_2436 {  
    function verifyBottleCode(uint idBottle, string memory verificationCode) public pure returns (bool){
        string[36] memory _originalCollection = [
"a84c1bf5bd95e257dac13a6fcf5054e4f08971955cd2b611492798f53abe9cbe",
"c693228a3f22fb1b4c6e566c8e524c1eeb3907da9db591be2c77caf6f8df66f1",
"b9c3a0767531869d297ace4349cf49f3993c7c6b4840d08800952877c641921a",
"cb5568e27453ddda4e10f70cd2ffec4ae03be9abb1daf2ef59e308dfe97290d2",
"492a1bc9d84e87f1675ba99f681d426aedbdb41ff952dfae2362c9070e06ef5f",
"ecce2bba2503ddc601f435fdfe2a96f0f9c5f21d09e1e1239d61c51b5e2bbf9b",
"9f0e4484126d0bb641089ebdd6137f375024488a21032a5a37bec15fbaff41b7",
"de98accc09c417aa32c47f3c69f09dfffffe22dd4ea76dbf66f40030a7a6ebc9",
"9426d4dbe9736cfd57ac48e8dcdcedbcf9e1db396bf18f54403b406393d9d8b7",
"6fc36e0272e982295619e3c38f6490b4ffea085a986a13187a7730383fb11aa0",
"ad057e0d0c13d526d0a91731aef8cacf535f5ed8f6e6d953815432b6b009d084",
"de525b5565e5bfaba2407b2e42414e8eac3f9e58fecab6ceaacb5d50e12b7c75",
"4a57d680cdd2457052cd5ddf69da9067e045350b619dec73a5dd5b239848962b",
"bab14af42fb90a63482fe6a338ba60f8ae95de49730d9c8b35528212097917b8",
"213abbd178a753009104a2d733deb41948e1df68cf671e8b38d989ec29bbb398",
"50717ffa98f6afd60cdf0c2ad1d9205800afb6259180866c4fc17d1a880de9c2",
"58022cb45bd094a07ab26edf77545cbc47e643faffa87d3d48750cc5c3035d25",
"e21ccd7cffccfe9d28363d530e917468f6051536e410db8f7a50d461011d5fa0",
"bae27e693c307e530c5162d0990ecc9c067edcdff3e07a318b2d6639c3e346e7",
"963258c9019b7443db40894f5a63c9a32876ce1fc8b1ce21bdcdc663d5b3eff5",
"ccce912b5d647e6ab896436092ab8998f4ba4ec9052759a62b62001dbaddf16c",
"9c822bf7baa68d423cb1a2354f81c09e36bee58fcce564029bd67f57a478798b",
"47df6f89ffc819f63ec7f93c0baa8db1bccdf959b21eeb3c6b52d00d4f49d41a",
"f667e4f0c12f67740dd5a7fdf57b03d8a977258a2b2db145f0e2483986608545",
"050ce09f2edfbbc09522bbaeb14f38f023eb1ea022b4a6cbdb12195d138eff2f",
"732d17a63104a77decabc5297bcff0b7269a41415c7913d20a93789bf6b4538e",
"85d4e70270cf6a0f81b03f172b67c27542dc3ea7702754a71618daf0dcc3eac2",
"5a6e6950acf3b9b2e8903463262ead58471c271f2bdfd750c443a20816a982ee",
"879c79cf38401c47adcaeae31fe7e803b0e62c44b45458dc1ce2285b28e2558f",
"6bab48780d572ac07285af57cc68f4e876b7cf89f9ac5f9eaf7726980f559f2a",
"311c9f4ea7586924e381e4c72131f02ed2b0057fbd0585103418bcc236fd73ed",
"0b9453a7511553a288f5db0f280925dfa4330a0680a28707357f9b806597b923",
"2c63b6f4fdc5c198727d11fbdf542a407f5641984b6a6feb7561d54444dc8384",
"b4bcd100199b37bbcbd9fa4d43783c6ecdbd9d9ff85168a4fc7de97e835c5097",
"56fff5477e11b64169454ce8fb697c6495efcff9eb391d06d2abd33903d126db",
"2d6d4774a1571b80925296939420d257ce97cf7c2f06ba3c652cfef6f3f592a9"
        ];
        return Utils.compare(_originalCollection[idBottle], verificationCode); 
    }    
}