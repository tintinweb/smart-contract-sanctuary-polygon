// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// OpenZeppelin imports
import {AccessControl} from "@openzeppelin/contracts_latest/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts_latest/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts_latest/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts_latest/token/ERC20/IERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts_latest/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts_latest/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts_latest/token/ERC20/utils/SafeERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// QiDao
import {IFarm} from "./qidao/IFarm.sol";

// UniSwap
import {IERC20Uniswap} from "./uniswap/interfaces/IERC20Uniswap.sol";
import {IUniswapV2Pair} from "./uniswap/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "./uniswap/interfaces/IUniswapV2Router02.sol";

// Interface & support
import "./PeronioSupport.sol";

string constant NAME = "Peronio";
string constant SYMBOL = "P";

contract Peronio is IPeronio, ERC20, ERC20Burnable, ERC20Permit, ERC165, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Roles
    RoleId public constant override MARKUP_ROLE = RoleId.wrap(keccak256("MARKUP_ROLE"));
    RoleId public constant override REWARDS_ROLE = RoleId.wrap(keccak256("REWARDS_ROLE"));
    RoleId public constant override MIGRATOR_ROLE = RoleId.wrap(keccak256("MIGRATOR_ROLE"));

    // USDC Token Address
    address public immutable override usdcAddress;
    // MAI Token Address
    address public immutable override maiAddress;
    // LP USDC/MAI Address from QuickSwap
    address public immutable override lpAddress;
    // QI Token Address
    address public immutable override qiAddress;

    // QuickSwap Router Address
    address public immutable override quickSwapRouterAddress;

    // QiDao Farm Address
    address public immutable override qiDaoFarmAddress;
    // QiDao Pool ID
    uint256 public immutable override qiDaoPoolId;

    // Constant number of significant decimals
    uint8 private constant DECIMALS = 6;

    // One-hour constant
    uint256 private constant ONE_HOUR = 60 * 60; /* 60 minutes * 60 seconds */

    // Rational constant one
    RatioWith6Decimals private constant ONE = RatioWith6Decimals.wrap(10**DECIMALS);

    // Fees
    RatioWith6Decimals public override markupFee = RatioWith6Decimals.wrap(50000); // 5.00%
    RatioWith6Decimals public override swapFee = RatioWith6Decimals.wrap(1500); // 0.15%

    // Initialization can only be run once
    bool public override initialized;

    /**
     * Allow execution by the default admin only
     *
     */
    modifier onlyAdminRole() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /**
     * Allow execution by the markup-setter only
     *
     */
    modifier onlyMarkupRole() {
        _checkRole(RoleId.unwrap(MARKUP_ROLE));
        _;
    }

    /**
     * Allow execution by the rewards-reaper only
     *
     */
    modifier onlyRewardsRole() {
        _checkRole(RoleId.unwrap(REWARDS_ROLE));
        _;
    }

    /**
     * Allow execution by the migrator only
     *
     */
    modifier onlyMigratorRole() {
        _checkRole(RoleId.unwrap(MIGRATOR_ROLE));
        _;
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --- Public Interface -----------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Construct a new Peronio contract
     *
     * @param _usdcAddress  Address used for the USDC tokens in vault
     * @param _maiAddress  Address used for the MAI tokens in vault
     * @param _lpAddress  LP Address for MAI/USDC
     * @param _qiAddress  Address used for the QI tokens in vault
     * @param _quickSwapRouterAddress  Address of the QuickSwap Router to talk to
     * @param _qiDaoFarmAddress  Address of the QiDao Farm to use
     * @param _qiDaoPoolId  Pool ID within the QiDao Farm
     */
    constructor(
        address _usdcAddress,
        address _maiAddress,
        address _lpAddress,
        address _qiAddress,
        address _quickSwapRouterAddress,
        address _qiDaoFarmAddress,
        uint256 _qiDaoPoolId
    ) ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        // --- Gas Saving -------------------------------------------------------------------------
        address sender = _msgSender();

        // Stablecoin Addresses
        usdcAddress = _usdcAddress;
        maiAddress = _maiAddress;

        // LP USDC/MAI Address
        lpAddress = _lpAddress;

        // Router Address
        quickSwapRouterAddress = _quickSwapRouterAddress;

        // QiDao Data
        qiDaoFarmAddress = _qiDaoFarmAddress;
        qiDaoPoolId = _qiDaoPoolId;
        qiAddress = _qiAddress;

        // Grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(RoleId.unwrap(MARKUP_ROLE), sender);
        _setupRole(RoleId.unwrap(REWARDS_ROLE), sender);
        _setupRole(RoleId.unwrap(MIGRATOR_ROLE), sender);
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC165) returns (bool) {
        return interfaceId == type(IPeronio).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Decimals -------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the number of decimals the PE token will work with
     *
     * @return decimals_  This will always be 6
     */
    function decimals() public view virtual override(ERC20, IPeronio) returns (uint8 decimals_) {
        decimals_ = DECIMALS;
    }

    // --- Markup fee change ----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Set the markup fee to the given value (take into account that this will use `DECIMALS` decimals implicitly)
     *
     * @param newMarkupFee  New markup fee value
     * @return prevMarkupFee  Previous markup fee value
     * @custom:emit  MarkupFeeUpdated
     */
    function setMarkupFee(RatioWith6Decimals newMarkupFee) external override onlyMarkupRole returns (RatioWith6Decimals prevMarkupFee) {
        (prevMarkupFee, markupFee) = (markupFee, newMarkupFee);

        emit MarkupFeeUpdated(_msgSender(), newMarkupFee);
    }

    // --- Initialization -------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Initialize the PE token by providing collateral USDC tokens - initial conversion rate will be set at the given starting ratio
     *
     * @param usdcAmount  Number of collateral USDC tokens
     * @param startingRatio  Initial minting ratio in PE tokens per USDC tokens minted (including DECIMALS)
     * @custom:emit  Initialized
     */
    function initialize(UsdcQuantity usdcAmount, PePerUsdcQuantity startingRatio) external override onlyAdminRole {
        // Prevent double initialization
        require(!initialized, "Contract already initialized");
        initialized = true;

        // --- Gas Saving -------------------------------------------------------------------------
        IERC20 maiERC20 = IERC20(maiAddress);
        IERC20 usdcERC20 = IERC20(usdcAddress);
        IERC20 lpERC20 = IERC20(lpAddress);
        IERC20 qiERC20 = IERC20(qiAddress);
        address sender = _msgSender();
        address _quickSwapRouterAddress = quickSwapRouterAddress;
        uint256 maxVal = type(uint256).max;

        // Transfer initial USDC amount from user to current contract
        usdcERC20.safeTransferFrom(sender, address(this), UsdcQuantity.unwrap(usdcAmount));

        // Unlimited ERC20 approval for Router
        maiERC20.approve(_quickSwapRouterAddress, maxVal);
        usdcERC20.approve(_quickSwapRouterAddress, maxVal);
        lpERC20.approve(_quickSwapRouterAddress, maxVal);
        qiERC20.approve(_quickSwapRouterAddress, maxVal);

        // Commit the complete initial USDC amount
        _zapIn(usdcAmount);
        usdcAmount = _stakedValue();

        // Mints exactly startingRatio for each collateral USDC token
        _mint(sender, PeQuantity.unwrap(mulDiv(usdcAmount, startingRatio, ONE)));

        emit Initialized(sender, usdcAmount, startingRatio);
    }

    // --- State views ----------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the USDC and MAI token reserves present in QuickSwap
     *
     * @return usdcReserves  Number of USDC tokens in reserve
     * @return maiReserves  Number of MAI tokens in reserve
     */
    function getLpReserves() external view override returns (UsdcQuantity usdcReserves, MaiQuantity maiReserves) {
        (usdcReserves, maiReserves) = _getLpReserves();
    }

    /**
     * Return the number of LP USDC/MAI tokens on stake at QiDao's Farm
     *
     * @return lpAmount  Number of LP USDC/MAI token on stake
     */
    function stakedBalance() external view override returns (LpQuantity lpAmount) {
        lpAmount = _stakedBalance();
    }

    /**
     * Return the number of USDC and MAI tokens on stake at QiDao's Farm
     *
     * @return usdcAmount  Number of USDC tokens on stake
     * @return maiAmount  Number of MAI tokens on stake
     */
    function stakedTokens() external view override returns (UsdcQuantity usdcAmount, MaiQuantity maiAmount) {
        (usdcAmount, maiAmount) = _stakedTokens();
    }

    /**
     * Return the equivalent number of USDC tokens on stake at QiDao's Farm
     *
     * @return usdcAmount  Total equivalent number of USDC token on stake
     */
    function stakedValue() external view override returns (UsdcQuantity usdcAmount) {
        usdcAmount = _stakedValue();
    }

    /**
     * Return the _collateralized_ price in USDC tokens per PE token
     *
     * @return price  Collateralized price in USDC tokens per PE token
     */
    function usdcPrice() external view override returns (PePerUsdcQuantity price) {
        price = mulDiv(ONE, _totalSupply(), _stakedValue());
    }

    /**
     * Return the effective _minting_ price in USDC tokens per PE token
     *
     * @return price  Minting price in USDC tokens per PE token
     */
    function buyingPrice() external view override returns (UsdcPerPeQuantity price) {
        price = mulDiv(_collateralRatio(), add(ONE, markupFee), ONE);
    }

    /**
     * Return the ratio of total number of USDC tokens per PE token
     *
     * @return ratio  Ratio of USDC tokens per PE token, with `_decimal` decimals
     */
    function collateralRatio() external view override returns (UsdcPerPeQuantity ratio) {
        ratio = _collateralRatio();
    }

    // --- State changers -------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Mint PE tokens using the provided USDC tokens as collateral
     *
     * @param to  The address to transfer the minted PE tokens to
     * @param usdcAmount  Number of USDC tokens to use as collateral
     * @param minReceive  The minimum number of PE tokens to mint
     * @return peAmount  The number of PE tokens actually minted
     * @custom:emit  Minted
     */
    function mint(
        address to,
        UsdcQuantity usdcAmount,
        PeQuantity minReceive
    ) external override nonReentrant returns (PeQuantity peAmount) {
        peAmount = _mintPe(to, usdcAmount, minReceive, markupFee);
    }

    /**
     * Mint PE tokens using the provided USDC tokens as collateral --- used by the migrators in order not to incur normal fees
     *
     * @param to  The address to transfer the minted PE tokens to
     * @param usdcAmount  Number of USDC tokens to use as collateral
     * @param minReceive  The minimum number of PE tokens to mint
     * @return peAmount  The number of PE tokens actually minted
     * @custom:emit  Minted
     */
    function mintForMigration(
        address to,
        UsdcQuantity usdcAmount,
        PeQuantity minReceive
    ) external override nonReentrant onlyMigratorRole returns (PeQuantity peAmount) {
        peAmount = _mintPe(to, usdcAmount, minReceive, RatioWith6Decimals.wrap(0));
    }

    /**
     * Extract the given number of PE tokens as USDC tokens
     *
     * @param to  Address to deposit extracted USDC tokens into
     * @param peAmount  Number of PE tokens to withdraw
     * @return usdcTotal  Number of USDC tokens extracted
     * @custom:emit  Withdrawal
     */
    function withdraw(address to, PeQuantity peAmount) external override nonReentrant returns (UsdcQuantity usdcTotal) {
        // --- Gas Saving -------------------------------------------------------------------------
        address sender = _msgSender();

        // Calculate equivalent number of LP USDC/MAI tokens for the given burnt PE tokens
        LpQuantity lpAmount = mulDiv(peAmount, _stakedBalance(), _totalSupply());

        // Extract the given number of LP USDC/MAI tokens as USDC tokens
        usdcTotal = _zapOut(lpAmount);

        // Transfer USDC tokens the the given address
        IERC20(usdcAddress).safeTransfer(to, UsdcQuantity.unwrap(usdcTotal));

        // Burn the given number of PE tokens
        _burn(sender, PeQuantity.unwrap(peAmount));

        emit Withdrawal(sender, usdcTotal, peAmount);
    }

    /**
     * Extract the given number of PE tokens as LP USDC/MAI tokens
     *
     * @param to  Address to deposit extracted LP USDC/MAI tokens into
     * @param peAmount  Number of PE tokens to withdraw liquidity for
     * @return lpAmount  Number of LP USDC/MAI tokens extracted
     * @custom:emit LiquidityWithdrawal
     */
    function withdrawLiquidity(address to, PeQuantity peAmount) external override nonReentrant returns (LpQuantity lpAmount) {
        // --- Gas Saving -------------------------------------------------------------------------
        address sender = _msgSender();

        // Calculate equivalent number of LP USDC/MAI tokens for the given burnt PE tokens
        lpAmount = mulDiv(peAmount, _stakedBalance(), _totalSupply());

        // Get LP USDC/MAI tokens out of QiDao's Farm
        _unstakeLP(lpAmount);

        // Transfer LP USDC/MAI tokens to the given address
        IERC20(lpAddress).safeTransfer(to, LpQuantity.unwrap(lpAmount));

        // Burn the given number of PE tokens
        _burn(sender, PeQuantity.unwrap(peAmount));

        emit LiquidityWithdrawal(sender, lpAmount, peAmount);
    }

    // --- Rewards --------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the rewards accrued by staking LP USDC/MAI tokens in QiDao's Farm (in QI tokens)
     *
     * @return qiAmount  Number of QI tokens accrued
     */
    function getPendingRewardsAmount() external view override returns (QiQuantity qiAmount) {
        qiAmount = _getPendingRewardsAmount();
    }

    /**
     * Claim QiDao's QI token rewards, and re-invest them in the QuickSwap liquidity pool and QiDao's Farm
     *
     * @return usdcAmount  The number of USDC tokens being re-invested
     * @return lpAmount  The number of LP USDC/MAI tokens being put on stake
     * @custom:emit CompoundRewards
     */
    function compoundRewards() external override onlyRewardsRole returns (UsdcQuantity usdcAmount, LpQuantity lpAmount) {
        // Claim rewards from QiDao's Farm
        IFarm(qiDaoFarmAddress).deposit(qiDaoPoolId, 0);

        // Retrieve the number of QI tokens rewarded and swap them to USDC tokens
        QiQuantity amount = QiQuantity.wrap(IERC20(qiAddress).balanceOf(address(this)));
        _swapTokens(amount);

        // Commit all USDC tokens so converted to the QuickSwap liquidity pool
        usdcAmount = UsdcQuantity.wrap(IERC20(usdcAddress).balanceOf(address(this)));
        lpAmount = _zapIn(usdcAmount);

        emit CompoundRewards(amount, usdcAmount, lpAmount);
    }

    // --- Quotes ---------------------------------------------------------------------------------------------------------------------------------------------
    //
    // Quotes are created by inlining the calls to mint (for quoteIn) and withdraw (for quoteOut), and discarding state-changing statements
    //

    /**
     * Retrieve the expected number of PE tokens corresponding to the given number of USDC tokens for minting.
     *
     * @dev This method was obtained by _inlining_ the call to mint() across contracts, and cleaning up the result.
     *
     * @param usdc  Number of USDC tokens to quote for
     * @return pe  Number of PE tokens quoted for the given number of USDC tokens
     */
    function quoteIn(UsdcQuantity usdc) external view override returns (PeQuantity pe) {
        // --- Gas Saving -------------------------------------------------------------------------
        address _lpAddress = lpAddress;

        // retrieve LP state (simulations will modify these)
        (UsdcQuantity usdcReserves, MaiQuantity maiReserves) = _getLpReserves();
        LpQuantity lpTotalSupply = LpQuantity.wrap(IERC20(_lpAddress).totalSupply());

        // -- SPLIT -------------------------------------------------------------------------------
        UsdcQuantity usdcAmount = _calculateSwapInAmount(usdcReserves, usdc);
        MaiQuantity maiAmount = _getAmountOut(usdcAmount, usdcReserves, maiReserves);

        // simulate LP state update
        usdcReserves = add(usdcReserves, usdcAmount);
        maiReserves = sub(maiReserves, maiAmount);

        // -- SWAP --------------------------------------------------------------------------------

        // calculate actual values swapped
        {
            MaiQuantity amountMaiOptimal = mulDiv(sub(usdc, usdcAmount), maiReserves, usdcReserves);
            if (lte(amountMaiOptimal, maiAmount)) {
                (usdcAmount, maiAmount) = (sub(usdc, usdcAmount), amountMaiOptimal);
            } else {
                UsdcQuantity amountUsdcOptimal = mulDiv(maiAmount, usdcReserves, maiReserves);
                (usdcAmount, maiAmount) = (amountUsdcOptimal, maiAmount);
            }
        }

        // deal with LP minting when changing its K
        {
            UniSwapRootKQuantity rootK = sqrt(mul(usdcReserves, maiReserves));
            UniSwapRootKQuantity rootKLast = sqrt(UniSwapKQuantity.wrap(IUniswapV2Pair(_lpAddress).kLast()));
            if (lt(rootKLast, rootK)) {
                lpTotalSupply = add(lpTotalSupply, mulDiv(lpTotalSupply, sub(rootK, rootKLast), add(mul(rootK, 5), rootKLast)));
            }
        }

        // calculate LP values actually provided
        LpQuantity zapInLps;
        {
            LpQuantity maiCandidate = mulDiv(maiAmount, lpTotalSupply, maiReserves);
            LpQuantity usdcCandidate = mulDiv(usdcAmount, lpTotalSupply, usdcReserves);
            zapInLps = min(maiCandidate, usdcCandidate);
        }

        // -- PERONIO -----------------------------------------------------------------------------
        LpQuantity lpAmount = mulDiv(zapInLps, sub(ONE, _totalMintFee(markupFee)), ONE);
        pe = mulDiv(lpAmount, _totalSupply(), _stakedBalance());
    }

    /**
     * Retrieve the expected number of USDC tokens corresponding to the given number of PE tokens for withdrawal.
     *
     * @dev This method was obtained by _inlining_ the call to withdraw() across contracts, and cleaning up the result.
     *
     * @param pe  Number of PE tokens to quote for
     * @return usdc  Number of USDC tokens quoted for the given number of PE tokens
     */
    function quoteOut(PeQuantity pe) external view override returns (UsdcQuantity usdc) {
        // --- Gas Saving -------------------------------------------------------------------------
        address _lpAddress = lpAddress;

        (UsdcQuantity usdcReserves, MaiQuantity maiReserves) = _getLpReserves();
        LpQuantity lpTotalSupply = LpQuantity.wrap(IERC20(_lpAddress).totalSupply());

        // deal with LP minting when changing its K
        {
            UniSwapRootKQuantity rootK = sqrt(mul(usdcReserves, maiReserves));
            UniSwapRootKQuantity rootKLast = sqrt(UniSwapKQuantity.wrap(IUniswapV2Pair(_lpAddress).kLast()));
            if (lt(rootKLast, rootK)) {
                lpTotalSupply = add(lpTotalSupply, mulDiv(lpTotalSupply, sub(rootK, rootKLast), add(mul(rootK, 5), rootKLast)));
            }
        }

        // calculate LP values actually withdrawn
        LpQuantity lpAmount = add(LpQuantity.wrap(IERC20Uniswap(_lpAddress).balanceOf(_lpAddress)), mulDiv(pe, _stakedBalance(), _totalSupply()));

        UsdcQuantity usdcAmount = mulDiv(usdcReserves, lpAmount, lpTotalSupply);
        MaiQuantity maiAmount = mulDiv(maiReserves, lpAmount, lpTotalSupply);

        usdc = add(usdcAmount, _getAmountOut(maiAmount, sub(maiReserves, maiAmount), sub(usdcReserves, usdcAmount)));
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --- Private Interface ----------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the number of PE tokens in existence
     *
     * @return peAmount  Number of PE tokens in existence
     */
    function _totalSupply() internal view returns (PeQuantity peAmount) {
        peAmount = PeQuantity.wrap(totalSupply());
    }

    /**
     * Return the USDC and MAI token reserves present in QuickSwap
     *
     * @return usdcReserves  Number of USDC tokens in reserve
     * @return maiReserves  Number of MAI tokens in reserve
     */
    function _getLpReserves() internal view returns (UsdcQuantity usdcReserves, MaiQuantity maiReserves) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(lpAddress).getReserves();
        (usdcReserves, maiReserves) = usdcAddress < maiAddress
            ? (UsdcQuantity.wrap(reserve0), MaiQuantity.wrap(reserve1))
            : (UsdcQuantity.wrap(reserve1), MaiQuantity.wrap(reserve0));
    }

    /**
     * Return the number of LP USDC/MAI tokens on stake at QiDao's Farm
     *
     * @return lpAmount  Number of LP USDC/MAI token on stake
     */
    function _stakedBalance() internal view returns (LpQuantity lpAmount) {
        lpAmount = LpQuantity.wrap(IFarm(qiDaoFarmAddress).deposited(qiDaoPoolId, address(this)));
    }

    /**
     * Return the number of USDC and MAI tokens on stake at QiDao's Farm
     *
     * @return usdcAmount  Number of USDC tokens on stake
     * @return maiAmount  Number of MAI tokens on stake
     */
    function _stakedTokens() internal view returns (UsdcQuantity usdcAmount, MaiQuantity maiAmount) {
        LpQuantity lpAmount = _stakedBalance();
        LpQuantity lpTotalSupply = LpQuantity.wrap(IERC20(lpAddress).totalSupply());

        (UsdcQuantity usdcReserves, MaiQuantity maiReserves) = _getLpReserves();

        usdcAmount = mulDiv(lpAmount, usdcReserves, lpTotalSupply);
        maiAmount = mulDiv(lpAmount, maiReserves, lpTotalSupply);
    }

    /**
     * Return the equivalent number of USDC tokens on stake at QiDao's Farm
     *
     * This method will return the equivalent number of USDC tokens for the number of USDC and MAI tokens on stake.
     *
     * @return totalUSDC  Total equivalent number of USDC token on stake
     */
    function _stakedValue() internal view returns (UsdcQuantity totalUSDC) {
        (UsdcQuantity usdcReserves, MaiQuantity maiReserves) = _getLpReserves();
        (UsdcQuantity usdcAmount, MaiQuantity maiAmount) = _stakedTokens();

        // Simulate Swap
        totalUSDC = add(usdcAmount, _getAmountOut(maiAmount, maiReserves, usdcReserves));
    }

    /**
     * Return the ratio of total number of USDC tokens per PE token
     *
     * @return ratio  Ratio of USDC tokens per PE token, with `_decimal` decimals
     */
    function _collateralRatio() internal view returns (UsdcPerPeQuantity ratio) {
        ratio = mulDiv(ONE, _stakedValue(), _totalSupply());
    }

    /**
     * Return the total minting fee to apply
     *
     * @return totalFee  The total fee to apply on minting
     */
    function _totalMintFee(RatioWith6Decimals _markupFee) internal view returns (RatioWith6Decimals totalFee) {
        // Retrieve the deposit fee from QiDao's Farm (this is always expressed with 4 decimals, as "basic points")
        // Convert these "basic points" to `DECIMALS` precision
        (, , , , uint16 depositFeeBP) = IFarm(qiDaoFarmAddress).poolInfo(qiDaoPoolId);
        RatioWith6Decimals depositFee = ratio4to6(RatioWith4Decimals.wrap(depositFeeBP));

        // Calculate total fee to apply
        // (ie. the swapFee and the depositFee are included in the total markup fee, thus, we don't double charge for both the markup fee itself
        // and the swap and deposit fees)
        totalFee = max(_markupFee, add(swapFee, depositFee));
    }

    /**
     * Actually mint PE tokens using the provided USDC tokens as collateral, applying the given markup fee
     *
     * @param to  The address to transfer the minted PE tokens to
     * @param usdcAmount  Number of USDC tokens to use as collateral
     * @param minReceive  The minimum number of PE tokens to mint
     * @param _markupFee  The markup fee to apply
     * @return peAmount  The number of PE tokens actually minted
     * @custom:emit  Minted
     */
    function _mintPe(
        address to,
        UsdcQuantity usdcAmount,
        PeQuantity minReceive,
        RatioWith6Decimals _markupFee
    ) internal returns (PeQuantity peAmount) {
        // --- Gas Saving -------------------------------------------------------------------------
        address sender = _msgSender();

        // Transfer USDC tokens as collateral to this contract
        IERC20(usdcAddress).safeTransferFrom(sender, address(this), UsdcQuantity.unwrap(usdcAmount));

        // Remember the previously staked balance
        LpQuantity stakedAmount = _stakedBalance();

        // Commit USDC tokens, and discount fees totalling the markup fee
        LpQuantity lpAmount = mulDiv(_zapIn(usdcAmount), sub(ONE, _totalMintFee(_markupFee)), ONE);

        // Calculate the number of PE tokens as the proportion of liquidity provided
        peAmount = mulDiv(lpAmount, _totalSupply(), stakedAmount);

        require(lte(minReceive, peAmount), "Minimum required not met");

        // Actually mint the PE tokens
        _mint(to, PeQuantity.unwrap(peAmount));

        emit Minted(sender, usdcAmount, peAmount);
    }

    /**
     * Commit the given number of USDC tokens
     *
     * This method will:
     *   1. split the given USDC amount into USDC/MAI amounts so as to provide balanced liquidity,
     *   2. add the given amounts of USDC and MAI tokens to the liquidity pool, and obtain LP USDC/MAI tokens in return, and
     *   3. stake the given LP USDC/MAI tokens in QiDao's Farm so as to accrue rewards therein.
     *
     * @param usdcAmount  Number of USDC tokens to commit
     * @return lpAmount  Number of LP USDC/MAI tokens committed
     */
    function _zapIn(UsdcQuantity usdcAmount) internal returns (LpQuantity lpAmount) {
        MaiQuantity maiAmount;

        (usdcAmount, maiAmount) = _splitUSDC(usdcAmount);
        lpAmount = _addLiquidity(usdcAmount, maiAmount);
        _stakeLP(lpAmount);
    }

    /**
     * Extract the given number of LP USDC/MAI tokens
     *
     * This method will:
     *   1. unstake the given number of LP USDC/MAI tokens from QuiDao's Farm,
     *   2. remove the liquidity provided by the given number of LP USDC/MAI tokens from the liquidity pool, and
     *   3. convert the MAI tokens back into USDC tokens.
     *
     * @param lpAmount  Number of LP USDC/MAI tokens to extract
     * @return usdcAmount  Number of extracted USDC tokens
     */
    function _zapOut(LpQuantity lpAmount) internal returns (UsdcQuantity usdcAmount) {
        MaiQuantity maiAmount;

        _unstakeLP(lpAmount);
        (usdcAmount, maiAmount) = _removeLiquidity(lpAmount);
        usdcAmount = _unsplitUSDC(usdcAmount, maiAmount);
    }

    /**
     * Given a USDC token amount, split a portion of it into MAI tokens so as to provide balanced liquidity
     *
     * @param amount  Number of USDC tokens to split
     * @return usdcAmount  Number of resulting USDC tokens
     * @return maiAmount  Number of resulting MAI tokens
     */
    function _splitUSDC(UsdcQuantity amount) internal returns (UsdcQuantity usdcAmount, MaiQuantity maiAmount) {
        (UsdcQuantity usdcReserves, ) = _getLpReserves();
        UsdcQuantity amountToSwap = _calculateSwapInAmount(usdcReserves, amount);

        require(lt(UsdcQuantity.wrap(0), amountToSwap), "Nothing to swap");

        maiAmount = _swapTokens(amountToSwap);
        usdcAmount = sub(amount, amountToSwap);
    }

    /**
     * Given a USDC token amount and a MAI token amount, swap MAIs into USDCs and consolidate
     *
     * @param amount  Number of USDC tokens to consolidate with
     * @param maiAmount  Number of MAI tokens to consolidate in
     * @return usdcAmount  Consolidated USDC amount
     */
    function _unsplitUSDC(UsdcQuantity amount, MaiQuantity maiAmount) internal returns (UsdcQuantity usdcAmount) {
        usdcAmount = add(amount, _swapTokens(maiAmount));
    }

    /**
     * Add liquidity to the QuickSwap Liquidity Pool, as much as indicated by the given pair od USDC/MAI amounts
     *
     * @param usdcAmount  Number of USDC tokens to add
     * @param maiAmount  Number of MAI tokens to add
     * @return lpAmount  Number of LP USDC/MAI tokens obtained
     */
    function _addLiquidity(UsdcQuantity usdcAmount, MaiQuantity maiAmount) internal returns (LpQuantity lpAmount) {
        (, , uint256 _lpAmount) = IUniswapV2Router02(quickSwapRouterAddress).addLiquidity(
            usdcAddress,
            maiAddress,
            UsdcQuantity.unwrap(usdcAmount),
            MaiQuantity.unwrap(maiAmount),
            1,
            1,
            address(this),
            block.timestamp + ONE_HOUR
        );
        lpAmount = LpQuantity.wrap(_lpAmount);
    }

    /**
     * Remove liquidity from the QuickSwap Liquidity Pool, as much as indicated by the given amount of LP tokens
     *
     * @param lpAmount  Number of LP USDC/MAI tokens to withdraw
     * @return usdcAmount  Number of USDC tokens withdrawn
     * @return maiAmount  Number of MAI tokens withdrawn
     */
    function _removeLiquidity(LpQuantity lpAmount) internal returns (UsdcQuantity usdcAmount, MaiQuantity maiAmount) {
        (uint256 _usdcAmount, uint256 _maiAmount) = IUniswapV2Router02(quickSwapRouterAddress).removeLiquidity(
            usdcAddress,
            maiAddress,
            LpQuantity.unwrap(lpAmount),
            1,
            1,
            address(this),
            block.timestamp + ONE_HOUR
        );
        (usdcAmount, maiAmount) = (UsdcQuantity.wrap(_usdcAmount), MaiQuantity.wrap(_maiAmount));
    }

    /**
     * Deposit the given number of LP tokens into QiDao's Farm
     *
     * @param lpAmount  Number of LP USDC/MAI tokens to deposit into QiDao's Farm
     */
    function _stakeLP(LpQuantity lpAmount) internal {
        // --- Gas Saving -------------------------------------------------------------------------
        address _qiDaoFarmAddress = qiDaoFarmAddress;

        IERC20(lpAddress).approve(_qiDaoFarmAddress, LpQuantity.unwrap(lpAmount));
        IFarm(_qiDaoFarmAddress).deposit(qiDaoPoolId, LpQuantity.unwrap(lpAmount));
    }

    /**
     * Remove the given number of LP tokens from QiDao's Farm
     *
     * @param lpAmount  Number of LP USDC/MAI tokens to remove from QiDao's Farm
     */
    function _unstakeLP(LpQuantity lpAmount) internal {
        IFarm(qiDaoFarmAddress).withdraw(qiDaoPoolId, LpQuantity.unwrap(lpAmount));
    }

    /**
     * Return the rewards accrued by staking LP USDC/MAI tokens in QiDao's Farm (in QI tokens)
     *
     * @return qiAmount  Number of QI tokens accrued
     */
    function _getPendingRewardsAmount() internal view returns (QiQuantity qiAmount) {
        // Get rewards on Farm
        qiAmount = QiQuantity.wrap(IFarm(qiDaoFarmAddress).pending(qiDaoPoolId, address(this)));
    }

    /**
     * Swap the given number of MAI tokens to USDC
     *
     * @param maiAmount  Number of MAI tokens to swap
     * @return usdcAmount  Number of USDC tokens obtained
     */
    function _swapTokens(MaiQuantity maiAmount) internal returns (UsdcQuantity usdcAmount) {
        usdcAmount = UsdcQuantity.wrap(_swapTokens(maiAddress, usdcAddress, MaiQuantity.unwrap(maiAmount)));
    }

    /**
     * Swap the given number of USDC tokens to MAI
     *
     * @param usdcAmount  Number of USDC tokens to swap
     * @return maiAmount  Number of MAI tokens obtained
     */
    function _swapTokens(UsdcQuantity usdcAmount) internal returns (MaiQuantity maiAmount) {
        maiAmount = MaiQuantity.wrap(_swapTokens(usdcAddress, maiAddress, UsdcQuantity.unwrap(usdcAmount)));
    }

    /**
     * Swap the given number of QI tokens to USDC
     *
     * @param qiAmount  Number of QI tokens to swap
     * @return usdcAmount  Number of USDC tokens obtained
     */
    function _swapTokens(QiQuantity qiAmount) internal returns (UsdcQuantity usdcAmount) {
        usdcAmount = UsdcQuantity.wrap(_swapTokens(qiAddress, usdcAddress, QiQuantity.unwrap(qiAmount)));
    }

    /**
     * Swap the given amount of tokens from the given "from" address to the given "to" address via QuickSwap, and return the amount of "to" tokens swapped
     *
     * @param fromAddress  Address to get swap tokens from
     * @param toAddress  Address to get swap tokens to
     * @param amount  Amount of tokens to swap (from)
     * @return swappedAmount  Amount of tokens deposited in addressTo
     */
    function _swapTokens(
        address fromAddress,
        address toAddress,
        uint256 amount
    ) internal returns (uint256 swappedAmount) {
        address[] memory path = new address[](2);
        (path[0], path[1]) = (fromAddress, toAddress);

        swappedAmount = IUniswapV2Router02(quickSwapRouterAddress).swapExactTokensForTokens(amount, 1, path, address(this), block.timestamp + ONE_HOUR)[1];
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --- UniSwap Simulation ---------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------

    function _calculateSwapInAmount(UsdcQuantity reserveIn, UsdcQuantity userIn) internal pure returns (UsdcQuantity amount) {
        amount = sub(sqrt(mulDiv(add(mul(3988009, reserveIn), mul(3988000, userIn)), reserveIn, 3976036)), mulDiv(reserveIn, 1997, 1994));
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        amountOut = Math.mulDiv(amountInWithFee, reserveOut, reserveIn * 1000 + amountInWithFee);
    }

    function _getAmountOut(
        MaiQuantity amountIn,
        MaiQuantity reserveIn,
        UsdcQuantity reserveOut
    ) internal pure returns (UsdcQuantity) {
        return UsdcQuantity.wrap(_getAmountOut(MaiQuantity.unwrap(amountIn), MaiQuantity.unwrap(reserveIn), UsdcQuantity.unwrap(reserveOut)));
    }

    function _getAmountOut(
        UsdcQuantity amountIn,
        UsdcQuantity reserveIn,
        MaiQuantity reserveOut
    ) internal pure returns (MaiQuantity amountOut) {
        return MaiQuantity.wrap(_getAmountOut(UsdcQuantity.unwrap(amountIn), UsdcQuantity.unwrap(reserveIn), MaiQuantity.unwrap(reserveOut)));
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./IPeronioSupport.sol";

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- Implementation-side user defined value types -----------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

type UniSwapKQuantity is uint256;
type UniSwapRootKQuantity is uint256;
type UsdcSqQuantity is uint256;
type RatioWith4Decimals is uint256;

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- Standard Numeric Types ---------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------
//
// Standard Numeric Types (SNTs) can be operated with in the same manner as "normal" numeric types can.
// This means that SNTs can:
//   - be added together,
//   - be subtracted from each other,
//   - be multiplied by a scalar value (only uint256 in this implementation) - both on the left and on the right,
//   - the minimum be calculated among them,
//   - the maximum be calculated among them,
//   - the "==", "!=", "<=", "<", ">", and ">=" relations established between them, and
// The mulDiv() interactions will be taken care of later.
//

// --- UniSwap K ----------------------------------------------------------------------------------------------------------------------------------------------
function add(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(UniSwapKQuantity.unwrap(left) + UniSwapKQuantity.unwrap(right));
}

function sub(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(UniSwapKQuantity.unwrap(left) - UniSwapKQuantity.unwrap(right));
}

function mul(UniSwapKQuantity val, uint256 x) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(UniSwapKQuantity.unwrap(val) * x);
}

function mul(uint256 x, UniSwapKQuantity val) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(x * UniSwapKQuantity.unwrap(val));
}

function min(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.min(UniSwapKQuantity.unwrap(left), UniSwapKQuantity.unwrap(right)));
}

