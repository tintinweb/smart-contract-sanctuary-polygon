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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

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
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

/**
▀█████████▄   ▄██████▄   ▄█          ▄████████    ▄████████  ▄██████▄  
  ███    ███ ███    ███ ███         ███    ███   ███    ███ ███    ███ 
  ███    ███ ███    ███ ███         ███    █▀    ███    ███ ███    ███ 
 ▄███▄▄▄██▀  ███    ███ ███        ▄███▄▄▄      ▄███▄▄▄▄██▀ ███    ███ 
▀▀███▀▀▀██▄  ███    ███ ███       ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███    ███ 
  ███    ██▄ ███    ███ ███         ███    █▄  ▀███████████ ███    ███ 
  ███    ███ ███    ███ ███▌    ▄   ███    ███   ███    ███ ███    ███ 
▄█████████▀   ▀██████▀  █████▄▄██   ██████████   ███    ███  ▀██████▀  
                        ▀                        ███    ███   
*/

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./LockRegistry.sol";
import "../interfaces/IBoleroERC721.sol";

interface IBoleroDeployer {
    function management() external view returns (address);

    function rewards() external view returns (address);
}

interface IBoleroPaymentSplitter {
    function initialize(
        address _bolero,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares
    ) external;

    function setMultisigWallet(address _multisigWallet) external;
}

interface IBoleroMultisig {
    function initialize(
        address[] memory _owners,
        uint256 _confirmations,
        address _paymentSplitter
    ) external;
}

interface IBoleroSwap {
    function openSellOffer(
        address _nftAddress,
        address _wantAddress,
        address _owner,
        address _paymentAddress,
        uint256 _nftTokenID,
        uint256 _wantAmount
    ) external;

    function openBid(
        address _nftAddress,
        address _wantAddress,
        address _owner,
        address _paymentAddress,
        uint256 _nftTokenID,
        uint256 _startOffer,
        uint256[2] memory _startEndTime
    ) external returns (uint256);
}

contract NFTController {
    address public bolero = address(0);
    bool public isEmergencyPause = false;

    modifier onlyBolero() {
        require(
            msg.sender == IBoleroDeployer(bolero).management(),
            "!authorized"
        );
        _;
    }

    function setEmergencyPause(bool shouldPause) public onlyBolero {
        isEmergencyPause = shouldPause;
    }

    function getManagement() public view returns (address) {
        return IBoleroDeployer(bolero).management();
    }
}



