// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// instead of an enum, we use uint8 to pack the trade type together with user and cometId for a single slot
// the tradeType maps according to the following struct
// enum MarginTradeType {
//     // // One-sided loan and collateral operations
//     // SWAP_BORROW_SINGLE=0,
//     // SWAP_COLLATERAL_SINGLE=1,
//     // SWAP_BORROW_MULTI_EXACT_IN=2,
//     // SWAP_BORROW_MULTI_EXACT_OUT=3,
//     // SWAP_COLLATERAL_MULTI_EXACT_IN=4,
//     // SWAP_COLLATERAL_MULTI_EXACT_OUT=5,
//     // // Two-sided operations
//     // OPEN_MARGIN_SINGLE=6,
//     // TRIM_MARGIN_SINGLE=7,
//     // OPEN_MARGIN_MULTI_EXACT_IN=8,
//     // OPEN_MARGIN_MULTI_EXACT_OUT=9,
//     // TRIM_MARGIN_MULTI_EXACT_IN=10,
//     // TRIM_MARGIN_MULTI_EXACT_OUT=11,
//     // // the following are only used internally
//     // UNISWAP_EXACT_OUT=12,
//     // UNISWAP_EXACT_OUT_BORROW=13,
//     // UNISWAP_EXACT_OUT_WITHDRAW=14
// }

// margin swap input
struct MarginCallbackData {
    bytes path;
    address user;
    // determines how to interact with the lending protocol
    uint8 tradeType;
    // determines the specific money market protocol
    uint8 cometId;
    bool exactIn;
}

struct ExactInputCollateralMultiParams {
    bytes path;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint8 cometId;
}


struct ExactInputNativeCollateralMultiParams {
    bytes path;
    uint256 amountOutMinimum;
    uint8 cometId;
}

struct ExactInputMoneyMarketMultiParams {
    bytes path;
    uint256 amountIn;
    uint256 amountOutMinimum;
    address recipient;
    uint8 cometId;
}

struct AllInputMoneyMarketMultiParams {
    bytes path;
    uint256 amountOutMinimum;
    address recipient;
    uint8 cometId;
}

struct ExactOutputCollateralMultiParams {
    bytes path;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint8 cometId;
}

struct ExactOutputMoneyMarketMultiParams {
    bytes path;
    uint256 amountOut;
    uint256 amountInMaximum;
    address recipient;
    uint8 cometId;
}

struct AllOutputMoneyMarketMultiParams {
    bytes path;
    uint256 amountInMaximum;
    address recipient;
    uint8 cometId;
}

struct ExactInputMultiParams {
    bytes path;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint8 cometId;
}

struct ExactOutputMultiParams {
    bytes path;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint8 cometId;
}

struct MarginSwapParamsMultiExactIn {
    bytes path;
    uint8 cometId;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

struct MarginSwapParamsMultiExactOut {
    bytes path;
    uint8 cometId;
    uint256 amountOut;
    uint256 amountInMaximum;
}

struct ExactOutputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    address user;
    uint8 cometId;
    uint8 tradeType;
    uint256 maximumInputAmount;
}

struct StandaloneExactInputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

// all in / out parameters

struct AllInputCollateralMultiParamsBase {
    bytes path;
    uint256 amountOutMinimum;
}

struct AllInputMultiParamsBase {
    bytes path;
    uint256 amountOutMinimum;
    uint8 cometId;
}

struct AllOutputMultiParamsBase {
    bytes path;
    uint256 amountInMaximum;
    uint8 cometId;
}

struct AllInputMultiParamsBaseWithRecipient {
    bytes path;
    address recipient;
    uint256 amountOutMinimum;
    uint8 cometId;
}

struct AllOutputMultiParamsBaseWithRecipient {
    bytes path;
    uint256 amountInMaximum;
    address recipient;
    uint8 cometId;
}

struct AllInputCollateralMultiParamsBaseWithRecipient {
    bytes path;
    uint256 amountOutMinimum;
    address recipient;
    uint8 cometId;
}

struct AllOutputCollateralMultiParamsBaseWithRecipient {
    bytes path;
    uint256 amountInMaximum;
    address recipient;
    uint8 cometId;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolEvents.sol';


interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

// solhint-disable max-line-length

interface IUniswapV3PoolActions {
    function initialize(uint160 sqrtPriceX96) external;

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

interface IUniswapV3PoolDerivedState {
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

// solhint-disable max-line-length

interface IUniswapV3PoolEvents {
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Collect(address indexed owner, address recipient, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount0, uint128 amount1);

