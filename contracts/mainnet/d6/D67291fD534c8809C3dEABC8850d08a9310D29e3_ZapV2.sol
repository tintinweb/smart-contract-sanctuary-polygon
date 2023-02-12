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

import "../../openzeppelin/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../base/governance/Controllable.sol";
import "../../base/interface/ISmartVault.sol";
import "./ZapV2UniswapLibrary.sol";
import "./ZapV2CommonLibrary.sol";
import "./ZapV2Balancer1Library.sol";
import "./ZapV2Balancer2Library.sol";

/// @title The second generation of dedicated solution for interacting with Tetu vaults.
///        Able to zap in/out assets to vaults.
/// @author a17
contract ZapV2 is Controllable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant VERSION = "1.1.0";
    mapping(address => uint) private calls;

    constructor(address controller_) {
        Controllable.initializeControllable(controller_);
    }

    modifier onlyOneCallPerBlock() {
        require(calls[msg.sender] < block.number, "ZC: call in the same block forbidden");
        _;
        calls[msg.sender] = block.number;
    }

    // ******************** USERS ZAP ACTIONS *********************

    function zapIntoSingle(
        address vault,
        address tokenIn,
        bytes memory assetSwapData,
        uint tokenInAmount
    ) external nonReentrant onlyOneCallPerBlock {
        require(tokenInAmount > 1, "ZC: not enough amount");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

        address asset = ISmartVault(vault).underlying();

        if (tokenIn != asset) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmount,
                assetSwapData
            );
        }

        uint assetAmount = IERC20(asset).balanceOf(address(this));

        ZapV2CommonLibrary._depositToVault(vault, asset, assetAmount);

        if (tokenIn != asset) {
            address[] memory dustAssets = new address[](2);
            dustAssets[0] = asset;
            dustAssets[1] = tokenIn;
            ZapV2CommonLibrary._sendBackChange(dustAssets);
        } else {
            address[] memory dustAssets = new address[](1);
            dustAssets[0] = asset;
            ZapV2CommonLibrary._sendBackChange(dustAssets);
        }
    }

    function zapOutSingle(
        address vault,
        address tokenOut,
        bytes memory assetSwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        require(shareAmount != 0, "ZC: zero amount");

        IERC20(vault).safeTransferFrom(msg.sender, address(this), shareAmount);

        address asset = ISmartVault(vault).underlying();

        uint assetBalance = ZapV2CommonLibrary._withdrawFromVault(vault, asset, shareAmount);

        if (tokenOut != asset) {
            ZapV2CommonLibrary._callOneInchSwap(
                asset,
                assetBalance,
                assetSwapData
            );
        }

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);

        address[] memory dustAssets = new address[](1);
        dustAssets[0] = asset;
        ZapV2CommonLibrary._sendBackChange(dustAssets);
    }

    function zapIntoUniswapV2(
        address vault,
        address tokenIn,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint tokenInAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2UniswapLibrary.zapIntoUniswapV2(vault, tokenIn, asset0SwapData, asset1SwapData, tokenInAmount);
    }

    function zapOutUniswapV2(
        address vault,
        address tokenOut,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2UniswapLibrary.zapOutUniswapV2(vault, tokenOut, asset0SwapData, asset1SwapData, shareAmount);
    }

    function zapIntoBalancer(
        address vault,
        address tokenIn,
        address[] memory assets,
        bytes[] memory assetsSwapData,
        uint[] memory tokenInAmounts
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer1Library.zapIntoBalancer(vault, tokenIn, assets, assetsSwapData, tokenInAmounts);
    }

    function zapOutBalancer(
        address vault,
        address tokenOut,
        address[] memory assets,
        uint[] memory amounts,
        bytes[] memory assetsSwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer1Library.zapOutBalancer(vault, tokenOut, assets, amounts, assetsSwapData, shareAmount);
    }

    function zapIntoBalancerAaveBoostedStablePool(
        address tokenIn,
        bytes[] memory assetsSwapData,
        uint[] memory tokenInAmounts // calculated off-chain
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer1Library.zapIntoBalancerAaveBoostedStablePool(tokenIn, assetsSwapData, tokenInAmounts);
    }

    function zapOutBalancerAaveBoostedStablePool(
        address tokenOut,
        bytes[] memory assetsSwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer1Library.zapOutBalancerAaveBoostedStablePool(tokenOut, assetsSwapData, shareAmount);
    }

    function zapIntoBalancerTetuBal(
        address tokenIn,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint tokenInAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer2Library.zapIntoBalancerTetuBal(tokenIn, asset0SwapData, asset1SwapData, tokenInAmount);
    }

    function zapOutBalancerTetuBal(
        address tokenOut,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer2Library.zapOutBalancerTetuBal(tokenOut, asset0SwapData, asset1SwapData, shareAmount);
    }

    function zapIntoBalancerTetuQiQi(
        address tokenIn,
        bytes memory assetSwapData,
        uint tokenInAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer2Library.zapIntoBalancerTetuQiQi(tokenIn, assetSwapData, tokenInAmount);
    }

    function zapOutBalancerTetuQiQi(
        address tokenOut,
        bytes memory assetSwapData,
        uint shareAmount
    ) external nonReentrant onlyOneCallPerBlock {
        ZapV2Balancer2Library.zapOutBalancerTetuQiQi(tokenOut, assetSwapData, shareAmount);
    }

    // ******************** QUOTE HELPERS *********************

    function quoteIntoSingle(address vault, uint amount) external view returns(uint) {
        return amount * IERC20(vault).totalSupply() / ISmartVault(vault).underlyingBalanceWithInvestment();
    }

    function quoteOutSingle(address vault, uint shareAmount, uint gap) external view returns(uint) {
        /// @dev -1 need for stable zapOuts on all supported SmartVaults
        ///      gap need for unusual vaults
        return shareAmount * ISmartVault(vault).underlyingBalanceWithInvestment() / IERC20(vault).totalSupply() * (1e8 - gap) / 1e8 - 1;
    }

    function quoteIntoUniswapV2(address vault, uint amount0, uint amount1) external view returns(uint) {
        return ZapV2UniswapLibrary.quoteIntoUniswapV2(vault, amount0, amount1);
    }

    function quoteOutUniswapV2(address vault, uint shareAmount) external view returns(uint[] memory) {
        return ZapV2UniswapLibrary.quoteOutUniswapV2(vault, shareAmount);
    }

    function quoteIntoBalancer(address vault, address[] memory assets, uint[] memory amounts) external returns(uint) {
        return ZapV2Balancer1Library.quoteIntoBalancer(vault, assets, amounts);
    }

    /// @dev Quote out for ComposableStablePool with Phantom BPT.
    ///      This unusual algorithm is used due to the impossibility of using EXACT_BPT_IN_FOR_ALL_TOKENS_OUT.
    ///      We think it's can be better than queryBatchSwap for such pools.
    function quoteOutBalancer(address vault, address[] memory assets, uint shareAmount) external view returns(uint[] memory) {
        return ZapV2Balancer1Library.quoteOutBalancer(vault, assets, shareAmount);
    }

    function quoteIntoBalancerAaveBoostedStablePool(uint[] memory amounts) external returns(uint) {
        return ZapV2Balancer1Library.quoteIntoBalancerAaveBoostedStablePool(amounts);
    }

    function quoteOutBalancerAaveBoostedStablePool(uint shareAmount) external returns(uint[] memory) {
        return ZapV2Balancer1Library.quoteOutBalancerAaveBoostedStablePool(shareAmount);
    }

    function quoteIntoBalancerTetuBal(uint wethAmount, uint balAmount) external returns(uint) {
        return ZapV2Balancer2Library.quoteIntoBalancerTetuBal(wethAmount, balAmount);
    }

    function quoteOutBalancerTetuBal(uint amount) external returns(uint[] memory) {
        return ZapV2Balancer2Library.quoteOutBalancerTetuBal(amount);
    }

    function quoteIntoBalancerTetuQiQi(uint qiAmount) external returns(uint) {
        return ZapV2Balancer2Library.quoteIntoBalancerTetuQiQi(qiAmount);
    }

    function quoteOutBalancerTetuQiQi(uint shareAmount) external returns(uint) {
        return ZapV2Balancer2Library.quoteOutBalancerTetuQiQi(shareAmount);
    }

    // ******************** DATA EXTRACTION HELPERS *********************

    function getBalancerPoolTokens(address bpt) external view returns(
        IERC20[] memory,
        uint[] memory
    ) {
        return ZapV2Balancer2Library.getBalancerPoolTokens(bpt);
    }

    // ************************* GOV ACTIONS *******************

    /// @notice Controller or Governance can claim coins that are somehow transferred into the contract
    /// @param token Token address
    /// @param amount Token amount
    function salvage(address token, uint amount) external onlyControllerOrGovernance {
        IERC20(token).safeTransfer(msg.sender, amount);
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

// SPDX-License-Identifier: MIT

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
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
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

interface ISmartVault {

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account)
  external
  view
  returns (uint256);

  function earnedWithBoost(address rt, address account)
  external
  view
  returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsAndRedirect(address owner) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt)
  external
  view
  returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(
    address _rewardToken,
    uint256 _amount
  ) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount)
  external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address)
  external
  view
  returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setRewardsRedirect(address owner, address receiver) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder)
  external
  view
  returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address)
  external
  view
  returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
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

