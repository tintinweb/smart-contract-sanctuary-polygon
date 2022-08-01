// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ILP } from "./interfaces/ILP.sol";
import { ICerosToken } from "./interfaces/ICerosToken.sol";
import { INativeERC20 } from "./interfaces/INativeERC20.sol";

enum UserType {
  MANAGER,
  LIQUIDITY_PROVIDER,
  INTEGRATOR
}

enum FeeType {
  OWNER,
  MANAGER,
  INTEGRATOR,
  STAKE,
  UNSTAKE
}

struct FeeAmounts {
  uint128 nativeFee;
  uint128 cerosFee;
}

// solhint-disable max-states-count
contract SwapPool is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  event UserTypeChanged(address indexed user, UserType indexed utype, bool indexed added);
  event FeeChanged(FeeType indexed utype, uint24 oldFee, uint24 newFee);
  event IntegratorLockEnabled(bool indexed enabled);
  event ProviderLockEnabled(bool indexed enabled);
  event ExcludedFromFee(address indexed user, bool indexed excluded);
  event LiquidityChange(
    address indexed user,
    uint256 nativeAmount,
    uint256 stakingAmount,
    uint256 nativeReserve,
    uint256 stakingReserve,
    bool indexed added
  );
  event Swap(
    address indexed sender,
    address indexed receiver,
    bool indexed nativeToCeros,
    uint256 amountIn,
    uint256 amountOut
  );

  uint24 public constant FEE_MAX = 100000;

  EnumerableSet.AddressSet private managers_;
  EnumerableSet.AddressSet private integrators_;
  EnumerableSet.AddressSet private liquidityProviders_;

  INativeERC20 public nativeToken;
  ICerosToken public cerosToken;
  ILP public lpToken;

  uint256 public nativeTokenAmount;
  uint256 public cerosTokenAmount;

  uint24 public ownerFee;
  uint24 public managerFee;
  uint24 public integratorFee;
  uint24 public stakeFee;
  uint24 public unstakeFee;
  uint24 public threshold;

  bool public integratorLockEnabled;
  bool public providerLockEnabled;

  FeeAmounts public ownerFeeCollected;

  FeeAmounts public managerFeeCollected;
  FeeAmounts private _accFeePerManager;
  FeeAmounts private _alreadyUpdatedFees;

  mapping(address => FeeAmounts) public managerRewardDebt;

  mapping(address => bool) public excludedFromFee;

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner() || managers_.contains(msg.sender),
      "only owner or manager can call this function"
    );
    _;
  }

  modifier onlyManager() {
    require(managers_.contains(msg.sender), "only manager can call this function");
    _;
  }

  modifier onlyIntegrator() {
    if (integratorLockEnabled) {
      require(integrators_.contains(msg.sender), "only integrators can call this function");
    }
    _;
  }

  modifier onlyProvider() {
    if (providerLockEnabled) {
      require(
        liquidityProviders_.contains(msg.sender),
        "only liquidity providers can call this function"
      );
    }
    _;
  }

  constructor(
    address _nativeToken,
    address _cerosToken,
    address _lpToken,
    bool _integratorLockEnabled,
    bool _providerLockEnabled
  ) {
    nativeToken = INativeERC20(_nativeToken);
    cerosToken = ICerosToken(_cerosToken);
    lpToken = ILP(_lpToken);
    integratorLockEnabled = _integratorLockEnabled;
    providerLockEnabled = _providerLockEnabled;
  }

  function addLiquidityEth(uint256 amount1) external payable onlyProvider nonReentrant {
    _addLiquidity(msg.value, amount1, true);
  }

  function addLiquidity(uint256 amount0, uint256 amount1) external onlyProvider nonReentrant {
    _addLiquidity(amount0, amount1, false);
  }

  function _addLiquidity(
    uint256 amount0,
    uint256 amount1,
    bool useEth
  ) internal {
    uint256 ratio = cerosToken.ratio();
    uint256 value = (amount0 * ratio) / 1e18;
    if (amount1 < value) {
      amount0 = (amount1 * 1e18) / ratio;
    } else {
      amount1 = value;
    }
    if (useEth) {
      nativeToken.deposit{ value: amount0 }();
    } else {
      nativeToken.transferFrom(msg.sender, address(this), amount0);
    }
    cerosToken.transferFrom(msg.sender, address(this), amount1);
    if (nativeTokenAmount == 0 && cerosTokenAmount == 0) {
      require(amount0 > 1e18, "cannot add first time less than 1 token");
      nativeTokenAmount = amount0;
      cerosTokenAmount = amount1;

      lpToken.mint(msg.sender, (2 * amount0) / 10**8);
    } else {
      uint256 allInNative = nativeTokenAmount + (cerosTokenAmount * 1e18) / ratio;
      uint256 mintAmount = (2 * amount0 * lpToken.totalSupply()) / allInNative;
      nativeTokenAmount += amount0;
      cerosTokenAmount += amount1;

      lpToken.mint(msg.sender, mintAmount);
    }
    emit LiquidityChange(msg.sender, amount0, amount1, nativeTokenAmount, cerosTokenAmount, true);
  }

  function removeLiquidity(uint256 lpAmount) external nonReentrant {
    _removeLiquidityLp(lpAmount, false);
  }

  function removeLiquidityEth(uint256 lpAmount) external nonReentrant {
    _removeLiquidityLp(lpAmount, true);
  }

  function removeLiquidityPercent(uint256 percent) external nonReentrant {
    _removeLiquidityPercent(percent, false);
  }

  function removeLiquidityPercentEth(uint256 percent) external nonReentrant {
    _removeLiquidityPercent(percent, true);
  }

  function _removeLiquidityPercent(uint256 percent, bool useEth) internal {
    require(percent > 0 && percent <= 1e18, "percent should be more than 0 and less than 1e18"); // max percnet(100%) is -> 10 ** 18
    uint256 balance = lpToken.balanceOf(msg.sender);
    uint256 removedLp = (balance * percent) / 1e18;
    _removeLiquidity(removedLp, useEth);
  }

  function _removeLiquidityLp(uint256 removedLp, bool useEth) internal {
    uint256 balance = lpToken.balanceOf(msg.sender);
    if (removedLp == type(uint256).max) {
      removedLp = balance;
    } else {
      require(removedLp <= balance, "you want to remove more than your lp balance");
    }
    require(removedLp > 0, "lp amount should be more than 0");
    _removeLiquidity(removedLp, useEth);
  }

  function _removeLiquidity(uint256 removedLp, bool useEth) internal {
    uint256 totalSupply = lpToken.totalSupply();
    lpToken.burn(msg.sender, removedLp);
    uint256 amount0Removed = (removedLp * nativeTokenAmount) / totalSupply;
    uint256 amount1Removed = (removedLp * cerosTokenAmount) / totalSupply;

    nativeTokenAmount -= amount0Removed;
    cerosTokenAmount -= amount1Removed;

    if (useEth) {
      nativeToken.withdraw(amount0Removed);
      _sendValue(msg.sender, amount0Removed);
    } else {
      nativeToken.transfer(msg.sender, amount0Removed);
    }
    cerosToken.transfer(msg.sender, amount1Removed);
    emit LiquidityChange(
      msg.sender,
      amount0Removed,
      amount1Removed,
      nativeTokenAmount,
      cerosTokenAmount,
      false
    );
  }

  function swapEth(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external payable onlyIntegrator nonReentrant returns (uint256 amountOut) {
    return _swap(nativeToCeros, amountIn, receiver, true);
  }

  function swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external onlyIntegrator nonReentrant returns (uint256 amountOut) {
    return _swap(nativeToCeros, amountIn, receiver, false);
  }

  function _swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver,
    bool useEth
  ) internal returns (uint256 amountOut) {
    uint256 ratio = cerosToken.ratio();
    if (nativeToCeros) {
      if (useEth) {
        nativeToken.deposit{ value: msg.value }();
      } else {
        nativeToken.transferFrom(msg.sender, address(this), amountIn);
      }
      if (!excludedFromFee[msg.sender]) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
        uint256 managerFeeAmt = (stakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (stakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (stakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            nativeToken.transfer(msg.sender, integratorFeeAmt);
          }
        }
        nativeTokenAmount +=
          amountIn +
          (stakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.nativeFee += uint128(ownerFeeAmt);
        managerFeeCollected.nativeFee += uint128(managerFeeAmt);
      } else {
        nativeTokenAmount += amountIn;
      }
      amountOut = (amountIn * ratio) / 1e18;
      require(cerosTokenAmount >= amountOut, "Not enough liquidity");
      cerosTokenAmount -= amountOut;
      cerosToken.transfer(receiver, amountOut);
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    } else {
      cerosToken.transferFrom(msg.sender, address(this), amountIn);
      if (!excludedFromFee[msg.sender]) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
        uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            cerosToken.transfer(msg.sender, integratorFeeAmt);
          }
        }
        cerosTokenAmount +=
          amountIn +
          (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.cerosFee += uint128(ownerFeeAmt);
        managerFeeCollected.cerosFee += uint128(managerFeeAmt);
      } else {
        cerosTokenAmount += amountIn;
      }
      amountOut = (amountIn * 1e18) / ratio;
      require(nativeTokenAmount >= amountOut, "Not enough liquidity");
      nativeTokenAmount -= amountOut;
      if (useEth) {
        nativeToken.withdraw(amountOut);
        _sendValue(receiver, amountOut);
      } else {
        nativeToken.transfer(receiver, amountOut);
      }
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    }
  }

  function getAmountOut(
    bool nativeToCeros,
    uint256 amountIn,
    bool isExcludedFromFee
  ) external view returns (uint256 amountOut, bool enoughLiquidity) {
    uint256 ratio = cerosToken.ratio();
    if (nativeToCeros) {
      if (!isExcludedFromFee) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
      }
      amountOut = (amountIn * ratio) / 1e18;
      enoughLiquidity = cerosTokenAmount >= amountOut;
    } else {
      if (!isExcludedFromFee) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
      }
      amountOut = (amountIn * 1e18) / ratio;
      enoughLiquidity = nativeTokenAmount >= amountOut;
    }
  }

  function _sendValue(address receiver, uint256 amount) private {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(receiver).call{ value: amount }("");
    require(success, "unable to send value, recipient may have reverted");
  }

  function withdrawOwnerFeeEth(uint256 amount0, uint256 amount1) external onlyOwner {
    _withdrawOwnerFee(amount0, amount1, true);
  }

  function withdrawOwnerFee(uint256 amount0, uint256 amount1) external onlyOwner {
    _withdrawOwnerFee(amount0, amount1, false);
  }

  function _withdrawOwnerFee(
    uint256 amount0Raw,
    uint256 amount1Raw,
    bool useEth
  ) internal {
    uint128 amount0;
    uint128 amount1;
    if (amount0Raw == type(uint256).max) {
      amount0 = ownerFeeCollected.nativeFee;
    } else {
      amount0 = uint128(amount0Raw);
    }
    if (amount1Raw == type(uint256).max) {
      amount1 = ownerFeeCollected.nativeFee;
    } else {
      amount1 = uint128(amount1Raw);
    }
    if (amount0 > 0) {
      ownerFeeCollected.nativeFee -= amount0;
      if (useEth) {
        nativeToken.withdraw(amount0);
        _sendValue(msg.sender, amount0);
      } else {
        nativeToken.transfer(msg.sender, amount0);
      }
    }
    if (amount1 > 0) {
      ownerFeeCollected.cerosFee -= amount1;
      cerosToken.transfer(msg.sender, amount1);
    }
  }

  function getRemainingManagerFee(address managerAddress)
    external
    view
    returns (FeeAmounts memory feeRewards)
  {
    if (managers_.contains(managerAddress)) {
      uint256 managersLength = managers_.length();
      FeeAmounts memory currentManagerRewardDebt = managerRewardDebt[managerAddress];
      FeeAmounts memory accFee;
      accFee.nativeFee =
        _accFeePerManager.nativeFee +
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
      accFee.cerosFee =
        _accFeePerManager.cerosFee +
        (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
        uint128(managersLength);
      feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
      feeRewards.cerosFee = accFee.cerosFee - currentManagerRewardDebt.cerosFee;
    }
  }

  function withdrawManagerFee() external onlyManager {
    _withdrawManagerFee(msg.sender, false);
  }

  function withdrawManagerFeeEth() external onlyManager {
    _withdrawManagerFee(msg.sender, true);
  }

  function _withdrawManagerFee(address managerAddress, bool useNative) internal {
    FeeAmounts memory feeRewards;
    FeeAmounts storage currentManagerRewardDebt = managerRewardDebt[managerAddress];
    _updateManagerFees();
    feeRewards.nativeFee = _accFeePerManager.nativeFee - currentManagerRewardDebt.nativeFee;
    feeRewards.cerosFee = _accFeePerManager.cerosFee - currentManagerRewardDebt.cerosFee;
    if (feeRewards.nativeFee > 0) {
      currentManagerRewardDebt.nativeFee += feeRewards.nativeFee;
      if (useNative) {
        nativeToken.withdraw(feeRewards.nativeFee);
        _sendValue(managerAddress, feeRewards.nativeFee);
      } else {
        nativeToken.transfer(managerAddress, feeRewards.nativeFee);
      }
    }
    if (feeRewards.cerosFee > 0) {
      currentManagerRewardDebt.cerosFee += feeRewards.cerosFee;
      cerosToken.transfer(managerAddress, feeRewards.cerosFee);
    }
  }

  function _updateManagerFees() private {
    uint256 managersLength = managers_.length();
    _accFeePerManager.nativeFee +=
      (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
      uint128(managersLength);
    _accFeePerManager.cerosFee +=
      (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
      uint128(managersLength);
    _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
    _alreadyUpdatedFees.cerosFee = managerFeeCollected.cerosFee;
  }

  function add(address value, UserType utype) public returns (bool) {
    require(value != address(0), "cannot add address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can add manager");
      if (!managers_.contains(value)) {
        uint256 managersLength = managers_.length();
        if (managersLength != 0) {
          _updateManagerFees();
          managerRewardDebt[value].nativeFee = _accFeePerManager.nativeFee;
          managerRewardDebt[value].cerosFee = _accFeePerManager.cerosFee;
        }
        success = managers_.add(value);
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can add liquidity provider");
      success = liquidityProviders_.add(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can add integrator");
      success = integrators_.add(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, true);
    }
    return success;
  }

  function setFee(uint24 newFee, FeeType feeType) external onlyOwnerOrManager {
    require(newFee < FEE_MAX, "Unsupported size of fee!");
    if (feeType == FeeType.OWNER) {
      require(msg.sender == owner(), "only owner can call this function");
      require(newFee + managerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, ownerFee, newFee);
      ownerFee = newFee;
    } else if (feeType == FeeType.MANAGER) {
      require(newFee + ownerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, managerFee, newFee);
      managerFee = newFee;
    } else if (feeType == FeeType.INTEGRATOR) {
      require(newFee + ownerFee + managerFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, integratorFee, newFee);
      integratorFee = newFee;
    } else if (feeType == FeeType.STAKE) {
      emit FeeChanged(feeType, stakeFee, newFee);
      stakeFee = newFee;
    } else {
      emit FeeChanged(feeType, unstakeFee, newFee);
      unstakeFee = newFee;
    }
  }

  function enableIntegratorLock(bool enable) external onlyOwnerOrManager {
    integratorLockEnabled = enable;
    emit IntegratorLockEnabled(enable);
  }

  function enableProviderLock(bool enable) external onlyOwnerOrManager {
    providerLockEnabled = enable;
    emit ProviderLockEnabled(enable);
  }

  function excludeFromFee(address value, bool exclude) external onlyOwnerOrManager {
    excludedFromFee[value] = exclude;
    emit ExcludedFromFee(value, exclude);
  }

  function remove(address value, UserType utype) public returns (bool) {
    require(value != address(0), "cannot remove address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can remove manager");
      if (managers_.contains(value)) {
        _withdrawManagerFee(value, false);
        delete managerRewardDebt[value];
        success = managers_.remove(value);
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can remove liquidity provider");
      success = liquidityProviders_.remove(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can remove integrator");
      success = integrators_.remove(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, false);
    }
    return success;
  }

  function contains(address value, UserType utype) external view returns (bool) {
    if (utype == UserType.MANAGER) {
      return managers_.contains(value);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.contains(value);
    } else {
      return integrators_.contains(value);
    }
  }

  function length(UserType utype) external view returns (uint256) {
    if (utype == UserType.MANAGER) {
      return managers_.length();
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.length();
    } else {
      return integrators_.length();
    }
  }

  function at(uint256 index, UserType utype) external view returns (address) {
    if (utype == UserType.MANAGER) {
      return managers_.at(index);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.at(index);
    } else {
      return integrators_.at(index);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILP is IERC20 {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICerosToken is IERC20 {
  function ratio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INativeERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
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