// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.8.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
        // cannot overflow.
        _erc20TotalReleased[token] += payment;
        unchecked {
            _erc20Released[token][account] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
interface IEventContract{
      struct TicketType {
        uint32 maxTickets;
        uint32 maxTicketsPerUser;
        uint256 ticketPrice; //exprimé en WEI 1 € = 1 ETH = 10^18 WEI (euros) 
        uint256 bookingStartDate;
        uint256 bookingEndDate;
        string name;
        string description;
        bool revealed;
        uint256 revealStartDate;
        bool sellable;
        uint256 maxSellablePrice;
        uint256 royaltySellable;
        bool earlyBid;
        uint256 discountPrice;
        uint256 discountEndDate;
        string uri;
    }
    function getEventId() external view returns (string memory);
    function getEventName() external view returns (string memory);
    function getTicketTypeInfo(uint256 _ticketTypeId) external view returns (TicketType memory);
    function getTicketTypesNbMinted(uint256 _ticketTypeId) external view returns (uint256);
    function getListOfTicketForTicketType(uint256 _ticketTypeId) external view returns (uint256);
    function addTicketToListOfTicketType(uint256 _ticketTypeId) external ;
    function addTicketTypesNbTicketMinted(uint256 _ticketTypeId,uint256 amount) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";  
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import 'abdk-libraries-solidity/ABDKMathQuad.sol'; 
import "./TokenPaymentSplitter.sol"; 
import "./IEventContract.sol";
/*
    Ticket smart contract for a specific Event of a specific organizer (the owner)
*/
contract TicketContract  is ERC721,Ownable {
   using Counters for Counters.Counter;
   Counters.Counter private _ticketIds;
   uint96 internal royaltyValue = 2;
   bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
   address[] founders;
   address payable  foundersWallet;
   address payable resellPaiementSplitter;
   AggregatorV3Interface internal dataFeed;
     struct TokenInfo {
        IERC20 paytoken;
        bool exists;
    }
    struct Ticket {
        uint256 ticketId;
        uint256 ticketTypeId;
        address owner;
        bytes32 hashedTicket; // EventId:TicketType:TicketId encrypté en SHA256
        uint256 pricePaid;
        uint256 purchasedDate;
        bool used;
        bool exists;
    }

    IEventContract public eventContract;
    TokenInfo[] public AllowedCrypto;
    string internal baseURI;
    string public uriSuffix = ".json";

     // Mappings
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => string) public ticketSpecificUri; 
    mapping(uint256 => uint256) public ticketTypesForTicket;
    // Events

    event NewTicket(uint256 ticketTypeId, uint256 ticketId,address owner);
    //1 smart contract par organisateur
   modifier onlyFounders() {
        require(
            msg.sender == founders[0] || msg.sender == founders[1],
            "Only founders can do that"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == founders[0] ||
                msg.sender == founders[1] ||
                msg.sender == owner(),
            "Only admins can do that"
        );
        _;
    }
   
     
    function getLatestData() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

   constructor(
        address _founder1,
        address _founder2,
        address _paymentSplitter,
        address _resellPaiementSplitter,
        address _dataFeedEURUSD,
        address _eventContract ,
        string memory _eventName      
    ) ERC721(string.concat(_eventName,"TixSell NFT Tickets"), string.concat(_eventName," TixTickets")) {
       
        foundersWallet = payable(_paymentSplitter);
        resellPaiementSplitter = payable(_resellPaiementSplitter);
        founders.push(payable(_founder1));
        founders.push(payable(_founder2));
      
         dataFeed = AggregatorV3Interface(
            _dataFeedEURUSD
        );
        eventContract = IEventContract(_eventContract);
    }

     function addCurrency(
        IERC20 _paytoken        
    ) public onlyFounders {
       
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                exists:true
            })
        );
        //Need to approve 
        uint256 approve_amount = (2^256 - 1 )*10e18;
    
        IERC20(_paytoken).approve(foundersWallet, approve_amount);
        IERC20(_paytoken).approve(owner(), approve_amount);
    }
    function setRoyalty(uint96 _newroyalty) public onlyFounders {
        royaltyValue = _newroyalty;
      }
    // Founders or owner can override hashed Ids for security reasons (like a hacked of current ticket id)
    function setHashTicketId(
        uint256 _tokenId,
        bytes32 _hashedTicketId
    ) public onlyFounders  {
        Ticket storage theTicket = tickets[_tokenId];
        theTicket.hashedTicket = _hashedTicketId;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    
   function updateMetadata(uint256 _tokenId, string calldata _uri) external onlyAdmin {
        ticketSpecificUri[_tokenId]=_uri;
    }
 

    // Mint en USDT
    // Il faut tenir compte de notre pourcentage 2%
    //Ou alors on considère que le mint est toujours passé en euros... 
    function buyTicket(uint256 _ticketTypeId,uint256 amount,bool _withERC20,uint256 _cryptoId) external payable 
    {
        IERC20 paytoken;
        if (_withERC20){
            require(AllowedCrypto.length>=_cryptoId,"Crypto id invalid");
            TokenInfo storage tokens = AllowedCrypto[_cryptoId];
         
            require(tokens.exists,"Crypto not supported");
            paytoken = tokens.paytoken;
        }
      
        
         
        IEventContract.TicketType memory theTicketType = eventContract.getTicketTypeInfo(_ticketTypeId);

        require(theTicketType.maxTickets>0,"TicketType does'nt exists");  
        //DIscount 
        if (theTicketType.earlyBid){
            require(theTicketType.discountEndDate < theTicketType.bookingStartDate,"Discount end date should be before booking start date");
            if ( block.timestamp > theTicketType.discountEndDate){
                require(theTicketType.bookingStartDate < block.timestamp,"Booking not started yet");
            }
        }   
        else{
            // check bookinStartDate started
           require(theTicketType.bookingStartDate < block.timestamp,"Booking not started yet");
        
        }   
         // check bookingEndDate not reached
         require(block.timestamp < theTicketType.bookingEndDate ,"Booking ended");
         uint256 nbMinted = eventContract.getTicketTypesNbMinted(_ticketTypeId);

         // check totalSupply not reached
         require (nbMinted< theTicketType.maxTickets,"No more tickets");

         // check amount per customer is ok 
         require(amount <= theTicketType.maxTicketsPerUser,"Amount per user too high");
         require(amount > 0,"Must buy 1 ticket at least");
         // Doit vérifie si user a déjà acheté des tickets et si oui que nb acheté + amount voulu < max ticket per user
         uint256 existingBalance = balanceOf(msg.sender);
        require(amount+existingBalance <= theTicketType.maxTicketsPerUser,"Amount per user reached");
         // check not reaching maxTickets with the amount to purchased
         require(nbMinted + amount <= theTicketType.maxTickets,"Amount too high no more tickets");
         
         uint256 pricePerTicket = theTicketType.ticketPrice;

         // check si discount 
         if (theTicketType.earlyBid){
            if (theTicketType.discountEndDate > block.timestamp && theTicketType.discountEndDate < theTicketType.bookingStartDate){
                // can apply discount
                pricePerTicket = theTicketType.discountPrice;
            }
         }


        uint256 priceToPaid = pricePerTicket*amount;
        uint priceInDollars = 1;
        if (_withERC20){
            //Prix exprimé en euros.
            //Need to convert $ in euros 
            int dollarValue = 109478000 ;  //is 8 decimal / (1e8);
            //REMOVE COMMENT 
            //int dollarValue = getLatestData() ;
            
            //Price to paid express in 10e18 ... 
            priceInDollars = uint(dollarValue) * 1e10;

            // 1,09 $ = 1 €
            //        = 10 €
            
            // prix exrpimés en euros , il faut trouver en $ combien on paye
            // 10 € = 10,9 $  (prix dollar * prix euros)

            // check paid enought
            priceToPaid = ((pricePerTicket*priceInDollars)/1e18)*amount;
        }
        
         
         
         require((msg.value >= priceToPaid),"not enough money");

         for (uint256 i = 0; i < amount; i++) {
            
            // // Send our royalties to our payment splitter  

            uint256 unitPrice = pricePerTicket;
            if (_withERC20){
                 unitPrice = ((pricePerTicket*priceInDollars)/1e18);
                 if (unitPrice>0){
                    paytoken.transferFrom(msg.sender, address(this), unitPrice);
                 }
                
            }
            uint256 amountPercent = mulDiv(royaltyValue, unitPrice, 100);
            if (amountPercent>0) {
                if (_withERC20){
                      paytoken.transfer(foundersWallet, amountPercent);
                }
                else{
                     payable(foundersWallet).transfer(amountPercent);
       
                }
            }
            
            
            // get next tokenId 
            uint256 tokenId = eventContract.getListOfTicketForTicketType(_ticketTypeId);
            _safeMint(msg.sender, tokenId);
            // hashcode
            string memory secretOne = string.concat(eventContract.getEventId(),":");
            string memory secretTwo = string.concat(secretOne,Strings.toString(_ticketTypeId));
            string memory secretThree = string.concat(secretTwo,":");
            string memory secret = string.concat(secretThree,Strings.toString(tokenId));
            bytes32 hashedCode = sha256(bytes(secret));

            tickets[tokenId] = Ticket(
                tokenId,
                _ticketTypeId,
                msg.sender,
                hashedCode,
                pricePerTicket,
                block.timestamp,
                false,
                true
            );
            eventContract.addTicketToListOfTicketType(_ticketTypeId);
            ticketTypesForTicket[tokenId] = _ticketTypeId;
            emit NewTicket(_ticketTypeId,tokenId,msg.sender);
        }   
        // increment totalSupply for ticketPrice 
         eventContract.addTicketTypesNbTicketMinted(_ticketTypeId,amount);
      // 
    }
 
 function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        //Si uri specific token on renvoi sinon on renvoi celui du ticket type 
        // Ticket memory theTicket = tickets[_tokenId];
        // TicketType memory theTicketType = ticketTypes[theTicket.ticketTypeId];
        //  if (theTicketType.revealed == false) {
        //     string memory currentBaseURI = hiddenMetadataUri;
        //     return
        //         bytes(currentBaseURI).length > 0
        //             ? string(
        //                 abi.encodePacked(
        //                     currentBaseURI,
        //                     _tokenId.toString(),
        //                     '.json'
        //                 )
        //             )
        //             : "";
        // }
        // else{
        //     string memory currentBaseURI = _baseURI();
        //     return
        //         bytes(currentBaseURI).length > 0
        //             ? string(
        //                 abi.encodePacked(
        //                     currentBaseURI,
        //                     _tokenId.toString(),
        //                     '.json'
        //                 )
        //             )
        //             : "";
        // }
        return "";
    }
   
    function getTotalTicketsSold() public view returns (uint256) {
        return  _ticketIds.current();
    }
    

    function fetchTicketsForOwner(address _fan)
        public
        view
        returns (Ticket[] memory)
    {
        uint256 totalItemCount = _ticketIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i <totalItemCount; i++) {
         
            if (tickets[i].owner == _fan) {
                itemCount += 1;
            }
        }

        Ticket[] memory items = new Ticket[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (tickets[i].owner == _fan) {
                uint256 currentId = i;
                Ticket memory currentItem = tickets[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
 
    //Pour la revente, il faut récupérer la config du Ticket et répartir l'argent pour l'acheteur, l'organisateur et notre %... 

      function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        Ticket storage theTicket = tickets[tokenId];
        //Get ticketTypeId from token 
        uint256 _ticketTypeId = ticketTypesForTicket[tokenId];
        // check si resellable
        IEventContract.TicketType memory theTicketType = eventContract.getTicketTypeInfo(_ticketTypeId);

        require(theTicketType.sellable,"not sellable");
         
        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId, data);
        theTicket.owner = payable(to);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
         Ticket storage theTicket = tickets[tokenId];
        // check si resellable
           //Get ticketTypeId from token 
        uint256 _ticketTypeId = ticketTypesForTicket[tokenId];
        IEventContract.TicketType memory theTicketType = eventContract.getTicketTypeInfo(_ticketTypeId);

        require(theTicketType.sellable,"not sellable");

        //call the original function that you wanted.
        super.safeTransferFrom(from, to, tokenId);
        theTicket.owner = payable(to);

        
    }

      function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
          Ticket storage theTicket = tickets[tokenId];
             //Get ticketTypeId from token 
        uint256 _ticketTypeId = ticketTypesForTicket[tokenId];
         // check si resellable
         IEventContract.TicketType memory theTicketType = eventContract.getTicketTypeInfo(_ticketTypeId);

        require(theTicketType.sellable,"not sellable");

        //call the original function that you wanted.
        super.transferFrom(from, to, tokenId);
        theTicket.owner = payable(to);
        
    }
 

    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount)
    {
      require(
            _exists(tokenId),
            "Nonexistent token"
        );
        //Get ticketTypeId from token 
        uint256 _ticketTypeId = ticketTypesForTicket[tokenId];
        IEventContract.TicketType memory theTicketType = eventContract.getTicketTypeInfo(_ticketTypeId);
        uint256 royaltySellable = theTicketType.royaltySellable;
        royaltyAmount = (value * royaltySellable) / 10000;
        receiver = resellPaiementSplitter;
    }
 
 
   function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool){
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
   }
    
    function withdraw() external onlyOwner {
     uint256 balance = address(this).balance;
     require(balance > 0, "No ether left to withdraw");

     (bool success, ) = payable(owner()).call{value: balance}("");

     require(success, "Transfer failed.");
    }

      function mulDiv (uint x, uint y, uint z)
        public pure returns (uint) {
        return
            ABDKMathQuad.toUInt (
            ABDKMathQuad.div (
                ABDKMathQuad.mul (
                ABDKMathQuad.fromUInt (x),
                ABDKMathQuad.fromUInt (y)
                ),
                ABDKMathQuad.fromUInt (z)
            )
            );
        }
 
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract TokenPaymentSplitter is PaymentSplitter {
    constructor (
        address[] memory payees,
        uint256[] memory shares_
    ) payable
    PaymentSplitter(payees, shares_)
    {}
}