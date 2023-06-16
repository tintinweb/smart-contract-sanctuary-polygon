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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token with automatic token ID handling.
 * @notice Token ID is automatically incremented when minting a new one
 */
abstract contract ERC721AutoId is ERC721 {
    using Counters for Counters.Counter;

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Current token ID
    Counters.Counter private _nextTokenId;

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     */
    constructor() {
        _nextTokenId.increment();
    }

    //=============================================================//
    //                      PUBLIC FUNCTIONS                       //
    //=============================================================//

    /**
     * Get total token supply
     * @return Total token supply
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Safe mint to `to_`
     * @param to_ Receiver address
     */
    function _safeMintTo(
        address to_
    ) internal virtual {
        uint256 curr_token_id = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to_, curr_token_id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "./ERC721AutoId.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token with maximum supply handling
 * @notice Supply can be increased or freezed to prevent future modifications
 */
abstract contract ERC721Capped is
    ERC721AutoId
{
    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Flag to freeze maximum supply
    bool public maxSupplyFreezed;
    /// Maximum supply
    uint256 public maxSupply;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if maximum supply is freezed
     */
    error MaxSupplyFreezedError();

    /**
     * Error raised if maximum supply is reached
     */
    error MaxSupplyReachedError(
        uint256 value
    );

    /**
     * Error raised if maximum supply value `value` is not valid
     */
    error MaxSupplyInvalidValueError(
        uint256 value
    );

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when maximum supply is freezed
     */
    event MaxSupplyFreezed(
        uint256 currValue
    );

    /**
     * Event emitted when maximum supply is increased
     */
    event MaxSupplyIncreased(
        uint256 oldValue,
        uint256 newValue
    );

    //=============================================================//
    //                          MODIFIERS                          //
    //=============================================================//

    /**
     * Modifier to make a function callable only when the maximum supply is not freezed.
     * Require maximum supply to be not freezed.
     */
    modifier whenUnfreezedMaxSupply() {
        if (maxSupplyFreezed) {
            revert MaxSupplyFreezedError();
        }
        _;
    }

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     * @param maxSupply_ Token maximum supply
     */
    constructor(
        uint256 maxSupply_
    ) {
        if (maxSupply_ == 0) {
            revert MaxSupplyInvalidValueError(maxSupply_);
        }

        maxSupplyFreezed = false;
        maxSupply = maxSupply_;
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Freeze maximum supply
     */
    function _freezeMaxSupply() internal whenUnfreezedMaxSupply {
        maxSupplyFreezed = true;

        emit MaxSupplyFreezed(maxSupply);
    }

    /**
     * Increase maximum supply to `maxSupply_`
     * @param maxSupply_ New maximum supply
     */
    function _increaseMaxSupply(
        uint256 maxSupply_
    ) internal whenUnfreezedMaxSupply {
        if (maxSupply_ <= maxSupply) {
            revert MaxSupplyInvalidValueError(maxSupply_);
        }

        uint256 old_value = maxSupply;
        maxSupply = maxSupply_;

        emit MaxSupplyIncreased(old_value, maxSupply_);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * Check maximum supply when minting.
     * See {ERC721-_mint}
     */
    function _mint(
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        if (tokenId_ > maxSupply) {
            revert MaxSupplyReachedError(maxSupply);
        }
        super._mint(to_, tokenId_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4906.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token that stores and handles a multiple URIs
 * @notice Both base URI and contract URI can be set. A custom URI for a specific token ID can also be set.
 *         URIs can be freezed to prevent future modifications.
 */
abstract contract ERC721MultipleURIStorage is
    ERC721,
    IERC4906
{
    //=============================================================//
    //                          CONSTANTS                          //
    //=============================================================//

    /// Default name for contract metadata
    string constant private CONTRACT_DEFAULT_METADATA = "contract";

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Flag to indicate if the URI is freezed or not
    bool public uriFreezed;
    /// Base URI
    string public baseURI;
    /// Contract URI
    string public contractURI;
    /// Mapping from token ID to specific token URI
    mapping(uint256 => string) private _tokenURIs;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if URI is empty
     */
    error UriEmptyError();

    /**
     * Error raised if URI is freezed
     */
    error UriFreezedError();

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when URI is freezed
     */
    event UriFreezed(
        string baseURI,
        string contractURI
    );

    /**
     * Event emitted when URI is changed
     */
    event UriChanged(
        string oldURI,
        string newURI
    );

    /**
     * Event emitted when a token URI is changed
     */
    event TokenUriChanged(
        uint256 tokenId,
        string oldURI,
        string newURI
    );

    //=============================================================//
    //                          MODIFIERS                          //
    //=============================================================//

    /**
     * Modifier to make a function callable only if the URI `uri_` is not empty
     * Require URI `uri_` to be not empty.
     * @param uri_ URI
     */
    modifier notEmptyURI(
        string memory uri_
    ) {
        if (bytes(uri_).length == 0) {
            revert UriEmptyError();
        }
        _;
    }

    /**
     * Modifier to make a function callable only when the URI is not freezed
     * Require URI to be not freezed.
     */
    modifier whenUnfreezedUri() {
        if (uriFreezed) {
            revert UriFreezedError();
        }
        _;
    }

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     * @param baseURI_ Base URI
     */
    constructor(
        string memory baseURI_
    ) {
        uriFreezed = false;

        _setBaseURI(baseURI_);
        _setContractURI(string(abi.encodePacked(baseURI_, CONTRACT_DEFAULT_METADATA)));
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Freeze URI
     */
    function _freezeURI() internal whenUnfreezedUri {
        uriFreezed = true;

        emit UriFreezed(baseURI, contractURI);
    }

    /**
     * Set base URI to `baseURI_`
     * @param baseURI_ Base URI
     */
    function _setBaseURI(
        string memory baseURI_
    ) internal whenUnfreezedUri {
        string memory old_uri = baseURI;
        baseURI = baseURI_;

        emit UriChanged(old_uri, baseURI);

        _updateEntireCollectionMetadata();
    }

    /**
     * Set contract URI to `contractURI_`
     * @param contractURI_ Contract URI
     */
    function _setContractURI(
        string memory contractURI_
    ) internal whenUnfreezedUri {
        string memory old_uri = contractURI;
        contractURI = contractURI_;

        emit UriChanged(old_uri, contractURI);
    }

    /**
     * Set URI of token ID `tokenId_` to `URI_`
     * @param tokenId_ Token ID
     * @param URI_     URI
     */
    function _setTokenURI(
        uint256 tokenId_,
        string memory URI_
    ) internal whenUnfreezedUri {
        string memory old_uri = _tokenURIs[tokenId_];
        _tokenURIs[tokenId_] = URI_;

        emit TokenUriChanged(tokenId_, old_uri, URI_);

        _updateSingleTokenMetadata(tokenId_);
    }

    /**
     * Update metadata of token `tokenId_`
     * @param tokenId_ Token ID
     */
    function _updateSingleTokenMetadata(
        uint256 tokenId_
    ) internal {
        emit MetadataUpdate(tokenId_);
    }

    /**
     * Update metadata of the entire collection
     */
    function _updateEntireCollectionMetadata() internal {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC721-_baseURI}
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * See {ERC721-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        string memory token_uri = _tokenURIs[tokenId_];
        if (bytes(token_uri).length > 0) {
            return token_uri;
        }
        return super.tokenURI(tokenId_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "./ERC721MultipleURIStorage.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token that stores and handles a single URI with the possibility to reveal it
 * @notice URIs can be revealed all in one go or one by one
 */
abstract contract ERC721RevealableMultipleURIStorage is
    ERC721MultipleURIStorage
{
    //=============================================================//
    //                          CONSTANTS                          //
    //=============================================================//

    /// Default name for unrevealed URI metadata
    string constant private UNREVEALED_DEFAULT_METADATA = "unrevealed";

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Mapping from token ID to revealed flag
    /// If true, the URI of the specific token ID is revealed
    mapping(uint256 => bool) public tokenURIsRevealed;
    /// Flag to indicate if URIs revealing is enabled or not
    bool public revealingURIsEnabled;
    /// Flag to indicate if all URIs are revealed or not
    bool public allURIsRevealed;
    /// Unrevealed URI
    string public unrevealedURI;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if URIs revealing is enabled or disabled
     */
    error URIsRevealingEnabledError();

    /**
     * Error raised if all URIs are revealed
     * @param tokenId Token ID
     */
    error SingleURIRevealedError(
        uint256 tokenId
    );

    /**
     * Error raised if all URIs are revealed
     */
    error AllURIsRevealedError();

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when URIs revealing is enabled
     */
    event URIsRevealingEnabled();

    /**
     * Event emitted when the URI of token `tokenId` is revealed
     * @param tokenId Token ID
     */
    event SingleURIRevealed(
        uint256 tokenId
    );

    /**
     * Event emitted when all URIs are revealed
     */
    event AllURIsRevealed();

    //=============================================================//
    //                          MODIFIERS                          //
    //=============================================================//

    /**
     * Modifier to make a function callable only when URIs revealing is enabled
     */
    modifier whenURIsRevealingEnabled() {
        if (!revealingURIsEnabled) {
            revert URIsRevealingEnabledError();
        }
        _;
    }

    /**
     * Modifier to make a function callable only when all URIs are not revealed
     */
    modifier whenNotAllURIsAreRevealed() {
        if (allURIsRevealed) {
            revert AllURIsRevealedError();
        }
        _;
    }

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     * @param baseURI_ Base URI
     */
    constructor(
        string memory baseURI_
    ) ERC721MultipleURIStorage(baseURI_) {
        allURIsRevealed = false;
        revealingURIsEnabled = false;

        _setUnrevealedURI(string(abi.encodePacked(baseURI_, UNREVEALED_DEFAULT_METADATA)));
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Set unrevealed URI to `unrevealedURI_`
     * @param unrevealedURI_ Unrevealed URI
     */
    function _setUnrevealedURI(
        string memory unrevealedURI_
    ) internal whenNotAllURIsAreRevealed {
        string memory old_uri = unrevealedURI;
        unrevealedURI = unrevealedURI_;

        emit UriChanged(old_uri, unrevealedURI);

        _updateEntireCollectionMetadata();
    }

    /**
     * Enable revealing URIs
     */
    function _enableURIsRevealing() internal whenNotAllURIsAreRevealed {
        if (revealingURIsEnabled) {
            revert URIsRevealingEnabledError();
        }

        revealingURIsEnabled = true;

        emit URIsRevealingEnabled();
    }

    /**
     * Reveal URI of single token `tokenId_`
     * @param tokenId_ Token ID
     */
    function _revealSingleURI(
        uint256 tokenId_
    ) internal whenURIsRevealingEnabled whenNotAllURIsAreRevealed {
        if (tokenURIsRevealed[tokenId_]) {
            revert SingleURIRevealedError(tokenId_);
        }

        tokenURIsRevealed[tokenId_] = true;

        emit SingleURIRevealed(tokenId_);

        _updateSingleTokenMetadata(tokenId_);
    }

    function unrevealSingleURI(
        uint256 tokenId_
    ) public whenURIsRevealingEnabled whenNotAllURIsAreRevealed {
        if (!tokenURIsRevealed[tokenId_]) {
            revert SingleURIRevealedError(tokenId_);
        }

        tokenURIsRevealed[tokenId_] = false;

        _updateSingleTokenMetadata(tokenId_);
    }


    /**
     * Reveal all URIs
     */
    function _revealAllURIs() internal whenURIsRevealingEnabled whenNotAllURIsAreRevealed {
        allURIsRevealed = true;

        emit AllURIsRevealed();

        _updateEntireCollectionMetadata();
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC721-tokenURI}
     */
    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        if (!allURIsRevealed && !tokenURIsRevealed[tokenId_]) {
            return unrevealedURI;
        }
        return super.tokenURI(tokenId_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token with the possibility to pause transfers in a selective way
 * @notice Transfers can be paused for all but some addresses or only for some addresses
 */
abstract contract ERC721SelectivePausable is
    ERC721,
    Pausable
{
    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Mapping from wallet address to the unpaused status
    /// If true, the wallet can transfer tokens when paused
    mapping(address => bool) public unpausedWallets;
    /// Mapping from wallet address to the paused status
    /// If true, the wallet cannot transfer tokens
    mapping(address => bool) public pausedWallets;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if a transfer is made by a paused wallet
     */
    error TransferByPausedWalletError();

    /**
     * Error raised if a transfer is made while paused
     */
    error TransferWhilePausedError();

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when a paused wallet status is changed
     */
    event PausedWalletStatusChanged(
        address walletAddress,
        bool status
    );

    /**
     * Event emitted when an unpaused wallet status is changed
     */
    event UnpausedWalletStatusChanged(
        address walletAddress,
        bool status
    );

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Set the status of paused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet cannot transfer tokens, false otherwise
     */
    function _setPausedWallet(
        address wallet_,
        bool status_
    ) internal {
        pausedWallets[wallet_] = status_;

        emit PausedWalletStatusChanged(wallet_, status_);
    }

    /**
     * Set the status of unpaused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet can transfer tokens when paused, false otherwise
     */
    function _setUnpausedWallet(
        address wallet_,
        bool status_
    ) internal {
        unpausedWallets[wallet_] = status_;

        emit UnpausedWalletStatusChanged(wallet_, status_);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC721-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);

        // Do not check address zero (in case of burning)
        if (to_ == address(0)) {
            return;
        }

        // Revert if paused wallet
        if (pausedWallets[from_]) {
            revert TransferByPausedWalletError();
        }

        // Revert if transfer while paused and wallet is not paused
        if (!unpausedWallets[from_] && paused()) {
            revert TransferWhilePausedError();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  ERC721 token with the possibility to limit the maximum number of token owned by each wallet
 */
abstract contract ERC721WalletCapped is
    ERC721
{
    //=============================================================//
    //                         STRUCTURES                          //
    //=============================================================//

    /// Data for wallet maximum number of tokens
    struct WalletMaxTokens {
        uint256 maxTokens;
        bool isSet;
    }

    //=============================================================//
    //                           STORAGE                           //
    //=============================================================//

    /// Mapping from wallet address to the maximum number of ownable tokens
    mapping(address => WalletMaxTokens) public walletsMaxTokens;
    /// Default maximum number of tokens if address is not in the mapping
    uint256 public defaultWalletMaxTokens;

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if default wallet maximum number of tokens is reached
     */
    error DefaultWalletMaxTokensReachedError(
        uint256 maxValue
    );

    /**
     * Error raised if specific wallet maximum number of tokens is reached
     */
    error WalletMaxTokensReachedError(
        uint256 maxValue
    );

    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * Event emitted when default maximum number of tokens is changed
     */
    event DefaultMaxTokensChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * Event emitted when maximum number of tokens for a wallet is changed
     */
    event WalletMaxTokensChanged(
        address walletAddress,
        uint256 oldValue,
        uint256 newValue
    );

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     */
    constructor() {
        defaultWalletMaxTokens = type(uint256).max;
    }

    //=============================================================//
    //                     INTERNAL FUNCTIONS                      //
    //=============================================================//

    /**
     * Set the maximum number of tokens for the wallet `wallet_` to `maxTokens_`
     * @param wallet_    Wallet address
     * @param maxTokens_ Maximum number of tokens
     */
    function _setWalletMaxTokens(
        address wallet_,
        uint256 maxTokens_
    ) internal {
        uint256 old_value = walletsMaxTokens[wallet_].maxTokens;

        WalletMaxTokens storage wallet_max_tokens = walletsMaxTokens[wallet_];

        wallet_max_tokens.isSet = true;
        wallet_max_tokens.maxTokens = maxTokens_;

        emit WalletMaxTokensChanged(wallet_, old_value, maxTokens_);
    }

    /**
     * Set the default wallet maximum number of tokens to `maxTokens_`
     * @param maxTokens_ Maximum number of tokens
     */
    function _setDefaultWalletMaxTokens(
        uint256 maxTokens_
    ) internal {
        uint256 old_value = defaultWalletMaxTokens;
        defaultWalletMaxTokens = maxTokens_;

        emit DefaultMaxTokensChanged(old_value, maxTokens_);
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC721-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);

        // Do not check address zero (in case of burning)
        if (to_ == address(0)) {
            return;
        }

        uint256 new_balance = balanceOf(to_) + batchSize_;

        WalletMaxTokens storage wallet_max_tokens = walletsMaxTokens[to_];
        if (wallet_max_tokens.isSet && new_balance > wallet_max_tokens.maxTokens) {
            revert WalletMaxTokensReachedError(wallet_max_tokens.maxTokens);
        } else if (new_balance > defaultWalletMaxTokens) {
            revert DefaultWalletMaxTokensReachedError(defaultWalletMaxTokens);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  IERC4906 interface ERC721
 * @dev    Added since not present in last openzeppelin release
 */
interface IERC4906 is
    IERC165,
    IERC721
{
    //=============================================================//
    //                           EVENTS                            //
    //=============================================================//

    /**
     * This event emits when the metadata of a token is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFT.
     */
    event MetadataUpdate(
        uint256 tokenId
    );

    /**
     * This event emits when the metadata of a range of tokens is changed.
     * So that the third-party platforms such as NFT market could
     * timely update the images and related attributes of the NFTs.
     */
    event BatchMetadataUpdate(
        uint256 fromTokenId,
        uint256 toTokenId
    );
}

// SPDX-License-Identifier: MIT

//
// Strategic Club (https://strategicclub.io/)
//
//                                    ..:^^~!!777????????777!!~^^:..
//                               .:^!!7????????????????????????????7!!^:.
//                           :^!7????????????????????????????????????????7!^:
//                       .^!7????????????????????????????????????????????????7!^.
//                    .^!????????????????????????????????????????????????????????!^.
//                  :!??????????????????????????????????????????????????????????????!:
//               .^7??????????????????????????????????????????????????????????????????7^.
//             .~7??????????????????????????????????????????????????????????????????????7~.
//            ^7????????????????7~!???????77???7777777????????????????????????????????????7^
//          :7?????????????????!:::~7???7^::~7^:::::::^^^^~!7???????????????????????????????7:
//         ~???????????????????7:::::^^~~::::^^:::::::::::::^~7???????????????????????????????~
//       .!?????????????????????7::::::::::::::::::::::::::::::^!??????????????????????????????!.
//      :7?????????????????????!^::::::::::::::::::::::::::::::::^!?????????????????????????????7:
//     :??????????????????????~:::::::::::::::::::^^::::::::::::^5^^7?????????????????????????????:
//    :??????????????????????~:::::::::::::::::::JG::::::..::..:~#5.:!?????????????????????????????:
//   .7??????????????????????~:::~~::::::::::::::[email protected]?~^~7??YPPJJP&B7:::~????????????????????????????7.
//   !?????????????????????7~::::::::::::::::::::~5##&@@@@@@@@@@B^:::::~????????????????????????????!
//  :????????????????????7~:::::::::::::::::::::::^[email protected]@@@@@@@@@5^:::::::7????????????????????????????:
//  !???????????????????~:::::::::::::::::::::::::[email protected]@@@@@@@@@@@&?:::::::~????????????????????????????!
// :????????????????????!::::::::::::::::::::::::.~G#&@@@@@@@@@@@5::::::^?????????????????????????????:
// ~?????????????????????7~^:::::::^^^^:::::::^~?5B&@@@@@@@@@@@@@@Y::::::?????????????????????????????~
// 7????????????????????????7777777G&&##BBBBBB#&@@@@@@@@@@@@@@@@@@#^:::::7????????????????????????????7
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^::::^??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::~??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~::::7??????????????????????????????
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5::::^??????????????????????????????7
// ~????????????????????????????G&@@@#BPPGB&@@@@@@@@@@@@@@@@@@@@@Y:::::7??????????????????????????????~
// :[email protected]@@BY^:::::[email protected]@@#P#@@@@@@@@@#&@@@J.::::~???????????????????????????????:
//  [email protected]@P7?!:::::~&@G^[email protected]@&YYPPY7:[email protected]@B:::::^???????????????????????????????!
//  :[email protected]@&?777^.:::[email protected]@Y::[email protected]@[email protected]#^:::^7???????????????????????????????:
//   [email protected]@@PY5PGPGBB#@@@&&@@@&#[email protected]@@Y~^^7???????????????????????????????!
//   [email protected]@@@@@@&&##BGGPP555YYY5555555P5PPGGPGGPP5YJJ????????????????????????7.
//    :????????????????J5G#&&#GPYJ?7!~~^^:::::::::::::::::::::::::^^^~~!77???77????????????????????:
//     :????????????YPGG5J7!^^:::::^^^^^~~~~~~~~~~~~~!!~~~~~~~~~~~~^^^^^^::::^^^^~!!7?????????????:
//      :7???????7?J?7~^^~~~!!777777????????????????????????????????????77777!!!~~~^^~~!77??????7:
//       .!?????7!!!77???????????????????????????????????????????????????????????????777!!7????!.
//         ~??????????????????????????????????????????????????????????????????????????????????~
//          :7??????????????????????????????????????????????????????????????????????????????7:
//            ^7??????????????????????????????????????????????????????????????????????????7^
//             .~7??????????????????????????????????????????????????????????????????????7~.
//               .^7??????????????????????????????????????????????????????????????????7^.
//                  :!??????????????????????????????????????????????????????????????!:
//                    .^!????????????????????????????????????????????????????????!^.
//                       .^!7????????????????????????????????????????????????7!^.
//                           :^!7????????????????????????????????????????7!^:
//                               .:^!!7????????????????????????????7!!^:.
//                                    ..:^^~!!777????????777!!~^^:..
//

pragma solidity ^0.8.19;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721Capped.sol";
import "./ERC721SelectivePausable.sol";
import "./ERC721RevealableMultipleURIStorage.sol";
import "./ERC721WalletCapped.sol";


/**
 * @author Emanuele ([email protected], @emanueleb88)
 * @title  Special NFT for Strategic Club group
 * @notice NFT purpose will be specified in NFT metadata traits
 */
contract StrategicClubSpecialNFT is
    ERC721Capped,
    ERC721WalletCapped,
    ERC721SelectivePausable,
    ERC721RevealableMultipleURIStorage,
    ERC2981,
    Ownable
{
    //=============================================================//
    //                          CONSTANTS                          //
    //=============================================================//

    /// NFT name
    string constant private NFT_NAME = "Strategic Club Special NFT";
    /// NFT symbol
    string constant private NFT_SYMBOL = "SCSP";

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if minting zero tokens
     * @param tokenId Token ID
     */
    error NotTokenOwnerError(
        uint256 tokenId
    );

    /**
     * Error raised if minting zero tokens
     */
    error ZeroTokensMintError();

    //=============================================================//
    //                            EVENTS                           //
    //=============================================================//

    /**
     * Event emitted when a single token is minted
     */
    event SingleTokenMinted(
        address toAddress,
        uint256 tokenId
    );

    /**
     * Event emitted when multiple tokens are minted
     */
    event MultipleTokensMinted(
        address toAddress,
        uint256 startTokenId,
        uint256 tokensAmount
    );

    /**
     * Event emitted when tokens are airdropped
     */
    event TokensAirdropped(
        address[] toAddresses,
        uint256 startTokenId,
        uint256 tokensAmount
    );

    /**
     * Event emitted when a single token is burned
     */
    event SingleTokenBurned(
        uint256 tokenId
    );

    /**
     * Event emitted when default royalty is set
     */
    event DefaultRoyaltySet(
        address receiver,
        uint256 feeFraction
    );

    /**
     * Event emitted when default royalty is deleted
     */
    event DefaultRoyaltyDeleted();

    //=============================================================//
    //                          MODIFIERS                          //
    //=============================================================//

    /**
     * Modifier to make a function callable only by the owner of token ID `tokenId_`
     * @param tokenId_ Token ID
     */
    modifier onlyOwnerOrTokenOwner(
        uint256 tokenId_
    ) {
        address sender = _msgSender();
        if (sender != owner() && sender != _ownerOf(tokenId_)) {
            revert NotTokenOwnerError(tokenId_);
        }
        _;
    }

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     * @param baseURI_  Base URI
     * @param maxSupply_ Token maximum supply
     */
    constructor(
        string memory baseURI_,
        uint256 maxSupply_
    )
        ERC721(NFT_NAME, NFT_SYMBOL)
        ERC721Capped(maxSupply_)
        ERC721RevealableMultipleURIStorage(baseURI_)
    {}

    //=============================================================//
    //                      PUBLIC FUNCTIONS                       //
    //=============================================================//

    //
    // Mint/Burn
    //

    /**
     * Mint a single token to `to_`
     * @param to_ Receiver address
     */
    function mintTo(
        address to_
    ) public onlyOwner {
        _safeMintTo(to_);

        emit SingleTokenMinted(to_, totalSupply());
    }

    /**
     * Mint `amount_` tokens to `to_`
     * @param to_     Receiver address
     * @param amount_ Amount of tokens
     */
    function mintBatchTo(
        address to_,
        uint256 amount_
    ) public onlyOwner {
        if (amount_ == 0) {
            revert ZeroTokensMintError();
        }

        for (uint256 i = 0; i < amount_; i++) {
            _safeMintTo(to_);
        }

        emit MultipleTokensMinted(to_, totalSupply() - amount_ + 1, amount_);
    }

    /**
     * Airdrop tokens to `receivers_`
     * @param receivers_ Receiver addresses
     */
    function airdrop(
        address[] calldata receivers_
    ) public onlyOwner {
        uint256 amount = receivers_.length;
        for (uint256 i = 0; i < amount; i++) {
            _safeMintTo(receivers_[i]);
        }

        emit TokensAirdropped(receivers_, totalSupply() - amount + 1, amount);
    }

    /**
     * Burn token `tokenId_`
     * @param tokenId_ Token ID
     */
    function burn(
        uint256 tokenId_
    ) public onlyOwner {
        _burn(tokenId_);

        emit SingleTokenBurned(tokenId_);
    }

    //
    // Maximum supply management
    //

    /**
     * Increase maximum supply to `maxSupply_`
     * @param maxSupply_ New maximum supply
     */
    function increaseMaxSupply(
        uint256 maxSupply_
    ) public onlyOwner {
        _increaseMaxSupply(maxSupply_);
    }

    /**
     * Freeze maximum supply
     */
    function freezeMaxSupply() public onlyOwner {
        _freezeMaxSupply();
    }

    //
    // URIs management
    //

    /**
     * Set base URI to `baseURI_`
     * @param baseURI_ Base URI
     */
    function setBaseURI(
        string memory baseURI_
    ) public onlyOwner notEmptyURI(baseURI_) {
        _setBaseURI(baseURI_);
    }

    /**
     * Set contract URI`to `contractURI_`
     * @param contractURI_ Contract URI
     */
    function setContractURI(
        string memory contractURI_
    ) public onlyOwner notEmptyURI(contractURI_) {
        _setContractURI(contractURI_);
    }

    /**
     * Set URI of token ID `tokenId_` to `URI_`
     * @param tokenId_ Token ID
     * @param URI_     URI
     */
    function setTokenURI(
        uint256 tokenId_,
        string memory URI_
    ) public onlyOwner {
        _setTokenURI(tokenId_, URI_);
    }

    /**
     * Set unrevealed URI to `unrevealedURI_`
     * @param unrevealedURI_ Unrevealed URI
     */
    function setUnrevealedURI(
        string memory unrevealedURI_
    ) public onlyOwner notEmptyURI(unrevealedURI_)  {
        _setUnrevealedURI(unrevealedURI_);
    }

    /**
     * Freeze URI
     */
    function freezeURI() public onlyOwner {
        _freezeURI();
    }

    /**
     * Enable URIs revealing
     */
    function enableURIsRevealing() public onlyOwner {
        _enableURIsRevealing();
    }

    /**
     * Reveal all URIs
     */
    function revealAllURIs() public onlyOwner {
        _revealAllURIs();
    }

    /**
     * Reveal URI of single token `tokenId_`
     * @param tokenId_ Token ID
     */
    function revealSingleURI(
        uint256 tokenId_
    ) public onlyOwnerOrTokenOwner(tokenId_) {
        _revealSingleURI(tokenId_);
    }

    //
    // Maximum tokens per wallet management
    //

    /**
     * Set the maximum number of tokens for the wallet `wallet_` to `maxTokens_
     * @param wallet_    Wallet address
     * @param maxTokens_ Maximum number of tokens
     */
    function setWalletMaxTokens(
        address wallet_,
        uint256 maxTokens_
    ) public onlyOwner {
        _setWalletMaxTokens(wallet_, maxTokens_);
    }

    /**
     * Set the default wallet maximum number of tokens to `maxTokens_`
     * @param maxTokens_ Maximum number of tokens
     */
    function setDefaultWalletMaxTokens(
        uint256 maxTokens_
    ) public onlyOwner {
        _setDefaultWalletMaxTokens(maxTokens_);
    }

    //
    // Pause management
    //

    /**
     * Set the status of paused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet cannot transfer tokens, false otherwise
     */
    function setPausedWallet(
        address wallet_,
        bool status_
    ) public onlyOwner {
        _setPausedWallet(wallet_, status_);
    }

    /**
     * Set the status of unpaused wallet `wallet_` to `status_`
     * @param wallet_ Wallet address
     * @param status_ True if wallet can transfer tokens when paused, false otherwise
     */
    function setUnpausedWallet(
        address wallet_,
        bool status_
    ) public onlyOwner {
        _setUnpausedWallet(wallet_, status_);
    }

    /**
     * Pause token transfers
     */
    function pauseTransfers() public onlyOwner {
        _pause();
    }

    /**
     * Unpause token transfers
     */
    function unpauseTransfers() public onlyOwner {
        _unpause();
    }

    //
    // Royalty management
    //

    /**
     * Set the royalty information that all ids in this contract will default to
     * @param receiver_    Receiver address
     * @param feeFraction_ Fee fraction
     */
    function setDefaultRoyalty(
        address receiver_,
        uint96 feeFraction_
    ) public onlyOwner {
        _setDefaultRoyalty(receiver_, feeFraction_);

        emit DefaultRoyaltySet(receiver_, feeFraction_);
    }

    /**
     * Delete default royalty information
     */
    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();

        emit DefaultRoyaltyDeleted();
    }

    //=============================================================//
    //                    OVERRIDDEN FUNCTIONS                     //
    //=============================================================//

    /**
     * See {ERC721-_mint}
     */
    function _mint(
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721Capped, ERC721) {
        super._mint(to_, tokenId_);
    }

    /**
     * See {ERC721-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual override(ERC721WalletCapped, ERC721SelectivePausable, ERC721) {
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
    }

    /**
     * See {ERC721-tokenURI}
     */
    function tokenURI(
        uint256 tokenId_
    ) public view virtual override(ERC721RevealableMultipleURIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId_);
    }

    /**
     * See {ERC721-_baseURI}
     */
    function _baseURI() internal view override(ERC721MultipleURIStorage, ERC721) returns (string memory) {
        return super._baseURI();
    }

    /**
     * See {IERC165-supportsInterface}
     */
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC721, ERC2981, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }
}