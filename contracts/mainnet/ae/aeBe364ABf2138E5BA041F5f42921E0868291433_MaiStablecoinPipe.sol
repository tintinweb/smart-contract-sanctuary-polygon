// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./../../../../openzeppelin/IERC20.sol";
import "./../../../../openzeppelin/SafeERC20.sol";
import "../../../../openzeppelin/Math.sol";
import "../../../SlotsLib.sol";
import "./Pipe.sol";
import "./../../../../third_party/qidao/IErc20Stablecoin.sol";
import "../../../interface/strategies/IMaiStablecoinPipe.sol";

/// @title Mai Stablecoin Pipe Contract
/// @author bogdoslav
contract MaiStablecoinPipe is Pipe, IMaiStablecoinPipe {
  using SafeERC20 for IERC20;
  using SlotsLib for bytes32;

  struct MaiStablecoinPipeData {
    address sourceToken;
    address stablecoin; //Erc20Stablecoin contract address
    // borrowing
    address borrowToken; // mai (miMATIC) for example
    uint256 targetPercentage; // Collateral to Debt target percentage
    uint256 maxImbalance;     // Maximum Imbalance in percents
    address rewardToken;
    uint256 collateralNumerator; // 1 for all tokens except 10*10 for WBTC erc20Stablecoin-cam-wbtc.sol at mai-qidao as it have only 8 decimals
  }

 bytes32 internal constant _STABLECOIN_SLOT           = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.stablecoin")) - 1);
 bytes32 internal constant _BORROW_TOKEN_SLOT         = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.borrowToken")) - 1);
 bytes32 internal constant _TARGET_PERCENTAGE_SLOT    = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.targetPercentage")) - 1);
 bytes32 internal constant _MAX_IMBALANCE_SLOT        = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.maxImbalance")) - 1);
 bytes32 internal constant _COLLATERAL_NUMERATOR_SLOT = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.collateralNumerator")) - 1);
 bytes32 internal constant _VAULT_ID_SLOT             = bytes32(uint(keccak256("eip1967.MaiStablecoinPipe.vaultID")) - 1);

  event Rebalanced(uint256 borrowed, uint256 repaid);
  event Borrowed(uint256 amount);
  event Repaid(uint256 amount);

  function initialize(MaiStablecoinPipeData memory _d) public {
    require(_d.stablecoin != address(0), "Zero stablecoin");
    require(_d.rewardToken != address(0), "Zero reward token");

    Pipe._initialize('MaiStablecoinPipe', _d.sourceToken, _d.borrowToken);

    _REWARD_TOKENS.push(_d.rewardToken);

    _STABLECOIN_SLOT.set(_d.stablecoin);
    _BORROW_TOKEN_SLOT.set(_d.borrowToken);
    _TARGET_PERCENTAGE_SLOT.set(_d.targetPercentage);
    _MAX_IMBALANCE_SLOT.set(_d.maxImbalance);
    _COLLATERAL_NUMERATOR_SLOT.set(_d.collateralNumerator);

    _VAULT_ID_SLOT.set(IErc20Stablecoin(_d.stablecoin).createVault());
  }

  // ************* SLOT SETTERS/GETTERS *******************
  function vaultID() external override view returns (uint256) {
    return _vaultID();
  }

  function _vaultID() internal view returns (uint256) {
    return _VAULT_ID_SLOT.getUint();
  }

  function stablecoin() external override view returns (address) {
    return address(_stablecoin());
  }

  function _stablecoin() internal view returns (IErc20Stablecoin) {
    return IErc20Stablecoin(_STABLECOIN_SLOT.getAddress());
  }

  function borrowToken() external override view returns (address) {
    return _borrowToken();
  }

  function _borrowToken() internal view returns (address) {
    return _BORROW_TOKEN_SLOT.getAddress();
  }

/// @dev Gets targetPercentage
/// @return target collateral to debt percentage
  function targetPercentage() external override view returns (uint) {
    return _targetPercentage();
  }

  function _targetPercentage() internal view returns (uint) {
    return _TARGET_PERCENTAGE_SLOT.getUint();
  }

  /// @dev Gets maxImbalance
  /// @return maximum imbalance (+/-%) to do re-balance
  function maxImbalance() external override view returns (uint) {
    return _maxImbalance();
  }

  function _maxImbalance() internal view returns (uint) {
    return _MAX_IMBALANCE_SLOT.getUint();
  }

  function collateralNumerator() external override view returns (uint) {
    return _collateralNumerator();
  }

  function _collateralNumerator() internal view returns (uint) {
    return _COLLATERAL_NUMERATOR_SLOT.getUint();
  }

  // ***************************************
  // ************** EXTERNAL VIEWS *********
  // ***************************************

  /// @dev Gets available MAI (miMATIC) to borrow at the Mai Stablecoin contract.
  /// @return miMatic borrow token Stablecoin supply
  function availableMai() external view override returns (uint256) {
    return _availableMai();
  }

  /// @dev Returns price of source token (cam), when vault will be liquidated, based on _minimumCollateralPercentage
  ///      collateral to debt percentage. Returns 0 when no debt or collateral
  function liquidationPrice()
  external view override returns (uint256 price) {
    IErc20Stablecoin __stablecoin = _stablecoin();
    uint __vaultID = _vaultID();
    uint256 borrowedAmount = __stablecoin.vaultDebt(__vaultID);
    if (borrowedAmount == 0) {
      return 0;
    }
    uint256 collateral = __stablecoin.vaultCollateral(__vaultID);
    if (collateral == 0) {
      return 0;
    }
    uint256 tokenPriceSource = __stablecoin.getTokenPriceSource();
    price = (borrowedAmount * tokenPriceSource * __stablecoin._minimumCollateralPercentage())
    / (collateral * 100 * _collateralNumerator());
  }

  /// @dev Returns maximal possible deposit of amToken, based on available mai and target percentage.
  /// @return max camToken maximum deposit
  function maxDeposit() external view override returns (uint256 max) {
    IErc20Stablecoin __stablecoin = _stablecoin();
    uint256 tokenPriceSource = __stablecoin.getTokenPriceSource();
    uint256 amPrice = __stablecoin.getEthPriceSource();
    max = _availableMai() * tokenPriceSource * _targetPercentage()
      / (amPrice * 100 * _collateralNumerator());
  }

  /// @dev Gets collateralPercentage
  /// @return current collateral to debt percentage
  function collateralPercentage() external view override returns (uint256) {
    return _stablecoin().checkCollateralPercentage(_vaultID());
  }

  /// @dev Returns true when rebalance needed
  function needsRebalance() override external view returns (bool){
    uint256 currentPercentage = _stablecoin().checkCollateralPercentage(_vaultID());
    if (currentPercentage == 0) {
      // no debt or collateral
      return false;
    }
    uint __maxImbalance = _maxImbalance();
    uint __targetPercentage = _targetPercentage();
    return ((currentPercentage + __maxImbalance) < __targetPercentage)
    || (currentPercentage > (uint256(__targetPercentage) + __maxImbalance));
  }

  // ***************************************
  // ************** EXTERNAL ***************
  // ***************************************


  /// @dev Sets maxImbalance
  /// @param __maxImbalance - maximum imbalance deviation (+/-%)
  function setMaxImbalance(uint256 __maxImbalance) onlyPipeline override external {
    _MAX_IMBALANCE_SLOT.set(__maxImbalance);
  }

  /// @dev Sets targetPercentage
  /// @param __targetPercentage - target collateral to debt percentage
  function setTargetPercentage(uint256 __targetPercentage) onlyPipeline override external {
    _TARGET_PERCENTAGE_SLOT.set(__targetPercentage);
  }

  /// @dev function for depositing to collateral then borrowing
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) override onlyPipeline external returns (uint256 output) {
    amount = maxSourceAmount(amount);
    if (amount != 0) {
      depositCollateral(amount);
      uint256 borrowAmount = _canSafelyBorrowMore();
      borrow(borrowAmount);
    }
    output = _erc20Balance(_outputToken());
    _transferERC20toNextPipe(_borrowToken(), output);
    emit Put(amount, output);
  }

  /// @dev function for repaying debt then withdrawing from collateral
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) override onlyPipeline external returns (uint256 output) {
    amount = _maxOutputAmount(amount);
    if (amount != 0) {
      IErc20Stablecoin __stablecoin = _stablecoin();
      uint __vaultID = _vaultID();
      uint256 debt = __stablecoin.vaultDebt(__vaultID);
      repay(amount);
      // repay subtracts fee from the collateral, so we get collateral after fees applied
      uint256 collateral = __stablecoin.vaultCollateral(__vaultID);
      uint256 debtAfterRepay = __stablecoin.vaultDebt(__vaultID);

      uint256 withdrawAmount = (debtAfterRepay == 0)
        ? collateral
        : (amount * collateral) / debt;
      withdrawCollateral(withdrawAmount);
    }
    address __sourceToken = _sourceToken();
    output = _erc20Balance(__sourceToken);
    _transferERC20toPrevPipe(__sourceToken, output);
    emit Get(amount, output);
  }

  /// @dev function for re balancing. When rebalance
  /// @return imbalance in underlying units
  /// @return deficit - when true, then asks to receive underlying imbalance amount, when false - put imbalance to next pipe,
  function rebalance() override onlyPipeline
  external returns (uint256 imbalance, bool deficit) {
    IErc20Stablecoin __stablecoin = _stablecoin();
    uint256 currentPercentage = __stablecoin.checkCollateralPercentage(_vaultID());
    if (currentPercentage == 0) {
      // no debt or collateral
      return (0, false);
    }

    uint __maxImbalance = _maxImbalance();
    uint __targetPercentage = _targetPercentage();
    address __borrowToken = _borrowToken();

    if ((currentPercentage + __maxImbalance) < __targetPercentage) {
      // we have deficit
      uint256 targetBorrow = _canSafelyBorrowTotal();
      uint256 debt = __stablecoin.vaultDebt(_vaultID());
      uint256 repayAmount = debt - targetBorrow;

      uint256 available = _erc20Balance(__borrowToken);
      uint256 paidAmount = Math.min(repayAmount, available);
      if (paidAmount > 0) {
        repay(paidAmount);
      }

      uint256 change = _erc20Balance(__borrowToken);
      if (change > 0) {
        _transferERC20toNextPipe(__borrowToken, change);
        return (change, false);
      } else {
        return (repayAmount - paidAmount, true);
      }

    } else if (currentPercentage > (uint256(__targetPercentage) + __maxImbalance)) {
      // we have excess
      uint256 targetBorrow = _canSafelyBorrowTotal();
      uint256 debt = __stablecoin.vaultDebt(_vaultID());
      if (debt < targetBorrow) {
        // do not borrow more than supply
        uint256 borrowAmount = Math.min(targetBorrow - debt, _availableMai());
        borrow(borrowAmount);
      }
      uint256 excess = _erc20Balance(__borrowToken);
      _transferERC20toNextPipe(__borrowToken, excess);
      return (excess, false);
    }

    return (0, false);
    // in balance
  }

  // ***************************************
  // ************** PRIVATE VIEWS **********
  // ***************************************

  /// @dev base function for all calculations below is: (each side in borrow token price * 100)
  /// collateral * collateralNumerator * ethPrice * 100 = borrow * tokenPrice * percentage

  /// @dev Returns how much we can safely borrow total (based on percentage)
  /// @return borrowAmount amount of borrow token for target percentage
  function _canSafelyBorrowTotal()
  private view returns (uint256 borrowAmount) {
    IErc20Stablecoin __stablecoin = _stablecoin();
    uint256 collateral = __stablecoin.vaultCollateral(_vaultID());
    if (collateral == 0) {
      return 0;
    }

    uint256 ethPrice = __stablecoin.getEthPriceSource();
    uint256 tokenPriceSource = __stablecoin.getTokenPriceSource();
    uint __targetPercentage = _targetPercentage();

    if (__targetPercentage == 0 || tokenPriceSource == 0) {
      borrowAmount = 0;
    } else {
      borrowAmount = (collateral * _collateralNumerator() * ethPrice * 100)
      / (tokenPriceSource * __targetPercentage);
    }
  }

  /// @dev Returns how much more we can safely borrow (based on percentage)
  function _canSafelyBorrowMore()
  private view returns (uint256) {
    uint256 canBorrowTotal = _canSafelyBorrowTotal();
    uint256 borrowed = _stablecoin().vaultDebt(_vaultID());

    if (borrowed >= canBorrowTotal) {
      return 0;
    } else {
      return canBorrowTotal - borrowed;
    }
  }


  /// @dev Gets available MAI (miMATIC) to borrow at the Mai Stablecoin contract.
  /// @return miMatic borrow token Stablecoin supply
  function _availableMai() private view returns (uint256) {
    return IERC20(_borrowToken()).balanceOf(address(_stablecoin()));
  }

  // ***************************************
  // ************** PRIVATE ****************
  // ***************************************

  /// @dev function for investing, deposits, entering, borrowing
  /// @param amount in source units
  function depositCollateral(uint256 amount) private {
    if (amount != 0) {
      IErc20Stablecoin __stablecoin = _stablecoin();
      _erc20Approve(_sourceToken(), address(__stablecoin), amount);
      __stablecoin.depositCollateral(_vaultID(), amount);
    }
  }

  /// @dev function for de-vesting, withdrawals, leaves, paybacks
  /// @param amount in underlying units
  function withdrawCollateral(uint256 amount) private {
    if (amount != 0) {
      _stablecoin().withdrawCollateral(_vaultID(), amount);
    }
  }

  /// @dev Borrow tokens
  /// @param amount to borrow in underlying units
  function borrow(uint256 amount) private {
    if (amount != 0) {
      _stablecoin().borrowToken(_vaultID(), amount);
      emit Borrowed(amount);
    }
  }

  /// @dev Repay borrowed tokens
  /// @param amount in borrowed tokens
  /// @return repaid in borrowed tokens
  function repay(uint256 amount) private returns (uint256) {
    uint __vaultID = _vaultID();
    IErc20Stablecoin __stablecoin = _stablecoin();
    uint256 repayAmount = Math.min(amount, __stablecoin.vaultDebt(__vaultID));
    if (repayAmount != 0) {
      _erc20Approve(_borrowToken(), address(__stablecoin), repayAmount);
      __stablecoin.payBackToken(__vaultID, repayAmount);
    }
    emit Repaid(repayAmount);
    return repayAmount;
  }

}

