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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHolePrevention is Ownable {
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberProvider {
    function requestRandomNumber() external returns (uint256 requestId);
    function requestRandomNumberWithCallback() external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberRequester {
    function process(uint256 rand, uint256 requestId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../traits/Implementers/ProjectInvestImplementer.sol";
import "../traits/Implementers/UserInvestmentImplementer.sol";
import "../traits/Implementers/TraitUint8ValueImplementer.sol";
import "../traits/Implementers/ReinvestRequestImplementer.sol";
import "../traits/TraitRegistryV3.sol";
import "../nft/token/ActivatableToken.sol";
import "../nft/sale/ExchangeRegistry.sol";

interface SimpleERC20Interface {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

//Error codes
uint8 constant ERR_CODE_SUCCESS = 0;
uint8 constant ERR_PROJECT_DOES_NOT_EXIST = 1;
uint8 constant ERR_USER_NOT_ACTIVE_TOKEN = 2;
uint8 constant ERR_FUNDING_NOT_STARTED = 3;
uint8 constant ERR_FUNDING_ENDED = 4;
uint8 constant ERR_INVESTMENT_BELOW_MIN = 5;
uint8 constant ERR_INVESTMENT_ABOVE_MAX = 6;
uint8 constant ERR_FUNDING_ABOVE_MAX = 7;
uint8 constant ERR_INSUFFICIENT_FUNDS = 8;

//Event types
uint8 constant INVEST_TYPE_CRYPTO = 0; //USDC invest by user
uint8 constant INVEST_TYPE_FIAT = 1; //Fiat invest added by SC owner
uint8 constant INVEST_TYPE_REINVEST_REQUEST = 2; //User made a reinvest request
uint8 constant INVEST_TYPE_REINVEST = 3; //Reinvest executed on payout
uint8 constant INVEST_TYPE_PAYOUT_CRYPTO = 4; //Payout in crypto to user
uint8 constant INVEST_TYPE_PAYOUT_FIAT = 5; //Balance for fiat was decremented from proj and added to user
uint8 constant INVEST_TYPE_PAYOUT_RETURN = 6; //Return of investment to user
uint8 constant INVEST_TYPE_PAYOUT_FIAT_DONE = 7; //After marking payment as done, this event is fired.
uint8 constant INVEST_TYPE_PAYOUT_CRYPTO_FAILED_FUNDING = 8; //if fundding fails and crypto is returned to investor
uint8 constant INVEST_TYPE_PAYOUT_FIAT_FAILED_FUNDING = 9; //if fundding fails and fiat is returned to user

//currency
uint8 constant CURRENCY_EUR = 0;
uint8 constant CURRENCY_USD = 1;
uint8 constant CURRENCY_RON = 2;
uint8 constant CURRENCY_USDC = 128;

//event type
uint8 constant EVENT_TYPE_NEW_PROJECT = 0;
uint8 constant EVENT_TYPE_UPDATE_PROJECT = 1;



contract Invest is Ownable {
    event InvestEvent(uint8 evType, uint32 fromProjId, uint32 toProjId, uint16 tokenId, uint256 value, bool isCrypto, uint8 currency);
    event ProjectEvent(uint8 eventType, ProjectInvestImplementer.Project project, address destinationWallet, string uid);

    TraitRegistryV3 public traitRegistry;
    ActivatableToken public token;
    ExchangeRegistry public exchangeRegistry;

    ProjectInvestImplementer public projectInvestImplementer;
    UserInvestmentImplementer public userInvestmentImplementer;
    ReinvestRequestImplementer public reinvestRequestImplementer;
    TraitUint8ValueImplementer public activatedTraitImplementer;
    string public constant version = "1.0.0";

    mapping (address => bool) public allowedFiatInvest;

    constructor(address _traitRegistryAddress, 
                address _tokenAddress, 
                uint16 _projectsTraitId, 
                uint16 _userInvetmentTraitId, 
                uint16 _reinvestmentTraitId ,
                uint16 _activatedTraitId,
                address _exchangeRegistryAddress) {
        require(_traitRegistryAddress != address(0), "Invest: traitRegistryAddress is zero");
        require(_tokenAddress != address(0), "Invest: tokenAddress is zero");
        require(_exchangeRegistryAddress != address(0), "Invest: exchangeRegistryAddress is zero");
        traitRegistry = TraitRegistryV3(_traitRegistryAddress);
        token = ActivatableToken(_tokenAddress);
        exchangeRegistry = ExchangeRegistry(_exchangeRegistryAddress);

        projectInvestImplementer = ProjectInvestImplementer(traitRegistry.getImplementer(_projectsTraitId));
        userInvestmentImplementer = UserInvestmentImplementer(traitRegistry.getImplementer(_userInvetmentTraitId));
        reinvestRequestImplementer = ReinvestRequestImplementer(traitRegistry.getImplementer(_reinvestmentTraitId));
        activatedTraitImplementer = TraitUint8ValueImplementer(traitRegistry.getImplementer(_activatedTraitId));
    }

    function addProject(ProjectInvestImplementer.Project memory proj, address destWallet, string calldata uid) external onlyOwner returns (uint32) {
        uint32 id = projectInvestImplementer.addProject(proj, destWallet, uid);
        proj.id = id;
        emit ProjectEvent(EVENT_TYPE_NEW_PROJECT ,proj, destWallet, uid);
        return proj.id;
    }

    function updateProject(ProjectInvestImplementer.Project memory proj, address destWallet, uint32 projectId ) external onlyOwner {
        projectInvestImplementer.updateProject(proj, destWallet, projectId);
        emit ProjectEvent(EVENT_TYPE_UPDATE_PROJECT ,proj, destWallet, "");
    }

    function getProject(uint32 projectId) external view returns (ProjectInvestImplementer.Project memory) {
        return projectInvestImplementer.getProject(projectId);
    }

    function userHasActiveToken(uint16 _tokenId, address user) public view returns (bool){
        return token.ownerOf(_tokenId) == user && (activatedTraitImplementer.getValue(_tokenId) == 1 || activatedTraitImplementer.getValue(_tokenId) == 2);
    }

    function invest(uint32 projectId, uint16 tokenId, uint256 amount) external {
        ProjectInvestImplementer.Project memory project = projectInvestImplementer.getProject(projectId); //throws error if project does not exist
        require(project.erc20PaymentTokenAddress != address(0), "ERC20 payment token address not set");
        SimpleERC20Interface paymentToken = SimpleERC20Interface(project.erc20PaymentTokenAddress);

        uint256 grossInv = exchange(CURRENCY_USDC, project.investmentCurrency, amount);
        uint256 netInv = grossInv - (grossInv * project.feeRate / 10000) - project.flatFee;
        requireWithErrorCode(investmentAllowed(projectId, tokenId, msg.sender, netInv, block.timestamp));
        require(paymentToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(paymentToken.transferFrom(msg.sender, projectInvestImplementer.getProjectWallet(projectId), amount), "Transfer failed");
        userInvestmentImplementer.incrementPayedCrypto(projectId, tokenId, CURRENCY_USDC, amount);
        _invest(projectId, tokenId, true, netInv);

        emit InvestEvent(INVEST_TYPE_CRYPTO, 0, projectId, tokenId, netInv, true, project.investmentCurrency);
    }


    function investmentAllowed(uint32 projectId, uint16 tokenId, address user, uint256 netInv, uint256 timestamp)  internal view returns (uint8) { //returns 0 for success, error code for others
        ProjectInvestImplementer.Project memory project;
        try projectInvestImplementer.getProject(projectId) returns (ProjectInvestImplementer.Project memory _project) {
            project = _project;
        } catch {
            return ERR_PROJECT_DOES_NOT_EXIST;
        }
        if(!userHasActiveToken(tokenId, user)) return ERR_USER_NOT_ACTIVE_TOKEN;
        if(timestamp < project.fundingStart) return ERR_FUNDING_NOT_STARTED;
        if(timestamp > project.fundingEnd) return ERR_FUNDING_ENDED;
        if(netInv < project.minInvestmentPerUser) return ERR_INVESTMENT_BELOW_MIN;
        if(userInvestmentImplementer.getUserTotalInvest(tokenId, projectId) + netInv > project.maxInvestmentPerUser) return ERR_INVESTMENT_ABOVE_MAX;
        if(netInv + projectInvestImplementer.getProjectTotalInvestment(projectId) > project.maxFundingTarget) return ERR_FUNDING_ABOVE_MAX;
        
        return ERR_CODE_SUCCESS;
    }


    function _invest(uint32 projectId, uint16 tokenId, bool isCrypto, uint256 netInv) internal {
        userInvestmentImplementer.incrementValue(tokenId, projectId, isCrypto, netInv);
        projectInvestImplementer.incrementProjectInvestment(projectId, isCrypto, netInv);
    }

    function reInvestRequest(uint32 fromProjectId, uint32 toProjectId, uint16 tokenId, bool isCrypto, uint256 amount) external{
        ProjectInvestImplementer.Project memory fromProject = projectInvestImplementer.getProject(fromProjectId); //throws error if project does not exist
        ProjectInvestImplementer.Project memory toProject = projectInvestImplementer.getProject(toProjectId); //throws error if project does not exist
        uint256 amountDst = exchange(fromProject.investmentCurrency, toProject.investmentCurrency, amount);
        canScheduleReinvest(fromProject, toProject, tokenId, isCrypto, amount, amountDst, block.timestamp);
        reinvestRequestImplementer.incrementValue(tokenId, fromProjectId, toProjectId, isCrypto, amount, amountDst);

        emit InvestEvent(INVEST_TYPE_REINVEST_REQUEST, fromProjectId, toProjectId, tokenId, amount, isCrypto, fromProject.investmentCurrency);
    }

    function canScheduleReinvest(ProjectInvestImplementer.Project memory fromProject, 
                         ProjectInvestImplementer.Project memory toProject, 
                         uint16 tokenId, 
                         bool isCrypto, 
                         uint256 amountSrc,
                         uint256 amountDst, 
                         uint256 scheduleTimestamp //timestamp of scheduling reinvestment
                        ) internal view {
        uint256 fromProjEnd = fromProject.fundingEnd + fromProject.duration;
        require(scheduleTimestamp > fromProject.fundingEnd, "Cannot schedule reinvest; Investment period of source project is not over yet");
        require(scheduleTimestamp >= fromProjEnd - projectInvestImplementer.reinvestStartTime(), "Cannot schedule reinvest, reinvest period not started yet");
        require(scheduleTimestamp <= fromProjEnd - projectInvestImplementer.reinvestCutOffTime(), "Cannot schedule reinvest, reinvest period is over");
        requireWithErrorCode(isReinvestmentPossible(fromProject, toProject, tokenId, isCrypto, amountSrc, amountDst, true, fromProjEnd)); 
    }


    function isReinvestmentPossible(ProjectInvestImplementer.Project memory fromProject, 
                                ProjectInvestImplementer.Project memory toProject, 
                                uint16 tokenId, 
                                bool isCrypto, 
                                uint256 amountSrc, //amount is in the currency of the source project
                                uint256 amountDst, //amount is in the currency of the destination project
                                bool forSchedule, //if true, then the reinvestment is scheduled, false if executed
                                uint256 reinvestTimestamp ) internal view returns (uint8) {
        uint256 srcFunds = userInvestmentImplementer.getValue(tokenId, fromProject.id, isCrypto);
        if (forSchedule) {
            srcFunds = srcFunds * (10000 + fromProject.returnRate) / 10000;
        }
        uint256 availableSrcFunds = srcFunds - reinvestRequestImplementer.getTotalSumReinvested(tokenId, fromProject.id, isCrypto);
        uint8 invAllowedRetCode = investmentAllowed(toProject.id, tokenId, msg.sender, amountDst, reinvestTimestamp);
        if(invAllowedRetCode != ERR_CODE_SUCCESS) return invAllowedRetCode;
        if(availableSrcFunds < amountSrc) return ERR_INSUFFICIENT_FUNDS;
        return ERR_CODE_SUCCESS;
    }



    function addFiatInvestment(uint32 projectId, uint16 tokenId, address destWallet, uint256 netInv) external allowFiatInvest { //net investment should be passed. Any fee, if it exsists, should be handled by the caller.
        requireWithErrorCode(investmentAllowed(projectId, tokenId, destWallet, netInv, block.timestamp));
        _invest(projectId, tokenId, false, netInv);

        emit InvestEvent(INVEST_TYPE_FIAT, 0, projectId, tokenId, netInv, false, projectInvestImplementer.getProject(projectId).investmentCurrency);
    }

    //this is a function called by the owner of the SC to pay out the investors all at once.
    function payout(uint32 projectId, address safe) external onlyOwner {
        ProjectInvestImplementer.Project memory project = projectInvestImplementer.getProject(projectId); //throws error if project does not exist
        uint256 projectInvestment = projectInvestImplementer.getProjectTotalInvestment(projectId);
        require(projectInvestment > 0, "Project has no investments");
        require(block.timestamp > project.fundingEnd, "Project funding period is not over yet");
        bool projectFundingTargetReached = projectInvestment >= project.minFundingTarget;
        if(projectFundingTargetReached) { //project funding target failed, return investment
            require(block.timestamp >= project.fundingEnd + project.duration, "Project duration is not over yet");
        } 
        

        SimpleERC20Interface paymentToken = SimpleERC20Interface(project.erc20PaymentTokenAddress);
        require(paymentToken.balanceOf(safe) >= projectInvestImplementer.getProjectInvestment(projectId, true) * (10000 + project.returnRate) / 10000 , "Insufficient balance");
        uint16[] memory tokenIds = userInvestmentImplementer.getTokenIds(projectId);
        for(uint16 i = 0; i < tokenIds.length; i++){
            if(projectFundingTargetReached) {
                //1 - add return to user
                addReturn(project, tokenIds[i], true);
                addReturn(project, tokenIds[i], false);
            }

            //2// reinvestment
            uint32[] memory destProjects = reinvestRequestImplementer.getDestProjects(projectId, tokenIds[i]);
            for(uint32 j = 0; j < destProjects.length; j++){
                ProjectInvestImplementer.Project memory destProject;
                try projectInvestImplementer.getProject(destProjects[j]) returns (ProjectInvestImplementer.Project memory retrievedProject) {
                    destProject = retrievedProject;
                } catch {
                    continue;
                }
                if(projectFundingTargetReached) {
                    executeReinvest(tokenIds[i], project, destProject, true);
                    executeReinvest(tokenIds[i], project, destProject, false);
                } 
                clearReinvest(tokenIds[i], project, destProject, true);
                clearReinvest(tokenIds[i], project, destProject, false);
            }

            //3// crypto payout remaining after reinvestment
            uint256 remaining = userInvestmentImplementer.getValue(tokenIds[i], projectId, true);
            if(remaining > 0){
                userInvestmentImplementer.decrementValue(tokenIds[i], projectId, true, remaining);
                projectInvestImplementer.decrementProjectInvestment(projectId, true, remaining);
                if(projectFundingTargetReached){
                    paymentToken.transferFrom(safe, token.ownerOf(tokenIds[i]) , exchange(project.investmentCurrency, CURRENCY_USDC, remaining));
                    emit InvestEvent(INVEST_TYPE_PAYOUT_CRYPTO, projectId, 0, tokenIds[i], remaining, true, project.investmentCurrency);
                } else {
                    uint256 payedCrypto =  userInvestmentImplementer.getPayedCrypto(projectId, tokenIds[i], CURRENCY_USDC);
                    if(payedCrypto > 0) {
                        paymentToken.transferFrom(safe, token.ownerOf(tokenIds[i]) , payedCrypto);
                        userInvestmentImplementer.decrementPayedCrypto(projectId, tokenIds[i], CURRENCY_USDC, payedCrypto);
                        emit InvestEvent(INVEST_TYPE_PAYOUT_CRYPTO_FAILED_FUNDING, projectId, 0, tokenIds[i], payedCrypto, true, CURRENCY_USDC);
                    }
                }
            }
                

            //4// fiat payout remaining after reinvestment
            remaining = userInvestmentImplementer.getValue(tokenIds[i], projectId, false);
            if(remaining > 0){
                userInvestmentImplementer.decrementValue(tokenIds[i], projectId, false, remaining); 
                projectInvestImplementer.decrementProjectInvestment(projectId, false, remaining);
                userInvestmentImplementer.incrementFiatPayment(tokenIds[i],project.investmentCurrency, remaining);
                if(projectFundingTargetReached) {
                    emit InvestEvent(INVEST_TYPE_PAYOUT_FIAT, projectId, 0, tokenIds[i], remaining, false, project.investmentCurrency);
                }
                else {
                    emit InvestEvent(INVEST_TYPE_PAYOUT_FIAT_FAILED_FUNDING, projectId, 0, tokenIds[i], remaining, false, project.investmentCurrency);
                }
            }

        }
    }

    function addReturn(ProjectInvestImplementer.Project memory project, uint16 tokenId, bool isCrypto) internal {
        uint256 value = userInvestmentImplementer.getValue(tokenId, project.id, isCrypto);
        if(value > 0 ) {
            uint256 returnAmount = value * project.returnRate / 10000;
            userInvestmentImplementer.incrementValue(tokenId, project.id, isCrypto, returnAmount);
            projectInvestImplementer.incrementProjectInvestment(project.id, isCrypto, returnAmount);
            emit InvestEvent(INVEST_TYPE_PAYOUT_RETURN, project.id, 0, tokenId, returnAmount, isCrypto, project.investmentCurrency);
        }
    }

    function executeReinvest(uint16 tokenId, ProjectInvestImplementer.Project memory fromProj, ProjectInvestImplementer.Project memory toProj, bool isCrypto) internal {
        uint256 valueSrc = reinvestRequestImplementer.getValue(tokenId, fromProj.id, toProj.id, isCrypto, true);
        uint256 valueDst = reinvestRequestImplementer.getValue(tokenId, fromProj.id, toProj.id, isCrypto, false);
        if(valueSrc > 0 && valueDst > 0 ) {
            if(isReinvestmentPossible(fromProj, toProj, tokenId, isCrypto, valueSrc, valueDst, false, block.timestamp) == ERR_CODE_SUCCESS){
                userInvestmentImplementer.decrementValue(tokenId, fromProj.id, true, valueSrc); 
                projectInvestImplementer.decrementProjectInvestment(fromProj.id, true, valueSrc);
                if(isCrypto){
                    ProjectInvestImplementer.Project memory proj = projectInvestImplementer.getProject(toProj.id);
                    userInvestmentImplementer.incrementPayedCrypto(toProj.id, tokenId, toProj.investmentCurrency, exchange(proj.investmentCurrency, CURRENCY_USDC, valueSrc) );
                }
                _invest(toProj.id, tokenId, true, valueDst);
                emit InvestEvent(INVEST_TYPE_REINVEST, fromProj.id, toProj.id, tokenId, valueSrc, true, fromProj.investmentCurrency);
                if(isCrypto){
                    emit InvestEvent(INVEST_TYPE_CRYPTO, 0, toProj.id, tokenId, valueDst, true, toProj.investmentCurrency);
                } else {
                    emit InvestEvent(INVEST_TYPE_FIAT, 0, toProj.id, tokenId, valueDst, false, toProj.investmentCurrency);
                }
            }           
        }
    }

    function clearReinvest(uint16 tokenId, ProjectInvestImplementer.Project memory fromProj, ProjectInvestImplementer.Project memory toProj, bool isCrypto) internal {
        uint256 valueSrc = reinvestRequestImplementer.getValue(tokenId, fromProj.id, toProj.id, isCrypto, true);
        uint256 valueDst = reinvestRequestImplementer.getValue(tokenId, fromProj.id, toProj.id, isCrypto, false);
        if(valueSrc > 0 && valueDst > 0 ) {
            reinvestRequestImplementer.decrementValue(tokenId, fromProj.id, toProj.id, true, valueSrc, valueDst);
        }
    }

    function markFiatPaymentAsDone(uint16 tokenId, uint32 projectId, uint8 currency, uint256 value) external onlyOwner {
        require(userInvestmentImplementer.getFiatPayment(tokenId, currency) >= value && value > 0, "markFiatPaymentAsDone: insufficient fiat payment");
        userInvestmentImplementer.decrementFiatPayment(tokenId, currency, value);
        emit InvestEvent(INVEST_TYPE_PAYOUT_FIAT_DONE, projectId, 0, tokenId, value, false, currency);
    }

    function getTotalProjectInvestment(uint32 projectId) external view returns (uint256) {
        return projectInvestImplementer.getProjectTotalInvestment(projectId);
    }

    function getFiatTokenIdsToPay(uint8 currency) external view returns (uint16[] memory) {
        return userInvestmentImplementer.getFiatPaymentTokenIds(currency);
    }

    //user fiat balance per currency
    function getFiatPayment(uint16 tokenId, uint8 currency) external view returns (uint256) {
        return userInvestmentImplementer.getFiatPayment(tokenId, currency);
    }

    function exchange(uint8 sourceCurrency, uint8 destCurrency, uint256 amount) internal view returns (uint256){
        uint256 result = exchangeRegistry.exchange(sourceCurrency, destCurrency, amount);
        return round(result, 4);
    }

    function round(uint256 value, uint256 decimals) internal pure returns (uint256) { //decimals represent the number of decimals that need to be dropped. As fiat will only have 2 meaningful decimals, we drop 4 decimals
        uint256 divisor = 10 ** decimals; //10^4 = 10000
        uint256 roundValue = value / divisor; // floor the value (round down)
        uint256 remainder = value % divisor; // last 4 digits
        if (remainder >= divisor / 2) { // if the remainder is greater than or equal to 5000, round up
            roundValue += 1;
        }
        return roundValue * divisor; //add back the decimals as zeros
    }


    modifier allowFiatInvest(){
        require(msg.sender == owner() || allowedFiatInvest[msg.sender], "Invest not allowed");
        _;
    }

    function setAllowedOffChainInvest(address _address, bool _allowed) external onlyOwner {
        allowedFiatInvest[_address] = _allowed;
    }


    function requireWithErrorCode(uint8 error_code) pure internal{
        if(error_code == ERR_CODE_SUCCESS) return;
        if(error_code == ERR_PROJECT_DOES_NOT_EXIST) revert("Project does not exist");
        if(error_code == ERR_USER_NOT_ACTIVE_TOKEN) revert("User does not have an active token");
        if(error_code == ERR_FUNDING_NOT_STARTED) revert("Funding not started");
        if(error_code == ERR_FUNDING_ENDED) revert("Funding ended");
        if(error_code == ERR_INVESTMENT_BELOW_MIN) revert("Investment below min");
        if(error_code == ERR_INVESTMENT_ABOVE_MAX) revert("Investment above max");
        if(error_code == ERR_FUNDING_ABOVE_MAX) revert("Funding above max");
        if(error_code == ERR_INSUFFICIENT_FUNDS) revert("Insufficient funds");
        revert("Unknown error");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IExchangeRate.sol";

contract ExchangeRegistry is Ownable {
    uint8 constant public CURRENCY_EUR = 0;
    uint8 constant public CURRENCY_USD = 1;
    uint8 constant public CURRENCY_RON = 2;
    uint8 constant public CURRENCY_USDC = 128;

    mapping (uint8 => string) public currency; //id && symbol
    uint8 public crossCurrency; 
    mapping (uint8 => mapping (uint8 => address)) public exchangePairContracts; //fromCurrency => toCurrency => contractAddress

    event AddExchangePairContract(uint8 from, uint8 to, address indexed exchangePairContract);

    constructor() {
        setCrossCurrency(CURRENCY_RON); //RON
    }



    function setCrossCurrency(uint8 _currency) public onlyOwner{
        crossCurrency = _currency;
    }

    function addExchangePairContract(uint8 fromCurrency, uint8 toCurrency, address exchangePairContract) public onlyOwner {
        require(fromCurrency != toCurrency, "ExchangeRegistry: fromCurrency and toCurrency must be different");
        exchangePairContracts[fromCurrency][toCurrency] = exchangePairContract;
        emit AddExchangePairContract(fromCurrency, toCurrency, exchangePairContract);
    }

    function exchange(uint8 fromCurrency, uint8 toCurrency, uint256 amount) public view returns(uint256) {
        if(fromCurrency == CURRENCY_USDC) {
            fromCurrency = CURRENCY_USD;
        }
        if(toCurrency == CURRENCY_USDC) {
            toCurrency = CURRENCY_USD;
        }
        if(fromCurrency == toCurrency) {
            return amount;
        }
        if (exchangePairContracts[fromCurrency][toCurrency] != address(0) ) { //direct
            return IExchangeRate(exchangePairContracts[fromCurrency][toCurrency]).mul(amount);
        } 
        if(exchangePairContracts[toCurrency][fromCurrency] != address(0)){ //inverse
            return inverseRate(IExchangeRate(exchangePairContracts[toCurrency][fromCurrency]).getRate(), amount);
        } 
        if (exchangePairContracts[fromCurrency][crossCurrency] != address(0) && exchangePairContracts[toCurrency][crossCurrency] != address(0)) { //cross
                uint256 rate1 = IExchangeRate(exchangePairContracts[fromCurrency][crossCurrency]).getRate();
                uint256 rate2 = IExchangeRate(exchangePairContracts[toCurrency][crossCurrency]).getRate();
                return SafeMath.div(SafeMath.mul(amount, rate1), rate2);
        }
        
        revert("ExchangeRegistry: exchangePairContract must be set");        
    }

    function inverseRate(uint256 rate, uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 1e18), rate);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

interface IExchangeRate {
    function getRate() external view returns (uint256);
    function getLastUpdate() external view returns (uint256);

    function mul(uint256 a) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC721Token.sol";

interface ITraitRegistry {
    function hasTrait(uint16 traitID, uint16 tokenId) external view returns (bool result);
}

interface ITraitImplementer {
    function getValue(uint16 _tokenId) external view returns (uint8 value);
}


// 

contract ActivatableToken is ERC721Token {

    mapping(uint16 => uint8)        internal activatedTokenData;
    ITraitRegistry     public       TraitRegistry;
    ITraitImplementer  public       TraitImplementer;
    address         public          ManagerMultisigAddress;
    uint16          public constant TRAIT_ACTIVATED_ID = 1;
    uint8           public constant TRAIT_ACTIVATED_USER_CAN_TRANSFER = 0;
    uint8           public constant TRAIT_ACTIVATED_ADMIN_CAN_TRANSFER = 2;

    struct TokenConfig {
        string  _name;
        string  _symbol;
        string  _baseURL;     
        uint256 _maxSupply;
        bool    _transferLocked;
        address _TraitRegistryAddress;
        address _TraitImplementerAddress;
        address _ManagerMultisigAddress;
    }

    constructor(
        TokenConfig memory config
    ) ERC721Token(
        config._name,
        config._symbol,
        config._baseURL,
        config._maxSupply,
        config._transferLocked
    ) {
        TraitRegistry = ITraitRegistry(config._TraitRegistryAddress);
        TraitImplementer = ITraitImplementer(config._TraitImplementerAddress);
        ManagerMultisigAddress = config._ManagerMultisigAddress;

        // @TODO: may want to mint the first 50 - 100 here
        // mintIncrementalCards(50, msg.sender);
    }

    function updateContractAddresses(
        address _TraitRegistryAddress,
        address _TraitImplementerAddress,
        address _ManagerMultisigAddress
    ) public {
        require(msg.sender == ManagerMultisigAddress, "Token: Unauthorised");

        TraitRegistry = ITraitRegistry(_TraitRegistryAddress);
        TraitImplementer = ITraitImplementer(_TraitImplementerAddress);
        ManagerMultisigAddress = _ManagerMultisigAddress;
    }

    function canAdminTransferToken(uint256 _tokenId, address _adminAddress) public view returns (bool) {
        // Once a token requests activation it can only be moved by admin multisig
        if(
            TraitImplementer.getValue(uint16(_tokenId)) != TRAIT_ACTIVATED_USER_CAN_TRANSFER
            && _adminAddress == ManagerMultisigAddress
        ) {
            return true;
        }
        return false;
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId) || canAdminTransferToken(tokenId, msg.sender);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId,
        uint256 batchSize
    ) internal override {

        // ignore minting so we don't waste gas for no reason
        if(from != address(0)) {

            // Once a token requests activation it can only be moved by admin multisig
            if(TraitImplementer.getValue(uint16(_tokenId)) != TRAIT_ACTIVATED_USER_CAN_TRANSFER) {
                if(msg.sender == ManagerMultisigAddress) {
                    super._beforeTokenTransfer(from, to, _tokenId, batchSize);
                } else {
                    revert("Token: Activated token can only be moved by request to admin multisig!");
                }
            }
        }

        super._beforeTokenTransfer(from, to, _tokenId, batchSize);
    }

    struct ActivatableTokenInfo {
        TokenConfig     config;
        uint256         mintedSupply;
        uint256         totalSupply;
        uint256         version;
    }

    function tellEverything() external view returns (ActivatableTokenInfo memory) {

        return ActivatableTokenInfo(
            TokenConfig(
                name(),
                symbol(),
                baseURL,
                maxSupply,
                transferLocked,
                address(TraitRegistry),
                address(TraitImplementer),
                address(ManagerMultisigAddress)
            ),
            // computed and hardcoded values
            mintedSupply,
            totalSupply(),
            version
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IToken.sol";
import "../../interfaces/IRandomNumberProvider.sol";
import "../../interfaces/IRandomNumberRequester.sol";
import "../../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


contract ERC721Token is IToken, ERC721Enumerable, BlackHolePrevention {
    using Strings  for uint256;

    uint256             immutable   public maxSupply;
    uint256                         public mintedSupply;    // minted incrementally

    string                          public baseURL;
    string                          public contractURI;

    bool                            public transferLocked;
    mapping (address => bool)       public permitted;
    uint32                 constant public version = 2023012601;

    event Allowed(address, bool);
    event Locked(bool);
    event ContractURIset(string contractURI);

    constructor(
        string memory   _name, 
        string memory   _symbol,
        string memory   _baseURL,
        uint256         _maxSupply,
        bool            _transferLocked
    ) ERC721(_name, _symbol) {
        baseURL             = _baseURL;
        maxSupply           = _maxSupply;
        transferLocked      = _transferLocked;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId,
        uint256 batchSize
    ) internal virtual override {
        if(from != address(0)) {
            require(!transferLocked, "Token: Transfers are not enabled");
        }
        
        super._beforeTokenTransfer(from, to, _tokenId, batchSize);
    }

    /**
     * @dev Sale: mint cards.
     */
    function mintIncrementalCards(uint256 numberOfCards, address recipient) public onlyAllowed returns (uint256)  {
        require(mintedSupply + numberOfCards <= maxSupply, "Token: This would exceed the number of cards available");
        uint256 mintId = mintedSupply + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedSupply+=numberOfCards;
        return mintId;
    }

    /**
     * @dev Admin: set PreRevealURI
     */
    function setBaseURL(string calldata _baseURL) external onlyAllowed {
        baseURL = _baseURL;
    }

    /**
    * @dev Get metadata server url for tokenId
    */
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        require(_exists(_tokenId), 'Token: Token does not exist');
        string memory folder = (_tokenId % 100).toString(); 
        string memory file = _tokenId.toString();
        string memory ext = ".json";
        string memory slash = "/";
        return string(abi.encodePacked(baseURL, folder, slash, file, ext));
    }

    /**
     * @dev Admin: Lock / Unlock transfers
     */
    function setTransferLock(bool _locked) external onlyAllowed {
        transferLocked = _locked;
        emit Locked(_locked);
    }

    /**
     * @dev Admin: Allow / Dissalow addresses
     */
    function setAllowed(address _addr, bool _state) external onlyOwner {
        permitted[_addr] = _state;
        emit Allowed(_addr, _state);
    }

    function isAllowed(address _addr) public view returns(bool) {
        return permitted[_addr] || _addr == owner();
    }

    modifier onlyAllowed() {
        require(isAllowed(msg.sender), "Token: Unauthorised");
        _;
    }

    // function tellEverything() external view virtual returns (TokenInfo memory) {
        
    //     revealStruct[] memory _reveals = new revealStruct[](currentRevealCount);
    //     for(uint16 i = 1; i <= currentRevealCount; i++) {
    //         _reveals[i - 1] = reveals[i];
    //     }

    //     return TokenInfo(
    //         name(),
    //         symbol(),
    //         version,
    //         maxSupply,
    //         mintedSupply,
    //         tokenPreRevealURI,
    //         tokenRevealURI,
    //         transferLocked,
    //         lastRevealRequested,
    //         totalSupply(),
    //         _reveals
    //     );
    // }

    function getTokenInfoForSale() external view returns (TokenInfoForSale memory) {
        return TokenInfoForSale(
            version,
            totalSupply(),
            maxSupply
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct revealStruct {
    uint256 REQUEST_ID;
    uint256 RANDOM_NUM;
    uint256 SHIFT;
    uint256 RANGE_START;
    uint256 RANGE_END;
    bool processed;
}

struct TokenInfoForSale {
    uint256 _version;
    uint256 _mintedSupply;
    uint256 _maxSupply;
}

struct TokenInfo {
    string _name;
    string _symbol;
    uint256 _version;
    uint256 _maxSupply;
    uint256 _mintedSupply;
    string _tokenPreRevealURI;
    string _tokenRevealURI;
    bool _transferLocked;
    bool _lastRevealRequested;
    uint256 _totalSupply;
    revealStruct[] _reveals;
}

interface IToken {

    function mintIncrementalCards(uint256, address) external returns (uint256);

    function setBaseURL(string calldata) external;
    function tokenURI(uint256) external view returns (string memory);

    function setTransferLock(bool) external;
    function setAllowed(address, bool) external;
    function isAllowed(address) external view returns(bool);

    function getTokenInfoForSale() external view returns (TokenInfoForSale memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../TraitRegistryV3.sol";

contract ProjectInvestImplementer {
    uint8 public immutable implementerType = 7;    // logic
    uint16 public immutable traitId;
    string public version = "1.0.0";
    uint32 public reinvestCutOffTime = 60 * 60 * 24 * 7; //time before project end after wich reinvestments are not allowed
    uint32 public reinvestStartTime = 60 * 60 * 24 * 30; //time before project end after wich reinvestments are allowed
    uint8 internal constant EVENT_TYPE_NEW_PROJECT = 0;
    uint8 internal constant EVENT_TYPE_UPDATE_PROJECT = 1;

    event projectEvent(uint8 eventType, Project project, address destWallet, string uid);

    struct Project {
        uint8 investmentCurrency; // 0: EUR, 1: USD, 2: RON
        address erc20PaymentTokenAddress;
        uint256 minFundingTarget;
        uint256 maxFundingTarget;
        uint32 returnRate;
        uint256 fundingStart;
        uint256 fundingEnd;
        uint256 duration;
        uint32 feeRate;
        uint32 flatFee;
        uint256 minInvestmentPerUser;
        uint256 maxInvestmentPerUser;
        uint32 id; //id will be automatically overwritten when project is added to ensure uniqueness
    }
    
    TraitRegistryV3 public TraitRegistry;
    mapping(uint32=>Project) public projects;
    mapping(uint32=>mapping(bool => uint256)) public projectInvestments;
    mapping(uint32=>address) public projectWallets;
    uint32 public projectCount;

    constructor(address _registry, uint16 _traitId) {
        require(_registry != address(0), "ProjectInvestImplementer: Invalid registry address");
        traitId = _traitId;
        TraitRegistry = TraitRegistryV3(_registry);
    }

    function addProject(Project calldata _project, address destWallet, string calldata uid) external onlyAllowed validProject(_project) returns (uint32){
        require(destWallet != address(0), "ProjectInvestImplementer: Invalid destination wallet");

        projectCount++; //project id starts from 1. 0 id is reserved for non-existing projects
        projects[projectCount] = _project;
        projects[projectCount].id = projectCount; //overwrite id to ensure uniqueness
        projectWallets[projectCount] = destWallet;
        emit projectEvent(EVENT_TYPE_NEW_PROJECT, projects[projectCount], destWallet, uid);
        return projectCount;
    }

    function updateProject(Project calldata _project, address destWallet, uint32 projId) external onlyAllowed validProject(_project) {
        require(destWallet != address(0));
        require(_project.id == projId, "Invalid project id");
        projects[projId] = _project;
        projectWallets[projId] = destWallet;
        emit projectEvent(EVENT_TYPE_UPDATE_PROJECT, _project, destWallet, "");
    }

    function getProject(uint32 _projectId) external view returns (Project memory) {
        require(_projectId <= projectCount, "ProjectInvestImplementer: Project does not exist");
        return projects[_projectId];
    }

    function getProjectWallet(uint32 _projectId) external view returns (address) {
        require(_projectId <= projectCount, "ProjectInvestImplementer: Project does not exist");
        return projectWallets[_projectId];
    }

    function getProjectTotalInvestment(uint32 _projectId) external view returns (uint256) {
        return projectInvestments[_projectId][true] + projectInvestments[_projectId][false];
    }

    function getProjectInvestment(uint32 _projectId, bool isCrypto) external view returns (uint256) {
        return projectInvestments[_projectId][isCrypto];
    }

    function incrementProjectInvestment(uint32 _projectId, bool isCrypto, uint256 _value) external onlyAllowed {
        projectInvestments[_projectId][isCrypto] += _value;
    }

    function decrementProjectInvestment(uint32 _projectId, bool isCrypto, uint256 _value) external onlyAllowed {
        require(projectInvestments[_projectId][isCrypto] >= _value, "ProjectInvestImplementer: Not enough investment");
        projectInvestments[_projectId][isCrypto] -= _value;
    }

    function updateReinvestInterval(uint32 reinvestStart, uint32 reinvestCutoff) external onlyAllowed {
        reinvestStartTime = reinvestStart;
        reinvestCutOffTime = reinvestCutoff;
    }



    modifier onlyAllowed() {
        require(
            TraitRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Implementer: Not Authorised" 
        );
        _;
    }

    modifier validProject(Project calldata _project) {
        require(_project.fundingEnd > _project.fundingStart, "ProjectInvestImplementer: Invalid funding end");
        require(_project.minFundingTarget > 0, "ProjectInvestImplementer: Invalid min funding target");
        require(_project.maxFundingTarget > _project.minFundingTarget, "ProjectInvestImplementer: Invalid max funding target");
        require(_project.minInvestmentPerUser > 0, "ProjectInvestImplementer: Invalid min investment per user");
        require(_project.maxInvestmentPerUser > _project.minInvestmentPerUser, "ProjectInvestImplementer: Invalid max investment per user");
        require(_project.duration > 0, "ProjectInvestImplementer: Invalid duration");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../TraitRegistryV3.sol";

contract ReinvestRequestImplementer {
    
    uint8 public immutable implementerType = 7;    // logic
    uint16 public immutable traitId;
    string public version = "1.0.0";

    TraitRegistryV3 public TraitRegistry;
    mapping ( uint32 => mapping ( uint16 => mapping (uint32 => mapping ( bool => uint256) ) ) ) public dataUserReinvetmentsSrcCurrency; //fromProjId=>tokenId=>toProjId=>isCrypto=>value
    mapping ( uint32 => mapping ( uint16 => mapping (uint32 => mapping ( bool => uint256) ) ) ) public dataUserReinvetmentsDstCurrency; //fromProjId=>tokenId=>toProjId=>isCrypto=>value
    mapping ( uint32 => mapping ( uint16 => uint32[] ) ) public dataDestProjects; //fromProjId=>tokenId=>toProjId[]

    constructor(address _registry, uint16 _traitId) {
        traitId = _traitId;
        TraitRegistry = TraitRegistryV3(_registry);
    }
    
    function incrementValue(uint16 tokenId, uint32 fromProjId, uint32 toProjId, bool isCrypto, uint256 valueSrc, uint256 valueDst) public onlyAllowed {
        if (dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][isCrypto] == 0) {
            dataDestProjects[fromProjId][tokenId].push(toProjId);
        }
        dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][isCrypto] += valueSrc;
        dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][isCrypto] += valueDst;
    }

    function decrementValue(uint16 tokenId, uint32 fromProjId, uint32 toProjId, bool isCrypto, uint256 valueSrc, uint256 valueDst) public onlyAllowed {
        require(dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][isCrypto] >= valueSrc, "ReinvestImplementer: Not enough reinvestment src");
        require(dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][isCrypto] >= valueDst, "ReinvestImplementer: Not enough reinvestment dst");
        dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][isCrypto] -= valueSrc;
        dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][isCrypto] -= valueDst;
        if((dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][false] == 0 && dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][true] == 0) ||
            (dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][false] == 0 && dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][true] == 0)) {
            require(dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][false] == 0 && dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][true] == 0, "ReinvestImplementer: if source reinvest is 0, destination reinvest must be 0");
            require(dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][false] == 0 && dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][true] == 0, "ReinvestImplementer: if destination reinvest is 0, source reinvest must be 0");

            uint32[] storage destProjects = dataDestProjects[fromProjId][tokenId];
            for (uint i = 0; i < destProjects.length; i++) {
                if (destProjects[i] == toProjId) {
                    destProjects[i] = destProjects[destProjects.length - 1];
                    destProjects.pop();
                    break;
                }
            }
        }

    }

    function getValue(uint16 tokenId, uint32 fromProjId, uint32 toProjId, bool isCrypto, bool isSource) public view returns (uint256) {
        if (isSource) {
            return dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][isCrypto];
        } else {
            return dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][isCrypto];
        }
    }

    function getTotalSumReinvested(uint16 tokenId, uint32 fromProjId, bool isCrypto) public view returns (uint256) {
        uint256 totalReinvest = 0;
        uint32[] storage destProjects = dataDestProjects[fromProjId][tokenId];
        for (uint i = 0; i < destProjects.length; i++) {
            totalReinvest += dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][destProjects[i]][isCrypto];
        }
        return totalReinvest;
    }

    function getUserTotalReinvest(uint16 tokenId, uint32 fromProjId, bool isSource) public view returns (uint256) {
        uint256 totalReinvest = 0;
        uint32[] storage destProjects = dataDestProjects[fromProjId][tokenId];
        for (uint i = 0; i < destProjects.length; i++) {
            if(isSource) {
                totalReinvest += dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][destProjects[i]][false];
                totalReinvest += dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][destProjects[i]][true];
            } else {
                totalReinvest += dataUserReinvetmentsDstCurrency[fromProjId][tokenId][destProjects[i]][false];
                totalReinvest += dataUserReinvetmentsDstCurrency[fromProjId][tokenId][destProjects[i]][true];
            }
        }
        return totalReinvest;
    }

    function getUserTotalReinvestToProj(uint16 tokenId, uint32 fromProjId, uint32 toProjId, bool isSource) public view returns (uint256) {
        if(isSource) {
            return dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][false] + dataUserReinvetmentsSrcCurrency[fromProjId][tokenId][toProjId][true];
        } else {
            return dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][false] + dataUserReinvetmentsDstCurrency[fromProjId][tokenId][toProjId][true];
        }
    }

    function getDestProjects(uint32 fromProjId, uint16 tokenId) public view returns (uint32[] memory) {
        return dataDestProjects[fromProjId][tokenId];
    }

    modifier onlyAllowed() {
        require(
            TraitRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Implementer: Not Authorised" 
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../TraitRegistryV3.sol";

contract TraitUint8ValueImplementer {

    uint8           public immutable    implementerType = 3;    // uint8
    uint16          public immutable    traitId;
    TraitRegistryV3 public              TraitRegistry;

    //  tokenID => uint value
    mapping(uint16 => uint8) public data;

    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(address _registry, uint16 _traitId) {
        traitId = _traitId;
        TraitRegistry = TraitRegistryV3(_registry);
    }

    // update multiple token values at once
    function setData(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    // update one
    function setValue(uint16 _tokenId, uint8 _value) public onlyAllowed {
        data[_tokenId] = _value;
        emit updateTraitEvent(_tokenId, _value);
    }

    function getValue(uint16 _tokenId) public view returns (uint8) {
         return data[_tokenId];
    }

    function getValues(uint16 _start, uint16 _len) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_len);
        for(uint16 i = _start; i < _len; i++) {
            retval[i] = data[i];
        }
        return retval;
    }

    modifier onlyAllowed() {
        require(
            TraitRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Implementer: Not Authorised" 
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../TraitRegistryV3.sol";

contract UserInvestmentImplementer {
    uint8 public constant implementerType = 7;    // logic
    uint16 public immutable traitId;
    string public version = "1.0.0";

    TraitRegistryV3 public TraitRegistry;
    mapping (uint16 => mapping (uint32 => mapping (bool => uint256))) public dataTokensToProjects; //tokenId=>projectId=>fiat/crypto=>value
    mapping (uint32 => uint16[]) public tokenIds;
    mapping (uint16 => mapping (uint8 => uint256)) public fiatPayment; //tokenId=> currencyId => value
    mapping (uint32 => mapping (uint16 => mapping (uint8 => uint256))) public payedCrypto; //projectId=>tokenId=>currencyId=>value //USDC = 128 - only crypto accepted for now
    mapping (uint8 => uint16[]) public tokenIdsByFiatCurrency; //currencyId => tokenIds

    constructor(address _registry, uint16 _traitId) {
        traitId = _traitId;
        TraitRegistry = TraitRegistryV3(_registry);
    }


    function incrementValue(uint16 _tokenId, uint32 _projectId, bool _isCrypto, uint256 _value) public onlyAllowed {
        if(dataTokensToProjects[_tokenId][_projectId][true] == 0 && dataTokensToProjects[_tokenId][_projectId][false] == 0  && _value != 0) {
            tokenIds[_projectId].push(_tokenId);
        }
        dataTokensToProjects[_tokenId][_projectId][_isCrypto] += _value;
    }

    function decrementValue(uint16 _tokenId, uint32 _projectId, bool _isCrypto, uint256 _value) public onlyAllowed {
        require(dataTokensToProjects[_tokenId][_projectId][_isCrypto] >= _value, "UserInvestmentImplementer: Not enough investment");
        dataTokensToProjects[_tokenId][_projectId][_isCrypto] -= _value;
        if(dataTokensToProjects[_tokenId][_projectId][true] == 0 && dataTokensToProjects[_tokenId][_projectId][false] == 0 ) {
            uint16[] storage ids = tokenIds[_projectId];
            for(uint16 i = 0; i < ids.length; i++) {
                if(ids[i] == _tokenId) {
                    ids[i] = ids[ids.length - 1];
                    ids.pop();
                    break;
                }
            }
        }
    }

    function incrementFiatPayment(uint16 _tokenId, uint8 _currencyId, uint256 _value) public onlyAllowed {
        if(_value > 0) {
            if(fiatPayment[_tokenId][_currencyId] == 0) {
                tokenIdsByFiatCurrency[_currencyId].push(_tokenId);
            }   
            fiatPayment[_tokenId][_currencyId] += _value;
        }
    }

    function decrementFiatPayment(uint16 _tokenId, uint8 _currencyId, uint256 _value) public onlyAllowed {
        require(fiatPayment[_tokenId][_currencyId] >= _value, "UserInvestmentImplementer: Not enough fiat");
        fiatPayment[_tokenId][_currencyId] -= _value;
        if(fiatPayment[_tokenId][_currencyId] == 0) {
            uint16[] storage ids = tokenIdsByFiatCurrency[_currencyId];
            for(uint16 i = 0; i < ids.length; i++) {
                if(ids[i] == _tokenId) {
                    ids[i] = ids[ids.length - 1];
                    ids.pop();
                    break;
                }
            }
        }
    }

    function getFiatPaymentTokenIds(uint8 _currencyId) public view returns (uint16[] memory) {
        return tokenIdsByFiatCurrency[_currencyId];
    }

    function getFiatPayment(uint16 _tokenId, uint8 _currencyId) public view returns (uint256) {
        return fiatPayment[_tokenId][_currencyId];
    }

    function getValue(uint16 _tokenId, uint32 _projectId, bool _isCrypto) public view returns (uint256) {
        return dataTokensToProjects[_tokenId][_projectId][_isCrypto];
    }

    function getUserTotalInvest(uint16 _tokenId, uint32 _projectId) public view returns (uint256) {
        return dataTokensToProjects[_tokenId][_projectId][true] + dataTokensToProjects[_tokenId][_projectId][false];
    }

    function getValues(uint16 _tokenId, uint32[] memory _projectIds, bool _isCrypto) public view returns (uint256[] memory) {
        uint256[] memory retval = new uint256[](_projectIds.length);
        for(uint16 i = 0; i < _projectIds.length; i++) {
            retval[i] = dataTokensToProjects[_tokenId][_projectIds[i]][_isCrypto];
        }
        return retval;
    }

    function getTokenIds(uint32 _projectId) public view returns (uint16[] memory) {
        return tokenIds[_projectId];
    }

    function incrementPayedCrypto(uint32 _projectId, uint16 _tokenId, uint8 _currencyId, uint256 _value) external onlyAllowed {
        payedCrypto[_projectId][_tokenId][_currencyId] += _value;
    }

    function decrementPayedCrypto(uint32 _projectId, uint16 _tokenId, uint8 _currencyId, uint256 _value) external onlyAllowed {
        require(payedCrypto[_projectId][_tokenId][_currencyId] >= _value, "UserInvestmentImplementer: Not enough crypto");
        payedCrypto[_projectId][_tokenId][_currencyId] -= _value;
    }

    function getPayedCrypto(uint32 _projectId, uint16 _tokenId, uint8 _currencyId) public view returns (uint256) {
        return payedCrypto[_projectId][_tokenId][_currencyId];
    }


    modifier onlyAllowed() {
        require(
            TraitRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Implementer: Not Authorised" 
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TraitRegistryV3 is Ownable {

    struct traitStruct {
        uint16  id;
        uint8   traitType;       
        // internal 0 for normal, 1 for inverted, 2 for inverted range,
        // external 3 uint8 values, 4 uint256 values, 5 bytes32, 6 string 
        // external 7 uint8 custom logic
        uint16  start;
        uint16  end;
        address implementer;     // address of the smart contract that will implement extra functionality
        bool    enabled;         // frontend decides if it wants to hide or not
        string  name;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;

    // token data
    mapping(uint16 => mapping(uint16 => uint8) ) public tokenData;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractController;

    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;

    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;


    /*
    *   Events
    */
    event contractControllerEvent(address _address, bool mode);
    event traitControllerEvent(address _address);
    
    // traits
    event newTraitEvent(string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end );
    event updateTraitEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitDataEvent(uint16 indexed _id);
    // tokens
    event tokenTraitChangeEvent(uint16 indexed _traitId, uint16 indexed _tokenId, bool mode);

    function getTraits() public view returns (traitStruct[] memory)
    {
        traitStruct[] memory retval = new traitStruct[](traitCount);
        for(uint16 i = 0; i < traitCount; i++) {
            retval[i] = traits[i];
        }
        return retval;
    }

    function addTrait(
        traitStruct[] calldata _newTraits
    ) public onlyAllowed {

        for (uint8 i = 0; i < _newTraits.length; i++) {

            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.id =           _newTraits[i].id;
            newT.name =         _newTraits[i].name;
            newT.traitType =    _newTraits[i].traitType;
            newT.start =        _newTraits[i].start;
            newT.end =          _newTraits[i].end;
            newT.implementer =  _newTraits[i].implementer;
            newT.enabled =      _newTraits[i].enabled;

            emit newTraitEvent(newT.name, newT.implementer, newT.traitType, newT.start, newT.end );
            setTraitControllerAccess(address(newT.implementer), newTraitId, true);
            setTraitControllerAccess(owner(), newTraitId, true);
        }
    }

    function updateTrait(
        uint16 _traitId,
        string memory _name,
        address _implementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end,
        bool    _enabled
    ) public onlyAllowed {
        traits[_traitId].name = _name;
        traits[_traitId].implementer = _implementer;
        traits[_traitId].traitType = _traitType;
        traits[_traitId].start = _start;
        traits[_traitId].end = _end;
        traits[_traitId].enabled = _enabled;
        
        emit updateTraitEvent(_traitId, _name, _implementer, _traitType, _start, _end);
    }

    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) {
        _setTrait(traitID, tokenId, _value);
    }

    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) public onlyTraitController(traitID) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _setTrait(traitID, tokenIds[i], _value[i]);
        }
    }

    function _setTrait(uint16 traitID, uint16 tokenId, bool _value) internal {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
        } else {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
        }
        emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
    }

    // set trait data
    function setData(uint16 traitId, uint16[] calldata _ids, uint8[] calldata _data) public onlyTraitController(traitId) {
        for (uint16 i = 0; i < _data.length; i++) {
            tokenData[traitId][_ids[i]] = _data[i];
        }
        emit updateTraitDataEvent(traitId);
    }

    /*
    *   View Methods
    */

    /*
    * _perPage = 1250 in order to load 10000 tokens ( 10000 / 8; starting from 0 )
    */
    function getData(uint16 traitId, uint8 _page, uint16 _perPage) public view returns (uint8[] memory) {
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues = new uint8[](max);
        while(i < max) {
            retValues[j] = tokenData[traitId][i];
            j++;
            i++;
        }
        return retValues;
    }

    function getTokenData(uint16 tokenId) public view returns (uint8[] memory) {
        uint8[] memory retValues = new uint8[](getByteCountToStoreTraitData());
        // calculate positions for our token
        for(uint16 i = 0; i < traitCount; i++) {
            if(hasTrait(i, tokenId)) {
                uint8 byteNum = uint8(i / 8);
                retValues[byteNum] = uint8(retValues[byteNum] | 2 ** uint8(i - byteNum * 8));
            }
        }
        return retValues;
    }

    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _returnCount = getByteCountToStoreTraitData();
        uint8[] memory retValues = new uint8[](_returnCount);
        for(uint8 i = 0; i < _returnCount; i++) {
            retValues[i] = traitControllerAccess[_addr][i];
        }
        return retValues;
    }

    function getByteCountToStoreTraitData() internal view returns (uint16) {
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < traitCount) {
            _returnCount++;
        }
        return _returnCount;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].implementer;
    }

    function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result)
    {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        bool _result = tokenData[traitID][byteNum] & (0x01 * 2**bitPos) != 0;
        bool _returnVal = (traits[traitID].traitType == 1) ? !_result: _result;
        if(traits[traitID].traitType == 2) {
            // range trait
            if(traits[traitID].start <= tokenId && tokenId <= traits[traitID].end) {
                _returnVal = !_result;
            }
        }
        return _returnVal;
    }

    /*
    *   Admin Stuff
    */

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        emit traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        emit traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }
    
    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "Not Authorised"
        );
        _;
    }
}