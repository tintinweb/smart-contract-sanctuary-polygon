/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// File: contracts/contracts/interfaces/other/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

// File: contracts/contracts/libraries/SafeMath.sol


pragma solidity 0.8.9;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/contracts/libraries/Address.sol


pragma solidity 0.8.9;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// File: contracts/contracts/libraries/SafeERC20.sol


pragma solidity 0.8.9;



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
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// File: contracts/contracts/interfaces/aave/IWETHGateway.sol


pragma solidity 0.8.9;

interface IWETHGateway {

  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param pool address of the targeted underlying pool
   * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositETH(
    address pool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param pool address of the targeted underlying pool
   * @param amount amount of aWETH to withdraw and receive native ETH
   * @param onBehalfOf address of the user who will receive native ETH
   */
  function withdrawETH(
    address pool,
    uint256 amount,
    address onBehalfOf
  ) external;

  /**
   * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
   * @param pool address of the targeted underlying pool
   * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
   * @param rateMode the rate mode to repay
   * @param onBehalfOf the address for which msg.sender is repaying
   */
  function repayETH(
    address pool,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external payable;

  /**
   * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `Pool.borrow`.
   * @param pool address of the targeted underlying pool
   * @param amount the amount of ETH to borrow
   * @param interesRateMode the interest rate mode
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards
   */
  function borrowETH(
    address pool,
    uint256 amount,
    uint256 interesRateMode,
    uint16 referralCode
  ) external;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param pool address of the targeted underlying pool
   * @param amount amount of aWETH to withdraw and receive native ETH
   * @param to address of the user who will receive native ETH
   * @param deadline validity deadline of permit and so depositWithPermit signature
   * @param permitV V parameter of ERC712 permit sig
   * @param permitR R parameter of ERC712 permit sig
   * @param permitS S parameter of ERC712 permit sig
   */
  function withdrawETHWithPermit(
    address pool,
    uint256 amount,
    address to,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;
  function getWETHAddress() external view returns (address);
}

// File: contracts/contracts/interfaces/protocol/IPremiumGenerator.sol


pragma solidity 0.8.9;

interface IPremiumGenerator {

    function deposit() external payable;
    function withdraw() external;
    function withdrawInterest() external returns(uint256);
    function getLendingPoolAddress() external view returns(address poolAddr);
    function getATokenAddress() external view returns(address aTokenAddress);
    function getUnclaimedInterest() external view returns (uint256);
    function getATokenBalance() external view returns (uint256);
    function getReserveNormalizedIncome() external view returns(uint256);
    function getAaveLiquidityIndex() external view returns(uint256 liquidityIndex);

    function setPremiumDeposit(uint _premiumDeposit) external;
    function getClaimedInterest() external view returns (uint256);
    function isBeneficiary(address beneficiary) external view returns(bool);

    /**
    * @notice Returns asset specific pool information
    * @return reserve address of reserve
    * @return interestWithdrawn amount of interest withdrawn
    * @return deposits amount of ETH/WETH deposited in contract
    * @return premiumDeposit amount of ETH required for a deposit
    * @return liquidityIndex reserve's liquidity index
    * @return normalizedIncome reserve's normalized income
    * @return aTokenBalance Pool balance of aToken for the asset
    * @return claimedInterest interest that has been claimed (no longer in contract)
    * @return unclaimedInterest accrued interest that has not yet been claimed
    * @return totalDeposit total assets deposited in pool
    * @return aTokenAddress address of Aave's aToken for asset
    */
    function getPoolInfo() external view returns(address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address);
}

// File: contracts/contracts/interfaces/protocol/IOracleGateway.sol


pragma solidity 0.8.9;

interface IOracleGateway {
    function setReserve(address _reserve) external;
    function callOracle(string memory _index) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/contracts/interfaces/protocol/IReserve.sol


pragma solidity 0.8.9;

interface IReserve {

    event AddPool(address pool, string name, address receiver);
    event AddDeposit(address userAddr, address pool, address asset, uint256 amount);
    event WithdrawDeposit(address userAddr, address pool, address asset, uint256 amount);
    event Claim(address userAddr, address receiver, address pool, address asset, uint256 amount);

    function provideInsurance() external payable;
    function applyForCoverage(address _withdrawAddress, uint _validatorIndex) external;
    function addBeneficiary(address _withdrawAddress, uint _validatorIndex) external;
    function oracleResponse(uint _validatorIndex, uint8 _slashed, address _withdrawAddress, uint _loss) external;
    function withdrawBeneficiary(address _withdrawAddress, uint _validatorIndex)external;
    function harvestInterestAll() external;
    function harvestInterestAmount(uint _requested) external;
    function addGeneratorPool(address _pool) external;
    function removeGeneratorPool(uint8 index) external;
    function getMultiSig() external view returns(address);
    function getGeneratorPools() external view returns(address[] memory);
    function checkPool(address _pool) external view returns(bool);
    function getSlashingInsuranceETHAddress() external view returns(address);
    function getProtocolBalance() external view returns(uint);

}

// File: contracts/contracts/SlashingInsuranceETH.sol


pragma solidity 0.8.9;


contract SlashingInsuranceETH is ERC20 {

    address[] allowed;
    address reserve;

    //Events
    event ETHDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);

    /**
    * @dev Only Reserve can call functions marked by this modifier.
    **/
    modifier onlyReserve(){
        require(reserve == msg.sender, "not the owner");
        _;
    }

    // Construct with our token details
    constructor() ERC20("Slashing Insurance ETH", "sliETH") {
        reserve = msg.sender;
    }

    // Receive an ETH deposit and reroute to reserve
    /*receive() external payable {
        IReserve(reserve).depositETHViaSLI{value: msg.value}(msg.sender);
        emit ETHDeposited(msg.sender, msg.value, block.timestamp);
    }*/

    function getETHValue(uint256 _sliETHAmount) public view returns (uint256) {
        // Get network balances
        uint256 reserveETH = getReserveBalance();
        uint256 sliETHSupply = totalSupply();
        // Use 1:1 ratio if no sliETH is minted
        if (sliETHSupply == 0) { return _sliETHAmount; }
        // Calculate and return
        return (_sliETHAmount * reserveETH) / sliETHSupply;
    }

    // Calculate the amount of sliETH backed by an amount of ETH
    function getSliETHValue(uint256 _ethAmount) public view returns (uint256) {
        // Get network balances
        uint256 reserveETH = getReserveBalance() - _ethAmount;
        uint256 sliETHSupply = totalSupply();
        // Use 1:1 ratio if no sliETH is minted
        if (sliETHSupply == 0) { return _ethAmount; }
        // Check network ETH balance
        require(reserveETH > 0, "Cannot calculate sliETH token amount while reserve balance is zero");
        // Calculate and return
        return (_ethAmount * sliETHSupply ) / reserveETH;
    }

    // Calculate the amount of ETH backing 1 slashing insurance ETH
    function getETHValuePerSliETH() public view returns (uint256) {
        // Get network balances
        uint256 reserveETH = getReserveBalance();
        uint256 sliETHSupply = totalSupply();
        if (sliETHSupply == 0 || reserveETH == 0) { return 0; }
        return ((1 ether) * reserveETH ) / sliETHSupply;
    }

    // Mint sliETH
    // Only accepts calls from the Reserve contract
    function mint(address _to, uint256 _ethAmount) external onlyReserve {
        // Get sliETH amount
        uint256 sliETHAmount = getSliETHValue(_ethAmount);
        // Check sliETH amount
        require(sliETHAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, sliETHAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, sliETHAmount, _ethAmount, block.timestamp);
    }

    // Burn sliETH for ETH
    // Only accepts calls from the Reserve contract
    function burn(address _from, uint256 _sliETHAmount) external onlyReserve {
        // Check sliETH amount
        require(_sliETHAmount > 0, "Invalid token burn amount");
        require(balanceOf(_from) >= _sliETHAmount, "Insufficient sliETH balance");
        // Get ETH amount
        uint256 ethAmount = getETHValue(_sliETHAmount);
        // Update balance & supply
        _burn(_from, _sliETHAmount);
        // Emit tokens burned event
        emit TokensBurned(msg.sender, _sliETHAmount, ethAmount, block.timestamp);
    }

    function getReserveBalance() public view returns(uint){
        return IReserve(reserve).getProtocolBalance();
    }

    receive() external payable{}

}

// File: contracts/contracts/ReserveStorage.sol


pragma solidity 0.8.9;

contract ReserveStorage {
address immutable wethGatewayAddr;
    address oracle;
    address public oracleGateway;
    uint256 public constant WAIT_PERIOD = 2 weeks;
    uint256 public constant APPLY_WINDOW = 2 days;

    enum Status {
        NOT_ACTIVE,
        ACTIVE,
        AWAIT_ORACLE_ADD,
        ORACLE_ADD_APPROVE,
        AWAIT_ORACLE_CLAIM,
        CLAIM_WAIT_PERIOD,
        CLOSED,
        CLAIM_PAUSED
    }

    struct Beneficiary {
        Status status;
        address withdrawAddress;
        uint claimTimestamp;
        uint applyTimestamp;
        uint loss;
    }

    //maps validator index to Beneficiary obj
    mapping(uint => Beneficiary) beneficiaries;
    //maps withdraw address to validator Ids
    mapping(address => uint[]) depositors;

    address public immutable generatorPool;

    address public immutable multiSig;
    uint public minimumProvide;
    //minimum required for withdrawals and accepting claims
    uint public minimumReserve;
    //minimum pure ETH to hold in Reserve
    //uint public minimumPureHoldings;
    uint public maxClaim;

    /**
     * @dev Constructor.
     */
    constructor(
        address _multiSig,
        address _generatorPool,
        address _wethGatewayAddr,
        uint _minimumProvide,
        uint _minimumReserve,
        uint _maxClaim,
        address _oracle,
        address _oracleGateway
    ){
        multiSig = _multiSig;
        generatorPool = _generatorPool;
        wethGatewayAddr = _wethGatewayAddr;
        minimumProvide = _minimumProvide;
        minimumReserve = _minimumReserve;
        maxClaim = _maxClaim;
        oracle = _oracle;
        oracleGateway = _oracleGateway;
    }
}

// File: contracts/contracts/Authenticator.sol


pragma solidity 0.8.9;

contract Authenticator is ReserveStorage {

    modifier minimumReserveMet(uint _protocolBalance) {
        require(
            minimumReserve <= _protocolBalance,
            "minimum reserve not met"
        );
        _;
    }

    modifier onlyApply(uint _validatorIndex) {
        bool validityCheck = (
                beneficiaries[_validatorIndex].status == Status.NOT_ACTIVE
            ) ||
            (
                beneficiaries[_validatorIndex].status == Status.ORACLE_ADD_APPROVE &&
                beneficiaries[_validatorIndex].withdrawAddress == msg.sender &&
                block.timestamp >= beneficiaries[_validatorIndex].applyTimestamp + APPLY_WINDOW
            );
        require(validityCheck, "not eligible to apply");
        _;
    }

    modifier onlyBeneficiary(address _withdrawAddress, uint _validatorIndex) {
        require(
            beneficiaries[_validatorIndex].withdrawAddress == _withdrawAddress,
            "must send tx from validator withdrawAddress"
        );
        _;
    }
    modifier onlyAddApproved(uint _validatorIndex) {
        require(
            beneficiaries[_validatorIndex].status == Status.ORACLE_ADD_APPROVE,
            "beneficiary is not approved"
        );
        _;
    }

    modifier onlyActiveBeneficiary(uint _validatorIndex) {
        require(
            beneficiaries[_validatorIndex].status == Status.ACTIVE,
            "beneficiary not active"
        );
        _;
    }

    modifier onlyWaitPeriod(uint _validatorIndex) {
        require(
            beneficiaries[_validatorIndex].status == Status.CLAIM_WAIT_PERIOD,
            "no claim pending"
        );
        _;
    }

    modifier onlyPausedClaim(uint _validatorIndex) {
        require(
            beneficiaries[_validatorIndex].status == Status.CLAIM_PAUSED,
            "no claim paused"
        );
        _;
    }

    modifier onlyTimeoutPassed(uint _validatorIndex) {
        require(block.timestamp >=
                beneficiaries[_validatorIndex].claimTimestamp +
                WAIT_PERIOD, "Cannot withdraw claim until timeout passed"
        );
        _;
    }

    modifier onlyInApplyWindow(uint _validatorIndex) {
        require((block.timestamp <=
                beneficiaries[_validatorIndex].applyTimestamp +
                APPLY_WINDOW), "Outside apply window"
        );
        _;
    }

    modifier fromWithdrawAddress(
        address _withdrawAddress,
        uint _validatorIndex
    ) {
        require(
            beneficiaries[_validatorIndex].withdrawAddress == _withdrawAddress,
            "withdrawAddress does not match"
        );
        _;
    }

    /**
     * @dev Only address that are a pool can be passed to functions marked by this modifier.
     **/
    modifier onlyPools() {
        require(msg.sender == generatorPool, "sender is not pool");
        _;
    }

    /**
     * @dev Only multisig can call functions marked by this modifier.
     **/
    modifier onlyMultiSig() {
        require(multiSig == msg.sender, "not the multiSig");
        _;
    }

    /**
     * @dev Only oracle can call functions marked by this modifier.
     **/
    modifier onlyOracle() {
        require(oracle == msg.sender, "not the oracle");
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        address _multiSig,
        address _generatorPool,
        address _wethGatewayAddr,
        uint _minimumProvide,
        uint _minimumReserve,
        uint _maxClaim,
        address _oracle,
        address _oracleGateway
    )ReserveStorage(
        _multiSig,
        _generatorPool,
        _wethGatewayAddr,
        _minimumProvide,
        _minimumReserve,
        _maxClaim,
        _oracle,
        _oracleGateway){
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/contracts/libraries/DataTypes.sol


pragma solidity 0.8.9;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// File: contracts/contracts/interfaces/aave/ILendingPoolAddressesProvider.sol


pragma solidity 0.8.9;

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// File: contracts/contracts/interfaces/aave/ILendingPool.sol


pragma solidity 0.8.9;


interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// File: contracts/contracts/interfaces/aave/IProtocolDataProvider.sol


pragma solidity 0.8.9;

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

// File: contracts/contracts/Reserve.sol


pragma solidity 0.8.9;









//AAVE V2



/**
 * @title Ethereum Slashing Insurance (SLI) Reserve contract
 * @author smeee
 * @notice Main point of interaction with SLI Protocol
 * This is a proof of concept starter contract for lossless insurance
 *
 * Aave v2 is used to generate interest from premium deposits
 * Premium is returned to beneficiary after the
 *
 * PoolTracker contract controls deposit calls to Aave to make
 * approvals needed only once per token. Calls JustCause Pools for
 * withdrawals and claims
 *
 * Controls Owner/Contributor NFT creation and updates for deposits/withdrawals
 *
 * Controls JustCause Pool creation with proxy contracts
 *
 * @dev Deposits, withdraws, and claims for Aave Pools
 * @dev Generate ERC721 token
 **/

contract Reserve is ReentrancyGuard, Authenticator{
    using SafeERC20 for IERC20;

    SlashingInsuranceETH immutable sliETH;

    event DenyApplication(uint validatorIndex,address withdrawAddress,uint8 reason);
    event ApproveApplication( uint validatorIndex, address withdrawAddress);
    event ProvideInsurance(address depositor, uint ethAmount);
    event WithdrawInsurance(address depositor, uint ethAmount, uint sliETHAmount);
    event DenyClaim(uint validatorIndex,address withdrawAddress,uint8 reason);
    event AcceptClaim(uint validatorIndex,address withdrawAddress);
    event AddBeneficiary(uint validatorIndex, address withdrawAddress);
    event WithdrawBeneficiary(uint validatorIndex, address withdrawAddress);
    event MakeClaim(uint validatorIndex);
    event ProcessClaim(address beneficiary, uint amount, uint8 result);

    /**
     * @dev Constructor.
     */
    constructor(
        address _multiSig,
        address _generatorPool,
        address _wethGatewayAddr,
        uint _minimumProvide,
        uint _minimumReserve,
        uint _maxClaim,
        address _oracle,
        address _oracleGateway
    ) Authenticator(
        _multiSig,
        _generatorPool,
        _wethGatewayAddr,
        _minimumProvide,
        _minimumReserve,
        _maxClaim,
        _oracle,
        _oracleGateway
    ){
        sliETH = new SlashingInsuranceETH();
    }

    receive() external payable {
        provideInsurance();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        provideInsurance();
    }

    function provideInsurance() public payable nonReentrant {
        require(
            msg.value >= minimumProvide,
            "value must be greater than minimum"
        );
        sliETH.mint(msg.sender, msg.value);
        address aaveLendingPool = IPremiumGenerator(generatorPool).getLendingPoolAddress();
        IWETHGateway(wethGatewayAddr).depositETH{value: msg.value}(aaveLendingPool, address(this), 0);
        emit ProvideInsurance(msg.sender, msg.value);
    }

    function withdrawInsurance(uint _sliETHAmount) external nonReentrant {
        uint requestedETH = sliETH.getETHValue(_sliETHAmount);
        require(
            minimumReserve < (getProtocolBalance() - requestedETH),
            "reserve insufficient to withdraw insurance"
        );
        sliETH.burn(msg.sender, _sliETHAmount);
        _processOutflow(msg.sender, requestedETH);
        emit WithdrawInsurance(msg.sender, requestedETH, _sliETHAmount);
    }

    function _processOutflow(address _to, uint requestedETH) internal {
        //harvest aave pools for outflow
        uint aTokenBalance = getReserveATokenBalance();
        if(aTokenBalance < requestedETH){
            _harvestInterest();
        }

        address aTokenAddress = IPremiumGenerator(generatorPool)
            .getATokenAddress();
        IERC20(aTokenAddress).safeApprove(wethGatewayAddr, 0);
        IERC20(aTokenAddress).safeApprove(wethGatewayAddr, requestedETH);
        address aaveLendingPool = IPremiumGenerator(generatorPool)
            .getLendingPoolAddress();
        IWETHGateway(wethGatewayAddr).withdrawETH(
            aaveLendingPool,
            requestedETH,
            _to
        );
    }

    /**
     * @param _validatorIndex uint index of insured validator
     **/
    function applyForCoverage(
        uint _validatorIndex
    ) external onlyApply(_validatorIndex) {
        IOracleGateway(oracleGateway).callOracle(Strings.toString(_validatorIndex));
        beneficiaries[_validatorIndex] = Beneficiary(
            Status.AWAIT_ORACLE_ADD,
            msg.sender,
            0,
            0,
            0
        );
        depositors[msg.sender].push(_validatorIndex);
    }

    /**
     * @param _withdrawAddress address of beneficiary
     * @param _validatorIndex uint index of insured validator
     **/
    function addBeneficiary(
        address _withdrawAddress,
        uint _validatorIndex
    )
        external
        minimumReserveMet(getProtocolBalance())
        onlyAddApproved(_validatorIndex)
        onlyBeneficiary(_withdrawAddress, _validatorIndex)
        onlyInApplyWindow(_validatorIndex)
        onlyPools
    {
        beneficiaries[_validatorIndex].status = Status.ACTIVE;
        emit AddBeneficiary(_validatorIndex, _withdrawAddress);
    }

    function oracleResponse(
        uint _validatorIndex,
        uint8 _slashed,
        address _withdrawAddress,
        uint _loss
    ) external onlyOracle {
        if (beneficiaries[_validatorIndex].status == Status.AWAIT_ORACLE_CLAIM) {
            _oracleClaimResponse(_validatorIndex, _slashed, _withdrawAddress, _loss);
        }
        else if (beneficiaries[_validatorIndex].status == Status.AWAIT_ORACLE_ADD) {
            _oracleAddBeneResponse(_validatorIndex, _slashed, _withdrawAddress);
        }
        else{
            return;
        }
    }

    function _oracleAddBeneResponse(
        uint _validatorIndex,
        uint8 _slashed,
        address _withdrawAddress
    ) internal {
        //check withdraw address with oracle reponse
        //check validator is active with oracle response
        if (
            beneficiaries[_validatorIndex].withdrawAddress != _withdrawAddress ||
            _slashed == 1
        ) {
            beneficiaries[_validatorIndex].withdrawAddress = address(0);
            beneficiaries[_validatorIndex].status = Status.NOT_ACTIVE;
            emit DenyApplication(
                _validatorIndex,
                _withdrawAddress,
                0 //address not correct or validator slashed
            );
        }
        else {
            beneficiaries[_validatorIndex].status = Status.ORACLE_ADD_APPROVE;
            beneficiaries[_validatorIndex].applyTimestamp = block.timestamp;
            emit ApproveApplication(_validatorIndex, _withdrawAddress);
        }
    }

    function _oracleClaimResponse(
        uint _validatorIndex,
        uint8 _slashed,
        address _withdrawAddress,
        uint _loss
    ) internal {
        //check withdraw address with oracle reponse
        if (
            beneficiaries[_validatorIndex].withdrawAddress != _withdrawAddress
        ) {
            beneficiaries[_validatorIndex].status = Status.ACTIVE;
            emit DenyClaim(
                _validatorIndex,
                _withdrawAddress,
                0//"withdrawAddress incorrect"
            );
        }
        //check if slashed
        else if (_slashed == 0 || _loss == 0) {
            beneficiaries[_validatorIndex].status = Status.ACTIVE;
            emit DenyClaim(
                _validatorIndex,
                _withdrawAddress,
                1//"not slashed"
            );
        }
        else {
            if(_loss > maxClaim){
                beneficiaries[_validatorIndex].status = Status.CLAIM_PAUSED;
                emit DenyClaim(
                _validatorIndex,
                _withdrawAddress,
                2//exceeds max claim and has to be reviewed
            );
            }
            else{
                beneficiaries[_validatorIndex].status = Status.CLAIM_WAIT_PERIOD;
                emit AcceptClaim(_validatorIndex, _withdrawAddress);
            }
            beneficiaries[_validatorIndex].claimTimestamp = block.timestamp;
            beneficiaries[_validatorIndex].loss = _loss;
        }
    }

    function makeClaim(
        uint _validatorIndex
    )
        public
        fromWithdrawAddress(msg.sender, _validatorIndex)
        onlyActiveBeneficiary(_validatorIndex)
    {
        IOracleGateway(oracleGateway).callOracle(Strings.toString(_validatorIndex));
        beneficiaries[_validatorIndex].status = Status.AWAIT_ORACLE_CLAIM;
    }

    function payClaim(
        uint _validatorIndex
    )
        external
        onlyWaitPeriod(_validatorIndex)
        onlyTimeoutPassed(_validatorIndex)
    {
        address withdrawAddress = beneficiaries[_validatorIndex]
            .withdrawAddress;
        uint loss = beneficiaries[_validatorIndex].loss;
        _processOutflow(
            withdrawAddress,
            beneficiaries[_validatorIndex].loss
        );
        beneficiaries[_validatorIndex].status = Status.CLOSED;
        emit ProcessClaim(
            withdrawAddress,
            loss,
            0//approve
            );
    }

    function denyClaim(
        uint _validatorIndex
    ) public onlyMultiSig onlyPausedClaim(_validatorIndex) {
        beneficiaries[_validatorIndex].status = Status.CLOSED;
        emit ProcessClaim(
            beneficiaries[_validatorIndex].withdrawAddress,
            0,
            1//deny
        );
    }

    function pauseClaim(
        uint _validatorIndex
    ) public onlyMultiSig onlyWaitPeriod(_validatorIndex) {
        beneficiaries[_validatorIndex].status = Status.CLAIM_PAUSED;
        emit ProcessClaim(
            beneficiaries[_validatorIndex].withdrawAddress,
            0,
            2//pause
        );
    }

    function unpauseClaim(
        uint _validatorIndex
    )
        public
        onlyMultiSig
        onlyPausedClaim(_validatorIndex)
    {
        beneficiaries[_validatorIndex].status = Status.CLAIM_WAIT_PERIOD;
        emit ProcessClaim(
            beneficiaries[_validatorIndex].withdrawAddress,
            0,
            3//"unpause"
        );
    }

    function resetClaim(
        uint _validatorIndex
    ) public onlyMultiSig {
        beneficiaries[_validatorIndex].status = Status.ACTIVE;
        emit ProcessClaim(
            beneficiaries[_validatorIndex].withdrawAddress,
            0,
            4//"reset"
        );
    }

    /**
     * @dev Emit WithdrawDeposit
     * @param _withdrawAddress address of beneficiary
     * @param _validatorIndex uint index of insured validator
     **/
    function withdrawBeneficiary(
        address _withdrawAddress,
        uint _validatorIndex
    )
        external
        fromWithdrawAddress(_withdrawAddress, _validatorIndex)
        onlyActiveBeneficiary(_validatorIndex)
        onlyPools
    {
        beneficiaries[_validatorIndex].status = Status.NOT_ACTIVE;
        emit WithdrawBeneficiary(_validatorIndex, _withdrawAddress);
    }

    /**
     * @dev Emit Claim
     **/
    function _harvestInterest() internal {
        uint256 amount = IPremiumGenerator(generatorPool).withdrawInterest();
    }

    function getSlashingInsuranceETHAddress() public view returns (address) {
        return address(sliETH);
    }

    function getSlashingInsuranceETHBalance(
        address _depositor
    ) public view returns (uint) {
        return IERC20(getSlashingInsuranceETHAddress()).balanceOf(_depositor);
    }

    function getDepositorValidatorIds(address _withdrawAddress) public view returns(uint[] memory){
        return depositors[_withdrawAddress];
    }

    function getReserveATokenBalance() public view returns (uint) {
        address aTokenAddress = IPremiumGenerator(generatorPool)
                .getATokenAddress();

        return IERC20(aTokenAddress).balanceOf(address(this));
    }

    function getProtocolBalance() public view returns (uint) {
        return (
            address(this).balance +
            IPremiumGenerator(generatorPool).getUnclaimedInterest() +
            getReserveATokenBalance()
        );
    }

    function getSliETHTotalSupply() public view returns (uint) {
        return IERC20(getSlashingInsuranceETHAddress()).totalSupply();
    }

    function getSliETHConversion() public view returns (uint256) {
        return sliETH.getETHValuePerSliETH();
    }

    function getBeneficiaryStatus(
        uint _validatorIndex
    ) public view returns (Status status) {
        status = beneficiaries[_validatorIndex].status;
    }

    function getValidatorWithdrawAddress(
        uint _validatorIndex
    ) public view returns (address withdrawAddress) {
        withdrawAddress = beneficiaries[_validatorIndex].withdrawAddress;
    }

    function getBeneficiaryInfo(
        uint _validatorIndex
    ) public view returns (Beneficiary memory) {
        return beneficiaries[_validatorIndex];
    }
}