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
import "../interfaces/IControllable.sol";
import "../interfaces/IControllableExtended.sol";
import "../interfaces/IController.sol";

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


  function VERSION() external view returns (string memory);

  function addHardWorker(address _worker) external;

  function addStrategiesToSplitter(
    address _splitter,
    address[] memory _strategies
  ) external;

  function addStrategy(address _strategy) external;

  function addVaultsAndStrategies(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function announcer() external view returns (address);

  function bookkeeper() external view returns (address);

  function changeWhiteListStatus(address[] memory _targets, bool status)
  external;

  function controllerTokenMove(
    address _recipient,
    address _token,
    uint256 _amount
  ) external;

  function dao() external view returns (address);

  function distributor() external view returns (address);

  function doHardWork(address _vault) external;

  function feeRewardForwarder() external view returns (address);

  function fund() external view returns (address);

  function fundDenominator() external view returns (uint256);

  function fundKeeperTokenMove(
    address _fund,
    address _token,
    uint256 _amount
  ) external;

  function fundNumerator() external view returns (uint256);

  function fundToken() external view returns (address);

  function governance() external view returns (address);

  function hardWorkers(address) external view returns (bool);

  function initialize() external;

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function mintAndDistribute(uint256 totalAmount, bool mintAllAvailable)
  external;

  function mintHelper() external view returns (address);

  function psDenominator() external view returns (uint256);

  function psNumerator() external view returns (uint256);

  function psVault() external view returns (address);

  function pureRewardConsumers(address) external view returns (bool);

  function removeHardWorker(address _worker) external;

  function rewardDistribution(address) external view returns (bool);

  function rewardToken() external view returns (address);

  function setAnnouncer(address _newValue) external;

  function setBookkeeper(address newValue) external;

  function setDao(address newValue) external;

  function setDistributor(address _distributor) external;

  function setFeeRewardForwarder(address _feeRewardForwarder) external;

  function setFund(address _newValue) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setFundToken(address _newValue) external;

  function setGovernance(address newValue) external;

  function setMintHelper(address _newValue) external;

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setPsVault(address _newValue) external;

  function setPureRewardConsumers(address[] memory _targets, bool _flag)
  external;

  function setRewardDistribution(
    address[] memory _newRewardDistribution,
    bool _flag
  ) external;

  function setRewardToken(address _newValue) external;

  function setVaultController(address _newValue) external;

  function setVaultStrategyBatch(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function strategies(address) external view returns (bool);

  function strategyTokenMove(
    address _strategy,
    address _token,
    uint256 _amount
  ) external;

  function upgradeTetuProxyBatch(
    address[] memory _contracts,
    address[] memory _implementations
  ) external;

  function vaultController() external view returns (address);

  function vaults(address) external view returns (bool);

  function whiteList(address) external view returns (bool);
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

import "@tetu_io/tetu-contracts/contracts/base/governance/ControllableV2.sol";
import "@tetu_io/tetu-contracts/contracts/openzeppelin/SafeERC20.sol";
import "../../third_party/balancer/IBalancerGauge.sol";
import "../../third_party/balancer/IBalancerMinter.sol";
import "./IGaugeDepositor.sol";

contract GaugeDepositor is ControllableV2, IGaugeDepositor {
    using SafeERC20 for IERC20;

    string public constant GAUGE_DEPOSITOR_VERSION = "1.0.0";
    address private constant BAL_TOKEN = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

    // user (strategy) -> gauge -> amount
    mapping(address => mapping(address => uint)) internal _balanceInGauge;

    function initialize(address controller_) external initializer {
        initializeControllable(controller_);
    }

    modifier onlyValidStrategy() {
        require(IController(_controller()).isValidStrategy(msg.sender), "GD: denied");
        _;
    }

    function deposit(address token, uint amount, address gauge) external override onlyValidStrategy {
        require(IBalancerGauge(gauge).balanceOf(address(this)) == _balanceInGauge[msg.sender][gauge], "GD: denied");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _approveIfNeeds(token, amount, gauge);
        IBalancerGauge(gauge).deposit(amount);
        _balanceInGauge[msg.sender][gauge] += amount;
    }

    function withdraw(uint amount, address gauge) external override onlyValidStrategy {
        require(IBalancerGauge(gauge).balanceOf(address(this)) == _balanceInGauge[msg.sender][gauge], "GD: denied");
        IBalancerGauge(gauge).withdraw(amount, msg.sender);
        _balanceInGauge[msg.sender][gauge] -= amount;
    }

    function claimRewards(address[] memory tokens, address gauge) external override onlyValidStrategy {
        require(IBalancerGauge(gauge).balanceOf(address(this)) == _balanceInGauge[msg.sender][gauge], "GD: denied");
        IBalancerGauge(gauge).claim_rewards();
        IBalancerMinter(IBalancerGauge(gauge).bal_pseudo_minter()).mint(gauge);
        uint len = tokens.length;
        for (uint i; i < len; ++i) {
            uint b = IERC20(tokens[i]).balanceOf(address(this));
            if (b > 0) {
                IERC20(tokens[i]).safeTransfer(msg.sender, b);
            }
        }
    }

    function getBalance(address user, address gauge) external view override returns (uint) {
        return _balanceInGauge[user][gauge];
    }

    function _approveIfNeeds(address token, uint amount, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, type(uint).max);
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

interface IGaugeDepositor {

    function deposit(address token, uint amount, address gauge) external;

    function withdraw(uint amount, address gauge) external;

    function claimRewards(address[] memory tokens, address gauge) external;

    function getBalance(address user, address gauge) external view returns (uint);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/// @notice gauge-v2, see 0xc9b36096f5201ea332Db35d6D195774ea0D5988f
/// @dev see 20230316-child-chain-gauge-factory-v2 in balancer-deployments repository
interface IBalancerGauge {
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Deposit(address indexed _user, uint256 _value);
  event Withdraw(address indexed _user, uint256 _value);
  event UpdateLiquidityLimit(
    address indexed _user,
    uint256 _original_balance,
    uint256 _original_supply,
    uint256 _working_balance,
    uint256 _working_supply
  );

  function deposit(uint256 _value) external;

  function deposit(uint256 _value, address _user) external;

  function withdraw(uint256 _value) external;

  function withdraw(uint256 _value, address _user) external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (bool);

  function transfer(address _to, uint256 _value) external returns (bool);

  function increaseAllowance(address _spender, uint256 _added_value)
  external
  returns (bool);

  function decreaseAllowance(address _spender, uint256 _subtracted_value)
  external
  returns (bool);

  function user_checkpoint(address addr) external returns (bool);

  function claimable_tokens(address addr) external returns (uint256);

  function claimed_reward(address _addr, address _token)
  external
  view
  returns (uint256);

  function claimable_reward(address _user, address _reward_token)
  external
  view
  returns (uint256);

  function set_rewards_receiver(address _receiver) external;

  function claim_rewards() external;

  function claim_rewards(address _addr) external;

  function claim_rewards(address _addr, address _receiver) external;

  function claim_rewards(
    address _addr,
    address _receiver,
    uint256[] memory _reward_indexes
  ) external;

  function add_reward(address _reward_token, address _distributor) external;

  function set_reward_distributor(address _reward_token, address _distributor)
  external;

  function deposit_reward_token(address _reward_token, uint256 _amount)
  external;

  function killGauge() external;

  function unkillGauge() external;

  function decimals() external view returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function integrate_checkpoint() external view returns (uint256);

  function bal_token() external view returns (address);

  function bal_pseudo_minter() external view returns (address);

  function voting_escrow_delegation_proxy() external view returns (address);

  function authorizer_adaptor() external view returns (address);

  function initialize(address _lp_token, string memory _version) external;

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function nonces(address arg0) external view returns (uint256);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function balanceOf(address arg0) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function lp_token() external view returns (address);

  function version() external view returns (string memory);

  function factory() external view returns (address);

  function working_balances(address arg0) external view returns (uint256);

  function working_supply() external view returns (uint256);

  function period() external view returns (uint256);

  function period_timestamp(uint256 arg0) external view returns (uint256);

  function integrate_checkpoint_of(address arg0)
  external
  view
  returns (uint256);

  function integrate_fraction(address arg0) external view returns (uint256);

  function integrate_inv_supply(uint256 arg0) external view returns (uint256);

  function integrate_inv_supply_of(address arg0)
  external
  view
  returns (uint256);

  function reward_count() external view returns (uint256);

  function reward_tokens(uint256 arg0) external view returns (address);

  function reward_data(address arg0) external view returns (S_0 memory);

  function rewards_receiver(address arg0) external view returns (address);

  function reward_integral_for(address arg0, address arg1)
  external
  view
  returns (uint256);

  function is_killed() external view returns (bool);

  function inflation_rate(uint256 arg0) external view returns (uint256);
}

  struct S_0 {
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 last_update;
    uint256 integral;
  }

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IBalancerMinter {
  event Minted(address indexed recipient, address gauge, uint256 minted);
  event MinterApprovalSet(
    address indexed user,
    address indexed minter,
    bool approval
  );

  function allowed_to_mint_for(address minter, address user)
  external
  view
  returns (bool);

  function getBalancerToken() external view returns (address);

  function getBalancerTokenAdmin() external view returns (address);

  function getDomainSeparator() external view returns (bytes32);

  function getGaugeController() external view returns (address);

  function getMinterApproval(address minter, address user)
  external
  view
  returns (bool);

  function getNextNonce(address user) external view returns (uint256);

  function mint(address gauge) external returns (uint256);

  function mintFor(address gauge, address user) external returns (uint256);

  function mintMany(address[] memory gauges) external returns (uint256);

  function mintManyFor(address[] memory gauges, address user)
  external
  returns (uint256);

  function mint_for(address gauge, address user) external;

  function mint_many(address[8] memory gauges) external;

  function minted(address user, address gauge)
  external
  view
  returns (uint256);

  function setMinterApproval(address minter, bool approval) external;

  function setMinterApprovalWithSignature(
    address minter,
    bool approval,
    address user,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function toggle_approve_mint(address minter) external;
}