    event Burn(address indexed owner, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount, uint256 amount0, uint256 amount1);

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

    event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew);

    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../core/IUniswapV3Pool.sol";
import "./PoolAddressCalculator.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view {
        require(msg.sender == PoolAddressCalculator.computeAddress(factory, tokenA, tokenB, fee));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            ))
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddressCalculator {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        if (tokenA < tokenB) {
            pool = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(tokenA, tokenB, fee)), POOL_INIT_CODE_HASH))
                    )
                )
            );
        } else {
             pool = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(tokenB, tokenA, fee)), POOL_INIT_CODE_HASH))
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     **/
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IComet {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    function supply(address asset, uint256 amount) external;

    function supplyTo(
        address dst,
        address asset,
        uint256 amount
    ) external;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function transferAsset(
        address dst,
        address asset,
        uint256 amount
    ) external;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function withdraw(address asset, uint256 amount) external;

    function withdrawTo(
        address to,
        address asset,
        uint256 amount
    ) external;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint256 amount
    ) external;

    function approveThis(
        address manager,
        address asset,
        uint256 amount
    ) external;

    function withdrawReserves(address to, uint256 amount) external;

    function absorb(address absorber, address[] calldata accounts) external;

    function buyCollateral(
        address asset,
        uint256 minAmount,
        uint256 baseAmount,
        address recipient
    ) external;

    function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

    function getCollateralReserves(address asset) external view returns (uint256);

    function getReserves() external view returns (int256);

    function getPrice(address priceFeed) external view returns (uint256);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external;

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function isAbsorbPaused() external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function accrueAccount(address account) external;

    function getSupplyRate(uint256 utilization) external view returns (uint64);

    function getBorrowRate(uint256 utilization) external view returns (uint64);

    function getUtilization() external view returns (uint256);

    function governor() external view returns (address);

    function pauseGuardian() external view returns (address);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function extensionDelegate() external view returns (address);

    /// @dev uint64
    function supplyKink() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint256);

    /// @dev uint64
    function borrowKink() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint256);

    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint256);

    /// @dev uint64
    function baseScale() external view returns (uint256);

    /// @dev uint64
    function trackingIndexScale() external view returns (uint256);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint256);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint256);

    /// @dev uint104
    function baseMinForRewards() external view returns (uint256);

    /// @dev uint104
    function baseBorrowMin() external view returns (uint256);

    /// @dev uint104
    function targetReserves() external view returns (uint256);

    function numAssets() external view returns (uint8);

    function decimals() external view returns (uint8);

    function initializeStorage() external;

    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    function isAllowed(address user, address manager) external view returns (bool);

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function userBasic(address user) external view returns (UserBasic memory);

    function totalsCollateral(address asset) external view returns (TotalsCollateral memory);

    function userCollateral(address user, address asset) external view returns (UserCollateral memory);

    function totalsBasic() external view returns (TotalsBasic memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface for WETH9
interface IWETH9 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    function transfer(address, uint256) external;
}

