//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IEIP3009.sol";
import "./interfaces/gamma/IUniProxy.sol";
import "./interfaces/gamma/IHypervisor.sol";
import "./interfaces/gamma/IMasterChef.sol";
import "./interfaces/gamma/IRewarder.sol";
import "./interfaces/uniswap/IUniswapV2Pair.sol";
import "./BaseYA.sol";
import "./libraries/GiddyUniswap.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "./GiddyConfigYA.sol";

contract GammaUsdcGiddyYA is BaseYA, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC2771ContextUpgradeable {
  uint256 constant private PRECISION = 1e36;
  uint constant private COMPOUND_THRESHOLD_GIDDY = 1e17;
  uint constant private PID = 0;
  address constant private UNI_PROXY = 0xe0A61107E250f8B5B24bf272baBFCf638569830C;
  address constant private MASTER_CHEF = 0x68678Cf174695fc2D27bd312DF67A3984364FFDd;
  address constant private GIDDY_REWARDER = 0x43e867915E4fBf7e3648800bF9bB5A4Bc7A49F37;
  address constant private USDC_GIDDY_POS = 0x1DDAe2e33C1d68211C5EAE05948FD298e72C541A;
  address constant private ALGEBRA_ROUTER = 0xf5b509bB0909a69B1c207E495f687a596C168E12;

  mapping(address => uint256) private userShares;
  uint256 private contractShares;
  uint256 public lastCompoundTime;

  function initialize(address _trustedForwarder) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __ERC2771Context_init(_trustedForwarder);
    lastCompoundTime = block.timestamp;
  }

  function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function getContractShares() public view override returns (uint256) {
    return contractShares;
  }

  function getContractBalance() public view override returns (uint256 amount) {
    (amount,) = IMasterChef(MASTER_CHEF).userInfo(PID, address(this));
  }

  function getContractRewards() public view override returns (uint256 amount) {
    amount = IRewarder(GIDDY_REWARDER).pendingToken(PID, address(this));
  }

  function getUserShares(address user) public view override returns (uint256) {
    return userShares[user];
  }

  function getUserBalance(address user) public view override returns (uint256) {
    return sharesToValue(getUserShares(user));
  }

  function sharesToValue(uint256 shares) public view override returns (uint256) {
    if (contractShares == 0) return 0;
    return getContractBalance() * shares / contractShares;
  }

  function compound() public override whenNotPaused {
    IMasterChef(MASTER_CHEF).deposit(PID, 0, address(this));
    uint value = IERC20(GIDDY_TOKEN).balanceOf(address(this));
    if (value > COMPOUND_THRESHOLD_GIDDY) {
      value = deductFeeGiddy(value, value * GIDDY_CONFIG.earningsFee() / BASE_PERCENT);
      (uint x, uint y) = IUniProxy(UNI_PROXY).getDepositAmount(USDC_GIDDY_POS, GIDDY_TOKEN, 1000e18);
      x = (x + y) / 2;
      (y,) = GiddyUniswap.calcPriceSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, 1000e18);
      x = (x * 1000e6 / y) + 1000e6;
      x = (value * 1000e6) / x;
      y = GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, address(this), value - x);

      if (!IERC20(GIDDY_TOKEN).approve(USDC_GIDDY_POS, x)) {
        revert("LP_GIDDY_APPROVE");
      }
      if (!IERC20(USDC_TOKEN).approve(USDC_GIDDY_POS, y)) {
        revert("LP_USDC_APPROVE");
      }
      value = IUniProxy(UNI_PROXY).deposit(y, x, address(this), USDC_GIDDY_POS, [uint(0), uint(0), uint(0), uint(0)]);
      if (!IERC20(USDC_GIDDY_POS).approve(MASTER_CHEF, value)) {
        revert("STAKE_APPROVE");
      }
      emit Compound(value, lastCompoundTime, getContractBalance());
      IMasterChef(MASTER_CHEF).deposit(PID, value, address(this));
      lastCompoundTime = block.timestamp;
    }
  }

  function depositCalc(uint256 value, uint256 fap) external view override returns (uint256 amountOut, uint256 priceImpact) {
    value -= fap;
    (uint x, uint y) = IUniProxy(UNI_PROXY).getDepositAmount(USDC_GIDDY_POS, USDC_TOKEN, 1e6);
    x = (x + y) / 2;
    (priceImpact, amountOut) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, 1e6, 1e6);
    x = (x * 1e18 / priceImpact) + 1e18;
    x = (value * 1e18) / x;
    y = (y * 1e18 / amountOut) + 1e18;
    y = (value * 1e18) / y;
    (amountOut, priceImpact) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, value - x, value - y);
    priceImpact = calcShares(USDC_GIDDY_POS, x, priceImpact);
    amountOut = calcShares(USDC_GIDDY_POS, y, amountOut);
    priceImpact = GiddyUniswap.calcPriceImpact(priceImpact, amountOut);
  }

  function deposit(bytes calldata auth, uint256 fap) external override whenNotPaused nonReentrant {
    compound();

    uint256 value = GiddyUniswap.approveAndTransferUsdc(auth, address(this), _msgSender());
    value = deductFeeUsdc(value, fap);
    (uint x, uint y) = IUniProxy(UNI_PROXY).getDepositAmount(USDC_GIDDY_POS, USDC_TOKEN, 1e6);
    x = (x + y) / 2;
    (y,) = GiddyUniswap.calcPriceSimpleAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, 1e6);
    x = (x * 1e18 / y) + 1e18;
    x = (value * 1e18) / x;
    y = GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, address(this), value - x);

    if (!IERC20(USDC_TOKEN).approve(USDC_GIDDY_POS, x)) {
      revert("LP_USDC_APPROVE");
    }
    if (!IERC20(GIDDY_TOKEN).approve(USDC_GIDDY_POS, y)) {
      revert("LP_GIDDY_APPROVE");
    }
    x = IUniProxy(UNI_PROXY).deposit(x, y, address(this), USDC_GIDDY_POS, [uint(0), uint(0), uint(0), uint(0)]);
    if (!IERC20(USDC_GIDDY_POS).approve(MASTER_CHEF, x)) {
      revert("STAKE_APPROVE");
    }

    uint256 shares = contractShares == 0 ? x * INIT_SHARES : x * contractShares / getContractBalance();
    userShares[_msgSender()] += shares;
    contractShares += shares;

    IMasterChef(MASTER_CHEF).deposit(PID, x, address(this));
    emit Deposit(_msgSender(), value);
  }

  function depositGiddyCalc(uint256 value, uint256 fap) external view override returns (uint256 amountOut, uint256 priceImpact) {
    value -= fap;
    (uint x, uint y) = IUniProxy(UNI_PROXY).getDepositAmount(USDC_GIDDY_POS, GIDDY_TOKEN, 1e18);
    x = (x + y) / 2;
    (priceImpact, amountOut) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, 1e18, 1e18);
    x = (x * 1e6 / priceImpact) + 1e6;
    x = (value * 1e6) / x;
    y = (y * 1e6 / amountOut) + 1e6;
    y = (value * 1e6) / y;
    (amountOut, priceImpact) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, value - x, value - y);
    priceImpact = calcShares(USDC_GIDDY_POS, priceImpact, x);
    amountOut = calcShares(USDC_GIDDY_POS, amountOut, y);
    priceImpact = GiddyUniswap.calcPriceImpact(priceImpact, amountOut);
  }

  function depositGiddy(ApproveWithAuthorization.ApprovalRequest calldata req, bytes calldata sig, uint256 fap) external override whenNotPaused nonReentrant {
    compound();
    
    GiddyUniswap.approveAndTransferGiddy(req, sig, address(this), _msgSender());
    uint256 value = deductFeeGiddy(req.value, fap);

    (uint x, uint y) = IUniProxy(UNI_PROXY).getDepositAmount(USDC_GIDDY_POS, GIDDY_TOKEN, 1e18);
    x = (x + y) / 2;
    (y,) = GiddyUniswap.calcPriceSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, 1e18);
    x = (x * 1e6 / y) + 1e6;
    x = (value * 1e6) / x;
    y = GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, address(this), value - x);

    if (!IERC20(GIDDY_TOKEN).approve(USDC_GIDDY_POS, x)) {
      revert("LP_GIDDY_APPROVE");
    }
    if (!IERC20(USDC_TOKEN).approve(USDC_GIDDY_POS, y)) {
      revert("LP_USDC_APPROVE");
    }
    x = IUniProxy(UNI_PROXY).deposit(y, x, address(this), USDC_GIDDY_POS, [uint(0), uint(0), uint(0), uint(0)]);
    if (!IERC20(USDC_GIDDY_POS).approve(MASTER_CHEF, x)) {
      revert("STAKE_APPROVE");
    }

    uint256 shares = contractShares == 0 ? x * INIT_SHARES : x * contractShares / getContractBalance();
    userShares[_msgSender()] += shares;
    contractShares += shares;

    IMasterChef(MASTER_CHEF).deposit(PID, x, address(this));
    emit Deposit(_msgSender(), giddyToUsdc(value));
  }

  function withdrawCalc(uint256 shares, uint256 fap) external view override returns (uint256 amountOut, uint256 priceImpact) {
    (shares, priceImpact) = calcTokens(USDC_GIDDY_POS, sharesToValue(shares));
    (priceImpact, amountOut) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, priceImpact, priceImpact);
    priceImpact += shares;
    amountOut += shares;
    priceImpact = GiddyUniswap.calcPriceImpact(priceImpact, amountOut);
    amountOut -= fap;
  }

  function withdraw(uint256 shares, uint256 fap) external override whenNotPaused nonReentrant {
    require(shares > 0);
    require(shares <= userShares[_msgSender()]);
    compound();

    uint256 value = getContractBalance() * shares / contractShares;
    userShares[_msgSender()] -= shares;
    contractShares -= shares;

    IMasterChef(MASTER_CHEF).withdraw(PID, value, address(this));
    if (!IERC20(USDC_GIDDY_POS).approve(USDC_GIDDY_POS, value)) {
      revert("REMOVE_LP_APPROVE");
    }
    (value, shares) = IHypervisor(USDC_GIDDY_POS).withdraw(value, address(this), address(this), [uint(0), uint(0), uint(0), uint(0)]);
    value += GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, address(this), shares);
    value = deductFeeUsdc(value, fap);

    if (!IERC20(USDC_TOKEN).transfer(_msgSender(), value)) {
      revert("USER_TRANSFER");
    }
    emit Withdraw(_msgSender(), value);
  }

  function withdrawGiddyCalc(uint256 shares, uint256 fap) external view override returns (uint256 amountOut, uint256 priceImpact) {
    (priceImpact, shares) = calcTokens(USDC_GIDDY_POS, sharesToValue(shares));
    (priceImpact, amountOut) = GiddyUniswap.calcSwapAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, priceImpact, priceImpact);
    priceImpact += shares;
    amountOut += shares;
    priceImpact = GiddyUniswap.calcPriceImpact(priceImpact, amountOut);
    amountOut -= fap;
  }

  function withdrawGiddy(uint256 shares, uint256 fap) external override whenNotPaused nonReentrant {
    require(shares > 0);
    require(shares <= userShares[_msgSender()]);
    compound();

    uint256 value = getContractBalance() * shares / contractShares;
    userShares[_msgSender()] -= shares;
    contractShares -= shares;

    IMasterChef(MASTER_CHEF).withdraw(PID, value, address(this));
    if (!IERC20(USDC_GIDDY_POS).approve(USDC_GIDDY_POS, value)) {
      revert("REMOVE_LP_APPROVE");
    }
    (shares, value) = IHypervisor(USDC_GIDDY_POS).withdraw(value, address(this), address(this), [uint(0), uint(0), uint(0), uint(0)]);
    value += GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, USDC_TOKEN, GIDDY_TOKEN, address(this), shares);
    value = deductFeeGiddy(value, fap);

    if (!IERC20(GIDDY_TOKEN).transfer(_msgSender(), value)) {
      revert("USER_TRANSFER");
    }
    emit Withdraw(_msgSender(), giddyToUsdc(value));
  }

  function usdcToGiddy(uint256 amount) private view returns(uint256)
  {
    (uint256 resUsdc, uint256 resGiddy,) = IUniswapV2Pair(GIDDY_USDC_PAIR).getReserves();
    require(resUsdc > 0 && resGiddy > 0);
    return (amount * resGiddy) / resUsdc;
  }

  function usdcToGiddyLP(uint256 value) private view returns (uint256) {
    (uint256 resUsdc,,) = IUniswapV2Pair(GIDDY_USDC_PAIR).getReserves();
    return (IUniswapV2Pair(GIDDY_USDC_PAIR).totalSupply() * (value / 2)) / resUsdc;
  }

  function giddyLPToUsdc(uint256 value) private view returns (uint256) {
    (uint256 resUsdc,,) = IUniswapV2Pair(GIDDY_USDC_PAIR).getReserves();
    return (resUsdc * value * 2) / IUniswapV2Pair(GIDDY_USDC_PAIR).totalSupply();
  }

  function deductFeeUsdc(uint256 amount, uint256 fap) private returns (uint256) {
    if (fap > 0) {
      if (!IERC20(USDC_TOKEN).transfer(GIDDY_CONFIG.feeAccount(), fap)) {
        revert("USDC_FEE_TRANSFER");
      }
    }
    return amount - fap;
  }

  function deductFeeGiddy(uint256 amount, uint256 fap) private returns (uint256) {
    if (fap > 0) {
      GiddyUniswap.swapTokensSimpleAlgebra(ALGEBRA_ROUTER, GIDDY_TOKEN, USDC_TOKEN, GIDDY_CONFIG.feeAccount(), fap);
    }
    return amount - fap;
  }

  function calcShares(address pos, uint deposit0, uint deposit1) private view returns (uint shares) {   
    IHypervisor hypervisor = IHypervisor(pos);
    uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(hypervisor.currentTick());
    uint256 price = FullMath.mulDiv(uint256(sqrtPrice) ** 2, PRECISION, 2 ** (96 * 2));
    (uint256 pool0, uint256 pool1) = hypervisor.getTotalAmounts();
    shares = deposit1 + ((deposit0 * price) / PRECISION);
    uint256 total = hypervisor.totalSupply();
    if (total != 0) {
      uint256 pool0PricedInToken1 = (pool0 * price) / PRECISION;
      shares = (shares * total) / (pool0PricedInToken1 + pool1);
    }
  }

  function calcTokens(address pos, uint shares) private view returns (uint withdraw0, uint withdraw1) {
    IHypervisor hypervisor = IHypervisor(pos);
    (withdraw0, withdraw1) = hypervisor.getTotalAmounts();
    uint totalSupply = hypervisor.totalSupply();
    withdraw0 = (withdraw0 * shares) / totalSupply;
    withdraw1 = (withdraw1 * shares) / totalSupply;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IEIP3009 {
    function approveWithAuthorization(
        address owner,
        address spender,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
  }

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface IUniProxy {
  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(address pos, address token, uint256 _deposit) external view returns (uint256 amountStart, uint256 amountEnd);

  /// @notice Deposit into the given position
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos Hypervisor Address
  /// @return shares Amount of liquidity tokens received
  function deposit(uint256 deposit0, uint256 deposit1, address to, address pos, uint256[4] memory minIn) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface IHypervisor {
  /// @param shares Number of liquidity tokens to redeem as pool assets
  /// @param to Address to which redeemed pool assets are sent
  /// @param from Address from which liquidity tokens are sent
  /// @param minAmounts min amount0,1 returned for shares of liq 
  /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
  /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
  function withdraw(uint256 shares, address to, address from, uint256[4] memory minAmounts) external returns (uint256 amount0, uint256 amount1);
      
  /// @return total0 Quantity of token0 in both positions and unused in the Hypervisor
  /// @return total1 Quantity of token1 in both positions and unused in the Hypervisor
  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

  /// @return tick Uniswap pool's current price tick
  function currentTick() external view returns (int24 tick);

  function totalSupply() external view returns (uint256);
  function baseLower() external view returns (int24);
  function baseUpper() external view returns (int24);
  function limitLower() external view returns (int24);
  function limitUpper() external view returns (int24);
  function pool() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function whitelistedAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
  /// @notice Deposit LP tokens to MCV2 for SUSHI allocation.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to deposit.
  /// @param to The receiver of `amount` deposit benefit.
  function deposit(uint256 pid, uint256 amount, address to) external;
  /// @notice Withdraw LP tokens from MCV2.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  /// @param to Receiver of the LP tokens.
  function withdraw(uint256 pid, uint256 amount, address to) external;
  function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
   /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
  function emergencyWithdraw(uint256 pid, address to) external;
  function getRewarder(uint256 _pid, uint256 _rid) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewarder {
  /// @notice View function to see pending Token
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending SUSHI reward for a given user.
  function pendingToken(uint256 _pid, address _user) external view returns (uint256 pending);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ApproveWithAuthorization.sol";
import "./interfaces/uniswap/IUniswapV2Pair.sol";
import "./GiddyConfigYA.sol";

abstract contract BaseYA {
  uint256 constant internal INIT_SHARES = 1e10;
  uint256 constant internal BASE_PERCENT = 1e6;
  address constant internal SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  address constant internal USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant internal GIDDY_TOKEN = 0x67eB41A14C0fe5CD701FC9d5A3D6597A72F641a6;
  address constant internal GIDDY_USDC_PAIR = 0xDE990994309BC08E57aca82B1A19170AD84323E8;
  GiddyConfigYA constant internal GIDDY_CONFIG = GiddyConfigYA(0x7D1a307dA8928C0086CC9b2c8a7f447e25e9BED4);

  function getContractShares() public view virtual returns (uint256);
  function getContractBalance() public view virtual returns (uint256);
  function getContractRewards() public view virtual returns (uint256);
  function getUserShares(address user) public view virtual returns (uint256);
  function getUserBalance(address user) public view virtual returns (uint256);
  function sharesToValue(uint256 shares) public view virtual returns (uint256);

  function compound() public virtual;
  function depositCalc(uint256 value, uint256 fap) external virtual returns (uint256 amountOut, uint256 priceImpact);
  function deposit(bytes calldata auth, uint256 fap) external virtual;
  function depositGiddyCalc(uint256 value, uint256 fap) external virtual returns (uint256 amountOut, uint256 priceImpact);
  function depositGiddy(ApproveWithAuthorization.ApprovalRequest calldata req, bytes calldata sig, uint256 fap) external virtual;
  function withdrawCalc(uint256 shares, uint256 fap) external virtual returns (uint256 amountOut, uint256 priceImpact);
  function withdraw(uint256 shares, uint256 fap) external virtual;
  function withdrawGiddyCalc(uint256 shares, uint256 fap) external virtual returns (uint256 amountOut, uint256 priceImpact);
  function withdrawGiddy(uint256 shares, uint256 fap) external virtual;

  event Deposit(address indexed from, uint256 usdc);
  event Withdraw(address indexed from, uint256 usdc);
  event Compound(uint256 value, uint256 lastCompoundTime, uint256 lastContractBalance);

  function giddyToUsdc(uint256 amount) internal view returns(uint256)
  {
    (uint256 resUsdc, uint256 resGiddy,) = IUniswapV2Pair(GIDDY_USDC_PAIR).getReserves();
    require(resUsdc > 0 && resGiddy > 0, "Invalid price data");
    return amount * resUsdc / resGiddy;
  }

  function getGlobalSettings() public view virtual returns(address feeAccount, uint256 earningsFee) {
    feeAccount = GIDDY_CONFIG.feeAccount();
    earningsFee = GIDDY_CONFIG.earningsFee();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
import "../interfaces/uniswap/IUniswapV3Router.sol";
import "../interfaces/uniswap/IUniswapV3Factory.sol";
import "../interfaces/uniswap/IUniswapV3Pool.sol";
import "../interfaces/uniswap/IUniswapV3Quoter.sol";
import "../interfaces/algebra/ISwapRouter.sol";
import "../interfaces/algebra/IAlgebraFactory.sol";
import "../interfaces/algebra/IAlgebraPool.sol";
import "../interfaces/IEIP3009.sol";
import "../ApproveWithAuthorization.sol";
import "./TickMath.sol";

library GiddyUniswap {
  address constant internal USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant internal GIDDY_TOKEN = 0x67eB41A14C0fe5CD701FC9d5A3D6597A72F641a6;

  uint256 constant private BASE_PERCENT = 1e6;
  uint256 constant internal SWAP_FEE_V2 = 3000;

  function approveAndTransferUsdc(bytes calldata auth, address recipient, address sender) public returns (uint256) {
    (address owner, address spender, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) = abi.decode(
      auth,
      (address, address, uint256, uint256, uint256, bytes32, uint8, bytes32, bytes32)
    );   
    require(spender == address(this), "Failed spender check");
    require(owner == sender, "Failed owner check");
    require(value > 0, "Invalid auth amount");
    IEIP3009(USDC_TOKEN).approveWithAuthorization(owner, spender, value, validAfter, validBefore, nonce, v, r, s);
    if (!IERC20(USDC_TOKEN).transferFrom(owner, recipient, value)) {
      revert("Failed one step transfer");
    }
    return value;
  }

  function approveAndTransferGiddy(ApproveWithAuthorization.ApprovalRequest calldata req, bytes calldata sig, address recipient, address sender) public {
    require(req.spender == address(this), "Failed spender check");
    require(req.owner == sender, "Failed owner check");
    require(req.value > 0, "Invalid auth amount");
    ApproveWithAuthorization(GIDDY_TOKEN).approveWithAuthorization(req, sig);
    if (!IERC20(GIDDY_TOKEN).transferFrom(req.owner, recipient, req.value)) {
      revert("Failed one step transfer");
    }
  }

  function getPairData(address pair) public view returns (uint constantProduct, uint totalSupply) {
    IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(pair);
    (uint reserve0, uint reserve1,) = uniswapV2Pair.getReserves();
    constantProduct = reserve0 * reserve1;
    totalSupply = uniswapV2Pair.totalSupply();
  }

  function calcPairEarnings(uint cpBefore, uint supplyBefore, uint cpAfter, uint supplyAfter, uint lpValue) public pure returns (uint) {
    uint cpBase = (cpAfter * supplyBefore * supplyBefore) / (supplyAfter * supplyAfter);
    return lpValue - (lpValue * cpBefore) / cpBase;
  }

  function calcPriceImpact(uint256 beforeSwap, uint256 afterSwap) public pure returns (uint256 priceImpact) {
    priceImpact = beforeSwap * BASE_PERCENT / afterSwap;
    if (priceImpact > BASE_PERCENT) {
      priceImpact -= BASE_PERCENT;
    }
    else {
      priceImpact = 0;
    }
  }

  function calcSwap(address router, address src, address dst, uint256 inBefore, uint256 inAfter) public view returns (uint256 outBefore, uint256 outAfter) {
    IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router01(router).factory()).getPair(src, dst));
    (uint256 srcReserve, uint256 dstReserve,) = pair.getReserves();
    if (pair.token0() != src) {
      uint256 temp = srcReserve;
      srcReserve = dstReserve;
      dstReserve = temp;
    }
    outBefore = (inBefore * dstReserve) / srcReserve;
    outAfter = dstReserve - ((srcReserve * dstReserve) / (srcReserve + inAfter));
    outAfter = (outAfter * (BASE_PERCENT - SWAP_FEE_V2)) / BASE_PERCENT;
  }

  function calcPrice(address router, address[] memory route, uint256 value) public view returns (uint256 amountOut, uint256 priceImpact) {
    uint256 outBefore = value;
    amountOut = value;
    for (uint16 i = 0; i < (route.length - 1); i++) {
      (outBefore, amountOut) = calcSwap(router, route[i], route[i + 1], outBefore, amountOut);
    }
    priceImpact = calcPriceImpact(outBefore, amountOut);
  }

  function calcPriceSimple(address router, address src, address dst, uint256 value) public view returns (uint256 amountOut, uint256 priceImpact) {
    address[] memory route = new address[](2);
    route[0] = src;
    route[1] = dst;
    (amountOut, priceImpact) = calcPrice(router, route, value);
  }

  function swapTokens(address router, address[] memory route, address receiver, uint256 amount) public returns (uint256) {
    if (!IERC20(route[0]).approve(router, amount)) {
      revert();
    }
    return IUniswapV2Router02(router).swapExactTokensForTokens(amount, 0, route, receiver, block.timestamp + 1200)[route.length - 1];
  }

  function swapTokensSimple(address router, address src, address dst, address receiver, uint256 amount) public returns (uint256) {
    address[] memory route = new address[](2);
    route[0] = src;
    route[1] = dst;
    return swapTokens(router, route, receiver, amount);
  }

  function calcSwapV3(address router, address quoter, address src, address dst, uint24 fee, uint256 inBefore, uint256 inAfter) public returns (uint256 outBefore, uint256 outAfter) {
    IUniswapV3Pool pool = IUniswapV3Pool(IUniswapV3Factory(IUniswapV3Router(router).factory()).getPool(src, dst, fee));
    (uint160 sqrtRatioX96,,,,,,) = pool.slot0();
    if (src == pool.token0()) {
      outBefore = ((((sqrtRatioX96 * 1e10) / (2 ** 96)) ** 2) * inBefore) / (1e10 ** 2);
      // outBefore = ((sqrtRatioX96 ** 2) * inBefore) / 2 ** 192;
    }
    else {
      outBefore = ((((2 ** 96 * 1e10) / sqrtRatioX96) ** 2) * inBefore) / (1e10 ** 2);
      // outBefore = ((2 ** 192) * inBefore) / (sqrtRatioX96 ** 2);
    }
    outAfter = IUniswapV3Quoter(quoter).quoteExactInputSingle(src, dst, fee, inAfter, 0);
  }

  function calcPriceSimpleV3(address router, address quoter, address src, address dst, uint24 fee, uint256 value) public returns (uint256 amountOut, uint256 priceImpact) {
    uint256 before = value;
    (before, amountOut) = calcSwapV3(router, quoter, src, dst, fee, before, value);
    priceImpact = calcPriceImpact(before, amountOut);
  }

  function swapTokensSimpleV3(address router, address src, address dst, uint24 fee, address receiver, uint256 amount) public returns (uint256) {
    if (!IERC20(src).approve(router, amount)) {
      revert();
    }
    IUniswapV3Router.ExactInputSingleParams memory param;
    param.tokenIn = src;
    param.tokenOut = dst;
    param.fee = fee;
    param.recipient = receiver;
    param.deadline = block.timestamp + 1200;
    param.amountIn = amount;
    param.amountOutMinimum = 0;
    param.sqrtPriceLimitX96 = 0;
    return IUniswapV3Router(router).exactInputSingle(param);
  }

  function calcSwapAlgebra(address router, address src, address dst, uint256 inBefore, uint256 inAfter) public view returns (uint256 outBefore, uint256 outAfter) {
    IAlgebraPool pool = IAlgebraPool(IAlgebraFactory(ISwapRouter(router).factory()).poolByPair(src, dst));
    (uint160 sqrtRatioX96,,uint16 fee,,,,) = pool.globalState();
    if (src == pool.token0()) {
      outBefore = ((((sqrtRatioX96 * 1e10) / (2 ** 96)) ** 2) * inBefore) / (1e10 ** 2);
      outAfter = ((((sqrtRatioX96 * 1e10) / (2 ** 96)) ** 2) * inAfter) / (1e10 ** 2);
    }
    else {
      outBefore = ((((2 ** 96 * 1e10) / sqrtRatioX96) ** 2) * inBefore) / (1e10 ** 2);
      outAfter = ((((2 ** 96 * 1e10) / sqrtRatioX96) ** 2) * inAfter) / (1e10 ** 2);
    }
    outAfter = (outAfter * (1e6 - fee)) / 1e6;
  }

  function calcPriceSimpleAlgebra(address router, address src, address dst, uint256 value) public view returns (uint256 amountOut, uint256 priceImpact) {
    uint256 before = value;
    (before, amountOut) = calcSwapAlgebra(router, src, dst, before, value);
    priceImpact = calcPriceImpact(before, amountOut);
  }

  function swapTokensSimpleAlgebra(address router, address src, address dst, address receiver, uint256 amount) public returns (uint256) {
    if (!IERC20(src).approve(router, amount)) {
      revert();
    }
    ISwapRouter.ExactInputSingleParams memory param;
    param.tokenIn = src;
    param.tokenOut = dst;
    param.recipient = receiver;
    param.deadline = block.timestamp + 1200;
    param.amountIn = amount;
    return ISwapRouter(router).exactInputSingle(param);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
    // get abs value
    int24 mask = tick >> (24 - 1);
    uint24 absTick = uint24((tick ^ mask) - mask);
    require(absTick <= uint24(MAX_TICK), "T");

    uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = type(uint256).max / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    price = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param price The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(price >= MIN_SQRT_RATIO && price < MAX_SQRT_RATIO, "R");
    uint256 ratio = uint256(price) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    assembly {
      let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(5, gt(r, 0xFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(4, gt(r, 0xFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(3, gt(r, 0xFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(2, gt(r, 0xF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(1, gt(r, 0x3))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := gt(r, 0x1)
      msb := or(msb, f)
    }

    if (msb >= 128) r = ratio >> (msb - 127);
    else r = ratio << (127 - msb);

    int256 log_2 = (int256(msb) - 128) << 64;

    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(63, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(62, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(61, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(60, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(59, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(58, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(57, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(56, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(55, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(54, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(53, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(52, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(51, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(50, f))
    }

    int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

    int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

    tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

contract GiddyConfigYA is OwnableUpgradeable, ERC2771ContextUpgradeable {
  address public feeAccount;
  uint256 public earningsFee;
  mapping(address => bool) public verifiedContracts;
  address public swapRouter;

  function initialize(address _trustedForwarder) public initializer {
    __Ownable_init();
    __ERC2771Context_init(_trustedForwarder);
  }

  function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function setFeeAccount(address account) public onlyOwner {
    feeAccount = account;
  }

  function setEarningsFee(uint256 fee) public onlyOwner {
    earningsFee = fee;
  }

  function setSwapRouter(address router) public onlyOwner {
    swapRouter = router;
  }

  function setVerifiedContracts(address[] calldata contracts, bool enabled) public onlyOwner {
    for (uint8 i = 0; i < contracts.length; i++) {
      verifiedContracts[contracts[i]] = enabled;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { EIP712 } from "./libraries/EIP712.sol";

abstract contract ApproveWithAuthorization is ERC20Upgradeable {

    struct ApprovalRequest {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        bytes32 nonce;
        uint256 currentApproval;
    }

    // keccak256("ApproveWithAuthorization(address owner,address spender,uint256 value,uint256 deadline,bytes32 nonce,uint256 currentApproval)")
    bytes32 public constant APPROVE_WITH_AUTHORIZATION_TYPEHASH = 0x7728b251b2f84612fd6271e82c54281223f0f808d4a779b17fc3e4aac5ccfb0b;

    bytes32 public DOMAIN_SEPARATOR;

    /**
     * @dev authorizer address => nonce => state (true = used / false = unused)
     */
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    string
        internal constant _INVALID_SIGNATURE_ERROR = "ApprovalRequest: invalid signature";
    string
        internal constant _AUTHORIZATION_USED_ERROR = "ApprovalRequest: authorization is already used";

    /**
     * @notice Returns the state of an authorization
     * @dev Nonces are randomly generated 32-byte data unique to the authorizer's
     * address
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @return True if the nonce is used
     */
    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    function approveWithAuthorization(
        ApprovalRequest memory req,
        bytes calldata sig
    ) external {

        require(block.timestamp < req.deadline, "ApprovalRequest: expired");
        require(!_authorizationStates[req.owner][req.nonce], _AUTHORIZATION_USED_ERROR);
        require(allowance(req.owner, req.spender) == req.currentApproval, "ApprovalRequest: Incorrect approval given");

        bytes memory data = abi.encodePacked(
            APPROVE_WITH_AUTHORIZATION_TYPEHASH,
            abi.encode(
                req.owner,
                req.spender,
                req.value,
                req.deadline,
                req.nonce,
                req.currentApproval
            )
        );

        require(
            EIP712.recover(DOMAIN_SEPARATOR, sig, data) == req.owner,
            _INVALID_SIGNATURE_ERROR
        );

        _authorizationStates[req.owner][req.nonce] = true;
        emit AuthorizationUsed(req.owner, req.nonce);

        _approve(req.owner, req.spender, req.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library EIP712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    bytes32(chainId),
                    address(this)
                )
            );
    }

    function recover(
        bytes32 domainSeparator,
        bytes calldata sig,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        address recovered = ECDSA.recover(digest, sig);
        require(recovered != address(0), "EIP712: invalid signature");
        return recovered;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router is IUniswapV3SwapCallback {
    function factory() external pure returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Factory {
  function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Pool {
  function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function tickSpacing() external pure returns (int24);
  function liquidity() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IUniswapV3Quoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapRouter {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 limitSqrtPrice;
  }

  struct SwapCallbackData {
    bytes path;
    address payer;
  }

  function factory() external pure returns (address);
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlgebraFactory {
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlgebraPool {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function globalState() external view returns (uint160 price, int24 tick, uint16 fee, uint16 timepointIndex, uint8 communityFeeToken0, uint8 communityFeeToken1, bool unlocked);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}