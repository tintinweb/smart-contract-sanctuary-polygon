// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import '../Interfaces/IOracleSimple.sol';
import '../Interfaces/ISugarBankWhitelist.sol';


   
//                                      ___---___
//                                ___---___---___---___
//                          ___---___---    *    ---___---___
//                    ___---___---    o/ 0_/  @  o ^   ---___---___
//              ___---___--- @  i_e J-U /|  -+D O|-| (o) /   ---___---___
//        ___---___---    __/|  //\  /|  |\  /\  |\|  |_  __--oj   ---___---___
//   __---___---_________________________________________________________---___---__
//   ===============================================================================
//    ||||                          SUGAR BANK V1.0.0                          ||||
//    |---------------------------------------------------------------------------|
//    |___-----___-----___-----___-----___-----___-----___-----___-----___-----___|
//    / _ \===/ _ \   / _ \===/ _ \   / _ \===/ _ \   / _ \===/ _ \   / _ \===/ _ \
//   ( (.\ oOo /.) ) ( (.\ oOo /.) ) ( (.\ oOo /.) ) ( (.\ oOo /.) ) ( (.\ oOo /.) )
//    \__/=====\__/   \__/=====\__/   \__/=====\__/   \__/=====\__/   \__/=====\__/
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       |||||||         |||||||         |||||||         |||||||         |||||||
//       (oOoOo)         (oOoOo)         (oOoOo)         (oOoOo)         (oOoOo)
//       J%%%%%L         J%%%%%L         J%%%%%L         J%%%%%L         J%%%%%L
//      ZZZZZZZZZ       ZZZZZZZZZ       ZZZZZZZZZ       ZZZZZZZZZ       ZZZZZZZZZ
//     ===========================================================================
//   __|_____________________ https://cryptocookiesdao.com/ _____________________|__
//   _|___________________________________________________________________________|_
//   |_____________________________________________________________________________|
//   _______________________________________________________________________________
//   
//                                  SUGAR BANK V1.0.0
  

uint256 constant BASE_PERC = 10000;
uint256 constant PERC_101 = 10100; // 101 %
uint256 constant PERC_1 = 100; // 1 %

uint256 constant BASE_ETH = 1 ether;

