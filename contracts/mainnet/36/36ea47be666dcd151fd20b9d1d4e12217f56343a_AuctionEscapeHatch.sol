// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Permissions.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/IBurnMintableERC20.sol";
import "./Auction.sol";


struct EarlyExitData {
  uint256 exitedEarly;
  uint256 earlyExitReturn;
  uint256 maltUsed;
}

struct AuctionExits {
  uint256 exitedEarly;
  uint256 earlyExitReturn;
  uint256 maltUsed;
  mapping(address => EarlyExitData) accountExits;
}


/// @title Auction Escape Hatch
/// @author 0xScotch <[email protected]>
/// @notice Functionality to reduce risk profile of holding arbitrage tokens by allowing early exit
contract AuctionEscapeHatch is Permissions {
  using SafeERC20 for ERC20;

  IAuction public auction;
  IDexHandler public dexHandler;
  ERC20 public collateralToken;
  IBurnMintableERC20 public malt;
  uint256 public maxEarlyExitBps = 2000; // 20%
  uint256 public cooloffPeriod = 60 * 60 * 24; // 24 hours

  mapping(uint256 => AuctionExits) internal auctionEarlyExits;

  event EarlyExit(address account, uint256 amount, uint256 received);
  event SetEarlyExitBps(uint256 earlyExitBps);
  event SetCooloffPeriod(uint256 period);
  event SetDexHandler(address handler);

  constructor(
    address _timelock,
    address initialAdmin,
    address _auction,
    address _handler,
    address _collateralToken,
    address _malt
  ) {
    require(_timelock != address(0), "EscapeHatch: Timelock addr(0)");
    require(initialAdmin != address(0), "EscapeHatch: Admin addr(0)");
    require(_auction != address(0), "EscapeHatch: Auction addr(0)");
    require(_handler != address(0), "EscapeHatch: DexHandler addr(0)");
    _adminSetup(_timelock);
    _setupRole(ADMIN_ROLE, initialAdmin);

    auction = IAuction(_auction);
    dexHandler = IDexHandler(_handler);
    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
  }

  function exitEarly(uint256 _auctionId, uint256 amount, uint256 minOut) external nonReentrant {
    AuctionExits storage auctionExits = auctionEarlyExits[_auctionId];

    (, uint256 maltQuantity, uint256 newAmount) = earlyExitReturn(msg.sender, _auctionId, amount);

    require(maltQuantity > 0, "ExitEarly: Insufficient output");

    malt.mint(address(dexHandler), maltQuantity);
    // Early exits happen below peg in recovery mode
    // So risk of sandwich is very low
    uint256 amountOut = dexHandler.sellMalt(maltQuantity, 5000);

    require(amountOut >= minOut, "EarlyExit: Insufficient output");

    auctionExits.exitedEarly += newAmount;
    auctionExits.earlyExitReturn += amountOut;
    auctionExits.maltUsed += maltQuantity;
    auctionExits.accountExits[msg.sender].exitedEarly +=  newAmount;
    auctionExits.accountExits[msg.sender].earlyExitReturn += amountOut;
    auctionExits.accountExits[msg.sender].maltUsed += maltQuantity;

    auction.accountExit(
      msg.sender,
      _auctionId,
      newAmount
    );

    collateralToken.safeTransfer(msg.sender, amountOut);
    emit EarlyExit(msg.sender, newAmount, amountOut);
  }

  function earlyExitReturn(address account, uint256 _auctionId, uint256 amount)
    public
    view
    returns(
      uint256 exitAmount,
      uint256 maltValue,
      uint256 usedAmount
    )
  {
    // We don't need all the values
    (,,,,,
     uint256 pegPrice,
     ,
     uint256 auctionEndTime,
     ,
     bool active
    ) = auction.getAuctionCore(_auctionId);

    // Cannot exit within 10% of the cooloffPeriod
    if(active || block.timestamp < auctionEndTime + cooloffPeriod * 10000 / 100000) {
      return (0, 0, amount);
    }

    (
      uint256 maltQuantity,
      uint256 newAmount
    ) = _getEarlyExitMaltQuantity(account, _auctionId, amount);

    if (maltQuantity == 0) {
      return (0, 0, newAmount);
    }

    // Reading direct from pool for this isn't bad as recovery
    // Mode avoids price being manipulated upwards
    (uint256 currentPrice,) = dexHandler.maltMarketPrice();
    require(currentPrice != 0, "Price should be more than zero");

    uint256 fullReturn = maltQuantity * currentPrice / pegPrice;

    // setCooloffPeriod guards against cooloffPeriod ever being 0
    uint256 progressionBps = (block.timestamp - auctionEndTime) * 10000 / cooloffPeriod;
    if (progressionBps > 10000) {
      progressionBps = 10000;
    }

    if (fullReturn > newAmount) {
      // Allow a % of profit to be realised
      // Add additional * 10,000 then / 10,000 to increase precision
      uint256 maxProfit = (fullReturn - newAmount) * (maxEarlyExitBps * 10000 * progressionBps / 10000) / 10000 / 10000;
      fullReturn = newAmount + maxProfit;
    }

    return (fullReturn, fullReturn * pegPrice / currentPrice, newAmount);
  }

  function accountEarlyExitReturns(address account) external view returns(
    uint256[] memory auctions,
    uint256[] memory earlyExitAmount
  ) {
    auctions = auction.getAccountCommitmentAuctions(account);
    uint256 length = auctions.length;

    earlyExitAmount = new uint256[](length);

    for (uint256 i; i < length; ++i) {
      (
        uint256 commitment,
        uint256 redeemed,
        ,
        uint256 exited
      ) = auction.getAuctionParticipationForAccount(account, auctions[i]);
      uint256 amount = commitment - redeemed - exited;
      (uint256 exitAmount,,) = earlyExitReturn(account, auctions[i], amount);
      earlyExitAmount[i] = exitAmount;
    }
  }

  function accountAuctionExits(address account, uint256 auctionId) external view returns (
    uint256 exitedEarly,
    uint256 earlyExitReturn,
    uint256 maltUsed
  ) {
    EarlyExitData storage accountExits = auctionEarlyExits[auctionId].accountExits[account];

    return (accountExits.exitedEarly, accountExits.earlyExitReturn, accountExits.maltUsed);
  }

  function globalAuctionExits(uint256 auctionId) external view returns (
    uint256 exitedEarly,
    uint256 earlyExitReturn,
    uint256 maltUsed
  ) {
    AuctionExits storage auctionExits = auctionEarlyExits[auctionId];

    return (auctionExits.exitedEarly, auctionExits.earlyExitReturn, auctionExits.maltUsed);
  }

  /*
   * INTERNAL METHODS
   */
  function _calculateMaltRequiredForExit(uint256 _auctionId, uint256 amount, uint256 exitedEarly) internal returns(uint256, uint256) {
  }

  function _getEarlyExitMaltQuantity(
    address account,
    uint256 _auctionId,
    uint256 amount
  )
    internal
    view returns (uint256 maltQuantity, uint256 newAmount)
  {
    (
      uint256 userCommitment,
      uint256 userRedeemed,
      uint256 userMaltPurchased,
      uint256 earlyExited
    ) = auction.getAuctionParticipationForAccount(account, _auctionId);

    uint256 exitedEarly = auctionEarlyExits[_auctionId].accountExits[account].exitedEarly;

    // This should never overflow due to guards in redemption code
    uint256 userOutstanding = userCommitment - userRedeemed - exitedEarly;

    if (amount > userOutstanding) {
      amount = userOutstanding;
    }

    if (amount == 0) {
      return (0, 0);
    }

    newAmount = amount;

    maltQuantity = userMaltPurchased * amount / userCommitment;
  }

  /*
   * PRIVILEDGED METHODS
   */
  function setEarlyExitBps(uint256 _earlyExitBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_earlyExitBps != 0 && _earlyExitBps <= 10000, "Must be between 0-100%");
    maxEarlyExitBps = _earlyExitBps;
    emit SetEarlyExitBps(_earlyExitBps);
  }

  function setCooloffPeriod(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_period != 0, "Cannot have 0 cool-off period");
    cooloffPeriod = _period;
    emit SetCooloffPeriod(_period);
  }

  function setDexHandler(address _handler)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    dexHandler = IDexHandler(_handler);
    emit SetDexHandler(_handler);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