function max(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.max(UniSwapKQuantity.unwrap(left), UniSwapKQuantity.unwrap(right)));
}

function eq(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) == UniSwapKQuantity.unwrap(right);
}

function neq(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) != UniSwapKQuantity.unwrap(right);
}

function lt(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) < UniSwapKQuantity.unwrap(right);
}

function gt(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) > UniSwapKQuantity.unwrap(right);
}

function lte(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) <= UniSwapKQuantity.unwrap(right);
}

function gte(UniSwapKQuantity left, UniSwapKQuantity right) pure returns (bool) {
    return UniSwapKQuantity.unwrap(left) >= UniSwapKQuantity.unwrap(right);
}

// --- UniSwap rootK ------------------------------------------------------------------------------------------------------------------------------------------
function add(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(UniSwapRootKQuantity.unwrap(left) + UniSwapRootKQuantity.unwrap(right));
}

function sub(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(UniSwapRootKQuantity.unwrap(left) - UniSwapRootKQuantity.unwrap(right));
}

function mul(UniSwapRootKQuantity val, uint256 x) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(UniSwapRootKQuantity.unwrap(val) * x);
}

function mul(uint256 x, UniSwapRootKQuantity val) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(x * UniSwapRootKQuantity.unwrap(val));
}

function min(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.min(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right)));
}

