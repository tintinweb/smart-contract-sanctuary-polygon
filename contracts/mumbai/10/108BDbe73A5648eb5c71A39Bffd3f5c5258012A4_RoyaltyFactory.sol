// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Royalty/RoyaltySplitter.sol";
import "../Store/IStorage.sol";

import "./IRoyaltyFactory.sol";

contract RoyaltyFactory is Ownable, IRoyaltyFactory {
  // ============ Storage ============

  //mapping of id to royalty splitter
  mapping(uint256 => RoyaltySplitter) private _royalties;

  // ============ Read Methods ============

  /**
   * @dev Returns the royalty address
   */
  function royalty(uint256 id) external view returns(address) {
    return address(_royalties[id]);
  }

  // ============ Write Methods ============

  /**
   * @dev Deploys a royalty splitter contract and adds to the store
   */
  function deploy(
    uint256 _id,
    address[] memory _payees,
    uint256[] memory _shares,
    address _owner,
    address _operator
  ) external onlyOwner {
    _royalties[_id] = new RoyaltySplitter(
      _payees, 
      _shares, 
      _owner,
      _operator
    );
  }

  /**
   * @dev Allows contracts to pass ownership
   */
  function transferOwnership(address newOwner) 
    public virtual override(IRoyaltyFactory, Ownable) onlyOwner 
  {
    super.transferOwnership(newOwner);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Operator/OwnerOperator.sol";
import "./IRoyaltySplitter.sol";

error InvalidRecipients();
error InvalidRecipient();
error InvalidShares();
error ZeroPaymentDue();
error RecipientZeroShares();
error RecipientExistingShares();
error TokenAlreadyAccepted();

contract RoyaltySplitter is 
  Context, 
  ReentrancyGuard, 
  OwnerOperator, 
  IRoyaltySplitter 
{ 
  // ============ Storage ============

  IERC20[] private _erc20Accepted;

  uint256 private _totalShares;
  mapping(address => uint256) private _shares;
  address[] private _recipients;

  uint256 private _ethTotalAccountedFor;
  uint256 private _ethTotalUnaccountedReleased;
  mapping(address => uint256) private _ethAccountedFor;
  mapping(address => uint256) private _ethAccountedReleased;
  mapping(address => uint256) private _ethUnaccountedReleased;

  mapping(IERC20 => uint256) private _erc20TotalAccountedFor;
  mapping(IERC20 => uint256) private _erc20TotalUnaccountedReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20AccountedFor;
  mapping(IERC20 => mapping(address => uint256)) private _erc20UnaccountedReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20AccountedReleased;

  // ============ Modifiers ============

  modifier validRecipients(
    address[] memory recipients, 
    uint256[] memory shares_
  ) {
    if (recipients.length == 0 || recipients.length != shares_.length) 
      revert InvalidRecipients();
    _;
  }

  // ============ Deploy ============

  /**
   * @dev Creates an instance of `RoyalySplitter` where each account 
   * in `recipients` is assigned the number of shares at the matching 
   * position in the `shares` array.
   *
   * All addresses in `recipients` must be non-zero. Both arrays must 
   * have the same non-zero length, and there must be no duplicates in 
   * `recipients`.
   */
  constructor(
    address[] memory recipients_, 
    uint256[] memory shares_,
    address owner_,
    address operator_
  ) payable validRecipients(recipients_, shares_) {
    _transferOwnership(owner_);
    _transferOperator(operator_);
    for (uint256 i = 0; i < recipients_.length; i++) {
      _addRecipient(recipients_[i], shares_[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} 
   * events. Note that these events are not fully reliable: it's 
   * possible for a contract to receive Ether without triggering this 
   * function. This only affects the reliability of the events, and not 
   * the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the recipient number `index`.
   */
  function recipient(uint256 index) external view returns(address) {
    return _recipients[index];
  }
  
  /**
   * @dev Calculates the eth that can be releasable to `account`
   */
  function releasable(address account) external view returns(uint256) {
    return _accountedFor(account) + _unaccountedFor(account);
  }

  /**
   * @dev Calculates the ERC20 that can be releasable to `account`
   */
  function releasable(IERC20 token, address account) 
    external view returns(uint256)
  {
    return _accountedFor(token, account) + _unaccountedFor(token, account);
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) external view returns(uint256) {
    return _ethUnaccountedReleased[account] + _ethAccountedReleased[account];
  }

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function released(IERC20 token, address account) 
    external view returns(uint256) 
  {
    return _erc20UnaccountedReleased[token][account] + _erc20AccountedReleased[token][account];
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) external view returns(uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the total amount of ether already released.
   */
  function totalReleased() external view returns(uint256) {
    return _ethTotalUnaccountedReleased;
  }

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function totalReleased(IERC20 token) external view returns(uint256) {
    return _erc20TotalUnaccountedReleased[token];
  }

  /**
   * @dev Getter for the total shares held by all recipients.
   */
  function totalShares() external view returns(uint256) {
    return _totalShares;
  }

  // ============ Write Methods ============

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function release(address payable account) 
    external nonReentrant 
  {
    //get the amount accounted for
    uint256 accountedFor = _accountedFor(account);
    //get the amount unaccounted for
    uint256 unaccountedFor = _unaccountedFor(account);
    //calc payment
    uint256 payment = accountedFor + unaccountedFor;
    //error if no payment
    if (payment == 0) revert ZeroPaymentDue();

    //update the release totals for unaccounted
    _ethUnaccountedReleased[account] += unaccountedFor;
    _ethTotalUnaccountedReleased += unaccountedFor;
    //update the release totals for accounted
    _ethAccountedReleased[account] += accountedFor;
    _ethTotalAccountedFor -= accountedFor;
    _ethAccountedFor[account] = 0;
    //now transfer the tokens out
    Address.sendValue(account, payment);
    //emit released
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function release(IERC20 token, address account) 
    external nonReentrant
  {
    //get the amount accounted for
    uint256 accountedFor = _accountedFor(token, account);
    //get the amount unaccounted for
    uint256 unaccountedFor = _unaccountedFor(token, account);
    //calc payment
    uint256 payment = accountedFor + unaccountedFor;
    //error if no payment
    if (payment == 0) revert ZeroPaymentDue();

    //update the release totals for unaccounted
    _erc20UnaccountedReleased[token][account] += unaccountedFor;
    _erc20TotalUnaccountedReleased[token] += unaccountedFor;
    //update the release totals for accounted
    _erc20AccountedReleased[token][account] += accountedFor;
    _erc20TotalAccountedFor[token] -= accountedFor;
    _erc20AccountedFor[token][account] = 0;
    //now transfer the tokens out
    SafeERC20.safeTransfer(token, account, payment);
    //emit released
    emit ERC20PaymentReleased(token, account, payment);
  }

  // ============ Admin Methods ============

  /**
   * @dev Considers tokens that can be accounted for
   */
  function accept(IERC20 token) external onlyOwnerOperator {
    for (uint256 i = 0; i < _erc20Accepted.length; i++) {
      if(_erc20Accepted[i] == token) revert TokenAlreadyAccepted();
    }

    _erc20Accepted.push(token);
  }

  /**
   * @dev Add a new `account` to the contract.
   */
  function addRecipient(address account, uint256 shares_) 
    external onlyOwnerOperator
  {
    //account for the unaccounted for
    _accountFor();
    //then just add recipient
    _addRecipient(account, shares_);
  }

  /**
   * @dev Replaces the `recipients` with a new set
   */
  function batchUpdate(
    address[] memory recipients, 
    uint256[] memory shares_
  ) external validRecipients(recipients, shares_) onlyOwnerOperator {
    //account for the unaccounted for
    _accountFor();
    //make sure total shares and payees are zeroed out
    _totalShares = 0;
    //reset the payees array
    delete _recipients;
    emit RecipientsPurged();
    //now add recipients
    for (uint256 i = 0; i < recipients.length; i++) {
      _addRecipient(recipients[i], shares_[i]);
    }
  }

  /**
   * @dev Removes a `account`
   */
  function removeRecipient(uint256 index) 
    external onlyOwnerOperator 
  {
    if (index >= _recipients.length) revert InvalidRecipient();
    //account for the unaccounted for
    _accountFor();

    address account = _recipients[index];

    //make the index the last account
    _recipients[index] = _recipients[_recipients.length - 1];
    //pop the last
    _recipients.pop();

    //now we need to less the total shares
    _totalShares -= _shares[account];
    //and zero out the account shares
    _shares[account] = 0;

    //emit that payee was removed
    emit RecipientRemoved(account);
  }

  /**
   * @dev Update a `account`
   */
  function updateRecipient(address account, uint256 shares_) 
    external onlyOwnerOperator 
  {
    //account for the unaccounted for
    _accountFor();
    //now we need to adjust the total shares
    _totalShares = (_totalShares + shares_) - _shares[account];
    //update account shares
    _shares[account] = shares_;

    //emit that payee was updated
    emit RecipientUpdated(account, shares_);
  }

  // ============ Internal Methods ============

  /**
   * @dev Add a new payee to the contract.
   */
  function _addRecipient(address account, uint256 shares_) internal {
    if (account == address(0)) revert InvalidRecipient();
    if (shares_ == 0) revert InvalidShares();
    if (_shares[account] > 0) revert RecipientExistingShares();

    _recipients.push(account);
    _shares[account] = shares_;
    _totalShares += shares_;
    emit RecipientAdded(account, shares_);
  }

  /**
   * @dev Returns the eth for an `account` that is already accounted for
   */
  function _accountedFor(address account) internal view returns(uint256) {
    return _ethAccountedFor[account];
  }

  /**
   * @dev Returns the erc20 `token` for an `account` that is already accounted for
   */
  function _accountedFor(IERC20 token, address account) 
    internal view returns(uint256) 
  {
    return _erc20AccountedFor[token][account];
  }

  /**
   * @dev Returns the eth for an `account` that is unaccounted for
   */
  function _unaccountedFor(address account) 
    internal view returns(uint256) 
  {
    uint256 balance = _totalUnaccountedFor() + _ethTotalUnaccountedReleased;
    return _account(balance, _shares[account], _totalShares) - _ethUnaccountedReleased[account];
  }

  /**
   * @dev Returns the erc20 `token` for an `account` that is unaccounted for
   */
  function _unaccountedFor(IERC20 token, address account) 
    internal view returns(uint256) 
  {
    uint256 balance = _totalUnaccountedFor(token) + _erc20TotalUnaccountedReleased[token];
    return _account(balance, _shares[account], _totalShares) - _erc20UnaccountedReleased[token][account];
  }

  /**
   * @dev Returns the total amount of accounted for eth
   */
  function _totalAccountedFor() internal view returns(uint256) {
    return _ethTotalAccountedFor;
  }

  /**
   * @dev Returns the total amount of accounted for an erc20 `token`
   */
  function _totalAccountedFor(IERC20 token) 
    internal view returns(uint256) 
  {
    return _erc20TotalAccountedFor[token];
  }

  /**
   * @dev Returns the total amount of unaccounted eth
   */
  function _totalUnaccountedFor() internal view returns(uint256) {
    return address(this).balance - _totalAccountedFor();
  }

  /**
   * @dev Returns the total amount of unaccounted erc20 `token`
   */
  function _totalUnaccountedFor(IERC20 token) 
    internal view returns(uint256) 
  {
    return token.balanceOf(address(this)) - _totalAccountedFor(token);
  }

  /**
   * @dev Stores the amounts due to all the recipients from the 
   * unaccounted balance to an account vault
   */
  function _accountFor() internal {
    //get eth balance
    uint256 balance = (
      address(this).balance + _ethTotalUnaccountedReleased
    ) -  _totalAccountedFor();
    //first lets account for the eth
    for (uint256 i = 0; i < _recipients.length; i++) {
      _accountFor(_recipients[i], balance);
    }

    //loop through the accepted erc20 tokens
    for (uint256 j = 0; j < _erc20Accepted.length; j++) {
      //get erc20 token
      IERC20 token = _erc20Accepted[j];
      //get erc20 balance
      balance = (
        token.balanceOf(address(this)) + _erc20TotalUnaccountedReleased[token]
      ) - _totalAccountedFor(token);
      //account for the erc20
      for (uint256 i = 0; i < _recipients.length; i++) {
        _accountFor(token, _recipients[i], balance);
      }
    }
  }

  /**
   * @dev Stores the eth due to the `account` from the unaccounted 
   * balance to an account vault
   */
  function _accountFor(address account, uint256 balance) internal {
    uint256 unaccounted = _account(
      balance,
      _shares[account],
      _totalShares
    );
    
    _ethAccountedFor[account] += unaccounted;
    _ethTotalAccountedFor += unaccounted;
  }

  /**
   * @dev Stores the erc20 `token` due to the `account` from the 
   * unaccounted balance to an account vault
   */
  function _accountFor(IERC20 token, address account, uint256 balance) 
    internal 
  {
    uint256 unaccounted = _account(
      balance,
      _shares[account],
      _totalShares
    );

    _erc20AccountedFor[token][account] += unaccounted;
    _erc20TotalAccountedFor[token] += unaccounted;
  }

  /**
   * @dev The formula to account stuff
   */
  function _account(
    uint256 balance,
    uint256 currentShares,
    uint256 totalCurrentShares
  ) internal pure returns(uint256) {
    return (balance  * currentShares) / totalCurrentShares;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Account/IProduct.sol";

interface IStorage is IProduct {

  // ============ Structs ============

  struct Account {
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Metadata URI
    string uri;
    // Type
    string typeOf;
    // current supply (how many tokens minted)
    uint256 currentSupply;
    //operator address
    address operator;
    //exists flag
    bool exists;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns account information
   */
  function account(uint256 accountId) external view returns(
    // Type
    string memory typeOf,
    // Token name
    string memory name,
    // Token symbol
    string memory symbol,
    // Metadata URI
    string memory uri,
    // current supply (how many tokens minted)
    uint256 currentSupply,
    //operator address
    address operator,
    //exists flag
    bool exists
  );

  /**
   * @dev Returns the account id of a product
   */
  function accountOf(uint256 productId) external view returns(uint256);

  /**
   * @dev Returns the balance of a `recipient` in an account
   */
  function balanceOf(uint256 accountId, address recipient) 
    external view returns(uint256); 

  /**
   * @dev Returns the owner of a token
   */
  function ownerOf(uint256 tokenId) external view returns(address);

  /**
   * @dev Returns the royalty address of a product
   */
  function royaltyOf(uint256 productId) external view returns(address);

  /**
   * @dev Returns the token URI by using the base uri and index
   */
  function tokenURI(uint256 tokenId) external view returns(string memory); 

  // ============ Write Methods ============ 
  
  /**
   * @dev Mints a token
   */
  function mint(
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) external;

  /**
   * @dev Pauses transactions
   */
  function pause() external;

  /**
   * @dev Adds an account
   */
  function setAccount(
    uint256 accountId,
    string memory typeOf,
    string memory name,
    string memory symbol,
    string memory uri,
    address operator
  ) external;
  
  /**
   * @dev Adds a product
   */
  function setProduct(
    uint256 accountId,
    uint256 productId,
    uint256 maxSupply,
    string memory uri,
    uint16 royaltyPercent,
    address royaltyRecipient
  ) external;
  
  /**
   * @dev Transfers a token
   */
  function transfer(address to, uint256 tokenId) external;

  /**
   * @dev Pauses transactions
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoyaltyFactory {
  // ============ Read Methods ============

  /**
   * @dev Returns the royalty address
   */
  function royalty(uint256 id) external view returns(address);

  // ============ Write Methods ============

  /**
   * @dev Deploys a royalty splitter contract and adds to the store
   */
  function deploy(
    uint256 _id,
    address[] memory _payees,
    uint256[] memory _shares,
    address _owner,
    address _operator
  ) external;

  /**
   * @dev Allows contracts to pass ownership
   */
  function transferOwnership(address newOwner) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

error AssignmentToZeroAddress();
error CallerNotOwner();
error CallerNotOperator();
error CallerNotOwnerOperator();

abstract contract OwnerOperator is Context {
  // ============ Events ============

  event OwnershipTransferred(address indexed previous, address indexed next);
  event OperatorTransferred(address indexed previous, address indexed next);

  // ============ Storage ============

  address public _owner;
  address public _operator;

  // ============ Modifiers ============

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner {
    if (_owner != _msgSender()) revert CallerNotOwner();
    _;
  }

  /**
   * @dev Throws if called by any account other than the operator.
   */
  modifier onlyOperator {
    if (_operator != _msgSender()) revert CallerNotOwner();
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or operator.
   */
  modifier onlyOwnerOperator {
    address sender = _msgSender();
    if (sender != _owner && sender != _operator) 
      revert CallerNotOwnerOperator();
    _;
  }

  // ============ Read Methods ============

  function owner() public virtual view returns(address) {
    return _owner;
  }

  function operator() public virtual view returns(address) {
    return _operator;
  }

  // ============ Write Methods ============

  /**
   * @dev Transfers operator of the contract to `newOperator`.
   */
  function transferOperator(address newOperator) public virtual onlyOwnerOperator {
    if (newOperator == address(0)) revert AssignmentToZeroAddress();
    _transferOperator(newOperator);
  }

  /**
   * @dev Transfers owner of the contract to `newOwner`.
   */
  function transferOwnership(address newOwner) public virtual onlyOwnerOperator {
    if (newOwner == address(0)) revert AssignmentToZeroAddress();
    _transferOwnership(newOwner);
  }

  // ============ Internal Methods ============

  /**
   * @dev Transfers operator of the contract to `newOperator`.
   */
  function _transferOperator(address newOperator) internal virtual {
    address oldOperator = _operator;
    _operator = newOperator;
    emit OperatorTransferred(oldOperator, newOperator);
  }

  /**
   * @dev Transfers owner of the contract to `newOwner`.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoyaltySplitter {
  // ============ Events ============

  event RecipientAdded(address account, uint256 shares);
  event RecipientUpdated(address account, uint256 shares);
  event RecipientRemoved(address account);
  event RecipientsPurged();
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function recipient(uint256 index) external view returns(address);

  /**
   * @dev Calculates the eth that can be releasable to `account`
   */
  function releasable(address account) external view returns(uint256);

  /**
   * @dev Calculates the ERC20 that can be releasable to `account`
   */
  function releasable(IERC20 token, address account) 
    external view returns(uint256);

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) external view returns(uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function released(IERC20 token, address account) 
    external view returns(uint256);

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) external view returns(uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() external view returns(uint256);

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function totalReleased(IERC20 token) external view returns(uint256);

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function totalShares() external view returns(uint256);

  // ============ Write Methods ============

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function release(address payable account) 
    external;

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function release(IERC20 token, address account) 
    external;

  // ============ Admin Methods ============

  /**
   * @dev Considers tokens that can be vaulted
   */
  function accept(IERC20 token) 
    external;

  /**
   * @dev Add a new `account` to the contract.
   */
  function addRecipient(address account, uint256 shares_) 
    external;

  function batchUpdate(
    address[] memory recipients_, 
    uint256[] memory shares_
  ) external;

  /**
   * @dev Removes a `recipient`
   */
  function removeRecipient(uint256 index) 
    external;

  /**
   * @dev Update a `recipient`
   */
  function updateRecipient(address account, uint256 shares_) 
    external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProduct {

  // ============ Structs ============

  struct Product {
    //fixed metadata uri
    string uri;
    //max supply size
    uint256 maxSupply;
    //current supply size (editions)
    uint256 currentSupply;
    //royalty percent
    uint16 royaltyPercent;
    //royalty recipient
    address royaltyRecipient;
    //exists flag
    bool exists;
  }

  // ============ Read Methods ============ 

  /**
   * @dev Returns product information
   */
  function product(uint256 productId) external view returns(
    //fixed metadata uri
    string memory uri,
    //max supply size
    uint256 maxSupply,
    //current supply size (editions)
    uint256 currentSupply,
    //royalty percent
    uint16 royaltyPercent,
    //royalty recipient
    address royaltyRecipient,
    //exists flag
    bool exists
  );

  /**
   * @dev Returns the product id of a token
   */
  function productOf(uint256 tokenId) external view returns(uint256);
}