// SPDX-License-Identifier: MIT
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]> / Achthar
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.20;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPoolAndValidateLength(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee,
            bool multiPool
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
        multiPool = path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }

    function getLastToken(bytes memory path) internal pure returns (address) {
        return path.toAddress(path.length - ADDR_SIZE);
    }

    function getFirstToken(bytes memory path) internal pure returns (address) {
        return path.toAddress(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import {MarginCallbackData} from "../../dataTypes/CometInputTypes.sol";
import {IPool} from "../../interfaces/IAAVEV3Pool.sol";
import {Path} from "../../libraries/Path.sol";
import {SafeCast} from "../../dex-tools/uniswap/libraries/SafeCast.sol";
import {IUniswapV3Pool} from "../../dex-tools/uniswap/core/IUniswapV3Pool.sol";
import {PoolAddress} from "../../dex-tools/uniswap/libraries/PoolAddress.sol";
import {WithStorageComet} from "../../storage/CometBrokerStorage.sol";

// solhint-disable max-line-length

/**
 * @title Money market module
 * @notice Allows users to chain a single money market transaction with a swap.
 * Direct lending pool interactions are unnecessary as the user can directly interact with the lending protocol
 * @author Achthar
 */
contract InternalSwapperComet is WithStorageComet {
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev MIN_SQRT_RATIO + 1 from Uniswap's TickMath
    uint160 internal immutable MIN_SQRT_RATIO = 4295128740;
    /// @dev MAX_SQRT_RATIO - 1 from Uniswap's TickMath
    uint160 internal immutable MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;

    bytes32 private immutable UNI_FF_FACTORY_ADDRESS;
    /// @dev Mask of lower 20 bytes.
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    /// @dev Mask of lower 3 bytes.
    uint256 private constant UINT24_MASK = 0xffffff;

    constructor(address uniFactory) {
        UNI_FF_FACTORY_ADDRESS = bytes32((uint256(0xff) << 248) | (uint256(uint160(uniFactory)) << 88));
    }

    // Compute the pool address given two tokens and a fee.
    function _toPool(
        address inputToken,
        uint24 fee,
        address outputToken
    ) internal view returns (IUniswapV3Pool pool) {
        // address(keccak256(abi.encodePacked(
        //     hex"ff",
        //     UNI_FACTORY_ADDRESS,
        //     keccak256(abi.encode(inputToken, outputToken, fee)),
        //     UNI_POOL_INIT_CODE_HASH
        // )))
        bytes32 ffFactoryAddress = UNI_FF_FACTORY_ADDRESS;
        bytes32 poolInitCodeHash = PoolAddress.POOL_INIT_CODE_HASH;
        (address token0, address token1) = inputToken < outputToken ? (inputToken, outputToken) : (outputToken, inputToken);
        assembly {
            let s := mload(0x40)
            let p := s
            mstore(p, ffFactoryAddress)
            p := add(p, 21)
            // Compute the inner hash in-place
            mstore(p, token0)
            mstore(add(p, 32), token1)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(p, keccak256(p, 96))
            p := add(p, 32)
            mstore(p, poolInitCodeHash)
            pool := and(ADDRESS_MASK, keccak256(s, 85))
        }
    }

    function exactInputToSelf(uint256 amountIn, bytes memory path) internal returns (uint256 amountOut) {
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();

            MarginCallbackData memory exactInputData;
            exactInputData.path = path.getFirstPool();
            exactInputData.tradeType = 99;
            (address tokenIn, address tokenOut, uint24 fee) = exactInputData.path.decodeFirstPool();

            bool zeroForOne = tokenIn < tokenOut;
            (int256 amount0, int256 amount1) = _toPool(tokenIn, fee, tokenOut).swap(
                address(this),
                zeroForOne,
                amountIn.toInt256(),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                abi.encode(exactInputData)
            );

            amountIn = uint256(-(zeroForOne ? amount1 : amount0));

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                amountOut = amountIn;
                break;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import {IERC20} from "../../../interfaces/IERC20.sol";
import {IComet} from "../../interfaces/IComet.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {CallbackValidation} from "../../dex-tools/uniswap/libraries/CallbackValidation.sol";
import "../base/InternalSwapperComet.sol";

// solhint-disable max-line-length

/**
 * @title MarginTrader contract
 * @notice Allows users to build large margin positions with one contract interaction
 * @author Achthar
 */
contract CometUniV3Callback is InternalSwapperComet {
    using Path for bytes;
    using SafeCast for uint256;

    constructor(address uniFactory) InternalSwapperComet(uniFactory) {}

    // callback for dealing with margin trades
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory _data
    ) external {
        MarginCallbackData memory data = abi.decode(_data, (MarginCallbackData));
        // fetch trade type and cast to uint256 as Sol always checks equality in this type
        uint256 tradeType = data.tradeType;
        // address user = data.user;
        // fetch pool data
        (address tokenIn, address tokenOut, uint24 fee, bool hasMore) = data.path.decodeFirstPoolAndValidateLength();
        {
            require(msg.sender == address(_toPool(tokenIn, fee, tokenOut)), "Invalid Caller");
        }

        // EXACT IN BASE SWAP
        if (tradeType == 99) {
            uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
            pay(tokenIn, address(this), amountToPay);
        } else {
            // get comet market
            IComet comet = IComet(cos().comet[data.cometId]);

            // COLLATERAL SWAPS
            if (tradeType == 4) {
                if (data.exactIn) {
                    (uint256 amountToWithdraw, uint256 amountToSwap) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));

                    if (hasMore) {
                        // we need to swap to the token that we want to supply
                        // the router returns the amount that we can finally supply to the protocol
                        data.path = data.path.skipToken();
                        amountToSwap = exactInputToSelf(amountToSwap, data.path);

                        // supply directly
                        tokenOut = data.path.getLastToken();
                    }
                    // cache amount
                    cs().amount = amountToSwap;

                    // aavePool.supply(tokenOut, amountToSwap, data.user, 0);
                    comet.supplyTo(data.user, tokenOut, amountToSwap);

                    // withraw and send funds to the pool
                    comet.withdrawFrom(data.user, msg.sender, tokenIn, amountToWithdraw);
                } else {
                    // multi swap exact out
                    (uint256 amountInLastPool, uint256 amountToSupply) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));
                    // we supply the amount received directly - together with user provided amount
                    comet.supplyTo(data.user, tokenIn, amountToSupply);
                    // we then swap exact out where the first amount is
                    // borrowed and paid from the money market
                    // the received amount is paid back to the original pool
                    if (hasMore) {
                        data.path = data.path.skipToken();
                        (tokenOut, tokenIn, fee) = data.path.decodeFirstPool();

                        data.tradeType = 13;
                        bool zeroForOne = tokenIn < tokenOut;

                        _toPool(tokenIn, fee, tokenOut).swap(
                            msg.sender,
                            zeroForOne,
                            -amountInLastPool.toInt256(),
                            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                            abi.encode(data)
                        );
                    } else {
                        // cache amount
                        cs().amount = amountInLastPool;

                        comet.withdrawFrom(data.user, msg.sender, tokenOut, amountInLastPool);
                    }
                }
            }
            // OPEN MARGIN
            else if (tradeType == 8) {
                if (data.exactIn) {
                    // multi swap exact in
                    (uint256 amountToBorrow, uint256 amountToSwap) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));

                    if (hasMore) {
                        // we need to swap to the token that we want to supply
                        // the router returns the amount that we can finally supply to the protocol
                        data.path = data.path.skipToken();
                        amountToSwap = exactInputToSelf(amountToSwap, data.path);
                        tokenOut = data.path.getLastToken();
                    }

                    // cache amount
                    cs().amount = amountToSwap;

                    // supply the provided amounts
                    comet.supplyTo(data.user, tokenOut, amountToSwap);

                    // borrow funds (amountIn) from pool
                    comet.withdrawFrom(data.user, msg.sender, tokenIn, amountToBorrow);
                } else {
                    // multi swap exact out
                    (uint256 amountInLastPool, uint256 amountToSupply) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));

                    // we supply the amount received directly - together with user provided amount
                    comet.supplyTo(data.user, tokenIn, amountToSupply);
                    if (hasMore) {
                        // we then swap exact out where the first amount is
                        // borrowed and paid from the money market
                        // the received amount is paid back to the original pool
                        data.path = data.path.skipToken();
                        (tokenOut, tokenIn, fee) = data.path.decodeFirstPool();
                        data.tradeType = 13;
                        bool zeroForOne = tokenIn < tokenOut;

                        _toPool(tokenIn, fee, tokenOut).swap(
                            msg.sender,
                            zeroForOne,
                            -amountInLastPool.toInt256(),
                            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                            abi.encode(data)
                        );
                    } else {
                        // cache amount
                        cs().amount = amountInLastPool;
                        comet.withdrawFrom(data.user, msg.sender, tokenOut, amountInLastPool);
                    }
                }
            }
            // EXACT OUT - BORROW (= WITHDRAW)
            else if (tradeType == 13) {
                // multi swap exact out
                uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
                // either initiate the next swap or pay
                if (hasMore) {
                    data.path = data.path.skipToken();
                    (tokenOut, tokenIn, fee) = data.path.decodeFirstPool();

                    bool zeroForOne = tokenIn < tokenOut;

                    _toPool(tokenIn, fee, tokenOut).swap(
                        msg.sender,
                        zeroForOne,
                        -amountToPay.toInt256(),
                        zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                        abi.encode(data)
                    );
                } else {
                    tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                    comet.withdrawFrom(data.user, msg.sender, tokenIn, amountToPay);
                    // cache amount
                    cs().amount = amountToPay;
                }
            }
            // TRIM
            else if (tradeType == 10) {
                if (data.exactIn) {
                    // trim position exact in
                    (uint256 amountToWithdraw, uint256 amountToSwap) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));
                    if (hasMore) {
                        // we need to swap to the token that we want to repay
                        // the router returns the amount that we can use to repay
                        data.path = data.path.skipToken();
                        amountToSwap = exactInputToSelf(amountToSwap, data.path);

                        tokenOut = data.path.getLastToken();
                    }
                    // cache amount
                    cs().amount = amountToSwap;
                    // lending protocol underlyings are approved by default
                    comet.supplyTo(data.user, tokenOut, amountToSwap);

                    // withraw and send funds to the pool
                    comet.withdrawFrom(data.user, msg.sender, tokenIn, amountToWithdraw);
                } else {
                    // multi swap exact out
                    (uint256 amountInLastPool, uint256 amountToRepay) = amount0Delta > 0
                        ? (uint256(amount0Delta), uint256(-amount1Delta))
                        : (uint256(amount1Delta), uint256(-amount0Delta));

                    // repay
                    comet.supplyTo(data.user, tokenIn, amountToRepay);

                    if (hasMore) {
                        // we then swap exact out where the first amount is
                        // withdrawn from the lending protocol pool and paid back to the pool
                        data.path = data.path.skipToken();
                        (tokenOut, tokenIn, fee) = data.path.decodeFirstPool();
                        data.tradeType = 13;
                        bool zeroForOne = tokenIn < tokenOut;

                        _toPool(tokenIn, fee, tokenOut).swap(
                            msg.sender,
                            zeroForOne,
                            -amountInLastPool.toInt256(),
                            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                            abi.encode(data)
                        );
                    } else {
                        // cache amount
                        cs().amount = amountInLastPool;
                        // withraw and send funds to the pool
                        comet.withdrawFrom(data.user, msg.sender, tokenOut, amountInLastPool);
                    }
                }
            }
            // EXACT OUT - PAID BY USER
            else if (tradeType == 12) {
                // multi swap exact out
                uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
                // either initiate the next swap or pay
                if (data.path.hasMultiplePools()) {
                    data.path = data.path.skipToken();
                    (tokenOut, tokenIn, fee) = data.path.decodeFirstPool();
                    bool zeroForOne = tokenIn < tokenOut;
                    // we do not require the condition for the exact output away, that is already done elsewhere
                    _toPool(tokenIn, fee, tokenOut).swap(
                        msg.sender,
                        zeroForOne,
                        -amountToPay.toInt256(),
                        zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                        abi.encode(data)
                    );
                } else {
                    tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                    pay(tokenIn, data.user, amountToPay);
                    // cache amount
                    cs().amount = amountToPay;
                }
            }
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        uint256 value
    ) internal {
        if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            IERC20(token).transfer(msg.sender, value);
        } else {
            // pull payment
            IERC20(token).transferFrom(payer, msg.sender, value);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// We do not use an array of stucts to avoid pointer conflicts

// Management storage that stores the different DAO roles
struct TradeDataStorage {
    uint256 test;
}

struct CometStorage {
    mapping(uint8 => address) comet;
    mapping(uint8 => address) base;
}

struct CompoundStorage {
    address comptroller;
    mapping(address => address) cTokens;
}

struct UniswapStorage {
    address v3factory;
    address weth;
    address swapRouter;
}

struct DataProviderStorage {
    address dataProvider;
}

struct ManagementStorage {
    address chief;
    mapping(address => bool) isManager;
}

// for exact output multihop swaps
struct Cache {
    uint256 amount;
}

library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant DATA_PROVIDER_STORAGE = keccak256("broker.storage.dataProvider");
    bytes32 constant MARGIN_SWAP_STORAGE = keccak256("broker.storage.marginSwap");
    bytes32 constant UNISWAP_STORAGE = keccak256("broker.storage.uniswap");
    bytes32 constant COMET_STORAGE = keccak256("broker.storage.comet");
    bytes32 constant MANAGEMENT_STORAGE = keccak256("broker.storage.management");
    bytes32 constant CACHE = keccak256("broker.storage.cache");

    function dataProviderStorage() internal pure returns (DataProviderStorage storage ps) {
        bytes32 position = DATA_PROVIDER_STORAGE;
        assembly {
            ps.slot := position
        }
    }

    function cometStorage() internal pure returns (CometStorage storage aas) {
        bytes32 position = COMET_STORAGE;
        assembly {
            aas.slot := position
        }
    }

    function uniswapStorage() internal pure returns (UniswapStorage storage us) {
        bytes32 position = UNISWAP_STORAGE;
        assembly {
            us.slot := position
        }
    }

    function managementStorage() internal pure returns (ManagementStorage storage ms) {
        bytes32 position = MANAGEMENT_STORAGE;
        assembly {
            ms.slot := position
        }
    }

    function cacheStorage() internal pure returns (Cache storage cs) {
        bytes32 position = CACHE;
        assembly {
            cs.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Module contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
abstract contract WithStorageComet {
    function ps() internal pure returns (DataProviderStorage storage) {
        return LibStorage.dataProviderStorage();
    }

    function cos() internal pure returns (CometStorage storage) {
        return LibStorage.cometStorage();
    }

    function us() internal pure returns (UniswapStorage storage) {
        return LibStorage.uniswapStorage();
    }

    function ms() internal pure returns (ManagementStorage storage) {
        return LibStorage.managementStorage();
    }

    function cs() internal pure returns (Cache storage) {
        return LibStorage.cacheStorage();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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