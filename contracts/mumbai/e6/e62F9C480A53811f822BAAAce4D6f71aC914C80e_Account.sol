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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

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
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AchievementNFT.sol";
import "./ValidatorNFT.sol";

/**
 * @title Account Contract
 * This contract stores and controls all user information
 */
contract Account is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    /**
     * @dev Event is triggered when user created
     */
    event UserCreated(
        bytes32 _id,
        string _email,
        string _avatar,
        string _nickname
    );

    /**
     * @dev Event is triggered when user deleted
     */
    event UserDeleted(bytes32 _id);

    /**
     * @dev Event is triggered when Matic deposited
     */
    event MaticDeposited(
        address indexed _from,
        bytes32 indexed _id,
        uint256 _amount
    );

    /**
     * @dev Event is triggered when Matic withdrawn
     */
    event MaticWithdrawn(
        address indexed _to,
        bytes32 indexed _id,
        uint256 _amount
    );

    /**
     * @dev Event is triggered when Matic blocked
     */
    event MaticBlocked(bytes32 _id, uint256 _amount);

    /**
     * @dev Event is triggered when Matic unblocked
     */
    event MaticUnblocked(bytes32 _id, uint256 _amount);

    /**
     * @dev Event is triggered when ERC20 token deposited
     */
    event ERC20TokenDeposited(
        address indexed _tokenAddress,
        address indexed _from,
        bytes32 indexed _id,
        uint256 _amount
    );

    /**
     * @dev Event is triggered when ERC20 token balance increased
     */
    event ERC20TokenBalanceIncreased(
        address indexed _tokenAddress,
        bytes32 indexed _id,
        uint256 _amount
    );

    /**
     * @dev Event is triggered when ERC20 token withdrawn
     */
    event ERC20TokenWithdrawn(
        address indexed _tokenAddress,
        address indexed _to,
        bytes32 indexed _id,
        uint256 _amount
    );

    /**
     * @dev Event is triggered when user payed ERC20 token fee
     */
    event ERC20FeePayed(address _tokenAddress, bytes32 _id, uint256 _fee);

    /**
     * @dev Event is triggered when ERC20 token blocked
     */
    event ERC20Blocked(address _tokenAddress, bytes32 _id, uint256 _amount);

    /**
     * @dev Event is triggered when ERC20 token unblocked
     */
    event ERC20Unblocked(address _tokenAddress, bytes32 _id, uint256 _amount);

    /**
     * @dev Event is triggered when NFT deposited
     */
    event NFTDeposited(
        address indexed _nftAddress,
        address indexed _from,
        bytes32 indexed _id,
        uint256 _tokenId
    );

    /**
     * @dev Event is triggered when NFT withdrawn
     */
    event NFTWithdrawn(
        address indexed _nftAddress,
        address indexed _to,
        bytes32 indexed _id,
        uint256 _tokenId
    );

    struct UserData {
        string email;
        string avatar;
        string nickname;
    }

    address public immutable utilityTokenAddress;
    address public immutable governanceTokenAddress;
    address public immutable achievementNFTAddress;
    address public immutable validatorNFTAddress;
    address public challengeAddress;
    uint256 public usersCount;
    mapping(bytes32 => UserData) users;
    mapping(bytes32 => uint256[]) allAchievements;
    mapping(bytes32 => uint256[]) allValidators;
    mapping(bytes32 => uint256) maticBalances;
    mapping(bytes32 => uint256) blockedMatic;
    mapping(bytes32 => mapping(uint256 => bool)) achievements;
    mapping(bytes32 => mapping(uint256 => bool)) validators;
    mapping(bytes32 => mapping(address => uint256)) erc20Balances;
    mapping(bytes32 => mapping(address => uint256)) blockedERC20;

    constructor(
        address _utilityTokenAddress,
        address _governanceTokenAddress,
        address _achievementNFTAddress,
        address _validatorNFTAddress
    ) {
        require(
            _utilityTokenAddress != address(0x0),
            "Account: utility token address cannot be zero"
        );
        require(
            _governanceTokenAddress != address(0x0),
            "Account: governance token address cannot be zero"
        );
        require(
            _achievementNFTAddress != address(0x0),
            "Account: achievement nft address cannot be zero"
        );
        require(
            _validatorNFTAddress != address(0x0),
            "Account: validator nft address cannot be zero"
        );
        utilityTokenAddress = _utilityTokenAddress;
        governanceTokenAddress = _governanceTokenAddress;
        achievementNFTAddress = _achievementNFTAddress;
        validatorNFTAddress = _validatorNFTAddress;
    }

    /**
     * @dev Sets challenge contract address
     * @param _challengeAddress address of challenge contract
     */
    function setChallengeContract(
        address _challengeAddress
    ) external onlyOwner {
        require(
            _challengeAddress != address(0x0),
            "Account: challenge address cannot be zero"
        );
        challengeAddress = _challengeAddress;
    }

    /**
     * @dev Creates new user
     * @param _id bytes32 id of user
     * @param _email string user's encoded email
     * @param _avatar string user's logo url
     * @param _nickname string user's nickname
     */
    function createUser(
        bytes32 _id,
        string calldata _email,
        string calldata _avatar,
        string calldata _nickname
    ) external onlyOwner {
        require(isIdUnique(_id), "Account: user already exists");
        require(bytes(_email).length != 0, "Account: email is empty");
        require(bytes(_nickname).length != 0, "Account: nickname is empty");
        UserData memory userData = UserData(_email, _avatar, _nickname);
        users[_id] = userData;
        usersCount++;
        emit UserCreated(_id, _email, _avatar, _nickname);
    }

    /**
     * @dev Get account data
     * @param _id bytes32 id of user
     * @return UserData struct
     */
    function getUser(bytes32 _id) external view returns (UserData memory) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        return users[_id];
    }

    /**
     * @dev Modifies users avatar
     * @param _id bytes32 id of user
     * @param _avatar string user's avatar
     */
    function modifyAvatar(
        bytes32 _id,
        string calldata _avatar
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(bytes(_avatar).length != 0, "Account: avatar is empty");
        users[_id].avatar = _avatar;
    }

    /**
     * @dev Modifies users nickname
     * @param _id bytes32 id of user
     * @param _nickname string user's nickname
     */
    function modifyNickname(
        bytes32 _id,
        string calldata _nickname
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(bytes(_nickname).length != 0, "Account: nickname is empty");
        users[_id].nickname = _nickname;
    }

    /**
     * @dev Deletes Account
     * @param _id bytes32 id of user
     */
    function deleteUser(bytes32 _id) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        UserData memory userData;
        users[_id] = userData;
        usersCount--;
        emit UserDeleted(_id);
    }

    /**
     * @dev Deposits Matic to the contract
     */
    function depositMatic(bytes32 _id) external payable {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(msg.value > 0, "Account: amount should be greater than 0");
        maticBalances[_id] += msg.value;
        emit MaticDeposited(msg.sender, _id, msg.value);
    }

    /**
     * @dev Withdraws Matic from the contract
     * @param _to address to
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of tokens
     */
    function withdrawMatic(
        address _to,
        bytes32 _id,
        uint256 _amount
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            _amount <= (maticBalances[_id] - blockedMatic[_id]),
            "Account: amount cannot be greater than balance"
        );
        require(address(this).balance >= _amount, "Account: not enough founds");
        payable(_to).transfer(_amount);
        maticBalances[_id] -= _amount;
        emit MaticWithdrawn(_to, _id, _amount);
    }

    /**
     * @dev Blocks Matic on user account
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of Matic
     */
    function blockMatic(bytes32 _id, uint256 _amount) external {
        require(
            msg.sender == challengeAddress,
            "Account: caller is not challenge contract"
        );
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(maticBalances[_id] >= _amount, "Account: not enough founds");
        blockedMatic[_id] += _amount;
        emit MaticBlocked(_id, _amount);
    }

    /**
     * @dev Unblocks Matic on user account
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of Matic
     */
    function unblockMatic(bytes32 _id, uint256 _amount) external {
        require(
            msg.sender == challengeAddress,
            "Account: caller is not challenge contract"
        );
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            blockedMatic[_id] >= _amount,
            "Account: amount is greater than blocked amount"
        );
        blockedMatic[_id] -= _amount;
        emit MaticUnblocked(_id, _amount);
    }

    /**
     * @dev Gets Matic balance
     * @param _id bytes32 id of user
     * @return uint256 balance
     */
    function getMaticBalance(bytes32 _id) external view returns (uint256) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(maticBalances[_id] != 0, "Account: balance is zero");
        return maticBalances[_id];
    }

    /**
     * @dev Gets Matic blocked amount
     * @param _id bytes32 id of user
     * @return uint256 blocked amount
     */
    function getMaticBlockedAmount(
        bytes32 _id
    ) external view returns (uint256) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(blockedMatic[_id] != 0, "Account: blocked amount is zero");
        return blockedMatic[_id];
    }

    /**
     * @dev Deposits ERC20 token to the contract
     * @param _from address from
     * @param _tokenAddress address of ERC20 token token
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of tokens
     */
    function depositERC20Token(
        address _tokenAddress,
        address _from,
        bytes32 _id,
        uint256 _amount
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.allowance(_from, address(this)) >= _amount,
            "Account: not enough allowance"
        );
        require(
            token.balanceOf(_from) >= _amount,
            "Account: not enough founds"
        );
        token.safeTransferFrom(_from, address(this), _amount);
        erc20Balances[_id][_tokenAddress] += _amount;
        emit ERC20TokenDeposited(_tokenAddress, _from, _id, _amount);
    }

    /**
     * @dev Increases ERC20 token balance
     * @param _tokenAddress address of ERC20 token token
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of tokens
     */
    function increaseERC20TokenBalance(
        address _tokenAddress,
        bytes32 _id,
        uint256 _amount
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        erc20Balances[_id][_tokenAddress] += _amount;
        emit ERC20TokenBalanceIncreased(_tokenAddress, _id, _amount);
    }

    /**
     * @dev Withdraws ERC20 token from the contract
     * @param _to address to
     * @param _tokenAddress address of ERC20 token token
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of tokens
     */
    function withdrawERC20Token(
        address _tokenAddress,
        address _to,
        bytes32 _id,
        uint256 _amount
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(
            _amount <= erc20Balances[_id][_tokenAddress],
            "Account: amount cannot be greater than balance"
        );
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Account: not enough founds"
        );
        token.safeTransfer(_to, _amount);
        erc20Balances[_id][_tokenAddress] -= _amount;
        emit ERC20TokenWithdrawn(_tokenAddress, _to, _id, _amount);
    }

    /**
     * @dev Pays ERC20 token fee
     * @param _tokenAddress address of ERC20 token token
     * @param _id bytes32 id of user
     * @param _fee uint256 amount of tokens
     */
    function payERC20Fee(
        address _tokenAddress,
        bytes32 _id,
        uint256 _fee
    ) external {
        require(
            msg.sender == challengeAddress,
            "Account: caller is not challenge contract"
        );
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_fee > 0, "Account: amount should be greater than 0");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(
            _fee <= erc20Balances[_id][_tokenAddress],
            "Account: amount cannot be greater than balance"
        );
        erc20Balances[_id][_tokenAddress] -= _fee;
        emit ERC20FeePayed(_tokenAddress, _id, _fee);
    }

    /**
     * @dev Blocks ERC20 token on user account
     * @param _tokenAddress address of token
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of Matic
     */
    function blockERC20(
        address _tokenAddress,
        bytes32 _id,
        uint256 _amount
    ) external {
        require(
            msg.sender == challengeAddress,
            "Account: caller is not challenge contract"
        );
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            erc20Balances[_id][_tokenAddress] >= _amount,
            "Account: not enough founds"
        );
        blockedERC20[_id][_tokenAddress] += _amount;
        emit ERC20Blocked(_tokenAddress, _id, _amount);
    }

    /**
     * @dev Unblocks ERC20 token on user account
     * @param _tokenAddress address of token
     * @param _id bytes32 id of user
     * @param _amount uint256 amount of Matic
     */
    function unblockERC20(
        address _tokenAddress,
        bytes32 _id,
        uint256 _amount
    ) external {
        require(
            msg.sender == challengeAddress,
            "Account: caller is not challenge contract"
        );
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(_amount > 0, "Account: amount should be greater than 0");
        require(
            blockedERC20[_id][_tokenAddress] >= _amount,
            "Account: amount is greater than blocked amount"
        );
        blockedERC20[_id][_tokenAddress] -= _amount;
        emit ERC20Unblocked(_tokenAddress, _id, _amount);
    }

    /**
     * @dev Gets ERC20 blocked amount
     * @param _tokenAddress address of token
     * @param _id bytes32 id of user
     * @return uint256 blocked amount
     */
    function getERC20BlockedAmount(
        address _tokenAddress,
        bytes32 _id
    ) external view returns (uint256) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(
            blockedERC20[_id][_tokenAddress] != 0,
            "Account: blocked amount is zero"
        );
        return blockedERC20[_id][_tokenAddress];
    }

    /**
     * @dev Gets Matic balance
     * @param _tokenAddress address of ERC20 token
     * @param _id bytes32 id of user
     * @return uint256 balance
     */
    function getERC20Balance(
        address _tokenAddress,
        bytes32 _id
    ) external view returns (uint256) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(
            _tokenAddress == utilityTokenAddress ||
                _tokenAddress == governanceTokenAddress,
            "Account: token is unavailable"
        );
        require(
            erc20Balances[_id][_tokenAddress] != 0,
            "Account: balance is zero"
        );
        return erc20Balances[_id][_tokenAddress];
    }

    /**
     * @dev Deposits Achievement NFT to the contract
     * @param _from address from
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function depositAchievementNFT(
        address _from,
        bytes32 _id,
        uint256 _tokenId
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_tokenId > 0, "Account: token id should be greater than 0");
        ERC721URIStorage achievementNFT = ERC721URIStorage(
            achievementNFTAddress
        );
        require(
            achievementNFT.getApproved(_tokenId) == address(this),
            "Account: not approved"
        );
        require(
            achievementNFT.ownerOf(_tokenId) == _from,
            "Account: not the owner"
        );
        achievementNFT.safeTransferFrom(_from, address(this), _tokenId);
        allAchievements[_id].push(_tokenId);
        achievements[_id][_tokenId] = true;
        emit NFTDeposited(achievementNFTAddress, _from, _id, _tokenId);
    }

    /**
     * @dev Withdraws Achievement NFT from the contract
     * @param _to address from
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function withdrawAchievementNFT(
        address _to,
        bytes32 _id,
        uint256 _tokenId
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_tokenId > 0, "Account: token id should be greater than 0");
        require(achievements[_id][_tokenId], "Account: unavailable token id");
        ERC721URIStorage achievementNFT = ERC721URIStorage(
            achievementNFTAddress
        );
        require(
            achievementNFT.ownerOf(_tokenId) == address(this),
            "Account: contract is not the owner of nft"
        );
        achievementNFT.safeTransferFrom(address(this), _to, _tokenId);
        removeAchievementTokenId(_id, _tokenId);
        achievements[_id][_tokenId] = false;
        emit NFTWithdrawn(achievementNFTAddress, _to, _id, _tokenId);
    }

    /**
     * @dev Gets Achievement NFTs
     * @param _id bytes32 id of user
     * @return uint256[] list of token ids
     */
    function getAchievementNFTs(
        bytes32 _id
    ) external view returns (uint256[] memory) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(allAchievements[_id].length > 0, "Account: balance is zero");
        return allAchievements[_id];
    }

    /**
     * @dev Deposits Validator NFT to the contract
     * @param _from address from
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function depositValidatorNFT(
        address _from,
        bytes32 _id,
        uint256 _tokenId
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_tokenId > 0, "Account: token id should be greater than 0");
        IERC721 validatorNFT = IERC721(validatorNFTAddress);
        require(
            validatorNFT.getApproved(_tokenId) == address(this),
            "Account: not approved"
        );
        require(
            validatorNFT.ownerOf(_tokenId) == _from,
            "Account: not the owner"
        );
        validatorNFT.safeTransferFrom(_from, address(this), _tokenId);
        allValidators[_id].push(_tokenId);
        validators[_id][_tokenId] = true;
        emit NFTDeposited(validatorNFTAddress, _from, _id, _tokenId);
    }

    /**
     * @dev Withdraws Validator NFT from the contract
     * @param _to address from
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function withdrawValidatorNFT(
        address _to,
        bytes32 _id,
        uint256 _tokenId
    ) external onlyOwner {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        require(_tokenId > 0, "Account: token id should be greater than 0");
        require(validators[_id][_tokenId], "Account: unavailable token id");
        IERC721 validatorNFT = IERC721(validatorNFTAddress);
        require(
            validatorNFT.ownerOf(_tokenId) == address(this),
            "Account: contract is not the owner of nft"
        );
        validatorNFT.safeTransferFrom(address(this), _to, _tokenId);
        removeValidatorTokenId(_id, _tokenId);
        validators[_id][_tokenId] = false;
        emit NFTWithdrawn(validatorNFTAddress, _to, _id, _tokenId);
    }

    /**
     * @dev Gets Validator NFTs
     * @param _id bytes32 id of user
     * @return uint256[] list of token ids
     */
    function getValidatorNFTs(
        bytes32 _id
    ) external view returns (uint256[] memory) {
        require(isValidator(_id), "Account: balance is zero");
        return allValidators[_id];
    }

    /**
     * @dev Removes Achievement token id from array
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function removeAchievementTokenId(bytes32 _id, uint256 _tokenId) internal {
        uint256 achievementsLength = allAchievements[_id].length;
        for (uint256 i = 0; i < achievementsLength; i++) {
            if (allAchievements[_id][i] == _tokenId) {
                allAchievements[_id][i] = allAchievements[_id][
                    achievementsLength - 1
                ];
                allAchievements[_id].pop();
                break;
            }
        }
    }

    /**
     * @dev Removes Validator token id from array
     * @param _id bytes32 id of user
     * @param _tokenId uint256 id of NFT
     */
    function removeValidatorTokenId(bytes32 _id, uint256 _tokenId) internal {
        uint256 validatorsLength = allValidators[_id].length;
        for (uint256 i = 0; i < validatorsLength; i++) {
            if (allValidators[_id][i] == _tokenId) {
                allValidators[_id][i] = allValidators[_id][
                    validatorsLength - 1
                ];
                allValidators[_id].pop();
                break;
            }
        }
    }

    /**
     * @dev Checks is email hash unique
     * @param _id bytes32 id of user
     * @return bool true if unique
     */
    function isIdUnique(bytes32 _id) public view returns (bool) {
        return (bytes(users[_id].nickname).length == 0);
    }

    /**
     * @dev Checks is user validator
     * @param _id bytes32 id of user
     * @return bool true if validator
     */
    function isValidator(bytes32 _id) public view returns (bool) {
        require(!isIdUnique(_id), "Account: user doesn't exist");
        return allValidators[_id].length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Achievement NFT Contract
 */
contract AchievementNFT is ERC721URIStorage, ERC721Enumerable, Ownable {
    /**
     * @dev Event is triggered if achievement NFT is minted
     * @param _recipient address of the achievement NFT recipient
     * @param _tokenId uint256 represents a specific achievement NFT
     * @param _tokenURI string containing achievement NFT metadata
     */
    event Minted(address _recipient, uint256 _tokenId, string _tokenURI);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /**
     * @dev NFT contract constructor
     * @param _name string represents the name
     * @param _symbol string represents the symbol
     */
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    /**
     * @dev Mint new Achievement NFT
     * @param _recipient address of the achievement NFT recipient
     * @param _tokenURI string containing achievement NFT metadata
     */
    function mintNFT(address _recipient, string memory _tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newNFTId = _tokenIds.current();
        _mint(_recipient, newNFTId);
        _setTokenURI(newNFTId, _tokenURI);
        return newNFTId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Validator NFT Contract
 */
contract ValidatorNFT is ERC721, ERC721Enumerable, Ownable {
    /**
     * @dev Event is triggered if achievement NFT is minted
     * @param _recipient address of the achievement NFT recipient
     * @param _tokenId uint256 represents a specific achievement NFT
     */
    event Minted(address _recipient, uint256 _tokenId);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /**
     * @dev NFT contract constructor
     * @param _name string represents the name
     * @param _symbol string represents the symbol
     */
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    /**
     * @dev Mints new validator NFT
     * @param _recipient address of the achievement NFT recipient
     */
    function mintNFT(address _recipient) public returns (uint256) {
        _tokenIds.increment();
        uint256 newNFTId = _tokenIds.current();
        _mint(_recipient, newNFTId);
        return newNFTId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}