pragma solidity >= 0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Permissions
/// @author 0xScotch <[email protected]>
/// @notice Inherited by almost all Malt contracts to provide access control
contract Permissions is AccessControl, ReentrancyGuard {
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  // Contract types
  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_NODE_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");
  bytes32 public constant REWARD_THROTTLE_ROLE = keccak256("REWARD_THROTTLE_ROLE");
  bytes32 public constant INTERNAL_WHITELIST_ROLE = keccak256("INTERNAL_WHITELIST_ROLE");

  address public proposedAdmin;
  address internal globalAdmin;

  event reassignGlobalAdminProposed(address newAdmin, address sender);
  event reassignGlobalAdminAccepted(address newAdmin);

  function _adminSetup(address _timelock) internal {
    require(_timelock != address(0), "Perm: Admin setup 0x0");
    _roleSetup(TIMELOCK_ROLE, _timelock);
    _roleSetup(ADMIN_ROLE, _timelock);
    _roleSetup(GOVERNOR_ROLE, _timelock);
    _roleSetup(STABILIZER_NODE_ROLE, _timelock);
    _roleSetup(LIQUIDITY_MINE_ROLE, _timelock);
    _roleSetup(AUCTION_ROLE, _timelock);
    _roleSetup(REWARD_THROTTLE_ROLE, _timelock);
    _roleSetup(INTERNAL_WHITELIST_ROLE, _timelock);

    globalAdmin = _timelock;
  }

  function assignRole(bytes32 role, address _assignee)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    _grantRole(role, _assignee);
  }

  function removeRole(bytes32 role, address _entity)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    revokeRole(role, _entity);
  }

  function grantRoleMultiple(bytes32 role, address[] calldata addresses)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    uint256 length = addresses.length;
    for (uint i; i < length; ++i) {
      address account = addresses[i];
      require(account != address(0), "0x0");
      _grantRole(role, account);
    }
  }

  function reassignGlobalAdmin(address _admin)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(_admin != address(0), "Perm: Reassign to 0x0");
    proposedAdmin = _admin;
    _grantRole(ADMIN_ROLE, proposedAdmin);
    emit reassignGlobalAdminProposed(_admin, msg.sender);
  }

  function acceptGlobalAdmin() external {
    require(proposedAdmin == msg.sender, "Perm: Not allowed to reassign");
    // give admin role to new admin so he can transfer roles from old admin
    _transferRole(proposedAdmin, globalAdmin, TIMELOCK_ROLE);
    _transferRole(proposedAdmin, globalAdmin, ADMIN_ROLE);
    _transferRole(proposedAdmin, globalAdmin, GOVERNOR_ROLE);
    _transferRole(proposedAdmin, globalAdmin, STABILIZER_NODE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, LIQUIDITY_MINE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, AUCTION_ROLE);
    _transferRole(proposedAdmin, globalAdmin, REWARD_THROTTLE_ROLE);

    globalAdmin = proposedAdmin;
    proposedAdmin = address(0x0);
    emit reassignGlobalAdminAccepted(globalAdmin);
  }

  function emergencyWithdrawGAS(address payable destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of the Gas token to destination
    (bool success, ) = destination.call{value: address(this).balance}('');
    require(success, "emergencyWithdrawGAS error");
  }

  function emergencyWithdraw(address _token, address destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    (bool success, ) = destination.call{value: amount}('');
    require(success, "partialWithdrawGAS error");
  }

  function partialWithdraw(address _token, address destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  /*
   * INTERNAL METHODS
   */
  function _transferRole(address newAccount, address oldAccount, bytes32 role) internal {
    revokeRole(role, oldAccount);
    _grantRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _grantRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRoleMalt(bytes32 role, string memory reason) internal view {
    require(
      hasRole(
        role,
        _msgSender()
      ),
      reason
    );
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRoleMalt(bytes32 role, string memory reason) {
    _onlyRoleMalt(role, reason);
    _;
  }

  // verifies that the caller is not a contract.
  modifier onlyEOA() {
    require(hasRole(INTERNAL_WHITELIST_ROLE, _msgSender()) || msg.sender == tx.origin, "Perm: Only EOA");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IAuction {
  function replenishingAuctionId() external view returns(uint256);
  function currentAuctionId() external view returns(uint256);
  function purchaseArbitrageTokens(uint256 amount) external;
  function claimArbitrage(uint256 _auctionId) external;
  function isAuctionFinished(uint256 _id) external view returns(bool);
  function auctionActive(uint256 _id) external view returns (bool);
  function isAuctionFinalized(uint256 _id) external view returns (bool);
  function userClaimableArbTokens(
    address account,
    uint256 auctionId
  ) external view returns (uint256);
  function balanceOfArbTokens(
    uint256 _auctionId,
    address account
  ) external view returns (uint256);
  function averageMaltPrice(uint256 _id) external view returns (uint256);
  function currentPrice(uint256 _id) external view returns (uint256);
  function getAuctionCommitments(uint256 _id) external view returns (uint256 commitments, uint256 maxCommitments);
  function getAuctionPrices(uint256 _id) external view returns (uint256 startingPrice, uint256 endingPrice, uint256 finalPrice);
  function auctionExists(uint256 _id) external view returns (bool);
  function getAccountCommitments(address account) external view returns (
    uint256[] memory auctions,
    uint256[] memory commitments,
    uint256[] memory awardedTokens,
    uint256[] memory redeemedTokens,
    uint256[] memory finalPrice,
    uint256[] memory claimable,
    uint256[] memory exitedTokens,
    bool[] memory finished
  );
  function getAccountCommitmentAuctions(address account) external view returns (uint[] memory);
  function hasOngoingAuction() external view returns (bool);
  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  );
  function getAuction(uint256 _id) external view returns (
    uint256 maxCommitments,
    uint256 commitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  );
  function getAuctionCore(uint256 _id) external view returns (
    uint256 auctionId,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 preAuctionReserveRatio,
    bool active
  );
  function checkAuctionFinalization() external;
  function allocateArbRewards(uint256 rewarded) external returns (uint256);
  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount) external;
  function getAuctionParticipationForAccount(address account, uint256 auctionId) external view returns(uint256, uint256, uint256, uint256);
  function accountExit(address account, uint256 auctionId, uint256 amount) external;
  function endAuctionEarly() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDexHandler {
  function buyMalt(uint256, uint256) external returns (uint256 purchased);
  function sellMalt(uint256, uint256) external returns (uint256 rewards);
  function addLiquidity(uint256, uint256, uint256) external returns (
    uint256 maltUsed,
    uint256 rewardUsed,
    uint256 liquidityCreated
  );
  function removeLiquidity(uint256, uint256) external returns (uint256 amountMalt, uint256 amountReward);
  function calculateMintingTradeSize(uint256 priceTarget) external view returns (uint256);
  function calculateBurningTradeSize(uint256 priceTarget) external view returns (uint256);
  function reserves() external view returns (uint256 maltSupply, uint256 rewardSupply);
  function maltMarketPrice() external view returns (uint256 price, uint256 decimals);
  function getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB)
    external view returns (uint256 liquidityA);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBurnMintableERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Permissions.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IBurnMintableERC20.sol";
import "./interfaces/IMaltDataLab.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/ILiquidityExtension.sol";
import "./interfaces/IImpliedCollateralService.sol";
import "./interfaces/IAuctionBurnReserveSkew.sol";
import "./interfaces/IAuctionStartController.sol";
import "./interfaces/IRewardMine.sol";


struct AccountCommitment {
  uint256 commitment;
  uint256 redeemed;
  uint256 maltPurchased;
  uint256 exited;
}

struct AuctionData {
  // The full amount of commitments required to return to peg
  uint256 fullRequirement;
  // total maximum desired commitments to this auction
  uint256 maxCommitments;
  // Quantity of sale currency committed to this auction
  uint256 commitments;
  // Quantity of commitments that have been exited early
  uint256 exited;
  // Malt purchased and burned using current commitments
  uint256 maltPurchased;
  // Desired starting price for the auction
  uint256 startingPrice;
  // Desired lowest price for the arbitrage token
  uint256 endingPrice;
  // Price of arbitrage tokens at conclusion of auction. This is either
  // when the duration elapses or the maxCommitments is reached
  uint256 finalPrice;
  // The peg price for the liquidity pool
  uint256 pegPrice;
  // Time when auction started
  uint256 startingTime;
  uint256 endingTime;
  // Is the auction currently accepting commitments?
  bool active;
  // The reserve ratio at the start of the auction
  uint256 preAuctionReserveRatio;
  // Has this auction been finalized? Meaning any additional stabilizing
  // has been done
  bool finalized;
  // The amount of arb tokens that have been executed and are now claimable
  uint256 claimableTokens;
  // The finally calculated realBurnBudget
  uint256 finalBurnBudget;
  // The amount of Malt purchased with realBurnBudget
  uint256 finalPurchased;
  // A map of all commitments to this auction by specific accounts
  mapping(address => AccountCommitment) accountCommitments;
}


/// @title Malt Arbitrage Auction
/// @author 0xScotch <[email protected]>
/// @notice The under peg Malt mechanism of dutch arbitrage auctions is implemented here
contract Auction is Permissions {
  using SafeERC20 for ERC20;

  bytes32 public constant AUCTION_AMENDER_ROLE = keccak256("AUCTION_AMENDER_ROLE");

  address public stabilizerNode;
  address public amender;
  IMaltDataLab public maltDataLab;
  ERC20 public collateralToken;
  IBurnMintableERC20 public malt;
  IDexHandler public dexHandler;
  ILiquidityExtension public liquidityExtension;
  IImpliedCollateralService public impliedCollateralService;
  IAuctionBurnReserveSkew public auctionBurnReserveSkew;
  IRewardMine public auctionPool;

  uint256 public unclaimedArbTokens;
  uint256 public replenishingAuctionId;
  uint256 public currentAuctionId;
  uint256 public claimableArbitrageRewards;
  uint256 public nextCommitmentId;
  uint256 public auctionLength = 600; // 10 minutes
  uint256 public arbTokenReplenishSplitBps = 7000; // 70%
  uint256 public maxAuctionEndBps = 9000; // 90% of target price
  uint256 public auctionEndReserveBps = 9000; // 90% of collateral
  uint256 public priceLookback = 0;
  uint256 public reserveRatioLookback = 30; // 30 seconds
  uint256 public dustThreshold = 1e15;
  uint256 public earlyEndThreshold;
  uint256 public costBufferBps = 1000;

  address public auctionStartController;

  mapping (uint256 => AuctionData) internal idToAuction;
  mapping(address => uint256[]) internal accountCommitmentEpochs;

  event AuctionCommitment(
    uint256 commitmentId,
    uint256 auctionId,
    address indexed account,
    uint256 commitment,
    uint256 purchased
  );

  event ClaimArbTokens(
    uint256 auctionId,
    address indexed account,
    uint256 amountTokens
  );

  event AuctionEnded(
    uint256 id,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 maltPurchased
  );

  event AuctionStarted(
    uint256 id,
    uint256 maxCommitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 startingTime,
    uint256 endingTime
  );

  event ArbTokenAllocation(
    uint256 replenishingAuctionId,
    uint256 maxArbAllocation
  );

  event SetAuctionLength(uint256 length);
  event SetStabilizerNode(address stabilizerNode);
  event SetMaltDataLab(address dataLab);
  event SetAuctionEndReserveBps(uint256 bps);
  event SetDustThreshold(uint256 threshold);
  event SetReserveRatioLookback(uint256 lookback);
  event SetPriceLookback(uint256 lookback);
  event SetMaxAuctionEnd(uint256 maxEnd);
  event SetTokenReplenishSplit(uint256 split);
  event SetAuctionStartController(address controller);
  event SetImpliedCollateralService(address impliedCollateralService);
  event SetLiquidityExtension(address liquidityExtension);
  event SetDexHandler(address handler);
  event SetAuctionReplenishId(uint256 id);
  event SetEarlyEndThreshold(uint256 threshold);
  event SetCostBufferBps(uint256 costBuffer);

  constructor(
    address _timelock,
    address initialAdmin,
    address _collateralToken,
    address _malt,
    uint256 _auctionLength,
    address _stabilizerNode,
    address _maltDataLab,
    address _dexHandler,
    uint256 _earlyEndThreshold
  ) {
    require(_timelock != address(0), "Auction: Timelock addr(0)");
    require(initialAdmin != address(0), "Auction: Admin addr(0)");
    require(_collateralToken != address(0), "Auction: ColToken addr(0)");
    require(_malt != address(0), "Auction: Malt addr(0)");
    require(_stabilizerNode != address(0), "Auction: StabNode addr(0)");
    require(_maltDataLab != address(0), "Auction: DataLab addr(0)");
    require(_dexHandler != address(0), "Auction: DexHandler addr(0)");
    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    auctionLength = _auctionLength;
    stabilizerNode = _stabilizerNode;
    maltDataLab = IMaltDataLab(_maltDataLab);
    dexHandler = IDexHandler(_dexHandler);
    earlyEndThreshold = _earlyEndThreshold;
  }

  function setupContracts(
    address _liquidityExtension,
    address _impliedCollateralService,
    address _auctionBurnReserveSkew,
    address _amender,
    address _auctionPool
  )
    external
    onlyRoleMalt(ADMIN_ROLE, "Must be admin")
  {
    require(address(liquidityExtension) == address(0), "Auction: Already setup");
    require(_liquidityExtension != address(0), "Auction: LE addr(0)");
    require(_impliedCollateralService != address(0), "Auction: ColSvc addr(0)");
    require(_auctionBurnReserveSkew != address(0), "Auction: BurnSkew addr(0)");
    require(_amender != address(0), "Auction: Amender addr(0)");
    require(_auctionPool != address(0), "Auction: AuctionPool addr(0)");

    _roleSetup(AUCTION_AMENDER_ROLE, _amender);

    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    amender = _amender;
    auctionPool = IRewardMine(_auctionPool);
  }

  /*
   * PUBLIC METHODS
   */
  function purchaseArbitrageTokens(uint256 amount) external nonReentrant {
    uint256 currentAuction = currentAuctionId;
    require(auctionActive(currentAuction), "No auction running");
    require(amount != 0, "purchaseArb: 0 amount");

    uint256 oldBalance = collateralToken.balanceOf(address(liquidityExtension));

    collateralToken.safeTransferFrom(msg.sender, address(liquidityExtension), amount);

    uint256 realAmount = collateralToken.balanceOf(address(liquidityExtension)) - oldBalance;
    require(realAmount <= amount, "Invalid amount");

    uint256 realCommitment = _capCommitment(currentAuction, realAmount);

    if (realCommitment == 0) {
      return;
    }

    uint256 purchased = liquidityExtension.purchaseAndBurn(realCommitment);

    AuctionData storage auction = idToAuction[currentAuction];

    require(auction.startingTime <= block.timestamp, "Auction hasn't started yet");
    require(auction.endingTime > block.timestamp, "Auction is already over");
    require(auction.active == true, "Auction is not active");

    auction.commitments = auction.commitments + realCommitment;

    if (auction.accountCommitments[msg.sender].commitment == 0) {
      accountCommitmentEpochs[msg.sender].push(currentAuction);
    }
    auction.accountCommitments[msg.sender].commitment = auction.accountCommitments[msg.sender].commitment + realCommitment;
    auction.accountCommitments[msg.sender].maltPurchased = auction.accountCommitments[msg.sender].maltPurchased + purchased;
    auction.maltPurchased = auction.maltPurchased + purchased;

    emit AuctionCommitment(
      nextCommitmentId,
      currentAuction,
      msg.sender,
      realCommitment,
      purchased
    );

    nextCommitmentId = nextCommitmentId + 1;

    if (auction.commitments + auction.pegPrice >= auction.maxCommitments) {
      _endAuction(currentAuction) ;
    }
  }

  function claimArbitrage(uint256 _auctionId) external nonReentrant {
    uint256 amountTokens = userClaimableArbTokens(msg.sender, _auctionId);

    require(amountTokens > 0, "No claimable Arb tokens");

    AuctionData storage auction = idToAuction[_auctionId];

    require(!auction.active, "Cannot claim tokens on an active auction");

    AccountCommitment storage commitment = auction.accountCommitments[msg.sender];

    uint256 redemption = amountTokens * auction.finalPrice / auction.pegPrice;
    uint256 remaining = commitment.commitment - commitment.redeemed - commitment.exited;

    if (redemption > remaining) {
      redemption = remaining;
    }

    commitment.redeemed = commitment.redeemed + redemption;

    // Unclaimed represents total outstanding, but not necessarily
    // claimable yet.
    // claimableArbitrageRewards represents total amount that is now
    // available to be claimed
    if (amountTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountTokens;
    }

    if (amountTokens > claimableArbitrageRewards) {
      claimableArbitrageRewards = 0;
    } else {
      claimableArbitrageRewards = claimableArbitrageRewards - amountTokens;
    }

    uint256 totalBalance = collateralToken.balanceOf(address(this));
    if (amountTokens + dustThreshold >= totalBalance) {
      amountTokens = totalBalance;
    }

    collateralToken.safeTransfer(msg.sender, amountTokens);

    emit ClaimArbTokens(
      _auctionId,
      msg.sender,
      amountTokens
    );
  }

  function endAuctionEarly() external {
    uint256 currentId = currentAuctionId;
    AuctionData storage auction = idToAuction[currentId];
    require(auction.active && block.timestamp >= auction.startingTime, "No auction running");
    require(auction.commitments >= (auction.maxCommitments - earlyEndThreshold), "Too early to end");

    _endAuction(currentId);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function isAuctionFinished(uint256 _id) public view returns(bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.endingTime > 0 && (block.timestamp >= auction.endingTime || auction.finalPrice > 0 || auction.commitments + auction.pegPrice >= auction.maxCommitments);
  }

  function auctionActive(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.active && block.timestamp >= auction.startingTime;
  }

  function isAuctionFinalized(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];
    return auction.finalized;
  }

  function userClaimableArbTokens(
    address account,
    uint256 auctionId
  ) public view returns (uint256) {
    AuctionData storage auction = idToAuction[auctionId];

    if (auction.claimableTokens == 0 || auction.finalPrice == 0 || auction.commitments == 0) {
      return 0;
    }

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 totalTokens = auction.commitments * auction.pegPrice / auction.finalPrice;

    uint256 claimablePerc = auction.claimableTokens * auction.pegPrice / totalTokens;

    uint256 amountTokens = commitment.commitment * auction.pegPrice / auction.finalPrice;
    uint256 redeemedTokens = commitment.redeemed * auction.pegPrice / auction.finalPrice;
    uint256 exitedTokens = commitment.exited * auction.pegPrice / auction.finalPrice;

    uint256 amountOut = (amountTokens * claimablePerc / auction.pegPrice) - redeemedTokens - exitedTokens;

    // Avoid leaving dust behind
    if (amountOut < dustThreshold) {
      return 0;
    }

    return amountOut;
  }

  function balanceOfArbTokens(
    uint256 _auctionId,
    address account
  ) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_auctionId];

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 remaining = commitment.commitment - commitment.redeemed - commitment.exited;

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(_auctionId);
    }

    return remaining * auction.pegPrice / price;
  }

  function averageMaltPrice(uint256 _id) external view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.maltPurchased == 0) {
      return 0;
    }

    return auction.commitments * auction.pegPrice / auction.maltPurchased;
  }

  function currentPrice(uint256 _id) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.startingTime == 0) {
      return maltDataLab.priceTarget();
    }

    uint256 secondsSinceStart = 0;

    if (block.timestamp > auction.startingTime) {
      secondsSinceStart = block.timestamp - auction.startingTime;
    }

    uint256 auctionDuration = auction.endingTime - auction.startingTime;

    if (secondsSinceStart >= auctionDuration) {
      return auction.endingPrice;
    }

    uint256 totalPriceDelta = auction.startingPrice - auction.endingPrice;

    uint256 currentPriceDelta = totalPriceDelta * secondsSinceStart / auctionDuration;

    return auction.startingPrice - currentPriceDelta;
  }

  function getAuctionCommitments(uint256 _id) public view returns (uint256 commitments, uint256 maxCommitments) {
    AuctionData storage auction = idToAuction[_id];

    return (auction.commitments, auction.maxCommitments);
  }

  function getAuctionPrices(uint256 _id) public view returns (uint256 startingPrice, uint256 endingPrice, uint256 finalPrice) {
    AuctionData storage auction = idToAuction[_id];

    return (auction.startingPrice, auction.endingPrice, auction.finalPrice);
  }

  function auctionExists(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.startingTime > 0;
  }

  function getAccountCommitments(address account) external view returns (
    uint256[] memory auctions,
    uint256[] memory commitments,
    uint256[] memory awardedTokens,
    uint256[] memory redeemedTokens,
    uint256[] memory exitedTokens,
    uint256[] memory finalPrice,
    uint256[] memory claimable,
    bool[] memory finished
  ) {
    uint256[] memory epochCommitments = accountCommitmentEpochs[account];

    auctions = new uint256[](epochCommitments.length);
    commitments = new uint256[](epochCommitments.length);
    awardedTokens = new uint256[](epochCommitments.length);
    redeemedTokens = new uint256[](epochCommitments.length);
    exitedTokens = new uint256[](epochCommitments.length);
    finalPrice = new uint256[](epochCommitments.length);
    claimable = new uint256[](epochCommitments.length);
    finished = new bool[](epochCommitments.length);

    for (uint i = 0; i < epochCommitments.length; ++i) {
      AuctionData storage auction = idToAuction[epochCommitments[i]];

      AccountCommitment storage commitment = auction.accountCommitments[account];

      uint256 price = auction.finalPrice;

      if (auction.finalPrice == 0) {
        price = currentPrice(epochCommitments[i]);
      }

      auctions[i] = epochCommitments[i];
      commitments[i] = commitment.commitment;
      awardedTokens[i] = commitment.commitment * auction.pegPrice / price;
      redeemedTokens[i] = commitment.redeemed * auction.pegPrice / price;
      exitedTokens[i] = commitment.exited * auction.pegPrice / price;
      finalPrice[i] = price;
      claimable[i] = userClaimableArbTokens(account, epochCommitments[i]);
      finished[i] = isAuctionFinished(epochCommitments[i]);
    }
  }

  function getAccountCommitmentAuctions(address account) external view returns (uint256[] memory) {
    return accountCommitmentEpochs[account];
  }

  function getAuctionParticipationForAccount(address account, uint256 auctionId) external view returns (
    uint256 commitment,
    uint256 redeemed,
    uint256 maltPurchased,
    uint256 exited
  ) {
    AccountCommitment storage _commitment = idToAuction[auctionId].accountCommitments[account];

    return (_commitment.commitment, _commitment.redeemed, _commitment.maltPurchased, _commitment.exited);
  }

  function hasOngoingAuction() external view returns (bool) {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return auction.startingTime > 0 && !auction.finalized;
  }

  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  ) {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return (
      currentAuctionId,
      auction.maxCommitments,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.finalPurchased
    );
  }

  function getAuction(uint256 _id) public view returns (
    uint256 fullRequirement,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased,
    uint256 exited
  ) {
    AuctionData storage auction = idToAuction[_id];

    return (
      auction.fullRequirement,
      auction.maxCommitments,
      auction.commitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.finalPurchased,
      auction.exited
    );
  }

  function getAuctionCore(uint256 _id) public view returns (
    uint256 auctionId,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 preAuctionReserveRatio,
    bool active
  ) {
    AuctionData storage auction = idToAuction[_id];

    return (
      _id,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.preAuctionReserveRatio,
      auction.active
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _triggerAuction(
    uint256 pegPrice,
    uint256 rRatio,
    uint256 purchaseAmount
  ) internal {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController).checkForStart();
      if (!success) {
        return;
      }
    }
    uint256 _auctionIndex = currentAuctionId;

    (uint256 startingPrice, uint256 endingPrice) = _calculateAuctionPricing(rRatio, purchaseAmount);

    AuctionData storage auction = idToAuction[_auctionIndex];

    auction.fullRequirement = purchaseAmount; // fullRequirement
    auction.maxCommitments = purchaseAmount; // maxCommitments
    auction.startingPrice = startingPrice;
    auction.endingPrice = endingPrice;
    auction.pegPrice = pegPrice;
    auction.startingTime = block.timestamp; // startingTime
    auction.endingTime = block.timestamp + auctionLength; // endingTime
    auction.active = true; // active
    auction.preAuctionReserveRatio = rRatio; // preAuctionReserveRatio
    auction.finalized = false; // finalized

    require(auction.endingTime == uint256(uint64(auction.endingTime)), "ending not eq");

    emit AuctionStarted(
      _auctionIndex,
      auction.maxCommitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.startingTime,
      auction.endingTime
    );
  }

  function _capCommitment(uint256 _id, uint256 _commitment) internal view returns (uint256 realCommitment) {
    AuctionData storage auction = idToAuction[_id];

    realCommitment = _commitment;

    if (auction.commitments + _commitment >= auction.maxCommitments) {
      realCommitment = auction.maxCommitments - auction.commitments;
    }
  }

  function _endAuction(uint256 _id) internal {
    AuctionData storage auction = idToAuction[_id];

    require(auction.active == true, "Auction is already over");

    auction.active = false;
    auction.finalPrice = currentPrice(_id);

    uint256 amountArbTokens = auction.commitments * auction.pegPrice / auction.finalPrice;
    unclaimedArbTokens = unclaimedArbTokens + amountArbTokens;
    auctionPool.declareReward(amountArbTokens);

    emit AuctionEnded(
      _id,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.maltPurchased
    );
  }

  function _finalizeAuction(uint256 auctionId) internal {
    (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    ) = _setupAuctionFinalization(auctionId);

    if (commitments >= fullRequirement) {
      return;
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    // priceTarget - preAuctionReserveRatio represents maximum deficit per token
    // priceTarget divided by the max deficit is equivalent to 1 over the max deficit given we are in uint decimal
    // (commitments * 1/maxDeficit) - commitments
    uint256 maxBurnSpend = (commitments * priceTarget) / (priceTarget - preAuctionReserveRatio) - commitments;

    uint256 totalTokens = commitments * priceTarget / finalPrice;

    uint256 premiumExcess = 0;

    // The assumption here is that each token will be worth 1 Malt when redeemed.
    // Therefore if totalTokens is greater than the malt purchased then there is a net supply growth
    // After the tokens are repaid. We want this process to be neutral to supply at the very worst.
    if (totalTokens > maltPurchased) {
      // This also assumes current purchase price of Malt is $1, which is higher than it will be in practice.
      // So the premium excess will actually ensure slight net negative supply growth.
      premiumExcess = totalTokens - maltPurchased;
    }

    uint256 realBurnBudget = auctionBurnReserveSkew.getRealBurnBudget(maxBurnSpend, premiumExcess);

    if (realBurnBudget > 0) {
      AuctionData storage auction = idToAuction[auctionId];

      auction.finalBurnBudget = realBurnBudget;
      auction.finalPurchased = liquidityExtension.purchaseAndBurn(realBurnBudget);
    }
    maltDataLab.trackPool();
  }

  function _setupAuctionFinalization(uint256 auctionId)
    internal
    returns (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    )
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.startingTime > 0, "No auction available for the given id");

    auction.finalized = true;

    if (auction.maltPurchased > 0) {
      avgMaltPrice = auction.commitments * auction.pegPrice / auction.maltPurchased;
    }

    return (
      avgMaltPrice,
      auction.commitments,
      auction.fullRequirement,
      auction.maltPurchased,
      auction.finalPrice,
      auction.preAuctionReserveRatio
    );
  }

  function _calcRealMaxRaise(uint256 purchaseAmount, uint256 rRatio, uint256 decimals) internal pure returns (uint256) {
    uint256 unity = 10**decimals;
    uint256 realBurn = purchaseAmount * Math.min(rRatio, unity) / unity;

    return purchaseAmount - realBurn;
  }

  function _calculateAuctionPricing(uint256 rRatio, uint256 maxCommitments) internal view returns (
    uint256 startingPrice,
    uint256 endingPrice
  ) {
    uint256 priceTarget = maltDataLab.priceTarget();
    if (rRatio > priceTarget) {
      rRatio = priceTarget;
    }
    startingPrice = maltDataLab.maltPriceAverage(priceLookback);
    uint256 liquidityExtensionBalance = collateralToken.balanceOf(address(liquidityExtension));

    (uint256 latestPrice,) = maltDataLab.lastMaltPrice();
    uint256 expectedMaltCost = priceTarget;
    if (latestPrice < priceTarget) {
      expectedMaltCost = latestPrice + (priceTarget - latestPrice) * (5000 + costBufferBps) / 10000;
    }

    // rRatio should never be large enough for this to overflow
    // uint256 absoluteBottom = rRatio * auctionEndReserveBps / 10000;

    // Absolute bottom is the lowest price
    uint256 decimals = collateralToken.decimals();
    uint256 unity = 10**decimals;
    uint256 absoluteBottom = maxCommitments * unity / (liquidityExtensionBalance + (maxCommitments * unity / expectedMaltCost));

    uint256 idealBottom = 1; // 1wei just to avoid any issues with it being 0

    if (expectedMaltCost > rRatio) {
      idealBottom = expectedMaltCost - rRatio;
    }

    // price should never go below absoluteBottom
    if (idealBottom < absoluteBottom) {
      idealBottom = absoluteBottom;
    }

    // price should never start above the peg price
    if (startingPrice > priceTarget) {
      startingPrice = priceTarget;
    }

    if (idealBottom < startingPrice) {
      endingPrice = idealBottom;
    } else if (absoluteBottom < startingPrice){
      endingPrice = absoluteBottom;
    } else {
      // There are no bottom prices that work with
      // the startingPrice so set start and end to
      // the absoluteBottom
      startingPrice = absoluteBottom;
      endingPrice = absoluteBottom;
    }

    // priceTarget should never be large enough to overflow here
    uint256 maxPrice = priceTarget * maxAuctionEndBps / 10000;

    if (endingPrice > maxPrice && maxPrice > absoluteBottom) {
      endingPrice = maxPrice;
    }
  }

  function _checkAuctionFinalization(bool isInternal) internal {
    uint256 currentAuction = currentAuctionId;
    if (isInternal && !isAuctionFinished(currentAuction)) {
      // Auction is still in progress after internal auction purchasing.
      _resetAuctionMaxCommitments();
    }

    if (isAuctionFinished(currentAuction)) {
      if (auctionActive(currentAuction)) {
        _endAuction(currentAuction);
      }

      if (!isAuctionFinalized(currentAuction)) {
        _finalizeAuction(currentAuction);
      }
      currentAuctionId = currentAuction + 1;
    }
  }

  function _resetAuctionMaxCommitments() internal {
    AuctionData storage auction = idToAuction[currentAuctionId];

    uint256 decimals = collateralToken.decimals();

    uint256 realMaxRaise = _calcRealMaxRaise(auction.fullRequirement, auction.preAuctionReserveRatio, decimals);

    if (auction.commitments <= realMaxRaise) {
      auction.maxCommitments = realMaxRaise;
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function checkAuctionFinalization()
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
  {
    _checkAuctionFinalization(false);
  }

  function accountExit(address account, uint256 auctionId, uint256 amount)
    external
    onlyRoleMalt(AUCTION_AMENDER_ROLE, "Only auction amender")
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.accountCommitments[account].commitment >= amount, "amend: amount underflows");

    if (auction.finalPrice == 0) {
      return;
    }

    auction.exited += amount;
    auction.accountCommitments[account].exited += amount;

    uint256 amountArbTokens = amount * auction.pegPrice / auction.finalPrice;

    if (amountArbTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountArbTokens;
    }
  }

  function allocateArbRewards(uint256 rewarded)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[replenishingAuctionId];

    if (auction.finalPrice == 0 || auction.startingTime == 0) {
      return rewarded;
    }

    if (auction.commitments == 0) {
      replenishingAuctionId = replenishingAuctionId + 1;
      return rewarded;
    }

    uint256 totalTokens = auction.commitments * auction.pegPrice / auction.finalPrice;

    if (auction.claimableTokens < totalTokens) {
      uint256 requirement = totalTokens - auction.claimableTokens;
      uint256 maxArbAllocation = rewarded * arbTokenReplenishSplitBps / 10000;

      if (requirement >= maxArbAllocation) {
        auction.claimableTokens = auction.claimableTokens + maxArbAllocation;
        rewarded = rewarded - maxArbAllocation;
        claimableArbitrageRewards = claimableArbitrageRewards + maxArbAllocation;

        collateralToken.safeTransferFrom(stabilizerNode, address(this), maxArbAllocation);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          maxArbAllocation
        );
      } else {
        auction.claimableTokens = auction.claimableTokens + requirement;
        rewarded = rewarded - requirement;
        claimableArbitrageRewards = claimableArbitrageRewards + requirement;

        collateralToken.safeTransferFrom(stabilizerNode, address(this), requirement);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          requirement
        );
      }

      if (auction.claimableTokens == totalTokens) {
        uint256 count = 1;

        // Break at 10 to avoid unbounded loops
        while (count < 10) {
          auction = idToAuction[replenishingAuctionId + count];

          if (auction.commitments > 0 || !auction.finalized) {
            break;
          }
          count += 1;
        }
        replenishingAuctionId = replenishingAuctionId + count;
      }
    }

    return rewarded;
  }

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
  {
    if (purchaseAmount == 0 || auctionExists(currentAuctionId)) {
      return;
    }

    // Data is consistent here as this method as the stabilizer
    // calls maltDataLab.trackPool at the start of stabilize
    (uint256 rRatio,) = liquidityExtension.reserveRatioAverage(reserveRatioLookback);

    _triggerAuction(pegPrice, rRatio, purchaseAmount);

    impliedCollateralService.handleDeficit(purchaseAmount);

    _checkAuctionFinalization(true);
  }

  function setAuctionLength(uint256 _length)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_length > 0, "Length must be larger than 0");
    auctionLength = _length;
    emit SetAuctionLength(_length);
  }

  function setStabilizerNode(address _stabilizerNode)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    _transferRole(_stabilizerNode, stabilizerNode, STABILIZER_NODE_ROLE);
    stabilizerNode = _stabilizerNode;
    emit SetStabilizerNode(_stabilizerNode);
  }

  function setMaltDataLab(address _dataLab)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    maltDataLab = IMaltDataLab(_dataLab);
    emit SetMaltDataLab(_dataLab);
  }

  function setAuctionReplenishId(uint256 _id)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    replenishingAuctionId = _id;
    emit SetAuctionReplenishId(_id);
  }

  function setDexHandler(address _handler)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    dexHandler = IDexHandler(_handler);
    emit SetDexHandler(_handler);
  }

  function setLiquidityExtension(address _liquidityExtension)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    emit SetLiquidityExtension(_liquidityExtension);
  }

  function setImpliedCollateralService(address _impliedCollateralService)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    emit SetImpliedCollateralService(_impliedCollateralService);
  }

  function setAuctionBurnReserveSkew(address _reserveSkew)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_reserveSkew);
  }

  function setAuctionAmender(address _amender)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_amender != address(0), "Cannot set 0 address");
    _transferRole(_amender, amender, AUCTION_AMENDER_ROLE);
    amender = _amender;
  }

  function setAuctionPool(address _auctionPool)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_auctionPool != address(0), "Cannot set 0 address");
    auctionPool = IRewardMine(_auctionPool);
  }

  function setAuctionStartController(address _controller)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setTokenReplenishSplit(uint256 _split)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_split != 0 && _split <= 10000, "Must be between 0-100%");
    arbTokenReplenishSplitBps = _split;
    emit SetTokenReplenishSplit(_split);
  }

  function setMaxAuctionEnd(uint256 _maxEnd)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_maxEnd != 0 && _maxEnd <= 10000, "Must be between 0-100%");
    maxAuctionEndBps = _maxEnd;
    emit SetMaxAuctionEnd(_maxEnd);
  }

  function setPriceLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    priceLookback = _lookback;
    emit SetPriceLookback(_lookback);
  }

  function setReserveRatioLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    reserveRatioLookback = _lookback;
    emit SetReserveRatioLookback(_lookback);
  }

  function setAuctionEndReserveBps(uint256 _bps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_bps != 0 && _bps < 10000, "Must be between 0-100%");
    auctionEndReserveBps = _bps;
    emit SetAuctionEndReserveBps(_bps);
  }

  function setDustThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    dustThreshold = _threshold;
    emit SetDustThreshold(_threshold);
  }

  function setEarlyEndThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    earlyEndThreshold = _threshold;
    emit SetEarlyEndThreshold(_threshold);
  }

  function setCostBufferBps(uint256 _costBuffer)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_costBuffer != 0 && _costBuffer <= 5000, "Must be > 0 && <= 5000");
    costBufferBps = _costBuffer;
    emit SetCostBufferBps(_costBuffer);
  }

  function adminEndAuction()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    uint256 currentId = currentAuctionId;
    require(auctionActive(currentId), "No auction running");
    _endAuction(currentId);
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
pragma solidity >=0.8.11;