function max(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.max(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right)));
}

function eq(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) == UniSwapRootKQuantity.unwrap(right);
}

function neq(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) != UniSwapRootKQuantity.unwrap(right);
}

function lt(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) < UniSwapRootKQuantity.unwrap(right);
}

function gt(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) > UniSwapRootKQuantity.unwrap(right);
}

function lte(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) <= UniSwapRootKQuantity.unwrap(right);
}

function gte(UniSwapRootKQuantity left, UniSwapRootKQuantity right) pure returns (bool) {
    return UniSwapRootKQuantity.unwrap(left) >= UniSwapRootKQuantity.unwrap(right);
}

// --- USDC-squared -------------------------------------------------------------------------------------------------------------------------------------------
function add(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(UsdcSqQuantity.unwrap(left) + UsdcSqQuantity.unwrap(right));
}

function sub(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(UsdcSqQuantity.unwrap(left) - UsdcSqQuantity.unwrap(right));
}

function mul(UsdcSqQuantity val, uint256 x) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(UsdcSqQuantity.unwrap(val) * x);
}

function mul(uint256 x, UsdcSqQuantity val) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(x * UsdcSqQuantity.unwrap(val));
}

function min(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.min(UsdcSqQuantity.unwrap(left), UsdcSqQuantity.unwrap(right)));
}