// SPDX-License-Identifier: MIT

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

import "./IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
/// @notice Example usage. Declare a slot variable. Change contract name and var name at string
/// @notice uint internal constant _MY_VAR = bytes32(uint(keccak256("eip1967.MyContract.myVar"))) - 1;
/// @notice use SlotsLib:
/// @notice using SlotsLib for uint;
/// @notice write value:
/// @notice _MY_VAR.set(100);
/// @notice read value:
/// @notice uint myVar = _MY_VAR.getUint();
library SlotsLib {

  function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }
    assembly {
      result := mload(add(source, 32))
    }
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (uint8 j = 0; j < i; j++) {
      bytesArray[j] = _bytes32[j];
    }
    return string(bytesArray);
  }

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as string
  function getString(bytes32 slot) internal view returns (string memory result) {
    bytes32 data;
    assembly {
      data := sload(slot)
    }
    result = bytes32ToString(data);
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with string (WARNING!!! truncated to 32 bytes)
  function set(bytes32 slot, string memory str) internal {
    bytes32 value = stringToBytes32(str);
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }


}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./../../../../openzeppelin/IERC20.sol";
import "./../../../../openzeppelin/SafeERC20.sol";
import "./../../../../openzeppelin/Initializable.sol";
import "../../../governance/ControllableV2.sol";
import "../../../interface/strategies/IPipe.sol";
import "../../../interface/IControllable.sol";
import "../../../SlotsLib.sol";
import "./PipeLib.sol";

