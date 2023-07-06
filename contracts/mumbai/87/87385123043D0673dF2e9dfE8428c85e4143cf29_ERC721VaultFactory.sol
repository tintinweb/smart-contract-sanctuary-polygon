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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@transmissions11/solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721TokenVault.sol";
import "./ERC721VaultFactory.sol";
import "../nft/CO2eCertificateNFT.sol";

contract ERC20TokenCenter is Ownable, ReentrancyGuard, ERC20 {
    /***************************** State veriable *****************************/
    ERC721VaultFactory public erc721VaultFactory;
    CO2eCertificateNFT public co2eCertificateNFT;
    
    /********************************** Event *********************************/
    event ExchangeToERC20(
        address indexed originalNFT,
        uint256 indexed vaultId,
        uint256 ratio,
        uint256 supply
    );
    
    event ExchangeToERC721(
        address indexed issuingNFT,
        uint256 tokenId
    );
    
    event AllowanceRecord(
        address indexed owner,
        address indexed spender,
        uint256 prevAmount,
        uint256 currAmount
    );
    
    event TransferByPlatform(
        address indexed from,
        address indexed spender,
        address to,
        uint256 amount
    );
    
    /****************************** Constructor *******************************/
    /**
     * @dev Because all the "Carbon Credit FT" are defined at "kilogram" in
     *      this contract, it is okay to use `decimals` = 0 in the constructor.
     *      If so, the frontend wallet will display token balances as "kilogram"
     *      to the users. Besides, developer could choose `decimals` = 3 for
     *      displaying token balances as "ton".
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}
    
    /************************** Public read function **************************/
    function callERC1271isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view {
        try erc721VaultFactory.isValidSignature(_hash, _signature) returns (bytes4 result) {
            require(result == 0x1626ba7e, "Invalid ERC-1271 signature");
        } catch {
            revert("Failed to call `ERC721VaultFactory`'s `isValidSignature()`");
        }
    }
    
    /************************** `onlyOwner` function **************************/
    function setERC721VaultFactory(
        address newERC721VaultFactory
    ) external onlyOwner returns (bool) {
        require(newERC721VaultFactory != address(erc721VaultFactory), "Cannot set the same address twice");
        erc721VaultFactory = ERC721VaultFactory(newERC721VaultFactory);
        return true;
    }
    
    function setCO2eCertificateNFT(
        address newCO2eCertificateNFT
    ) external onlyOwner returns (bool) {
        require(newCO2eCertificateNFT != address(co2eCertificateNFT), "Cannot set the same address twice");
        co2eCertificateNFT = CO2eCertificateNFT(newCO2eCertificateNFT);
        return true;
    }
    
    function mintToken(
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }
    
    function burnToken(
        address from,
        uint256 amount
    ) external returns (bool) {
        // Called by `CO2eCertificateNFT` or `onlyOwner`
        if ((msg.sender != owner()) && (msg.sender != address(co2eCertificateNFT))) {
            revert("Caller is not allowed to invoke this function");
        }
        
        _burn(from, amount);
        return true;
    }
    
    /************************* Public write function **************************/
    /**
     * @dev Exchange ERC721 token to ERC20 tokens
     * 
     * This function is meant to be called by `TokenVault` created by
     * `ERC721VaultFactory`, otherwise it will revert.
     * 
     * @param creator `TokenVault`'s creator who is the receiver of new Carbon Credit FTs
     * @param vaultId `TokenVault`'s identifier in the `ERC721VaultFactory`
     * @param originalNFT The underlying NFT contract belongs to `TokenVault`
     * @param supply Amount of Carbon Credit FTs which will be minted
     * @param ratio Conversion ratio of NFT's `weight` to Carbon Credit FT
     */
    function exchangeToken(
        address creator,
        uint256 vaultId,
        address originalNFT,
        uint256 supply,
        uint256 ratio
    ) external returns (bool) {
        // Check validity of the caller (a contract created by `ERC721VaultFactory`)
        address tokenVaultAddress = msg.sender;
        bytes memory _signature = abi.encode(tokenVaultAddress, vaultId);
        bytes32 _hash = keccak256(_signature);
        this.callERC1271isValidSignature(_hash, _signature);
        
        // Mint new Carbon Credit FTs according to the argument `supply`
        _mint(creator, supply);
        emit ExchangeToERC20(originalNFT, vaultId, ratio, supply);
        
        return true;
    }
    
    /**
     * @dev Exchange ERC20 tokens to ERC721 token
     * 
     * This function can be called by anyone who owns at least `minSwapAmount`
     * amount of Carbon Credit FTs.
     * 
     * @param receiver Address of receiver who owns the new minted CO2e Certificate NFT
     * @param amount Amount of Carbon Credit FTs that receiver wants to exchange
     */
    function exchangeToken(
        address receiver,
        uint256 amount
    ) external nonReentrant returns (bool) {
        // Transfer `ERC20TokenCenter` tokens to this contract
        require(
            allowance[msg.sender][address(this)] >= amount,
            "Carbon Credit FT allowance is not enough for now"
        );
        TransferFromHelper.safeTransferFrom(
            address(this),
            msg.sender,
            address(this),
            amount
        );
        
        // Grant transferring FT permission to `CO2eCertificateNFT`
        this.approve(address(co2eCertificateNFT), amount);
        
        // Mint a new NFT
        uint256 tokenId = co2eCertificateNFT.mintToken(
            receiver,
            amount
        );
        emit ExchangeToERC721(address(co2eCertificateNFT), tokenId);
        return true;
    }
    
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        address owner = msg.sender;
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");
        
        uint256 oldAmount = allowance[owner][spender];
        uint256 newAmount = oldAmount + addedValue;
        require(approve(spender, newAmount), "Failed to call `approve()`");
        
        emit AllowanceRecord(
            owner,
            spender,
            oldAmount,
            newAmount
        );
        
        return true;
    }
    
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        address owner = msg.sender;
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");
        
        uint256 oldAmount = allowance[owner][spender];
        uint256 newAmount;
        require(oldAmount >= subtractedValue, "Try to decrease allowance below zero");
        unchecked {
            newAmount = oldAmount - subtractedValue;
        }
        require(approve(spender, newAmount), "Failed to call `approve()`");
        
        emit AllowanceRecord(
            owner,
            spender,
            oldAmount, 
            newAmount
        );
        
        return true;
    }
    
    /************************** Overriding function ***************************/
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        super.transferFrom(from, to, amount);
        
        if (msg.sender == owner()) {
            emit TransferByPlatform(from, msg.sender, to, amount);
        }
        else {
            // Do nothing
        }
        
        return true;
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ERC20TokenCenter.sol";
import "../nft/CarbonCreditNFT.sol";