function max(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.max(UsdcSqQuantity.unwrap(left), UsdcSqQuantity.unwrap(right)));
}

function eq(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) == UsdcSqQuantity.unwrap(right);
}

function neq(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) != UsdcSqQuantity.unwrap(right);
}

function lt(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) < UsdcSqQuantity.unwrap(right);
}

function gt(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) > UsdcSqQuantity.unwrap(right);
}

function lte(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) <= UsdcSqQuantity.unwrap(right);
}

function gte(UsdcSqQuantity left, UsdcSqQuantity right) pure returns (bool) {
    return UsdcSqQuantity.unwrap(left) >= UsdcSqQuantity.unwrap(right);
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- USDC-squared quantities --------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

function sqrt(UsdcSqQuantity x) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.sqrt(UsdcSqQuantity.unwrap(x)));
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- UniSwap K-values ---------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

function mul(UsdcQuantity left, MaiQuantity right) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(UsdcQuantity.unwrap(left) * MaiQuantity.unwrap(right));
}

function sqrt(UniSwapKQuantity x) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.sqrt(UniSwapKQuantity.unwrap(x)));
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- Ratio conversion ---------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

function ratio4to6(RatioWith4Decimals x) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(RatioWith4Decimals.unwrap(x) * 10**2);
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- MulDiv Interactions ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

function mulDiv(
    LpQuantity left,
    RatioWith4Decimals right,
    LpQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(LpQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UniSwapKQuantity right,
    LpQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UniSwapRootKQuantity right,
    LpQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcSqQuantity right,
    LpQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    RatioWith4Decimals right,
    MaiQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(MaiQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UniSwapKQuantity right,
    MaiQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UniSwapRootKQuantity right,
    MaiQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcQuantity right,
    UniSwapKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(MaiQuantity.unwrap(left), UsdcQuantity.unwrap(right), UniSwapKQuantity.unwrap(div));
}

function mulDiv(
    MaiQuantity left,
    UsdcQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcQuantity right,
    uint256 div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcQuantity.unwrap(right), div));
}