import "../../openzeppelin/Math.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../base/interface/ISmartVault.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "./ZapV2CommonLibrary.sol";

library ZapV2UniswapLibrary {
    using SafeERC20 for IERC20;

    function zapIntoUniswapV2(
        address vault,
        address tokenIn,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint tokenInAmount
    ) public {
        require(tokenInAmount > 1, "ZC: not enough amount");

        IUniswapV2Pair lp = IUniswapV2Pair(ISmartVault(vault).underlying());

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount / 2 * 2);

        address asset0 = lp.token0();
        address asset1 = lp.token1();

        if (tokenIn != asset0) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmount / 2,
                asset0SwapData
            );
        }

        if (tokenIn != asset1) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmount / 2,
                asset1SwapData
            );
        }

        uint lpAmount = _addLiquidityUniswapV2(address(lp), asset0, asset1);

        ZapV2CommonLibrary._depositToVault(vault, address(lp), lpAmount);

        address[] memory dustAssets = new address[](2);
        dustAssets[0] = asset0;
        dustAssets[1] = asset1;
        ZapV2CommonLibrary._sendBackChange(dustAssets);
    }

    function zapOutUniswapV2(
        address vault,
        address tokenOut,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint shareAmount
    ) external {
        require(shareAmount != 0, "ZC: zero amount");

        IERC20(vault).safeTransferFrom(msg.sender, address(this), shareAmount);

        address lp = ISmartVault(vault).underlying();

        uint lpBalance = ZapV2CommonLibrary._withdrawFromVault(vault, lp, shareAmount);

        IERC20(lp).safeTransfer(lp, lpBalance);

        (uint amount0, uint amount1) = IUniswapV2Pair(lp).burn(address(this));
        address asset0 = IUniswapV2Pair(lp).token0();
        address asset1 = IUniswapV2Pair(lp).token1();

        if (tokenOut != asset0) {
            ZapV2CommonLibrary._callOneInchSwap(
                asset0,
                amount0,
                asset0SwapData
            );
        }

        if (tokenOut != asset1) {
            ZapV2CommonLibrary._callOneInchSwap(
                asset1,
                amount1,
                asset1SwapData
            );
        }

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);

        address[] memory dustAssets = new address[](2);
        dustAssets[0] = asset0;
        dustAssets[1] = asset1;
        ZapV2CommonLibrary._sendBackChange(dustAssets);
    }

    function quoteIntoUniswapV2(address vault, uint amount0, uint amount1) external view returns(uint) {
        address lp = ISmartVault(vault).underlying();
        uint totalSupply = IERC20(lp).totalSupply();
        uint amountA;
        uint amountB;
        uint liquidity;
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(lp).getReserves();
        uint amount1Optimal = _quoteLiquidityUniswapV2(amount0, reserve0, reserve1);
        if (amount1Optimal <= amount1) {
            (amountA, amountB) = (amount0, amount1Optimal);
            liquidity = Math.min(amountA * totalSupply / reserve0, amountB * totalSupply / reserve1);
        } else {
            uint amount0Optimal = _quoteLiquidityUniswapV2(amount1, reserve1, reserve0);
            (amountA, amountB) = (amount0Optimal, amount1);
            liquidity = Math.min(amountA * totalSupply / reserve0, amountB * totalSupply / reserve1);
        }
        return liquidity * IERC20(vault).totalSupply() / ISmartVault(vault).underlyingBalanceWithInvestment();
    }

    function quoteOutUniswapV2(address vault, uint shareAmount) external view returns(uint[] memory) {
        uint liquidityOut = shareAmount * ISmartVault(vault).underlyingBalanceWithInvestment() / IERC20(vault).totalSupply();
        address lp = ISmartVault(vault).underlying();
        uint totalSupply = IERC20(lp).totalSupply();
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(lp).getReserves();
        uint[] memory amountsOut = new uint[](2);
        // -1 need for working zapOutUniswapV2 with tetuswap
        amountsOut[0] = liquidityOut * reserve0 / totalSupply - 1;
        amountsOut[1] = liquidityOut * reserve1 / totalSupply - 1;
        return amountsOut;
    }

    function _addLiquidityUniswapV2(address lp, address asset0, address asset1) internal returns (uint) {
        uint amount0 = IERC20(asset0).balanceOf(address(this));
        uint amount1 = IERC20(asset1).balanceOf(address(this));
        uint amountA;
        uint amountB;

        (uint reserve0, uint reserve1,) = IUniswapV2Pair(lp).getReserves();
        uint amount1Optimal = _quoteLiquidityUniswapV2(amount0, reserve0, reserve1);
        if (amount1Optimal <= amount1) {
            (amountA, amountB) = (amount0, amount1Optimal);
        } else {
            uint amount0Optimal = _quoteLiquidityUniswapV2(amount1, reserve1, reserve0);
            (amountA, amountB) = (amount0Optimal, amount1);
        }

        IERC20(asset0).safeTransfer(lp, amountA);
        IERC20(asset1).safeTransfer(lp, amountB);
        return IUniswapV2Pair(lp).mint(address(this));
    }

    /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset.
    function _quoteLiquidityUniswapV2(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ZC: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ZC: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
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

import "../../openzeppelin/SafeERC20.sol";
import "../../base/interface/ISmartVault.sol";

library ZapV2CommonLibrary {
    using SafeERC20 for IERC20;
    address private constant ONEINCH_ROUTER = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    function _sendBackChange(address[] memory assets) internal {
        uint len = assets.length;
        for (uint i; i < len; i++) {
            uint bal = IERC20(assets[i]).balanceOf(address(this));
            if (bal != 0) {
                IERC20(assets[i]).safeTransfer(msg.sender, bal);
            }
        }
    }

    function _callOneInchSwap(address tokenIn, uint tokenInAmount, bytes memory swapData) internal {
        require(tokenInAmount <= IERC20(tokenIn).balanceOf(address(this)), "ZC: not enough balance for swap");
        _approveIfNeeds(tokenIn, tokenInAmount, ONEINCH_ROUTER);
        (bool success,bytes memory result) = ONEINCH_ROUTER.call(swapData);
        require(success, string(result));
    }

    /// @dev Deposit into the vault, check the result and send share token to msg.sender
    function _depositToVault(address vault, address asset, uint amount) internal {
        _approveIfNeeds(asset, amount, vault);
        ISmartVault(vault).depositAndInvest(amount);
        uint shareBalance = IERC20(vault).balanceOf(address(this));
        require(shareBalance != 0, "ZC: zero shareBalance");
        IERC20(vault).safeTransfer(msg.sender, shareBalance);
    }

    /// @dev Withdraw from vault and check the result
    function _withdrawFromVault(address vault, address asset, uint amount) internal returns (uint) {
        ISmartVault(vault).withdraw(amount);
        uint underlyingBalance = IERC20(asset).balanceOf(address(this));
        require(underlyingBalance != 0, "ZC: zero underlying balance");
        return underlyingBalance;
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

import "../../openzeppelin/SafeERC20.sol";
import "../../base/interface/ISmartVault.sol";
import "../../third_party/balancer/IBVault.sol";
import "../../third_party/balancer/IBPT.sol";
import "../../third_party/balancer/IBalancerHelper.sol";
import "./ZapV2CommonLibrary.sol";
import "./ZapV2BalancerCommonLibrary.sol";


library ZapV2Balancer1Library {
    using SafeERC20 for IERC20;

    address private constant BB_AM_USD_VAULT = 0xf2fB1979C4bed7E71E6ac829801E0A8a4eFa8513;
    address private constant BB_AM_USD_BPT = 0x48e6B98ef6329f8f0A30eBB8c7C960330d648085;
    bytes32 private constant BB_AM_USD_POOL_ID = 0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b;
    address private constant BB_AM_USD_POOL0_BPT = 0x178E029173417b1F9C8bC16DCeC6f697bC323746; // Balancer Aave Boosted Pool (DAI) (bb-am-DAI)
    address private constant BB_AM_USD_POOL2_BPT = 0xF93579002DBE8046c43FEfE86ec78b1112247BB8; // Balancer Aave Boosted Pool (USDC) (bb-am-USDC)
    address private constant BB_AM_USD_POOL3_BPT = 0xFf4ce5AAAb5a627bf82f4A571AB1cE94Aa365eA6; // Balancer Aave Boosted Pool (USDT) (bb-am-USDT)
    bytes32 private constant BB_AM_USD_POOL0_ID = 0x178e029173417b1f9c8bc16dcec6f697bc323746000000000000000000000758;
    bytes32 private constant BB_AM_USD_POOL2_ID = 0xf93579002dbe8046c43fefe86ec78b1112247bb8000000000000000000000759;
    bytes32 private constant BB_AM_USD_POOL3_ID = 0xff4ce5aaab5a627bf82f4a571ab1ce94aa365ea600000000000000000000075a;
    address private constant BB_AM_USD_POOL0_TOKEN1 = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // DAI
    address private constant BB_AM_USD_POOL2_TOKEN1 = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
    address private constant BB_AM_USD_POOL3_TOKEN1 = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT

    function zapIntoBalancer(
        address vault,
        address tokenIn,
        address[] memory assets,
        bytes[] memory assetsSwapData,
        uint[] memory tokenInAmounts
    ) external {
        uint len = assets.length;

        uint totalTokenInAmount;
        uint i;
        for (; i < len; i++) {
            totalTokenInAmount += tokenInAmounts[i];
        }

        require(totalTokenInAmount > 1, "ZC: not enough amount");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), totalTokenInAmount);

        address bpt = ISmartVault(vault).underlying();
        bytes32 poolId = IBPT(bpt).getPoolId();

        bool tokenInInAssets;
        uint[] memory amounts = new uint[](len);
        for (i = 0; i < len; i++) {
            if (tokenInAmounts[i] != 0) {
                if (tokenIn != assets[i]) {
                    ZapV2CommonLibrary._callOneInchSwap(
                        tokenIn,
                        tokenInAmounts[i],
                        assetsSwapData[i]
                    );
                    amounts[i] = IERC20(assets[i]).balanceOf(address(this));
                } else {
                    amounts[i] = tokenInAmounts[i];
                    tokenInInAssets = true;
                }

            }
        }

        ZapV2BalancerCommonLibrary._addLiquidityBalancer(poolId, assets, amounts, bpt);

        uint bptBalance = IERC20(bpt).balanceOf(address(this));

        require(bptBalance != 0, "ZC: zero liq");

        ZapV2CommonLibrary._depositToVault(vault, bpt, bptBalance);

        ZapV2CommonLibrary._sendBackChange(assets);
        if (!tokenInInAssets) {
            address[] memory dustAssets = new address[](1);
            dustAssets[0] = tokenIn;
            ZapV2CommonLibrary._sendBackChange(dustAssets);
        }
    }

    function zapOutBalancer(
        address vault,
        address tokenOut,
        address[] memory assets,
        uint[] memory amounts,
        bytes[] memory assetsSwapData,
        uint shareAmount
    ) external {
        require(shareAmount != 0, "ZC: zero amount");
        IERC20(vault).safeTransferFrom(msg.sender, address(this), shareAmount);
        address bpt = ISmartVault(vault).underlying();
        bytes32 poolId = IBPT(bpt).getPoolId();

        uint bptOut = ZapV2CommonLibrary._withdrawFromVault(vault, bpt, shareAmount);

        uint len = assets.length;

        uint[] memory amountsOut = ZapV2BalancerCommonLibrary._removeLiquidityBalancer(poolId, assets, amounts, bptOut);

        for (uint i; i < len; i++) {
            if (assets[i] != bpt && amountsOut[i] != 0 && tokenOut != assets[i]) {
                ZapV2CommonLibrary._callOneInchSwap(
                    assets[i],
                    amountsOut[i],
                    assetsSwapData[i]
                );
            }
        }

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);

        ZapV2CommonLibrary._sendBackChange(assets);
    }

    function zapIntoBalancerAaveBoostedStablePool(
        address tokenIn,
        bytes[] memory assetsSwapData,
        uint[] memory tokenInAmounts // calculated off-chain
    ) external {
        uint totalTokenInAmount = tokenInAmounts[0] + tokenInAmounts[1] + tokenInAmounts[2];
        require(totalTokenInAmount > 1, "ZC: not enough amount");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), totalTokenInAmount);

        // swap to DAI
        if (tokenIn != BB_AM_USD_POOL0_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmounts[0],
                assetsSwapData[0]
            );
        }

        // swap to USDC
        if (tokenIn != BB_AM_USD_POOL2_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmounts[1],
                assetsSwapData[1]
            );
        }

        // swap to USDT
        if (tokenIn != BB_AM_USD_POOL3_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmounts[2],
                assetsSwapData[2]
            );
        }

        uint[] memory realAssetsAmounts = new uint[](3);
        realAssetsAmounts[0] = IERC20(BB_AM_USD_POOL0_TOKEN1).balanceOf(address(this));
        realAssetsAmounts[1] = IERC20(BB_AM_USD_POOL2_TOKEN1).balanceOf(address(this));
        realAssetsAmounts[2] = IERC20(BB_AM_USD_POOL3_TOKEN1).balanceOf(address(this));

        // get linear pool phantom bpts
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL0_ID, BB_AM_USD_POOL0_TOKEN1, BB_AM_USD_POOL0_BPT, realAssetsAmounts[0]);
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL2_ID, BB_AM_USD_POOL2_TOKEN1, BB_AM_USD_POOL2_BPT, realAssetsAmounts[1]);
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL3_ID, BB_AM_USD_POOL3_TOKEN1, BB_AM_USD_POOL3_BPT, realAssetsAmounts[2]);

        // get root BPT
        address[] memory rootAssets = new address[](4);
        uint[] memory rootAmounts = new uint[](4);
        rootAssets[0] = BB_AM_USD_POOL0_BPT;
        rootAssets[1] = BB_AM_USD_BPT;
        rootAssets[2] = BB_AM_USD_POOL2_BPT;
        rootAssets[3] = BB_AM_USD_POOL3_BPT;
        rootAmounts[0] = IERC20(BB_AM_USD_POOL0_BPT).balanceOf(address(this));
        rootAmounts[1] = 0;
        rootAmounts[2] = IERC20(BB_AM_USD_POOL2_BPT).balanceOf(address(this));
        rootAmounts[3] = IERC20(BB_AM_USD_POOL3_BPT).balanceOf(address(this));
        ZapV2BalancerCommonLibrary._addLiquidityBalancer(BB_AM_USD_POOL_ID, rootAssets, rootAmounts, BB_AM_USD_BPT);

        uint bptBalance = IERC20(BB_AM_USD_BPT).balanceOf(address(this));
        require(bptBalance != 0, "ZC: zero liq");
        ZapV2CommonLibrary._depositToVault(BB_AM_USD_VAULT, BB_AM_USD_BPT, bptBalance);

        ZapV2CommonLibrary._sendBackChange(rootAssets);
    }

    function zapOutBalancerAaveBoostedStablePool(
        address tokenOut,
        bytes[] memory assetsSwapData,
        uint shareAmount
    ) external {
        require(shareAmount != 0, "ZC: zero amount");
        IERC20(BB_AM_USD_VAULT).safeTransferFrom(msg.sender, address(this), shareAmount);
        uint bptOut = ZapV2CommonLibrary._withdrawFromVault(BB_AM_USD_VAULT, BB_AM_USD_BPT, shareAmount);

        (, uint[] memory tokensBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(BB_AM_USD_POOL_ID);
        uint totalTokenBalances = tokensBalances[0] + tokensBalances[2] + tokensBalances[3];

        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL_ID, BB_AM_USD_BPT, BB_AM_USD_POOL0_BPT, bptOut * tokensBalances[0] / totalTokenBalances);
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL0_ID, BB_AM_USD_POOL0_BPT, BB_AM_USD_POOL0_TOKEN1, IERC20(BB_AM_USD_POOL0_BPT).balanceOf(address(this)));

        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL_ID, BB_AM_USD_BPT, BB_AM_USD_POOL2_BPT, bptOut * tokensBalances[2] / totalTokenBalances);
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL2_ID, BB_AM_USD_POOL2_BPT, BB_AM_USD_POOL2_TOKEN1, IERC20(BB_AM_USD_POOL2_BPT).balanceOf(address(this)));

        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL_ID, BB_AM_USD_BPT, BB_AM_USD_POOL3_BPT, bptOut * tokensBalances[3] / totalTokenBalances);
        ZapV2BalancerCommonLibrary._balancerSwap(BB_AM_USD_POOL3_ID, BB_AM_USD_POOL3_BPT, BB_AM_USD_POOL3_TOKEN1, IERC20(BB_AM_USD_POOL3_BPT).balanceOf(address(this)));

        if (tokenOut != BB_AM_USD_POOL0_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                BB_AM_USD_POOL0_TOKEN1,
                IERC20(BB_AM_USD_POOL0_TOKEN1).balanceOf(address(this)),
                assetsSwapData[0]
            );
        }

        if (tokenOut != BB_AM_USD_POOL2_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                BB_AM_USD_POOL2_TOKEN1,
                IERC20(BB_AM_USD_POOL2_TOKEN1).balanceOf(address(this)),
                assetsSwapData[1]
            );
        }

        if (tokenOut != BB_AM_USD_POOL3_TOKEN1) {
            ZapV2CommonLibrary._callOneInchSwap(
                BB_AM_USD_POOL3_TOKEN1,
                IERC20(BB_AM_USD_POOL3_TOKEN1).balanceOf(address(this)),
                assetsSwapData[2]
            );
        }

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);

        address[] memory assets = new address[](4);
        assets[0] = BB_AM_USD_BPT;
        assets[1] = BB_AM_USD_POOL0_TOKEN1;
        assets[2] = BB_AM_USD_POOL2_TOKEN1;
        assets[3] = BB_AM_USD_POOL3_TOKEN1;
        ZapV2CommonLibrary._sendBackChange(assets);
    }

    function quoteIntoBalancer(address vault, address[] memory assets, uint[] memory amounts) external returns(uint) {
        address bpt = ISmartVault(vault).underlying();
        bytes32 poolId = IBPT(bpt).getPoolId();
        uint bptOut = ZapV2BalancerCommonLibrary._quoteJoinBalancer(poolId, assets, amounts, bpt);
        return bptOut * IERC20(vault).totalSupply() / ISmartVault(vault).underlyingBalanceWithInvestment();
    }

    /// @dev Quote out for ComposableStablePool with Phantom BPT and without it.
    ///      This unusual algorithm is used due to the impossibility of using EXACT_BPT_IN_FOR_ALL_TOKENS_OUT.
    ///      We think it's can be better than queryBatchSwap for such pools.
    function quoteOutBalancer(address vault, address[] memory assets, uint shareAmount) external view returns(uint[] memory) {
        address bpt = ISmartVault(vault).underlying();
        bytes32 poolId = IBPT(bpt).getPoolId();
        uint bptAmountOut = shareAmount * ISmartVault(vault).underlyingBalanceWithInvestment() / IERC20(vault).totalSupply();
        uint len = assets.length;
        uint bptNotInPool;
        uint i;
        (, uint[] memory tokensBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(poolId);
        for (; i < len; i++) {
            if (assets[i] == bpt) {
                bptNotInPool = IERC20(bpt).totalSupply() - tokensBalances[i];
            }
        }

        if (bptNotInPool == 0) {
            bptNotInPool = IERC20(bpt).totalSupply();
        }

        uint[] memory amounts = new uint[](len);
        for (i = 0; i < len; i++) {
            if (assets[i] != bpt) {
                amounts[i] = tokensBalances[i] * bptAmountOut / bptNotInPool * 999998 / 1000000;
            }
        }

        return amounts;
    }

    function quoteIntoBalancerAaveBoostedStablePool(uint[] memory amounts) external returns(uint) {
        uint[] memory rootAmounts = new uint[](4);
        rootAmounts[0] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL0_ID, 1, 0, amounts[0]);
        rootAmounts[1] = 0;
        rootAmounts[2] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL2_ID, 1, 2, amounts[1]);
        rootAmounts[3] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL3_ID, 1, 2, amounts[2]);

        address[] memory rootAssets = new address[](4);
        rootAssets[0] = BB_AM_USD_POOL0_BPT;
        rootAssets[1] = BB_AM_USD_BPT;
        rootAssets[2] = BB_AM_USD_POOL2_BPT;
        rootAssets[3] = BB_AM_USD_POOL3_BPT;

        uint bptOut = ZapV2BalancerCommonLibrary._quoteJoinBalancer(BB_AM_USD_POOL_ID, rootAssets, rootAmounts, BB_AM_USD_BPT);
        return bptOut * IERC20(BB_AM_USD_VAULT).totalSupply() / ISmartVault(BB_AM_USD_VAULT).underlyingBalanceWithInvestment();
    }

    function quoteOutBalancerAaveBoostedStablePool(uint shareAmount) external returns(uint[] memory) {
        uint bptAmountOut = shareAmount * ISmartVault(BB_AM_USD_VAULT).underlyingBalanceWithInvestment() / IERC20(BB_AM_USD_VAULT).totalSupply();
        (, uint[] memory tokensBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(BB_AM_USD_POOL_ID);
        uint totalTokenBalances = tokensBalances[0] + tokensBalances[2] + tokensBalances[3];

        uint[] memory outAmounts = new uint[](3);
        uint bptOutTmp;

        bptOutTmp = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL_ID, 1, 0, bptAmountOut * tokensBalances[0] / totalTokenBalances);
        outAmounts[0] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL0_ID, 0, 1, bptOutTmp);
        bptOutTmp = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL_ID, 1, 2, bptAmountOut * tokensBalances[2] / totalTokenBalances);
        outAmounts[1] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL2_ID, 2, 1, bptOutTmp);
        bptOutTmp = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL_ID, 1, 3, bptAmountOut * tokensBalances[3] / totalTokenBalances);
        outAmounts[2] = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(BB_AM_USD_POOL3_ID, 2, 1, bptOutTmp);

        return outAmounts;
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