contract ERC721TokenVault {
    /******************************** Constant ********************************/
    // Address of Carbon Credit FT contract
    ERC20TokenCenter public immutable erc20TokenCenter;
    
    // Address of the underlying NFT contract
    CarbonCreditNFT  public immutable underlyingToken;
    
    // `tokenId` of the underlying NFT
    uint256 public immutable underlyingTokenId;
    
    // Address who creates this NFT vault
    address public immutable creator;
    
    // `TokenVault`'s identifier in the `ERC721VaultFactory`'s mapping `vaults`
    uint256 public immutable vaultId;
    
    // Conversion ratio of NFT's `weight` to Carbon Credit FT
    uint16  public immutable ratio;
    
    // Carbon credit `weight` of the underlying NFT
    uint64  public immutable weight;
    
    // Amount of new minted Carbon Credit FT
    uint256 public immutable supply;
    
    /****************************** Constructor *******************************/
    constructor(
        ERC20TokenCenter _erc20TokenCenter,
        CarbonCreditNFT  _underlyingToken,
        uint256 _tokenId,
        address _creator,
        uint256 _vaultId
    ) {
        // Initialize some constants
        erc20TokenCenter  = _erc20TokenCenter;
        underlyingToken   = _underlyingToken;
        underlyingTokenId = _tokenId;
        creator           = _creator;
        vaultId           = _vaultId;
        
        // Check if the ownership of NFT has been passed to this contract
        require(underlyingToken.ownerOf(underlyingTokenId) == address(this), "New `TokenVault` has not owned the NFT");
        
        // Calaculate the amount of new Carbon Credit FT which will be minted
        CarbonCreditNFT.TokenInfo memory tokenInfo;
        
        try underlyingToken.getTokenInfo(underlyingTokenId) returns (CarbonCreditNFT.TokenInfo memory _tokenInfo) {
            tokenInfo = _tokenInfo;
        } catch {
            revert("Failed to get `TokenInfo` from Carbon Credit NFT contract");
        }
        
        try underlyingToken.getRatio(tokenInfo.issueById) returns (uint16 _ratio) {
            ratio  = _ratio;
            weight = tokenInfo.weight;
            supply = uint256(weight) * uint256(ratio);
        } catch {
            revert("Failed to get `ratio` from Carbon Credit NFT contract");
        }
        
        // Call `ERC20TokenCenter.exchangeToken()` to mint new Carbon Credit FT
        bool result = erc20TokenCenter.exchangeToken(
            creator,
            vaultId,
            address(underlyingToken),
            supply,
            ratio
        );
        require(result, "Failed to mint new Carbon Credit FTs");
    }
    
    /************************** Overriding function ***************************/
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        // Do nothing because this vault is meant to lock NFT forever.
        
        if ((operator == operator) || (from == from) || (tokenId == tokenId) || (keccak256(data) == keccak256(data))) {
            // Dummy expresions using for disabling compiler unused function parameter warnings
        }
        
        return IERC721Receiver.onERC721Received.selector;
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC20TokenCenter.sol";
import "./ERC721TokenVault.sol";
import "../nft/CarbonCreditNFT.sol";

contract ERC721VaultFactory is Ownable, ReentrancyGuard, IERC1271 {
    /******************************** Constant ********************************/
    ERC20TokenCenter public immutable erc20TokenCenter;
    CarbonCreditNFT  public immutable authorizedNFT;
    
    /********************************** Event *********************************/
    // Emit when a new `TokenVault` is created
    event Mint(
        uint256 indexed tokenId,
        address vault,
        uint256 vaultId
    );
    
    /***************************** State veriable *****************************/
    // The minimal "un-used" `vaultId`, i.e., the maximum "used" `(vaultId + 1)`
    uint256 public maxVaultId;
    
    // A whitelist mapping from `vaultId` to the address of vault
    mapping(uint256 => address) public vaults;
    
    /****************************** Constructor *******************************/
    constructor(address _erc20TokenCenter, address _authorizedNFT) {
        erc20TokenCenter = ERC20TokenCenter(_erc20TokenCenter);
        authorizedNFT = CarbonCreditNFT(_authorizedNFT);
    }
    
    /************************* Public write function **************************/
    /**
     * @dev Fractionalize the ERC721 token
     * 
     * This function is meant to be called by anyone who owns `authorizedNFT`.
     * Please be aware of granting permission to `ERC721VaultFactory` for
     * transferring token, otherwise it will revert.
     * 
     * @param tokenId Token identifier of `authorizedNFT`
     */
    function fractionalization(uint256 tokenId) public nonReentrant returns (uint256) {
        // Check if `tokenId` is avaliable for transferring by `address(this)`
        require(
            authorizedNFT.getApproved(tokenId) == address(this),
            "Please give NFT transferring permission to `ERC721VaultFactory`"
        );
        
        // Predict contract address of the new TokenVault
        uint256 curVaultId = maxVaultId++;
        bytes32 salt = bytes32(curVaultId) ^ bytes32(block.difficulty);
        address predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(ERC721TokenVault).creationCode,
                abi.encode(
                    erc20TokenCenter,
                    authorizedNFT,
                    tokenId,
                    msg.sender,
                    curVaultId
                )
            ))
        )))));
        
        // Transfer `msg.sender`'s NFT to the new TokenVault
        try authorizedNFT.safeTransferFrom(msg.sender, predictedAddress, tokenId) {
        } catch {
            revert("Failed to transfer NFT from the owner to the `TokenVault`");
        }
        
        // Store new TokenVault address into the whitelist which will let `ERC20TokenCenter` know later
        vaults[curVaultId] = predictedAddress;
        emit Mint(tokenId, predictedAddress, curVaultId);
        
        // Establish new TokenVault by `CREATE2`
        ERC721TokenVault newTokenVault = new ERC721TokenVault{salt: salt}(
            erc20TokenCenter,
            authorizedNFT,
            tokenId,
            msg.sender,
            curVaultId
        );
        require(
            address(newTokenVault) == predictedAddress,
            "Predicting address is failed, so revert NFT transferring"
        );
        
        return curVaultId;
    }
    
    /************************** Overriding function ***************************/
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view override returns (bytes4) {
        // Check whether the caller is `ERC20TokenCenter`
        require(msg.sender == address(erc20TokenCenter), "Invalid caller of `isValidSignature()`");
        
        // Split the signature
        address prevMsgSender;
        uint256 vaultId;
        (prevMsgSender, vaultId) = abi.decode(_signature, (address, uint256));
        
        // Validate signatures
        require(_hash == keccak256(_signature), "`_signature` is differnet from `_hash`");
        require(vaultId < maxVaultId, "Invalid `vaultId`");
        require(prevMsgSender != address(0), "Caller cannot be the zero address");
        require(vaults[vaultId] == prevMsgSender, "Caller is not included in the `ERC721VaultFactory`'s whitelist");
        
        return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IERC4906.sol";

contract CarbonCreditNFT is Ownable, IERC4906, ERC721, ERC721Enumerable {
    /******************************* Structure ********************************/
    struct NewTokenData {
        string certId;     // 證書 ID（至多三十二位元組）
        uint256 sourceId;  // 證書來源 ID
        uint256 issueById; // 簽發機構 ID
        uint64  weight;    // 碳權當量（公噸）
    }
    
    struct TokenInfo {
        string certId;     // 證書 ID（至多三十二位元組）
        uint256 sourceId;  // 證書來源 ID（需再查詢 `getSourceList()`）
        uint256 issueById; // 簽發機構 ID（需再查詢 `getIssueByList()`）
        uint64 weight;     // 碳權當量（公噸）
        uint256 date;      // 代幣鑄造時間戳記
    }
    
    struct TokenInfoLiterally {
        string certId;  // 證書 ID（至多三十二位元組）
        string source;  // 證書來源字串（至多三十二位元組）
        string issueBy; // 簽發機構字串（至多三十位元組）
        uint64 weight;  // 碳權當量（公噸）
        uint256 date;   // 代幣鑄造時間戳記
    }
    
    struct TokenData {
        uint256 sourceId;
        uint256 issueById;
        bytes32 certId;
        uint192 date;
        uint64  weight;
    }
    
    struct CertSource {
        bytes32 source; // 證書來源字串（至多三十二位元組）
    }
    
    struct CertIssueBy {
        bytes30 issueBy; // 簽發機構字串（至多三十位元組）
        uint16  ratio; // `weight` * `ratio` = Carbon Credit FTs `supply` amount
    }
    
    /***************************** State veriable *****************************/
    uint256 public maxSourceId;
    uint256 public maxIssueById;
    uint256 public currTokenId;
    
    mapping(uint256 => TokenData) private _tokenURIs; // `tokenId` => TokenData
    mapping(uint256 => CertSource) private _sourceMaps; // `sourceId` => CertSource
    mapping(uint256 => CertIssueBy) private _issueByMaps; // `issueById` => CertIssueBy
    
    /****************************** Constructor *******************************/
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}
    
    /************************** Public read function **************************/
    function getSourceList() external view returns (string[] memory){
        string[] memory sourceList = new string[](maxSourceId);
        bytes32 ith_source;
        
        for (uint256 i = 0; i < maxSourceId;) {
            ith_source = _sourceMaps[i].source;
            sourceList[i] = string(bytes.concat(ith_source));
            unchecked {i++;}
        }
        
        return sourceList;
    }
    
    function getIssueByList() external view returns (string[] memory){
        string[] memory issueByList = new string[](maxIssueById);
        bytes30 ith_issueBy;
        
        for (uint256 i = 0; i < maxIssueById;) {
            ith_issueBy = _issueByMaps[i].issueBy;
            issueByList[i] = string(bytes.concat(ith_issueBy));
            unchecked {i++;}
        }
        
        return issueByList;
    }

    function getRatioList() external view returns (uint16[] memory){
        uint16[] memory ratioList = new uint16[](maxIssueById);
        
        for (uint256 i = 0; i < maxIssueById;) {
            ratioList[i] = _issueByMaps[i].ratio;
            unchecked {i++;}
        }
        
        return ratioList;
    }
    
    function getTokenInfo(
        uint256 tokenId
    ) external view returns (TokenInfo memory){
        require(ERC721._exists(tokenId), "Cannot get non-existent token");
        
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return TokenInfo(
            string(bytes.concat(tokenData.certId)),
            tokenData.sourceId,
            tokenData.issueById,
            tokenData.weight,
            (((block.timestamp>>192)<<192) + uint256(tokenData.date))
        );
    }
    
    function getTokenInfoLiterally(
        uint256 tokenId
    ) external view returns (TokenInfoLiterally memory) {
        require(ERC721._exists(tokenId), "Cannot get non-existent token");
        
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return TokenInfoLiterally(
            string(bytes.concat(tokenData.certId)),
            string(bytes.concat(_sourceMaps[tokenData.sourceId].source)),
            string(bytes.concat(_issueByMaps[tokenData.issueById].issueBy)),
            tokenData.weight,
            (((block.timestamp>>192)<<192) + uint256(tokenData.date))
        );
    }
    
    function getRatio(uint256 issueById) external view returns (uint16) {
        require(issueById < maxIssueById, "Cannot get non-existent `issueBy`");
        
        CertIssueBy storage slot = _issueByMaps[issueById];
        require((slot.issueBy) != bytes30(0), "Cannot get non-existent `issueBy`");
        
        return slot.ratio;
    }
    
    /************************** `onlyOwner` function **************************/
    function addSource(
        string calldata source
    ) external onlyOwner returns (bool) {
        require(bytes(source).length != 0, "Forbid empty `source`");
        require(bytes(source).length < 33, "The length of `source` <= 32 bytes");
        
        _sourceMaps[maxSourceId] = CertSource(bytes32(abi.encodePacked(source)));
        maxSourceId++;
        
        return true;
    }
    
    function delSource(uint256 sourceId) external onlyOwner returns (bool) {
        require(sourceId < maxSourceId, "Cannot delete non-existent `source`");
        _sourceMaps[sourceId] = CertSource(bytes32(0));
        return true;
    }
    
    function addIssueBy(
        string calldata issueBy,
        uint16 ratio
    ) external onlyOwner returns (bool) {
        require(bytes(issueBy).length != 0, "Forbid empty `issueBy`");
        require(bytes(issueBy).length < 31, "The length of `issueBy` <= 30 bytes");
        require(ratio != 0, "Conversion `ratio` must be non-zero");
        
        _issueByMaps[maxIssueById] = CertIssueBy(bytes30(abi.encodePacked(issueBy)), ratio);
        maxIssueById++;
        
        return true;
    }
    
    function delIssueBy(uint256 issueById) external onlyOwner returns (bool) {
        require(issueById < maxIssueById, "Cannot delete non-existent `issueBy`");
        _issueByMaps[issueById] = CertIssueBy(bytes30(0), 0);
        return true;
    }
    
    function setRatio(
        uint256 issueById,
        uint16 ratio
    ) external onlyOwner returns (bool) {
        require(issueById < maxIssueById, "Cannot modify non-existent `issueBy`");
        require(ratio != 0, "Conversion `ratio` must be non-zero");
        
        CertIssueBy storage slot = _issueByMaps[issueById];
        require((slot.issueBy) != bytes30(0), "Cannot modify non-existent `issueBy`");
        slot.ratio = ratio;
        
        return true;
    }
    
    /************************* Public write function **************************/
    function mintToken(
        NewTokenData calldata newTokenData,
        address receiver
    ) external onlyOwner returns (bool) {
        uint256 newTokenId;
        unchecked {
            newTokenId = (currTokenId++);
        }
        
        _safeMint(receiver, newTokenId);
        _setTokenURI(newTokenId, newTokenData);
        
        return true;
    }
    
    function burnToken(uint256 tokenId) external returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "You cannot burn this NFT.");

        _burn(tokenId);

        return true;
    }
    
    /**************************** Private function ****************************/
    function _constructTokenURI(
        uint256 tokenId
    ) private view returns (string memory) {
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return string(
            abi.encode(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encode(
                            '{"certId":"',
                            string(bytes.concat(tokenData.certId)),
                            '", "sourceId":"',
                            Strings.toString(tokenData.sourceId),
                            '", "issueById":"',
                            Strings.toString(tokenData.issueById),
                            '", "weight":"',
                            Strings.toString(tokenData.weight),
                            '", "date":"',
                            string.concat(Strings.toString((block.timestamp>>192)), Strings.toString(tokenData.date)),
                            '"}'
                        )
                    )
                )
            )
        );
    }
    
    function _setTokenURI(
        uint256 tokenId,
        NewTokenData calldata newTokenData
    ) private {
        require(ERC721._exists(tokenId), "Cannot set non-existent token");
        require(bytes(newTokenData.certId).length < 33, "The length of `certId` <= 32 bytes");
        
        _tokenURIs[tokenId] = TokenData(
            newTokenData.sourceId,
            newTokenData.issueById,
            bytes32(abi.encodePacked(newTokenData.certId)),
            uint192(block.timestamp), // Higher-order bits are cut off.
            newTokenData.weight
        );
        
        emit MetadataUpdate(tokenId);
    }
    
    /************************** Overriding function ***************************/
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return _constructTokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721)
    {
        require(ERC721._exists(tokenId), "Cannot burn non-existent token");
        super._burn(tokenId);
        _tokenURIs[tokenId] = TokenData(uint256(0),uint256(0),bytes32(0),uint192(0),uint64(0));
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId,batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable,IERC165)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC4906.sol";
import "../fractional/ERC20TokenCenter.sol";
import "./UUIDGenerator.sol";
import "./TransferFromHelper.sol";

