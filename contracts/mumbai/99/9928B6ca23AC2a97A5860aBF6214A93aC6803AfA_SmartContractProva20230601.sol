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

contract SmartContractProva20230601 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint private constant _TOTAL = 500;
    string[_TOTAL] private _collection;

    constructor() ERC721("Smart Contract Prova 2023-06-01", "MTK") {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

    // END -The following functions are overrides required by Solidity.

}

library LibProva {
    function verify(uint id, string memory hashCode) public view returns (bool){
    string[500] memory coll = ["2635589cb3747eff43d344e470af370db07e03904524398294e71809f6352b25",
"5778513c2dabfa43ac171807e4dfb5825cc154b5422ea197a3f7c532002a1bb4",
"802d196f4dc8464cb0573504578aa8f0b707b3477f1cbd2b10a5d5fb6bf958c4",
"cd286e5ef686774a316a9672c0864f15dca30a602aafea13fab9e3882866ac3b",
"8e9661a610ce751bec7433f7ea6f342bea9d4d98e8010de90369814db20abf95",
"0dfd086199263892c67db884b35be5be3af2c610a6d9dd8dd7d6cb636cd7c6a9",
"3ffccf81956bfa3d559c31948fc6633306ce9a7200b3084691dd742393c4d28e",
"9b78e627b07ea13a22a300eb0f0cc0989ac4c9a75dc6a61f6d8148fff42bce44",
"bb7998091a6001df26592dd3a2dd357cfdd4d316bde021419d3cc25c59b401f2",
"3630365db2cf88c437c454eae7c202df459e61e4014a6773ae11e5aade70847a",
"b117987dacc2849c6c23adab1c15f1ffecbd9badcee234758f677bfbbab7103c",
"b851ac0e95fef71525de1c120e72d61033ab64e8bd35d09d22f9d866121b3706",
"5e22d8b31312e430126c464b92263b913df606197ff50e828755f336352d94bf",
"6dbc884ffd9458ca9056518de4c0ac120a090e6cc987dcc786580e8415e7786b",
"07000452134c5d67d8c954766dc233eae113a8010a4fce643e016648a26887d3",
"5752a75d1351c7971dcf14b891225b2e894dfc8a50a4be3107c85aed1c660d78",
"ebed3e8c4fdfda30e940adbaa3d5e9b0c349cdc7b01f7ee33e7649b7b7c42620",
"c7a6f760a199ec6a826766f379892c51ff77c962650d5fc02ab837a08ed963c3",
"0c45e0cc266a3bd8da31a943191fa5870327bf83fc1d4772359b45455dcc5d67",
"b58915990b646d4f37224bea60521a9eddd7c9773da8a853047ef4d5c2a375b9",
"4e35abd3b2d03ad073da0d53707ed43169d01359e194a4d359639307cc80bb71",
"76bd572716809a8674a661851bddab6dfecf8161653bde52e56f890e3553320b",
"6cce77f5f5ac64f0ba5d86d2904b1d6504da158c1236c1b255f6269a3bc4c577",
"fa7da3bac7a8c0606fd600130be5e59b300f48ec0a4ff05cc62a49bcef0490b9",
"5834bcba9b5b40601528198dab389e6db2d82b34daa3b36ac4f972b70519653d",
"01b42b9171d2bf910cf1d91fa4b62f4ad3fc58cf4904d29887d340725e885a88",
"d7bbe687a9e9baec0bd9166dee19ba69c60de1762d8d7510d02c1b771dc0abbf",
"7716db3da2a57dd073fb8faa84a143a4255032aaa54c1589f94e534930649645",
"34fea748f31ae520c642db7dc56820768e1612dd4631175ec375459801b99fd5",
"4be52814b90f737326bce96022f865bab113b4e8f5a2e68931041fd96410da3a",
"f6340986a49039e7a9dab4fc3368b7f1ef14db84426245e9686abd2f302152bc",
"2ca5379e1f3489756631cbb9e550a9621884d28749ebecfe2a21bc0daae7bd25",
"c8181a03fe0f67f8182f1dc6afbf39c0d118f9f47d75f096efe9a38d0e730d05",
"daa8a219496ded7ae44cb73809b966b5bba773dda600f122a760753ad52b03d1",
"d493c6922c425e0b7cc5085c70d32be31e1afb31375c8328896583f9577a7e01",
"55e025d331bfa6e38b1d815bdc19252b375ff85d3a3d64abdd79c389f0696a31",
"db4ad2faf46deb381240210c729e41217b90c01d3c1a4cabd567cc2df67a35ca",
"86cc046ef1f214cc2e8b109cc57409fda4f32d91c5aa4da9b892eed5f69cb947",
"e05a2c1e915f7fa4b64289eb435f480e609b0a4718f2239bce049f12d6e13931",
"340cfba0300d5a0fb2600245a2cfff557fbe8c1e15553d29d5f7643894429344",
"b12e82b33ade326f53e8d96837f46cc44a03b7f43a372cade4aa0dbeb958320c",
"01929241e1133ff149e7bfab53934bcea9759d98a2d6fd75438fc055f72de940",
"0ebcef9ff7c0ad36eab7d3c61d26bf6a41bbc1c592138ce373785cccb66a899f",
"f2f1586da793ed39c8bb630552321345c8bd4fe6fc1a2bfea0a7a7f0e9992334",
"7b74db0c058ecb4891c9f465f3c6cfedbac0c8318c52ebd6182db5c9c0d82ddd",
"3883cb4288b4c3205eb055b50acf01e4f4ad0ebb36f79ac20ff2cce525c21c7e",
"df37ba7b1233df31b4c9f9c78220f502e2eff2b894a8d79b5748f80b1528d96d",
"3ec61adbb2d4c611e0cc2ae0a840ad8be10f5886e97a587c3d3537da84801334",
"79148e598bb2f94549fba6f46f3225b9f751616b2daf6ab176b0af14f82d9641",
"077b5dc76f428aef361692ae97654dc189c2a2a2e461ce0133fb53ab5fba1774",
"b03301f2f37ab010ce2805eb67aaa2752d285d032faab072e3a8ab331686d2ed",
"7c8a6cdbbdd598d29e63aa076bca8f24511632938e5b2972c5c33c1b5b9929c8",
"7d30266fadd2f503918809280aeb74e6963c198d22952db8ca3be9e4e1043e44",
"4e8b24324da3a03bfd3db7dca1037f43d1763afd6e41999ba67cc53202ef5b36",
"c07984abec26ea3e10293e8f7b599a8f28c2784de7e2a6587d838b25536b13ae",
"e29bbf0632b99b8b64784c99eaf8df37e86455fc7209f5f8729db47e2793b835",
"461209f73eaab29b164228d11e42b6fcba4d845b2b0d2bcd092f00c9a862b0d0",
"4506de72084e6f7ef7a7bb84484e0eaf222d3c5506330216640e3ee1cc3634a8",
"43f0511795139c075de8aee4d9e1e92092921890179194f36ea887ba5ef8473c",
"99435f643abfa3a47bcec5c3ce8654f6f28080a55b7cdeb79cb31724fe12741c",
"c29e7caf5725a070a2043cef689cd22004e61e32c793152c49af4efd6dbbdb4a",
"804a954af22b47e38e3e6ebbf8cffe9bab4a49990d3afd90c3853a7c730a0e84",
"fd9ce2480a4c4642979425a0ea43b9c3773b49d908485be5946c7d33960d25ee",
"88dca428c6ce0700dcaa12d2749903f326d110de7222b8ed143823366851104f",
"6279a367049e9bdac2ef6bfe3c4d65cb704ea3c71b473a88aacfa2a26402cc5c",
"fc5f248bc4aefb8d6520df7d715fe101d28795686acf04684b6a6cf0888a099e",
"75a42ebbf5fef3ad2fcb02d90e93bbaaf723f2254e1092c5bcdefd6292951b05",
"97a6fd8230f036e8901386fb0f35e21d208e1f3a9de34d81c328e7740c770847",
"a3e49d89b618e16d21a463d55d714933032cbd7882aae80a1ad72d4ee96834c8",
"da9b0eacc2f3eaeffde131688c3a54fbc1dbb9bcb9aea882297feb0838e8e77a",
"99fb78a1bd1f6724be1aa1c3007b83b6b21f2485b36d8168185885bc42afaf9a",
"94ea8c297a5534f0c4ab7b3743a9721697dcbc1c1aea8fab3723ba3ed8e42351",
"3c5c2e1d7ec793cd22c02be22044cfc72e4941a7ea0836cd15c3a9d3b17ce689",
"95798cf2790d95a705396276f3923f1c8cd57c702314755c6a676adebe8e5062",
"70e0bad417fdf8b4147fd9c07a8d8ca2f39ee492c75898bc334ea77c5d74a67c",
"ad8ea48fe9d062d548a2f5e71e94e1f9a67725870c0bce9b41580f1707264930",
"3b679d2b3916042b74760f3e51655a56f244018c8d742eb47cb46b66a5a7d7d6",
"415b36e700520e974139278fdd5a4d85909042dcf730cf924d9750cb655ba044",
"76dfe684ecc071a4596732e255aa8dab59f629d4bfb5eb0183b5ee5d5cb79802",
"90e9b6178976e7c7c8b449a288396dc4d2b577cb83ccee1d62a0d78f6d74c4a0",
"01e2d98c5f4eb6a530c9190e3cbaf71e6c2f5b4ee819830708fecea3edf08985",
"296335a929afac5ec738056c6de83a9db1e40d8e8f628ec5b16e4646947d0e35",
"21f36c4d2ba0794955b22a365396720d66f70f21bc350949a5a3479bfbff2cc0",
"e6170faf7155fcbb1d84452a8e73a0c1a518871ecd8220637bd34f43f0871c5d",
"74f0d97ca3c1c57ff9cc4b3638a3ded7f99b60650a79da92417951a19cf1e7f0",
"da838c936422c6215f060437a52253c1955056ef1df3aa9c1edfa4172fd00ac1",
"c1cd312a05d8cbd1a24385082c97e36b2f41d519308990e9254211474ddb237b",
"06e4eb38f69d7d29e0dc46f2b5b6b5ad9198596353728af36ac4cc64cb6f87c6",
"f8145b74b3079860c2185a67225fd417d4b87dd53d1c566c4a21b1d7d8fd64b5",
"9a49be173ef126d813743040f275b1da2a6395bb699e8fed7511ec3666a07237",
"ffe9f3f4c2f6c534f7fdb3fd65f019dbdca6997c837189e506231387b25e6944",
"70e5d473b1222d406a770fba48d1591ba6a2d26bb8eec0d7522d7c0813ca2b8b",
"b1a155a9fb2df17fa22f3a82a88b66e97d754772925335558c8abbbb5f8de439",
"3ba460474a6edf13c626154a767a5f6c0a94d3f0f021a8a8e4aa77e8a4a9b30b",
"27bcfedfd070923850bde74e63cedde282549cb86736ad5a194e5d3681adf1d3",
"823628f6d3f4d7b78b05f9da2e80489ee195bf4517a669d95631d2c12bdfe748",
"e08e051e213bf36238457f1a8e0fe32060ea01ae81de8b11676195df004c80ed",
"28ef6c39cae4fc0e4ac66314a77c95b83c4450201e97f0f1557e2936e68d50d9",
"0e594688cde3f98a3e765f9b8c1f486968f953c54a6804e5f59b94a7b993ae43",
"a2814395afe88f3e3588cf280b61ec65e1398fa3ba85da5fe437dd6c9b666234",
"4047c806465e5ebfd5c798cbfa87731a7cf537a32edfe40fc6d2623c1e421659",
"2d7899a6d5078ed2d42fca1ad9702600b59ed8462f8ac527695bb434d8891c4e",
"f84fd927813c377d73fb5ded93bd57b1931ad8b87841cf91b8fafe01bde753ce",
"3b206a169937a8c25fc75b011bbc7dd37c8cb55a564f8be5f449ef64f2d5b3ce",
"ce2989ce8eb211e72919a37601841df97d11eb5280bb4f7479b5b2349c42e87b",
"0881bc20c377023d41b3588d883600a5c7ffc9d32eaff3b84a1ebd9fd077651b",
"6951d7740d864ef9cbd4967d657816f7be8b629660e29fd15768cfcd220bdbc8",
"a940a6dbc83c2fae026dca0b1778f4d44c87abda87f6012b9ac0f3bf04e04d26",
"4d7f7274015148bc29eb1ee436ce347ecf9c9213158430b18d4b401713a134c4",
"bbad360d0b045596784e46f1bb9627f124fc26431711085b654f592a802039f5",
"0828a8ded8257c900faa69aa46b464baefd7c16ec202ab559dfc6872bb2e54af",
"c42401f729c02ca734f83a507104880b23fcc114b8088a51671750fdb6e0d284",
"cec85f27d77bf9349087f0e7da93180c9b608561eb3733d6a1e76e6e47c621f4",
"1a7a6da56df9f344fcd05536949aeb00ebd01c34907ef6d3826573b3fdf54763",
"5ee1a3e58511a9a43256f3010c5d104dbea199d3d51694f2cc311e573dc84301",
"a1ca7c617a26321fc47d1c3b6b85fdff856e05d7311ff3513e6a8d5c2ec62075",
"c42d537219cb91e399e808440a96192d0198da2c0ffbee723bf997c18a1623fd",
"bba63b9c489139486ad0c0395b4b2db6067701df61337d28ed2911d3dd846e41",
"27ceefceb4f4bb45ea70f00fcf78f1e04b0080b8413e3d4e1a3817ffea275b2a",
"44a6bd2e713acdf7ef9860ea4fe6470b30b56acfeb0bb7980c5d83393a27e82f",
"90f77e0fcde23da1285a3867418bf32ec04341c8c44fee45039c604af9270f38",
"2266c1c9ef5d2b21e6d9e21404954e9ff08190cd8f1252b18e2b4bcf162cc3b3",
"9f517356db2a3b12fd9db3a0eb95d21bed2349efd1fca65f1eb981954d2e2918",
"4192080596ac16275ca33771aa3f5d17cfc4b3691b2db5f90584a38680b030bc",
"bca82bd1d2136a37610ad7ac5f01884e767dff718f6820865b37835037210387",
"475cd6b1f37307d5b637a0e3410c757bb634fb08750fd28c4a8bc972e1bc7d8d",
"ce3667c695acb050f8484121bf17313b021d9adfac05228dc39cf898c449cb49",
"26f4015910335f17ccdd06dd2499e23eeff8d7da581cff757de8d80fa4bbb42a",
"bfbe8557a0da67c7e8a7cd39ded9cb67f2bb6317be07bf25695de1cd9a1d7776",
"b3ecf033e013a673a99c7a3a9275ac859ce8914db2c6cebbb50a9d2a7582776a",
"9664063f22b5ea59d905629016e96b35f2fb6e88fd45e7ec8fd8c1937b01bd08",
"d8544fec9b8ee83b7841af930edb8dbcf60da0ad5bc2c564b7309486360d7e0a",
"6f91ff5d7b7342a241dbadc89f2ebd94e0e97ca54da9a35ab521bf7ce6b52664",
"4c83c4283f70b77494e3b0b9454d5a3154efe849d66358165a85595b963a1f9e",
"c25e952174e71daaba95ecd07920e1b9d2174293344491eaa44abe90695cce7e",
"bdb11f888542cbf75aed5fdecc0414420d3e7bfdf7a36d7668de5c3223b3d066",
"35c54a57802a5f7991320b29b2ad639a37db11609765b451f7e708f91e7681ed",
"eadd434ebf051a8a55ce964d9173155ff2181fd621cecb348c44b6e90868130f",
"c5700051aa6cb18a5157c6cb5d72b7bb2eceaef02dc91f81d86c39a66504bab0",
"728f240d20015faad74ae36d622df5b7dbf9d43c29b98cd6cccae6ba0c33bcc2",
"8dbeb254242cea26a7bd2534079fe76e7b66b852e43f56f3aea8e30177ac05eb",
"b463c27418c4a87600e82c32d1d45bb5007cbaf755c463e1446445fe8f3474c5",
"06d65b3e18b6ebdbe672978762efa2166b4e1b4cae0887175cfb15b36eeb5eaf",
"dd5c580f2870ca65f4cb5305343b6127f9e7ed590008448958255d4fe48eda23",
"048bdd72d6a6bccd03247787313bb024c0760116d702f10de1b235ece240e2f3",
"8d1b08b631fb8781da2b28b8eb37b5c06c7398a58ab1a5ee12a1f38f6d0d5e66",
"463198c8a90b858ab3474a3bb0ec4cfc63872b1f7cd5c3cb9921f4722d04eb6b",
"8914b03bcb09ae105dcfd3ea647afe68385e54cd7ea328eea0ca0e31f6cbaa3e",
"683005a2938bdb9d80466f139f22d147a0c6cf8adfc25bb0f882f1c7e8af8a3b",
"7ccf3b4e5e9fcb002fe0a5c3da6201bc69211b9863057367e620a81709e4982a",
"401225ecb6aa1fc7ea6414c79208ef2fc1282f4a30ceb24e6f0f7b9de22184e3",
"1ab1842c9d69dcdd374c8422ad4634a5f58d0c28880549a3382af5bbaa044107",
"263d710673a144fb6db6fcfc9fd09ff6fa9fd585d04bbaecff59abbfe4677047",
"9cfe7f9bc8fffe2a78cd2bcfe15e7a2359ede28a128e81c19746ba499c845a34",
"97960a5935b87a6e65d44d71dfb1234171b4f56b15a6e6fb66900a0ecf4cbdf9",
"169ee571b8d6d4ee7f102e9b19821b714e8c9f31698a7ddf966c8cf9c58259fb",
"9b91374ef126ec6fbc00bb10eca61042bbe26c0962de23414fd3555044810927",
"699d6531f186c5918527caf9aeb86f7664c848509b9265a9bcea0ef658b487cd",
"d17b13b1671cb9469b348b8c92d8eb44442aa092d10ef7b4f7e884ff8832399b",
"a1fb7a4a084335d5b89a8d5e414675e1b724fb5c0e5a3891ad585f18612ce71e",
"2e9fada6df1ab939b9d05f2ca979e1212509344954ac2e581d458ad919cfa6d4",
"977f0d7b1adce6694f5fa91a98a34dac6a283858d46ddc256fb7d7d20d847b4d",
"6c6ab1c811f02ee0d98cc5c1e2200f2d3b885748236f616bef7cdfb10349e405",
"c821d588fe105f06747a16ec0a3dd19fe2633a1e6a3c8c7336b016b22168f2d8",
"9f23f8d3a8b5010449985fd8153ef4adf54eb642b4637ef8f817d51fe0049ef8",
"f615be00bc838974704ae3f26fb43d40e16bd549b63b6fb083446de5b9db3f56",
"ccc1fc8308c361bdcef359fe63b3a19a20f2a007997be1c4177bec30aa3e91b3",
"2ebd3ae4284d4ff7a4bd17dfc311c908c922a5b8dd12b7553624ed894ebb2e7e",
"6a32b79d2778c3cf2065e19ea091faf82982c0d2c252797465889a6677caa33c",
"44b1b54bc63deda52c04339a16d8b6389422357b11c9632ea5e96988875925cb",
"7473095fbdcabbe51200d92e9579e4c0597b73e7d7abbac594e64b67d4d5eef6",
"de2efb761388082bf2bc3b34921285ec8180cb47e5c84534b13f8f4523c9fd72",
"a9429388100ad9fc47e2893a004b570dc83e067ce7da829262c0cd631529bc58",
"0b2680e8cfc9b5dc09cdb22ffcf6c8b231cdda5a5068f42866e96661e255c083",
"fdce87786695cbda1225f45890e6668eb1cd9d02394188b06000f5e39f8fb63b",
"3306f7ab8b7118f0625469dd0bda35c76851fb4181f328252a1a108af49ae550",
"5a076c059dd3fa6968620ab732d6aa0065aeb9be52ba7cc7f59948471f9d5ccc",
"cde962ccb25e284a41b9ee07d4c8227398b821a82fa9736d2b1f115e45a9c7e2",
"67536f01d35d74aa4cd63ba0376a64e0589d661f60da0693a6103cf2d1a802af",
"cb6941e27e89c987d09ad0d641246030e578cfd9148267e53a88434a9f823d6c",
"ffe9855e548ef94ad729d0f8d7cda3271ed31982df3ba97cc7771b608416551c",
"d6fd3f287c25e9049f06a358a86ac2257af78c4d32c3afbe5f62980dc4552da8",
"27755c344006c989c2e3fccf396978022d5565dc8a4808de3362496ebb543bfd",
"dc88968fadb4319051b002d4a7bad4eba1772eb4fe1e5295ff7cc1bb24526f7b",
"d78ca525a0aba53ea16ddcf3094f8740a4aa48f51e6518363dae28b1fbc496eb",
"167387bbada5a802cd6e220abf4a7e200cfe1015494d0ef6af0b7aa51fcd084b",
"71636d8e0ca59e0e6804aeab1b653f5372d321b4028a10d9789d19439d5912ef",
"bd30406802204912c7bd15ac8a4b51c20e6dc24204c491a8fe01edaf7e84d524",
"ca353ea244570cbba50b4e58e759a5cf814efcadde3cb9f438ce837abe13eedd",
"d63abc5aeaa00a110563c30e51108cc64b297bb400fdefde7a2bca851466c182",
"a261780ecdd6567b50d4ea73af6d84e4f77c57b129cf2525b85d50f5e6f91229",
"d0d31b4f4ee77a87ab2851b69bcd0b92c884b93f755ec5a0896abaad31dfd55a",
"497b45b38bfac771b441b753a140254939b21cad3d376ed8b6d4cb5300f24610",
"a90b7630242d77288e9bf8d51f7872969ee225a67a82897b61650c1e508385f8",
"3b7e8ae5083e593d878fed20d794c6f478b3018e41128437e39ede77b545ceb1",
"f23786e937b9a3a36e9e5a3e9e5511d44c9a8c33e2035d33187a6b50ba0f367b",
"af5eb26733dc6427b507273ea6f6a5398cd92635af390f01755062a59da30cc8",
"31c3fd46ca8398f3d7e1fac6a1e1a339f312b9c836cb16e50213000404c0a34e",
"ccd9f9683f7559c55decaa89b03d4b9c8e6cf71e012e8aeacbecd7fcdc6b8727",
"288ed7e4b5db2541162645f5d82185f520bcec32af6e8677d6402c513996f8d8",
"869b943c3a2ca86bf5bcd534441a73fd09d47c3bf02606b4787a7683d64a06fe",
"9b9c3e5247dab444cd88e85fea1a5736a7de9ca0441c431656126566288be7b2",
"b24e5cfc6365a8ff4e99b6f7286fbceb726ef53a49ac1499f752070fc13a32d0",
"8cfd7187b726798ca9d5acf4aebaecc012680da6608873a045eeca226147713b",
"a9efa6f971381eb5a311a93e17c5babfa972a014c7996a2aa2fc2eebba13c277",
"86f4aba5d1558fe6928caf38dc252260578268978e31cf187a580f9569794e1e",
"e60b7a1655295f65097de68d73434f7426eb03742f14aeb102afdb10376f2a26",
"89f624405e69d4cbf132ff74d35cd7004041f71276a75273f73bc98a20581731",
"91f6082c00133066b4e0aa13d2df79f2446f3314064eadc50084fac17537f77c",
"22bdf73eeecdb2e0d101bc7defa7b1a2adc4daca7b2685fbd4e723c3ca9343cb",
"e21d1b24f77d4dab48b43f3a4687733152bdc0c00b34e6c3003fd4767f51a88f",
"6c16310ccd9ebaacd66e204077c18dbcde421219c182b1ed0a00790971dc581b",
"2a6f079c6b039f562d041df6111729f6199c3b1c048ffb683fa303ad9266de58",
"f9f15a8f2f693faad1f48d5f380d8f6e7f00099b95bd44f1cbeaa752cc384901",
"c284d3ddd1556cda1baf43a9da71e39abe5bdfade1caea18e713c477e9bab125",
"2816a43a84e6e31526bf2acdc51cc7a2c4ca2042dd59d8ee2ffa71e934b15801",
"4d3d2ca8738f08a204a0465f46494f8e89eba04b9cac1d2c604bee06fb9d84b1",
"bc5a118b3747cbc414d75e8ceba629c2bdc80999c9fe73bc39b3e31d6a719d6c",
"d77627ee7601cd04458973d3d493a9a47ffc9d2da4f51ad0d96ad2a00ba00c0e",
"f58f2efe4f0df439d6cc04b47c180e756c263a728ca2824082553483989ea322",
"981e1cf6286632854fb74c44ad77bb5576303dc648bd2f555539f801d8eb598d",
"28797892641b753b57873e3c3d3d6e2e248e5e8364f32f7712d9545735ec90be",
"3d954edfc4b9db9e6ee964cabbad8bc1ff9332627256fc044e1b239be05cf1b7",
"1ce7fcd4ed44bf3292aa5c1add1e8f0c0b288e6aa59100bb41a44f30be4cea2b",
"6d504b3e094787e3d74a7fb1cef78b3f84c91e233dbc9c7102228f2c725edb64",
"92b41f5d393783d5c93b7965e6435fd8673ec674d3a507dd996d0a15d63a6e2c",
"9746e09eca4d287cb8c455549ad8edeea13433166b4ac191756c420acb3d3217",
"d32de541ef79f27cb240421decfdde98d1f2a72b80540674d8c514d041ad0ec1",
"1c9d3db506f4fe7105f5f748ca915a8d2bd21bd85a57ffd146899ca0063c4fff",
"23efdea57a5ccbeea24b0bf78ac5ef89a8dd563b48f550d779432a3ca1d875e0",
"1b9faa482207355a0b05d3f0d3b28a657c56930f5d7aa3c673577d1fc2e66880",
"eb93fff6a06c2504ec358ef3165d61d5a6cf86f947a6494ccb616b96f8b4dc66",
"36a7efe179b56e438f801e6f37f6a039fe666ba59cc041e5a7da9247f8a8fa38",
"bc7d96816e9ac6454c8cd43483ca8b8ccec3970cddd2d9182ffcde52461f7336",
"efaab9703c4a930d0b3ee649e42cf4b51290a439e6a94b1c9cf3a1449531b9a0",
"bc896ced1b2a7d61f27a2a524bec9d8737fdda22d1a5ea0d948e4dc93afb33f3",
"2ec3220a3689672ade434f0be7020c7e42ae4c90a73fd64e6278c3c97581204a",
"7e445fd4e875f1fff1bfa883b2522f36c028c26a66409f82f177060c589727b0",
"a6855df4101b950f65954da364eb1422ad25e2aca2d618bcfda34c806ee201e9",
"ed547c2457011cab868bb7b587d641745168c886c3d051102e94656b96ef7e01",
"f398062eecd56e51e5480c2f233dd09698639772407a5b8b051468707f208e59",
"3ed302ad97304b2e40f6197b47348824c47a2eb299d7b1052914eae6c9372c4e",
"15a81244b8d6ca1634814f717319158b3e41ab9271400910fcb15d1bae3e0cd9",
"d3c8b8c5b8d09a461dcc4c14009c8e8009df5cce2b43b2c0e81df259f0c27b4b",
"59430dcb28e4c6a240478f5866371163869268aae7febadc1ef5a24f034b2911",
"b238fabcf71b202aef40bba9c41a16c1b6001f399654495781d2e77b73be1c75",
"09f03a61b5402bf7dd0b5313cde696694781a7778e18fcf88e087f642dcd1a8d",
"e4c193b43d625ed09f10aa8d6e5e518d3b5d4d98df0d7e75ee963daced0c8774",
"fd15f55ac65fe27a0c699afd636dccf86347a0323da0e614e6715ec69718f392",
"8878efcd51d5c3007f7cc4119b0f6f3431d757ab83cefc4511b9488d7ba25964",
"845e776f602ec63e18e5f24a55ddf544517aa9d40dc033b4614e063f1b13768d",
"1dce9acd1da6768bb738d51d2e719bda5095cfc29944e06a896227f93e1bc62a",
"7cc136ab4f4a59c3e8a30f877625bf066c26d3f9f2a1887af268dc2b767bbc6c",
"9b3275f223f41418c1473ac4c82989b22fb9dcd635fcf75bf24436f26b28468c",
"1e8ed900d75e4de5f09c73f7c23876ea23312a3daedc8fb6380ac82be4e98279",
"0e9d41de0820787bda3c6b3bc16f3a67284d7c69168006c8d3c1e975c968e281",
"86190ac4e7b1cd10dc747cfb3ee27254a0fee4e513875610ebe52b3cf2c9093c",
"3a929f46ad5138070cee466f8b44c10c153d1db6a3e0bf4389486a38eafd7575",
"0dc6d192d9d6119baf432478faaebc99d3b257e53454fc912ac2b71b079f4e86",
"caebc5832cc4dfa75c82d7d557e6be3224b1de71706d0d179f19a20da09991e7",
"b158b8b243dab47f3b070afcd732302ee2afa4524ab575748e830dcdeff367aa",
"613d0997bed4f3f263e1d469fd2b3ab2c9881c1c107c40f7ce35f3c37636661d",
"5b76bc3c8f505c5312d7d408f222e13f5fe52bcaf173b90dfa3e4b217b17f049",
"557c8e5b185d35e5ace5084de277fbed8b6d099637d9650198b5363a51f6a54a",
"437615e53a0c53327d63a74e9c8dc73273928eba496523cd2b0ae60b686065c8",
"125fa86774db9d0dbef71b65fd155d79f1f4c739e3ef8c6b28b890f7e7b9b780",
"cbce6a0fb47367ce19f7ede2695a1dfe78d14536546c6c2debf823133d82a039",
"82fd27863e422f9a33e2f09efc67496ca4a9d2779e2fca6c0f01ff85294f329f",
"8e4e4d30ec85d5baa534ed00916f77f2d7333c830327259ae3b634cab528ce9c",
"794ae63205e9d4f7e7786c6df954a74cc77d6a47fcef3c4bc86743cbd4657682",
"588ac9e22113e6faec804c913074cba16f2c9e241f0b8dac5b3881b2eba83ecd",
"b2ad3ccfb8e36067219b2796376ad08c1cdbcb40bb095cbe3ad8dd1fabf1f123",
"b03168c2b4c19b5d9d155faca1eca09d363ef4023581508e008e4b7755762080",
"c4b41c3b18298ead182db950d2e2b8518ceafa68b720280fe5a72140d31fa6d6",
"286f7ef1051f1cc90fc84b82ad2bab3c6f66601e9acc9be1a3477e32495d99de",
"c7a6b4f92f387ccff07e289692147ef464f191c729f9fd8f52dfb382d8e99af0",
"cf9794d5547182d7bae8dd71d6c80094d824b5e3fb81f47b1de5ad49a206ba15",
"0a8d42425d0c34f569547d243a53e818660a20667852026ce9b59218bbfc6683",
"51a223ce339c8b10a031c8930c98a3d740eaac14cd5243b8aec761d35e037bf7",
"49bdc347b763390789983389c57fbe2c4e88542e8c34fe01432bc2cc03e193fe",
"89ea492c6e7dfa17b3f7db61e954efba1900a6b048c0bf1127160d8784f2e446",
"65b2ff0308052d4195eed4d154fab894566446762d7a41ae3c120184aa379c8a",
"b3b079bb9f3ce1ed03397cd006d7fefe197efa2b3a9ee0a29405665b44f9be3b",
"c552f4342d7c849034ee10c2695d86d98b94c2c77b1a478fa64bf8a8e0444f0f",
"0071c9687c9d38e8c78fc0ea20d59ccb451e4a51683b59d655e33b608f2b7e18",
"d42cd6686879e920838d32a022c9b81fc4384c84fac6f00e6ebce65ecdc67d3f",
"ffee91a96dfe77c0761f3f982640442c1f2be8ab418efe64c4d60935db96ff89",
"65756594d185d8d175955366749725092cffeee2ae7cdf7f92c29ab872c72344",
"a3d628128453045faf6df6c4bdcd9892edf67ba42c900042ebd4a3686071e1e7",
"5ae137f7a0cceb4e10dc60b5b98b95216ce05c07dcf5e136a5df5e7d45b71176",
"438742bb92b580d1d5c274ba8f3db7790ee9228cbd447a1de82bc578e22495e9",
"ce58522572034ca27274486b50149fc559fdd307d3ab2ae107bc0b686fd0e293",
"d24eeb4cf728378487cdb90cd61ca2888d7a3b30bc90b3a04fa9ef72b59d0b4e",
"41dfb0c981700f123098b2e02a26895f667f1dbcafec8f0e0bcf9603b8ecce6e",
"5cae7e4f313f00a5cba464c1038b0ccb02df366cb23c9e13cd847e7ef9723a95",
"803b315e1b86cacbf07ebee8cf954783044de9b372aa044092c917fd43352c14",
"8467ee4978b35b4007f01f0f68cb64911fcc8e358b44b79cf744c599b771a06c",
"18364745dc8bf251fbbb857eca0ff088231eb58bceba4ce4e2de6d78cce5b994",
"c9dfec6ddd835cb867e75bbb563a07d3af21f4be986bd603df2cd656af5c48c1",
"40b2e887116d184d1652304fdc0944c0798de5e861e75d023d022291c85bad91",
"6f9e60ec4c52bd1c84e7361f173f297153a474d28a373b497a099ad3727f1ab8",
"d3bdbc3bce533fa43218a8923735d7cbf0e1b6be4d3a0b052f4e37d69c192d9d",
"a4efa97d51568444ea2c131030ba2168fa4aaec5f5b06847e59cd3da88cf25da",
"0bd7e2afbab9ec1656fade2f4a338db2dba75938f67f2a4166d8a189ae6a861b",
"44f55b0f2120567a597cfcb705014182c8e8b57ba568c6cda8cb312d9d427243",
"9b97af325bd94ef19bfb05441329f9a655952b09b0a6dfbab36bad7b8640fee5",
"a4261542507e55489e6bf6482f8de5ce5ee33b9ab553640da50035b2ac4ce962",
"5f3cdf8a578a3a701c1248538aab81cf1556f1f1e1410b5e7d4403c8f283f185",
"a26ff34a0cfb5d0a3044fea396ca067fbed57b427d8eee1e9bb7ff3b5b3863f6",
"65122601bf4c2a0630960c2466c9632054d2e731c9a827d5d667bb09743ec46d",
"066f3e3630a0c18e409fbb7740dc8902679be7da436453fd5d5022eade041f0a",
"aeeb5f989a22cc6e71af9420d8e298a7bc408242e4fb353b1f749fdf163a251f",
"1ea4bd00da6d7db5db721dc8d6ffda7e8b526a789d83c130a59a2e035e55c91d",
"8a0f26faea18c71a48e38e560f7c54e148b885ba712eef22960cc431485b927e",
"166aaa0f82146b2d4ff16946ac6c03895ef2b75a38f37ff03c199f06660fb202",
"2b8b249f8cb08adbd3402ec549ea711faa95225474fcc57e0f4d04b45df8c45c",
"d6b5c2ce7598b5631bbdcce32f9fdcef5777c7609e5ace92e9ed8cdf99ae0bde",
"778a1c02c1b0f4edb044ad725f2d456b2422ae96a96812d00869d9626b858e27",
"4c9bdbfd1661e2ec335359fe7f23246ec26a1b84c66cacc3aaed90c3661e22e1",
"4169b5ee2230b2a7fe444f4f90d1c9f240df088333f4b6232004e634a129f09b",
"1ca84b2ff9af3d35cde0069bb9bb85b56bd22e72bc8b6a4244702ffb710788cb",
"752fed0cd1ca7aa47ad3d7b54bdbb5df61b9de426ed98999af463357636927fa",
"ebb5332839582bf05d234a56149f3074ed880c0e400584eb4aa7ec0640718061",
"4b1b680a252a8f82e36ca015ba8d859fefcde2f4634bd0ed09487a7eef600181",
"8b8e70bd7dc09f49c3122a63d216ab7df557bd30d013e14b9648ff8ed9de814e",
"b9bb6ac5d106610922193f421fcb8e5aa394cff4dfbf2189e0ba3b93025f2969",
"cdd231e749c6bccbe528bba10944eaad341549eac5d6dc8db670c0f12a589cbc",
"449d454fbe2acdc947e1e9c3f66419cbd880ffc78397f2c1594a2b55a1b19724",
"407a9fa32a04f5b1c64485a527a631bb6e1b9ec014d8e339869f620ae220dc4c",
"e02129597e0b62bae0c1ca4611694c967627a23bb236b441560fcd8b3ab63698",
"9f04526ac1aa223e5de8a9568f3b4e48b1c480980813e685618ff9bbe3751f99",
"13b45e85454b9b42558a270070500cc20085757090a41656cc4be8bcc5ce412c",
"66ee98f43ade4cc27f059ad01a3e93d668510d0f76b6b94960abaf70e47ccffd",
"70ae12d7a73a5694c9865c30d511de13383721220fe0d38049acbbf8b13ca1af",
"0e71626bf8c1e75fe0c05cc963e3955d8c4bf4d12621ff577256519d142af874",
"f1a26cdbff39e4078b9d83422af37acbba8e5265f99e26cab25632626d67a1ad",
"3576364474a9549d84051e2233358231bdf86b8e1dd87c60e34739a58933e770",
"2ae69f327ff797c5fdc4e6fceff87c65fb42b95d20bb0a517d8e340354e60e32",
"c10470b420888a2e80f5696e401f488e5bfd7dedaec0b75eaf6397cf830d4edc",
"812e4b1bceb85c4b17362dc989f8067f15c5286b01470fe4ffa42bd9b667dea7",
"a39f4c8ca647e8fe7e7f28f02fd04c45376bbebc1e49c56f03ca097360242ba1",
"2374737d67df748a025aaf58152fc1dfbf6b4a2e58f93fe9d1051a08646fde8e",
"b6fb82fd7c1c8ca0872e88c9fcfbe165f74427b4f88d3001e3e4d48b5fe19750",
"ecc9faf85d51cc4b2ab54acf48bf31b948e902c49db11aad8fd37f323dfe1d6f",
"33c182f61c8f8c72ae3d10757d4cf78b46a79551a9cef17fb6257aebe1d4d9f4",
"8b1550b90be92e8b9040681a013d37daf724d1dddebd353c6281f4b7c66b051a",
"2456a8ef7cf5e2a372568c0d5703dc84769e47485d1946a253adade9cc2be054",
"a7c87ee8bde43fc4f78449513a478f13781173a3eb20984f0a9d33e945d64827",
"5430b92627b3ecdcdeecddd3671f582aea5d9212e8654449accedc0f0ded711d",
"9979e518076fab6266469cd3b1a0be7da3a5a1456c143286724340fc5a01c119",
"937d2c80b1f702775e6022ffc59403cc29f0a1f478cd4d3739a46d4f7884c02d",
"7c5ee517e8e2bc425bd53533b20536137b7af16f930506f0075054a44239cbef",
"2cc3c64de9cfab7efc1d79092525ef8c17729cb671ba409dcdcc1d3fcb610e3d",
"4f03428601fe54cdc0ae03e05a9acbe9dc50a448e920d8f262fdf0abface86c0",
"991f76478cd822492f478ddcc8933905162bc990ee49b69b69dd166359febd34",
"0e7dfbfc1fdb9ceaac8348335160bad48b6ea86687204a878ed57e1cc261d6f8",
"7366639541469c8a0cf20ebfecf3d8a2aa6e4da5538c4d948113511114a64c20",
"a36c5adaae0652f06d3060cdb7b2ff09d142a1ccd745947a2b50a536825dcea1",
"66c3cfc5065a63c5c38b140530dcdcb17c54e084bf151819514afba85739d174",
"04048cc7eb687b11eed0c3cf779bfbb3e4bcb4bad8a36aa6ce43949c36c39a73",
"269efcd10886efcb3ede629d9b929b982c10354842723b1026bef41197403679",
"20f8e2809fe2e5a0d7ada781f7f09151bb3a39eada162086bc1de79f0e627036",
"9156f5d253800c93407b44c530441f119fe41be45d45a67e4e47dc3e8f0814a8",
"f3a4d59ad6fc8ad222aaae9b15d744f0117bfc61b7e754956a6b7e56e4b58590",
"6269e7add14a64701554994450a4b3b1caf0ae1143657bf51e0c55afae966175",
"739d233401b4d57c42b21818b7cdaa287d8cc807b8e0bcca6f51ac1042c62271",
"4c4d3b924a90b2c55566405217897539de90ea08008f48b5d02ce81e2f47e3d9",
"fbad388c4497f51112b47809dd9ee4f96daa3bdf530b2330b61d50857fdaf93a",
"b4f9b5f5436e4ffb98d9662688ff6aeadf054867d764933634da15110509074e",
"399c513ab3b026f45cb92ba4ee4bff529beb0440c41dbed81f818bb37d010a04",
"07af42a5c1b11b67cb903e50c2bdcdb2b054ed3870850173b118b14c13cf5815",
"26d20bddfb9df95a6fba1a6243cccb01d5f01a3a8fa23e7cd04f82d0fedad91c",
"020b73cb659e74a840d2d7c0f6fd029b4f732eb4e2695519f1e0b846f7739255",
"be17d17ecc8870287121c8466fa70870f4a31c241f6f452e11708c96ca641d60",
"60d5957940cb4d232d1cb04eae8fbdc20894c191595612e422f039143789f75e",
"4ec9d172b985335283c5da2734c290ae0b1b1ac1f67781126ab363a41ccac975",
"4bbf4540c2619b37384967bff3a2319410e214e1fe9f64c66eeb95d9136c9f8f",
"e45643234092b15f2e730d56aef057390d8803575bdbaf2eb986b8ca379f0282",
"d6022b1633ee9e8cd6c1bcef841d3b79ef014b68d0a6524e09ab3659ae46d576",
"6edc150e0e137093c8fd9759a32fe451a9549b692d23c713a7e2c600049a3410",
"61f2cf3ffb001c7af93b40fa59c769518c7db7a2156bb844e6d0916b48c25449",
"ced53ef1012c990cf99d8dd709c69e94c93e1911252c50f286410f21cfc64a1e",
"c3c3c2ec4d56e2b8086ad418a5acf668f698e0f23417f3fce7b4adeed0330374",
"7628796e43e4f41b14e1a5fff628f232f4a7c05d317874557526bf5172fb77c2",
"5cde6dbdaa02240189945236bc4f44838ce01a165a23489a38277445d8f74684",
"6b2bfc3a3e3030a727c7e6d8f23fe78787b9d47320921828a4d6edc8f0f9ad2a",
"04bd34037a9b5e9c8e15b9e1462b5c1c8c00c323b63f11c3be0ee3b8a999fca8",
"1f6b291599204d656f6bf7afb749e0f4eccebd4dfd4a6891814e99ec53498e8d",
"1336e5bc72525c2e56be51e2cdc73fe7ac046f0cadbad9c738522f7268ada0b8",
"0ef88c66d9c4bdaac592b5877b44738e29c034530c31e866ab38450336a30ede",
"7c992d4668e566884b0f7f113cd6157318da58a33dd10c8155938a94b8a5b89e",
"81177083e5a5787f6cfab8a68a897c21cff0fb443ddb5c395a9abf76d93c7e3d",
"a065eca017f319638310b450fb3f997c8f9dc1497275955d98b33eff217942dd",
"7dfa873e5512fbfa14e3e9eba3fd46728fc8fa8240aab11c11ef77b07fbda663",
"3a752638d604fec9c8ee64ee4fada129f7f3a6228317b21e9067950ec62c29ea",
"8d2d199c4d26c462e41c16b8527fa55684249949b82a16ec7a468df1520a3483",
"21400a9499c6a7a085c23e6e61285a154c2898ae7455389aba46708e91d2e11b",
"8e416f7fd5083388f72c687c5b8465be6e6fc685452d33c21650bee0b71c6167",
"d228cd3dbad54f30a24a29dba6ece4cbeef0164be3c1f0b43ede72a4c2b60bde",
"d93f3ba29b01d9df65c498bad034f70eb9b80e382942ba40390741063c429f92",
"dbbff8341f304c85b311124d30542f2a433ccb4d548430ae852097d8cd72f4db",
"fa0f355a95ceb1d509ae2a7c93b16771defb2bc42adb063c0e611a573e3905e5",
"31cd16704f6ac10a698e9bd1e0add5b946815f6752a90e6087b5db7fb8b5af49",
"c95e02bda2bbd5c1d8869f3d8c8f0f319022749367c23ab92d6165d6e6f3b47e",
"1ce40c3198e6f5d4956fcea318f15d0ac55d288f6bf65cb0888ab96b95810e9c",
"eb47c7d81d61e0e1a5508f487431ac8f46363047c8e082c9c73e7b16a13a370b",
"299a562350457933836cd2b5a3472e60bc589d06c47ada4e073926733adb6b16",
"d4b9e8665258e70f326c6a774b74acdbb3815b30cb0b852e5b3e75d0e85aa9c5",
"b427704c71c47270586ce7a0404ee4ebb1c8c6755fc7662ab53a845ba73c85a1",
"e1ee95c24f3324ee798de2a938e7ae99ce04691d5b1ec33e537b8a15d56dba44",
"afd35958a31e92d5f3a2f799c18c9c8e41fb485da85ee3afc04ce532ca72d524",
"fa9c124e9e4d0eedb346fa764f46a0893a63a300482824c70ff071ae70444f12",
"3a2df50e3d986bf17ab68e790a1488930a26b53ea7234591d6a3c4d6adf2b744",
"9d76b468a7f92268c36919cc49467b4e86e34d7a5f848f2e3966983e69a5d054",
"d37496a733f0dac6aafc22532837d9351658728386cb946879727820a1fb9474",
"48587d5f37f8bdf88b8405f3dc693b51a77972bded6c6b0ac99aeaf3fb28c0f2",
"e7a75da35ee047ced609c6198ff8ddb137eb2c2390fc8c2dc35ddb8636b19307",
"88467cf0c41740e0b1c7add6e535b6993656da8f9431098382f8b6d1cfd9b41c",
"76c2128775b72b9b8d3488bbe5212cc0aabb0ee1cf5a9b2fff27f748191c04c3",
"953083d01f551c6c0011a19c50924331a7516272fa46499c3e95581ebca9eece",
"68bae700aed7ab5e0d801ac482f8fe02447d66db46383869a4b3c7c85fa459ae",
"bd6ca006712218debe91e4f25d0fc61f7a7e4f414162b948f98137847bafcaea",
"71c918b62ac052f6994e5e2236762c6e894d8cffaf6e10df64de628ea0cb16c8",
"505abca177737e9e4a120712d7a04b48458d948073a6d4cb8d867f48340b4d9e",
"89a3d2e1ec4d7a1a3e0e35a617831c84fe9ff9eeaa7268b197a31000100d2d24",
"f76255fbb21886c5b2dafd4f5eafc8187f208b32d553c77493bdaddaa5bc2a49",
"3816143f3019f34a12764b13afc568229c46e0d480252928ecfa3cec626dbab8",
"e40f9abbf15ed058bd2853388dc402c9813fe30fd741558408e4ec974c6ab3b7",
"6af2dc647b3ce636acef8c7f542715b245f27249654be80cc79963cf8f9b7afc",
"889a0e0e674f1f382d0c8b74da13b0ad7922112e888f56ab95433f4f89e0caf5",
"38e41f1729b218d4e62d3440c69f6b4daaef91a7b3585b8bd9f1465d77852bc3",
"e9141d1c3e76b60b4cc758f1816ca7d8ecb14c8fda4e30e305be4c2b272f57de",
"fa9b13715101b027332a5668c9cc2b0053568412edfde19b9b340ade89dcdbe2",
"f48dc51540627cce5ac842c6e1b513f31edfc3920e38f690f92bd926d8846ca8",
"8ac0a46c5895b1f7ffb55d1ae9b09bbcb354e4be60e185d46a4fa01a7765be76",
"0e7c40f1d00d1a8a06a4d0caaf9ac82ebfddd1b9c2a95669fa398bea07f6b0fe",
"30f1154a734ac5f21739734372f9451a030a20438d1725b2783c4daa2ef21294",
"4bf1ce171e38f093f2d07f4d1a83baba4414c462965cb60f0e97244a313e4856",
"df8c3b1303768228a4c1b6c1de4c79cfa2707c4106caf2a1a835a408957f7933",
"83fdd907a6b140799db2273bb202b99f13d694eaa3e293c6f986ab0cbb361225",
"38d880384ae3c8b1b089d313c856bf44e191c8672ac013339b596c480c46d139",
"def867e1addea0f90fd05f70f0a9d5334cbe93220fa51aa55d1c31763c0ed405",
"77fa185541de5a8ab447bc2f07b0a45d837a5c70d58513e660c10f1a1912ea27",
"767fdbb848134df57a53797937d2907ed3ba982e4af2633600b98a72b57753e4",
"9305c5ad36ead27357ea79341e1d658ff5fec614a214d34a15c3b3646cbbe5d2",
"e37adcb101c6a28166a295fc73f89e302e42d97ebb18b6ba8479c4afbe458107",
"da1b434b1d28af821053537fd0dd0316873dcd49e11c316e720ab057ff935adb",
"022a3db00bc87ff06ca55daed11a7d6e599089135618623f6d37bb022cffc4ed",
"57213663295b40b533afd22dca6db10be729b3f12da4d62fc1c2974d4faf9256",
"fb79b621e14839ec360a7bfe35b7cbfad24126ba7bff0c6054bb8296ef6bed0d",
"18cdcc48d9bbcb4e0d60b797d9925446a36cd740540e96a467141423f602ae2e",
"75576b37776044a0be1a846d400b91b1b8976934eff755a5a872dfb368ab894a",
"5acde0c5a4eb72ff1df47b6d38d62afd70646fab5796da9ccc7cd89ef737d35c",
"f2037e7f28828129fd742374af0358a54fb6294653ceefa5844befed49b8d8b2",
"4ba8797a92c0fb372860afc01931abc7d021ca84ee3118eed7346f6b79e2e0df",
"9a8b40faf8807fba154a83c6326634efc649eb5ea6926b7f6a87639b8116583b",
"707d8053b4aa6b8b3ee71e756f4e54d7b36ebcfca8f8d291074351b435576498",
"6978c68acaf92dde12d58e7a13424ed4e99bf4aa8966502820ee07de01b729e4",
"fc6e695122ee8f74070f240702b382ada98c8ad0e2cd5896eb6d35399150de74",
"e6fa52ee430771aa6a8c510bebd9a9667f7bd46db8feae61f6f43d3ad759bc4e",
"4a1b2236fde8cd589b62cddc662ca0dcda5076a8d2b7f3d25fe8179b406240d6",
"aeb8cca502e5b3dbc9e783448b29f89a444251638fa2121d21992ef09457faa8",
"de9adc0f2a3e168424fa34bcd6e9f9176ea58a9ee701706145f0e8fc47bb4f61",
"62e7610e8dd92a9a03cc2010585a9c5fe5bb1a8304542ec4312733c99d2e6a42",
"3cf5edea35404765dc90fcfb19cc35fe1676a8faae565d5bc7e5710e52bfcb30",
"6bc72e005cb02a424191d41d51acd9706ada49e051e625fd05dafd0d96375ae5",
"ce5c311ac8510ccc52580d59e81cae95821cb37a7df7e6ea88fde19a17981ab9",
"796542710cd615fb9f4105a606f15bd41150cb2b7d025f3ef0de7cbc84b9c755",
"60e54a63fb4758aad8964b099fad661fb447f089c725846a5020060271a40f14",
"3e49d3fbe59b557bb3e4df2dfd490720d44cad88060e8cdd133f42c0d89fa05a",
"9e0ff14553e2fd21785e223847219861c4714d902aa2f512d43e25361cdc2802",
"31700c61333c2cdcef7408c1045369a234093d3daa3626fe2e1ab5c0c21f494d",
"884057021b82cc1d9b7a5d5f7bc7c8c5ae3e89544e4d25492c083f2200a7c5b7",
"ea52b1beb9332cfebdd59fe8bd660bd972de19b7b2a9bbce519d917f9c3c4f63",
"2d27942e9ac8e410bf508e58f636ea95e33fc7353ad896d83d02849ce5fe324b",
"95d059c1acaf0ae53ac9cdc93e230bae1e87da83fa62c4e86871fbc8a8a47958",
"8ea83c5f5507bd8f36ab3d713ff87a5bb44151879ff32e688f770814101f18bf",
"bd1d2bcab925b0c89ec0e877fb91e28eb5ecb0fa7f59842789d080f105021427",
"fa96462f5777387f87cf033fb0497f14f8de32a95669c093417f22714df00404",
"9ea66edd2278bcbab0ebab01354a1e021da733abeaad6c5911f2874d499f79ec",
"52fd8c6c34314b95a6871efcea33ee5272cf2aede25fb2f6de869c4eced6f133",
"3371b207d2906e823e2f4ab63aa0fbe9cd5160660ddad016dc8be989bef89b44",
"61afa0253494abd7b19de355c5e290cc715dcdae039fedff6ef047855c723b84",
"03c7898532c0a7dcb39499221dc384b813b2f63be0cdc773bd82a1cfcb2da9d2",
"4b1dfa2ee5418a3ff42693ffb81f6ecfd78c708ee455eafab398a76c46a34ede",
"a31062301edb3584db0c6afb5f9af004323f0133e2d4b7dd7c59078da21768e0",
"c548b78e6a334068e79a38eef770cd161048f58ddd48e181b51daf9744036701",
"fed274fb9c4176c609853ecb4867593078ee02999925d43d8a19bd019bb90d22",
"bcf4b66610858eaf4a688570e5a7b1149674eb99d8474c17b4487b0af44d05f1",
"93c1518f309a273999b702af25fa80f0dc4fe60b0c71a2680805c48e878f79a0",
"b6b037e1d21a23ac85a6f634678a10f13d04b55ff47ceb2bdbaead241bcf79c1",
"9f385adcb2ec19ab7814f4bc47be00d0e6fb05c1784b4f10e03081324703940e",
"3cc18b7d2e2b35f1fbb169f275038892172c17997dfa9934975f137faa9a62d1",
"48b0b27d4452ab0ba06423f857fec8a63816ffea0434a36c3e9be2eebda2d6c6",
"0e34b7fda01524d30e87dced60b46357cd4feae2961fd8096116927ccc95465f",
"b85ce80626fcb1bb435ac0483a89ea15426104f7f4a19853e11db12d505b1c63",
"0b013b5be0ba9ab46c4403e47d940ab91d946eef5315a975a59ab810cefa6df4",
"ba45f7defca875de8206cdc757ab8f2d185b202c16f4cbc22174e22e93492b88",
"a9c109c54d3c8669282a4500f7bca8568255e27541607f043624da09101d7205",
"1df005012f27fe9fe198be360b4cf8e3fc302cdff404ed359b01748f8c63e8d9"
];        
     return true;   
    }
}