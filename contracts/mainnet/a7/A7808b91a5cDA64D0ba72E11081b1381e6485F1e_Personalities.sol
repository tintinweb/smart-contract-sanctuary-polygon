// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract Personalities is ERC721Enumerable, ReentrancyGuard, Ownable {
    string[] private eyes = [
        '<g stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M37.217 32.006s0 0 0 0" stroke="#fff"/><path d="M30.539 41.314c-5.15.24-8.278-3.963-9.198-6.094 5.616-5.094 14.147-2.262 17.71-.21-.692 2.002-3.363 6.064-8.512 6.304Z" stroke="#000"/><path d="M28.597 37.199c.796.528 2.703 1.107 3.97-.802 1.585-2.386-2.392-5.026-3.66-3.806-1.015.976-.56 2.455-.206 3.072M90.713 35.175c.932-.399 2.556-1.754 1.6-3.99-1.195-2.794-5.853-.803-5.508 1.033.275 1.469 1.852 1.926 2.605 1.971" stroke="#000"/><path d="M90.666 38.819c-5.023 1.16-9.054-2.8-9.754-5.507 4.613-6.018 15.027-3.5 17.547-1.307-.321 2.093-2.77 5.655-7.793 6.814ZM17.259 20.91c5.555-1.038 18.38-1.45 25.248 5.197M75.585 25.663c3.35-5.32 14.235-11.166 22.051-7.537" stroke="#000"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M25.508 18.188c1.685-1.252 6.125-2.587 11.267-1.878 4.493.62 6.435 2.245 7.736 4.267M72.914 20.047c2.16-2.8 5.933-3.351 8.298-3.483 2.365-.132 5.04 0 7.165.683M4 20.632l13.684 8.495M48.232 32.957c5.142-3.297 17.622-3.304 20.454-1.835M96.88 28.803c2.544-1.323 10.581-8.782 13.124-10.613M18.146 29.718c-.34 3.702-.418 13.116 4.334 16.62 4.76 3.51 23.542-.341 25.255-.947 1.617-.573 1.665-7.8-.894-14.373-2.15-5.522-20.502-3.698-28.098-2.34"/><path d="M70.486 27.953c5.988-2.674 21.938-.9 24.97 0 3.79 1.126 4.147 10.342 3.802 13.717-.344 3.376-20.459 3.436-25.11 3.249-3.721-.15-4.915-11.643-4.053-16.518M33.43 32.3c-.401.247-1.13.963-.834 1.853.37 1.111 3.428 2.501 3.52.833.094-1.667-.462-2.316-1.203-1.575"/><path d="M81.613 31.205c-.617.556-1.668 1.797-.926 2.316.926.648 4.169 2.316 3.89 0-.222-1.853-1.08-1.699-1.482-1.39l-.833.741"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 12.257c1.685-1.252 6.125-2.587 11.267-1.878 4.493.619 6.435 2.244 7.736 4.266M72.868 14.15c2.02-2.903 5.76-3.64 8.115-3.89 2.355-.249 5.035-.25 7.19.328M4 21.169l13.684 6.495M48.232 31.494c5.142-3.297 17.622-3.304 20.454-1.835M96.88 27.34c2.544-1.323 10.581-6.782 13.124-8.613M24.635 49.885c-5.031-3.088-10.578-15.72-5.891-22.67 5.245-7.779 23.806-8.685 28.097 2.34 2.56 6.574 1.531 12.78.894 14.373-1.796 4.488-10.253 13.84-23.1 5.957ZM95.457 26.49c-5.54-7.954-20.979-8.26-25.362.448-1.854 3.686-3.08 14.193 4.383 20.122 3.864 3.07 17.975 8.25 22.817-5.174 2.249-6.237.422-12.151-1.838-15.396Z"/><path d="M34.424 29.788c-.402.247-1.13.964-.834 1.853.37 1.112 3.427 2.501 3.52.834.093-1.668-.463-2.316-1.204-1.575M80.98 27.664c-.617.556-1.668 1.797-.926 2.316.927.648 4.169 2.316 3.89 0-.221-1.853-1.08-1.698-1.481-1.39l-.834.741"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M26.833 19.11c1.286 1.158 4.672 2.392 8.595 1.737 3.428-.573 4.91-2.075 5.901-3.945M70.075 16.14c1.998 2.588 5.331 3.394 7.518 3.516 2.186.122 5.021-.772 7.184-1.931M4 20.484l13.684 8.495M48.232 32.81c5.142-3.299 17.622-3.305 20.454-1.837M96.88 28.655c2.544-1.323 10.581-7.782 13.124-9.613"/><path d="M22.564 45.956c-8.29-3.093-7.59-11.34-3.649-17.136 3.046-3.805 22.755-2.179 27.158 1.787 4.207 3.789 2.358 11.778-1.798 14.272-3.372 2.023-16.17 3.145-21.711 1.077ZM94.396 26.673c-3.606-1.126-18.195-1.052-23.903 2.613-3.86 2.478-6.58 14.713 3.514 16.066 4.614.619 14.882-.084 18.703-1.882 8.2-3.859 6.743-15.217 1.686-16.797Z"/><path d="M29.674 35.308c1.02-1.947 3.19-2.642 4.127-2.642 3.105 0 3.987 1.339 4.687 2.172M77.929 35.308c1.02-1.947 3.19-2.642 4.127-2.642 3.105 0 3.987 1.339 4.687 2.172"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M33.046 35.608c-1.817-1.754.438-4.382 2.423-3.389 2.482 1.241 3.41 4.32 1.239 6.491-2.171 2.172-7.167.782-7.477-4.492-.31-5.275 6.46-9.173 9.872-2.968 3.413 6.205 2.323 11.804-5.148 11.804-5.088 0-7.3-3.526-7.813-6.898-1.03-6.753 2.409-13.665 9.69-11.992 4.483 1.03 9.653 3.956 8.722 13.264-.93 9.307-5.932 10.236-12.293 9.146-7.666-1.314-9.752-8.177-7.268-15.93M78.465 35.608c-1.817-1.754.438-4.382 2.423-3.389 2.481 1.241 3.41 4.32 1.239 6.491-2.171 2.172-7.167.782-7.477-4.492-.31-5.275 6.46-9.173 9.872-2.968 3.413 6.205 2.323 11.804-5.148 11.804-5.088 0-7.3-3.526-7.813-6.898-1.03-6.753 2.409-13.665 9.69-11.992 4.483 1.03 9.653 3.956 8.722 13.264-.93 9.307-5.932 10.236-12.293 9.146-7.666-1.314-9.752-8.177-7.268-15.93M29.773 15.88c3.085 2.178 8.839 2.639 12.115 1M72.204 16.791c3.613 1.103 9.221-.26 11.82-2.84"/></g>',
        '<g stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M35.343 28.88c-2.382.126-7.346 1.43-8.148 5.64-1.003 5.265 2.131 7.396 3.26 7.897 1.127.502 8.272 1.88 9.149-3.008.877-4.888-1.504-8.273-2.883-8.9-1.378-.626-5.64 1.63-6.267 4.012-.627 2.381-2.632 3.384 0 4.888s4.512 3.51 6.267.501c1.755-3.008 1.379-6.643 0-6.893-1.378-.251-4.512.626-4.512 2.506s.376 4.889 1.378 3.886c.803-.802 1.505-2.925 1.755-3.886M84.526 26.953c-2.382.126-7.345 1.43-8.147 5.64-1.003 5.265 2.13 7.396 3.259 7.897 1.128.502 8.272 1.88 9.15-3.008.877-4.888-1.505-8.273-2.883-8.9-1.379-.626-5.64 1.63-6.267 4.012-.627 2.381-2.632 3.384 0 4.888s4.512 3.51 6.267.501c1.754-3.008 1.378-6.643 0-6.893-1.379-.251-4.513.626-4.513 2.506s.376 4.889 1.38 3.886c.801-.802 1.503-2.925 1.754-3.886" stroke="#000"/><path d="M85.38 37.335s0 0 0 0M32.167 34.618c-.39.078-1.209.178-.936.859.273.68 1.327.529 1.58 0 .254-.529-.253-1.717-.253-1.717M81.35 32.691c-.39.078-1.208.178-.936.859.273.68 1.327.529 1.58 0 .254-.529-.253-1.717-.253-1.717" stroke="#fff"/><path d="M27.505 21.785c1.071-1.26 3.781-3.403 6.05-1.89M77.934 17.968c1.071-1.261 4.276-1.32 4.806 0" stroke="#000"/></g>',
        '<g stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20.42 39.818c2.168-3.167 9-8.4 19-4" stroke="#000"/><path d="M28.92 35.318c-1 .5-2.7 2.1-1.5 4.5 1.5 3 6.5.5 6-1.5-.4-1.6-2.166-2-3-2M16.99 24.619c4.828-1.675 16.183-3.573 22.976 2.233M71.4 24.619c4.829-1.675 16.184-3.573 22.977 2.233" stroke="#000"/><path d="M67.944 28.07c6.41-.85 24.343 1.538 27.055 3.166 2.96 1.776 3.452 15.124 1.17 21.6-1.129 3.2-13.275 6.681-23.796 0-7.518-4.774-5.832-18.864-4.97-23.74" stroke="#F24E1E"/><path d="M70.584 31.088c-.693 1.764-1.81 8.396-2.519 10.705l5.117-10.22c-.793 3.218-3.57 14.255-3.333 15.205.297 1.189 5.822-15.28 6.416-15.205.594.074-4.337 16.914-4.337 17.88 0 .965 5.786-17.185 6.678-17.185.89 0-4.375 17.927-3.781 18.818.594.891 5.141-17.296 5.884-18.187.743-.891-4.547 20.192-3.73 20.118.817-.074 6.164-20.944 6.907-19.013.743 1.931-5.108 21.938-3.177 20.304 1.931-1.634 5.625-21.79 7.036-20.304 1.411 1.485-4.491 20.824-3.229 20.304 1.263-.52 5.502-19.441 6.096-19.441.595 0-2.436 20.811-1.86 19.441.172-.41 4.602-18.253 4.973-19.441.372-1.189.075 3.064 0 6.926-.059 3.09-2.093 10.51-2.44 12.515l4.378-14.574c.066 2.295.108 7.524-.246 10.084-.354 2.56-.787 3.657-.959 3.886M6 3c29.494 17.714 55.633 25.247 58.601 26.027 2.969.781 27.994 4.49 32.056 2.303 3.249-1.75 11.191-14.01 12.909-15.99" stroke="#F24E1E"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M23.161 17.605c1.685.842 6.124 1.739 11.266 1.262 4.492-.416 6.434-1.508 7.734-2.867M75.161 15c2.161 1.884 5.933 2.255 8.298 2.343 2.365.09 5.04 0 7.165-.46M4 18.466l13.684 7.495M48.232 29.791c5.142-3.297 17.622-3.304 20.454-1.835M96.88 25.637c2.544-1.323 10.581-7.782 13.124-9.613M18.149 26.552c-.34 3.702-1.703 15.673-.002 17.668 2.602 3.05 27.77-.937 29.483-1.543 1.617-.573 1.99-8.774-.569-15.348-2.149-5.522-20.72-3.174-28.315-1.817"/><path d="m19.532 31.876 2.77-5.333c-.791 3.218-3.007 11.041-2.77 11.992.297 1.189 5.667-12.66 6.262-12.586.594.074-4.472 15.968-4.472 16.933 0 .966 5.957-16.933 6.848-16.933s-4.194 15.593-3.6 16.484c.594.891 5.457-16.038 6.2-16.93.742-.89-4.234 18.196-3.417 18.122.817-.074 6.165-20.944 6.907-19.013.743 1.931-4.827 21.167-2.896 19.533 1.93-1.634 5.345-21.018 6.756-19.533 1.41 1.485-3.637 20.053-2.374 19.533 1.262-.52 4.53-17.602 5.124-17.602.594 0-.891 17.082-.445 17.082.445 0 3.26-13.971 3.632-15.16.371-1.188 1.048-.45.974 3.411-.06 3.09-1.215 9.001-1.561 11.006l2.97-7.575M70.783 32.963l2.823-6.907c-.793 3.218-2.317 9.893-2.08 10.843.297 1.188 4.976-11.512 5.57-11.437.595.074-3.49 13.145-3.49 14.11 0 .966 4.976-14.11 5.867-14.11s-3.565 14.854-2.97 15.745c.594.891 4.827-15.3 5.57-16.19.742-.892-4.234 18.195-3.417 18.12.817-.074 6.164-20.943 6.907-19.012.743 1.93-5.108 20.647-3.177 19.013 1.931-1.634 5.626-20.498 7.037-19.013 1.41 1.485-3.637 20.053-2.374 19.533 1.262-.52 4.53-17.602 5.124-17.602.594 0-.891 17.082-.445 17.082.445 0 2.673-12.7 3.045-13.889.37-1.188 1.188-.594 1.114 3.268-.06 3.09-.768 7.873-1.114 9.878l2.97-7.575"/><path d="M70.485 24.788c5.988-2.674 22.187-.9 25.22 0 3.79 1.125 3.592 14.676 3.248 18.051-.345 3.376-22.066.188-26.717 0-3.721-.15-3.004-12.729-2.142-17.604"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M34.805 27.833c3.332.593 10.93-.16 14.663-7.921M65.192 15c.533 2.66 2.752 8.547 7.37 10.807 4.617 2.26 8.8 2.334 10.315 2.088M21.221 40.544c7.082-2.334 23.355-5.235 27.088-5.038M21 42.697c6.763-1.285 20.546-4.452 25.213-5.16M67.324 34.752c7.086-1.278 22.317 2.419 26.31 4.194"/><path d="M66.715 35.249c7.086-1.278 20.544 3.645 24.536 5.42"/><path d="M66.458 36.105c7.086-1.278 21.687 4.893 25.68 6.667"/><path d="M66.458 37.475c7.086-1.278 21.688 5.117 25.68 6.891M24.906 41.28c6.59-2.292 20.632-6.533 24.07-5.158M23.985 45.029c6.59-2.293 20.3-6.185 23.982-7.126"/></g>',
        '<g stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M35.524 47.974c-.725-.535-5.135-2.321-7.438-6.16-2.303-3.837-2.456-7.675 0-9.364 1.65-1.134 5.147.682 7.438 2.233M36.423 34.017c1.491-1.646 4.12-3.032 6.709-1.567 1.737.983 1.535 7.062 0 9.365-1.233 1.849-5.195 4.94-6.709 5.928M77.688 33.251c-2.2-2.098-7.123-5.373-9.211-1.688-2.61 4.605 5.577 12.974 10.188 14.886M79.776 47.006c2.251-1.689 6.97-5.373 7.83-6.602 1.074-1.535 2.763-7.983 0-10.593-2.764-2.61-8.598 1.075-8.598 5.22" stroke="#F24E1E"/><path d="M26 18.272c.637-1.42 2.937-4.14 7.05-3.671 5.139.587 6.167 1.469 7.342 3.671M72.157 16.213c.588-1.664 3.055-4.817 8.224-4.112 5.17.705 7.05 3.623 7.343 4.993" stroke="#000"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M42.82 24.089C36.434 24.293 25 27.127 25 35.427c0 12.334 9.708 14.617 13.247 14.617 2.89 0 9.136-1.598 11.42-4.11 2.284-2.513 3.198-12.563 1.599-15.76-1.082-2.165-3.135-4.885-6.985-4.885"/><path d="M30.687 32.308c-.39.078-1.21.178-.937.858.273.68 1.327.53 1.58 0 .254-.529-.253-1.717-.253-1.717M78.592 41.91c.273.681.499.53.752 0"/><path d="M80.277 30.439c-2.977.763-8.61 3.8-7.328 9.846 1.282 6.046 5.799 7.743 10.305 6.375 4.506-1.368 7.144-7.52 6.411-10.268-.916-3.435-5.712-5.954-9.388-5.031M28.697 16.703c2.14 1.59 7.996 4.292 14.306 2.385C49.313 17.18 54.19 11.568 55.842 9M78.86 14.52c-.922.992.21 4.663 2.421 5.513 2.21.85 3.636 1.501 5.868 1.501"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M30.235 23.57c2.53 1.833 7.697 5.97 8.115 7.854.42 1.885-8.725 5.322-13.35 6.806M89.396 22c-3.578 1.309-10.523 4.346-9.685 6.02 1.047 2.095 6.855 3.63 9.685 5.76"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M26.715 26.256c.904-2.448 4.142-7.291 9.866-7.074 5.725.217 8.306 3.403 8.881 4.969M71.172 24.602c.99-2.853 4.216-8.394 9.198-7.732 4.981.662 7.506 4.332 8.145 6.084M25 42.913c2.745-3.965 9.53-6.579 14.937-6.087 6.759.614 4.348 6.53 2.62 7.24-2.175.892-5.132-.83-3.288-3.288 1.475-1.966 2.847 0 2.474.814M72.607 38.611c1.741-1.74 6.452-5.161 11.368-4.916 6.145.308 7.778 3.266 5.934 5.417-1.843 2.15-4.513 2.458-4.513 0s2-2.56 2.788-.93"/></g>',
        '<g stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M21 41.866c.58-.937 2.196-2.892 4.016-3.213M25.765 45.213l2.811-4.954M32.46 41.81c0 1.129-1.157 5.37-1.157 5.37" stroke="#F24E1E"/><path d="M21.278 32.108c1.198 2.745 4.94 8.42 10.322 9.163 5.382.742 9.202-1.083 10.439-2.088" stroke="#000"/><path d="M80.815 40.26v3.882M84.416 39.42l1.52 3.627M87.777 38.385c.714.67 2.58 1.93 2.58 3.108" stroke="#F24E1E"/><path d="M72.784 35.038c1.205 1.428 4.204 4.284 6.56 4.284 2.945 0 8.166-.803 11.914-4.284M21.15 21.92c.982-1.563 4.551-4.794 10.977-5.222 6.426-.428 9.103 1.16 9.639 2.008M73.738 20.699c1.48-2.08 5.856-6.22 11.511-6.151 2.214.31 7.066 2.059 8.765 6.574" stroke="#000"/></g>',
        '<g stroke="#000" stroke-linecap="round" stroke-linejoin="round"><path d="M33.942 27.705c7.098-2.653 13.238 5.211 13.238 10.872 0 6.83-5.28 12.537-10.293 12.537-5.011 0-9.887-5.707-9.887-12.536 0-5.662 4.02-9.794 7.83-11.262M77.413 23.224c6.564-2.653 11.03 5.332 11.03 10.993 0 6.83-3.868 12.537-8.503 12.537s-9.02-4.682-9.02-12.171c0-7.489 3.594-10.16 7.117-11.627" stroke-width="3"/><path d="M40.12 40.512s0 0 0 0M81.992 38.226s0 0 0 0" stroke-width="6"/><path d="M28.229 19.251c2.78-3.127 10.059-7.817 16.938-1.563M66.192 15.104c4.343-4.169 14.437-10.37 20.065-1.824" stroke-width="3"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M22.307 39.332c2.166-3.166 9-8.4 19-4M78.067 34.953c2.79-2.634 10.579-6.296 19.416.127"/><path d="M30.807 34.832c-1 .5-2.7 2.1-1.5 4.5 1.5 3 6.5.5 6-1.5-.4-1.6-2.167-2-3-2M87.329 32.361c-1.084.277-3.085 1.479-2.422 4.08.828 3.25 6.245 1.868 6.182-.192-.051-1.649-1.693-2.415-2.507-2.592M18 25.866c5.397-1.675 18.088-3.573 25.68 2.233M75.225 28.663c3.35-5.32 14.236-11.166 22.052-7.537"/></g>'
    ];

    string[] private nose = [
        '<path d="M23.34 22.446c.638.718 2.572 5.494-5.66 6.457-6.972.816-7.094-3.746-7.094-5.34" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M15.276 18c-3.978.854-7.159 6.761-3.977 9.944 3.977 3.977 12.33 4.773 13.125 0 .637-3.819-1.281-5.857-2.74-6.652" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M2 2.745c3.502 0 7.716 5.688 8.111 14.749.643 14.704-4.162 19.358 0 26.97 2.728 4.989 17.76 4.733 21.85-3.534 3.218-6.502-2.929-12.045-6.593-20.744C21.873 11.894 19.66 6.796 23.314 2" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M24.26 5c-.79 5.338-1.113 16.334.387 22.334 3.517 14.067-1.546 17.47-3.286 17.47-5.263 0-6.502-4.699-7.71-17.991-1.5-16.5-1.542-16.351-3.651-20.974" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M20.822 8c2.658 8.077 7.542 25.256 5.818 29.354-2.155 5.122-5.487-2.206-5.487 3.507-1.042 2.806-3.778 3.19-5.071-1.537-1.293-4.728-5.216 3.508-6.51 1.537-3.531-1.537-.665-7.067 1.275-8.84" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M13.265 12c1.81 16.085 7.474 10.4 9.852 19.302 1.886 7.057-9.187 7.745-12.117 5.357" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M13 43.803c3.666 0 8.537-1.535 9.228-5.918.602-3.812-5.617-3.21-7.322-7.523s-.893-17.67 0-23.362" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M21.738 10c4.916 3.966 11.94 22.935 5.97 28.98-5.97 6.046-8.678-4.656-13.806-4.656-5.127 0-9.034 5.918-8.513-1.062.416-5.583 4.035-5.499 4.729-5.763" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M13.749 15c3.806 2.131 10.88 11.851 10.149 17.332-.476 3.566-8.483 2.42-12.898 1.66" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
    ];

    string[] private mouth = [
        '<path d="M20 19.524c2.175-4.66 11.277-13.886 30.288-13.513" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M44.351 6.502C40.236 8.559 24.01 13.19 14 10.658c6.187 10.009 34.962 11.423 39.612 2.532 4.914-9.399-4.116-9.26-9.26-6.688Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M13.609 13.778c4.708 4.08 13.46 6.474 22.473 5.468 10.228-1.142 16.289-6.566 18.855-10.7M10 16.544c1.58-1.009 4.81-3.742 5.084-6.61M53.135 6c1.006 1.582 3.735 4.815 6.602 5.093"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M13.609 14.49c4.708 4.08 12.445 10.451 22.85-1.947 6.616-7.884 15.912.85 18.478-3.284M10 17.257c1.58-1.009 4.81-3.742 5.084-6.61M55.34 6c-.152 1.868.073 6.093 2.192 8.045"/></g>',
        '<path d="M15 14.063s4.249 1.542 7.056 0c2.807-1.542 2.97-5.953 5.098-3.632 2.66 2.901 3.123 4.841 4.574 6.292 1.451 1.45 2.621-4.933 3.83-7.109 1.21-2.176 4.66 6.206 6.594 6.206 1.935 0 1.445-9.494 3.62-7.56 2.177 1.934 1.795 5.394 8.793 3.423" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M22.158 21.451c-.426.568-2.898-7.097-4.08-11l7.452 1.241c-.947 3.017-2.946 9.191-3.372 9.76ZM49.386 20.394c-.66.26-3.062-6.04-4.244-9.944L51.08 8.5c-.946 3.016-.574 11.454-1.694 11.895Z"/><path d="M13 4.662c3.008 6.197 12.364 7.772 24.06 6.467C47.28 9.988 53.305 6.725 56.263 3"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M54.254 13.735c4.915-9.399-1.372-9.996-6.517-7.424-2.417 1.208-14.6 4.267-23.49 2.403-6.452-2.437-9.806-6.733-10.243 4.184-.438 10.917 36.17 8.642 40.25.837Z"/><path d="M15.169 11.877c7.97 2.77 26.97 5.86 39.215-3.936M23.902 10.969l-.861 5.645M30.84 12.387l-.51 6.195M37.44 11.66l.872 6.441M45.273 9.8l1.409 7.064"/></g>',
        '<path d="M34.032 8.914C26.782 8.914 20.018 7.822 17 7c1.088 2.587 3.382 11.973 17.032 11.973S50.497 9.776 52.258 7c-5.897 1.823-10.976 1.914-18.226 1.914Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M54.7 2.055c-7.309 0-25.936-.671-38.7 2.673 0 10.66 12.607 20.135 23.232 17.264C49.857 19.12 56.18 7.072 54.7 2.055Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M16 6.624c5.289 2.44 13.494 7.955 22.652 7.677C49.779 13.964 53.259 8.17 54.775 5"/><path d="M34.268 6.309c-3.02-1.866-8.596 1.799-9.879 4.203 1.516 5.512 7.297 9.171 13.905 9.171 7.27 0 11.264-6.268 11.933-8.482l-.017-.034c-.624-1.177-1.73-3.266-4.668-4.858-3.708-2.009-6.175 6.067-6.865 6.067-.689 0-.579-3.7-4.41-6.067Z"/></g>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14.783S9.688 12 11.11 7.228M12.173 8.97c.226.843-6.946 9.302-6.946 9.302M14.219 8.558c-.548 4.191-5.21 10.324-5.21 10.324M11.618 20.032s5.27-4.839 5.742-10.336M19.569 9.373c0 3.5-1.669 11.195-1.669 11.195M45.614 7.717l-.001 12.296M18.735 20.177s4.158-5.23 4.158-9.55M49.151 18.246s-3.032-6.278-3.032-10.6M25.345 10.242c.298 2.359-2.915 9.713-2.915 9.713M55.519 6.876c.298 2.359 5.415 8.371 5.415 8.371M49.15 8.048c.299 2.36 4.858 9.796 4.858 9.796M27.684 10.056c-.596 4-1.253 10.62-1.253 10.62M50.823 7.331l6.37 9.173M30.008 9.871c.608 2.86.767 8.629 3.689 10.589M58.485 7.253c1.542 2.38 4.446 5.94 8.242 6.877M34.033 8.966c0 1.335-1.784 5.893.956 11.132M39.924 20.465S34.99 14.332 34.99 8.966M37.456 8.61c0 3.832 6.17 11.958 6.17 11.958M44.547 19.979c-.66-1.994-3.856-9.246-3.497-12.461"/></g>',
        '<path d="M12 5.602c2.425 3.907 6.607 15.1 22.733 15.1S57.026 6.547 57.713 5" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M43.831 10.44c-8.085 1.427-20.546.901-22.445 2.328-3.364 3.752 16.225 1.365 20.465.865 8.885-1.048 11.798-4.926 1.98-3.193Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<g stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M11 11.184c2.913 1.137 9.265 3.07 24.27 1.707C54.029 11.186 54.224 9.558 58.7 7"/><path d="M35.745 7.562c-10.82.637-17.105 3.713-18.895 5.172 15.713 12.331 34.807 0 34.807-2.586-2.387-.994-2.387-3.381-15.912-2.586Z"/></g>',
        '<path d="M34.032 9.914C26.782 9.914 20.018 8.822 17 8c1.088 2.587 6.42 8.26 17.032 8.26 11.938 0 16.465-5.484 18.226-8.26-5.897 1.823-10.976 1.914-18.226 1.914Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M19.5 9.991c-1.26 2.154.364 7.707 15.282 6.79 14.918-.917 19.07-8.996 14.51-8.804-6.2.262-10.649 4.193-20.131 2.073-3.36-.752-8.486-2.067-9.66-.059Z" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M22 16.73c7.19 3.826 23.134 1.937 25.412-7.063.236-.934.055-2.667-1.167-2.667" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
        '<path d="M17 12s13.39 3.898 36.157 0" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EYES", eyes);
    }

    function getNose(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NOSE", nose);
    }

    function getMouth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOUTH", mouth);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[7] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 128 128" style="background-color:white"><g transform="translate(7 4)">';

        parts[1] = getEyes(tokenId);

        parts[2] = '</g><g transform="translate(47 46)">';

        parts[3] = getNose(tokenId);

        parts[4] = '</g><g transform="translate(30 93)">';

        parts[5] = getMouth(tokenId);

        parts[6] = "</g></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Personality #',
                        toString(tokenId),
                        '", "description": "Personalities is randomized NFT project generated and stored on chain. Claim your Personality.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function claim(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 0 && tokenId < 1000, "Token ID invalid");
        (bool sent, bytes memory data) = payable(owner()).call{
            value: 100 ether
        }("");
        require(sent, "Failed to send claim fee");
        _safeMint(_msgSender(), tokenId);
    }

    constructor() ERC721("Personalities", "PRSNLTYS") Ownable() {}
}