function mulDiv(
    MaiQuantity left,
    UsdcSqQuantity right,
    MaiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcSqQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcSqQuantity right,
    UsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    RatioWith4Decimals right,
    PePerUsdcQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UniSwapKQuantity right,
    PePerUsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UniSwapRootKQuantity right,
    PePerUsdcQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcSqQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith4Decimals right,
    PeQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UniSwapKQuantity right,
    PeQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UniSwapRootKQuantity right,
    PeQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcSqQuantity right,
    PeQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    RatioWith4Decimals right,
    QiQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(QiQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UniSwapKQuantity right,
    QiQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UniSwapRootKQuantity right,
    QiQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcSqQuantity right,
    QiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    LpQuantity right,
    LpQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    LpQuantity right,
    RatioWith4Decimals div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), LpQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    MaiQuantity right,
    RatioWith4Decimals div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), MaiQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    PePerUsdcQuantity right,
    RatioWith4Decimals div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), PePerUsdcQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    PeQuantity right,
    PeQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    PeQuantity right,
    RatioWith4Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), PeQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    QiQuantity right,
    QiQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    QiQuantity right,
    RatioWith4Decimals div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), QiQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    RatioWith6Decimals right,
    RatioWith4Decimals div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UniSwapKQuantity right,
    RatioWith4Decimals div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UniSwapKQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UniSwapRootKQuantity right,
    RatioWith4Decimals div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UniSwapRootKQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcPerPeQuantity right,
    RatioWith4Decimals div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcPerPeQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcQuantity right,
    RatioWith4Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcSqQuantity right,
    RatioWith4Decimals div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcSqQuantity.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith4Decimals left,
    uint256 right,
    RatioWith4Decimals div
) pure returns (uint256) {
    return Math.mulDiv(RatioWith4Decimals.unwrap(left), right, RatioWith4Decimals.unwrap(div));
}

function mulDiv(
    RatioWith4Decimals left,
    uint256 right,
    uint256 div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith4Decimals.unwrap(left), right, div));
}

function mulDiv(
    RatioWith6Decimals left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    RatioWith4Decimals right,
    RatioWith6Decimals div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UniSwapKQuantity right,
    RatioWith6Decimals div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UniSwapKQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UniSwapRootKQuantity right,
    RatioWith6Decimals div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UniSwapRootKQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcSqQuantity right,
    RatioWith6Decimals div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcSqQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    LpQuantity right,
    UniSwapKQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), LpQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    MaiQuantity right,
    UniSwapKQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), MaiQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    PePerUsdcQuantity right,
    UniSwapKQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    PeQuantity right,
    UniSwapKQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), PeQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    QiQuantity right,
    UniSwapKQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), QiQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    RatioWith4Decimals right,
    UniSwapKQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    RatioWith6Decimals right,
    UniSwapKQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UniSwapRootKQuantity right,
    UniSwapKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcPerPeQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcQuantity right,
    MaiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcQuantity right,
    UsdcSqQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcSqQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    uint256 right,
    MaiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), right, MaiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    uint256 right,
    UniSwapKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UniSwapKQuantity.unwrap(left), right, UniSwapKQuantity.unwrap(div));
}

function mulDiv(
    UniSwapKQuantity left,
    uint256 right,
    UniSwapRootKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), right, UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    uint256 right,
    UsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), right, UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapKQuantity left,
    uint256 right,
    uint256 div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapKQuantity.unwrap(left), right, div));
}

function mulDiv(
    UniSwapRootKQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    LpQuantity right,
    UniSwapRootKQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), LpQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    MaiQuantity right,
    UniSwapRootKQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), MaiQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    PePerUsdcQuantity right,
    UniSwapRootKQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    PeQuantity right,
    UniSwapRootKQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), PeQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    QiQuantity right,
    UniSwapRootKQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), QiQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    RatioWith4Decimals right,
    UniSwapRootKQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    RatioWith6Decimals right,
    UniSwapRootKQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapRootKQuantity right,
    MaiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapRootKQuantity right,
    UniSwapKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapRootKQuantity right,
    UsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UniSwapRootKQuantity right,
    uint256 div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), div));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcPerPeQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcSqQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UniSwapRootKQuantity left,
    uint256 right,
    UniSwapRootKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UniSwapRootKQuantity.unwrap(left), right, UniSwapRootKQuantity.unwrap(div));
}

function mulDiv(
    UniSwapRootKQuantity left,
    uint256 right,
    uint256 div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UniSwapRootKQuantity.unwrap(left), right, div));
}

function mulDiv(
    UsdcPerPeQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    RatioWith4Decimals right,
    UsdcPerPeQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UniSwapKQuantity right,
    UsdcPerPeQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UniSwapRootKQuantity right,
    UsdcPerPeQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UsdcSqQuantity right,
    UsdcPerPeQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    MaiQuantity right,
    UniSwapKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), UniSwapKQuantity.unwrap(div));
}

function mulDiv(
    UsdcQuantity left,
    MaiQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    MaiQuantity right,
    uint256 div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), div));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith4Decimals right,
    UsdcQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapKQuantity right,
    MaiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapKQuantity right,
    UsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapKQuantity right,
    UsdcSqQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UniSwapRootKQuantity right,
    UsdcQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UsdcQuantity right,
    UsdcSqQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcSqQuantity.unwrap(div));
}

function mulDiv(
    UsdcQuantity left,
    UsdcQuantity right,
    uint256 div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), div));
}

function mulDiv(
    UsdcQuantity left,
    UsdcSqQuantity right,
    UsdcQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    LpQuantity right,
    UsdcSqQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), LpQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    MaiQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), MaiQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    MaiQuantity right,
    UsdcQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), MaiQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    MaiQuantity right,
    UsdcSqQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), MaiQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    PePerUsdcQuantity right,
    UsdcSqQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    PeQuantity right,
    UsdcSqQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), PeQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    QiQuantity right,
    UsdcSqQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), QiQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    RatioWith4Decimals right,
    UsdcSqQuantity div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), RatioWith4Decimals.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    RatioWith6Decimals right,
    UsdcSqQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UniSwapKQuantity right,
    UsdcSqQuantity div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UniSwapKQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UniSwapRootKQuantity right,
    UsdcSqQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UniSwapRootKQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UsdcPerPeQuantity right,
    UsdcSqQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UsdcQuantity right,
    UsdcSqQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    uint256 right,
    UsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), right, UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcSqQuantity left,
    uint256 right,
    UsdcSqQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UsdcSqQuantity.unwrap(left), right, UsdcSqQuantity.unwrap(div));
}

function mulDiv(
    UsdcSqQuantity left,
    uint256 right,
    uint256 div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(UsdcSqQuantity.unwrap(left), right, div));
}

function mulDiv(
    uint256 left,
    RatioWith4Decimals right,
    RatioWith4Decimals div
) pure returns (uint256) {
    return Math.mulDiv(left, RatioWith4Decimals.unwrap(right), RatioWith4Decimals.unwrap(div));
}

function mulDiv(
    uint256 left,
    RatioWith4Decimals right,
    uint256 div
) pure returns (RatioWith4Decimals) {
    return RatioWith4Decimals.wrap(Math.mulDiv(left, RatioWith4Decimals.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    UniSwapKQuantity right,
    MaiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(left, UniSwapKQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    uint256 left,
    UniSwapKQuantity right,
    UniSwapKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, UniSwapKQuantity.unwrap(right), UniSwapKQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    UniSwapKQuantity right,
    UniSwapRootKQuantity div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(left, UniSwapKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div)));
}

function mulDiv(
    uint256 left,
    UniSwapKQuantity right,
    UsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(left, UniSwapKQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    uint256 left,
    UniSwapKQuantity right,
    uint256 div
) pure returns (UniSwapKQuantity) {
    return UniSwapKQuantity.wrap(Math.mulDiv(left, UniSwapKQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    UniSwapRootKQuantity right,
    UniSwapRootKQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, UniSwapRootKQuantity.unwrap(right), UniSwapRootKQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    UniSwapRootKQuantity right,
    uint256 div
) pure returns (UniSwapRootKQuantity) {
    return UniSwapRootKQuantity.wrap(Math.mulDiv(left, UniSwapRootKQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    UsdcSqQuantity right,
    UsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(left, UsdcSqQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    uint256 left,
    UsdcSqQuantity right,
    UsdcSqQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, UsdcSqQuantity.unwrap(right), UsdcSqQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    UsdcSqQuantity right,
    uint256 div
) pure returns (UsdcSqQuantity) {
    return UsdcSqQuantity.wrap(Math.mulDiv(left, UsdcSqQuantity.unwrap(right), div));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFarm {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function endBlock() external view returns (uint256);

    function erc20() external view returns (address);

    function feeAddress() external view returns (address);

    function fund(uint256 _amount) external;

    function massUpdatePools() external;

    function owner() external view returns (address);

    function paidOut() external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accERC20PerShare,
            uint16 depositFeeBP
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function rewardPerBlock() external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setFeeAddress(address _feeAddress) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function totalPending() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function NAME() external pure returns (string memory);

    function SYMBOL() external pure returns (string memory);

    function DECIMALS() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./IPeronio.sol";

import {Math} from "@openzeppelin/contracts_latest/utils/math/Math.sol";

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- Standard Numeric Types ---------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------
//
// Standard Numeric Types (SNTs) can be operated with in the same manner as "normal" numeric types can.
// This means that SNTs can:
//   - be added together,
//   - be subtracted from each other,
//   - be multiplied by a scalar value (only uint256 in this implementation) - both on the left and on the right,
//   - the minimum be calculated among them,
//   - the maximum be calculated among them,
//   - the "==", "!=", "<=", "<", ">", and ">=" relations established between them, and
// The mulDiv() interactions will be taken care of later.
//

// --- USDC ---------------------------------------------------------------------------------------------------------------------------------------------------
function add(UsdcQuantity left, UsdcQuantity right) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(UsdcQuantity.unwrap(left) + UsdcQuantity.unwrap(right));
}

function sub(UsdcQuantity left, UsdcQuantity right) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(UsdcQuantity.unwrap(left) - UsdcQuantity.unwrap(right));
}

function mul(UsdcQuantity val, uint256 x) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(UsdcQuantity.unwrap(val) * x);
}

function mul(uint256 x, UsdcQuantity val) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(x * UsdcQuantity.unwrap(val));
}

function min(UsdcQuantity left, UsdcQuantity right) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.min(UsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right)));
}

function max(UsdcQuantity left, UsdcQuantity right) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.max(UsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right)));
}

function eq(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) == UsdcQuantity.unwrap(right);
}

function neq(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) != UsdcQuantity.unwrap(right);
}

function lt(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) < UsdcQuantity.unwrap(right);
}

function gt(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) > UsdcQuantity.unwrap(right);
}

function lte(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) <= UsdcQuantity.unwrap(right);
}

function gte(UsdcQuantity left, UsdcQuantity right) pure returns (bool) {
    return UsdcQuantity.unwrap(left) >= UsdcQuantity.unwrap(right);
}

// --- MAI ----------------------------------------------------------------------------------------------------------------------------------------------------
function add(MaiQuantity left, MaiQuantity right) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(MaiQuantity.unwrap(left) + MaiQuantity.unwrap(right));
}