contract BoleroNFT is ERC721Enumerable, LockRegistry, NFTController  {
    uint256 public constant MAXIMUM_PERCENT = 10000;
    uint256 public constant MAXIMUM_ROYALTIES_PERCENT_SECONDARY = 1500;

    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes4 private constant _INTERFACE_ID_BOLEROERC721 = type(IBoleroERC721).interfaceId;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    // CollectiveCollection

    struct Collection {
        address artist;
        address payment;
        address privateSaleToken;
        string collectionName;
        uint256 collectionId;
        uint256 cap;
        Royalties royalties;
        uint256 privateSaleThreshold;
        bool isWithPaymentSplitter;
    }

    struct Royalties {
        uint256 boleroFeesPrimary;
        uint256 boleroFeesSecondary;
        uint256 artistRoyalties;
    }

    struct MintData {
        address _to;
        string _tokenURI;
        uint256 _collectionId;
    }
    
    struct MintAndSellData {
        address _to;
        address _wantToken;
        string _tokenURI;
        uint256 _wantAmount;
        uint256 _collectionId;
    }
    struct MintAndBidData {
        address _to;
        address _wantToken;
        string _tokenURI;
        uint256 _startOffer;
        uint256 _collectionId;
        uint256[2] _startEndTime;
    }

    Counters.Counter public _collectionIds;
    Counters.Counter public _tokenIds;
    address public boleroSwap = address(0);
    address public boleroPaymentSplitterImplementation;
    address public boleroMultisigImplementation;
    address public rewards2981;

    IBoleroPaymentSplitter public PaymentSplitter;
    IBoleroMultisig public BoleroMultisig;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) public isSecondaryMarket;
    mapping(uint256 => Collection) public collections;
    mapping(uint256 => uint256[]) public collection_tokensIds;
    mapping(address => uint256[]) public collection_byArtist;
    mapping(uint256 => uint256) public collectionForTokenID;
    mapping(uint256 => address) public multisigForCollectionID;

    event NewCollection(
        uint256 collectionID,
        address artist,
        string name,
        uint256 boleroFeesPrimary,
        uint256 boleroFeesSecondary,
        uint256 artistRoyalties,
        uint256 cap,
        uint256 privateSaleThreshold,
        bool isWithPaymentSplitter
    );

    event NewCollectionWithPaymentSplitter(
        address indexed artistAddress,
        address indexed privateSaleToken,
        string collectionName,
        address[] indexed payees,
        string[] roles,
        uint256[] shares,
        uint256 boleroFeesPrimary,
        uint256 boleroFeesSecondary,
        uint256 artistRoyalties,
        uint256 cap,
        uint256 privateSaleThreshold,
        bool isWithPaymentSplitter
    );

    event newBoleroMultisigImplementation(address indexed implementation);

    event newBoleroPaymentSplitterImplementation(
        address indexed implementation
    );

    event newBoleroLockRegistryImplementation(
        address indexed implementation
    );

    event SetSecondaryMarket(uint256 tokenID);

    event ChangeTokenURI(uint256 tokenId, string _tokenURI);

    /*******************************************************************************
     *  @notice Initialize the new contract.
     *  @param name Name of the erc721
     *  @param symbol Symbol of the erc721
     *  @param swap address of the swap contract
     *  @param royalties royalties split for the artist and bolero
     *******************************************************************************/
    constructor(
        string memory name,
        string memory symbol,
        address swap,
        address managerRegistry
    ) ERC721(name, symbol) {
        bolero = msg.sender;
        boleroSwap = swap;
        address[] memory approved = new address[](2);
        approved[0] = msg.sender;
        approved[1] = managerRegistry;
        initApprovedContracts(approved);
    }

	function lockId(uint256 _id) public onlyBolero {
		require(_exists(_id), "Token !exist");
		_lockId(_id);
	}

	function unlockId(uint256 _id) public onlyBolero {
		require(_exists(_id), "Token !exist");
		_unlockId(_id);
	}
    
	function autoLockId(uint256 _id) external virtual {
		require(_exists(_id), "Token !exist");
		require(msg.sender == boleroSwap, "!authorized");
		_lockId(_id); 
	}


	function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
		return _interfaceId == _INTERFACE_ID_BOLEROERC721
			|| super.supportsInterface(_interfaceId);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public override(ERC721, IERC721) virtual {
		require(!lockMap[_tokenId], "Token is locked");
		ERC721.transferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override(ERC721, IERC721) virtual {
		require(!lockMap[_tokenId], "Token is locked");
		ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
	}




    /*******************************************************************************
     *  @notice Initialize the new contract.
     *  @param artistAddress The address of the artist
     *  @param collectionPaymentAddress payment address for this artist
     *  @param collectionName Name of the collection
     *  @param _royalties amount of royalties in % for this artist and for bolero primary and secondary market 
     *                    [boleroFeesPrimary,boleroFeesSecondary,artistRoyalties]
     *  @param cap the maximum amount of tokens in the collection
     *  @param privateSaleThreshold the amount of tokens needed to be able to buy
     *                              a token from this collection on the swap.
     *******************************************************************************/
    function newCollection(
        address artistAddress,
        address collectionPaymentAddress,
        address privateSaleToken,
        string memory collectionName,
        Royalties memory _royalties,
        uint256 cap,
        uint256 privateSaleThreshold
    ) public {
        _collectionIds.increment();
        uint256 newCollectionIds = _collectionIds.current();

        Collection memory _newCollection = Collection(
            artistAddress,
            collectionPaymentAddress,
            privateSaleToken,
            collectionName,
            newCollectionIds,
            cap,
            _royalties,
            privateSaleThreshold,
            false
        );
        collections[newCollectionIds] = _newCollection;
        collection_byArtist[artistAddress].push(newCollectionIds);
        emit NewCollection(
            newCollectionIds,
            artistAddress,
            collectionName,
            _royalties.boleroFeesPrimary,
            _royalties.boleroFeesSecondary,
            _royalties.artistRoyalties,
            cap,
            privateSaleThreshold,
            false
        );
    }

    /*******************************************************************************
     *  @notice Initialize a collection with paymentSplitter and a Multisig with it.
     *  @param artistAddress The address of the artist
     *  @param collectionPaymentAddress payment address for this artist
     *  @param collectionName Name of the collection
     *  @param _payees Array of addresses of the different beneficiaries.
     *  @param _roles The roles of each beneficiaries/payees per index.
     *  @param _shares The ammount of shares each payees will get, index per index.
     *  @param artistRoyalty amount of royalties in % for this artist
     *  @param cap the maximum amount of tokens in the collection
     *  @param privateSaleThreshold the amount of tokens needed to be able to buy
     *                              a token from this collection on the swap.
     *******************************************************************************/
    function newCollectionWithPaymentSplitter(
        address artistAddress,
        address privateSaleToken,
        string memory collectionName,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        Royalties memory _royalties,
        uint256 cap,
        uint256 privateSaleThreshold
    ) public {
        _collectionIds.increment();
        uint256 newCollectionIds = _collectionIds.current();

        address collectionPaymentAddress = Clones.clone(
            boleroPaymentSplitterImplementation
        );
        PaymentSplitter = IBoleroPaymentSplitter(collectionPaymentAddress);
        PaymentSplitter.initialize(bolero, _payees, _roles, _shares);

        address collectionMultisigAddress = Clones.clone(
            boleroMultisigImplementation
        );

        BoleroMultisig = IBoleroMultisig(collectionMultisigAddress);
        BoleroMultisig.initialize(
            _payees,
            _payees.length,
            collectionPaymentAddress
        );

        PaymentSplitter.setMultisigWallet(collectionMultisigAddress);

        Collection memory _newCollection = Collection(
            artistAddress,
            collectionPaymentAddress,
            privateSaleToken,
            collectionName,
            newCollectionIds,
            cap,
            _royalties,
            privateSaleThreshold,
            true
        );
         
        collections[newCollectionIds] = _newCollection;
        collection_byArtist[artistAddress].push(newCollectionIds);
        multisigForCollectionID[newCollectionIds] = collectionMultisigAddress;
        emit NewCollectionWithPaymentSplitter(
            artistAddress,
            privateSaleToken,
            collectionName,
            _payees,
            _roles,
            _shares,
            _royalties.boleroFeesPrimary,
            _royalties.boleroFeesSecondary,
            _royalties.artistRoyalties,
            cap,
            privateSaleThreshold,
            true
        );
    }

    /*******************************************************************************
     *  @notice Create a new paymentSplitter for an existing collection w/ a multisig.
     *  @param _payees Array of addresses of the different beneficiaries.
     *  @param _roles The roles of each beneficiaries/payees per index.
     *  @param _shares The ammount of shares each payees will get, index per index.
     *  @param collectionId The id of the collection.
     *******************************************************************************/
    function newPaymentSplitter(
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        uint256 _collectionId
    ) public returns (address) {
        Collection memory workingCollection = collections[_collectionId];
        require(
            msg.sender == workingCollection.artist ||
                msg.sender == IBoleroDeployer(bolero).management(),
            "!authorized"
        );
        address _collectionPaymentAddress = Clones.clone(
            boleroPaymentSplitterImplementation
        );
        PaymentSplitter = IBoleroPaymentSplitter(_collectionPaymentAddress);
        PaymentSplitter.initialize(bolero, _payees, _roles, _shares);
        address collectionMultisigAddress = Clones.clone(
            boleroMultisigImplementation
        );

        BoleroMultisig = IBoleroMultisig(collectionMultisigAddress);
        BoleroMultisig.initialize(
            _payees,
            _payees.length,
            _collectionPaymentAddress
        );

        PaymentSplitter.setMultisigWallet(collectionMultisigAddress);
        setCollectionPaymentAddress(_collectionPaymentAddress, _collectionId);
        return _collectionPaymentAddress;
    }

    /*******************************************************************************
     *  @notice Replace the payment address of a collection. Can only be called by
     *          the artist or Bolero.
     *  @param _payment new address to use as payment address
     *  @param _collectionId id of the collection to update
     *******************************************************************************/
    function setCollectionPaymentAddress(
        address _payment,
        uint256 _collectionId
    ) public {
        Collection storage col = collections[_collectionId];
        require(
            msg.sender == IBoleroDeployer(bolero).management() ||
                msg.sender == col.artist,
            "!authorized"
        );
        require(_payment != address(0), "!payment");
        col.payment = _payment;
    }

    /*******************************************************************************
     *  @notice Mint a new NFT for a specific address.
     *  @param _to: Address of the address receiving the new token
     *  @param _tokenURI: Data to attach to this token
     *  @param _collectionId: the collection in wich we should put this token
     *******************************************************************************/
    function _mintNFT(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId
    ) internal returns (uint256) {
        require(_collectionId != 0, "!collectionId");
        Collection memory workingCollection = collections[_collectionId];
        require(
            msg.sender == workingCollection.artist ||
                msg.sender == IBoleroDeployer(bolero).management(),
            "!authorized"
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        uint256 numberOfItemsInCollection = collection_tokensIds[_collectionId]
            .length;
        require(numberOfItemsInCollection < workingCollection.cap, "!cap");

        collection_tokensIds[_collectionId].push(newItemId);
        collectionForTokenID[newItemId] = _collectionId;
        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }

    function mintNFT(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId
    ) public returns (uint256) {
        return _mintNFT(_to, _tokenURI, _collectionId);
    }

    /*******************************************************************************
     *  @notice Mint a new NFT for a specific address and put a sell offer on the
     *          swap contract
     *  @param _to: Address of the address receiving the new token
     *  @param _tokenURI: Data to attach to this token
     *  @param _collectionId: the collection in wich we should put this token
     *  @param _wantToken: token expected as countervalue
     *  @param _wantAmount: amount expected as countervalue
     *******************************************************************************/
    function mintNFTAndOpenSellOffer(
        MintData memory _mintData,
        address _wantToken,
        uint256 _wantAmount
    ) public returns (uint256) {
        Collection storage col = collections[_mintData._collectionId];
        uint256 _tokenId = _mintNFT(
            address(this),
            _mintData._tokenURI,
            _mintData._collectionId
        );
        IERC721(address(this)).approve(boleroSwap, _tokenId);
        IBoleroSwap(boleroSwap).openSellOffer(
            address(this),
            _wantToken,
            _mintData._to,
            col.payment,
            _tokenId,
            _wantAmount
        );
        return _tokenId;
    }

    /*******************************************************************************
     *  @notice Mint a new NFT for a specific address and put a bid offer on the
     *          swap contract
     *  @param _to: Address of the address receiving the new token
     *  @param _tokenURI: Data to attach to this token
     *  @param _collectionId: the collection in wich we should put this token
     *  @param _wantToken: token expected as countervalue
     *  @param _startOffer start price for this bid
     *  @param _startTime: start time for this auction
     *  @param _endTime: end time for this auction
     *******************************************************************************/
    function _mintNFTAndOpenBidOfferHelper(MintData memory _mintData)
        internal
        returns (uint256, address)
    {
        Collection storage col = collections[_mintData._collectionId];
        uint256 tokenId = _mintNFT(
            address(this),
            _mintData._tokenURI,
            _mintData._collectionId
        );
        IERC721(address(this)).approve(boleroSwap, tokenId);
        return (tokenId, col.payment);
    }

    function mintNFTAndOpenBidOffer(
        MintData memory _mintData,
        address _wantToken,
        uint256 _startOffer,
        uint256[2] memory _startEndTime
    ) public returns (uint256) {
        (uint256 _tokenId, address _payment) = _mintNFTAndOpenBidOfferHelper(
            _mintData
        );
        return
            IBoleroSwap(boleroSwap).openBid(
                address(this),
                _wantToken,
                _mintData._to,
                _payment,
                _tokenId,
                _startOffer,
                _startEndTime
            );
    }

    /*******************************************************************************
     *  @notice Mint a batch of new NFT. Only the Bolero Management or the artist
     *          can mint.
     *  @param _mintData: Array of MintData to mint the NFT
     *******************************************************************************/
    function mintBatchNFT(MintData[] memory _mintData) public {
        for (uint256 index = 0; index < _mintData.length; index++) {
            _mintNFT(
                _mintData[index]._to,
                _mintData[index]._tokenURI,
                _mintData[index]._collectionId
            );
        }
    }

    /*******************************************************************************
     *  @notice Mint a batch of new NFT for a specific address and put a sell offer
     *          on the swap contract
     *  @param _mintData: Array of MintAndSellData to mint the NFT
     *******************************************************************************/
    function mintBatchNFTAndOpenSellOffer(MintAndSellData[] memory _mintData)
        public
    {
        for (uint256 index = 0; index < _mintData.length; index++) {
            Collection storage col = collections[
                _mintData[index]._collectionId
            ];
            uint256 tokenId = _mintNFT(
                address(this),
                _mintData[index]._tokenURI,
                _mintData[index]._collectionId
            );
            IERC721(address(this)).approve(boleroSwap, tokenId);
            IBoleroSwap(boleroSwap).openSellOffer(
                address(this),
                _mintData[index]._wantToken,
                _mintData[index]._to,
                col.payment,
                tokenId,
                _mintData[index]._wantAmount
            );
        }
    }

    /*******************************************************************************
     *  @notice Mint a batch of new NFT for a specific address and put a bid offer
     *          on the swap contract
     *  @param _mintData: Array of MintAndBidData to mint the NFT
     *******************************************************************************/
    function mintBatchNFTAndOpenBidOffer(MintAndBidData[] memory _mintData)
        public
    {
        for (uint256 index = 0; index < _mintData.length; index++) {
            Collection storage col = collections[
                _mintData[index]._collectionId
            ];
            uint256 tokenId = _mintNFT(
                address(this),
                _mintData[index]._tokenURI,
                _mintData[index]._collectionId
            );
            IERC721(address(this)).approve(boleroSwap, tokenId);
            IBoleroSwap(boleroSwap).openBid(
                address(this),
                _mintData[index]._wantToken,
                _mintData[index]._to,
                col.payment,
                tokenId,
                _mintData[index]._startOffer,
                _mintData[index]._startEndTime
            );
        }
    }

    /*******************************************************************************
     *  @dev Set the implementation of the paymentSplitter to be cloned.
     *  @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroPaymentSplitterImplementation(address implementation)
        public
        onlyBolero
    {
        boleroPaymentSplitterImplementation = implementation;
        emit newBoleroMultisigImplementation(implementation);
    }

    /*******************************************************************************
     *  @dev Set the implementation of the multiSig to be cloned.
     *  @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroMultisigImplementation(address implementation)
        public
        onlyBolero
    {
        boleroMultisigImplementation = implementation;
        emit newBoleroMultisigImplementation(implementation);
    }

    /*******************************************************************************
     *  @dev Return the royalties for a specific token
     *******************************************************************************/
    function getRoyalties(uint256 _tokenID) external view returns (uint256) {
        uint256 collectionForToken = getCollectionIDForToken(_tokenID);
        return collections[collectionForToken].royalties.artistRoyalties;
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 collectionForToken = getCollectionIDForToken(tokenId);
  
        return (
            rewards2981,
            (value * (collections[collectionForToken].royalties.boleroFeesSecondary + collections[collectionForToken].royalties.artistRoyalties)) /
                MAXIMUM_PERCENT
        );
  
    }

    /*******************************************************************************
     *  @dev Return the collection for a specific token
     *******************************************************************************/
    function getCollectionForToken(uint256 _tokenID)
        public
        view
        returns (Collection memory)
    {
        Collection memory col = collections[collectionForTokenID[_tokenID]];
        return col;
    }

    /*******************************************************************************
     *  @dev Return the collectionID for a specific token
     *******************************************************************************/
    function getCollectionIDForToken(uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        return collectionForTokenID[_tokenID];
    }

    /*******************************************************************************
     *  @dev Return the list of tokens for a specific collection
     *******************************************************************************/
    function listTokensForCollection(uint256 _collectionID)
        public
        view
        returns (uint256[] memory)
    {
        return collection_tokensIds[_collectionID];
    }

    /*******************************************************************************
     *  @dev Return the list of collections for a specific artist
     *******************************************************************************/
    function listCollectionsForArtist(address _artist)
        public
        view
        returns (uint256[] memory)
    {
        return collection_byArtist[_artist];
    }

    /*******************************************************************************
     *  @dev Return the payment address for a specific token
     *******************************************************************************/
    function artistPayment(uint256 _tokenID) public view returns (address) {
        uint256 collectionForToken = getCollectionIDForToken(_tokenID);
        Collection memory col = collections[collectionForToken];
        return col.payment;
    }

    /*******************************************************************************
     *  @dev Return the payment address for a specific collection id
     *******************************************************************************/
    function collectionPayment(uint256 _collectionId)
        external
        view
        returns (address)
    {
        return collections[_collectionId].payment;
    }

    /*******************************************************************************
     *  @dev Return the multisig address for a specific collection id
     *******************************************************************************/
    function collectionMultisig(uint256 _collectionId)
        external
        view
        returns (address)
    {
        return multisigForCollectionID[_collectionId];
    }

    /*******************************************************************************
     *  @dev Return if payment address for an artist is a paymentSplitter or not
     *******************************************************************************/
    function isWithPaymentSplitter(uint256 _collectionId)
        external
        view
        returns (bool)
    {
        return collections[_collectionId].isWithPaymentSplitter;
    }

    /*******************************************************************************
     *  @dev set theshold cap
     *******************************************************************************/
    function setThresholdPrivate(uint256 _collectionId, uint256 cap)
        public 
        onlyBolero
    {
         collections[_collectionId].privateSaleThreshold = cap;
    }

    /*******************************************************************************
     *  @dev Return the list of tokens for a specific artist
     *******************************************************************************/
    function listTokensForArtist(address _artist)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _collections = listCollectionsForArtist(_artist);
        uint256 currentIndex = 0;
        uint256 len = 0;

        for (uint256 index = 0; index < _collections.length; index++) {
            uint256[] memory tokensForCollection = listTokensForCollection(
                _collections[index]
            );
                len += tokensForCollection.length;
        }

        uint256[] memory _tokens = new uint256[](len);
        for (uint256 index = 0; index < _collections.length; index++) {
            uint256[] memory tokensForCollection = listTokensForCollection(
                _collections[index]
            );
            for (
                uint256 index2 = 0;
                index2 < tokensForCollection.length;
                index2++
            ) {
                _tokens[currentIndex] = tokensForCollection[index2];
                currentIndex += 1;
            }
        }
        return _tokens;
    }

    /*******************************************************************************
     *  @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *******************************************************************************/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
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

    /*******************************************************************************
     *  @notice Check if a user could access the offer/bid for a specific collection
     *  @param _userAddress address to check whitelisting
     *  @param _tokenID id of the token to check
     *******************************************************************************/
    function canSwap(address _userAddress, uint256 _tokenID)
        public
        view
        returns (bool)
    {
        Collection memory col = collections[collectionForTokenID[_tokenID]];
        if (
            isSecondaryMarket[_tokenID] || col.privateSaleToken == address(0) || col.privateSaleThreshold == 0
        ) {
            return true;
        }
        uint256 balanceOfUser = IERC20(col.privateSaleToken).balanceOf(
            _userAddress
        );
        if (balanceOfUser >= col.privateSaleThreshold) {
            return true;
        }
        return false;
    }

    /*******************************************************************************
     *  @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *       `tokenId` must exist.
     *******************************************************************************/
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function changeTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyBolero
    {
        _setTokenURI(tokenId, _tokenURI);
        emit ChangeTokenURI(tokenId, _tokenURI);
    }

    /*******************************************************************************
     *  @dev Replace the swap contract address.
     *******************************************************************************/
    function setBoleroSwap(address _swap) public onlyBolero {
        boleroSwap = _swap;
    }

    function setRewards(address _newRewards2981) public onlyBolero {
        rewards2981 = _newRewards2981;
    }

    /*******************************************************************************
     *  @dev Notify secondary market
     *******************************************************************************/
    function setSecondaryMarketStatus(uint256 _tokenID) public {
        require(msg.sender == boleroSwap, "!swap");
        isSecondaryMarket[_tokenID] = true;
        emit SetSecondaryMarket(_tokenID);
    }

    /*******************************************************************************
     *  @dev Get secondary market value
     *******************************************************************************/
    function getIsSecondaryMarket(uint256 _tokenID) external view returns (bool){
        return isSecondaryMarket[_tokenID];
    }

    /*******************************************************************************
     *  Requirements:
     *  @dev Burns `tokenId`. See {ERC721-_burn}.
     *       - The caller must own `tokenId` or be an approved operator.
     *******************************************************************************/
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

}

