// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

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

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/WadRayMath.sol";
import "../interfaces/IVaultsCore.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

contract VaultsCore is IVaultsCore, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using WadRayMath for uint256;

  uint256 internal constant _MAX_INT = 2**256 - 1;

  IAddressProvider public override a;
  IWETH public override WETH;
  IVaultsCoreState public override state;
  IDebtNotifier public override debtNotifier;

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender));
    _;
  }

  modifier onlyVaultOwner(uint256 _vaultId) {
    require(a.vaultsData().vaultOwner(_vaultId) == msg.sender);
    _;
  }

  constructor(
    IAddressProvider _addresses,
    IWETH _IWETH,
    IVaultsCoreState _vaultsCoreState
  ) public {
    require(address(_addresses) != address(0));
    require(address(_IWETH) != address(0));
    require(address(_vaultsCoreState) != address(0));
    a = _addresses;
    WETH = _IWETH;
    state = _vaultsCoreState;
  }

  // For a contract to receive ETH, it needs to have a payable fallback function
  // https://ethereum.stackexchange.com/a/47415
  receive() external payable {
    require(msg.sender == address(WETH));
  }

  /*
    Allow smooth upgrading of the vaultscore.
    @dev this function approves token transfers to the new vaultscore of
    both stablex and all configured collateral types
    @param _newVaultsCore address of the new vaultscore
  */
  function upgrade(address payable _newVaultsCore) public override onlyManager {
    require(address(_newVaultsCore) != address(0));
    require(a.stablex().approve(_newVaultsCore, _MAX_INT));

    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      IERC20 asset = IERC20(collateralType);
      asset.safeApprove(_newVaultsCore, _MAX_INT);
    }
  }

  /*
    Allow smooth upgrading of the VaultsCore.
    @dev this function transfers both PAR and all configured collateral
    types to the new vaultscore.
  */
  function acceptUpgrade(address payable _oldVaultsCore) public override onlyManager {
    IERC20 stableX = IERC20(a.stablex());
    stableX.safeTransferFrom(_oldVaultsCore, address(this), stableX.balanceOf(_oldVaultsCore));

    for (uint256 i = 1; i <= a.config().numCollateralConfigs(); i++) {
      address collateralType = a.config().collateralConfigs(i).collateralType;
      IERC20 asset = IERC20(collateralType);
      asset.safeTransferFrom(_oldVaultsCore, address(this), asset.balanceOf(_oldVaultsCore));
    }
  }

  /**
    Configure the debt notifier.
    @param _debtNotifier the new DebtNotifier module address.
  **/
  function setDebtNotifier(IDebtNotifier _debtNotifier) public override onlyManager {
    require(address(_debtNotifier) != address(0));
    debtNotifier = _debtNotifier;
  }

  /**
    Deposit an ERC20 token into the vault of the msg.sender as collateral
    @dev A new vault is created if no vault exists for the `msg.sender` with the specified collateral type.
    this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _collateralType the address of the collateral type to be deposited
    @param _amount the amount of tokens to be deposited in WEI.
  **/
  function deposit(address _collateralType, uint256 _amount) public override {
    require(a.config().collateralIds(_collateralType) != 0);

    IERC20 asset = IERC20(_collateralType);
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    _addCollateralToVault(_collateralType, _amount);
  }

  /**
    Wraps ETH and deposits WETH into the vault of the msg.sender as collateral
    @dev A new vault is created if no WETH vault exists
  **/
  function depositETH() public payable override {
    WETH.deposit{ value: msg.value }();
    _addCollateralToVault(address(WETH), msg.value);
  }

  /**
    Deposit an ERC20 token into the specified vault as collateral
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _vaultId the address of the collateral type to be deposited
    @param _amount the amount of tokens to be deposited in WEI.
  **/
  function depositByVaultId(uint256 _vaultId, uint256 _amount) public override {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(v.collateralType != address(0));

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    _addCollateralToVaultById(_vaultId, _amount);
  }

  /**
    Wraps ETH and deposits WETH into the specified vault as collateral
    @dev this function uses `transferFrom()` and requires pre-approval via `approve()` on the ERC20.
    @param _vaultId the address of the collateral type to be deposited
  **/
  function depositETHByVaultId(uint256 _vaultId) public payable override {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(v.collateralType == address(WETH));

    WETH.deposit{ value: msg.value }();

    _addCollateralToVaultById(_vaultId, msg.value);
  }

  /**
    Deposit an ERC20 token into the vault of the msg.sender as collateral and borrows the specified amount of tokens in WEI
    @dev see deposit() and borrow()
    @param _collateralType the address of the collateral type to be deposited
    @param _depositAmount the amount of tokens to be deposited in WEI.
    @param _borrowAmount the amount of borrowed StableX tokens in WEI.
  **/
  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) public override {
    deposit(_collateralType, _depositAmount);
    uint256 vaultId = a.vaultsData().vaultId(_collateralType, msg.sender);
    borrow(vaultId, _borrowAmount);
  }

  /**
    Wraps ETH and deposits WETH into the vault of the msg.sender as collateral and borrows the specified amount of tokens in WEI
    @dev see depositETH() and borrow()
    @param _borrowAmount the amount of borrowed StableX tokens in WEI.
  **/
  function depositETHAndBorrow(uint256 _borrowAmount) public payable override {
    depositETH();
    uint256 vaultId = a.vaultsData().vaultId(address(WETH), msg.sender);
    borrow(vaultId, _borrowAmount);
  }

  function _addCollateralToVault(address _collateralType, uint256 _amount) internal {
    uint256 vaultId = a.vaultsData().vaultId(_collateralType, msg.sender);
    if (vaultId == 0) {
      vaultId = a.vaultsData().createVault(_collateralType, msg.sender);
    }

    _addCollateralToVaultById(vaultId, _amount);
  }

  function _addCollateralToVaultById(uint256 _vaultId, uint256 _amount) internal {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    a.vaultsData().setCollateralBalance(_vaultId, v.collateralBalance.add(_amount));

    emit Deposited(_vaultId, _amount, msg.sender);
  }

  /**
    Withdraws ERC20 tokens from a vault.
    @dev Only the owner of a vault can withdraw collateral from it.
    `withdraw()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
    @param _amount the amount of ERC20 tokens to be withdrawn in WEI.
  **/
  function withdraw(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    _removeCollateralFromVault(_vaultId, _amount);
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, _amount);
  }

  /**
    Withdraws ETH from a WETH vault.
    @dev Only the owner of a vault can withdraw collateral from it.
    `withdraw()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to withdraw the collateral.
    @param _amount the amount of ETH to be withdrawn in WEI.
  **/
  function withdrawETH(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    _removeCollateralFromVault(_vaultId, _amount);
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    require(v.collateralType == address(WETH));

    WETH.withdraw(_amount);
    msg.sender.transfer(_amount);
  }

  function _removeCollateralFromVault(uint256 _vaultId, uint256 _amount) internal {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);
    require(_amount <= v.collateralBalance);
    uint256 newCollateralBalance = v.collateralBalance.sub(_amount);
    a.vaultsData().setCollateralBalance(_vaultId, newCollateralBalance);
    if (v.baseDebt > 0) {
      // Save gas cost when withdrawing from 0 debt vault
      state.refreshCollateral(v.collateralType);
      uint256 newCollateralValue = a.priceFeed().convertFrom(v.collateralType, newCollateralBalance);
      require(
        a.liquidationManager().isHealthy(
          newCollateralValue,
          a.vaultsData().vaultDebt(_vaultId),
          a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).minCollateralRatio
        )
      );
    }

    emit Withdrawn(_vaultId, _amount, msg.sender);
  }

  /**
    Borrow new PAR tokens from a vault.
    @dev Only the owner of a vault can borrow from it.
    `borrow()` will update the outstanding vault debt to the current time before attempting the withdrawal.
     `borrow()` will fail if it would bring the vault below the minimum collateralization treshold.
    @param _vaultId the ID of the vault from which to borrow.
    @param _amount the amount of borrowed PAR tokens in WEI.
  **/
  function borrow(uint256 _vaultId, uint256 _amount) public override onlyVaultOwner(_vaultId) nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    // Make sure current rate is up to date
    state.refreshCollateral(v.collateralType);

    uint256 originationFeePercentage = a.config().collateralOriginationFee(v.collateralType);
    uint256 newDebt = _amount;
    if (originationFeePercentage > 0) {
      newDebt = newDebt.add(_amount.wadMul(originationFeePercentage));
    }

    // Increment vault borrow balance
    uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(newDebt, cumulativeRates(v.collateralType));

    a.vaultsData().setBaseDebt(_vaultId, v.baseDebt.add(newBaseDebt));

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 newVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(a.vaultsData().collateralDebt(v.collateralType) <= a.config().collateralDebtLimit(v.collateralType));

    bool isHealthy = a.liquidationManager().isHealthy(
      collateralValue,
      newVaultDebt,
      a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).minCollateralRatio
    );
    require(isHealthy);

    a.stablex().mint(msg.sender, _amount);
    debtNotifier.debtChanged(_vaultId);
    emit Borrowed(_vaultId, _amount, msg.sender);
  }

  /**
    Convenience function to repay all debt of a vault
    @dev `repayAll()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the debt.
  **/
  function repayAll(uint256 _vaultId) public override {
    repay(_vaultId, _MAX_INT);
  }

  /**
    Repay an outstanding PAR balance to a vault.
    @dev `repay()` will update the outstanding vault debt to the current time.
    @param _vaultId the ID of the vault for which to repay the outstanding debt balance.
    @param _amount the amount of PAR tokens in WEI to be repaid.
  **/
  function repay(uint256 _vaultId, uint256 _amount) public override nonReentrant {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    // Make sure current rate is up to date
    state.refreshCollateral(collateralType);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    // Decrement vault borrow balance
    if (_amount >= currentVaultDebt) {
      //full repayment
      _amount = currentVaultDebt; //only pay back what's outstanding
    }
    _reduceVaultDebt(_vaultId, _amount);
    a.stablex().burn(msg.sender, _amount);
    debtNotifier.debtChanged(_vaultId);
    emit Repaid(_vaultId, _amount, msg.sender);
  }

  /**
    Internal helper function to reduce the debt of a vault.
    @dev assumes cumulative rates for the vault's collateral type are up to date.
    please call `refreshCollateral()` before calling this function.
    @param _vaultId the ID of the vault for which to reduce the debt.
    @param _amount the amount of debt to be reduced.
  **/
  function _reduceVaultDebt(uint256 _vaultId, uint256 _amount) internal {
    address collateralType = a.vaultsData().vaultCollateralType(_vaultId);

    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);
    uint256 remainder = currentVaultDebt.sub(_amount);
    uint256 cumulativeRate = cumulativeRates(collateralType);

    if (remainder == 0) {
      a.vaultsData().setBaseDebt(_vaultId, 0);
    } else {
      uint256 newBaseDebt = a.ratesManager().calculateBaseDebt(remainder, cumulativeRate);
      a.vaultsData().setBaseDebt(_vaultId, newBaseDebt);
    }
  }

  /**
    Liquidate a vault that is below the liquidation treshold by repaying its outstanding debt.
    @dev `liquidate()` will update the outstanding vault debt to the current time and pay a `liquidationBonus`
    to the liquidator. `liquidate()` can be called by anyone.
    @param _vaultId the ID of the vault to be liquidated.
  **/
  function liquidate(uint256 _vaultId) public override {
    liquidatePartial(_vaultId, _MAX_INT);
  }

  /**
    Liquidate a vault partially that is below the liquidation treshold by repaying part of its outstanding debt.
    @dev `liquidatePartial()` will update the outstanding vault debt to the current time and pay a `liquidationBonus`
    to the liquidator. A LiquidationFee will be applied to the borrower during the liquidation.
    This means that the change in outstanding debt can be smaller than the repaid amount.
    `liquidatePartial()` can be called by anyone.
    @param _vaultId the ID of the vault to be liquidated.
    @param _amount the amount of debt+liquidationFee to repay.
  **/
  function liquidatePartial(uint256 _vaultId, uint256 _amount) public override nonReentrant {
    IVaultsDataProvider.Vault memory v = a.vaultsData().vaults(_vaultId);

    state.refreshCollateral(v.collateralType);

    uint256 collateralValue = a.priceFeed().convertFrom(v.collateralType, v.collateralBalance);
    uint256 currentVaultDebt = a.vaultsData().vaultDebt(_vaultId);

    require(
      !a.liquidationManager().isHealthy(
        collateralValue,
        currentVaultDebt,
        a.config().collateralConfigs(a.config().collateralIds(v.collateralType)).liquidationRatio
      )
    );

    uint256 repaymentAfterLiquidationFeeRatio = WadRayMath.wad().sub(
      a.config().collateralLiquidationFee(v.collateralType)
    );
    uint256 maxLiquiditionCost = currentVaultDebt.wadDiv(repaymentAfterLiquidationFeeRatio);

    uint256 repayAmount;

    if (_amount > maxLiquiditionCost) {
      _amount = maxLiquiditionCost;
      repayAmount = currentVaultDebt;
    } else {
      repayAmount = _amount.wadMul(repaymentAfterLiquidationFeeRatio);
    }

    // collateral value to be received by the liquidator is based on the total amount repaid (including the liquidationFee).
    uint256 collateralValueToReceive = _amount.add(a.liquidationManager().liquidationBonus(v.collateralType, _amount));
    uint256 insuranceAmount = 0;
    if (collateralValueToReceive >= collateralValue) {
      // Not enough collateral for debt & liquidation fee
      collateralValueToReceive = collateralValue;
      uint256 discountedCollateralValue = a.liquidationManager().applyLiquidationDiscount(
        v.collateralType,
        collateralValue
      );

      if (currentVaultDebt > discountedCollateralValue) {
        // Not enough collateral for debt alone
        insuranceAmount = currentVaultDebt.sub(discountedCollateralValue);
        require(a.stablex().balanceOf(address(this)) >= insuranceAmount);
        a.stablex().burn(address(this), insuranceAmount); // Insurance uses local reserves to pay down debt
        emit InsurancePaid(_vaultId, insuranceAmount, msg.sender);
      }

      repayAmount = currentVaultDebt.sub(insuranceAmount);
      _amount = discountedCollateralValue;
    }

    // reduce the vault debt by repayAmount
    _reduceVaultDebt(_vaultId, repayAmount.add(insuranceAmount));
    a.stablex().burn(msg.sender, _amount);

    // send the claimed collateral to the liquidator
    uint256 collateralToReceive = a.priceFeed().convertTo(v.collateralType, collateralValueToReceive);
    a.vaultsData().setCollateralBalance(_vaultId, v.collateralBalance.sub(collateralToReceive));
    IERC20 asset = IERC20(v.collateralType);
    asset.safeTransfer(msg.sender, collateralToReceive);

    debtNotifier.debtChanged(_vaultId);

    emit Liquidated(_vaultId, repayAmount, collateralToReceive, v.owner, msg.sender);
  }

  /**
    Returns the cumulativeRate of a collateral type. This function exists for
    backwards compatibility with the VaultsDataProvider.
    @param _collateralType the address of the collateral type.
  **/
  function cumulativeRates(address _collateralType) public view override returns (uint256) {
    return state.cumulativeRates(_collateralType);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAccessController {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAccessController.sol";
import "./IConfigProvider.sol";
import "./ISTABLEX.sol";
import "./IPriceFeed.sol";
import "./IRatesManager.sol";
import "./ILiquidationManager.sol";
import "./IVaultsCore.sol";
import "./IVaultsDataProvider.sol";
import "./IFeeDistributor.sol";

interface IAddressProvider {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProvider _config) external;

  function setVaultsCore(IVaultsCore _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManager _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProvider);

  function core() external view returns (IVaultsCore);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManager);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IConfigProvider {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 liquidationRatio;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
    uint256 liquidationBonus;
    uint256 liquidationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 liquidationRatio,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee,
    uint256 liquidationBonus,
    uint256 liquidationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus) external;

  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) external;

  function setMinVotingPeriod(uint256 _minVotingPeriod) external;

  function setMaxVotingPeriod(uint256 _maxVotingPeriod) external;

  function setVotingQuorum(uint256 _votingQuorum) external;

  function setProposalThreshold(uint256 _proposalThreshold) external;

  function a() external view returns (IAddressProvider);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function minVotingPeriod() external view returns (uint256);

  function maxVotingPeriod() external view returns (uint256);

  function votingQuorum() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralLiquidationRatio(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);

  function collateralLiquidationBonus(address _collateralType) external view returns (uint256);

  function collateralLiquidationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IFeeDistributor {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProvider);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface ILiquidationManager {
  function a() external view returns (IAddressProvider);

  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(address _collateralType, uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    external
    view
    returns (uint256 discountedAmount);

  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../chainlink/AggregatorV3Interface.sol";
import "../interfaces/IAddressProvider.sol";

interface IPriceFeed {
  event OracleUpdated(address indexed asset, address oracle, address sender);
  event EurOracleUpdated(address oracle, address sender);

  function setAssetOracle(address _asset, address _oracle) external;

  function setEurOracle(address _oracle) external;

  function a() external view returns (IAddressProvider);

  function assetOracles(address _asset) external view returns (AggregatorV3Interface);

  function eurOracle() external view returns (AggregatorV3Interface);

  function getAssetPrice(address _asset) external view returns (uint256);

  function convertFrom(address _asset, uint256 _amount) external view returns (uint256);

  function convertTo(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IRatesManager {
  function a() external view returns (IAddressProvider);

  //current annualized borrow rate
  function annualizedBorrowRate(uint256 _currentBorrowRate) external pure returns (uint256);

  //uses current cumulative rate to calculate totalDebt based on baseDebt at time T0
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) external pure returns (uint256);

  //uses current cumulative rate to calculate baseDebt at time T0
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) external pure returns (uint256);

  //calculate a new cumulative rate
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAddressProvider.sol";

interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../interfaces/IWETH.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

interface IVaultsCore {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function depositETH() external payable;

  function depositByVaultId(uint256 _vaultId, uint256 _amount) external;

  function depositETHByVaultId(uint256 _vaultId) external payable;

  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) external;

  function depositETHAndBorrow(uint256 _borrowAmount) external payable;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawETH(uint256 _vaultId, uint256 _amount) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  function liquidatePartial(uint256 _vaultId, uint256 _amount) external;

  function upgrade(address payable _newVaultsCore) external;

  function acceptUpgrade(address payable _oldVaultsCore) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function WETH() external view returns (IWETH);

  function debtNotifier() external view returns (IDebtNotifier);

  function state() external view returns (IVaultsCoreState);

  function cumulativeRates(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProvider.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";

interface IVaultsCoreState {
  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  function syncState(IVaultsCoreState _stateAddress) external;

  function syncStateFromV1(IVaultsCoreV1 _core) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);

  function synced() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";

interface IVaultsDataProvider {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  // Read
  function a() external view returns (IAddressProvider);

  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;

  function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
  using SafeMath for uint256;

  uint256 internal constant _WAD = 1e18;
  uint256 internal constant _HALF_WAD = _WAD / 2;

  uint256 internal constant _RAY = 1e27;
  uint256 internal constant _HALF_RAY = _RAY / 2;

  uint256 internal constant _WAD_RAY_RATIO = 1e9;

  function ray() internal pure returns (uint256) {
    return _RAY;
  }

  function wad() internal pure returns (uint256) {
    return _WAD;
  }

  function halfRay() internal pure returns (uint256) {
    return _HALF_RAY;
  }

  function halfWad() internal pure returns (uint256) {
    return _HALF_WAD;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_WAD.add(a.mul(b)).div(_WAD);
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_WAD)).div(b);
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_RAY.add(a.mul(b)).div(_RAY);
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_RAY)).div(b);
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = _WAD_RAY_RATIO / 2;

    return halfRatio.add(a).div(_WAD_RAY_RATIO);
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a.mul(_WAD_RAY_RATIO);
  }

  /**
   * @dev calculates x^n, in ray. The code uses the ModExp precompile
   * @param x base
   * @param n exponent
   * @return z = x^n, in ray
   */
  function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : _RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rayMul(x, x);

      if (n % 2 != 0) {
        z = rayMul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../../interfaces/IAddressProvider.sol";
import "./ISupplyMiner.sol";

interface IDebtNotifier {
  function debtChanged(uint256 _vaultId) external;

  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) external;

  function a() external view returns (IAddressProvider);

  function collateralSupplyMinerMapping(address collateral) external view returns (ISupplyMiner);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface ISupplyMiner {
  function baseDebtChanged(address user, uint256 newBaseDebt) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IConfigProviderV1.sol";
import "./ILiquidationManagerV1.sol";
import "./IVaultsCoreV1.sol";
import "../../interfaces/IVaultsCore.sol";
import "../../interfaces/IAccessController.sol";
import "../../interfaces/ISTABLEX.sol";
import "../../interfaces/IPriceFeed.sol";
import "../../interfaces/IRatesManager.sol";
import "../../interfaces/IVaultsDataProvider.sol";
import "../../interfaces/IFeeDistributor.sol";

interface IAddressProviderV1 {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProviderV1 _config) external;

  function setVaultsCore(IVaultsCoreV1 _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManagerV1 _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProviderV1);

  function core() external view returns (IVaultsCoreV1);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManagerV1);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAddressProviderV1.sol";

interface IConfigProviderV1 {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setLiquidationBonus(uint256 _bonus) external;

  function a() external view returns (IAddressProviderV1);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function liquidationBonus() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAddressProviderV1.sol";

interface ILiquidationManagerV1 {
  function a() external view returns (IAddressProviderV1);

  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(uint256 _amount) external view returns (uint256 discountedAmount);

  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProviderV1.sol";

interface IVaultsCoreV1 {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawAll(uint256 _vaultId) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  //Refresh
  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  //upgrade
  function upgrade(address _newVaultsCore) external;

  //Read only

  function a() external view returns (IAddressProviderV1);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);
}