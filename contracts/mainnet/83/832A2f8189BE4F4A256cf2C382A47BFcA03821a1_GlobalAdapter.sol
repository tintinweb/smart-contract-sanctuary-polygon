//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./StakingAdapter.sol";
import "./VaultAdapter.sol";
import "./BalanceAdapter.sol";
import "./LpAdapter.sol";
import "./GovernanceAdapter.sol";

contract GlobalAdapter is BalanceAdapter, StakingAdapter, VaultAdapter, LpAdapter, GovernanceAdapter {
    constructor(address _feeManager) VaultAdapter(_feeManager) {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IStakingRewards} from "../interfaces/IStakingRewards.sol";
import {IDragonLair} from "../interfaces/IDragonLair.sol";
import {IDistributionFactory} from "../interfaces/IDistributionFactory.sol";
import {IMasterChefDistribution} from "../interfaces/IMasterChefDistribution.sol";
import {CommonAdapter, IERC20Metadata} from "./CommonAdapter.sol";

contract StakingAdapter is CommonAdapter {
    IDragonLair public constant DQUICK = IDragonLair(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

    struct Data {
        address stakingToken;
        address stakingContract;
        address rewardsToken;
        uint256 totalStaked;
        uint256 rewardsRate;
        uint256 periodFinish;
        uint256 rewardBalance;
    }

    struct ChefData {
        address stakingToken;
        address stakingContract;
        address rewardsToken;
        uint256 totalStaked;
        uint256 rewardsRate;
        uint256 periodFinish;
        uint256 rewardBalance;
    }

    /**
        @dev fetch general staking info of a certain synthetix type contract
    */
    function getStakingInfo(IDistributionFactory stakingFactory, address[] calldata poolTokens)
        external
        view
        returns (Data[] memory)
    {
        Data[] memory _datas = new Data[](poolTokens.length);

        IStakingRewards instance;
        uint256 rewardRate;
        uint256 rewardBalance;
        address rewardsToken;
        uint256 periodFinish;
        uint256 totalStaked;

        for (uint256 i = 0; i < _datas.length; i++) {
            instance = IStakingRewards(stakingFactory.stakingRewardsInfoByStakingToken(poolTokens[i]));

            // If poolToken not present in factory, skip
            if (address(instance) == address(0)) continue;

            rewardsToken = instance.rewardsToken();
            rewardBalance = IERC20Metadata(rewardsToken).balanceOf(address(instance));

            // format dQuick to Quick
            if (rewardsToken == address(DQUICK)) {
                rewardRate = DQUICK.dQUICKForQUICK(instance.rewardRate());
                rewardsToken = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13; // QUICK
                rewardBalance = DQUICK.dQUICKForQUICK(rewardBalance);
            } else rewardRate = instance.rewardRate();

            periodFinish = instance.periodFinish();
            totalStaked = instance.totalSupply();

            _datas[i] = Data(
                poolTokens[i],
                address(instance),
                rewardsToken,
                totalStaked,
                rewardRate,
                periodFinish,
                rewardBalance
            );
        }

        return _datas;
    }

    /**
        @dev fetch reward rate per block for masterchef poolIds
    */
    function getMasterChefInfo(IMasterChefDistribution chef, uint poolId)
        external
        view
        returns (uint ratePerBlock, uint totalStaked)
    {
        uint256 rewardPerBlock = chef.rewardPerBlock();
        (address depositToken, uint allocPoint, , ) = chef.poolInfo(poolId);
        uint256 totalAllocPoint = chef.totalAllocPoint();

        ratePerBlock = (rewardPerBlock * allocPoint) / totalAllocPoint;
        totalStaked = IERC20Metadata(depositToken).balanceOf(address(chef));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {CommonAdapter} from "./CommonAdapter.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import "../interfaces/IFeeManager.sol";

contract VaultAdapter is CommonAdapter {
    address public feeManager;

    struct VaultInfo {
        address depositToken;
        address rewardsToken;
        address strategy;
        address distribution;
        uint256 totalDeposits;
        uint256 performanceFee;
        uint256 withdrawalFee;
        uint256 lastDistribution;
    }

    constructor(address _feeManager) {
        feeManager = _feeManager;
    }

    function getVolatileVaultInfo(IVault vault) external view returns (VaultInfo memory info) {
        info.depositToken = address(vault.underlying());
        info.rewardsToken = address(vault.target());
        info.strategy = address(vault.strat());
        info.distribution = vault.distribution();
        info.totalDeposits = vault.calcTotalValue();
        info.lastDistribution = vault.lastDistribution();

        try vault.performanceFee() returns (uint _performanceFee) {
            info.performanceFee = _performanceFee;
        } catch {
            info.performanceFee = vault.profitFee();
        }

        try vault.withdrawalFee() returns (uint _withdrawalFee) {
            info.withdrawalFee = _withdrawalFee;
        } catch {
            info.withdrawalFee = IFeeManager(feeManager).getVaultFee(address(vault));
        }
    }

    function getCompoundVaultInfo(IERC4626 vault) external view returns (VaultInfo memory info) {
        info.depositToken = vault.asset();
        info.strategy = vault.strategy();
        info.distribution = vault.distribution();
        info.totalDeposits = vault.totalAssets();
        info.performanceFee = IStrategy(info.strategy).profitFee();

        try IStrategy(info.strategy).output() returns (address output) {
            info.rewardsToken = output;
        } catch {
            info.rewardsToken = address(0);
        }

        try IStrategy(info.strategy).lastHarvest() returns (uint lastHarvest) {
            info.lastDistribution = lastHarvest;
        } catch {
            info.lastDistribution = 0;
        }

        info.withdrawalFee = IStrategy(info.strategy).withdrawalFee();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./CommonAdapter.sol";

contract BalanceAdapter is CommonAdapter {
    function getBalances(address[] calldata tokens, address user) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == MATIC) balances[i] = user.balance;
            else balances[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return balances;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./CommonAdapter.sol";
import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/ICurvePool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract LpAdapter is CommonAdapter {
    using SafeMath for uint256;

    function getLpPrice(address lpPairToken)
        public
        view
        returns (
            uint256 lpPrice,
            uint112 reserves0,
            uint112 reserves1,
            string memory symbol0,
            string memory symbol1
        )
    {
        uint256 market0;
        uint256 market1;
        uint totalMarketUSD;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        //// Get Pair data
        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        (reserves0, reserves1, ) = pair.getReserves();
        address lpToken0 = pair.token0();
        address lpToken1 = pair.token1();
        symbol0 = IERC20Metadata(pair.token0()).symbol();
        symbol1 = IERC20Metadata(pair.token1()).symbol();

        if (priceFeeds[lpToken0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(priceFeeds[lpToken0]).latestRoundData();
            market0 = (formatDecimals(lpToken0, uint256(reserves0)) * uint256(price0)) / (10**8);
        }
        if (priceFeeds[lpToken1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(priceFeeds[lpToken1]).latestRoundData();
            market1 = (formatDecimals(lpToken1, uint256(reserves1)) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            totalMarketUSD = 2 * market0;
        } else {
            totalMarketUSD = market0 + market1;
        }

        if (totalMarketUSD == 0) revert("MARKET ZERO");

        lpPrice = (totalMarketUSD * 1 ether) / pair.totalSupply();
    }

    function getCurveLpInfo(address lpToken) public view returns (uint256 lpPrice, uint256 totalSupply) {
        if (curvePools[lpToken] != address(0)) {
            lpPrice = ICurvePool(curvePools[lpToken]).get_virtual_price();
            totalSupply = IERC20(lpToken).totalSupply();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IMultiFeeDistribution.sol";

contract GovernanceAdapter {
    struct VeEthaInfo {
        address feeRecipient;
        uint256 minLockedAmount;
        uint256 penaltyRate;
        uint256 totalEthaLocked;
        uint256 totalVeEthaSupply;
        address multiFeeAddress;
        uint256 multiFeeTotalStaked;
        uint256 userVeEthaBalance;
        uint256 userEthaLocked;
        uint256 userLockEnds;
        uint256 multiFeeUserStake;
    }

    struct Rewards {
        address tokenAddress;
        uint256 rewardRate;
        uint periodFinish;
        uint balance;
        uint claimable;
    }

    function getGovernanceInfo(address veETHA, address user)
        external
        view
        returns (VeEthaInfo memory info, Rewards[] memory rewards)
    {
        info.feeRecipient = IVotingEscrow(veETHA).penaltyCollector();
        info.minLockedAmount = IVotingEscrow(veETHA).minLockedAmount();
        info.penaltyRate = IVotingEscrow(veETHA).earlyWithdrawPenaltyRate();
        info.totalEthaLocked = IVotingEscrow(veETHA).supply();
        info.totalVeEthaSupply = IVotingEscrow(veETHA).totalSupply();
        info.userVeEthaBalance = IVotingEscrow(veETHA).balanceOf(user);
        (info.userEthaLocked, info.userLockEnds) = IVotingEscrow(veETHA).locked(user);

        info.multiFeeAddress = IVotingEscrow(veETHA).multiFeeDistribution();
        IMultiFeeDistribution multiFee = IMultiFeeDistribution(info.multiFeeAddress);
        info.multiFeeTotalStaked = multiFee.totalStaked();
        info.multiFeeUserStake = multiFee.balances(user);

        address[] memory rewardTokens = multiFee.getRewardTokens(); // only works with new multi fee

        IMultiFeeDistribution.RewardData[] memory userClaimable = multiFee.claimableRewards(user);
        rewards = new Rewards[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IMultiFeeDistribution.Reward memory rewardData = multiFee.rewardData(rewardTokens[i]);
            rewards[i].tokenAddress = rewardTokens[i];
            rewards[i].rewardRate = rewardData.rewardRate;
            rewards[i].periodFinish = rewardData.periodFinish;
            rewards[i].balance = rewardData.balance;
            rewards[i].claimable = userClaimable[i].amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
	// Views
	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function claimDate() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function stakingToken() external view returns (address);

	function rewardRate() external view returns (uint256);

	function periodFinish() external view returns (uint256);

	// Mutative

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair is IERC20 {
	function enter(uint256 _quickAmount) external;

	function leave(uint256 _dQuickAmount) external;

	function QUICKBalance(address _account)
		external
		view
		returns (uint256 quickAmount_);

	function dQUICKForQUICK(uint256 _dQuickAmount)
		external
		view
		returns (uint256 quickAmount_);

	function QUICKForDQUICK(uint256 _quickAmount)
		external
		view
		returns (uint256 dQuickAmount_);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistributionFactory {
	function stakingRewardsInfoByStakingToken(address erc20)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefDistribution {
    function setFeeAddress(address _feeAddress) external;

    function setPoolId(address _vault, uint256 _id) external;

    function updateVaultAddresses(address _vaultAddress, bool _status) external;

    function balanceOf(address _user) external returns (uint256);

    function getReward(address _user) external;

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function fund(uint256 _amount) external;

    function add(
        uint256 _allocPoint,
        IERC20 _vault,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function getBoosts(address userAddress) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function stake(address userAddress, uint256 _amount) external;

    function withdraw(address userAddress, uint256 _amount) external;

    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address depositToken,
            uint allocPoint,
            uint lastRewardBlock,
            uint accERC20PerShare
        );
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CommonAdapter is Ownable {
    // Storage
    mapping(address => address) public aTokens;
    mapping(address => address) public debtTokens;
    mapping(address => address) public crTokens;
    mapping(address => address) public priceFeeds;
    mapping(address => address) public curvePools;
    address[] public creamMarkets;
    address internal constant MATIC = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    function setPriceFeeds(address[] memory _tokens, address[] memory _feeds) external onlyOwner {
        require(_tokens.length == _feeds.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            priceFeeds[_tokens[i]] = _feeds[i];
        }
    }

    function setAaveSupplyTokens(address[] memory _tokens, address[] memory _aTokens) external onlyOwner {
        require(_tokens.length == _aTokens.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            aTokens[_tokens[i]] = _aTokens[i];
        }
    }

    function setAaveBorrowTokens(address[] memory _tokens, address[] memory _debtTokens) external onlyOwner {
        require(_tokens.length == _debtTokens.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            debtTokens[_tokens[i]] = _debtTokens[i];
        }
    }

    function setCreamSupplyTokens(address[] memory _tokens, address[] memory _crTokens) external onlyOwner {
        require(_tokens.length == _crTokens.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            crTokens[_tokens[i]] = _crTokens[i];
        }
    }

    function setCreamMarkets(address[] memory _creamMarkets) external onlyOwner {
        creamMarkets = _creamMarkets;
    }

    function setCurvePool(address[] memory lpTokens, address[] memory pools) external onlyOwner {
        require(lpTokens.length == pools.length, "!LENGTH");
        for (uint256 i = 0; i < lpTokens.length; i++) {
            curvePools[lpTokens[i]] = pools[i];
        }
    }

    function formatDecimals(address token, uint256 amount) public view returns (uint256) {
        uint256 decimals = IERC20Metadata(token).decimals();

        if (decimals == 18) return amount;
        else return (amount * 1 ether) / (10**decimals);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

interface IVault {
    function totalSupply() external view returns (uint256);

    function harvest() external returns (uint256);

    function distribute(uint256 amount) external;

    function rewards() external view returns (IERC20);

    function underlying() external view returns (IERC20Detailed);

    function target() external view returns (IERC20);

    function harvester() external view returns (address);

    function owner() external view returns (address);

    function distribution() external view returns (address);

    function strat() external view returns (address);

    function timelock() external view returns (address payable);

    function claimOnBehalf(address recipient) external;

    function lastDistribution() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalYield() external returns (uint256);

    function calcTotalValue() external view returns (uint256);

    function deposit(uint256 amount) external;

    function depositAndWait(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawPending(uint256 amount) external;

    function changePerformanceFee(uint256 fee) external;

    function claim() external returns (uint256 claimed);

    function unclaimedProfit(address user) external view returns (uint256);

    function pending(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {
    function asset() external view returns (address assetTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function assetsPerShare() external view returns (uint256 assetsPerUnitShare);

    function maxDeposit(address caller) external view returns (uint256 maxAssets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address caller) external view returns (uint256 maxShares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address caller) external view returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function maxRedeem(address caller) external view returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function claim() external;

    function distribution() external view returns (address);

    function strategy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function callFee() external view returns (uint256);

    function poolId() external view returns (uint256);

    function strategistFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function vault() external view returns (address);

    function want() external view returns (IERC20);

    function outputToNative() external view returns (address[] memory);

    function getStakingContract() external view returns (address);

    function native() external view returns (address);

    function output() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function getMaximumDepositLimit() external view returns (uint256);

    function withdraw(uint256) external;

    function balanceOfStrategy() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function lastHarvest() external view returns (uint256);

    function harvest() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
	function MAX_FEE() external view returns (uint256);

	function getVaultFee(address _vault) external view returns (uint256);

	function setVaultFee(address _vault, uint256 _fee) external;

	function getLendingFee(address _asset) external view returns (uint256);

	function setLendingFee(address _asset, uint256 _fee) external;

	function getSwapFee() external view returns (uint256);

	function setSwapFee(uint256 _swapFee) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2ERC20 {
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function getReserves()
		external
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function token0() external view returns (address);

	function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    event TokenExchangeUnderlying(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );

    // solium-disable-next-line mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external returns (uint256);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function underlying_coins(uint256) external view returns (address);

    function lp_token() external view returns (address);

    function token() external view returns (address);

    function coins(uint arg0) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// Standard Curvefi voting escrow interface
// We want to use a standard iface to allow compatibility
pragma solidity ^0.8.0;

interface IVotingEscrow {
    // Following are used in Fee distribution contracts e.g.
    /*
        https://etherscan.io/address/0x74c6cade3ef61d64dcc9b97490d9fbb231e4bdcc#code
    */
    // struct Point {
    //     int128 bias;
    //     int128 slope;
    //     uint256 ts;
    //     uint256 blk;
    // }

    // function user_point_epoch(address addr) external view returns (uint256);

    // function epoch() external view returns (uint256);

    // function user_point_history(address addr, uint256 loc) external view returns (Point);

    // function checkpoint() external;

    /*
    https://etherscan.io/address/0x2e57627ACf6c1812F99e274d0ac61B786c19E74f#readContract
    */
    // Gauge proxy requires the following. inherit from ERC20
    // balanceOf
    // totalSupply

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function emergencyWithdraw() external;

    // Extra required views
    function balanceOf(address) external view returns (uint256);

    function supply() external view returns (uint256);

    function minLockedAmount() external view returns (uint256);

    function earlyWithdrawPenaltyRate() external view returns (uint256);

    function MINDAYS() external view returns (uint256);

    function MAXDAYS() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function locked(address) external view returns (uint256, uint256);

    function delegates(address account) external view returns (address);

    function lockedToken() external view returns (address);

    function penaltyCollector() external view returns (address);

    function multiFeeDistribution() external view returns (address);

    function delegate(address delegatee) external;

    // function transferOwnership(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        // tracks already-added balances to handle accrued interest in aToken rewards
        // for the stakingToken this value is unused and will always be 0
        uint256 balance;
    }

    struct RewardData {
        address token;
        uint256 amount;
    }

    function stake(uint256 amount, address user) external;

    function withdraw(uint256 amount, address user) external;

    function getReward(address[] memory _rewardTokens, address user) external;

    function exit(address user) external;

    function getRewardTokens() external view returns (address[] memory);

    function rewardData(address) external view returns (Reward memory);

    function claimableRewards(address) external view returns (RewardData[] memory);

    function totalStaked() external view returns (uint);

    function balances(address) external view returns (uint);
}