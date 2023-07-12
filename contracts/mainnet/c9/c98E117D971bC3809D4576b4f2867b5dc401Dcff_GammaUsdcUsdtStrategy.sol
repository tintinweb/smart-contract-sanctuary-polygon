//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/gamma/IUniProxy.sol";
import "./interfaces/gamma/IHypervisor.sol";
import "./interfaces/gamma/IMasterChef.sol";
import "./interfaces/gamma/IRewarder.sol";
import "./interfaces/quick/IDragonsLair.sol";
import "./GiddyVaultV2.sol";

contract GammaUsdcUsdtStrategy is GiddyStrategyV2, Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  uint256 constant private BASE_PERCENT = 1e6;
  uint256 constant private COMPOUND_THRESHOLD_WMATIC = 1e18;
  uint256 constant private COMPOUND_THRESHOLD_QUICK = 1e18;
  uint256 constant private PID = 11;
  address constant private MASTER_CHEF = 0x20ec0d06F447d550fC6edee42121bc8C1817b97D;
  address constant private USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant private USDT_TOKEN = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address constant private WMATIC_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address constant private QUICK_TOKEN = 0xB5C064F955D8e7F38fE0460C556a72987494eE17;
  address constant private DQUICK_TOKEN_AND_LAIR = 0x958d208Cdf087843e9AD98d23823d32E17d723A1;
  address constant private POS = 0x795f8c9B0A0Da9Cd8dea65Fc10f9B57AbC532E58;

  GiddyVaultV2 public vault;

  function initialize(address vaultAddress) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    vault = GiddyVaultV2(vaultAddress);
  }

  function getContractBalance() public view override returns (uint256 amount) {
    (amount,) = IMasterChef(MASTER_CHEF).userInfo(PID, address(this));
     amount += IERC20(POS).balanceOf(address(this));
  }

  function getContractRewards() public view override returns (uint256[] memory amounts) {
    amounts = new uint256[](4);
    amounts[0] += IRewarder(IMasterChef(MASTER_CHEF).getRewarder(PID, 1)).pendingToken(PID, address(this));
    amounts[0] += IERC20(WMATIC_TOKEN).balanceOf(address(this));
    amounts[1] = COMPOUND_THRESHOLD_WMATIC;

    amounts[2] += IRewarder(IMasterChef(MASTER_CHEF).getRewarder(PID, 0)).pendingToken(PID, address(this));
    amounts[2] += IERC20(DQUICK_TOKEN_AND_LAIR).balanceOf(address(this));
    amounts[2] = IDragonsLair(DQUICK_TOKEN_AND_LAIR).dQUICKForQUICK(amounts[2]);
    amounts[2] += IERC20(QUICK_TOKEN).balanceOf(address(this));
    amounts[3] = COMPOUND_THRESHOLD_QUICK;
  }

  function compound(SwapInfo[] calldata swaps) external override onlyVault returns (uint256 staked) {
    if (swaps.length == 0) return 0;
    require(swaps.length == 4, "SWAP_LENGTH");

    IMasterChef(MASTER_CHEF).deposit(PID, 0, address(this));
    IDragonsLair(DQUICK_TOKEN_AND_LAIR).leave(IERC20(DQUICK_TOKEN_AND_LAIR).balanceOf(address(this)));

    address router = vault.config().swapRouter();
    uint256[] memory amounts = new uint256[](2);
    if (swaps[0].amount > 0) {
      amounts[0] += GiddyLibraryV2.routerSwap(router, swaps[0], address(this), address(this), USDC_TOKEN);
    }
    if (swaps[1].amount > 0) {
      amounts[1] += GiddyLibraryV2.routerSwap(router, swaps[1], address(this), address(this), USDT_TOKEN);
    }
    if (swaps[2].amount > 0) {
      amounts[0] += GiddyLibraryV2.routerSwap(router, swaps[2], address(this), address(this), USDC_TOKEN);
    }
    if (swaps[3].amount > 0) {
      amounts[1] += GiddyLibraryV2.routerSwap(router, swaps[3], address(this), address(this), USDT_TOKEN);
    }
    amounts[0] = deductEarningsFee(USDC_TOKEN, amounts[0]);
    amounts[1] = deductEarningsFee(USDT_TOKEN, amounts[1]);
    return depositLP(amounts);
  }

  function deposit(uint256[] memory amounts) external override nonReentrant onlyVault returns (uint256 staked) {
    return depositLP(amounts);
  }

  function depositNative(uint256 amount) external override nonReentrant onlyVault returns (uint256 staked) {
    depositChef(amount);
    return amount;
  }

  function withdraw(uint256 staked) external override nonReentrant onlyVault returns (uint256[] memory amounts) {
    uint256 contractBalance = IERC20(POS).balanceOf(address(this));
    if (staked > contractBalance) {
      IMasterChef(MASTER_CHEF).withdraw(PID, staked - contractBalance, address(this));
    }
    amounts = new uint[](2);
    (amounts[0], amounts[1]) = IHypervisor(POS).withdraw(staked, address(this), address(this), [uint(0), uint(0), uint(0), uint(0)]);
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(USDC_TOKEN), address(vault), amounts[0]);
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(USDT_TOKEN), address(vault), amounts[1]);
  }

  function moveStrategy(address strategy) external override onlyVault {
    IMasterChef(MASTER_CHEF).emergencyWithdraw(PID, address(this));
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(POS), strategy, IERC20(POS).balanceOf(address(this)));
  }

  function emergencyWithdraw() external onlyOwner {
    IMasterChef(MASTER_CHEF).emergencyWithdraw(PID, address(this));
  }

  function emergencyDeposit() external onlyOwner {
    depositChef(IERC20(POS).balanceOf(address(this)));
  }

  function depositChef(uint256 amount) private {
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(POS), MASTER_CHEF, amount);
    IMasterChef(MASTER_CHEF).deposit(PID, amount, address(this));
  }

  function depositLP(uint256[] memory amounts) private returns (uint256 staked) {
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(USDC_TOKEN), POS, amounts[0]);
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(USDT_TOKEN), POS, amounts[1]);
    staked = IUniProxy(IHypervisor(POS).whitelistedAddress()).deposit(amounts[0], amounts[1], address(this), POS, [uint(0), uint(0), uint(0), uint(0)]);
    depositChef(staked);
  }

  function deductEarningsFee(address token, uint256 amount) private returns (uint256) {
    uint fee = amount * vault.config().earningsFee() / BASE_PERCENT;
    if (fee > 0) {
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), vault.config().feeAccount(), fee);
    }
    return amount - fee;
  }

  modifier onlyVault() {
    require(_msgSender() == address(vault), "VAULT_CHECK");
    _;
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDragonsLair {
    function enter(uint256 amount) external;
    function leave(uint256 amount) external;
    function dQUICKForQUICK(uint256 amount) external view returns (uint256);
    function QUICKForDQUICK(uint256 amount) external view returns (uint256);
    function QUICKBalance(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IEIP3009.sol";
import "./ApproveWithAuthorization.sol";
import "./GiddyStrategyV2.sol";
import "./GiddyQueryV2.sol";
import "./GiddyConfigYA.sol";

contract GiddyVaultV2 is ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC2771ContextUpgradeable {
  struct VaultAuth {
    bytes signature;
    bytes32 nonce;
    uint256 deadline;
    uint256 amount;
    uint256 fap;
    uint256 fapIndex;
    SwapInfo[] depositSwaps;
    SwapInfo[] compoundSwaps;
  }

  struct UsdcAuth {
    address owner;
    address spender;
    uint256 value;
    uint256 validAfter;
    uint256 validBefore;
    bytes32 nonce;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  uint256 constant internal INIT_SHARES = 1e10;
  uint256 constant internal BASE_PERCENT = 1e6;
  address constant internal USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant internal GIDDY_TOKEN = 0x67eB41A14C0fe5CD701FC9d5A3D6597A72F641a6;
  address constant internal GIDDY_USDC_PAIR = 0xDE990994309BC08E57aca82B1A19170AD84323E8;
  bytes32 constant public SWAP_AUTHORIZATION_TYPEHASH = keccak256("VaultAuth(bytes32 nonce,uint256 deadline,uint256 amount,uint256 fap,uint256 fapIndex,bytes[] data)");

  bytes32 public domainSeparator;
  mapping(bytes32 => bool) private nonceMap;
  string public name;

  mapping(address => uint256) private userShares;
  uint256 private contractShares;
  GiddyStrategyV2 public strategy;
  GiddyQueryV2 public query;
  GiddyConfigYA public config;
  bool public rewardsEnabled;

  event Deposit(address indexed from, uint256 fap, address token, uint256 amount, uint256 shares);
  event DepositExact(address indexed from, uint256 fap, uint256 fapIndex, uint256[] amounts, uint256 shares);
  event Withdraw(address indexed from, uint256 fap, uint256 fapIndex, uint256 shares, uint256[] amounts);
  event CompoundV2(uint256 contractBalance, uint256 contractShares);

  function initialize(address trustedForwarder, address configAddress, string calldata _name) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __ERC2771Context_init(trustedForwarder);
    name = _name;
    domainSeparator = EIP712.makeDomainSeparator(_name, "1.0");
    config = GiddyConfigYA(configAddress);
    rewardsEnabled = true;
  }

  function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function getNativeToken() external view returns (address token) {
    return query.getNativeToken();
  }

  function getDepositTokens() external view returns (address[] memory tokens) {
    return query.getDepositTokens(); 
  }

  function getDepositRatios() external view returns (uint256[] memory ratios) {
    return query.getDepositRatios(); 
  }

  function getWithdrawTokens() external view returns (address[] memory tokens) {
    return query.getWithdrawTokens(); 
  }

  function getWithdrawAmounts(uint256 shares) external view returns (uint256[] memory amounts) {
    return query.getWithdrawAmounts(sharesToValue(shares));
  }

  function getRewardTokens() external view returns (address[] memory tokens) {
    return query.getRewardTokens(); 
  }

  function getContractRewards() public view returns (uint256[] memory amounts) {
    return strategy.getContractRewards();
  }

  function getContractShares() public view returns (uint256 shares) {
    return contractShares;
  }

  function getContractBalance() public view returns (uint256 amount) {
    return strategy.getContractBalance();
  }

  function getUserShares(address user) public view returns (uint256 shares) {
    return userShares[user];
  }

  function getUserBalance(address user) public view returns (uint256 amount) {
    return sharesToValue(getUserShares(user));
  }

  function sharesToValue(uint256 shares) public view returns (uint256 amount) {
    if (contractShares == 0) return 0;
    return getContractBalance() * shares / contractShares;
  }
  
  function compound(VaultAuth calldata vaultAuth) public whenNotPaused {
    validateVaultAuth(vaultAuth);
    if (strategy.compound(vaultAuth.compoundSwaps) > 0) {
      emit CompoundV2(getContractBalance(), getContractShares());
    }
  }

  function depositSingle(VaultAuth calldata vaultAuth) external whenNotPaused nonReentrant {
    validateVaultAuth(vaultAuth);
    compoundCheck(vaultAuth.compoundSwaps);
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(vaultAuth.depositSwaps[0].srcToken), _msgSender(), address(this), vaultAuth.amount);
    deductFee(vaultAuth.depositSwaps[0].srcToken, vaultAuth.amount, vaultAuth.fap);
    uint256 shares = joinStrategy(_msgSender(), vaultAuth.depositSwaps);
    emit Deposit(_msgSender(), vaultAuth.fap, vaultAuth.depositSwaps[0].srcToken, vaultAuth.amount, shares);
  }

  function depositUsdc(UsdcAuth calldata usdcAuth, VaultAuth calldata vaultAuth) external whenNotPaused nonReentrant {
    validateVaultAuth(vaultAuth);
    compoundCheck(vaultAuth.compoundSwaps);
    require(usdcAuth.spender == address(this), "AUTH_SPENDER");
    require(usdcAuth.owner == _msgSender(), "AUTH_OWNER");

    IEIP3009(USDC_TOKEN).approveWithAuthorization(usdcAuth.owner, usdcAuth.spender, usdcAuth.value, usdcAuth.validAfter, usdcAuth.validBefore, usdcAuth.nonce, usdcAuth.v, usdcAuth.r, usdcAuth.s);
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(USDC_TOKEN), usdcAuth.owner, address(this), usdcAuth.value);
    

    deductFee(USDC_TOKEN, usdcAuth.value, vaultAuth.fap);
    uint256 shares = joinStrategy(usdcAuth.owner, vaultAuth.depositSwaps);
    emit Deposit(_msgSender(), vaultAuth.fap, USDC_TOKEN, usdcAuth.value, shares);
  }

  function depositGiddy(ApproveWithAuthorization.ApprovalRequest calldata giddyAuth, bytes calldata giddySig, VaultAuth calldata vaultAuth) external whenNotPaused nonReentrant {
    validateVaultAuth(vaultAuth);
    compoundCheck(vaultAuth.compoundSwaps);
    require(giddyAuth.spender == address(this), "AUTH_SPENDER");
    require(giddyAuth.owner == _msgSender(), "AUTH_OWNER");

    ApproveWithAuthorization(GIDDY_TOKEN).approveWithAuthorization(giddyAuth, giddySig);
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(GIDDY_TOKEN), giddyAuth.owner, address(this), giddyAuth.value);

    deductFee(GIDDY_TOKEN, giddyAuth.value, vaultAuth.fap);
    uint256 shares = joinStrategy(giddyAuth.owner, vaultAuth.depositSwaps);
    emit Deposit(_msgSender(), vaultAuth.fap, GIDDY_TOKEN, giddyAuth.value, shares);
  }

  function joinStrategy(address user, SwapInfo[] calldata swaps) private returns (uint256 shares) {
    address[] memory depositTokens = query.getDepositTokens();
    uint256[] memory amounts = new uint256[](depositTokens.length);
    address router = config.swapRouter();

    for (uint8 i; i < depositTokens.length; i++) {
      if (swaps[i].amount > 0) {
        if (swaps[i].srcToken == depositTokens[i]) {
          SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(swaps[i].srcToken), address(strategy), swaps[i].amount);
          amounts[i] = swaps[i].amount;
        }
        else {
          amounts[i] = GiddyLibraryV2.routerSwap(router, swaps[i], address(this), address(strategy), depositTokens[i]);
        }
      }
    }

    uint256 staked = strategy.deposit(amounts);
    shares = contractShares == 0 ? staked * INIT_SHARES : staked * contractShares / (getContractBalance() - staked);
    userShares[user] += shares;
    contractShares += shares;
  }

  function withdrawAuth(VaultAuth calldata vaultAuth) external whenNotPaused nonReentrant {
    validateVaultAuth(vaultAuth);
    compoundCheck(vaultAuth.compoundSwaps);
    require(vaultAuth.amount > 0, "ZERO_SHARES");
    require(vaultAuth.amount <= userShares[_msgSender()], "SHARES_EXCEEDS_OWNED");

    address[] memory withdrawTokens = query.getWithdrawTokens();
    uint256 staked = getContractBalance() * vaultAuth.amount / contractShares;
    userShares[_msgSender()] -= vaultAuth.amount;
    contractShares -= vaultAuth.amount;
    uint256[] memory amounts = strategy.withdraw(staked);
    for (uint8 i; i < amounts.length; i++) {
      if (amounts[i] > 0) {
        if (vaultAuth.fap > 0 && i == vaultAuth.fapIndex && amounts[0] >= vaultAuth.fap) {
          amounts[i] = deductFee(withdrawTokens[i], amounts[i], vaultAuth.fap);
        }
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(withdrawTokens[i]), _msgSender(), amounts[i]);
      }
    }
    emit Withdraw(_msgSender(), vaultAuth.fap, vaultAuth.fapIndex, vaultAuth.amount, amounts);
  }

  function withdraw(uint256 shares) external whenNotPaused nonReentrant {
    require(shares > 0, "ZERO_SHARES");
    require(shares <= userShares[_msgSender()], "SHARES_EXCEEDS_OWNED");

    address[] memory withdrawTokens = query.getWithdrawTokens();
    uint256 staked = getContractBalance() * shares / contractShares;
    userShares[_msgSender()] -= shares;
    contractShares -= shares;
    uint256[] memory amounts = strategy.withdraw(staked);
    for (uint8 i; i < amounts.length; i++) {
      if (amounts[i] > 0) {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(withdrawTokens[i]), _msgSender(), amounts[i]);
      }
    }
    emit Withdraw(_msgSender(), 0, 0, shares, amounts);
  }

  function setStrategy(address strategyAddress) public onlyOwner {
    if (address(strategy) != address(0)) {
      strategy.moveStrategy(strategyAddress);
    }
    strategy = GiddyStrategyV2(strategyAddress);
  }

  function setQuery(address queryAddress) public onlyOwner {
    query = GiddyQueryV2(queryAddress);
  }

  function setConfig(address configAddress) public onlyOwner {
    config = GiddyConfigYA(configAddress);
  }

  function setRewardsEnabled(bool enabled) public onlyOwner {
    rewardsEnabled = enabled;
  }

  function getGlobalSettings() public view virtual returns(address feeAccount, uint256 earningsFee) {
    feeAccount = config.feeAccount();
    earningsFee = config.earningsFee();
  }

  function deductFee(address token, uint256 amount, uint256 fap) private returns (uint256) {
    if (fap > 0) {
      require(fap < amount, "FEE_AMOUNT");
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), config.feeAccount(), fap);
    }
    return amount - fap;
  }

  function compoundCheck(SwapInfo[] calldata swaps) private {
    if (rewardsEnabled) {
      if (strategy.compound(swaps) > 0) {
        emit CompoundV2(getContractBalance(), getContractShares());
      }
    }
  }

  function validateVaultAuth(VaultAuth calldata auth) private {
    require(block.timestamp < auth.deadline, "SWAP_AUTH_EXPRIED");
    require(!nonceMap[auth.nonce], "NONCE_USED");
    bytes memory dataArray;
    for (uint i = 0; i < auth.depositSwaps.length; i++) {
      dataArray = abi.encodePacked(dataArray, keccak256(auth.depositSwaps[i].data));
    }
    for (uint i = 0; i < auth.compoundSwaps.length; i++) {
      dataArray = abi.encodePacked(dataArray, keccak256(auth.compoundSwaps[i].data));
    }
    bytes memory data = abi.encodePacked(SWAP_AUTHORIZATION_TYPEHASH, abi.encode(
      auth.nonce,
      auth.deadline,
      auth.amount,
      auth.fap,
      auth.fapIndex,
      keccak256(dataArray)
    ));
    require(config.verifiedContracts(EIP712.recover(domainSeparator, auth.signature, data)), "VERIFY_SWAP");
    nonceMap[auth.nonce] = true;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libraries/GiddyLibraryV2.sol";

abstract contract GiddyStrategyV2 {
  function getContractBalance() public view virtual returns (uint256 amount);
  function getContractRewards() public view virtual returns (uint256[] memory amounts);
  function compound(SwapInfo[] calldata swaps) external virtual returns (uint256 staked);
  function deposit(uint256[] calldata amounts) external virtual returns (uint256 staked);
  function depositNative(uint256 amount) external virtual returns (uint256 staked);
  function withdraw(uint256 staked) external virtual returns (uint256[] memory amounts);
  function moveStrategy(address strategy) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract GiddyQueryV2 {
  function getNativeToken() external pure virtual returns (address token);
  function getRewardTokens() external pure virtual returns (address[] memory tokens);
  function getDepositTokens() external pure virtual returns (address[] memory tokens);
  function getDepositRatios() external view virtual returns (uint256[] memory ratios);
  function getWithdrawTokens() external pure virtual returns (address[] memory tokens);
  function getWithdrawAmounts(uint256 staked) external view virtual returns (uint256[] memory amounts);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

struct SwapInfo {
  address srcToken;
  uint256 amount;
  bytes data;
}

library GiddyLibraryV2 {
  function routerSwap(address router, SwapInfo calldata swap, address srcAccount, address dstAccount, address dstToken) internal returns (uint returnAmount) {
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(swap.srcToken), router, swap.amount);
    uint srcBalance = IERC20(swap.srcToken).balanceOf(address(srcAccount));
    uint dstBalance = IERC20(dstToken).balanceOf(address(dstAccount));
    (bool swapResult, ) = address(router).call(swap.data);
    if (!swapResult) {
      revert("SWAP_CALL");
    }
    require(srcBalance - IERC20(swap.srcToken).balanceOf(srcAccount) == swap.amount, "SWAP_SRC_BALANCE");
    returnAmount = IERC20(dstToken).balanceOf(dstAccount) - dstBalance;
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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