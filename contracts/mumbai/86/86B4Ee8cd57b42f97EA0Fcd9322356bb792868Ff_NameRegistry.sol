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
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NameRegistry
 * @author limone (@lim0n3)
 * @custom:version 2.0.0
 *
 * @notice NameRegistry lets any ETH addrxess claim a Open Work Graph Name (owUsername). A name is a rentable
 *         ERC-721 that can be registered for one year by paying a fee. On expiry, the owner has
 *         30 days to renew the name by paying a fee, or it is placed in a dutch autction.
 *
 *         The NameRegistry starts in the seedable state where only a trusted caller can register
 *         owUsernames and can be moved to an open state where any address can register an owUsername. The
 *         Registry implements a recovery system which lets the address nominate a recovery address
 *         that can transfer the owUsername to a new address after a delay.
 */
contract NameRegistry is ERC721, Ownable {
  /**
   * @dev Contains the metadata for an owUsername
   * @param recovery Address that can recover the owUsername.
   * @param expiryTs The time at which the owUsername expires.
   */
  struct Metadata {
    address recovery;
    uint40 expiryTs;
    uint40 registeredTs;
  }

  /**
   * @dev Contains the state of the most recent recovery attempt.
   * @param destination Destination of the current recovery or address(0) if no active recovery.
   * @param startTs Timestamp of the current recovery or zero if no active recovery.
   */
  struct RecoveryState {
    address destination;
    uint40 startTs;
  }

  /**
   * @dev Contains information about a reclaim action performed on an owUsername.
   * @param tokenId The uint256 representation of the owUsername.
   * @param destination The address that the owUsername is being reclaimed to.
   */
  struct ReclaimAction {
    uint256 tokenId;
    address destination;
  }

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @dev Revert when there are not enough funds to complete the transaction
  error InsufficientFunds();

  /// @dev Revert when the caller does not have the authority to perform the action
  error Unauthorized();

  /// @dev Revert if the caller does not have ADMIN_ROLE
  error NotAdmin();

  /// @dev Revert if the caller does not have OPERATOR_ROLE
  error NotOperator();

  /// @dev Revert if the caller does not have MODERATOR_ROLE
  error NotModerator();

  /// @dev Revert if the caller does not have TREASURER_ROLE
  error NotTreasurer();

  /// @dev Revert when excess funds could not be sent back to the caller
  error CallFailed();

  /// @dev Revert when the commit hash is not found
  error InvalidCommit();

  /// @dev Revert when a commit is re-submitted before it has expired
  error CommitReplay();

  /// @dev Revert if the owUsername has invalid characters during registration
  error InvalidName();

  /// @dev Revert if renew() is called on a registered name.
  error Registered();

  /// @dev Revert if an operation is called on a name that hasn't been minted
  error Registrable();

  /// @dev Revert if makeCommit() is invoked before trustedCallerOnly is disabled
  error Seedable();

  /// @dev Revert if trustedRegister() is invoked after trustedCallerOnly is disabled
  error NotSeedable();

  /// @dev Revert if the owUsername being operated on is renewable or biddable
  error Expired();

  /// @dev Revert if renew() is called after the owUsername becomes Biddable
  error NotRenewable();

  /// @dev Revert if bid() is called on an owUsername that has not become Biddable.
  error NotBiddable();

  /// @dev Revert when completeRecovery() is called before the escrow period has elapsed.
  error Escrow();

  /// @dev Revert if a recovery operation is called when there is no active recovery.
  error NoRecovery();

  /// @dev Revert if the recovery address is set to address(0).
  error InvalidRecovery();

  /// @dev Revert when an invalid address is provided as input.
  error InvalidAddress();

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Emit an event when a Open Work Graph Name is renewed for another year.
   *
   * @param tokenId The uint256 representation of the owUsername
   * @param expiry  The timestamp at which the renewal expires
   */
  event Renew(uint256 indexed tokenId, uint256 expiry);

  /**
   * @dev Emit an event when a Open Work Graph Name's recovery address is updated
   *
   * @param tokenId  The uint256 representation of the owUsername being updated
   * @param recovery The new recovery address
   */
  event ChangeRecoveryAddress(
    uint256 indexed tokenId,
    address indexed recovery
  );

  /**
   * @dev Emit an event when a recovery request is initiated for a Open Work Graph Name
   *
   * @param from     The custody address of the owUsername being recovered.
   * @param to       The destination address for the owUsername when the recovery is completed.
   * @param tokenId  The uint256 representation of the owUsername being recovered
   */
  event RequestRecovery(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emit an event when a recovery request is cancelled
   *
   * @param by      The address that cancelled the recovery request
   * @param tokenId The uint256 representation of the owUsername
   */
  event CancelRecovery(address indexed by, uint256 indexed tokenId);

  /**
   * @dev Emit an event when the trusted caller is modified
   *
   * @param trustedCaller The address of the new trusted caller.
   */
  event ChangeTrustedCaller(address indexed trustedCaller);

  /**
   * @dev Emit an event when the trusted only state is disabled.
   */
  event DisableTrustedOnly();

  /**
   * @dev Emit an event when the vault address is modified
   *
   * @param vault The address of the new vault.
   */
  event ChangeVault(address indexed vault);

  /**
   * @dev Emit an event when the pool address is modified
   *
   * @param pool The address of the new pool.
   */
  event ChangePool(address indexed pool);

  /**
   * @dev Emit an event when the fee is changed
   *
   * @param fee The new yearly registration fee
   */
  event ChangeFee(uint256 fee);

  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  /*
   * WARNING - DO NOT CHANGE THE ORDER OF THESE VARIABLES ONCE DEPLOYED
   *
   * Any changes before deployment should be copied to NameRegistryV2 in NameRegistryUpdate.t.sol
   *
   * Many variables are kept public to test the contract, since the inherit and extend trick in
   * IdRegistry is harder to pull off due to the UUPS structure.
   */

  /**
   * @notice The fee to renew a name for a full calendar year
   * @dev    Occupies slot 0.
   */
  uint256 public fee;

  /**
   * @notice The address controlled by the Open Work Graph Bootstrap service allowed to call
   *         trustedRegister
   * @dev    Occupies slot 1
   */
  address public trustedCaller;

  /**
   * @notice Flag that determines if registration can occur through trustedRegister or register
   * @dev    Occupies slot 2, initialized to 1 and can only be changed to zero
   */
  uint256 public trustedOnly;

  /**
   * @notice Maps each commit to the timestamp at which it was created.
   * @dev    Occupies slot 3
   */
  mapping(bytes32 => uint256) public timestampOf;

  /**
   * @notice The address that funds can be withdrawn to
   * @dev    Occupies slot 4
   */
  address public vault;

  /**
   * @notice The address that names can be reclaimed to
   * @dev    Occupies slot 5
   */
  address public pool;

  /**
   * @notice Maps each uint256 representation of an owUsername to registration metadata
   * @dev    Occupies slot 6
   */
  mapping(uint256 => Metadata) public metadataOf;

  /**
   * @notice Maps each uint256 representation of an owUsername to recovery metadata
   * @dev    Occupies slot 7
   */
  mapping(uint256 => RecoveryState) public recoveryStateOf;

  /**
   * @dev Added to allow future versions to add new variables in case this contract becomes
   *      inherited. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[40] private __gap;

  /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

  string internal constant BASE_URI = "http://www.backdrop.so/u/";

  /// @dev enforced delay between makeCommit() and register() to prevent front-running
  uint256 internal constant REVEAL_DELAY = 60 seconds;

  /// @dev enforced delay in makeCommit() to prevent griefing by replaying the commit
  uint256 internal constant COMMIT_REPLAY_DELAY = 10 minutes;

  uint256 internal constant REGISTRATION_PERIOD = 365 days;

  uint256 internal constant CHANGE_PERIOD = 60 days;

  uint256 internal constant RENEWAL_PERIOD = 30 days;

  uint256 internal constant ESCROW_PERIOD = 3 days;

  /// @dev Starting price of every bid during the first period
  uint256 internal constant BID_START_PRICE = 1000 ether;

  /// @dev 60.18-decimal fixed-point that decreases the price by 10% when multiplied
  uint256 internal constant BID_PERIOD_DECREASE_UD60X18 = 0.9 ether;

  /// @dev 60.18-decimal fixed-point that approximates divide by 28,800 when multiplied
  uint256 internal constant DIV_28800_UD60X18 = 3.4722222222222e13;

  uint256 internal constant INITIAL_FEE = 0.01 ether;

  /*//////////////////////////////////////////////////////////////
                      CONSTRUCTORS AND INITIALIZERS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Disable initialization to protect the contract and configure the trusted forwarder.
   */
  // solhint-disable-next-line no-empty-blocks
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault,
    address _pool
  ) ERC721(_tokenName, _tokenSymbol) Ownable() {
    vault = _vault;
    emit ChangeVault(_vault);

    pool = _pool;
    emit ChangePool(_pool);

    fee = INITIAL_FEE;
    emit ChangeFee(INITIAL_FEE);

    /* Set the contract to the seedable state */
    trustedOnly = 1;
  }

  /*//////////////////////////////////////////////////////////////
                           REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * INVARIANT 1A: If an owUsername is not minted:
   *               metadataOf[id].expiryTs == 0 &&
   *               ownerOf(id) == address(0) &&
   *               metadataOf[id].recovery[id] == address(0)
   *
   * INVARIANT 1B: If an owUsername is minted:
   *               metadataOf[id].expiryTs != 0 &&
   *               ownerOf(id) != address(0).
   *
   * INVARIANT 2: An owUsername cannot be transferred to address(0) after it is minted.
   */

  /**
   * @notice Generate a commitment to use in a commit-reveal scheme to register an owUsername and
   *         prevent front-running.
   *
   * @param owUsername  The owUsername to be registered
   * @param to     The address that will own the owUsername
   * @param secret A secret that will be broadcast on-chain during the reveal
   */
  function generateCommit(
    bytes16 owUsername,
    address to,
    bytes32 secret,
    address recovery
  ) public pure returns (bytes32 commit) {
    /* Revert unless the owUsername is valid */
    _validateName(owUsername);

    /* Perf: Do not validate to != address(0) because it happens during register */
    commit = keccak256(abi.encodePacked(owUsername, to, recovery, secret));
  }

  /**
   * @notice Save a commitment on-chain which can be revealed later to register an owUsername. The
   *         commit reveal scheme protects the register action from being front run. makeCommit
   *         can be called even when the contract is paused.
   *
   * @param commit The commitment hash to be saved on-chain
   */
  function makeCommit(bytes32 commit) external {
    /* Revert if the contract is in the Seedable state */
    if (trustedOnly == 1) revert Seedable();

    /**
     * Revert unless some time has passed since the last commit to prevent griefing by
     * replaying the commit and restarting the REVEAL_DELAY timer.
     *
     *  Safety: cannot overflow because timestampOf[commit] is a block.timestamp or zero
     */
    unchecked {
      if (block.timestamp <= timestampOf[commit] + COMMIT_REPLAY_DELAY) {
        revert CommitReplay();
      }
    }

    timestampOf[commit] = block.timestamp;
  }

  /**
   * @notice Mint a new owUsername if the inputs match a previous commit and if it was called at least
   *         60 seconds after the commit's timestamp to prevent frontrunning within the same block.
   *         It fails when paused because it invokes _mint which in turn invokes beforeTransfer()
   *
   * @param owUsername    The owUsername to register
   * @param to       The address that will own the owUsername
   * @param secret   The secret value in the commitment
   * @param recovery The address which can recover the owUsername if the custody address is lost
   */
  function register(
    bytes16 owUsername,
    address to,
    bytes32 secret,
    address recovery
  ) external payable {
    /* Revert if the registration fee was not provided */
    uint256 _fee = fee;
    if (msg.value < _fee) revert InsufficientFunds();

    /**
     * Revert unless a matching commit was found
     *
     * Perf: do not check if trustedOnly = 1, because timestampOf[commit] must be zero when
     * trustedOnly = 1 since makeCommit() cannot be called.
     */
    bytes32 commit = generateCommit(owUsername, to, secret, recovery);
    uint256 commitTs = timestampOf[commit];
    if (commitTs == 0) revert InvalidCommit();

    /**
     * Revert unless the reveal delay has passed, which prevents frontrunning within the block.
     *
     * Audit: verify that 60s is the right duration to use
     * Safety: makeCommit() sets commitTs to block.timestamp which cannot overflow
     */
    unchecked {
      if (block.timestamp < commitTs + REVEAL_DELAY) {
        revert InvalidCommit();
      }
    }

    /**
     * Mints the token by calling the ERC-721 _mint() function and using the uint256 value of
     * the username as the tokenId. The _mint() function ensures that the to address isnt 0
     * and that the tokenId is not already minted.
     */
    uint256 tokenId = uint256(bytes32(owUsername));
    _mint(to, tokenId);

    /* Perf: Clearing timestamp reduces gas consumption */
    delete timestampOf[commit];

    /**
     * Set the expiration timestamp and the recovery address
     *
     * Safety: expiryTs will not overflow given that block.timestamp < block.timestamp
     */
    unchecked {
      metadataOf[tokenId].expiryTs = uint40(
        block.timestamp + REGISTRATION_PERIOD
      );
    }

    metadataOf[tokenId].recovery = recovery;

    /**
     * Refund overpayment to the caller and revert if the refund fails.
     *
     * Safety: msg.value >= _fee by check above, so this cannot overflow
     * Perf: Call msg.sender instead of msg.sender to save ~100 gas b/c we don't need meta-tx
     */
    uint256 overpayment;

    unchecked {
      overpayment = msg.value - _fee;
    }

    if (overpayment > 0) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = msg.sender.call{value: overpayment}("");
      if (!success) revert CallFailed();
    }
  }

  /**
   * @notice Mint an owUsername during the bootstrap period from the trusted caller.
   *
   * @dev The function is pauseable since it invokes _transfer by way of _mint.
   *
   * @param to the address that will claim the owUsername
   * @param owUsername the owUsername to register
   * @param recovery address which can recovery the owUsername if the custody address is lost
   */
  function trustedRegister(
    bytes16 owUsername,
    address to,
    address recovery
  ) external payable {
    /* Revert if called after the bootstrap period */
    if (trustedOnly == 0) revert NotSeedable();

    /**
     * Revert if the caller is not the trusted caller.
     *
     * Perf: Using msg.sender saves ~100 gas and prevents meta-txns while allowing the function
     * to be called by BatchRegistry.
     */
    if (msg.sender != trustedCaller) revert Unauthorized();

    /* Perf: this can be omitted to save ~3k gas */
    _validateName(owUsername);

    /**
     * Mints the token by calling the ERC-721 _mint() function and using the uint256 value of
     * the username as the tokenId. The _mint() function ensures that the to address isnt 0
     * and that the tokenId is not already minted.
     */
    uint256 tokenId = uint256(bytes32(owUsername));
    _mint(to, tokenId);

    /**
     * Set the expiration timestamp and the recovery address
     *
     * Safety: expiryTs will not overflow given that block.timestamp < block.timestamp
     */
    unchecked {
      metadataOf[tokenId].expiryTs = uint40(
        block.timestamp + REGISTRATION_PERIOD
      );
    }

    metadataOf[tokenId].recovery = recovery;
  }

  /*//////////////////////////////////////////////////////////////
                            ERC-721 OVERRIDES
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Override the ownerOf implementation to throw if an owUsername is renewable or biddable.
   *
   * @param tokenId The uint256 tokenId of the owUsername
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    /* Revert if owUsername was registered once and the expiration time has passed */
    uint256 expiryTs = uint256(metadataOf[tokenId].expiryTs);
    if (expiryTs != 0 && block.timestamp >= expiryTs) revert Expired();

    /* Safety: If the token is unregistered, super.ownerOf will revert */
    return super.ownerOf(tokenId);
  }

  /* Audit: ERC721 balanceOf will over report owner balance if the name is expired */

  /**
   * @notice Override transferFrom to throw if the name is renewable or biddable.
   *
   * @param from    The address which currently holds the owUsername
   * @param to      The address to transfer the owUsername to
   * @param tokenId The uint256 representation of the owUsername to transfer
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    /* Revert if owUsername was registered once and the expiration time has passed */
    uint256 expiryTs = uint256(metadataOf[tokenId].expiryTs);
    if (expiryTs != 0 && block.timestamp >= expiryTs) revert Expired();

    super.transferFrom(from, to, tokenId);
  }

  /**
   * @notice Override safeTransferFrom to throw if the name is renewable or biddable.
   *
   * @param from     The address which currently holds the owUsername
   * @param to       The address to transfer the owUsername to
   * @param tokenId  The uint256 tokenId of the owUsername to transfer
   * @param data     Additional data with no specified format, sent in call to `to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override {
    /* Revert if owUsername was registered once and the expiration time has passed */
    uint256 expiryTs = uint256(metadataOf[tokenId].expiryTs);
    if (expiryTs != 0 && block.timestamp >= expiryTs) revert Expired();

    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @notice Return a distinct URI for a tokenId of the form
   *         https://www.backdrop.so/u/<owUsername>.json
   *
   * @param tokenId The uint256 tokenId of the owUsername
   */
  function tokenURI(
    uint256 tokenId
  ) public pure override returns (string memory) {
    /**
     * Revert if the owUsername is invalid
     *
     * Safety: owUsernames are 16 bytes long, so truncating the token id is safe.
     */
    bytes16 owUsername = bytes16(bytes32(tokenId));
    _validateName(owUsername);

    /**
     * Find the index of the last character of the owUsername.
     *
     * Since owUsernames are between 1 and 16 bytes long, there must be at least one non-zero value
     * and there may be trailing zeros that can be discarded. Loop back from the last value
     * until the first non-zero value is found.
     */
    uint256 lastCharIdx;
    for (uint256 i = 15; ; ) {
      if (uint8(owUsername[i]) != 0) {
        lastCharIdx = i;
        break;
      }

      unchecked {
        --i; // Safety: cannot underflow because the loop ends when i == 0
      }
    }

    /* Construct a bytes[] with only valid owUsername characters */
    bytes memory owUsernameBytes = new bytes(lastCharIdx + 1);

    for (uint256 j = 0; j <= lastCharIdx; ) {
      owUsernameBytes[j] = owUsername[j];

      unchecked {
        ++j; // Safety: cannot overflow because the loop ends when j > lastCharIdx
      }
    }

    /* Return a URI of the form https://www.backdrop.so/u/<owUsername>.json */
    return string(abi.encodePacked(BASE_URI, string(owUsernameBytes), ".json"));
  }

  /**
   * @dev Hook that ensures that recovery state and address is reset whenever a transfer occurs.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override {
    super._afterTokenTransfer(from, to, tokenId, batchSize);
    delete recoveryStateOf[tokenId];
    delete metadataOf[tokenId].recovery;
  }

  /*//////////////////////////////////////////////////////////////
                             RECOVERY LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * The custodyAddress (i.e. owner) can appoint a recoveryAddress which can transfer a
   * specific owUsername if the custodyAddress is lost. The recovery address must first request the
   * transfer on-chain which moves it into escrow. If the custodyAddress does not cancel
   * the request during escrow, the recoveryAddress can then transfer the owUsername. The custody
   * address can remove or change the recovery address at any time.
   *
   * INVARIANT 3: Changing ownerOf must set recovery to address(0) and
   *              recoveryState[id].startTs to 0
   *
   * INVARIANT 4: If RecoveryState.startTs is non-zero, then RecoveryState.destination is
   *              also non zero. If RecoveryState.startTs 0, then
   *              RecoveryState.destination must also be address(0)
   */

  /**
   * @notice Change the recovery address of the owUsername, resetting active recovery requests.
   *         Supports ERC 2771 meta-transactions and can be called by a relayer.
   *
   * @param tokenId  The uint256 representation of the owUsername
   * @param recovery The address which can recover the owUsername (set to 0x0 to disable recovery)
   */
  function changeRecoveryAddress(uint256 tokenId, address recovery) external {
    /* Revert if the caller is not the owner of the owUsername */
    if (ownerOf(tokenId) != msg.sender) revert Unauthorized();

    /* Change the recovery address and reset active recovery requests */
    metadataOf[tokenId].recovery = recovery;
    delete recoveryStateOf[tokenId];

    emit ChangeRecoveryAddress(tokenId, recovery);
  }

  /**
   * @notice Request a recovery of an fid to a new address if the caller is the recovery address.
   *         Supports ERC 2771 meta-transactions and can be called by a relayer. Requests can be
   *         overwritten by making another request.
   *
   * @param tokenId The uint256 representation of the owUsername
   * @param to      The address to transfer the owUsername to, which cannot be address(0)
   */
  function requestRecovery(uint256 tokenId, address to) external {
    /* Revert if the destination is the zero address */
    if (to == address(0)) revert InvalidRecovery();

    /* Revert if the caller is not the recovery address */
    if (msg.sender != metadataOf[tokenId].recovery) {
      revert Unauthorized();
    }

    /**
     * Start the recovery by setting the timestamp and destination of the request.
     *
     * Safety: requestRecovery is allowed to be performed on a renewable or biddable name,
     * to save gas since completeRecovery will fail anyway.
     */
    recoveryStateOf[tokenId].startTs = uint40(block.timestamp);
    recoveryStateOf[tokenId].destination = to;

    emit RequestRecovery(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @notice Complete a recovery request and transfer the owUsername if the escrow period has passed.
   *         Supports ERC 2771 meta-transactions and can be called by a relayer. Cannot be called
   *         when paused because _transfer reverts.
   *
   * @param tokenId The uint256 representation of the owUsername
   */
  function completeRecovery(uint256 tokenId) external {
    /* Revert if owUsername ownership has expired and it's state is renwable or biddable */
    if (block.timestamp >= uint256(metadataOf[tokenId].expiryTs)) {
      revert Expired();
    }

    /* Revert if the caller is not the recovery address */
    if (msg.sender != metadataOf[tokenId].recovery) {
      revert Unauthorized();
    }

    /* Revert if there is no active recovery request */
    uint256 recoveryTimestamp = recoveryStateOf[tokenId].startTs;
    if (recoveryTimestamp == 0) revert NoRecovery();

    /**
     * Revert if there recovery request is still in the escrow period, which gives the custody
     * address time to cancel the request if it was unauthorized.
     *
     * Safety: recoveryTimestamp was a block.timestamp and cannot realistically overflow.
     */
    unchecked {
      if (block.timestamp < recoveryTimestamp + ESCROW_PERIOD) {
        revert Escrow();
      }
    }

    /* Safety: Invariant 4 prevents this from going to address(0) */
    _transfer(ownerOf(tokenId), recoveryStateOf[tokenId].destination, tokenId);
  }

  /**
   * @notice Cancel an active recovery request from the recovery address or the custody address.
   *  Supports ERC 2771 meta-transactions and can be called by a relayer. Can be called even if
   *  the contract is paused to avoid griefing before a known pause.
   *
   * @param tokenId The uint256 representation of the owUsername
   */
  function cancelRecovery(uint256 tokenId) external {
    /**
     * Revert if the caller is not the custody or recovery address.
     *
     * Perf: ownerOf is called instead of super.ownerOf to save gas since cancellation is safe
     * even if the name has expired.
     */
    address sender = msg.sender;
    if (
      sender != super.ownerOf(tokenId) && sender != metadataOf[tokenId].recovery
    ) {
      revert Unauthorized();
    }

    /* Revert if there is no active recovery request */
    if (recoveryStateOf[tokenId].startTs == 0) revert NoRecovery();

    delete recoveryStateOf[tokenId];

    emit CancelRecovery(sender, tokenId);
  }

  /*


  /**
  * @notice Allows a user to change their username by burning their old username token and minting a new one
  *         with the specified new username. The function first verifies that the caller is the owner of the old username token,
  *         then burns the old token, and mints the new one with the specified new username. The function also sets the
  *         expiration timestamp and recovery address of the new token.
  * @param oldOwUsername The bytes16 representation of the old username token to be burned
  * @param newOwUsername The bytes16 representation of the new username to be minted
  */
  function changeUsername(
    bytes16 oldOwUsername,
    bytes16 newOwUsername
  ) external {
    uint256 oldTokenId = uint256(bytes32(oldOwUsername));

    require(
      block.timestamp >= metadataOf[oldTokenId].registeredTs + CHANGE_PERIOD,
      "Change period has not passed"
    );

    /* Revert if the caller is not the owner of the owUsername */
    if (ownerOf(oldTokenId) != msg.sender) revert Unauthorized();

    uint256 tokenId = uint256(bytes32(newOwUsername));

    /* Perf: this can be omitted to save ~3k gas */
    _validateName(newOwUsername);

    address recovery = metadataOf[oldTokenId].recovery;

    /* Burn the old owUsername token and mint a new one */
    _burn(oldTokenId);
    delete metadataOf[oldTokenId];

    /**
     * Mints the token by calling the ERC-721 _mint() function and using the uint256 value of
     * the username as the tokenId. The _mint() function ensures that the to address isnt 0
     * and that the tokenId is not already minted.
     */
    _mint(msg.sender, tokenId);

    /**
     * Set the expiration timestamp and the recovery address
     *
     * Safety: expiryTs will not overflow given that block.timestamp < block.timestamp
     */
    unchecked {
      metadataOf[tokenId].expiryTs = uint40(
        block.timestamp + REGISTRATION_PERIOD
      );
      metadataOf[tokenId].registeredTs = uint40(block.timestamp);
    }

    metadataOf[tokenId].recovery = recovery;
  }

  /*//////////////////////////////////////////////////////////////
                            MODERATOR ACTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Move the owUsernames from their current owners to their new destinations and renew them
   *         for 30 days if they expire within the next 30 days. Does not work when paused
   *         because it calls _transfer.
   *
   * @param reclaimActions an array of ReclaimAction structs representing the owUsernames and their
   *                       destination addresses.
   */
  function reclaim(
    ReclaimAction[] calldata reclaimActions
  ) external payable onlyOwner {
    uint256 reclaimActionsLength = reclaimActions.length;

    for (uint256 i = 0; i < reclaimActionsLength; ) {
      /* Revert if the owUsername was never registered */
      uint256 tokenId = reclaimActions[i].tokenId;
      uint256 _expiry = uint256(metadataOf[tokenId].expiryTs);
      if (_expiry == 0) revert Registrable();

      /* Transfer the name with super.ownerOf so that it works even if the name is expired */
      _transfer(super.ownerOf(tokenId), reclaimActions[i].destination, tokenId);

      /**
       * If the owUsername expires soon, extend its expiry by 30 days
       *
       * Safety: RENEWAL_PERIOD is a constant much smaller than _expiry which is a recent
       * block.timestamp and subtraction cannot underflow.
       *
       * Safety: block.timestamp + RENEWAL_PERIOD cannot overflow a uint40 for many years.
       */

      unchecked {
        if (block.timestamp >= _expiry - RENEWAL_PERIOD) {
          metadataOf[tokenId].expiryTs = uint40(
            block.timestamp + RENEWAL_PERIOD
          );
        }
        i++; // Safety: the loop ends if i is >= reclaimActions.length
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                              ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Changes the address from which trustedRegister calls can be made
   *
   * @param _trustedCaller The address of the new trusted caller
   */
  function changeTrustedCaller(address _trustedCaller) external onlyOwner {
    /* Revert if the trustedCaller is being set to the zero address */
    if (_trustedCaller == address(0)) revert InvalidAddress();

    trustedCaller = _trustedCaller;

    emit ChangeTrustedCaller(_trustedCaller);
  }

  /**
   * @notice Disables trustedRegister and enables register calls from any address.
   */
  function disableTrustedOnly() external onlyOwner {
    delete trustedOnly;

    emit DisableTrustedOnly();
  }

  /**
   * @notice Changes the address to which funds can be withdrawn
   *
   * @param _vault The address of the new vault
   */
  function changeVault(address _vault) external onlyOwner {
    /* Revert if the vault is being set to the zero address */
    if (_vault == address(0)) revert InvalidAddress();

    vault = _vault;

    emit ChangeVault(_vault);
  }

  /**
   * @notice Changes the address to which names are reclaimed
   *
   * @param _pool The address of the new pool
   */
  function changePool(address _pool) external onlyOwner {
    if (_pool == address(0)) revert InvalidAddress();

    pool = _pool;
    emit ChangePool(_pool);
  }

  /*//////////////////////////////////////////////////////////////
                            TREASURER ACTIONS
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Change the fee charged to register an owUsername for a year
   *
   * @param _fee The new yearly fee
   */
  function changeFee(uint256 _fee) external onlyOwner {
    /* Audit does fee == 0 cause any problems with other logic? */
    fee = _fee;

    emit ChangeFee(_fee);
  }

  /**
   * @notice Withdraw a specified amount of ether to the vault
   *
   * @param amount The amount of ether to withdraw
   */
  function withdraw(uint256 amount) external onlyOwner {
    /* Audit: this will not revert if the requested amount is zero, will that cause problems? */
    if (address(this).balance < amount) revert InsufficientFunds();

    /* Transfer the funds to the vault and revert if the transfer fails */
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = vault.call{value: amount}("");
    if (!success) revert CallFailed();
  }

  /*//////////////////////////////////////////////////////////////
                         OPEN ZEPPELIN OVERRIDES
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId);
  }

  /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Reverts if the owUsername contains an invalid character
   *
   * Iterate over the bytes16 owUsername one char at a time, ensuring that:
   *   1. The name begins with [a-z 0-9] or the ascii numbers [48-57, 97-122] inclusive
   *   2. The name can contain [a-z 0-9 -] or the ascii numbers [45, 48-57, 97-122] inclusive
   *   3. Once the name is ended with a NULL char (0), the follows character must also be NULLs
   */
  // solhint-disable-next-line code-complexity
  function _validateName(bytes16 owUsername) internal pure {
    /* Revert if the name begins with a underscore */
    if (uint8(owUsername[0]) == 95) revert InvalidName();

    uint256 length = owUsername.length;
    if (length < 2) revert InvalidName();
    bool nameEnded = false;

    for (uint256 i = 0; i < length; ) {
      uint8 charInt = uint8(owUsername[i]);

      unchecked {
        i++; // Safety: i can never overflow because length is <= 16
      }

      if (nameEnded) {
        /* Revert if non NULL characters are found after a NULL character */
        if (charInt != 0) {
          revert InvalidName();
        }
      } else {
        if ((charInt >= 97 && charInt <= 122)) {
          continue; // The character is one of a-z
        }

        if ((charInt >= 48 && charInt <= 57)) {
          continue; // The character is one of 0-9
        }

        if ((charInt == 95)) {
          continue; // The character is a hyphen
        }

        /**
         * If a null character is discovered in the owUsername:
         * - revert if it is the first character, since the name must have at least 1 non NULL character
         * - otherwise, mark the name as having ended, with the null indicating unused bytes.
         */
        if (charInt == 0) {
          if (i == 1) revert InvalidName(); // Check i==1 since i is incremented before the check

          nameEnded = true;
          continue;
        }

        /* Revert if invalid ASCII characters are found before the name ends    */
        revert InvalidName();
      }
    }
  }
}