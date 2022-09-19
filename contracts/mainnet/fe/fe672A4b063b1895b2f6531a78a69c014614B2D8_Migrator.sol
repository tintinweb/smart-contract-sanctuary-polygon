// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PeronioV1Wrapper} from "./old/PeronioV1Wrapper.sol";
import {IPeronioV1} from "./old/IPeronioV1.sol";
import "../IPeronio.sol";

import {Math} from "@openzeppelin/contracts_latest/utils/math/Math.sol";
import {IUniswapV2Pair} from "../uniswap/interfaces/IUniswapV2Pair.sol";
import {IFarm} from "../qidao/IFarm.sol";

import {IERC20} from "@openzeppelin/contracts_latest/token/ERC20/IERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Interface
import {IMigrator} from "./IMigrator.sol";

contract Migrator is IMigrator, ERC165 {
    using PeronioV1Wrapper for IPeronioV1;

    // Peronio V1 Address
    address public immutable peronioV1Address;

    // Peronio V2 Address
    address public immutable peronioV2Address;

    /**
     * Construct a new Peronio migrator
     *
     * @param _peronioV1Address  The address of the old PE contract
     * @param _peronioV2Address  The address of the new PE contract
     */
    constructor(address _peronioV1Address, address _peronioV2Address) {
        // Peronio Addresses
        peronioV1Address = _peronioV1Address;
        peronioV2Address = _peronioV2Address;

        // Unlimited USDC Approve to Peronio V2 contract
        IERC20(IPeronioV1(_peronioV1Address).USDC_ADDRESS()).approve(_peronioV2Address, type(uint256).max);
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMigrator).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Migration Proper -----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Migrate the given number of PE tokens from the old contract to the new one
     *
     * @param amount  The number of PE tokens to withdraw from the old contract
     * @return usdc  The number of USDC tokens withdrawn from the old contract
     * @return pe  The number of PE tokens minted on the new contract
     * @custom:emit  Migrated
     */
    function migrate(uint256 amount) external override returns (uint256 usdc, uint256 pe) {
        // Peronio V1 Contract Wrapper
        IPeronioV1 peronioV1 = IPeronioV1(peronioV1Address);
        // Peronio V2 Contract
        IPeronio peronioV2 = IPeronio(peronioV2Address);

        // Transfer PE V1 to this contract
        IERC20(peronioV1Address).transferFrom(msg.sender, address(this), amount);

        // Calculate USDC to be received by Peronio V1
        usdc = peronioV1.withdrawV2(address(this), amount);
        // Calculate PE to be minted by Peronio V2
        pe = PeQuantity.unwrap(peronioV2.mintForMigration(msg.sender, UsdcQuantity.wrap(usdc), PeQuantity.wrap(1)));

        // Emit Migrated event
        emit Migrated(block.timestamp, amount, usdc, pe);
    }

    // --- Quote ----------------------------------------------------------------------------------------------------------------------------------------------
    //
    // Quote is created by inlining the call to migrate, and discarding state-changing statements
    //

    /**
     * Retrieve the number of USDC tokens to withdraw from the old contract, and the number of OE tokens to mint on the new one
     *
     * @param amount  The number of PE tokens to withdraw from the old contract
     * @return usdc  The number of USDC tokens to withdraw from the old contract
     * @return pe  The number of PE tokens to mint on the new contract
     */
    function quote(uint256 amount) external view override returns (uint256 usdc, uint256 pe) {
        uint256 usdcReserves;
        uint256 maiReserves;
        {
            (uint112 _usdcReserves, uint112 _maiReserves) = IPeronioV1(peronioV1Address).getLpReserves();
            (usdcReserves, maiReserves) = (uint256(_usdcReserves), uint256(_maiReserves));
        }

        uint256 lpTotalSupply = IERC20(IPeronioV1(peronioV1Address).LP_ADDRESS()).totalSupply();
        uint256 kLast = IUniswapV2Pair(IPeronioV1(peronioV1Address).LP_ADDRESS()).kLast();

        {
            uint256 rootKLast = Math.sqrt(kLast);
            uint256 rootK = Math.sqrt(usdcReserves * maiReserves);
            if (rootKLast < rootK) {
                lpTotalSupply += (lpTotalSupply * (rootK - rootKLast)) / (5 * rootK + rootKLast);
            }
        }

        {
            uint256 usdcAmount;
            uint256 maiAmount;
            {
                uint256 newLpBalance = IERC20(IPeronioV1(peronioV1Address).LP_ADDRESS()).balanceOf(IPeronioV1(peronioV1Address).LP_ADDRESS()) +
                    (((amount * 10e8) / IERC20(peronioV1Address).totalSupply()) *
                        IFarm(IPeronioV1(peronioV1Address).QIDAO_FARM_ADDRESS()).deposited(IPeronioV1(peronioV1Address).QIDAO_POOL_ID(), peronioV1Address)) /
                    10e8;
                usdcAmount = Math.mulDiv(newLpBalance, usdcReserves, lpTotalSupply);
                maiAmount = Math.mulDiv(newLpBalance, maiReserves, lpTotalSupply);
                lpTotalSupply -= newLpBalance;
            }

            usdcReserves -= usdcAmount;
            maiReserves -= maiAmount;
            kLast = usdcReserves * maiReserves;

            {
                uint256 usdcAmountOut = Math.mulDiv(997 * maiAmount, usdcReserves, 997 * maiAmount + 1000 * maiReserves);
                usdc = usdcAmount + usdcAmountOut;
                usdcReserves -= usdcAmountOut;
            }
        }

        uint256 lpAmountMint;
        {
            uint256 usdcAmount;
            uint256 maiAmount;
            {
                uint256 usdcAmountToSwap = Math.sqrt(Math.mulDiv(3988009 * usdcReserves + 3988000 * usdc, usdcReserves, 3976036)) -
                    Math.mulDiv(usdcReserves, 1997, 1994);
                uint256 maiAmountOut = Math.mulDiv(997 * usdcAmountToSwap, maiReserves, 997 * usdcAmountToSwap + 1000 * usdcReserves);

                usdcReserves += usdcAmountToSwap;
                maiReserves -= maiAmountOut;

                {
                    uint256 amountMaiOptimal = Math.mulDiv(usdc, maiReserves, usdcReserves);
                    if (amountMaiOptimal <= maiAmountOut) {
                        (usdcAmount, maiAmount) = (usdc, amountMaiOptimal);
                    } else {
                        uint256 amountUsdcOptimal = (maiAmountOut * usdcReserves) / maiReserves;
                        (usdcAmount, maiAmount) = (amountUsdcOptimal, maiAmountOut);
                    }
                }

                {
                    uint256 rootK = Math.sqrt(usdcReserves * maiReserves);
                    uint256 rootKLast = Math.sqrt(kLast);
                    if (rootKLast < rootK) {
                        lpTotalSupply += (lpTotalSupply * (rootK - rootKLast)) / (5 * rootK + rootKLast);
                    }
                }
            }

            uint8 decimals = IPeronio(peronioV2Address).decimals();
            uint256 totalMintFee;
            {
                (, , , , uint16 depositFeeBP) = IFarm(IPeronio(peronioV2Address).qiDaoFarmAddress()).poolInfo(IPeronio(peronioV2Address).qiDaoPoolId());
                totalMintFee = RatioWith6Decimals.unwrap(IPeronio(peronioV2Address).swapFee()) + uint256(depositFeeBP) * 10**(decimals - 4);
            }

            lpAmountMint = Math.mulDiv(
                Math.min(Math.mulDiv(usdcAmount, lpTotalSupply, usdcReserves), Math.mulDiv(maiAmount, lpTotalSupply, maiReserves)),
                10**decimals - totalMintFee,
                10**decimals
            );
        }

        uint256 stakedAmount = IFarm(IPeronio(peronioV2Address).qiDaoFarmAddress()).deposited(IPeronio(peronioV2Address).qiDaoPoolId(), peronioV2Address);

        pe = Math.mulDiv(lpAmountMint, IERC20(peronioV2Address).totalSupply(), stakedAmount);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMigrator {
    // --- Events ---------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Emitted upon migration
     *
     * @param timestamp  The moment in time when migration took place
     * @param oldPe  The number of old PE tokens withdraw from the previous version
     * @param usdc  The number of USDC tokens converted from the previous version and into the new version
     * @param newPe  The number of new PE tokens migrated to the new version
     */
    event Migrated(uint256 timestamp, uint256 oldPe, uint256 usdc, uint256 newPe);

    // --- Addresses - Automatic ------------------------------------------------------------------------------------------------------------------------------

    /**
     * Retrieve the old version's address
     *
     * @return The address in question
     */
    function peronioV1Address() external view returns (address);

    /**
     * Retrieve the new version's address
     *
     * @return The address in question
     */
    function peronioV2Address() external view returns (address);

    // --- Migration Proper -----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Migrate the given number of PE tokens from the old contract to the new one
     *
     * @param amount  The number of PE tokens to withdraw from the old contract
     * @return usdc  The number of USDC tokens withdrawn from the old contract
     * @return pe  The number of PE tokens minted on the new contract
     * @custom:emit  Migrated
     */
    function migrate(uint256 amount) external returns (uint256 usdc, uint256 pe);

    // --- Quote ----------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Retrieve the number of USDC tokens to withdraw from the old contract, and the number of OE tokens to mint on the new one
     *
     * @param amount  The number of PE tokens to withdraw from the old contract
     * @return usdc  The number of USDC tokens to withdraw from the old contract
     * @return pe  The number of PE tokens to mint on the new contract
     */
    function quote(uint256 amount) external view returns (uint256 usdc, uint256 pe);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Peronio V1 Interface
import {IPeronioV1} from "./IPeronioV1.sol";

// ERC20 Interface
import {IERC20} from "@openzeppelin/contracts_latest/token/ERC20/IERC20.sol";

// QiDao
import {IFarm} from "../../qidao/IFarm.sol";

// UniSwap
import {IUniswapV2Pair} from "../../uniswap/interfaces/IUniswapV2Pair.sol";
import {IERC20Uniswap} from "../../uniswap/interfaces/IERC20Uniswap.sol";

import {Math} from "@openzeppelin/contracts_latest/utils/math/Math.sol";

library PeronioV1Wrapper {
    /**
     * Retrieve the expected number of USDC tokens corresponding to the given number of PE tokens for withdrawal.
     *
     * @param peronioContract  Peronio contract interface
     * @param pe  Number of PE tokens to quote for
     * @return usdc  Number of USDC tokens quoted for the given number of PE tokens
     */
    function quoteOut(IPeronioV1 peronioContract, uint256 pe) internal view returns (uint256 usdc) {
        // --- Gas Saving -------------------------------------------------------------------------
        address _lpAddress = peronioContract.LP_ADDRESS();

        (uint256 usdcReserves, uint256 maiReserves) = peronioContract.getLpReserves();
        uint256 lpTotalSupply = IERC20(_lpAddress).totalSupply();

        // deal with LP minting when changing its K
        {
            uint256 rootK = Math.sqrt(usdcReserves * maiReserves);
            uint256 rootKLast = Math.sqrt(IUniswapV2Pair(_lpAddress).kLast());
            if (rootKLast < rootK) {
                lpTotalSupply += Math.mulDiv(lpTotalSupply, rootK - rootKLast, (rootK * 5) + rootKLast);
            }
        }

        // calculate LP values actually withdrawn
        uint256 lpAmount = IERC20Uniswap(_lpAddress).balanceOf(_lpAddress) +
            Math.mulDiv(pe, peronioContract.stakedBalance(), IERC20(address(peronioContract)).totalSupply());

        uint256 usdcAmount = Math.mulDiv(usdcReserves, lpAmount, lpTotalSupply);
        uint256 maiAmount = Math.mulDiv(maiReserves, lpAmount, lpTotalSupply);

        usdc = usdcAmount + _getAmountOut(maiAmount, maiReserves - maiAmount, usdcReserves - usdcAmount);
    }

    /**
     * Extract the given number of PE tokens as USDC tokens
     *
     * @param peronioContract  Peronio contract interface
     * @param to  Address to deposit extracted USDC tokens into
     * @param peAmount  Number of PE tokens to withdraw
     * @return usdcTotal  Number of USDC tokens extracted
     * @custom:emit  Withdrawal
     */
    function withdrawV2(
        IPeronioV1 peronioContract,
        address to,
        uint256 peAmount
    ) internal returns (uint256 usdcTotal) {
        address usdcAddress = peronioContract.USDC_ADDRESS();
        uint256 oldUsdcBalance = IERC20(usdcAddress).balanceOf(to);

        peronioContract.withdraw(to, peAmount);

        usdcTotal = IERC20(usdcAddress).balanceOf(to) - oldUsdcBalance;
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        amountOut = Math.mulDiv(amountInWithFee, reserveOut, reserveIn * 1000 + amountInWithFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPeronioV1 {
    function USDC_ADDRESS() external view returns (address);

    function MAI_ADDRESS() external view returns (address);

    function LP_ADDRESS() external view returns (address);

    function QUICKSWAP_ROUTER_ADDRESS() external view returns (address);

    function QIDAO_FARM_ADDRESS() external view returns (address);

    function QI_ADDRESS() external view returns (address);

    function QIDAO_POOL_ID() external view returns (uint256);

    // Markup
    function MARKUP_DECIMALS() external view returns (uint8);

    function markup() external view returns (uint256);

    function swapFee() external view returns (uint256);

    // Initialization can only be run once
    function initialized() external view returns (bool);

    // Roles
    function MARKUP_ROLE() external view returns (bytes32);

    function REWARDS_ROLE() external view returns (bytes32);

    // Events
    event Initialized(address owner, uint256 collateral, uint256 startingRatio);
    event Minted(address indexed to, uint256 collateralAmount, uint256 tokenAmount);
    event Withdrawal(address indexed to, uint256 collateralAmount, uint256 tokenAmount);
    event MarkupUpdated(address operator, uint256 markup);
    event CompoundRewards(uint256 qi, uint256 usdc, uint256 lp);
    event HarvestedMatic(uint256 wmatic, uint256 collateral);

    function decimals() external view returns (uint8);

    function initialize(uint256 usdcAmount, uint256 startingRatio) external;

    function setMarkup(uint256 markup_) external;

    function mint(
        address to,
        uint256 usdcAmount,
        uint256 minReceive
    ) external returns (uint256 peAmount);

    function withdraw(address to, uint256 peAmount) external;

    function claimRewards() external;

    function compoundRewards() external returns (uint256 usdcAmount, uint256 lpAmount);

    function stakedBalance() external view returns (uint256);

    function stakedValue() external view returns (uint256 totalUSDC);

    function usdcPrice() external view returns (uint256);

    function buyingPrice() external view returns (uint256);

    function collateralRatio() external view returns (uint256);

    function getPendingRewardsAmount() external view returns (uint256 amount);

    function getLpReserves() external view returns (uint112 usdcReserves, uint112 maiReserves);
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