function sub(MaiQuantity left, MaiQuantity right) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(MaiQuantity.unwrap(left) - MaiQuantity.unwrap(right));
}

function mul(MaiQuantity val, uint256 x) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(MaiQuantity.unwrap(val) * x);
}

function mul(uint256 x, MaiQuantity val) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(x * MaiQuantity.unwrap(val));
}

function min(MaiQuantity left, MaiQuantity right) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.min(MaiQuantity.unwrap(left), MaiQuantity.unwrap(right)));
}

function max(MaiQuantity left, MaiQuantity right) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.max(MaiQuantity.unwrap(left), MaiQuantity.unwrap(right)));
}

function eq(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) == MaiQuantity.unwrap(right);
}

function neq(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) != MaiQuantity.unwrap(right);
}

function lt(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) < MaiQuantity.unwrap(right);
}

function gt(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) > MaiQuantity.unwrap(right);
}

function lte(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) <= MaiQuantity.unwrap(right);
}

function gte(MaiQuantity left, MaiQuantity right) pure returns (bool) {
    return MaiQuantity.unwrap(left) >= MaiQuantity.unwrap(right);
}

// --- LP USDC/MAI --------------------------------------------------------------------------------------------------------------------------------------------
function add(LpQuantity left, LpQuantity right) pure returns (LpQuantity) {
    return LpQuantity.wrap(LpQuantity.unwrap(left) + LpQuantity.unwrap(right));
}

function sub(LpQuantity left, LpQuantity right) pure returns (LpQuantity) {
    return LpQuantity.wrap(LpQuantity.unwrap(left) - LpQuantity.unwrap(right));
}

function mul(LpQuantity val, uint256 x) pure returns (LpQuantity) {
    return LpQuantity.wrap(LpQuantity.unwrap(val) * x);
}

function mul(uint256 x, LpQuantity val) pure returns (LpQuantity) {
    return LpQuantity.wrap(x * LpQuantity.unwrap(val));
}

function min(LpQuantity left, LpQuantity right) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.min(LpQuantity.unwrap(left), LpQuantity.unwrap(right)));
}

function max(LpQuantity left, LpQuantity right) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.max(LpQuantity.unwrap(left), LpQuantity.unwrap(right)));
}

function eq(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) == LpQuantity.unwrap(right);
}

function neq(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) != LpQuantity.unwrap(right);
}

function lt(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) < LpQuantity.unwrap(right);
}

function gt(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) > LpQuantity.unwrap(right);
}

function lte(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) <= LpQuantity.unwrap(right);
}

function gte(LpQuantity left, LpQuantity right) pure returns (bool) {
    return LpQuantity.unwrap(left) >= LpQuantity.unwrap(right);
}

// --- PE -----------------------------------------------------------------------------------------------------------------------------------------------------
function add(PeQuantity left, PeQuantity right) pure returns (PeQuantity) {
    return PeQuantity.wrap(PeQuantity.unwrap(left) + PeQuantity.unwrap(right));
}

function sub(PeQuantity left, PeQuantity right) pure returns (PeQuantity) {
    return PeQuantity.wrap(PeQuantity.unwrap(left) - PeQuantity.unwrap(right));
}

function mul(PeQuantity val, uint256 x) pure returns (PeQuantity) {
    return PeQuantity.wrap(PeQuantity.unwrap(val) * x);
}

function mul(uint256 x, PeQuantity val) pure returns (PeQuantity) {
    return PeQuantity.wrap(x * PeQuantity.unwrap(val));
}

function min(PeQuantity left, PeQuantity right) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.min(PeQuantity.unwrap(left), PeQuantity.unwrap(right)));
}

function max(PeQuantity left, PeQuantity right) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.max(PeQuantity.unwrap(left), PeQuantity.unwrap(right)));
}

function eq(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) == PeQuantity.unwrap(right);
}

function neq(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) != PeQuantity.unwrap(right);
}

function lt(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) < PeQuantity.unwrap(right);
}

function gt(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) > PeQuantity.unwrap(right);
}

function lte(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) <= PeQuantity.unwrap(right);
}

function gte(PeQuantity left, PeQuantity right) pure returns (bool) {
    return PeQuantity.unwrap(left) >= PeQuantity.unwrap(right);
}

// --- QI -----------------------------------------------------------------------------------------------------------------------------------------------------
function add(QiQuantity left, QiQuantity right) pure returns (QiQuantity) {
    return QiQuantity.wrap(QiQuantity.unwrap(left) + QiQuantity.unwrap(right));
}

function sub(QiQuantity left, QiQuantity right) pure returns (QiQuantity) {
    return QiQuantity.wrap(QiQuantity.unwrap(left) - QiQuantity.unwrap(right));
}

function mul(QiQuantity val, uint256 x) pure returns (QiQuantity) {
    return QiQuantity.wrap(QiQuantity.unwrap(val) * x);
}

function mul(uint256 x, QiQuantity val) pure returns (QiQuantity) {
    return QiQuantity.wrap(x * QiQuantity.unwrap(val));
}

function min(QiQuantity left, QiQuantity right) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.min(QiQuantity.unwrap(left), QiQuantity.unwrap(right)));
}

function max(QiQuantity left, QiQuantity right) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.max(QiQuantity.unwrap(left), QiQuantity.unwrap(right)));
}

function eq(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) == QiQuantity.unwrap(right);
}

function neq(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) != QiQuantity.unwrap(right);
}

function lt(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) < QiQuantity.unwrap(right);
}

function gt(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) > QiQuantity.unwrap(right);
}

function lte(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) <= QiQuantity.unwrap(right);
}

function gte(QiQuantity left, QiQuantity right) pure returns (bool) {
    return QiQuantity.unwrap(left) >= QiQuantity.unwrap(right);
}

// --- PE/USDC ------------------------------------------------------------------------------------------------------------------------------------------------
function add(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(PePerUsdcQuantity.unwrap(left) + PePerUsdcQuantity.unwrap(right));
}

function sub(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(PePerUsdcQuantity.unwrap(left) - PePerUsdcQuantity.unwrap(right));
}

function mul(PePerUsdcQuantity val, uint256 x) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(PePerUsdcQuantity.unwrap(val) * x);
}

function mul(uint256 x, PePerUsdcQuantity val) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(x * PePerUsdcQuantity.unwrap(val));
}

function min(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.min(PePerUsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right)));
}

function max(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.max(PePerUsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right)));
}

function eq(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) == PePerUsdcQuantity.unwrap(right);
}

function neq(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) != PePerUsdcQuantity.unwrap(right);
}

function lt(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) < PePerUsdcQuantity.unwrap(right);
}

function gt(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) > PePerUsdcQuantity.unwrap(right);
}

function lte(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) <= PePerUsdcQuantity.unwrap(right);
}

function gte(PePerUsdcQuantity left, PePerUsdcQuantity right) pure returns (bool) {
    return PePerUsdcQuantity.unwrap(left) >= PePerUsdcQuantity.unwrap(right);
}

// --- USDC/PE ------------------------------------------------------------------------------------------------------------------------------------------------
function add(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(UsdcPerPeQuantity.unwrap(left) + UsdcPerPeQuantity.unwrap(right));
}

function sub(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(UsdcPerPeQuantity.unwrap(left) - UsdcPerPeQuantity.unwrap(right));
}

function mul(UsdcPerPeQuantity val, uint256 x) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(UsdcPerPeQuantity.unwrap(val) * x);
}

function mul(uint256 x, UsdcPerPeQuantity val) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(x * UsdcPerPeQuantity.unwrap(val));
}

function min(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.min(UsdcPerPeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right)));
}

function max(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.max(UsdcPerPeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right)));
}

function eq(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) == UsdcPerPeQuantity.unwrap(right);
}

function neq(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) != UsdcPerPeQuantity.unwrap(right);
}

function lt(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) < UsdcPerPeQuantity.unwrap(right);
}

function gt(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) > UsdcPerPeQuantity.unwrap(right);
}

function lte(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) <= UsdcPerPeQuantity.unwrap(right);
}

function gte(UsdcPerPeQuantity left, UsdcPerPeQuantity right) pure returns (bool) {
    return UsdcPerPeQuantity.unwrap(left) >= UsdcPerPeQuantity.unwrap(right);
}

// --- 6-decimals ratio ---------------------------------------------------------------------------------------------------------------------------------------
function add(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(RatioWith6Decimals.unwrap(left) + RatioWith6Decimals.unwrap(right));
}

function sub(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(RatioWith6Decimals.unwrap(left) - RatioWith6Decimals.unwrap(right));
}

function mul(RatioWith6Decimals val, uint256 x) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(RatioWith6Decimals.unwrap(val) * x);
}

function mul(uint256 x, RatioWith6Decimals val) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(x * RatioWith6Decimals.unwrap(val));
}

function min(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.min(RatioWith6Decimals.unwrap(left), RatioWith6Decimals.unwrap(right)));
}

function max(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.max(RatioWith6Decimals.unwrap(left), RatioWith6Decimals.unwrap(right)));
}

function eq(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) == RatioWith6Decimals.unwrap(right);
}

function neq(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) != RatioWith6Decimals.unwrap(right);
}

function lt(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) < RatioWith6Decimals.unwrap(right);
}

function gt(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) > RatioWith6Decimals.unwrap(right);
}

function lte(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) <= RatioWith6Decimals.unwrap(right);
}

function gte(RatioWith6Decimals left, RatioWith6Decimals right) pure returns (bool) {
    return RatioWith6Decimals.unwrap(left) >= RatioWith6Decimals.unwrap(right);
}

// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// --- MulDiv Interactions ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

function mulDiv(
    LpQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    MaiQuantity right,
    LpQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), MaiQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    PePerUsdcQuantity right,
    LpQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    PeQuantity right,
    LpQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), PeQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    QiQuantity right,
    LpQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), QiQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    RatioWith6Decimals right,
    LpQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(LpQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcPerPeQuantity right,
    LpQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcQuantity right,
    LpQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    LpQuantity left,
    uint256 right,
    LpQuantity div
) pure returns (uint256) {
    return Math.mulDiv(LpQuantity.unwrap(left), right, LpQuantity.unwrap(div));
}

function mulDiv(
    LpQuantity left,
    uint256 right,
    uint256 div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(LpQuantity.unwrap(left), right, div));
}