import "../../openzeppelin/SafeERC20.sol";
import "../../base/interface/ISmartVault.sol";
import "../../third_party/balancer/IBVault.sol";
import "../../third_party/balancer/IBPT.sol";
import "../../third_party/balancer/IBalancerHelper.sol";
import "./ZapV2CommonLibrary.sol";
import "./ZapV2BalancerCommonLibrary.sol";

library ZapV2Balancer2Library {
    using SafeERC20 for IERC20;

    address private constant TETUBAL = 0x7fC9E0Aa043787BFad28e29632AdA302C790Ce33;
    bytes32 private constant TETUBAL_WETHBAL_POOL_ID = 0xb797adfb7b268faeaa90cadbfed464c76ee599cd0002000000000000000005ba;
    address private constant WETH20BAL80_BPT = 0x3d468AB2329F296e1b9d8476Bb54Dd77D8c2320f;
    bytes32 private constant WETH20BAL80_POOL_ID = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    address private constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant BAL = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
    address private constant TETUQI_QI_VAULT = 0x190cA39f86ea92eaaF19cB2acCA17F8B2718ed58;
    address private constant TETUQI_QI_BPT = 0x05F21bAcc4Fd8590D1eaCa9830a64B66a733316C;
    bytes32 private constant TETUQI_QI_POOL_ID = 0x05f21bacc4fd8590d1eaca9830a64b66a733316c00000000000000000000087e;
    address private constant TETUQI = 0x4Cd44ced63d9a6FEF595f6AD3F7CED13fCEAc768;
    address private constant QI = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;

    function zapIntoBalancerTetuBal(
        address tokenIn,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint tokenInAmount
    ) external {
        require(tokenInAmount > 1, "ZC: not enough amount");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

        bool tokenInInAssets = false;
        if (tokenIn != WETH) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmount * 2 / 10,
                asset0SwapData
            );
        } else {
            tokenInInAssets = true;
        }

        if (tokenIn != BAL) {
            ZapV2CommonLibrary._callOneInchSwap(
                tokenIn,
                tokenInAmount * 8 / 10,
                asset1SwapData
            );
        } else {
            tokenInInAssets = true;
        }

        address[] memory assets = new address[](2);
        assets[0] = WETH;
        assets[1] = BAL;
        uint[] memory amounts = new uint[](2);
        amounts[0] = IERC20(WETH).balanceOf(address(this));
        amounts[1] = IERC20(BAL).balanceOf(address(this));
        ZapV2BalancerCommonLibrary._addLiquidityBalancer(WETH20BAL80_POOL_ID, assets, amounts, WETH20BAL80_BPT);
        uint bptBalance = IERC20(WETH20BAL80_BPT).balanceOf(address(this));
        (, uint[] memory tetuBalWethBalPoolBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(TETUBAL_WETHBAL_POOL_ID);
        uint canBuyTetuBalBPTByGoodPrice = tetuBalWethBalPoolBalances[1] > tetuBalWethBalPoolBalances[0] ? (tetuBalWethBalPoolBalances[1] - tetuBalWethBalPoolBalances[0]) / 2 : 0;
        uint needToMintTetuBal;
        if (canBuyTetuBalBPTByGoodPrice < bptBalance) {
            needToMintTetuBal = bptBalance - canBuyTetuBalBPTByGoodPrice;
        }
        if (needToMintTetuBal != 0) {
            ZapV2CommonLibrary._approveIfNeeds(WETH20BAL80_BPT, needToMintTetuBal, TETUBAL);
            ISmartVault(TETUBAL).depositAndInvest(needToMintTetuBal);
        }
        ZapV2BalancerCommonLibrary._balancerSwap(TETUBAL_WETHBAL_POOL_ID, WETH20BAL80_BPT, TETUBAL, bptBalance - needToMintTetuBal);
        uint tetuBalBalance = IERC20(TETUBAL).balanceOf(address(this));
        require(tetuBalBalance != 0, "ZC: zero shareBalance");
        IERC20(TETUBAL).safeTransfer(msg.sender, tetuBalBalance);

        ZapV2CommonLibrary._sendBackChange(assets);

        if (!tokenInInAssets) {
            address[] memory dustAssets = new address[](1);
            dustAssets[0] = tokenIn;
            ZapV2CommonLibrary._sendBackChange(dustAssets);
        }
    }

    function zapOutBalancerTetuBal(
        address tokenOut,
        bytes memory asset0SwapData,
        bytes memory asset1SwapData,
        uint shareAmount
    ) external {
        require(shareAmount != 0, "ZC: zero amount");
        IERC20(TETUBAL).safeTransferFrom(msg.sender, address(this), shareAmount);
        ZapV2BalancerCommonLibrary._balancerSwap(TETUBAL_WETHBAL_POOL_ID, TETUBAL, WETH20BAL80_BPT, shareAmount);

        uint[] memory amounts = new uint[](2);
        address[] memory assets = new address[](2);
        assets[0] = WETH;
        assets[1] = BAL;
        uint[] memory amountsOut = ZapV2BalancerCommonLibrary._removeLiquidityBalancer(WETH20BAL80_POOL_ID, assets, amounts, IERC20(WETH20BAL80_BPT).balanceOf(address(this)));
        if (tokenOut != WETH) {
            ZapV2CommonLibrary._callOneInchSwap(
                WETH,
                amountsOut[0],
                asset0SwapData
            );
        }

        if (tokenOut != BAL) {
            ZapV2CommonLibrary._callOneInchSwap(
                BAL,
                amountsOut[1],
                asset1SwapData
            );
        }

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);
    }

    function zapIntoBalancerTetuQiQi(
        address tokenIn,
        bytes memory assetSwapData,
        uint tokenInAmount
    ) external {
        require(tokenInAmount > 1, "ZC: not enough amount");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

        ZapV2CommonLibrary._callOneInchSwap(
            tokenIn,
            tokenInAmount,
            assetSwapData
        );

        uint qiBal = IERC20(QI).balanceOf(address(this));

        (, uint[] memory tetuQiQiPoolBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(TETUQI_QI_POOL_ID);
        uint canBuyTetuQiByGoodPrice = tetuQiQiPoolBalances[1] > tetuQiQiPoolBalances[2] ? (tetuQiQiPoolBalances[1] - tetuQiQiPoolBalances[2]) / 2 : 0;
        uint needToMintTetuQi;
        if (canBuyTetuQiByGoodPrice < qiBal / 2) {
            needToMintTetuQi = qiBal / 2 - canBuyTetuQiByGoodPrice;
        }
        if (needToMintTetuQi != 0) {
            ZapV2CommonLibrary._approveIfNeeds(QI, needToMintTetuQi, TETUQI);
            ISmartVault(TETUQI).depositAndInvest(needToMintTetuQi);
        }

        address[] memory assets = new address[](3);
        assets[0] = TETUQI_QI_BPT;
        assets[1] = TETUQI;
        assets[2] = QI;
        uint[] memory amounts = new uint[](3);
        if (needToMintTetuQi != 0) {
            amounts[1] = IERC20(TETUQI).balanceOf(address(this));
        }
        amounts[2] = IERC20(QI).balanceOf(address(this));
        ZapV2BalancerCommonLibrary._addLiquidityBalancer(TETUQI_QI_POOL_ID, assets, amounts, TETUQI_QI_BPT);

        ZapV2CommonLibrary._depositToVault(TETUQI_QI_VAULT, TETUQI_QI_BPT, IERC20(TETUQI_QI_BPT).balanceOf(address(this)));

        ZapV2CommonLibrary._sendBackChange(assets);
    }

    function zapOutBalancerTetuQiQi(
        address tokenOut,
        bytes memory assetSwapData,
        uint shareAmount
    ) external {
        require(shareAmount != 0, "ZC: zero amount");
        IERC20(TETUQI_QI_VAULT).safeTransferFrom(msg.sender, address(this), shareAmount);
        uint bptAmount = ZapV2CommonLibrary._withdrawFromVault(TETUQI_QI_VAULT, TETUQI_QI_BPT, shareAmount);
        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(TETUQI_QI_BPT);
        assets[1] = IAsset(TETUQI);
        assets[2] = IAsset(QI);
        uint[] memory amounts = new uint[](3);
        IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).exitPool(
            TETUQI_QI_POOL_ID,
            address(this),
            payable(address(this)),
            IBVault.ExitPoolRequest({
                assets : assets,
                minAmountsOut : amounts,
                userData : abi.encode(IBVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmount, 1),
                toInternalBalance : false
            })
        );

        ZapV2CommonLibrary._callOneInchSwap(
            QI,
            IERC20(QI).balanceOf(address(this)),
            assetSwapData
        );

        uint tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        require(tokenOutBalance != 0, "zero token out balance");
        IERC20(tokenOut).safeTransfer(msg.sender, tokenOutBalance);
    }

    function quoteIntoBalancerTetuBal(uint wethAmount, uint balAmount) external returns(uint) {
        uint[] memory amounts = new uint[](2);
        amounts[0] = wethAmount;
        amounts[1] = balAmount;

        address[] memory assets = new address[](2);
        assets[0] = WETH;
        assets[1] = BAL;

        uint bptOut = ZapV2BalancerCommonLibrary._quoteJoinBalancer(WETH20BAL80_POOL_ID, assets, amounts, WETH20BAL80_BPT);
        (, uint[] memory tetuBalWethBalPoolBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(TETUBAL_WETHBAL_POOL_ID);
        uint canBuyTetuBalBPTByGoodPrice = tetuBalWethBalPoolBalances[1] > tetuBalWethBalPoolBalances[0] ? (tetuBalWethBalPoolBalances[1] - tetuBalWethBalPoolBalances[0]) / 2 : 0;
        uint needToMintTetuBal;
        if (canBuyTetuBalBPTByGoodPrice < bptOut) {
            needToMintTetuBal = bptOut - canBuyTetuBalBPTByGoodPrice;
        }

        uint swapOut = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(TETUBAL_WETHBAL_POOL_ID, 0, 1, bptOut - needToMintTetuBal);

        return swapOut + needToMintTetuBal;
    }

    function quoteOutBalancerTetuBal(uint amount) external returns(uint[] memory) {
        uint wethBalBpt = ZapV2BalancerCommonLibrary._queryBalancerSingleSwap(TETUBAL_WETHBAL_POOL_ID, 1, 0, amount);
        address[] memory assets = new address[](2);
        assets[0] = WETH;
        assets[1] = BAL;
        uint[] memory amounts = new uint[](2);
        (, uint[] memory amountsOut) = IBalancerHelper(ZapV2BalancerCommonLibrary.BALANCER_HELPER).queryExit(
            WETH20BAL80_POOL_ID,
            address(this),
            payable(address(this)),
            IVault.JoinPoolRequest({
                assets : assets,
                maxAmountsIn : amounts,
                userData : abi.encode(IBVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, wethBalBpt),
                fromInternalBalance : false
            })
        );

        return amountsOut;
    }

    function quoteIntoBalancerTetuQiQi(uint qiAmount) external returns(uint) {
        (, uint[] memory tetuQiQiPoolBalances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(TETUQI_QI_POOL_ID);
        uint canBuyTetuQiByGoodPrice = tetuQiQiPoolBalances[1] > tetuQiQiPoolBalances[2] ? (tetuQiQiPoolBalances[1] - tetuQiQiPoolBalances[2]) / 2 : 0;
        uint needToMintTetuQi;
        if (canBuyTetuQiByGoodPrice < qiAmount / 2) {
            needToMintTetuQi = qiAmount / 2 - canBuyTetuQiByGoodPrice;
        }
        address[] memory assets = new address[](3);
        assets[0] = TETUQI_QI_BPT;
        assets[1] = TETUQI;
        assets[2] = QI;
        uint[] memory amounts = new uint[](3);
        amounts[1] = needToMintTetuQi;
        amounts[2] = qiAmount;
        uint bptOut = ZapV2BalancerCommonLibrary._quoteJoinBalancer(TETUQI_QI_POOL_ID, assets, amounts, TETUQI_QI_BPT);
        return bptOut * IERC20(TETUQI_QI_VAULT).totalSupply() / ISmartVault(TETUQI_QI_VAULT).underlyingBalanceWithInvestment();
    }

    function quoteOutBalancerTetuQiQi(uint shareAmount) external returns(uint) {
        uint bptOut = shareAmount * ISmartVault(TETUQI_QI_VAULT).underlyingBalanceWithInvestment() / IERC20(TETUQI_QI_VAULT).totalSupply();
        address[] memory assets = new address[](3);
        assets[0] = TETUQI_QI_BPT;
        assets[1] = TETUQI;
        assets[2] = QI;
        uint[] memory amounts = new uint[](3);
        (, uint[] memory amountsOut) = IBalancerHelper(ZapV2BalancerCommonLibrary.BALANCER_HELPER).queryExit(
            TETUQI_QI_POOL_ID,
            address(this),
            payable(address(this)),
            IVault.JoinPoolRequest({
                assets : assets,
                maxAmountsIn : amounts,
                userData : abi.encode(IBVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptOut, 1),
                fromInternalBalance : false
            })
        );
        return amountsOut[2];
    }

    function getBalancerPoolTokens(address bpt) external view returns(
        IERC20[] memory,
        uint[] memory
    ) {
        bytes32 poolId = IBPT(bpt).getPoolId();
        (IERC20[] memory tokens, uint[] memory balances,) = IBVault(ZapV2BalancerCommonLibrary.BALANCER_VAULT).getPoolTokens(poolId);
        return (tokens, balances);
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

  function rebalance(address _strategy) external;

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

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(
    uint256 a,
    uint256 b,
    bool roundUp
  ) internal pure returns (uint256) {
    return roundUp ? divUp(a, b) : divDown(a, b);
  }

  function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    } else {
      return 1 + (a - 1) / b;
    }
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
    return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
  }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";


interface IAsset {
}

interface IBVault {
  // Internal Balance
  //
  // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
  // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
  // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
  // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
  //
  // Internal Balance management features batching, which means a single contract call can be used to perform multiple
  // operations of different kinds, with different senders and recipients, at once.

  /**
   * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
  function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

  /**
   * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
  function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

  /**
   * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
  struct UserBalanceOp {
    UserBalanceOpKind kind;
    IAsset asset;
    uint256 amount;
    address sender;
    address payable recipient;
  }

  // There are four possible operations in `manageUserBalance`:
  //
  // - DEPOSIT_INTERNAL
  // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
  // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
  // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
  // relevant for relayers).
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - WITHDRAW_INTERNAL
  // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
  // it to the recipient as ETH.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_INTERNAL
  // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_EXTERNAL
  // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
  // relayers, as it lets them reuse a user's Vault allowance.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `ExternalBalanceTransfer` event.

  enum UserBalanceOpKind {DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL}

  /**
   * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
  event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

  /**
   * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
  event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

  // Pools
  //
  // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
  // functionality:
  //
  //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
  // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
  // which increase with the number of registered tokens.
  //
  //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
  // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
  // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
  // independent of the number of registered tokens.
  //
  //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
  // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

  enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}

  /**
   * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
  function registerPool(PoolSpecialization specialization) external returns (bytes32);

  /**
   * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
  event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

  /**
   * @dev Returns a Pool's contract address and specialization setting.
     */
  function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

  /**
   * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
  function registerTokens(
    bytes32 poolId,
    IERC20[] calldata tokens,
    address[] calldata assetManagers
  ) external;

  /**
   * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
  event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

  /**
   * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
  function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

  /**
   * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
  event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

  /**
   * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
  function getPoolTokenInfo(bytes32 poolId, IERC20 token)
  external
  view
  returns (
    uint256 cash,
    uint256 managed,
    uint256 lastChangeBlock,
    address assetManager
  );

  /**
   * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
  function getPoolTokens(bytes32 poolId)
  external
  view
  returns (
    IERC20[] memory tokens,
    uint256[] memory balances,
    uint256 lastChangeBlock
  );

  /**
   * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external payable;

  enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
  enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  /**
   * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  /**
   * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
  event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    IERC20[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
  );

  enum PoolBalanceChangeKind {JOIN, EXIT}

  // Swaps
  //
  // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
  // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
  // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
  //
  // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
  // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
  // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
  // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
  // individual swaps.
  //
  // There are two swap kinds:
  //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
  // `onSwap` hook) the amount of tokens out (to send to the recipient).
  //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
  // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
  //
  // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
  // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
  // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
  // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
  // the final intended token.
  //
  // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
  // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
  // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
  // much less gas than they would otherwise.
  //
  // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
  // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
  // updating the Pool's internal accounting).
  //
  // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
  // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
  // minimum amount of tokens to receive (by passing a negative value) is specified.
  //
  // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
  // this point in time (e.g. if the transaction failed to be included in a block promptly).
  //
  // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
  // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
  // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
  // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
  //
  // Finally, Internal Balance can be used when either sending or receiving tokens.

  enum SwapKind {GIVEN_IN, GIVEN_OUT}

  /**
   * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
  function swap(
    SingleSwap calldata singleSwap,
    FundManagement calldata funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds,
    int256[] calldata limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
  event Swap(
    bytes32 indexed poolId,
    IERC20 indexed tokenIn,
    IERC20 indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds
  ) external returns (int256[] memory assetDeltas);

  // BasePool.sol

  /**
* @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    uint256[] memory balances,
    uint256 lastChangeBlock,
    uint256 protocolSwapFeePercentage,
    bytes memory userData
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);


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

/// @dev lite version of BPT token
interface IBPT {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getVault() external view returns (address);
    function getPoolId() external view returns (bytes32);
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.4;

interface IBalancerHelper {
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    IVault.JoinPoolRequest memory request
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);

  function queryJoin(
    bytes32 poolId,
    address sender,
    address recipient,
    IVault.JoinPoolRequest memory request
  ) external returns (uint256 bptOut, uint256[] memory amountsIn);

  function vault() external view returns (address);
}

interface IVault {
  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
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

import "../../third_party/balancer/IBVault.sol";
import "../../third_party/balancer/IBPT.sol";
import "../../third_party/balancer/IBalancerHelper.sol";
import "./ZapV2CommonLibrary.sol";

library ZapV2BalancerCommonLibrary {
    address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address internal constant BALANCER_HELPER = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;

    function _quoteJoinBalancer(bytes32 poolId, address[] memory assets, uint[] memory amounts, address bpt) internal returns(uint) {
        uint len = assets.length;
        uint userDataAmountsLen;
        for (uint i; i < len; i++) {
            if (assets[i] != bpt) {
                userDataAmountsLen++;
            }
        }

        uint[] memory userDataAmounts = new uint[](userDataAmountsLen);
        uint k;
        for (uint i = 0; i < len; i++) {
            if (assets[i] != bpt) {
                userDataAmounts[k] = amounts[i];
                k++;
            }
        }

        (uint bptOut,) = IBalancerHelper(BALANCER_HELPER).queryJoin(
            poolId,
            address(this),
            address(this),
            IVault.JoinPoolRequest({
                assets : assets,
                maxAmountsIn : amounts,
                userData : abi.encode(IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, userDataAmounts, 0),
                fromInternalBalance : false
            })
        );

        return bptOut;
    }

    function _addLiquidityBalancer(bytes32 poolId, address[] memory assets, uint[] memory amounts, address bpt) internal {
        uint len = assets.length;
        IAsset[] memory _poolTokens = new IAsset[](len);
        uint userDataAmountsLen;
        uint i;
        for (; i < len; i++) {
            if (assets[i] != bpt) {
                if (amounts[i] != 0) {
                    ZapV2CommonLibrary._approveIfNeeds(assets[i], amounts[i], BALANCER_VAULT);
                }
                userDataAmountsLen++;
            }
            _poolTokens[i] = IAsset(assets[i]);
        }

        uint[] memory userDataAmounts = new uint[](userDataAmountsLen);
        uint k;
        for (i = 0; i < len; i++) {
            if (assets[i] != bpt) {
                userDataAmounts[k] = amounts[i];
                k++;
            }
        }

        IBVault(BALANCER_VAULT).joinPool(
            poolId,
            address(this),
            address(this),
            IBVault.JoinPoolRequest({
                assets : _poolTokens,
                maxAmountsIn : amounts,
                userData : abi.encode(IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, userDataAmounts, 0),
                fromInternalBalance : false
            })
        );
    }

    function _removeLiquidityBalancer(bytes32 poolId, address[] memory assets, uint[] memory amounts, uint bptAmount) internal returns(uint[] memory) {
        require(bptAmount != 0, "ZC: zero amount");
        uint len = assets.length;

        uint[] memory _amounts = new uint[](len);

        IAsset[] memory _poolTokens = new IAsset[](len);
        uint i;
        for (; i < len; i++) {
            _poolTokens[i] = IAsset(assets[i]);
        }

        IBVault(BALANCER_VAULT).exitPool(
            poolId,
            address(this),
            payable(address(this)),
            IBVault.ExitPoolRequest({
                assets : _poolTokens,
                minAmountsOut : _amounts,
                /// BPT_IN_FOR_EXACT_TOKENS_OUT for stable pools or EXACT_BPT_IN_FOR_TOKENS_OUT for weighted pools
                userData : amounts[0] != 0 ? abi.encode(1, amounts, bptAmount) : abi.encode(1, bptAmount),
                toInternalBalance : false
            })
        );

        for (i = 0; i < len; i++) {
            _amounts[i] = IERC20(assets[i]).balanceOf(address(this));
        }

        return _amounts;
    }

    /// @dev Swap _tokenIn to _tokenOut using pool identified by _poolId
    function _balancerSwap(bytes32 poolId, address tokenIn, address tokenOut, uint amountIn) internal {
        if (amountIn != 0) {
            IBVault.SingleSwap memory singleSwapData = IBVault.SingleSwap({
                poolId : poolId,
                kind : IBVault.SwapKind.GIVEN_IN,
                assetIn : IAsset(tokenIn),
                assetOut : IAsset(tokenOut),
                amount : amountIn,
                userData : ""
            });

            IBVault.FundManagement memory fundManagementStruct = IBVault.FundManagement({
                sender : address(this),
                fromInternalBalance : false,
                recipient : payable(address(this)),
                toInternalBalance : false
            });

            ZapV2CommonLibrary._approveIfNeeds(tokenIn, amountIn, BALANCER_VAULT);
            IBVault(BALANCER_VAULT).swap(singleSwapData, fundManagementStruct, 1, block.timestamp);
        }
    }

    function _queryBalancerSingleSwap(bytes32 poolId, uint assetInIndex, uint assetOutIndex, uint amountIn) internal returns (uint) {
        (IERC20[] memory tokens,,) = IBVault(BALANCER_VAULT).getPoolTokens(poolId);
        IAsset[] memory assets = new IAsset[](tokens.length);
        for (uint i; i < tokens.length; i++) {
            assets[i] = IAsset(address(tokens[i]));
        }

        IBVault.BatchSwapStep[] memory swaps = new IBVault.BatchSwapStep[](1);

        IBVault.FundManagement memory fundManagementStruct = IBVault.FundManagement({
            sender : address(this),
            fromInternalBalance : false,
            recipient : payable(address(this)),
            toInternalBalance : false
        });

        swaps[0] = IBVault.BatchSwapStep(
            poolId,
            assetInIndex,
            assetOutIndex,
            amountIn,
            ""
        );

        int256[] memory assetDeltas = IBVault(BALANCER_VAULT).queryBatchSwap(
            IBVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundManagementStruct
        );

        return uint(-assetDeltas[assetOutIndex]);
    }
}