contract SugarBankV1 is Ownable {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  event BondTermsStart(Bond bond);
  event BondTermsEnd(uint256 cookieRemains);

  event NoteAdded(address indexed owner, uint256 indexed noteId, uint256 amountMATIC, uint256 cookiesForUser);
  event BondAddLiquidity(uint256 totalValueSend, uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);
  event NoteRedeem(address indexed owner, uint256 indexed noteId, uint256 redeemAmount);

  event UpdateOperator(address operator, bool isOperator);

  struct Bond {
    uint256 uid;
    uint256 bondStart;
    uint256 vestingTime;
    uint256 startDiscount;
    uint256 endDiscount;
    uint256 dailyDiscount;
    uint256 bondedCookies;
    uint256 cookiesToBond;
    address whitelistStrategy;
  }

  struct Note {
    uint256 uid;
    uint256 uidBond;
    uint256 timestampStart;
    uint256 timestampLastRedeem;
    uint256 timestampEnd;
    uint256 paid;
    uint256 totalCookies;
  }

  Counters.Counter private _noteIdCounter;
  Counters.Counter private _bondIdCounter;

  IERC20 public immutable cookieToken;
  IOracleSimple public immutable oracleSimple;
  IUniswapV2Router02 public immutable router;
  address public immutable WETH;
  address public immutable treasury;
  address public dev;
  mapping(address=>bool) public operators;

  Bond public bond;
  mapping(address => Note[]) public toNotes;

  uint256 public totalCookiesDebt;

  constructor(
    IERC20 _cookieToken,
    IOracleSimple _oracleSimple,
    IUniswapV2Router02 _router,
    address _treasury
  ) {
    cookieToken = _cookieToken;
    oracleSimple = _oracleSimple;
    treasury = _treasury;
    router = _router;
    dev = msg.sender;

    WETH = _router.WETH();
    cookieToken.approve(address(_router), type(uint256).max);

    operators[msg.sender] = true;
  }

  function updateDev(address _dev) external onlyOwner {
    dev = _dev;
  }

  function updateOperator(address operator, bool status) external onlyOwner {
    operators[operator] = status;
    emit UpdateOperator(operator, status);
  }

  function withdraw(IERC20 _token, uint256 _amount) external onlyOwner {
    if (_token == cookieToken) {
      require(_amount <= _token.balanceOf(address(this)) - totalCookiesDebt, 'cant withdraw cookies to bond');
      _token.transfer(msg.sender, _amount);
    } else if (_token == IERC20(address(0))) {
      payable(msg.sender).transfer(_amount);
    } else {
      _token.transfer(msg.sender, _amount);
    }
  }

  function startBondSell(
    uint256 _vestingTime,
    uint256 _startDiscount,
    uint256 _endDiscount,
    uint256 _dailyDiscount,
    uint256 _cookiesToBond,
    address _whitelistStrategy
  ) external {
    require(operators[msg.sender], 'only operators can start a bond');
    require(_cookiesToBond > 0, 'No cookies to bond');

    _endBondSell();

    // Sumo 101% del _cookiesToBond, ya que 1% es para devs
    totalCookiesDebt += (_cookiesToBond * PERC_101) / BASE_PERC;

    require(cookieToken.balanceOf(address(this)) >= totalCookiesDebt, 'Not enough cookies');
    require(_startDiscount <= _endDiscount, 'The _endDiscount should be greather than _startDiscount');

    bond.uid = _bondIdCounter.current();
    bond.bondStart = block.timestamp;
    bond.vestingTime = _vestingTime;

    bond.startDiscount = _startDiscount;
    bond.endDiscount = _endDiscount;
    bond.dailyDiscount = _dailyDiscount;

    bond.bondedCookies = 0;
    bond.cookiesToBond = _cookiesToBond;

    bond.whitelistStrategy = _whitelistStrategy;

    _bondIdCounter.increment();

    emit BondTermsStart(bond);
  }

  function endBondSell() external {
    require(operators[msg.sender], 'only operators can end a bond');
    _endBondSell();
  }

  function _endBondSell() internal {
    uint256 cookieRemains = bond.cookiesToBond - bond.bondedCookies;
    totalCookiesDebt -= (cookieRemains * PERC_101) / BASE_PERC; // plus 1% for devs;
    delete (bond);
    emit BondTermsEnd(cookieRemains);
  }

  function buyBond() external payable {
    require(bond.cookiesToBond != 0, 'The bond was ended');
    if (bond.whitelistStrategy != address(0)) {
      require(ISugarBankWhitelist(bond.whitelistStrategy).whitelisted(msg.sender), 'The bond whitelist is not valid');
    }

    // update oracle if needed
    oracleSimple.update();

    uint256 value = msg.value;
    uint256 vestingTime = bond.vestingTime;

    uint256 discountPrice = priceOfCookieWithDiscount();
    uint256 cookiesForUser = (value * BASE_ETH) / discountPrice;

    uint256 cookieRemains = bond.cookiesToBond - bond.bondedCookies;
    if (cookieRemains <= cookiesForUser) {
      cookiesForUser = cookieRemains;
      value = (cookieRemains * discountPrice) / BASE_ETH;
    }
    bond.bondedCookies += cookiesForUser;

    // 1% for devs
    uint256 forDev = (cookiesForUser * PERC_1) / BASE_PERC;
    totalCookiesDebt -= forDev;
    cookieToken.transfer(dev, forDev);

    _buildLiquidity(value);

    toNotes[msg.sender].push(
      Note({
        uid: _noteIdCounter.current(),
        uidBond: bond.uid,
        timestampStart: block.timestamp,
        timestampLastRedeem: block.timestamp,
        timestampEnd: block.timestamp + vestingTime,
        paid: 0,
        totalCookies: cookiesForUser
      })
    );

    _noteIdCounter.increment();

    emit NoteAdded(msg.sender, toNotes[msg.sender].length - 1, value, cookiesForUser);

    if (bond.cookiesToBond == bond.bondedCookies) {
      _endBondSell();
    }

    if (value < msg.value) {
      payable(msg.sender).transfer(msg.value - value);
    }
  }

  function redeemAll() external {
    for (uint256 i; i < toNotes[msg.sender].length; ) {
      if (!redeem(i)) {
        i++;
      }
    }
  }

  function redeem(uint256 _noteId) public returns (bool resize) {
    Note storage note = toNotes[msg.sender][_noteId];

    uint256 redeemAmount = _toRedeem(msg.sender, _noteId);

    if (redeemAmount == 0) {
      return false;
    }

    note.timestampLastRedeem = block.timestamp;
    note.paid += redeemAmount;
    totalCookiesDebt -= redeemAmount;
    cookieToken.transfer(msg.sender, redeemAmount);

    emit NoteRedeem(msg.sender, _noteId, redeemAmount);

    if (note.paid == note.totalCookies) {
      _deleteNote(msg.sender, _noteId);
      resize = true;
    }
  }

  function notes(address _account) public view returns (Note[] memory) {
    return toNotes[_account];
  }

  function notesLength(address _account) public view returns (uint256) {
    return toNotes[_account].length;
  }

  function currentDiscount() public view returns (uint256) {
    uint256 discount = bond.startDiscount + ((block.timestamp - bond.bondStart) * bond.dailyDiscount) / 1 days;

    if (discount > bond.endDiscount) {
      return bond.endDiscount;
    }

    return discount;
  }

  function priceOfCookieWithDiscount() public view returns (uint256) {
    uint256 price = oracleSimple.consult(address(cookieToken), BASE_ETH);

    return (price * (BASE_PERC - currentDiscount())) / BASE_PERC;
  }

  function _toRedeem(address _account, uint256 _noteId) internal view returns (uint256) {
    Note storage note = toNotes[_account][_noteId];

    if (block.timestamp >= note.timestampEnd) {
      return note.totalCookies - note.paid;
    } else {
      uint256 deltaY = block.timestamp - note.timestampLastRedeem;
      uint256 redeemPerc = (deltaY * BASE_ETH) / (note.timestampEnd - note.timestampStart);
      return (note.totalCookies * redeemPerc) / BASE_ETH;
    }
  }

  function toRedeem(address _account) external view returns (uint256[] memory _pendingAmount) {
    _pendingAmount = new uint256[](toNotes[_account].length);
    for (uint256 i; i < toNotes[_account].length; i++) {
      _pendingAmount[i] = _toRedeem(_account, i);
    }
  }

  function totalToRedeem(address _account) external view returns (uint256 _pendingAmount) {
    for (uint256 i; i < toNotes[_account].length; i++) {
      _pendingAmount += _toRedeem(_account, i);
    }
  }

  function _deleteNote(address _account, uint256 _index) internal {
    Note[] storage userNotes = toNotes[_account];
    uint256 noteslength = userNotes.length;

    if (noteslength > 1 && noteslength != _index) {
      userNotes[_index] = userNotes[noteslength - 1];
    }

    userNotes.pop();
  }

  function _buildLiquidity(uint256 _value) internal {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(cookieToken);

    uint256 half = _value / 2;

    uint256[] memory amounts = router.swapExactETHForTokens{value: _value - half}(0, path, address(this), block.timestamp);

    // add LP
    (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = router.addLiquidityETH{value: half}(
      address(cookieToken),
      amounts[1], // cookie amount
      // Bounds the extent to which the WETH/token price can go up before the transaction reverts.
      // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
      0,
      // Bounds the extent to which the token/WETH price can go up before the transaction reverts.
      // 0 = accept any amount (slippage is inevitable)
      0,
      treasury,
      block.timestamp
    );

    emit BondAddLiquidity(_value, tokenAmountSent, ethAmountSent, liquidity);
  }

  receive() external payable {}
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.11;

interface IOracleSimple {
  function update() external;

  function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISugarBankWhitelist {
  function whitelisted(address account) external view returns (bool);
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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