/// @title Pipe Base Contract
/// @author bogdoslav
abstract contract Pipe is IPipe, ControllableV2 {
  using SafeERC20 for IERC20;
  using SlotsLib for bytes32;

  /// @notice Address of the master pipeline
  /// @dev After adding the pipe to a pipeline it should be immediately initialized
 bytes32 internal constant _PIPELINE_SLOT = bytes32(uint(keccak256("eip1967.Pipe.pipeline")) - 1);

  /// @notice Pipe name for statistical purposes only
  /// @dev initialize it in initializer
 bytes32 internal constant _NAME_SLOT = bytes32(uint(keccak256("eip1967.Pipe.name")) - 1);

  /// @notice Source token address type
  /// @dev initialize it in initializer, for ether (bnb, matic) use _ETHER
 bytes32 internal constant _SOURCE_TOKEN_SLOT = bytes32(uint(keccak256("eip1967.Pipe.sourceToken")) - 1);

  /// @notice Output token address type
  /// @dev initialize it in initializer, for ether (bnb, matic) use _ETHER
 bytes32 internal constant _OUTPUT_TOKEN_SLOT = bytes32(uint(keccak256("eip1967.Pipe.outputToken")) - 1);

  /// @notice Next pipe in pipeline
 bytes32 internal constant _PREV_PIPE_SLOT = bytes32(uint(keccak256("eip1967.Pipe.prevPipe")) - 1);

  /// @notice Previous pipe in pipeline
 bytes32 internal constant _NEXT_PIPE_SLOT = bytes32(uint(keccak256("eip1967.Pipe.nextPipe")) - 1);

  /// @notice Reward token address for claiming
  /// @dev initialize it in initializer
 bytes32 internal constant _REWARD_TOKENS = bytes32(uint(keccak256("eip1967.Pipe.rewardTokens")) - 1);

  event Get(uint256 amount, uint256 output);
  event Put(uint256 amount, uint256 output);

  function _initialize(
    string memory __name,
    address __sourceToken,
    address __outputToken
  ) internal  {
    require(
      _SOURCE_TOKEN_SLOT.getUint() == 0 &&
      _OUTPUT_TOKEN_SLOT.getUint() == 0,
      'Pipe: Already initialized'
    );

    require(__sourceToken != address(0), "Zero source token");
    require(__outputToken != address(0), "Zero output token");

    _NAME_SLOT.set(__name);
    _SOURCE_TOKEN_SLOT.set(__sourceToken);
    _OUTPUT_TOKEN_SLOT.set(__outputToken);
  }

  modifier onlyPipeline() {
    address __pipeline = _pipeline();
    require(
      __pipeline == msg.sender || __pipeline == address(this),
      "PIPE: caller is not the pipeline"
    );
    _;
  }

  // ************* SLOT SETTERS/GETTERS *******************
  function sourceToken() external view override returns (address) {
    return _sourceToken();
  }

  function _sourceToken() internal view returns (address) {
    return _SOURCE_TOKEN_SLOT.getAddress();
  }

  function outputToken() external view override returns (address) {
    return _outputToken();
  }

  function _outputToken() internal view returns (address) {
    return _OUTPUT_TOKEN_SLOT.getAddress();
  }

  function name() external view override returns (string memory) {
    return _NAME_SLOT.getString();
  }

  function pipeline() external view override returns (address) {
    return _pipeline();
  }

  function _pipeline() internal view returns (address) {
    return _PIPELINE_SLOT.getAddress();
  }

  function nextPipe() external view override returns (address) {
    return _NEXT_PIPE_SLOT.getAddress();
  }

  function prevPipe() external view override returns (address) {
    return _PREV_PIPE_SLOT.getAddress();
  }

  // ******************************************************

  /// @dev Replaces MAX constant to source token balance. Should be used at put() function start
  function maxSourceAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return sourceBalance();
    } else {
      return amount;
    }
  }

  /// @dev Replaces MAX constant to output token balance. Should be used at get() function start
  function _maxOutputAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return outputBalance();
    } else {
      return amount;
    }
  }

  /// @dev After adding the pipe to a pipeline it should be immediately initialized
  /// @notice ! Pipeline must be Controllable
  function setPipeline(address __pipeline) external override {
    require(_pipeline() == address(0), "PIPE: Already init");
    _PIPELINE_SLOT.set(__pipeline);
    initializeControllable(IControllableExtended(__pipeline).controller());
  }

  /// @dev Size of reward tokens array
  function rewardTokensLength() external view override returns (uint) {
    return _REWARD_TOKENS.arrayLength();
  }

  /// @dev Returns reward token
  /// @param index - token index in array
  function rewardTokens(uint index) external view override returns (address) {
    return _REWARD_TOKENS.addressAt(index);
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _nextPipe - next pipe in pipeline
  function setNextPipe(address _nextPipe) onlyPipeline override external {
    _NEXT_PIPE_SLOT.set(_nextPipe);
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _prevPipe - next pipe in pipeline
  function setPrevPipe(address _prevPipe) onlyPipeline override external {
    _PREV_PIPE_SLOT.set(_prevPipe);
  }

  /// @dev function for investing, deposits, entering, borrowing. Do not forget to transfer assets to next pipe
  /// @dev In almost all cases overrides should have maxSourceAmount(amount)modifier
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for de-vesting, withdrawals, leaves, paybacks. Amount in underlying units. Do not forget to transfer assets to prev pipe
  /// @dev In almost all cases overrides should have maxOutputAmount(amount)modifier
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for re balancing. Mark it as onlyPipeline when override
  /// @return imbalance in underlying units
  /// @return deficit - when true, then ask to receive underlying imbalance amount, when false - put imbalance to next pipe,
  function rebalance() virtual override external returns (uint256 imbalance, bool deficit) {
    // balanced, no deficit by default
    return (0, false);
  }

  /// @dev Returns true when rebalance needed
  function needsRebalance() virtual override external view returns (bool){
    // balanced, no deficit by default
    return false;
  }

  /// @dev function for claiming rewards
  function claim() onlyPipeline virtual override external {
    address __pipeline = _pipeline();
    require(__pipeline != address(0));

    uint len = _REWARD_TOKENS.arrayLength();
    for (uint i = 0; i < len; i++) {
      address rewardToken = _REWARD_TOKENS.addressAt(i);
      if (rewardToken == address(0)) {
        return;
      }
      uint256 amount = _erc20Balance(rewardToken);
      if (amount > 0) {
        IERC20(rewardToken).safeTransfer(__pipeline, amount);
      }
    }
  }

  /// @dev available source balance (tokens, matic etc).
  /// @return balance in source units
  function sourceBalance() public view virtual override returns (uint256) {
    return _erc20Balance(_SOURCE_TOKEN_SLOT.getAddress());
  }

  /// @dev underlying balance (LP tokens, collateral etc).
  /// @return balance in underlying units
  function outputBalance() public view virtual override returns (uint256) {
    return _erc20Balance(_OUTPUT_TOKEN_SLOT.getAddress());
  }

  /// @notice Pipeline can claim coins that are somehow transferred into the contract
  /// @param recipient Recipient address
  /// @param recipient Token address
  function salvageFromPipe(address recipient, address token) external virtual override onlyPipeline {
    // To make sure that governance cannot come in and take away the coins
    // checking first and last pipes only to have ability salvage tokens from inside pipeline
    if ((!hasPrevPipe() || !hasNextPipe())
      && (_SOURCE_TOKEN_SLOT.getAddress() == token || _OUTPUT_TOKEN_SLOT.getAddress() == token)) {
      return;
    }

    uint256 amount = _erc20Balance(token);
    if (amount > 0) {
      IERC20(token).safeTransfer(recipient, amount);
    }
  }

  // ***************************************
  // ************** INTERNAL HELPERS *******
  // ***************************************

  /// @dev Checks is pipe have next pipe connected
  /// @return true when connected
  function hasNextPipe() internal view returns (bool) {
    return _NEXT_PIPE_SLOT.getAddress() != address(0);
  }

  /// @dev Checks is pipe have previous pipe connected
  /// @return true when connected
  function hasPrevPipe() internal view returns (bool) {
    return _PREV_PIPE_SLOT.getAddress() != address(0);
  }

  /// @dev Transfers ERC20 token to next pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toNextPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasNextPipe()) {
      IERC20(_token).safeTransfer(_NEXT_PIPE_SLOT.getAddress(), amount);
    }
  }

  /// @dev Transfers ERC20 token to previous pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toPrevPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasPrevPipe()) {
      IERC20(_token).safeTransfer(_PREV_PIPE_SLOT.getAddress(), amount);
    }
  }

  /// @dev returns ERC20 token balance
  /// @param _token ERC20 token address
  /// @return balance for address(this)
  function _erc20Balance(address _token) internal view returns (uint256){
    return IERC20(_token).balanceOf(address(this));
  }

  /// @dev Approve to spend ERC20 token amount for spender
  /// @param _token ERC20 token address
  /// @param spender address
  /// @param amount to spend
  function _erc20Approve(address _token, address spender, uint256 amount) internal {
    IERC20(_token).safeApprove(spender, 0);
    IERC20(_token).safeApprove(spender, amount);
  }

  uint[32] private ______gap;
}

