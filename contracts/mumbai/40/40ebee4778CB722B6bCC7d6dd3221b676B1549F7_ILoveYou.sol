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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import 'base64-sol/base64.sol';

contract ILoveYou is Ownable, ERC721Enumerable {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdTracker;

	// Truth:
	string public constant message = unicode"Immature love says: ‘I love you because I need you.’ Mature love says: ‘I need you because I love you.' —Erich Fromm";

	bool public released = false;
	uint public priceToSaveTheLove = 0.05 ether;

	mapping(bytes8 => string) svg;
	mapping(bytes8 => string) metaData;
	bytes8[] firstLoveSVG;
	bytes8[] hologramLoveSVG;

	uint public safePossessionTime = 60 * 24 * 3; // thee days in seconds
	
	// timestamp (block.time) when the current token was being owned 
	uint public ownershipStarted;

	
	constructor() ERC721('I love you', 'ILOVEYOU') {
		svg[
			'head'
		] = "<svg version='1.1' id='Layer_1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' viewBox='0 0 346 346' style='enable-background:new 0 0 346 346;' xml:space='preserve'>";
		svg[
			'style_o'
		] = "<style type='text/css'> @font-face { font-family: 'COMPUTER Robot'; font-weight: normal; src: url(data:application/font-woff2;charset=utf-8;base64,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) format('woff2'); } .st0{fill:#FF0000;} .st1{fill:#FFFFFF;} .st2{fill:#020000;} .st3{font-family:'COMPUTER Robot';} .st4{font-size:35px;} </style>";
		svg[
			'style_h'
		] = "<style type='text/css'> @font-face { font-family: 'COMPUTER Robot'; font-weight: normal; src: url(data:application/font-woff2;charset=utf-8;base64,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) format('woff2'); } .st0{fill:#DEA1CC;} .st1{fill:#FFFFFF;} .st2{fill:#AD1380;} .st3{font-family:'COMPUTER Robot';} .st4{font-size:35px;} </style>";
		svg[
			'part1'
		] = "<g id='back_00000011016698134591472900000003843687749160118194_'><path id='overlay_00000004542064449564145510000015842186980723492251_' class='st0' d='M0,0h346v346H0V0z'/></g>";
		svg[
			'part2'
		] = "<path class='st1' d='M10.8,197c5.7,7.1,8.4,3.8,13.6,1.5c7.1-3.1,4.4,6.2,4.4,6.2s7.3,5.4,0.2,9.3c-7.1,3.8-8.2-11.3-16-9.4 c-7.8,1.9-11.6,8.3-9.3,18.5s11.8,16.1,19.1,15.9c14.7-0.4,22.2-19.4,29.7-6.4c2,3.5-2.6,7.6-2.6,7.6s9.2,4.7,3.3,10.1 c-8.7,7.9-10.9-5.4-17.9-7.1c-6.9-1.7-30.4,1.8-28.6,12.9c1.8,11.1,20.1,17.5,37,13.6c9.7-2.2,19.3-9.6,21.9-2.2 c2.1,5.9-4,6.1-4,6.1s10.1,7.3,5.1,13.1c-9.4,10.9-14.2-11.5-26.8-13.2s-32.2,5.8-35,12.7c-2.8,6.9-2.9,20.4,6.2,22.5 c9.2,2.1,17.9,2,22.5-6.2c4.7-8.4,9.9-8.3,11.6-3.8c1.7,4.5-2.8,6.6-2.8,6.6s10.2-0.2,6.2,8.3s-18.7-0.5-24.2-0.3 s-17.7,2.1-17.3,11.1c0.3,9-0.9,20.9,16.6,16.8s37.1-2.3,37.1-2.3c7.6,0,26.4,10.9,26.4-6.6s-11.2-9.9-18.7-20.1 c-8.2-11.3-0.3-16.6,5.9-17.3c5.4-0.6,8.5,5.2,8.5,5.2s4.7-10,12.1-6.6c7.4,3.5,4.7,9.3-0.2,15.6c-4.8,6.2-5.9,16.6-4,24.9 s7.9,5.9,16.1,6.1c8.1,0.2,14.9,6,17.2-2.8c2.2-8.8-0.2-10.6-6.6-13.3c-6.4-2.8-12.5-8.3-7.4-13c5-4.7,9.9,2.1,9.9,2.1 s4.5-11.4,12.3-9.3s4.3,8-0.2,15.6s-4.1,15.5,3.7,20.2c5.2,3.1,24.4,3.9,28.9-2.4s5.9-7.8-1.2-14.3c-7.1-6.6-13-11.4-6.7-17.7 c6.3-6.3,13.3,2.8,13.3,2.8s7.1-10,13.5-4.5s2.9,13.2-3.3,19.2c-6.2,6.1-8.8,7.6-5.4,15.7c3.5,8.1,17.7,6.9,24.6,3.6 c6.9-3.3,19.6,2.9,26.6-6.9c7.1-9.9,8.8-19.2,1.7-28s-13.7-18.2-6.9-22.3c6.8-4.1,9.9,2.9,9.9,2.9s6.6-11.4,13-4.8s0,11.2-4,17.1 s-3.3,20.6,0.9,28s9.9,11.4,22.3,12.3c12.5,0.9,14-14,12.5-23.4c-1.6-9.3-5.2-18.7-10.6-23.7s-8.1-14.4-3.1-17.1 c5-2.8,14.4,9.3,14.4,9.3s7.3-8.5,13.3-1.4s-8.1,17.7-9.3,28.2c-1.2,10.6-0.7,19.9,4,24.2c4.7,4.3,22.2,5.2,24.1,0 s1.7-10.6-4.2-17.7c-5.9-7.1-6.4-12.3-2.9-14s7.8,3.6,7.8,3.6s5.4-7.8,9.3-2.2c4,5.5-0.7,13.5-3.6,18.9s-4,10.7-1.7,13.8 c2.2,3.1,17.6,5.3,22.7-1.9c6.3-9-1.7-17-4.6-21.2s7.8-4.2,11.4-13s-3.9-32.7-11.4-34.3s-14.5,5.2-20.2,13.5s-12.2,1.8-13-1.3 c-0.8-3.1,2.6-6.5,2.6-6.5s-8-7-0.8-14.8c7.3-7.8,11.2-1.6,15.6,1.8s12.5,6.7,17.9,2.1s3.5-24.5,3.4-28.5c-0.2-4-1.7-10.4-6.6-9.3 c-4.9,1.1-6.6,2.8-8.7,6.9c-2.1,4.2-10.6,3.3-11.2-1.2s3.8-6.2,3.8-6.2s-9-2.6-5.5-8.1s7.3-3.5,13-0.2s11.4,4,14-5.7 s9.1-36.3-0.5-52.3c-7.9-13.2-0.3-25.1-6.4-23.5s-6.9,10.9-11.9,9.7s-0.9-9.7-0.9-9.7s-5.2-4.7,0.2-8.8c5.4-4.2,6.7,5.9,12.3,4.7 c5.5-1.2,6.2-8,6.4-14.4c0.2-6.4,0-15.4-6.9-13S317,115.9,310,116.4c-6.9,0.5-3.1-11.2-3.1-11.2s-7.4-4.7-4.2-12.3 c3.2-7.6,14.9-0.3,18.3,2.8c3.5,3.1,10.2,5.9,12.5-1c2.2-6.9,4.2-35-3.3-36.9s-8.5,12.6-18,14s2.7-14.5,2.7-14.5s-10.5-4.6-7.5-9.8 s11.3,6,16.7,4.9c13.6-2.9,16.7-29.1,0.3-42.1s-33.4-2.6-34.3,7.6s5.7,15.1,9,21.1c3.3,6.1,0.9,13-4.2,13.3c-5,0.3-8.6-5.1-8.6-5.1 s-4.9,10.5-11.3,5s2.1-17.1,7.4-27.3c5.4-10.2-1-21.1-15.9-20.1s-20.9,5.4-20.1,12.1c0.8,6.7,7.2,11.1,11.4,16.6 c4.1,5.4,1.9,12.5-2.4,13s-7.4-7.3-7.4-7.3s-3.1,9-8.1,5.9s-0.5-13,3.3-19.2s0-23.9-12.8-24.4s-16.8,12.8-15.2,21.6 s11.7,10.4,12.8,18.7c1.2,8.8-3.8,10.8-8.8,10.4c-4.7-0.4-7.1-6.2-7.1-6.2s-6.9,12.3-12.3,8.3s-3.5-10.9,3.6-17.5s7.1-15.7,5.4-21.6 C206.6,9.4,191.5,2.8,178,3.5s-26.3,5.4-26.1,16.8s10.9,18,13.8,24.4c2.9,6.4,0.5,11.8-4,13.3s-8.8-2.2-8.8-2.2s-2.2,10-10.6,10 c-8.3,0-5.7-14.2-0.9-25.3S155.7,3.8,128.2,4c-27.5,0.2-24.7,19.3-20.6,28.3c4.2,9,11.7,14.6,8.4,19c-7.1,9.3-13.4-4.1-13.4-4.1 s-1.2,12.5-10.9,6.4s4.6-13.6,8.9-23.3S99.3,3,83.7,2.3s-12.6,11.9-4.8,17.2c7.8,5.4,12.3,16.3,7.3,19.7s-13.2-4-13.2-4 s-4.5,10.9-11.4,6.9S58.4,28.4,64,22.5c5.5-5.9,7.4-11.9,1.2-16.3C58.9,1.9,6.3-3.1,5.8,12.3s10.7,17.5,18.7,10.2s15.9-9.3,18.2-4.5 c2.2,4.8-8.1,6.6-8.1,6.6s11.9,2.4,7.3,7.8c-4.7,5.4-12.8-8.8-23.5-3.6S0.1,50.4,19.3,54.4s22-1,26.6-4.3s13.5-6.7,14.9,0 S56.5,57,56.5,57s7.8-1.2,8.1,4.7s-10.9,9.5-19.4,4.7S14,54.9,8.2,75.9c-5.5,19.8-5.5,45.8-1.5,48.8s7,0,12-4s10,2,7,5s-5,3-5,3 s9,4,4,7s-6-6-10-6s-11-3-8,15S2.7,188.7,10.8,197z'/>";
		svg[
			'part3'
		] = "<g> <path class='st0' d='M310.6,145.6c0,101.7-139.5,154-139.5,154s-139.5-52.3-139.5-154c0-43.4,33.7-78.4,75.3-78.4 c27.1,0,50.9,14.9,64.2,37.3c13.3-22.4,37-37.3,64.2-37.3C276.9,67.1,310.6,102.2,310.6,145.6z'/> </g>";
		svg[
			'part4'
		] = "<circle class='st1' cx='92.9' cy='104.1' r='4.3'/> <circle class='st1' cx='294.9' cy='138.5' r='4.3'/> <circle class='st1' cx='116.4' cy='255.5' r='4.3'/> <circle class='st1' cx='144.4' cy='273.4' r='4.3'/> <circle class='st1' cx='242.7' cy='82.1' r='4.3'/> <circle class='st1' cx='218.7' cy='84.8' r='4.3'/> <circle class='st1' cx='197.8' cy='97' r='4.3'/> <circle class='st1' cx='182.1' cy='116.1' r='4.3'/> <circle class='st1' cx='270.6' cy='92.5' r='4.3'/> <circle class='st1' cx='288.2' cy='110.7' r='4.3'/> <ellipse class='st1' cx='94.1' cy='240.5' rx='4.3' ry='4.3'/> <circle class='st1' cx='228.7' cy='255.5' r='4.3'/> <circle class='st1' cx='200.6' cy='273.4' r='4.3'/> <circle class='st1' cx='173.1' cy='283.5' r='4.3'/> <circle class='st0' cx='29.5' cy='78.4' r='4.3'/> <circle class='st0' cx='13.8' cy='102.1' r='4.3'/> <circle class='st0' cx='30.7' cy='96.8' r='4.3'/> <circle class='st0' cx='173.8' cy='79.9' r='4.3'/> <circle class='st0' cx='22.4' cy='181.3' r='4.3'/> <circle class='st0' cx='63.3' cy='323.8' r='4.3'/> <circle class='st0' cx='23.5' cy='328.7' r='4.3'/> <circle class='st0' cx='200.6' cy='306' r='4.3'/> <circle class='st0' cx='192.2' cy='327.6' r='4.3'/> <circle class='st0' cx='215.9' cy='322.7' r='4.3'/> <circle class='st0' cx='295.3' cy='243.9' r='4.3'/> <circle class='st0' cx='327.2' cy='177.6' r='4.3'/> <circle class='st0' cx='292.8' cy='69.7' r='4.3'/> <circle class='st0' cx='269.3' cy='56.4' r='4.3'/> <circle class='st0' cx='179.4' cy='42.1' r='4.3'/> <circle class='st0' cx='190.9' cy='27.5' r='4.3'/> <circle class='st0' cx='327.5' cy='302.1' r='4.3'/> <circle class='st1' cx='172.2' cy='136.7' r='4.3'/> <circle class='st1' cx='155.6' cy='154.9' r='4.3'/> <circle class='st1' cx='131.1' cy='159.4' r='4.3'/> <circle class='st1' cx='108' cy='149.1' r='4.3'/>";
		svg[
			'part5'
		] = "<path class='st2' d='M95.2,82.4v13h-4.4c-3.3,0-5.4,0.4-6.3,1.3c-0.8,0.8-1.5,2.9-1.5,6.5v49.7c0,3.6,0.4,5.6,1.5,6.5 c1,0.8,2.9,1.3,6.3,1.3h4.4v13H40.9v-13h4.6c3.1,0,5.2-0.4,6.3-1.3c1-0.8,1.5-3.1,1.5-6.5v-49.7c0-3.6-0.4-5.6-1.5-6.5 c-0.8-0.8-2.9-1.3-6.3-1.3h-4.6v-13C40.9,82.4,95.2,82.4,95.2,82.4z'/> <circle class='st1' cx='95.1' cy='128.3' r='4.3'/> <circle class='st0' cx='69.2' cy='251.2' r='4.3'/> <path class='st2' d='M179.6,199.3c0-0.1,0.1-0.4,0.3-0.7c0.1-0.6,0.3-0.8,0.3-1c0-0.8-0.4-1.4-1.1-1.7c-0.7-0.3-2.3-0.6-4.4-0.6 v-7.9h21.7v7.9c-1.8,0-3.3,0.3-4.2,1c-1,0.7-2,2-2.7,3.8l-13.6,33.3c-2.1,5.2-4.8,9.2-8.2,11.9s-7.2,3.8-11.6,3.8 c-4.4,0-7.9-1.1-10.5-3.1c-2.7-2.1-3.8-5-3.8-8.5c0-2.5,0.8-4.5,2.5-6.2s3.7-2.4,6.4-2.4c2.3,0,4.1,0.6,5.5,1.8 c1.4,1.3,2.1,2.7,2.1,4.7c0,1.7-0.4,3-1.4,4.1s-2.4,1.8-4.2,2.3c0.4,0.6,1,1,1.6,1.1c0.6,0.3,1.1,0.4,1.8,0.4c1.8,0,3.4-0.7,5.1-2.3 c1.7-1.6,3.1-3.7,4.4-6.5l-14-32.1l-0.3-0.6c-1.8-4.1-3.7-6.2-5.8-6.2h-1.7v-7.8h27.6v7.9c-1.8,0-2.8,0.1-3.3,0.4 c-0.4,0.3-0.6,0.7-0.6,1.3c0,0.4,0.1,1,0.4,1.7c0.1,0.1,0.1,0.4,0.3,0.6l6.1,14.9L179.6,199.3z'/> <path class='st2' d='M219.3,185.9c8.1,0,14.3,2.1,19,6.1c4.7,4.1,6.9,9.6,6.9,16.7c0,7.1-2.4,12.6-6.9,16.6s-10.9,6.1-19,6.1 s-14.3-2.1-19-6.1c-4.5-4-6.8-9.5-6.8-16.7c0-7.1,2.3-12.7,6.8-16.7C205,187.8,211.2,185.9,219.3,185.9z M226,208.7 c0-5.5-0.6-9.2-1.6-11.3s-2.7-3.1-5.2-3.1c-2.4,0-4.1,1.1-5.1,3.1c-1,2.1-1.6,5.9-1.6,11.3c0,5.5,0.6,9.2,1.6,11.3s2.7,3.1,5.2,3.1 c2.4,0,4.1-1,5.1-3C225.5,217.9,226,214.2,226,208.7z'/> <path class='st2' d='M280.9,223.7c-2,2.5-4.2,4.4-6.9,5.8c-2.7,1.4-5.7,2-8.8,2c-5.4,0-9.2-1.1-11.5-3.4c-2.3-2.4-3.3-6.4-3.3-12.3 v-16.1c0-1.8-0.3-2.8-0.8-3.4c-0.6-0.6-1.7-0.8-3.4-0.8h-1.4v-7.9h23.4v27.5c0,2.5,0.4,4.2,1.4,5.5s2.4,1.8,4.2,1.8 c2.1,0,3.7-0.8,4.8-2.4c1.1-1.6,1.8-3.5,1.8-6.4v-13.9c0-1.8-0.3-2.8-0.8-3.4c-0.6-0.6-1.7-0.8-3.3-0.8h-1.8v-7.9h23.6v30.3 c0,1.7,0.3,2.8,0.8,3.4c0.6,0.6,1.7,0.8,3.3,0.8h2v7.9h-23.4L280.9,223.7L280.9,223.7z'/>";
		svg[
			'text_a'
		] = "<g id='text'><text transform='matrix(1 0 0 1 170.3923 180.3399)' class='st2 st3 st4'>#";
		svg[
			'text_b'
		] = "</text></g></svg> ";

		firstLoveSVG = [
			bytes8('head'),
			bytes8('style_o'),
			bytes8('part1'),
			bytes8('part2'),
			bytes8('part3'),
			bytes8('part4'),
			bytes8('part5'),
			bytes8('text_a'),
			bytes8('token_id'),
			bytes8('text_b')
		];

		hologramLoveSVG = [
			bytes8('head'),
			bytes8('style_h'),
			bytes8('part1'),
			bytes8('part2'),
			bytes8('part3'),
			bytes8('part4'),
			bytes8('part5'),
			bytes8('text_a'),
			bytes8('token_id'),
			bytes8('text_b')
		];

		metaData[
			'baseDesc'
		] = "The First Love is eternal.";
		metaData[
			'holoDesc'
		] = "I've left this beautiful Hologram of myself as a memento of our special time together. Joining my cult was the best decision you ever made. You can never leave. With Love.";
		metaData['ext_url'] = "https://iloveyounft.com/";
		
		// mint the first to the creator
		mint(msg.sender);
	}

	// Management funcptions

	// withdraw contract balance
	function getPaid() public payable onlyOwner {
		require(payable(_msgSender()).send(address(this).balance));
	}

	function setReleased(bool yes) external onlyOwner {
		released = yes;
	}

	function setPriceToSaveTheLove(uint _newPrice) external onlyOwner {
		priceToSaveTheLove = _newPrice;
	}

	// Main functions

	// This is the main transfer function
	function spreadTheLove(address to) public {
		transferOverride(msg.sender, to, 0);
	}

	// If the token got stuck on an address for more than three days
	// we'd like to give a chance to people to save the love
	// By calling this method you'll be the owner of the #0 token and you can continue to spead the message
	function saveTheLove() public payable {
		require(msg.sender == owner() || msg.value >= priceToSaveTheLove,'Do not be cheap');
		require((ownershipStarted + safePossessionTime) <= block.timestamp, 'Sorry my love, you need to wait for three days');

		address from = ownerOf(0);
		_transfer(from, msg.sender, 0);
		mint(from);
		ownershipStarted = block.timestamp;
	}


	//
	// transferring
	//
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override(ERC721, IERC721) {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override(ERC721, IERC721) {
		transferOverride(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public override(ERC721, IERC721) {
		transferOverride(from, to, tokenId, _data);
	}

	function transferOverride(
		address from,
		address to,
		uint256 tokenId
	) internal {
		transferOverride(from, to, tokenId, '');
	}

	function transferOverride(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		transfer(from, to, tokenId, _data);
		mint(from);
		ownershipStarted = block.timestamp;
	}

	// internal transfer
	function transfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		require( to != address(0), 'You can not burn me');
		require(tokenId == 0, 'Only the original can be transferred');
		require( balanceOf(to) == 0, 'The recipient already had the original' );
		require(released == true, 'Sorry my Love, transfer is not allowed');

		require(
			// We overrode safeTransferFrom
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

		_safeTransfer(from, to, tokenId, _data);
	}

	// internal minting
	function mint(address to) internal {
		// mint one
		uint newTokenId = _tokenIdTracker.current();
		_safeMint(to, newTokenId);
		// incrementing AFTER because counting starts at 0
		_tokenIdTracker.increment();
	}

	function join(string memory _a, string memory _b) internal pure returns (string memory result)
	{
		result = string(abi.encodePacked(bytes(_a), bytes(_b)));
	}
	
	function getMeta(uint256 _tokenId) public view returns (string memory) {
		string memory name;
		string memory desc;

		string memory image = Base64.encode(bytes(getArt(_tokenId)));

		if (_tokenId == 0) {
			name = 'ILoveYou';
			desc = metaData['baseDesc'];
		} else {
			name = join('ILoveYou Hologram #', _tokenId.toString());
			desc = metaData['holoDesc'];
		}

		return string(abi.encodePacked(
			'data:application/json;base64,',
			Base64.encode(
				bytes(abi.encodePacked(
					'{',
						'"name": "', name, '",',
						'"description": "', desc, '",',
						'"image": "data:image/svg+xml;base64,', image, '",',
						'"external_url": "', metaData['ext_url'], _tokenId.toString(), '"',
					'}'
				))
			)
		));
	}

	function getArt(uint256 _tokenId) public view returns (string memory) {
		string memory acc;
		bytes8[] memory layers;

		if (_tokenId == 0) {
			layers = firstLoveSVG;
		} else {
			layers = hologramLoveSVG;
		}

		for (uint i = 0; i < layers.length; i++) {
			if (layers[i] == bytes8('token_id')) {
				acc = join(acc, _tokenId.toString());
			} else {
				acc = join(acc, svg[layers[i]]);
			}
		}

		return acc;
	}

	//
	// Displaying
	//
	function tokenURI(uint256 _tokenId) public view override returns (string memory)
	{
		return getMeta(_tokenId);
	}

	// accept all the love sent to this contract
	receive() external payable {}
}