function mulDiv(
    MaiQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    LpQuantity right,
    MaiQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), LpQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    PePerUsdcQuantity right,
    MaiQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    PeQuantity right,
    MaiQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), PeQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    QiQuantity right,
    MaiQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), QiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    RatioWith6Decimals right,
    MaiQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(MaiQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcPerPeQuantity right,
    MaiQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcQuantity right,
    MaiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    MaiQuantity left,
    uint256 right,
    MaiQuantity div
) pure returns (uint256) {
    return Math.mulDiv(MaiQuantity.unwrap(left), right, MaiQuantity.unwrap(div));
}

function mulDiv(
    MaiQuantity left,
    uint256 right,
    uint256 div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(MaiQuantity.unwrap(left), right, div));
}

function mulDiv(
    PePerUsdcQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    LpQuantity right,
    PePerUsdcQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), LpQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    MaiQuantity right,
    PePerUsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    PeQuantity right,
    PePerUsdcQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), PeQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    QiQuantity right,
    PePerUsdcQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), QiQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    RatioWith6Decimals right,
    PePerUsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcPerPeQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcPerPeQuantity right,
    RatioWith6Decimals div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcQuantity right,
    PeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcQuantity right,
    RatioWith6Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    PePerUsdcQuantity left,
    uint256 right,
    PePerUsdcQuantity div
) pure returns (uint256) {
    return Math.mulDiv(PePerUsdcQuantity.unwrap(left), right, PePerUsdcQuantity.unwrap(div));
}

function mulDiv(
    PePerUsdcQuantity left,
    uint256 right,
    uint256 div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PePerUsdcQuantity.unwrap(left), right, div));
}

function mulDiv(
    PeQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    LpQuantity right,
    PeQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), LpQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    MaiQuantity right,
    PeQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), MaiQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    PePerUsdcQuantity right,
    PeQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    QiQuantity right,
    PeQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), QiQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith6Decimals right,
    PePerUsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith6Decimals right,
    PeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    RatioWith6Decimals right,
    UsdcQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcPerPeQuantity right,
    PeQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcPerPeQuantity right,
    RatioWith6Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcPerPeQuantity right,
    UsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcQuantity right,
    PeQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    PeQuantity left,
    uint256 right,
    PeQuantity div
) pure returns (uint256) {
    return Math.mulDiv(PeQuantity.unwrap(left), right, PeQuantity.unwrap(div));
}

function mulDiv(
    PeQuantity left,
    uint256 right,
    uint256 div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(PeQuantity.unwrap(left), right, div));
}

function mulDiv(
    QiQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    LpQuantity right,
    QiQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), LpQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    MaiQuantity right,
    QiQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), MaiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    PePerUsdcQuantity right,
    QiQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    PeQuantity right,
    QiQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), PeQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    RatioWith6Decimals right,
    QiQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(QiQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcPerPeQuantity right,
    QiQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcQuantity right,
    QiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    QiQuantity left,
    uint256 right,
    QiQuantity div
) pure returns (uint256) {
    return Math.mulDiv(QiQuantity.unwrap(left), right, QiQuantity.unwrap(div));
}

function mulDiv(
    QiQuantity left,
    uint256 right,
    uint256 div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(QiQuantity.unwrap(left), right, div));
}

function mulDiv(
    RatioWith6Decimals left,
    LpQuantity right,
    LpQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    LpQuantity right,
    RatioWith6Decimals div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), LpQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    MaiQuantity right,
    RatioWith6Decimals div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), MaiQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PePerUsdcQuantity right,
    RatioWith6Decimals div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PePerUsdcQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PeQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PeQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PeQuantity right,
    PeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PeQuantity right,
    RatioWith6Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PeQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    PeQuantity right,
    UsdcQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), PeQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    QiQuantity right,
    QiQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    QiQuantity right,
    RatioWith6Decimals div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), QiQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    RatioWith6Decimals right,
    PePerUsdcQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), RatioWith6Decimals.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    RatioWith6Decimals right,
    UsdcPerPeQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcPerPeQuantity right,
    RatioWith6Decimals div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcPerPeQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcQuantity right,
    PeQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcQuantity right,
    RatioWith6Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcQuantity right,
    UsdcPerPeQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    RatioWith6Decimals left,
    uint256 right,
    RatioWith6Decimals div
) pure returns (uint256) {
    return Math.mulDiv(RatioWith6Decimals.unwrap(left), right, RatioWith6Decimals.unwrap(div));
}

function mulDiv(
    RatioWith6Decimals left,
    uint256 right,
    uint256 div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(RatioWith6Decimals.unwrap(left), right, div));
}

function mulDiv(
    UsdcPerPeQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    LpQuantity right,
    UsdcPerPeQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), LpQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    MaiQuantity right,
    UsdcPerPeQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), MaiQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PePerUsdcQuantity right,
    RatioWith6Decimals div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PePerUsdcQuantity right,
    UsdcPerPeQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PeQuantity right,
    RatioWith6Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PeQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PeQuantity right,
    UsdcPerPeQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    PeQuantity right,
    UsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), PeQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    QiQuantity right,
    UsdcPerPeQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), QiQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    RatioWith6Decimals right,
    UsdcPerPeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UsdcQuantity right,
    UsdcPerPeQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcPerPeQuantity left,
    uint256 right,
    UsdcPerPeQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UsdcPerPeQuantity.unwrap(left), right, UsdcPerPeQuantity.unwrap(div));
}

function mulDiv(
    UsdcPerPeQuantity left,
    uint256 right,
    uint256 div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcPerPeQuantity.unwrap(left), right, div));
}

function mulDiv(
    UsdcQuantity left,
    LpQuantity right,
    LpQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), LpQuantity.unwrap(right), LpQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    LpQuantity right,
    UsdcQuantity div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), LpQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), MaiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    MaiQuantity right,
    UsdcQuantity div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), MaiQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PePerUsdcQuantity right,
    PeQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PePerUsdcQuantity right,
    RatioWith6Decimals div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PePerUsdcQuantity right,
    UsdcQuantity div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PePerUsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PeQuantity right,
    PeQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PeQuantity.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    PeQuantity right,
    UsdcQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), PeQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    QiQuantity right,
    QiQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), QiQuantity.unwrap(right), QiQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    QiQuantity right,
    UsdcQuantity div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), QiQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith6Decimals right,
    PeQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), PeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith6Decimals right,
    UsdcPerPeQuantity div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    RatioWith6Decimals right,
    UsdcQuantity div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), RatioWith6Decimals.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UsdcPerPeQuantity right,
    UsdcQuantity div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcPerPeQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div)));
}

function mulDiv(
    UsdcQuantity left,
    uint256 right,
    UsdcQuantity div
) pure returns (uint256) {
    return Math.mulDiv(UsdcQuantity.unwrap(left), right, UsdcQuantity.unwrap(div));
}

function mulDiv(
    UsdcQuantity left,
    uint256 right,
    uint256 div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(UsdcQuantity.unwrap(left), right, div));
}