contract CO2eCertificateNFT is Ownable, ReentrancyGuard, IERC4906, ERC721, ERC721Enumerable {
    /**
     * @dev Because the carbon credit certificates generated from this contract
     *      are all issued by a single platform - HSNLab, it does make sense
     *      to let both `_sourceMaps` and `_issueByMaps` shrink into two
     *      constant logical structures `CertSource` and `CertIssueBy`.
     *      BTW, type `immutable` does not support `struct`.
     */
    /******************************** Constant ********************************/
    uint256 public immutable certSourceId;
    uint256 public immutable certIssueById;
    bytes32 public immutable certSource;
    bytes30 public immutable certIssueBy;
    uint16  public immutable certIssueByRatio;
    ERC20TokenCenter public immutable erc20TokenCenter;
    UUIDGenerator public immutable uuidGenerator;
    
    /******************************* Structure ********************************/
    struct TokenInfo {
        string certId;     // 證書 ID（至多三十二位元組）
        uint256 sourceId;  // 證書來源 ID（需再查詢 `getSourceList()`）
        uint256 issueById; // 簽發機構 ID（需再查詢 `getIssueByList()`）
        uint64 weight;     // 碳權當量（公噸）
        uint256 date;      // 代幣鑄造時間戳記
    }
    
    struct TokenInfoLiterally {
        string certId;  // 證書 ID（至多三十二位元組）
        string source;  // 證書來源字串（至多三十二位元組）
        string issueBy; // 簽發機構字串（至多三十位元組）
        uint64 weight;  // 碳權當量（公噸）
        uint256 date;   // 代幣鑄造時間戳記
    }
    
    struct TokenData {
        bytes32 certId;
        uint192 date;
        uint64  weight;
    }
    
    struct CertSource {
        bytes32 source; // 證書來源字串（至多三十二位元組）
    }
    
    struct CertIssueBy {
        bytes30 issueBy; // 簽發機構字串（至多三十位元組）
        uint16  ratio; // `weight` * `ratio` = Carbon Credit FTs `supply` amount
    }
    
    /***************************** State veriable *****************************/
    uint256 public currTokenId;
    uint256 public minSwapAmount;
    mapping(uint256 => TokenData) private _tokenURIs; // `tokenId` => TokenData
    
    /****************************** Constructor *******************************/
    constructor(
        string memory name,
        string memory symbol,
        string memory source,
        string memory issueBy,
        uint16 ratio,
        address tokenCenter,
        address uuidGen
    ) ERC721(name, symbol) {
        require(bytes(source).length != 0, "Forbid empty `source`");
        require(bytes(source).length < 33, "The length of `source` <= 32 bytes");
        
        require(bytes(issueBy).length != 0, "Forbid empty `issueBy`");
        require(bytes(issueBy).length < 31, "The length of `issueBy` <= 30 bytes");
        require(ratio != 0, "Conversion `ratio` must be non-zero");
        
        minSwapAmount    = 1000;
        certSourceId     = 0;
        certIssueById    = 0;
        certSource       = bytes32(abi.encodePacked(source));
        certIssueBy      = bytes30(abi.encodePacked(issueBy));
        certIssueByRatio = ratio;
        erc20TokenCenter = ERC20TokenCenter(tokenCenter);
        uuidGenerator    = UUIDGenerator(uuidGen);
    }
    
    /************************** Public read function **************************/
    function getSourceList() external view returns (string[] memory){
        string[] memory sourceList = new string[](1);
        sourceList[0] = string(bytes.concat(certSource));
        return sourceList;
    }
    
    function getIssueByList() external view returns (string[] memory){
        string[] memory issueByList = new string[](1);
        issueByList[0] = string(bytes.concat(certIssueBy));
        return issueByList;
    }

    function getRatioList() external view returns (uint16[] memory){
        uint16[] memory ratioList = new uint16[](1);
        ratioList[0] = certIssueByRatio;
        return ratioList;
    }

    function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory){
        require(ERC721._exists(tokenId), "Cannot get non-existent token");
        
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return TokenInfo(
            string(bytes.concat(tokenData.certId)),
            certSourceId,
            certIssueById,
            tokenData.weight,
            (((block.timestamp>>192)<<192) + uint256(tokenData.date))
        );
    }
    
    function getTokenInfoLiterally(
        uint256 tokenId
    ) external view returns (TokenInfoLiterally memory) {
        require(ERC721._exists(tokenId), "Cannot get non-existent token");
        
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return TokenInfoLiterally(
            string(bytes.concat(tokenData.certId)),
            string(bytes.concat(certSource)),
            string(bytes.concat(certIssueBy)),
            tokenData.weight,
            (((block.timestamp>>192)<<192) + uint256(tokenData.date))
        );
    }
    
    function getRatio(uint256 issueById) external view returns (uint16) {
        return certIssueByRatio;
    }
    
    /************************* Public write function **************************/
    function addSource(string calldata source) external pure returns (bool) {
        // Dummy function in order to keep compatibilities of `CarbonCreditNFT`
        return true;
    }
    
    function delSource(uint256 sourceId) external pure returns (bool) {
        // Dummy function in order to keep compatibilities of `CarbonCreditNFT`
        return true;
    }
    
    function addIssueBy(
        string calldata issueBy,
        uint16 ratio
    ) external pure returns (bool) {
        // Dummy function in order to keep compatibilities of `CarbonCreditNFT`
        return true;
    }
    
    function delIssueBy(uint256 issueById) external pure returns (bool) {
        // Dummy function in order to keep compatibilities of `CarbonCreditNFT`
        return true;
    }
    
    function setRatio(
        uint256 issueById,
        uint16 ratio
    ) external pure returns (bool) {   
        // Dummy function in order to keep compatibilities of `CarbonCreditNFT`     
        return true;
    }
    
    /************************* Public write function **************************/
    /**
     * @dev Mint the new CO2e Certificate NFT
     * 
     * This function is meant to be called by `ERC20TokenCenter`, otherwise
     * it will revert.
     */
    function mintToken(
        address receiver,
        uint256 amount
    ) external nonReentrant returns (uint256) {
        require(
            msg.sender == address(erc20TokenCenter),
            "Caller is not allowed to invoke this function"
        );
        
        // Check whether `amount` is qualified for all the criterias
        require(
            amount >= minSwapAmount,
            "`amount` must be at least `minSwapAmount` Carbon Credit FTs"
        );
        require(
            (amount % uint256(certIssueByRatio)) == 0,
            "Conversion `amount` must be a multiple of `ratio`"
        );
        
        // Check whether `amount` will cause `weight` to be overflow
        uint256 pseudoWeight = amount / uint256(certIssueByRatio);
        require(
            pseudoWeight <= type(uint64).max,
            "Try to convert overwhelming amount of Carbon Credit FTs"
        );
        uint64 weight = uint64(pseudoWeight);
        
        // Transfer `ERC20TokenCenter` tokens to this contract
        TransferFromHelper.safeTransferFrom(
            address(erc20TokenCenter),
            address(erc20TokenCenter),
            address(this),
            amount
        );
        
        // Burn "Carbon Credit FT" ERC20 tokens
        erc20TokenCenter.burnToken(address(this), amount);
        
        // Mint a new ERC721 token "CO2e Certificate NFT"
        uint256 newTokenId = _mintToken(
            TokenData(
                bytes32(abi.encodePacked(uuidGenerator.generateUUID4())),
                uint192(block.timestamp), // Higher-order bits are cut off.
                weight
            ),
            receiver
        );
        
        return newTokenId;
    }
    
    function burnToken(uint256 tokenId) external returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "You cannot burn this NFT.");

        _burn(tokenId);

        return true;
    }
    
    /**************************** Private function ****************************/
    function _constructTokenURI(
        uint256 tokenId
    ) private view returns (string memory) {
        TokenData memory tokenData = _tokenURIs[tokenId];
        
        return string(
            abi.encode(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encode(
                            '{"certId":"',
                            string(bytes.concat(tokenData.certId)),
                            '", "sourceId":"',
                            Strings.toString(certSourceId),
                            '", "issueById":"',
                            Strings.toString(certIssueById),
                            '", "weight":"',
                            Strings.toString(tokenData.weight),
                            '", "date":"',
                            string.concat(Strings.toString((block.timestamp>>192)), Strings.toString(tokenData.date)),
                            '"}'
                        )
                    )
                )
            )
        );
    }
    
    function _mintToken(
        TokenData memory newTokenData,
        address receiver
    ) private returns (uint256) {
        uint256 newTokenId;
        unchecked {
            newTokenId = (currTokenId++);
        }
        
        _safeMint(receiver, newTokenId);
        _setTokenURI(newTokenId, newTokenData);
        
        return newTokenId;
    }
    
    function _setTokenURI(
        uint256 tokenId,
        TokenData memory newTokenData
    ) private {
        require(ERC721._exists(tokenId), "Cannot set non-existent token");
        _tokenURIs[tokenId] = newTokenData;
        emit MetadataUpdate(tokenId);
    }
    
    /************************** Overriding function ***************************/
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _constructTokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721)
    {
        require(ERC721._exists(tokenId), "Cannot burn non-existent token");
        super._burn(tokenId);
        _tokenURIs[tokenId] = TokenData(bytes32(0),uint192(0),uint64(0));
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId,batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable,IERC165)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Acknowledgement: This contract was directly modified from openzeppelin library IERC4906.sol

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC4906 is IERC165, IERC721 {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: GPL-3.0
// Acknowledgement: This contract was directly modified from uniswap-v3 library TransferHelper.sol
pragma solidity ^0.8.17;

import "@transmissions11/solmate/src/tokens/ERC20.sol";

/// @title TransferFromHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferFromHelper {
    /// @notice Transfers tokens from 'src' to the recipient address 'dst'
    /// @dev Calls transferFrom on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param src The source address of the transfer
    /// @param dst The destination address of the transfer
    /// @param value The value of the transfer
    
    function safeTransferFrom(
        address token,
        address src,
        address dst,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20.transferFrom.selector, src, dst, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

/**
 *            _   __________  ____  __            __  _______ _   ____
 *           / | / /_  __/ / / / / / /           / / / / ___// | / / /
 *          /  |/ / / / / /_/ / / / /  ______   / /_/ /\__ \/  |/ / /
 *         / /|  / / / / __  / /_/ /  /_____/  / __  /___/ / /|  / /___
 *        /_/ |_/ /_/ /_/ /_/\____/           /_/ /_//____/_/ |_/_____/
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * Generate UUID strings from `block.difficulty`, i.e., `block.prevrandao`
 * 
 * UUID follows RFC4122 Version-4 Variant-1 (DCE 1.1, ISO/IEC 11578:1996)
 * 
 * See more at https://datatracker.ietf.org/doc/html/rfc4122.html
 */

contract UUIDGenerator {
    /******************************** Constant ********************************/
    bytes16 private constant symbols      = "0123456789abcdef";
    uint256 private constant maxLoopCount = 3;
    
    /***************************** State veriable *****************************/
    mapping(bytes16 => bool) public usedUUIDs;
    
    /************************* Public write function **************************/
    function generateUUID4() public returns (string memory) {
        bytes16 result;
        uint256 i;
        
        // Try at most 3 times to generate non-repeating UUID4, otherwise revert
        for (;i < maxLoopCount;) {
            result = randomUUID4();
            
            if (!usedUUIDs[result]) {
                break;
            }
            
            unchecked {i++;}
        }
        if (i == maxLoopCount) {
            revert('Failed to generate "non-repeating" UUID4 for now');
        }
        else {
            usedUUIDs[result] = true;
        }
        
        return toUUIDLayout(result);
    }
    
    /**************************** Private function ****************************/
    function randomUUID4() private view returns (bytes16) {
        bytes16 randomSource = bytes16(uint128(block.difficulty));
        
        bytes1 byte_9 = bytes1(randomSource << (6*8));
        bytes1 byte_7 = bytes1(randomSource << (8*8));
        
        // Version hex digit: M
        if (((byte_9 < 0x40) || (byte_9 > 0x4F))) {
            byte_9 = bytes1((uint8(byte_9) % 16) + 64);
            randomSource &= 0xFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFF;
            randomSource |= (bytes16(byte_9) >> (6*8));
        }
        
        // Variant hex digit: N
        if (((byte_7 < 0x80) || (byte_7 > 0xBF))) {
            byte_7 = bytes1((uint8(byte_7) % 64) + 128);
            randomSource &= 0xFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFF;
            randomSource |= (bytes16(byte_7) >> (8*8));
        }
        
        return randomSource;
    }
    
    function toUUIDLayout(bytes16 uuid) private pure returns (string memory) {
        string memory uuidLayout;
        string memory partialLayout;
        
        partialLayout = toHexString(uint256(uint32(bytes4(uuid << (0 *8)))), 4);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (4 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (6 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint16(bytes2(uuid << (8 *8)))), 2);
        uuidLayout = string.concat(uuidLayout, partialLayout, "-");
        
        partialLayout = toHexString(uint256(uint48(bytes6(uuid << (10*8)))), 6);
        uuidLayout = string.concat(uuidLayout, partialLayout);
        
        return uuidLayout;
    }
    
    function toHexString(uint256 value, uint256 length) private pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        
        for (uint256 i = 2 * length - 1;;) {
            buffer[i] = symbols[value & 0xF];
            value >>= 4;
            
            if (i == 0) {
                break;
            }
            else {
                unchecked{i--;}
            }
        }
        
        return string(buffer);
    }
}