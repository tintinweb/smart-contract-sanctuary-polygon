// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract GlobalLegendAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;
    mapping(address => bool) private writers;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WriterAdded(address indexed writer);
    event WriterRemoved(address indexed writer);

    modifier onlyAdmin() {
        require(admins[msg.sender], "GlobalLegendAccessControl: Only admin can perform this action");
        _;
    }

    modifier onlyWrite() {
        require(
            writers[msg.sender],
            "GlobalLegendAccessControl: Only authorized writers can perform this action"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        symbol = _symbol;
        name = _name;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "GlobalLegendAccessControl: Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != msg.sender, "GlobalLegendAccessControl: Cannot remove yourself as admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function addWriter(address _writer) external onlyAdmin {
        writers[_writer] = true;
        emit WriterAdded(_writer);
    }

    function removeWriter(address _writer) external onlyAdmin {
        writers[_writer] = false;
        emit WriterRemoved(_writer);
    }

    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    function isWriter(address _writer) public view returns (bool) {
        return writers[_writer];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract LegendAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        require(
            admins[msg.sender],
            "LegendAccessControl: Only admins can perform this action"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _externalOwner
    ) {
        symbol = _symbol;
        name = _name;
        admins[_externalOwner] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != msg.sender, "Cannot remove yourself as admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendNFT.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendPayment.sol";
import "./LegendEscrow.sol";
import "./LegendDrop.sol";
import "./LegendFactory.sol";
import "./LegendFulfillment.sol";

interface IDynamicNFT {
    function getDeployerAddress() external view returns (address);

    function getCollectorClaimedNFT(address) external view returns (bool);
}

interface ILegendKeeper {
    function getPostId() external view returns (uint256);
}

library MintParamsLibrary {
    struct MintParams {
        address[] acceptedTokens;
        uint256[] basePrices;
        string uri;
        string printType;
        uint256 fulfillerId;
        uint256 discount;
        bool grantCollectorsOnly;
    }
}

contract LegendCollection {
    using MintParamsLibrary for MintParamsLibrary.MintParams;

    LegendNFT private _legendNFT;
    LegendFulfillment private _legendFulfillment;
    GlobalLegendAccessControl private _accessControl;
    LegendPayment private _legendPayment;
    LegendEscrow private _legendEscrow;
    LegendDrop private _legendDrop;
    LegendFactory private _legendFactory;
    uint256 private _collectionSupply;
    string public symbol;
    string public name;

    struct Collection {
        uint256[] basePrices;
        uint256[] tokenIds;
        uint256 collectionId;
        uint256 amount;
        uint256 dropId;
        uint256 timestamp;
        address[] acceptedTokens;
        address creator;
        string uri;
        bool isBurned;
    }

    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => uint256) private _fulfillerId;
    mapping(uint256 => string) private _printType;
    mapping(uint256 => uint256) private _discount;
    mapping(uint256 => bool) private _grantCollectorsOnly;
    mapping(uint256 => uint256) private _pubId;
    mapping(uint256 => address) private _dynamicNFTAddress;

    event CollectionMinted(
        uint256 indexed collectionId,
        string uri,
        uint256 amount,
        address owner
    );

    event CollectionAdded(
        uint256 indexed collectionId,
        uint256 amount,
        address owner
    );

    event CollectionBurned(
        address indexed burner,
        uint256 indexed collectionId
    );

    event CollectionURIUpdated(
        uint256 indexed collectionId,
        string oldURI,
        string newURI,
        address updater
    );

    event CollectionBasePricesUpdated(
        uint256 indexed collectionId,
        uint256[] oldPrices,
        uint256[] newPrices,
        address updater
    );

    event CollectionAcceptedTokensUpdated(
        uint256 indexed collectionId,
        address[] oldAcceptedTokens,
        address[] newAcceptedTokens,
        address updater
    );

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );

    event LegendFulfillmentUpdated(
        address indexed oldLegendFulfillment,
        address indexed newLegendFulfillment,
        address updater
    );

    event LegendPaymentUpdated(
        address indexed oldLegendPayment,
        address indexed newLegendPayment,
        address updater
    );

    event LegendFactoryUpdated(
        address indexed oldLegendFactory,
        address indexed newLegendFactory,
        address updater
    );

    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );

    event LegendDropUpdated(
        address indexed oldLegendDrop,
        address indexed newLegendDrop,
        address updater
    );

    event CollectionFulfillerIdUpdated(
        uint256 indexed collectionId,
        uint256 oldFulfillerId,
        uint256 newFulfillerId,
        address updater
    );

    event CollectionDropIdUpdated(
        uint256 indexed collectionId,
        uint256 newDropId,
        address updater
    );

    event CollectionPrintTypeUpdated(
        uint256 indexed collectionId,
        string oldPrintType,
        string newPrintType,
        address updater
    );

    event CollectionDiscountUpdated(
        uint256 indexed collectionId,
        uint256 discount,
        address updater
    );

    event CollectionGrantCollectorsOnlyUpdated(
        uint256 indexed collectionId,
        bool grantCollectorOnly,
        address updater
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCreator(uint256 _collectionId) {
        require(
            msg.sender == _collections[_collectionId].creator,
            "LegendCollection: Only the creator can edit this collection"
        );
        _;
    }

    modifier onlyGrantPublishers(
        address _functionCallerAddress,
        string memory _grantName
    ) {
        require(
            _legendFactory.getGrantContracts(
                _functionCallerAddress,
                _grantName
            )[2] !=
                address(0) &&
                IDynamicNFT(
                    _legendFactory.getGrantContracts(
                        _functionCallerAddress,
                        _grantName
                    )[2]
                ).getDeployerAddress() ==
                _functionCallerAddress,
            "LegendCollection: Only grant publishers can make collections for their grants."
        );
        _;
    }

    constructor(
        address _legendNFTAddress,
        address _accessControlAddress,
        address _legendPaymentAddress,
        address _legendFactoryAddress,
        string memory _symbol,
        string memory _name
    ) {
        _legendNFT = LegendNFT(_legendNFTAddress);
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _legendPayment = LegendPayment(_legendPaymentAddress);
        _legendFactory = LegendFactory(_legendFactoryAddress);
        _collectionSupply = 0;
        symbol = _symbol;
        name = _name;
    }

    function mintCollection(
        uint256 _amount,
        MintParamsLibrary.MintParams memory params,
        string memory _grantName
    ) external onlyGrantPublishers(msg.sender, _grantName) {
        address _creator = msg.sender;

        require(
            params.basePrices.length == params.acceptedTokens.length,
            "LegendCollection: Invalid input"
        );
        require(
            _accessControl.isAdmin(_creator) ||
                _accessControl.isWriter(_creator),
            "LegendCollection: Only admin or writer can perform this action"
        );
        require(
            _legendFulfillment.getFulfillerAddress(params.fulfillerId) !=
                address(0),
            "LegendFulfillment: FulfillerId does not exist."
        );
        for (uint256 i = 0; i < params.acceptedTokens.length; i++) {
            require(
                _legendPayment.checkIfAddressVerified(params.acceptedTokens[i]),
                "LegendCollection: Payment Token is Not Verified"
            );
        }

        _collectionSupply++;

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = _legendNFT.getTotalSupplyCount() + i + 1;
        }

        uint256 _pubIdValue = ILegendKeeper(
            _legendFactory.getGrantContracts(_creator, _grantName)[0]
        ).getPostId();
        address _dynamicNFTAddressValue = _legendFactory.getGrantContracts(
            _creator,
            _grantName
        )[2];

        _createNewCollection(params, _amount, tokenIds, _creator);

        _setMappings(params, _pubIdValue, _dynamicNFTAddressValue);

        _mintNFT(
            params,
            _pubIdValue,
            _amount,
            _dynamicNFTAddressValue,
            _creator
        );

        emit CollectionMinted(_collectionSupply, params.uri, _amount, _creator);
    }

    function addToExistingCollection(uint256 _collectionId, uint256 _amount)
        external
    {
        address _creator = msg.sender;
        require(
            _accessControl.isAdmin(_creator) ||
                _accessControl.isWriter(_creator),
            "LegendCollection: Only admin or writer can perform this action"
        );
        require(
            _collections[_collectionId].creator == _creator,
            "LegendCollection: Only the owner of a collection can add to it."
        );

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = _legendNFT.getTotalSupplyCount() + i + 1;
        }

        _collections[_collectionId].tokenIds = _concatenateArrays(
            _collections[_collectionId].tokenIds,
            tokenIds
        );

        MintParamsLibrary.MintParams memory params = MintParamsLibrary
            .MintParams({
                acceptedTokens: _collections[_collectionId].acceptedTokens,
                basePrices: _collections[_collectionId].basePrices,
                uri: _collections[_collectionId].uri,
                printType: _printType[_collectionId],
                fulfillerId: _fulfillerId[_collectionId],
                discount: _discount[_collectionId],
                grantCollectorsOnly: _grantCollectorsOnly[_collectionId]
            });

        _mintNFT(
            params,
            _pubId[_collectionId],
            _amount,
            _dynamicNFTAddress[_collectionId],
            _creator
        );

        emit CollectionAdded(_collectionId, _amount, _creator);
    }

    function _concatenateArrays(
        uint256[] memory array1,
        uint256[] memory array2
    ) internal pure returns (uint256[] memory) {
        uint256[] memory concatenated = new uint256[](
            array1.length + array2.length
        );

        for (uint256 i = 0; i < array1.length; i++) {
            concatenated[i] = array1[i];
        }

        for (uint256 j = 0; j < array2.length; j++) {
            concatenated[array1.length + j] = array2[j];
        }

        return concatenated;
    }

    function _setMappings(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        address _dynamicNFTAddressValue
    ) private {
        _printType[_collectionSupply] = params.printType;
        _fulfillerId[_collectionSupply] = params.fulfillerId;
        _discount[_collectionSupply] = params.discount;
        _grantCollectorsOnly[_collectionSupply] = params.grantCollectorsOnly;
        _pubId[_collectionSupply] = _pubIdValue;
        _dynamicNFTAddress[_collectionSupply] = _dynamicNFTAddressValue;
    }

    function _createNewCollection(
        MintParamsLibrary.MintParams memory params,
        uint256 _amount,
        uint256[] memory tokenIds,
        address _creatorAddress
    ) private {
        Collection memory newCollection = Collection({
            collectionId: _collectionSupply,
            acceptedTokens: params.acceptedTokens,
            basePrices: params.basePrices,
            tokenIds: tokenIds,
            amount: _amount,
            creator: _creatorAddress,
            uri: params.uri,
            isBurned: false,
            timestamp: block.timestamp,
            dropId: 0
        });

        _collections[_collectionSupply] = newCollection;
    }

    function _mintNFT(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        uint256 _amount,
        address _dynamicNFTAddressValue,
        address _creatorAddress
    ) private {
        MintParamsLibrary.MintParams memory paramsNFT = MintParamsLibrary
            .MintParams({
                acceptedTokens: params.acceptedTokens,
                basePrices: params.basePrices,
                uri: params.uri,
                printType: params.printType,
                fulfillerId: params.fulfillerId,
                discount: params.discount,
                grantCollectorsOnly: params.grantCollectorsOnly
            });

        _legendNFT.mintBatch(
            paramsNFT,
            _amount,
            _pubIdValue,
            _collectionSupply,
            _dynamicNFTAddressValue,
            _creatorAddress
        );
    }

    function burnCollection(uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        require(
            !_collections[_collectionId].isBurned,
            "LegendCollection: This collection has already been burned"
        );

        if (getCollectionDropId(_collectionId) != 0) {
            _legendDrop.removeCollectionFromDrop(_collectionId);
        }

        for (
            uint256 i = 0;
            i < _collections[_collectionId].tokenIds.length;
            i++
        ) {
            if (
                address(_legendEscrow) ==
                _legendNFT.ownerOf(_collections[_collectionId].tokenIds[i])
            ) {
                _legendEscrow.release(
                    _collections[_collectionId].tokenIds[i],
                    true,
                    address(0)
                );
            }
        }

        _collections[_collectionId].isBurned = true;
        emit CollectionBurned(msg.sender, _collectionId);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function updateLegendPayment(address _newLegendPaymentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendPayment);
        _legendPayment = LegendPayment(_newLegendPaymentAddress);
        emit LegendPaymentUpdated(
            oldAddress,
            _newLegendPaymentAddress,
            msg.sender
        );
    }

    function updateLegendFactory(address _newLegendFactoryAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFactory);
        _legendFactory = LegendFactory(_newLegendFactoryAddress);
        emit LegendFactoryUpdated(
            oldAddress,
            _newLegendFactoryAddress,
            msg.sender
        );
    }

    function setLegendEscrow(address _newLegendEscrowAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_newLegendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _newLegendEscrowAddress,
            msg.sender
        );
    }

    function setLegendDrop(address _newLegendDropAddress) external onlyAdmin {
        address oldAddress = address(_legendDrop);
        _legendDrop = LegendDrop(_newLegendDropAddress);
        emit LegendDropUpdated(oldAddress, _newLegendDropAddress, msg.sender);
    }

    function setLegendFulfillment(address _newLegendFulfillmentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFulfillment);
        _legendFulfillment = LegendFulfillment(_newLegendFulfillmentAddress);
        emit LegendFulfillmentUpdated(
            oldAddress,
            _newLegendFulfillmentAddress,
            msg.sender
        );
    }

    function getCollectionCreator(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return _collections[_collectionId].creator;
    }

    function getCollectionURI(uint256 _collectionId)
        public
        view
        returns (string memory)
    {
        return _collections[_collectionId].uri;
    }

    function getCollectionAmount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].amount;
    }

    function getCollectionAcceptedTokens(uint256 _collectionId)
        public
        view
        returns (address[] memory)
    {
        return _collections[_collectionId].acceptedTokens;
    }

    function getCollectionBasePrices(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _collections[_collectionId].basePrices;
    }

    function getCollectionIsBurned(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _collections[_collectionId].isBurned;
    }

    function getCollectionTimestamp(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].timestamp;
    }

    function getCollectionDropId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collections[_collectionId].dropId;
    }

    function getCollectionFulfillerId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _fulfillerId[_collectionId];
    }

    function getCollectionPrintType(uint256 _collectionId)
        public
        view
        returns (string memory)
    {
        return _printType[_collectionId];
    }

    function getCollectionTokenIds(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _collections[_collectionId].tokenIds;
    }

    function getCollectionDiscount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _discount[_collectionId];
    }

    function getCollectionDynamicNFTAddress(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return _dynamicNFTAddress[_collectionId];
    }

    function getCollectionPubId(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _pubId[_collectionId];
    }

    function getCollectionGrantCollectorsOnly(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return _grantCollectorsOnly[_collectionId];
    }

    function setCollectionPrintType(
        string memory _newPrintType,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setPrintType(tokenIds[i], _newPrintType);
            }
        }
        string memory oldPrintType = _printType[_collectionId];
        _printType[_collectionId] = _newPrintType;
        emit CollectionPrintTypeUpdated(
            _collectionId,
            oldPrintType,
            _newPrintType,
            msg.sender
        );
    }

    function setCollectionFulfillerId(
        uint256 _newFulfillerId,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        require(
            _legendFulfillment.getFulfillerAddress(_newFulfillerId) !=
                address(0),
            "LegendFulfillment: FulfillerId does not exist."
        );
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setFulfillerId(tokenIds[i], _newFulfillerId);
            }
        }
        uint256 oldFufillerId = _fulfillerId[_collectionId];
        _fulfillerId[_collectionId] = _newFulfillerId;
        emit CollectionFulfillerIdUpdated(
            _collectionId,
            oldFufillerId,
            _newFulfillerId,
            msg.sender
        );
    }

    function setCollectionURI(string memory _newURI, uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow),
                "LegendCollection: The entire collection must be owned by Escrow to update"
            );
            _legendNFT.setTokenURI(tokenIds[i], _newURI);
        }
        string memory oldURI = _collections[_collectionId].uri;
        _collections[_collectionId].uri = _newURI;
        emit CollectionURIUpdated(_collectionId, oldURI, _newURI, msg.sender);
    }

    function setCollectionDropId(uint256 _dropId, uint256 _collectionId)
        external
    {
        require(
            msg.sender == address(_legendDrop) ||
                msg.sender == _collections[_collectionId].creator,
            "LegendCollection: Only the collection creator or drop contract can update."
        );
        _collections[_collectionId].dropId = _dropId;
        emit CollectionDropIdUpdated(_collectionId, _dropId, msg.sender);
    }

    function setCollectionDiscount(uint256 _newDiscount, uint256 _collectionId)
        external
        onlyCreator(_collectionId)
    {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setDiscount(tokenIds[i], _newDiscount);
            }
        }
        _discount[_collectionId] = _newDiscount;
        emit CollectionDiscountUpdated(_collectionId, _newDiscount, msg.sender);
    }

    function setCollectionGrantCollectorsOnly(
        bool _collectorsOnly,
        uint256 _collectionId
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setGrantCollectorsOnly(tokenIds[i], _collectorsOnly);
            }
        }
        _grantCollectorsOnly[_collectionId] = _collectorsOnly;
        emit CollectionGrantCollectorsOnlyUpdated(
            _collectionId,
            _collectorsOnly,
            msg.sender
        );
    }

    function setCollectionBasePrices(
        uint256 _collectionId,
        uint256[] memory _newPrices
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setBasePrices(tokenIds[i], _newPrices);
            }
        }
        uint256[] memory oldPrices = _collections[_collectionId].basePrices;
        _collections[_collectionId].basePrices = _newPrices;
        emit CollectionBasePricesUpdated(
            _collectionId,
            oldPrices,
            _newPrices,
            msg.sender
        );
    }

    function setCollectionAcceptedTokens(
        uint256 _collectionId,
        address[] memory _newAcceptedTokens
    ) external onlyCreator(_collectionId) {
        uint256[] memory tokenIds = _collections[_collectionId].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_legendNFT.ownerOf(tokenIds[i]) == address(_legendEscrow)) {
                _legendNFT.setTokenAcceptedTokens(
                    tokenIds[i],
                    _newAcceptedTokens
                );
            }
        }
        address[] memory oldTokens = _collections[_collectionId].acceptedTokens;
        _collections[_collectionId].acceptedTokens = _newAcceptedTokens;
        emit CollectionAcceptedTokensUpdated(
            _collectionId,
            oldTokens,
            _newAcceptedTokens,
            msg.sender
        );
    }

    function getCollectionSupply() public view returns (uint256) {
        return _collectionSupply;
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendEscrowContract() public view returns (address) {
        return address(_legendEscrow);
    }

    function getLegendPaymentContract() public view returns (address) {
        return address(_legendPayment);
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendFactoryContract() public view returns (address) {
        return address(_legendFactory);
    }

    function getLegendFulfillmentContract() public view returns (address) {
        return address(_legendFulfillment);
    }

    function getLegendDropContract() public view returns (address) {
        return address(_legendDrop);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./GlobalLegendAccessControl.sol";

contract LegendDrop {
    GlobalLegendAccessControl private _accessControl;
    LegendCollection private _legendCollection;
    uint256 private _dropSupply;
    string public symbol;
    string public name;

    struct Drop {
        uint256 dropId;
        uint256[] collectionIds;
        string dropURI;
        address creator;
        uint256 timestamp;
    }

    mapping(uint256 => Drop) private _drops;
    mapping(uint256 => uint256) private _collectionIdToDrop;

    event DropCreated(
        uint256 indexed dropId,
        uint256[] collectionIds,
        address creator
    );

    event CollectionAddedToDrop(
        uint256 indexed dropId,
        uint256[] collectionIds
    );

    event CollectionRemovedFromDrop(
        uint256 indexed dropId,
        uint256 collectionId
    );

    event DropURIUpdated(uint256 indexed dropId, string dropURI);

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );

    event DropDeleted(uint256 indexed dropId, address deleter);

    modifier onlyCreator(uint256[] memory _collectionIds) {
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(_collectionIds[i]) ==
                    msg.sender,
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
        }
        _;
    }

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        address _legendCollectionAddress,
        address _accessControlAddress,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_legendCollectionAddress);
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _dropSupply = 0;
        symbol = _symbol;
        name = _name;
    }

    function createDrop(uint256[] memory _collectionIds, string memory _dropURI)
        external
    {
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(_collectionIds[i]) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
            require(
                _collectionIds[i] != 0 &&
                    _collectionIds[i] <=
                    _legendCollection.getCollectionSupply(),
                "LegendDrop: Collection does not exist"
            );
            require(
                _collectionIdToDrop[_collectionIds[i]] == 0,
                "LegendDrop: Collection is already part of another existing drop"
            );
        }

        _dropSupply++;

        Drop memory newDrop = Drop({
            dropId: _dropSupply,
            collectionIds: _collectionIds,
            dropURI: _dropURI,
            creator: msg.sender,
            timestamp: block.timestamp
        });

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _collectionIdToDrop[_collectionIds[i]] = _dropSupply;
            _legendCollection.setCollectionDropId(
                _dropSupply,
                _collectionIds[i]
            );
        }

        _drops[_dropSupply] = newDrop;

        emit DropCreated(_dropSupply, _collectionIds, msg.sender);
    }

    function addCollectionToDrop(
        uint256 _dropId,
        uint256[] memory _collectionIds
    ) external onlyCreator(_collectionIds) {
        require(_drops[_dropId].dropId != 0, "LegendDrop: Drop does not exist");
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(
                _collectionIdToDrop[_collectionIds[i]] == 0,
                "LegendDrop: Collection is already part of another existing drop"
            );
        }

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _drops[_dropId].collectionIds.push(_collectionIds[i]);
            _collectionIdToDrop[_collectionIds[i]] = _dropId;
            _legendCollection.setCollectionDropId(_dropId, _collectionIds[i]);
        }

        emit CollectionAddedToDrop(_dropId, _collectionIds);
    }

    function removeCollectionFromDrop(uint256 _collectionId) external {
        require(
            _drops[_collectionIdToDrop[_collectionId]].dropId != 0,
            "LegendDrop: Collection is not part of a drop"
        );
        require(
            _legendCollection.getCollectionCreator(_collectionId) ==
                msg.sender ||
                address(_legendCollection) == msg.sender,
            "LegendDrop: Only creator or collection contract can remove collection"
        );

        uint256[] storage collectionIds = _drops[
            _collectionIdToDrop[_collectionId]
        ].collectionIds;
        uint256 collectionIndex = findIndex(collectionIds, _collectionId);
        require(
            collectionIndex < collectionIds.length,
            "LegendDrop: Collection not found"
        );

        collectionIds[collectionIndex] = collectionIds[
            collectionIds.length - 1
        ];
        collectionIds.pop();

        emit CollectionRemovedFromDrop(
            _collectionIdToDrop[_collectionId],
            _collectionId
        );
    }

    function findIndex(uint256[] storage array, uint256 value)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }
        return array.length;
    }

    function deleteDrop(uint256 _dropId) external {
        require(_drops[_dropId].dropId != 0, "LegendDrop: Drop does not exist");
        for (uint256 i = 0; i < _drops[_dropId].collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(
                    _drops[_dropId].collectionIds[i]
                ) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a collection can add it to a drop"
            );
        }

        uint256[] memory collectionIds = _drops[_dropId].collectionIds;
        for (uint256 i = 0; i < collectionIds.length; i++) {
            _collectionIdToDrop[collectionIds[i]] = 0;
        }
        delete _drops[_dropId];

        emit DropDeleted(_dropId, msg.sender);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollectionAddress,
            msg.sender
        );
    }

    function getCollectionsInDrop(uint256 _dropId)
        public
        view
        returns (uint256[] memory)
    {
        return _drops[_dropId].collectionIds;
    }

    function getCollectionIdToDrop(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _collectionIdToDrop[_collectionId];
    }

    function getDropURI(uint256 _dropId) public view returns (string memory) {
        return _drops[_dropId].dropURI;
    }

    function getDropCreator(uint256 _dropId) public view returns (address) {
        return _drops[_dropId].creator;
    }

    function getDropTimestamp(uint256 _dropId) public view returns (uint256) {
        return _drops[_dropId].timestamp;
    }

    function setDropURI(uint256 _dropId, string memory _dropURI) external {
        for (uint256 i = 0; i < _drops[_dropId].collectionIds.length; i++) {
            require(
                _legendCollection.getCollectionCreator(
                    _drops[_dropId].collectionIds[i]
                ) ==
                    msg.sender &&
                    (_accessControl.isWriter(msg.sender) ||
                        _accessControl.isAdmin(msg.sender)),
                "LegendDrop: Only the owner of a drop can edit a drop"
            );
        }
        _drops[_dropId].dropURI = _dropURI;
        emit DropURIUpdated(_dropId, _dropURI);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getDropSupply() public view returns (uint256) {
        return _dropSupply;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendFactory.sol";
import "./GlobalLegendAccessControl.sol";

library DynamicNFTLibrary {
    struct ConstructorArgs {
        string[] URIArrayValue;
        string grantNameValue;
        uint256 editionAmountValue;
    }
}

contract LegendDynamicNFT is ERC721 {
    using Counters for Counters.Counter;
    uint256 private _editionAmount;
    uint256 private _currentCounter;
    uint256 private _maxSupply;
    string[] private _URIArray;
    string private _myBaseURI;
    string private _grantName;
    address private _deployerAddress;

    mapping(address => bool) private _collectorClaimedNFT;
    mapping(address => uint256) private _collectorMapping;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(address => bool)) private _collectorToPubId;

    Counters.Counter private _tokenIdCounter;
    ICollectNFT private _collectNFT;
    ILensHubProxy private _lensHubProxy;
    LegendKeeper private _legendKeeper;
    LegendAccessControl private _legendAccessControl;
    LegendFactory private _legendFactory;

    event TokenURIUpdated(
        uint256 indexed collectAmount,
        string newURI,
        address updater
    );
    event DynamicNFTMinted(address collector, uint256 tokenId);

    modifier onlyFactory() {
        require(
            msg.sender == address(_legendFactory),
            "LegendDynamicNFT: Only the factory can set the keeper address"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            _legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == address(_legendKeeper),
            "LegendDynamicNFT: Only the Keeper Contract can perform this action"
        );
        _;
    }

    modifier onlyCollector() {
        require(
            _collectNFT.balanceOf(msg.sender) > 0,
            "LegendDynamicNFT: Only Publication Collectors can perform this action"
        );
        _;
    }

    constructor(
        DynamicNFTLibrary.ConstructorArgs memory args,
        address _legendAccessControlValue,
        address _legendFactoryValue,
        address _deployerAddressValue,
        address _lensHubProxyAddressValue
    ) ERC721("LegendDynamicNFT", "LDNFT") {
        _editionAmount = args.editionAmountValue;
        _URIArray = args.URIArrayValue;
        _currentCounter = 0;
        _deployerAddress = _deployerAddressValue;
        _legendAccessControl = LegendAccessControl(_legendAccessControlValue);
        _legendFactory = LegendFactory(_legendFactoryValue);
        _lensHubProxy = ILensHubProxy(_lensHubProxyAddressValue);
        _myBaseURI = _URIArray[0];
        _grantName = args.grantNameValue;
        _maxSupply = _editionAmount;
    }

    function safeMint(address _to) external onlyCollector {
        require(
            !_collectorClaimedNFT[msg.sender],
            "LegendDynamicNFT: Only 1 NFT can be claimed per unique collector."
        );

        require(
            _tokenIdCounter.current() < _maxSupply,
            "LegendDynamicNFT: Cannot mint above the max supply."
        );

        _tokenIdCounter.increment();
        uint256 _tokenId = _tokenIdCounter.current();

        _safeMint(_to, _tokenId);

        _collectorClaimedNFT[msg.sender] = true;
        _collectorToPubId[_legendKeeper.getPostId()][msg.sender] = true;
        _collectorMapping[msg.sender] = _lensHubProxy.defaultProfile(
            _deployerAddress
        );

        emit DynamicNFTMinted(msg.sender, _tokenIdCounter.current());
    }

    function updateMetadata(uint256 _totalAmountOfCollects)
        external
        onlyKeeper
    {
        if (_totalAmountOfCollects > _editionAmount) return;

        if (_totalAmountOfCollects == _editionAmount) {
            _legendFactory.setGrantStatus(
                _deployerAddress,
                "ended",
                _grantName
            );
        }

        _currentCounter += _totalAmountOfCollects;

        // update new uri for all tokenids
        _myBaseURI = _URIArray[_currentCounter];

        emit TokenURIUpdated(
            _totalAmountOfCollects,
            _URIArray[_currentCounter],
            msg.sender
        );
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _myBaseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _myBaseURI;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function setLegendKeeperAddress(address _legendKeeperAddress)
        external
        onlyFactory
    {
        _legendKeeper = LegendKeeper(_legendKeeperAddress);
    }

    function setCollectNFTAddress(address _collectNFTAddress)
        external
        onlyKeeper
    {
        require(address(_collectNFT) == address(0));
        _collectNFT = ICollectNFT(_collectNFTAddress);
    }

    function getEditionAmount() public view returns (uint256) {
        return _editionAmount;
    }

    function getCurrentCounter() public view returns (uint256) {
        return _currentCounter;
    }

    function getCollectorClaimedNFT(address _collectorAddress)
        public
        view
        returns (bool)
    {
        return _collectorClaimedNFT[_collectorAddress];
    }

    function getCollectorMapping(address _collectorAddress)
        public
        view
        returns (uint256)
    {
        return _collectorMapping[_collectorAddress];
    }

    function getCollectorPubId(address _address) public view returns (bool) {
        return _collectorToPubId[_legendKeeper.getPostId()][_address];
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function getGrantName() public view returns (string memory) {
        return _grantName;
    }

    function getDeployerAddress() public view returns (address) {
        return _deployerAddress;
    }

    function getLegendKeeperAddress() public view returns (address) {
        return address(_legendKeeper);
    }

    function getLegendAccessControlAddress() public view returns (address) {
        return address(_legendAccessControl);
    }

    function getCollectNFTAddress() public view returns (address) {
        return address(_collectNFT);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./LegendCollection.sol";
import "./LegendMarket.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendNFT.sol";

contract LegendEscrow is ERC721Holder {
    GlobalLegendAccessControl private _accessControl;
    LegendCollection private _legendCollection;
    LegendMarket private _legendMarketplace;
    LegendNFT private _legendNFT;
    string public symbol;
    string public name;

    mapping(uint256 => bool) private _deposited;

    event LegendMarketplaceUpdated(
        address indexed oldLegendMarketplace,
        address indexed newLegendMarketplace,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );

    constructor(
        address _legendCollectionContract,
        address _legendMarketplaceContract,
        address _accessControlContract,
        address _legendNFTContract,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_legendCollectionContract);
        _legendMarketplace = LegendMarket(_legendMarketplaceContract);
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendNFT = LegendNFT(_legendNFTContract);
        symbol = _symbol;
        name = _name;
    }

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDepositer() {
        require(
            msg.sender == address(_legendCollection) ||
                msg.sender == address(_legendNFT),
            "LegendEscrow: Only the Legend Collection or NFT contract can call this function"
        );
        _;
    }

    modifier onlyReleaser(bool _isBurn, uint256 _tokenId) {
        require(
            msg.sender == address(_legendMarketplace) ||
                msg.sender == address(_legendCollection) ||
                msg.sender == address(_legendNFT),
            "LegendEscrow: Only the Legend Marketplace contract can call this function"
        );
        if (_isBurn) {
            require(
                _legendNFT.getTokenCreator(_tokenId) == msg.sender ||
                    address(_legendCollection) == msg.sender,
                "LegendEscrow: Only the creator of the token can transfer it to the burn address"
            );
        }
        _;
    }

    function deposit(uint256 _tokenId, bool _bool) external onlyDepositer {
        require(
            _legendNFT.ownerOf(_tokenId) == address(this),
            "LegendEscrow: Token must be owned by escrow contract or Owner"
        );
        _deposited[_tokenId] = _bool;
    }

    function release(
        uint256 _tokenId,
        bool _isBurn,
        address _to
    ) external onlyReleaser(_isBurn, _tokenId) {
        require(_deposited[_tokenId], "LegendEscrow: Token must be in escrow");
        _deposited[_tokenId] = false;
        if (_isBurn) {
            _legendNFT.burn(_tokenId);
        } else {
            _legendNFT.safeTransferFrom(address(this), _to, _tokenId);
        }
    }

    function updateLegendMarketplace(address _newLegendMarketplace)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendMarketplace);
        _legendMarketplace = LegendMarket(_newLegendMarketplace);
        emit LegendMarketplaceUpdated(
            oldAddress,
            _newLegendMarketplace,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollection)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollection);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollection,
            msg.sender
        );
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendMarketContract() public view returns (address) {
        return address(_legendMarketplace);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";
import "./LegendDynamicNFT.sol";
import "./GlobalLegendAccessControl.sol";

contract LegendFactory {
    GlobalLegendAccessControl private _accessControl;
    ILensHubProxy private _lensHubProxyAddressValue;
    string public name;
    string public symbol;

    struct Grant {
        address[3] contracts;
        string name;
        uint256 timestamp;
        string status;
    }

    event AccessControlSet(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event FactoryDeployed(
        address keeperAddress,
        address accessControlAddress,
        address dynamicNFTAddress,
        string name,
        address indexed deployer,
        uint256 timestamp,
        uint256 pubId,
        uint256 profileId
    );

    event GrantStatusUpdated(
        string grantName,
        address deployerAddress,
        string status
    );

    mapping(address => mapping(string => Grant)) private _deployerToGrant;
    mapping(address => address[]) private _deployedLegendKeepers;
    mapping(address => address[]) private _deployedLegendAccessControls;
    mapping(address => address[]) private _deployedLegendDynamicNFTs;
    mapping(address => uint256[]) private _deployerTimestamps;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyDynamicNFT(
        address _deployerAddress,
        string memory _grantName,
        address _dynamicNFTAddress
    ) {
        require(
            _deployerToGrant[_deployerAddress][_grantName].contracts[2] ==
                _dynamicNFTAddress,
            "LegendFactory: Only the Dynamic NFT Address can update the grant status"
        );

        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _accessControlsAddress
    ) {
        name = _name;
        symbol = _symbol;
        _accessControl = GlobalLegendAccessControl(_accessControlsAddress);
    }

    function createContracts(
        uint256 _pubId,
        uint256 _profileId,
        DynamicNFTLibrary.ConstructorArgs memory args
    ) public {
        address _grantDeployer = msg.sender;

        require(
            bytes(_deployerToGrant[_grantDeployer][args.grantNameValue].name)
                .length == 0,
            "LegendFactory: Grant Name must be unique."
        );
        require(
            args.editionAmountValue == args.URIArrayValue.length,
            "LegendFactory: The URI values must match the edition amount."
        );

        // Deploy LegendAccessControl
        LegendAccessControl newLegendAccessControl = new LegendAccessControl(
            "LegendAccessControl",
            "LAC",
            _grantDeployer
        );

        // Deploy LegendDynamicNFT
        LegendDynamicNFT newLegendDynamicNFT = new LegendDynamicNFT(
            args,
            address(newLegendAccessControl),
            address(this),
            _grantDeployer,
            address(_lensHubProxyAddressValue)
        );

        // Deploy LegendKeeper
        LegendKeeper newLegendKeeper = new LegendKeeper(
            args.editionAmountValue,
            _pubId,
            _profileId,
            address(_lensHubProxyAddressValue),
            address(newLegendDynamicNFT),
            address(newLegendAccessControl),
            _grantDeployer,
            "LegendKeeper",
            "LKEEP"
        );

        newLegendDynamicNFT.setLegendKeeperAddress(address(newLegendKeeper));

        _accessControl.addWriter(_grantDeployer);

        Grant memory grantDetails = Grant(
            [
                address(newLegendKeeper),
                address(newLegendAccessControl),
                address(newLegendDynamicNFT)
            ],
            args.grantNameValue,
            block.timestamp,
            "live"
        );

        _deployerToGrant[_grantDeployer][args.grantNameValue] = grantDetails;

        _deployedLegendKeepers[_grantDeployer].push(address(newLegendKeeper));
        _deployedLegendDynamicNFTs[_grantDeployer].push(
            address(newLegendDynamicNFT)
        );
        _deployedLegendAccessControls[_grantDeployer].push(
            address(newLegendAccessControl)
        );

        emit FactoryDeployed(
            address(newLegendKeeper),
            address(newLegendAccessControl),
            address(newLegendDynamicNFT),
            args.grantNameValue,
            msg.sender,
            block.timestamp,
            _pubId,
            _profileId
        );
    }

    function getDeployedLegendKeepers(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendKeepers[_deployerAddress];
    }

    function getDeployedLegendAccessControls(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendAccessControls[_deployerAddress];
    }

    function getDeployedLegendDynamicNFTs(address _deployerAddress)
        public
        view
        returns (address[] memory)
    {
        return _deployedLegendDynamicNFTs[_deployerAddress];
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function setAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlSet(oldAddress, _newAccessControlAddress, msg.sender);
    }

    function getGrantName(address _deployerAddress, string memory _grantName)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress][_grantName].name;
    }

    function getGrantContracts(
        address _deployerAddress,
        string memory _grantName
    ) public view returns (address[3] memory) {
        return _deployerToGrant[_deployerAddress][_grantName].contracts;
    }

    function getGrantTimestamp(
        address _deployerAddress,
        string memory _grantName
    ) public view returns (uint256) {
        return _deployerToGrant[_deployerAddress][_grantName].timestamp;
    }

    function getGrantStatus(address _deployerAddress, string memory _grantName)
        public
        view
        returns (string memory)
    {
        return _deployerToGrant[_deployerAddress][_grantName].status;
    }

    function setGrantStatus(
        address _deployerAddress,
        string memory _newStatus,
        string memory _grantName
    ) external onlyDynamicNFT(_deployerAddress, _grantName, msg.sender) {
        _deployerToGrant[_deployerAddress][_grantName].status = _newStatus;
        emit GrantStatusUpdated(_grantName, _deployerAddress, _newStatus);
    }

    function setLensHubProxy(address _newAddress) external onlyAdmin {
        _lensHubProxyAddressValue = ILensHubProxy(_newAddress);
    }

    function getLensHubProxy() public view returns (address) {
        return address(_lensHubProxyAddressValue);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./GlobalLegendAccessControl.sol";
import "./LegendNFT.sol";
import "./LegendCollection.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LegendFulfillment {
    LegendNFT private _legendNFT;
    GlobalLegendAccessControl private _accessControl;
    LegendCollection private _legendCollection;
    uint256 private _fullfillerCount;
    string public symbol;
    string public name;

    struct Fulfiller {
        uint256 fulfillerId;
        uint256 fulfillerPercent;
        address fulfillerAddress;
    }

    mapping(uint256 => Fulfiller) private _fulfillers;

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );

    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );

    event OrderCreated(
        uint256 indexed orderId,
        address buyer,
        string fulfillmentInformation
    );

    event FulfillerAddressUpdated(
        uint256 indexed fulfillerId,
        address newFulfillerAddress
    );

    event FulfillerCreated(
        uint256 indexed fulfillerId,
        uint256 fulfillerPercent,
        address fulfillerAddress
    );

    event FulfillerPercentUpdated(
        uint256 indexed fulfillerId,
        uint256 newFulfillerPercent
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyFulfiller(uint256 _fulfillerId) {
        require(
            msg.sender == _fulfillers[_fulfillerId].fulfillerAddress,
            "LegendFulfillment: Only the fulfiller can update."
        );
        _;
    }

    constructor(
        address _accessControlContract,
        address _NFTContract,
        address _collectionContract,
        string memory _symbol,
        string memory _name
    ) {
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendNFT = LegendNFT(_NFTContract);
        _legendCollection = LegendCollection(_collectionContract);
        symbol = _symbol;
        name = _name;
        _fullfillerCount = 0;
    }

    function createFulfiller(
        uint256 _fulfillerPercent,
        address _fulfillerAddress
    ) external onlyAdmin {
        require(
            _fulfillerPercent < 100,
            "LegendFulfillment: Percent can not be greater than 100."
        );
        _fullfillerCount++;

        Fulfiller memory newFulfiller = Fulfiller({
            fulfillerId: _fullfillerCount,
            fulfillerPercent: _fulfillerPercent,
            fulfillerAddress: _fulfillerAddress
        });

        _fulfillers[_fullfillerCount] = newFulfiller;

        emit FulfillerCreated(
            _fullfillerCount,
            _fulfillerPercent,
            _fulfillerAddress
        );
    }

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollectionAddress,
            msg.sender
        );
    }

    function updateFulfillerPercent(
        uint256 _fulfillerId,
        uint256 _fulfillerPercent
    ) public onlyFulfiller(_fulfillerId) {
        require(
            _fulfillerId <= _fullfillerCount,
            "LegendFulfillment: Fulfiller does not exist."
        );
        _fulfillers[_fulfillerId].fulfillerPercent = _fulfillerPercent;
        emit FulfillerPercentUpdated(_fulfillerId, _fulfillerPercent);
    }

    function getFulfillerPercent(uint256 _fulfillerId)
        public
        view
        returns (uint256)
    {
        return _fulfillers[_fulfillerId].fulfillerPercent;
    }

    function updateFulfillerAddress(
        uint256 _fulfillerId,
        address _fulfillerAddress
    ) public onlyFulfiller(_fulfillerId) {
        require(
            _fulfillerId <= _fullfillerCount,
            "LegendFulfillment: Fulfiller does not exist."
        );
        _fulfillers[_fulfillerId].fulfillerAddress = _fulfillerAddress;
        emit FulfillerAddressUpdated(_fulfillerId, _fulfillerAddress);
    }

    function getFulfillerAddress(uint256 _fulfillerId)
        public
        view
        returns (address)
    {
        return _fulfillers[_fulfillerId].fulfillerAddress;
    }

    function getFulfillerCount() public view returns (uint256) {
        return _fullfillerCount;
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./LegendDynamicNFT.sol";
import "./LegendAccessControl.sol";

interface ILensHubProxy {
    function defaultProfile(address wallet) external view returns (uint256);

    function getCollectNFT(uint256 profileId, uint256 pubId)
        external
        view
        returns (address);
}

interface ICollectNFT {
    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract LegendKeeper is AutomationCompatibleInterface {
    string public symbol;
    string public name;
    uint256 private _pubId;
    uint256 private _profileId;
    uint256 private _editionAmount;
    uint256 private _keeperId;
    uint256 private _totalAmountOfCollects;
    uint256 private _currentCollects;
    address private _deployerAddress;

    ICollectNFT private _collectNFT;
    ILensHubProxy private _lensHubProxy;
    LegendDynamicNFT private _legendDynamicNFT;
    LegendAccessControl private _legendAccessControl;

    modifier onlyAdmin() {
        require(
            _legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    constructor(
        uint256 _editionAmountValue,
        uint256 _pubIdValue,
        uint256 _profileIdValue,
        address _lensHubProxyAddress,
        address _legendDynamicNFTAddress,
        address _accessControlAddress,
        address _deployerAddressValue,
        string memory _name,
        string memory _symbol
    ) {
        _editionAmount = _editionAmountValue;
        _totalAmountOfCollects = 0;
        _currentCollects = 0;
        _deployerAddress = _deployerAddressValue;

        _lensHubProxy = ILensHubProxy(_lensHubProxyAddress);
        _legendDynamicNFT = LegendDynamicNFT(_legendDynamicNFTAddress);
        _legendAccessControl = LegendAccessControl(_accessControlAddress);

        symbol = _symbol;
        name = _name;
        _pubId = _pubIdValue;
        _profileId = _profileIdValue;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        _returnValues();

        upkeepNeeded = _currentCollects > _totalAmountOfCollects;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if (_currentCollects > _totalAmountOfCollects) {
            _totalAmountOfCollects = _currentCollects;
            _legendDynamicNFT.updateMetadata(_totalAmountOfCollects);
        }
    }

    function _returnValues() private {
        if (address(_collectNFT) == address(0)) {
            address collectNFTAddress = _lensHubProxy.getCollectNFT(
                _profileId,
                _pubId
            );

            // if the collectNFT address has not been set and the there has been collected editions of the post, set the collectNFT  address and update the current collect amount
            if (collectNFTAddress != address(0)) {
                _setCollectNFTAddress(collectNFTAddress);

                _currentCollects = _collectNFT.totalSupply();
            }
        }
    }

    function _setCollectNFTAddress(address _collectNFTAddress) private {
        require(address(_collectNFT) == address(0));
        _collectNFT = ICollectNFT(_collectNFTAddress);
    }

    function setKeeperId(uint256 _keeperIdValue) public onlyAdmin {
        require(_keeperId == 0, "LegendKeeper: KeeperId already set.");
        _keeperId = _keeperIdValue;
    }

    function getCollectionNFTAddress() private view returns (address) {
        return address(_collectNFT);
    }

    function getProfileId() public view returns (uint256) {
        return _profileId;
    }

    function getPostId() public view returns (uint256) {
        return _pubId;
    }

    function getKeeperId() public view returns (uint256) {
        return _keeperId;
    }

    function getEditionAmount() public view returns (uint256) {
        return _editionAmount;
    }

    function getDeployerAddress() public view returns (address) {
        return _deployerAddress;
    }

    function getTotalAmountOfCollects() public view returns (uint256) {
        return _totalAmountOfCollects;
    }

    function getCurrentCollects() public view returns (uint256) {
        return _currentCollects;
    }

    function getDynamicNFTAddress() public view returns (address) {
        return address(_legendDynamicNFT);
    }

    function getAccessControlAddress() public view returns (address) {
        return address(_legendAccessControl);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./GlobalLegendAccessControl.sol";
import "./LegendCollection.sol";
import "./LegendEscrow.sol";
import "./LegendNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LegendFulfillment.sol";

contract LegendMarket {
    LegendCollection private _legendCollection;
    LegendEscrow private _legendEscrow;
    LegendNFT private _legendNFT;
    GlobalLegendAccessControl private _accessControl;
    LegendFulfillment private _legendFulfillment;
    uint256 private _orderSupply;
    string public symbol;
    string public name;

    struct Order {
        uint256 orderId;
        uint256 tokenId;
        string details;
        address buyer;
        address chosenAddress;
        uint256 timestamp;
        string status;
        bool isFulfilled;
        uint256 fulfillerId;
    }

    mapping(uint256 => uint256) private _tokensSold;
    mapping(uint256 => uint256[]) private _tokenIdsSold;
    mapping(uint256 => Order) private _orders;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyFulfiller(uint256 _fulfillerId) {
        require(
            _legendFulfillment.getFulfillerAddress(_fulfillerId) == msg.sender,
            "LegendMarket: Only the fulfiller can update this status."
        );
        _;
    }

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event LegendNFTUpdated(
        address indexed oldLegendNFT,
        address indexed newLegendNFT,
        address updater
    );
    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );
    event LegendFulfillmentUpdated(
        address indexed oldLegendFulfillment,
        address indexed newLegendFulfillment,
        address updater
    );
    event TokensBought(
        uint256[] tokenIds,
        address buyer,
        address[] chosenAddress
    );
    event OrderIsFulfilled(uint256 indexed _orderId, address _fulfillerAddress);

    event OrderCreated(
        uint256 indexed orderId,
        uint256 totalPrice,
        address buyer,
        string fulfillmentInformation,
        uint256 fulfillerId
    );
    event UpdateOrderDetails(
        uint256 indexed _orderId,
        string newOrderDetails,
        address buyer
    );
    event UpdateOrderStatus(
        uint256 indexed _orderId,
        string newOrderStatus,
        address buyer
    );

    event FulfillerAddressUpdated(
        uint256 indexed fulfillerId,
        address newFulfillerAddress
    );

    event FulfillerPercentUpdated(
        uint256 indexed fulfillerId,
        uint256 newFulfillerPercent
    );

    constructor(
        address _collectionContract,
        address _accessControlContract,
        address _fulfillmentContract,
        address _NFTContract,
        string memory _symbol,
        string memory _name
    ) {
        _legendCollection = LegendCollection(_collectionContract);
        _accessControl = GlobalLegendAccessControl(_accessControlContract);
        _legendNFT = LegendNFT(_NFTContract);
        _legendFulfillment = LegendFulfillment(_fulfillmentContract);
        symbol = _symbol;
        name = _name;
        _orderSupply = 0;
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        address[] memory _chosenTokenAddresses,
        string memory _fulfillmentDetails
    ) external {
        require(
            _chosenTokenAddresses.length == _tokenIds.length,
            "LegendMarket: Must provide a token address for each tokenId"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_legendNFT.getTokenGrantCollectorsOnly(_tokenIds[i])) {
                require(
                    IDynamicNFT(
                        _legendNFT.getTokenDynamicNFTAddress(_tokenIds[i])
                    ).getCollectorClaimedNFT(msg.sender),
                    "LegendMarket: Must be authorized grant collector."
                );
                require(
                    _legendNFT.ownerOf(_tokenIds[i]) == address(_legendEscrow),
                    "LegendMarket: Token must be owned by Escrow"
                );
            }

            bool isAccepted = false;
            address[] memory acceptedTokens = _legendNFT.getTokenAcceptedTokens(
                _tokenIds[i]
            );
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddresses[i]) {
                    isAccepted = true;
                    break;
                }
            }
            require(
                isAccepted,
                "LegendMarket: Chosen token address is not an accepted token for the collection"
            );
        }

        uint256[] memory prices = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address[] memory acceptedTokens = _legendNFT.getTokenAcceptedTokens(
                _tokenIds[i]
            );
            for (uint256 j = 0; j < acceptedTokens.length; j++) {
                if (acceptedTokens[j] == _chosenTokenAddresses[i]) {
                    prices[i] = _legendNFT.getTokenBasePrices(_tokenIds[i])[j];

                    if (
                        _legendNFT.getTokenDiscount(_tokenIds[i]) != 0 &&
                        IDynamicNFT(
                            _legendNFT.getTokenDynamicNFTAddress(_tokenIds[i])
                        ).getCollectorClaimedNFT(msg.sender)
                    ) {
                        prices[i] =
                            prices[i] -
                            ((prices[i] *
                                _legendNFT.getTokenDiscount(_tokenIds[i])) /
                                100);
                    }

                    break;
                }
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 allowance = IERC20(_chosenTokenAddresses[i]).allowance(
                msg.sender,
                address(this)
            );

            require(
                allowance >= prices[i],
                "LegendMarket: Insufficient Approval Allowance"
            );

            uint256 _fulfillerId = _legendNFT.getTokenFulfillerId(_tokenIds[i]);
            IERC20(_chosenTokenAddresses[i]).transferFrom(
                msg.sender,
                _legendNFT.getTokenCreator(_tokenIds[i]),
                prices[i] -
                    ((prices[i] *
                        (
                            _legendFulfillment.getFulfillerPercent(_fulfillerId)
                        )) / 100)
            );
            IERC20(_chosenTokenAddresses[i]).transferFrom(
                msg.sender,
                _legendFulfillment.getFulfillerAddress(_fulfillerId),
                ((prices[i] *
                    (_legendFulfillment.getFulfillerPercent(_fulfillerId))) /
                    100)
            );
            _legendEscrow.release(_tokenIds[i], false, msg.sender);

            _orderSupply++;

            Order memory newOrder = Order({
                orderId: _orderSupply,
                tokenId: _tokenIds[i],
                details: _fulfillmentDetails,
                buyer: msg.sender,
                chosenAddress: _chosenTokenAddresses[i],
                timestamp: block.timestamp,
                status: "ordered",
                isFulfilled: false,
                fulfillerId: _fulfillerId
            });

            _orders[_orderSupply] = newOrder;

            emit OrderCreated(
                _orderSupply,
                prices[i],
                msg.sender,
                _fulfillmentDetails,
                _fulfillerId
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tokensSold[_legendNFT.getTokenCollection(_tokenIds[i])] += 1;
            _tokenIdsSold[_legendNFT.getTokenCollection(_tokenIds[i])].push(
                _tokenIds[i]
            );
        }

        emit TokensBought(_tokenIds, msg.sender, _chosenTokenAddresses);
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateLegendCollection(address _newLegendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_newLegendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _newLegendCollectionAddress,
            msg.sender
        );
    }

    function updateLegendNFT(address _newLegendNFTAddress) external onlyAdmin {
        address oldAddress = address(_legendNFT);
        _legendNFT = LegendNFT(_newLegendNFTAddress);
        emit LegendNFTUpdated(oldAddress, _newLegendNFTAddress, msg.sender);
    }

    function updateLegendFulfillment(address _newLegendFulfillmentAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendFulfillment);
        _legendFulfillment = LegendFulfillment(_newLegendFulfillmentAddress);
        emit LegendFulfillmentUpdated(
            oldAddress,
            _newLegendFulfillmentAddress,
            msg.sender
        );
    }

    function setLegendEscrow(address _newLegendEscrowAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_newLegendEscrowAddress);
        emit LegendEscrowUpdated(
            oldAddress,
            _newLegendEscrowAddress,
            msg.sender
        );
    }

    function getCollectionSoldCount(uint256 _collectionId)
        public
        view
        returns (uint256)
    {
        return _tokensSold[_collectionId];
    }

    function getTokensSoldCollection(uint256 _collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return _tokenIdsSold[_collectionId];
    }

    function getOrderTokenId(uint256 _orderId) public view returns (uint256) {
        return _orders[_orderId].tokenId;
    }

    function getOrderDetails(uint256 _orderId)
        public
        view
        returns (string memory)
    {
        return _orders[_orderId].details;
    }

    function getOrderBuyer(uint256 _orderId) public view returns (address) {
        return _orders[_orderId].buyer;
    }

    function getOrderChosenAddress(uint256 _orderId)
        public
        view
        returns (address)
    {
        return _orders[_orderId].chosenAddress;
    }

    function getOrderTimestamp(uint256 _orderId) public view returns (uint256) {
        return _orders[_orderId].timestamp;
    }

    function getOrderStatus(uint256 _orderId)
        public
        view
        returns (string memory)
    {
        return _orders[_orderId].status;
    }

    function getOrderIsFulfilled(uint256 _orderId) public view returns (bool) {
        return _orders[_orderId].isFulfilled;
    }

    function getOrderFulfillerId(uint256 _orderId)
        public
        view
        returns (uint256)
    {
        return _orders[_orderId].fulfillerId;
    }

    function getOrderSupply() public view returns (uint256) {
        return _orderSupply;
    }

    function setOrderisFulfilled(uint256 _orderId)
        external
        onlyFulfiller(_orders[_orderId].fulfillerId)
    {
        _orders[_orderId].isFulfilled = true;
        emit OrderIsFulfilled(_orderId, msg.sender);
    }

    function setOrderStatus(uint256 _orderId, string memory _status)
        external
        onlyFulfiller(_orders[_orderId].fulfillerId)
    {
        _orders[_orderId].status = _status;
        emit UpdateOrderStatus(_orderId, _status, msg.sender);
    }

    function setOrderDetails(uint256 _orderId, string memory _newDetails)
        external
    {
        require(
            _orders[_orderId].buyer == msg.sender,
            "LegendMarket: Only the buyer can update their order details."
        );
        _orders[_orderId].details = _newDetails;
        emit UpdateOrderDetails(_orderId, _newDetails, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendEscrowContract() public view returns (address) {
        return address(_legendEscrow);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }

    function getLegendNFTContract() public view returns (address) {
        return address(_legendNFT);
    }

    function getLegendFulfillmentContract() public view returns (address) {
        return address(_legendFulfillment);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./LegendCollection.sol";
import "./GlobalLegendAccessControl.sol";
import "./LegendEscrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LegendNFT is ERC721Enumerable {
    using MintParamsLibrary for MintParamsLibrary.MintParams;

    GlobalLegendAccessControl private _accessControl;
    LegendEscrow private _legendEscrow;
    LegendCollection private _legendCollection;
    uint256 private _totalSupplyCount;

    struct Token {
        uint256 tokenId;
        uint256 collectionId;
        address[] acceptedTokens;
        uint256[] basePrices;
        address creator;
        string uri;
        bool isBurned;
        uint256 timestamp;
    }

    mapping(uint256 => Token) private _tokens;
    mapping(uint256 => uint256) private _fulfillerId;
    mapping(uint256 => string) private _printType;
    mapping(uint256 => uint256) private _discount;
    mapping(uint256 => bool) private _grantCollectorsOnly;
    mapping(uint256 => uint256) private _pubId;
    mapping(uint256 => address) private _dynamicNFTAddress;

    event BatchTokenMinted(address indexed to, uint256[] tokenIds, string uri);
    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );
    event LegendCollectionUpdated(
        address indexed oldLegendCollection,
        address indexed newLegendCollection,
        address updater
    );
    event LegendEscrowUpdated(
        address indexed oldLegendEscrow,
        address indexed newLegendEscrow,
        address updater
    );
    event TokenBurned(uint256 indexed tokenId);
    event TokenBasePriceUpdated(
        uint256 indexed tokenId,
        uint256[] oldPrice,
        uint256[] newPrice,
        address updater
    );
    event TokenAcceptedTokensUpdated(
        uint256 indexed tokenId,
        address[] oldAcceptedTokens,
        address[] newAcceptedTokens,
        address updater
    );
    event TokenURIUpdated(
        uint256 indexed tokenId,
        string oldURI,
        string newURI,
        address updater
    );
    event TokenFulfillerIdUpdated(
        uint256 indexed tokenId,
        uint256 oldFulfillerId,
        uint256 newFulfillerId,
        address updater
    );
    event TokenPrintTypeUpdated(
        uint256 indexed tokenId,
        string oldPrintType,
        string newPrintType,
        address updater
    );
    event TokenGrantCollectorsOnlyUpdated(
        uint256 indexed tokenId,
        bool collectorsOnly,
        address updater
    );
    event TokenDiscountUpdated(
        uint256 indexed tokenId,
        uint256 discount,
        address updater
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "GlobalLegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyCollectionContract() {
        require(
            msg.sender == address(_legendCollection),
            "LegendNFT: Only collection contract can mint tokens"
        );
        _;
    }

    modifier tokensInEscrow(uint256 _tokenId) {
        require(
            ownerOf(_tokenId) == address(_legendEscrow),
            "LegendNFT: Tokens can only be edited when whole collection is in Escrow"
        );
        _;
    }

    constructor(address _accessControlAddress) ERC721("LegendNFT", "CHRON") {
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
        _totalSupplyCount = 0;
    }

    function mintBatch(
        MintParamsLibrary.MintParams memory params,
        uint256 _amount,
        uint256 _pubIdValue,
        uint256 _collectionId,
        address _dynamicNFTAddressValue,
        address _creatorAddress
    ) public onlyCollectionContract {
        require(
            params.discount < 100,
            "LegendMarket: Discount cannot exceed 100."
        );
        uint256[] memory tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            _totalSupplyCount += 1;
            _mintToken(params, _collectionId, _creatorAddress);
            _setMappings(params, _pubIdValue, _dynamicNFTAddressValue);

            tokenIds[i] = _totalSupplyCount;
            _safeMint(address(_legendEscrow), _totalSupplyCount);
            _legendEscrow.deposit(_totalSupplyCount, true);
        }

        emit BatchTokenMinted(address(_legendEscrow), tokenIds, params.uri);
    }

    function _setMappings(
        MintParamsLibrary.MintParams memory params,
        uint256 _pubIdValue,
        address _dynamicNFTAddressValue
    ) private {
        _fulfillerId[_totalSupplyCount] = params.fulfillerId;
        _printType[_totalSupplyCount] = params.printType;
        _discount[_totalSupplyCount] = params.discount;
        _grantCollectorsOnly[_totalSupplyCount] = params.grantCollectorsOnly;
        _pubId[_totalSupplyCount] = _pubIdValue;
        _dynamicNFTAddress[_totalSupplyCount] = _dynamicNFTAddressValue;
    }

    function _mintToken(
        MintParamsLibrary.MintParams memory params,
        uint256 _collectionId,
        address _creatorAddress
    ) private {
        Token memory newToken = Token({
            tokenId: _totalSupplyCount,
            collectionId: _collectionId,
            acceptedTokens: params.acceptedTokens,
            basePrices: params.basePrices,
            creator: _creatorAddress,
            uri: params.uri,
            isBurned: false,
            timestamp: block.timestamp
        });

        _tokens[_totalSupplyCount] = newToken;
    }

    function burnBatch(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(_tokenIds[i]),
                "ERC721Metadata: Only token owner can burn tokens"
            );
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    function burn(uint256 _tokenId) public {
        require(
            msg.sender == ownerOf(_tokenId),
            "ERC721Metadata: Only token owner can burn token"
        );
        _burn(_tokenId);
        _tokens[_tokenId].isBurned = true;
        emit TokenBurned(_tokenId);
    }

    function setLegendCollection(address _legendCollectionAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_legendCollection);
        _legendCollection = LegendCollection(_legendCollectionAddress);
        emit LegendCollectionUpdated(
            oldAddress,
            _legendCollectionAddress,
            msg.sender
        );
    }

    function setLegendEscrow(address _legendEscrowAddress) external onlyAdmin {
        address oldAddress = address(_legendEscrow);
        _legendEscrow = LegendEscrow(_legendEscrowAddress);
        emit LegendEscrowUpdated(oldAddress, _legendEscrowAddress, msg.sender);
    }

    function updateAccessControl(address _newAccessControlAddress)
        public
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokens[_tokenId].uri;
    }

    function getTotalSupplyCount() public view returns (uint256) {
        return _totalSupplyCount;
    }

    function getTokenCreator(uint256 _tokenId) public view returns (address) {
        return _tokens[_tokenId].creator;
    }

    function getTokenAcceptedTokens(uint256 _tokenId)
        public
        view
        returns (address[] memory)
    {
        return _tokens[_tokenId].acceptedTokens;
    }

    function getTokenBasePrices(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return _tokens[_tokenId].basePrices;
    }

    function getTokenCollection(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _tokens[_tokenId].collectionId;
    }

    function getTokenDiscount(uint256 _tokenId) public view returns (uint256) {
        return _discount[_tokenId];
    }

    function getTokenGrantCollectorsOnly(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return _grantCollectorsOnly[_tokenId];
    }

    function getTokenIsBurned(uint256 _tokenId) public view returns (bool) {
        return _tokens[_tokenId].isBurned;
    }

    function getTokenTimestamp(uint256 _tokenId) public view returns (uint256) {
        return _tokens[_tokenId].timestamp;
    }

    function getTokenId(uint256 _tokenId) public view returns (uint256) {
        return _tokens[_tokenId].tokenId;
    }

    function getTokenPrintType(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return _printType[_tokenId];
    }

    function getTokenDynamicNFTAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return _dynamicNFTAddress[_tokenId];
    }

    function getTokenFulfillerId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _fulfillerId[_tokenId];
    }

    function getTokenPubId(uint256 _tokenId) public view returns (uint256) {
        return _pubId[_tokenId];
    }

    function setTokenAcceptedTokens(
        uint256 _tokenId,
        address[] memory _newAcceptedTokens
    ) public onlyCollectionContract {
        address[] memory oldTokens = _tokens[_tokenId].acceptedTokens;
        _tokens[_tokenId].acceptedTokens = _newAcceptedTokens;
        emit TokenAcceptedTokensUpdated(
            _tokenId,
            oldTokens,
            _newAcceptedTokens,
            msg.sender
        );
    }

    function setBasePrices(uint256 _tokenId, uint256[] memory _newPrices)
        public
        onlyCollectionContract
    {
        uint256[] memory oldPrices = _tokens[_tokenId].basePrices;
        _tokens[_tokenId].basePrices = _newPrices;
        emit TokenBasePriceUpdated(_tokenId, oldPrices, _newPrices, msg.sender);
    }

    function setFulfillerId(uint256 _tokenId, uint256 _newFulfillerId)
        public
        onlyCollectionContract
    {
        uint256 oldFulfillerId = _fulfillerId[_tokenId];
        _fulfillerId[_tokenId] = _newFulfillerId;
        emit TokenFulfillerIdUpdated(
            _tokenId,
            oldFulfillerId,
            _newFulfillerId,
            msg.sender
        );
    }

    function setPrintType(uint256 _tokenId, string memory _newPrintType)
        public
        onlyCollectionContract
    {
        string memory oldPrintType = _printType[_tokenId];
        _printType[_tokenId] = _newPrintType;
        emit TokenPrintTypeUpdated(
            _tokenId,
            oldPrintType,
            _newPrintType,
            msg.sender
        );
    }

    function setTokenURI(uint256 _tokenId, string memory _newURI)
        public
        onlyCollectionContract
        tokensInEscrow(_tokenId)
    {
        string memory oldURI = _tokens[_tokenId].uri;
        _tokens[_tokenId].uri = _newURI;
        emit TokenURIUpdated(_tokenId, oldURI, _newURI, msg.sender);
    }

    function setGrantCollectorsOnly(uint256 _tokenId, bool _collectorsOnly)
        public
        onlyCollectionContract
    {
        _grantCollectorsOnly[_tokenId] = _collectorsOnly;
        emit TokenGrantCollectorsOnlyUpdated(
            _tokenId,
            _collectorsOnly,
            msg.sender
        );
    }

    function setDiscount(uint256 _tokenId, uint256 _newDiscount)
        public
        onlyCollectionContract
    {
        require(
            _newDiscount < 100,
            "LegendMarket: Discount cannot exceed 100."
        );
        _discount[_tokenId] = _newDiscount;
        emit TokenDiscountUpdated(_tokenId, _newDiscount, msg.sender);
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }

    function getLegendEscrowContract() public view returns (address) {
        return address(_legendEscrow);
    }

    function getLegendCollectionContract() public view returns (address) {
        return address(_legendCollection);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GlobalLegendAccessControl.sol";

contract LegendPayment {
    GlobalLegendAccessControl private _accessControl;
    address[] private _verifiedPaymentTokens;

    mapping(address => bool) private isVerifiedPaymentToken;

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    constructor(address _accessControlAddress) {
        _accessControl = GlobalLegendAccessControl(_accessControlAddress);
    }

    function setVerifiedPaymentTokens(address[] memory _paymentTokens)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < _verifiedPaymentTokens.length; i++) {
            isVerifiedPaymentToken[_verifiedPaymentTokens[i]] = false;
        }
        delete _verifiedPaymentTokens;

        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            isVerifiedPaymentToken[_paymentTokens[i]] = true;
            _verifiedPaymentTokens.push(_paymentTokens[i]);
        }
    }

    function getVerifiedPaymentTokens() public view returns (address[] memory) {
        return _verifiedPaymentTokens;
    }

    function updateAccessControl(address _newAccessControlAddress)
        external
        onlyAdmin
    {
        address oldAddress = address(_accessControl);
        _accessControl = GlobalLegendAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function checkIfAddressVerified(address _address)
        public
        view
        returns (bool)
    {
        return isVerifiedPaymentToken[_address];
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }
}