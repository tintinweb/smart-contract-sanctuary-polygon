// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../../common/StratManagerUpgradeable.sol";
import "../../../../common/DynamicFeeManager.sol";

import "../../../../interfaces/balancer/IDysonBalancerVault.sol";
import "../../../../interfaces/dystopia/IDystopiaRouter.sol";
import "../../../../interfaces/balancer/Maximizer/IDysonMaximizerBalancerVault.sol";
import "../../../../interfaces/balancer/Maximizer/IBalancerRouterUtils.sol";
import "../../../../interfaces/common/IPenroseMasterChef.sol";
import "../../../../interfaces/common/IStakingPool.sol";
import "../../../../interfaces/common/IUserProxyFactory.sol";
import "../../../../interfaces/common/IUniswapV2Pair.sol";
import "../../../../interfaces/balancer/IRouterVault.sol";

/// @dev Maximizer Strategy where primary vault is based off the Balancer protocol
contract MaximizerBalancer is StratManagerUpgradeable, DynamicFeeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IDysonBalancerVault;
    using SafeERC20Upgradeable for IDysonMaximizerBalancerVault;

    // Info of each user.
    struct UserInfo {
        uint256 reward1Debt;
        uint256 reward2Debt;
        uint256 secondaryWantDebt;
    }

    // Accumulated rewards per share
    uint256 public accReward1PerShare;
    uint256 public accReward2PerShare;
    uint256 public accSecondaryWantPerShare;

    // rewards
    IERC20Upgradeable public reward1;
    IERC20Upgradeable public reward2;
    IERC20Upgradeable public secondaryWant;

    // token addresses
    address public native;
    address public primaryLpToken0;
    address public primaryLpToken1;
    address public secondaryLpToken0;
    address public secondaryLpToken1;

    // Dynamic Fee
    uint256 public feeOnProfits;

    uint256 public lastHarvest;
    uint256 public lastPrimaryWantBalance;
    mapping(address => UserInfo) public userInfo; // Info of each user that deposits through the vault

    IDysonBalancerVault public primaryVault;
    IDysonMaximizerBalancerVault public maximizerVault;
    IBalancerRouterUtils public routerUtils;

    // addresses
    address public dystPoolAddress;
    address public stakingPoolAddress;
    address public penroseChef;
    address public userProxyFactory;

    /**
     * @param _maximizerVault Address of the vault connected to this strategy
     * @param _primaryVault Address of the primary vault
     * @param _routerUtils Address of the contract responsible for common router functions
     * @param _secondaryWant Address of the secondary want token
     * @param _rewards Array of address, each element being the reward token address
     * @param _penroseAddresses Array of address: [_dystPoolAddress, _stakingPoolAddress, _penroseChef, _userProxyFactory]
     * @param _keeper Keeper
     * @param _strategist Strategist
     * @param _feeRecipient Fee Recipient receives a portion of fee
     */
    function __MaximizerBalancer_init(
        address _maximizerVault,
        address _primaryVault,
        address _routerUtils,
        address _secondaryWant,
        address[] memory _rewards,
        address[] memory _penroseAddresses,
        address _keeper,
        address _strategist,
        address _feeRecipient
    ) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __StratManager_init_unchained(_keeper, _strategist, address(0), _maximizerVault, _feeRecipient);
        __DynamicFeeManager_init_unchained();
        __MaximizerBalancer_init_unchained(_primaryVault, _routerUtils, _secondaryWant, _rewards, _penroseAddresses);
    }

    function __MaximizerBalancer_init_unchained(
        address _primaryVault,
        address _routerUtils,
        address _secondaryWant,
        address[] memory _rewards,
        address[] memory _penroseAddresses
    ) internal initializer {
        maximizerVault = IDysonMaximizerBalancerVault(vault);
        primaryVault = IDysonBalancerVault(_primaryVault);

        routerUtils = IBalancerRouterUtils(_routerUtils);
        feeOnProfits = 40;

        require(_rewards.length == 2, "_rewards.length != 2");
        reward1 = IERC20Upgradeable(_rewards[0]);
        reward2 = IERC20Upgradeable(_rewards[1]);

        dystPoolAddress = _penroseAddresses[0];
        stakingPoolAddress = _penroseAddresses[1];
        penroseChef = _penroseAddresses[2];
        userProxyFactory = _penroseAddresses[3];

        secondaryWant = IERC20Upgradeable(_secondaryWant);
        secondaryLpToken0 = IUniswapV2Pair(_secondaryWant).token0();
        secondaryLpToken1 = IUniswapV2Pair(_secondaryWant).token1();

        primaryLpToken0 = primaryVault.strategy().lpToken0();
        primaryLpToken1 = primaryVault.strategy().lpToken1();

        native = primaryVault.strategy().native();
        _giveAllowances();
    }

    /**
     * @dev can only be called by the vault
     * @param sender Address from which the tokens
     * @param shares Current shares of the user
     */
    function deposit(address sender, uint256 shares) public whenNotPaused {
        require(msg.sender == vault, "!vault");
        UserInfo storage user = userInfo[sender];
        _claimReward(sender);

        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            primaryVault.deposit(wantBal);
            lastPrimaryWantBalance = balanceOfPrimaryPool();
        }

        uint256 userNewShare = maximizerVault.balanceBelongTo(sender) + shares;
        // update reward debts
        user.reward1Debt = (userNewShare * accReward1PerShare) / 1e18;
        user.reward2Debt = (userNewShare * accReward2PerShare) / 1e18;
        user.secondaryWantDebt = (userNewShare * accSecondaryWantPerShare) / 1e18;
    }

    /**
     * @dev can only be called by the vault
     * @param sender Address from which the tokens
     * @param shares Current shares of the user
     */
    function withdraw(address sender, uint256 shares) external returns (uint256){
        require(msg.sender == vault, "!vault");

        UserInfo storage user = userInfo[sender];
        _claimReward(sender);

        uint256 amount = balanceOf() * shares / maximizerVault.totalSupply();
        uint256 wantBal = balanceOfWant();

        if (amount > wantBal) {
            uint256 sharesToBurn = (amount - wantBal) * primaryVault.totalSupply() / primaryVault.balance();
            primaryVault.withdraw(sharesToBurn);
            lastPrimaryWantBalance = balanceOfPrimaryPool();
            wantBal = balanceOfWant();
        }

        if (amount > wantBal) {
            amount = wantBal;
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = (amount * withdrawalFee) / WITHDRAWAL_MAX;
            amount -= withdrawalFeeAmount;
        }

        primaryVault.want().safeTransfer(vault, amount);

        uint256 userNewShare = maximizerVault.balanceBelongTo(sender) - shares;
        // update reward debts
        user.reward1Debt = (userNewShare * accReward1PerShare) / 1e18;
        user.reward2Debt = (userNewShare * accReward2PerShare) / 1e18;
        user.secondaryWantDebt = (userNewShare * accSecondaryWantPerShare) / 1e18;

        return amount;
    }

    /// @dev claims all pending rewards {reward1, reward2 and Secondary want}
    function claimReward() external {
        _claimReward(msg.sender);
    }

    function _claimReward(address sender) internal {
        updateReward();
        _updateLP(sender);
        _harvestRewardAndSecondaryLP(sender);
    }

    /**
     * @dev gets more rewards into this contract for distribution
     * @dev updates accReward1PerShare, accReward2PerShare
     */
    function updateReward() public {
        if (maximizerVault.totalSupply() == 0) return;

        uint256 reward1Before = reward1.balanceOf(address(this));
        uint256 reward2Before = reward2.balanceOf(address(this));

        // claim reward1 and reward2 reward
        IPenroseMasterChef(penroseChef).claimStakingRewards(stakingPoolAddress);

        uint256 reward1After = reward1.balanceOf(address(this));
        uint256 reward2After = reward2.balanceOf(address(this));

        accReward1PerShare += (reward1After - reward1Before) * 1e18 / maximizerVault.totalSupply();
        accReward2PerShare += (reward2After - reward2Before) * 1e18 / maximizerVault.totalSupply();
    }

    /**
     * @dev First harvests the primary strategy, converts all earned primaryWant tokens to secondaryWant tokens,
            then deposits these secondaryWant tokens to the secondary vault
     * @dev won't work more than once per hour
     * @dev updates accSecondaryWantPerShare
     */
    function updateLP() external {
        _updateLP(tx.origin);
    }

    /// @param callFeeRecipient Address that will receive a part of the charged fees
    function updateLP(address callFeeRecipient) external {
        _updateLP(callFeeRecipient);
    }

    function _updateLP(address callFeeRecipient) internal whenNotPaused {
        if (block.timestamp > lastHarvest + 1 hours) {
            if (maximizerVault.totalSupply() == 0) return;

            uint256 secondaryWantBalanceBefore = secondaryWant.balanceOf(address(this));

            primaryVault.strategy().harvest(callFeeRecipient);
            uint256 primaryWantEarnedSinceLastHarvest = balanceOfPrimaryPool() - lastPrimaryWantBalance;
            uint256 primaryWantAmountForSecondary = primaryWantEarnedSinceLastHarvest;
            uint256 sharesToBurn = (primaryWantAmountForSecondary * primaryVault.totalSupply()) / primaryVault.balance();

            uint256 primaryWantBefore = balanceOfWant();
            primaryVault.withdraw(sharesToBurn);
            primaryWantAmountForSecondary = balanceOfWant() - primaryWantBefore;
            if (primaryWantAmountForSecondary > 0) {
                lastPrimaryWantBalance = balanceOfPrimaryPool();
                _zapPrimaryWantToNative(primaryWantAmountForSecondary);
            }
            uint256 nativeBalance = IERC20Upgradeable(native).balanceOf(address(this));
            if (nativeBalance > 0) {
                _chargeFees(callFeeRecipient);
                nativeBalance = IERC20Upgradeable(native).balanceOf(address(this));
                _zapNativeToSecondaryWant(nativeBalance);
            }

            uint256 secondaryWantBalanceAfter = secondaryWant.balanceOf(address(this));
            if (secondaryWantBalanceAfter - secondaryWantBalanceBefore > 0) {
                IPenroseMasterChef(penroseChef).depositLpAndStake(
                    dystPoolAddress,
                    secondaryWantBalanceAfter - secondaryWantBalanceBefore
                );
            }
            accSecondaryWantPerShare +=
            (secondaryWantBalanceAfter - secondaryWantBalanceBefore) * 1e18 / maximizerVault.totalSupply();
            lastHarvest = block.timestamp;
        }
    }

    /**
     * @dev gives pending reward1, reward2 and secondaryWant to the user
     * @dev updates reward1Debt, reward2Debt, secondaryWantDebt
     * @param sender User's address
     */
    function _harvestRewardAndSecondaryLP(address sender) internal {
        UserInfo storage user = userInfo[sender];
        uint256 userBalance = maximizerVault.balanceBelongTo(sender);

        uint256 pendingReward;
        uint256 masterBalance;
        if (userBalance > 0) {
            // give reward1 to user
            pendingReward = userBalance * accReward1PerShare / 1e18 - user.reward1Debt;
            masterBalance = reward1.balanceOf(address(this));
            if (pendingReward > masterBalance) pendingReward = masterBalance;
            if (pendingReward > 0) {
                reward1.transfer(sender, pendingReward);
            }

            // give reward2 to user
            pendingReward = userBalance * accReward2PerShare / 1e18 - user.reward2Debt;
            masterBalance = reward2.balanceOf(address(this));
            if (pendingReward > masterBalance) pendingReward = masterBalance;
            if (pendingReward > 0) {
                reward2.transfer(sender, pendingReward);
            }

            // give secondaryWant to user
            uint256 pendingSecondaryWant = userBalance * accSecondaryWantPerShare / 1e18 - user.secondaryWantDebt;
            if (pendingSecondaryWant > 0) {
                IPenroseMasterChef(penroseChef).unstakeLpAndWithdraw(dystPoolAddress, pendingSecondaryWant);
                uint256 masterBalanceSecondaryWant = secondaryWant.balanceOf(address(this));
                if (pendingSecondaryWant > masterBalanceSecondaryWant) pendingSecondaryWant = masterBalanceSecondaryWant;
            }
            if (pendingSecondaryWant > 0) {
                secondaryWant.transfer(sender, pendingSecondaryWant);
            }

            user.reward1Debt = userBalance * accReward1PerShare / 1e18;
            user.reward2Debt = userBalance * accReward2PerShare / 1e18;
            user.secondaryWantDebt = userBalance * accSecondaryWantPerShare / 1e18;
        }
    }

    /// @dev swaps given primary-want amount to native tokens
    /// @param primaryWantAmount Amount that is to be swapped
    function _zapPrimaryWantToNative(uint256 primaryWantAmount) internal {
        require(primaryVault.want().balanceOf(address(this)) >= primaryWantAmount, "zap::doesn't have enough primaryWant balance");
        routerUtils.zapPrimaryWantToNative(primaryWantAmount);
    }

    /**
     * @dev swaps given native amount to secondary-want tokens
     * @param nativeBalance Amount that is to be swapped
     */
    function _zapNativeToSecondaryWant(uint256 nativeBalance) internal {
        require(IERC20Upgradeable(native).balanceOf(address(this)) >= nativeBalance, "zap::doesn't have enough native balance");
        uint256 nativeHalf = nativeBalance / 2;

        if (native != secondaryLpToken0) {
            IDystopiaRouter.Route[] memory routeArray = getRoute(routerUtils.getNativeToSecondaryLpToken0Route(),
                routerUtils.getIsStableNativeToSecondaryLpToken0());
            IDystopiaRouter(routerUtils.secondaryRouter()).swapExactTokensForTokens(nativeHalf, 0, routeArray,
                address(this), block.timestamp);
        }

        if (native != secondaryLpToken1) {
            IDystopiaRouter.Route[] memory routeArray = getRoute(routerUtils.getNativeToSecondaryLpToken1Route(),
                routerUtils.getIsStableNativeToSecondaryLpToken1());
            IDystopiaRouter(routerUtils.secondaryRouter()).swapExactTokensForTokens(nativeHalf, 0, routeArray,
                address(this), block.timestamp);
        }

        uint256 secondaryLpToken0Bal = IERC20Upgradeable(secondaryLpToken0).balanceOf(address(this));
        uint256 secondaryLpToken1Bal = IERC20Upgradeable(secondaryLpToken1).balanceOf(address(this));
        IDystopiaRouter(routerUtils.secondaryRouter()).addLiquidity(
            secondaryLpToken0,
            secondaryLpToken1,
            routerUtils.getIsStableSecondaryLp0LP1(),
            secondaryLpToken0Bal,
            secondaryLpToken1Bal,
            0,
            0,
            address(this),
            block.timestamp + 10 seconds
        );
    }

    function getRoute(address[] memory addressRoute, bool[] memory isStable) public pure returns (IDystopiaRouter.Route[] memory) {
        IDystopiaRouter.Route[] memory routeArray = new IDystopiaRouter.Route[](addressRoute.length - 1);
        for (uint256 i = 0; i < addressRoute.length - 1; i++) {
            routeArray[i] = IDystopiaRouter.Route({from : addressRoute[i], to : addressRoute[i + 1], stable : isStable[i]});
        }
        return routeArray;
    }

    /// @dev charges fees
    function _chargeFees(address callFeeRecipient) internal {
        uint256 nativeBalance = IERC20Upgradeable(native).balanceOf(address(this));
        uint256 generalFeeOnProfits = (nativeBalance * feeOnProfits) / 1000;
        uint256 generalFeeAmount = generalFeeOnProfits;

        uint256 callFeeAmount = (generalFeeAmount * callFee) / MAX_FEE;
        IERC20Upgradeable(native).safeTransfer(callFeeRecipient, callFeeAmount);

        // Calculating the Fee to be distributed
        uint256 feeAmount1 = (generalFeeAmount * fee1) / MAX_FEE;
        uint256 feeAmount2 = (generalFeeAmount * fee2) / MAX_FEE;
        uint256 strategistFeeAmount = (generalFeeAmount * strategistFee) / MAX_FEE;

        // Transfer fees to recipients
        if (feeAmount1 > 0) {
            IERC20Upgradeable(native).safeTransfer(feeRecipient1, feeAmount1);
        }
        if (feeAmount2 > 0) {
            IERC20Upgradeable(native).safeTransfer(feeRecipient2, feeAmount2);
        }
        if (strategistFeeAmount > 0) {
            IERC20Upgradeable(native).safeTransfer(strategist, strategistFeeAmount);
        }
    }

    /**
     * @return pending rewards for reward 1
     * @return pending rewards for reward 2
     * @return pending rewards for secondary want
     */
    function pendingRewards()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        address proxyAddress = IUserProxyFactory(userProxyFactory).userProxyByAccount(address(this));
        uint256 userBalance = maximizerVault.balanceBelongTo(msg.sender);
        uint256 accRewardPerShare;
        uint256 earnedRewards;

        // DYST rewards
        earnedRewards = IStakingPool(stakingPoolAddress).earned(proxyAddress, address(reward1));
        accRewardPerShare = accReward1PerShare + (earnedRewards * 1e18) / maximizerVault.totalSupply();
        uint256 pendingReward1 = (userBalance * accRewardPerShare) / 1e18 - userInfo[msg.sender].reward1Debt;

        // PEN rewards
        earnedRewards = IStakingPool(stakingPoolAddress).earned(proxyAddress, address(reward2));
        accRewardPerShare = accReward2PerShare + (earnedRewards * 1e18) / maximizerVault.totalSupply();
        uint256 pendingReward2 = (userBalance * accRewardPerShare) / 1e18 - userInfo[msg.sender].reward2Debt;

        uint256 pendingSecondary = (userBalance * accSecondaryWantPerShare) / 1e18 - userInfo[msg.sender].secondaryWantDebt;

        return (pendingReward1, pendingReward2, pendingSecondary);
    }

    /// @dev calculate the total underlying 'primaryWant' held by the strategy
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPrimaryPool();
    }

    /// @dev calculates how much 'primaryWant' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return primaryVault.want().balanceOf(address(this));
    }

    /// @dev strategy's share of primary want that is held by the primary vault
    function balanceOfPrimaryPool() public view returns (uint256) {
        if (primaryVault.totalSupply() != 0) {
            return (primaryVault.balance() * primaryVault.balanceOf(address(this))) / primaryVault.totalSupply();
        } else {
            return 0;
        }
    }

    /// @dev strategy's share of secondary want that is held by the secondary vault
    function balanceOfSecondaryPool() public view returns (uint256) {
        address proxyAddress = IUserProxyFactory(userProxyFactory).userProxyByAccount(address(this));
        return IERC20Upgradeable(stakingPoolAddress).balanceOf(proxyAddress);
    }

    /// @dev pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        primaryVault.withdrawAll();
        IPenroseMasterChef(penroseChef).unstakeLpAndWithdraw(dystPoolAddress);
    }

    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();

        primaryVault.deposit(primaryVault.want().balanceOf(address(this)));
        IPenroseMasterChef(penroseChef).depositLpAndStake(dystPoolAddress);
    }

    /// @dev `primaryRouter` already has the allowance to spend primary want
    function _giveAllowances() internal {
        address primaryRouter = primaryVault.strategy().router();

        primaryVault.want().safeApprove(address(primaryVault), 0);
        primaryVault.want().safeApprove(address(primaryVault), type(uint256).max);

        secondaryWant.safeApprove(penroseChef, 0);
        secondaryWant.safeApprove(penroseChef, type(uint256).max);

        //        primaryVault.want().safeApprove(primaryRouter, 0);
        //        primaryVault.want().safeApprove(primaryRouter, type(uint256).max);

        IERC20Upgradeable(primaryLpToken0).safeApprove(primaryRouter, 0);
        IERC20Upgradeable(primaryLpToken0).safeApprove(primaryRouter, type(uint256).max);

        IERC20Upgradeable(primaryLpToken1).safeApprove(primaryRouter, 0);
        IERC20Upgradeable(primaryLpToken1).safeApprove(primaryRouter, type(uint256).max);

        IERC20Upgradeable(native).safeApprove(routerUtils.secondaryRouter(), 0);
        IERC20Upgradeable(native).safeApprove(routerUtils.secondaryRouter(), type(uint256).max);

        IERC20Upgradeable(secondaryLpToken0).safeApprove(routerUtils.secondaryRouter(), 0);
        IERC20Upgradeable(secondaryLpToken0).safeApprove(routerUtils.secondaryRouter(), type(uint256).max);

        IERC20Upgradeable(secondaryLpToken1).safeApprove(routerUtils.secondaryRouter(), 0);
        IERC20Upgradeable(secondaryLpToken1).safeApprove(routerUtils.secondaryRouter(), type(uint256).max);

        primaryVault.want().safeApprove(address(routerUtils), 0);
        primaryVault.want().safeApprove(address(routerUtils), type(uint256).max);
    }

    function _removeAllowances() internal {
        address primaryRouter = primaryVault.strategy().router();

        primaryVault.want().safeApprove(address(primaryVault), 0);
        secondaryWant.safeApprove(penroseChef, 0);
        // primaryRouter already has the allowance
        // primaryVault.want().safeApprove(primaryRouter, 0);
        IERC20Upgradeable(primaryLpToken0).safeApprove(primaryRouter, 0);
        IERC20Upgradeable(primaryLpToken1).safeApprove(primaryRouter, 0);
        IERC20Upgradeable(native).safeApprove(routerUtils.secondaryRouter(), 0);
        IERC20Upgradeable(secondaryLpToken0).safeApprove(routerUtils.secondaryRouter(), 0);
        IERC20Upgradeable(secondaryLpToken1).safeApprove(routerUtils.secondaryRouter(), 0);
        primaryVault.want().safeApprove(address(routerUtils), 0);
    }

    /// @dev Setter for Dynamic fee percentage
    function setFeeOnProfits(uint256 feeOnProfits_) external onlyManager {
        require(feeOnProfits_ <= 100, "Dynamic Fees can be set to maximum of 10% (100)");
        feeOnProfits = feeOnProfits_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract DynamicFeeManager is Initializable, OwnableUpgradeable {
  uint256 public constant MAX_FEE = 1000;
  uint256 public constant MAX_CALL_FEE = 111;

  uint256 public constant WITHDRAWAL_FEE_CAP = 50;
  uint256 public constant WITHDRAWAL_MAX = 10000;

  uint256 public withdrawalFee;
  uint256 public callFee;
  uint256 public strategistFee;
  uint256 public fee1;
  uint256 public fee2;

  function __DynamicFeeManager_init() internal initializer {
    __Ownable_init_unchained();
    __DynamicFeeManager_init_unchained();
  }

  function __DynamicFeeManager_init_unchained() internal initializer {
    withdrawalFee = 0;
    callFee = 0;
    strategistFee = 0;
    fee1 = 400;
    fee2 = 600;
  }

  function setFee(
    uint256 _callFee,
    uint256 _strategistFee,
    uint256 _fee2
  ) public onlyOwner {
    require(_callFee <= MAX_CALL_FEE, "!cap");
    uint256 sum = _callFee + _strategistFee + _fee2;
    require(sum <= 1000, "Invalid Fee Combination (Please add total fee less than 1000)");

    callFee = _callFee;
    strategistFee = _strategistFee;
    fee2 = _fee2;

    fee1 = MAX_FEE - sum;
  }

  function setWithdrawalFee(uint256 _fee) public onlyOwner {
    require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

    withdrawalFee = _fee;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract StratManagerUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
  /**
   * @dev Beefy Contracts:
   * {keeper} - Address to manage a few lower risk features of the strat
   * {strategist} - Address of the strategy author/deployer where strategist fee will go.
   * {vault} - Address of the vault that controls the strategy's funds.
   * {dystRouter} - Address of exchange to execute swaps.
   */
  address public keeper;
  address public strategist;
  address public dystRouter;
  address public vault;
  address public feeRecipient1;
  address public feeRecipient2;

  /**
   * @dev Initializes the base strategy.
   * @param _keeper address to use as alternative owner.
   * @param _strategist address where strategist fees go.
   * @param _dystRouter router to use for swaps
   * @param _vault address of parent vault.
   * @param _feeRecipient address where to send Beefy's fees.
   */
  function __StratManager_init(
    address _keeper,
    address _strategist,
    address _dystRouter,
    address _vault,
    address _feeRecipient
  ) internal initializer {
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    __StratManager_init_unchained(_keeper, _strategist, _dystRouter, _vault, _feeRecipient);
  }

  function __StratManager_init_unchained(
    address _keeper,
    address _strategist,
    address _dystRouter,
    address _vault,
    address _feeRecipient
  ) internal initializer {
    keeper = _keeper;
    strategist = _strategist;
    dystRouter = _dystRouter;
    vault = _vault;
    feeRecipient1 = _feeRecipient;
    feeRecipient2 = _feeRecipient;
  }

  // checks that caller is either owner or keeper.
  modifier onlyManager() {
    require(msg.sender == owner() || msg.sender == keeper, "!manager");
    _;
  }

  /**
   * @dev Updates address of the strat keeper.
   * @param _keeper new keeper address.
   */
  function setKeeper(address _keeper) external onlyManager {
    keeper = _keeper;
  }

  /**
   * @dev Updates address where strategist fee earnings will go.
   * @param _strategist new strategist address.
   */
  function setStrategist(address _strategist) external {
    require(msg.sender == strategist, "!strategist");
    strategist = _strategist;
  }

  /**
   * @dev Updates router that will be used for swaps.
   * @param _dystRouter new dystRouter address.
   */
  function setDystRouter(address _dystRouter) external onlyOwner {
    dystRouter = _dystRouter;
  }

  /**
   * @dev Updates parent vault.
   * @param _vault new vault address.
   */
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  /**
   * @dev Updates beefy fee recipient.
   * @param _feeRecipient new beefy fee recipient address.
   */
  function setFeeRecipient1(address _feeRecipient) external onlyOwner {
    feeRecipient1 = _feeRecipient;
  }

  /**
   * @dev Updates beefy fee recipient 2.
   * @param _feeRecipient2 new beefy fee recipient address.
   */
  function setFeeRecipient2(address _feeRecipient2) external onlyOwner {
    feeRecipient2 = _feeRecipient2;
  }

  /**
   * @dev Function to synchronize balances before new user deposit.
   * Can be overridden in the strategy.
   */
  function beforeDeposit() external virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IDystopiaRouter {
  struct Route {
    address from;
    address to;
    bool stable;
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
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

  function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    Route[] calldata routes,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function getAmountOut(
    uint256 amountIn,
    address tokenIn,
    address tokenOut
  ) external view returns (uint256 amount, bool stable);

  function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);

  function getReserves(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (uint256 reserveA, uint256 reserveB);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../balancer/IStrategyBalancerAC.sol";

interface IDysonBalancerVault {
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function available (  ) external view returns ( uint256 );
  function balance (  ) external view returns ( uint256 );
  function balanceOf ( address account ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function deposit ( uint256 _amount ) external;
  function depositAll (  ) external;
  function earn (  ) external;
  function getPricePerFullShare (  ) external view returns ( uint256 );
  function inCaseTokensGetStuck ( address _token ) external;
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setStrategy ( address _strategy ) external;
  function strategy (  ) external view returns ( IStrategyBalancerAC );
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function want (  ) external view returns ( IERC20Upgradeable );
  function withdraw ( uint256 _shares ) external;
  function withdrawAll (  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPenroseMasterChef {
    function depositLpAndStake(address dystPoolAddress, uint256 amount) external;

    // deposit all
    function depositLpAndStake(address dystPoolAddress) external;

    function unstakeLpAndWithdraw(address dystPoolAddress, uint256 amount) external;

    // unstake all
    function unstakeLpAndWithdraw(address dystPoolAddress) external;

    function claimStakingRewards(address stakingPoolAddress) external;

    function createAndGetUserProxy() external view returns (address);

    //  function balanceOf(address _address) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IStakingPool {
    function earned(address account, address _rewardsToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRouterVault {
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
    function getPoolTokenInfo(bytes32 poolId, IERC20Upgradeable token)
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
            address[] memory tokens,
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
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
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
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
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
        IERC20Upgradeable[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

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

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

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
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit, // can use onSwap function?
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
        address assetIn;
        address assetOut;
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
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
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
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapV2Pair {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IUserProxyFactory {
  function createAndGetUserProxy(address) external returns (address);

  function penLensAddress() external view returns (address);

  function userProxyByAccount(address) external view returns (address);

  function userProxyByIndex(uint256) external view returns (address);

  function userProxyInterfaceAddress() external view returns (address);

  function userProxiesLength() external view returns (uint256);

  function isUserProxy(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../Maximizer/IMaximizerBalancer.sol";

interface IDysonMaximizerBalancerVault {
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function available (  ) external view returns ( uint256 );
  function balance (  ) external view returns ( uint256 );
  function balanceBelongTo ( address _address ) external view returns ( uint256 );
  function balanceOf ( address account ) external view returns ( uint256 );
  function boostPool (  ) external view returns ( address );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function deposit ( uint256 _amount ) external;
  function depositAll (  ) external;
  function earn ( uint256 _shares ) external;
  function getPricePerFullShare (  ) external view returns ( uint256 );
  function inCaseTokensGetStuck ( address _token ) external;
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setBoostPool ( address _address ) external;
  function setStrategy ( address _strategy ) external;
  function strategy (  ) external view returns ( IMaximizerBalancer );
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function want (  ) external view returns ( address );
  function withdraw ( uint256 _shares ) external;
  function withdrawAll (  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBalancerRouterUtils {
  function exitPoolBalancer ( uint256 primaryWantAmount ) external;
  function getIsStableNativeToSecondaryLpToken0 (  ) external view returns ( bool[] memory );
  function getIsStableNativeToSecondaryLpToken1 (  ) external view returns ( bool[] memory );
  function getIsStableSecondaryLp0LP1 (  ) external view returns ( bool );
  function getNativeToSecondaryLpToken0Route (  ) external view returns ( address[] memory );
  function getNativeToSecondaryLpToken1Route (  ) external view returns ( address[] memory );
  function getPrimaryLp0ToNativeRoute (  ) external view returns ( address[] memory );
  function getPrimaryLp0ToNativeRoutePids (  ) external view returns ( bytes32[] memory );
  function getPrimaryLp1ToNativeRoute (  ) external view returns ( address[] memory );
  function getPrimaryLp1ToNativeRoutePids (  ) external view returns ( bytes32[] memory );
  function isStableNativeToSecondaryLpToken0 ( uint256 ) external view returns ( bool );
  function isStableNativeToSecondaryLpToken1 ( uint256 ) external view returns ( bool );
  function isStableSecondaryLp0LP1 (  ) external view returns ( bool );
  function maximizer (  ) external view returns ( address );
  function native (  ) external view returns ( address );
  function nativeToSecondaryLpToken0Route ( uint256 ) external view returns ( address );
  function nativeToSecondaryLpToken1Route ( uint256 ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function primaryLp0ToNativeRoute ( uint256 ) external view returns ( address );
  function primaryLp0ToNativeRoutePids ( uint256 ) external view returns ( bytes32 );
  function primaryLp1ToNativeRoute ( uint256 ) external view returns ( address );
  function primaryLp1ToNativeRoutePids ( uint256 ) external view returns ( bytes32 );
  function primaryLpToken0 (  ) external view returns ( address );
  function primaryLpToken1 (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function secondaryRouter (  ) external view returns ( address );
  function setMaximizer ( address _maximizerAddress ) external;
  function swapBalancer ( uint256 amount, address[] memory route, bytes32[] memory routePids ) external;
  function transferOwnership ( address newOwner ) external;
  function zapPrimaryWantToNative ( uint256 primaryWantAmount ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStrategyBalancerAC {
  function MAX_CALL_FEE (  ) external view returns ( uint256 );
  function MAX_FEE (  ) external view returns ( uint256 );
  function WITHDRAWAL_FEE_CAP (  ) external view returns ( uint256 );
  function WITHDRAWAL_MAX (  ) external view returns ( uint256 );
  function addLiquidity (  ) external;
  function balanceOf (  ) external view returns ( uint256 );
  function balanceOfPool (  ) external view returns ( uint256 );
  function balanceOfWant (  ) external view returns ( uint256 );
  function beforeDeposit (  ) external;
  function callFee (  ) external view returns ( uint256 );
  function deposit (  ) external;
  function fee1 (  ) external view returns ( uint256 );
  function fee2 (  ) external view returns ( uint256 );
  function feeOnProfits (  ) external view returns ( uint256 );
  function feeRecipient1 (  ) external view returns ( address );
  function feeRecipient2 (  ) external view returns ( address );
  function harvest ( address callFeeRecipient ) external;
  function harvest (  ) external;
  function harvestOnDeposit (  ) external view returns ( bool );
  function keeper (  ) external view returns ( address );
  function lastHarvest (  ) external view returns ( uint256 );
  function lpToken0 (  ) external view returns ( address );
  function lpToken1 (  ) external view returns ( address );
  function managerHarvest (  ) external;
  function native (  ) external view returns ( address );
  function nativeTokenBalance (  ) external view returns ( uint256 );
  function output (  ) external view returns ( address );
  function outputBalance (  ) external view returns ( uint256 );
  function outputToLp0Route ( uint256 ) external view returns ( address );
  function outputToLp0RoutePids ( uint256 ) external view returns ( bytes32 );
  function outputToLp1Route ( uint256 ) external view returns ( address );
  function outputToLp1RoutePids ( uint256 ) external view returns ( bytes32 );
  function outputToNativeRoute ( uint256 ) external view returns ( address );
  function outputToNativeRoutePids ( uint256 ) external view returns ( bytes32 );
  function owner (  ) external view returns ( address );
  function panic (  ) external;
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function poolId (  ) external view returns ( bytes32 );
  function recoverAllFunds ( address _tokenAddress ) external;
  function recoverFunds ( address _tokenAddress, uint256 amount ) external;
  function renounceOwnership (  ) external;
  function rewardPool (  ) external view returns ( address );
  function router (  ) external view returns ( address );
  function setFee ( uint256 _callFee, uint256 _strategistFee, uint256 _fee2 ) external;
  function setFeeOnProfits ( uint256 _feeOnProfits ) external;
  function setFeeRecipient1 ( address _feeRecipient ) external;
  function setFeeRecipient2 ( address _feeRecipient2 ) external;
  function setHarvestOnDeposit ( bool _harvestOnDeposit ) external;
  function setKeeper ( address _keeper ) external;
  function setRouter ( address _router ) external;
  function setStrategist ( address _strategist ) external;
  function setVault ( address _vault ) external;
  function setWithdrawalFee ( uint256 _fee ) external;
  function strategist (  ) external view returns ( address );
  function strategistFee (  ) external view returns ( uint256 );
  function testHarvest1 (  ) external;
  function testHarvest2 (  ) external;
  function test_claim_rewards (  ) external;
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function vault (  ) external view returns ( address );
  function want (  ) external view returns ( address );
  function withdraw ( uint256 _amount ) external;
  function withdrawalFee (  ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.9;

import "../IDysonBalancerVault.sol";
import "../Maximizer/IDysonMaximizerBalancerVault.sol";
import "../Maximizer/IBalancerRouterUtils.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMaximizerBalancer {
  function MAX_CALL_FEE (  ) external view returns ( uint256 );
  function MAX_FEE (  ) external view returns ( uint256 );
  function WITHDRAWAL_FEE_CAP (  ) external view returns ( uint256 );
  function WITHDRAWAL_MAX (  ) external view returns ( uint256 );
  function _zapNativeToSecondaryWant ( uint256 nativeBalance ) external;
  function _zapPrimaryWantToNative ( uint256 primaryWantAmount ) external;
  function accReward1PerShare (  ) external view returns ( uint256 );
  function accReward2PerShare (  ) external view returns ( uint256 );
  function accSecondaryWantPerShare (  ) external view returns ( uint256 );
  function balanceOf (  ) external view returns ( uint256 );
  function balanceOfPrimaryPool (  ) external view returns ( uint256 );
  function balanceOfSecondaryPool (  ) external view returns ( uint256 );
  function balanceOfWant (  ) external view returns ( uint256 );
  function beforeDeposit (  ) external;
  function callFee (  ) external view returns ( uint256 );
  function claimReward (  ) external;
  function deposit ( address _sender, uint256 _shares ) external;
  function dystPoolAddress (  ) external view returns ( address );
  function dystRouter (  ) external view returns ( address );
  function fee1 (  ) external view returns ( uint256 );
  function fee2 (  ) external view returns ( uint256 );
  function feeOnProfits (  ) external view returns ( uint256 );
  function feeRecipient1 (  ) external view returns ( address );
  function feeRecipient2 (  ) external view returns ( address );
  function keeper (  ) external view returns ( address );
  function lastHarvest (  ) external view returns ( uint256 );
  function lastPrimaryWantBalance (  ) external view returns ( uint256 );
  function routerUtils (  ) external view returns ( IBalancerRouterUtils );
  function native (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function panic (  ) external;
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function pendingRewards (  ) external view returns ( uint256, uint256, uint256 );
  function penroseChef (  ) external view returns ( address );
  function primaryLpToken0 (  ) external view returns ( address );
  function primaryLpToken1 (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function secondaryLpToken0 (  ) external view returns ( address );
  function secondaryLpToken1 (  ) external view returns ( address );
  function setDystRouter ( address _dystRouter ) external;
  function setFee ( uint256 _callFee, uint256 _strategistFee, uint256 _fee2 ) external;
  function setFeeOnProfits ( uint256 _feeOnProfits ) external;
  function setFeeRecipient1 ( address _feeRecipient ) external;
  function setFeeRecipient2 ( address _feeRecipient2 ) external;
  function setKeeper ( address _keeper ) external;
  function setStrategist ( address _strategist ) external;
  function setVault ( address _vault ) external;
  function setWithdrawalFee ( uint256 _fee ) external;
  function stakingPoolAddress (  ) external view returns ( address );
  function strategist (  ) external view returns ( address );
  function strategistFee (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function updateLP (  ) external;
  function updateLP ( address callFeeRecipient ) external;
  function updateReward (  ) external;
  function userInfo ( address ) external view returns ( uint256 reward1Debt, uint256 reward2Debt, uint256 secondaryWantDebt );
  function userProxyFactory (  ) external view returns ( address );
  function vault (  ) external view returns ( address );
  function withdraw ( address _sender, uint256 _shares ) external returns ( uint256 );
  function withdrawalFee (  ) external view returns ( uint256 );
  function maximizerVault (  ) external view returns ( IDysonMaximizerBalancerVault );
  function primaryVault (  ) external view returns ( IDysonBalancerVault );
  function reward1 (  ) external view returns ( IERC20Upgradeable );
  function reward2 (  ) external view returns ( IERC20Upgradeable );
  function secondaryWant (  ) external view returns ( IERC20Upgradeable );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}