interface IMaltDataLab {
  function priceTarget() external view returns (uint256);
  function smoothedMaltPrice() external view returns (uint256);
  function smoothedK() external view returns (uint256);
  function smoothedReserves() external view returns (uint256);
  function maltPriceAverage(uint256 _lookback) external view returns (uint256);
  function kAverage(uint256 _lookback) external view returns (uint256);
  function poolReservesAverage(uint256 _lookback) external view returns (uint256, uint256);
  function lastMaltPrice() external view returns (uint256, uint64);
  function lastPoolReserves() external view returns (uint256, uint256, uint64);
  function lastK() external view returns (uint256, uint64);
  function realValueOfLPToken(uint256 amount) external view returns (uint256);
  function trackPool() external;
  function trustedTrackPool(uint256, uint256, uint256) external;
  function rewardToken() external view returns(address);
  function malt() external view returns(address);
  function stakeToken() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface ILiquidityExtension {
  function hasMinimumReserves() external view returns (bool);
  function collateralDeficit() external view returns (uint256, uint256);
  function reserveRatio() external view returns (uint256, uint256);
  function reserveRatioAverage(uint256) external view returns (uint256, uint256);
  function purchaseAndBurn(uint256 amount) external returns (uint256 purchased);
  function buyBack(uint256 maltAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IImpliedCollateralService {
  function handleDeficit(uint256 maxAmount) external;
  function claim() external;
  function getCollateralValueInMalt() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IAuctionBurnReserveSkew {
  function consult(uint256 excess) external view returns (uint256);
  function getAverageParticipation() external view;
  function getPegDeltaFrequency() external view;
  function addAbovePegObservation(uint256 amount) external;
  function addBelowPegObservation(uint256 amount) external;
  function setNewStabilizerNode() external;
  function removeStabilizerNode() external;
  function getRealBurnBudget(
    uint256 maxBurnSpend,
    uint256 premiumExcess
  ) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IAuctionStartController {
  function checkForStart() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IRewardMine {
  function rewardToken() external view returns (address);
  function onBond(address account, uint256 amount) external;
  function onUnbond(address account, uint256 amount) external;
  function withdrawAll() external;
  function withdraw(uint256 rewardAmount) external;
  function totalBonded() external view returns (uint256);
  function balanceOfBonded(address account) external view returns (uint256);
  function totalDeclaredReward() external view returns (uint256);
  function totalReleasedReward() external view returns (uint256);
  function totalStakePadding() external view returns(uint256);
  function balanceOfStakePadding(address account) external view returns (uint256);
  function getRewardOwnershipFraction(address account) external view returns(uint256 numerator, uint256 denominator);
  function balanceOfRewards(address account) external view returns (uint256);
  function netRewardBalance(address account) external view returns (uint256);
  function earned(address account) external view returns (uint256 earnedReward);
  function withdrawForAccount(address account, uint256 amount, address to) external returns (uint256);
  function declareReward(uint256 amount) external;
  function releaseReward(uint256) external;
}