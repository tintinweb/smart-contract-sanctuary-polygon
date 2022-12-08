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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILiquidationPool.sol";
import "./interfaces/ITroveFactory.sol";
import "./interfaces/ITrove.sol";
import "./interfaces/IMintableToken.sol";

/// @title is used in case when stabilityPool is empty or not enough to liquidate trove
contract CommunityLiquidationPool is ILiquidationPool, Constants {
  using SafeERC20 for IERC20;
  ITroveFactory public immutable factory;
  uint256 public override liqTokenRate = DECIMAL_PRECISION;
  uint256 public override collateral;
  uint256 public override debt;
  IERC20 public immutable collateralToken;

  // solhint-disable-next-line func-visibility
  constructor(address _factory, address _token) {
    require(_factory != address(0x0) && _token != address(0x0), "65151f no zero addresses");
    factory = ITroveFactory(_factory);
    collateralToken = IERC20(_token);
  }

  /// @dev to approve trove, and let it liquidate itself further
  /// @param _trove address of the trove
  function approveTrove(address _trove) public override {
    require(msg.sender == address(factory), "1b023 only the factory is allowed to call");
    collateralToken.approve(_trove, MAX_INT);
  }

  /// @dev to unapprove trove, forbid it to liquidate itself further
  /// @param _trove address of the trove
  function unapproveTrove(address _trove) public override {
    require(msg.sender == address(factory), "cfec3 only the factory is allowed to call");
    collateralToken.approve(_trove, 0);
  }

  /// @dev to transfer collateral and decrease collateral and debt in the pool
  /// @param _unclaimedCollateral unclaimed collateral calculated in the trove
  /// @param _unclaimedDebt the unclaimed debt calculated in the trove
  function claimCollateralAndDebt(uint256 _unclaimedCollateral, uint256 _unclaimedDebt) external override {
    IERC20 tokenCache = collateralToken;
    require(factory.containsTrove(address(tokenCache), msg.sender), "c0e31 must be called from a valid trove");
    collateral -= _unclaimedCollateral;
    debt -= _unclaimedDebt;

    tokenCache.safeTransfer(msg.sender, _unclaimedCollateral);
  }

  /// @dev liquidates the trove that called it
  function liquidate() external override {
    ITroveFactory factoryCache = factory;
    IERC20 tokenCache = collateralToken;
    require(factoryCache.troveCount(address(tokenCache)) > 1, "c0e35 the last trove can not be liquidated");
    require(factoryCache.containsTrove(address(tokenCache), msg.sender), "c0e35 must be called from a valid trove");
    ITrove trove = ITrove(msg.sender);
    uint256 troveCollateral = trove.recordedCollateral();
    collateral += troveCollateral;
    debt += trove.debt();
    uint256 factoryCollateral = factoryCache.totalCollateral(address(tokenCache));
    liqTokenRate += (troveCollateral * liqTokenRate) / (factoryCollateral - troveCollateral); // = (FactoryCollateral / prevLiqCollateral)

    tokenCache.safeTransferFrom(msg.sender, address(this), troveCollateral);

    factoryCache.emitLiquidationEvent(address(tokenCache), msg.sender, address(0), troveCollateral);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFeeRecipient {
  function baseRate() external view returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  function calcDecayedBaseRate(uint256 _currentBaseRate) external view returns (uint256);

  /**
     @dev is called to make the FeeRecipient contract transfer the fees to itself. It will use transferFrom to get the
     fees from the msg.sender
     @param _amount the amount in Wei of fees to transfer
     */
  function takeFees(uint256 _amount) external returns (bool);

  function increaseBaseRate(uint256 _increase) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";

interface ILiquidationPool {
  function collateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function liqTokenRate() external view returns (uint256);

  function claimCollateralAndDebt(uint256 _unclaimedCollateral, uint256 _unclaimedDebt) external;

  function approveTrove(address _trove) external;

  function unapproveTrove(address _trove) external;

  function liquidate() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";

interface IMintableToken is IERC20, IOwnable {
  function mint(address recipient, uint256 amount) external;

  function burn(uint256 amount) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function approve(address spender, uint256 amount) external override returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./IMintableToken.sol";

interface IMintableTokenOwner is IOwnable {
  function token() external view returns (IMintableToken);

  function mint(address _recipient, uint256 _amount) external;

  function transferTokenOwnership(address _newOwner) external;

  function addMinter(address _newMinter) external;

  function revokeMinter(address _minter) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IStabilityPoolBase.sol";

interface IStabilityPool is IStabilityPoolBase {
  function arbitrage(
    uint256 _amountIn,
    address[] calldata _path,
    uint256 _deadline
  ) external;

  function setRouter(address _router) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITroveFactory.sol";
import "./IMintableToken.sol";

interface IStabilityPoolBase {
  function factory() external view returns (ITroveFactory);

  function stableCoin() external view returns (IMintableToken);

  function bonqToken() external view returns (IERC20);

  function totalDeposit() external view returns (uint256);

  function withdraw(uint256 _amount) external;

  function deposit(uint256 _amount) external;

  function redeemReward() external;

  function liquidate() external;

  function setBONQPerMinute(uint256 _bonqPerMinute) external;

  function setBONQAmountForRewards() external;

  function getDepositorBONQGain(address _depositor) external view returns (uint256);

  function getWithdrawableDeposit(address staker) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";

interface ITokenPriceFeed is IOwnable {
  struct TokenInfo {
    address priceFeed;
    uint256 mcr;
    uint256 mrf; // Maximum Redemption Fee
  }

  function tokenPriceFeed(address) external view returns (address);

  function tokenPrice(address _token) external view returns (uint256);

  function mcr(address _token) external view returns (uint256);

  function mrf(address _token) external view returns (uint256);

  function setTokenPriceFeed(
    address _token,
    address _priceFeed,
    uint256 _mcr,
    uint256 _maxRedemptionFeeBasisPoints
  ) external;

  function emitPriceUpdate(
    address _token,
    uint256 _priceAverage,
    uint256 _pricePoint
  ) external;

  event NewTokenPriceFeed(address _token, address _priceFeed, string _name, string _symbol, uint256 _mcr, uint256 _mrf);
  event PriceUpdate(address token, uint256 priceAverage, uint256 pricePoint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";
import "./ITroveFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrove is IOwnable {
  function factory() external view returns (ITroveFactory);

  function token() external view returns (IERC20);

  // solhint-disable-next-line func-name-mixedcase
  function TOKEN_PRECISION() external view returns (uint256);

  function mcr() external view returns (uint256);

  function collateralization() external view returns (uint256);

  function collateralValue() external view returns (uint256);

  function collateral() external view returns (uint256);

  function recordedCollateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function netDebt() external view returns (uint256);

  //  function rewardRatioSnapshot() external view returns (uint256);

  function initialize(
    //    address _factory,
    address _token,
    address _troveOwner
  ) external;

  function increaseCollateral(uint256 _amount, address _newNextTrove) external;

  function decreaseCollateral(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function borrow(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function repay(uint256 _amount, address _newNextTrove) external;

  function redeem(address _recipient, address _newNextTrove)
    external
    returns (uint256 _stableAmount, uint256 _collateralRecieved);

  function setArbitrageParticipation(bool _state) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./ITokenPriceFeed.sol";
import "./IMintableToken.sol";
import "./IMintableTokenOwner.sol";
import "./IFeeRecipient.sol";
import "./ILiquidationPool.sol";
import "./IStabilityPool.sol";
import "./ITrove.sol";

interface ITroveFactory {
  /* view */
  function lastTrove(address _trove) external view returns (address);

  function firstTrove(address _trove) external view returns (address);

  function nextTrove(address _token, address _trove) external view returns (address);

  function prevTrove(address _token, address _trove) external view returns (address);

  function containsTrove(address _token, address _trove) external view returns (bool);

  function stableCoin() external view returns (IMintableToken);

  function tokenOwner() external view returns (IMintableTokenOwner);

  function tokenToPriceFeed() external view returns (ITokenPriceFeed);

  function feeRecipient() external view returns (IFeeRecipient);

  function troveCount(address _token) external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function totalCollateral(address _token) external view returns (uint256);

  function totalDebtForToken(address _token) external view returns (uint256);

  function liquidationPool(address _token) external view returns (ILiquidationPool);

  function stabilityPool() external view returns (IStabilityPool);

  function arbitragePool() external view returns (address);

  function getRedemptionFeeRatio(address _trove) external view returns (uint256);

  function getRedemptionFee(uint256 _feeRatio, uint256 _amount) external pure returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  /* state changes*/
  function createTrove(address _token) external returns (ITrove trove);

  function createTroveAndBorrow(
    address _token,
    uint256 _collateralAmount,
    address _recipient,
    uint256 _borrowAmount,
    address _nextTrove
  ) external;

  function removeTrove(address _token, address _trove) external;

  function insertTrove(address _trove, address _newNextTrove) external;

  function updateTotalCollateral(
    address _token,
    uint256 _amount,
    bool _increase
  ) external;

  function updateTotalDebt(uint256 _amount, bool _borrow) external;

  function setStabilityPool(address _stabilityPool) external;

  function setArbitragePool(address _arbitragePool) external;

  // solhint-disable-next-line var-name-mixedcase
  function setWETH(address _WETH, address _liquidationPool) external;

  function increaseCollateralNative(address _trove, address _newNextTrove) external payable;

  /* utils */
  function emitLiquidationEvent(
    address _token,
    address _trove,
    address stabilityPoolLiquidation,
    uint256 collateral
  ) external;

  function emitTroveCollateralUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization
  ) external;

  function emitTroveDebtUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization,
    uint256 _feePaid
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Constants {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant LIQUIDATION_RESERVE = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant PERCENT = (DECIMAL_PRECISION * 1) / 100; // 1%
  uint256 public constant PERCENT10 = PERCENT * 10; // 10%
  uint256 public constant PERCENT_05 = PERCENT / 2; // 0.5%
  uint256 public constant BORROWING_RATE = PERCENT_05;
  uint256 public constant MAX_BORROWING_RATE = (DECIMAL_PRECISION * 5) / 100; // 5%
}