function mulDiv(
    uint256 left,
    LpQuantity right,
    LpQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, LpQuantity.unwrap(right), LpQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    LpQuantity right,
    uint256 div
) pure returns (LpQuantity) {
    return LpQuantity.wrap(Math.mulDiv(left, LpQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    MaiQuantity right,
    MaiQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, MaiQuantity.unwrap(right), MaiQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    MaiQuantity right,
    uint256 div
) pure returns (MaiQuantity) {
    return MaiQuantity.wrap(Math.mulDiv(left, MaiQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    PePerUsdcQuantity right,
    PePerUsdcQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, PePerUsdcQuantity.unwrap(right), PePerUsdcQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    PePerUsdcQuantity right,
    uint256 div
) pure returns (PePerUsdcQuantity) {
    return PePerUsdcQuantity.wrap(Math.mulDiv(left, PePerUsdcQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    PeQuantity right,
    PeQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, PeQuantity.unwrap(right), PeQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    PeQuantity right,
    uint256 div
) pure returns (PeQuantity) {
    return PeQuantity.wrap(Math.mulDiv(left, PeQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    QiQuantity right,
    QiQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, QiQuantity.unwrap(right), QiQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    QiQuantity right,
    uint256 div
) pure returns (QiQuantity) {
    return QiQuantity.wrap(Math.mulDiv(left, QiQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    RatioWith6Decimals right,
    RatioWith6Decimals div
) pure returns (uint256) {
    return Math.mulDiv(left, RatioWith6Decimals.unwrap(right), RatioWith6Decimals.unwrap(div));
}

function mulDiv(
    uint256 left,
    RatioWith6Decimals right,
    uint256 div
) pure returns (RatioWith6Decimals) {
    return RatioWith6Decimals.wrap(Math.mulDiv(left, RatioWith6Decimals.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    UsdcPerPeQuantity right,
    UsdcPerPeQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, UsdcPerPeQuantity.unwrap(right), UsdcPerPeQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    UsdcPerPeQuantity right,
    uint256 div
) pure returns (UsdcPerPeQuantity) {
    return UsdcPerPeQuantity.wrap(Math.mulDiv(left, UsdcPerPeQuantity.unwrap(right), div));
}

function mulDiv(
    uint256 left,
    UsdcQuantity right,
    UsdcQuantity div
) pure returns (uint256) {
    return Math.mulDiv(left, UsdcQuantity.unwrap(right), UsdcQuantity.unwrap(div));
}

function mulDiv(
    uint256 left,
    UsdcQuantity right,
    uint256 div
) pure returns (UsdcQuantity) {
    return UsdcQuantity.wrap(Math.mulDiv(left, UsdcQuantity.unwrap(right), div));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Type representing an USDC token quantity
 *
 */
type UsdcQuantity is uint256;

/**
 * Type representing a MAI token quantity
 *
 */
type MaiQuantity is uint256;

/**
 * Type representing an LP USDC/MAI token quantity
 *
 */
type LpQuantity is uint256;

/**
 * Type representing a PE token quantity
 *
 */
type PeQuantity is uint256;

/**
 * Type representing a QI token quantity
 *
 */
type QiQuantity is uint256;

/**
 * Type representing a ratio of PE/USD tokens (always represented using `DECIMALS` decimals)
 *
 */
type PePerUsdcQuantity is uint256;

/**
 * Type representing a ratio of USD/PE tokens (always represented using `DECIMALS` decimals)
 *
 */
type UsdcPerPeQuantity is uint256;

/**
 * Type representing an adimensional ratio, expressed with 6 decimals
 *
 */
type RatioWith6Decimals is uint256;

/**
 * Type representing a role ID
 *
 */
type RoleId is bytes32;

interface IPeronio {
    // --- Events ---------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Emitted upon initialization of the Peronio contract
     *
     * @param owner  The address initializing the contract
     * @param collateral  The number of USDC tokens used as collateral
     * @param startingRatio  The number of PE tokens per USDC token the vault is initialized with
     */
    event Initialized(address owner, UsdcQuantity collateral, PePerUsdcQuantity startingRatio);

    /**
     * Emitted upon minting PE tokens
     *
     * @param to  The address where minted PE tokens get transferred to
     * @param collateralAmount  The number of USDC tokens used as collateral in this minting
     * @param tokenAmount  Amount of PE tokens minted
     */
    event Minted(address indexed to, UsdcQuantity collateralAmount, PeQuantity tokenAmount);

    /**
     * Emitted upon collateral withdrawal
     *
     * @param to  Address where the USDC token withdrawal is directed
     * @param collateralAmount  The number of USDC tokens withdrawn
     * @param tokenAmount  The number of PE tokens burnt
     */
    event Withdrawal(address indexed to, UsdcQuantity collateralAmount, PeQuantity tokenAmount);

    /**
     * Emitted upon liquidity withdrawal
     *
     * @param to  Address where the USDC token withdrawal is directed
     * @param lpAmount  The number of LP USDC/MAI tokens withdrawn
     * @param tokenAmount  The number of PE tokens burnt
     */
    event LiquidityWithdrawal(address indexed to, LpQuantity lpAmount, PeQuantity tokenAmount);

    /**
     * Emitted upon the markup fee being updated
     *
     * @param operator  Address of the one updating the markup fee
     * @param markupFee  New markup fee
     */
    event MarkupFeeUpdated(address operator, RatioWith6Decimals markupFee);

    /**
     * Emitted upon compounding rewards from QiDao's Farm back into the vault
     *
     * @param qi  Number of awarded QI tokens
     * @param usdc  Equivalent number of USDC tokens
     * @param lp  Number of LP USDC/MAI tokens re-invested
     */
    event CompoundRewards(QiQuantity qi, UsdcQuantity usdc, LpQuantity lp);

    // --- Roles - Automatic ----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the hash identifying the role responsible for updating the markup fee
     *
     * @return roleId  The role hash in question
     */
    function MARKUP_ROLE() external view returns (RoleId roleId); // solhint-disable-line func-name-mixedcase

    /**
     * Return the hash identifying the role responsible for compounding rewards
     *
     * @return roleId  The role hash in question
     */
    function REWARDS_ROLE() external view returns (RoleId roleId); // solhint-disable-line func-name-mixedcase

    /**
     * Return the hash identifying the role responsible for migrating between versions
     *
     * @return roleId  The role hash in question
     */
    function MIGRATOR_ROLE() external view returns (RoleId roleId); // solhint-disable-line func-name-mixedcase

    // --- Addresses - Automatic ------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the address used for the USDC tokens in vault
     *
     * @return  The address in question
     */
    function usdcAddress() external view returns (address);

    /**
     * Return the address used for the MAI tokens in vault
     *
     * @return  The address in question
     */
    function maiAddress() external view returns (address);

    /**
     * Return the address used for the LP USDC/MAI tokens in vault
     *
     * @return  The address in question
     */
    function lpAddress() external view returns (address);

    /**
     * Return the address used for the QI tokens in vault
     *
     * @return  The address in question
     */
    function qiAddress() external view returns (address);

    /**
     * Return the address of the QuickSwap Router to talk to
     *
     * @return  The address in question
     */
    function quickSwapRouterAddress() external view returns (address);

    /**
     * Return the address of the QiDao Farm to use
     *
     * @return  The address in question
     */
    function qiDaoFarmAddress() external view returns (address);

    /**
     * Return the pool ID within the QiDao Farm
     *
     * @return  The pool ID in question
     */
    function qiDaoPoolId() external view returns (uint256);

    // --- Fees - Automatic -----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the markup fee the use, using `_decimals()` decimals implicitly
     *
     * @return  The markup fee to use
     */
    function markupFee() external view returns (RatioWith6Decimals);

    /**
     * Return the swap fee the use, using `_decimals()` decimals implicitly
     *
     * @return  The swap fee to use
     */
    function swapFee() external view returns (RatioWith6Decimals);

    // --- Status - Automatic ---------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return wether the Peronio contract has been initialized yet
     *
     * @return  True whenever the contract has already been initialized, false otherwise
     */
    function initialized() external view returns (bool);

    // --- Decimals -------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the number of decimals the PE token will work with
     *
     * @return decimals_  This will always be 6
     */
    function decimals() external view returns (uint8);

    // --- Markup fee change ----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Set the markup fee to the given value (take into account that this will use `_decimals` decimals implicitly)
     *
     * @param newMarkupFee  New markup fee value
     * @return prevMarkupFee  Previous markup fee value
     * @custom:emit  MarkupFeeUpdated
     */
    function setMarkupFee(RatioWith6Decimals newMarkupFee) external returns (RatioWith6Decimals prevMarkupFee);

    // --- Initialization -------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Initialize the PE token by providing collateral USDC tokens - initial conversion rate will be set at the given starting ratio
     *
     * @param usdcAmount  Number of collateral USDC tokens
     * @param startingRatio  Initial minting ratio in PE tokens per USDC tokens minted
     * @custom:emit  Initialized
     */
    function initialize(UsdcQuantity usdcAmount, PePerUsdcQuantity startingRatio) external;

    // --- State views ----------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the USDC and MAI token reserves present in QuickSwap
     *
     * @return usdcReserves  Number of USDC tokens in reserve
     * @return maiReserves  Number of MAI tokens in reserve
     */
    function getLpReserves() external view returns (UsdcQuantity usdcReserves, MaiQuantity maiReserves);

    /**
     * Return the number of LP USDC/MAI tokens on stake at QiDao's Farm
     *
     * @return lpAmount  Number of LP USDC/MAI token on stake
     */
    function stakedBalance() external view returns (LpQuantity lpAmount);

    /**
     * Return the number of USDC and MAI tokens on stake at QiDao's Farm
     *
     * @return usdcAmount  Number of USDC tokens on stake
     * @return maiAmount  Number of MAI tokens on stake
     */
    function stakedTokens() external view returns (UsdcQuantity usdcAmount, MaiQuantity maiAmount);

    /**
     * Return the equivalent number of USDC tokens on stake at QiDao's Farm
     *
     * @return usdcAmount  Total equivalent number of USDC token on stake
     */
    function stakedValue() external view returns (UsdcQuantity usdcAmount);

    /**
     * Return the _collateralized_ price in USDC tokens per PE token
     *
     * @return price  Collateralized price in USDC tokens per PE token
     */
    function usdcPrice() external view returns (PePerUsdcQuantity price);

    /**
     * Return the effective _minting_ price in USDC tokens per PE token
     *
     * @return price  Minting price in USDC tokens per PE token
     */
    function buyingPrice() external view returns (UsdcPerPeQuantity price);

    /**
     * Return the ratio of total number of USDC tokens per PE token
     *
     * @return ratio  Ratio of USDC tokens per PE token, with `_decimal` decimals
     */
    function collateralRatio() external view returns (UsdcPerPeQuantity ratio);

    // --- State changers -------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Mint PE tokens using the provided USDC tokens as collateral --- used by the migrators in order not to incur normal fees
     *
     * @param to  The address to transfer the minted PE tokens to
     * @param usdcAmount  Number of USDC tokens to use as collateral
     * @param minReceive  The minimum number of PE tokens to mint
     * @return peAmount  The number of PE tokens actually minted
     * @custom:emit  Minted
     */
    function mintForMigration(
        address to,
        UsdcQuantity usdcAmount,
        PeQuantity minReceive
    ) external returns (PeQuantity peAmount);

    /**
     * Mint PE tokens using the provided USDC tokens as collateral
     *
     * @param to  The address to transfer the minted PE tokens to
     * @param usdcAmount  Number of USDC tokens to use as collateral
     * @param minReceive  The minimum number of PE tokens to mint
     * @return peAmount  The number of PE tokens actually minted
     * @custom:emit  Minted
     */
    function mint(
        address to,
        UsdcQuantity usdcAmount,
        PeQuantity minReceive
    ) external returns (PeQuantity peAmount);

    /**
     * Extract the given number of PE tokens as USDC tokens
     *
     * @param to  Address to deposit extracted USDC tokens into
     * @param peAmount  Number of PE tokens to withdraw
     * @return usdcTotal  Number of USDC tokens extracted
     * @custom:emit  Withdrawal
     */
    function withdraw(address to, PeQuantity peAmount) external returns (UsdcQuantity usdcTotal);

    /**
     * Extract the given number of PE tokens as LP USDC/MAI tokens
     *
     * @param to  Address to deposit extracted LP USDC/MAI tokens into
     * @param peAmount  Number of PE tokens to withdraw liquidity for
     * @return lpAmount  Number of LP USDC/MAI tokens extracted
     * @custom:emit LiquidityWithdrawal
     */
    function withdrawLiquidity(address to, PeQuantity peAmount) external returns (LpQuantity lpAmount);

    // --- Rewards --------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the rewards accrued by staking LP USDC/MAI tokens in QiDao's Farm (in QI tokens)
     *
     * @return qiAmount  Number of QI tokens accrued
     */
    function getPendingRewardsAmount() external view returns (QiQuantity qiAmount);

    /**
     * Claim QiDao's QI token rewards, and re-invest them in the QuickSwap liquidity pool and QiDao's Farm
     *
     * @return usdcAmount  The number of USDC tokens being re-invested
     * @return lpAmount  The number of LP USDC/MAI tokens being put on stake
     * @custom:emit CompoundRewards
     */
    function compoundRewards() external returns (UsdcQuantity usdcAmount, LpQuantity lpAmount);

    // --- Quotes ---------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Retrieve the expected number of PE tokens corresponding to the given number of USDC tokens for minting.
     *
     * @param usdc  Number of USDC tokens to quote for
     * @return pe  Number of PE tokens quoted for the given number of USDC tokens
     */
    function quoteIn(UsdcQuantity usdc) external view returns (PeQuantity pe);

    /**
     * Retrieve the expected number of USDC tokens corresponding to the given number of PE tokens for withdrawal.
     *
     * @param pe  Number of PE tokens to quote for
     * @return usdc  Number of USDC tokens quoted for the given number of PE tokens
     */
    function quoteOut(PeQuantity pe) external view returns (UsdcQuantity usdc);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
interface IERC20Permit {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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