// SPDX-License-Identifier: ISC
//https://github.com/0xlaozi/qidao/blob/main/contracts/erc20Stablecoin/erc20Stablecoin.sol
pragma solidity 0.8.4;

interface IErc20Stablecoin {
//    PriceSource external ethPriceSource;
    function ethPriceSource() external view returns (address);
//
//    uint256 external _minimumCollateralPercentage;
    function _minimumCollateralPercentage() external view returns (uint256);
//    uint256 external vaultCount;
//    uint256 external closingFee;
    function closingFee() external view returns (uint256);
//    uint256 external openingFee;
    function openingFee() external view returns (uint256);
//
//    uint256 external treasury;
//    uint256 external tokenPeg;
//
//    mapping(uint256 => uint256) external vaultCollateral;
    function vaultCollateral(uint256 vaultID) external view returns (uint256);
//    mapping(uint256 => uint256) external vaultDebt;
    function vaultDebt(uint256 vaultID) external view returns (uint256);
//
//    uint256 external debtRatio;
//    uint256 external gainRatio;
//
//    address external stabilityPool;
//
//    ERC20Detailed external collateral;
    function collateral() external view returns (address);
//
//    ERC20Detailed external mai;
    function mai() external view returns (address);
//
//    uint8 external priceSourceDecimals;

//    mapping(address => uint256) external maticDebt;