// SPDX-License-Identifier: UNLICENSED

/**
▀█████████▄   ▄██████▄   ▄█          ▄████████    ▄████████  ▄██████▄  
  ███    ███ ███    ███ ███         ███    ███   ███    ███ ███    ███ 
  ███    ███ ███    ███ ███         ███    █▀    ███    ███ ███    ███ 
 ▄███▄▄▄██▀  ███    ███ ███        ▄███▄▄▄      ▄███▄▄▄▄██▀ ███    ███ 
▀▀███▀▀▀██▄  ███    ███ ███       ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███    ███ 
  ███    ██▄ ███    ███ ███         ███    █▄  ▀███████████ ███    ███ 
  ███    ███ ███    ███ ███▌    ▄   ███    ███   ███    ███ ███    ███ 
▄█████████▀   ▀██████▀  █████▄▄██   ██████████   ███    ███  ▀██████▀  
                        ▀                        ███    ███   
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBoleroERC721.sol";

contract LockRegistry is Ownable {
    mapping(address => bool) public approvedContract;
    mapping(uint256 => bool) public lockMap;
    address[] public keys;

    event TokenLocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );
    event TokenUnlocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );

    function isLocked(uint256 _id) external view returns (bool) {
        return lockMap[_id];
    }

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external onlyOwner {
          require(_contracts.length == _values.length, "!length");
          for(uint256 i = 0; i < _contracts.length; i++){
            keys.push(_contracts[i]);
            approvedContract[_contracts[i]] = _values[i];
          }
    }

    function initApprovedContracts( address[] memory _contracts ) internal  {
        for(uint256 i = 0; i < _contracts.length; i++){
          keys.push(_contracts[i]);
          approvedContract[_contracts[i]] = true;
        }
    }

    function getApprovedContracts() external view returns ( address[] memory ){
        return keys;
    } 

    function _lockId(uint256 _id) internal {
        require(!lockMap[_id], "ID already locked by caller");
        lockMap[_id] = true;
        emit TokenLocked(_id, msg.sender);
    }

    function _unlockId(uint256 _id) internal {
        require(lockMap[_id], "ID already unlocked");

        lockMap[_id] = false;
        emit TokenUnlocked(_id, msg.sender);
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