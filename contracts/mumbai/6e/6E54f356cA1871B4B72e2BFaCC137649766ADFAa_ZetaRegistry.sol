pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {StringUtils} from "@ensdomains/ens-contracts/contracts/ethregistrar/StringUtils.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ZetaRegistry is ERC721URIStorage, Ownable, ReentrancyGuard, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    string public tld = "zeta";
    string svgPartOne =
        '<?xml version="1.0" encoding="UTF-8"?> <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 270 270"><rect width="270" height="270" fill="url(#a)"/><g clip-path="url(#b)"><path d="m45.636 28h0.8412c14.098 0.6599 24.78 11.011 25.523 25.03v2.0527c-0.3732 6.3718-2.5878 11.791-6.6438 16.257-8.5983 9.4665-22.953 11.44-33.668 4.2847-7.1597-4.7783-11.056-11.688-11.688-20.73v-1.9005c0.7311-14.034 11.538-24.4 25.636-24.994zm-14.658 30.467c-0.0114 4e-4 -0.0226-0.0026-0.0323-0.0085-0.0098-6e-3 -0.0176-0.0146-0.0227-0.025-0.0051-0.0105-0.0072-0.0222-0.0061-0.034s0.0053-0.0232 0.0122-0.0328c2.4654-3.1504 4.9165-6.3008 7.3534-9.4512 1.352-1.7425 0.5567-3.19-1.5967-3.1961-3.014-0.0081-6.029-0.0101-9.045-6e-3 -0.94 0-1.5844 0.0983-1.9331 0.2949-1.3153 0.739-1.0706 3.4728 0.6637 3.488 2.1779 0.0223 4.3456 0.0273 6.5031 0.0152 0.0139-2e-4 0.0275 0.0036 0.0394 0.0109 0.0118 0.0072 0.0213 0.0177 0.0274 0.0301s0.0085 0.0263 7e-3 0.04c-0.0016 0.0138-7e-3 0.0268-0.0157 0.0376-2.5205 3.1524-5.0236 6.3059-7.5094 9.4603-1.0553 1.338-0.4038 3.1961 1.3826 3.1961 4.8676 0 9.7372-0.0152 14.609-0.0457 2.8631-0.0182 2.7407-3.7525-0.1407-3.7494-3.4381 2e-3 -6.8701-0.0061-10.296-0.0244zm12.728-8.9342c1.4009-0.0264 2.8029-0.0304 4.2059-0.0122 1.5508 0.0213 2.0555 0.7177 2.0586 2.2533 2e-3 2.8646 0.0091 5.7292 0.0214 8.5937 0.0061 1.2955 0.6331 1.858 1.9484 1.855 2.961-0.0122 5.928-0.0162 8.9012-0.0122 3.013 0.0031 5.6313-0.5352 6.2033-3.7646 0.5995-3.3603-1.0125-6.1306-4.7045-6.3221-0.9808-0.0528-1.9586-0.0953-2.9334-0.1278-1.0889-0.0395-1.6059-1.3106-0.7647-2.0526 0.8443-0.745 5.2795-0.4349 6.5673-0.4379 2.1748-0.0061 2.6245-2.4449 1.1165-3.5944-0.0797-0.0613-0.1767-0.0974-0.2784-0.1034-2.5735-0.1459-4.8023-0.1662-6.6866-0.0608-3.5482 0.2007-5.1887 2.1114-4.9216 5.7322 0.3365 4.4975 4.3435 4.4093 7.7725 4.4854 1.4254 0.0334 1.563 2.4084-0.364 2.4905-1.6946 0.073-4.3048 0.0719-7.8306-0.0031-0.0401-8e-4 -0.0782-0.0171-0.1062-0.0456-0.028-0.0284-0.0437-0.0666-0.0437-0.1064-0.0102-1.9969-0.0326-3.9907-0.0673-5.9815-0.0489-2.7065-0.3089-4.9476-2.8049-6.0637-2.1351-0.9579-6.7356-0.5595-9.5007-0.5504-1.1012 0.0041-1.6793 0.4704-1.7344 1.3989-0.1122 1.8914-0.1387 5.3652-0.0795 10.421 7e-4 0.0414 0.0172 0.0811 0.0461 0.111s0.0682 0.0478 0.1099 0.0501c1.4131 0.1004 2.2635-0.0882 3.5788 0.5717 0.0143 0.0072 0.0302 0.0107 0.0462 0.0101 0.0161-5e-4 0.0317-0.0051 0.0454-0.0133 0.0138-0.0082 0.0252-0.0198 0.0333-0.0336 8e-3 -0.0138 0.0124-0.0293 0.0127-0.0453v-8.4903c0-0.0403 0.0162-0.079 0.0448-0.1075 0.0287-0.0285 0.0676-0.0445 0.1082-0.0445z" fill="#CAFC01"/><path d="m30.978 58.467c3.4259 0.0183 6.8579 0.0264 10.296 0.0244 2.8814-0.0031 3.0038 3.7312 0.1407 3.7494-4.8717 0.0304-9.7413 0.0456-14.609 0.0456-1.7864 0-2.4379-1.858-1.3826-3.196 2.4858-3.1544 4.9889-6.3079 7.5094-9.4603 0.0087-0.0108 0.0141-0.0238 0.0156-0.0376 0.0016-0.0137-8e-4 -0.0276-0.0069-0.04s-0.0156-0.0229-0.0274-0.0301c-0.0119-0.0073-0.0255-0.0111-0.0394-0.0109-2.1575 0.0121-4.3252 0.0071-6.5031-0.0152-1.7343-0.0152-1.979-2.749-0.6638-3.488 0.3487-0.1966 0.9931-0.2949 1.9332-0.2949 3.016-0.0041 6.031-0.0021 9.045 6e-3 2.1534 0.0061 2.9487 1.4536 1.5967 3.1961-2.4369 3.1504-4.888 6.3008-7.3534 9.4512-0.0069 0.0096-0.0112 0.021-0.0122 0.0328-0.0011 0.0118 1e-3 0.0235 0.0061 0.0339 0.0051 0.0105 0.0129 0.0191 0.0226 0.0251 0.0098 0.0059 0.021 0.0089 0.0324 0.0085z" fill="#2B2A29"/><path d="m43.553 49.685v8.4903c-3e-4 0.0159-0.0047 0.0315-0.0127 0.0453-0.0081 0.0138-0.0195 0.0253-0.0333 0.0335-0.0137 0.0082-0.0293 0.0128-0.0454 0.0134-0.016 6e-4 -0.0319-0.0029-0.0462-0.0101-1.3153-0.6599-2.1657-0.4713-3.5788-0.5717-0.0417-0.0023-0.081-0.0202-0.1099-0.0501s-0.0454-0.0696-0.0461-0.1111c-0.0592-5.056-0.0327-8.5298 0.0795-10.421 0.0551-0.9284 0.6332-1.3947 1.7343-1.3988 2.7652-0.0091 7.3657-0.4075 9.5008 0.5504 2.496 1.1161 2.756 3.3572 2.8049 6.0637 0.0347 1.9908 0.0571 3.9846 0.0673 5.9815 0 0.0398 0.0157 0.078 0.0437 0.1064 0.028 0.0285 0.0661 0.0448 0.1062 0.0456 3.5258 0.075 6.136 0.076 7.8306 0.0031 1.927-0.0821 1.7894-2.4571 0.364-2.4906-3.429-0.076-7.436 0.0122-7.7725-4.4853-0.2671-3.6208 1.3734-5.5315 4.9216-5.7322 1.8843-0.1054 4.1131-0.0852 6.6866 0.0608 0.1017 6e-3 0.1987 0.0421 0.2784 0.1034 1.508 1.1495 1.0583 3.5883-1.1165 3.5944-1.2878 3e-3 -5.723-0.3071-6.5673 0.4379-0.8412 0.742-0.3242 2.0131 0.7647 2.0526 0.9748 0.0325 1.9526 0.075 2.9334 0.1277 3.692 0.1916 5.304 2.9619 4.7045 6.3221-0.572 3.2295-3.1903 3.7678-6.2033 3.7647-2.9732-4e-3 -5.9402 0-8.9012 0.0122-1.3153 3e-3 -1.9423-0.5596-1.9484-1.855-0.0123-2.8646-0.0194-5.7291-0.0214-8.5937-0.0031-1.5356-0.5078-2.232-2.0586-2.2533-1.403-0.0183-2.805-0.0142-4.2059 0.0122-0.0406 0-0.0795 0.016-0.1082 0.0445-0.0286 0.0285-0.0448 0.0672-0.0448 0.1075z" fill="#2B2A29"/></g><path d="m82.63 54.2c0-1.236 0.276-2.34 0.828-3.312 0.564-0.984 1.326-1.746 2.286-2.286 0.972-0.552 2.058-0.828 3.258-0.828 1.404 0 2.634 0.36 3.69 1.08s1.794 1.716 2.214 2.988h-2.898c-0.288-0.6-0.696-1.05-1.224-1.35-0.516-0.3-1.116-0.45-1.8-0.45-0.732 0-1.386 0.174-1.962 0.522-0.564 0.336-1.008 0.816-1.332 1.44-0.312 0.624-0.468 1.356-0.468 2.196 0 0.828 0.156 1.56 0.468 2.196 0.324 0.624 0.768 1.11 1.332 1.458 0.576 0.336 1.23 0.504 1.962 0.504 0.684 0 1.284-0.15 1.8-0.45 0.528-0.312 0.936-0.768 1.224-1.368h2.898c-0.42 1.284-1.158 2.286-2.214 3.006-1.044 0.708-2.274 1.062-3.69 1.062-1.2 0-2.286-0.27-3.258-0.81-0.96-0.552-1.722-1.314-2.286-2.286-0.552-0.972-0.828-2.076-0.828-3.312zm19.216 6.462c-0.96 0-1.824-0.21-2.5916-0.63-0.768-0.432-1.374-1.038-1.818-1.818-0.432-0.78-0.648-1.68-0.648-2.7s0.222-1.92 0.666-2.7c0.456-0.78 1.074-1.38 1.854-1.8 0.7796-0.432 1.6496-0.648 2.6096-0.648s1.83 0.216 2.61 0.648c0.78 0.42 1.392 1.02 1.836 1.8 0.456 0.78 0.684 1.68 0.684 2.7s-0.234 1.92-0.702 2.7c-0.456 0.78-1.08 1.386-1.872 1.818-0.78 0.42-1.656 0.63-2.628 0.63zm0-2.196c0.456 0 0.882-0.108 1.278-0.324 0.408-0.228 0.732-0.564 0.972-1.008s0.36-0.984 0.36-1.62c0-0.948-0.252-1.674-0.756-2.178-0.492-0.516-1.098-0.774-1.818-0.774s-1.326 0.258-1.818 0.774c-0.4796 0.504-0.7196 1.23-0.7196 2.178s0.234 1.68 0.7016 2.196c0.48 0.504 1.08 0.756 1.8 0.756zm12.937-8.082c1.188 0 2.148 0.378 2.88 1.134 0.732 0.744 1.098 1.788 1.098 3.132v5.85h-2.52v-5.508c0-0.792-0.198-1.398-0.594-1.818-0.396-0.432-0.936-0.648-1.62-0.648-0.696 0-1.248 0.216-1.656 0.648-0.396 0.42-0.594 1.026-0.594 1.818v5.508h-2.52v-9.972h2.52v1.242c0.336-0.432 0.762-0.768 1.278-1.008 0.528-0.252 1.104-0.378 1.728-0.378zm12.26 0c1.188 0 2.148 0.378 2.88 1.134 0.732 0.744 1.098 1.788 1.098 3.132v5.85h-2.52v-5.508c0-0.792-0.198-1.398-0.594-1.818-0.396-0.432-0.936-0.648-1.62-0.648-0.696 0-1.248 0.216-1.656 0.648-0.396 0.42-0.594 1.026-0.594 1.818v5.508h-2.52v-9.972h2.52v1.242c0.336-0.432 0.762-0.768 1.278-1.008 0.528-0.252 1.104-0.378 1.728-0.378zm16.005 4.914c0 0.36-0.024 0.684-0.072 0.972h-7.29c0.06 0.72 0.312 1.284 0.756 1.692s0.99 0.612 1.638 0.612c0.936 0 1.602-0.402 1.998-1.206h2.718c-0.288 0.96-0.84 1.752-1.656 2.376-0.816 0.612-1.818 0.918-3.006 0.918-0.96 0-1.824-0.21-2.592-0.63-0.756-0.432-1.35-1.038-1.782-1.818-0.42-0.78-0.63-1.68-0.63-2.7 0-1.032 0.21-1.938 0.63-2.718s1.008-1.38 1.764-1.8 1.626-0.63 2.61-0.63c0.948 0 1.794 0.204 2.538 0.612 0.756 0.408 1.338 0.99 1.746 1.746 0.42 0.744 0.63 1.602 0.63 2.574zm-2.61-0.72c-0.012-0.648-0.246-1.164-0.702-1.548-0.456-0.396-1.014-0.594-1.674-0.594-0.624 0-1.152 0.192-1.584 0.576-0.42 0.372-0.678 0.894-0.774 1.566h4.734zm4.161 0.936c0-1.032 0.21-1.932 0.63-2.7 0.42-0.78 1.002-1.38 1.746-1.8 0.744-0.432 1.596-0.648 2.556-0.648 1.236 0 2.256 0.312 3.06 0.936 0.816 0.612 1.362 1.476 1.638 2.592h-2.718c-0.144-0.432-0.39-0.768-0.738-1.008-0.336-0.252-0.756-0.378-1.26-0.378-0.72 0-1.29 0.264-1.71 0.792-0.42 0.516-0.63 1.254-0.63 2.214 0 0.948 0.21 1.686 0.63 2.214 0.42 0.516 0.99 0.774 1.71 0.774 1.02 0 1.686-0.456 1.998-1.368h2.718c-0.276 1.08-0.822 1.938-1.638 2.574s-1.836 0.954-3.06 0.954c-0.96 0-1.812-0.21-2.556-0.63-0.744-0.432-1.326-1.032-1.746-1.8-0.42-0.78-0.63-1.686-0.63-2.718zm14.77-2.916v4.824c0 0.336 0.078 0.582 0.234 0.738 0.168 0.144 0.444 0.216 0.828 0.216h1.17v2.124h-1.584c-2.124 0-3.186-1.032-3.186-3.096v-4.806h-1.188v-2.07h1.188v-2.466h2.538v2.466h2.232v2.07h-2.232z" fill="#E4E4E4"/><text x="6%" y="66%" fill="#fff" font-size="20" font-weight="bold">';
    string svgPartTwo =
        '</text><path d="m26.776 205.27v1.302h-4.13v2.87h3.22v1.302h-3.22v4.256h-1.596v-9.73h5.726zm8.7451 2.016v7.714h-1.596v-0.91c-0.252 0.317-0.5834 0.569-0.994 0.756-0.4014 0.177-0.8307 0.266-1.288 0.266-0.6067 0-1.1527-0.126-1.638-0.378-0.476-0.252-0.854-0.625-1.134-1.12-0.2707-0.495-0.406-1.092-0.406-1.792v-4.536h1.582v4.298c0 0.691 0.1726 1.223 0.518 1.596 0.3453 0.364 0.8166 0.546 1.414 0.546 0.5973 0 1.0686-0.182 1.414-0.546 0.3546-0.373 0.532-0.905 0.532-1.596v-4.298h1.596zm4.2478 1.302v4.27c0 0.289 0.0653 0.499 0.196 0.63 0.14 0.121 0.3733 0.182 0.7 0.182h0.98v1.33h-1.26c-0.7187 0-1.2694-0.168-1.652-0.504-0.3827-0.336-0.574-0.882-0.574-1.638v-4.27h-0.91v-1.302h0.91v-1.918h1.61v1.918h1.876v1.302h-1.876zm10.613-1.302v7.714h-1.596v-0.91c-0.252 0.317-0.5834 0.569-0.994 0.756-0.4014 0.177-0.8307 0.266-1.288 0.266-0.6067 0-1.1527-0.126-1.638-0.378-0.476-0.252-0.854-0.625-1.134-1.12-0.2707-0.495-0.406-1.092-0.406-1.792v-4.536h1.582v4.298c0 0.691 0.1726 1.223 0.518 1.596 0.3453 0.364 0.8166 0.546 1.414 0.546 0.5973 0 1.0686-0.182 1.414-0.546 0.3546-0.373 0.532-0.905 0.532-1.596v-4.298h1.596zm3.9818 1.12c0.2333-0.392 0.5413-0.695 0.924-0.91 0.392-0.224 0.854-0.336 1.386-0.336v1.652h-0.406c-0.6254 0-1.1014 0.159-1.428 0.476-0.3174 0.317-0.476 0.868-0.476 1.652v4.06h-1.596v-7.714h1.596v1.12zm11.127 2.548c0 0.289-0.0187 0.551-0.056 0.784h-5.894c0.0467 0.616 0.2753 1.111 0.686 1.484s0.9147 0.56 1.512 0.56c0.8587 0 1.4653-0.359 1.82-1.078h1.722c-0.2333 0.709-0.658 1.293-1.274 1.75-0.6067 0.448-1.3627 0.672-2.268 0.672-0.7373 0-1.4-0.163-1.988-0.49-0.5787-0.336-1.036-0.803-1.372-1.4-0.3267-0.607-0.49-1.307-0.49-2.1s0.1587-1.489 0.476-2.086c0.3267-0.607 0.7793-1.073 1.358-1.4 0.588-0.327 1.26-0.49 2.016-0.49 0.728 0 1.3767 0.159 1.946 0.476s1.0127 0.765 1.33 1.344c0.3173 0.569 0.476 1.227 0.476 1.974zm-1.666-0.504c-0.0093-0.588-0.2193-1.059-0.63-1.414s-0.9193-0.532-1.526-0.532c-0.5507 0-1.022 0.177-1.414 0.532-0.392 0.345-0.6253 0.817-0.7 1.414h4.27zm10.779 4.676c-0.728 0-1.386-0.163-1.974-0.49-0.588-0.336-1.05-0.803-1.386-1.4-0.336-0.607-0.504-1.307-0.504-2.1 0-0.784 0.1727-1.479 0.518-2.086 0.3454-0.607 0.8167-1.073 1.414-1.4 0.5974-0.327 1.2647-0.49 2.002-0.49 0.7374 0 1.4047 0.163 2.002 0.49 0.5974 0.327 1.0687 0.793 1.414 1.4 0.3454 0.607 0.518 1.302 0.518 2.086s-0.1773 1.479-0.532 2.086c-0.3546 0.607-0.84 1.078-1.456 1.414-0.6066 0.327-1.2786 0.49-2.016 0.49zm0-1.386c0.4107 0 0.7934-0.098 1.148-0.294 0.364-0.196 0.658-0.49 0.882-0.882s0.336-0.868 0.336-1.428-0.1073-1.031-0.322-1.414c-0.2146-0.392-0.4993-0.686-0.854-0.882-0.3546-0.196-0.7373-0.294-1.148-0.294-0.4106 0-0.7933 0.098-1.148 0.294-0.3453 0.196-0.6206 0.49-0.826 0.882-0.2053 0.383-0.308 0.854-0.308 1.414 0 0.831 0.21 1.475 0.63 1.932 0.4294 0.448 0.966 0.672 1.61 0.672zm9.0958-5.152h-1.428v6.412h-1.61v-6.412h-0.91v-1.302h0.91v-0.546c0-0.887 0.2333-1.531 0.7-1.932 0.476-0.411 1.218-0.616 2.226-0.616v1.33c-0.4854 0-0.826 0.093-1.022 0.28-0.196 0.177-0.294 0.49-0.294 0.938v0.546h1.428v1.302zm8.7891-3.318c1.036 0 1.9414 0.201 2.716 0.602 0.784 0.392 1.386 0.961 1.806 1.708 0.4294 0.737 0.644 1.601 0.644 2.59s-0.2146 1.848-0.644 2.576c-0.42 0.728-1.022 1.288-1.806 1.68-0.7746 0.383-1.68 0.574-2.716 0.574h-3.178v-9.73h3.178zm0 8.428c1.1387 0 2.0114-0.308 2.618-0.924 0.6067-0.616 0.91-1.484 0.91-2.604 0-1.129-0.3033-2.011-0.91-2.646-0.6066-0.635-1.4793-0.952-2.618-0.952h-1.582v7.126h1.582zm14.098-2.744c0 0.289-0.019 0.551-0.056 0.784h-5.894c0.046 0.616 0.275 1.111 0.686 1.484 0.41 0.373 0.914 0.56 1.512 0.56 0.858 0 1.465-0.359 1.82-1.078h1.722c-0.234 0.709-0.658 1.293-1.274 1.75-0.607 0.448-1.363 0.672-2.268 0.672-0.738 0-1.4-0.163-1.988-0.49-0.579-0.336-1.0363-0.803-1.3723-1.4-0.3266-0.607-0.49-1.307-0.49-2.1s0.1587-1.489 0.476-2.086c0.3267-0.607 0.7793-1.073 1.3583-1.4 0.588-0.327 1.26-0.49 2.016-0.49 0.728 0 1.376 0.159 1.946 0.476 0.569 0.317 1.012 0.765 1.33 1.344 0.317 0.569 0.476 1.227 0.476 1.974zm-1.666-0.504c-0.01-0.588-0.22-1.059-0.63-1.414-0.411-0.355-0.92-0.532-1.526-0.532-0.551 0-1.022 0.177-1.414 0.532-0.392 0.345-0.626 0.817-0.7 1.414h4.27zm2.984 0.686c0-0.793 0.159-1.489 0.476-2.086 0.327-0.607 0.775-1.073 1.344-1.4 0.57-0.327 1.223-0.49 1.96-0.49 0.934 0 1.704 0.224 2.31 0.672 0.616 0.439 1.032 1.069 1.246 1.89h-1.722c-0.14-0.383-0.364-0.681-0.672-0.896s-0.695-0.322-1.162-0.322c-0.653 0-1.176 0.233-1.568 0.7-0.382 0.457-0.574 1.101-0.574 1.932s0.192 1.479 0.574 1.946c0.392 0.467 0.915 0.7 1.568 0.7 0.924 0 1.536-0.406 1.834-1.218h1.722c-0.224 0.784-0.644 1.409-1.26 1.876-0.616 0.457-1.381 0.686-2.296 0.686-0.737 0-1.39-0.163-1.96-0.49-0.569-0.336-1.017-0.803-1.344-1.4-0.317-0.607-0.476-1.307-0.476-2.1zm16.277-0.182c0 0.289-0.019 0.551-0.056 0.784h-5.894c0.047 0.616 0.275 1.111 0.686 1.484s0.915 0.56 1.512 0.56c0.859 0 1.465-0.359 1.82-1.078h1.722c-0.233 0.709-0.658 1.293-1.274 1.75-0.607 0.448-1.363 0.672-2.268 0.672-0.737 0-1.4-0.163-1.988-0.49-0.579-0.336-1.036-0.803-1.372-1.4-0.327-0.607-0.49-1.307-0.49-2.1s0.159-1.489 0.476-2.086c0.327-0.607 0.779-1.073 1.358-1.4 0.588-0.327 1.26-0.49 2.016-0.49 0.728 0 1.377 0.159 1.946 0.476s1.013 0.765 1.33 1.344c0.317 0.569 0.476 1.227 0.476 1.974zm-1.666-0.504c-9e-3 -0.588-0.219-1.059-0.63-1.414s-0.919-0.532-1.526-0.532c-0.551 0-1.022 0.177-1.414 0.532-0.392 0.345-0.625 0.817-0.7 1.414h4.27zm7.408-3.29c0.607 0 1.148 0.126 1.624 0.378 0.486 0.252 0.864 0.625 1.134 1.12 0.271 0.495 0.406 1.092 0.406 1.792v4.55h-1.582v-4.312c0-0.691-0.172-1.218-0.518-1.582-0.345-0.373-0.816-0.56-1.414-0.56-0.597 0-1.073 0.187-1.428 0.56-0.345 0.364-0.518 0.891-0.518 1.582v4.312h-1.596v-7.714h1.596v0.882c0.262-0.317 0.593-0.565 0.994-0.742 0.411-0.177 0.845-0.266 1.302-0.266zm7.342 1.428v4.27c0 0.289 0.066 0.499 0.196 0.63 0.14 0.121 0.374 0.182 0.7 0.182h0.98v1.33h-1.26c-0.718 0-1.269-0.168-1.652-0.504-0.382-0.336-0.574-0.882-0.574-1.638v-4.27h-0.91v-1.302h0.91v-1.918h1.61v1.918h1.876v1.302h-1.876zm5.223-0.182c0.234-0.392 0.542-0.695 0.924-0.91 0.392-0.224 0.854-0.336 1.386-0.336v1.652h-0.406c-0.625 0-1.101 0.159-1.428 0.476-0.317 0.317-0.476 0.868-0.476 1.652v4.06h-1.596v-7.714h1.596v1.12zm3.525 2.702c0-0.775 0.159-1.461 0.476-2.058 0.327-0.597 0.766-1.059 1.316-1.386 0.56-0.336 1.176-0.504 1.848-0.504 0.607 0 1.134 0.121 1.582 0.364 0.458 0.233 0.822 0.527 1.092 0.882v-1.12h1.61v7.714h-1.61v-1.148c-0.27 0.364-0.639 0.667-1.106 0.91-0.466 0.243-0.998 0.364-1.596 0.364-0.662 0-1.269-0.168-1.82-0.504-0.55-0.345-0.989-0.821-1.316-1.428-0.317-0.616-0.476-1.311-0.476-2.086zm6.314 0.028c0-0.532-0.112-0.994-0.336-1.386-0.214-0.392-0.499-0.691-0.854-0.896-0.354-0.205-0.737-0.308-1.148-0.308-0.41 0-0.793 0.103-1.148 0.308-0.354 0.196-0.644 0.49-0.868 0.882-0.214 0.383-0.322 0.84-0.322 1.372s0.108 0.999 0.322 1.4c0.224 0.401 0.514 0.709 0.868 0.924 0.364 0.205 0.747 0.308 1.148 0.308 0.411 0 0.794-0.103 1.148-0.308 0.355-0.205 0.64-0.504 0.854-0.896 0.224-0.401 0.336-0.868 0.336-1.4zm5.583-6.496v10.36h-1.596v-10.36h1.596zm3.187 1.624c-0.289 0-0.532-0.098-0.728-0.294s-0.294-0.439-0.294-0.728 0.098-0.532 0.294-0.728 0.439-0.294 0.728-0.294c0.28 0 0.518 0.098 0.714 0.294s0.294 0.439 0.294 0.728-0.098 0.532-0.294 0.728-0.434 0.294-0.714 0.294zm0.784 1.022v7.714h-1.596v-7.714h1.596zm3.789 6.412h3.5v1.302h-5.348v-1.302l3.514-5.11h-3.514v-1.302h5.348v1.302l-3.5 5.11zm12.526-2.744c0 0.289-0.018 0.551-0.056 0.784h-5.894c0.047 0.616 0.276 1.111 0.686 1.484 0.411 0.373 0.915 0.56 1.512 0.56 0.859 0 1.466-0.359 1.82-1.078h1.722c-0.233 0.709-0.658 1.293-1.274 1.75-0.606 0.448-1.362 0.672-2.268 0.672-0.737 0-1.4-0.163-1.988-0.49-0.578-0.336-1.036-0.803-1.372-1.4-0.326-0.607-0.49-1.307-0.49-2.1s0.159-1.489 0.476-2.086c0.327-0.607 0.78-1.073 1.358-1.4 0.588-0.327 1.26-0.49 2.016-0.49 0.728 0 1.377 0.159 1.946 0.476 0.57 0.317 1.013 0.765 1.33 1.344 0.318 0.569 0.476 1.227 0.476 1.974zm-1.666-0.504c-9e-3 -0.588-0.219-1.059-0.63-1.414-0.41-0.355-0.919-0.532-1.526-0.532-0.55 0-1.022 0.177-1.414 0.532-0.392 0.345-0.625 0.817-0.7 1.414h4.27zm2.985 0.658c0-0.775 0.159-1.461 0.476-2.058 0.327-0.597 0.765-1.059 1.316-1.386 0.56-0.336 1.181-0.504 1.862-0.504 0.504 0 0.999 0.112 1.484 0.336 0.495 0.215 0.887 0.504 1.176 0.868v-3.724h1.61v10.36h-1.61v-1.162c-0.261 0.373-0.625 0.681-1.092 0.924-0.457 0.243-0.985 0.364-1.582 0.364-0.672 0-1.288-0.168-1.848-0.504-0.551-0.345-0.989-0.821-1.316-1.428-0.317-0.616-0.476-1.311-0.476-2.086zm6.314 0.028c0-0.532-0.112-0.994-0.336-1.386-0.215-0.392-0.499-0.691-0.854-0.896s-0.737-0.308-1.148-0.308-0.793 0.103-1.148 0.308c-0.355 0.196-0.644 0.49-0.868 0.882-0.215 0.383-0.322 0.84-0.322 1.372s0.107 0.999 0.322 1.4c0.224 0.401 0.513 0.709 0.868 0.924 0.364 0.205 0.747 0.308 1.148 0.308 0.411 0 0.793-0.103 1.148-0.308s0.639-0.504 0.854-0.896c0.224-0.401 0.336-0.868 0.336-1.4z" fill="#fff"/><path d="m29.044 236h-1.596l-4.802-7.266v7.266h-1.596v-9.744h1.596l4.802 7.252v-7.252h1.596v9.744zm1.8438-3.892c0-0.775 0.1587-1.461 0.476-2.058 0.3267-0.597 0.7654-1.059 1.316-1.386 0.56-0.336 1.176-0.504 1.848-0.504 0.6067 0 1.134 0.121 1.582 0.364 0.4574 0.233 0.8214 0.527 1.092 0.882v-1.12h1.61v7.714h-1.61v-1.148c-0.2706 0.364-0.6393 0.667-1.106 0.91-0.4666 0.243-0.9986 0.364-1.596 0.364-0.6626 0-1.2693-0.168-1.82-0.504-0.5506-0.345-0.9893-0.821-1.316-1.428-0.3173-0.616-0.476-1.311-0.476-2.086zm6.314 0.028c0-0.532-0.112-0.994-0.336-1.386-0.2146-0.392-0.4993-0.691-0.854-0.896-0.3546-0.205-0.7373-0.308-1.148-0.308-0.4106 0-0.7933 0.103-1.148 0.308-0.3546 0.196-0.644 0.49-0.868 0.882-0.2146 0.383-0.322 0.84-0.322 1.372s0.1074 0.999 0.322 1.4c0.224 0.401 0.5134 0.709 0.868 0.924 0.364 0.205 0.7467 0.308 1.148 0.308 0.4107 0 0.7934-0.103 1.148-0.308 0.3547-0.205 0.6394-0.504 0.854-0.896 0.224-0.401 0.336-0.868 0.336-1.4zm13.324-3.976c0.6067 0 1.148 0.126 1.624 0.378 0.4854 0.252 0.8634 0.625 1.134 1.12 0.28 0.495 0.42 1.092 0.42 1.792v4.55h-1.582v-4.312c0-0.691-0.1726-1.218-0.518-1.582-0.3453-0.373-0.8166-0.56-1.414-0.56-0.5973 0-1.0733 0.187-1.428 0.56-0.3453 0.364-0.518 0.891-0.518 1.582v4.312h-1.582v-4.312c0-0.691-0.1726-1.218-0.518-1.582-0.3453-0.373-0.8166-0.56-1.414-0.56-0.5973 0-1.0733 0.187-1.428 0.56-0.3453 0.364-0.518 0.891-0.518 1.582v4.312h-1.596v-7.714h1.596v0.882c0.2614-0.317 0.5927-0.565 0.994-0.742 0.4014-0.177 0.8307-0.266 1.288-0.266 0.616 0 1.1667 0.131 1.652 0.392 0.4854 0.261 0.8587 0.639 1.12 1.134 0.2334-0.467 0.5974-0.835 1.092-1.106 0.4947-0.28 1.0267-0.42 1.596-0.42zm6.3009-0.896c-0.2893 0-0.532-0.098-0.728-0.294s-0.294-0.439-0.294-0.728 0.098-0.532 0.294-0.728 0.4387-0.294 0.728-0.294c0.28 0 0.518 0.098 0.714 0.294s0.294 0.439 0.294 0.728-0.098 0.532-0.294 0.728-0.434 0.294-0.714 0.294zm0.784 1.022v7.714h-1.596v-7.714h1.596zm6.2674-0.126c0.6067 0 1.148 0.126 1.624 0.378 0.4853 0.252 0.8633 0.625 1.134 1.12s0.406 1.092 0.406 1.792v4.55h-1.582v-4.312c0-0.691-0.1727-1.218-0.518-1.582-0.3453-0.373-0.8167-0.56-1.414-0.56s-1.0733 0.187-1.428 0.56c-0.3453 0.364-0.518 0.891-0.518 1.582v4.312h-1.596v-7.714h1.596v0.882c0.2613-0.317 0.5927-0.565 0.994-0.742 0.4107-0.177 0.8447-0.266 1.302-0.266zm8.5878 0c0.5973 0 1.1247 0.121 1.582 0.364 0.4667 0.233 0.8307 0.527 1.092 0.882v-1.12h1.61v7.84c0 0.709-0.1493 1.339-0.448 1.89-0.2987 0.56-0.7327 0.999-1.302 1.316-0.56 0.317-1.232 0.476-2.016 0.476-1.0453 0-1.9133-0.247-2.604-0.742-0.6907-0.485-1.0827-1.148-1.176-1.988h1.582c0.1213 0.401 0.378 0.723 0.77 0.966 0.4013 0.252 0.8773 0.378 1.428 0.378 0.644 0 1.162-0.196 1.554-0.588 0.4013-0.392 0.602-0.961 0.602-1.708v-1.288c-0.2707 0.364-0.6393 0.672-1.106 0.924-0.4573 0.243-0.98 0.364-1.568 0.364-0.672 0-1.288-0.168-1.848-0.504-0.5507-0.345-0.9893-0.821-1.316-1.428-0.3173-0.616-0.476-1.311-0.476-2.086s0.1587-1.461 0.476-2.058c0.3267-0.597 0.7653-1.059 1.316-1.386 0.56-0.336 1.176-0.504 1.848-0.504zm2.674 3.976c0-0.532-0.112-0.994-0.336-1.386-0.2147-0.392-0.4993-0.691-0.854-0.896s-0.7373-0.308-1.148-0.308-0.7933 0.103-1.148 0.308c-0.3547 0.196-0.644 0.49-0.868 0.882-0.2147 0.383-0.322 0.84-0.322 1.372s0.1073 0.999 0.322 1.4c0.224 0.401 0.5133 0.709 0.868 0.924 0.364 0.205 0.7467 0.308 1.148 0.308 0.4107 0 0.7933-0.103 1.148-0.308s0.6393-0.504 0.854-0.896c0.224-0.401 0.336-0.868 0.336-1.4z" fill="#CAFC01"/><path d="m20 195h181v-2h-181v2z" fill="#CAFC01" mask="url(#path-6-inside-1_1_2)"/><defs><linearGradient id="a" x1="1.5" x2="270" y1="2" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#2B2A29" offset="0"/><stop stop-color="#2E3A00" offset=".4319"/></linearGradient><clipPath id="b"><rect transform="translate(20 28)" width="52" height="52" fill="#fff"/></clipPath></defs></svg>';
    bool[15] pauseDomainLen;
    uint256[5] public priceToMintDomain;
    mapping(string => address) public forwardLookUp;
    mapping(address => string) public reverseLookUp;
    mapping(uint256 => string) public tokenIDtoDomainName;
    mapping(string => uint256) public domainNameToTokenID;
    mapping(string => bool) public protectedDomains;
    mapping(address => uint256[]) public ownedDomains;
    address public treasury;

    constructor(
        address _treasury,
        uint96 _royalityInBips
    ) payable ERC721("ZNS Connect Name Service", "ZNS") {
        treasury = _treasury;
        _setDefaultRoyalty(msg.sender, _royalityInBips);
    }

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidLength();
    error DomainLengthIsPaused();
    error AlreadyRegistered();
    error NotEnoughNativeTokenPaid();
    error domainIsProtected();
    error SelfReferral();

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function registerDomain(
        string calldata domainName,
        address referral
    ) public payable nonReentrant {
        if (referral == msg.sender) revert SelfReferral();
        if (forwardLookUp[domainName] != address(0)) revert AlreadyRegistered();
        uint256 _price = priceToMint(domainName);
        if (msg.value < _price) revert NotEnoughNativeTokenPaid();
        if (protectedDomains[domainName]) revert domainIsProtected();

        string memory _domainName = string(
            abi.encodePacked(domainName, ".", tld)
        );
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _domainName, svgPartTwo)
        );
        uint256 length = StringUtils.strlen(domainName);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _domainName,
                '", "description": "A domain on ZNS Connect Name Service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                Strings.toString(length),
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        uint256 newRecordId = _tokenIds.current();

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        forwardLookUp[domainName] = msg.sender;
        reverseLookUp[msg.sender] = domainName;
        tokenIDtoDomainName[newRecordId] = domainName;
        domainNameToTokenID[domainName] = newRecordId;
        ownedDomains[msg.sender].push(newRecordId);
        _tokenIds.increment();

        if (referral != address(0)) {
            uint referralAmount = _price / 10;
            payable(referral).transfer(referralAmount);
            payable(treasury).transfer(_price - referralAmount);
        } else payable(treasury).transfer(_price);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        trasnferFunctions(from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        trasnferFunctions(from, to, tokenId);
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        trasnferFunctions(from, to, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    function trasnferFunctions(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        forwardLookUp[tokenIDtoDomainName[tokenId]] = to;
        reverseLookUp[to] = tokenIDtoDomainName[tokenId];
        uint256 lenght = ownedDomains[from].length;
        for (uint256 i = 0; i < lenght; i++) {
            if (ownedDomains[from][i] == tokenId) {
                ownedDomains[from][i] = ownedDomains[from][lenght - 1];
                ownedDomains[from].pop();
                break;
            }
        }
    }

    function getOwnedDomains(
        address owner
    ) external view returns (uint256[] memory) {
        return ownedDomains[owner];
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function pauseDomainLenght(uint256 length) external onlyOwner {
        pauseDomainLen[length - 1] = true;
    }

    function priceToMint(string calldata name) public view returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        if (len <= 0 && len > 15) revert InvalidLength();
        if (pauseDomainLen[len - 1]) revert DomainLengthIsPaused();
        if (len == 1) return priceToMintDomain[0];
        else if (len == 2) return priceToMintDomain[1];
        else if (len == 3) return priceToMintDomain[2];
        else if (len == 4) return priceToMintDomain[3];
        else if (len >= 5 && len <= 15) return priceToMintDomain[4];
        else revert InvalidLength();
    }

    function changePriceToMint(
        uint256[5] calldata _priceToMintDomain
    ) external onlyOwner {
        priceToMintDomain = _priceToMintDomain;
    }

    function changeTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function protectDomain(
        string calldata domainName,
        bool trueOrFalse
    ) external onlyOwner {
        protectedDomains[domainName] = trueOrFalse;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721URIStorage, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function changeRoyality(
        address _receiver,
        uint96 _royalityInBips
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royalityInBips);
    }
}