    function getDebtCeiling() external view returns (uint256);

    function exists(uint256 vaultID) external view returns (bool);

    function getClosingFee() external view returns (uint256);

    function getOpeningFee() external view returns (uint256);

    function getTokenPriceSource() external view returns (uint256);

    function getEthPriceSource() external view returns (uint256);

    function createVault() external returns (uint256);

    function destroyVault(uint256 vaultID) external;

    function depositCollateral(uint256 vaultID, uint256 amount) external;

    function withdrawCollateral(uint256 vaultID, uint256 amount) external;

    function borrowToken(uint256 vaultID, uint256 amount) external;

    function payBackToken(uint256 vaultID, uint256 amount) external;

    function getPaid() external;

    function checkCost(uint256 vaultID) external view returns (uint256);

    function checkExtract(uint256 vaultID) external view returns (uint256);

    function checkCollateralPercentage(uint256 vaultID) external view returns(uint256);

    function checkLiquidation(uint256 vaultID) external view returns (bool);

    function liquidateVault(uint256 vaultID) external;

    function ownerOf(uint256 vaultID) external view returns (address);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IMaiStablecoinPipe {

  function setMaxImbalance(uint256 _maxImbalance) external;

  function maxImbalance() external view returns (uint256);

  function setTargetPercentage(uint256 _targetPercentage) external;

  function targetPercentage() external view returns (uint256);

  function vaultID() external view returns (uint256);

  function borrowToken() external view returns (address);

  function stablecoin() external view returns (address);

  function collateralNumerator() external view returns (uint);

  function collateralPercentage() external view returns (uint256);

  function liquidationPrice() external view returns (uint256);

  function availableMai() external view returns (uint256);

  function maxDeposit() external view returns (uint256);

  }

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPipe {

  function pipeline() external view returns (address);

  function name() external view returns (string memory);

  function sourceToken() external view returns (address);

  function outputToken() external view returns (address);

  function rewardTokens(uint index) external view returns (address);

  function rewardTokensLength() external view returns (uint);

  function prevPipe() external view returns (address);

  function nextPipe() external view returns (address);

  function setPipeline(address _pipeline) external;

  function setNextPipe(address _nextPipe) external;

  function setPrevPipe(address _prevPipe) external;

  function put(uint256 amount) external returns (uint256 output);

  function get(uint256 amount) external returns (uint256 output);

  function rebalance() external returns (uint256 imbalance, bool deficit);

  function needsRebalance() external view returns (bool);

  function claim() external;

  function sourceBalance() external view returns (uint256);

  function outputBalance() external view returns (uint256);

  function salvageFromPipe(address recipient, address token) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

library PipeLib {

  /// @dev Constant value to get or put all available token amount
  uint256 public constant MAX_AMOUNT = type(uint).max;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}